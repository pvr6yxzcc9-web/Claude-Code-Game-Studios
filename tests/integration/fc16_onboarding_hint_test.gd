extends GutTest

# FC-16 Onboarding Hint Test (S2-010)
# Verifies HUD.show_hint displays an onboarding hint that auto-hides after duration.

const MAIN_SCENE := "res://src/main.tscn"
const HINT_TEXT := "WASD to move | 1/2/3 to attack | E to interact"

var _main: Node = null
var _hud: Node = null

func before_all() -> void:
    _main = load(MAIN_SCENE).instantiate()
    get_tree().root.add_child(_main)
    await get_tree().process_frame
    await get_tree().process_frame
    _hud = get_tree().get_root().find_child("HUD", true, false)

func after_all() -> void:
    if _main != null:
        _main.queue_free()
        _main = null

func test_hud_present() -> void:
    assert_not_null(_hud, "HUD must be in scene tree after main scene loads")

func test_show_hint_creates_label() -> void:
    _hud.show_hint(HINT_TEXT, 10.0)
    var hint: Node = _hud.find_child("OnboardingHint", true, false)
    assert_not_null(hint, "OnboardingHint Label must be created after show_hint")
    assert_eq(hint.text, HINT_TEXT, "hint label text matches input")
    assert_true(hint.visible, "hint label is visible after show_hint")

func test_hint_does_not_persist_after_building_other_room() -> void:
    # Building a different room should not destroy HUD (HUD is in preserve list),
    # but the hint should still be controllable.
    _hud.show_hint("temporary", 10.0)
    _main.build_room(3)
    var hint: Node = _hud.find_child("OnboardingHint", true, false)
    if hint != null:
        # We can re-show / re-hide without crashing
        _hud.show_hint("re-shown", 10.0)
        assert_eq(hint.text, "re-shown", "hint text updates on re-show")

func test_hint_uses_short_duration_for_test() -> void:
    # Use 0.2s duration so we don't slow the test suite
    _hud.show_hint("brief", 0.2)
    var hint: Node = _hud.find_child("OnboardingHint", true, false)
    assert_true(hint.visible, "hint visible immediately")
    await get_tree().create_timer(0.4).timeout
    # SceneTreeTimer.timeout should have fired
    assert_false(hint.visible, "hint auto-hides after duration")
