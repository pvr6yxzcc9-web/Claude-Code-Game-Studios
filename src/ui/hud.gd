extends Control

# HUD (per design/ux/hud.md) — Label-based, no _draw (avoids Godot 4.6 HiDPI crash).
# Shows: state badge, fragment counter, weapon slots, mode indicator, HP bar.
# Listens to GameStateMachine, WeaponLoadout, MetaState, BattleCore.

@export var player_hp: int = 100
@export var player_hp_max: int = 100
@export var active_weapon_name: String = "(none)"

var _state_label: String = "EXPLORING"
var _state_color: Color = Color(0.3, 0.8, 1.0, 1)
var _fragment_count: int = 0
var _fragment_total: int = 12
var _mode_label: String = ""

# S2-010: Onboarding hint overlay (room 0 first 10s)
var _hint_label: Label = null
var _hint_timer: SceneTreeTimer = null

# UI elements
var _state_text: Label
var _state_bg: ColorRect
var _frag_text: Label
var _frag_bg: ColorRect
var _slot_bg: Array[ColorRect] = []
var _slot_borders: Array[ColorRect] = []
var _slot_labels: Array[Label] = []
var _slot_name_labels: Array[Label] = []
var _hp_bg: ColorRect
var _hp_fill: ColorRect
var _hp_border: ColorRect
var _hp_text: Label
var _mode_text: Label
# S6-105: speedrun timer
var _timer_text: Label
var _timer_bg: ColorRect

# S6-008: sprite overlays for HUD elements. Text-only HUD is functional
# but reads like a debug build; sprites make it look like a game.
var _weapon_icons: Array[TextureRect] = []  # 3 weapon slot icons
var _fragment_icon: TextureRect
var _mech_part_icons: Dictionary[StringName, TextureRect] = {}  # slot -> icon
# Cached texture for fallback / hot-reload during dev
const _FALLBACK_WEAPON_ICON_PATH := "res://assets/sprites/hud/weapons/%s.png"

# S6-008: load a weapon icon by id. Returns null if sprite not found;
# TextureRect gracefully shows empty if texture is null.
func _load_weapon_icon(weapon_id: StringName) -> Texture2D:
    if weapon_id == &"":
        return null
    var path: String = _FALLBACK_WEAPON_ICON_PATH % String(weapon_id)
    if ResourceLoader.exists(path):
        return load(path)
    return null

# S4-002: mech part status display (under weapon slots)
var _mech_labels: Dictionary[StringName, Label] = {}  # slot_short -> Label
var _mech_active_slot: StringName = &""

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_PASS
    set_anchors_preset(Control.PRESET_FULL_RECT)
    set_process_unhandled_input(true)
    print("[HUD] ready")
    # Top-left state badge
    _state_bg = ColorRect.new()
    _state_bg.color = Color(0, 0, 0, 0.6)
    _state_bg.position = Vector2(8, 8)
    _state_bg.size = Vector2(200, 24)
    add_child(_state_bg)
    _state_text = Label.new()
    _state_text.position = Vector2(14, 10)
    _state_text.add_theme_font_size_override("font_size", 14)
    add_child(_state_text)
    # Top-right fragment counter
    _frag_bg = ColorRect.new()
    _frag_bg.color = Color(0, 0, 0, 0.6)
    _frag_bg.position = Vector2(1280 - 168, 8)
    _frag_bg.size = Vector2(160, 24)
    add_child(_frag_bg)
    _frag_text = Label.new()
    _frag_text.position = Vector2(1280 - 168 + 6, 10)
    _frag_text.add_theme_font_size_override("font_size", 14)
    _frag_text.add_theme_color_override("font_color", Color(0.9, 0.9, 0.5, 1))
    add_child(_frag_text)
    # S6-008: fragment diamond icon
    _fragment_icon = TextureRect.new()
    _fragment_icon.position = Vector2(1280 - 192, 4)
    _fragment_icon.size = Vector2(20, 20)
    _fragment_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    if ResourceLoader.exists("res://assets/sprites/hud/fragment_icon.png"):
        _fragment_icon.texture = load("res://assets/sprites/hud/fragment_icon.png")
    add_child(_fragment_icon)
    # Bottom-left weapon slots (3)
    var slots_y: float = 720 - 80
    for s in 3:
        var slot_x: float = 10.0 + s * 70.0
        var bg: ColorRect = ColorRect.new()
        bg.color = Color(0.1, 0.1, 0.15, 0.85)
        bg.position = Vector2(slot_x, slots_y)
        bg.size = Vector2(64, 64)
        add_child(bg)
        _slot_bg.append(bg)
        var border: ColorRect = ColorRect.new()
        border.color = Color(0.1, 0.1, 0.1, 1)  # active slot = dark backdrop (white text reads cleanly)
        border.color = Color(1, 1, 0.5, 1)
        border.position = Vector2(slot_x - 2, slots_y - 2)
        border.size = Vector2(68, 68)
        border.visible = false
        add_child(border)
        _slot_borders.append(border)
        var lbl: Label = Label.new()
        lbl.text = "[%d]" % (s + 1)
        lbl.position = Vector2(slot_x + 6, slots_y + 0)
        lbl.add_theme_font_size_override("font_size", 12)
        add_child(lbl)
        _slot_labels.append(lbl)
        var name_lbl: Label = Label.new()
        name_lbl.text = "EMPTY"
        name_lbl.position = Vector2(slot_x + 6, slots_y + 22)
        name_lbl.add_theme_font_size_override("font_size", 10)
        name_lbl.add_theme_color_override("font_color", Color.WHITE)
        add_child(name_lbl)
        _slot_name_labels.append(name_lbl)
        # S6-008: weapon sprite icon on each slot
        var icon: TextureRect = TextureRect.new()
        icon.name = "WeaponIcon_%d" % s
        icon.position = Vector2(slot_x, slots_y + 30)
        icon.size = Vector2(64, 24)
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        add_child(icon)
        _weapon_icons.append(icon)
    # Bottom-right HP bar
    var bar_w: float = 200.0
    var bar_h: float = 18.0
    var bar_x: float = 1280 - bar_w - 10
    var bar_y: float = 720 - 50
    _hp_bg = ColorRect.new()
    _hp_bg.color = Color(0.15, 0.15, 0.15, 1)
    _hp_bg.position = Vector2(bar_x, bar_y)
    _hp_bg.size = Vector2(bar_w, bar_h)
    add_child(_hp_bg)
    _hp_fill = ColorRect.new()
    _hp_fill.position = Vector2(bar_x, bar_y)
    _hp_fill.size = Vector2(bar_w, bar_h)
    add_child(_hp_fill)
    _hp_border = ColorRect.new()
    _hp_border.color = Color(0.4, 0.4, 0.4, 1)
    _hp_border.position = Vector2(bar_x, bar_y)
    _hp_border.size = Vector2(bar_w, bar_h)
    add_child(_hp_border)
    _hp_text = Label.new()
    _hp_text.text = "HP 100 / 100"
    _hp_text.position = Vector2(bar_x + 6, bar_y)
    _hp_text.add_theme_font_size_override("font_size", 12)
    add_child(_hp_text)
    # Mode indicator (above HP, shown only in battle)
    _mode_text = Label.new()
    _mode_text.position = Vector2(bar_x, bar_y - 18)
    _mode_text.add_theme_font_size_override("font_size", 14)
    _mode_text.visible = false
    add_child(_mode_text)
    # S6-105: speedrun timer (top-center)
    _timer_bg = ColorRect.new()
    _timer_bg.color = Color(0, 0, 0, 0.6)
    _timer_bg.position = Vector2(560, 8)
    _timer_bg.size = Vector2(160, 24)
    _timer_bg.visible = false
    add_child(_timer_bg)
    _timer_text = Label.new()
    _timer_text.position = Vector2(566, 12)
    _timer_text.add_theme_font_size_override("font_size", 16)
    _timer_text.add_theme_color_override("font_color", Color(1, 1, 0.5, 1))
    _timer_text.text = "00:00.000"
    _timer_text.visible = false
    add_child(_timer_text)
    # S4-002: mech part status row, 3 columns (T=torso, L=arm, R=arm).
    # Active slot (after Q cycle) is highlighted yellow; inactive is dim gray.
    var mech_y: float = 712.0
    var mech_x: float = 10.0
    var mech_slot_keys: Array[StringName] = [&"T", &"L", &"R"]
    for k in mech_slot_keys:
        var mlbl: Label = Label.new()
        mlbl.add_theme_font_size_override("font_size", 11)
        mlbl.position = Vector2(mech_x, mech_y)
        mlbl.text = "%s:-" % k
        add_child(mlbl)
        _mech_labels[k] = mlbl
        mech_x += 60.0
    _refresh_mech_status()
    # Wire listeners
    var sm: Node = get_node_or_null("/root/GameStateMachine")
    if sm != null:
        sm.state_changed.connect(_on_state_changed)
        _refresh_state(sm.top_of_stack)
    var loadout: Node = get_node_or_null("/root/WeaponLoadout")
    if loadout != null:
        loadout.weapon_changed.connect(_on_weapon_changed)
        loadout.attack_triggered.connect(_on_attack)
        # S4-007: reflect auto/manual mode in HUD mode label
        loadout.mode_changed.connect(_on_mode_changed)
        _mode_label = "MANUAL"  # default; toggle_mode() flips to "AUTO"
    var meta: Node = get_node_or_null("/root/MetaState")
    if meta != null:
        # S2-005: subscribe so HUD counter updates live when a fragment is
        # unlocked mid-play (terminal open or dialogue choice), not just on
        # next manual _refresh_fragments() call.
        meta.fragment_unlocked.connect(_on_fragment_unlocked)
        _refresh_fragments(meta)
    var input_bus: Node = get_node_or_null("/root/InputBus")
    if input_bus != null:
        input_bus.action_pressed.connect(_on_action_pressed)
    _refresh()

func _on_action_pressed(_action: StringName) -> void:
    pass

func _on_state_changed(_old: StringName, new: StringName) -> void:
    _refresh_state(new)
    _refresh()

func _refresh_state(state: StringName) -> void:
    # S6-017: state badge labels are localized
    var loc: Node = get_node_or_null("/root/Localization")
    match String(state):
        "state_title":
            _state_label = loc.t(&"ui.hud.state.title") if loc != null else "TITLE"
            _state_color = Color(0.5, 0.5, 0.5, 1)
            _state_bg.color = Color(0, 0, 0, 0.6)
        "state_exploration":
            _state_label = loc.t(&"ui.hud.state.exploring") if loc != null else "EXPLORING"
            _state_color = Color(0.3, 0.8, 1.0, 1)
            _state_bg.color = Color(0, 0, 0, 0.6)
        "state_battle":
            _state_label = loc.t(&"ui.hud.state.in_battle") if loc != null else "IN BATTLE"
            _state_color = Color(1.0, 0.3, 0.3, 1)
            _state_bg.color = Color(0, 0, 0, 0.6)
        "state_menu", "state_pause":
            _state_label = loc.t(&"ui.hud.state.paused") if loc != null else "PAUSED"
            _state_color = Color(0.9, 0.9, 0.3, 1)
            _state_bg.color = Color(0.3, 0.3, 0, 0.85)
        "state_dialogue":
            _state_label = loc.t(&"ui.hud.state.dialogue") if loc != null else "DIALOGUE"
            _state_color = Color(0.6, 0.4, 0.9, 1)
        "state_terminal":
            _state_label = loc.t(&"ui.hud.state.terminal") if loc != null else "TERMINAL"
            _state_color = Color(0.3, 0.9, 0.6, 1)
        "state_codex":
            _state_label = loc.t(&"ui.hud.state.codex") if loc != null else "CODEX"
            _state_color = Color(0.4, 0.7, 0.9, 1)
        "state_save_load":
            _state_label = loc.t(&"ui.hud.state.save_load") if loc != null else "SAVE/LOAD"
            _state_color = Color(0.7, 0.7, 0.7, 1)
        "state_game_over":
            _state_label = loc.t(&"ui.hud.state.game_over") if loc != null else "GAME OVER"
            _state_color = Color(0.9, 0.1, 0.1, 1)
        _:
            _state_label = String(state).to_upper()
            _state_color = Color(0.7, 0.7, 0.7, 1)
    if String(state) == "state_battle":
        _mode_label = loc.t(&"ui.hud.mode_manual") if loc != null else "MANUAL"
    else:
        _mode_label = ""

# S6-002: ESC dismisses current tutorial hint. The hint auto-hides anyway
# (via show_hint's timer), but ESC lets experienced players skip faster.
func _unhandled_input(event: InputEvent) -> void:
    if not (event is InputEventKey and event.pressed):
        return
    if event.keycode != KEY_ESCAPE:
        return
    var tutorial: Node = get_node_or_null("/root/TutorialManager")
    if tutorial == null:
        return
    if tutorial.has_method("is_active") and tutorial.is_active():
        if tutorial.has_method("dismiss_current"):
            tutorial.dismiss_current()
        get_viewport().set_input_as_handled()

func _refresh_fragments(_meta: Node) -> void:
    var live_size: int = 0
    # S5-006 fix: "unlocked" is a VAR (property), not a method. has_method
    # returns false for properties. Use the `in` operator to check
    # property existence, then read .size() directly.
    if "unlocked" in _meta:
        live_size = _meta.unlocked.size()
    _fragment_count = live_size
    _fragment_total = 12
    if _frag_text != null:
        var loc: Node = get_node_or_null("/root/Localization")
        var fmt: String = loc.t(&"ui.hud.fragments") if loc != null else "FRAGMENTS: %d/%d"
        _frag_text.text = fmt % [_fragment_count, _fragment_total]

# S2-005: live-update fragment counter when a fragment is unlocked mid-play
# (terminal open, dialogue choice). mark_unlocked() in MetaState is the only
# state writer; this handler is display-only.
func _on_fragment_unlocked(_frag_id: StringName) -> void:
    var meta: Node = get_node_or_null("/root/MetaState")
    if meta != null:
        _refresh_fragments(meta)

func _on_weapon_changed(slot: int, _weapon_id: StringName) -> void:
    _refresh()

func _on_attack(_slot: int) -> void:
    _refresh()

func set_mode(mode: String) -> void:
    _mode_label = mode
    _refresh()

# S4-007: mirror WeaponLoadout mode into HUD label
func _on_mode_changed(new_mode: StringName) -> void:
    _mode_label = String(new_mode)
    _refresh()

func set_hp(current: int, max_hp: int) -> void:
    player_hp = current
    player_hp_max = max_hp
    _refresh()

func _refresh() -> void:
    _state_text.text = _state_label
    _state_text.add_theme_color_override("font_color", _state_color)
    var loc3: Node = get_node_or_null("/root/Localization")
    var frag_fmt: String = loc3.t(&"ui.hud.fragments") if loc3 != null else "FRAGMENTS: %d/%d"
    _frag_text.text = frag_fmt % [_fragment_count, _fragment_total]
    # Weapon slots
    var loadout: Node = get_node_or_null("/root/WeaponLoadout")
    if loadout != null:
        for s in 3:
            var is_active: bool = s == loadout.active_slot
            _slot_borders[s].visible = is_active
            # Active = dark text on yellow border (high contrast); inactive = gray text.
            var slot_color: Color = Color(0.05, 0.05, 0.05, 1) if is_active else Color(0.65, 0.65, 0.65, 1)
            _slot_labels[s].add_theme_color_override("font_color", slot_color)
            var name_color: Color = Color(1, 1, 1, 1) if is_active else Color(0.45, 0.45, 0.45, 1)
            _slot_name_labels[s].add_theme_color_override("font_color", name_color)
            _slot_name_labels[s].text = _slot_name(loadout.weapon_slots[s])
            # S6-008: load weapon icon sprite
            var wid: StringName = loadout.weapon_slots[s]
            if s < _weapon_icons.size():
                _weapon_icons[s].texture = _load_weapon_icon(wid)
    # HP bar
    var ratio: float = float(player_hp) / float(player_hp_max) if player_hp_max > 0 else 0.0
    var bar_w: float = 200.0
    var hp_color: Color
    if ratio > 0.5:
        hp_color = Color(0.2, 0.8, 0.2)
    elif ratio > 0.25:
        hp_color = Color(0.8, 0.8, 0.2)
    else:
        hp_color = Color(0.8, 0.2, 0.2)
    _hp_fill.color = hp_color
    _hp_fill.size.x = bar_w * ratio
    var loc4: Node = get_node_or_null("/root/Localization")
    var hp_fmt: String = loc4.t(&"ui.hud.hp") if loc4 != null else "HP %d / %d"
    _hp_text.text = hp_fmt % [player_hp, player_hp_max]
    # Mode indicator
    if _mode_label != "":
        var loc5: Node = get_node_or_null("/root/Localization")
        var mode_fmt: String = loc5.t(&"ui.hud.mode_label") if loc5 != null else "MODE: [%s]  (M to toggle)"
        _mode_text.text = mode_fmt % _mode_label
        var is_manual: bool = _mode_label == loc5.t(&"ui.hud.mode_manual") if loc5 != null else _mode_label == "MANUAL"
        _mode_text.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0) if is_manual else Color(1.0, 0.6, 0.3))
        _mode_text.visible = true
    else:
        _mode_text.visible = false
    # S6-105: speedrun timer
    var st: Node = get_node_or_null("/root/SpeedrunTimer")
    if st != null and _timer_text != null:
        if st.is_running() or st.get_elapsed_ms() > 0:
            var ms: int = st.get_elapsed_ms()
            _timer_text.text = st.format_time(ms)
            _timer_text.visible = true
            if _timer_bg != null:
                _timer_bg.visible = true
        else:
            _timer_text.visible = false
            if _timer_bg != null:
                _timer_bg.visible = false

func _slot_name(weapon_id: StringName) -> String:
    if weapon_id == &"":
        return "EMPTY"
    var reg: Node = get_node("/root/ResourceRegistry")
    var w: Resource = reg.get_resource(weapon_id)
    if w == null:
        return String(weapon_id)
    return String(w.get("display_name"))

# S2-010: Onboarding hint overlay
func show_hint(text: String, duration: float = 10.0) -> void:
    if _hint_label == null:
        _hint_label = Label.new()
        _hint_label.name = "OnboardingHint"
        _hint_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
        _hint_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
        _hint_label.add_theme_constant_override("outline_size", 4)
        _hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        _hint_label.anchor_left = 0.0
        _hint_label.anchor_right = 1.0
        _hint_label.anchor_top = 0.5
        _hint_label.anchor_bottom = 0.5
        _hint_label.offset_top = -40
        _hint_label.offset_bottom = 40
        add_child(_hint_label)
    _hint_label.text = text
    _hint_label.show()
    if _hint_timer != null and _hint_timer.timeout.is_connected(_hide_hint):
        _hint_timer.timeout.disconnect(_hide_hint)
    _hint_timer = get_tree().create_timer(duration)
    _hint_timer.timeout.connect(_hide_hint)

func _hide_hint() -> void:
    if _hint_label != null:
        _hint_label.hide()

# S6-002: immediate hide (called by TutorialManager when player presses ESC)
func hide_hint() -> void:
    if _hint_label != null:
        _hint_label.hide()
    if _hint_timer != null and _hint_timer.timeout.is_connected(_hide_hint):
        _hint_timer.timeout.disconnect(_hide_hint)

# S4-002: mech part display + cycle handler.
# Each label is a 1-letter slot indicator (T/L/R) + the part's display_name
# (abbreviated to 6 chars to fit 60px column).
func _refresh_mech_status() -> void:
    var mech: Node = get_node_or_null("/root/MechLoadout")
    if mech == null:
        return
    # Map: 1-letter display -> full slot name in MechLoadout.SLOTS
    var slot_map: Dictionary = {
        &"T": &"torso",
        &"L": &"left_arm",
        &"R": &"right_arm",
    }
    for short_key in slot_map:
        var full_slot: StringName = slot_map[short_key]
        var part_id: StringName = mech.parts.get(full_slot, &"")
        var label: Label = _mech_labels.get(short_key, null)
        if label == null:
            continue
        if part_id == &"":
            label.text = "%s:-" % short_key
            label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
        else:
            var reg: Node = get_node("/root/ResourceRegistry")
            var part_res: Resource = reg.get_resource(part_id)
            var short_name: String = String(part_id) if part_res == null else String(part_res.get("display_name"))
            if short_name.length() > 6:
                short_name = short_name.substr(0, 6)
            label.text = "%s:%s" % [short_key, short_name]
            # Active slot = highlighted yellow
            if full_slot == _mech_active_slot:
                label.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
            else:
                label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))

# Called by LevelRuntime._unhandled_input after Q is pressed in exploration.
# Public so tests can drive it directly.
func _on_mech_cycled(slot: StringName, _part_id: StringName) -> void:
    _mech_active_slot = slot
    _refresh_mech_status()
