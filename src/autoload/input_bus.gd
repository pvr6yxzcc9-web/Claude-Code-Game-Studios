extends Node

# InputBus (autoload #2)
# Per ADR-0009 Input Binding + player-input.md C-R1..C-R8.
# Routes player input to subscribers based on current GameStateMachine state.
# Reads 49 actions from Godot InputMap (47 default Godot 4.6 + 2 custom: mech_cycle, toggle_mode).
# Emits action_pressed / action_released / action_held signals per ADR-0002.

signal action_pressed(action: StringName)
signal action_released(action: StringName)
signal action_held(action: StringName, duration: float)

const EXPECTED_ACTION_COUNT: int = 49

# Per-action hold timer (per ADR-0009 AC-3c)
var _press_start_times: Dictionary[StringName, float] = {}

# Subscribers per state (per ADR-0002 + player-input.md C-R4)
var _subscribers: Dictionary[StringName, Dictionary] = {}

# Mock clock for test injection (per ADR-0009 mock-clock DI)
var clock: Callable = func() -> float: return Time.get_ticks_msec() / 1000.0

func _ready() -> void:
    # ADR-0001: assert all upstream autoloads exist
    if get_node_or_null("/root/GameStateMachine") == null:
        push_error("InputBus: GameStateMachine must load before InputBus")
    set_process_input(true)
    set_process(true)
    print("[InputBus] ready as autoload #2")

func _process(_delta: float) -> void:
    var _sm: Node = get_node_or_null("/root/GameStateMachine")
    if _sm != null and _sm.is_paused():
        return
    # Hold timer: per ADR-0009, emit action_held every frame action is held
    var now: float = clock.call()
    for action in _press_start_times.keys():
        if Input.is_action_pressed(action):
            var duration: float = now - _press_start_times[action]
            action_held.emit(action, duration)

func _input(event: InputEvent) -> void:
    # Per ADR-0009, dispatch to all 47 actions
    var actions: Array[StringName] = InputMap.get_actions()
    for action in actions:
        if event.is_action_pressed(action):
            print("[InputBus] dispatching action=", action)
            if action not in _press_start_times:
                _press_start_times[action] = clock.call()
                _dispatch_to_subscribers(action, "pressed")
        elif event.is_action_released(action):
            if action in _press_start_times:
                _press_start_times.erase(action)
                _dispatch_to_subscribers(action, "released")

func _dispatch_to_subscribers(action: StringName, kind: StringName) -> void:
    # ADR-0002: dispatch via signals (cross-module pattern)
    var top: StringName = GameStateMachine.top_of_stack
    # PR-10: Always-dispatch actions (cross-state) — battle inputs work in both states
    var always_dispatch: Dictionary[StringName, bool] = {
        &"battle_attack_slot1": true,
        &"battle_attack_slot2": true,
        &"battle_attack_slot3": true,
        &"pause": true,
        &"toggle_mode": true,  # S4-007: M key works in any state
    }
    if not always_dispatch.get(action, false):
        if not _subscribers.has(top):
            return  # no subscribers in current state — silent
    # Per ADR-0002: signal is the only cross-module mechanism
    if kind == &"pressed":
        action_pressed.emit(action)
    elif kind == &"released":
        action_released.emit(action)

# Subscription API (per ADR-0002 + player-input.md C-R4)
func subscribe(state: StringName, callable: Callable) -> void:
    if not _subscribers.has(state):
        _subscribers[state] = {}
    _subscribers[state][callable.get_method()] = callable

func unsubscribe(state: StringName, callable: Callable) -> void:
    if _subscribers.has(state):
        _subscribers[state].erase(callable.get_method())

# Mock clock DI (per ADR-0009 mock-clock)
func set_clock(c: Callable) -> void:
    clock = c
