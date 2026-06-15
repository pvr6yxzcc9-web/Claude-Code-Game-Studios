extends Node

# Sprint 2 S2-002: Full regression runner
# Loads all FC-1..FC-11 + sprint1 integration tests and runs them sequentially.

const GUT_SCRIPT_PATH = "res://addons/gut/gut.gd"

const TEST_FILES: Array[String] = [
    "res://tests/integration/fc1_smoke_test.gd",
    "res://tests/integration/fc3_combat_smoke_test.gd",
    "res://tests/integration/fc4_room_test.gd",
    "res://tests/integration/fc5_mech_test.gd",
    "res://tests/integration/fc6_terminal_test.gd",
    "res://tests/integration/fc7_npc_test.gd",
    "res://tests/integration/fc8_level_test.gd",
    "res://tests/integration/fc9_save_test.gd",
    "res://tests/integration/fc10_polish_test.gd",
    "res://tests/integration/fc11_vertical_slice_test.gd",
    "res://tests/integration/fc12_weapons_test.gd",
    "res://tests/integration/fc13_enemies_test.gd",
    "res://tests/integration/fc14_npc_terminal_test.gd",
    "res://tests/integration/fc15_pacing_boss_test.gd",
    "res://tests/integration/fc16_onboarding_hint_test.gd",
    "res://tests/integration/fc17_codex_test.gd",
    "res://tests/integration/fc18_sfx_test.gd",
    "res://tests/integration/fc19_pause_test.gd",
    "res://tests/integration/fc20_codex_key_test.gd",
    "res://tests/integration/fc21_save_ui_test.gd",
    "res://tests/integration/fc22_dialogue_fragment_test.gd",
    "res://tests/integration/fc23_door_test.gd",
    "res://tests/integration/fc24_mech_cycle_test.gd",
    "res://tests/integration/fc25_fragment_arc_test.gd",
    "res://tests/integration/fc26_npc_arc_test.gd",
    "res://tests/integration/fc27_auto_mode_test.gd",
    "res://tests/integration/fc28_breakable_wall_test.gd",
    "res://tests/integration/fc29_ending_test.gd",
    "res://tests/integration/fc30_ammo_test.gd",
    "res://tests/integration/fc32_wall_structure_test.gd",
    "res://tests/integration/fc31_schema_consumer_test.gd",
    "res://tests/integration/fc33_ending_ui_test.gd",
    "res://tests/integration/fc34_tbd_unlock_test.gd",
    "res://tests/integration/fc35_wall_hint_test.gd",
    "res://tests/integration/fc36_build_script_test.gd",
    "res://tests/integration/fc37_tutorial_test.gd",
    "res://tests/integration/fc38_combat_feedback_test.gd",
    "res://tests/integration/fc39_death_screen_test.gd",
    "res://tests/integration/fc40_hud_sprites_test.gd",
    "res://tests/integration/fc41_tilemap_test.gd",
    "res://tests/integration/fc42_sfx_test.gd",
    "res://tests/integration/fc43_music_test.gd",
    "res://tests/integration/fc44_npc_portraits_test.gd",
    "res://tests/integration/fc45_title_art_test.gd",
    "res://tests/integration/fc46_localization_test.gd",
    "res://tests/integration/fc47_screenshots_test.gd",
    "res://tests/integration/fc48_l10n_coverage_test.gd",
    "res://tests/integration/fc49_build_pipeline_test.gd",
    "res://tests/integration/fc50_build_artifacts_test.gd",
    "res://tests/integration/sprint1_10_room_traversal_test.gd",
]

func _ready() -> void:
    await get_tree().process_frame

    var gut: Node = load(GUT_SCRIPT_PATH).new()
    get_tree().root.add_child(gut)

    gut.log_level = 1
    for path in TEST_FILES:
        gut.add_script(path)

    gut.run_tests()

    while gut.is_running():
        await get_tree().process_frame

    var passed: int = gut.get_pass_count()
    var failed: int = gut.get_fail_count()

    # Dump failing tests
    var has_failures: bool = false
    for cs in gut.get_test_collector().scripts:
        for t in cs.tests:
            if t.fail_texts.size() > 0:
                if not has_failures:
                    print("\n=== Regression Failing Tests ===")
                    has_failures = true
                print("  [FAIL] %s::%s" % [cs.path, t.name])
                for ft in t.fail_texts:
                    print("         %s" % ft)

    print("\n=== Regression Results ===")
    print("Passed:  %d" % passed)
    print("Failed:  %d" % failed)
    print("Total scripts: %d" % TEST_FILES.size())

    if DisplayServer.get_name() == "headless":
        if failed > 0:
            get_tree().quit(1)
        else:
            get_tree().quit(0)
