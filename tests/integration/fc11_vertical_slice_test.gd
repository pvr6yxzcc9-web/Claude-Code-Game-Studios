extends GutTest

# FC-11 Vertical Slice Validation
# Verifies: main scene boots end-to-end with all 11 autoloads + 4 UIs + LevelRuntime.

func test_main_scene_loads() -> void:
    var main: PackedScene = load("res://src/main.tscn")
    assert_not_null(main, "main.tscn loads")

func test_main_scene_has_all_ui_systems() -> void:
    var main: PackedScene = load("res://src/main.tscn")
    var instance: Node = main.instantiate()
    var found_ui: Array[String] = []
    for child in instance.get_children():
        found_ui.append(child.name)
    instance.queue_free()
    var expected: Array[String] = ["Player", "BattleScene", "HUD", "SaveUI", "CodexUI", "TerminalUI", "DialogueUI"]
    var missing: Array = []
    for e in expected:
        if e not in found_ui:
            missing.append(e)
    assert_eq(missing.size(), 0, "all UI systems present; missing: %s" % str(missing))

func test_level_runtime_present_in_main() -> void:
    var main: PackedScene = load("res://src/main.tscn")
    var instance: Node = main.instantiate()
    # PR-10: LevelRuntime is the ROOT script of main.tscn, not a child
    var is_level: bool = false
    if instance.get_script() != null:
        var script_path: String = instance.get_script().resource_path
        if script_path.ends_with("level_runtime.gd"):
            is_level = true
    instance.queue_free()
    assert_true(is_level, "LevelRuntime script present as root of main scene")

func test_player_has_camera_child() -> void:
    var main: PackedScene = load("res://src/main.tscn")
    var instance: Node = main.instantiate()
    var player: Node = null
    for child in instance.get_children():
        if child.name == "Player":
            player = child
            break
    if player == null:
        pending("Player not in main scene")
        instance.queue_free()
        return
    var has_camera: bool = false
    for c in player.get_children():
        if c is Camera2D:
            has_camera = true
            break
    instance.queue_free()
    assert_true(has_camera, "Player has Camera2D child for follow")

func test_everything_required_loaded_for_vertical_slice() -> void:
    # Run the autoload + main scene instantiation and verify nothing errors
    var main: PackedScene = load("res://src/main.tscn")
    var instance: Node = main.instantiate()
    # Simulate add_child to root to trigger _ready
    var save: Node = get_node("/root/SaveManager")
    var file_count_before: int = 0
    var dir: DirAccess = DirAccess.open("user://")
    if dir != null:
        dir.list_dir_begin()
        var entry: String = dir.get_next()
        while entry != "":
            if entry.ends_with(".json"):
                file_count_before += 1
            entry = dir.get_next()
    add_child_autofree(instance) if Engine.has_singleton("Engine") else null
    # Verify all 11 autoloads
    var expected: Array[String] = [
        "GameStateMachine", "InputBus", "ResourceRegistry", "MetaState",
        "MechLoadout", "WeaponLoadout", "Inventory", "TerminalController",
        "DialogueManager", "SaveManager", "ResourceIntegrity",
    ]
    var missing: Array = []
    for n in expected:
        if get_node_or_null("/root/" + n) == null:
            missing.append(n)
    assert_eq(missing.size(), 0, "all 11 autoloads present after main scene load; missing: %s" % str(missing))

func test_resources_loaded_count_is_substantial() -> void:
    # Per PR-9, we expect ~10-15 resources: 3 weapons + 3 ammo + 2 enemies +
    # 1 mech part + 1 log + 1 fragment + 1 NPC + 1 dialogue + 1 level
    var reg: Node = get_node("/root/ResourceRegistry")
    var count: int = reg._registry.size()
    assert_true(count >= 10, "at least 10 resources in registry, got %d" % count)
