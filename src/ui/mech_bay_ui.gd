extends Control
# MechBayUI (S7-007) — modal menu for managing mechs + pilots + weapons.
# Per .claude/rules/ui-code.md:
# - UI never directly modifies game state (uses MechBayEvents)
# - All text via Localization (deferred — keys are hardcoded English for now)
# - Keyboard + gamepad input
# - Skippable animations
#
# Layout:
#   ┌────────────────────────────────────────────┐
#   │ MECH BAY                          [M] Close │
#   ├────────────────────────────────────────────┤
#   │ [ranger]  [frostbite] [bomber]  [cang-locked]│
#   ├────────────────────────────────────────────┤
#   │ Active: ranger_mech — pilot: ranger       │
#   │ Weapons: [rifle] [knife] [throwable]      │
#   ├────────────────────────────────────────────┤
#   │ Pilots: [ranger] [frostbite] [bomber]    │
#   │ (click to assign to active mech)          │
#   └────────────────────────────────────────────┘

const MENU_WIDTH: float = 800.0
const MENU_HEIGHT: float = 540.0

# Visual elements
var _bg: ColorRect
var _title_label: Label
var _close_hint: Label
var _mech_cards: Array[Dictionary] = []  # 4 cards, one per mech in roster
var _active_mech_label: Label
var _weapon_slot_labels: Array[Label] = []
var _pilot_buttons: Array[Button] = []

# Currently selected mech (UI-local — different from global active_mech)
var _selected_mech_index: int = 0

# Mech roster order (matches MechLoadout.ROSTER)
const MECH_ROSTER: Array[StringName] = [
	&"ranger_mech",
	&"frostbite_mech",
	&"bomber_mech",
	&"cangqiong_mech",
]

const PILOT_NAMES: Array[String] = ["ranger", "frostbite", "bomber"]
const PILOT_DISPLAY: Array[String] = ["漫游者", "霜尾", "轰天"]

# Mech display names (for placeholder text until SpriteRect loads real portraits)
const MECH_DISPLAY: Dictionary = {
	&"ranger_mech": "漫游者号",
	&"frostbite_mech": "霜尾号",
	&"bomber_mech": "轰天号",
	&"cangqiong_mech": "苍穹号",
}

signal closed

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	hide()
	# Subscribe to events
	var events: Node = get_node_or_null("/root/MechBayEvents")
	if events != null:
		events.active_mech_changed.connect(_on_active_mech_changed)
		events.pilot_assigned.connect(_on_pilot_assigned)
		events.weapon_moved.connect(_on_weapon_moved)
	print("[MechBayUI] ready")

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
	_title_label.text = "MECH BAY"
	_title_label.add_theme_font_size_override("font_size", 24)
	_title_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 1))
	_title_label.position = panel.position + Vector2(20, 15)
	add_child(_title_label)

	# Close hint
	_close_hint = Label.new()
	_close_hint.text = "[M] Close"
	_close_hint.add_theme_font_size_override("font_size", 14)
	_close_hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	_close_hint.position = panel.position + Vector2(MENU_WIDTH - 100, 20)
	add_child(_close_hint)

	# Mech cards row
	_build_mech_cards(panel.position + Vector2(20, 60))

	# Active mech label + weapons
	_active_mech_label = Label.new()
	_active_mech_label.text = "Active: (none)"
	_active_mech_label.add_theme_font_size_override("font_size", 16)
	_active_mech_label.add_theme_color_override("font_color", Color.WHITE)
	_active_mech_label.position = panel.position + Vector2(20, 200)
	add_child(_active_mech_label)

	# Weapon slot labels (3 placeholder slots; cangqiong has 4 in build_mech_cards flow)
	for i in 4:
		var lbl: Label = Label.new()
		lbl.text = "[%d] empty" % (i + 1)
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
		lbl.position = panel.position + Vector2(20 + i * 130, 240)
		lbl.custom_minimum_size = Vector2(120, 40)
		_weapon_slot_labels.append(lbl)
		add_child(lbl)

	# Pilot buttons row
	_build_pilot_buttons(panel.position + Vector2(20, 350))

func _build_mech_cards(panel_origin: Vector2) -> void:
	for i in MECH_ROSTER.size():
		var mech_id: StringName = MECH_ROSTER[i]
		var card: Dictionary = {}
		var x: float = panel_origin.x + i * 185

		# Card background
		var card_bg: ColorRect = ColorRect.new()
		card_bg.color = Color(0.1, 0.1, 0.15, 1.0)
		card_bg.position = Vector2(x, panel_origin.y)
		card_bg.size = Vector2(170, 110)
		card_bg.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(card_bg)
		card["bg"] = card_bg

		# Mech name label
		var name_label: Label = Label.new()
		name_label.text = String(MECH_DISPLAY.get(mech_id, "?"))
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.add_theme_color_override("font_color", Color.WHITE)
		name_label.position = Vector2(x + 8, panel_origin.y + 6)
		name_label.size = Vector2(154, 20)
		add_child(name_label)
		card["name"] = name_label

		# HP label
		var hp_label: Label = Label.new()
		hp_label.text = "HP: ?"
		hp_label.add_theme_font_size_override("font_size", 11)
		hp_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
		hp_label.position = Vector2(x + 8, panel_origin.y + 32)
		hp_label.size = Vector2(154, 16)
		add_child(hp_label)
		card["hp"] = hp_label

		# Pilot label
		var pilot_label: Label = Label.new()
		pilot_label.text = "pilot: ?"
		pilot_label.add_theme_font_size_override("font_size", 11)
		pilot_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
		pilot_label.position = Vector2(x + 8, panel_origin.y + 52)
		pilot_label.size = Vector2(154, 16)
		add_child(pilot_label)
		card["pilot"] = pilot_label

		# Click target
		card_bg.gui_input.connect(_on_card_input.bind(i))

		_mech_cards.append(card)

func _build_pilot_buttons(panel_origin: Vector2) -> void:
	for i in PILOT_NAMES.size():
		var btn: Button = Button.new()
		btn.text = PILOT_DISPLAY[i]
		btn.position = Vector2(panel_origin.x + i * 130, panel_origin.y)
		btn.size = Vector2(120, 36)
		btn.pressed.connect(_on_pilot_pressed.bind(i))
		add_child(btn)
		_pilot_buttons.append(btn)

# === Input ===

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"mech_bay_toggle"):
		if visible:
			_close()
		else:
			_open()
		get_viewport().set_input_as_handled()

func _open() -> void:
	show()
	_refresh()
	var events: Node = get_node_or_null("/root/MechBayEvents")
	if events != null:
		events.notify_opened()

func _close() -> void:
	hide()
	closed.emit()
	var events: Node = get_node_or_null("/root/MechBayEvents")
	if events != null:
		events.notify_closed()

func _on_card_input(event: InputEvent, mech_index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Click a mech card → set as active
		var events: Node = get_node_or_null("/root/MechBayEvents")
		if events != null:
			var mech_id: StringName = MECH_ROSTER[mech_index]
			events.set_active_mech(mech_id)

func _on_pilot_pressed(pilot_index: int) -> void:
	# Assign this pilot to the active mech
	var ml: Node = get_node("/root/MechLoadout")
	var events: Node = get_node_or_null("/root/MechBayEvents")
	if ml == null or events == null:
		return
	var active_mech_id: StringName = ml.get_active_mech_id()
	var pilot_id: StringName = StringName(PILOT_NAMES[pilot_index])
	events.assign_pilot(active_mech_id, pilot_id)

# === Signal handlers ===

func _on_active_mech_changed(_mech_id: StringName) -> void:
	_refresh()

func _on_pilot_assigned(_mech_id: StringName, _pilot_id: StringName, _prev: StringName) -> void:
	_refresh()

func _on_weapon_moved(_from_mech: StringName, _from_slot: int, _to_mech: StringName, _to_slot: int) -> void:
	_refresh()

# === Refresh ===

func _refresh() -> void:
	var ml: Node = get_node("/root/MechLoadout")
	if ml == null:
		return
	var wl: Node = get_node_or_null("/root/WeaponLoadout")
	var active_mech_id: StringName = ml.get_active_mech_id()

	# Update mech cards
	for i in _mech_cards.size():
		var card: Dictionary = _mech_cards[i]
		var mech_id: StringName = MECH_ROSTER[i]
		var mech: Resource = ml.get_mech(mech_id)
		if mech == null:
			continue
		# HP
		var total: int = mech.head_hp + mech.chest_hp + mech.arms_hp + mech.legs_hp
		var max_total: int = mech.max_head_hp + mech.max_chest_hp + mech.max_arms_hp + mech.max_legs_hp
		card["hp"].text = "HP: %d/%d" % [total, max_total]
		# Pilot
		var pilot_label_text: String = "pilot: %s" % String(mech.pilot_id) if String(mech.pilot_id) != "" else "pilot: —"
		card["pilot"].text = pilot_label_text
		# Highlight active
		var bg: ColorRect = card["bg"]
		if mech_id == active_mech_id:
			bg.color = Color(0.15, 0.1, 0.0, 1.0)  # yellow-ish
		elif not mech.unlocked:
			bg.color = Color(0.05, 0.05, 0.05, 1.0)  # dimmed gray
			card["name"].text = "???"  # hide locked mech's name
		else:
			bg.color = Color(0.1, 0.1, 0.15, 1.0)

	# Update active mech label + weapons
	_active_mech_label.text = "Active: %s — pilot: %s" % [
		String(MECH_DISPLAY.get(active_mech_id, active_mech_id)),
		String(ml.get_active_mech().pilot_id),
	]
	if wl != null:
		var active_loadout: Resource = wl.get_active_mech_loadout()
		if active_loadout != null:
			var max_slots: int = active_loadout.max_weapon_slots
			for i in 4:
				var lbl: Label = _weapon_slot_labels[i]
				if i < max_slots:
					var wid: StringName = StringName(active_loadout.weapon_slots[i])
					lbl.text = "[%d] %s" % [i + 1, String(wid) if String(wid) != "" else "empty"]
					lbl.visible = true
				else:
					lbl.visible = false
		else:
			for lbl in _weapon_slot_labels:
				lbl.visible = false

	# Update pilot buttons — highlight assigned pilot
	for i in _pilot_buttons.size():
		var btn: Button = _pilot_buttons[i]
		var active_mech: Resource = ml.get_active_mech()
		var is_assigned: bool = active_mech != null and String(active_mech.pilot_id) == PILOT_NAMES[i]
		if is_assigned:
			btn.modulate = Color(1.0, 0.9, 0.5)  # gold-ish highlight
		else:
			btn.modulate = Color.WHITE