extends Control

# RacingArenaUI (S11-013 + S11-014 + S11-018) — town interaction for racing.
# Shows 6 tracks, 4 racing mechs, betting counter, race results.
# Per production/sprints/sprint-11-bounty-racing.md + design/gdd/racing-minigame.md

const MENU_WIDTH: float = 900.0
const MENU_HEIGHT: float = 650.0

signal closed

# Visual elements
var _bg: ColorRect
var _title_label: Label
var _track_buttons: Array[Button] = []
var _mech_buttons: Array[Button] = []
var _selected_track: StringName = &""
var _selected_mech: StringName = &""
var _bet_amount: int = 100
var _bet_label: Label
var _results_label: Label
var _gold_label: Label
var _race_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	hide()
	var rm: Node = get_node_or_null("/root/RacingManager")
	if rm != null:
		rm.race_finished.connect(_on_race_finished)
		rm.bet_placed.connect(_on_bet_placed)
	_refresh_gold()
	print("[RacingArenaUI] ready")

func _build_ui() -> void:
	# Background
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
	_title_label.text = "RACING ARENA"
	_title_label.add_theme_font_size_override("font_size", 24)
	_title_label.add_theme_color_override("font_color", Color(0.5, 0.9, 1, 1))
	_title_label.position = panel.position + Vector2(20, 15)
	add_child(_title_label)

	# Gold label (top right)
	_gold_label = Label.new()
	_gold_label.text = "Gold: 0"
	_gold_label.add_theme_font_size_override("font_size", 14)
	_gold_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 1))
	_gold_label.position = panel.position + Vector2(MENU_WIDTH - 130, 20)
	add_child(_gold_label)

	# Track selection (left column)
	var track_title: Label = Label.new()
	track_title.text = "TRACKS"
	track_title.add_theme_font_size_override("font_size", 16)
	track_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	track_title.position = panel.position + Vector2(20, 60)
	add_child(track_title)

	var rm: Node = get_node_or_null("/root/RacingManager")
	if rm != null:
		var y: float = 90.0
		for tid in rm.ALL_TRACKS:
			var track: Dictionary = rm.get_track_info(tid)
			var btn: Button = Button.new()
			btn.text = "%s (%d m)" % [String(track.get("name", "?")), int(track.get("distance", 0))]
			btn.position = panel.position + Vector2(20, y)
			btn.size = Vector2(280, 36)
			btn.pressed.connect(_on_track_pressed.bind(tid))
			add_child(btn)
			_track_buttons.append(btn)
			y += 42

	# Mech selection (middle column)
	var mech_title: Label = Label.new()
	mech_title.text = "RACING MECHS"
	mech_title.add_theme_font_size_override("font_size", 16)
	mech_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	mech_title.position = panel.position + Vector2(320, 60)
	add_child(mech_title)

	if rm != null:
		var y2: float = 90.0
		for mid in rm.ALL_RACING_MECHS:
			var mech: Dictionary = rm.get_racing_mech_info(mid)
			var btn2: Button = Button.new()
			btn2.text = "%s (SPD %d, HND %d, DUR %d)" % [
				String(mech.get("name", "?")),
				int(mech.get("speed", 0)),
				int(mech.get("handling", 0)),
				int(mech.get("durability", 0))
			]
			btn2.position = panel.position + Vector2(320, y2)
			btn2.size = Vector2(280, 36)
			btn2.pressed.connect(_on_mech_pressed.bind(mid))
			add_child(btn2)
			_mech_buttons.append(btn2)
			y2 += 42

	# Bet + Race (right column)
	var bet_title: Label = Label.new()
	bet_title.text = "BET"
	bet_title.add_theme_font_size_override("font_size", 16)
	bet_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	bet_title.position = panel.position + Vector2(620, 60)
	add_child(bet_title)

	_bet_label = Label.new()
	_bet_label.text = "Bet: 100g"
	_bet_label.add_theme_font_size_override("font_size", 14)
	_bet_label.position = panel.position + Vector2(620, 90)
	add_child(_bet_label)

	# Bet adjustment buttons
	var btn_100: Button = Button.new()
	btn_100.text = "+100"
	btn_100.position = panel.position + Vector2(620, 120)
	btn_100.size = Vector2(60, 32)
	btn_100.pressed.connect(_on_bet_change.bind(100))
	add_child(btn_100)

	var btn_500: Button = Button.new()
	btn_500.text = "+500"
	btn_500.position = panel.position + Vector2(690, 120)
	btn_500.size = Vector2(60, 32)
	btn_500.pressed.connect(_on_bet_change.bind(500))
	add_child(btn_500)

	var btn_max: Button = Button.new()
	btn_max.text = "MAX"
	btn_max.position = panel.position + Vector2(760, 120)
	btn_max.size = Vector2(60, 32)
	btn_max.pressed.connect(_on_bet_max)
	add_child(btn_max)

	# Race button
	_race_button = Button.new()
	_race_button.text = "PLACE BET & RACE"
	_race_button.position = panel.position + Vector2(620, 170)
	_race_button.size = Vector2(200, 48)
	_race_button.disabled = true
	_race_button.pressed.connect(_on_race_pressed)
	add_child(_race_button)

	# Results label (bottom)
	_results_label = Label.new()
	_results_label.text = "Select a track and mech to start."
	_results_label.add_theme_font_size_override("font_size", 14)
	_results_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	_results_label.position = panel.position + Vector2(20, 470)
	_results_label.size = Vector2(MENU_WIDTH - 40, 110)
	_results_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(_results_label)

func _refresh_gold() -> void:
	var cm: Node = get_node_or_null("/root/ClinicManager")
	if cm != null and _gold_label != null:
		_gold_label.text = "Gold: %d" % cm.get_gold()

func _on_track_pressed(track_id: StringName) -> void:
	_selected_track = track_id
	_refresh_race_button()
	# Highlight selected (simplified)
	for i in _track_buttons.size():
		var btn: Button = _track_buttons[i]
		btn.modulate = Color(0.6, 0.8, 1.0) if i == _track_buttons.find(_track_buttons[i]) else Color.WHITE

func _on_mech_pressed(mech_id: StringName) -> void:
	_selected_mech = mech_id
	_refresh_race_button()

func _refresh_race_button() -> void:
	if _race_button == null:
		return
	_race_button.disabled = (_selected_track == &"" or _selected_mech == &"")

func _on_bet_change(delta: int) -> void:
	_bet_amount = max(0, _bet_amount + delta)
	_bet_label.text = "Bet: %dg" % _bet_amount

func _on_bet_max() -> void:
	var cm: Node = get_node_or_null("/root/ClinicManager")
	if cm != null:
		_bet_amount = cm.get_gold()
		_bet_label.text = "Bet: %dg (MAX)" % _bet_amount

func _on_race_pressed() -> void:
	var rm: Node = get_node_or_null("/root/RacingManager")
	if rm == null:
		return
	if _selected_track == &"" or _selected_mech == &"":
		return
	var err: int = rm.place_bet(_selected_track, _selected_mech, _bet_amount)
	if err != OK:
		_results_label.text = "Bet failed: %s" % error_string(err)
		return
	# Run race
	var results: Dictionary = rm.run_race(_selected_track)
	# Determine winner
	var min_time: float = INF
	var winner: StringName = &""
	for mid in results:
		if float(results[mid]) < min_time:
			min_time = float(results[mid])
			winner = StringName(mid)
	# Display results
	var text: String = "Race finished!\nWinner: %s (%.1fs)\n\n" % [String(rm.get_racing_mech_info(winner).get("name", "?")), min_time]
	for mid in results:
		var time: float = float(results[mid])
		var name: String = String(rm.get_racing_mech_info(mid).get("name", "?"))
		text += "  %s: %.1fs%s\n" % [name, time, " (WINNER)" if mid == winner else ""]
	# Check if player won the bet
	if winner == _selected_mech:
		var cm: Node = get_node_or_null("/root/ClinicManager")
		if cm != null:
			cm.add_gold(int(_bet_amount * 1.5))
		text += "\nYou won! Payout: %d gold" % int(_bet_amount * 1.5)
	else:
		text += "\nYou lost. Better luck next time."
	_results_label.text = text
	_refresh_gold()

func _on_race_finished(_track_id: StringName, results: Dictionary, _payouts: Dictionary) -> void:
	# Could be used for race animation — deferred to S11-017
	pass

func _on_bet_placed(_track_id: StringName, _mech_id: StringName, _amount: int, _odds: float) -> void:
	_refresh_gold()

func open_arena() -> void:
	show()
	_refresh_gold()

func close_arena() -> void:
	hide()
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_cancel"):
		close_arena()
		get_viewport().set_input_as_handled()