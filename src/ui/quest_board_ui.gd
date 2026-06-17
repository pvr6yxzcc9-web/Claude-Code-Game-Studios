extends Control

# QuestBoardUI (Sprint 13, S13-007) — town interaction showing 12 side quests.
# Per design/gdd/side-quest-system.md + .claude/rules/ui-code.md
#
# Tabs: Active / Available / Completed (default: Active).
# Q key opens from exploration, ESC closes.
# Color coding: gray=AVAILABLE, green=ACTIVE, gold=COMPLETED, red=FAILED, orange=PLOT.
# Per ui-code.md: UI never directly mutates state — calls QuestManager methods.

const MENU_WIDTH: float = 900.0
const MENU_HEIGHT: float = 700.0

signal closed

# Visual elements
var _bg: ColorRect
var _title_label: Label
var _tab_buttons: Array[Button] = []
var _quest_list: VBoxContainer
var _quest_labels: Array[Label] = []
var _current_tab: int = 0  # 0=Active, 1=Available, 2=Completed

const TAB_NAMES: Array[String] = ["Active", "Available", "Completed"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	hide()
	# Subscribe to QuestManager for refresh on state changes
	var qm: Node = get_node_or_null("/root/QuestManager")
	if qm != null:
		qm.quest_accepted.connect(_on_quest_state_changed)
		qm.quest_completed.connect(_on_quest_state_changed)
		qm.quest_failed.connect(_on_quest_state_changed)
		qm.quest_abandoned.connect(_on_quest_state_changed)
	print("[QuestBoardUI] ready")

func _build_ui() -> void:
	# Background overlay
	_bg = ColorRect.new()
	_bg.color = Color(0.0, 0.0, 0.0, 0.85)
	_bg.position = Vector2(0, 0)
	_bg.size = Vector2(1280, 720)
	add_child(_bg)

	# Menu panel
	var panel: ColorRect = ColorRect.new()
	panel.color = Color(0.05, 0.05, 0.1, 0.98)
	panel.position = Vector2((1280 - MENU_WIDTH) * 0.5, (720 - MENU_HEIGHT) * 0.5)
	panel.size = Vector2(MENU_WIDTH, MENU_HEIGHT)
	add_child(panel)

	# Title
	_title_label = Label.new()
	_title_label.text = "QUEST BOARD (Q to open)"
	_title_label.add_theme_font_size_override("font_size", 24)
	_title_label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7, 1))
	_title_label.position = panel.position + Vector2(20, 15)
	add_child(_title_label)

	# Tabs row
	var tab_y: float = panel.position.y + 50
	for i in TAB_NAMES.size():
		var btn: Button = Button.new()
		btn.text = TAB_NAMES[i] + " (0)"
		btn.position = Vector2(panel.position.x + 20 + i * 110, tab_y)
		btn.size = Vector2(100, 28)
		btn.pressed.connect(_on_tab_pressed.bind(i))
		add_child(btn)
		_tab_buttons.append(btn)

	# Quest list
	_quest_list = VBoxContainer.new()
	_quest_list.position = panel.position + Vector2(20, 95)
	_quest_list.size = Vector2(MENU_WIDTH - 40, MENU_HEIGHT - 115)
	add_child(_quest_list)

func _refresh() -> void:
	# Clear existing labels
	for label in _quest_labels:
		label.queue_free()
	_quest_labels.clear()

	var qm: Node = get_node_or_null("/root/QuestManager")
	if qm == null:
		return

	# Update tab counts
	var counts: Array[int] = [
		qm.get_active_quests().size(),
		qm.get_available_quests().size(),
		qm.get_completed_quests().size(),
	]
	for i in _tab_buttons.size():
		_tab_buttons[i].text = "%s (%d)" % [TAB_NAMES[i], counts[i]]
		if i == _current_tab:
			_tab_buttons[i].add_theme_color_override("font_color", Color(0.5, 1.0, 0.5, 1))
		else:
			_tab_buttons[i].add_theme_color_override("font_color", Color.WHITE)

	# Get quests for current tab
	var qids: Array[StringName] = []
	if _current_tab == 0:
		qids = qm.get_active_quests()
	elif _current_tab == 1:
		qids = qm.get_available_quests()
	elif _current_tab == 2:
		qids = qm.get_completed_quests()

	# Group by satellite
	for sat in [2, 3, 4, 5]:
		var sat_qids: Array[StringName] = []
		for qid in qids:
			var data: Resource = qm.get_quest_data(qid)
			if data != null and int(data.get("satellite", 0)) == sat:
				sat_qids.append(qid)
		if sat_qids.is_empty():
			continue
		# Satellite header
		var header: Label = Label.new()
		header.text = "── Satellite %d ──" % sat
		header.add_theme_font_size_override("font_size", 14)
		header.add_theme_color_override("font_color", Color(0.7, 0.7, 1.0, 1))
		_quest_list.add_child(header)
		_quest_labels.append(header)
		# Quest entries
		for qid in sat_qids:
			_quest_list.add_child(_make_quest_label(qm, qid))

func _make_quest_label(qm: Node, qid: StringName) -> Label:
	var data: Resource = qm.get_quest_data(qid)
	if data == null:
		var lbl: Label = Label.new()
		lbl.text = "[missing data] %s" % String(qid)
		return lbl
	var status: int = qm.get_quest_state(qid)
	var status_name: String = qm.QuestState.keys()[status]
	var title: String = String(data.get("title_en", String(qid)))
	var desc: String = String(data.get("description_en", ""))
	var last_choice: int = qm.get_quest_choice(qid)
	var choice_str: String = ""
	if last_choice >= 0:
		var choice_names: Array[String] = ["compassionate", "pragmatic", "ruthless"]
		choice_str = " [choice: %s]" % choice_names[last_choice]
	var text: String = "%s [%s]%s\n  %s" % [title, status_name, choice_str, desc]
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.custom_minimum_size = Vector2(0, 60)
	# Color coding per status
	if status == 2:  # COMPLETED
		lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1))  # gold
		lbl.text = "[DONE] " + lbl.text
	elif status == 3:  # FAILED
		lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1))  # red
		lbl.text = "[FAILED] " + lbl.text
	elif bool(data.get("is_plot_required", false)):
		lbl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3, 1))  # orange for plot
		lbl.text = "[PLOT] " + lbl.text
	elif status == 1:  # ACTIVE
		lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5, 1))  # green
	else:
		lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))  # gray
	_quest_labels.append(lbl)
	return lbl

func open_quest_board() -> void:
	show()
	_refresh()

func close_quest_board() -> void:
	hide()
	closed.emit()

func toggle() -> void:
	if visible:
		close_quest_board()
	else:
		open_quest_board()

func _unhandled_input(event: InputEvent) -> void:
	# Q key opens from any state (per S13-007)
	if not visible and event.is_action_pressed(&"ui_focus_next") and event.is_action_pressed(&"ui_text_completion_accept"):
		# Avoid opening on every keypress — only on Q
		pass
	# Open on Q key (manual check since we don't have a custom action yet)
	if not visible and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			open_quest_board()
			get_viewport().set_input_as_handled()
			return
	if visible and event.is_action_pressed(&"ui_cancel"):
		close_quest_board()
		get_viewport().set_input_as_handled()

func _on_tab_pressed(idx: int) -> void:
	_current_tab = idx
	_refresh()

func _on_quest_state_changed(_qid: StringName = &"") -> void:
	if visible:
		_refresh()
