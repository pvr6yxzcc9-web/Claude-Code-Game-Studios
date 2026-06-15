extends GutTest

# FC-33 Boss ending UI integration (S5-006)
# Pins the post-battle-victory state transitions that fc29 could not:
#   1) BattleScene visible=false after boss win (no zombie UI)
#   2) BattleScene children still exist (not queue_freed mid-dialogue)
#   3) battle_resolved signal fires for boss win too
#   4) Ending dialogue close returns to exploration (no stuck state)
#   5) Boss defeat does NOT trigger autosave reload (vs player defeat)
#   6) Each ending tree has non-empty text (player sees content)
#
# This is the "S4-009 F5 was untested" regression net. Without these
# tests, a future refactor could break the boss-victory UI flow without
# any signal.

const MAIN_SCENE := "res://src/main.tscn"

var _main: Node = null
var _bs: Node = null
var _dm: Node = null
var _sm: Node = null
var _meta: Node = null
var _reg: Node = null

func before_all() -> void:
    _main = load(MAIN_SCENE).instantiate()
    get_tree().root.add_child(_main)
    await get_tree().process_frame
    await get_tree().process_frame
    _bs = get_tree().get_root().find_child("BattleScene", true, false)
    _dm = get_node("/root/DialogueManager")
    _sm = get_node("/root/GameStateMachine")
    _meta = get_node("/root/MetaState")
    _reg = get_node("/root/ResourceRegistry")

func after_all() -> void:
    if _main != null:
        _main.queue_free()
        _main = null

func before_each() -> void:
    _meta.unlocked.clear()
    # Reset to exploration
    while _sm.state_stack.size() > 1:
        _sm.pop()

# --- A) UI child survival after boss win ---

func test_boss_win_hides_battle_scene_but_keeps_children() -> void:
    var boss: Resource = _reg.get_resource(&"boss_marrow_sentinel")
    _bs._enemy = boss
    _bs.in_battle = true
    _sm.transition_to(&"state_battle")
    await get_tree().process_frame
    var child_count_before: int = _bs.get_child_count()
    assert_gt(child_count_before, 0, "BattleScene has children pre-resolve")
    _bs._resolve_battle(true, 200, 0)
    await get_tree().process_frame
    assert_false(_bs.visible, "BattleScene hidden after boss win")
    assert_eq(_bs.get_child_count(), child_count_before,
        "BattleScene children survive (not queue_freed mid-dialogue)")
    # Cleanup
    _dm.end_dialogue()

# --- B) battle_resolved signal still fires for boss win ---

func test_battle_resolved_signal_fires_on_boss_win() -> void:
    var received: Array = []
    _bs.battle_resolved.connect(func(v: bool, d: int, t: int) -> void:
        received.append([v, d, t]))
    var boss: Resource = _reg.get_resource(&"boss_marrow_sentinel")
    _bs._enemy = boss
    _bs.in_battle = true
    _sm.transition_to(&"state_battle")
    await get_tree().process_frame
    _bs._resolve_battle(true, 200, 0)
    await get_tree().process_frame
    assert_eq(received.size(), 1, "battle_resolved fired once for boss win")
    assert_eq(received[0][0], true, "victory=true")
    # Cleanup
    _dm.end_dialogue()

# --- C) Dialogue close returns to exploration ---

func test_ending_dialogue_close_returns_to_exploration() -> void:
    _meta.mark_unlocked(&"fragment_who_we_were")
    _meta.mark_unlocked(&"fragment_the_convoy")
    _meta.mark_unlocked(&"fragment_marlows_daughter")  # 3 fragments -> B
    var boss: Resource = _reg.get_resource(&"boss_marrow_sentinel")
    _bs._enemy = boss
    _bs.in_battle = true
    _sm.transition_to(&"state_battle")
    await get_tree().process_frame
    _bs._resolve_battle(true, 200, 0)
    await get_tree().process_frame
    assert_true(_dm.is_active, "dialogue active after boss win")
    assert_ne(_sm.top_of_stack, &"state_exploration",
        "state is NOT exploration during ending dialogue")
    # End the dialogue (ending tree has 0 choices, auto-ends after enter,
    # but we explicitly call to test the close path)
    _dm.end_dialogue()
    await get_tree().process_frame
    assert_false(_dm.is_active, "dialogue ended")
    # After end_dialogue, the FSM should pop state_dialogue -> state_exploration
    assert_eq(_sm.top_of_stack, &"state_exploration",
        "state popped back to exploration after ending dialogue closes")

# --- D) Boss defeat does NOT trigger autosave reload ---

func test_boss_win_does_not_trigger_save_reload() -> void:
    # Player defeat (loss) path calls save.get_autosave() to reload.
    # Boss victory (win) path should NOT do that. Verify by:
    # 1) Snapshotting save state
    # 2) Winning boss fight
    # 3) Confirming save state is unchanged (no reload occurred)
    var save: Node = get_node("/root/SaveManager")
    var inventory: Node = get_node("/root/Inventory")
    inventory.add(&"test_item", 1)
    save.save_to_slot(0)
    await get_tree().create_timer(0.2).timeout
    inventory.add(&"pollution", 99)  # dirty state
    # Snapshot
    var item_count_before: int = inventory.count(&"test_item")
    var pollution_before: int = inventory.count(&"pollution")
    # Boss victory
    var boss: Resource = _reg.get_resource(&"boss_marrow_sentinel")
    _bs._enemy = boss
    _bs.in_battle = true
    _sm.transition_to(&"state_battle")
    await get_tree().process_frame
    _bs._resolve_battle(true, 200, 0)
    await get_tree().process_frame
    # Inventory should be UNCHANGED (no reload)
    assert_eq(inventory.count(&"test_item"), item_count_before,
        "test_item count unchanged (no save reload)")
    assert_eq(inventory.count(&"pollution"), pollution_before,
        "pollution count unchanged (no save reload)")
    # Cleanup
    _dm.end_dialogue()
    await get_tree().process_frame

# --- E) Each ending tree has non-empty text ---

func test_ending_A_text_is_non_empty() -> void:
    var tree: Resource = _reg.get_resource(&"dlg_ending_A")
    var nodes: Dictionary = tree.get("nodes")
    var ending_node: Dictionary = nodes[&"ending"]
    var text: String = String(ending_node.get("text", ""))
    assert_gt(text.length(), 50, "ending A text is non-trivial (>50 chars)")

func test_ending_B_text_is_non_empty() -> void:
    var tree: Resource = _reg.get_resource(&"dlg_ending_B")
    var nodes: Dictionary = tree.get("nodes")
    var ending_node: Dictionary = nodes[&"ending"]
    var text: String = String(ending_node.get("text", ""))
    assert_gt(text.length(), 50, "ending B text is non-trivial (>50 chars)")

func test_ending_C_text_is_non_empty() -> void:
    var tree: Resource = _reg.get_resource(&"dlg_ending_C")
    var nodes: Dictionary = tree.get("nodes")
    var ending_node: Dictionary = nodes[&"ending"]
    var text: String = String(ending_node.get("text", ""))
    assert_gt(text.length(), 50, "ending C text is non-trivial (>50 chars)")

# --- F) AUTO mode is force-disabled after boss win (S4-007 cross-cut) ---

func test_auto_mode_force_disabled_after_boss_win() -> void:
    # If player was in AUTO mode and triggered boss fight (via the
    # encounter transition), the AUTO timer should be force-stopped
    # when the battle ends. Otherwise the timer could leak into
    # the ending dialogue state.
    var loadout: Node = get_node("/root/WeaponLoadout")
    loadout.set_auto_mode(true)
    assert_true(loadout.is_auto_mode(), "AUTO mode on before boss fight")
    var boss: Resource = _reg.get_resource(&"boss_marrow_sentinel")
    _bs._enemy = boss
    _bs.in_battle = true
    _sm.transition_to(&"state_battle")
    await get_tree().process_frame
    _bs._resolve_battle(true, 200, 0)
    await get_tree().process_frame
    # BattleScene._on_state_changed has logic to force-stop AUTO on
    # state_battle exit; verify it happened.
    assert_false(loadout.is_auto_mode(),
        "AUTO mode force-disabled after boss win (no timer leak into ending dialogue)")
    # Cleanup
    _dm.end_dialogue()
