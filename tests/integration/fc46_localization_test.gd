extends GutTest

# FC-46 Localization (S6-017)
# Pins that localization plumbing works:
#   1) strings.csv exists
#   2) Localization autoload registered
#   3) CSV loaded with N keys
#   4) tr() returns English for known key
#   5) tr() returns "[key]" for missing key
#   6) trf() with %d format args
#   7) set_locale("zh") switches language
#   8) has_key() works
#   9) MainMenu title text uses localized string
#  10) TutorialManager step 1 uses CSV-driven text (not hardcoded)

var _loc: Node = null

func before_all() -> void:
	_loc = get_node_or_null("/root/Localization")
	if _loc == null:
		var main: Node = load("res://src/main.tscn").instantiate()
		get_tree().root.add_child(main)
		await get_tree().process_frame
		_loc = get_node_or_null("/root/Localization")

func after_all() -> void:
	pass

# 1) CSV exists

func test_strings_csv_exists() -> void:
	assert_true(FileAccess.file_exists("res://design/l10n/strings.csv"),
		"strings.csv exists at design/l10n/")

# 2) Autoload

func test_localization_autoload_exists() -> void:
	assert_not_null(_loc, "Localization autoload registered")

# 3) Keys loaded

func test_localization_loaded_at_least_50_keys() -> void:
	assert_gt(_loc.key_count(), 50, "loaded >50 keys from strings.csv")

# 4) English lookup

func test_tr_returns_english_for_known_key() -> void:
	var s: String = _loc.t(&"ui.main_menu.title")
	assert_eq(s, "RAILHUNTER", "ui.main_menu.title in English = RAILHUNTER")

# 5) Missing key

func test_tr_returns_marker_for_missing_key() -> void:
	var s: String = _loc.t(&"nonexistent.key")
	assert_eq(s, "[nonexistent.key]", "missing key returns [key] marker")

# 6) trf() with format args

func test_trf_with_format_args() -> void:
	var s: String = _loc.trf(&"ui.hud.fragments", [3, 12])
	assert_eq(s, "FRAGMENTS: 3/12", "trf formats %d placeholders")

# 7) Switch locale

func test_set_locale_switches_language() -> void:
	# Start in English
	_loc.set_locale("en")
	assert_eq(_loc.t(&"ui.main_menu.title"), "RAILHUNTER", "en: RAILHUNTER")
	# Switch to Chinese
	_loc.set_locale("zh")
	var zh_text: String = _loc.t(&"ui.main_menu.title")
	assert_eq(zh_text, "钢轨猎人", "zh: 钢轨猎人")
	# Switch back
	_loc.set_locale("en")

# 8) has_key

func test_has_key_returns_true_for_existing() -> void:
	assert_true(_loc.has_key(&"ui.main_menu.title"), "has_key true for existing key")
	assert_false(_loc.has_key(&"fake.key"), "has_key false for missing key")

# 9) MainMenu uses localized title

func test_main_menu_title_uses_localized_text() -> void:
	# In English, title is "RAILHUNTER"
	var menu: Node = get_tree().get_root().find_child("MainMenu", true, false)
	if menu == null:
		pending("MainMenu not in scene tree")
		return
	for child in menu.get_children():
		if child is Label and String(child.text) == "RAILHUNTER":
			return
	assert_true(false, "MainMenu has 'RAILHUNTER' title (English localization working)")

# 10) TutorialManager step 1 has resolved text

func test_tutorial_step_1_text_is_resolved() -> void:
	var tut: Node = get_node_or_null("/root/TutorialManager")
	if tut == null:
		pending("TutorialManager not in scene tree")
		return
	# Start tutorial and check that the first hint uses localized text
	tut._active = true
	tut._current_step = 0
	tut._show_current()
	await get_tree().process_frame
	# Hint should be the English step 1 text + ESC suffix
	var hud: Node = get_tree().get_root().find_child("HUD", true, false)
	if hud == null or hud._hint_label == null:
		pending("HUD not ready")
		return
	var hint: String = String(hud._hint_label.text)
	assert_true(hint.contains("WASD"), "tutorial step 1 hint contains 'WASD' (English text)")
	assert_true(hint.contains("ESC"), "tutorial hint has ESC suffix")
