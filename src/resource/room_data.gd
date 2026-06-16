@tool
class_name RoomData
extends Resource

# RoomData (per level-dungeon.md) — per-room metadata for Sat-3 content (S8-007).
# Each room has: id, display_name, chapter (7/8/9), tile_set, enemy_encounters,
# npcs, terminals, exits (room_id connections), and hallucination decoy hints.
#
# Per sprint-08-sat3-hive.md + data/levels/ch3_room_layouts.md.

@export var id: StringName                  # e.g. &"c3_r1"
@export var display_name: String             # e.g. "The Air Lock"
@export var chapter: int = 7                 # 7 / 8 / 9
@export var description: String = ""          # 1-line summary
@export var tile_set: StringName = &"ch3"    # ch3 = hive tiles
@export var enemy_encounters: Array[StringName] = []  # enemy IDs in this room
@export var has_boss: bool = false           # true only for c3_r10 (boss arena)
@export var npcs: Array[StringName] = []     # NPC IDs in this room
@export var terminals: Array[StringName] = []  # terminal log IDs
@export var fragment_ids: Array[StringName] = []  # fragment IDs found here
@export var exits: Array[StringName] = []    # connected room IDs
@export var decoy_count: int = 0             # 0-2 hallucination decoys