extends Node

# Sprint 7+ regression runner — runs all Sprint 7-12 test files.
# Mirrors sprint7_runner.gd but covers the entire party + content phase.

const GUT_SCRIPT_PATH = "res://addons/gut/gut.gd"

const TEST_SCRIPTS: Array[String] = [
	# Sprint 7 — Party System
	"res://tests/integration/fc59_formulas_test.gd",
	"res://tests/integration/fc60_save_load_test.gd",
	"res://tests/integration/fc61_auto_mode_test.gd",
	"res://tests/integration/fc62_hud_3mech_test.gd",
	"res://tests/integration/fc63_dialogue_companion_test.gd",
	"res://tests/integration/fc64_clinic_revive_test.gd",
	"res://tests/integration/fc65_mech_bay_test.gd",
	"res://tests/integration/fc66_cangqiong_inheritance_test.gd",
	"res://tests/integration/fc67_sprint7_coverage_test.gd",
	# Sprint 8 — Sat-3 Hive
	"res://tests/integration/fc68_sat3_hallucination_test.gd",
	"res://tests/integration/fc69_sat3_rooms_test.gd",
	# Sprint 9 — Sat-4 Military
	"res://tests/integration/fc70_sat4_ai_mechanic_test.gd",
	# Sprint 10 — Sat-5 Climax + 4 Endings
	"res://tests/integration/fc71_sat5_ending_test.gd",
	# Sprint 11 — Bounty + Racing
	"res://tests/integration/fc72_bounty_racing_test.gd",
	"res://tests/integration/fc73_bounty_racing_ui_test.gd",
	# Sprint 12 — Polish
	"res://tests/integration/fc74_polish_test.gd",
	"res://tests/integration/fc75_audit_test.gd",
	"res://tests/integration/fc76_full_game_flow_test.gd",
	"res://tests/integration/fc77_combat_stress_test.gd",
	# Sprint 7 unit tests
	"res://tests/unit/autoload/fc60_weapon_decoupling_test.gd",
	"res://tests/unit/autoload/fc61_mech_swap_test.gd",
	"res://tests/unit/resource/mech_combat_loadout_test.gd",
]

func _ready() -> void:
	await get_tree().process_frame

	var gut: Node = load(GUT_SCRIPT_PATH).new()
	get_tree().root.add_child(gut)

	gut.log_level = 2
	for script_path in TEST_SCRIPTS:
		gut.add_script(script_path)

	gut.run_tests()

	while gut.is_running():
		await get_tree().process_frame

	var passed: int = gut.get_pass_count()
	var failed: int = gut.get_fail_count()
	var pending: int = gut.get_pending_count()

	# Dump failing tests
	var has_failures: bool = false
	for cs in gut.get_test_collector().scripts:
		for t in cs.tests:
			if t.fail_texts.size() > 0:
				if not has_failures:
					print("\n=== GUT Sprint7+ Failing Tests ===")
					has_failures = true
				print("  [FAIL] %s::%s" % [cs.path, t.name])
				for ft in t.fail_texts:
					print("         %s" % ft)

	print("\n=== GUT Sprint7+ Results ===")
	print("Scripts: %d" % TEST_SCRIPTS.size())
	print("Passed:  %d" % passed)
	print("Failed:  %d" % failed)
	print("Pending: %d" % pending)

	if DisplayServer.get_name() == "headless":
		if failed > 0:
			get_tree().quit(1)
		else:
			get_tree().quit(0)