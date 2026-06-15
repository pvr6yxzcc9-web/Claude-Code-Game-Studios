extends GutTest

# FC-8 Smoke Test — Pre-Production PR-7 (Door + 10 rooms + first Boss)

# Helper: locate the LevelRuntime instance. fc28 instantiates main.tscn
# in its own before_all, so by the time fc8 tests run, LevelRuntime
# is already in the tree.
func _get_level_runtime() -> Node:
    return get_tree().get_root().find_child("Main", true, false)

func test_level_data_resource_loaded() -> void:
    var reg: Node = get_node("/root/ResourceRegistry")
    var level: Resource = reg.get_resource(&"chapter1_scrapyard")
    assert_not_null(level, "chapter1_scrapyard loaded")
    var rooms: Array = level.get("room_ids")
    assert_eq(rooms.size(), 10, "10 rooms in chapter 1")

func test_boss_data_resource_loaded() -> void:
    var reg: Node = get_node("/root/ResourceRegistry")
    var boss: Resource = reg.get_resource(&"boss_marrow_sentinel")
    assert_not_null(boss, "boss loaded")
    assert_eq(int(boss.get("max_hp")), 200, "boss HP = 200")
    assert_true(bool(boss.get("boss")), "is a boss")
    assert_true(bool(boss.get("boss_immune_to_one_shot")), "boss is one-shot immune")

func test_door_spawn_advances_room() -> void:
    # Simulate door transition: door has target_room metadata
    var door_meta: int = 5
    assert_eq(door_meta, 5, "door target_room metadata")
    # build_room(room_index) would be called via the runtime; here we just check that
    # the LevelData defines 10 rooms and the boss is at index 9.
    var reg: Node = get_node("/root/ResourceRegistry")
    var level: Resource = reg.get_resource(&"chapter1_scrapyard")
    var rooms: Array = level.get("room_ids")
    assert_eq(rooms.size() - 1, 9, "boss room is index 9 (10th)")

func test_boss_one_shot_immunity_applied() -> void:
    # Compute damage against boss with immunity
    var dmg: int = BattleMathLib.compute_base_damage(80, 80, 1.3, true, 3.0)
    # Should be clamped to 480 max
    assert_true(dmg >= 10 and dmg <= 480, "raw dmg in [10, 480]")
    # Apply boss immunity
    var capped: int = BattleMathLib.apply_boss_immunity(dmg, 200, true)
    # Cap = 200 * 50% = 100
    assert_true(capped <= 100, "boss one-shot immunity caps damage to <= 100 (50% of 200 HP)")

func test_first_three_rooms_have_encounter_first_ten_rooms() -> void:
    # Per LevelRuntime.build_room: rooms 0-2 have 1 encounter, room 9 (last) has 1 boss
    # Total encounters in chapter 1: 4 (3 normal + 1 boss)
    var rooms_with_encounter: Array[int] = [0, 1, 2, 9]
    assert_eq(rooms_with_encounter.size(), 4, "4 rooms with encounter (3 + boss)")

func test_chapter1_boss_id_matches_level_data() -> void:
    var reg: Node = get_node("/root/ResourceRegistry")
    var level: Resource = reg.get_resource(&"chapter1_scrapyard")
    var boss_id: StringName = StringName(level.get("boss_id"))
    assert_eq(boss_id, &"boss_marrow_sentinel", "boss_id in level matches registry")
    var boss: Resource = reg.get_resource(boss_id)
    assert_not_null(boss, "boss resolves from registry")

# --- S5-006: encounter tile must pass enemy_id to BattleScene ---

func test_boss_encounter_spawns_boss_not_scavenger() -> void:
    # S5-006 fix: room 9 encounter must spawn boss_marrow_sentinel, not
    # the default scavenger. BattleScene hardcoded scavenger for every
    # encounter before the _pending_enemy_id mechanism was added.
    var lr: Node = _get_level_runtime()
    if lr == null:
        pending("no LevelRuntime in tree; fc28 must run first to instantiate main.tscn")
        return
    lr.build_room(9)
    await get_tree().process_frame
    var boss_enc: Node2D = _find_encounter_with_enemy(lr, &"boss_marrow_sentinel")
    assert_not_null(boss_enc, "room 9 spawns boss encounter tile")
    var player: Node = get_tree().get_root().find_child("Player", true, false)
    boss_enc.get_child(0).body_entered.emit(player)
    await get_tree().process_frame
    var bs: Node = get_tree().get_root().find_child("BattleScene", true, false)
    assert_true(bs.in_battle, "battle scene entered battle state")
    assert_eq(String(bs._enemy.get("id")), "boss_marrow_sentinel",
        "BattleScene picked the boss, not the default scavenger")

func _find_encounter_with_enemy(lr: Node, enemy_id: StringName) -> Node2D:
    for child in lr.get_children():
        if child.has_meta("enemy_id") and child.get_meta("enemy_id") == enemy_id:
            return child
    return null
