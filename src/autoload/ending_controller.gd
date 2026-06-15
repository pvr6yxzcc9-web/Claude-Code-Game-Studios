extends Node

# EndingController (S4-009 + S5-005)
# Decides which ending the player gets after defeating the final boss.
# Logic is purely data-driven: count unlocked fragments in MetaState.
#
# S5-005 update: thresholds are still based on total unlocked count
# (unchanged from S4-009), but the 3 S4-005 tbd fragments have been
# wired to "boss_victory" trigger (see BattleScene._resolve_battle).
# This means at boss victory, the player will have at least the
# 3 boss-victory fragments + any log fragments they found.
#
# Thresholds:
#   - 6+ fragments unlocked: ending A (revelation)
#   - 3-5 fragments: ending B (partial)
#   - 0-2 fragments: ending C (default)
#   - S6-103: 0 log fragments (player never read any terminal) AND
#     defeated boss: ending D ("the worst kind of ending")
#
# Net effect: the 3 boss-victory fragments alone (without any log
# exploration) put the player at 3 fragments -> ending D. To get
# ending A, the player must have explored at least 3 logs (3 log
# fragments + 3 boss fragments = 6 -> A). To get ending C, the
# player must skip the boss-victory trigger entirely (impossible
# since boss victory is the only path to ending determination).
#
# In practice: with the current 7 fragment resources, the breakdown is
#   0 logs + boss victory: 3 fragments + 0 logs -> D (S6-103)
#   1 log  + boss victory: 4 fragments + 1 log  -> B
#   2 logs + boss victory: 5 fragments + 2 logs -> B
#   3 logs + boss victory: 6 fragments + 3 logs -> A
#   4 logs + boss victory: 7 fragments + 4 logs -> A
# Ending D is now reachable via the "I-just-killed-the-boss-and-didn't-read-anything"
# path. Ending C is reserved for save-data corruption or debug paths.
#
# The actual ending is then shown via DialogueManager.start_dialogue_with_tree
# using the returned tree id (no NPC resource needed; ends are not NPCs).

const ENDING_A_THRESHOLD: int = 6
const ENDING_B_THRESHOLD: int = 3

const ENDING_A_TREE_ID: StringName = &"dlg_ending_A"
const ENDING_B_TREE_ID: StringName = &"dlg_ending_B"
const ENDING_C_TREE_ID: StringName = &"dlg_ending_C"
const ENDING_D_TREE_ID: StringName = &"dlg_ending_D"  # S6-103

signal ending_chosen(tree_id: StringName, fragment_count: int)

func _ready() -> void:
    print("[EndingController] ready (S4-009 + S5-005)")

# Returns the dialogue tree id for the player's current fragment count.
# Pure function: read MetaState.unlocked_count, threshold check.
func determine_ending() -> StringName:
    var meta: Node = get_node_or_null("/root/MetaState")
    if meta == null:
        push_warning("EndingController: MetaState missing")
        return ENDING_C_TREE_ID
    var count: int = meta.unlocked_count()
    var log_count: int = 0
    if "log_fragments_count" in meta:
        log_count = int(meta.log_fragments_count())
    var chosen: StringName
    # S6-103: D-tier takes priority over B when the player has killed
    # the boss (>= 3 boss-victory fragments) but read ZERO log terminals.
    # This rewards exploration explicitly.
    if count >= ENDING_B_THRESHOLD and log_count == 0:
        chosen = ENDING_D_TREE_ID
    elif count >= ENDING_A_THRESHOLD:
        chosen = ENDING_A_TREE_ID
    elif count >= ENDING_B_THRESHOLD:
        chosen = ENDING_B_TREE_ID
    else:
        chosen = ENDING_C_TREE_ID
    ending_chosen.emit(chosen, count)
    return chosen

# Play the chosen ending. Caller (BattleScene) calls this after boss win.
func play_ending() -> Error:
    var tree_id: StringName = determine_ending()
    var reg: Node = get_node("/root/ResourceRegistry")
    var tree: Resource = reg.get_resource(tree_id)
    if tree == null:
        push_error("EndingController: tree %s not found" % tree_id)
        return ERR_DOES_NOT_EXIST
    var dm: Node = get_node("/root/DialogueManager")
    # Construct a synthetic "ending NPC" so dialogue manager can bind
    # the ending display. (dialogue_manager.start_dialogue_with_tree
    # accepts (tree, npc) but npc is only used for dialogue_started emit.)
    var npc: Resource = Resource.new()
    npc.set("id", &"_ending")
    npc.set("display_name", "The Convoy")
    npc.set("dialogue_tree_id", tree_id)
    return dm.start_dialogue_with_tree(tree, npc)
