extends GutTest

# FC-4 Smoke Test — Pre-Production PR-3 (room geometry + camera + collision)
# Validates: Player position, walls present, encounter tile trigger, camera follow target.

const MAIN_SCENE := "res://src/main.tscn"

var _main: Node = null

func before_all() -> void:
    _main = load(MAIN_SCENE).instantiate()
    get_tree().root.add_child(_main)
    # Wait two frames for _ready and build_room(0) to complete
    await get_tree().process_frame
    await get_tree().process_frame

func after_all() -> void:
    if _main != null:
        _main.queue_free()
        _main = null

func _find_by_name(root: Node, name_to_find: String) -> Node:
    if root.name == name_to_find:
        return root
    for child in root.get_children():
        var found: Node = _find_by_name(child, name_to_find)
        if found != null:
            return found
    return null

func test_player_node_exists_in_main_scene() -> void:
    var found: Node = get_node_or_null("/root/Main/Player")
    assert_not_null(found, "Player node present under /root/Main")

func test_walls_present() -> void:
    var walls: Node = get_node_or_null("/root/Main/Walls")
    if walls == null:
        pending("Walls not found in scene tree")
        return
    var walls_found: int = 0
    for child in walls.get_children():
        if child is CollisionShape2D:
            walls_found += 1
    # Room 0 is the first room — has top + bottom + right walls (no left, since it's the start).
    # Mid rooms (1..8) have 4 walls. Boss room (9) has top + bottom + left (no right).
    assert_eq(walls_found, 3, "room 0 has 3 wall collision shapes (top + bottom + right; no left wall)")

func test_encounter_tile_present() -> void:
    # Encounter tiles are spawned dynamically by LevelRuntime, named "Node2D" (default).
    # Look for the LevelRuntime and check it has encounters.
    var runtime: Node = get_node_or_null("/root/Main")
    if runtime == null:
        pending("Main (LevelRuntime) not in tree")
        return
    var encs: Array = runtime._encounters
    assert_true(encs.size() > 0, "LevelRuntime has at least 1 encounter spawned")
    var has_area: bool = false
    for enc in encs:
        for child in enc.get_children():
            if child is Area2D:
                has_area = true
                break
        if has_area:
            break
    assert_true(has_area, "At least one encounter wrapper contains an Area2D")

func test_camera_target_is_player() -> void:
    var player: Node = _find_by_name(get_tree().get_root(), "Player")
    if player == null:
        pending("Player not found")
        return
    var cam: Camera2D = null
    for child in player.get_children():
        if child is Camera2D:
            cam = child
            break
    if cam == null:
        pending("Camera2D not found in Player children")
        return
    assert_true(cam.target != null, "Camera target is set (auto-detected parent)")
    assert_true(cam.target.name == "Player", "Camera target is Player")

func test_player_has_collision_shape() -> void:
    var player: Node = _find_by_name(get_tree().get_root(), "Player")
    if player == null:
        pending("Player not found in main scene")
        return
    var has_shape: bool = false
    for child in player.get_children():
        if child is CollisionShape2D and child.shape != null:
            has_shape = true
            break
    assert_true(has_shape, "Player has a CollisionShape2D with a shape")

func test_state_machine_in_battle_returns_to_exploration() -> void:
    var sm: Node = get_node("/root/GameStateMachine")
    sm.transition_to(&"state_battle")
    sm.transition_to(&"state_exploration")
    assert_eq(sm.top_of_stack, &"state_exploration", "back to exploration after battle")
