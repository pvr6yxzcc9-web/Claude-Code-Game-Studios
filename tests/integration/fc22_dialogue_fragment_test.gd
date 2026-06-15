extends GutTest

# FC-22 Dialogue fragment unlock + HUD live counter (S2-005)
#
# Sprint 2 close report noted: "fragment count auto-increment on dialogue
# completion is wired in spirit but not directly verified by an automated
# test." This file locks in:
#   1) DialogueManager per-node unlock_fragment_id -> MetaState.mark_unlocked
#   2) HUD live counter update via MetaState.fragment_unlocked signal
#
# Terminal path (log.unlock_fragment_id -> MetaState) is already covered by
# fc6. This file is dialogue-specific.
#
# Test strategy: use DialogueManager.start_dialogue_with_tree() to inject
# synthetic trees without polluting data/ with test-only .tres files. The
# trees are plain Resource.new() with .set() field assignment, which works
# for the dynamic-Dictionary `nodes` payload that DialogueManager reads.

const TEST_FRAG_ID := &"fragment_fc22_test_only"

func before_each() -> void:
    var meta: Node = get_node_or_null("/root/MetaState")
    if meta != null:
        meta.unlocked.clear()

func _make_test_tree(unlock_id: StringName) -> Resource:
    # Tree with one node that has unlock_fragment_id = unlock_id
    var tree: Resource = Resource.new()
    tree.set("id", &"dlg_fc22_test")
    tree.set("start_node_id", &"greet")
    tree.set("nodes", {
        &"greet": {
            "text": "FC-22 test greeting.",
            "choices": [],
            "unlock_fragment_id": unlock_id,
        },
    })
    return tree

func _make_plain_tree() -> Resource:
    # Tree with one node that has NO unlock_fragment_id
    var tree: Resource = Resource.new()
    tree.set("id", &"dlg_fc22_plain")
    tree.set("start_node_id", &"greet")
    tree.set("nodes", {
        &"greet": {
            "text": "No fragment here.",
            "choices": [],
        },
    })
    return tree

func _make_test_npc() -> Resource:
    var npc: Resource = Resource.new()
    npc.set("id", &"fc22_test_npc")
    npc.set("display_name", "Test NPC")
    npc.set("role", &"test")
    npc.set("dialogue_tree_id", &"dlg_fc22_test")
    return npc

# --- A) Dialogue path: per-node unlock_fragment_id ---

func test_dialogue_start_unlocks_node_fragment() -> void:
    var dm: Node = get_node("/root/DialogueManager")
    var meta: Node = get_node("/root/MetaState")
    var received: Array = []
    meta.fragment_unlocked.connect(func(id: StringName) -> void: received.append(id))
    var tree: Resource = _make_test_tree(TEST_FRAG_ID)
    var npc: Resource = _make_test_npc()
    dm.start_dialogue_with_tree(tree, npc)
    await get_tree().process_frame
    assert_true(meta.is_unlocked(TEST_FRAG_ID), "fragment marked unlocked after entering node")
    assert_eq(received, [TEST_FRAG_ID], "fragment_unlocked signal emitted once with TEST_FRAG_ID")

func test_dialogue_re_enter_does_not_double_emit() -> void:
    var dm: Node = get_node("/root/DialogueManager")
    var meta: Node = get_node("/root/MetaState")
    var received: Array = []
    meta.fragment_unlocked.connect(func(id: StringName) -> void: received.append(id))
    var tree: Resource = _make_test_tree(TEST_FRAG_ID)
    var npc: Resource = _make_test_npc()
    dm.start_dialogue_with_tree(tree, npc)
    await get_tree().process_frame
    # End and re-start — fragment is already unlocked, no second signal
    dm.end_dialogue()
    await get_tree().process_frame
    dm.start_dialogue_with_tree(tree, npc)
    await get_tree().process_frame
    assert_eq(received, [TEST_FRAG_ID], "fragment_unlocked fired exactly once across re-entry")

# --- B) Backward-compat: node without unlock_fragment_id ---

func test_dialogue_node_without_unlock_field_does_nothing() -> void:
    var dm: Node = get_node("/root/DialogueManager")
    var meta: Node = get_node("/root/MetaState")
    var received: Array = []
    meta.fragment_unlocked.connect(func(id: StringName) -> void: received.append(id))
    var tree: Resource = _make_plain_tree()
    var npc: Resource = _make_test_npc()
    dm.start_dialogue_with_tree(tree, npc)
    await get_tree().process_frame
    assert_eq(received, [], "no fragment_unlocked fired when node has no unlock_fragment_id")

# --- C) HUD live counter ---

func test_hud_fragment_count_tracks_metastate() -> void:
    var meta: Node = get_node("/root/MetaState")
    var hud: Node = get_tree().get_root().find_child("HUD", true, false)
    assert_not_null(hud, "HUD present in scene tree")
    assert_eq(hud._fragment_count, 0, "HUD count starts at 0")
    meta.mark_unlocked(TEST_FRAG_ID)
    # mark_unlocked is synchronous + emits signal; HUD handler should have
    # run by next idle frame.
    await get_tree().process_frame
    assert_eq(hud._fragment_count, 1, "HUD count updates to 1 after mark_unlocked")
    meta.mark_unlocked(&"fragment_who_we_were")
    await get_tree().process_frame
    assert_eq(hud._fragment_count, 2, "HUD count updates to 2 after second unlock")
