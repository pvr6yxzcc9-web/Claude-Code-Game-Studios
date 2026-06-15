@tool
class_name EnemyData
extends ImmutableResource

# EnemyData (per resource-data.md + ADR-0008 + ADR-0011)

@export var id: StringName
@export var display_name: String
@export var sprite: Texture2D
@export_range(10, 500) var max_hp: int = 40
@export_range(1, 100) var attack: int = 25
@export_range(0.0, 1.0) var accuracy: float = 0.85
@export var drops: Array[Resource] = []
@export var weaknesses: Array[StringName] = []
@export var resistances: Array[StringName] = []
@export var boss: bool = false
@export var boss_immune_to_one_shot: bool = true  # per ADR-0011
