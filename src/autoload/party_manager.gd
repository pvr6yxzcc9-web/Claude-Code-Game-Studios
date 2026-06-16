extends Node
# PartyManager (Sprint 7 PR 2 stub)
#
# This is a **minimal stub** that provides the party data interface
# for PartyBattleController. The full implementation (per the
# sprint-07-003 plan) is deferred to when MechLoadout is committed.
#
# Current state:
# - Provides a hardcoded 3-mech party
# - Provides a cangqiong unlock flag (always false for now)
# - Provides the "active pilot" (always "ranger")
#
# Sprint 7 PR 2 next steps:
# - Replace the hardcoded data with reads from MechLoadout
# - Add the cangqiong_unlocked flag
# - Add the pilot assignment data

# === Signals ===

signal party_changed
signal active_pilot_changed(new_pilot_id: StringName)
signal cangqiong_unlocked

# === Party State ===

# Default 3 pilots (per party-system.md §3.1)
const DEFAULT_PILOTS: Array[StringName] = [&"ranger", &"frostbite", &"bomber"]

# 3 mechs in the party
# Each: {id, name, max_hp, hp, pilot_id, is_active, parts_hp (4 parts), weapon_slots}
var _party_mechs: Array[Dictionary] = []
var _active_pilot_id: StringName = &"ranger"
var _cangqiong_unlocked: bool = false

func _ready() -> void:
    print("[PartyManager] ready (Sprint 7 PR 2 stub)")
    _initialize_default_party()

func _initialize_default_party() -> void:
    # Default 3-mech party (Ranger / Frostbite / Bomber)
    _party_mechs = [
        {
            "id": "ranger",
            "name": "漫游者",
            "max_hp": 400,
            "hp": 400,
            "pilot_id": "ranger",
            "is_active": true,
            "parts_hp": {"head": 100, "chest": 100, "arms": 100, "legs": 100},
            "weapon_slots": [&"rifle", &"knife", &"throwable"],
        },
        {
            "id": "frostbite",
            "name": "霜尾",
            "max_hp": 320,
            "hp": 320,
            "pilot_id": "frostbite",
            "is_active": false,
            "parts_hp": {"head": 80, "chest": 80, "arms": 80, "legs": 80},
            "weapon_slots": [&"greatsword", &"cryo_grenade", &""],
        },
        {
            "id": "bomber",
            "name": "轰天",
            "max_hp": 480,
            "hp": 480,
            "pilot_id": "bomber",
            "is_active": false,
            "parts_hp": {"head": 120, "chest": 120, "arms": 120, "legs": 120},
            "weapon_slots": [&"rail_cannon", &"grenade_launcher", &"repair_drone"],
        },
    ]

# === Public API ===

func get_party_mechs() -> Array[Dictionary]:
    return _party_mechs.duplicate(true)

func get_active_pilot() -> StringName:
    return _active_pilot_id

func set_active_pilot(pilot_id: StringName) -> void:
    if pilot_id == _active_pilot_id:
        return
    _active_pilot_id = pilot_id
    active_pilot_changed.emit(pilot_id)
    party_changed.emit()

func is_cangqiong_unlocked() -> bool:
    return _cangqiong_unlocked

func unlock_cangqiong() -> void:
    if _cangqiong_unlocked:
        return
    _cangqiong_unlocked = true
    cangqiong_unlocked.emit()
    party_changed.emit()
    print("[PartyManager] cangqiong unlocked")

# === Save/Load Stubs (Sprint 7-010 will replace) ===

func get_state_snapshot() -> Dictionary:
    return {
        "active_pilot_id": _active_pilot_id,
        "cangqiong_unlocked": _cangqiong_unlocked,
        # Per-mech state in a future PR
    }

func load_snapshot(snap: Dictionary) -> Error:
    if "active_pilot_id" in snap:
        _active_pilot_id = snap["active_pilot_id"]
    if "cangqiong_unlocked" in snap:
        _cangqiong_unlocked = snap["cangqiong_unlocked"]
    return OK
