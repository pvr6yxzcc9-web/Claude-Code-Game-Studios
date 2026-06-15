extends CanvasLayer

# DeathScreen (S6-004)
# Shown when player HP hits 0 in battle. Offers two choices:
#   - RETRY: loads the most recent autosave, returns to exploration
#   - QUIT TO TITLE: returns to main menu (does NOT delete saves)
#
# Triggered by BattleScene via state transition to `state_game_over`.
# Listens to GameStateMachine.state_changed for visibility.
# Input is handled via _unhandled_input (Enter / E / Space confirms focused button).

const _BG_COLOR := Color(0.05, 0.0, 0.0, 0.85)
const _TEXT_COLOR := Color(0.95, 0.2, 0.2, 1.0)
const _BUTTON_FOCUSED := Color(0.9, 0.3, 0.3, 1.0)
const _BUTTON_NORMAL := Color(0.4, 0.4, 0.4, 1.0)

var _title_label: Label
var _retry_button: Label
var _quit_button: Label
var _focus_index: int = 0  # 0 = retry, 1 = quit
var _buttons: Array = []

func _ready() -> void:
	layer = 100  # on top of everything
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  # accept input even if paused
	_build_ui()
	var sm: Node = get_node("/root/GameStateMachine")
	sm.state_changed.connect(_on_state_changed)
	set_process_unhandled_input(true)
	print("[DeathScreen] ready")

func _build_ui() -> void:
	# Full-screen red overlay
	var bg: ColorRect = ColorRect.new()
	bg.color = _BG_COLOR
	bg.anchor_left = 0.0
	bg.anchor_right = 1.0
	bg.anchor_top = 0.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Death title (lore-flavored)
	_title_label = Label.new()
	var loc: Node = get_node_or_null("/root/Localization")
	_title_label.text = loc.t(&"ui.death.title") if loc != null else "REACTOR OFFLINE"
	_title_label.add_theme_font_size_override("font_size", 64)
	_title_label.add_theme_color_override("font_color", _TEXT_COLOR)
	_title_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_title_label.add_theme_constant_override("outline_size", 6)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.anchor_left = 0.0
	_title_label.anchor_right = 1.0
	_title_label.offset_top = 220
	add_child(_title_label)

	# Subtitle
	var subtitle: Label = Label.new()
	subtitle.text = loc.t(&"ui.death.subtitle") if loc != null else "The convoy has gone dark. Stand by for reactivation."
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.5, 0.5, 1))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.anchor_left = 0.0
	subtitle.anchor_right = 1.0
	subtitle.offset_top = 310
	add_child(subtitle)

	# Retry button (default focus)
	_retry_button = _make_button("> " + (loc.t(&"ui.death.retry") if loc != null else "RETRY") + " <", Vector2(640 - 100, 400), 200, 60)
	_quit_button = _make_button("  " + (loc.t(&"ui.death.quit") if loc != null else "QUIT TO TITLE") + "  ", Vector2(640 - 100, 480), 200, 60)
	_buttons = [_retry_button, _quit_button]
	_update_focus()

func _make_button(text: String, pos: Vector2, w: float, h: float) -> Label:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = pos
	lbl.size = Vector2(w, h)
	add_child(lbl)
	return lbl

func _update_focus() -> void:
	for i in _buttons.size():
		var btn: Label = _buttons[i]
		if i == _focus_index:
			btn.add_theme_color_override("font_color", _BUTTON_FOCUSED)
			btn.text = "> " + _strip_brackets(btn.text) + " <"
		else:
			btn.add_theme_color_override("font_color", _BUTTON_NORMAL)
			btn.text = "  " + _strip_brackets(btn.text) + "  "

func _strip_brackets(text: String) -> String:
	# Strip leading "> " / "< " and trailing " <" if any
	var result: String = text
	if result.begins_with("> "):
		result = result.substr(2)
	if result.ends_with(" <"):
		result = result.substr(0, result.length() - 2)
	return result.strip_edges()

func _on_state_changed(_old: StringName, new: StringName) -> void:
	visible = (new == &"state_game_over")
	if visible:
		_focus_index = 0
		_update_focus()
		# Pause any other timers etc — death screen is modal
		var sm: Node = get_node("/root/GameStateMachine")
		if sm.has_method("is_paused") and not sm.is_paused():
			# We don't push a pause state, but we can freeze via the
			# state_game_over entry itself (battle_scene calls transition_to
			# with this state, which freezes the battle scene since
			# battle_scene's _on_state_changed hides on state != battle).
			pass

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey and event.pressed):
		return
	var sm: Node = get_node("/root/GameStateMachine")
	if new_check_should_close(sm, event):
		return
	if event.keycode == KEY_UP or event.keycode == KEY_W:
		_focus_index = (_focus_index - 1 + _buttons.size()) % _buttons.size()
		_update_focus()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_DOWN or event.keycode == KEY_S:
		_focus_index = (_focus_index + 1) % _buttons.size()
		_update_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact") \
		or (event is InputEventKey and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE)):
		_confirm_selection()
		get_viewport().set_input_as_handled()

func new_check_should_close(sm: Node, _event: InputEvent) -> bool:
	# No ESC dismissal — death is permanent until player chooses.
	return false

func _confirm_selection() -> void:
	var sm: Node = get_node("/root/GameStateMachine")
	if _focus_index == 0:
		# RETRY: load autosave, then return to exploration
		_retry_from_autosave()
		sm.transition_to(&"state_exploration")
	else:
		# QUIT TO TITLE
		sm.transition_to(&"state_title")

func _retry_from_autosave() -> void:
	var save: Node = get_node_or_null("/root/SaveManager")
	if save == null:
		push_warning("DeathScreen: SaveManager missing, cannot load autosave")
		return
	var err: Error = save.get_autosave()
	if err != OK:
		push_warning("DeathScreen: no autosave to load")
	# Reset battle state so battle doesn't re-fire
	var bs: Node = get_tree().get_root().find_child("BattleScene", true, false)
	if bs != null:
		bs.in_battle = false
		bs.hide()
		bs._enemy_hp = 0
		bs._player_hp = 100
