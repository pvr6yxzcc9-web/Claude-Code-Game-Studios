extends GutTest

# FC-35 Breakable wall discoverability hint (S5-007)
# Pins:
#   1) Build room 4 spawns 2 hint markers above the breakable wall
#   2) Markers are Label nodes with "?" text
#   3) Markers are children of the wall (auto-free with wall)
#   4) After wall breaks, markers are gone (no zombie UI)

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

func _find_breakable_wall() -> StaticBody2D:
    for child in _level_runtime.get_children():
        var script: Script = child.get_script() if child.has_method("get_script") else null
        if script != null and script.resource_path.ends_with("breakable_wall.gd"):
            return child
    return null

func test_room_4_wall_has_two_hint_markers() -> void:
    _level_runtime.build_room(4)
    await get_tree().process_frame
    var wall: StaticBody2D = _find_breakable_wall()
    assert_not_null(wall, "room 4 spawns breakable wall")
    # Count Label children with "?" text
    var marker_count: int = 0
    for child in wall.get_children():
        if child is Label and child.text == "?":
            marker_count += 1
    assert_eq(marker_count, 2, "wall has 2 hint markers (S5-007 discoverability)")

func test_hint_markers_are_yellow() -> void:
    _level_runtime.build_room(4)
    await get_tree().process_frame
    var wall: StaticBody2D = _find_breakable_wall()
    var markers: Array = []
    for child in wall.get_children():
        if child is Label and child.text == "?":
            markers.append(child)
    assert_eq(markers.size(), 2)
    for m in markers:
        var color: Color = m.get_theme_color("font_color")
        # Yellow-ish: r > 0.9, g > 0.9, b < 0.6
        assert_gt(color.r, 0.9, "marker red > 0.9 (yellow)")
        assert_gt(color.g, 0.9, "marker green > 0.9 (yellow)")
        assert_lt(color.b, 0.6, "marker blue < 0.6 (yellow)")

func test_markers_auto_free_with_wall() -> void:
    _level_runtime.build_room(4)
    await get_tree().process_frame
    var wall: StaticBody2D = _find_breakable_wall()
    assert_not_null(wall)
    # Pre-break: markers exist
    var pre_count: int = 0
    for child in wall.get_children():
        if child is Label and child.text == "?":
            pre_count += 1
    assert_eq(pre_count, 2, "2 markers exist pre-break")
    # Break the wall
    wall._take_hit()
    wall._take_hit()
    wall._take_hit()
    await get_tree().process_frame
    # Wall queue_freed; markers queue_freed with parent
    assert_false(is_instance_valid(wall), "wall queue_freed after break")
    # Markers should be gone too (children of wall). Even if is_instance_valid
    # is true briefly, findable test below confirms scene tree is clean.
    var found_markers: int = 0
    for child in _level_runtime.get_children():
        if child is StaticBody2D and child.get_script() != null:
            if child.get_script().resource_path.ends_with("breakable_wall.gd"):
                for sub in child.get_children():
                    if sub is Label and sub.text == "?":
                        found_markers += 1
    assert_eq(found_markers, 0, "no zombie markers after wall break")

# --- D) Hint does NOT spawn for other rooms (no regression) ---

func test_room_3_has_no_wall_or_markers() -> void:
    _level_runtime.build_room(3)
    await get_tree().process_frame
    var wall: StaticBody2D = _find_breakable_wall()
    assert_null(wall, "room 3 has no breakable wall (and no hint markers)")
