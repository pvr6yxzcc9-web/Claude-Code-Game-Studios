@tool
class_name MechPartData
extends ImmutableResource

# MechPartData (per resource-data.md + ADR-0008)

@export var id: StringName
@export var display_name: String
@export var part_slot: StringName  # torso / left_arm / right_arm / legs / core
@export_range(0, 1000) var hp_bonus: int = 0
@export_range(0, 100) var attack_bonus: int = 0
@export_range(0, 100) var defense_bonus: int = 0
@export var weapon_slots: Array[StringName] = []
@export var sprite: Texture2D
@export var description: String
