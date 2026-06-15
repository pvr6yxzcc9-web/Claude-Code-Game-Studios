extends Node

# DialogueManager (per npc-terminal.md)
# Manages current dialogue state. Listens to input (1/2/3) to advance.
# Per player-input.md: 1/2/3 in state_dialogue = choice 1/2/3.

signal dialogue_started(npc: Resource)
signal dialogue_ended()
signal node_entered(node_id: StringName, text: String, choices: Array)
signal choice_made(idx: int)

var current_npc: Resource = null
var current_tree: Resource = null
var current_node_id: StringName = &""
var is_active: bool = false

func _ready() -> void:
    if get_node_or_null("/root/GameStateMachine") == null:
        push_error("DialogueManager: GameStateMachine must load first")
    # Listen for 1/2/3 input via InputBus
    var input_bus: Node = get_node("/root/InputBus")
    input_bus.action_pressed.connect(_on_action_pressed)
    print("[DialogueManager] ready")

func _on_action_pressed(action: StringName) -> void:
    if not is_active:
        return
    # Per player-input.md: 1/2/3 in dialogue = choice
    match action:
        &"battle_attack_slot1":
            choose(0)
        &"battle_attack_slot2":
            choose(1)
        &"battle_attack_slot3":
            choose(2)

func start_dialogue(npc: Resource) -> Error:
    if npc == null:
        return ERR_INVALID_PARAMETER
    var tree_id: StringName = StringName(npc.get("dialogue_tree_id"))
    if tree_id == &"":
        push_warning("DialogueManager: NPC %s has no dialogue_tree_id" % npc.get("id"))
        return ERR_DOES_NOT_EXIST
    var reg: Node = get_node("/root/ResourceRegistry")
    var tree: Resource = reg.get_resource(tree_id)
    if tree == null:
        push_error("DialogueManager: tree %s not found" % tree_id)
        return ERR_DOES_NOT_EXIST
    return start_dialogue_with_tree(tree, npc)

# Test-friendly entry point: starts a dialogue with a tree that was NOT
# loaded from ResourceRegistry. Used by fc22 to inject synthetic trees
# without writing test-only .tres files into data/.
# (Used by tests; safe to call in production too if a caller already has
# the tree resource in hand.)
func start_dialogue_with_tree(tree: Resource, npc: Resource) -> Error:
    if tree == null or npc == null:
        return ERR_INVALID_PARAMETER
    current_npc = npc
    current_tree = tree
    is_active = true
    current_node_id = StringName(tree.get("start_node_id"))
    var sm: Node = get_node("/root/GameStateMachine")
    sm.transition_to(&"state_dialogue")
    dialogue_started.emit(npc)
    _emit_current_node()
    return OK

func choose(choice_index: int) -> void:
    if not is_active or current_tree == null:
        return
    var nodes: Dictionary = current_tree.get("nodes")
    if not nodes.has(current_node_id):
        push_error("DialogueManager: node %s not in tree" % current_node_id)
        end_dialogue()
        return
    var node: Dictionary = nodes[current_node_id]
    var choices: Array = node.get("choices", [])
    if choice_index < 0 or choice_index >= choices.size():
        return  # invalid choice, ignore
    choice_made.emit(choice_index)
    var next_id: StringName = StringName(choices[choice_index].get("next", ""))
    if next_id == &"":
        end_dialogue()
        return
    current_node_id = next_id
    _emit_current_node()

func _emit_current_node() -> void:
    if current_tree == null:
        return
    var nodes: Dictionary = current_tree.get("nodes")
    if not nodes.has(current_node_id):
        end_dialogue()
        return
    var node: Dictionary = nodes[current_node_id]
    var text: String = String(node.get("text", ""))
    var choices: Array = node.get("choices", [])
    # S2-005: per-node fragment unlock. If the dialogue node has an
    # `unlock_fragment_id` field, mark it in MetaState (idempotent via
    # mark_unlocked). Backward-compatible: nodes without the field do nothing.
    var frag_id_v: Variant = node.get("unlock_fragment_id", null)
    if frag_id_v != null and frag_id_v != &"":
        var frag_id: StringName = StringName(frag_id_v)
        var meta: Node = get_node_or_null("/root/MetaState")
        if meta != null and meta.has_method("mark_unlocked"):
            meta.mark_unlocked(frag_id)
    if choices.is_empty():
        # S5-006: emit the final node, but DO NOT auto-end the dialogue.
        # Ending dialogues (e.g. dlg_ending_A.tres) have 0 choices and
        # must stay visible until the player explicitly closes them.
        # Without this fix, ending was emitted and end_dialogue() ran
        # in the same frame, transitioning back to state_exploration
        # before the DialogueUI had a chance to render the text.
        node_entered.emit(current_node_id, text, [])
    else:
        node_entered.emit(current_node_id, text, choices)

func end_dialogue() -> void:
    is_active = false
    current_npc = null
    current_tree = null
    current_node_id = &""
    var sm: Node = get_node("/root/GameStateMachine")
    sm.transition_to(&"state_exploration")
    dialogue_ended.emit()
