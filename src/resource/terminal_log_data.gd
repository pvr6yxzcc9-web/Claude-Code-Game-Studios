@tool
class_name TerminalLogData
extends ImmutableResource

# TerminalLogData (per resource-data.md + ADR-0008)
# A log entry read from an in-world terminal. Flavored world-building.

@export var id: StringName
@export var title: String
@export var body: String
@export var author: String = ""
@export var date_in_world: String = ""
@export var unlock_fragment_id: StringName = &""  # optional story fragment
@export_range(1, 5) var importance: int = 1
