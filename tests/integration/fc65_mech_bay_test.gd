extends GutTest

# Integration test: MechBayEvents + MechBayUI (S7-007, fc65)
# Per party-system.md §3.4 + sprint-07-007 plan
# Verifies:
#   - MechBayEvents.set_active_mech switches active mech (validates unlocked)
#   - assign_pilot sets pilot_id on a mech, supports auto-swap
#   - move_weapon swaps weapons between two mechs
#   - Default pilot mapping from DEFAULT_PILOT_MAPPING is applied at registration
#   - get_mech_for_pilot now reads from per-mech state (S7-007)
#   - Save/load roundtrip preserves pilot assignments

const EVENTS_PATH: String = "/root/MechBayEvents"
const ML_PATH: String = "/root/MechLoadout"
const WL_PATH: String = "/root/WeaponLoadout"

func _events() -> Node:
	var e: Node = get_node_or_null(EVENTS_PATH)
	if e == null:
		pending("MechBayEvents autoload missing")
		return null
	return e

func _ml() -> Node:
	return get_node_or_null(ML_PATH)

func test_set_active_mech_succeeds() -> void:
	var events: Node = _events()
	var ml: Node = _ml()
	if events == null or ml == null:
		return
	var err: int = events.set_active_mech(&"frostbite_mech")
	assert_eq(err, OK, "set_active_mech OK")
	assert_eq(String(ml.get_active_mech_id()), "frostbite_mech", "active mech is frostbite_mech")
	# Reset
	events.set_active_mech(&"ranger_mech")

func test_set_active_mech_rejects_locked_cangqiong() -> void:
	var events: Node = _events()
	var ml: Node = _ml()
	if events == null or ml == null:
		return
	# Lock cangqiong for clean baseline
	var cq: Resource = ml.get_mech(&"cangqiong_mech")
	cq.unlocked = false
	var err: int = events.set_active_mech(&"cangqiong_mech")
	assert_eq(err, ERR_UNAVAILABLE, "locked cangqiong rejected with ERR_UNAVAILABLE")
	cq.unlocked = false  # reset

func test_set_active_mech_rejects_unknown() -> void:
	var events: Node = _events()
	if events == null:
		return
	var err: int = events.set_active_mech(&"nonexistent_mech")
	assert_eq(err, ERR_INVALID_PARAMETER, "unknown mech rejected")

func test_assign_pilot_sets_pilot_id() -> void:
	var events: Node = _events()
	var ml: Node = _ml()
	if events == null or ml == null:
		return
	var err: int = events.assign_pilot(&"frostbite_mech", &"bomber")
	assert_eq(err, OK, "assign_pilot OK")
	var fb: Resource = ml.get_mech(&"frostbite_mech")
	assert_eq(String(fb.pilot_id), "bomber", "frostbite_mech pilot = bomber")

func test_assign_pilot_swaps_with_previous() -> void:
	# Default: frostbite_mech pilot = frostbite
	# Default: bomber_mech pilot = bomber
	# Assign ranger to frostbite_mech → frostbite goes to ranger_mech (auto-swap)
	var events: Node = _events()
	var ml: Node = _ml()
	if events == null or ml == null:
		return
	var err: int = events.assign_pilot(&"frostbite_mech", &"ranger")
	assert_eq(err, OK, "assign OK")
	var fb: Resource = ml.get_mech(&"frostbite_mech")
	var rm: Resource = ml.get_mech(&"ranger_mech")
	assert_eq(String(fb.pilot_id), "ranger", "frostbite_mech pilot = ranger")
	assert_eq(String(rm.pilot_id), "frostbite", "ranger_mech pilot = frostbite (auto-swap)")
	# Reset
	events.assign_pilot(&"frostbite_mech", &"frostbite")

func test_assign_pilot_rejects_unknown_pilot() -> void:
	var events: Node = _events()
	if events == null:
		return
	var err: int = events.assign_pilot(&"ranger_mech", &"unknown_pilot")
	assert_eq(err, ERR_INVALID_PARAMETER, "unknown pilot rejected")

func test_assign_pilot_emits_signal() -> void:
	var events: Node = _events()
	if events == null:
		return
	var emitted: bool = false
	var handler: Callable = func(_m: StringName, _p: StringName, _prev: StringName) -> void:
		emitted = true
	events.pilot_assigned.connect(handler)
	events.assign_pilot(&"bomber_mech", &"ranger")
	assert_true(emitted, "pilot_assigned signal emitted")
	if events.pilot_assigned.is_connected(handler):
		events.pilot_assigned.disconnect(handler)

func test_move_weapon_swaps_between_mechs() -> void:
	var events: Node = _events()
	var wl: Node = get_node_or_null(WL_PATH)
	if events == null or wl == null:
		return
	# Set known starting state
	var ranger_loadout: Resource = wl.get_mech_loadout(&"ranger_mech")
	var fb_loadout: Resource = wl.get_mech_loadout(&"frostbite_mech")
	ranger_loadout.weapon_slots[0] = &"rifle_x"
	fb_loadout.weapon_slots[1] = &"knife_y"
	# Move
	var err: int = events.move_weapon(&"ranger_mech", 0, &"frostbite_mech", 1)
	assert_eq(err, OK, "move_weapon OK")
	assert_eq(String(ranger_loadout.weapon_slots[0]), "knife_y", "ranger slot 0 = knife_y (from fb)")
	assert_eq(String(fb_loadout.weapon_slots[1]), "rifle_x", "frostbite slot 1 = rifle_x (from ranger)")
	# Reset
	ranger_loadout.weapon_slots[0] = &"blaster_rifle"
	fb_loadout.weapon_slots[1] = &"knife"

func test_move_weapon_rejects_invalid_slot() -> void:
	var events: Node = _events()
	if events == null:
		return
	var err: int = events.move_weapon(&"ranger_mech", 99, &"frostbite_mech", 0)
	assert_eq(err, ERR_INVALID_PARAMETER, "invalid slot rejected")

func test_default_pilot_mapping_applied_at_registration() -> void:
	var ml: Node = _ml()
	if ml == null:
		return
	# ranger_mech default pilot = ranger, etc.
	var rm: Resource = ml.get_mech(&"ranger_mech")
	var fb: Resource = ml.get_mech(&"frostbite_mech")
	var bm: Resource = ml.get_mech(&"bomber_mech")
	assert_eq(String(rm.pilot_id), "ranger", "ranger_mech default pilot = ranger")
	assert_eq(String(fb.pilot_id), "frostbite", "frostbite_mech default pilot = frostbite")
	assert_eq(String(bm.pilot_id), "bomber", "bomber_mech default pilot = bomber")

func test_get_mech_for_pilot_reads_per_mech_state() -> void:
	var ml: Node = _ml()
	var events: Node = _events()
	if ml == null or events == null:
		return
	# Reassign
	events.assign_pilot(&"frostbite_mech", &"ranger")  # auto-swaps
	# Now ranger is on frostbite_mech
	var ranger_mech: Resource = ml.get_mech_for_pilot(&"ranger")
	assert_eq(String(ranger_mech.mech_id), "frostbite_mech", "ranger now on frostbite_mech")
	# And frostbite is on ranger_mech
	var fb_mech: Resource = ml.get_mech_for_pilot(&"frostbite")
	assert_eq(String(fb_mech.mech_id), "ranger_mech", "frostbite now on ranger_mech")
	# Reset
	events.assign_pilot(&"frostbite_mech", &"frostbite")

func test_save_load_preserves_pilot_assignment() -> void:
	var ml: Node = _ml()
	var events: Node = _events()
	if ml == null or events == null:
		return
	# Set known state: bomber_mech pilot = frostbite
	events.assign_pilot(&"bomber_mech", &"frostbite")
	# Snapshot
	var snap: Dictionary = ml.get_state_snapshot()
	var bm_data: Dictionary = snap["mechs"]["bomber_mech"]
	assert_eq(String(bm_data.get("pilot_id", "")), "frostbite", "bomber_mech pilot_id in snap")
	# Mutate
	var bm: Resource = ml.get_mech(&"bomber_mech")
	bm.pilot_id = &""
	# Load
	var result: int = ml.load_snapshot(snap)
	assert_eq(result, OK, "load OK")
	assert_eq(String(bm.pilot_id), "frostbite", "bomber_mech pilot_id restored")
	# Reset
	events.assign_pilot(&"bomber_mech", &"bomber")

func test_mech_bay_opened_closed_signals() -> void:
	var events: Node = _events()
	if events == null:
		return
	var opened: bool = false
	var closed: bool = false
	var open_handler: Callable = func() -> void:
		opened = true
	var close_handler: Callable = func() -> void:
		closed = true
	events.mech_bay_opened.connect(open_handler)
	events.mech_bay_closed.connect(close_handler)
	events.notify_opened()
	events.notify_closed()
	assert_true(opened, "mech_bay_opened signal fired")
	assert_true(closed, "mech_bay_closed signal fired")
	if events.mech_bay_opened.is_connected(open_handler):
		events.mech_bay_opened.disconnect(open_handler)
	if events.mech_bay_closed.is_connected(close_handler):
		events.mech_bay_closed.disconnect(close_handler)