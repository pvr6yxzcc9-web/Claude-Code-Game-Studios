@tool
class_name StoryFragmentData
extends ImmutableResource

# StoryFragmentData (per resource-data.md + ADR-0008)
# A piece of the world's truth narrative. Unlocked via discovery.

@export var id: StringName
@export var title: String
@export var body: String
@export var unlock_condition: StringName  # discovery type (e.g., visited_room, defeated_boss)
@export var related_fragment_ids: Array[StringName] = []
@export_range(1, 10) var lore_layer: int = 1  # 1=surface, 10=deepest truth
@export var icon: Texture2D
