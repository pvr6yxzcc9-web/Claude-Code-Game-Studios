extends Control

# BountyBoardUI (S11-001 + S11-002) — town interaction showing available bounties.
# Per production/sprints/sprint-11-bounty-racing.md + design/gdd/bounty-system.md
# Per .claude/rules/ui-code.md: UI never directly mutates game state — uses
# BountyManager for accept/complete/abandon operations.

const MENU_WIDTH: float = 800.0
const MENU_HEIGHT: float = 600.0

signal closed

# Visual elements
var _bg: ColorRect
var _title_label: Label
var _bounty_list: VBoxContainer
var _bounty_labels: Array[Label] = []

# Per .claude/rules/ui-code.md: UI does not modify state directly
# It calls BountyManager methods which emit signals

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	hide()
	# Subscribe to BountyManager for refresh on state changes
	var bm: Node = get_node_or_null("/root/BountyManager")
	if bm != null:
		bm.bounty_accepted.connect(_on_bounty_state_changed)
		bm.bounty_completed.connect(_on_bounty_completed)
		bm.bounty_failed.connect(_on_bounty_state_changed)
		bm.bounty_abandoned.connect(_on_bounty_state_changed)
	print("[BountyBoardUI] ready")

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
	_title_label.text = "BOUNTY BOARD"
	_title_label.add_theme_font_size_override("font_size", 24)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5, 1))
	_title_label.position = panel.position + Vector2(20, 15)
	add_child(_title_label)

	# Bounty list
	_bounty_list = VBoxContainer.new()
	_bounty_list.position = panel.position + Vector2(20, 60)
	_bounty_list.size = Vector2(MENU_WIDTH - 40, MENU_HEIGHT - 80)
	add_child(_bounty_list)

func _refresh() -> void:
	# Clear existing labels
	for label in _bounty_labels:
		label.queue_free()
	_bounty_labels.clear()

	var bm: Node = get_node_or_null("/root/BountyManager")
	if bm == null:
		return

	for bid in bm.ALL_BOUNTIES:
		var info: Dictionary = bm.get_bounty_info(bid)
		if info.is_empty():
			continue
		var status: String = bm.get_bounty_status(bid)
		var label: Label = Label.new()
		var text: String = "%s [%s] — %s\n  Reward: %d gold | Threat: %d | Level: %d\n  %s" % [
			String(info.get("title", "?")),
			status,
			String(info.get("satellite", "?")),
			int(info.get("gold_reward", 0)),
			int(info.get("threat_level", 0)),
			int(info.get("recommended_level", 0)),
			String(info.get("description", ""))
		]
		if status == "COMPLETED":
			text = "[DONE] " + text
			label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
		elif bool(info.get("is_plot", false)):
			label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3, 1))  # orange for plot
		else:
			label.add_theme_color_override("font_color", Color.WHITE)
		label.text = text
		label.add_theme_font_size_override("font_size", 13)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.custom_minimum_size = Vector2(0, 80)
		_bounty_list.add_child(label)
		_bounty_labels.append(label)

func open_bounty_board() -> void:
	show()
	_refresh()

func close_bounty_board() -> void:
	hide()
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_cancel"):
		close_bounty_board()
		get_viewport().set_input_as_handled()

func _on_bounty_state_changed(_bid: StringName) -> void:
	if visible:
		_refresh()

func _on_bounty_completed(bid: StringName, _gold: int) -> void:
	# Show a brief gold popup (simplified — actual popup deferred)
	print("[BountyBoardUI] bounty %s completed" % bid)
	if visible:
		_refresh()