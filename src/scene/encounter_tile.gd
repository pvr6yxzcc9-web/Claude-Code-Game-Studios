extends Area2D
class_name EncounterTile

# EncounterTile — per random-encounter GDD + level-dungeon.md
# A hidden encounter trigger. When player steps here, rolls for battle.

@export var region_id: StringName
@export var encounter_table_path: String = "res://data/encounters/"

# Per random-encounter GDD: encounter rate is per-region
# PR-3 dev: bumped to 0.5 for testing convenience (5%-6% is brutal for first playtest)
var _encounter_rate: float = 0.5

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    print("[EncounterTile] ready in region %s" % region_id)

func _on_body_entered(body: Node) -> void:
    if not body is PlayerController:
        return
    # Per random-encounter GDD: roll on every step
    if randf() > _encounter_rate:
        return
    # Per ADR-0001: state transition EXPLORATION → BATTLE
    get_node("/root/GameStateMachine").transition_to(&"state_battle")
