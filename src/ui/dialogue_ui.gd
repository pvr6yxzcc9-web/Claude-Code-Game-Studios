extends Control

# DialogueUI (per npc-terminal.md) — Label-based, no _draw (avoids Godot 4.6 HiDPI crash).
# Shows current node text + 1-3 choices. Listens to DialogueManager.
# S3-003: W/S or Up/Down changes focused choice; current focus is highlighted.
# S6-100: animated NPC portrait (lip-sync + eye-blink) on the left side of
# the dialogue box. Mouth alternates closed/open every 0.4s; eye-blink
# fires ~every 1.5s for 0.1s.

@export var speaker_name: String = ""
@export var current_text: String = ""
@export var current_choices: Array = []

const LIP_SYNC_INTERVAL: float = 0.4
const BLINK_INTERVAL: float = 0.3
const BLINK_CHANCE: float = 0.18

var _bg: ColorRect
var _border: ColorRect
var _speaker_label: Label
var _body_labels: Array[Label] = []
var _choice_labels: Array[Label] = []
var _choice_focus: int = 0

# S6-100: animated portrait
var _portrait_panel: PanelContainer
var _portrait: TextureRect
var _current_npc_id: StringName = &""
var _mouth_open: bool = false
var _blinking: bool = false
var _lip_sync_timer: SceneTreeTimer = null
var _blink_timer: SceneTreeTimer = null
var _blink_recover_timer: SceneTreeTimer = null
const _PORTRAIT_BASE := "res://assets/sprites/npcs/"

func _ready() -> void:
    visible = false
    set_anchors_preset(Control.PRESET_FULL_RECT)
    # Background panel
    _bg = ColorRect.new()
    _bg.color = Color(0.05, 0.05, 0.1, 0.95)
    _bg.position = Vector2(190, 290)
    _bg.size = Vector2(900, 400)
    add_child(_bg)
    # Top accent stripe
    _border = ColorRect.new()
    _border.color = Color(1.0, 0.8, 0.4, 1)
    _border.position = _bg.position
    _border.size = Vector2(_bg.size.x, 2)
    add_child(_border)
    var bottom_border: ColorRect = ColorRect.new()
    bottom_border.color = Color(1.0, 0.8, 0.4, 1)
    bottom_border.position = Vector2(_bg.position.x, _bg.position.y + _bg.size.y - 2)
    bottom_border.size = Vector2(_bg.size.x, 2)
    add_child(bottom_border)
    # S6-100: portrait panel (left side of dialogue box)
    _portrait_panel = PanelContainer.new()
    _portrait_panel.size = Vector2(160, 160)
    _portrait_panel.position = _bg.position + Vector2(20, 50)
    var portrait_stylebox: StyleBoxFlat = StyleBoxFlat.new()
    portrait_stylebox.bg_color = Color(0.08, 0.08, 0.15, 1.0)
    portrait_stylebox.border_color = Color(0.6, 0.4, 0.2, 1)
    portrait_stylebox.border_width_left = 2
    portrait_stylebox.border_width_right = 2
    portrait_stylebox.border_width_top = 2
    portrait_stylebox.border_width_bottom = 2
    _portrait_panel.add_theme_stylebox_override("panel", portrait_stylebox)
    add_child(_portrait_panel)
    _portrait = TextureRect.new()
    _portrait.size = Vector2(160, 160)
    _portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _portrait_panel.add_child(_portrait)
    # Speaker — shifted right to make room for portrait
    _speaker_label = Label.new()
    _speaker_label.add_theme_font_size_override("font_size", 18)
    _speaker_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 1))
    _speaker_label.position = _bg.position + Vector2(200, 35)
    add_child(_speaker_label)
    # Listen
    var dm: Node = get_node_or_null("/root/DialogueManager")
    if dm != null:
        dm.dialogue_started.connect(_on_dialogue_started)
        dm.node_entered.connect(_on_node_entered)
        dm.dialogue_ended.connect(_on_dialogue_ended)
        # S3-003: also listen to choice_made to keep our focus index in sync
        if dm.has_signal("choice_made"):
            dm.choice_made.connect(_on_choice_made)
    var sm: Node = get_node("/root/GameStateMachine")
    sm.state_changed.connect(_on_state_changed)
    print("[DialogueUI] ready")

func _on_state_changed(_old: StringName, new: StringName) -> void:
    visible = (new == &"state_dialogue")
    if visible:
        _choice_focus = 0
        _refresh_focus()
    else:
        _stop_animation()

func _on_dialogue_started(npc: Resource) -> void:
    _choice_focus = 0
    # S6-100: load NPC portrait for animation
    if npc != null and "id" in npc:
        _current_npc_id = StringName(npc.get("id"))
    else:
        _current_npc_id = &""
    _load_portrait_frame()
    _start_animation()
    _refresh()

func _on_node_entered(_node_id: StringName, text: String, choices: Array) -> void:
    current_text = text
    current_choices = choices
    _choice_focus = 0
    _refresh()

func _on_dialogue_ended() -> void:
    current_text = ""
    current_choices = []
    _clear_body_labels()
    _clear_choice_labels()

func _on_choice_made(idx: int) -> void:
    # When 1/2/3 fires DialogueManager.choose(idx), reflect that in our focus index
    # so the highlighted option matches what the player just selected.
    _choice_focus = idx
    _refresh_focus()

func _clear_body_labels() -> void:
    for lbl in _body_labels:
        lbl.queue_free()
    _body_labels.clear()

func _clear_choice_labels() -> void:
    for lbl in _choice_labels:
        lbl.queue_free()
    _choice_labels.clear()

func _refresh() -> void:
    _speaker_label.text = speaker_name
    _clear_body_labels()
    _clear_choice_labels()
    var base_pos: Vector2 = _bg.position + Vector2(20, 70)
    # Word-wrap body
    var words: PackedStringArray = current_text.split(" ")
    var line: String = ""
    var y: float = 0.0
    for w in words:
        var test: String = line + " " + w if line != "" else w
        if test.length() > 80:
            var lbl: Label = Label.new()
            lbl.text = line
            lbl.add_theme_font_size_override("font_size", 16)
            lbl.add_theme_color_override("font_color", Color.WHITE)
            lbl.position = base_pos + Vector2(0, y)
            add_child(lbl)
            _body_labels.append(lbl)
            y += 22
            line = w
        else:
            line = test
    if line != "":
        var lbl: Label = Label.new()
        lbl.text = line
        lbl.add_theme_font_size_override("font_size", 16)
        lbl.add_theme_color_override("font_color", Color.WHITE)
        lbl.position = base_pos + Vector2(0, y)
        add_child(lbl)
        _body_labels.append(lbl)
        y += 30
    # Choices
    for i in current_choices.size():
        var choice: Dictionary = current_choices[i]
        var clbl: Label = Label.new()
        clbl.add_theme_font_size_override("font_size", 15)
        clbl.position = base_pos + Vector2(20, y)
        add_child(clbl)
        _choice_labels.append(clbl)
        y += 22
    _refresh_focus()

func _refresh_focus() -> void:
    for i in _choice_labels.size():
        var clbl: Label = _choice_labels[i]
        var choice: Dictionary = current_choices[i] if i < current_choices.size() else {}
        var label_text: String = String(choice.get("label", ""))
        if i == _choice_focus:
            clbl.text = "> [%d] %s" % [i + 1, label_text]
            clbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5, 1))
            clbl.add_theme_font_size_override("font_size", 17)  # slightly larger when focused
        else:
            clbl.text = "  [%d] %s" % [i + 1, label_text]
            clbl.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5, 1))
            clbl.add_theme_font_size_override("font_size", 15)

func _unhandled_input(event: InputEvent) -> void:
    if not visible:
        return
    var dm: Node = get_node("/root/DialogueManager")
    if current_choices.is_empty():
        # S5-006: ending dialogues have 0 choices. Player must be able
        # to close the dialogue with ESC, ENTER, or SPACE so they can
        # return to the exploration state and see the ending credits.
        var is_esc: bool = event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed
        var is_close: bool = event.is_action_pressed("ui_cancel") \
            or event.is_action_pressed("ui_accept") \
            or (event is InputEventKey and event.keycode == KEY_SPACE and event.pressed)
        if is_esc or is_close:
            if dm != null and dm.has_method("end_dialogue"):
                dm.end_dialogue()
            get_viewport().set_input_as_handled()
        return
    if event.is_action_pressed("move_up") or (event is InputEventKey and event.keycode == KEY_W and event.pressed):
        _choice_focus = (_choice_focus - 1 + current_choices.size()) % current_choices.size()
        _refresh_focus()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("move_down") or (event is InputEventKey and event.keycode == KEY_S and event.pressed):
        _choice_focus = (_choice_focus + 1) % current_choices.size()
        _refresh_focus()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("ui_accept") or (event is InputEventKey and event.keycode == KEY_ENTER and event.pressed):
        # Confirm the currently-focused choice
        if dm != null and dm.has_method("choose"):
            dm.choose(_choice_focus)
        get_viewport().set_input_as_handled()

# S6-100: load the appropriate portrait frame based on _mouth_open + _blinking.
# Path priority: open_blink > blink (if blinking) > open (if mouth_open) > base.
func _load_portrait_frame() -> void:
    if _portrait == null:
        return
    if _current_npc_id == &"":
        _portrait.texture = null
        return
    var base: String = _PORTRAIT_BASE + String(_current_npc_id) + ".png"
    var path: String = base
    if _blinking and _mouth_open:
        var candidate: String = _PORTRAIT_BASE + String(_current_npc_id) + "_mouth_open_blink.png"
        if ResourceLoader.exists(candidate):
            path = candidate
    elif _blinking:
        var candidate: String = _PORTRAIT_BASE + String(_current_npc_id) + "_eyes_blink.png"
        if ResourceLoader.exists(candidate):
            path = candidate
    elif _mouth_open:
        var candidate: String = _PORTRAIT_BASE + String(_current_npc_id) + "_mouth_open.png"
        if ResourceLoader.exists(candidate):
            path = candidate
    if ResourceLoader.exists(path):
        _portrait.texture = load(path)
    else:
        _portrait.texture = null

# S6-100: start the lip-sync and blink timers. Called when dialogue opens.
func _start_animation() -> void:
    _mouth_open = false
    _blinking = false
    if _lip_sync_timer != null and _lip_sync_timer.timeout.is_connected(_on_lip_sync_tick):
        _lip_sync_timer.timeout.disconnect(_on_lip_sync_tick)
    _lip_sync_timer = get_tree().create_timer(LIP_SYNC_INTERVAL)
    _lip_sync_timer.timeout.connect(_on_lip_sync_tick)
    if _blink_timer != null and _blink_timer.timeout.is_connected(_on_blink_tick):
        _blink_timer.timeout.disconnect(_on_blink_tick)
    _blink_timer = get_tree().create_timer(BLINK_INTERVAL)
    _blink_timer.timeout.connect(_on_blink_tick)

# S6-100: stop timers when dialogue ends.
func _stop_animation() -> void:
    if _lip_sync_timer != null and _lip_sync_timer.timeout.is_connected(_on_lip_sync_tick):
        _lip_sync_timer.timeout.disconnect(_on_lip_sync_tick)
    if _blink_timer != null and _blink_timer.timeout.is_connected(_on_blink_tick):
        _blink_timer.timeout.disconnect(_on_blink_tick)
    if _blink_recover_timer != null and _blink_recover_timer.timeout.is_connected(_on_blink_recover):
        _blink_recover_timer.timeout.disconnect(_on_blink_recover)
    _mouth_open = false
    _blinking = false
    _current_npc_id = &""
    if _portrait != null:
        _portrait.texture = null

# S6-100: lip-sync tick — flip mouth state, reload frame, schedule next tick.
func _on_lip_sync_tick() -> void:
    _mouth_open = not _mouth_open
    _load_portrait_frame()
    if _lip_sync_timer != null and _lip_sync_timer.timeout.is_connected(_on_lip_sync_tick):
        _lip_sync_timer.timeout.disconnect(_on_lip_sync_tick)
    _lip_sync_timer = get_tree().create_timer(LIP_SYNC_INTERVAL)
    _lip_sync_timer.timeout.connect(_on_lip_sync_tick)

# S6-100: blink tick — chance of starting a blink, schedule next tick.
func _on_blink_tick() -> void:
    if not _blinking and randf() < BLINK_CHANCE:
        _blinking = true
        _load_portrait_frame()
        # Recover after a short blink (0.1s)
        if _blink_recover_timer != null and _blink_recover_timer.timeout.is_connected(_on_blink_recover):
            _blink_recover_timer.timeout.disconnect(_on_blink_recover)
        _blink_recover_timer = get_tree().create_timer(0.1)
        _blink_recover_timer.timeout.connect(_on_blink_recover)
    if _blink_timer != null and _blink_timer.timeout.is_connected(_on_blink_tick):
        _blink_timer.timeout.disconnect(_on_blink_tick)
    _blink_timer = get_tree().create_timer(BLINK_INTERVAL)
    _blink_timer.timeout.connect(_on_blink_tick)

func _on_blink_recover() -> void:
    _blinking = false
    _load_portrait_frame()
