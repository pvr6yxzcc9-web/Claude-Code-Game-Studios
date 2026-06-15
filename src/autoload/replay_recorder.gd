extends Node

# ReplayRecorder (S6-104) — basic input replay for "watch your last run".
#
# Architecture:
#   1. record()  starts recording InputBus.action_pressed events into a
#                ring buffer (last 5 minutes by default)
#   2. stop()    ends recording, saves to user://replay_last.bin
#   3. playback() replays in real-time via Input.action_press/release
#                (synthetic input, doesn't go through InputBus to avoid
#                 feedback loops)
#   4. is_recording / is_playing state queries
#
# Out of scope (full deterministic replay is much harder):
#   - State snapshots (player position, HP, etc.) — would need periodic
#     serialization of MetaState + battle state
#   - RNG state save/restore — would need to wrap randf() in a SeededRandom
#   - Playback sync (the watcher sees the same physics, but the
#     state is reset to the start of recording, not live)
#
# This implementation records inputs only — the replayed run replays the
# same *inputs* the player issued, but in a fresh game state. Useful for
# "let me see my last run" UX, not for ghost-replay verification.

const REPLAY_PATH := "user://replay_last.bin"
const MAX_EVENTS: int = 30000  # ~5 min at 100 events/sec
const MAX_DURATION_MS: int = 300000  # 5 minutes

# Event: {ts_ms: int, action: StringName, type: String}  type = "press" or "release"
var _events: Array = []
var _is_recording: bool = false
var _recording_start_ms: int = 0

# Playback state
var _is_playing: bool = false
var _playback_events: Array = []
var _playback_start_ms: int = 0
var _playback_index: int = 0

signal recording_started
signal recording_stopped(event_count: int)
signal playback_started
signal playback_finished
signal playback_event_fired(action: StringName, type: String)

func _ready() -> void:
	# Subscribe to InputBus action_pressed / action_released
	var ib: Node = get_node_or_null("/root/InputBus")
	if ib != null:
		ib.action_pressed.connect(_on_action_pressed)
		ib.action_released.connect(_on_action_released)
	print("[ReplayRecorder] ready (max %d events, %d sec window)" % [MAX_EVENTS, MAX_DURATION_MS / 1000])

func _on_action_pressed(action: StringName) -> void:
	if not _is_recording:
		return
	_record_event(action, "press")

func _on_action_released(action: StringName) -> void:
	if not _is_recording:
		return
	_record_event(action, "release")

func _record_event(action: StringName, type: String) -> void:
	var now: int = Time.get_ticks_msec()
	if _events.is_empty():
		_recording_start_ms = now
	var ts_ms: int = now - _recording_start_ms
	if ts_ms > MAX_DURATION_MS:
		# Auto-stop at 5 min to prevent unbounded growth
		stop_recording()
		return
	_events.append({"ts_ms": ts_ms, "action": action, "type": type})
	if _events.size() > MAX_EVENTS:
		_events.pop_front()  # drop oldest

# Public: start recording
func start_recording() -> void:
	if _is_recording:
		return
	_events.clear()
	_recording_start_ms = Time.get_ticks_msec()
	_is_recording = true
	recording_started.emit()
	print("[ReplayRecorder] recording started")

# Public: stop recording + save to disk
func stop_recording() -> int:
	if not _is_recording:
		return 0
	_is_recording = false
	var count: int = _events.size()
	_save_to_disk()
	recording_stopped.emit(count)
	print("[ReplayRecorder] recording stopped: %d events" % count)
	return count

func is_recording() -> bool:
	return _is_recording

func get_event_count() -> int:
	return _events.size()

# Public: playback the most recent saved recording
func playback_recent() -> Error:
	if not FileAccess.file_exists(REPLAY_PATH):
		push_warning("[ReplayRecorder] no saved replay at %s" % REPLAY_PATH)
		return ERR_FILE_NOT_FOUND
	if not _load_from_disk():
		return ERR_PARSE_ERROR
	if _playback_events.is_empty():
		return ERR_FILE_EMPTY
	_is_playing = true
	_playback_start_ms = Time.get_ticks_msec()
	_playback_index = 0
	playback_started.emit()
	print("[ReplayRecorder] playback started: %d events" % _playback_events.size())
	return OK

func is_playing() -> bool:
	return _is_playing

func _process(_delta: float) -> void:
	if not _is_playing:
		return
	var now: int = Time.get_ticks_msec()
	var elapsed: int = now - _playback_start_ms
	# Fire all events whose timestamp has been reached
	while _playback_index < _playback_events.size():
		var ev: Dictionary = _playback_events[_playback_index]
		var ts_ms_val: Variant = ev.get("ts_ms")
		var ts_ms: int = int(ts_ms_val) if ts_ms_val != null else 0
		if ts_ms <= elapsed:
			var action: StringName = StringName(ev.get("action") if ev.get("action") != null else &"")
			var type: String = String(ev.get("type")) if ev.get("type") != null else "press"
			_synth_input(action, type)
			playback_event_fired.emit(action, type)
			_playback_index += 1
		else:
			break
	# Done?
	if _playback_index >= _playback_events.size():
		_is_playing = false
		playback_finished.emit()
		print("[ReplayRecorder] playback finished")

# Synth input via Input.action_press/release (does NOT go through InputBus
# — would cause infinite feedback loop if it did).
func _synth_input(action: StringName, type: String) -> void:
	if type == "press":
		Input.action_press(action)
	else:
		Input.action_release(action)

# Save/load: simple binary format. Not portable across versions but
# sufficient for "replay last run" UX.
func _save_to_disk() -> void:
	var f: FileAccess = FileAccess.open(REPLAY_PATH, FileAccess.WRITE)
	if f == null:
		push_error("[ReplayRecorder] cannot open %s for write" % REPLAY_PATH)
		return
	# Header: magic + version
	f.store_buffer("RPLY".to_ascii_buffer())
	f.store_32(1)  # version
	# Events: count + per-event (ts: int, action: StringName, type: byte)
	f.store_32(_events.size())
	for ev in _events:
		f.store_32(int(ev.get("ts_ms")) if ev.get("ts_ms") != null else 0)
		f.store_string(String(ev.get("action")) if ev.get("action") != null else "")
		f.store_8(0 if String(ev.get("type")) == "press" else 1)
	f.close()

func _load_from_disk() -> bool:
	var f: FileAccess = FileAccess.open(REPLAY_PATH, FileAccess.READ)
	if f == null:
		return false
	var magic: PackedByteArray = f.get_buffer(4)
	if magic.size() < 4 or magic[0] != 0x52 or magic[1] != 0x50 or magic[2] != 0x4C or magic[3] != 0x59:
		f.close()
		return false
	var version: int = f.get_32()
	if version != 1:
		f.close()
		return false
	var count: int = f.get_32()
	_playback_events.clear()
	for i in count:
		var ts: int = f.get_32()
		var action: String = f.get_string()
		var type_byte: int = f.get_8()
		_playback_events.append({
			"ts_ms": ts,
			"action": StringName(action),
			"type": "press" if type_byte == 0 else "release",
		})
	f.close()
	return true
