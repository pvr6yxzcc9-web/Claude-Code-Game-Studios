extends Control

# TerminalUI (per npc-terminal.md) — Label-based, no _draw (avoids Godot 4.6 HiDPI crash).
# Shows log title + body. Reads from TerminalController.

@export var log_title: String = ""
@export var log_body: String = ""

var _bg: ColorRect
var _title_label: Label
var _body_labels: Array[Label] = []
var _footer_label: Label

func _ready() -> void:
    visible = false
    set_anchors_preset(Control.PRESET_FULL_RECT)
    # Per close affordance: ESC or E closes the terminal. Without this, the
    # UI shows "[ESC] to close" but the player is stuck. Two binding paths
    # (the documented ESC and the E they were already pressing in exploration).
    set_process_unhandled_input(true)
    # Panel background
    _bg = ColorRect.new()
    _bg.color = Color(0.05, 0.05, 0.1, 0.95)
    _bg.position = Vector2(190, 60)
    _bg.size = Vector2(900, 600)
    add_child(_bg)
    # Top + bottom border stripes
    var top: ColorRect = ColorRect.new()
    top.color = Color(0.4, 0.6, 1.0, 1)
    top.position = _bg.position
    top.size = Vector2(_bg.size.x, 2)
    add_child(top)
    var bot: ColorRect = ColorRect.new()
    bot.color = Color(0.4, 0.6, 1.0, 1)
    bot.position = Vector2(_bg.position.x, _bg.position.y + _bg.size.y - 2)
    bot.size = Vector2(_bg.size.x, 2)
    add_child(bot)
    # Title
    _title_label = Label.new()
    _title_label.add_theme_font_size_override("font_size", 20)
    _title_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0, 1))
    _title_label.position = _bg.position + Vector2(20, 40)
    add_child(_title_label)
    # Footer
    _footer_label = Label.new()
    var loc: Node = get_node_or_null("/root/Localization")
    _footer_label.text = loc.t(&"ui.terminal.footer") if loc != null else "[ESC] to close"
    _footer_label.add_theme_font_size_override("font_size", 14)
    _footer_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
    _footer_label.position = _bg.position + Vector2(20, _bg.size.y - 30)
    add_child(_footer_label)
    # Listen
    var tc: Node = get_node_or_null("/root/TerminalController")
    if tc != null:
        tc.terminal_opened.connect(_on_terminal_opened)
        tc.terminal_closed.connect(_on_terminal_closed)
    var sm: Node = get_node("/root/GameStateMachine")
    sm.state_changed.connect(_on_state_changed)
    print("[TerminalUI] ready")

func _on_state_changed(_old: StringName, new: StringName) -> void:
    visible = (new == &"state_terminal")

func _unhandled_input(event: InputEvent) -> void:
    if not visible:
        return
    var sm: Node = get_node("/root/GameStateMachine")
    if sm == null or sm.top_of_stack != &"state_terminal":
        return
    # ESC keycode or the "ui_cancel" / "interact" action both close.
    var is_esc: bool = event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed
    var is_cancel: bool = event.is_action_pressed("ui_cancel")
    var is_interact: bool = event.is_action_pressed("interact")
    if is_esc or is_cancel or is_interact:
        var tc: Node = get_node("/root/TerminalController")
        if tc != null:
            tc.close()
        sm.transition_to(&"state_exploration")
        get_viewport().set_input_as_handled()

func _on_terminal_opened(log: Resource) -> void:
    log_title = String(log.get("title"))
    log_body = String(log.get("body"))
    _refresh()

func _on_terminal_closed() -> void:
    log_title = ""
    log_body = ""

func _clear_body_labels() -> void:
    for lbl in _body_labels:
        lbl.queue_free()
    _body_labels.clear()

func _refresh() -> void:
    _title_label.text = log_title
    _clear_body_labels()
    var max_chars_per_line: int = 80
    var y_offset: int = 80
    var words: PackedStringArray = log_body.split(" ")
    var current_line: String = ""
    for w in words:
        var test_line: String = current_line + " " + w if current_line != "" else w
        if test_line.length() > max_chars_per_line:
            var lbl: Label = Label.new()
            lbl.text = current_line
            lbl.add_theme_font_size_override("font_size", 16)
            lbl.add_theme_color_override("font_color", Color.WHITE)
            lbl.position = _bg.position + Vector2(20, y_offset)
            add_child(lbl)
            _body_labels.append(lbl)
            y_offset += 22
            current_line = w
        else:
            current_line = test_line
    if current_line != "":
        var lbl: Label = Label.new()
        lbl.text = current_line
        lbl.add_theme_font_size_override("font_size", 16)
        lbl.add_theme_color_override("font_color", Color.WHITE)
        lbl.position = _bg.position + Vector2(20, y_offset)
        add_child(lbl)
        _body_labels.append(lbl)
