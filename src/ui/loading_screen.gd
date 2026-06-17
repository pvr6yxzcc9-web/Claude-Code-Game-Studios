extends CanvasLayer

# LoadingScreen (Sprint 14, S14-005) — show-before-heavy-work / hide-after pattern.
# Per design/P0-ship-blockers: wraps LevelRuntime.build_room + change_chapter
# and BattleScene._enter_battle with a visible loading indicator.
#
# Usage:
#   LoadingScreen.show_loading("Loading Sat-3 hive...")
#   await heavy_work()
#   LoadingScreen.hide_loading()
#
# Or use the context manager pattern:
#   await LoadingScreen.wrap_loading(callable, "Loading...")

var _panel: Control
var _label: Label
var _progress: ProgressBar
var _tips: Array[String] = [
	"Tip: Press M to open the Mech Bay in town.",
	"Tip: 3 truths unlock the 苍穹号 mech.",
	"Tip: Bounties reward special tools for the next satellite.",
	"Tip: Q opens the quest board from any state.",
	"Tip: The hidden quest q12 requires all 35 truths + ending A or B.",
	"Tip: Compassionate choices give +1 truth. Ruthless give -1.",
	"Tip: Save often — the clinic revives pilots, not saves.",
	"Tip: Auto mode rotates rangers → frostbite → bomber.",
	"Tip: Each satellite has 1 BOSS + 6 normal enemies + 1 BGM.",
	"Tip: Racing mechs are faster but weaker than combat mechs.",
]

static func show_loading(message: String = "Loading...") -> void:
	var inst: LoadingScreen = _get_instance()
	inst._show(message)

static func hide_loading() -> void:
	var inst: LoadingScreen = _get_instance()
	inst._hide()

static func set_progress(value: float) -> void:
	var inst: LoadingScreen = _get_instance()
	if inst._progress != null:
		inst._progress.value = value

# Wrap a callable with loading screen visibility
static func wrap_loading(callable: Callable, message: String = "Loading...") -> void:
	show_loading(message)
	# Yield to let the UI paint
	await Engine.get_main_loop().process_frame
	callable.call()
	await Engine.get_main_loop().process_frame
	hide_loading()

static var _instance: LoadingScreen = null
static func _get_instance() -> LoadingScreen:
	if _instance != null and is_instance_valid(_instance):
		return _instance
	# Try to find existing one
	var existing: Node = Engine.get_main_loop().root.get_node_or_null("LoadingScreen")
	if existing != null and existing is LoadingScreen:
		_instance = existing
		return _instance
	# Create new
	var inst: LoadingScreen = LoadingScreen.new()
	inst.name = "LoadingScreen"
	inst.layer = 100  # on top
	Engine.get_main_loop().root.add_child(inst)
	_instance = inst
	return inst

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_build_ui()
	hide()

func _build_ui() -> void:
	# Full-screen dark overlay
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# Center panel
	_panel = Control.new()
	_panel.position = Vector2(440, 280)
	_panel.size = Vector2(400, 160)
	add_child(_panel)
	# Spinner circle (drawn via ColorRect rectangles for simplicity)
	# Just a label with "..." for now (procedural spinner is heavy in GDScript)
	_label = Label.new()
	_label.text = "Loading..."
	_label.add_theme_font_size_override("font_size", 24)
	_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	_label.position = Vector2(0, 40)
	_label.size = Vector2(400, 30)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(_label)
	# Progress bar
	_progress = ProgressBar.new()
	_progress.position = Vector2(0, 80)
	_progress.size = Vector2(400, 20)
	_progress.min_value = 0.0
	_progress.max_value = 1.0
	_progress.value = 0.0
	_panel.add_child(_progress)
	# Tip label
	var tip_label: Label = Label.new()
	tip_label.text = _tips[randi() % _tips.size()]
	tip_label.add_theme_font_size_override("font_size", 14)
	tip_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	tip_label.position = Vector2(0, 110)
	tip_label.size = Vector2(400, 20)
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(tip_label)

func _show(message: String) -> void:
	if _label != null:
		_label.text = message
	if _progress != null:
		_progress.value = 0.0
	# Animate progress
	_animate_progress()
	show()

func _hide() -> void:
	hide()

func _animate_progress() -> void:
	# Quick tween 0 -> 1 over 0.5s
	if _progress == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(_progress, "value", 1.0, 0.5)
