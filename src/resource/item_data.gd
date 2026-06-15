@tool
class_name ItemData
extends ImmutableResource

# ItemData (per resource-data.md + ADR-0008)

@export var id: StringName
@export var display_name: String
@export var icon: Texture2D
@export var category: StringName  # consumable / key / quest / misc
@export var description: String
@export_range(1, 999) var max_stack: int = 99
@export var effect: Resource  # optional EffectData
