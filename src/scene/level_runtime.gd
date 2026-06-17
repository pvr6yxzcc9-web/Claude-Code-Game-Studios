extends Node

# LevelRuntime (per level-dungeon.md)
# Programmatic level builder. Loads a LevelData, builds walls + doors + encounter tiles
# procedurally. Avoids writing 10 .tscn files (per MVP).
# PR-10: extends Node (not Node2D) so the root scene can have other children
# (Player, Camera, UI) that survive build_room's clear_room().

@export var level_id: StringName = &"chapter1_scrapyard"

var level_data: Resource = null
var current_room_index: int = 0
var player_spawn_pos: Vector2 = Vector2(200, 360)

var _walls: StaticBody2D
var _doors: Array[Node2D] = []
var _encounters: Array[Node2D] = []

func _ready() -> void:
	var reg: Node = get_node("/root/ResourceRegistry")
	level_data = reg.get_resource(level_id)
	if level_data == null:
		push_error("LevelRuntime: level %s not found" % level_id)
		return
	# S4-002: equip starting mech parts (torso + both arms). Players can
	# cycle between them with Q (see MechLoadout.cycle_equipped_part).
	_equip_starting_mech_parts()
	print("[LevelRuntime] _ready: calling build_room(0) directly")
	# NOTE: call_deferred was failing in 4.6 with Node root. Call directly.
	build_room(0)
	# PR-10: enable polling fallback after build_room settles (1.5s delay)
	# This prevents false triggers on the very first frame after build
	_polling_enabled = false
	get_tree().create_timer(1.5).timeout.connect(_enable_polling)
	set_process(true)
	print("[LevelRuntime] ready, level=%s rooms=%d" % [level_id, level_data.get("room_ids").size()])

func _equip_starting_mech_parts() -> void:
	var mech: Node = get_node("/root/MechLoadout")
	mech.equip_part(&"torso", &"starter_torso")
	mech.equip_part(&"left_arm", &"steady_arm")
	mech.equip_part(&"right_arm", &"plated_arm")

func _enable_polling() -> void:
	_polling_enabled = true

var _polling_enabled: bool = false

# S6-102: switch to a different level (chapter transition). Reloads
# the level data, clears the room, and rebuilds from room 0.
func change_chapter(new_level_id: StringName) -> void:
	# S14-005: show loading during chapter change
	var ls: Node = get_node_or_null("/root/LoadingScreen")
	if ls != null and ls.has_method("show_loading"):
		ls.show_loading("Changing chapter...")
	level_id = new_level_id
	var reg: Node = get_node("/root/ResourceRegistry")
	level_data = reg.get_resource(level_id) if reg != null else null
	if level_data == null:
		push_error("LevelRuntime: level %s not found" % level_id)
		if ls != null and ls.has_method("hide_loading"):
			ls.hide_loading()
		return
	current_room_index = 0
	build_room(0)
	if ls != null and ls.has_method("hide_loading"):
		ls.hide_loading()
	print("[LevelRuntime] changed to chapter %d (%s)" % [
		int(level_data.get("chapter_index")) if level_data != null else 0, level_id])

# S6-102: helper to get current chapter index, defaults to 1
func get_chapter_index() -> int:
	if level_data == null:
		return 1
	if "chapter_index" in level_data:
		return int(level_data.chapter_index)
	return 1

func build_room(room_index: int) -> void:
	print("[LevelRuntime] build_room(%d) called" % room_index)
	current_room_index = room_index
	clear_room()
	# S6-009: tiled floor (20x12 grid of 64x64 Sprite2D). Replaces the
	# single ColorRect so rooms read as sci-fi ruin, not gray box.
	# All tiles use the same z_index = -10 to render behind everything.
	_build_tiled_floor()
	# S6-009: wall visuals (Sprite2D segments) added as siblings of
	# the player. The StaticBody2D collision shapes (added below) still
	# gate player movement; these sprites are purely decorative.
	_build_wall_visuals()
	# Walls (PR-10: doors replace wall sections, so skip the right wall if room has a right door)
	_walls = StaticBody2D.new()
	_walls.name = "Walls"
	add_child(_walls)
	var total_rooms: int = level_data.get("room_ids").size()
	var has_right_door: bool = room_index < total_rooms - 1
	var has_left_door: bool = room_index > 0
	var wall_shape: RectangleShape2D = RectangleShape2D.new()
	wall_shape.size = Vector2(1312, 32)
	var rect_h: RectangleShape2D = RectangleShape2D.new()
	rect_h.size = Vector2(32, 752)
	# Top + bottom always
	var wt: CollisionShape2D = CollisionShape2D.new()
	wt.shape = wall_shape
	wt.position = Vector2(640, -16)
	_walls.add_child(wt)
	var wb: CollisionShape2D = CollisionShape2D.new()
	wb.shape = wall_shape
	wb.position = Vector2(640, 736)
	_walls.add_child(wb)
	# Left wall: split into two vertical segments if a left door exists
	# (so the door has a 96px gap at y=312..408); otherwise single full
	# vertical wall. Without the split, players walk off-screen in rooms
	# with a door.
	var door_gap_top_shape: RectangleShape2D = RectangleShape2D.new()
	door_gap_top_shape.size = Vector2(32, 312)  # y range 0..312 at x=-16 or 1296
	var door_gap_bot_shape: RectangleShape2D = RectangleShape2D.new()
	door_gap_bot_shape.size = Vector2(32, 312)  # y range 408..720
	if has_left_door:
		var wl_top: CollisionShape2D = CollisionShape2D.new()
		wl_top.shape = door_gap_top_shape
		wl_top.position = Vector2(-16, 156)
		_walls.add_child(wl_top)
		var wl_bot: CollisionShape2D = CollisionShape2D.new()
		wl_bot.shape = door_gap_bot_shape
		wl_bot.position = Vector2(-16, 564)
		_walls.add_child(wl_bot)
	else:
		var wl: CollisionShape2D = CollisionShape2D.new()
		wl.shape = rect_h
		wl.position = Vector2(-16, 360)
		_walls.add_child(wl)
	# Right wall: same split logic. Room 9 (last) has no right door -> full
	# wall. Rooms 0-8 have a right door -> split wall with 96px gap.
	if has_right_door:
		var wr_top: CollisionShape2D = CollisionShape2D.new()
		wr_top.shape = door_gap_top_shape
		wr_top.position = Vector2(1296, 156)
		_walls.add_child(wr_top)
		var wr_bot: CollisionShape2D = CollisionShape2D.new()
		wr_bot.shape = door_gap_bot_shape
		wr_bot.position = Vector2(1296, 564)
		_walls.add_child(wr_bot)
	else:
		var wr: CollisionShape2D = CollisionShape2D.new()
		wr.shape = rect_h
		wr.position = Vector2(1296, 360)
		_walls.add_child(wr)
	# Doors: right door (if not last room), left door (if not first room)
	if room_index < total_rooms - 1:
		_spawn_door(Vector2(1280, 360), room_index + 1, "right")
	if room_index > 0:
		_spawn_door(Vector2(0, 360), room_index - 1, "left")
	# Boss room (last): add 1 encounter at center
	if room_index == total_rooms - 1:
		_spawn_encounter(Vector2(640, 360), &"boss_marrow_sentinel")
	# First 3 rooms: 1 random encounter
	elif room_index < 3:
		_spawn_encounter(Vector2(900, 400), &"scavenger")
	# S2-005: Vera NPC in room 0 (left of center)
	if room_index == 0:
		_spawn_npc(Vector2(300, 360), &"vera_merchant")
		# S6-002: replace the S2-010 single-hint with the multi-step
		# TutorialManager. Triggered only on first visit (or if MetaState
		# doesn't already have tutorial_dismissed=true).
		var tutorial: Node = get_node_or_null("/root/TutorialManager")
		if tutorial != null and tutorial.has_method("start"):
			tutorial.start()
	# S4-006: Additional NPCs in rooms 3, 4, 6 — three dialogue roles
	# (merchant / lore_keeper / ambient) that don't compete with Vera in room 0.
	if room_index == 3:
		_spawn_npc(Vector2(950, 360), &"salvage_drone_operator")
	if room_index == 4:
		_spawn_npc(Vector2(300, 360), &"marlow_ghost")
		# S4-008: hidden area in top-right of room 4 (behind Marlow).
		# Wall blocks access; destroying it reveals a hidden terminal that
		# unlocks fragment_the_seal (was tbd; now wired).
		_spawn_breakable_wall(Vector2(1100, 360), 3)
	if room_index == 6:
		_spawn_npc(Vector2(950, 360), &"courier_14")
	# S2-006: Terminal log in room 2 (right of center)
	if room_index == 2:
		_spawn_terminal(Vector2(950, 360), &"log_scrapyard_intro")
	# S4-005: Additional fragment-triggering terminals in rooms 5 and 8.
	# These unlock fragment_the_convoy, fragment_marlows_daughter, fragment_the_seal
	# via the same body_entered -> TerminalController.open_log path.
	if room_index == 5:
		_spawn_terminal(Vector2(950, 360), &"log_wreckage_inspection")
	if room_index == 8:
		_spawn_terminal(Vector2(950, 360), &"log_personal_log")
	# S6-102: Chapter 2 content. Only applies when chapter_index == 2.
	# C2 rooms have different NPCs (frost themed), terminals, and a
	# breakable wall in room 7 that unlocks the secret terminal.
	var is_ch2: bool = (get_chapter_index() == 2)
	if is_ch2:
		# C2-Room 0: frost engineer (lore)
		if room_index == 0:
			_spawn_npc(Vector2(300, 360), &"frost_engineer")
		# C2-Room 2: ice hermit (ambient)
		if room_index == 2:
			_spawn_npc(Vector2(300, 360), &"ice_hermit")
			_spawn_terminal(Vector2(950, 360), &"log_who_remains")
		# C2-Room 3: scavenger leader (merchant) + 1 encounter
		if room_index == 3:
			_spawn_npc(Vector2(950, 360), &"scavenger_leader")
			_spawn_encounter(Vector2(400, 400), &"frostling")
		# C2-Room 4: salvage drone (merchant) + 1 terminal
		if room_index == 4:
			_spawn_npc(Vector2(300, 360), &"frost_drone")
			_spawn_terminal(Vector2(950, 360), &"log_whats_in_the_crates")
		# C2-Room 5: 1 encounter
		if room_index == 5:
			_spawn_encounter(Vector2(900, 400), &"shard_bot")
		# C2-Room 6: 1 encounter
		if room_index == 6:
			_spawn_encounter(Vector2(900, 400), &"glacier")
		# C2-Room 7: breakable wall (S4-008 equivalent) + 1 terminal
		if room_index == 7:
			_spawn_breakable_wall(Vector2(1100, 360), 4)  # harder to break
			_spawn_terminal(Vector2(950, 360), &"log_what_lurks_below")
		# C2-Room 8: 1 encounter (mini-boss-tier)
		if room_index == 8:
			_spawn_encounter(Vector2(900, 400), &"crystal_sentinel")
		# C2-Room 9: BOSS (Ice Warden)
		if room_index == 9:
			_spawn_encounter(Vector2(640, 360), &"boss_ice_warden")
	# Reposition player (use a fresh center spawn for first room; left/right edge otherwise)
	var player: Node = get_tree().get_root().find_child("Player", true, false)
	if player != null:
		if room_index == 0:
			player.global_position = Vector2(640, 360)  # room 0: center spawn
			# S6-105: start speedrun timer on chapter entry (room 0).
			# Re-start each time the player enters a fresh chapter.
			var st: Node = get_node_or_null("/root/SpeedrunTimer")
			if st != null and not st.is_running():
				var chap_id: StringName = &"chapter1_scrapyard" if get_chapter_index() == 1 else &"chapter2_frozen_reactor"
				st.start_run(chap_id)
		elif door_dir == "right":
			player.global_position = Vector2(1180, 360)  # came from right door (now on left side of new room)
		else:
			player.global_position = Vector2(100, 360)  # came from left door (now on right side of new room)

var door_dir: String = ""

func _spawn_door(pos: Vector2, target_room: int, direction: String) -> void:
	# PR-10: Wrap in Node2D so the visual ColorRect is rendered (Area2D doesn't render children)
	var door_wrapper: Node2D = Node2D.new()
	door_wrapper.name = "Door_%d_%s" % [target_room, direction]
	door_wrapper.position = pos
	# PR-10: add to tree FIRST so child Area2D + CollisionShape are active
	add_child(door_wrapper)
	var area: Area2D = Area2D.new()
	# PR-10 fix: start with monitoring=false, enable via timer after build settles
	# This prevents spurious body_entered when player is still in initial position
	area.monitoring = false
	door_wrapper.add_child(area)
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(32, 96)
	shape.shape = rect
	area.add_child(shape)
	# Visual marker on the wrapper (Node2D canvas item)
	var visual: ColorRect = ColorRect.new()
	visual.position = Vector2(-16, -48)
	visual.size = Vector2(32, 96)
	visual.color = Color(0.3, 0.7, 1.0, 0.5) if direction == "right" else Color(0.3, 1.0, 0.3, 0.5)
	door_wrapper.add_child(visual)
	door_wrapper.set_meta("target_room", target_room)
	door_wrapper.set_meta("direction", direction)
	area.body_entered.connect(_on_door_body_entered.bind(door_wrapper))
	_doors.append(door_wrapper)
	# Enable monitoring after the initial settle window
	get_tree().create_timer(0.3).timeout.connect(func() -> void: if is_instance_valid(area): area.monitoring = true)

func _on_door_body_entered(body: Node, door: Area2D) -> void:
	print("[LevelRuntime] door entered! body=%s door=%s" % [body.name, door.get_meta("target_room", -1)])
	if not body is PlayerController:
		return
	var target_room: int = int(door.get_meta("target_room"))
	var direction: String = String(door.get_meta("direction"))
	door_dir = "left" if direction == "right" else "right"
	# Disconnect so subsequent re-entries don't double-fire
	var area: Area2D = door.get_node("Area2D") if door.has_node("Area2D") else null
	if area == null:
		# 4.6 may put Area2D as a different index; iterate
		for child in door.get_children():
			if child is Area2D:
				area = child
				break
	if area != null and area.body_entered.is_connected(_on_door_body_entered.bind(door)):
		# Don't disconnect bound callable (we bound it differently per door); just disable monitoring
		area.monitoring = false
	build_room(target_room)

func _spawn_encounter(pos: Vector2, enemy_id: StringName) -> void:
	# PR-10: Wrap in Node2D for visual + collision (Area2D doesn't render children)
	var enc_wrapper: Node2D = Node2D.new()
	enc_wrapper.position = pos
	# PR-10: add to tree FIRST so Area2D is in the physics world
	add_child(enc_wrapper)
	var area: Area2D = Area2D.new()
	area.monitoring = false  # PR-10: don't trigger until player has settled
	enc_wrapper.add_child(area)
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(48, 48)
	shape.shape = rect
	area.add_child(shape)
	# Visual: red diamond indicator
	var visual: ColorRect = ColorRect.new()
	visual.position = Vector2(-24, -24)
	visual.size = Vector2(48, 48)
	visual.color = Color(1.0, 0.2, 0.2, 0.5) if enemy_id != &"boss_marrow_sentinel" else Color(1.0, 0.5, 0.0, 0.7)
	enc_wrapper.add_child(visual)
	enc_wrapper.set_meta("enemy_id", enemy_id)
	area.body_entered.connect(_on_encounter_body_entered.bind(enc_wrapper))
	_encounters.append(enc_wrapper)
	# PR-10: enable monitoring after one frame (so player can walk to/from without immediate trigger)
	area.set_deferred("monitoring", true)

# S2-005: NPC spawn (Vera in room 0)
var _npcs: Array[Node2D] = []

func _spawn_npc(pos: Vector2, npc_id: StringName) -> void:
	var npc_wrapper: Node2D = Node2D.new()
	npc_wrapper.position = pos
	add_child(npc_wrapper)
	var npc_ctrl: NPCController = NPCController.new()
	npc_ctrl.npc_data_id = npc_id
	npc_wrapper.add_child(npc_ctrl)
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(48, 48)
	shape.shape = rect
	npc_ctrl.add_child(shape)
	# S6-015: visual is now the NPC's portrait (64x64 sprite) if available.
	# Fall back to a yellow ColorRect (legacy) if portrait is missing.
	var reg: Node = get_node("/root/ResourceRegistry")
	var npc_data_res: Resource = reg.get_resource(npc_id)
	if npc_data_res != null and "portrait" in npc_data_res and npc_data_res.portrait != null:
		var portrait_sprite: Sprite2D = Sprite2D.new()
		portrait_sprite.texture = npc_data_res.portrait
		portrait_sprite.position = Vector2(-32, -32)
		portrait_sprite.centered = true
		npc_wrapper.add_child(portrait_sprite)
		# Interaction prompt "E" above head
		var prompt: Label = Label.new()
		prompt.text = _tr(&"ui.prompt.interact", "[E]")
		prompt.position = Vector2(-12, -52)
		prompt.add_theme_font_size_override("font_size", 12)
		prompt.add_theme_color_override("font_color", Color(1, 1, 0.5, 1))
		npc_wrapper.add_child(prompt)
	else:
		# Fallback: yellow square + label (legacy)
		var visual: ColorRect = ColorRect.new()
		visual.position = Vector2(-24, -24)
		visual.size = Vector2(48, 48)
		visual.color = Color(0.9, 0.8, 0.2, 0.8)
		npc_wrapper.add_child(visual)
		var label: Label = Label.new()
		label.text = _tr(&"ui.npc.marker_label", "NPC")
		label.position = Vector2(-12, -50)
		npc_wrapper.add_child(label)
	npc_wrapper.set_meta("npc_id", npc_id)
	_npcs.append(npc_wrapper)

# S2-006: Terminal log spawn (room 2)
var _terminals: Array[Node2D] = []

func _spawn_breakable_wall(pos: Vector2, hp: int) -> void:
	# S4-008: place a destructible wall at pos. When broken, spawn a
	# hidden terminal behind it that unlocks fragment_the_seal.
	var wall_script: Script = load("res://src/scene/breakable_wall.gd")
	var wall: StaticBody2D = StaticBody2D.new()
	wall.set_script(wall_script)
	wall.max_hp = hp
	wall.position = pos
	add_child(wall)
	wall.wall_broken.connect(_on_breakable_wall_broken.bind(wall.position))
	# S5-007: discoverability hint. Spawn 2 small yellow "?" markers
	# hovering above the wall so the player notices the wall can be
	# interacted with. Parent them to the wall so they queue_free
	# together when the wall breaks.
	for marker_offset in [Vector2(-20, -180), Vector2(20, -180)]:
		var marker: Label = Label.new()
		marker.text = _tr(&"ui.breakable.marker_label", "?")
		marker.add_theme_font_size_override("font_size", 24)
		marker.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4, 1))
		marker.position = marker_offset
		wall.add_child(marker)

func _on_breakable_wall_broken(wall_pos: Vector2) -> void:
	# Spawn hidden terminal to the LEFT of the wall (in the newly-opened space).
	# S4-005 had the_seal as tbd; this is the wiring that activates it.
	var hidden_pos: Vector2 = wall_pos + Vector2(-80, 0)
	_spawn_terminal(hidden_pos, &"log_engine_room_note")
	print("[LevelRuntime] breakable wall broken at %s -> hidden terminal at %s" % [wall_pos, hidden_pos])

func _spawn_terminal(pos: Vector2, log_id: StringName) -> void:
	var term_wrapper: Node2D = Node2D.new()
	term_wrapper.position = pos
	add_child(term_wrapper)
	var term_area: Area2D = Area2D.new()
	term_wrapper.add_child(term_area)
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(48, 48)
	shape.shape = rect
	term_area.add_child(shape)
	# Visual: cyan square for terminal
	var visual: ColorRect = ColorRect.new()
	visual.position = Vector2(-24, -24)
	visual.size = Vector2(48, 48)
	visual.color = Color(0.2, 0.7, 0.9, 0.8)
	term_wrapper.add_child(visual)
	var label: Label = Label.new()
	label.text = _tr(&"ui.terminal.marker_label", "TERMINAL")
	label.position = Vector2(-30, -50)
	term_wrapper.add_child(label)
	# Wire up: body_entered opens the log via TerminalController
	term_area.body_entered.connect(_on_terminal_body_entered.bind(log_id))
	term_wrapper.set_meta("log_id", log_id)
	_terminals.append(term_wrapper)

func _on_terminal_body_entered(_body: Node, log_id: StringName) -> void:
	print("[LevelRuntime] terminal body entered! log_id=", log_id)
	var tc: Node = get_node_or_null("/root/TerminalController")
	if tc == null:
		return
	var reg: Node = get_node("/root/ResourceRegistry")
	var log: Resource = reg.get_resource(log_id)
	if log == null:
		return
	# Use the public method if it exists
	if tc.has_method("open_log"):
		tc.open_log(log)

func _process(_delta: float) -> void:
	var _sm: Node = get_node_or_null("/root/GameStateMachine")
	if _sm != null and _sm.is_paused():
		return
	# PR-10: Area2D body_entered unreliable in 4.6 — manual AABB check as fallback.
	# Wait until polling is enabled (after build_room settles)
	if not _polling_enabled:
		return
	# Scan all doors: if player center is inside door rect, trigger transition.
	if _doors.is_empty():
		return
	var player: Node = get_tree().get_root().find_child("Player", true, false)
	if player == null:
		return
	var pp: Vector2 = player.global_position
	for door in _doors:
		if door.has_meta("target_room") and not door.has_meta("consumed"):
			var dp: Vector2 = door.global_position
			# Door shape: Vector2(32, 96) centered
			var half: Vector2 = Vector2(16, 48)
			if abs(pp.x - dp.x) <= half.x and abs(pp.y - dp.y) <= half.y:
				print("[LevelRuntime] door trigger at %s" % dp)
				door.set_meta("consumed", true)
				var direction: String = String(door.get_meta("direction"))
				door_dir = "left" if direction == "right" else "right"
				build_room(int(door.get_meta("target_room")))
				return
	# Same for encounters
	for enc in _encounters:
		if enc.has_meta("triggered"):
			continue
		var ep: Vector2 = enc.global_position
		if abs(pp.x - ep.x) <= 24 and abs(pp.y - ep.y) <= 24:
			print("[LevelRuntime] encounter trigger at %s" % ep)
			enc.set_meta("triggered", true)
			enc.visible = false
			var sm: Node = get_node("/root/GameStateMachine")
			sm.transition_to(&"state_battle")
			return

# S6-019: small wrapper around Localization.tr() with English fallback.
# Use this anywhere you'd write a hardcoded UI string in level_runtime.
func _tr(key: StringName, fallback: String) -> String:
	var loc: Node = get_node_or_null("/root/Localization")
	if loc != null:
		return loc.tr(key)
	return fallback

func _on_encounter_body_entered(body: Node, enc: Node2D) -> void:
	if not body is PlayerController:
		return
	var enemy_id: StringName = StringName(enc.get_meta("enemy_id"))
	# PR-10: PR-11 — disable this encounter so the player can step off without re-triggering
	enc.set_meta("triggered", true)
	enc.visible = false
	enc.get_child(0).set_deferred("monitoring", false)  # disable Area2D collision
	# S5-006: tell BattleScene which enemy to spawn BEFORE the state
	# transition. The state_battle listener calls BattleScene._enter_battle()
	# which reads _pending_enemy_id. Without this, the boss fight in
	# room 9 was actually a scavenger (S4 boss encounter never propagated
	# its enemy id).
	var bs: Node = get_tree().get_root().find_child("BattleScene", true, false)
	if bs != null:
		bs._pending_enemy_id = enemy_id
	# PR-10: trigger battle via state transition
	var sm: Node = get_node("/root/GameStateMachine")
	sm.transition_to(&"state_battle")

# S6-009: floor tile grid. 1280/64=20 columns x 720/64=12 rows = 240 tiles.
# Each tile is a Sprite2D with the floor_main texture. Damaged tiles
# (small chance) use floor_damaged. All at z_index=-10 to render behind
# walls, player, doors, and HUD.
const _TILE_SIZE: int = 64
const _FLOOR_COLS: int = 20
const _FLOOR_ROWS: int = 12
const _FLOOR_DAMAGE_CHANCE: float = 0.08  # 8% of tiles damaged

func _build_tiled_floor() -> void:
	# S6-102: chapter-aware tile set. Ch1 = navy/orange, Ch2 = ice blue.
	var tile_dir: String = "res://assets/tilesets/"
	if level_data != null and "chapter_index" in level_data and int(level_data.chapter_index) == 2:
		tile_dir = "res://assets/tilesets/ch2/"
	var floor_main: Texture2D = load(tile_dir + "floor_main.png") as Texture2D
	if floor_main == null:
		floor_main = load("res://assets/tilesets/floor_main.png") as Texture2D
	var floor_damaged: Texture2D = load(tile_dir + "floor_damaged.png") as Texture2D
	if floor_damaged == null:
		floor_damaged = load("res://assets/tilesets/floor_damaged.png") as Texture2D
	var floor_warning: Texture2D = null
	if int(level_data.get("chapter_index") if level_data != null else 1) == 1:
		floor_warning = load("res://assets/tilesets/floor_warning.png") as Texture2D
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash("level_runtime_floor") ^ current_room_index
	for row in _FLOOR_ROWS:
		for col in _FLOOR_COLS:
			var tile: Sprite2D = Sprite2D.new()
			tile.position = Vector2(col * _TILE_SIZE, row * _TILE_SIZE)
			# Boss room (last): warning tiles. Otherwise pick damaged by chance.
			var total_rooms: int = level_data.get("room_ids").size()
			if current_room_index == total_rooms - 1 and (col + row) % 2 == 0:
				tile.texture = floor_warning
			elif rng.randf() < _FLOOR_DAMAGE_CHANCE:
				tile.texture = floor_damaged
			else:
				tile.texture = floor_main
			tile.z_index = -10
			add_child(tile)

# S6-009: decorative wall sprites. The collision shapes on _walls (added
# in build_room above) still drive physics. These sprites are positioned
# to match the collision extents so the visual and physical walls align.
func _build_wall_visuals() -> void:
	# S6-102: chapter-aware wall tiles
	var wall_path: String = "wall_industrial.png" if int(level_data.get("chapter_index") if level_data != null else 1) == 1 else "wall_ice.png"
	var wall_dmg_path: String = "wall_damaged.png" if int(level_data.get("chapter_index") if level_data != null else 1) == 1 else "wall_ice_damaged.png"
	var wall_tex: Texture2D = load("res://assets/tilesets/" + wall_path) as Texture2D
	if wall_tex == null:
		wall_tex = load("res://assets/tilesets/wall_industrial.png") as Texture2D
	var wall_dmg: Texture2D = load("res://assets/tilesets/" + wall_dmg_path) as Texture2D
	if wall_dmg == null:
		wall_dmg = load("res://assets/tilesets/wall_damaged.png") as Texture2D
	if wall_tex == null:
		return  # texture missing — fall back to invisible walls (still collidable)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash("level_runtime_walls") ^ current_room_index
	# Top wall: full strip across, at y=-16 (center), height 32. Tiles 20 wide.
	for col in _FLOOR_COLS:
		var tile: Sprite2D = Sprite2D.new()
		tile.position = Vector2(col * _TILE_SIZE, -16)
		tile.texture = wall_dmg if rng.randf() < 0.25 else wall_tex
		tile.z_index = -5  # in front of floor, behind doors/player
		add_child(tile)
	# Bottom wall
	for col in _FLOOR_COLS:
		var tile: Sprite2D = Sprite2D.new()
		tile.position = Vector2(col * _TILE_SIZE, 720 - _TILE_SIZE + 16)
		tile.texture = wall_dmg if rng.randf() < 0.25 else wall_tex
		tile.z_index = -5
		add_child(tile)
	# Left wall: 12 rows. Split into top half (rows 0-4) and bottom half (rows 7-11)
	# to leave a 96px gap at the door y range 312..408 (rows 5-6).
	var left_door_exists: bool = current_room_index > 0
	for row in _FLOOR_ROWS:
		var in_door_gap: bool = left_door_exists and row >= 5 and row <= 6
		if in_door_gap:
			continue
		var tile_l: Sprite2D = Sprite2D.new()
		tile_l.position = Vector2(-16, row * _TILE_SIZE)
		tile_l.texture = wall_dmg if rng.randf() < 0.25 else wall_tex
		tile_l.z_index = -5
		add_child(tile_l)
	# Right wall: same split logic
	var total_rooms: int = level_data.get("room_ids").size()
	var right_door_exists: bool = current_room_index < total_rooms - 1
	for row in _FLOOR_ROWS:
		var in_door_gap: bool = right_door_exists and row >= 5 and row <= 6
		if in_door_gap:
			continue
		var tile_r: Sprite2D = Sprite2D.new()
		tile_r.position = Vector2(1280 - _TILE_SIZE + 16, row * _TILE_SIZE)
		tile_r.texture = wall_dmg if rng.randf() < 0.25 else wall_tex
		tile_r.z_index = -5
		add_child(tile_r)

func clear_room() -> void:
	# PR-10: only remove room-content children (Floor, Walls, Doors, Encounters).
	# Keep Player, Camera, BattleScene, HUD, MainMenu, PauseMenu, UI etc. as siblings.
	var preserve: Array[StringName] = [&"Player", &"Camera", &"BattleScene", &"HUD", &"SaveUI", &"CodexUI", &"TerminalUI", &"DialogueUI", &"MainMenu", &"PauseMenu"]
	for child in get_children():
		if child.name in preserve:
			continue
		child.queue_free()
	_doors.clear()
	_encounters.clear()
	_npcs.clear()
	_terminals.clear()

# S3-004: C key opens Codex in exploration. C again / Esc closes.
func _unhandled_input(event: InputEvent) -> void:
	var sm: Node = get_node_or_null("/root/GameStateMachine")
	if sm == null:
		return
	# Soft-pause guard: don't react when paused/menu/title/codex itself
	if sm.is_paused() and sm.top_of_stack != &"state_exploration":
		return
	var top: StringName = sm.top_of_stack
	if event.is_action_pressed("codex") or (event is InputEventKey and event.keycode == KEY_C and event.pressed):
		if top == &"state_codex":
			# Close codex
			sm.transition_to(&"state_exploration")
		elif top == &"state_exploration":
			# Open codex
			sm.transition_to(&"state_codex")
		get_viewport().set_input_as_handled()
	# S4-002: Q cycles active mech part. Only in exploration (not in
	# pause/menu/dialogue/battle) — InputBus always-dispatch not used, so
	# this naturally gates.
	elif event.is_action_pressed("mech_cycle") or (event is InputEventKey and event.keycode == KEY_Q and event.pressed):
		if top == &"state_exploration":
			var mech: Node = get_node("/root/MechLoadout")
			var cycled: Dictionary = mech.cycle_equipped_part()
			print("[LevelRuntime] mech_cycle -> slot=%s part=%s" % [cycled["slot"], cycled["part_id"]])
			# Notify HUD via signal
			var hud: Node = get_tree().get_root().find_child("HUD", true, false)
			if hud != null and hud.has_method("_on_mech_cycled"):
				hud._on_mech_cycled(cycled["slot"], cycled["part_id"])
		get_viewport().set_input_as_handled()
