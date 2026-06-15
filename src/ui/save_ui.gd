extends Control

# SaveUI (per save-load.md) — Label-based, no _draw (avoids Godot 4.6 HiDPI crash).
# 3 manual save slots + load button. Listen to InputBus for "pause" (open) / "interact" (select).

@export var selected_slot: int = 0
const SLOT_COUNT: int = 3
const SLOT_LABELS: Array[String] = ["Slot 1", "Slot 2", "Slot 3"]

signal slot_saved(slot: int)
signal slot_loaded(slot: int)

var is_open: bool = false
var _bg: ColorRect
var _title_label: Label
var _slot_labels: Array[Label] = []
var _highlight: ColorRect
var _footer1: Label
var _footer2: Label

# Panel geometry (exposed as constants so _refresh() can keep highlight in sync)
const PANEL_W: float = 600.0
const PANEL_H: float = 400.0
const PANEL_X: float = (1280.0 - PANEL_W) / 2.0  # 340
const PANEL_Y: float = (720.0 - PANEL_H) / 2.0   # 160
const SLOT_ROW_Y_OFFSET: float = 80.0  # first slot row Y is PANEL_Y + this
const SLOT_ROW_SPACING: float = 40.0

func _ready() -> void:
    visible = false
    set_anchors_preset(Control.PRESET_FULL_RECT)
    _bg = ColorRect.new()
    _bg.color = Color(0.05, 0.05, 0.1, 0.95)
    _bg.position = Vector2(PANEL_X, PANEL_Y)
    _bg.size = Vector2(PANEL_W, PANEL_H)
    add_child(_bg)
    var top: ColorRect = ColorRect.new()
    top.color = Color(0.5, 1.0, 0.5, 1)
    top.position = _bg.position
    top.size = Vector2(PANEL_W, 2)
    add_child(top)
    var bot: ColorRect = ColorRect.new()
    bot.color = Color(0.5, 1.0, 0.5, 1)
    bot.position = Vector2(PANEL_X, PANEL_Y + PANEL_H - 2)
    bot.size = Vector2(PANEL_W, 2)
    add_child(bot)
    _title_label = Label.new()
    _title_label.text = "SAVE / LOAD"
    _title_label.add_theme_font_size_override("font_size", 20)
    _title_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5, 1))
    _title_label.position = Vector2(PANEL_X + 20, PANEL_Y + 35)
    add_child(_title_label)
    _highlight = ColorRect.new()
    _highlight.color = Color(0.3, 0.3, 0.0, 0.5)
    _highlight.position = Vector2(PANEL_X + 10, PANEL_Y + SLOT_ROW_Y_OFFSET)
    _highlight.size = Vector2(PANEL_W - 20, 32)
    add_child(_highlight)
    for i in SLOT_COUNT:
        var lbl: Label = Label.new()
        lbl.add_theme_font_size_override("font_size", 16)
        lbl.position = Vector2(PANEL_X + 30, PANEL_Y + SLOT_ROW_Y_OFFSET + i * SLOT_ROW_SPACING)
        add_child(lbl)
        _slot_labels.append(lbl)
    _footer1 = Label.new()
    _footer1.text = "[E] Save current slot  |  [Enter] Load slot"
    _footer1.add_theme_font_size_override("font_size", 14)
    _footer1.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
    _footer1.position = Vector2(PANEL_X + 20, PANEL_Y + PANEL_H - 50)
    add_child(_footer1)
    _footer2 = Label.new()
    _footer2.text = "[Esc] Close  |  [Up/Down] Select slot"
    _footer2.add_theme_font_size_override("font_size", 14)
    _footer2.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
    _footer2.position = Vector2(PANEL_X + 20, PANEL_Y + PANEL_H - 30)
    add_child(_footer2)
    var input_bus: Node = get_node_or_null("/root/InputBus")
    if input_bus != null:
        input_bus.action_pressed.connect(_on_action_pressed)
    print("[SaveUI] ready")

func _on_action_pressed(action: StringName) -> void:
    if not is_open:
        return
    match action:
        &"interact":
            save_slot(selected_slot)
        &"menu_select":
            load_slot(selected_slot)
        &"menu_cancel":
            close()
        &"menu_up":
            selected_slot = (selected_slot - 1) % SLOT_COUNT
            _refresh()
        &"menu_down":
            selected_slot = (selected_slot + 1) % SLOT_COUNT
            _refresh()

func open() -> void:
    is_open = true
    visible = true
    _refresh()

func close() -> void:
    is_open = false
    visible = false

func save_slot(slot: int) -> void:
    var save: Node = get_node("/root/SaveManager")
    save.save_to_slot(slot)
    slot_saved.emit(slot)
    _refresh()

func load_slot(slot: int) -> void:
    var save: Node = get_node("/root/SaveManager")
    var err: int = save.load_from_slot(slot)
    if err == OK:
        slot_loaded.emit(slot)
        close()
    else:
        _refresh()

func _refresh() -> void:
    var save: Node = get_node("/root/SaveManager")
    # Move highlight to the selected slot row. Must use the same Y formula as
    # the slot label creation above (PANEL_Y + SLOT_ROW_Y_OFFSET + i * SLOT_ROW_SPACING)
    # otherwise the highlight drifts off the slot list. (S3-010 fix — was 60+i*40,
    # which is absolute y, not relative to the panel.)
    _highlight.position.y = PANEL_Y + SLOT_ROW_Y_OFFSET + selected_slot * SLOT_ROW_SPACING
    for i in SLOT_COUNT:
        var exists: bool = FileAccess.file_exists(save._slot_to_path(i))
        var label_text: String = "%s  [%s]" % [SLOT_LABELS[i], "saved" if exists else "empty"]
        _slot_labels[i].text = label_text
        if i == selected_slot:
            _slot_labels[i].add_theme_color_override("font_color", Color(1, 1, 0.5, 1))
        else:
            _slot_labels[i].add_theme_color_override("font_color", Color.WHITE)
