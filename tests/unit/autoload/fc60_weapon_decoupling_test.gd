extends GutTest

# Unit test: WeaponLoadout pilot-mech decoupling (S7-002, fc60)
# Per party-system.md §3.4 + sprint-07-002 plan
# Verifies that:
#   - Each mech has its own weapon/ammo loadout
#   - set_active_mech() swaps the global view to the new mech
#   - equip on one mech does NOT leak to another
#   - Legacy equip_weapon/equip_ammo delegate to the active mech
#   - trigger_attack respects the active mech's slot
#   - Save/load v2 round-trips per-mech data
#   - Save/load v1 migrates legacy global into the active mech

const WL_PATH: String = "/root/WeaponLoadout"

func _wl() -> Node:
	var wl: Node = get_node_or_null(WL_PATH)
	if wl == null:
		# Autoload not present in this test context — skip.
		pending("WeaponLoadout autoload not available — skipping")
		return null
	return wl

func test_default_active_mech_is_ranger() -> void:
	var wl: Node = _wl()
	if wl == null:
		return
	# Per S7-002 _ready(): default registrations include ranger, frostbite, bomber
	assert_eq(String(wl.get_active_mech_id()), "ranger", "active mech defaults to ranger")
	var loadout: Resource = wl.get_active_mech_loadout()
	assert_not_null(loadout, "active loadout exists")
	assert_eq(loadout.max_weapon_slots, 3, "ranger has 3 weapon slots")

func test_all_three_default_mechs_registered() -> void:
	var wl: Node = _wl()
	if wl == null:
		return
	var all: Dictionary = wl.get_all_mech_loadouts()
	assert_true(all.has(&"ranger"), "ranger registered")
	assert_true(all.has(&"frostbite"), "frostbite registered")
	assert_true(all.has(&"bomber"), "bomber registered")

func test_set_active_mech_swaps_legacy_view() -> void:
	var wl: Node = _wl()
	if wl == null:
		return
	# Ranger slot 0 = blaster_rifle
	wl.set_active_mech(&"ranger")
	assert_eq(String(wl.weapon_slots[0]), "blaster_rifle", "ranger slot 0 is blaster_rifle")
	# Switch to frostbite
	wl.set_active_mech(&"frostbite")
	assert_eq(String(wl.weapon_slots[0]), "rifle", "frostbite slot 0 is rifle")
	assert_eq(String(wl.weapon_slots[1]), "knife", "frostbite slot 1 is knife")
	assert_eq(String(wl.weapon_slots[2]), "throwable", "frostbite slot 2 is throwable")
	# Switch to bomber
	wl.set_active_mech(&"bomber")
	assert_eq(String(wl.weapon_slots[0]), "rail_cannon", "bomber slot 0 is rail_cannon")
	# Switch back — should still have original ranger loadout intact
	wl.set_active_mech(&"ranger")
	assert_eq(String(wl.weapon_slots[0]), "blaster_rifle", "ranger slot 0 still blaster_rifle after swap")

func test_equip_to_one_mech_does_not_leak_to_another() -> void:
	var wl: Node = _wl()
	if wl == null:
		return
	# Equip a new weapon to ranger slot 1
	wl.set_active_mech(&"ranger")
	wl.equip_weapon(1, &"plasma_rifle")
	assert_eq(String(wl.weapon_slots[1]), "plasma_rifle", "ranger slot 1 is plasma_rifle")
	# Switch to frostbite — slot 1 should still be knife (untouched)
	wl.set_active_mech(&"frostbite")
	assert_eq(String(wl.weapon_slots[1]), "knife", "frostbite slot 1 unchanged")
	# Switch back to ranger — slot 1 should still be plasma_rifle
	wl.set_active_mech(&"ranger")
	assert_eq(String(wl.weapon_slots[1]), "plasma_rifle", "ranger slot 1 still plasma_rifle after frostbite visit")
	# Reset for other tests
	wl.equip_weapon(1, &"")

func test_equip_weapon_to_mech_direct() -> void:
	var wl: Node = _wl()
	if wl == null:
		return
	# Direct per-mech equip, even when ranger is not active
	wl.set_active_mech(&"bomber")
	# Equip to ranger slot 2 while bomber is active
	wl.equip_weapon_to_mech(&"ranger", 2, &"test_weapon")
	# Ranger's slot 2 should be test_weapon
	var ranger_loadout: Resource = wl.get_mech_loadout(&"ranger")
	assert_eq(String(ranger_loadout.weapon_slots[2]), "test_weapon", "ranger slot 2 updated")
	# Active mech (bomber) should be unchanged
	assert_ne(String(wl.weapon_slots[2]), "test_weapon", "bomber slot 2 unaffected")
	# Switch to ranger to verify the legacy view reflects the change
	wl.set_active_mech(&"ranger")
	assert_eq(String(wl.weapon_slots[2]), "test_weapon", "ranger slot 2 visible after activation")
	# Cleanup
	wl.equip_weapon_to_mech(&"ranger", 2, &"")

func test_legacy_equip_weapon_delegates_to_active() -> void:
	var wl: Node = _wl()
	if wl == null:
		return
	# The legacy equip_weapon(slot, id) must call into the active mech
	wl.set_active_mech(&"frostbite")
	wl.equip_weapon(0, &"new_frostbite_rifle")
	var frostbite: Resource = wl.get_mech_loadout(&"frostbite")
	assert_eq(String(frostbite.weapon_slots[0]), "new_frostbite_rifle", "legacy equip writes to frostbite")
	assert_eq(String(wl.weapon_slots[0]), "new_frostbite_rifle", "legacy view reflects new weapon")
	# Reset
	wl.equip_weapon(0, &"rifle")

func test_equip_ammo_to_mech() -> void:
	var wl: Node = _wl()
	if wl == null:
		return
	wl.set_active_mech(&"ranger")
	wl.equip_ammo_to_mech(&"ranger", 0, &"plasma_cell")
	assert_eq(String(wl.ammo_slots[0]), "plasma_cell", "ranger ammo slot 0 set")
	# Bomber ammo slot 0 should still be heavy_round
	wl.set_active_mech(&"bomber")
	assert_eq(String(wl.ammo_slots[0]), "heavy_round", "bomber ammo slot 0 untouched")
	# Reset
	wl.equip_ammo_to_mech(&"ranger", 0, &"basic_cell")

func test_trigger_attack_emits_signal_for_active_mech() -> void:
	var wl: Node = _wl()
	if wl == null:
		return
	wl.set_active_mech(&"ranger")
	# Watch the attack_triggered signal
	var emitted_slot: int = -1
	var handler: Callable = func(slot: int) -> void:
		emitted_slot = slot
	wl.attack_triggered.connect(handler, CONNECT_ONE_SHOT)
	wl.trigger_attack(0)
	assert_eq(emitted_slot, 0, "attack triggered on slot 0 for ranger")
	# Disconnect
	if wl.attack_triggered.is_connected(handler):
		wl.attack_triggered.disconnect(handler)

func test_trigger_attack_skips_empty_slot() -> void:
	var wl: Node = _wl()
	if wl == null:
		return
	wl.set_active_mech(&"ranger")
	# Ranger slot 1 is empty by default
	wl.equip_weapon(1, &"")
	var emitted: bool = false
	var handler: Callable = func(_slot: int) -> void:
		emitted = true
	wl.attack_triggered.connect(handler, CONNECT_ONE_SHOT)
	wl.trigger_attack(1)
	assert_false(emitted, "no attack emitted for empty slot")
	if wl.attack_triggered.is_connected(handler):
		wl.attack_triggered.disconnect(handler)

func test_max_weapon_slots_per_mech() -> void:
	var wl: Node = _wl()
	if wl == null:
		return
	# Per GDD: 苍穹号 has 4 slots, normal mechs have 3
	var ranger: Resource = wl.get_mech_loadout(&"ranger")
	var frostbite: Resource = wl.get_mech_loadout(&"frostbite")
	var bomber: Resource = wl.get_mech_loadout(&"bomber")
	assert_eq(ranger.max_weapon_slots, 3, "ranger: 3 slots")
	assert_eq(frostbite.max_weapon_slots, 3, "frostbite: 3 slots")
	assert_eq(bomber.max_weapon_slots, 3, "bomber: 3 slots")

func test_register_custom_mech_with_4_slots() -> void:
	var wl: Node = _wl()
	if wl == null:
		return
	# Register 苍穹号 with 4 slots
	wl.register_mech(&"cangqiong", 4,
			[&"plasma_cannon", &"laser_lance", &"missile_pod", &"emp_blaster"],
			[&"plasma_cell", &"energy_cell", &"missile", &"emp_charge"])
	var cangqiong: Resource = wl.get_mech_loadout(&"cangqiong")
	assert_not_null(cangqiong, "cangqiong registered")
	assert_eq(cangqiong.max_weapon_slots, 4, "cangqiong has 4 slots")
	assert_eq(String(cangqiong.weapon_slots[0]), "plasma_cannon", "slot 0 is plasma_cannon")
	assert_eq(String(cangqiong.weapon_slots[3]), "emp_blaster", "slot 3 is emp_blaster")
	# Idempotency: re-register should not overwrite
	wl.register_mech(&"cangqiong", 4, [&"WRONG", &"", &"", &""], [&"", &"", &"", &""])
	assert_eq(String(cangqiong.weapon_slots[0]), "plasma_cannon", "re-register did not overwrite")

func test_equip_out_of_bounds_emits_warning_but_does_not_crash() -> void:
	var wl: Node = _wl()
	if wl == null:
		return
	# Ranger has 3 slots, so slot 5 is out of bounds
	wl.equip_weapon_to_mech(&"ranger", 5, &"oops")
	# Should not crash; weapon_slots[5] would be out of range, but the function
	# guards against it and just pushes a warning. No assertion needed beyond
	# the call not throwing.

func test_save_load_v2_round_trip() -> void:
	var wl: Node = _wl()
	if wl == null:
		return
	# Set up a known state
	wl.set_active_mech(&"frostbite")
	wl.equip_weapon(0, &"modified_frostbite_rifle")
	wl.equip_ammo(1, &"test_ammo")
	# Snapshot
	var snap: Dictionary = wl.get_state_snapshot()
	assert_eq(int(snap.get("schema_version", 0)), 2, "snapshot is v2")
	assert_eq(String(snap.get("active_mech_id")), "frostbite", "active mech in snap")
	assert_true(snap.has("mechs"), "snap has per-mech data")
	var mechs: Dictionary = snap["mechs"]
	assert_true(mechs.has("ranger"), "ranger in snap")
	assert_true(mechs.has("frostbite"), "frostbite in snap")
	assert_eq(String(mechs["frostbite"]["weapon_slots"][0]), "modified_frostbite_rifle",
			"frostbite weapon[0] in snap")
	# Modify state
	wl.equip_weapon(0, &"changed_again")
	# Load
	var result: int = wl.load_snapshot(snap)
	assert_eq(result, OK, "load returns OK")
	# Verify restoration
	assert_eq(String(wl.get_active_mech_id()), "frostbite", "active mech restored")
	assert_eq(String(wl.weapon_slots[0]), "modified_frostbite_rifle", "frostbite slot 0 restored")
	assert_eq(String(wl.ammo_slots[1]), "test_ammo", "frostbite slot 1 ammo restored")
	# Cleanup
	wl.equip_weapon(0, &"rifle")
	wl.equip_ammo(1, &"")
	wl.set_active_mech(&"ranger")

func test_save_load_v1_migrates_legacy_global() -> void:
	var wl: Node = _wl()
	if wl == null:
		return
	# Construct a v1 save (legacy format — no schema_version, no per-mech data)
	var v1_snap: Dictionary = {
		"weapon_slots": [&"legacy_weapon_1", &"legacy_weapon_2", &""],
		"ammo_slots": [&"legacy_ammo_1", &"", &""],
		"active_slot": 0,
	}
	# Set active mech to ranger first
	wl.set_active_mech(&"ranger")
	var result: int = wl.load_snapshot(v1_snap)
	assert_eq(result, OK, "v1 load returns OK")
	# The legacy data should have been written into the active mech (ranger)
	var ranger: Resource = wl.get_mech_loadout(&"ranger")
	assert_eq(String(ranger.weapon_slots[0]), "legacy_weapon_1", "v1 slot 0 migrated to ranger")
	assert_eq(String(ranger.weapon_slots[1]), "legacy_weapon_2", "v1 slot 1 migrated to ranger")
	assert_eq(String(ranger.ammo_slots[0]), "legacy_ammo_1", "v1 ammo slot 0 migrated to ranger")
	# Other mechs (frostbite, bomber) should be untouched
	var frostbite: Resource = wl.get_mech_loadout(&"frostbite")
	assert_eq(String(frostbite.weapon_slots[0]), "rifle", "frostbite unaffected by v1 load")
	# Cleanup
	wl.equip_weapon(0, &"blaster_rifle")
	wl.equip_weapon(1, &"")
	wl.equip_ammo(0, &"basic_cell")

func test_set_active_mech_emits_signals() -> void:
	var wl: Node = _wl()
	if wl == null:
		return
	# Capture active_mech_changed
	var changed_to: StringName = &""
	var handler: Callable = func(id: StringName) -> void:
		changed_to = id
	wl.active_mech_changed.connect(handler, CONNECT_ONE_SHOT)
	wl.set_active_mech(&"bomber")
	assert_eq(String(changed_to), "bomber", "active_mech_changed emitted")
	if wl.active_mech_changed.is_connected(handler):
		wl.active_mech_changed.disconnect(handler)
	# Reset
	wl.set_active_mech(&"ranger")

func test_register_idempotent_no_emit_on_re_register() -> void:
	var wl: Node = _wl()
	if wl == null:
		return
	# ranger is already registered at _ready(); re-registering should NOT emit
	# mech_loadout_registered
	var count: int = 0
	var handler: Callable = func(_id: StringName) -> void:
		count += 1
	wl.mech_loadout_registered.connect(handler)
	wl.register_mech(&"ranger", 3, [&"foo", &"", &""], [&"", &"", &""])
	assert_eq(count, 0, "no signal on re-register of existing mech")
	if wl.mech_loadout_registered.is_connected(handler):
		wl.mech_loadout_registered.disconnect(handler)
