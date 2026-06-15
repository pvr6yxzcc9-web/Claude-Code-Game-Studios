extends Node

# Sprint 1 S1-002 runner: 10-room traversal test
# Loads only tests/integration/sprint1_10_room_traversal_test.gd

const GUT_SCRIPT_PATH = "res://addons/gut/gut.gd"

func _ready() -> void:
    await get_tree().process_frame

    var gut: Node = load(GUT_SCRIPT_PATH).new()
    get_tree().root.add_child(gut)

    gut.log_level = 2
    gut.add_script("res://tests/integration/sprint1_10_room_traversal_test.gd")

    gut.run_tests()

    while gut.is_running():
        await get_tree().process_frame

    var passed: int = gut.get_pass_count()
    var failed: int = gut.get_fail_count()

    # Dump failing tests if any
    var has_failures: bool = false
    for cs in gut.get_test_collector().scripts:
        for t in cs.tests:
            if t.fail_texts.size() > 0:
                if not has_failures:
                    print("\n=== GUT Sprint1 Failing Tests ===")
                    has_failures = true
                print("  [FAIL] %s::%s" % [cs.path, t.name])
                for ft in t.fail_texts:
                    print("         %s" % ft)

    print("\n=== GUT Sprint1 Results ===")
    print("Passed:  %d" % passed)
    print("Failed:  %d" % failed)

    if DisplayServer.get_name() == "headless":
        if failed > 0:
            get_tree().quit(1)
        else:
            get_tree().quit(0)
