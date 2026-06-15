extends Node

# FC-4 Smoke test runner — requires main scene loaded (NOT just autoloads).
# This runner is run with the main scene as the test container.
# Loads main.tscn then runs fc4_room_test.gd.

const MAIN_SCENE := "res://src/main.tscn"
const TEST_SCENE := "res://tests/integration/fc4_room_test.gd"
const GUT_SCRIPT_PATH := "res://addons/gut/gut.gd"

func _ready() -> void:
	await get_tree().process_frame

	# Load the main scene as a child of root (NOT change_scene_to_file which tears down
	# the runner). The test will see it as a sibling of FC4Runner under /root.
	var main: PackedScene = load(MAIN_SCENE)
	if main == null:
		push_error("FC-4: failed to load main scene")
		get_tree().quit(1)
		return
	var main_instance: Node = main.instantiate()
	main_instance.name = "MainSceneInstance"
	get_tree().root.add_child(main_instance)
	print("[FC-4 Runner] main scene instantiated as child of root")

	# Spin several frames so _ready() of all autoloads + scene nodes runs
	for i in 5:
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

	# Dump failures if any
	var has_failures: bool = false
	for cs in gut.get_test_collector().scripts:
		for t in cs.tests:
			if t.fail_texts.size() > 0:
				if not has_failures:
					print("\n=== GUT FC-4 Failing Tests ===")
					has_failures = true
				print("  [FAIL] %s::%s" % [cs.path, t.name])
				for ft in t.fail_texts:
					print("         %s" % ft)

	print("\n=== GUT FC-4 Results ===")
	print("Passed:  %d" % passed)
	print("Failed:  %d" % failed)

	if DisplayServer.get_name() == "headless":
		if failed > 0:
			get_tree().quit(1)
		else:
			get_tree().quit(0)
