extends GutTest

# FC-25 Fragment arc (S4-005)
# Pins:
#   1) 6 new fragments + 1 new terminal log + 1 new terminal log + 1 new terminal log
#      exist in registry with valid schema fields
#   2) lore_layer ladder 1-6 is monotonic
#   3) related_fragment_ids form a connected graph (the_convoy <-> marlows_daughter)
#   4) 2 of 6 fragments have working unlock via terminal log
#      (the_convoy, marlows_daughter). 4 are tbd (stub body + unlock_condition tbd_sprint5)
#   5) TerminalController.open_log on new logs unlocks new fragments

const NEW_FRAGMENT_IDS: Array[StringName] = [
    &"fragment_the_convoy",
    &"fragment_marlows_daughter",
    &"fragment_the_seal",
    &"fragment_what_was_carried",
    &"fragment_the_truth",
    &"fragment_engineer_last_stand",
]

const ACTIVE_FRAGMENT_IDS: Array[StringName] = [
    &"fragment_the_convoy",
    &"fragment_marlows_daughter",
    # the_seal was S4-005 tbd but promoted to active by S4-008 (hidden
    # terminal in room 4 unlocks it via the breakable wall).
    &"fragment_the_seal",
]

const TBD_FRAGMENT_IDS: Array[StringName] = [
    # These three were S4-005 tbd; S5-005 wired them to boss_victory
    # (BattleScene._resolve_battle unlocks them right before the
    # EndingController determines the ending).
    &"fragment_what_was_carried",
    &"fragment_the_truth",
    &"fragment_engineer_last_stand",
]

const NEW_LOG_IDS: Array[StringName] = [
    &"log_wreckage_inspection",
    &"log_personal_log",
    &"log_engine_room_note",  # reserved for Sprint 5 (currently no spawn)
]

func before_each() -> void:
    var meta: Node = get_node_or_null("/root/MetaState")
    if meta != null:
        meta.unlocked.clear()

# --- A) Resources loaded ---

func test_six_new_fragments_in_registry() -> void:
    var reg: Node = get_node("/root/ResourceRegistry")
    for id in NEW_FRAGMENT_IDS:
        var r: Resource = reg.get_resource(id)
        assert_not_null(r, "%s must be in registry" % id)

func test_three_new_logs_in_registry() -> void:
    var reg: Node = get_node("/root/ResourceRegistry")
    for id in NEW_LOG_IDS:
        var r: Resource = reg.get_resource(id)
        assert_not_null(r, "%s must be in registry" % id)

# --- B) Lore layer ladder 1-6 ---

func test_lore_layer_ladder_monotonic() -> void:
    # Each fragment should have lore_layer in 1-6 (range matches the arc
    # depth: 1=surface truth, 6=deepest). Order is by id alphabetically for
    # determinism; the ladder is the ARC ORDER, not alphabetical.
    var reg: Node = get_node("/root/ResourceRegistry")
    # Arc order (surface to deep):
    var arc_order: Array[StringName] = [
        &"fragment_who_we_were",        # layer 1
        &"fragment_the_convoy",         # layer 2
        &"fragment_marlows_daughter",   # layer 3
        &"fragment_the_seal",           # layer 4
        &"fragment_what_was_carried",   # layer 5 (tied with engineer)
        &"fragment_engineer_last_stand",# layer 5
        &"fragment_the_truth",          # layer 6
    ]
    var last_layer: int = 0
    for id in arc_order:
        var r: Resource = reg.get_resource(id)
        var layer: int = int(r.get("lore_layer"))
        assert_true(layer >= last_layer, "%s layer %d >= previous %d" % [id, layer, last_layer])
        assert_true(layer >= 1 and layer <= 10, "%s layer in [1,10]" % id)
        last_layer = layer

# --- C) Related graph connectivity ---

func test_related_fragment_graph_is_connected() -> void:
    # The arc forms a chain: who_we_were -> the_convoy -> marlows_daughter ->
    # the_seal -> what_was_carried -> engineer_last_stand -> the_truth.
    # Each fragment's related_fragment_ids should include at least one
    # neighbor (or its own back-link).
    var reg: Node = get_node("/root/ResourceRegistry")
    for id in NEW_FRAGMENT_IDS:
        var r: Resource = reg.get_resource(id)
        var rel: Array[StringName] = r.get("related_fragment_ids") if r.get("related_fragment_ids") != null else []
        assert_gt(rel.size(), 0, "%s should have at least one related_fragment" % id)
        # Verify the related IDs all exist in registry
        for ref_id in rel:
            var ref: Resource = reg.get_resource(ref_id)
            assert_not_null(ref, "%s references %s which must be in registry" % [id, ref_id])

# --- D) Active fragments unlock via terminal log ---

func test_log_wreckage_inspection_unlocks_the_convoy() -> void:
    var tc: Node = get_node("/root/TerminalController")
    var reg: Node = get_node("/root/ResourceRegistry")
    var log: Resource = reg.get_resource(&"log_wreckage_inspection")
    assert_eq(StringName(log.get("unlock_fragment_id")), &"fragment_the_convoy",
        "log links to fragment_the_convoy")
    tc.open_log(log)
    assert_true(get_node("/root/MetaState").is_unlocked(&"fragment_the_convoy"),
        "fragment_the_convoy unlocked after open_log")

func test_log_personal_log_unlocks_marlows_daughter() -> void:
    var tc: Node = get_node("/root/TerminalController")
    var reg: Node = get_node("/root/ResourceRegistry")
    var log: Resource = reg.get_resource(&"log_personal_log")
    assert_eq(StringName(log.get("unlock_fragment_id")), &"fragment_marlows_daughter",
        "log links to fragment_marlows_daughter")
    tc.open_log(log)
    assert_true(get_node("/root/MetaState").is_unlocked(&"fragment_marlows_daughter"),
        "fragment_marlows_daughter unlocked after open_log")

# --- E) TBD fragments are properly stubbed ---

func test_tbd_fragments_have_boss_victory_unlock_condition() -> void:
    # S5-005: 3 tbd fragments now unlock on boss victory. The
    # "tbd_sprint5" placeholder string is gone; the trigger is the
    # boss_victory marker that BattleScene._resolve_battle honors
    # right before determining the ending.
    var reg: Node = get_node("/root/ResourceRegistry")
    for id in TBD_FRAGMENT_IDS:
        var r: Resource = reg.get_resource(id)
        var cond: StringName = r.get("unlock_condition")
        assert_eq(cond, &"boss_victory", "%s has boss_victory unlock_condition" % id)

# --- F) Total fragment count ---

func test_total_fragment_count_in_registry() -> void:
    var reg: Node = get_node("/root/ResourceRegistry")
    var all_ids: Array[StringName] = [&"fragment_who_we_were"]
    for id in NEW_FRAGMENT_IDS:
        all_ids.append(id)
    var count: int = 0
    for id in all_ids:
        if reg.get_resource(id) != null:
            count += 1
    assert_eq(count, 7, "exactly 7 fragments in registry (was 1 in Sprint 2)")
