@tool
class_name DialogueTree
extends Resource

# DialogueTree (per npc-terminal.md)
# Node-based dialogue: each node has text + 1-3 choices leading to next node.
# Simplified MVP: choices are {label, next_node_id} pairs.
# Linear tree (no conditions yet) — PR-6 stub.

@export var id: StringName
@export var start_node_id: StringName = &"start"

# node_id -> {text, choices: [{label, next_node_id}]}
# Using a Dictionary for MVP simplicity (no custom Resource for nodes yet).
@export var nodes: Dictionary = {}
