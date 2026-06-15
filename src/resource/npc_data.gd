@tool
class_name NPCData
extends ImmutableResource

# NPCData (per resource-data.md + ADR-0008)
# 10th Resource subtype — per ADR-0008.

@export var id: StringName  # MUST be unique across all NPCs (per ADR-0008 C-R3)
@export var display_name: String
@export var portrait: Texture2D
@export var faction: StringName = &""
@export var dialogue_tree_id: StringName = &""
@export var location: StringName = &""  # region id
@export var role: StringName = &""  # merchant / quest_giver / lore_keeper / ambient
@export var inventory_id: StringName = &""  # optional merchant inventory id
@export var description: String
@export_range(0, 5) var priority: int = 0  # quest priority, 0=ambient
