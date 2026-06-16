extends Node

# RacingManager (Sprint 11) — 6 tracks + 4 racing mechs + fixed-odds betting.
# Per production/sprints/sprint-11-bounty-racing.md + design/gdd/racing-minigame.md
# 6 tracks, 4 racing mechs, fixed-odds betting, deterministic outcomes.

signal race_started(track_id: StringName, mech_id: StringName)
signal race_finished(track_id: StringName, results: Dictionary, payouts: Dictionary)
signal bet_placed(track_id: StringName, mech_id: StringName, amount: int, payout_odds: float)

# Track IDs
const TRACK_FROZEN_FLATS: StringName = &"track_frozen_flats"
const TRACK_HIVE_TUNNELS: StringName = &"track_hive_tunnels"
const TRACK_WARZONE_RUINS: StringName = &"track_warzone_ruins"
const TRACK_DESERT_DASH: StringName = &"track_desert_dash"
const TRACK_NEON_NIGHTS: StringName = &"track_neon_nights"
const TRACK_CREATOR_RING: StringName = &"track_creator_ring"

const ALL_TRACKS: Array[StringName] = [
	TRACK_FROZEN_FLATS,
	TRACK_HIVE_TUNNELS,
	TRACK_WARZONE_RUINS,
	TRACK_DESERT_DASH,
	TRACK_NEON_NIGHTS,
	TRACK_CREATOR_RING,
]

# Racing mech IDs (4)
const MECH_BOLT: StringName = &"racing_bolt"
const MECH_SHADOW: StringName = &"racing_shadow"
const MECH_TITAN: StringName = &"racing_titan"
const MECH_WISP: StringName = &"racing_wisp"

const ALL_RACING_MECHS: Array[StringName] = [MECH_BOLT, MECH_SHADOW, MECH_TITAN, MECH_WISP]

# Track data: { id: {name, distance, terrain, recommended_mech, base_payout_odds} }
var _tracks: Dictionary = {}

# Racing mech data: { id: {speed, handling, durability, name, sprite} }
var _racing_mechs: Dictionary = {}

# Last race result (per track)
var _last_results: Dictionary = {}

func _ready() -> void:
	_register_default_tracks()
	_register_default_mechs()
	print("[RacingManager] ready — 6 tracks + 4 racing mechs registered")

func _register_default_tracks() -> void:
	_tracks[TRACK_FROZEN_FLATS] = {
		"name": "Frozen Flats",
		"distance": 1000,
		"terrain": "ice",
		"recommended_mech": MECH_BOLT,
		"base_payout_odds": 2.0,
		"description": "Flat ice plains. Speed mechs excel.",
	}
	_tracks[TRACK_HIVE_TUNNELS] = {
		"name": "Hive Tunnels",
		"distance": 800,
		"terrain": "hive",
		"recommended_mech": MECH_WISP,
		"base_payout_odds": 2.5,
		"description": "Tight corridors. Handling mechs excel.",
	}
	_tracks[TRACK_WARZONE_RUINS] = {
		"name": "Warzone Ruins",
		"distance": 1200,
		"terrain": "debris",
		"recommended_mech": MECH_TITAN,
		"base_payout_odds": 2.2,
		"description": "Debris-filled ruins. Durable mechs survive.",
	}
	_tracks[TRACK_DESERT_DASH] = {
		"name": "Desert Dash",
		"distance": 1500,
		"terrain": "sand",
		"recommended_mech": MECH_BOLT,
		"base_payout_odds": 1.8,
		"description": "Endless sand. Straight-line speed wins.",
	}
	_tracks[TRACK_NEON_NIGHTS] = {
		"name": "Neon Nights",
		"distance": 900,
		"terrain": "city",
		"recommended_mech": MECH_SHADOW,
		"base_payout_odds": 2.3,
		"description": "City at night. Shadow mechs blend in.",
	}
	_tracks[TRACK_CREATOR_RING] = {
		"name": "Creator's Ring",
		"distance": 2000,
		"terrain": "cosmic",
		"recommended_mech": MECH_WISP,
		"base_payout_odds": 3.0,
		"description": "The Creator's test track. Cosmic speeds.",
	}

func _register_default_mechs() -> void:
	_racing_mechs[MECH_BOLT] = {
		"name": "Bolt",
		"speed": 10,
		"handling": 6,
		"durability": 4,
		"description": "Fast but fragile. Best on flat tracks.",
	}
	_racing_mechs[MECH_SHADOW] = {
		"name": "Shadow",
		"speed": 7,
		"handling": 10,
		"durability": 5,
		"description": "Stealthy and agile. Best in cities.",
	}
	_racing_mechs[MECH_TITAN] = {
		"name": "Titan",
		"speed": 5,
		"handling": 5,
		"durability": 10,
		"description": "Slow but unstoppable. Best in warzones.",
	}
	_racing_mechs[MECH_WISP] = {
		"name": "Wisp",
		"speed": 9,
		"handling": 9,
		"durability": 6,
		"description": "Balanced. Best on cosmic tracks.",
	}

# === API ===

func get_track_info(track_id: StringName) -> Dictionary:
	return _tracks.get(track_id, {})

func get_all_tracks() -> Array[StringName]:
	return ALL_TRACKS.duplicate()

func get_racing_mech_info(mech_id: StringName) -> Dictionary:
	return _racing_mechs.get(mech_id, {})

func get_all_racing_mechs() -> Array[StringName]:
	return ALL_RACING_MECHS.duplicate()

# Calculate race time for a mech on a track (lower is better)
# Formula: time = distance / (speed * terrain_modifier)
func calculate_race_time(track_id: StringName, mech_id: StringName) -> float:
	var track: Dictionary = _tracks.get(track_id, {})
	var mech: Dictionary = _racing_mechs.get(mech_id, {})
	if track.is_empty() or mech.is_empty():
		return -1.0
	var distance: float = float(track.get("distance", 1000))
	var speed: float = float(mech.get("speed", 5))
	var handling: float = float(mech.get("handling", 5))
	var terrain: String = String(track.get("terrain", ""))
	# Terrain modifier: favored terrain = 1.0, neutral = 1.2, unfavorable = 1.5
	var terrain_mod: float = 1.2
	match terrain:
		"ice":
			terrain_mod = 1.0 if mech_id == MECH_BOLT else 1.3
		"hive":
			terrain_mod = 1.0 if mech_id == MECH_WISP else 1.3
		"debris":
			terrain_mod = 1.0 if mech_id == MECH_TITAN else 1.3
		"sand":
			terrain_mod = 1.0 if mech_id == MECH_BOLT else 1.3
		"city":
			terrain_mod = 1.0 if mech_id == MECH_SHADOW else 1.3
		"cosmic":
			terrain_mod = 1.0 if mech_id == MECH_WISP else 1.3
	# Handling reduces terrain penalty
	var handling_mod: float = 1.0 - (handling - 5) * 0.04
	terrain_mod = max(0.8, terrain_mod * handling_mod)
	return distance / (speed * (1.0 / terrain_mod))

# Run a race: returns ranked results {mech_id: time}
# Deterministic seed based on track_id + frame
func run_race(track_id: StringName) -> Dictionary:
	var times: Dictionary = {}
	for mech_id in ALL_RACING_MECHS:
		times[mech_id] = calculate_race_time(track_id, mech_id)
	_last_results[track_id] = times
	race_finished.emit(track_id, times, {})
	return times

# Place a bet
func place_bet(track_id: StringName, mech_id: StringName, amount: int) -> Error:
	var track: Dictionary = _tracks.get(track_id, {})
	if track.is_empty():
		return ERR_INVALID_PARAMETER
	var cm: Node = get_node_or_null("/root/ClinicManager")
	if cm == null:
		return ERR_DOES_NOT_EXIST
	if cm.get_gold() < amount:
		return ERR_DOES_NOT_EXIST
	# Calculate payout odds based on the mech's likelihood to win
	var all_times: Dictionary = run_race(track_id)
	var min_time: float = INF
	var winner: StringName = &""
	for mid in all_times:
		if float(all_times[mid]) < min_time:
			min_time = float(all_times[mid])
			winner = StringName(mid)
	var payout_odds: float = 1.0
	if winner == mech_id:
		payout_odds = 1.5  # Bet on winner = 1.5x
	else:
		payout_odds = float(track.get("base_payout_odds", 2.0)) * 1.5  # Bet on loser = higher payout
	cm.spend_gold(amount)
	bet_placed.emit(track_id, mech_id, amount, payout_odds)
	return OK

# Get last race result
func get_last_result(track_id: StringName) -> Dictionary:
	return _last_results.get(track_id, {})

# === Save/Load ===

func get_state_snapshot() -> Dictionary:
	return {
		"last_results": _last_results.duplicate(true),
	}

func load_snapshot(snap: Dictionary) -> Error:
	if snap.has("last_results"):
		var lr: Dictionary = snap["last_results"]
		for tid in lr:
			_last_results[tid] = lr[tid]
	return OK