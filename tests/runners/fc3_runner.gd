extends Node

# FC-3 Smoke test runner (PR-2 input wiring + combat stub)
# Loads only tests/integration/fc3_combat_smoke_test.gd

const GUT_SCRIPT_PATH = "res://addons/gut/gut.gd"

func _ready() -> void:
    await get_tree().process_frame

    var gut: Node = load(GUT_SCRIPT_PATH).new()
    get_tree().root.add_child(gut)

    gut.log_level = 2
    gut.add_script("res://tests/integration/fc3_combat_smoke_test.gd")

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
                    print("\n=== GUT FC-3 Failing Tests ===")
                    has_failures = true
                print("  [FAIL] %s::%s" % [cs.path, t.name])
                for ft in t.fail_texts:
                    print("         %s" % ft)

    print("\n=== GUT FC-3 Results ===")
    print("Passed:  %d" % passed)
    print("Failed:  %d" % failed)

    if DisplayServer.get_name() == "headless":
        if failed > 0:
            get_tree().quit(1)
        else:
            get_tree().quit(0)
