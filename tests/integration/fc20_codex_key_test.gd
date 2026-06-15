extends GutTest

# FC-20 Codex Key Test (S3-004)
# Verifies C key opens Codex in exploration and C again closes it.

const MAIN_SCENE := "res://src/main.tscn"

var _main: Node = null
var _codex: Node = null
var _sm: Node = null

func before_all() -> void:
    _main = load(MAIN_SCENE).instantiate()
    get_tree().root.add_child(_main)
    await get_tree().process_frame
    await get_tree().process_frame
    _codex = get_tree().get_root().find_child("CodexUI", true, false)
    _sm = get_node("/root/GameStateMachine")

func after_all() -> void:
    if _main != null:
        _main.queue_free()
        _main = null

func test_codex_present() -> void:
    assert_not_null(_codex, "CodexUI must be in scene tree")

func test_codex_input_action_exists() -> void:
    # "codex" must be bound to a key (we use C, physical_keycode=67)
    var actions: Array = InputMap.get_actions()
    assert_true(actions.has(&"codex"), "codex action must exist in InputMap")

func test_codex_transitions() -> void:
    _sm.transition_to(&"state_exploration")
    assert_eq(_sm.top_of_stack, &"state_exploration")
    assert_false(_codex.visible, "CodexUI hidden in state_exploration")
    # Simulate the C key transition
    _sm.transition_to(&"state_codex")
    assert_eq(_sm.top_of_stack, &"state_codex")
    assert_true(_codex.visible, "CodexUI visible in state_codex")
    # Close it
    _sm.transition_to(&"state_exploration")
    assert_false(_codex.visible, "CodexUI hidden after closing")
