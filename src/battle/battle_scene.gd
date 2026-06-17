extends Control

# BattleScene (per battle-core-loop.md) — Label-based, no _draw (avoids Godot 4.6 HiDPI crash).
# Listens for state_battle, displays enemy info + player HP, attacks via 1/2/3.

signal battle_resolved(victory: bool, damage_dealt: int, damage_taken: int)

var in_battle: bool = false
var _enemy: Resource = null
var _enemy_hp: int = 0
var _player_hp: int = 100
# Set by encounter_tile before triggering state_battle. Consumed by
# _enter_battle(). S5-006 fix — without this, every encounter defaulted
# to scavenger because the S4 boss encounter never passed an id.
var _pending_enemy_id: StringName = &""

# S6-003: visual feedback state
var _enemy_visual: TextureRect  # displays the enemy sprite
var _enemy_base_modulate: Color = Color.WHITE
var _hit_flash_timer: SceneTreeTimer = null

# UI elements
var _bg: ColorRect
var _bg_sprite: TextureRect  # S14-002: satellite-themed background image
var _title_label: Label
var _enemy_name: Label
var _enemy_hp_label: Label
var _player_hp_label: Label
var _instr1: Label
var _instr2: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	hide()
	# S14-002: satellite background image (loaded dynamically by chapter)
	_bg_sprite = TextureRect.new()
	_bg_sprite.name = "bg_sprite"
	_bg_sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_sprite.stretch_mode = TextureRect.STRETCH_SCALE
	_bg_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(_bg_sprite)
	# Background overlay (darkens the sprite for legibility)
	_bg = ColorRect.new()
	_bg.color = Color(0, 0, 0, 0.55)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)
	# Title
	_title_label = Label.new()
	var loc: Node = get_node_or_null("/root/Localization")
	_title_label.text = loc.t(&"ui.battle.title") if loc != null else "IN BATTLE"
	_title_label.position = Vector2(540, 200)
	_title_label.add_theme_font_size_override("font_size", 48)
	_title_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
	add_child(_title_label)
	# S6-003: enemy visual (sprite or placeholder ColorRect). The TextureRect
	# is large and centered; modulate is what we flash on hit.
	_enemy_visual = TextureRect.new()
	_enemy_visual.position = Vector2(540, 80)
	_enemy_visual.size = Vector2(200, 200)
	_enemy_visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_enemy_visual.modulate = Color.WHITE
	add_child(_enemy_visual)
	# Enemy info
	_enemy_name = Label.new()
	_enemy_name.position = Vector2(490, 280)
	_enemy_name.add_theme_font_size_override("font_size", 28)
	add_child(_enemy_name)
	_enemy_hp_label = Label.new()
	_enemy_hp_label.position = Vector2(540, 320)
	_enemy_hp_label.add_theme_font_size_override("font_size", 24)
	_enemy_hp_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4, 1))
	add_child(_enemy_hp_label)
	# Player HP
	_player_hp_label = Label.new()
	_player_hp_label.position = Vector2(540, 400)
	_player_hp_label.add_theme_font_size_override("font_size", 24)
	_player_hp_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4, 1))
	add_child(_player_hp_label)
	# Instructions
	_instr1 = Label.new()
	_instr1.text = loc.t(&"ui.battle.instr_attack") if loc != null else "Press 1/2/3 to attack"
	_instr1.position = Vector2(380, 500)
	_instr1.add_theme_font_size_override("font_size", 20)
	_instr1.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	add_child(_instr1)
	_instr2 = Label.new()
	_instr2.text = loc.t(&"ui.battle.instr_flee") if loc != null else "Press Esc to flee"
	_instr2.position = Vector2(360, 540)
	_instr2.add_theme_font_size_override("font_size", 20)
	_instr2.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	add_child(_instr2)
	# Listeners
	var sm: Node = get_node("/root/GameStateMachine")
	sm.state_changed.connect(_on_state_changed)
	set_process_unhandled_input(true)
	var loadout: Node = get_node_or_null("/root/WeaponLoadout")
	if loadout != null:
		loadout.attack_triggered.connect(on_player_attack)
	print("[BattleScene] ready (stub)")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		if in_battle:
			var sm: Node = get_node("/root/GameStateMachine")
			sm.transition_to(&"state_exploration")
			get_viewport().set_input_as_handled()

func _on_state_changed(_old: StringName, new: StringName) -> void:
	if new == &"state_battle":
		_enter_battle()
	elif _old == &"state_battle" and new == &"state_exploration":
		in_battle = false
		hide()
	# S4-007: if AUTO mode is on when battle ends, stop the AI timer.
	if _old == &"state_battle" and new != &"state_battle":
		var loadout: Node = get_node_or_null("/root/WeaponLoadout")
		if loadout != null and loadout.has_method("set_auto_mode") and loadout.is_auto_mode():
			loadout.set_auto_mode(false)

func _enter_battle() -> void:
	in_battle = true
	show()
	var reg: Node = get_node("/root/ResourceRegistry")
	# Pick the enemy: if a previous encounter tile set the pending id, use it
	# (per S4-007 contract). Otherwise fall back to scavenger (the
	# original "always scavenger" default from PR-3 — the S4 boss
	# encounter was a "set the pending id" call that this code never
	# actually read, so every encounter was a scavenger until S5-006).
	if _pending_enemy_id != &"":
		_enemy = reg.get_resource(_pending_enemy_id)
		_pending_enemy_id = &""  # consume
	else:
		_enemy = reg.get_resource(&"scavenger")
	if _enemy == null:
		push_error("BattleScene: enemy 'scavenger' not found in registry")
		return
	# S6-003: load enemy sprite if available; fall back to colored rect
	# if sprite not yet painted.
	var sprite_path: String = "res://assets/sprites/enemies/%s.png" % _enemy.get("id")
	if ResourceLoader.exists(sprite_path):
		_enemy_visual.texture = load(sprite_path)
	else:
		# Fallback: a colored square so the visual is never blank
		# (caller can always ship without final art).
		var img: Image = Image.create(200, 200, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.5, 0.2, 0.2, 1.0))
		_enemy_visual.texture = ImageTexture.create_from_image(img)
	_enemy_base_modulate = Color.WHITE
	_enemy_visual.modulate = _enemy_base_modulate
	_enemy_hp = int(_enemy.get("max_hp"))
	_load_battle_background(String(_enemy.get("id", "")))
	_refresh()
	print("[BattleScene] encounter started: %s (HP=%d)" % [_enemy.get("display_name"), _enemy_hp])
	var hud: Node = get_tree().get_root().find_child("HUD", true, false)
	if hud != null and hud.has_method("set_mode"):
		hud.set_mode("MANUAL")
	if hud != null and hud.has_method("set_hp"):
		hud.set_hp(_player_hp, 100)

func _refresh() -> void:
	if _enemy != null:
		_enemy_name.text = String(_enemy.get("display_name"))
		var loc: Node = get_node_or_null("/root/Localization")
		var enemy_fmt: String = loc.t(&"ui.battle.enemy_hp") if loc != null else "HP: %d"
		_enemy_hp_label.text = enemy_fmt % _enemy_hp
	var loc2: Node = get_node_or_null("/root/Localization")
	var player_fmt: String = loc2.t(&"ui.battle.player_hp") if loc2 != null else "Player HP: %d"
	_player_hp_label.text = player_fmt % _player_hp

func on_player_attack(slot: int) -> void:
	if not in_battle:
		return
	var loadout: Node = get_node("/root/WeaponLoadout")
	var weapon: Resource = loadout.get_active_weapon()
	if weapon == null:
		return
	var wmin: int = int(weapon.get("min_damage"))
	var wmax: int = int(weapon.get("max_damage"))
	var crit_chance: float = float(weapon.get("crit_chance"))
	var crit_mult: float = float(weapon.get("crit_multiplier"))
	var ammo: Resource = loadout.get_active_ammo()
	var ammo_mult: float = 1.0
	if ammo != null:
		ammo_mult = float(ammo.get("damage_mult"))
	var is_crit: bool = randf() < crit_chance
	var raw_damage: int = BattleMathLib.compute_base_damage(wmin, wmax, ammo_mult, is_crit, crit_mult)
	# S5-002/003/004: schema consumer wiring. Fold effect/weakness/weapon
	# bonuses into raw damage BEFORE boss immunity clamp.
	raw_damage += BattleMathLib.apply_ammo_effect_bonus(ammo)
	raw_damage = BattleMathLib.apply_weakness_resistance(raw_damage, weapon, ammo, _enemy)
	raw_damage = BattleMathLib.apply_weapon_effects_bonus(raw_damage, weapon)
	print("[BattleScene] attack: raw=%d crit=%s" % [raw_damage, is_crit])
	var boss: bool = bool(_enemy.get("boss"))
	var boss_immune: bool = bool(_enemy.get("boss_immune_to_one_shot"))
	var boss_hp: int = int(_enemy.get("max_hp"))
	raw_damage = BattleMathLib.apply_boss_immunity(raw_damage, boss_hp, boss_immune)
	_enemy_hp -= raw_damage
	print("[BattleScene] enemy HP: %d -> %d" % [_enemy_hp + raw_damage, _enemy_hp])
	# S6-003: hit feedback — flash + damage popup + camera shake
	_flash_enemy()
	_spawn_damage_popup(raw_damage, is_crit)
	_shake_camera(2.0 if is_crit else 1.0, 0.10 if is_crit else 0.06)
	# S6-101: muzzle flash at player position + hit sparks at enemy position
	var pfx: Node = get_node_or_null("/root/ParticleFx")
	if pfx != null:
		var player: Node = get_tree().get_root().find_child("Player", true, false)
		if player != null:
			pfx.spawn_muzzle_flash(player.global_position)
		if _enemy_visual != null:
			pfx.spawn_hit_spark(_enemy_visual.global_position)
	var sfx: Node = get_node_or_null("/root/SFXPlayer")
	if sfx != null and sfx.has_method("play_attack"):
		# S6-010: pass weapon id so SFXPlayer can pick the right .wav
		# (railgun/rail → railgun shot, plasma/cannon → plasma shot, else blaster)
		sfx.play_attack(slot, loadout.weapon_slots[slot])
	_refresh()
	if _enemy_hp <= 0:
		# S6-003: kill feedback — stronger shake
		_shake_camera(4.0, 0.30)
		_resolve_battle(true, raw_damage, 0)
		return
	var enemy_attack: int = int(_enemy.get("attack"))
	var enemy_accuracy: float = float(_enemy.get("accuracy"))
	if BattleMathLib.roll_accuracy(enemy_accuracy):
		_player_hp -= enemy_attack
		print("[BattleScene] player HP: %d -> %d (took %d)" % [_player_hp + enemy_attack, _player_hp, enemy_attack])
		# S6-003: player taking damage also gets a camera shake (smaller
		# than enemy kill shake, larger than non-crit hit shake)
		_shake_camera(1.5, 0.10)
		if sfx != null and sfx.has_method("play_damage"):
			sfx.play_damage()
		_refresh()
		var hud2: Node = get_tree().get_root().find_child("HUD", true, false)
		if hud2 != null and hud2.has_method("set_hp"):
			hud2.set_hp(_player_hp, 100)
		if _player_hp <= 0:
			# S6-004: player death transitions to state_game over instead
			# of resolving battle as a loss. The DeathScreen takes over
			# from there (retry/quit).
			print("[BattleScene] player died in battle")
			battle_resolved.emit(false, raw_damage, enemy_attack)
			in_battle = false
			hide()
			var sm: Node = get_node("/root/GameStateMachine")
			sm.transition_to(&"state_game over")
			return

func _resolve_battle(victory: bool, dmg_dealt: int, dmg_taken: int) -> void:
	print("[BattleScene] battle resolved: victory=%s dealt=%d taken=%d" % [victory, dmg_dealt, dmg_taken])
	battle_resolved.emit(victory, dmg_dealt, dmg_taken)
	if not victory:
		var save: Node = get_node("/root/SaveManager")
		var err: int = save.get_autosave()
		if err != OK:
			push_warning("BattleScene: no autosave to reload from")
		var sm: Node = get_node("/root/GameStateMachine")
		sm.transition_to(&"state_exploration")
		in_battle = false
		hide()
		return
	# S4-009: victory against a boss triggers an ending (replaces the
	# normal return to exploration). Non-boss victories go to exploration.
	if _enemy != null and bool(_enemy.get("boss")):
		# S5-005: unlock the 3 boss-victory fragments BEFORE determining
		# ending. Mark_unlocked is idempotent (no-op if already unlocked).
		var meta: Node = get_node_or_null("/root/MetaState")
		if meta != null:
			meta.mark_unlocked(&"fragment_what_was_carried")
			meta.mark_unlocked(&"fragment_the_truth")
			meta.mark_unlocked(&"fragment_engineer_last_stand")
		# S6-105: stop speedrun timer on boss victory. Records final
		# time + updates best-time per chapter if faster.
		var st: Node = get_node_or_null("/root/SpeedrunTimer")
		if st != null and st.is_running():
			var elapsed: int = st.stop_run()
			print("[BattleScene] boss defeated in %d ms (best? %s)" % [elapsed, st.was_last_run_best()])
		var ec: Node = get_node_or_null("/root/EndingController")
		if ec != null and ec.has_method("play_ending"):
			var err2: int = ec.play_ending()
			if err2 == OK:
				# EndingController transitioned into state_dialogue
				# (via DialogueManager). Mark battle done; the dialogue
				# tree is now the active state. Player can read ending
				# text; closing dialogue returns to exploration.
				in_battle = false
				hide()
				return
	# Default: victory against non-boss returns to exploration
	var sm2: Node = get_node("/root/GameStateMachine")
	sm2.transition_to(&"state_exploration")
	in_battle = false
	hide()

# === S6-003: Combat feedback helpers ===

# Flash the enemy visual white for a brief moment, then restore.
func _flash_enemy() -> void:
	if _enemy_visual == null:
		return
	_enemy_visual.modulate = Color(2.0, 2.0, 2.0, 1.0)  # overbright white
	if _hit_flash_timer != null and _hit_flash_timer.timeout.is_connected(_unflash_enemy):
		_hit_flash_timer.timeout.disconnect(_unflash_enemy)
	_hit_flash_timer = get_tree().create_timer(0.08)
	_hit_flash_timer.timeout.connect(_unflash_enemy)

func _unflash_enemy() -> void:
	if _enemy_visual != null:
		_enemy_visual.modulate = _enemy_base_modulate

# Spawn a damage number popup at the enemy position, animate up + fade.
func _spawn_damage_popup(damage: int, is_crit: bool) -> void:
	if _enemy_visual == null:
		return
	var popup: Label = Label.new()
	var loc: Node = get_node_or_null("/root/Localization")
	var crit_prefix: String = (loc.t(&"ui.battle.crit_popup") if loc != null else "CRIT %d")
	# Only use the prefix for crits; non-crit is just the number
	if is_crit:
		# crit_popup is "CRIT %d" in English — split off the number for the popup
		var prefix_only: String = "CRIT " if loc == null else loc.t(&"ui.battle.crit_prefix")
		popup.text = prefix_only + str(damage)
	else:
		popup.text = str(damage)
	popup.add_theme_font_size_override("font_size", 28 if is_crit else 22)
	var color: Color = Color(1, 0.85, 0.2) if is_crit else Color(1, 1, 1)
	popup.add_theme_color_override("font_color", color)
	popup.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	popup.add_theme_constant_override("outline_size", 4)
	# Position at enemy center, slightly offset so consecutive numbers stack
	var base_pos: Vector2 = _enemy_visual.position + _enemy_visual.size * 0.5
	popup.position = base_pos + Vector2(randf_range(-20, 20), -10)
	popup.pivot_offset = popup.size * 0.5
	add_child(popup)
	# Animate up + fade out over 0.7s
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position", popup.position + Vector2(0, -60), 0.7)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "modulate:a", 0.0, 0.7)\
		.set_trans(Tween.TRANS_LINEAR)
	tween.chain().tween_callback(popup.queue_free)

# Camera shake. amount is pixels of displacement, duration is seconds.
# Uses the existing Camera2D if available; degrades silently if no camera.
func _shake_camera(amount: float, duration: float) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	var original: Vector2 = camera.offset
	var tween: Tween = create_tween()
	var steps: int = 6
	for i in steps:
		var offset: Vector2 = Vector2(
			randf_range(-amount, amount),
			randf_range(-amount, amount)
		)
		var t: float = duration / steps
		tween.tween_property(camera, "offset", original + offset, t)\
			.set_trans(Tween.TRANS_SINE)
	# Final reset
	tween.tween_property(camera, "offset", original, 0.05)

# S14-002: load satellite-themed battle background based on enemy id
# Pattern: ch1_*, ch2_*, ch3_*, ch4_*, ch5_* → bg_sat1..5.png
# Default to bg_sat1 if no match.
func _load_battle_background(enemy_id: String) -> void:
	if _bg_sprite == null:
		return
	var sat: int = 1  # default
	if enemy_id.begins_with("ch2_") or enemy_id.begins_with("boss_marrow"):
		sat = 2
	elif enemy_id.begins_with("ch3_") or enemy_id.begins_with("boss_hive"):
		sat = 3
	elif enemy_id.begins_with("ch4_") or enemy_id.begins_with("boss_pluto"):
		sat = 4
	elif enemy_id.begins_with("ch5_") or enemy_id.begins_with("boss_creator"):
		sat = 5
	var bg_path: String = "res://assets/sprites/battle/bg_sat%d.png" % sat
	if ResourceLoader.exists(bg_path):
		_bg_sprite.texture = load(bg_path)
	else:
		_bg_sprite.texture = null

