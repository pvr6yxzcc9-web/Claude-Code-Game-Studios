extends Control

# PauseMenu (S2-001, S3-001) — soft-pause via GameStateMachine state_pause.
# Esc in state_exploration/state_battle → transition_to(state_pause) → show().
# No _draw() override — uses real Label/Button child nodes.
# S3-001 fix: anchored properly with explicit size; menu items center-stacked in vbox.

const MENU_WIDTH: float = 480.0
const MENU_ITEM_HEIGHT: float = 44.0
const MENU_ITEM_SEP: float = 8.0

var _focus_index: int = 0
var _menu_items: Array = []
var _show_confirm: bool = false
var _confirm_focus: int = 1

var _bg: ColorRect
var _menu_box: VBoxContainer
var _label_widgets: Array = []  # menu item Labels

# Confirm dialog
var _confirm_bg: PanelContainer
var _confirm_title: Label
var _confirm_subtitle: Label
var _confirm_yes: Label
var _confirm_no: Label

# Footer
var _footer_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# S6-019: localize menu items via Localization autoload
	var loc: Node = get_node_or_null("/root/Localization")
	_menu_items = [
		{"label": loc.t(&"ui.pause.resume") if loc != null else "RESUME", "action": "resume"},
		{"label": loc.t(&"ui.pause.save") if loc != null else "SAVE", "action": "save"},
		{"label": loc.t(&"ui.pause.load") if loc != null else "LOAD", "action": "load"},
		{"label": loc.t(&"ui.pause.settings") if loc != null else "SETTINGS (TBD)", "action": "settings"},
		{"label": loc.t(&"ui.pause.quit_to_title") if loc != null else "QUIT TO TITLE", "action": "quit_to_title"},
	]
	# Backdrop: a dark PANEL only behind the menu items, NOT the full screen.
	# (Earlier we used FULL_RECT which made the entire viewport darken — wrong.)
	var total_h: float = _menu_items.size() * (MENU_ITEM_HEIGHT + MENU_ITEM_SEP)
	var box_x: float = (1280.0 - MENU_WIDTH) / 2.0
	var box_y: float = (720.0 - total_h) / 2.0
	_bg = ColorRect.new()
	_bg.color = Color(0.05, 0.05, 0.1, 0.85)
	_bg.position = Vector2(box_x - 20, box_y - 20)
	_bg.size = Vector2(MENU_WIDTH + 40, total_h + 40)
	_bg.z_index = 0
	add_child(_bg)
	for i in _menu_items.size():
		var panel: PanelContainer = PanelContainer.new()
		panel.position = Vector2(box_x, box_y + i * (MENU_ITEM_HEIGHT + MENU_ITEM_SEP))
		panel.size = Vector2(MENU_WIDTH, MENU_ITEM_HEIGHT)
		panel.z_index = 1
		add_child(panel)
		var lbl: Label = Label.new()
		lbl.text = "  " + _menu_items[i]["label"]
		lbl.add_theme_font_size_override("font_size", 28)
		lbl.size = Vector2(MENU_WIDTH, MENU_ITEM_HEIGHT)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		panel.add_child(lbl)
		_label_widgets.append(lbl)
	_refresh_focus()
	# Confirm dialog (hidden by default) — PanelContainer with dark StyleBox,
	# z_index high enough to overlay menu. Label children at absolute positions.
	_confirm_bg = PanelContainer.new()
	_confirm_bg.size = Vector2(460, 140)
	_confirm_bg.position = Vector2((1280.0 - 460.0) / 2.0, (720.0 - 140.0) / 2.0)
	_confirm_bg.visible = false
	_confirm_bg.z_index = 200
	# Add a dark stylebox so the panel has a visible background
	var stylebox: StyleBoxFlat = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.05, 0.05, 0.1, 0.98)
	stylebox.border_color = Color(1.0, 0.5, 0.3, 1)
	stylebox.border_width_left = 2
	stylebox.border_width_right = 2
	stylebox.border_width_top = 2
	stylebox.border_width_bottom = 2
	_confirm_bg.add_theme_stylebox_override("panel", stylebox)
	add_child(_confirm_bg)
	_confirm_title = Label.new()
	_confirm_title.text = loc.t(&"ui.pause.confirm_title") if loc != null else "QUIT TO TITLE?"
	_confirm_title.add_theme_font_size_override("font_size", 22)
	_confirm_title.add_theme_color_override("font_color", Color.WHITE)
	_confirm_title.position = _confirm_bg.position + Vector2(20, 15)
	_confirm_title.z_index = 201
	add_child(_confirm_title)
	_confirm_subtitle = Label.new()
	_confirm_subtitle.text = loc.t(&"ui.pause.confirm_subtitle") if loc != null else "Unsaved progress will be lost."
	_confirm_subtitle.add_theme_font_size_override("font_size", 14)
	_confirm_subtitle.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	_confirm_subtitle.position = _confirm_bg.position + Vector2(20, 45)
	_confirm_subtitle.z_index = 201
	add_child(_confirm_subtitle)
	_confirm_yes = Label.new()
	_confirm_yes.text = loc.t(&"ui.pause.confirm_yes") if loc != null else "[YES]"
	_confirm_yes.add_theme_font_size_override("font_size", 18)
	_confirm_yes.position = _confirm_bg.position + Vector2(60, 100)
	_confirm_yes.z_index = 201
	add_child(_confirm_yes)
	_confirm_no = Label.new()
	_confirm_no.text = loc.t(&"ui.pause.confirm_no") if loc != null else "[NO]"
	_confirm_no.add_theme_font_size_override("font_size", 18)
	_confirm_no.position = _confirm_bg.position + Vector2(220, 100)
	_confirm_no.z_index = 201
	add_child(_confirm_no)
	# Footer
	_footer_label = Label.new()
	_footer_label.text = loc.t(&"ui.pause.footer") if loc != null else "↑/↓ + ENTER  |  Esc to resume"
	_footer_label.add_theme_font_size_override("font_size", 12)
	_footer_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	_footer_label.position = Vector2((1280.0 - 280.0) / 2.0, 700.0)
	add_child(_footer_label)
	# State machine listener
	var sm: Node = get_node_or_null("/root/GameStateMachine")
	if sm != null:
		sm.state_changed.connect(_on_state_changed)
		_on_state_changed(&"", sm.top_of_stack)
	print("[PauseMenu] ready")

func _on_state_changed(_old: StringName, new: StringName) -> void:
	print("[PauseMenu] _on_state_changed: %s -> %s" % [_old, new])
	if new == &"state_pause":
		_show_confirm = false
		_focus_index = 0
		_confirm_focus = 1
		_confirm_bg.visible = false
		_refresh_focus()
		# Explicitly show all menu/confirm children
		_bg.visible = true
		for lbl in _label_widgets:
			lbl.visible = true
		if _footer_label != null: _footer_label.visible = true
		show()
	else:
		# Leaving pause — fully reset state so a re-entry is clean
		_show_confirm = false
		# Hide ALL menu/confirm children explicitly (HiDPI + process_mode=ALWAYS can keep
		# them painted even when parent is hidden)
		for lbl in _label_widgets:
			lbl.visible = false
		_confirm_bg.visible = false
		if _confirm_title != null: _confirm_title.visible = false
		if _confirm_subtitle != null: _confirm_subtitle.visible = false
		if _confirm_yes != null: _confirm_yes.visible = false
		if _confirm_no != null: _confirm_no.visible = false
		_bg.visible = false
		if _footer_label != null: _footer_label.visible = false
		hide()

func _unhandled_input(event: InputEvent) -> void:
	var sm: Node = get_node("/root/GameStateMachine")
	var top: StringName = sm.top_of_stack
	if event.is_action_pressed("pause") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed):
		if top == &"state_pause":
			_resume()
			get_viewport().set_input_as_handled()
			return
		elif top != &"state_title" and top != &"state_menu":
			var err: int = sm.transition_to(&"state_pause")
			if err == OK:
				get_viewport().set_input_as_handled()
			return
	if not visible:
		return
	if _show_confirm:
		if event.is_action_pressed("move_left") or (event is InputEventKey and event.keycode == KEY_A and event.pressed):
			_confirm_focus = (_confirm_focus - 1 + 2) % 2
			_refresh_confirm_focus()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("move_right") or (event is InputEventKey and event.keycode == KEY_D and event.pressed):
			_confirm_focus = (_confirm_focus + 1) % 2
			_refresh_confirm_focus()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept") or (event is InputEventKey and event.keycode == KEY_ENTER and event.pressed):
			if _confirm_focus == 0:
				_quit_to_title()
			else:
				_show_confirm = false
				_confirm_bg.visible = false
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("move_up") or (event is InputEventKey and event.keycode == KEY_W and event.pressed):
		_focus_index = (_focus_index - 1 + _menu_items.size()) % _menu_items.size()
		_refresh_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down") or (event is InputEventKey and event.keycode == KEY_S and event.pressed):
		_focus_index = (_focus_index + 1) % _menu_items.size()
		_refresh_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or (event is InputEventKey and event.keycode == KEY_ENTER and event.pressed):
		_activate_focused()
		get_viewport().set_input_as_handled()

func _refresh_focus() -> void:
	for i in _label_widgets.size():
		var lbl: Label = _label_widgets[i]
		if i == _focus_index:
			lbl.text = "> " + _menu_items[i]["label"]
			lbl.add_theme_color_override("font_color", Color(0.3, 0.95, 1.0))
		else:
			lbl.text = "  " + _menu_items[i]["label"]
			lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_refresh_confirm_focus()

func _refresh_confirm_focus() -> void:
	if not _show_confirm:
		return
	if _confirm_yes != null and _confirm_no != null:
		_confirm_yes.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5) if _confirm_focus == 0 else Color(0.7, 0.7, 0.7))
		_confirm_no.add_theme_color_override("font_color", Color(0.3, 0.95, 1.0) if _confirm_focus == 1 else Color(0.7, 0.7, 0.7))

func _activate_focused() -> void:
	if _focus_index < 0 or _focus_index >= _menu_items.size():
		return
	var item: Dictionary = _menu_items[_focus_index]
	match item["action"]:
		"resume":
			_resume()
		"save":
			var save: Node = get_node("/root/SaveManager")
			if save.has_method("save_to_slot"):
				var err: int = save.save_to_slot(1)
				print("[PauseMenu] save_to_slot err=%d" % err)
		"load":
			var save: Node = get_node("/root/SaveManager")
			if save.has_method("load_from_slot"):
				var err: int = save.load_from_slot(1)
				if err == OK:
					_resume()
		"settings":
			print("[PauseMenu] SETTINGS (TBD)")
		"quit_to_title":
			_show_confirm = true
			_confirm_bg.visible = true
			if _confirm_title != null: _confirm_title.visible = true
			if _confirm_subtitle != null: _confirm_subtitle.visible = true
			if _confirm_yes != null: _confirm_yes.visible = true
			if _confirm_no != null: _confirm_no.visible = true
			_refresh_confirm_focus()

func _resume() -> void:
	var sm: Node = get_node("/root/GameStateMachine")
	sm.transition_to(&"state_exploration")

func _quit_to_title() -> void:
	_show_confirm = false
	_confirm_bg.visible = false
	var sm: Node = get_node("/root/GameStateMachine")
	# pause -> title is now allowed directly (added in ALLOWED_TRANSITIONS).
	sm.transition_to(&"state_title")
	var runtime: Node = get_tree().get_root().find_child("Main", true, false)
	if runtime != null and runtime.has_method("build_room"):
		runtime.build_room(0)
