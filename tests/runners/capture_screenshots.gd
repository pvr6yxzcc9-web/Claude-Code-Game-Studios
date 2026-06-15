extends Node

# S6-018: Auto-screenshot capture script
#
# Walks the main scene through 6 key moments and saves viewport
# screenshots to production/store/screenshots/ as 1920x1080 PNGs.
#
# This script does NOT require a real F5 in the editor — it runs
# headlessly (or in editor) and uses Godot's viewport screenshot API.
#
# Run from project root:
#   godot --headless --script tests/runners/capture_screenshots.gd
#
# Captures:
#   01_title.png          — Main menu with title bg art
#   02_exploration.png    — Mech in room 0, full HUD visible
#   03_combat.png         — Battle scene with HP bars + damage popup
#   04_boss.png           — Boss fight (Marrow Sentinel)
#   05_codex.png          — Codex menu open with fragments
#   06_ending.png         — state_game over screen (proxy for ending)
#
# Notes:
#   - Actual UI text rendering in headless mode is limited (no fonts),
#     so screenshots may have placeholder text. Run in windowed mode
#     for real screenshots.
#   - This script is the automation; F5-with-screenshot is the
#     real-capture path for the Steam/itch.io pages.

const OUT_DIR: String = "res://production/store/screenshots/"

# Each capture is (filename, description, callable that sets up the scene)
var _captures: Array = []

func _ready() -> void:
	print("\n=== S6-018: Auto-screenshot capture ===\n")
	await get_tree().process_frame
	await get_tree().process_frame

	# Verify autoloads present
	var sm: Node = get_node_or_null("/root/GameStateMachine")
	if sm == null:
		push_error("GameStateMachine autoload missing — run via main.tscn")
		get_tree().quit(1)
		return

	# Define captures (deferred — callables are set up below)
	_captures = [
		{"name": "01_title.png", "label": "Title screen", "setup": _setup_title},
		{"name": "02_exploration.png", "label": "Exploration", "setup": _setup_exploration},
		{"name": "03_combat.png", "label": "Combat", "setup": _setup_combat},
		{"name": "04_boss.png", "label": "Boss fight", "setup": _setup_boss},
		{"name": "05_codex.png", "label": "Codex", "setup": _setup_codex},
		{"name": "06_ending.png", "label": "Ending", "setup": _setup_ending},
	]

	var success: int = 0
	for cap in _captures:
		var name: String = cap["name"]
		var label: String = cap["label"]
		var setup_callable: Callable = cap["setup"]
		print("  [%d/%d] %s -> %s" % [_captures.find(cap) + 1, _captures.size(), label, name])
		setup_callable.call()
		# Trigger damage popup for combat / boss after the transition settles
		if name in ["03_combat.png", "04_boss.png"]:
			var bs2: Node = get_tree().get_root().find_child("BattleScene", true, false)
			if bs2 != null:
				if name == "03_combat.png":
					bs2._spawn_damage_popup(15, false)
				else:
					bs2._spawn_damage_popup(28, true)
		await get_tree().process_frame
		await get_tree().process_frame
		# Wait one more frame to let everything settle
		await get_tree().process_frame
		if _capture_viewport(name):
			success += 1
			print("       OK")
		else:
			print("       FAIL")
		# Restore between captures
		_restore()

	print("\n=== Summary: %d/%d captures saved to %s ===" % [success, _captures.size(), OUT_DIR])
	if success == _captures.size():
		print("All screenshots captured successfully.")
		if DisplayServer.get_name() == "headless":
			get_tree().quit(0)
	else:
		print("Some captures failed. See errors above.")
		if DisplayServer.get_name() == "headless":
			get_tree().quit(1)

# === Capture helper ===

func _capture_viewport(filename: String) -> bool:
	# Try multiple paths to get the viewport
	var img: Image = null
	# Path 1: standard get_viewport().get_texture().get_image()
	var vp: Viewport = get_viewport()
	if vp != null:
		var tex: ViewportTexture = vp.get_texture()
		if tex != null:
			img = tex.get_image()
	if img == null:
		push_warning("  could not get viewport image (headless mode may lack GPU)")
		return false
	# Save
	var out_path: String = OUT_DIR + filename
	var abs_path: String = ProjectSettings.globalize_path(out_path)
	# Ensure dir exists
	var dir_path: String = out_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
	var err: int = img.save_png(out_path)
	if err != OK:
		push_error("  save_png failed for %s (err=%d)" % [out_path, err])
		return false
	print("       saved: %s (%dx%d, %d bytes)" % [out_path, img.get_width(), img.get_height(), FileAccess.get_size(out_path) if FileAccess.file_exists(out_path) else -1])
	return true

# === Setup helpers ===

func _setup_title() -> void:
	# MainMenu is hidden by default — show it
	var menu: Node = get_tree().get_root().find_child("MainMenu", true, false)
	if menu != null:
		menu.show()
	# Hide other overlays
	_hide_overlays()

func _setup_exploration() -> void:
	var sm: Node = get_node("/root/GameStateMachine")
	sm.transition_to(&"state_exploration")
	var runtime: Node = get_tree().get_root().find_child("Main", true, false)
	if runtime != null and runtime.has_method("build_room"):
		runtime.build_room(0)
	_hide_overlays()

func _setup_combat() -> void:
	var sm: Node = get_node("/root/GameStateMachine")
	var bs: Node = get_tree().get_root().find_child("BattleScene", true, false)
	if bs != null:
		bs._pending_enemy_id = &"scavenger"
		# Pre-set HP to 60/100 so the HP bar is visible
		bs._player_hp = 60
		bs._enemy_hp = 45
	sm.transition_to(&"state_battle")
	# Damage popup triggered after the loop's settle frames
	# Hide pause menu and main menu
	_hide_overlays()

func _setup_boss() -> void:
	var sm: Node = get_node("/root/GameStateMachine")
	var bs: Node = get_tree().get_root().find_child("BattleScene", true, false)
	if bs != null:
		bs._pending_enemy_id = &"boss_marrow_sentinel"
		bs._player_hp = 75
		bs._enemy_hp = 200
	sm.transition_to(&"state_battle")
	_hide_overlays()

func _setup_codex() -> void:
	var sm: Node = get_node("/root/GameStateMachine")
	# Unlock a few fragments for the codex to display
	var meta: Node = get_node("/root/MetaState")
	if meta != null and meta.has_method("unlock"):
		for fid in [&"fragment_the_convoy", &"fragment_marlows_daughter", &"fragment_the_seal"]:
			meta.unlock(fid)
	sm.transition_to(&"state_codex")
	_hide_overlays()

func _setup_ending() -> void:
	var sm: Node = get_node("/root/GameStateMachine")
	sm.transition_to(&"state_game over")
	_hide_overlays()

func _hide_overlays() -> void:
	var menu: Node = get_tree().get_root().find_child("MainMenu", true, false)
	if menu != null:
		menu.hide()
	var pause: Node = get_tree().get_root().find_child("PauseMenu", true, false)
	if pause != null:
		pause.hide()

func _restore() -> void:
	# Reset state to a clean baseline
	var sm: Node = get_node("/root/GameStateMachine")
	if sm != null and sm.top_of_stack != &"state_exploration":
		# Find a legal transition
		if sm.ALLOWED_TRANSITIONS[sm.top_of_stack].has(&"state_exploration"):
			sm.transition_to(&"state_exploration")
		elif sm.ALLOWED_TRANSITIONS[sm.top_of_stack].has(&"state_title"):
			sm.transition_to(&"state_title")
	# Hide overlays again
	_hide_overlays()
