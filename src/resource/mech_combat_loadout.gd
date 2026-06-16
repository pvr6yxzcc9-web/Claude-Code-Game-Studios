@tool
class_name MechCombatLoadout
extends Resource

# MechCombatLoadout (S7-002 + S7-003) — per-mech all-in-one data.
# Each mech in the roster has one of these. Holds:
#   - Identity (mech_id, display_name, class_type)
#   - Weapon slots + ammo (3-4 slots)
#   - 4 parts HP (head / chest / arms / legs) per party-system.md §3.5
#   - Stats (mobility / armor / firepower)
#   - Module slots (1 for normal, 2 for 苍穹号)
#
# NOTE: Distinct from the `MechLoadout` autoload (src/autoload/mech_loadout.gd),
# which tracks the roster of mechs + global cycling API. This resource is the
# per-mech data; the autoload manages a collection of them.

# === Identity (S7-003) ===

var mech_id: StringName = &""  # e.g. &"ranger_mech"
var display_name: String = ""  # e.g. "漫游者号"
var class_type: StringName = &"infantry"  # infantry / cavalry / artillery / legendary

# S7-007: pilot currently driving this mech. Default mapping is in
# MechLoadout.DEFAULT_PILOT_MAPPING but can be reassigned via Mech Bay.
var pilot_id: StringName = &""

# === Weapon slots (S7-002) ===

# 3 weapon slots (4 for 苍穹号, set via max_weapon_slots)
var weapon_slots: Array[StringName] = [&"", &"", &""]
# 3 ammo slots (parallel to weapon_slots)
var ammo_slots: Array[StringName] = [&"", &"", &""]

# Active slot within this mech (not a global index)
var active_slot: int = 0

# Max weapon slots (3 for normal mechs, 4 for 苍穹号)
var max_weapon_slots: int = 3

# === Parts HP (S7-002, S7-003 §3.5) ===

var head_hp: int = 100
var chest_hp: int = 100
var arms_hp: int = 100
var legs_hp: int = 100

var max_head_hp: int = 100
var max_chest_hp: int = 100
var max_arms_hp: int = 100
var max_legs_hp: int = 100

# === Stats (S7-003) ===

var mobility: int = 3
var armor: int = 3
var firepower: int = 3

# === Modules (S7-003) ===
# 1 slot for normal mechs, 2 slots for 苍穹号
var module_ids: Array[StringName] = [&""]

# === Unlocked flag (S7-003) ===
# 苍穹号 is locked until Ch13 inheritance. Other mechs are unlocked from game start.
var unlocked: bool = true