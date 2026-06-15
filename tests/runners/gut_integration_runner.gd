extends Node

# GUT 9.6 test runner for integration tests (Godot 4.6 compatible).
# Extends Node so it can be attached to a scene; runs tests in _ready().
#
# Usage: F5/F6 with this scene as main, OR run from project root:
#   godot --headless res://tests/runners/gut_integration_runner.tscn
#
# GUT 9.6 API: gut.add_script(path) + gut.run_tests() (no more gut_config)
#
# NOTE: This scene is the temporary "main scene" while running tests.
# After running tests, restore the main scene to res://src/main.tscn:
#   Project > Project Settings > Run > Main Scene > res://src/main.tscn

const GUT_SCRIPT_PATH = "res://addons/gut/gut.gd"

func _ready() -> void:
	# Wait one frame for the scene tree to be ready
	await get_tree().process_frame

	# Create the GUT runner
	var gut: Node = load(GUT_SCRIPT_PATH).new()
	get_tree().root.add_child(gut)

	# Configure
	gut.log_level = 2  # ALL_ASSERTS
	# Add ONLY fc1_smoke_test.gd explicitly to avoid sweeping unit tests + helpers
	gut.add_script("res://tests/integration/fc1_smoke_test.gd")

	# Run tests
	gut.run_tests()

	# GUT runs asynchronously; wait for completion
	while gut.is_running():
		await get_tree().process_frame

	# Get result
	var passed: int = gut.get_pass_count()
	var failed: int = gut.get_fail_count()
	var pending: int = gut.get_pending_count()

	print("\n=== GUT Integration Results ===")
	print("Passed:  %d" % passed)
	print("Failed:  %d" % failed)
	print("Pending: %d" % pending)

	# Exit with proper code (only if running headless)
	if DisplayServer.get_name() == "headless":
		if failed > 0:
			get_tree().quit(1)
		else:
			get_tree().quit(0)
