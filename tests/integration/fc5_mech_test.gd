extends GutTest

# FC-5 Smoke Test — Pre-Production PR-4 (mech system + multi-weapon + ammo)

func before_each() -> void:
    var inv: Node = get_node_or_null("/root/Inventory")
    if inv != null:
        inv.reset()
    var mech: Node = get_node_or_null("/root/MechLoadout")
    if mech != null:
        for s in mech.SLOTS:
            mech.unequip_part(s)
    var loadout: Node = get_node_or_null("/root/WeaponLoadout")
    if loadout != null:
        loadout.equip_weapon(0, &"blaster_rifle")
        loadout.equip_weapon(1, &"shotgun")
        loadout.equip_weapon(2, &"sniper_rifle")

func test_resource_registry_loads_weapons_and_ammo() -> void:
    var reg: Node = get_node("/root/ResourceRegistry")
    assert_not_null(reg.get_resource(&"blaster_rifle"), "blaster_rifle loaded")
    assert_not_null(reg.get_resource(&"shotgun"), "shotgun loaded")
    assert_not_null(reg.get_resource(&"sniper_rifle"), "sniper_rifle loaded")
    assert_not_null(reg.get_resource(&"basic_cell"), "basic_cell loaded")
    assert_not_null(reg.get_resource(&"acid_round"), "acid_round loaded")
    assert_not_null(reg.get_resource(&"emp_charge"), "emp_charge loaded")

func test_weapon_loadout_all_three_slots_can_be_equipped() -> void:
    var loadout: Node = get_node("/root/WeaponLoadout")
    assert_eq(loadout.weapon_slots[0], &"blaster_rifle", "slot 0 = blaster_rifle")
    assert_eq(loadout.weapon_slots[1], &"shotgun", "slot 1 = shotgun")
    assert_eq(loadout.weapon_slots[2], &"sniper_rifle", "slot 2 = sniper_rifle")

func test_weapon_loadout_ammo_equip() -> void:
    var loadout: Node = get_node("/root/WeaponLoadout")
    loadout.equip_ammo(0, &"basic_cell")
    loadout.equip_ammo(1, &"acid_round")
    loadout.equip_ammo(2, &"emp_charge")
    assert_eq(loadout.ammo_slots[0], &"basic_cell", "ammo 0 = basic_cell")
    assert_eq(loadout.ammo_slots[1], &"acid_round", "ammo 1 = acid_round")
    assert_eq(loadout.ammo_slots[2], &"emp_charge", "ammo 2 = emp_charge")

func test_mech_loadout_default_all_empty() -> void:
    var mech: Node = get_node("/root/MechLoadout")
    for s in mech.SLOTS:
        assert_eq(mech.parts[s], &"", "slot %s starts empty" % s)

func test_mech_loadout_equip_part() -> void:
    var mech: Node = get_node("/root/MechLoadout")
    mech.equip_part(&"torso", &"starter_torso")
    assert_eq(mech.parts[&"torso"], &"starter_torso", "torso equipped")
    mech.unequip_part(&"torso")
    assert_eq(mech.parts[&"torso"], &"", "torso unequipped")

func test_mech_loadout_aggregated_stats() -> void:
    var mech: Node = get_node("/root/MechLoadout")
    mech.equip_part(&"torso", &"starter_torso")
    var stats: Dictionary = mech.get_aggregated_stats()
    # starter_torso contributes: hp=20, attack=5, defense=10
    assert_eq(stats.get("hp_bonus", 0), 20, "hp_bonus = 20")
    assert_eq(stats.get("attack_bonus", 0), 5, "attack_bonus = 5")
    assert_eq(stats.get("defense_bonus", 0), 10, "defense_bonus = 10")

func test_mech_loadout_aggregated_stats_empty_all_zero() -> void:
    var mech: Node = get_node("/root/MechLoadout")
    var stats: Dictionary = mech.get_aggregated_stats()
    assert_eq(stats.get("hp_bonus", -1), 0, "empty hp = 0")
    assert_eq(stats.get("attack_bonus", -1), 0, "empty attack = 0")
    assert_eq(stats.get("defense_bonus", -1), 0, "empty defense = 0")

func test_save_load_with_weapon_loadout_and_mech() -> void:
    var loadout: Node = get_node("/root/WeaponLoadout")
    loadout.equip_ammo(1, &"acid_round")
    var mech: Node = get_node("/root/MechLoadout")
    mech.equip_part(&"torso", &"starter_torso")
    var save: Node = get_node("/root/SaveManager")
    save.save_to_slot(2)
    await get_tree().create_timer(0.2).timeout
    # Mutate
    loadout.equip_ammo(1, &"basic_cell")
    mech.unequip_part(&"torso")
    # Restore
    save.load_from_slot(2)
    assert_eq(loadout.ammo_slots[1], &"acid_round", "ammo slot 1 restored")
    assert_eq(mech.parts[&"torso"], &"starter_torso", "mech torso restored")

# --- S4-001: arm parts (steady_arm + plated_arm) ---

func test_mech_parts_arm_resources_loaded() -> void:
    var reg: Node = get_node("/root/ResourceRegistry")
    var steady: Resource = reg.get_resource(&"steady_arm")
    var plated: Resource = reg.get_resource(&"plated_arm")
    assert_not_null(steady, "steady_arm loaded")
    assert_not_null(plated, "plated_arm loaded")
    assert_eq(String(steady.get("display_name")), "Steady Arm")
    assert_eq(String(plated.get("display_name")), "Plated Arm")
    assert_eq(StringName(steady.get("part_slot")), &"left_arm", "steady_arm slot = left_arm")
    assert_eq(StringName(plated.get("part_slot")), &"right_arm", "plated_arm slot = right_arm")

func test_mech_loadout_equip_both_arms() -> void:
    var mech: Node = get_node("/root/MechLoadout")
    mech.equip_part(&"left_arm", &"steady_arm")
    mech.equip_part(&"right_arm", &"plated_arm")
    assert_eq(mech.parts[&"left_arm"], &"steady_arm", "left_arm equipped")
    assert_eq(mech.parts[&"right_arm"], &"plated_arm", "right_arm equipped")
    mech.unequip_part(&"left_arm")
    assert_eq(mech.parts[&"left_arm"], &"", "left_arm unequipped")
    assert_eq(mech.parts[&"right_arm"], &"plated_arm", "right_arm still equipped")

func test_mech_loadout_aggregated_stats_with_arms() -> void:
    # Full set: starter_torso + steady_arm + plated_arm
    # starter_torso: hp=20, attack=5, defense=10
    # steady_arm:   hp=5,  attack=10, defense=0
    # plated_arm:   hp=10, attack=0,  defense=8
    # totals:       hp=35, attack=15, defense=18
    var mech: Node = get_node("/root/MechLoadout")
    mech.equip_part(&"torso", &"starter_torso")
    mech.equip_part(&"left_arm", &"steady_arm")
    mech.equip_part(&"right_arm", &"plated_arm")
    var stats: Dictionary = mech.get_aggregated_stats()
    assert_eq(stats.get("hp_bonus", 0), 35, "hp_bonus = 35 (20+5+10)")
    assert_eq(stats.get("attack_bonus", 0), 15, "attack_bonus = 15 (5+10+0)")
    assert_eq(stats.get("defense_bonus", 0), 18, "defense_bonus = 18 (10+0+8)")

func test_mech_loadout_part_equipped_signal_fires() -> void:
    var mech: Node = get_node("/root/MechLoadout")
    var received: Array = []
    mech.part_equipped.connect(func(slot: StringName, part_id: StringName) -> void:
        received.append([slot, part_id]))
    mech.equip_part(&"left_arm", &"steady_arm")
    assert_eq(received.size(), 1, "part_equipped fired once")
    assert_eq(received[0][0], &"left_arm", "signal slot = left_arm")
    assert_eq(received[0][1], &"steady_arm", "signal part_id = steady_arm")
