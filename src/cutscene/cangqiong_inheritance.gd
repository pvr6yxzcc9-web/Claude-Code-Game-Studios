extends Control
# CangqiongInheritance (S7-008) — 7-beat cutscene for inheriting the
# 苍穹号 mech in Ch13 (or via debug). After completion:
# - MechLoadout.unlock_cangqiong() is called
# - WeaponLoadout equips 4 default cangqiong weapons
# - The player's roster is now 4 mechs
#
# Per party-system.md §3.3 + sprint-07-008 plan.
# Per .claude/rules/ui-code.md: cutscene never modifies state directly —
# it calls into autoloads that emit signals.

signal cutscene_started
signal beat_advanced(beat_index: int)
signal cutscene_finished
signal cutscene_skipped

# === Beat enum (7 beats + COMPLETE) ===
enum Beat {
	FIND_COCKPIT,      # 1
	SEE_PILOT_BODY,    # 2
	READ_LETTER,       # 3
	PARTY_MOURNS,      # 4
	MECH_POWERON,      # 5
	BOND_TO_RANGER,    # 6
	RECEIVE_MECH,      # 7
	COMPLETE,          # end state
}

# Timing per beat (seconds). Total = 4+3+5+2+3+3+3 = 23s
const BEAT_DURATIONS := {
	Beat.FIND_COCKPIT: 4.0,
	Beat.SEE_PILOT_BODY: 3.0,
	Beat.READ_LETTER: 5.0,
	Beat.PARTY_MOURNS: 2.0,
	Beat.MECH_POWERON: 3.0,
	Beat.BOND_TO_RANGER: 3.0,
	Beat.RECEIVE_MECH: 3.0,
}

const BEAT_TITLES := {
	Beat.FIND_COCKPIT: "[Ch13 — The Cockpit]",
	Beat.SEE_PILOT_BODY: "[The Pilot Inside]",
	Beat.READ_LETTER: "[A Final Letter]",
	Beat.PARTY_MOURNS: "[Silence]",
	Beat.MECH_POWERON: "[苍穹号 Awakens]",
	Beat.BOND_TO_RANGER: "[The Bond]",
	Beat.RECEIVE_MECH: "[You Receive 苍穹号]",
}

const FINAL_LETTER := """To whoever finds this,

I was the first to hear the signal. I tried to warn them. They didn't listen.
I followed the signal to Sat-5. I saw what was waiting.
The Creator is not a god. It is a question. And we are the answer it fears.

I am leaving this mech to the one who comes after.
The receiver code is yours now. You will need it. When the time comes,
you will need to speak — not fight.

The cycle has run for 50 years. It will run for 50 more,
unless someone breaks it. Be that someone.

— 苍穹号 (Azure Sky)"""

# 4 default weapons to equip after the cutscene
const CANGQIONG_WEAPONS: Array[StringName] = [
	&"cangqiong_cannon",
	&"cangqiong_light_blade",
	&"cangqiong_signal_jammer",
	&"cangqiong_creator_receiver",
]

# === State ===
var _current_beat: int = Beat.FIND_COCKPIT
var _timer: SceneTreeTimer
var _completed: bool = false
var _started: bool = false

# === Visual elements ===
var _bg: ColorRect
var _stage_bg: ColorRect
var _title_label: Label
var _body_label: Label
var _continue_prompt: Label
var _skip_hint: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_ui()
	hide()
	print("[CangqiongInheritance] ready")

func _build_ui() -> void:
	# Black overlay
	_bg = ColorRect.new()
	_bg.color = Color(0.0, 0.0, 0.0, 1.0)
	_bg.position = Vector2(0, 0)
	_bg.size = Vector2(1280, 720)
	add_child(_bg)

	# Stage area (where mech art would go — placeholder ColorRect for now)
	_stage_bg = ColorRect.new()
	_stage_bg.color = Color(0.05, 0.05, 0.1, 1.0)
	_stage_bg.position = Vector2(0, 0)
	_stage_bg.size = Vector2(1280, 720)
	add_child(_stage_bg)

	# Title (top center)
	_title_label = Label.new()
	_title_label.text = ""
	_title_label.add_theme_font_size_override("font_size", 22)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5, 1))
	_title_label.position = Vector2(40, 30)
	_title_label.size = Vector2(1200, 30)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title_label)

	# Body text (centered, scrollable area for the letter)
	_body_label = Label.new()
	_body_label.text = ""
	_body_label.add_theme_font_size_override("font_size", 16)
	_body_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.85, 1))
	_body_label.position = Vector2(120, 200)
	_body_label.size = Vector2(1040, 400)
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_body_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	add_child(_body_label)

	# Skip hint (bottom right)
	_skip_hint = Label.new()
	_skip_hint.text = "[SPACE] Skip"
	_skip_hint.add_theme_font_size_override("font_size", 12)
	_skip_hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	_skip_hint.position = Vector2(1100, 690)
	add_child(_skip_hint)

	# Continue prompt (after cutscene)
	_continue_prompt = Label.new()
	_continue_prompt.text = "[SPACE] Continue"
	_continue_prompt.add_theme_font_size_override("font_size", 18)
	_continue_prompt.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_continue_prompt.position = Vector2(540, 600)
	_continue_prompt.size = Vector2(200, 30)
	_continue_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_continue_prompt.visible = false
	add_child(_continue_prompt)

# === Input ===

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_accept"):  # SPACE / ENTER
		if _completed:
			_close()
		else:
			_skip_to_end()
		get_viewport().set_input_as_handled()

# === Lifecycle ===

# Start the cutscene. Validates that cangqiong is not already unlocked.
func start() -> Error:
	var ml: Node = get_node_or_null("/root/MechLoadout")
	if ml == null:
		push_error("CangqiongInheritance: MechLoadout missing")
		return ERR_DOES_NOT_EXIST
	if ml.is_unlocked(&"cangqiong_mech"):
		# Already inherited — show message and exit
		_title_label.text = "[苍穹号 has already been inherited]"
		_body_label.text = "The bond is permanent. There is no second inheritance."
		_continue_prompt.visible = true
		_completed = true
		show()
		return OK
	_started = true
	_current_beat = Beat.FIND_COCKPIT
	_completed = false
	show()
	cutscene_started.emit()
	_advance_beat()
	return OK

# Debug entry point (used by Sprint 7 testing before Ch13 is implemented)
func start_debug() -> Error:
	return start()

# === Beat progression ===

func _advance_beat() -> void:
	if _current_beat > Beat.RECEIVE_MECH:
		_complete_cutscene()
		return
	# Cancel any existing timer
	if _timer != null and is_instance_valid(_timer):
		if _timer.timeout.is_connected(_on_beat_complete):
			_timer.timeout.disconnect(_on_beat_complete)
	_show_beat_content(_current_beat)
	beat_advanced.emit(_current_beat)
	var duration: float = BEAT_DURATIONS[_current_beat]
	_timer = get_tree().create_timer(duration)
	_timer.timeout.connect(_on_beat_complete, CONNECT_ONE_SHOT)

func _on_beat_complete() -> void:
	if _completed:
		return
	_current_beat += 1
	_advance_beat()

func _skip_to_end() -> void:
	if _completed:
		return
	# Cancel timer
	if _timer != null and is_instance_valid(_timer):
		if _timer.timeout.is_connected(_on_beat_complete):
			_timer.timeout.disconnect(_on_beat_complete)
	cutscene_skipped.emit()
	# Skip directly to RECEIVE_MECH beat, then complete
	_current_beat = Beat.RECEIVE_MECH
	_show_beat_content(_current_beat)
	_complete_cutscene()

# === Beat content ===

func _show_beat_content(beat: int) -> void:
	_title_label.text = BEAT_TITLES.get(beat, "")
	_continue_prompt.visible = false
	match beat:
		Beat.FIND_COCKPIT:
			_body_label.text = "The party finds 苍穹号's destroyed cockpit. Smoke rises. Inside, a faint amber light still glows."
		Beat.SEE_PILOT_BODY:
			_body_label.text = "苍穹号's pilot lies at rest within the cockpit. Beside him: 4 weapons, untouched by time."
		Beat.READ_LETTER:
			_body_label.text = FINAL_LETTER
		Beat.PARTY_MOURNS:
			_body_label.text = "[No words. The 3 pilots stand in silence, heads bowed.]\n\nFrostbite. Bomber. Ranger."
		Beat.MECH_POWERON:
			_body_label.text = "苍穹号 awakens. Lights flicker. Engines hum. The 4 weapons rise and dock into the mech."
		Beat.BOND_TO_RANGER:
			_body_label.text = "A beam of light connects 漫游号 (the Ranger's mech) to 苍穹号. The Creator Receiver activates.\n\nThe bond is established."
		Beat.RECEIVE_MECH:
			_body_label.text = "苍穹号 is now in your roster.\n\nYou have inherited the mech of the one who came before."
		_:
			_body_label.text = ""

func _complete_cutscene() -> void:
	if _completed:
		return
	_completed = true
	_title_label.text = "[苍穹号 has joined your roster]"
	_body_label.text = "Open the Mech Bay (M key) to see your 4 mechs and assign pilots.\n\n苍穹号 has 4 weapon slots — 1 more than your other mechs."
	_continue_prompt.visible = true
	_skip_hint.visible = false
	# Unlock 苍穹号 in MechLoadout
	var ml: Node = get_node_or_null("/root/MechLoadout")
	if ml != null:
		ml.unlock_cangqiong()
	# Equip the 4 default weapons via WeaponLoadout
	var wl: Node = get_node_or_null("/root/WeaponLoadout")
	if wl != null:
		for i in CANGQIONG_WEAPONS.size():
			wl.equip_weapon_to_mech(&"cangqiong_mech", i, CANGQIONG_WEAPONS[i])
	cutscene_finished.emit()
	print("[CangqiongInheritance] cutscene complete — cangqiong unlocked + 4 weapons equipped")

func _close() -> void:
	hide()
	_started = false

# === Public helpers ===

func is_completed() -> bool:
	return _completed

func is_started() -> bool:
	return _started

func get_current_beat() -> int:
	return _current_beat