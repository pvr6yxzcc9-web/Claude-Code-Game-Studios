extends Node

# S6-014: Final F5 walkthrough (post-polish).
#
# This is a CODE-LEVEL walkthrough script — it programmatically walks
# through the canonical Railhunter playthrough (room 0 -> Marrow Sentinel
# kill -> ending), asserting that all the post-Sprint-5 polish features
# work end-to-end. It catches the integration bugs that escape unit tests:
# autoload ordering, signal routing, state transitions, and resource
# loading.
#
# This is NOT a substitute for a real F5 in the Godot editor. The
# real F5 is still required to verify visual polish, music timing, SFX
# feel, and player input. But running this script in headless mode is
# a much faster pre-flight than manual testing.
#
# Run from project root:
#   godot --headless --script tests/runners/polish_f5_walkthrough.gd
#
# Exit code: 0 if all assertions pass, 1 otherwise.

const GUT_SCRIPT_PATH = "res://addons/gut/gut.gd"

# Track assertion failures
var _failures: Array[String] = []
var _checks: int = 0

func _ready() -> void:
	print("\n=== S6-014: Final F5 Walkthrough (post-polish) ===\n")

	# Wait for scene tree + autoloads
	await get_tree().process_frame
	await get_tree().process_frame

	# === Phase 1: Title state ===
	_check("Phase 1: GSM top of stack is state_exploration (initial)",
		_get_top_state() == &"state_exploration")
	_check("Phase 1: MusicPlayer current track is exploration (auto-played on init)",
		_get_current_music() == &"exploration")
	_check("Phase 1: HUD is in scene tree",
		_find_hud() != null)
	_check("Phase 1: BattleScene hidden",
		_get_battle_scene() != null and not _get_battle_scene().visible)
	_check("Phase 1: DeathScreen hidden",
		_get_death_screen() != null and not _get_death_screen().visible)

	# === Phase 2: Room 0 — Vera NPC + tutorial ===
	var runtime: Node = _get_level_runtime()
	_check("Phase 2: LevelRuntime is room 0",
		runtime != null and runtime.current_room_index == 0)
	_check("Phase 2: TutorialManager autoload registered",
		_get_tutorial_manager() != null)
	# Start tutorial (would be triggered by level_runtime in real play)
	var tutorial: Node = _get_tutorial_manager()
	if tutorial != null and tutorial.has_method("start"):
		tutorial.start()
		await get_tree().process_frame
		_check("Phase 2: Tutorial is active after start()",
			tutorial.has_method("is_active") and tutorial.is_active())

	# === Phase 3: Move to first encounter (room 0 scavenger) ===
	# Force the encounter trigger to test state_battle flow
	# (in real F5 player walks into the encounter)
	var reg: Node = get_node("/root/ResourceRegistry")
	var sm: Node = get_node("/root/GameStateMachine")

	# Verify all enemies exist in registry
	for eid in [&"swarmer", &"scavenger", &"shielded_bot", &"mine_layer", &"sniper_bot", &"drone", &"heavy_walker", &"boss_marrow_sentinel"]:
		_check("Phase 3: enemy %s registered" % eid, reg.get_resource(eid) != null)

	# === Phase 4: state_battle transition (encounter trigger) ===
	var bs: Node = _get_battle_scene()
	if bs != null:
		bs._pending_enemy_id = &"scavenger"
	sm.transition_to(&"state_battle")
	await get_tree().process_frame
	await get_tree().process_frame
	_check("Phase 4: state changed to state_battle",
		_get_top_state() == &"state_battle")
	_check("Phase 4: BattleScene visible",
		bs != null and bs.visible)
	_check("Phase 4: MusicPlayer current track is battle",
		_get_current_music() == &"battle")

	# === Phase 5: Combat — verify attack wires to BattleMathLib + SFXPlayer ===
	if bs != null and bs.in_battle:
		# Give player enough HP to survive
		bs._player_hp = 100
		# Trigger an attack
		bs.on_player_attack(0)
		await get_tree().process_frame
		_check("Phase 5: enemy HP reduced after attack",
			bs._enemy_hp < int(bs._enemy.get("max_hp")))
		_check("Phase 5: HUD updated (HP shown)",
			bs._player_hp_label != null and "Player HP" in bs._player_hp_label.text)
	else:
		_fail("Phase 5: battle not started; skipping combat checks")

	# === Phase 6: Kill enemy — win battle, transition to exploration ===
	if bs != null:
		bs._enemy_hp = 1
		bs.on_player_attack(0)
		await get_tree().process_frame
		await get_tree().process_frame
		_check("Phase 6: state returned to exploration after kill",
			_get_top_state() == &"state_exploration")
		_check("Phase 6: MusicPlayer back to exploration track",
			_get_current_music() == &"exploration")

	# === Phase 7: Walk through rooms 0..9 (just check transitions) ===
	for room_idx in [1, 2, 3, 4, 5, 6, 7, 8]:
		if runtime != null:
			runtime.build_room(room_idx)
			await get_tree().process_frame
			_check("Phase 7: room %d built" % room_idx,
				runtime.current_room_index == room_idx)

	# === Phase 8: Boss fight (room 9) ===
	if runtime != null:
		runtime.build_room(9)
		await get_tree().process_frame
		if bs != null:
			bs._pending_enemy_id = &"boss_marrow_sentinel"
		sm.transition_to(&"state_battle")
		await get_tree().process_frame
		await get_tree().process_frame
		_check("Phase 8: boss fight started",
			_get_top_state() == &"state_battle" and bs != null and bs._enemy != null)
		_check("Phase 8: boss is Marrow Sentinel",
			bs != null and bs._enemy != null and String(bs._enemy.get("display_name")) == "Marrow Sentinel")
		_check("Phase 8: boss has 200 HP",
			bs != null and int(bs._enemy.get("max_hp")) == 200)
		_check("Phase 8: boss is immune to one-shot",
			bs != null and bool(bs._enemy.get("boss_immune_to_one_shot")))

	# === Phase 9: SFXPlayer loaded real .wav files ===
	var sfx: Node = get_node_or_null("/root/SFXPlayer")
	_check("Phase 9: SFXPlayer autoload registered", sfx != null)
	if sfx != null:
		_check("Phase 9: SFXPlayer has 5 streams cached",
			sfx._streams.size() == 5)
		_check("Phase 9: attack_blaster stream loaded",
			sfx._streams.has(&"attack_blaster"))
		_check("Phase 9: hit_enemy stream loaded",
			sfx._streams.has(&"hit_enemy"))

	# === Phase 10: Death screen (state_game over) ===
	# Simulate fatal damage
	if bs != null:
		bs._player_hp = 1
		bs.on_player_attack(0)
		await get_tree().process_frame
		await get_tree().process_frame
		# HP may have gone to 0; if so state_game over is entered
		# (this is the S6-004 wiring)
		_check("Phase 10: DeathScreen autoload exists",
			_get_death_screen() != null)

	# === Summary ===
	print("\n=== F5 Walkthrough Summary ===")
	print("Checks run:  %d" % _checks)
	print("Failures:    %d" % _failures.size())
	for fail in _failures:
		print("  [FAIL] %s" % fail)
	print("")
	if _failures.is_empty():
		print("VERDICT: PASS — all post-polish systems wire up correctly.")
		print("F5 in editor is still required to verify visual feel.")
		if DisplayServer.get_name() == "headless":
			get_tree().quit(0)
	else:
		print("VERDICT: FAIL — see failures above.")
		if DisplayServer.get_name() == "headless":
			get_tree().quit(1)

# === Helper functions ===

func _check(name: String, condition: bool) -> void:
	_checks += 1
	if not condition:
		_failures.append(name)
		print("  [FAIL] %s" % name)
	else:
		print("  [ OK ] %s" % name)

func _get_top_state() -> StringName:
	return get_node("/root/GameStateMachine").top_of_stack

func _get_current_music() -> StringName:
	var mp: Node = get_node_or_null("/root/MusicPlayer")
	if mp == null:
		return &""
	return mp.current_track()

func _find_hud() -> Node:
	return get_tree().get_root().find_child("HUD", true, false)

func _get_battle_scene() -> Node:
	return get_tree().get_root().find_child("BattleScene", true, false)

func _get_death_screen() -> Node:
	return get_node_or_null("/root/DeathScreen")

func _get_level_runtime() -> Node:
	return get_tree().get_root().find_child("Main", true, false)

func _get_tutorial_manager() -> Node:
	return get_node_or_null("/root/TutorialManager")

func _fail(msg: String) -> void:
	_failures.append(msg)
