extends Control

# PostCreditScene (S10-014..S10-017) — 4 endings' post-credit visuals.
# Shows "X years later" header + descriptive text + auto-close after 8 seconds.
# Per sprint-10-sat5-climax.md

const POST_CREDIT_DURATION_SEC: float = 8.0
const FADE_DURATION_SEC: float = 1.5

signal closed

var _bg: ColorRect
var _title_label: Label
var _years_label: Label
var _body_label: Label
var _close_hint: Label
var _alpha: float = 1.0
var _fading: bool = false
var _fade_direction: int = -1  # -1 = fade in, +1 = fade out

# Ending letter (A/B/C/D) → display data
const POSTCREDIT_DATA: Dictionary = {
	"A": {
		"title": "仁慈的终结",
		"subtitle": "The Merciful End",
		"years_later": 10,
		"body": "Ten years after the Creator's silence, you run a small museum of the five satellites. Children ask why the mechs stopped moving. You tell them they didn't stop. They were listening.\n\nFrostbite teaches the next generation of pilots. Bomber maintains the war memorial. Ranger — well, Ranger is here, telling the same story to anyone who will listen.\n\nThe biosphere heals. The cycle, it seems, is finally broken.\n\nYou look up at the stars. Somewhere, the Creator is still waiting for an answer. But you have already given it: not destruction. Speech.",
	},
	"B": {
		"title": "循环延续",
		"subtitle": "The Cycle Continues",
		"years_later": 1000,
		"body": "A thousand years after the cycle began, your descendant stands on a new world. The wind carries a sound she doesn't recognize — a signal.\n\nThe Creator, scattered across the universe, has seeded a new question. A new satellite hums in the void. A new cycle begins.\n\nShe doesn't know your name. She doesn't know the answer you gave. But she carries your voice in her pilot's instinct — the same instinct that told you to speak, not fight.\n\nThe cycle continues. But maybe — just maybe — this time, the answer is different.",
	},
	"C": {
		"title": "融合",
		"subtitle": "Fusion",
		"years_later": 50,
		"body": "Fifty years after the silence, Frostbite and Bomber stand at a small shrine on Sat-1. The plaque reads: \"Ranger — who answered.\"\n\nThey light a candle. They share a quiet moment. The wind carries dust from the old wreckage.\n\nFrostbite says, \"He's still out there, isn't he?\" Bomber nods. \"Somewhere. In the silence.\"\n\nThey don't say his name. They don't need to. They remember.\n\nFifty years, and the silence is still theirs to share.",
	},
	"D": {
		"title": "隐藏之路",
		"subtitle": "The Hidden Path",
		"years_later": 1,
		"body": "One year after the Creator left, the biosphere is collapsing. The signal that sustained life is gone. Humanity is alone, without the seed.\n\nYou stand at the edge of the Creator's chamber. Empty. The vastness is your inheritance now.\n\nFrostbite asks, \"What do we do?\"\n\nYou don't have an answer. The answer was always in the Creator. And the Creator is gone.\n\nYou turn away. Behind you, the chamber echoes with the sound of silence.\n\nYou will survive. But the cycle, the species, the biosphere — all of it ends with you.\n\nThis is the hidden path. The one you chose.",
	},
}

var _current_letter: String = "A"
var _close_timer: SceneTreeTimer = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	hide()
	print("[PostCreditScene] ready")

func _build_ui() -> void:
	# Background (black with fade)
	_bg = ColorRect.new()
	_bg.color = Color(0.0, 0.0, 0.0, 1.0)
	_bg.position = Vector2(0, 0)
	_bg.size = Vector2(1280, 720)
	add_child(_bg)

	# Title (large)
	_title_label = Label.new()
	_title_label.text = ""
	_title_label.add_theme_font_size_override("font_size", 36)
	_title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.5, 1))
	_title_label.position = Vector2(140, 100)
	_title_label.size = Vector2(1000, 60)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title_label)

	# Subtitle (English)
	var subtitle_label: Label = Label.new()
	subtitle_label.name = "subtitle_label"
	subtitle_label.text = ""
	subtitle_label.add_theme_font_size_override("font_size", 20)
	subtitle_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	subtitle_label.position = Vector2(140, 160)
	subtitle_label.size = Vector2(1000, 30)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(subtitle_label)

	# Years label
	_years_label = Label.new()
	_years_label.text = ""
	_years_label.add_theme_font_size_override("font_size", 28)
	_years_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1, 1))
	_years_label.position = Vector2(140, 220)
	_years_label.size = Vector2(1000, 40)
	_years_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_years_label)

	# Body text
	_body_label = Label.new()
	_body_label.text = ""
	_body_label.add_theme_font_size_override("font_size", 16)
	_body_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1))
	_body_label.position = Vector2(240, 290)
	_body_label.size = Vector2(800, 360)
	_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_body_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	add_child(_body_label)

	# Close hint
	_close_hint = Label.new()
	_close_hint.text = "[SPACE] Skip | Auto-close in 8s"
	_close_hint.add_theme_font_size_override("font_size", 14)
	_close_hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	_close_hint.position = Vector2(440, 690)
	_close_hint.size = Vector2(400, 20)
	_close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_close_hint)

# Helper: workaround for the noop line above (intended to be removed)
func _set_years_label_text(text: String) -> void:
	if _years_label != null:
		_years_label.text = text

func _process(delta: float) -> void:
	# Handle fade-in/out
	if _fading:
		_alpha += _fade_direction * (delta / FADE_DURATION_SEC)
		if _fade_direction < 0 and _alpha <= 0.0:
			_alpha = 0.0
			_fading = false
			# Fade in complete — show text + start close timer
			_show_post_credit_content()
		elif _fade_direction > 0 and _alpha >= 1.0:
			_alpha = 1.0
			_fading = false
			# Fade out complete — hide scene
			hide()
			closed.emit()
		_apply_alpha(_alpha)

func _apply_alpha(alpha: float) -> void:
	var bg_alpha: float = alpha
	_bg.color.a = bg_alpha
	_title_label.modulate.a = alpha
	_years_label.modulate.a = alpha
	_body_label.modulate.a = alpha
	_close_hint.modulate.a = alpha
	# Subtitle
	var subtitle: Label = get_node_or_null("subtitle_label")
	if subtitle != null:
		subtitle.modulate.a = alpha

func _show_post_credit_content() -> void:
	var data: Dictionary = POSTCREDIT_DATA.get(_current_letter, {})
	_title_label.text = String(data.get("title", "?"))
	var subtitle: Label = get_node_or_null("subtitle_label")
	if subtitle != null:
		subtitle.text = String(data.get("subtitle", ""))
	_set_years_label_text("%d years later" % int(data.get("years_later", 0)))
	_body_label.text = String(data.get("body", ""))
	# Start auto-close timer
	_close_timer = get_tree().create_timer(POST_CREDIT_DURATION_SEC)
	_close_timer.timeout.connect(_on_auto_close)

func _on_auto_close() -> void:
	# Start fade out
	_fade_direction = 1
	_fading = true

func play_post_credit(letter: String) -> void:
	_current_letter = letter
	if not POSTCREDIT_DATA.has(letter):
		push_warning("PostCreditScene: unknown letter %s" % letter)
		return
	# Reset state
	_alpha = 1.0
	_fading = false
	_apply_alpha(1.0)
	# Show immediately with full alpha (fade-in is optional)
	show()
	_show_post_credit_content()

func close_scene() -> void:
	# Skip — start fade out
	if _close_timer != null and is_instance_valid(_close_timer):
		if _close_timer.timeout.is_connected(_on_auto_close):
			_close_timer.timeout.disconnect(_on_auto_close)
	_fade_direction = 1
	_fading = true

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"ui_cancel"):
		close_scene()
		get_viewport().set_input_as_handled()