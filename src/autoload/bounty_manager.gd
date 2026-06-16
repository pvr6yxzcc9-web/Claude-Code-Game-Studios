extends Node

# BountyManager (Sprint 11) — manages the 6 bounties.
# Per production/sprints/sprint-11-bounty-racing.md + design/gdd/bounty-system.md
# 6 bounties: 1 plot (Bounty #2) + 5 optional + 1 post-game (Bounty #6).

signal bounty_accepted(bounty_id: StringName)
signal bounty_completed(bounty_id: StringName, reward_gold: int)
signal bounty_abandoned(bounty_id: StringName)
signal bounty_failed(bounty_id: StringName)

# Bounty IDs
const BOUNTY_HIDDEN_HUNTER: StringName = &"b1_hidden_hunter"
const BOUNTY_TRAITORS_LEGACY: StringName = &"b2_traitors_legacy"  # PLOT — required for Sat-3
const BOUNTY_HIVE_QUEEN: StringName = &"b3_hive_queen"
const BOUNTY_AI_ECHO: StringName = &"b4_ai_echo"
const BOUNTY_CREATOR_ECHO: StringName = &"b5_creator_echo"
const BOUNTY_HIDDEN_POSTGAME: StringName = &"b6_hidden_postgame"

# All bounties (in order)
const ALL_BOUNTIES: Array[StringName] = [
	BOUNTY_HIDDEN_HUNTER,
	BOUNTY_TRAITORS_LEGACY,
	BOUNTY_HIVE_QUEEN,
	BOUNTY_AI_ECHO,
	BOUNTY_CREATOR_ECHO,
	BOUNTY_HIDDEN_POSTGAME,
]

# Bounty definitions: { id: {satellite, target_id, gold_reward, is_plot, special_tool_drop, threat_level, ...} }
var _bounties: Dictionary = {}

# Per-bounty state: { id: {status, attempt_count} }
# Status: AVAILABLE, ACCEPTED, COMPLETED, FAILED, ABANDONED
var _bounty_state: Dictionary = {}

# Per-bounty medal: { id: bool (collected) }
var _medals_collected: Dictionary = {}

func _ready() -> void:
	# Register all 6 bounties
	_register_default_bounties()
	print("[BountyManager] ready — 6 bounties registered")

func _register_default_bounties() -> void:
	# Bounty #1: Hidden Hunter (Sat-1)
	_bounties[BOUNTY_HIDDEN_HUNTER] = {
		"satellite": 1,
		"target_id": &"ch1_hidden_hunter",
		"gold_reward": 800,
		"is_plot": false,
		"special_tool_drop": &"ice_detector",
		"threat_level": 3,
		"recommended_level": 8,
		"title": "隐藏的猎手",
		"description": "A lone hunter stalks Sat-1's scavengers. Track and kill.",
	}
	# Bounty #2: Traitor's Legacy (Sat-2, PLOT)
	_bounties[BOUNTY_TRAITORS_LEGACY] = {
		"satellite": 2,
		"target_id": &"ch2_traitor_boss",
		"gold_reward": 1500,
		"is_plot": true,
		"special_tool_drop": &"hive_scanner",
		"threat_level": 5,
		"recommended_level": 12,
		"title": "叛徒的遗产",
		"description": "The Sat-2 traitor left a stash of weapons. Recover them.",
	}
	# Bounty #3: Hive Queen (Sat-3)
	_bounties[BOUNTY_HIVE_QUEEN] = {
		"satellite": 3,
		"target_id": &"boss_hive_queen_guardian",
		"gold_reward": 2000,
		"is_plot": false,
		"special_tool_drop": &"military_jammer",
		"threat_level": 6,
		"recommended_level": 15,
		"title": "蜂后守卫",
		"description": "The hive queen's guard has been spotted. Defeat it.",
	}
	# Bounty #4: AI Echo (Sat-4)
	_bounties[BOUNTY_AI_ECHO] = {
		"satellite": 4,
		"target_id": &"boss_pluto_remnant",
		"gold_reward": 3000,
		"is_plot": false,
		"special_tool_drop": &"creator_locator",
		"threat_level": 7,
		"recommended_level": 18,
		"title": "AI 残响",
		"description": "Pluto's echo survives. Silence it.",
	}
	# Bounty #5: Creator's Echo (Sat-5)
	_bounties[BOUNTY_CREATOR_ECHO] = {
		"satellite": 5,
		"target_id": &"boss_creator",
		"gold_reward": 5000,
		"is_plot": false,
		"special_tool_drop": &"cangqiong_upgrade",
		"threat_level": 10,
		"recommended_level": 25,
		"title": "造物者的回声",
		"description": "A fragment of the Creator haunts Sat-5's deepest chamber.",
	}
	# Bounty #6: Hidden post-game (Sat-5, post-game only)
	_bounties[BOUNTY_HIDDEN_POSTGAME] = {
		"satellite": 5,
		"target_id": &"boss_creator_prime",
		"gold_reward": 10000,
		"is_plot": false,
		"special_tool_drop": &"",
		"threat_level": 12,
		"recommended_level": 30,
		"title": "???",
		"description": "A hidden post-game challenge for those who have completed the main story.",
	}
	# Initialize state for each
	for bid in _bounties:
		_bounty_state[bid] = {"status": "AVAILABLE", "attempt_count": 0}
		_medals_collected[bid] = false

# === API ===

# Get bounty info
func get_bounty_info(bounty_id: StringName) -> Dictionary:
	return _bounties.get(bounty_id, {})

# Get all bounties
func get_all_bounties() -> Array[StringName]:
	return ALL_BOUNTIES.duplicate()

# Get bounties for a specific satellite
func get_bounties_for_satellite(satellite: int) -> Array[StringName]:
	var out: Array[StringName] = []
	for bid in _bounties:
		if int(_bounties[bid].get("satellite", 0)) == satellite:
			out.append(bid)
	return out

# Get bounty status
func get_bounty_status(bounty_id: StringName) -> String:
	if not _bounty_state.has(bounty_id):
		return "UNKNOWN"
	return String(_bounty_state[bounty_id].get("status", "AVAILABLE"))

# Accept a bounty
func accept_bounty(bounty_id: StringName) -> Error:
	if not _bounties.has(bounty_id):
		return ERR_INVALID_PARAMETER
	var status: String = get_bounty_status(bounty_id)
	if status == "COMPLETED":
		return ERR_ALREADY_IN_USE
	if status == "ACCEPTED":
		return ERR_ALREADY_IN_USE
	_bounty_state[bounty_id]["status"] = "ACCEPTED"
	bounty_accepted.emit(bounty_id)
	return OK

# Abandon a bounty (only non-plot bounties can be abandoned)
func abandon_bounty(bounty_id: StringName) -> Error:
	if not _bounties.has(bounty_id):
		return ERR_INVALID_PARAMETER
	if bool(_bounties[bounty_id].get("is_plot", false)):
		return ERR_UNAVAILABLE  # Plot bounties can't be abandoned
	_bounty_state[bounty_id]["status"] = "ABANDONED"
	bounty_abandoned.emit(bounty_id)
	return OK

# Complete a bounty (grants gold + special tool)
func complete_bounty(bounty_id: StringName) -> Error:
	if not _bounties.has(bounty_id):
		return ERR_INVALID_PARAMETER
	var gold: int = int(_bounties[bounty_id].get("gold_reward", 0))
	_bounty_state[bounty_id]["status"] = "COMPLETED"
	_medals_collected[bounty_id] = true
	# Grant gold via ClinicManager
	var cm: Node = get_node_or_null("/root/ClinicManager")
	if cm != null:
		cm.add_gold(gold)
	bounty_completed.emit(bounty_id, gold)
	return OK

# Fail a bounty (player died)
func fail_bounty(bounty_id: StringName) -> Error:
	if not _bounties.has(bounty_id):
		return ERR_INVALID_PARAMETER
	_bounty_state[bounty_id]["attempt_count"] = int(_bounty_state[bounty_id].get("attempt_count", 0)) + 1
	_bounty_state[bounty_id]["status"] = "AVAILABLE"  # Can retry
	bounty_failed.emit(bounty_id)
	return OK

# Medal queries
func has_medal(bounty_id: StringName) -> bool:
	return bool(_medals_collected.get(bounty_id, false))

func get_medal_count() -> int:
	var count: int = 0
	for bid in _medals_collected:
		if bool(_medals_collected[bid]):
			count += 1
	return count

func get_total_medals() -> int:
	return _medals_collected.size()

# Special tool queries
func get_special_tool_drop(bounty_id: StringName) -> StringName:
	return StringName(_bounties.get(bounty_id, {}).get("special_tool_drop", ""))

# Reset all bounties (new game)
func reset_all_bounties() -> void:
	for bid in _bounties:
		_bounty_state[bid] = {"status": "AVAILABLE", "attempt_count": 0}
		_medals_collected[bid] = false

# === Save/Load ===

func get_state_snapshot() -> Dictionary:
	return {
		"bounty_state": _bounty_state.duplicate(true),
		"medals": _medals_collected.duplicate(true),
	}

func load_snapshot(snap: Dictionary) -> Error:
	if snap.has("bounty_state"):
		var bs: Dictionary = snap["bounty_state"]
		for bid in bs:
			if _bounty_state.has(bid):
				_bounty_state[bid] = bs[bid]
	if snap.has("medals"):
		var ms: Dictionary = snap["medals"]
		for bid in ms:
			if _medals_collected.has(bid):
				_medals_collected[bid] = ms[bid]
	return OK