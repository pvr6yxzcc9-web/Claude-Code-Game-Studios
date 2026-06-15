@tool
class_name WeaponData
extends ImmutableResource

# WeaponData (per resource-data.md + ADR-0008)
# Static data for a weapon. Loaded from .tres. Immutable at runtime.

@export var id: StringName
@export var display_name: String
@export var icon: Texture2D
@export_range(1, 999) var min_damage: int = 20
@export_range(1, 999) var max_damage: int = 20
@export_range(0.0, 1.0) var accuracy: float = 0.9
@export var ammo_slot: StringName = &"any"
@export var range: StringName = &"mid"  # near / mid / far
@export_range(0.0, 1.0) var crit_chance: float = 0.05
@export_range(1.0, 5.0) var crit_multiplier: float = 2.0
@export var special_effects: Array[Resource] = []
