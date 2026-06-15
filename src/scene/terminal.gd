extends Area2D
class_name Terminal

# Terminal — per npc-terminal.md
# Interactable world object that opens a log-reading UI.

@export var terminal_log_ids: Array[StringName] = []  # list of TerminalLogData ids

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
        # Per ADR-0001: state transition EXPLORATION → TERMINAL
        get_node("/root/GameStateMachine").transition_to(&"state_terminal")
