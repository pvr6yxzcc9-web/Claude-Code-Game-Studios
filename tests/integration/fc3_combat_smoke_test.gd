extends GutTest

# FC-3 Smoke Test — Pre-Production PR-2 (input wiring + combat stub)
# Validates: WeaponLoadout 1/2/3 attack trigger, Inventory persistence,
# BattleScene state machine integration, save/load with new autoloads.

func before_each() -> void:
	# Reset Inventory between tests to avoid cross-test state leakage
	var inv: Node = get_node_or_null("/root/Inventory")
	if inv != null:
		inv.reset()

func test_weapon_loadout_default_has_blaster_rifle() -> void:
	var loadout: Node = get_node("/root/WeaponLoadout")
	assert_eq(loadout.weapon_slots[0], &"blaster_rifle", "default slot 0 = blaster_rifle")
	assert_eq(loadout.active_slot, 0, "default active slot is 0")

func test_weapon_loadout_equip_swap() -> void:
	var loadout: Node = get_node("/root/WeaponLoadout")
	loadout.equip_weapon(1, &"test_weapon")
	assert_eq(loadout.weapon_slots[1], &"test_weapon", "slot 1 equipped")
	loadout.equip_weapon(1, &"")
	assert_eq(loadout.weapon_slots[1], &"", "slot 1 cleared")

func test_weapon_loadout_trigger_attack_emits_signal() -> void:
	var loadout: Node = get_node("/root/WeaponLoadout")
	# Equip slots 0 and 2 first (default only has slot 0)
	loadout.equip_weapon(2, &"test_weapon_2")
	var received: Array = []
	loadout.attack_triggered.connect(func(slot: int) -> void: received.append(slot))
	loadout.trigger_attack(0)
	loadout.trigger_attack(2)
	assert_eq(received, [0, 2], "attack_triggered emitted for slots 0 and 2")

func test_weapon_loadout_trigger_empty_slot_no_emit() -> void:
	var loadout: Node = get_node("/root/WeaponLoadout")
	var received: Array = []
	loadout.attack_triggered.connect(func(slot: int) -> void: received.append(slot))
	loadout.equip_weapon(1, &"")  # empty
	loadout.trigger_attack(1)
	assert_eq(received.size(), 0, "empty slot must not emit attack_triggered")

func test_inventory_add_and_count() -> void:
	var inv: Node = get_node("/root/Inventory")
	inv.add(&"medkit", 3)
	assert_eq(inv.count(&"medkit"), 3, "3 medkits added")
	inv.add(&"medkit", 2)
	assert_eq(inv.count(&"medkit"), 5, "5 medkits total")
	inv.add(&"ammo_pack", 10)
	assert_eq(inv.count(&"ammo_pack"), 10, "10 ammo packs")

func test_inventory_remove_partial() -> void:
	var inv: Node = get_node("/root/Inventory")
	inv.add(&"medkit", 5)
	var ok: bool = inv.remove(&"medkit", 2)
	assert_true(ok, "remove succeeded")
	assert_eq(inv.count(&"medkit"), 3, "3 left after remove 2")

func test_inventory_remove_more_than_have_fails() -> void:
	var inv: Node = get_node("/root/Inventory")
	inv.add(&"medkit", 2)
	var ok: bool = inv.remove(&"medkit", 5)
	assert_false(ok, "remove of more than have fails")
	assert_eq(inv.count(&"medkit"), 2, "still 2 medkits")

func test_inventory_remove_to_zero_erases() -> void:
	var inv: Node = get_node("/root/Inventory")
	inv.add(&"medkit", 1)
	inv.remove(&"medkit", 1)
	assert_eq(inv.count(&"medkit"), 0, "removed last, count is 0")
	assert_false(inv.items.has(&"medkit"), "item entry erased from dict")

func test_save_load_with_inventory() -> void:
	var inv: Node = get_node("/root/Inventory")
	inv.add(&"rare_loot", 7)
	var save: Node = get_node("/root/SaveManager")
	var err: int = save.save_to_slot(1)
	assert_eq(err, OK, "save ok")
	await get_tree().create_timer(0.2).timeout
	inv.add(&"should_be_gone", 99)
	var err2: int = save.load_from_slot(1)
	assert_eq(err2, OK, "load ok")
	assert_eq(inv.count(&"rare_loot"), 7, "rare_loot persisted")
	assert_eq(inv.count(&"should_be_gone"), 0, "post-load state is restored")

func test_state_machine_battle_transition_works() -> void:
	var sm: Node = get_node("/root/GameStateMachine")
	var err: int = sm.transition_to(&"state_battle")
	assert_eq(err, OK, "EXPLORATION -> BATTLE is legal")
	assert_eq(sm.top_of_stack, &"state_battle", "top of stack is now BATTLE")
	var err2: int = sm.transition_to(&"state_exploration")
	assert_eq(err2, OK, "BATTLE -> EXPLORATION is legal")
	assert_eq(sm.top_of_stack, &"state_exploration", "back to exploration")
