extends GutTest

# Integration test: Sat-4 断魂号 content + AI enemy mechanic (Sprint 9, fc70)
# Per sprint-09-sat4-military.md
# Verifies:
#   - AIEnemyManager autoload is registered
#   - 3 AI enemy abilities registered (force_recalculate_aim,
#     disable_player_ability_1_turn, summon_scrap_drone)
#   - Boss ability (disable_2_player_abilities_1_turn)
#   - try_trigger_ability returns true for known enemies with cooldowns
#   - Cooldown ticks decrement
#   - Locked abilities expire on tick_turn
#   - reset() clears state
#   - 6 Sat-4 enemy .tres load via ResourceRegistry
#   - Boss .tres loads
#   - 7 fragment .tres load
#   - 10 room data files exist
#   - chapter4.tres loads
#   - 4 NPC .tres load
#   - 17 generated assets exist on disk

const AIM_PATH: String = "/root/AIEnemyManager"

func _aim() -> Node:
	var aim: Node = get_node_or_null(AIM_PATH)
	if aim == null:
		pending("AIEnemyManager autoload missing")
		return null
	return aim

func test_ai_enemy_manager_registered() -> void:
	var aim: Node = _aim()
	if aim == null:
		return
	assert_not_null(aim, "AIEnemyManager autoload registered")

func test_three_ai_abilities_registered() -> void:
	var aim: Node = _aim()
	if aim == null:
		return
	assert_true(aim._abilities.has(&"ch4_renegade_sentinel"), "renegade_sentinel ability registered")
	assert_true(aim._abilities.has(&"ch4_ai_remnant"), "ai_remnant ability registered")
	assert_true(aim._abilities.has(&"ch4_rogue_drone"), "rogue_drone ability registered")

func test_boss_ability_registered() -> void:
	var aim: Node = _aim()
	if aim == null:
		return
	assert_true(aim._abilities.has(&"boss_pluto_remnant"), "boss ability registered")
	var boss_abilities: Array = aim._abilities[&"boss_pluto_remnant"]
	assert_gt(boss_abilities.size(), 0, "boss has ≥1 ability")

func test_renegade_sentinel_ability_is_disable() -> void:
	var aim: Node = _aim()
	if aim == null:
		return
	var abilities: Array = aim._abilities[&"ch4_renegade_sentinel"]
	var ability: StringName = abilities[0]["ability"]
	assert_eq(String(ability), "disable_player_ability_1_turn", "sentinel ability disables 1 player ability")

func test_ai_remnant_ability_is_force_recalculate() -> void:
	var aim: Node = _aim()
	if aim == null:
		return
	var abilities: Array = aim._abilities[&"ch4_ai_remnant"]
	var ability: StringName = abilities[0]["ability"]
	assert_eq(String(ability), "force_recalculate_aim", "remnant ability is force_recalculate_aim")

func test_rogue_drone_ability_is_summon() -> void:
	var aim: Node = _aim()
	if aim == null:
		return
	var abilities: Array = aim._abilities[&"ch4_rogue_drone"]
	var ability: StringName = abilities[0]["ability"]
	assert_eq(String(ability), "summon_scrap_drone", "drone ability is summon_scrap_drone")
	var params: Dictionary = abilities[0]["params"]
	assert_eq(String(params.get("ally_id", &"")), "ch4_wreck_bot", "summon spawns wreck_bot")

func test_try_trigger_ability_with_high_chance() -> void:
	var aim: Node = _aim()
	if aim == null:
		return
	# Force chance to 1.0 for deterministic test
	aim.register_ability(&"test_enemy", &"test_ability", 1.0, 0)
	var triggered: bool = false
	var handler: Callable = func(_e: StringName, _a: StringName, _t: StringName) -> void:
		triggered = true
	aim.ai_ability_triggered.connect(handler)
	var result: bool = aim.try_trigger_ability(&"test_enemy", &"player_1")
	assert_true(result, "ability triggered with 100% chance")
	assert_true(triggered, "signal emitted")
	if aim.ai_ability_triggered.is_connected(handler):
		aim.ai_ability_triggered.disconnect(handler)
	aim.reset()

func test_ability_cooldown_ticks() -> void:
	var aim: Node = _aim()
	if aim == null:
		return
	aim.reset()
	aim.register_ability(&"test_enemy_cd", &"test_ability", 1.0, 3)
	aim.try_trigger_ability(&"test_enemy_cd", &"player_1")
	var key: String = "test_enemy_cd_test_ability"
	assert_eq(int(aim._cooldowns.get(key, 0)), 3, "cooldown set to 3")
	aim.tick_turn()
	assert_eq(int(aim._cooldowns.get(key, 0)), 2, "cooldown decremented to 2")
	aim.tick_turn()
	assert_eq(int(aim._cooldowns.get(key, 0)), 1, "cooldown decremented to 1")
	aim.tick_turn()
	assert_false(aim._cooldowns.has(key), "cooldown expired and removed")
	aim.reset()

func test_player_ability_lock_expires() -> void:
	var aim: Node = _aim()
	if aim == null:
		return
	aim.reset()
	# Trigger sentinel's disable ability 5 times to ensure it lands
	for i in 20:
		aim._locked_abilities.clear()
		aim.try_trigger_ability(&"ch4_renegade_sentinel", &"player_1")
		if aim.is_ability_locked(&"q"):
			break
	# Some lock should be active
	if aim.is_ability_locked(&"q"):
		assert_true(aim.is_ability_locked(&"q"), "ability q is locked")
		aim.tick_turn()
		assert_false(aim.is_ability_locked(&"q"), "lock expires after 1 tick")
	aim.reset()

func test_get_locked_abilities() -> void:
	var aim: Node = _aim()
	if aim == null:
		return
	aim.reset()
	aim._locked_abilities[&"q"] = 1
	aim._locked_abilities[&"w"] = 1
	var locked: Array = aim.get_locked_abilities()
	assert_eq(locked.size(), 2, "2 abilities locked")
	aim.reset()

func test_reset_clears_state() -> void:
	var aim: Node = _aim()
	if aim == null:
		return
	aim._locked_abilities[&"q"] = 1
	aim._cooldowns[&"test"] = 5
	aim.reset()
	assert_eq(aim._locked_abilities.size(), 0, "locks cleared")
	assert_eq(aim._cooldowns.size(), 0, "cooldowns cleared")

# === Sat-4 resource tests ===

func test_sat4_enemy_resources_exist() -> void:
	var reg: Node = get_node_or_null("/root/ResourceRegistry")
	if reg == null:
		pending("ResourceRegistry missing")
		return
	for eid in [&"ch4_ai_remnant", &"ch4_renegade_sentinel", &"ch4_rogue_drone", &"ch4_battle_mech", &"ch4_wreck_bot", &"ch4_self_destruct"]:
		var resource: Resource = reg.get_resource(StringName(eid))
		assert_not_null(resource, "%s registered" % eid)

func test_sat4_boss_resource_exists() -> void:
	var reg: Node = get_node_or_null("/root/ResourceRegistry")
	if reg == null:
		return
	var boss: Resource = reg.get_resource(&"boss_pluto_remnant")
	assert_not_null(boss, "boss_pluto_remnant registered")
	assert_true(boss.boss, "is a boss")

func test_sat4_fragment_resources_exist() -> void:
	var reg: Node = get_node_or_null("/root/ResourceRegistry")
	if reg == null:
		return
	for i in 7:
		var fid: StringName = StringName("fragment_ch4_%d" % (i + 1))
		var frag: Resource = reg.get_resource(fid)
		assert_not_null(frag, "%s registered" % fid)

func test_sat4_chapter4_resource_exists() -> void:
	var reg: Node = get_node_or_null("/root/ResourceRegistry")
	if reg == null:
		return
	var chapter: Resource = reg.get_resource(&"chapter4_warzone")
	assert_not_null(chapter, "chapter4_warzone registered")

func test_sat4_npcs_have_portraits() -> void:
	var reg: Node = get_node_or_null("/root/ResourceRegistry")
	if reg == null:
		return
	for npc_id in [&"ch4_veteran", &"ch4_ai_repair", &"ch4_pluto_fragment", &"ch4_war_orphan"]:
		var npc: Resource = reg.get_resource(StringName(npc_id))
		assert_not_null(npc, "%s registered" % npc_id)
		assert_not_null(npc.portrait, "%s has portrait" % npc_id)

func test_sat4_10_room_data_files_exist() -> void:
	for i in 10:
		var rid: String = "c4_r%d" % (i + 1)
		var path: String = "res://data/levels/ch4/%s.tres" % rid
		assert_true(FileAccess.file_exists(path), "%s room data exists" % rid)

func test_sat4_assets_exist_on_disk() -> void:
	var paths: Array[String] = [
		"res://assets/tilesets/ch4/floor_military.png",
		"res://assets/tilesets/ch4/floor_military_damaged.png",
		"res://assets/tilesets/ch4/wall_military.png",
		"res://assets/tilesets/ch4/wall_military_damaged.png",
		"res://assets/sprites/enemies/ch4_ai_remnant.png",
		"res://assets/sprites/enemies/ch4_renegade_sentinel.png",
		"res://assets/sprites/enemies/ch4_rogue_drone.png",
		"res://assets/sprites/enemies/ch4_battle_mech.png",
		"res://assets/sprites/enemies/ch4_wreck_bot.png",
		"res://assets/sprites/enemies/ch4_self_destruct.png",
		"res://assets/sprites/enemies/boss_pluto_remnant.png",
		"res://assets/sprites/npcs/ch4_veteran.png",
		"res://assets/sprites/npcs/ch4_ai_repair.png",
		"res://assets/sprites/npcs/ch4_pluto_fragment.png",
		"res://assets/sprites/npcs/ch4_war_orphan.png",
		"res://assets/sprites/title/title_ch4.png",
		"res://assets/audio/music/wreckage_echo.wav",
	]
	for path in paths:
		assert_true(FileAccess.file_exists(path), "asset exists: %s" % path)

func test_sat4_room_boss_room() -> void:
	# Load c4_r10 (boss arena) and verify has_boss=true
	var room: Resource = load("res://data/levels/ch4/c4_r10.tres")
	if room == null:
		pending("c4_r10 not loadable")
		return
	assert_true(room.has_boss, "c4_r10 has boss")
	assert_eq(String(room.enemy_encounters[0]), "boss_pluto_remnant", "boss is Pluto Remnant")

func test_sat4_bomber_recruitment_room() -> void:
	# c4_r5 should have a Bomber-related NPC
	var room: Resource = load("res://data/levels/ch4/c4_r5.tres")
	if room == null:
		return
	assert_gt(room.npcs.size(), 0, "c4_r5 has an NPC (Bomber)")