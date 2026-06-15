@tool
class_name RegionData
extends ImmutableResource

# RegionData (per resource-data.md + ADR-0008)
# A region/chapter of the game. Holds meta info for save + display.

@export var id: StringName
@export var display_name: String
@export var chapter_index: int = 1
@export var tilemap_path: String = ""
@export var background_music: String = ""
@export_range(1, 999) var enemy_pool_min_level: int = 1
@export_range(1, 999) var enemy_pool_max_level: int = 10
@export var boss_id: StringName = &""
@export var encounter_rate: float = 0.06  # 6% per step (per random-encounter GDD)
@export var description: String
