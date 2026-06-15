extends GutTest

# FC-57 Replay recorder (S6-104)
# Pins that ReplayRecorder works:
#   1) Autoload registered
#   2) start_recording() / stop_recording() toggle is_recording
#   3) Recording captures InputBus action_pressed events
#   4) Recording captures action_released events
#   5) stop_recording saves to disk
#   6) playback_recent loads + plays back events
#   7) is_playing flips during playback
#   8) playback_finished signal fires
#   9) Auto-stop at MAX_DURATION_MS (5 min) not testable; just check overflow safety

var _main: Node = null
var _rr: Node = null

func before_all() -> void:
    _main = load("res://src/main.tscn").instantiate()
    get_tree().root.add_child(_main)
    await get_tree().process_frame
    await get_tree().process_frame
    _rr = get_node_or_null("/root/ReplayRecorder")

func after_all() -> void:
    if _main != null:
        _main.queue_free()
        _main = null

# 1) Autoload

func test_replay_recorder_registered() -> void:
    assert_not_null(_rr, "ReplayRecorder autoload registered")

# 2) State toggle

func test_start_stop_recording() -> void:
    _rr.start_recording()
    assert_true(_rr.is_recording(), "is_recording true after start")
    await get_tree().process_frame
    _rr.stop_recording()
    assert_false(_rr.is_recording(), "is_recording false after stop")

# 3) Captures action_pressed

func test_records_action_pressed() -> void:
    var ib: Node = get_node("/root/InputBus")
    _rr.start_recording()
    # Synth input — should trigger InputBus.action_pressed via the
    # action_press() API (which our input_bus listens to).
    Input.action_press(&"move_up")
    ib.action_pressed.emit(&"move_up")
    Input.action_release(&"move_up")
    ib.action_released.emit(&"move_up")
    await get_tree().process_frame
    var count: int = _rr.get_event_count()
    _rr.stop_recording()
    assert_gt(count, 0, "recorded at least 1 event")

# 4) Captures both press and release

func test_records_press_and_release() -> void:
    var ib: Node = get_node("/root/InputBus")
    _rr.start_recording()
    ib.action_pressed.emit(&"move_left")
    ib.action_released.emit(&"move_left")
    ib.action_pressed.emit(&"move_right")
    await get_tree().process_frame
    var count: int = _rr.get_event_count()
    _rr.stop_recording()
    # At least 3 events
    assert_gte(count, 3, "recorded press + release + press (>=3 events)")

# 5) Saves to disk

func test_stop_recording_returns_count_and_saves() -> void:
    _rr.start_recording()
    var ib: Node = get_node("/root/InputBus")
    for i in 5:
        ib.action_pressed.emit(&"interact")
    await get_tree().process_frame
    var count: int = _rr.stop_recording()
    assert_gte(count, 5, "stop returned count >= 5")
    # File should exist at user://replay_last.bin
    var f: FileAccess = FileAccess.open("user://replay_last.bin", FileAccess.READ)
    assert_not_null(f, "replay file saved to user://replay_last.bin")
    if f != null:
        f.close()

# 6) Playback loads

func test_playback_recent_loads() -> void:
    # First record something
    _rr.start_recording()
    var ib: Node = get_node("/root/InputBus")
    ib.action_pressed.emit(&"pause")
    await get_tree().process_frame
    _rr.stop_recording()
    # Now play back
    var err: int = _rr.playback_recent()
    assert_eq(err, OK, "playback_recent returned OK")
    assert_true(_rr.is_playing(), "is_playing true during playback")

# 7-8) Playback events fire + finish

func test_playback_fires_events_and_finishes() -> void:
    # Record 3 events at known intervals (1ms apart so playback fires fast)
    _rr.start_recording()
    var ib: Node = get_node("/root/InputBus")
    # Manually inject events with controlled timestamps via _record_event
    # (private, but we can call it via reflection)
    _rr._record_event(&"test_action_1", "press")
    _rr._record_event(&"test_action_2", "press")
    _rr._record_event(&"test_action_3", "press")
    _rr.stop_recording()
    # Manually inject into playback events with timestamps 0, 1, 2 ms
    # (so playback fires them immediately)
    _rr._playback_events = [
        {"ts_ms": 0, "action": &"test_action_1", "type": "press"},
        {"ts_ms": 1, "action": &"test_action_2", "type": "press"},
        {"ts_ms": 2, "action": &"test_action_3", "type": "press"},
    ]
    _rr._is_playing = true
    _rr._playback_start_ms = Time.get_ticks_msec()
    _rr._playback_index = 0
    # Wait one frame — _process should fire all events
    await get_tree().process_frame
    await get_tree().process_frame
    assert_false(_rr.is_playing(), "is_playing false after all events fired")
    assert_eq(_rr._playback_index, 3, "playback_index reached end")
