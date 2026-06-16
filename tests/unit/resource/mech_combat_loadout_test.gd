extends GutTest

# Unit test: MechCombatLoadout resource type (S7-002 + S7-003)
# Per party-system.md §3.4 + §3.5 + sprint-07-003 plan
# Verifies the per-mech data model: identity, weapon slots, ammo slots,
# 4 parts HP, stats, module slots, unlocked flag.

func test_default_loadout_has_3_slots() -> void:
	var loadout: MechCombatLoadout = MechCombatLoadout.new()
	assert_eq(loadout.max_weapon_slots, 3, "default 3 weapon slots")
	assert_eq(loadout.weapon_slots.size(), 3, "weapon_slots array size 3")
	assert_eq(loadout.ammo_slots.size(), 3, "ammo_slots array size 3")

func test_default_identity_fields() -> void:
	var loadout: MechCombatLoadout = MechCombatLoadout.new()
	assert_eq(String(loadout.mech_id), "", "mech_id empty by default")
	assert_eq(loadout.display_name, "", "display_name empty by default")
	assert_eq(String(loadout.class_type), "infantry", "class_type defaults to infantry")
	loadout.mech_id = &"test_mech"
	loadout.display_name = "Test Mech"
	loadout.class_type = &"artillery"
	assert_eq(String(loadout.mech_id), "test_mech", "mech_id can be set")
	assert_eq(loadout.display_name, "Test Mech", "display_name can be set")
	assert_eq(String(loadout.class_type), "artillery", "class_type can be set")

func test_default_parts_hp_full() -> void:
	var loadout: MechCombatLoadout = MechCombatLoadout.new()
	assert_eq(loadout.head_hp, 100, "head_hp default 100")
	assert_eq(loadout.chest_hp, 100, "chest_hp default 100")
	assert_eq(loadout.arms_hp, 100, "arms_hp default 100")
	assert_eq(loadout.legs_hp, 100, "legs_hp default 100")
	assert_eq(loadout.max_head_hp, 100, "max_head_hp default 100")
	assert_eq(loadout.max_chest_hp, 100, "max_chest_hp default 100")
	assert_eq(loadout.max_arms_hp, 100, "max_arms_hp default 100")
	assert_eq(loadout.max_legs_hp, 100, "max_legs_hp default 100")

func test_default_slots_empty() -> void:
	var loadout: MechCombatLoadout = MechCombatLoadout.new()
	for i in loadout.weapon_slots.size():
		assert_eq(String(loadout.weapon_slots[i]), "", "weapon slot %d empty by default" % i)
	for i in loadout.ammo_slots.size():
		assert_eq(String(loadout.ammo_slots[i]), "", "ammo slot %d empty by default" % i)

func test_can_set_4_slots_for_cangqiong() -> void:
	var loadout: MechCombatLoadout = MechCombatLoadout.new()
	loadout.max_weapon_slots = 4
	loadout.weapon_slots = [&"plasma", &"laser", &"missile", &"emp"]
	loadout.ammo_slots = [&"p_cell", &"e_cell", &"m_round", &"emp"]
	assert_eq(loadout.weapon_slots.size(), 4, "4 weapon slots set")
	assert_eq(loadout.max_weapon_slots, 4, "max_weapon_slots = 4")
	assert_eq(String(loadout.weapon_slots[3]), "emp", "slot 3 set")

func test_module_slot_default_one_slot() -> void:
	var loadout: MechCombatLoadout = MechCombatLoadout.new()
	assert_eq(loadout.module_ids.size(), 1, "default 1 module slot")
	assert_eq(String(loadout.module_ids[0]), "", "module_ids[0] empty by default")
	loadout.module_ids[0] = &"shield_booster"
	assert_eq(String(loadout.module_ids[0]), "shield_booster", "module_ids[0] can be set")

func test_cangqiong_has_2_module_slots() -> void:
	var loadout: MechCombatLoadout = MechCombatLoadout.new()
	loadout.module_ids = [&"", &""]
	assert_eq(loadout.module_ids.size(), 2, "2 module slots")
	loadout.module_ids[1] = &"repair_drone"
	assert_eq(String(loadout.module_ids[1]), "repair_drone", "second module slot")

func test_default_stats_three_three_three() -> void:
	var loadout: MechCombatLoadout = MechCombatLoadout.new()
	assert_eq(loadout.mobility, 3, "default mobility 3")
	assert_eq(loadout.armor, 3, "default armor 3")
	assert_eq(loadout.firepower, 3, "default firepower 3")

func test_active_slot_default_zero() -> void:
	var loadout: MechCombatLoadout = MechCombatLoadout.new()
	assert_eq(loadout.active_slot, 0, "active_slot defaults to 0")
	loadout.active_slot = 2
	assert_eq(loadout.active_slot, 2, "active_slot can be set")

func test_unlocked_default_true() -> void:
	var loadout: MechCombatLoadout = MechCombatLoadout.new()
	assert_true(loadout.unlocked, "default unlocked=true")
	loadout.unlocked = false
	assert_false(loadout.unlocked, "unlocked can be set to false")

func test_independent_instances() -> void:
	# Critical: two MechCombatLoadout instances must be independent (not share state)
	var a: MechCombatLoadout = MechCombatLoadout.new()
	var b: MechCombatLoadout = MechCombatLoadout.new()
	a.weapon_slots[0] = &"rifle"
	b.weapon_slots[0] = &"cannon"
	assert_eq(String(a.weapon_slots[0]), "rifle", "a has rifle")
	assert_eq(String(b.weapon_slots[0]), "cannon", "b has cannon")
	# Mutating b's HP must not affect a
	b.head_hp = 50
	assert_eq(a.head_hp, 100, "a's head_hp unchanged after mutating b")

func test_resource_can_be_saved_and_loaded() -> void:
	# Resource must be serializable for save/load to work
	var loadout: MechCombatLoadout = MechCombatLoadout.new()
	loadout.max_weapon_slots = 4
	loadout.weapon_slots = [&"a", &"b", &"c", &"d"]
	loadout.head_hp = 75
	loadout.module_ids = [&"", &""]
	loadout.module_ids[0] = &"repair_drone"
	# dict representation (Godot Resource → dict via .duplicate or get_property_list)
	# We just verify the property assignments round-trip via .duplicate()
	var copy: Resource = loadout.duplicate()
	assert_eq(int(copy.head_hp), 75, "head_hp round-trips through duplicate")
	assert_eq(String(copy.module_ids[0]), "repair_drone", "module_ids[0] round-trips")
	assert_eq(String(copy.weapon_slots[3]), "d", "weapon_slots[3] round-trips")
	assert_eq(int(copy.max_weapon_slots), 4, "max_weapon_slots round-trips")