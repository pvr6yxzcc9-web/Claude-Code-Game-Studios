extends Node

# DialogueManager (per npc-terminal.md + party-system.md §3.9)
# Manages current dialogue state. Listens to input (1/2/3) to advance.
# Per player-input.md: 1/2/3 in state_dialogue = choice 1/2/3.
# S7-005: supports in_dialogue_companion_id. Player picks companion before
# dialogue via Shift+1/2/3 (handled by set_in_dialogue_companion()).
# Some NPCs have companion-specific dialogue trees.

signal dialogue_started(npc: Resource)
signal dialogue_ended()
signal node_entered(node_id: StringName, text: String, choices: Array)
signal choice_made(idx: int)

var current_npc: Resource = null
var current_tree: Resource = null
var current_node_id: StringName = &""
var is_active: bool = false

# S7-005: in-dialogue companion (the pilot "speaking" alongside the main character)
# Defaults to empty — caller (e.g. interaction code) can pre-set via
# set_in_dialogue_companion(id) before calling start_dialogue.
var in_dialogue_companion_id: StringName = &""

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
        # S7-005: Shift+1/2/3 swaps in-dialogue companion mid-dialogue
        &"dialogue_companion_1":
            set_in_dialogue_companion(&"ranger")
        &"dialogue_companion_2":
            set_in_dialogue_companion(&"frostbite")
        &"dialogue_companion_3":
            set_in_dialogue_companion(&"bomber")

# S7-005: set the in-dialogue companion (called by input handler or external code).
# Validates against the current pilot roster if PartyManager is available.
func set_in_dialogue_companion(companion_id: StringName) -> void:
    if companion_id == &"":
        in_dialogue_companion_id = &""
        return
    # Validate: companion must be in the player's party (if PartyManager exists)
    var pm: Node = get_node_or_null("/root/PartyManager")
    if pm != null:
        var is_in_party: bool = false
        for pilot in pm.DEFAULT_PILOTS:
            if pilot == companion_id:
                is_in_party = true
                break
        if not is_in_party:
            push_warning("DialogueManager: companion %s not in party roster" % companion_id)
            return
    in_dialogue_companion_id = companion_id
    print("[DialogueManager] in-dialogue companion = %s" % companion_id)

# S7-005: pick the dialogue tree for this NPC based on companion.
# Returns the companion-specific tree if the NPC has one; otherwise the default.
func _pick_dialogue_tree(npc: Resource, companion_id: StringName) -> Resource:
    if npc == null:
        return null
    # Look up companion_trees on the NPC (Dict[StringName, StringName] of tree_id by companion)
    if companion_id != &"" and "companion_trees" in npc:
        var trees: Variant = npc.get("companion_trees")
        if trees is Dictionary and (trees as Dictionary).has(companion_id):
            var tree_id: StringName = StringName((trees as Dictionary)[companion_id])
            if tree_id != &"":
                var reg: Node = get_node("/root/ResourceRegistry")
                var tree: Resource = reg.get_resource(tree_id)
                if tree != null:
                    return tree
    # Fall back to default tree
    var default_tree_id: StringName = StringName(npc.get("dialogue_tree_id"))
    if default_tree_id == &"":
        return null
    var reg: Node = get_node("/root/ResourceRegistry")
    return reg.get_resource(default_tree_id)

func start_dialogue(npc: Resource, companion_id: StringName = &"") -> Error:
    if npc == null:
        return ERR_INVALID_PARAMETER
    # S7-005: if companion_id is passed, set it; otherwise use current in_dialogue_companion_id
    if companion_id != &"":
        in_dialogue_companion_id = companion_id
    var tree: Resource = _pick_dialogue_tree(npc, in_dialogue_companion_id)
    if tree == null:
        push_warning("DialogueManager: NPC %s has no dialogue tree (companion=%s)" % [npc.get("id"), in_dialogue_companion_id])
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

# S7-005: get the text for a node, applying companion_overrides if present.
# Returns the base text from nodes[node_id], or the companion-specific text
# if the tree has companion_overrides[node_id][companion_id].
func get_node_text(node_id: StringName, companion_id: StringName = &"") -> String:
    if current_tree == null:
        return ""
    if companion_id == &"":
        companion_id = in_dialogue_companion_id
    # Check companion_overrides first
    if companion_id != &"" and "companion_overrides" in current_tree:
        var overrides: Variant = current_tree.get("companion_overrides")
        if overrides is Dictionary:
            var ov_dict: Dictionary = overrides
            if ov_dict.has(node_id):
                var per_companion: Variant = ov_dict[node_id]
                if per_companion is Dictionary:
                    var pc_dict: Dictionary = per_companion
                    if pc_dict.has(companion_id):
                        return String(pc_dict[companion_id])
    # Fall back to default node text
    var nodes: Dictionary = current_tree.get("nodes", {})
    if nodes.has(node_id):
        return String(nodes[node_id].get("text", ""))
    return ""

func _emit_current_node() -> void:
    if current_tree == null:
        return
    var nodes: Dictionary = current_tree.get("nodes")
    if not nodes.has(current_node_id):
        end_dialogue()
        return
    var node: Dictionary = nodes[current_node_id]
    var choices: Array = node.get("choices", [])
    # S7-005: apply companion_overrides to text if present
    var text: String = get_node_text(current_node_id, in_dialogue_companion_id)
    if text == "":
        text = String(node.get("text", ""))
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
    in_dialogue_companion_id = &""  # S7-005: reset companion on dialogue end
    var sm: Node = get_node("/root/GameStateMachine")
    sm.transition_to(&"state_exploration")
    dialogue_ended.emit()