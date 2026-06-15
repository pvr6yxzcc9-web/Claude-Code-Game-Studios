extends Node

const TEST_SCENE := "res://tests/integration/fc7_npc_test.gd"
const GUT_SCRIPT_PATH := "res://addons/gut/gut.gd"

func _ready() -> void:
    await get_tree().process_frame

    var gut: Node = load(GUT_SCRIPT_PATH).new()
    get_tree().root.add_child(gut)

    gut.log_level = 2
    gut.add_script(TEST_SCENE)

    gut.run_tests()

    while gut.is_running():
        await get_tree().process_frame

    var passed: int = gut.get_pass_count()
    var failed: int = gut.get_fail_count()

    var has_failures: bool = false
    for cs in gut.get_test_collector().scripts:
        for t in cs.tests:
            if t.fail_texts.size() > 0:
                if not has_failures:
                    print("\n=== GUT FC-7 Failing Tests ===")
                    has_failures = true
                print("  [FAIL] %s::%s" % [cs.path, t.name])
                for ft in t.fail_texts:
                    print("         %s" % ft)

    print("\n=== GUT FC-7 Results ===")
    print("Passed:  %d" % passed)
    print("Failed:  %d" % failed)

    if DisplayServer.get_name() == "headless":
        if failed > 0:
            get_tree().quit(1)
        else:
            get_tree().quit(0)
