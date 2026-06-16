extends GutTest

# Unit test: MechCombatLoadout resource type (S7-002)
# Per party-system.md §3.5 (4 parts HP) + sprint-07-002 plan
# Verifies the per-mech data model: weapon slots, ammo slots, 4 parts HP,
# special module slot, max_weapon_slots.
#
# NOTE: Distinct from the `MechLoadout` autoload (5 equipable mech parts).
# The weapon-side data is `MechCombatLoadout`.

func test_default_loadout_has_3_slots() -> void:
	var loadout: MechCombatLoadout = MechCombatLoadout.new()
	assert_eq(loadout.max_weapon_slots, 3, "default 3 weapon slots")
	assert_eq(loadout.weapon_slots.size(), 3, "weapon_slots array size 3")
	assert_eq(loadout.ammo_slots.size(), 3, "ammo_slots array size 3")

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

func test_module_slot_default_empty() -> void:
	var loadout: MechCombatLoadout = MechCombatLoadout.new()
	assert_eq(String(loadout.module_id), "", "module_id empty by default")
	loadout.module_id = &"shield_booster"
	assert_eq(String(loadout.module_id), "shield_booster", "module_id can be set")

func test_active_slot_default_zero() -> void:
	var loadout: MechCombatLoadout = MechCombatLoadout.new()
	assert_eq(loadout.active_slot, 0, "active_slot defaults to 0")
	loadout.active_slot = 2
	assert_eq(loadout.active_slot, 2, "active_slot can be set")

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
	loadout.module_id = &"repair_drone"
	# dict representation (Godot Resource → dict via .duplicate or get_property_list)
	# We just verify the property assignments round-trip via .duplicate()
	var copy: Resource = loadout.duplicate()
	assert_eq(int(copy.head_hp), 75, "head_hp round-trips through duplicate")
	assert_eq(String(copy.module_id), "repair_drone", "module_id round-trips")
	assert_eq(String(copy.weapon_slots[3]), "d", "weapon_slots[3] round-trips")
	assert_eq(int(copy.max_weapon_slots), 4, "max_weapon_slots round-trips")
