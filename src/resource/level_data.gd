@tool
class_name LevelData
extends Resource

# LevelData (per level-dungeon.md)
# Defines a chapter/region: list of room ids, encounter rate, boss id.
# Per ADR-0010: uses TileMapLayer for room geometry (rooms themselves can be .tscn).

@export var id: StringName
@export var display_name: String
@export var chapter_index: int = 1
@export var room_ids: Array[StringName] = []
@export var boss_id: StringName = &""
@export var encounter_rate: float = 0.06
@export var description: String
