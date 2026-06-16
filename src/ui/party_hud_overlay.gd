extends Control
# Party HUD Overlay (Sprint 7-001 PR 5)
#
# A minimal HUD overlay for 3v1 combat. Shows 3-4 mech HP bars
# (one per party mech) on the LEFT side of the screen.
#
# This is a **separate overlay** that does NOT modify the existing
# 1v1 HUD (src/ui/hud.gd). The 1v1 HUD continues to work as
# before. When 3v1 combat is active, this overlay appears
# alongside the 1v1 HUD.
#
# Per .claude/rules/ui-code.md:
# - UI never directly modifies game state
# - Reads from PartyBattleController and PartyManager via signals
# - All text localized (future)
#
# Per party-system.md §3.4:
# - 3-4 mech bars
# - Active mech highlighted (yellow border)
# - Knocked-out mechs dimmed (gray)
# - Click a bar to set active mech (debug — the keyboard 1/2/3
#   is the primary control)

# === Visual elements ===

const BAR_WIDTH: float = 220.0
const BAR_HEIGHT: float = 70.0
const BAR_SPACING: float = 8.0
const BAR_X: float = 30.0
const BAR_Y_START: float = 200.0

# 3-4 mech bars (created in _build_ui)
var _mech_bars: Array[Dictionary] = []  # each: {bg, fill, label, pilot_icon, parts_indicators}
var _active_mech_index: int = 0

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
        return
    pbc.active_mech_changed.connect(_on_active_mech_changed)
    pbc.party_member_knocked_out.connect(_on_knocked_out)
    pbc.party_battle_started.connect(_on_battle_started)
    pbc.party_battle_ended.connect(_on_battle_ended)
    print("[PartyHudOverlay] ready (PR 5 — opt-in 3v1 HUD)")

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

        # HP fill (placeholder, will be updated in _refresh)
        var fill: ColorRect = ColorRect.new()
        fill.color = Color(0.2, 0.8, 0.2, 1.0)
        fill.position = Vector2(BAR_X + 4, y + 24)
        fill.size = Vector2(BAR_WIDTH - 8, 12)
        add_child(fill)
        bar["fill"] = fill

        # Label (mech name + HP text)
        var label: Label = Label.new()
        label.position = Vector2(BAR_X + 6, y + 4)
        label.size = Vector2(BAR_WIDTH - 12, 18)
        label.add_theme_font_size_override("font_size", 14)
        label.add_theme_color_override("font_color", Color.WHITE)
        add_child(label)
        bar["label"] = label

        # 4 parts indicators (small horizontal bar)
        var parts: Array = []
        for p in 4:
            var p_color: ColorRect = ColorRect.new()
            p_color.position = Vector2(BAR_X + 6 + p * 50, y + 42)
            p_color.size = Vector2(46, 8)
            p_color.color = Color(0.4, 0.4, 0.4, 0.8)
            add_child(p_color)
            parts.append(p_color)
        bar["parts"] = parts

        _mech_bars.append(bar)

# === Refresh from PartyManager data ===

func _refresh() -> void:
    var pm: Node = get_node_or_null("/root/PartyManager")
    if pm == null:
        return
    var mechs: Array = pm.get_party_mechs()
    for i in mechs.size():
        if i >= _mech_bars.size():
            break
        var m: Dictionary = mechs[i]
        var bar: Dictionary = _mech_bars[i]
        var max_hp: int = int(m.get("max_hp", 100))
        var hp: int = int(m.get("hp", 0))
        var name: String = String(m.get("name", "?"))

        # Label
        bar["label"].text = "%d. %s  %d/%d" % [i + 1, name, hp, max_hp]

        # HP fill
        var fill: ColorRect = bar["fill"]
        var fill_ratio: float = float(hp) / float(max(max_hp, 1))
        fill.size.x = (BAR_WIDTH - 8) * fill_ratio
        # Color: green > 50%, yellow > 25%, red < 25%
        if fill_ratio > 0.5:
            fill.color = Color(0.2, 0.8, 0.2, 1.0)
        elif fill_ratio > 0.25:
            fill.color = Color(0.8, 0.8, 0.2, 1.0)
        else:
            fill.color = Color(0.8, 0.2, 0.2, 1.0)

        # Active mech: yellow border
        if i == _active_mech_index:
            bar["bg"].color = Color(0.1, 0.05, 0.0, 0.7)
        elif hp <= 0:
            # Knocked out: dimmed gray
            bar["bg"].color = Color(0.1, 0.1, 0.1, 0.5)
        else:
            bar["bg"].color = Color(0.0, 0.0, 0.0, 0.6)

        # Parts indicators: green if all 4 parts > 0, red if any 0
        var parts_hp: Dictionary = m.get("parts_hp", {})
        for p in 4:
            var p_key: String = ["head", "chest", "arms", "legs"][p]
            var p_hp: int = int(parts_hp.get(p_key, 100))
            var p_color: ColorRect = bar["parts"][p]
            if p_hp <= 0:
                p_color.color = Color(0.6, 0.0, 0.0, 0.8)
            else:
                p_color.color = Color(0.3, 0.5, 0.3, 0.8)

# === Signal Handlers ===

func _on_active_mech_changed(new_index: int) -> void:
    _active_mech_index = new_index
    _refresh()

func _on_knocked_out(pilot_id: StringName) -> void:
    _refresh()

func _on_battle_started(_enemy_id: StringName) -> void:
    show()
    _refresh()

func _on_battle_ended(_victory: bool) -> void:
    hide()
