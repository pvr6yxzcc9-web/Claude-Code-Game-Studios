extends Control

# MainMenu — reimplemented without _draw to avoid Godot 4.6 HiDPI _draw crash.
# Uses Label children for title + menu items.

var _focus_index: int = 0
var _menu_items: Array = []
var _can_load: bool = true
var _title_label: Label
var _label_widgets: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	size = Vector2(1280, 720)
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	# Background
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.04, 0.06, 0.10, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# Title
	_title_label = Label.new()
	_title_label.text = "RAILHUNTER"
	_title_label.add_theme_font_size_override("font_size", 48)
	_title_label.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	_title_label.position = Vector2(400, 180)
	add_child(_title_label)
	var subtitle: Label = Label.new()
	subtitle.text = "钢轨猎人"
	subtitle.add_theme_font_size_override("font_size", 28)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.85, 0.9))
	subtitle.position = Vector2(590, 220)
	add_child(subtitle)
	# Menu items
	_menu_items = [
		{"label": "NEW GAME", "action": "new_game"},
		{"label": "LOAD GAME", "action": "load_game"},
		{"label": "SETTINGS (TBD)", "action": "settings"},
		{"label": "QUIT", "action": "quit"},
	]
	var menu_x: float = 560
	var menu_y: float = 396
	for i in _menu_items.size():
		var lbl: Label = Label.new()
		lbl.text = "  " + _menu_items[i]["label"]
		lbl.add_theme_font_size_override("font_size", 28)
		lbl.position = Vector2(menu_x, menu_y + i * 40)
		add_child(lbl)
		_label_widgets.append(lbl)
	_refresh_focus()
	# State machine
	var sm: Node = get_node_or_null("/root/GameStateMachine")
	if sm != null:
		sm.state_changed.connect(_on_state_changed)
		_on_state_changed(&"", sm.top_of_stack)
	# Footer
	var footer: Label = Label.new()
	footer.text = "v0.1.0 (build 2026-06-14)  -  ↑/↓ + ENTER"
	footer.add_theme_font_size_override("font_size", 12)
	footer.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	footer.position = Vector2(10, 700)
	add_child(footer)
	print("[MainMenu] ready")

func _on_state_changed(_old: StringName, new: StringName) -> void:
	if new == &"state_title":
		show()
	else:
		hide()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("move_up") or (event is InputEventKey and event.keycode == KEY_W and event.pressed):
		_focus_index = (_focus_index - 1 + _menu_items.size()) % _menu_items.size()
		_refresh_focus()
	elif event.is_action_pressed("move_down") or (event is InputEventKey and event.keycode == KEY_S and event.pressed):
		_focus_index = (_focus_index + 1) % _menu_items.size()
		_refresh_focus()
	elif event.is_action_pressed("ui_accept") or (event is InputEventKey and event.keycode == KEY_ENTER and event.pressed):
		_activate_focused()
	elif event.is_action_pressed("pause"):
		get_tree().quit()

func _refresh_focus() -> void:
	for i in _label_widgets.size():
		var lbl: Label = _label_widgets[i]
		if i == _focus_index:
			lbl.text = "> " + _menu_items[i]["label"]
			lbl.add_theme_color_override("font_color", Color(0.3, 0.95, 1.0, 1))
		else:
			lbl.text = "  " + _menu_items[i]["label"]
			lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))

func _activate_focused() -> void:
	if _focus_index < 0 or _focus_index >= _menu_items.size():
		return
	var item: Dictionary = _menu_items[_focus_index]
	match item["action"]:
		"new_game":
			print("[MainMenu] NEW GAME")
			var sm: Node = get_node("/root/GameStateMachine")
			sm.transition_to(&"state_exploration")
			var runtime: Node = get_tree().get_root().find_child("Main", true, false)
			if runtime != null and runtime.has_method("build_room"):
				runtime.build_room(0)
		"load_game":
			print("[MainMenu] LOAD GAME")
			var save: Node = get_node("/root/SaveManager")
			var err: int = save.get_autosave()
			if err == OK:
				var sm2: Node = get_node("/root/GameStateMachine")
				sm2.transition_to(&"state_exploration")
		"settings":
			print("[MainMenu] SETTINGS (TBD)")
		"quit":
			get_tree().quit()
