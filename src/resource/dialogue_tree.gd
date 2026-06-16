@tool
class_name DialogueTree
extends Resource

# DialogueTree (per npc-terminal.md + party-system.md §3.9)
# Node-based dialogue: each node has text + 1-3 choices leading to next node.
# Simplified MVP: choices are {label, next_node_id} pairs.
# Linear tree (no conditions yet) — PR-6 stub.
# S7-005: companion_overrides allow a node's text to vary by in-dialogue
# companion (e.g., a scientist who knew 霜尾's mother says different lines
# when 霜尾 is in dialogue).

@export var id: StringName
@export var start_node_id: StringName = &"start"

# node_id -> {text, choices: [{label, next_node_id}]}
# Using a Dictionary for MVP simplicity (no custom Resource for nodes yet).
@export var nodes: Dictionary = {}

# S7-005: companion-specific text overrides.
# Shape: {node_id: {companion_id: text}}
# Example:
#   companion_overrides = {
#       &"node_5": {
#           &"frostbite": "Your mother was the only one who...",
#           &"ranger": "I don't really know you, but...",
#       }
#   }
# DialogueManager.get_node_text() checks this first before falling back
# to nodes[node_id].text.
@export var companion_overrides: Dictionary = {}

# Convenience: get text for a node, with optional companion override.
# Returns "" if the node_id does not exist.
func get_text(node_id: StringName, companion_id: StringName = &"") -> String:
	# Check companion_overrides first
	if companion_id != &"" and companion_overrides.has(node_id):
		var per_companion: Variant = companion_overrides[node_id]
		if per_companion is Dictionary:
			var pc_dict: Dictionary = per_companion
			if pc_dict.has(companion_id):
				return String(pc_dict[companion_id])
	# Fall back to default
	if nodes.has(node_id):
		return String(nodes[node_id].get("text", ""))
	return ""
