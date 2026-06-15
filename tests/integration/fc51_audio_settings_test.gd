extends GutTest

# FC-51 Audio settings (S6-018)
# Pins that AudioManager + pause menu settings sub-panel work:
#   1) AudioManager autoload registered
#   2) set_master_db clamps to [-30, 0]
#   3) toggle_mute flips state
#   4) volume_changed / mute_changed signals fire
#   5) PauseMenu has settings sub-panel widgets
#   6) Selecting SETTINGS shows the sub-panel
#   7) CSV has new settings keys

var _main: Node = null
var _am: Node = null

func before_all() -> void:
	_main = load("res://src/main.tscn").instantiate()
	get_tree().root.add_child(_main)
	await get_tree().process_frame
	await get_tree().process_frame
	_am = get_node_or_null("/root/AudioManager")

func after_all() -> void:
	if _main != null:
		_main.queue_free()
		_main = null

# 1) Autoload

func test_audio_manager_registered() -> void:
	assert_not_null(_am, "AudioManager autoload registered")

# 2) Clamp

func test_set_master_db_clamps_low() -> void:
	_am.set_master_db(-100.0)
	assert_eq(_am.get_db(), -30.0, "clamped to MIN_DB=-30")

func test_set_master_db_clamps_high() -> void:
	_am.set_master_db(20.0)
	assert_eq(_am.get_db(), 0.0, "clamped to MAX_DB=0")

func test_set_master_db_in_range() -> void:
	_am.set_master_db(-12.5)
	assert_eq(_am.get_db(), -12.5, "in-range dB preserved")

# 3) Mute toggle

func test_toggle_mute_flips_state() -> void:
	var initial: bool = _am.is_muted()
	_am.toggle_mute()
	assert_eq(_am.is_muted(), not initial, "toggle flips mute state")
	_am.toggle_mute()  # restore
	assert_eq(_am.is_muted(), initial, "second toggle restores state")

# 4) Signals

func test_volume_changed_signal_fires() -> void:
	var fired: bool = false
	var received_db: float = 0.0
	var cb: Callable = func(db: float) -> void:
		fired = true
		received_db = db
	_am.volume_changed.connect(cb)
	_am.set_master_db(-7.5)
	assert_true(fired, "volume_changed signal fired")
	assert_eq(received_db, -7.5, "signal carries new dB")
	_am.volume_changed.disconnect(cb)

func test_mute_changed_signal_fires() -> void:
	var fired: bool = false
	var cb: Callable = func(_muted: bool) -> void:
		fired = true
	_am.mute_changed.connect(cb)
	_am.toggle_mute()
	assert_true(fired, "mute_changed signal fired")
	_am.toggle_mute()  # restore
	_am.mute_changed.disconnect(cb)

# 5) PauseMenu has settings widgets

func test_pause_menu_has_settings_widgets() -> void:
	var menu: Node = get_tree().get_root().find_child("PauseMenu", true, false)
	if menu == null:
		pending("PauseMenu not in scene")
		return
	assert_not_null(menu._settings_bg, "PauseMenu has _settings_bg")
	assert_not_null(menu._settings_volume_slider, "PauseMenu has _settings_volume_slider")
	assert_not_null(menu._settings_mute_value, "PauseMenu has _settings_mute_value")
	# Slider range
	assert_eq(menu._settings_volume_slider.min_value, -30.0, "slider min = -30 dB")
	assert_eq(menu._settings_volume_slider.max_value, 0.0, "slider max = 0 dB")

# 6) Selecting SETTINGS shows panel

func test_settings_panel_shows_on_select() -> void:
	var menu: Node = get_tree().get_root().find_child("PauseMenu", true, false)
	if menu == null:
		pending("PauseMenu not in scene")
		return
	# Initially hidden
	assert_false(menu._settings_bg.visible, "settings panel hidden by default")
	# Simulate selecting SETTINGS (find that menu index and call _activate_focused)
	for i in menu._menu_items.size():
		if menu._menu_items[i].get("action") == "settings":
			menu._focus_index = i
			menu._activate_focused()
			break
	assert_true(menu._settings_bg.visible, "settings panel visible after select")

# 7) CSV has new keys

func test_csv_has_settings_keys() -> void:
	var loc: Node = get_node_or_null("/root/Localization")
	if loc == null:
		pending("no Localization")
		return
	for k in [&"ui.pause.settings_title", &"ui.pause.master_volume", &"ui.pause.mute", &"ui.pause.settings_footer"]:
		assert_true(loc.has_key(k), "%s key exists" % k)
