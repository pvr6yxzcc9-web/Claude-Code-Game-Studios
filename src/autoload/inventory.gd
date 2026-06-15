extends Node

# Inventory (per weapon-ammo.md + resource-data.md)
# Holds consumable items (healing, ammo packs, etc).
# Saved as part of SaveManager's snapshot (per ADR-0003 producer list).

signal item_added(item_id: StringName, count: int)
signal item_removed(item_id: StringName, count: int)

# item_id -> count
var items: Dictionary[StringName, int] = {}

func _ready() -> void:
    if get_node_or_null("/root/GameStateMachine") == null:
        push_error("Inventory: GameStateMachine must load first")
    print("[Inventory] ready")

func add(item_id: StringName, count: int = 1) -> void:
    if count <= 0:
        return
    items[item_id] = items.get(item_id, 0) + count
    item_added.emit(item_id, items[item_id])

func remove(item_id: StringName, count: int = 1) -> bool:
    if not items.has(item_id):
        return false
    if items[item_id] < count:
        return false
    items[item_id] -= count
    if items[item_id] <= 0:
        items.erase(item_id)
        item_removed.emit(item_id, 0)
    else:
        item_removed.emit(item_id, items[item_id])
    return true

func reset() -> void:
    # Wipe all items. Used by tests + debug console.
    items.clear()

func count(item_id: StringName) -> int:
    return items.get(item_id, 0)

func get_state_snapshot() -> Dictionary:
    return {
        "schema_version": 1,
        "items": items.duplicate(),
    }

func load_snapshot(snap: Dictionary) -> Error:
    if not snap.has("items"):
        return OK
    items.clear()
    for key in snap["items"].keys():
        items[StringName(key)] = int(snap["items"][key])
    return OK
