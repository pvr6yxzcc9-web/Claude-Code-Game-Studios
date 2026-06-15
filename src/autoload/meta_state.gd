extends Node

# MetaState (autoload #4)
# Per ADR-0008 + architecture §4a.
# Tracks per-entity discovery (for Codex) and per-item unlock (for story fragments).
# Emits entity_discovered / fragment_unlocked signals per ADR-0002.

signal entity_discovered(id: StringName)
signal fragment_unlocked(fragment_id: StringName)

var discovered: Dictionary[StringName, bool] = {}
var unlocked: Dictionary[StringName, bool] = {}

func _ready() -> void:
	# ADR-0001: assert upstream autoloads exist
	if get_node_or_null("/root/GameStateMachine") == null:
		push_error("MetaState: GameStateMachine must load before MetaState")
	if get_node_or_null("/root/InputBus") == null:
		push_error("MetaState: InputBus must load before MetaState")
	if get_node_or_null("/root/ResourceRegistry") == null:
		push_error("MetaState: ResourceRegistry must load before MetaState")
	print("[MetaState] ready as autoload #4")

func mark_discovered(id: StringName) -> void:
	if id in discovered and discovered[id]:
		return  # already discovered, no-op
	discovered[id] = true
	entity_discovered.emit(id)

func mark_unlocked(id: StringName) -> void:
	if id in unlocked and unlocked[id]:
		return  # already unlocked, no-op
	unlocked[id] = true
	fragment_unlocked.emit(id)

# S6-103: list of fragment ids granted by boss-victory (not exploration).
# Used to distinguish "read logs" vs "got boss kill bonus".
const _BOSS_VICTORY_FRAGMENTS := [
	&"fragment_what_was_carried",
	&"fragment_the_truth",
	&"fragment_engineer_last_stand",
]

func _is_boss_victory_fragment(id: StringName) -> bool:
	return id in _BOSS_VICTORY_FRAGMENTS

# S6-103: count of log-derived fragments unlocked (excludes boss-victory
# bonus). Used by EndingController to detect "player never read any log".
func log_fragments_count() -> int:
	var count: int = 0
	for id in unlocked:
		if unlocked[id] and not _is_boss_victory_fragment(id):
			count += 1
	return count

func is_discovered(id: StringName) -> bool:
	return id in discovered and discovered[id]

func is_unlocked(id: StringName) -> bool:
	return id in unlocked and unlocked[id]

func unlocked_count() -> int:
	return unlocked.size()

func get_state_snapshot() -> Dictionary:
	# Per ADR-0003 Save Contract
	return {
		"schema_version": 1,
		"discovered": discovered.duplicate(),
		"unlocked": unlocked.duplicate(),
	}

func load_snapshot(snap: Dictionary) -> Error:
	if not snap.has("discovered") or not snap.has("unlocked"):
		push_warning("MetaState.load_snapshot: missing fields, using defaults")
		return OK
	discovered.clear()
	for key in snap["discovered"].keys():
		discovered[StringName(key)] = bool(snap["discovered"][key])
	unlocked.clear()
	for key in snap["unlocked"].keys():
		unlocked[StringName(key)] = bool(snap["unlocked"][key])
	return OK
