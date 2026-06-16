@tool
class_name MechCombatLoadout
extends Resource

# MechCombatLoadout (S7-002) — per-mech weapon + ammo + parts HP data.
# Each mech has its own MechCombatLoadout instance held by WeaponLoadout.
# Replaces the global weapon_slots in the legacy 1v1 model.
#
# NOTE: This is distinct from the `MechLoadout` autoload (src/autoload/
# mech_loadout.gd), which tracks the 5 equipable mech parts (torso /
# left_arm / right_arm / legs / core). That one is for parts; this one is
# for weapons. Renamed to avoid class_name collision.

# 3 weapon slots (4 for 苍穹号, set per-mech via max_weapon_slots)
var weapon_slots: Array[StringName] = [&"", &"", &""]
# 3 ammo slots (parallel to weapon_slots)
var ammo_slots: Array[StringName] = [&"", &"", &""]

# Active slot within this mech (not a global index)
var active_slot: int = 0

# 4 parts HP (per party-system.md §3.5)
var head_hp: int = 100
var chest_hp: int = 100
var arms_hp: int = 100
var legs_hp: int = 100

# Max HP (per part)
var max_head_hp: int = 100
var max_chest_hp: int = 100
var max_arms_hp: int = 100
var max_legs_hp: int = 100

# Special module slot
var module_id: StringName = &""

# Max weapon slots (3 for normal mechs, 4 for 苍穹号)
var max_weapon_slots: int = 3