extends GutTest

# FC-32 Wall structure (S5-001 F5 fix)
# Bug found in F5: rooms with a right door (or left door) had no wall
# at the door's side, so the player could walk off-screen. The fix
# splits the side wall into two vertical segments above and below the
# 96px door gap. This test pins the new wall structure.

const MAIN_SCENE := "res://src/main.tscn"

var _main: Node = null
var _level_runtime: Node = null

func before_all() -> void:
    _main = load(MAIN_SCENE).instantiate()
    get_tree().root.add_child(_main)
    await get_tree().process_frame
    await get_tree().process_frame
    _level_runtime = get_tree().get_root().find_child("Main", true, false)

func after_all() -> void:
    if _main != null:
        _main.queue_free()
        _main = null

# --- A) Room 0 (has both left door=no and right door=yes) ---
# Expected: left wall single, right wall split (top+bot with 96px gap)

func test_room_0_left_wall_is_single() -> void:
    _level_runtime.build_room(0)
    await get_tree().process_frame
    var wall: StaticBody2D = _find_walls()
    assert_not_null(wall)
    # Find segments at x=-16
    var left_segments: Array = _segments_at_x(wall, -16.0)
    assert_eq(left_segments.size(), 1, "room 0 left side has 1 segment (no left door)")

func test_room_0_right_wall_is_split_with_door_gap() -> void:
    _level_runtime.build_room(0)
    await get_tree().process_frame
    var wall: StaticBody2D = _find_walls()
    assert_not_null(wall)
    # Find segments at x=1296
    var right_segments: Array = _segments_at_x(wall, 1296.0)
    assert_eq(right_segments.size(), 2, "room 0 right side has 2 segments (split for right door)")
    # Top segment ends at y <= 312, bottom starts at y >= 408
    var top_y_end: float = right_segments[0].position.y + right_segments[0].shape.size.y / 2
    var bot_y_start: float = right_segments[1].position.y - right_segments[1].shape.size.y / 2
    assert_true(top_y_end <= 312, "top segment ends at or before y=312 (got %f)" % top_y_end)
    assert_true(bot_y_start >= 408, "bottom segment starts at or after y=408 (got %f)" % bot_y_start)

# --- B) Room 9 (last room, no right door, no left door) ---
# Expected: both left and right walls are single (no doors at all)

func test_room_9_both_side_walls_are_single() -> void:
    _level_runtime.build_room(9)
    await get_tree().process_frame
    var wall: StaticBody2D = _find_walls()
    assert_not_null(wall)
    var left_segments: Array = _segments_at_x(wall, -16.0)
    var right_segments: Array = _segments_at_x(wall, 1296.0)
    assert_eq(left_segments.size(), 1, "room 9 left wall single (no left door)")
    assert_eq(right_segments.size(), 1, "room 9 right wall single (no right door)")

# --- C) Room 5 (mid, has both left and right doors) ---
# Expected: both sides split

func test_room_5_both_side_walls_are_split() -> void:
    _level_runtime.build_room(5)
    await get_tree().process_frame
    var wall: StaticBody2D = _find_walls()
    assert_not_null(wall)
    var left_segments: Array = _segments_at_x(wall, -16.0)
    var right_segments: Array = _segments_at_x(wall, 1296.0)
    assert_eq(left_segments.size(), 2, "room 5 left side split (has left door)")
    assert_eq(right_segments.size(), 2, "room 5 right side split (has right door)")

# --- D) Regression: original right_wall_position_unchanged ---

func test_full_wall_position_unchanged() -> void:
    # Room 9 right wall position must remain (1296, 360) (regression pin)
    _level_runtime.build_room(9)
    await get_tree().process_frame
    var wall: StaticBody2D = _find_walls()
    var right_segments: Array = _segments_at_x(wall, 1296.0)
    assert_eq(right_segments.size(), 1, "1 segment for full right wall")
    var seg: CollisionShape2D = right_segments[0]
    assert_eq(seg.position, Vector2(1296, 360), "full right wall center still at (1296, 360)")
    # Size 32x752 (the original rect_h)
    assert_eq(seg.shape.size, Vector2(32, 752), "full right wall size unchanged")

# --- Helpers ---

func _find_walls() -> StaticBody2D:
    for child in _level_runtime.get_children():
        if child.name == "Walls" and child is StaticBody2D:
            return child
    return null

func _segments_at_x(wall: StaticBody2D, x: float) -> Array[CollisionShape2D]:
    var result: Array[CollisionShape2D] = []
    for child in wall.get_children():
        if child is CollisionShape2D:
            var cs: CollisionShape2D = child
            if abs(cs.position.x - x) < 0.5:
                result.append(cs)
    return result
