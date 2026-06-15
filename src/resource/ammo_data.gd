@tool
class_name AmmoData
extends ImmutableResource

# AmmoData (per resource-data.md + ADR-0008)

@export var id: StringName
@export var display_name: String
@export_range(0.1, 3.0) var damage_mult: float = 1.0
@export var effect: Resource  # optional EffectData
@export_range(1, 999) var stack_size: int = 99
