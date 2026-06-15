extends GutTest

# FC-15 Pacing + Boss Integration Test (S2-011 + S2-012)
# Verifies encounter pacing: rooms 3-8 have 0 encounters, room 9 has boss.

const MAIN_SCENE := "res://src/main.tscn"

var _main: Node = null

func before_all() -> void:
    _main = load(MAIN_SCENE).instantiate()
    get_tree().root.add_child(_main)
    await get_tree().process_frame
    await get_tree().process_frame

func after_all() -> void:
    if _main != null:
        _main.queue_free()
        _main = null

# --- S2-011: Encounter rate tuning ---

func test_mid_rooms_3_to_8_have_zero_encounters() -> void:
    # Per S2-011 AC: rooms 3-8 should have 0 encounters (rate feels intentional)
    for i in range(3, 9):
        _main.build_room(i)
        var encs: Array = _main._encounters
        assert_eq(encs.size(), 0, "room %d should have 0 encounters (mid-game pacing)" % i)

func test_early_rooms_have_one_scavenger_encounter() -> void:
    for i in range(3):
        _main.build_room(i)
        var encs: Array = _main._encounters
        assert_eq(encs.size(), 1, "room %d should have 1 encounter" % i)
        var enc: Node = encs[0]
        assert_eq(enc.get_meta("enemy_id"), &"scavenger", "room %d encounter is scavenger" % i)

# --- S2-012: Boss fight verify ---

func test_room_9_spawns_boss_encounter() -> void:
    _main.build_room(9)
    var encs: Array = _main._encounters
    assert_eq(encs.size(), 1, "room 9 spawns 1 encounter")
    var enc: Node = encs[0]
    assert_eq(enc.get_meta("enemy_id"), &"boss_marrow_sentinel", "room 9 encounter is boss")

func test_boss_has_immune_to_one_shot_flag() -> void:
    # Per ADR-0011: boss should be immune to one-shot kills
    var reg: Node = get_node("/root/ResourceRegistry")
    var boss: Resource = reg.get_resource(&"boss_marrow_sentinel")
    assert_not_null(boss, "boss resource loaded")
    assert_eq(boss.boss, true, "boss has boss flag = true")
    assert_eq(boss.boss_immune_to_one_shot, true, "boss has boss_immune_to_one_shot = true")

func test_boss_is_unique_among_enemies() -> void:
    # Only the boss should have boss=true; the 4 other enemies should have boss=false
    var reg: Node = get_node("/root/ResourceRegistry")
    var ids: Array[StringName] = [&"scavenger", &"drone", &"heavy_walker", &"sniper_bot", &"boss_marrow_sentinel"]
    for id in ids:
        var e: Resource = reg.get_resource(id)
        if e == null:
            continue
        if id == &"boss_marrow_sentinel":
            assert_eq(e.boss, true, "%s should be boss" % id)
        else:
            assert_eq(e.boss, false, "%s should NOT be boss" % id)
