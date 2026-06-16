extends Control

# RaceAnimation (S11-017) — 30-60s top-down race visualization.
# Shows 4 mechs racing horizontally with progress bars + leader highlight.
# Triggered after the player places a bet + clicks "Race" in RacingArenaUI.
# Per production/sprints/sprint-11-bounty-racing.md + design/gdd/racing-minigame.md

const RACE_DURATION_SEC: float = 8.0  # Visual race length (compressed from real-time)
const FINISH_LINE_X: float = 1100.0  # x position where mechs "finish"
const START_LINE_X: float = 180.0
const TRACK_LENGTH: float = FINISH_LINE_X - START_LINE_X  # 920 px

signal race_finished(results: Dictionary)

# Visual elements
var _bg: ColorRect
var _track_lines: Array[ColorRect] = []  # 4 horizontal lanes
var _mech_labels: Array[Label] = []  # mech name labels
var _mech_sprites: Array[ColorRect] = []  # mech position indicators
var _progress_bars: Array[ColorRect] = []
var _time_label: Label
var _winner_label: Label

# Race state
var _race_active: bool = false
var _race_results: Dictionary = {}
var _race_elapsed: float = 0.0
var _last_delta: float = 0.0

# Mapping mech_id → index (0-3)
const MECH_ORDER: Array[StringName] = [
	&"racing_bolt", &"racing_shadow", &"racing_titan", &"racing_wisp"
]
const MECH_COLORS: Array[Color] = [
	Color(1.0, 0.6, 0.0),    # Bolt = orange
	Color(0.4, 0.6, 1.0),    # Shadow = blue
	Color(0.5, 0.5, 0.5),    # Titan = gray
	Color(0.8, 0.4, 1.0),    # Wisp = purple
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	hide()
	# Subscribe to race_finished to know when to start animation
	var rm: Node = get_node_or_null("/root/RacingManager")
	if rm != null:
		rm.race_finished.connect(_on_race_triggered)
	print("[RaceAnimation] ready")

func _build_ui() -> void:
	# Background overlay (semi-transparent)
	_bg = ColorRect.new()
	_bg.color = Color(0.0, 0.0, 0.0, 0.92)
	_bg.position = Vector2(0, 0)
	_bg.size = Vector2(1280, 720)
	add_child(_bg)

	# Title
	var title: Label = Label.new()
	title.text = "RACE IN PROGRESS"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.5, 0.9, 1, 1))
	title.position = Vector2(440, 30)
	title.size = Vector2(400, 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	# Time label (top right)
	_time_label = Label.new()
	_time_label.text = "0.0s"
	_time_label.add_theme_font_size_override("font_size", 18)
	_time_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 1))
	_time_label.position = Vector2(1120, 35)
	_time_label.size = Vector2(120, 30)
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_time_label)

	# 4 horizontal lanes (one per mech)
	for i in 4:
		var y: float = 130.0 + i * 110.0
		# Lane background
		var lane: ColorRect = ColorRect.new()
		lane.color = Color(0.15, 0.15, 0.2, 1.0)
		lane.position = Vector2(START_LINE_X - 10, y - 20)
		lane.size = Vector2(TRACK_LENGTH + 20, 80)
		add_child(lane)
		_track_lines.append(lane)

		# Mech name label (left)
		var name_label: Label = Label.new()
		name_label.text = MECH_ORDER[i]
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.add_theme_color_override("font_color", Color.WHITE)
		name_label.position = Vector2(20, y + 20)
		name_label.size = Vector2(150, 30)
		add_child(name_label)
		_mech_labels.append(name_label)

		# Mech sprite (colored square moving across the lane)
		var sprite: ColorRect = ColorRect.new()
		sprite.color = MECH_COLORS[i]
		sprite.position = Vector2(START_LINE_X, y)
		sprite.size = Vector2(40, 40)
		add_child(sprite)
		_mech_sprites.append(sprite)

		# Progress bar (background)
		var progress_bg: ColorRect = ColorRect.new()
		progress_bg.color = Color(0.1, 0.1, 0.1, 1.0)
		progress_bg.position = Vector2(START_LINE_X, y + 45)
		progress_bg.size = Vector2(TRACK_LENGTH, 6)
		add_child(progress_bg)

		# Progress bar (fill — starts empty)
		var progress_fill: ColorRect = ColorRect.new()
		progress_fill.color = MECH_COLORS[i]
		progress_fill.position = Vector2(START_LINE_X, y + 45)
		progress_fill.size = Vector2(0, 6)
		add_child(progress_fill)
		_progress_bars.append(progress_fill)

	# Finish line (vertical line at FINISH_LINE_X)
	var finish: ColorRect = ColorRect.new()
	finish.color = Color(1.0, 0.9, 0.5, 0.8)
	finish.position = Vector2(FINISH_LINE_X, 110)
	finish.size = Vector2(4, 460)
	add_child(finish)

	# Winner label (bottom center)
	_winner_label = Label.new()
	_winner_label.text = ""
	_winner_label.add_theme_font_size_override("font_size", 24)
	_winner_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 1))
	_winner_label.position = Vector2(340, 600)
	_winner_label.size = Vector2(600, 36)
	_winner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_winner_label)

func _process(delta: float) -> void:
	if not _race_active:
		return
	_race_elapsed += delta
	_time_label.text = "%.1fs" % _race_elapsed
	# Update mech positions based on race elapsed vs calculated race times
	_update_mech_positions()

func _update_mech_positions() -> void:
	var rm: Node = get_node_or_null("/root/RacingManager")
	if rm == null:
		return
	# For each mech, position = start + (elapsed / race_time) * track_length
	# Clamp to finish line
	for i in MECH_ORDER.size():
		var mech_id: StringName = MECH_ORDER[i]
		if not _race_results.has(mech_id):
			continue
		var race_time: float = float(_race_results[mech_id])
		var progress: float = min(1.0, _race_elapsed / race_time)
		var x: float = START_LINE_X + progress * TRACK_LENGTH
		_mech_sprites[i].position.x = x
		_progress_bars[i].size.x = progress * TRACK_LENGTH

	# Check winner (first to cross finish line)
	if _race_elapsed >= RACE_DURATION_SEC:
		_finish_race()

func _finish_race() -> void:
	if not _race_active:
		return
	_race_active = false
	# Determine winner (lowest time)
	var min_time: float = INF
	var winner: StringName = &""
	for mid in _race_results:
		if float(_race_results[mid]) < min_time:
			min_time = float(_race_results[mid])
			winner = StringName(mid)
	# Show winner label
	_winner_label.text = "WINNER: %s (%.1fs)" % [String(winner), min_time]
	# Stop auto-close after 2 seconds
	await get_tree().create_timer(2.0).timeout
	race_finished.emit(_race_results)

func _on_race_triggered(_track_id: StringName, results: Dictionary, _payouts: Dictionary) -> void:
	# Triggered by RacingManager.run_race() → race_finished signal
	start_animation(results)

func start_animation(results: Dictionary) -> void:
	_race_results = results.duplicate()
	_race_elapsed = 0.0
	_race_active = true
	# Reset positions
	for i in MECH_ORDER.size():
		_mech_sprites[i].position.x = START_LINE_X
		_progress_bars[i].size.x = 0
	_winner_label.text = ""
	show()

func close_animation() -> void:
	hide()
	_race_active = false

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_cancel"):
		close_animation()
		get_viewport().set_input_as_handled()
	# Space to skip to end
	if event.is_action_pressed(&"ui_accept"):
		if _race_active:
			# Skip to end
			_race_elapsed = RACE_DURATION_SEC
			_update_mech_positions()