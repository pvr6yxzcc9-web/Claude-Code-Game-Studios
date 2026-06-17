@tool
class_name QuestData
extends ImmutableResource

# QuestData (per design/gdd/side-quest-system.md) — 12th Resource subtype.
#
# 12 quest definitions total (3 per satellite × 4 satellites, skipping Sat-1).
# 3-choice outcome model: compassionate (idx 0, +1 truth, low gold) /
#                          pragmatic    (idx 1,  0 truth, mid gold) /
#                          ruthless     (idx 2, -1 truth, high gold, sometimes mech part).
#
# Quest state is NOT stored here — see QuestManager autoload.

@export var id: StringName  # MUST be unique across all 12 quests

# Display
@export var title_zh: String
@export var title_en: String
@export var description_zh: String
@export var description_en: String

# Where the quest lives
@export_range(1, 5) var satellite: int = 2  # Sat-2/3/4/5 only (Sat-1 is prologue)
@export var giver_npc_id: StringName  # NPC that offers this quest
@export var dialogue_tree_id: StringName  # initial dialogue (when AVAILABLE)

# Quest structure
@export var prerequisite_quest_ids: Array[StringName] = []  # must be COMPLETED to accept
@export var turn_in_npc_id: StringName  # NPC that accepts the turn-in (may differ from giver)
@export var quest_complete_dialogue_id: StringName  # dialogue during turn-in (when ACTIVE)
@export var quest_done_dialogue_id: StringName  # dialogue after completion (when COMPLETED)

# Rewards — arrays of 3 elements (one per choice idx: 0=compassionate, 1=pragmatic, 2=ruthless)
@export var gold_reward: Array[int] = [300, 800, 1500]  # per choice
@export var xp_reward: Array[int] = [200, 400, 600]  # per choice
@export var mech_part_reward: Array[StringName] = [&"", &"", &""]  # per choice; empty = no part
@export var truth_count_modifier: Array[int] = [1, 0, -1]  # per choice (drives ending)

# Visibility
@export var is_repeatable: bool = false  # can be accepted again after completion
@export var is_hidden: bool = false  # doesn't appear in board until conditions met
@export var is_plot_required: bool = false  # cannot be abandoned (like Bounty #2)
