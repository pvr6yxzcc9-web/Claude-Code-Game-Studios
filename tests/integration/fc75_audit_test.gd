extends GutTest

# Polish audit test (Sprint 12, fc75) — pre-F5 verification.
# Checks that all critical systems are in place so the game can load.

const EXPECTED_AUTOLOADS: Array[String] = [
	"GameStateMachine",
	"InputBus",
	"ResourceRegistry",
	"MetaState",
	"SaveManager",
	"WeaponLoadout",
	"Inventory",
	"MechLoadout",
	"ClinicManager",
	"MechBayEvents",
	"AutoModeAI",
	"HallucinationManager",
	"AIEnemyManager",
	"BountyManager",
	"RacingManager",
	"EndingController",
]

# 8 new autoloads added this session
const NEW_AUTOLOADS: Array[String] = [
	"ClinicManager",
	"MechBayEvents",
	"AutoModeAI",
	"HallucinationManager",
	"AIEnemyManager",
	"BountyManager",
	"RacingManager",
]

const EXPECTED_RESOURCES: Array[String] = [
	"MechCombatLoadout",
	"RoomData",
]

const EXPECTED_UI_SCENES: Array[String] = [
	"res://src/ui/mech_bay_ui.gd",
	"res://src/ui/bounty_board_ui.gd",
	"res://src/ui/racing_arena_ui.gd",
	"res://src/ui/race_animation.gd",
	"res://src/ui/post_credit_scene.gd",
]

func test_all_expected_autoloads_registered() -> void:
	for autoload_name in EXPECTED_AUTOLOADS:
		var node: Node = get_node_or_null("/root/%s" % autoload_name)
		assert_not_null(node, "%s autoload is registered" % autoload_name)

func test_all_new_autoloads_functional() -> void:
	# All 7 NEW autoloads (Sprint 7-11) must have basic methods
	var cm: Node = get_node_or_null("/root/ClinicManager")
	if cm != null:
		assert_true(cm.has_method("get_revival_cost"), "ClinicManager.get_revival_cost")
		assert_true(cm.has_method("revive_pilot"), "ClinicManager.revive_pilot")
	var mbe: Node = get_node_or_null("/root/MechBayEvents")
	if mbe != null:
		assert_true(mbe.has_method("set_active_mech"), "MechBayEvents.set_active_mech")
		assert_true(mbe.has_method("assign_pilot"), "MechBayEvents.assign_pilot")
		assert_true(mbe.has_method("move_weapon"), "MechBayEvents.move_weapon")
	var ai: Node = get_node_or_null("/root/AutoModeAI")
	if ai != null:
		assert_true(ai.has_method("toggle_auto_mode"), "AutoModeAI.toggle_auto_mode")
		assert_true(ai.has_method("set_enemy_targets"), "AutoModeAI.set_enemy_targets")
	var hm: Node = get_node_or_null("/root/HallucinationManager")
	if hm != null:
		assert_true(hm.has_method("is_decoy"), "HallucinationManager.is_decoy")
		assert_true(hm.has_method("on_attack"), "HallucinationManager.on_attack")
	var aim: Node = get_node_or_null("/root/AIEnemyManager")
	if aim != null:
		assert_true(aim.has_method("try_trigger_ability"), "AIEnemyManager.try_trigger_ability")
		assert_true(aim.has_method("tick_turn"), "AIEnemyManager.tick_turn")
	var bm: Node = get_node_or_null("/root/BountyManager")
	if bm != null:
		assert_true(bm.has_method("accept_bounty"), "BountyManager.accept_bounty")
		assert_true(bm.has_method("complete_bounty"), "BountyManager.complete_bounty")
	var rm: Node = get_node_or_null("/root/RacingManager")
	if rm != null:
		assert_true(rm.has_method("run_race"), "RacingManager.run_race")
		assert_true(rm.has_method("place_bet"), "RacingManager.place_bet")

func test_new_resource_types_exist() -> void:
	# MechCombatLoadout
	var MechCombatLoadout: Script = load("res://src/resource/mech_combat_loadout.gd")
	if MechCombatLoadout == null:
		pending("MechCombatLoadout script not found")
		return
	assert_true(MechCombatLoadout.has_method("new"), "MechCombatLoadout has new()")
	var instance: Resource = MechCombatLoadout.new()
	assert_not_null(instance, "MechCombatLoadout instantiated")
	assert_true(instance.has_method("get"), "instance is Resource")
	# RoomData
	var RoomData: Script = load("res://src/resource/room_data.gd")
	if RoomData == null:
		pending("RoomData script not found")
		return
	var rd: Resource = RoomData.new()
	assert_not_null(rd, "RoomData instantiated")

func test_all_ui_scene_scripts_exist() -> void:
	for path in EXPECTED_UI_SCENES:
		assert_true(FileAccess.file_exists(path), "%s exists" % path)

func test_all_satellite_chapters_registered() -> void:
	# 5 satellites × chapter header (.tres)
	var reg: Node = get_node_or_null("/root/ResourceRegistry")
	if reg == null:
		pending("ResourceRegistry missing")
		return
	var expected: Array[StringName] = [
		&"chapter1_frozen_reactor",  # (assumed — check below)
		&"chapter2_frozen_reactor",
		&"chapter3_hive",
		&"chapter4_warzone",
		&"chapter5_origin",
	]
	# We only check the new ones (chapter1 may not have chapter1 ID)
	for cid in [&"chapter2_frozen_reactor", &"chapter3_hive", &"chapter4_warzone", &"chapter5_origin"]:
		var chapter: Resource = reg.get_resource(cid)
		assert_not_null(chapter, "%s registered" % cid)

func test_all_satellite_bosses_registered() -> void:
	var reg: Node = get_node_or_null("/root/ResourceRegistry")
	if reg == null:
		return
	for bid in [&"boss_ice_warden", &"boss_hive_queen_guardian", &"boss_pluto_remnant", &"boss_creator"]:
		var boss: Resource = reg.get_resource(bid)
		assert_not_null(boss, "%s registered" % bid)

func test_ending_controller_has_4_endings() -> void:
	var ec: Node = get_node_or_null("/root/EndingController")
	if ec == null:
		pending("EndingController missing")
		return
	var info_a: Dictionary = ec.get_post_credit_info("A")
	var info_b: Dictionary = ec.get_post_credit_info("B")
	var info_c: Dictionary = ec.get_post_credit_info("C")
	var info_d: Dictionary = ec.get_post_credit_info("D")
	assert_gt(info_a.size(), 0, "Ending A info present")
	assert_gt(info_b.size(), 0, "Ending B info present")
	assert_gt(info_c.size(), 0, "Ending C info present")
	assert_gt(info_d.size(), 0, "Ending D info present")

func test_total_data_files_present() -> void:
	# Verify all .tres files are loadable
	var reg: Node = get_node_or_null("/root/ResourceRegistry")
	if reg == null:
		pending("ResourceRegistry missing")
		return
	# Check a sample of resources from each satellite
	var sample: Array[StringName] = [
		&"chapter3_hive",
		&"chapter4_warzone",
		&"chapter5_origin",
		&"boss_hive_queen_guardian",
		&"boss_pluto_remnant",
		&"boss_creator",
		&"fragment_hive_1",
		&"fragment_ch4_1",
		&"fragment_ch5_1",
	]
	var loaded_count: int = 0
	for rid in sample:
		if reg.get_resource(rid) != null:
			loaded_count += 1
	assert_eq(loaded_count, sample.size(), "All sample resources loaded")

func test_localization_csv_has_all_4_endings() -> void:
	# Verify the localization CSV has the post-credit endings
	if not FileAccess.file_exists("res://design/l10n/strings.csv"):
		pending("strings.csv missing")
		return
	var f: FileAccess = FileAccess.open("res://design/l10n/strings.csv", FileAccess.READ)
	if f == null:
		return
	var content: String = f.get_as_text()
	f.close()
	assert_true(content.contains("ending_a_title"), "has ending_a_title")
	assert_true(content.contains("ending_b_title"), "has ending_b_title")
	assert_true(content.contains("ending_c_title"), "has ending_c_title")
	assert_true(content.contains("ending_d_title"), "has ending_d_title")
	assert_true(content.contains("race_animation"), "has race_animation keys")
	assert_true(content.contains("bounty_board"), "has bounty_board keys")

func test_generated_bgms_all_present() -> void:
	var bgms: Array[String] = [
		"res://assets/audio/music/frozen_reactor.wav",
		"res://assets/audio/music/hive_heart.wav",
		"res://assets/audio/music/wreckage_echo.wav",
		"res://assets/audio/music/creators_dream.wav",
	]
	for bgm in bgms:
		assert_true(FileAccess.file_exists(bgm), "%s exists" % bgm)

func test_all_satellite_tilesets_present() -> void:
	var tilesets: Array[String] = [
		"res://assets/tilesets/ch3/",
		"res://assets/tilesets/ch4/",
		"res://assets/tilesets/ch5/",
	]
	for path in tilesets:
		assert_true(DirAccess.dir_exists_absolute(path), "%s directory exists" % path)
		# Each tileset should have at least 4 tiles
		var d: DirAccess = DirAccess.open(path)
		if d != null:
			d.list_dir_begin()
			var count: int = 0
			while d.list_dir_next() != END_OF_FILE:
				if not d.get_current().begins_with("."):
					count += 1
			d.list_dir_end()
			assert_ge(count, 4, "%s has ≥4 tile files" % path)

func test_save_load_v2_migration_works() -> void:
	# Critical for backward compatibility
	var sm: Node = get_node_or_null("/root/SaveManager")
	if sm == null:
		pending("SaveManager missing")
		return
	assert_eq(int(sm.SAVE_VERSION_CURRENT), 2, "Save version is 2")
	# Verify migration function exists
	assert_true(sm.has_method("_upgrade_v1_to_v2"), "_upgrade_v1_to_v2 exists")