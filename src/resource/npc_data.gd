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

# S13-008: Quest handoff fields. If gives_quest_ids is non-empty, this NPC
# is a quest giver. The 3 dialogue trees let DialogueManager pick the right
# one based on the quest's current state (AVAILABLE/ACTIVE/COMPLETED).
@export var gives_quest_ids: Array[StringName] = []  # quests this NPC offers (priority order)
@export var quest_complete_dialogue_id: StringName = &""  # dialogue during turn-in (when ACTIVE)
@export var quest_done_dialogue_id: StringName = &""  # dialogue after completion (when COMPLETED)
