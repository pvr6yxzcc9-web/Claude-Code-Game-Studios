extends GutTest

# FC-29 Multiple endings (S4-009)
# Pins:
#   1) EndingController autoload exists, has determine_ending + play_ending
#   2) 3 ending dialogue trees loaded (A/B/C)
#   3) determine_ending thresholds: 0-2 -> C, 3-5 -> B, 6+ -> A
#   4) play_ending starts a dialogue (ends with no choices -> dialogue ends)
#   5) BattleScene _resolve_battle triggers ending for boss win
#   6) Non-boss win returns to exploration (no ending)

const MAIN_SCENE := "res://src/main.tscn"

var _main: Node = null
var _ending: Node = null
var _dm: Node = null
var _meta: Node = null
var _bs: Node = null
var _sm: Node = null
var _reg: Node = null

func before_all() -> void:
    _main = load(MAIN_SCENE).instantiate()
    get_tree().root.add_child(_main)
    await get_tree().process_frame
    await get_tree().process_frame
    _ending = get_node("/root/EndingController")
    _dm = get_node("/root/DialogueManager")
    _meta = get_node("/root/MetaState")
    _bs = get_tree().get_root().find_child("BattleScene", true, false)
    _sm = get_node("/root/GameStateMachine")
    _reg = get_node("/root/ResourceRegistry")

func after_all() -> void:
    if _main != null:
        _main.queue_free()
        _main = null

func before_each() -> void:
    _meta.unlocked.clear()
    if _sm.top_of_stack != &"state_exploration":
        while _sm.state_stack.size() > 1:
            _sm.pop()

# --- A) Autoload + dialogue trees loaded ---

func test_state_battle_can_transition_to_state_dialogue_for_boss_ending() -> void:
    # S5-006: ending requires state_battle -> state_dialogue, but the
    # FSM ALLOWED_TRANSITIONS only listed state_exploration and
    # state_menu. This blocked all boss endings silently.
    var sm: Node = get_node("/root/GameStateMachine")
    var original: StringName = sm.top_of_stack
    if original != &"state_battle":
        sm.transition_to(&"state_battle")
    sm.transition_to(&"state_dialogue")
    assert_eq(sm.top_of_stack, &"state_dialogue", "state_battle can transition to state_dialogue")
    sm.transition_to(&"state_exploration")
    sm.transition_to(original)

func test_ending_controller_autoload_exists() -> void:
    assert_not_null(_ending, "EndingController is registered as autoload")
    assert_true(_ending.has_method("determine_ending"), "has determine_ending()")
    assert_true(_ending.has_method("play_ending"), "has play_ending()")

func test_three_ending_dialogue_trees_loaded() -> void:
    for tree_id in [&"dlg_ending_A", &"dlg_ending_B", &"dlg_ending_C"]:
        var t: Resource = _reg.get_resource(tree_id)
        assert_not_null(t, "%s loaded in registry" % tree_id)

# --- B) Threshold logic ---

func test_zero_fragments_chooses_ending_C() -> void:
    var chosen: StringName = _ending.determine_ending()
    assert_eq(chosen, &"dlg_ending_C", "0 fragments -> C (default)")

func test_one_fragment_chooses_ending_C() -> void:
    _meta.mark_unlocked(&"fragment_who_we_were")
    var chosen: StringName = _ending.determine_ending()
    assert_eq(chosen, &"dlg_ending_C", "1 fragment -> C")

func test_two_fragments_chooses_ending_C() -> void:
    _meta.mark_unlocked(&"fragment_who_we_were")
    _meta.mark_unlocked(&"fragment_the_convoy")
    var chosen: StringName = _ending.determine_ending()
    assert_eq(chosen, &"dlg_ending_C", "2 fragments -> C (still under B threshold)")

func test_three_fragments_chooses_ending_B() -> void:
    _meta.mark_unlocked(&"fragment_who_we_were")
    _meta.mark_unlocked(&"fragment_the_convoy")
    _meta.mark_unlocked(&"fragment_marlows_daughter")
    var chosen: StringName = _ending.determine_ending()
    assert_eq(chosen, &"dlg_ending_B", "3 fragments -> B (partial)")

func test_five_fragments_chooses_ending_B() -> void:
    for frag_id in [&"fragment_who_we_were", &"fragment_the_convoy",
                    &"fragment_marlows_daughter", &"fragment_the_seal",
                    &"fragment_engineer_last_stand"]:
        _meta.mark_unlocked(frag_id)
    var chosen: StringName = _ending.determine_ending()
    assert_eq(chosen, &"dlg_ending_B", "5 fragments -> B (under A threshold)")

func test_six_fragments_chooses_ending_A() -> void:
    for frag_id in [&"fragment_who_we_were", &"fragment_the_convoy",
                    &"fragment_marlows_daughter", &"fragment_the_seal",
                    &"fragment_engineer_last_stand", &"fragment_the_truth"]:
        _meta.mark_unlocked(frag_id)
    var chosen: StringName = _ending.determine_ending()
    assert_eq(chosen, &"dlg_ending_A", "6 fragments -> A (revelation)")

func test_ending_chosen_signal_fires() -> void:
    var received: Array = []
    _ending.ending_chosen.connect(func(t: StringName, c: int) -> void: received.append([t, c]))
    _ending.determine_ending()
    assert_eq(received.size(), 1, "ending_chosen fired once")
    assert_eq(received[0][1], 0, "signal carries fragment count 0")

# --- C) Play ending starts dialogue ---

func test_play_ending_starts_dialogue_with_ending_tree() -> void:
    _meta.mark_unlocked(&"fragment_who_we_were")
    _meta.mark_unlocked(&"fragment_the_convoy")
    _meta.mark_unlocked(&"fragment_marlows_daughter")  # 3 -> B
    var err: int = _ending.play_ending()
    await get_tree().process_frame
    assert_eq(err, OK, "play_ending returns OK")
    assert_true(_dm.is_active, "dialogue is active after play_ending")
    # B tree has 1 node (ending) with 0 choices
    assert_eq(_dm.current_node_id, &"ending", "ending tree starts at 'ending' node")
    # End dialogue (0 choices auto-end)
    _dm.end_dialogue()
    await get_tree().process_frame
    assert_false(_dm.is_active, "dialogue ends (ending node has no choices)")

# --- D) BattleScene _resolve_battle integration ---

func test_boss_victory_triggers_ending_controller() -> void:
    # Set up: boss win, 3 fragments
    _meta.mark_unlocked(&"fragment_who_we_were")
    _meta.mark_unlocked(&"fragment_the_convoy")
    _meta.mark_unlocked(&"fragment_marlows_daughter")
    # Get boss resource
    var boss: Resource = _reg.get_resource(&"boss_marrow_sentinel")
    assert_not_null(boss)
    # Manually invoke _resolve_battle with boss as enemy
    _bs._enemy = boss
    _bs.in_battle = true
    _bs._resolve_battle(true, 200, 0)
    await get_tree().process_frame
    # EndingController should have started a dialogue
    assert_true(_dm.is_active, "dialogue active after boss victory")
    # Should NOT be in exploration (ending replaced the exploration transition)
    assert_ne(_sm.top_of_stack, &"state_exploration",
        "did not transition to exploration after boss win (ending replaced it)")
    # Cleanup
    _dm.end_dialogue()
    await get_tree().process_frame

func test_non_boss_victory_returns_to_exploration() -> void:
    # Set up: non-boss win (scavenger)
    _sm.transition_to(&"state_battle")
    await get_tree().process_frame
    var scavenger: Resource = _reg.get_resource(&"scavenger")
    _bs._enemy = scavenger
    _bs.in_battle = true
    _bs._resolve_battle(true, 40, 0)
    await get_tree().process_frame
    assert_eq(_sm.top_of_stack, &"state_exploration",
        "non-boss victory returns to exploration (no ending)")
    assert_false(_dm.is_active, "no dialogue started for non-boss victory")
