extends GutTest

# FC-37 Tutorial overlay (S6-002)
# Pins the 6-step 60s onboarding tutorial.
#   1) TutorialManager autoload exists
#   2) Constants: 6 steps, 10s per step
#   3) Hint sequence is exactly 6 messages covering all controls
#   4) start() is idempotent (don't restart if already running)
#   5) start() is gated by MetaState.tutorial_dismissed
#   6) dismiss_current() advances step
#   7) dismiss_current() at last step fully dismisses
#   8) Once dismissed, persistent state stops re-showing tutorial

const TutorialManager = preload("res://src/autoload/tutorial_manager.gd")
const TOTAL_STEPS: int = 6
const STEP_DURATION: float = 10.0

func _get_tutorial() -> Node:
    return get_node_or_null("/root/TutorialManager")

func _get_meta() -> Node:
    return get_node_or_null("/root/MetaState")

func test_tutorial_manager_autoload_exists() -> void:
    var t: Node = _get_tutorial()
    assert_not_null(t, "TutorialManager autoload is registered")
    assert_true(t.has_method("start"), "has start()")
    assert_true(t.has_method("dismiss_current"), "has dismiss_current()")
    assert_true(t.has_method("is_active"), "has is_active()")

func test_tutorial_step_count_is_six() -> void:
    var t: Node = _get_tutorial()
    assert_eq(t.HINTS.size(), TOTAL_STEPS, "6 sequential hints")

func test_tutorial_step_duration_is_ten_seconds() -> void:
    var t: Node = _get_tutorial()
    assert_eq(t.HINT_DURATION_PER_STEP, STEP_DURATION, "10 seconds per hint")

func test_tutorial_hints_cover_all_systems() -> void:
    # Each hint must cover a real system. If we add/remove systems
    # without updating the tutorial, this test should fail.
    var t: Node = _get_tutorial()
    var hints_text: String = " ".join(t.HINTS)
    assert_string_contains(hints_text, "WASD", "hint 1: movement")
    assert_string_contains(hints_text, "interact", "hint 2: E to interact")
    assert_string_contains(hints_text, "1/2/3", "hint 3: combat weapons")
    assert_string_contains(hints_text, "Codex", "hint 4: C for codex")
    assert_string_contains(hints_text, "auto-mode", "hint 4: M for auto-mode")
    assert_string_contains(hints_text, "Q", "hint 5: Q for mech cycle")
    assert_string_contains(hints_text, "fragments", "hint 6: fragment meta")

func test_tutorial_start_is_idempotent() -> void:
    var t: Node = _get_tutorial()
    var meta: Node = _get_meta()
    if meta != null:
        meta.set("tutorial_dismissed", null)  # clear any prior dismissal
    t.start()
    assert_true(t.is_active(), "after first start, is_active=true")
    var step_after_first: int = t.get_current_step()
    t.start()  # second start should be a no-op
    assert_eq(t.get_current_step(), step_after_first,
        "second start is a no-op (does not reset step)")

func test_tutorial_dismiss_current_advances() -> void:
    var t: Node = _get_tutorial()
    var meta: Node = _get_meta()
    if meta != null:
        meta.set("tutorial_dismissed", null)
    t.start()
    var step_before: int = t.get_current_step()
    t.dismiss_current()
    if step_before < TOTAL_STEPS - 1:
        assert_eq(t.get_current_step(), step_before + 1,
            "dismiss_current advances to next step (not last)")
    else:
        assert_false(t.is_active(), "dismiss_current at last step fully dismisses")

func test_tutorial_dismissed_persists_in_meta() -> void:
    var t: Node = _get_tutorial()
    var meta: Node = _get_meta()
    if meta != null:
        meta.set("tutorial_dismissed", null)
    t.start()
    # Skip through all 6 steps
    for i in TOTAL_STEPS:
        t.dismiss_current()
    assert_false(t.is_active(), "tutorial fully dismissed after 6 dismisses")
    assert_eq(bool(meta.get("tutorial_dismissed")), true, "dismissal persisted to MetaState")

func test_tutorial_start_skipped_after_dismissal() -> void:
    var t: Node = _get_tutorial()
    var meta: Node = _get_meta()
    if meta != null:
        meta.set("tutorial_dismissed", true)
    t.start()
    # Wait a frame to let the deferred check happen
    await get_tree().process_frame
    assert_false(t.is_active(),
        "tutorial does not start when MetaState.tutorial_dismissed=true")
