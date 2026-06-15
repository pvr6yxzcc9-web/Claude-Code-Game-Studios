extends Node

# TerminalController (per npc-terminal.md)
# Singleton-style manager for terminal log reading + fragment unlock.
# Actual UI is in TerminalUI scene; this handles state + signals.

signal terminal_opened(log: Resource)
signal terminal_closed()
signal fragment_unlocked_from_log(fragment_id: StringName)

var current_log: Resource = null
var is_open: bool = false

func _ready() -> void:
    print("[TerminalController] ready")

func open_log(log: Resource) -> void:
    if log == null:
        push_warning("TerminalController.open_log called with null")
        return
    current_log = log
    is_open = true
    # Per npc-terminal.md: reading a log may unlock a story fragment
    var frag_id_variant: Variant = log.get("unlock_fragment_id")
    if frag_id_variant != null and frag_id_variant != &"":
        var frag_id: StringName = StringName(frag_id_variant)
        var meta: Node = get_node("/root/MetaState")
        if not meta.is_unlocked(frag_id):
            meta.mark_unlocked(frag_id)
            fragment_unlocked_from_log.emit(frag_id)
    # Transition to state_terminal so TerminalUI (which gates visibility on
    # state_terminal per ui/terminal_ui.gd:57) actually displays the log.
    # Without this, open_log() emits terminal_opened and unlocks the
    # fragment, but the UI is invisible because the state machine is
    # still in state_exploration.
    var sm: Node = get_node_or_null("/root/GameStateMachine")
    if sm != null and sm.top_of_stack != &"state_terminal":
        sm.transition_to(&"state_terminal")
    terminal_opened.emit(log)

func close() -> void:
    is_open = false
    current_log = null
    terminal_closed.emit()
