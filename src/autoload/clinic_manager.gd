extends Node

# ClinicManager (S7-006) — town clinic revival system.
# Per party-system.md §3.8: non-main pilots knocked out in combat are
# auto-queued for revival. Cost = max(floor(gold × 0.25), 100). Unlimited
# revivals. Main character (漫游者 / ranger) cannot be revived — death = game over.

signal pilot_revived(pilot_id: StringName, gold_spent: int)
signal pilot_state_changed(pilot_id: StringName, new_state: int)
signal gold_changed(new_amount: int)
signal pilot_knocked_out(pilot_id: StringName)

# Per-pilot state
enum PilotState { ACTIVE, KNOCKED_OUT, DEAD }

# pilot_id (StringName) → PilotState (int)
var _pilot_states: Dictionary = {}

# Pilots queued for revival (set after combat)
var _revival_queue: Array[StringName] = []

# Gold tracking
var _gold: int = 0

# Revival cost formula
const REVIVAL_COST_RATIO: float = 0.25
const REVIVAL_COST_MIN: int = 100

# The main character — cannot be revived (death = game over)
const MAIN_PILOT: StringName = &"ranger"

func _ready() -> void:
	# Initialize 3 pilots (even if not yet recruited — they're ACTIVE by default)
	# The party system tracks recruitment separately.
	_pilot_states[&"ranger"] = PilotState.ACTIVE
	_pilot_states[&"frostbite"] = PilotState.ACTIVE
	_pilot_states[&"bomber"] = PilotState.ACTIVE
	print("[ClinicManager] ready — 3 pilots initialized")

# Knock out a non-main pilot. Called from BattleScene when a mech reaches 0 HP.
# Main character is rejected — death = game over (caller must handle).
func knock_out_pilot(pilot_id: StringName) -> void:
	if pilot_id == MAIN_PILOT:
		push_error("ClinicManager: cannot knock out main character (ranger) — that's game over")
		return
	if not _pilot_states.has(pilot_id):
		# Auto-add the pilot (e.g., newly recruited companion)
		_pilot_states[pilot_id] = PilotState.ACTIVE
	if _pilot_states[pilot_id] == PilotState.KNOCKED_OUT:
		return  # already knocked out
	_pilot_states[pilot_id] = PilotState.KNOCKED_OUT
	if not _revival_queue.has(pilot_id):
		_revival_queue.append(pilot_id)
	pilot_state_changed.emit(pilot_id, PilotState.KNOCKED_OUT)
	pilot_knocked_out.emit(pilot_id)
	print("[ClinicManager] pilot %s knocked out, queued for revival" % pilot_id)

# Mark a pilot as dead (cannot be revived). For story-critical deaths.
func mark_pilot_dead(pilot_id: StringName) -> void:
	if pilot_id == MAIN_PILOT:
		push_warning("ClinicManager: marking main character dead — game over should fire elsewhere")
	_pilot_states[pilot_id] = PilotState.DEAD
	_revival_queue.erase(pilot_id)
	pilot_state_changed.emit(pilot_id, PilotState.DEAD)

# Revive a knocked-out pilot. Deducts gold.
# Returns OK on success, ERR_DOES_NOT_EXIST if insufficient gold,
# ERR_INVALID_DATA if pilot is not knocked out, ERR_INVALID_PARAMETER if unknown.
func revive_pilot(pilot_id: StringName) -> Error:
	if not _pilot_states.has(pilot_id):
		return ERR_INVALID_PARAMETER
	if _pilot_states[pilot_id] != PilotState.KNOCKED_OUT:
		return ERR_INVALID_DATA
	var cost: int = get_revival_cost()
	if _gold < cost:
		return ERR_DOES_NOT_EXIST
	_gold -= cost
	_pilot_states[pilot_id] = PilotState.ACTIVE
	_revival_queue.erase(pilot_id)
	pilot_revived.emit(pilot_id, cost)
	gold_changed.emit(_gold)
	pilot_state_changed.emit(pilot_id, PilotState.ACTIVE)
	print("[ClinicManager] pilot %s revived for %d gold" % [pilot_id, cost])
	return OK

# Get the cost to revive the next knocked-out pilot.
# Formula: max(floor(gold × 0.25), 100).
func get_revival_cost() -> int:
	return max(int(floor(float(_gold) * REVIVAL_COST_RATIO)), REVIVAL_COST_MIN)

func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	_gold += amount
	gold_changed.emit(_gold)

func spend_gold(amount: int) -> bool:
	if amount > _gold:
		return false
	_gold -= amount
	gold_changed.emit(_gold)
	return true

func get_gold() -> int:
	return _gold

func is_knocked_out(pilot_id: StringName) -> bool:
	return _pilot_states.get(pilot_id, PilotState.ACTIVE) == PilotState.KNOCKED_OUT

func is_dead(pilot_id: StringName) -> bool:
	return _pilot_states.get(pilot_id, PilotState.ACTIVE) == PilotState.DEAD

func is_active(pilot_id: StringName) -> bool:
	return _pilot_states.get(pilot_id, PilotState.ACTIVE) == PilotState.ACTIVE

func get_pilot_state(pilot_id: StringName) -> int:
	return _pilot_states.get(pilot_id, PilotState.ACTIVE)

func get_knocked_out_pilots() -> Array[StringName]:
	# Return a copy of the queue
	var out: Array[StringName] = []
	for pid in _revival_queue:
		if _pilot_states.get(pid, PilotState.ACTIVE) == PilotState.KNOCKED_OUT:
			out.append(pid)
	return out

func has_pending_revivals() -> bool:
	return not _revival_queue.is_empty()

# === Save/Load ===

func get_state_snapshot() -> Dictionary:
	# Persist enum values as ints (Godot Resource doesn't serialize enums directly)
	var states_dict: Dictionary = {}
	for pid in _pilot_states:
		states_dict[String(pid)] = int(_pilot_states[pid])
	return {
		"gold": _gold,
		"pilot_states": states_dict,
		"revival_queue": _revival_queue.duplicate(),
	}

func load_snapshot(snap: Dictionary) -> Error:
	if snap.has("gold"):
		_gold = int(snap["gold"])
	if snap.has("pilot_states"):
		var states_dict: Dictionary = snap["pilot_states"]
		for pid_str in states_dict:
			_pilot_states[StringName(pid_str)] = int(states_dict[pid_str])
	if snap.has("revival_queue"):
		_revival_queue.clear()
		var queue_arr: Array = snap["revival_queue"]
		for pid in queue_arr:
			_revival_queue.append(StringName(pid))
	# Migrate: ensure all 3 known pilots have a state entry (defaults to ACTIVE)
	for default_pid in [&"ranger", &"frostbite", &"bomber"]:
		if not _pilot_states.has(default_pid):
			_pilot_states[default_pid] = PilotState.ACTIVE
	return OK