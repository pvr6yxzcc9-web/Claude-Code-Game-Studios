extends SceneTree

# Smoke test runner — runs the critical-path test list (~15 min manual gate)
#
# Usage: godot --headless --script tests/runners/smoke_runner.gd
#
# Smoke tests are the "did the build work end-to-end" gate. They cover
# the most important paths but skip exhaustive edge cases.

const GUT_SCRIPT_PATH = "res://addons/gut/test.gd"

func _init() -> void:
    await process_frame

    var gut: Node = load(GUT_SCRIPT_PATH).new()
    get_root().add_child(gut)

    gut.gut_config.gut_run_on_load = false
    gut.gut_config.gut_log_level = 1  # WARN (less verbose)
    gut.gut_config.terminal_output_style = 1
    gut.gut_config.unit_test_name = "smoke"
    gut.gut_config.unit_test_path = "res://tests/smoke/"
    gut.gut_config.dirs_to_scan = ["res://tests/smoke/"]
    gut.gut_config.should_print_to_console = true

    gut.run_tests()

    await process_frame
    while gut.is_running():
        await process_frame

    var passed: int = gut.get_pass_count()
    var failed: int = gut.get_fail_count()

    print("\n=== Smoke Test Results ===")
    print("Passed: %d" % passed)
    print("Failed: %d" % failed)

    if failed > 0:
        quit(1)
    else:
        quit(0)
