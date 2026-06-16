extends Node

# HallucinationManager (S8-013) — manages decoy enemies in Sat-3 蜂巢号.
# Per sprint-08-sat3-hive.md + multi-satellite-arc.md §4.3
# Decoys are visual-only enemies that fade away when attacked.
# They do NOT deal damage. They help convey the "hive mind" theme.

signal decoy_attacked(decoy_id: StringName, room_id: StringName)
signal decoy_revealed(decoy_id: StringName, room_id: StringName)

# Per-room decoy configuration. Each room has 0-2 decoys.
# Format: { room_id: [decoy1_id, decoy2_id] }
var _decoys: Dictionary = {}

# Active decoys (decoy_id → {position, room_id})
var _active_decoys: Dictionary = {}

# ROOMS WITH DECOYS (Sat-3 only — per OQ4 "per-room not per-save")
# Decoys are deterministic per room (save/load preserves them).
const SAT3_DECOY_ROOMS: Dictionary = {
	&"c3_r2": [&"decoy_1", &"decoy_2"],          # Ch7 Room 2 (Ch7 = c3_r1 to c3_r3)
	&"c3_r4": [&"decoy_3"],                       # Ch8 Room 1
	&"c3_r7": [&"decoy_4", &"decoy_5"],           # Ch9 Room 1
	&"c3_r9": [&"decoy_6"],                       # Boss arena (1 decoy)
}

# Visual properties: decoys are translucent purple
const DECOY_COLOR: Color = Color(0.6, 0.4, 0.8, 0.5)
const DECOY_QUESTION_LABEL: String = "?"

func _ready() -> void:
	print("[HallucinationManager] ready — Sat-3 decoys registered")

# === API ===

# Get all decoys in a given room. Returns Array[StringName] of decoy IDs.
func get_decoys_in_room(room_id: StringName) -> Array[StringName]:
	return SAT3_DECOY_ROOMS.get(room_id, [])

# Check if a given "enemy" is a decoy. Returns true if the entity is a hallucination.
func is_decoy(entity_id: StringName, room_id: StringName) -> bool:
	var decoys: Array[StringName] = SAT3_DECOY_ROOMS.get(room_id, [])
	return entity_id in decoys

# Player attacks a decoy. Returns true if the attack was on a decoy
# (so the caller can skip damage application).
func on_attack(entity_id: StringName, room_id: StringName) -> bool:
	if not is_decoy(entity_id, room_id):
		return false  # Not a decoy — normal enemy attack
	# It's a decoy — emit reveal signal
	decoy_attacked.emit(entity_id, room_id)
	decoy_revealed.emit(entity_id, room_id)
	# Remove from active set
	if _active_decoys.has(entity_id):
		_active_decoys.erase(entity_id)
	print("[HallucinationManager] decoy %s attacked in %s — fades away" % [entity_id, room_id])
	return true

# Register a decoy's position (called by encounter_tile when the room loads).
func register_decoy_position(decoy_id: StringName, room_id: StringName, position: Vector2) -> void:
	_active_decoys[decoy_id] = {
		"room_id": room_id,
		"position": position,
		"revealed": false,
	}

# Get a decoy's properties (for the encounter tile to render it).
func get_decoy_info(decoy_id: StringName) -> Dictionary:
	return _active_decoys.get(decoy_id, {})

# Get the visual color (translucent purple) for decoy rendering.
func get_decoy_color() -> Color:
	return DECOY_COLOR

# Get the question label for the decoy (hover indicator).
func get_decoy_label() -> String:
	return DECOY_QUESTION_LABEL

# === Save/Load ===

func get_state_snapshot() -> Dictionary:
	# Decoys are deterministic per room — no per-save state needed.
	# We just record which decoys have been revealed (so they don't reappear
	# after a save/load cycle if the player already attacked them).
	return {
		"revealed_decoys": _get_revealed_decoys(),
	}

func _get_revealed_decoys() -> Array:
	var out: Array = []
	for decoy_id in _active_decoys:
		if _active_decoys[decoy_id].get("revealed", false):
			out.append(String(decoy_id))
	return out

func load_snapshot(snap: Dictionary) -> Error:
	if not snap.has("revealed_decoys"):
		return OK
	# Mark already-revealed decoys as revealed (they won't respawn)
	var revealed: Array = snap["revealed_decoys"]
	for decoy_id_str in revealed:
		var decoy_id: StringName = StringName(decoy_id_str)
		if _active_decoys.has(decoy_id):
			_active_decoys[decoy_id]["revealed"] = true
	return OK

# Reset all decoys (called on new game)
func reset_all_decoys() -> void:
	_active_decoys.clear()