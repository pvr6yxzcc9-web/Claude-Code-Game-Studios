extends Node

# GUT 9.6 test runner for unit tests (Godot 4.6 compatible).
# Extends Node so it can be attached to a scene; runs tests in _ready().
#
# Usage: F5/F6 with this scene as main, OR run from project root:
#   godot --headless res://tests/runners/gut_runner.tscn
#
# GUT 9.6 API: gut.add_directory(path) + gut.run_tests() (no more gut_config)
#
# After running, restore main scene to res://src/main.tscn.

const GUT_SCRIPT_PATH = "res://addons/gut/gut.gd"

func _ready() -> void:
    await get_tree().process_frame

    var gut: Node = load(GUT_SCRIPT_PATH).new()
    get_tree().root.add_child(gut)

    gut.log_level = 2
    # add_directory broken in GUT 9.6 for this project — use add_script explicitly
    gut.add_script("res://tests/unit/combat/damage_bounds_test.gd")
    gut.add_script("res://tests/unit/resource/immutability_test.gd")

    gut.run_tests()

    while gut.is_running():
        await get_tree().process_frame

    var passed: int = gut.get_pass_count()
    var failed: int = gut.get_fail_count()
    var pending: int = gut.get_pending_count()

    # Dump failing test details
    var has_failures: bool = false
    for cs in gut.get_test_collector().scripts:
        for t in cs.tests:
            if t.fail_texts.size() > 0:
                if not has_failures:
                    print("\n=== GUT Failing Tests ===")
                    has_failures = true
                print("  [FAIL] %s::%s" % [cs.path, t.name])
                for ft in t.fail_texts:
                    print("         %s" % ft)

    print("\n=== GUT Unit Results ===")
    print("Passed:  %d" % passed)
    print("Failed:  %d" % failed)
    print("Pending: %d" % pending)

    if DisplayServer.get_name() == "headless":
        if failed > 0:
            get_tree().quit(1)
        else:
            get_tree().quit(0)
