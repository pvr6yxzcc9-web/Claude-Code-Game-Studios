extends GutTest

# Sprint 1 S1-002: Full 10-room traversal verification.
# Loads main.tscn, calls build_room(0..9) on the LevelRuntime,
# asserts that each room is built and has the expected walls/doors/encounters.

const MAIN_SCENE := "res://src/main.tscn"

var _main: Node = null
var _runtime: Node = null

func before_all() -> void:
    _main = load(MAIN_SCENE).instantiate()
    get_tree().root.add_child(_main)
    # Wait one frame for _ready to run + call_deferred(build_room, 0) to fire
    await get_tree().process_frame
    await get_tree().process_frame
    _runtime = _main

func after_all() -> void:
    if _main != null:
        _main.queue_free()
        _main = null
        _runtime = null

func test_main_scene_instantiates() -> void:
    assert_not_null(_main, "main.tscn must instantiate")
    assert_not_null(_runtime, "Main (LevelRuntime) must be the root")

func test_room_zero_built_with_1_door_1_encounter() -> void:
    # Room 0: right door (to room 1) + encounter (scavenger)
    var doors: Array = _runtime._doors
    var encs: Array = _runtime._encounters
    assert_eq(doors.size(), 1, "room 0 has 1 right door")
    assert_eq(encs.size(), 1, "room 0 has 1 scavenger encounter")

func test_walls_built_with_correct_collision_shapes() -> void:
    var walls: StaticBody2D = _runtime._walls
    assert_not_null(walls, "walls must exist in room 0")
    # room 0: top + bottom + right (no left since it's first room) = 3 collision shapes
    assert_eq(walls.get_child_count(), 3, "room 0 walls: top + bottom + right = 3 shapes")

func test_room_9_boss_room_has_no_right_door() -> void:
    # Build room 9 (last = boss)
    _runtime.build_room(9)
    var doors: Array = _runtime._doors
    # room 9: left door (to room 8) only — no right door
    assert_eq(doors.size(), 1, "boss room has only left door, no right door")

func test_boss_room_has_boss_encounter() -> void:
    # Build boss room explicitly (don't rely on test order)
    _runtime.build_room(9)
    var encs: Array = _runtime._encounters
    assert_eq(encs.size(), 1, "boss room has 1 encounter")
    var enc: Node = encs[0]
    assert_eq(enc.get_meta("enemy_id"), &"boss_marrow_sentinel", "boss is boss_marrow_sentinel")

func test_all_10_rooms_built_without_error() -> void:
    for i in range(10):
        _runtime.build_room(i)
        var doors: Array = _runtime._doors
        var encs: Array = _runtime._encounters
        # room 0: 1 door (right), 1 scavenger enc
        # room 1..2: 2 doors (left + right), 1 scavenger enc
        # room 3..8: 2 doors (left + right), 0 enc (mid-game explore rooms)
        # room 9: 1 door (left), 1 boss enc
        var expected_doors: int = 1 if i == 0 or i == 9 else 2
        var expected_encs: int = 1 if i < 3 or i == 9 else 0
        assert_eq(doors.size(), expected_doors, "room %d has %d doors" % [i, expected_doors])
        assert_eq(encs.size(), expected_encs, "room %d has %d encounters" % [i, expected_encs])

func test_door_polling_triggers_build_room() -> void:
    # Build room 0, position player at right door, advance frame, verify room 1 built
    _runtime.build_room(0)
    # Wait for the 1.5s polling delay to elapse, then position player
    await get_tree().create_timer(2.0).timeout
    var player: Node = get_tree().root.find_child("Player", true, false)
    assert_not_null(player, "Player must exist")
    player.global_position = Vector2(1280, 360)
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    # After polling, room 1 should be built
    assert_eq(_runtime.current_room_index, 1, "polling should trigger transition to room 1")
