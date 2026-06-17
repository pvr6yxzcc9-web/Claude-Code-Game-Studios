extends GutTest

# Side quest integration test (Sprint 13, fc78) — exercises the 12-quest system.
# Per design/gdd/side-quest-system.md + tests/integration/fc72_bounty_racing_test.gd pattern.
#
# 18 tests covering: schema, state machine, truth integration, rewards,
# prerequisites, save/load, NPC dialogue resolution, hidden quest unlock.

const QM_PATH: String = "/root/QuestManager"
const MS_PATH: String = "/root/MetaState"
const DM_PATH: String = "/root/DialogueManager"
const CM_PATH: String = "/root/ClinicManager"
const EC_PATH: String = "/root/EndingController"
const REG_PATH: String = "/root/ResourceRegistry"

func _qm() -> Node: return get_node_or_null(QM_PATH)
func _ms() -> Node: return get_node_or_null(MS_PATH)
func _dm() -> Node: return get_node_or_null(DM_PATH)
func _cm() -> Node: return get_node_or_null(CM_PATH)
func _ec() -> Node: return get_node_or_null(EC_PATH)
func _reg() -> Node: return get_node_or_null(REG_PATH)

# === Schema & registration ===

func test_quest_data_resource_loads() -> void:
	var reg: Node = _reg()
	if reg == null:
		pending("ResourceRegistry missing")
		return
	var qm: Node = _qm()
	for qid in qm.ALL_QUESTS:
		var data: Resource = reg.get_resource(qid)
		assert_not_null(data, "quest %s loaded" % String(qid))

func test_quest_data_schema_valid() -> void:
	var qm: Node = _qm()
	if qm == null:
		pending("QuestManager missing")
		return
	for qid in qm.ALL_QUESTS:
		var data: Resource = qm.get_quest_data(qid)
		if data == null:
			continue
		assert_ne(String(data.get("id", "")), "", "%s has id" % String(qid))
		var sat: int = int(data.get("satellite", 0))
		assert_gte(sat, 2, "%s satellite >= 2" % String(qid))
		assert_lte(sat, 5, "%s satellite <= 5" % String(qid))
		assert_ne(String(data.get("dialogue_tree_id", "")), "", "%s has dialogue_tree_id" % String(qid))

func test_quest_manager_registers_all_12() -> void:
	var qm: Node = _qm()
	if qm == null:
		pending("QuestManager missing")
		return
	assert_eq(qm.ALL_QUESTS.size(), 12, "12 quests registered")

func test_quest_manager_satellite_distribution() -> void:
	var qm: Node = _qm()
	if qm == null:
		pending("QuestManager missing")
		return
	var counts: Dictionary = {2: 0, 3: 0, 4: 0, 5: 0}
	for qid in qm.ALL_QUESTS:
		var data: Resource = qm.get_quest_data(qid)
		if data == null:
			continue
		var sat: int = int(data.get("satellite", 0))
		counts[sat] = counts.get(sat, 0) + 1
	assert_eq(int(counts[2]), 3, "3 Sat-2 quests")
	assert_eq(int(counts[3]), 3, "3 Sat-3 quests")
	assert_eq(int(counts[4]), 3, "3 Sat-4 quests")
	assert_eq(int(counts[5]), 3, "3 Sat-5 quests")

# === State machine ===

func test_accept_quest_transitions_to_active() -> void:
	var qm: Node = _qm()
	if qm == null:
		pending("QuestManager missing")
		return
	qm.reset_all_quests()
	var qid: StringName = qm.QUEST_RESCUE_SCAVENGER
	assert_eq(qm.get_quest_state_name(qid), "AVAILABLE", "starts AVAILABLE")
	var err: int = qm.accept_quest(qid)
	assert_eq(err, OK, "accept OK")
	assert_eq(qm.get_quest_state_name(qid), "ACTIVE", "now ACTIVE")

func test_accept_quest_twice_returns_error() -> void:
	var qm: Node = _qm()
	if qm == null:
		pending("QuestManager missing")
		return
	qm.reset_all_quests()
	var qid: StringName = qm.QUEST_RESCUE_SCAVENGER
	qm.accept_quest(qid)
	var err: int = qm.accept_quest(qid)
	assert_eq(err, ERR_ALREADY_IN_USE, "second accept returns ERR_ALREADY_IN_USE")

func test_complete_quest_with_choice_grants_rewards() -> void:
	var qm: Node = _qm()
	var cm: Node = _cm()
	if qm == null or cm == null:
		pending("QuestManager or ClinicManager missing")
		return
	qm.reset_all_quests()
	cm._gold = 0  # reset
	var qid: StringName = qm.QUEST_RESCUE_SCAVENGER
	qm.accept_quest(qid)
	var err: int = qm.complete_quest(qid, 1)  # pragmatic
	assert_eq(err, OK, "complete OK")
	assert_eq(qm.get_quest_state_name(qid), "COMPLETED", "now COMPLETED")
	assert_gt(cm.get_gold(), 0, "gold granted")
	# Reset
	cm._gold = 0

func test_abandon_quest_resets_to_available() -> void:
	var qm: Node = _qm()
	if qm == null:
		pending("QuestManager missing")
		return
	qm.reset_all_quests()
	var qid: StringName = qm.QUEST_RESCUE_SCAVENGER
	qm.accept_quest(qid)
	var err: int = qm.abandon_quest(qid)
	assert_eq(err, OK, "abandon OK")
	assert_eq(qm.get_quest_state_name(qid), "AVAILABLE", "back to AVAILABLE")

func test_fail_quest_keeps_active_for_retry() -> void:
	var qm: Node = _qm()
	if qm == null:
		pending("QuestManager missing")
		return
	qm.reset_all_quests()
	var qid: StringName = qm.QUEST_RESCUE_SCAVENGER
	qm.accept_quest(qid)
	qm.fail_quest(qid)
	assert_eq(qm.get_quest_state_name(qid), "ACTIVE", "still ACTIVE for retry")

# === Truth integration ===

func test_truth_count_modifier_applies() -> void:
	var qm: Node = _qm()
	var ms: Node = _ms()
	if qm == null or ms == null:
		pending("QuestManager or MetaState missing")
		return
	qm.reset_all_quests()
	# Clear the fragment if it exists
	var fragment_id: StringName = StringName("quest_q1_truth_compassionate")
	ms.unlocked[fragment_id] = false
	# Mark some baseline fragments so we can measure delta
	var baseline: int = int(ms.unlocked_count()) if ms.has_method("unlocked_count") else 0
	# Complete q1 with compassionate
	var qid: StringName = qm.QUEST_RESCUE_SCAVENGER
	qm.accept_quest(qid)
	qm.complete_quest(qid, 0)  # compassionate
	# Check fragment unlocked
	var after: int = int(ms.unlocked_count()) if ms.has_method("unlocked_count") else 0
	assert_eq(after - baseline, 1, "compassionate grants +1 truth")
	# Clean up
	ms.unlocked[fragment_id] = false

func test_ruthless_choice_unlocks_mech_part() -> void:
	var qm: Node = _qm()
	if qm == null:
		pending("QuestManager missing")
		return
	qm.reset_all_quests()
	# q3 (drone_ambush) has a mech part on ruthless
	var qid: StringName = qm.QUEST_DRONE_AMBUSH
	qm.accept_quest(qid)
	qm.complete_quest(qid, 2)  # ruthless
	var granted: StringName = qm.get_granted_part(qid)
	assert_ne(String(granted), "", "q3 ruthless grants mech part")
	# Clean up
	# (quest state is COMPLETED; that's fine)

# === Prerequisites ===

func test_prerequisite_chain_blocks_acceptance() -> void:
	var qm: Node = _qm()
	if qm == null:
		pending("QuestManager missing")
		return
	qm.reset_all_quests()
	# q12 requires q11 COMPLETED
	var q12: StringName = qm.QUEST_HIDDEN_POSTGAME
	var err: int = qm.accept_quest(q12)
	assert_eq(err, ERR_PREREQUISITE_NOT_MET, "q12 blocked without q11")
	# Complete q11 first
	qm.accept_quest(qm.QUEST_CANGQIONG_LEGACY)
	qm.complete_quest(qm.QUEST_CANGQIONG_LEGACY, 0)
	# Try q12 again (still hidden + need 35 truths, so this should still fail with different reason)
	var err2: int = qm.accept_quest(q12)
	assert_ne(err2, ERR_PREREQUISITE_NOT_MET, "q12 prerequisite OK after q11")

# === Save/Load ===

func test_save_load_roundtrip_preserves_quest_state() -> void:
	var qm: Node = _qm()
	if qm == null:
		pending("QuestManager missing")
		return
	qm.reset_all_quests()
	qm.accept_quest(qm.QUEST_RESCUE_SCAVENGER)
	qm.accept_quest(qm.QUEST_ICE_HERMIT)
	# Snapshot
	var snap: Dictionary = qm.get_state_snapshot()
	# Mutate
	qm.reset_all_quests()
	# Restore
	qm.load_snapshot(snap)
	assert_eq(qm.get_quest_state_name(qm.QUEST_RESCUE_SCAVENGER), "ACTIVE", "q1 restored")
	assert_eq(qm.get_quest_state_name(qm.QUEST_ICE_HERMIT), "ACTIVE", "q2 restored")
	# Reset
	qm.reset_all_quests()

func test_save_v1_still_loads_after_namespace_addition() -> void:
	# The PRODUCER_NAMESPACES addition in S13-004 is additive.
	# Simulate a v1 save (no quest data) and verify load is a no-op.
	var qm: Node = _qm()
	if qm == null:
		pending("QuestManager missing")
		return
	var v1_snap: Dictionary = {"save_version": 2}  # v2 save without quest data
	var err: int = qm.load_snapshot(v1_snap)
	assert_eq(err, OK, "v1-style save loads without error")
	# Quest states remain at default
	assert_eq(qm.get_quest_state_name(qm.QUEST_RESCUE_SCAVENGER), "AVAILABLE", "default state preserved")

# === NPC dialogue resolution ===

func test_npc_dialogue_replacement_for_active_quest() -> void:
	var qm: Node = _qm()
	if qm == null:
		pending("QuestManager missing")
		return
	qm.reset_all_quests()
	qm.accept_quest(qm.QUEST_HIVE_SURVIVOR)
	# Verify the NPC has the right field set
	var reg: Node = _reg()
	if reg == null:
		pending("ResourceRegistry missing")
		return
	var npc: Resource = reg.get_resource(&"ch3_hive_survivor")
	if npc == null:
		pending("ch3_hive_survivor NPC missing")
		return
	var gives: Array = npc.get("gives_quest_ids", [])
	assert_eq(gives.size(), 1, "NPC gives 1 quest")
	assert_eq(String(gives[0]), "q4_hive_survivor_trust", "gives q4")
	var turnin: StringName = StringName(npc.get("quest_complete_dialogue_id", ""))
	assert_ne(String(turnin), "", "has quest_complete_dialogue_id")

func test_npc_dialogue_thanks_player_on_done() -> void:
	var reg: Node = _reg()
	if reg == null:
		pending("ResourceRegistry missing")
		return
	var npc: Resource = reg.get_resource(&"ch3_hive_survivor")
	if npc == null:
		pending("ch3_hive_survivor NPC missing")
		return
	var done: StringName = StringName(npc.get("quest_done_dialogue_id", ""))
	assert_ne(String(done), "", "has quest_done_dialogue_id")

# === Choice recording ===

func test_quest_dialogue_choice_records_on_completion() -> void:
	var qm: Node = _qm()
	if qm == null:
		pending("QuestManager missing")
		return
	qm.reset_all_quests()
	var qid: StringName = qm.QUEST_ICE_HERMIT
	qm.accept_quest(qid)
	assert_eq(qm.get_quest_choice(qid), -1, "no choice yet")
	qm.complete_quest(qid, 2)  # ruthless
	assert_eq(qm.get_quest_choice(qid), 2, "choice recorded")

# === Hidden quest unlock ===

func test_hidden_quest_q12_locked_until_35_truths() -> void:
	var qm: Node = _qm()
	var ms: Node = _ms()
	var ec: Node = _ec()
	if qm == null or ms == null or ec == null:
		pending("autoloads missing")
		return
	qm.reset_all_quests()
	# q11 must be completed first to satisfy prereq
	qm.accept_quest(qm.QUEST_CANGQIONG_LEGACY)
	qm.complete_quest(qm.QUEST_CANGQIONG_LEGACY, 0)
	# Without 35 truths and ending, q12 should be ERR_UNAVAILABLE
	var err: int = qm.accept_quest(qm.QUEST_HIDDEN_POSTGAME)
	assert_eq(err, ERR_UNAVAILABLE, "q12 locked without 35 truths + ending A/B")

# === S13-013: All 4 quest-giver NPCs exist ===

func test_all_quest_giver_npcs_registered() -> void:
	var reg: Node = _reg()
	if reg == null:
		pending("ResourceRegistry missing")
		return
	# Sat-2 trio (added in S13-013) + Sat-5 postgame courier
	var expected_npcs: Array[StringName] = [
		&"ch2_scavenger_leader",
		&"ch2_ice_hermit",
		&"ch2_drone_operator",
		&"ch5_postgame_courier",
	]
	for npc_id in expected_npcs:
		var npc: Resource = reg.get_resource(npc_id)
		assert_not_null(npc, "NPC %s registered" % String(npc_id))
		# Each must be a quest_giver with a quest in gives_quest_ids
		assert_eq(String(npc.get("role", "")), "quest_giver", "%s is quest_giver" % String(npc_id))
		var gives: Array = npc.get("gives_quest_ids", [])
		assert_gt(gives.size(), 0, "%s gives at least 1 quest" % String(npc_id))
		# Has turn-in + done dialogues
		assert_ne(String(npc.get("quest_complete_dialogue_id", "")), "", "%s has quest_complete_dialogue_id" % String(npc_id))
		assert_ne(String(npc.get("quest_done_dialogue_id", "")), "", "%s has quest_done_dialogue_id" % String(npc_id))

func test_sat2_quest_givers_connected_to_correct_quests() -> void:
	var reg: Node = _reg()
	if reg == null:
		pending("ResourceRegistry missing")
		return
	# ch2_scavenger_leader -> q1
	# ch2_ice_hermit -> q2
	# ch2_drone_operator -> q3
	# ch5_postgame_courier -> q12
	var bindings: Dictionary = {
		&"ch2_scavenger_leader": &"q1_rescue_scavenger_leader",
		&"ch2_ice_hermit": &"q2_ice_hermit_relic",
		&"ch2_drone_operator": &"q3_drone_ambush",
		&"ch5_postgame_courier": &"q12_hidden_postgame",
	}
	for npc_id in bindings:
		var npc: Resource = reg.get_resource(npc_id)
		if npc == null:
			continue
		var gives: Array = npc.get("gives_quest_ids", [])
		assert_eq(String(gives[0]), String(bindings[npc_id]), "%s gives %s" % [String(npc_id), String(bindings[npc_id])])

func test_postgame_courier_default_dialogue_tree_exists() -> void:
	var reg: Node = _reg()
	if reg == null:
		pending("ResourceRegistry missing")
		return
	# The postgame NPC's default dialogue (used when no quest is active) must load
	var dlg: Resource = reg.get_resource(&"dlg_ch5_postgame_courier")
	assert_not_null(dlg, "dlg_ch5_postgame_courier loaded")
	if dlg != null:
		assert_ne(String(dlg.get("start_node_id", "")), "", "has start_node_id")
