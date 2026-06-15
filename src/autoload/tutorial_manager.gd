extends Node

# TutorialManager (S6-002) — auto-loaded autoload (singleton).
#
# Per art-bible / ux spec: a new player should be able to play through room 0
# with no external help. S2-010 added a single 10s hint; this expands it to a
# 6-step 60s contextual tutorial.
#
# Sequence (auto-advances every 10s):
#   0-10s:  "WASD/方向键 to move" (movement basics)
#  10-20s:  "Press E near NPCs/terminals to interact" (interaction)
#  20-30s:  "1/2/3 to attack in battle" (combat)
#  30-40s:  "C opens codex | M toggles auto-mode" (advanced)
#  40-50s:  "Q cycles mech parts" (loadout)
#  50-60s:  "Find 7 fragments before beating the boss" (meta)
#  60s+:    all hints dismissed
#
# Player can press ESC at any time to skip the current hint and the rest of
# the tutorial. Once dismissed, the player has_dismissed_tutorial=true is
# persisted to MetaState (save-survives) so it never re-shows for that player.

const HINT_DURATION_PER_STEP: float = 10.0
const TOTAL_STEPS: int = 6

const HINTS: Array[String] = [
	"WASD or arrow keys to move",
	"Press E near NPCs or terminals to interact",
	"In battle, press 1/2/3 to attack with that slot's weapon",
	"C opens the Codex (story fragments) | M toggles auto-mode",
	"Q cycles your equipped mech part (Torso/Legs/Arms)",
	"Explore terminals to find 7 fragments before beating the boss",
]

signal hint_shown(text: String, step: int, total: int)
signal hint_dismissed

var _current_step: int = 0
var _active: bool = false
var _timer: SceneTreeTimer = null
var hud: Node = null

func _ready() -> void:
	print("[TutorialManager] ready")

func start() -> void:
	# Idempotent: don't restart if already running or already dismissed
	if _active:
		return
	var meta: Node = get_node_or_null("/root/MetaState")
	if meta != null and meta.get("tutorial_dismissed"):
		return
	# Find HUD lazily (HUD might not be ready at autoload _ready time)
	if hud == null:
		hud = get_tree().get_root().find_child("HUD", true, false)
		if hud == null:
			# Retry on next frame
			await get_tree().process_frame
			hud = get_tree().get_root().find_child("HUD", true, false)
	if hud == null:
		push_warning("TutorialManager: HUD not found, tutorial disabled")
		return
	_active = true
	_current_step = 0
	_show_current()

func _show_current() -> void:
	if _current_step >= TOTAL_STEPS:
		_dismiss_all()
		return
	if not _active:
		return
	var text: String = HINTS[_current_step]
	if hud != null and hud.has_method("show_hint"):
		hud.show_hint(text + " (ESC to skip)", HINT_DURATION_PER_STEP)
	hint_shown.emit(text, _current_step + 1, TOTAL_STEPS)
	# Auto-advance to next step
	if _timer != null and _timer.timeout.is_connected(_advance):
		_timer.timeout.disconnect(_advance)
	_timer = get_tree().create_timer(HINT_DURATION_PER_STEP)
	_timer.timeout.connect(_advance)

func _advance() -> void:
	_current_step += 1
	_show_current()

func dismiss_current() -> void:
	# Called when player presses ESC. Skip current step and go to next.
	# If at last step, dismiss entirely.
	if not _active:
		return
	# Skip current step
	if _current_step < TOTAL_STEPS - 1:
		_current_step += 1
		_show_current()
	else:
		_dismiss_all()

func _dismiss_all() -> void:
	_active = false
	if _timer != null and _timer.timeout.is_connected(_advance):
		_timer.timeout.disconnect(_advance)
	if hud != null and hud.has_method("show_hint"):
		hud.call("hide_hint")  # immediate hide
	# Persist dismissal to MetaState
	var meta: Node = get_node_or_null("/root/MetaState")
	if meta != null:
		meta.set("tutorial_dismissed", true)
	# Don't persist to save — tutorial should show on new game
	# but not on re-load of an existing save
	hint_dismissed.emit()
	print("[TutorialManager] tutorial dismissed")

func is_active() -> bool:
	return _active

func get_current_step() -> int:
	return _current_step
