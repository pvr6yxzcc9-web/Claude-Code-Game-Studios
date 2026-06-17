extends Node

# QuestManager (Sprint 13) — manages the 12 dialogue-driven side quests.
# Per design/gdd/side-quest-system.md
#
# 12 quests: 3 per satellite × 4 satellites (skipping Sat-1 prologue).
# 3-choice outcome model: compassionate (idx 0, +1 truth) /
#                          pragmatic    (idx 1,  0 truth) /
#                          ruthless     (idx 2, -1 truth).
#
# PARALLEL to BountyManager (Sprint 11). Bounties = boss fights.
# Quests = narrative side content with dialogue, choice, truth impact.
#
# This S13-003 commit ships the state machine + state snapshot/load.
# Reward application is wired in S13-005/006.

signal quest_accepted(quest_id: StringName)
signal quest_completed(quest_id: StringName, choice_idx: int, gold: int, xp: int, part_id: StringName)
signal quest_abandoned(quest_id: StringName)
signal quest_failed(quest_id: StringName)
signal truth_count_changed(delta: int)

# Quest IDs (in order)
const QUEST_RESCUE_SCAVENGER: StringName = &"q1_rescue_scavenger_leader"
const QUEST_ICE_HERMIT: StringName = &"q2_ice_hermit_relic"
const QUEST_DRONE_AMBUSH: StringName = &"q3_drone_ambush"
const QUEST_HIVE_SURVIVOR: StringName = &"q4_hive_survivor_trust"
const QUEST_FUNGAL_CURE: StringName = &"q5_fungal_infection_cure"
const QUEST_QUEEN_AMBROSIA: StringName = &"q6_queen_ambrosia"
const QUEST_VETERAN_ARSENAL: StringName = &"q7_veteran_arsenal"
const QUEST_AI_FRAGMENT: StringName = &"q8_ai_fragment_merge"
const QUEST_WAR_ORPHAN: StringName = &"q9_war_orphan_home"
const QUEST_CREATOR_PREMONITION: StringName = &"q10_creator_premonition"
const QUEST_CANGQIONG_LEGACY: StringName = &"q11_cangqiong_legacy"
const QUEST_HIDDEN_POSTGAME: StringName = &"q12_hidden_postgame"

# All quests (in order)
const ALL_QUESTS: Array[StringName] = [
	QUEST_RESCUE_SCAVENGER,
	QUEST_ICE_HERMIT,
	QUEST_DRONE_AMBUSH,
	QUEST_HIVE_SURVIVOR,
	QUEST_FUNGAL_CURE,
	QUEST_QUEEN_AMBROSIA,
	QUEST_VETERAN_ARSENAL,
	QUEST_AI_FRAGMENT,
	QUEST_WAR_ORPHAN,
	QUEST_CREATOR_PREMONITION,
	QUEST_CANGQIONG_LEGACY,
	QUEST_HIDDEN_POSTGAME,
]

# Quest state enum (per GDD §3.1)
enum QuestState {
	AVAILABLE,  # not yet accepted, can be offered by NPC
	ACTIVE,     # accepted, in progress, awaiting turn-in
	COMPLETED,  # turned in, terminal state (unless is_repeatable)
	FAILED,     # failed (still retryable)
	ABANDONED,  # dropped (resets to AVAILABLE on next visit)
	LOCKED,     # hidden + conditions not met (doesn't appear in board)
}

# Per-quest state: { id: {"status": QuestState, "attempt_count": int, "last_choice": int} }
var _quest_state: Dictionary = {}

# Per-quest choice record: { id: int (0/1/2) } — last choice made (drives NPC dialogue swaps)
var _quest_choice: Dictionary = {}

# Feature flag — flipped true in S13-005 when dialogue-reward wiring lands.
# Until then, accept_quest is a no-op so the rest of the game isn't affected.
@export var _quests_enabled: bool = true  # S13-005: enabled after dialogue-reward wiring

func _ready() -> void:
	# Register all 12 quests (no-op for the data; .tres is the source of truth)
	_init_default_state()
	print("[QuestManager] ready — 12 side quests registered (enabled=%s)" % _quests_enabled)

func _init_default_state() -> void:
	for qid in ALL_QUESTS:
		_quest_state[qid] = {
			"status": QuestState.AVAILABLE,
			"attempt_count": 0,
			"last_choice": -1,
		}
		_quest_choice[qid] = -1

# === API ===

# Get quest state
func get_quest_state(quest_id: StringName) -> int:
	if not _quest_state.has(quest_id):
		return QuestState.LOCKED
	return int(_quest_state[quest_id].get("status", QuestState.AVAILABLE))

func get_quest_state_name(quest_id: StringName) -> String:
	return QuestState.keys()[get_quest_state(quest_id)]

# Get quest data (looks up .tres via ResourceRegistry)
func get_quest_data(quest_id: StringName) -> Resource:
	var reg: Node = get_node_or_null("/root/ResourceRegistry")
	if reg == null:
		return null
	return reg.get_resource(quest_id)

# Get the last choice made on a quest (-1 = not yet chosen)
func get_quest_choice(quest_id: StringName) -> int:
	return int(_quest_choice.get(quest_id, -1))

# Get all quests
func get_all_quests() -> Array[StringName]:
	return ALL_QUESTS.duplicate()

# Get quests for a specific satellite
func get_quests_for_satellite(satellite: int) -> Array[StringName]:
	var out: Array[StringName] = []
	for qid in ALL_QUESTS:
		var data: Resource = get_quest_data(qid)
		if data != null and int(data.get("satellite", 0)) == satellite:
			out.append(qid)
	return out

# Get active quests (in progress)
func get_active_quests() -> Array[StringName]:
	var out: Array[StringName] = []
	for qid in ALL_QUESTS:
		if get_quest_state(qid) == QuestState.ACTIVE:
			out.append(qid)
	return out

# Get completed quests
func get_completed_quests() -> Array[StringName]:
	var out: Array[StringName] = []
	for qid in ALL_QUESTS:
		if get_quest_state(qid) == QuestState.COMPLETED:
			out.append(qid)
	return out

# Get available quests (offered, not yet accepted)
func get_available_quests() -> Array[StringName]:
	var out: Array[StringName] = []
	for qid in ALL_QUESTS:
		if get_quest_state(qid) == QuestState.AVAILABLE:
			# Skip hidden quests whose conditions are not met
			var data: Resource = get_quest_data(qid)
			if data != null and bool(data.get("is_hidden", false)):
				if not _hidden_quest_unlocked(data):
					continue
			out.append(qid)
	return out

# Accept a quest
func accept_quest(quest_id: StringName) -> Error:
	if not _quests_enabled:
		return ERR_UNAVAILABLE
	if not _quest_state.has(quest_id):
		return ERR_INVALID_PARAMETER
	var status: int = get_quest_state(quest_id)
	if status == QuestState.ACTIVE or status == QuestState.COMPLETED:
		return ERR_ALREADY_IN_USE
	# Check prerequisites
	var data: Resource = get_quest_data(quest_id)
	if data != null:
		var prereqs: Array = data.get("prerequisite_quest_ids", [])
		for prereq_id in prereqs:
			if get_quest_state(prereq_id) != QuestState.COMPLETED:
				return ERR_PREREQUISITE_NOT_MET
		# Check hidden quest conditions
		if bool(data.get("is_hidden", false)):
			if not _hidden_quest_unlocked(data):
				return ERR_UNAVAILABLE
	_quest_state[quest_id]["status"] = QuestState.ACTIVE
	quest_accepted.emit(quest_id)
	return OK

# Abandon a quest (only non-plot quests can be abandoned)
func abandon_quest(quest_id: StringName) -> Error:
	if not _quests_state_valid(quest_id):
		return ERR_INVALID_PARAMETER
	var data: Resource = get_quest_data(quest_id)
	if data != null and bool(data.get("is_plot_required", false)):
		return ERR_UNAVAILABLE  # Plot-required quests can't be abandoned
	if get_quest_state(quest_id) != QuestState.ACTIVE:
		return ERR_INVALID_STATE
	_quest_state[quest_id]["status"] = QuestState.AVAILABLE
	quest_abandoned.emit(quest_id)
	return OK

# Complete a quest with a choice (0=compassionate, 1=pragmatic, 2=ruthless)
# Called from DialogueManager.dialogue_ended signal (S13-005).
# Re-checks state to handle "abandoned mid-dialogue" edge case.
func complete_quest(quest_id: StringName, choice_idx: int) -> Error:
	if not _quest_state.has(quest_id):
		return ERR_INVALID_PARAMETER
	if choice_idx < 0 or choice_idx > 2:
		return ERR_INVALID_PARAMETER
	# Re-check state: if not ACTIVE anymore (e.g., abandoned), reject
	if get_quest_state(quest_id) != QuestState.ACTIVE:
		return ERR_INVALID_STATE
	var data: Resource = get_quest_data(quest_id)
	if data == null:
		return ERR_DOES_NOT_EXIST
	# Record the choice
	_quest_state[quest_id]["last_choice"] = choice_idx
	_quest_choice[quest_id] = choice_idx
	# Mark completed
	_quest_state[quest_id]["status"] = QuestState.COMPLETED
	# Apply rewards (delegated to _apply_rewards — implemented in S13-005/006)
	var gold: int = int(data.get("gold_reward", [0, 0, 0])[choice_idx])
	var xp: int = int(data.get("xp_reward", [0, 0, 0])[choice_idx])
	var part_id: StringName = StringName(data.get("mech_part_reward", ["", "", ""])[choice_idx])
	_apply_rewards(quest_id, data, choice_idx, gold, xp, part_id)
	quest_completed.emit(quest_id, choice_idx, gold, xp, part_id)
	# S14-003: quest complete SFX
	var sfx: Node = get_node_or_null("/root/SFXPlayer")
	if sfx != null and sfx.has_method("play_quest_complete"):
		sfx.play_quest_complete()
	return OK

# Fail a quest (player died or quest-specific fail condition)
func fail_quest(quest_id: StringName) -> Error:
	if not _quest_state.has(quest_id):
		return ERR_INVALID_PARAMETER
	_quest_state[quest_id]["attempt_count"] = int(_quest_state[quest_id].get("attempt_count", 0)) + 1
	# Keep ACTIVE so player can retry (per BountyManager convention)
	quest_failed.emit(quest_id)
	return OK

# === Internal ===

func _quest_state_valid(quest_id: StringName) -> bool:
	return _quest_state.has(quest_id)

# Apply rewards — S13-005 wires MetaState.mark_unlocked for truth fragments.
# S13-006 wires ClinicManager.add_gold (gold), XP via Inventory if present,
# and records mech_part_reward as a granted part (signal-based so future
# Inventory/MechLoadout systems can consume it).
func _apply_rewards(quest_id: StringName, data: Resource, choice_idx: int, gold: int, xp: int, part_id: StringName) -> void:
	# Truth integration: unlock fragment id matching the choice
	# Pattern: quest_q{N}_truth_{compassionate|pragmatic|ruthless}
	# Modifiers: +1 / 0 / -1 (pragmatic = 0, no fragment unlock)
	var truth_mods: Array = data.get("truth_count_modifier", [1, 0, -1])
	var truth_delta: int = int(truth_mods[choice_idx])
	if truth_delta != 0:
		var choice_name: String = ["compassionate", "pragmatic", "ruthless"][choice_idx]
		var fragment_id: StringName = StringName("quest_%s_truth_%s" % [String(quest_id), choice_name])
		var ms: Node = get_node_or_null("/root/MetaState")
		if ms != null and ms.has_method("mark_unlocked"):
			ms.mark_unlocked(fragment_id)
			truth_count_changed.emit(truth_delta)
	# Gold reward — uses existing ClinicManager.add_gold (Sprint 7)
	if gold > 0:
		var cm: Node = get_node_or_null("/root/ClinicManager")
		if cm != null and cm.has_method("add_gold"):
			cm.add_gold(gold)
	# XP reward — try Inventory.grant_xp if it exists; otherwise log it.
	# (S13-006 ships the wiring; the Inventory.grant_xp call site is in S13-009+.)
	if xp > 0:
		var inv: Node = get_node_or_null("/root/Inventory")
		if inv != null and inv.has_method("grant_xp"):
			inv.grant_xp(xp)
		# else: silently dropped — Inventory.grant_xp added in later sprint
	# Mech part reward — signal-based so future Inventory/MechLoadout can consume.
	# For now, just track via _granted_parts dict so tests can verify.
	if part_id != &"":
		_granted_parts[quest_id] = part_id

# Track granted parts for testing/inspection
var _granted_parts: Dictionary = {}

# Test/inspection API
func get_granted_part(quest_id: StringName) -> StringName:
	return StringName(_granted_parts.get(quest_id, ""))

# Hidden quest unlock conditions
func _hidden_quest_unlocked(data: Resource) -> bool:
	# Hidden quests require ≥35 truths + ending A or B
	var ms: Node = get_node_or_null("/root/MetaState")
	if ms == null:
		return false
	var ec: Node = get_node_or_null("/root/EndingController")
	if ec == null:
		return false
	var truth_count: int = int(ms.unlocked_count()) if ms.has_method("unlocked_count") else 0
	var reached: String = String(ec.get_reached_ending()) if ec.has_method("get_reached_ending") else ""
	return truth_count >= 35 and (reached == "A" or reached == "B")

# === Save/Load ===

func get_state_snapshot() -> Dictionary:
	return {
		"quest_state": _quest_state.duplicate(true),
		"quest_choice": _quest_choice.duplicate(true),
	}

func load_snapshot(snap: Dictionary) -> Error:
	if snap.has("quest_state"):
		var qs: Dictionary = snap["quest_state"]
		for qid in qs:
			if _quest_state.has(qid):
				_quest_state[qid] = qs[qid]
	if snap.has("quest_choice"):
		var qc: Dictionary = snap["quest_choice"]
		for qid in qc:
			_quest_choice[qid] = qc[qid]
	return OK

# Reset all quests (new game)
func reset_all_quests() -> void:
	_init_default_state()
