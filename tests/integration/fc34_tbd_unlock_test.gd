extends GutTest

# FC-34 Boss-victory tbd unlock (S5-005)
# Pins:
#   1) The 3 S4-005 tbd fragments are now unlockable via boss_victory
#   2) BattleScene._resolve_battle unlocks all 3 when boss is defeated
#   3) Non-boss victories do NOT unlock them (unchanged behavior)
#   4) The 3 are pre-marked as tbd (still stub bodies from S4-005
#      narrative draft, but unlock path is now real)

const MAIN_SCENE := "res://src/main.tscn"
const TBD_IDS: Array[StringName] = [
    &"fragment_what_was_carried",
    &"fragment_the_truth",
    &"fragment_engineer_last_stand",
]

var _main: Node = null
var _bs: Node = null
var _sm: Node = null
var _meta: Node = null
var _reg: Node = null
var _dm: Node = null

func before_all() -> void:
    _main = load(MAIN_SCENE).instantiate()
    get_tree().root.add_child(_main)
    await get_tree().process_frame
    await get_tree().process_frame
    _bs = get_tree().get_root().find_child("BattleScene", true, false)
    _sm = get_node("/root/GameStateMachine")
    _meta = get_node("/root/MetaState")
    _reg = get_node("/root/ResourceRegistry")
    _dm = get_node("/root/DialogueManager")

func after_all() -> void:
    if _main != null:
        _main.queue_free()
        _main = null

func before_each() -> void:
    _meta.unlocked.clear()
    while _sm.state_stack.size() > 1:
        _sm.pop()

# --- A) All 3 tbd resources unlockable on boss victory ---

func test_boss_victory_unlocks_all_three_tbd_fragments() -> void:
    var boss: Resource = _reg.get_resource(&"boss_marrow_sentinel")
    _bs._enemy = boss
    _bs.in_battle = true
    _sm.transition_to(&"state_battle")
    await get_tree().process_frame
    _bs._resolve_battle(true, 200, 0)
    await get_tree().process_frame
    for id in TBD_IDS:
        assert_true(_meta.is_unlocked(id), "%s unlocked after boss win" % id)
    # Cleanup
    _dm.end_dialogue()
    await get_tree().process_frame

func test_non_boss_victory_does_not_unlock_tbd() -> void:
    var scavenger: Resource = _reg.get_resource(&"scavenger")
    _bs._enemy = scavenger
    _bs.in_battle = true
    _sm.transition_to(&"state_battle")
    await get_tree().process_frame
    _bs._resolve_battle(true, 40, 0)
    await get_tree().process_frame
    for id in TBD_IDS:
        assert_false(_meta.is_unlocked(id), "%s NOT unlocked by non-boss win" % id)
    # Cleanup
    while _sm.state_stack.size() > 1:
        _sm.pop()

# --- B) tbd resources have boss_victory unlock_condition ---

func test_tbd_fragments_have_boss_victory_trigger() -> void:
    for id in TBD_IDS:
        var f: Resource = _reg.get_resource(id)
        assert_eq(StringName(f.get("unlock_condition")), &"boss_victory",
            "%s unlock_condition = boss_victory" % id)

# --- C) Idempotency: re-running boss victory does not re-emit ---

func test_re_running_boss_victory_is_idempotent() -> void:
    var boss: Resource = _reg.get_resource(&"boss_marrow_sentinel")
    _bs._enemy = boss
    _bs.in_battle = true
    _sm.transition_to(&"state_battle")
    await get_tree().process_frame
    _bs._resolve_battle(true, 200, 0)
    await get_tree().process_frame
    var first_count: int = _meta.unlocked.size()
    # Re-arm and resolve again
    _sm.transition_to(&"state_battle")
    await get_tree().process_frame
    _bs._resolve_battle(true, 200, 0)
    await get_tree().process_frame
    var second_count: int = _meta.unlocked.size()
    assert_eq(second_count, first_count,
        "second boss victory does not double-unlock (idempotent)")
    # Cleanup
    _dm.end_dialogue()
    await get_tree().process_frame

# --- D) boss victory unlocks tbd BEFORE ending determination ---

func test_tbd_unlocked_before_ending_determination() -> void:
    # The order matters: BattleScene._resolve_battle marks tbd unlock
    # BEFORE calling EndingController.play_ending. If reversed, ending
    # determination would see count=0 (or player-only count), which
    # would defeat the purpose of the tbd fragments.
    var boss: Resource = _reg.get_resource(&"boss_marrow_sentinel")
    _bs._enemy = boss
    _bs.in_battle = true
    _sm.transition_to(&"state_battle")
    await get_tree().process_frame
    # Pre-state: no tbd unlocked
    for id in TBD_IDS:
        assert_false(_meta.is_unlocked(id), "pre-state: tbd not unlocked yet")
    _bs._resolve_battle(true, 200, 0)
    # Immediately after (within same frame), tbd should be marked
    # (no need to await; BattleScene resolves synchronously before
    # calling play_ending which starts the dialogue asynchronously).
    for id in TBD_IDS:
        assert_true(_meta.is_unlocked(id), "after resolve: tbd marked")
    # Cleanup
    _dm.end_dialogue()
    await get_tree().process_frame
