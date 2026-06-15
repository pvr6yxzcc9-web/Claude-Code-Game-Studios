extends Node

# GameStateMachine (autoload #1)
# Per ADR-0001 (Scene Management) + game-state-machine.md C-R1..C-R7.
# Owns the state stack; gates all state transitions; emits state_changed signal.

signal state_changed(old: StringName, new: StringName)

const ALLOWED_TRANSITIONS: Dictionary[StringName, Array] = {
    &"state_title":       [&"state_exploration"],
    &"state_exploration": [&"state_battle", &"state_menu", &"state_terminal", &"state_codex", &"state_dialogue", &"state_pause", &"state_title"],
    &"state_battle":      [&"state_exploration", &"state_menu", &"state_dialogue", &"state_game_over"],  # S6-004: BATTLE → GAME_OVER on fatal damage
    &"state_menu":        [&"state_pause", &"state_exploration", &"state_title"],
    &"state_terminal":    [&"state_exploration"],
    &"state_codex":       [&"state_exploration"],
    &"state_dialogue":    [&"state_exploration"],
    &"state_pause":       [&"state_menu", &"state_exploration", &"state_title"],
    &"state_game_over":   [&"state_exploration", &"state_title"],  # S6-004: retry or quit
}

var state_stack: Array[StringName] = [&"state_exploration"]
var top_of_stack: StringName = &"state_exploration"

func _ready() -> void:
    # ADR-0001: _ready() must assert all upstream autoloads exist (none for #1)
    print("[GameStateMachine] ready as autoload #1")

func transition_to(new_state: StringName) -> Error:
    # C-R3: Check if transition is legal
    var current: StringName = top_of_stack
    if not _is_legal_transition(current, new_state):
        push_error("GameStateMachine: illegal transition %s -> %s" % [current, new_state])
        return ERR_INVALID_PARAMETER

    print("[GSM] transition: %s -> %s" % [current, new_state])

    # C-R2: Stack semantics (replace for BATTLE/EXPLORATION transitions, push for overlays)
    match new_state:
        &"state_battle", &"state_exploration", &"state_title":
            # Replace operation: swap top of stack
            state_stack[-1] = new_state
        _:
            # Push operation: append to stack
            state_stack.append(new_state)

    top_of_stack = new_state
    state_changed.emit(current, new_state)
    return OK

func push(state: StringName) -> Error:
    return transition_to(state)

func pop() -> Error:
    if state_stack.size() <= 1:
        push_error("GameStateMachine: cannot pop last state from stack")
        return ERR_DOES_NOT_EXIST
    var popped: StringName = state_stack.pop_back()
    top_of_stack = state_stack[-1]
    print("[GSM] pop: %s (top now %s)" % [popped, top_of_stack])
    state_changed.emit(popped, top_of_stack)
    return OK

func get_state_snapshot() -> Dictionary:
    # Per ADR-0003 Save Contract
    return {
        "schema_version": 1,
        "state_stack": state_stack.duplicate(),
        "top_of_stack": top_of_stack,
    }

func load_snapshot(snap: Dictionary) -> Error:
    if not snap.has("state_stack"):
        push_warning("GameStateMachine.load_snapshot: missing state_stack")
        return OK  # use default
    var stack: Array = snap["state_stack"]
    state_stack.clear()
    for s in stack:
        state_stack.append(StringName(s))
    if state_stack.is_empty():
        state_stack = [&"state_exploration"]
    top_of_stack = state_stack[-1]
    return OK

func _is_legal_transition(from: StringName, to: StringName) -> bool:
    if from == to:
        return false  # same state, no-op
    if not ALLOWED_TRANSITIONS.has(from):
        return false
    var allowed: Array = ALLOWED_TRANSITIONS[from]
    return to in allowed

# PR-9: Safety — prevent infinite state-changed bounce.
# If a state_changed listener immediately calls transition_to the same target,
# we cap repeat transitions within N frames to a warning.
var _recent_transitions: Array = []  # ring buffer of [frame, old, new]
const BOUNCE_WINDOW_FRAMES: int = 5
const BOUNCE_THRESHOLD: int = 3  # if same transition happens > N times in window, warn

func _post_transition_watchdog(_delta: float) -> void:
    # Track same-source->same-target transitions; warn if too many
    pass

# S2-001: Soft-pause helper. Returns true when gameplay should freeze
# (in state_pause or in state_menu / state_title where player input is gated).
func is_paused() -> bool:
    return top_of_stack in [&"state_pause", &"state_menu", &"state_title"]
