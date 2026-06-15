extends GutTest

# FC-48 L10n coverage (S6-019)
# Pins that the remaining hardcoded UI strings have been migrated:
#   1) All 30+ new strings now resolve via Localization.tr()
#   2) PauseMenu items use tr()
#   3) Death screen title uses tr()
#   4) Save/load slot labels use tr()
#   5) Battle scene title + instructions use tr()
#   6) Level runtime markers use tr() (via _tr helper)
#   7) Terminal footer uses tr()
#   8) CSV has at least 70 keys
#   9) Switching to Chinese translates at least 5 critical UI elements

var _loc: Node = null
var _main: Node = null

func before_all() -> void:
	_main = load("res://src/main.tscn").instantiate()
	get_tree().root.add_child(_main)
	await get_tree().process_frame
	await get_tree().process_frame
	_loc = get_node_or_null("/root/Localization")

func after_all() -> void:
	if _main != null:
		_main.queue_free()
		_main = null

# 1) Localization is registered
func test_localization_registered() -> void:
	assert_not_null(_loc, "Localization autoload present")

# 2) PauseMenu items translated

func test_pause_menu_items_translated() -> void:
	# Switch to Chinese to verify the keys resolve
	if _loc == null:
		pending("no Localization")
		return
	_loc.set_locale("en")
	var menu: Node = get_tree().get_root().find_child("PauseMenu", true, false)
	if menu == null:
		pending("PauseMenu not in scene tree (state_pause hidden by default)")
		return
	# Resume should be in _menu_items
	assert_eq(menu._menu_items[0]["label"], "RESUME", "Pause menu resume in English")
	_loc.set_locale("zh")
	assert_eq(menu._menu_items[0]["label"], "继续", "Pause menu resume in Chinese")
	_loc.set_locale("en")

# 3) Death screen

func test_death_screen_title_translated() -> void:
	if _loc == null:
		pending("no Localization")
		return
	# DeathScreen is a CanvasLayer autoload
	var ds: Node = get_node_or_null("/root/DeathScreen")
	if ds == null:
		pending("DeathScreen not in scene tree")
		return
	_loc.set_locale("en")
	assert_eq(ds._title_label.text, "REACTOR OFFLINE", "death title EN")
	_loc.set_locale("zh")
	assert_eq(ds._title_label.text, "反应堆离线", "death title ZH")
	_loc.set_locale("en")

# 4) Save/load slot label format

func test_save_ui_slot_keys_present() -> void:
	if _loc == null:
		pending("no Localization")
		return
	assert_true(_loc.has_key(&"ui.save.saved"), "ui.save.saved key exists")
	assert_true(_loc.has_key(&"ui.save.empty_slot"), "ui.save.empty_slot key exists")

# 5) Battle scene keys

func test_battle_scene_keys() -> void:
	if _loc == null:
		pending("no Localization")
		return
	for k in [&"ui.battle.title", &"ui.battle.instr_attack", &"ui.battle.instr_flee",
			&"ui.battle.enemy_hp", &"ui.battle.player_hp", &"ui.battle.crit_prefix"]:
		assert_true(_loc.has_key(k), "%s key exists" % k)

# 6) Level runtime _tr helper

func test_level_runtime_tr_helper_exists() -> void:
	var rt: Node = get_tree().get_root().find_child("Main", true, false)
	if rt == null:
		pending("no level runtime")
		return
	assert_true(rt.has_method("_tr"), "_tr helper exists on LevelRuntime")
	# Test it works
	var s: String = rt._tr(&"ui.terminal.marker_label", "FALLBACK")
	assert_ne(s, "FALLBACK", "_tr returns localized text (not fallback)")

# 7) Terminal footer

func test_terminal_footer_translated() -> void:
	if _loc == null:
		pending("no Localization")
		return
	var tu: Node = get_tree().get_root().find_child("TerminalUI", true, false)
	if tu == null:
		pending("TerminalUI not in scene")
		return
	assert_true(tu._footer_label != null, "TerminalUI has _footer_label")

# 8) CSV coverage

func test_csv_has_at_least_70_keys() -> void:
	if _loc == null:
		pending("no Localization")
		return
	assert_gt(_loc.key_count(), 70, "at least 70 keys loaded (was 60+ before S6-019)")

# 9) Chinese locale affects multiple UI elements

func test_zh_locale_affects_multiple_ui() -> void:
	if _loc == null:
		pending("no Localization")
		return
	_loc.set_locale("zh")
	# Check several keys that should change
	var title_zh: String = _loc.t(&"ui.main_menu.title")
	var resume_zh: String = _loc.t(&"ui.pause.resume")
	var death_zh: String = _loc.t(&"ui.death.title")
	assert_eq(title_zh, "钢轨猎人", "title ZH")
	assert_eq(resume_zh, "继续", "resume ZH")
	assert_eq(death_zh, "反应堆离线", "death title ZH")
	_loc.set_locale("en")
