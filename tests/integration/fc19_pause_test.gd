extends GutTest

# FC-19 Pause Menu Soft-Pause Test (S2-001)
# Verifies pause menu opens/closes via state_pause without get_tree().paused.

const MAIN_SCENE := "res://src/main.tscn"

var _main: Node = null
var _pause: Node = null
var _sm: Node = null

func before_all() -> void:
	_main = load(MAIN_SCENE).instantiate()
	get_tree().root.add_child(_main)
	await get_tree().process_frame
	await get_tree().process_frame
	_pause = get_tree().get_root().find_child("PauseMenu", true, false)
	_sm = get_node("/root/GameStateMachine")

func after_all() -> void:
	if _main != null:
		_main.queue_free()
		_main = null

func test_pause_menu_present() -> void:
	assert_not_null(_pause, "PauseMenu must be in scene tree")
	assert_false(_pause.visible, "PauseMenu hidden by default")

func test_game_state_machine_has_is_paused_helper() -> void:
	assert_true(_sm.has_method("is_paused"), "GameStateMachine has is_paused()")

func test_is_paused_returns_false_in_exploration() -> void:
	_sm.transition_to(&"state_exploration")
	assert_eq(_sm.top_of_stack, &"state_exploration")
	assert_false(_sm.is_paused(), "is_paused() returns false in exploration")

func test_transitioning_to_pause_shows_menu() -> void:
	_sm.transition_to(&"state_exploration")
	_sm.transition_to(&"state_pause")
	assert_eq(_sm.top_of_stack, &"state_pause", "top of stack is state_pause")
	assert_true(_sm.is_paused(), "is_paused() returns true in state_pause")
	assert_true(_pause.visible, "PauseMenu visible after state_pause")
	_sm.transition_to(&"state_exploration")
	assert_false(_pause.visible, "PauseMenu hidden after leaving state_pause")

func test_get_tree_paused_never_set() -> void:
	_sm.transition_to(&"state_exploration")
	assert_false(get_tree().paused, "tree not paused in exploration")
	_sm.transition_to(&"state_pause")
	assert_false(get_tree().paused, "tree NOT paused in state_pause (soft pause)")
	_sm.transition_to(&"state_exploration")
	assert_false(get_tree().paused, "tree still not paused after resume")

func test_pause_resume_round_trip() -> void:
	_sm.transition_to(&"state_exploration")
	_sm.transition_to(&"state_pause")
	_pause._resume()
	assert_eq(_sm.top_of_stack, &"state_exploration", "back to exploration after _resume")

func test_is_paused_in_title() -> void:
	# Direct check: is_paused() returns true when top is state_title.
	# (We don't transition into state_title via transition_to because the FSM
	# only allows it as the initial state; we set it directly to test the helper.)
	_sm.state_stack = [&"state_title"] as Array[StringName]
	_sm.top_of_stack = &"state_title"
	assert_true(_sm.is_paused(), "is_paused() returns true in state_title (input gated)")
	# Reset
	_sm.state_stack = [&"state_exploration"] as Array[StringName]
	_sm.top_of_stack = &"state_exploration"
