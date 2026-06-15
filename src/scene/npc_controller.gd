extends Area2D
class_name NPCController

# NPCController — per npc-terminal.md
# Drives NPC behavior: in-range, talkable, optional merchant menu.

@export var npc_data_id: StringName  # ref to NPCData Resource via ResourceRegistry

var _player_in_range: bool = false

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
    if body is PlayerController:
        _player_in_range = true

func _on_body_exited(body: Node) -> void:
    if body is PlayerController:
        _player_in_range = false

func _unhandled_input(event: InputEvent) -> void:
    if not _player_in_range:
        return
    if event.is_action_pressed("interact"):
        var npc: Resource = get_node("/root/ResourceRegistry").get_resource(npc_data_id)
        if npc == null:
            push_warning("NPCController: npc %s not found" % npc_data_id)
            return
        # Per ADR-0008: dialogue_tree_id triggers dialogue system
        var dm: Node = get_node_or_null("/root/DialogueManager")
        if dm != null and dm.has_method("start_dialogue"):
            dm.start_dialogue(npc)
