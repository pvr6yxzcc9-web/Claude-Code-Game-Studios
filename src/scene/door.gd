extends Area2D
class_name Door

# Door — per level-dungeon.md
# Transitions player to another room on contact.
#
# Note: locked + required_key_id fields were removed in Sprint 4 cleanup.
# Rationale: with a 10-room linear maze + boss, key-gating is redundant
# friction — exploration is the gating mechanism, not inventory items.
# If lockable doors are reintroduced later (e.g., for optional side rooms),
# re-add the fields and gate on Inventory.count(id) > 0 here.

@export var target_room_path: String
@export var target_spawn: StringName = &"default"

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
    if not body is PlayerController:
        return
    get_tree().change_scene_to_file(target_room_path)
