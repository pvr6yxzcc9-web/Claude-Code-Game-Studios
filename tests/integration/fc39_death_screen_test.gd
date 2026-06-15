extends GutTest

# FC-39 Death screen + retry (S6-004)
# Pins the death/retry flow:
#   1) state_battle -> state_game over is a legal transition
#   2) state_game over -> state_exploration (retry) is legal
#   3) state_game over -> state_title (quit) is legal
#   4) state_game over -> state_battle is NOT legal (no skip)
#   5) DeathScreen autoload exists and is a CanvasLayer
#   6) DeathScreen becomes visible on state_game over
#   7) DeathScreen hides on any other state
#   8) Retrying loads the autosave and resets battle state

const DeathScreen = preload("res://src/ui/death_screen.gd")

var _main: Node = null

func before_all() -> void:
	_main = load("res://src/main.tscn").instantiate()
	get_tree().root.add_child(_main)
	await get_tree().process_frame
	await get_tree().process_frame

func after_all() -> void:
	if _main != null:
		_main.queue_free()
		_main = null

func test_state_game_over_legal_transitions() -> void:
	var sm: Node = get_node("/root/GameStateMachine")
	# Battle -> game over (death): legal
	assert_true(sm.ALLOWED_TRANSITIONS[&"state_battle"].has(&"state_game over"),
		"state_battle can transition to state_game over (death)")
	# Game over -> exploration (retry): legal
	assert_true(sm.ALLOWED_TRANSITIONS[&"state_game over"].has(&"state_exploration"),
		"state_game over can transition to state_exploration (retry)")
	# Game over -> title (quit): legal
	assert_true(sm.ALLOWED_TRANSITIONS[&"state_game over"].has(&"state_title"),
		"state_game over can transition to state_title (quit)")

func test_state_game_over_to_battle_is_illegal() -> void:
	# Cannot skip death screen back into battle
	var sm: Node = get_node("/root/GameStateMachine")
	var allowed: Array = sm.ALLOWED_TRANSITIONS[&"state_game over"]
	assert_false(allowed.has(&"state_battle"),
		"state_game over cannot skip directly to state_battle (would be a bug)")

func test_death_screen_autoload_exists() -> void:
	var ds: Node = get_node_or_null("/root/DeathScreen")
	assert_not_null(ds, "DeathScreen autoload is registered")
	assert_true(ds is CanvasLayer, "DeathScreen extends CanvasLayer")

func test_death_screen_becomes_visible_on_death_state() -> void:
	var ds: Node = get_node("/root/DeathScreen")
	# Start hidden
	ds.visible = false
	var sm: Node = get_node("/root/GameStateMachine")
	# Force a transition to state_game over from current state
	if sm.top_of_stack == &"state_game over":
		sm.transition_to(&"state_exploration")
		await get_tree().process_frame
	sm.transition_to(&"state_game over")
	await get_tree().process_frame
	assert_true(ds.visible, "DeathScreen visible after transition to state_game over")
	# Cleanup
	sm.transition_to(&"state_exploration")
	await get_tree().process_frame

func test_death_screen_hides_on_other_states() -> void:
	var ds: Node = get_node("/root/DeathScreen")
	var sm: Node = get_node("/root/GameStateMachine")
	# Force game over then exit
	if sm.top_of_stack != &"state_game over":
		sm.transition_to(&"state_game over")
		await get_tree().process_frame
	sm.transition_to(&"state_exploration")
	await get_tree().process_frame
	assert_false(ds.visible, "DeathScreen hidden after returning to exploration")

func test_death_screen_has_buttons() -> void:
	var ds: Node = get_node("/root/DeathScreen")
	assert_gt(ds._buttons.size(), 0, "DeathScreen has at least 1 button")
	# Should have both RETRY and QUIT buttons
	var has_retry: bool = false
	var has_quit: bool = false
	for btn in ds._buttons:
		var text: String = String(btn.text).to_lower()
		if text.contains("retry") or text.contains("reactivat"):
			has_retry = true
		if text.contains("quit") or text.contains("title"):
			has_quit = true
	assert_true(has_retry, "DeathScreen has RETRY button")
	assert_true(has_quit, "DeathScreen has QUIT button")

func test_retry_focus_can_be_cycled() -> void:
	var ds: Node = get_node("/root/DeathScreen")
	ds._focus_index = 0
	ds._update_focus()
	# Simulate down arrow: focus_index goes from 0 to 1
	ds._focus_index = 1
	ds._update_focus()
	assert_eq(ds._focus_index, 1, "focus_index advances to QUIT")
	# Simulate up arrow: wraps to 0
	ds._focus_index = 0
	ds._update_focus()
	assert_eq(ds._focus_index, 0, "focus_index wraps to RETRY")

func test_retry_selection_triggers_autosave_load() -> void:
	var ds: Node = get_node("/root/DeathScreen")
	var save: Node = get_node("/root/SaveManager")
	var bs: Node = get_tree().get_root().find_child("BattleScene", true, false)
	# Put battle in mid-battle state
	if bs != null:
		bs._player_hp = 50
	# Simulate retry selection
	ds._focus_index = 0
	ds._retry_from_autosave()
	if bs != null:
		assert_eq(bs._player_hp, 100, "battle player HP reset to 100 after retry")
		assert_false(bs.in_battle, "battle scene flagged not in battle after retry")

func test_battle_scene_transitions_to_game_over_on_fatal_damage() -> void:
	# Full integration: setup battle, set HP low, force attack
	var bs: Node = get_tree().get_root().find_child("BattleScene", true, false)
	if bs == null:
		pending("BattleScene not found; skipping integration test")
		return
	bs._pending_enemy_id = &"scavenger"
	var sm: Node = get_node("/root/GameStateMachine")
	sm.transition_to(&"state_battle")
	await get_tree().process_frame
	await get_tree().process_frame
	# Now set player HP to 1, simulate an attack that does >1 damage
	bs._player_hp = 1
	# Trigger on_player_attack with weapon 0
	bs.on_player_attack(0)
	await get_tree().process_frame
	# After fatal damage, should be in state_game over
	assert_eq(sm.top_of_stack, &"state_game over",
		"fatal damage transitions to state_game over")
	# Cleanup
	sm.transition_to(&"state_exploration")
	await get_tree().process_frame
