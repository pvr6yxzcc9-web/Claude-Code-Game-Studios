extends Control
# Party HUD Overlay (Sprint 7-001 PR 5 + Sprint 7-004)
#
# A HUD overlay for 3v1 combat AND exploration. Shows 3-4 mech HP bars
# (one per party mech) on the LEFT side of the screen.
#
# This is a **separate overlay** that does NOT modify the existing
# 1v1 HUD (src/ui/hud.gd). The 1v1 HUD continues to work as
# before. When 3v1 combat is active, this overlay appears
# alongside the 1v1 HUD.
#
# Per .claude/rules/ui-code.md:
# - UI never directly modifies game state
# - Reads from MechLoadout + PartyBattleController via signals
# - All text localized (future)
# - Emits click signal for parent to call set_active_mech()
#
# Per party-system.md §3.4:
# - 3-4 mech bars
# - Active mech highlighted (yellow border)
# - Knocked-out mechs dimmed (gray)
# - Click a bar to emit mech_bar_clicked(mech_index) — the keyboard
#   1/2/3 is the primary control; click is an alternative

# === Signals ===

signal mech_bar_clicked(mech_index: int)

# === Visual constants ===

const BAR_WIDTH: float = 220.0
const BAR_HEIGHT: float = 70.0
const BAR_SPACING: float = 8.0
const BAR_X: float = 30.0
const BAR_Y_START: float = 200.0
const ICON_SIZE: float = 32.0

# === Visual elements ===

# 3-4 mech bars (created in _build_ui)
# Each: {bg, fill, label, pilot_icon, parts: Array[ColorRect], button}
var _mech_bars: Array[Dictionary] = []
var _active_mech_index: int = 0
var _mech_count: int = 3  # how many bars to show (3 default, 4 with cangqiong)

# === Lifecycle ===

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 50  # above the regular HUD
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_ui()
	hide()
	# Subscribe to PartyBattleController signals
	var pbc: Node = get_node_or_null("/root/PartyBattleController")
	if pbc == null:
		push_warning("PartyHudOverlay: PartyBattleController autoload missing")
	else:
		pbc.active_mech_changed.connect(_on_active_mech_changed)
		pbc.party_member_knocked_out.connect(_on_knocked_out)
		pbc.party_battle_started.connect(_on_battle_started)
		pbc.party_battle_ended.connect(_on_battle_ended)
	# Subscribe to MechLoadout signals (S7-003)
	var ml: Node = get_node_or_null("/root/MechLoadout")
	if ml != null:
		ml.active_mech_changed.connect(_on_mech_loadout_active_changed)
		ml.cangqiong_unlocked.connect(_on_cangqiong_unlocked)
		# Determine initial mech count
		_mech_count = ml.get_unlocked_mechs().size()
		print("[PartyHudOverlay] ready — initial mech count = %d" % _mech_count)
	else:
		print("[PartyHudOverlay] ready (PR 5 — opt-in 3v1 HUD, MechLoadout not yet)")

# === Build UI ===

func _build_ui() -> void:
	for i in 4:
		var y: float = BAR_Y_START + i * (BAR_HEIGHT + BAR_SPACING)
		var bar: Dictionary = {}

		# Background
		var bg: ColorRect = ColorRect.new()
		bg.color = Color(0.0, 0.0, 0.0, 0.6)
		bg.position = Vector2(BAR_X, y)
		bg.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
		add_child(bg)
		bar["bg"] = bg

		# Pilot icon (S7-004 — placeholder ColorRect, replace with TextureRect+PNG)
		var pilot_icon: ColorRect = ColorRect.new()
		pilot_icon.color = Color(0.3, 0.3, 0.5, 1.0)  # placeholder blue
		pilot_icon.position = Vector2(BAR_X + 4, y + 4)
		pilot_icon.size = Vector2(ICON_SIZE, ICON_SIZE)
		add_child(pilot_icon)
		bar["pilot_icon"] = pilot_icon

		# Label (mech name + HP text)
		var label: Label = Label.new()
		label.position = Vector2(BAR_X + 4 + ICON_SIZE + 4, y + 4)
		label.size = Vector2(BAR_WIDTH - ICON_SIZE - 12, 18)
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color.WHITE)
		add_child(label)
		bar["label"] = label

		# HP fill (below label, full width)
		var fill: ColorRect = ColorRect.new()
		fill.color = Color(0.2, 0.8, 0.2, 1.0)
		fill.position = Vector2(BAR_X + 4 + ICON_SIZE + 4, y + 24)
		fill.size = Vector2(BAR_WIDTH - ICON_SIZE - 12, 10)
		add_child(fill)
		bar["fill"] = fill

		# 4 parts indicators (small horizontal bar at the bottom)
		var parts: Array = []
		for p in 4:
			var p_color: ColorRect = ColorRect.new()
			p_color.position = Vector2(BAR_X + 4 + ICON_SIZE + 4 + p * 45, y + 40)
			p_color.size = Vector2(42, 6)
			p_color.color = Color(0.4, 0.4, 0.4, 0.8)
			add_child(p_color)
			parts.append(p_color)
		bar["parts"] = parts

		# Click handler (S7-004) — invisible Button overlay
		var click_rect: ColorRect = ColorRect.new()
		click_rect.color = Color(0, 0, 0, 0)  # invisible
		click_rect.position = Vector2(BAR_X, y)
		click_rect.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
		click_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(click_rect)
		# Connect via input_event (we don't use Button — ColorRect is enough for a click target)
		click_rect.gui_input.connect(_on_bar_input.bind(i))
		bar["click_rect"] = click_rect

		_mech_bars.append(bar)
		# Hide bars beyond the initial mech count
		if i >= _mech_count:
			bg.visible = false
			fill.visible = false
			label.visible = false
			pilot_icon.visible = false
			for pc in parts:
				pc.visible = false
			click_rect.visible = false

# === Refresh from MechLoadout (S7-004) ===

func _refresh() -> void:
	var ml: Node = get_node_or_null("/root/MechLoadout")
	if ml == null:
		return
	var unlocked: Array = ml.get_unlocked_mechs()
	for i in unlocked.size():
		if i >= _mech_bars.size():
			break
		var mech: Resource = unlocked[i]
		var bar: Dictionary = _mech_bars[i]
		# Show this bar (in case cangqiong just unlocked)
		bar["bg"].visible = true
		bar["fill"].visible = true
		bar["label"].visible = true
		bar["pilot_icon"].visible = true
		for pc in bar["parts"]:
			pc.visible = true
		bar["click_rect"].visible = true

		# Total HP = sum of 4 parts
		var total_hp: int = mech.head_hp + mech.chest_hp + mech.arms_hp + mech.legs_hp
		var max_total_hp: int = mech.max_head_hp + mech.max_chest_hp + mech.max_arms_hp + mech.max_legs_hp
		var display_name: String = String(mech.display_name) if mech.display_name != "" else String(mech.mech_id)

		# Label
		bar["label"].text = "%d. %s  %d/%d" % [i + 1, display_name, total_hp, max_total_hp]

		# HP fill
		var fill: ColorRect = bar["fill"]
		var fill_ratio: float = float(total_hp) / float(max(max_total_hp, 1))
		fill.size.x = (BAR_WIDTH - ICON_SIZE - 12) * fill_ratio
		# Color: green > 50%, yellow > 25%, red < 25%
		if fill_ratio > 0.5:
			fill.color = Color(0.2, 0.8, 0.2, 1.0)
		elif fill_ratio > 0.25:
			fill.color = Color(0.8, 0.8, 0.2, 1.0)
		else:
			fill.color = Color(0.8, 0.2, 0.2, 1.0)

		# Active mech: yellow-tinted background; knocked-out: dimmed gray
		var is_destroyed: bool = ml.is_mech_destroyed(String(mech.mech_id))
		if i == _active_mech_index:
			bar["bg"].color = Color(0.1, 0.05, 0.0, 0.7)  # yellow-ish dark
		elif is_destroyed:
			bar["bg"].color = Color(0.1, 0.1, 0.1, 0.5)  # dimmed gray
		else:
			bar["bg"].color = Color(0.0, 0.0, 0.0, 0.6)

		# Parts indicators: green if > 0, red if 0
		var part_keys: Array[StringName] = [&"head", &"chest", &"arms", &"legs"]
		var part_hps: Array[int] = [mech.head_hp, mech.chest_hp, mech.arms_hp, mech.legs_hp]
		for p in 4:
			var p_color: ColorRect = bar["parts"][p]
			if part_hps[p] <= 0:
				p_color.color = Color(0.6, 0.0, 0.0, 0.8)
			else:
				p_color.color = Color(0.3, 0.5, 0.3, 0.8)

	# Hide bars beyond the unlocked count
	for i in range(unlocked.size(), _mech_bars.size()):
		var bar: Dictionary = _mech_bars[i]
		bar["bg"].visible = false
		bar["fill"].visible = false
		bar["label"].visible = false
		bar["pilot_icon"].visible = false
		for pc in bar["parts"]:
			pc.visible = false
		bar["click_rect"].visible = false

# === Click handler (S7-004) ===

func _on_bar_input(event: InputEvent, mech_index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		mech_bar_clicked.emit(mech_index)

# === Signal Handlers ===

func _on_active_mech_changed(new_index: int) -> void:
	_active_mech_index = new_index
	_refresh()

func _on_knocked_out(_pilot_id: StringName) -> void:
	_refresh()

func _on_battle_started(_enemy_id: StringName) -> void:
	show()
	_refresh()

func _on_battle_ended(_victory: bool) -> void:
	hide()

func _on_mech_loadout_active_changed(_mech_id: StringName) -> void:
	# Active mech in MechLoadout changed (Mech Bay or exploration)
	_refresh()

func _on_cangqiong_unlocked(_mech_id: StringName) -> void:
	# cangqiong unlocked — show 4th bar
	var ml: Node = get_node_or_null("/root/MechLoadout")
	if ml != null:
		_mech_count = ml.get_unlocked_mechs().size()
		_refresh()