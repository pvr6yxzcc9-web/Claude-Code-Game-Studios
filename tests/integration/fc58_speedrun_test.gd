extends GutTest

# FC-58 Speedrun timer (S6-105)
# Pins that SpeedrunTimer works and is wired:
#   1) SpeedrunTimer autoload registered
#   2) start_run sets is_running + chapter_id
#   3) get_elapsed_ms grows over time
#   4) stop_run returns elapsed + is_running false
#   5) was_last_run_best flips based on best-time comparison
#   6) Best time persists in MetaState
#   7) get_best_ms returns 0 for unknown chapter
#   8) format_time produces MM:SS.mmm format
#   9) Second run updates best if faster

var _main: Node = null
var _st: Node = null

func before_all() -> void:
    _main = load("res://src/main.tscn").instantiate()
    get_tree().root.add_child(_main)
    await get_tree().process_frame
    await get_tree().process_frame
    _st = get_node_or_null("/root/SpeedrunTimer")

func after_all() -> void:
    if _main != null:
        _main.queue_free()
        _main = null

# 1) Autoload

func test_speedrun_timer_registered() -> void:
    assert_not_null(_st, "SpeedrunTimer autoload registered")

# 2) start_run state

func test_start_run_sets_state() -> void:
    _st.start_run(&"test_chap_1")
    assert_true(_st.is_running(), "is_running true after start")
    assert_eq(_st.get_chapter_id(), &"test_chap_1", "chapter_id set")
    _st.stop_run()

# 3) Elapsed grows

func test_elapsed_grows_over_time() -> void:
    _st.start_run(&"test_chap_2")
    var ms1: int = _st.get_elapsed_ms()
    await get_tree().create_timer(0.2).timeout
    var ms2: int = _st.get_elapsed_ms()
    _st.stop_run()
    assert_gt(ms2, ms1, "elapsed_ms grew over 0.2s")
    # Should be at least 150ms (give some slack)
    assert_gte(ms2 - ms1, 100, "elapsed grew by at least 100ms")

# 4) stop_run returns elapsed

func test_stop_run_returns_elapsed() -> void:
    _st.start_run(&"test_chap_3")
    await get_tree().create_timer(0.1).timeout
    var final_ms: int = _st.stop_run()
    assert_gte(final_ms, 50, "stop returned elapsed >= 50ms")
    assert_false(_st.is_running(), "is_running false after stop")

# 5) was_last_run_best for new best

func test_was_last_run_best_when_no_prev() -> void:
    # No prior best for this chapter
    _st.start_run(&"test_chap_no_prev")
    await get_tree().create_timer(0.05).timeout
    _st.stop_run()
    assert_true(_st.was_last_run_best(), "no prev best -> new run is best")

# 6) Best persists in MetaState

func test_best_time_persists_to_meta_state() -> void:
    _st.start_run(&"test_chap_persist")
    await get_tree().create_timer(0.05).timeout
    _st.stop_run()
    var best: int = _st.get_best_ms(&"test_chap_persist")
    assert_gt(best, 0, "best time > 0 after first run")
    # Verify it's in MetaState
    var meta: Node = get_node("/root/MetaState")
    if "best_times" in meta:
        var dict: Dictionary = meta.get("best_times")
        assert_true(dict.has(&"test_chap_persist"), "best_times dict has chapter")

# 7) Unknown chapter best = 0

func test_unknown_chapter_best_is_zero() -> void:
    assert_eq(_st.get_best_ms(&"never_run_chap"), 0, "unknown chapter best = 0")

# 8) format_time format

func test_format_time_format() -> void:
    assert_eq(_st.format_time(0), "00:00.000", "0 ms formats as 00:00.000")
    assert_eq(_st.format_time(1234), "00:01.234", "1234 ms = 00:01.234")
    assert_eq(_st.format_time(65000), "01:05.000", "65000 ms = 01:05.000")
    assert_eq(_st.format_time(125000), "02:05.000", "125000 ms = 02:05.000")

# 9) Second faster run updates best

func test_second_faster_run_updates_best() -> void:
    # Set a slow best first
    _st.start_run(&"test_chap_2run")
    await get_tree().create_timer(0.1).timeout
    var first_ms: int = _st.stop_run()
    var first_best: int = _st.get_best_ms(&"test_chap_2run")
    assert_eq(first_best, first_ms, "first best == first time")
    # Now stop a second run very quickly (just call stop right after start)
    _st.start_run(&"test_chap_2run")
    var second_ms: int = _st.stop_run()
    var second_best: int = _st.get_best_ms(&"test_chap_2run")
    assert_eq(second_best, second_ms, "second best == second time (faster)")
    assert_lt(second_ms, first_ms, "second run was faster")
    assert_true(_st.was_last_run_best(), "faster run was marked best")
