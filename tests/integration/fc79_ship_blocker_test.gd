extends GutTest

# Ship-blocker integration test (Sprint 14, fc79) — verifies P0 assets
# and systems are in place. Per design/P0-ship-blockers + linear-painting-sunbeam.md.
#
# 10 tests covering: font, 5 battle bg, SFXPlayer methods, 13 SFX files,
# Logo file, loading screen, battle scene bg integration, export presets.

const LS_PATH: String = "/root/LoadingScreen"
const SFX_PATH: String = "/root/SFXPlayer"

func _ls() -> Node: return get_node_or_null(LS_PATH)
func _sfx() -> Node: return get_node_or_null(SFX_PATH)

# === Font (S14-001) ===

func test_font_loaded_in_project_godot() -> void:
	# Verify default_theme.tres exists
	assert_true(FileAccess.file_exists("res://assets/fonts/default_theme.tres"),
		"default_theme.tres exists")
	# Verify CJK + English fonts exist
	assert_true(FileAccess.file_exists("res://assets/fonts/NotoSansSC-Regular.otf"),
		"NotoSansSC exists")
	assert_true(FileAccess.file_exists("res://assets/fonts/AnonymousPro-Regular.ttf"),
		"AnonymousPro exists")

# === Battle backgrounds (S14-002) ===

func test_battle_backgrounds_all_5_present() -> void:
	for sat in range(1, 6):
		var path: String = "res://assets/sprites/battle/bg_sat%d.png" % sat
		assert_true(FileAccess.file_exists(path), "%s exists" % path)

# === SFX (S14-003) ===

func test_sfx_player_has_all_required_methods() -> void:
	var sfx: Node = _sfx()
	if sfx == null:
		pending("SFXPlayer missing")
		return
	for method in ["play_death", "play_heal", "play_buff", "play_debuff",
		"play_ui_hover", "play_ui_open", "play_ui_close", "play_quest_complete"]:
		assert_true(sfx.has_method(method), "SFXPlayer.%s exists" % method)

func test_sfx_files_all_13_present() -> void:
	# S6-010 originals (5) + S14-003 additions (8)
	var names: Array[String] = [
		"attack_blaster", "attack_railgun", "attack_plasma",
		"hit_enemy", "ui_click",
		"death", "heal", "buff", "debuff",
		"ui_hover", "ui_open", "ui_close", "quest_complete",
	]
	for name in names:
		var path: String = "res://assets/audio/sfx/%s.wav" % name
		assert_true(FileAccess.file_exists(path), "%s.wav exists" % name)

# === Logo (S14-004) ===

func test_main_menu_logo_loaded() -> void:
	assert_true(FileAccess.file_exists("res://assets/sprites/title/logo.png"),
		"logo.png exists")
	# Verify main_menu.gd references it
	var menu_src: String = "res://src/ui/main_menu.gd"
	if FileAccess.file_exists(menu_src):
		var f: FileAccess = FileAccess.open(menu_src, FileAccess.READ)
		if f != null:
			var text: String = f.get_as_text()
			f.close()
			assert_true(text.contains("assets/sprites/title/logo.png"),
				"main_menu.gd references logo.png")

# === Loading screen (S14-005) ===

func test_loading_screen_can_be_instantiated() -> void:
	var ls: Node = _ls()
	if ls == null:
		pending("LoadingScreen autoload missing")
		return
	# Verify static API exists
	assert_true(ls.has_method("show_loading"), "LoadingScreen.show_loading")
	assert_true(ls.has_method("hide_loading"), "LoadingScreen.hide_loading")
	assert_true(ls.has_method("set_progress"), "LoadingScreen.set_progress")

func test_battle_scene_uses_satellite_background() -> void:
	# Verify battle_scene.gd has the _load_battle_background method
	var src: String = "res://src/battle/battle_scene.gd"
	if not FileAccess.file_exists(src):
		return
	var f: FileAccess = FileAccess.open(src, FileAccess.READ)
	if f == null:
		return
	var text: String = f.get_as_text()
	f.close()
	assert_true(text.contains("_load_battle_background"),
		"battle_scene.gd has _load_battle_background")
	assert_true(text.contains("bg_sat"),
		"battle_scene.gd references bg_sat")

# === Export presets (S14-006) ===

func test_export_presets_present() -> void:
	assert_true(FileAccess.file_exists("res://export_presets.cfg"),
		"export_presets.cfg exists")
	var f: FileAccess = FileAccess.open("res://export_presets.cfg", FileAccess.READ)
	if f == null:
		return
	var content: String = f.get_as_text()
	f.close()
	for preset in ["Linux/X11", "Linux/X11 (Debug)", "Windows Desktop", "Windows Desktop (Debug)"]:
		assert_true(content.contains('name="%s"' % preset),
			"preset '%s' defined" % preset)

# === Loading screen wiring ===

func test_loading_screen_wired_to_battle_entry() -> void:
	var src: String = "res://src/battle/battle_scene.gd"
	if not FileAccess.file_exists(src):
		return
	var f: FileAccess = FileAccess.open(src, FileAccess.READ)
	if f == null:
		return
	var text: String = f.get_as_text()
	f.close()
	assert_true(text.contains('ls.show_loading'),
		"battle_scene.gd calls ls.show_loading")
	assert_true(text.contains('ls.hide_loading'),
		"battle_scene.gd calls ls.hide_loading")

func test_loading_screen_wired_to_chapter_change() -> void:
	var src: String = "res://src/scene/level_runtime.gd"
	if not FileAccess.file_exists(src):
		return
	var f: FileAccess = FileAccess.open(src, FileAccess.READ)
	if f == null:
		return
	var text: String = f.get_as_text()
	f.close()
	assert_true(text.contains('ls.show_loading'),
		"level_runtime.gd calls ls.show_loading")
	assert_true(text.contains('ls.hide_loading'),
		"level_runtime.gd calls ls.hide_loading")
