extends Node

# Sprint 7 consolidated runner (S7-012)
# Runs all 8 Sprint 7 test files (fc59-fc66) plus the unit tests
# (fc60/fc61 autoload tests + mech_combat_loadout_test).

const GUT_SCRIPT_PATH = "res://addons/gut/gut.gd"

const TEST_SCRIPTS: Array[String] = [
	# S7-009 — Combat formulas
	"res://tests/integration/fc59_formulas_test.gd",
	# S7-010 — Save/Load versioning
	"res://tests/integration/fc60_save_load_test.gd",
	# S7-011 — Auto mode 3-pilot AI
	"res://tests/integration/fc61_auto_mode_test.gd",
	# S7-004 — HUD 3-4 mech HP bars
	"res://tests/integration/fc62_hud_3mech_test.gd",
	# S7-005 — Dialogue companion swap
	"res://tests/integration/fc63_dialogue_companion_test.gd",
	# S7-006 — Town clinic revival
	"res://tests/integration/fc64_clinic_revive_test.gd",
	# S7-007 — Mech Bay menu
	"res://tests/integration/fc65_mech_bay_test.gd",
	# S7-008 — 苍穹号 inheritance cutscene
	"res://tests/integration/fc66_cangqiong_inheritance_test.gd",
	# S7-012 — Sprint 7 coverage matrix
	"res://tests/integration/fc67_sprint7_coverage_test.gd",
	# S7-002 — Unit tests (WeaponLoadout pilot-mech decoupling)
	"res://tests/unit/autoload/fc60_weapon_decoupling_test.gd",
	# S7-003 — Unit tests (MechLoadout 4-mech roster)
	"res://tests/unit/autoload/fc61_mech_swap_test.gd",
	# S7-002 + S7-003 — Resource type tests
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

	# Dump failing tests if any
	var has_failures: bool = false
	for cs in gut.get_test_collector().scripts:
		for t in cs.tests:
			if t.fail_texts.size() > 0:
				if not has_failures:
					print("\n=== GUT Sprint7 Failing Tests ===")
					has_failures = true
				print("  [FAIL] %s::%s" % [cs.path, t.name])
				for ft in t.fail_texts:
					print("         %s" % ft)

	print("\n=== GUT Sprint7 Results ===")
	print("Scripts: %d" % TEST_SCRIPTS.size())
	print("Passed:  %d" % passed)
	print("Failed:  %d" % failed)
	print("Pending: %d" % pending)

	if DisplayServer.get_name() == "headless":
		if failed > 0:
			get_tree().quit(1)
		else:
			get_tree().quit(0)