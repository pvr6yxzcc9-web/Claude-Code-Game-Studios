extends GutTest

# Unit test: MechLoadout 4-mech roster + swap (S7-003, fc61)
# Per party-system.md §3.4 + sprint-07-003 plan
# Verifies:
#   - 4 mechs are registered in the roster (ranger / frostbite / bomber / cangqiong)
#   - 3 are unlocked by default; cangqiong is locked until unlock_cangqiong()
#   - set_active_mech() switches the active mech
#   - Each mech has 4 parts HP (head / chest / arms / legs)
#   - Damage to parts HP reduces HP, with the part reaching 0 triggers a flag
#   - All 4 parts at 0 = mech destroyed
#   - Save/load round-trip preserves all 4 mechs' state
#   - Default pilot → mech mapping is correct

const ML_PATH: String = "/root/MechLoadout"

func _ml() -> Node:
	var ml: Node = get_node_or_null(ML_PATH)
	if ml == null:
		pending("MechLoadout autoload not available — skipping")
		return null
	return ml

func test_four_mechs_in_roster() -> void:
	var ml: Node = _ml()
	if ml == null:
		return
	var all: Dictionary = ml.get_all_mechs()
	assert_eq(all.size(), 4, "4 mechs registered")
	assert_true(all.has(&"ranger_mech"), "ranger_mech registered")
	assert_true(all.has(&"frostbite_mech"), "frostbite_mech registered")
	assert_true(all.has(&"bomber_mech"), "bomber_mech registered")
	assert_true(all.has(&"cangqiong_mech"), "cangqiong_mech registered")

func test_three_default_mechs_unlocked_cangqiong_locked() -> void:
	var ml: Node = _ml()
	if ml == null:
		return
	assert_true(ml.is_unlocked(&"ranger_mech"), "ranger_mech unlocked")
	assert_true(ml.is_unlocked(&"frostbite_mech"), "frostbite_mech unlocked")
	assert_true(ml.is_unlocked(&"bomber_mech"), "bomber_mech unlocked")
	assert_false(ml.is_unlocked(&"cangqiong_mech"), "cangqiong_mech locked until Ch13")

func test_unlock_cangqiong() -> void:
	var ml: Node = _ml()
	if ml == null:
		return
	# Lock cangqiong first if it was already unlocked by a prior test
	if ml.is_unlocked(&"cangqiong_mech"):
		# Reset
		var cq: Resource = ml.get_mech(&"cangqiong_mech")
		cq.unlocked = false
	ml.unlock_cangqiong()
	assert_true(ml.is_unlocked(&"cangqiong_mech"), "cangqiong_mech unlocked after unlock_cangqiong()")
	# Idempotency: second call should not crash or re-emit
	ml.unlock_cangqiong()
	assert_true(ml.is_unlocked(&"cangqiong_mech"), "still unlocked after second call")
	# Reset for other tests
	var cq2: Resource = ml.get_mech(&"cangqiong_mech")
	cq2.unlocked = false

func test_set_active_mech_changes_active() -> void:
	var ml: Node = _ml()
	if ml == null:
		return
	# Reset to ranger_mech
	ml.set_active_mech(&"ranger_mech")
	assert_eq(String(ml.get_active_mech_id()), "ranger_mech", "default active is ranger_mech")
	ml.set_active_mech(&"frostbite_mech")
	assert_eq(String(ml.get_active_mech_id()), "frostbite_mech", "active is frostbite_mech")
	ml.set_active_mech(&"bomber_mech")
	assert_eq(String(ml.get_active_mech_id()), "bomber_mech", "active is bomber_mech")
	# Reset
	ml.set_active_mech(&"ranger_mech")

func test_set_active_mech_refuses_unregistered() -> void:
	var ml: Node = _ml()
	if ml == null:
		return
	ml.set_active_mech(&"ranger_mech")
	ml.set_active_mech(&"nonexistent_mech")
	# Should not change active
	assert_eq(String(ml.get_active_mech_id()), "ranger_mech", "active unchanged for unknown mech")

func test_set_active_mech_refuses_locked_cangqiong() -> void:
	var ml: Node = _ml()
	if ml == null:
		return
	var cq: Resource = ml.get_mech(&"cangqiong_mech")
	if cq != null:
		cq.unlocked = false  # ensure locked
	ml.set_active_mech(&"ranger_mech")
	ml.set_active_mech(&"cangqiong_mech")
	# Should refuse and stay on ranger_mech
	assert_eq(String(ml.get_active_mech_id()), "ranger_mech", "locked cangqiong refused")
	# Reset
	if cq != null:
		cq.unlocked = false

func test_each_mech_has_four_parts_hp() -> void:
	var ml: Node = _ml()
	if ml == null:
		return
	var ids: Array[StringName] = [&"ranger_mech", &"frostbite_mech", &"bomber_mech"]
	for id in ids:
		var mech: Resource = ml.get_mech(id)
		assert_not_null(mech, "mech %s exists" % id)
		assert_eq(mech.head_hp, mech.max_head_hp, "%s head_hp full" % id)
		assert_eq(mech.chest_hp, mech.max_chest_hp, "%s chest_hp full" % id)
		assert_eq(mech.arms_hp, mech.max_arms_hp, "%s arms_hp full" % id)
		assert_eq(mech.legs_hp, mech.max_legs_hp, "%s legs_hp full" % id)

func test_cangqiong_has_4_weapon_slots_and_2_module_slots() -> void:
	var ml: Node = _ml()
	if ml == null:
		return
	var cq: Resource = ml.get_mech(&"cangqiong_mech")
	assert_eq(cq.max_weapon_slots, 4, "cangqiong has 4 weapon slots")
	assert_eq(cq.module_ids.size(), 2, "cangqiong has 2 module slots")
	# Other mechs have 1 module slot
	for id in [&"ranger_mech", &"frostbite_mech", &"bomber_mech"]:
		var mech: Resource = ml.get_mech(id)
		assert_eq(mech.max_weapon_slots, 3, "%s has 3 weapon slots" % id)
		assert_eq(mech.module_ids.size(), 1, "%s has 1 module slot" % id)

func test_damage_part_reduces_hp() -> void:
	var ml: Node = _ml()
	if ml == null:
		return
	var ranger: Resource = ml.get_mech(&"ranger_mech")
	var starting_head_hp: int = ranger.head_hp
	var destroyed: bool = ml.damage_part(&"ranger_mech", &"head", 30)
	assert_false(destroyed, "head not destroyed at 30 dmg (HP was %d)" % starting_head_hp)
	assert_eq(ranger.head_hp, starting_head_hp - 30, "head HP reduced by 30")
	# Now deal enough to destroy
	destroyed = ml.damage_part(&"ranger_mech", &"head", starting_head_hp)
	assert_true(destroyed, "head destroyed after total %d dmg" % starting_head_hp)
	assert_eq(ranger.head_hp, 0, "head HP clamped to 0")
	# Reset
	ranger.head_hp = ranger.max_head_hp

func test_heal_part_caps_at_max() -> void:
	var ml: Node = _ml()
	if ml == null:
		return
	var ranger: Resource = ml.get_mech(&"ranger_mech")
	ranger.legs_hp = 10  # damaged
	ml.heal_part(&"ranger_mech", &"legs", 30)
	assert_eq(ranger.legs_hp, ranger.max_legs_hp, "legs HP capped at max (was 10, healed 30 → max)")
	# Reset
	ranger.legs_hp = ranger.max_legs_hp

func test_is_mech_destroyed_when_all_parts_zero() -> void:
	var ml: Node = _ml()
	if ml == null:
		return
	var ranger: Resource = ml.get_mech(&"ranger_mech")
	var orig_head: int = ranger.head_hp
	var orig_chest: int = ranger.chest_hp
	var orig_arms: int = ranger.arms_hp
	var orig_legs: int = ranger.legs_hp
	ranger.head_hp = 0
	ranger.chest_hp = 0
	ranger.arms_hp = 0
	ranger.legs_hp = 0
	assert_true(ml.is_mech_destroyed(&"ranger_mech"), "all parts at 0 = destroyed")
	# One part alive = not destroyed
	ranger.legs_hp = 10
	assert_false(ml.is_mech_destroyed(&"ranger_mech"), "any part > 0 = not destroyed")
	# Reset
	ranger.head_hp = orig_head
	ranger.chest_hp = orig_chest
	ranger.arms_hp = orig_arms
	ranger.legs_hp = orig_legs

func test_default_pilot_mapping() -> void:
	var ml: Node = _ml()
	if ml == null:
		return
	var ranger_mech: Resource = ml.get_mech_for_pilot(&"ranger")
	assert_not_null(ranger_mech, "ranger pilot maps to a mech")
	assert_eq(String(ranger_mech.mech_id), "ranger_mech", "ranger → ranger_mech")
	var frostbite_mech: Resource = ml.get_mech_for_pilot(&"frostbite")
	assert_eq(String(frostbite_mech.mech_id), "frostbite_mech", "frostbite → frostbite_mech")
	var bomber_mech: Resource = ml.get_mech_for_pilot(&"bomber")
	assert_eq(String(bomber_mech.mech_id), "bomber_mech", "bomber → bomber_mech")
	# Unknown pilot → null
	var unknown: Resource = ml.get_mech_for_pilot(&"unknown_pilot")
	assert_null(unknown, "unknown pilot → null")

func test_get_unlocked_mechs_excludes_locked() -> void:
	var ml: Node = _ml()
	if ml == null:
		return
	var cq: Resource = ml.get_mech(&"cangqiong_mech")
	if cq != null:
		cq.unlocked = false
	var unlocked: Array = ml.get_unlocked_mechs()
	assert_eq(unlocked.size(), 3, "only 3 unlocked mechs when cangqiong locked")
	for m in unlocked:
		assert_ne(String(m.mech_id), "cangqiong_mech", "cangqiong excluded from unlocked")
	# Unlock and re-check
	if cq != null:
		cq.unlocked = false

func test_save_load_round_trip() -> void:
	var ml: Node = _ml()
	if ml == null:
		return
	# Set up known state
	ml.set_active_mech(&"frostbite_mech")
	var ranger: Resource = ml.get_mech(&"ranger_mech")
	ranger.head_hp = 50
	ranger.arms_hp = 75
	var frostbite: Resource = ml.get_mech(&"frostbite_mech")
	frostbite.legs_hp = 25
	# Snapshot
	var snap: Dictionary = ml.get_state_snapshot()
	assert_eq(int(snap.get("schema_version", 0)), 2, "snapshot is v2")
	assert_eq(String(snap.get("active_mech_id")), "frostbite_mech", "active mech in snap")
	assert_eq(snap["mechs"].size(), 4, "all 4 mechs in snap")
	assert_eq(int(snap["mechs"]["ranger_mech"]["head_hp"]), 50, "ranger head_hp in snap")
	assert_eq(int(snap["mechs"]["frostbite_mech"]["legs_hp"]), 25, "frostbite legs_hp in snap")
	# Mutate
	ranger.head_hp = 100
	# Load
	var result: int = ml.load_snapshot(snap)
	assert_eq(result, OK, "load returns OK")
	assert_eq(String(ml.get_active_mech_id()), "frostbite_mech", "active mech restored")
	assert_eq(int(ranger.head_hp), 50, "ranger head_hp restored")
	assert_eq(int(ranger.arms_hp), 75, "ranger arms_hp restored")
	assert_eq(int(frostbite.legs_hp), 25, "frostbite legs_hp restored")
	# Reset
	ml.set_active_mech(&"ranger_mech")
	ranger.head_hp = ranger.max_head_hp
	ranger.arms_hp = ranger.max_arms_hp
	frostbite.legs_hp = frostbite.max_legs_hp

func test_save_load_v1_legacy_compat() -> void:
	var ml: Node = _ml()
	if ml == null:
		return
	# v1 saves had just { parts: { torso, ... } }
	var v1_snap: Dictionary = {
		"schema_version": 1,
		"parts": {
			"torso": "torso_mk1",
			"left_arm": "arm_mk1",
			"right_arm": "",
			"legs": "legs_mk1",
			"core": "",
		},
	}
	var result: int = ml.load_snapshot(v1_snap)
	assert_eq(result, OK, "v1 load returns OK")
	assert_eq(String(ml.parts[&"torso"]), "torso_mk1", "v1 torso loaded")
	assert_eq(String(ml.parts[&"left_arm"]), "arm_mk1", "v1 left_arm loaded")
	# Reset
	for s in ml.LEGACY_SLOTS:
		ml.parts[s] = &""

func test_cangqiong_unlocked_signal_fires() -> void:
	var ml: Node = _ml()
	if ml == null:
		return
	var cq: Resource = ml.get_mech(&"cangqiong_mech")
	if cq != null:
		cq.unlocked = false
	var emitted: bool = false
	var handler: Callable = func(_id: StringName) -> void:
		emitted = true
	ml.cangqiong_unlocked.connect(handler, CONNECT_ONE_SHOT)
	ml.unlock_cangqiong()
	assert_true(emitted, "cangqiong_unlocked signal emitted")
	if ml.cangqiong_unlocked.is_connected(handler):
		ml.cangqiong_unlocked.disconnect(handler)
	# Reset
	if cq != null:
		cq.unlocked = false

func test_active_mech_changed_signal() -> void:
	var ml: Node = _ml()
	if ml == null:
		return
	var emitted_id: StringName = &""
	var handler: Callable = func(id: StringName) -> void:
		emitted_id = id
	ml.active_mech_changed.connect(handler, CONNECT_ONE_SHOT)
	ml.set_active_mech(&"bomber_mech")
	assert_eq(String(emitted_id), "bomber_mech", "active_mech_changed emitted with new id")
	if ml.active_mech_changed.is_connected(handler):
		ml.active_mech_changed.disconnect(handler)
	# Reset
	ml.set_active_mech(&"ranger_mech")