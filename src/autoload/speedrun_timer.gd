extends Node

# SpeedrunTimer (S6-105) — tracks current run time + best per chapter.
#
# Lifecycle:
#   1. start_run(chapter_id)     — begin timer for a chapter
#   2. stop_run() -> int         — end timer, return elapsed ms; updates best if faster
#   3. get_elapsed_ms() -> int   — current run time (or 0 if not running)
#   4. get_best_ms(chapter_id)   — persisted best time for chapter (0 if none)
#   5. is_running() -> bool      — is timer active
#   6. get_last_run_was_best()   — true if stop_run() updated best
#
# HUD reads get_elapsed_ms() each frame to display MM:SS.mmm in top corner.
# Boss victory calls stop_run() to capture the final time.
#
# Storage: MetaState.best_times Dictionary[StringName, int] in ms.

const _META_KEY_BEST := "best_times"

signal run_started(chapter_id: StringName)
signal run_stopped(elapsed_ms: int, was_best: bool)
signal best_updated(chapter_id: StringName, new_best_ms: int)

var _running: bool = false
var _chapter_id: StringName = &""
var _start_ms: int = 0
var _last_elapsed_ms: int = 0
var _last_was_best: bool = false

func _ready() -> void:
	# Best times are persisted in MetaState. Load at boot.
	var meta: Node = get_node_or_null("/root/MetaState")
	if meta == null:
		push_warning("[SpeedrunTimer] MetaState missing")
		return
	if not _META_KEY_BEST in meta:
		meta.set(_META_KEY_BEST, {})
	print("[SpeedrunTimer] ready")

func _process(_delta: float) -> void:
	if _running:
		_last_elapsed_ms = Time.get_ticks_msec() - _start_ms

# Public: start a new run for a given chapter
func start_run(chapter_id: StringName) -> void:
	_chapter_id = chapter_id
	_start_ms = Time.get_ticks_msec()
	_last_elapsed_ms = 0
	_last_was_best = false
	_running = true
	run_started.emit(chapter_id)
	print("[SpeedrunTimer] run started for %s" % chapter_id)

# Public: stop the run, update best if faster, return final elapsed
func stop_run() -> int:
	if not _running:
		return _last_elapsed_ms
	_running = false
	var final_ms: int = Time.get_ticks_msec() - _start_ms
	_last_elapsed_ms = final_ms
	# Compare to best
	var prev_best: int = get_best_ms(_chapter_id)
	if prev_best == 0 or final_ms < prev_best:
		_set_best_ms(_chapter_id, final_ms)
		_last_was_best = true
		best_updated.emit(_chapter_id, final_ms)
		print("[SpeedrunTimer] new best for %s: %s" % [_chapter_id, _format_time(final_ms)])
	else:
		_last_was_best = false
	run_stopped.emit(final_ms, _last_was_best)
	return final_ms

func is_running() -> bool:
	return _running

func get_elapsed_ms() -> int:
	if _running:
		return Time.get_ticks_msec() - _start_ms
	return _last_elapsed_ms

func get_chapter_id() -> StringName:
	return _chapter_id

func was_last_run_best() -> bool:
	return _last_was_best

# Best-time persistence via MetaState
func get_best_ms(chapter_id: StringName) -> int:
	var meta: Node = get_node_or_null("/root/MetaState")
	if meta == null or not _META_KEY_BEST in meta:
		return 0
	var best_dict: Dictionary = meta.get(_META_KEY_BEST)
	if not best_dict.has(chapter_id):
		return 0
	return int(best_dict[chapter_id])

func _set_best_ms(chapter_id: StringName, ms: int) -> void:
	var meta: Node = get_node_or_null("/root/MetaState")
	if meta == null:
		return
	var best_dict: Dictionary = meta.get(_META_KEY_BEST) if _META_KEY_BEST in meta else {}
	best_dict[chapter_id] = ms
	meta.set(_META_KEY_BEST, best_dict)

# Format helper: 12345 ms -> "00:12.34"
func _format_time(ms: int) -> String:
	var secs: int = ms / 1000
	var millis: int = ms % 1000
	var mins: int = secs / 60
	secs = secs % 60
	return "%02d:%02d.%03d" % [mins, secs, millis]

# Public: format any ms the same way (for HUD display)
func format_time(ms: int) -> String:
	return _format_time(ms)
