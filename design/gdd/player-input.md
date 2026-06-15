# 玩家输入 (Player Input)

> **Status**: Approved
> **Author**: user + game-designer + gameplay-programmer (feasibility)
> **Review Verdict**: APPROVED (post-revision 2026-06-12, lean re-review 2026-06-12)
> **Last Updated**: 2026-06-12 (lean re-review)
> **Last Verified**: 2026-06-12
> **Implements Pillar**: Pillar 1 (探索密度) + Pillar 3 (每次战斗都是 build 试验) + Pillar 4 (真相是收集的结果)

## Summary

Player Input is the Foundation-layer system that translates keyboard, mouse, and gamepad input into game-action signals consumed by combat, exploration, UI, and narrative systems. It defines the action map (input bindings), the event bus that broadcasts action events to listeners, and the focus routing rules that make UI navigable by both keyboard and gamepad. Players experience it as responsive controls: 1/2/3 weapon swap is one keypress, manual/auto mode toggle is one keypress, terminal log playback is one keypress, and the cursor is always where the player expects it to be.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None`（地基）· Depended on by: 战斗核心, 武器弹药, 关卡/迷宫, 暗雷遇敌, NPC, 门锁, HUD, 小地图, 菜单（**9 个系统**）

## Overview

**Player Input** is the Foundation-layer system that translates raw keyboard, mouse, and gamepad hardware events into the action signals consumed by every other system in the game. It defines three artifacts: an **InputMap** (the project's action dictionary — `move_up`, `attack_primary`, `weapon_slot_1`, `toggle_mode`, `pause`, etc., each bound to one or more physical inputs), an **InputBus** (a single event channel that broadcasts `InputActionEvent` signals to listeners and lets the active game state claim, ignore, or absorb actions before they propagate), and a **Focus Routing** layer (a `viewport.gui_focus_owner` chain that lets the keyboard and gamepad cursor walk through UI elements as if they were spatial targets). The game can be played end-to-end with keyboard and mouse alone; the gamepad is an **optional affordance** that covers movement and battle-menu navigation but is not required for terminal log playback, codex browsing, or the 1/2/3 weapon-slot hotkeys (these remain keyboard-only for MVP). Hard-coded bindings — no in-game rebinding. The system exists because every downstream system (combat, exploration, doors, NPC terminals, HUD) needs to ask one well-defined question ("did the player trigger action X?") rather than each one polling the hardware itself; without it, modal switching (Exploration → Battle → Menu) would force every system to know about every input device and every state boundary.

**Pillar alignment**: Pillar 1 (探索密度 — exploration input must never block on a modal or stutter on a state transition), Pillar 3 (每次战斗都是 build 试验 — 1/2/3 weapon-swap and manual/auto toggle are build-shape actions, not combat actions), Pillar 4 (真相是收集的结果 — terminal log playback is an input action that unlocks codex entries).

## Player Fantasy

**The fantasy of Player Input is the disappearance of the controller into the player's intent.**

When the player thinks "swap to missile launcher," the missile launcher is already in hand. When they think "auto mode," the mode indicator flips. When they think "what was that log I read two hours ago," the log appears. The keystroke, the key, the device — all of it is invisible. What remains is the player's intention, perfectly executed.

This is not "good game feel" in the abstract (that's Combat's fantasy). It is a more specific promise: **the system is a perfect translation layer between will and action**, with three concrete sub-promises.

1. **Predictability**. A key that worked once works the same way ten hours later, in every state, in every room, on every weapon. The player never has to ask "wait, does Tab do this here?" If the same key behaves differently in two states, that difference is visually obvious (e.g., the cursor is on a UI element, so SPACE means "confirm" instead of "interact").

2. **Latency as a feature, not a budget**. There is no perceptible delay between keypress and game response. We do not promise zero-latency (that is not realistic); we promise that any latency present is **frame-aligned and visually explained** — a hit-flash on attack input, a sound on mode toggle, a screen-ripple on pause. If a keypress takes 50ms, the player saw something happen in those 50ms.

3. **Modal transparency** (audited 2026-06-12, Blk #1 fix). The game is in some state (Exploration, Battle, Menu, Terminal, Codex, Paused). The player can always tell which one, and the same keypress never has a "secret" meaning in any state. Three concrete commitments:
   - **Persistent state badge** (top-left of HUD, always visible during gameplay and overlays). Shows the current top-of-stack state as text: `EXPLORATION` / `BATTLE` / `MENU` / `TERMINAL` / `CODEX` / `PAUSED`. In BATTLE, the MANUAL/AUTO sub-indicator sits adjacent to the badge.
   - **Audio cue on every state transition** (already specified; see Tuning Knobs F2).
   - **Visible refusal-with-hint** for two refusal categories:
     - *Context-blocked* (key bound in state but current context disallows, e.g. `interact` with nothing in range): 0.3s text hint near focused element + 100ms `input_refused` audio cue.
     - *Bound-elsewhere* (key has a binding in another state but not this one, e.g. `TAB` opening codex from BATTLE): 0.5s cross-state hint like `TAB opens codex — only in Exploration` + no audio cue (audio would be misleading).

**Reference games that nail this**:
- **Into the Breach** — every move is a one-click decision with zero input friction. The fantasy of "I am the strategist" is achieved partly through input clarity.
- **Outer Wilds** — controller disappears completely. Probe launcher, signalscope, translation gun — each has a distinct feel that comes from input design.
- **Into the Breach** (again, intentionally) — the manual/auto dual-mode is a direct inspiration for our mode-toggle input. In ItB, the toggle is instant and obvious; we mirror that.

**What this fantasy is NOT**:
- It is not "lots of options" — we are hard-coding bindings, no rebinding. The fantasy is **not** customization, it is **not** depth-of-configuration. It is predictability.
- It is not "innovation in input" — no motion controls, no touch, no voice. Keyboard/mouse + optional gamepad. Fantasy is restraint.
- It is not "forgiving" — a key that does nothing in a state should be ignored, not remapped. The fantasy is the absence of silent remapping.

**One player moment that anchors the fantasy**:
The player is in a boss battle. Their manual-mode tactics are failing. They hit the mode-toggle key. The HUD flips from MANUAL to AUTO. The cursor disappears. The mech executes the optimal play. The player watches, learns the pattern, and re-engages. **One keypress. Instant. The mode is always visible. The transition is always explained.** The player never has to think "did the game hear me?" — they heard themselves.

> **`creative-director` not consulted — Solo mode** (per `production/review-mode.txt`). Review manually before production. The fantasy above aligns with game pillars: Pillar 3 (the mode-toggle is the build-test mechanism) and Pillar 1 (no input friction means exploration flows).

## Detailed Design

### Core Rules

The system has **7 invariants**. Any implementation that violates one of them fails a design audit.

**C-R1 — One InputMap, no overlays.** The project has exactly one Godot `InputMap` resource. All actions are defined at the project level (`Project > Project Settings > Input Map`). The action set is closed: 47 actions total (see Tuning Knobs for the full list). Adding or removing an action is a GDD change, not an implementation choice.

**C-R2 — Action names use snake_case StringName, never strings.** Every action name in code is a `StringName` (e.g., `&"weapon_slot_1"`), not a `"weapon_slot_1"` string literal. This is a Godot 4.6 performance idiom (StringName is interned, comparison is pointer-equal). All hot paths (per-frame polling, per-event dispatch) must use StringName.

**C-R3 — InputBus is an autoload, not a singleton in code.** The class `InputBus` is registered in `Project > Autoload` as `InputBus`. It re-emits three signals for every actionable input:
- `action_pressed(action: StringName)` — fired once on the frame the action transitions from not-pressed to pressed
- `action_released(action: StringName)` — fired once on the frame the action transitions from pressed to not-pressed
- `action_held(action: StringName, duration: float)` — fired every frame the action is held, with the cumulative hold time in seconds (for charge attacks, hold-to-skip dialogue, etc.)

**action_held implementation** (audited 2026-06-12, Blk #3 fix): Godot's built-in `Input.is_action_pressed()` returns bool only — it does not return hold duration. The InputBus MUST maintain its own per-action timer:
```gdscript
var _press_start_times: Dictionary[StringName, float] = {}
func _ready() -> void:
    set_process(true)
func _process(_delta: float) -> void:
    for action in _press_start_times.keys():
        if Input.is_action_pressed(action):
            var duration: float = (Time.get_ticks_msec() / 1000.0) - _press_start_times[action]
            action_held.emit(action, duration)
func _input(event: InputEvent) -> void:
    for action in active_actions:
        if event.is_action_pressed(action):
            if action not in _press_start_times:
                _press_start_times[action] = Time.get_ticks_msec() / 1000.0
                action_pressed.emit(action)
        elif event.is_action_released(action):
            _press_start_times.erase(action)
            action_released.emit(action)
```
Consumers never call `Time.get_ticks_msec()` directly — they subscribe to `action_held`.

**C-R4 — State subscribers, not global polling.** Each game state (Exploration, Battle, Menu, Terminal, Codex, Pause) is a scene-tree node that subscribes to InputBus signals on `_enter_tree()` and unsubscribes on `_exit_tree()`. A state that doesn't subscribe receives no input — implicit rejection. This eliminates the need for "if state == X" guards in the bus itself.

**C-R5 — One action, one canonical handler per state.** A single action (e.g., `pause`) has exactly one handler method per state. If two systems in the same state both want to react to `pause`, they share a state-level dispatcher — they do not both subscribe to InputBus independently. This prevents double-handling (e.g., Menu opens AND HUD pauses the same frame).

**C-R6 — Focus owner is the single source of UI truth.** When a UI element has `focus_mode = FOCUS_ALL` and is the current `viewport.gui_focus_owner`, the SPACE / ENTER / GAMEPAD-A actions mean "confirm this element" — not the action's state-level meaning. The state-level handler checks `viewport.gui_focus_owner` and bails (re-emits as `action_pressed` to the UI element via the focus chain) if a focused element is consuming input.

**C-R7 — Hard-coded bindings, no runtime mutation.** Bindings are defined in the InputMap resource. There is no in-game rebinding UI, no save file for bindings, no per-player binding profile. The binding table is the same for every player in every playthrough. (See Open Questions for the deferral note on accessibility.)

### Action Inventory (47 actions, closed set)

Actions are grouped by domain. The exact binding is in Tuning Knobs.

| Domain | Count | Examples |
|---|---|---|
| **Exploration** | 8 | `move_up`, `move_down`, `move_left`, `move_right`, `interact`, `dash`, `open_codex`, `open_minimap` |
| **Battle — Combat** | 12 | `attack_primary`, `attack_secondary`, `use_item`, `defend`, `skip_turn`, `target_next`, `target_prev`, `cycle_weapons`, `confirm_target`, `cancel_target`, `flee_battle`, `pause` |
| **Battle — Build** | 4 | `weapon_slot_1`, `weapon_slot_2`, `weapon_slot_3`, `cycle_ammo` |
| **Battle — Mode** | 2 | `toggle_mode`, `toggle_auto_attack` |
| **Menu / UI** | 8 | `menu_up`, `menu_down`, `menu_left`, `menu_right`, `menu_confirm`, `menu_cancel`, `menu_tab_next`, `menu_tab_prev` |
| **Terminal / Codex** | 4 | `play_log`, `skip_log`, `codex_filter`, `codex_close` |
| **System** | 5 | `pause`, `quick_save`, `quick_load`, `screenshot`, `quit_to_title` |
| **Debug (dev build only)** | 4 | `debug_toggle_god`, `debug_warp`, `debug_fill_codex`, `debug_damage` |

> **Total: 8 + 12 + 4 + 2 + 8 + 4 + 5 + 4 = 47 actions.**
>
> **Action-count invariant**: the action count is a closed set. Adding an action requires updating this GDD and the Tuning Knobs table. Removing an action requires marking it deprecated in one release before deletion (so save data and codex entries referencing the action can be migrated). The Debug actions are stripped from release builds (compile-time `#if DEBUG`).

### States and Transitions

The game has 6 input-relevant states. The state stack is owned by `GameStateMachine` (a separate GDD). Player Input **does not own state transitions** — it only declares the input policy for each state.

| State | Input Owner | Action Set Active | State Badge Shown | Gamepad Covers |
|---|---|---|---|---|
| **Exploration** | `ExplorationState` scene | All Exploration + System + Debug | `EXPLORATION` | See G1 Gamepad Coverage matrix |
| **Battle** | `BattleState` scene | All Battle (Combat + Build + Mode) + System + Debug | `BATTLE` + adjacent MANUAL/AUTO sub-indicator | See G1 Gamepad Coverage matrix |
| **Menu** | `MenuState` scene (current top-level menu) | All Menu + System | `MENU` | See G1 Gamepad Coverage matrix |
| **Terminal** | `TerminalState` scene | Terminal + System | `TERMINAL` | See G1 Gamepad Coverage matrix |
| **Codex** | `CodexState` scene | Codex + System | `CODEX` | See G1 Gamepad Coverage matrix |
| **Pause** | Overlay on top of prior state | Menu + System | `PAUSED` (replaces prior state's badge while paused) | See G1 Gamepad Coverage matrix |

**State transitions are atomic**. When the GameStateMachine transitions Exploration → Battle, the following sequence happens in one frame:
1. ExplorationState subscribes all its handlers (`unsubscribe` on `_exit_tree()`)
2. BattleState subscribes all its handlers (`subscribe` on `_enter_tree()`)
3. The InputBus clears its `pressed_this_frame` queue (no carryover)
4. The HUD mode indicator updates

**Input refused feedback** (audited 2026-06-12, Blk #1 fix). Two distinct categories:

- **Context-blocked** (key bound in current state but current context disallows, e.g. `interact` with nothing in range, or `weapon_slot_2` with only 1 weapon equipped): state handler (1) plays the `input_refused` audio cue for 100ms, (2) shows a 0.3s text hint near the focused element, (3) does NOT flash the screen, shake the camera, or pause the action queue.
- **Bound-elsewhere** (key has a binding in another state but not this one, e.g. `TAB` opening codex from BATTLE): state handler (1) shows a 0.5s cross-state hint like `TAB opens codex — only in Exploration`, (2) does NOT play audio (audio would mislead), (3) does NOT pulse or otherwise draw excess attention.

Both categories emit a `signal: input_refused(action, category)` from InputBus for telemetry / debug.

**Modal overlays stack, not replace**. If Battle is paused, PauseState pushes on top — the underlying BattleState's `_input()` is gated by `get_tree().paused`, so it does not receive input while paused. When PauseState exits, BattleState resumes. The same applies to Menu opening from Exploration, Codex opening from Pause, etc. The rule: **a state higher in the stack consumes input; lower states are gated.**

### Interactions with Other Systems

**Player Input is consumed by 9 downstream systems** (per systems-index.md). This GDD defines only the **input contract** — the action names, the signal payload, the focus-routing rules. Each consuming system defines what it does with the input.

| Consumer | Actions it subscribes to | Signal | Payload expectations |
|---|---|---|---|
| **Battle Core** | All Battle (Combat + Build + Mode) | `action_pressed` | Battle dispatches to its own internal turn manager |
| **Weapon System** | `weapon_slot_1/2/3`, `cycle_weapons`, `cycle_ammo` | `action_pressed` | WeaponSystem queries `current_weapon_slots` from SaveState |
| **Level/Dungeon** | All Exploration | `action_pressed` | Movement actions polled via `Input.is_action_pressed` in `_physics_process` for movement (held continuously); one-shot actions via signal |
| **Encounter System** | (no direct input) | n/a | Encounter triggers from Level's movement, not from Player Input |
| **NPC / Terminal** | `interact` (Exploration), Terminal action set | `action_pressed` | NPC node subscribes when player is in range |
| **Doors/Locks** | `interact` (Exploration) | `action_pressed` | Door node subscribes when player is adjacent |
| **HUD** | (no direct input) | n/a | HUD displays state, doesn't consume input |
| **Minimap** | `open_minimap` | `action_pressed` | Toggles minimap visibility |
| **Menu / Pause** | Menu action set | `action_pressed` | MenuState owns the active menu node |

**Player Input depends on 1 upstream system**:
- **Resource/Data**: not directly. Player Input does not read or write any Resource. (This is correct — the action set is hard-coded, not data-driven.)
- **GameStateMachine**: indirectly. Player Input is gated by the current state but does not own the state stack. The state changes are owned by GameStateMachine.

**Player Input does not depend on any other system** — it is a true Foundation-layer system. The 47 actions are stable. Save/Load does not touch input (bindings are not saved). Settings does not touch input (no rebinding).

> **`gameplay-programmer` feasibility check — DEFERRED to /architecture-decision.** The patterns above (autoload InputBus, StringName action names, `_enter_tree` subscription) are idiomatic Godot 4.6 and consistent with the technical-preferences doc. The decision to use autoload vs. plain singleton is a technical choice that belongs in an ADR, not this GDD. **The first ADR for Player Input is `ADR-0006-player-input-architecture` (proposed by gameplay-programmer in /architecture-decision after this GDD is approved).**

## Formulas

Player Input has three formulas. None of them produce damage or economy values — they produce timing, feedback, and movement behavior.

### F1. Input Latency Budget

**Variables:**
- `target_frame_ms` = 16.6 (60 FPS frame budget, from technical-preferences.md)
- `input_to_handler_us` = microseconds from InputEvent arrival to `action_pressed` signal emit
- `handler_to_visual_ms` = milliseconds from signal receive to first visual change

**Formula:**
```
total_input_latency = input_to_handler_us / 1000 + handler_to_visual_ms
constraint: total_input_latency ≤ target_frame_ms
```

**Expected range:**
- `input_to_handler_us` ≤ 500 µs (autoload `Input.is_action_just_pressed` in `_process` is measured at ~200-400 µs on 4.6, per Godot profiler defaults)
- `handler_to_visual_ms` ≤ 16.0 ms (one full frame at 60 FPS, allowing a 0.6ms safety margin)
- `total_input_latency` ≤ 16.5 ms

**Example calculation:**
- Worst case: `400 µs / 1000 + 16.0 ms = 16.4 ms` ✓
- Best case: `200 µs / 1000 + 8.0 ms = 8.2 ms` (visual happens mid-frame)
- Failure case: `600 µs / 1000 + 16.0 ms = 16.6 ms` — at the budget edge; **not a hard fail** but a profiling trigger to optimize

**Profiling trigger**: If `input_to_handler_us` exceeds 500 µs on a release-build profile of a representative scene, the architecture is too chatty. The fix is to consolidate subscribers (C-R5) or batch signals. This is a continuous performance budget, not a one-time check.

### F2. Input Refused Feedback Duration

**Variables:**
- `t_hint` = duration of the on-screen hint (seconds)
- `t_audio` = duration of the audio cue (seconds)
- `t_min` = minimum perceivable feedback duration (seconds)

**Formula:**
```
t_hint = clamp(0.30, t_min, 0.50)  # always 0.30s, bounded to be perceivable but not nag
t_audio = 0.10  # the "input_refused" cue is 100ms by design
```

**Constants:**
- `t_min = 0.15` (anything shorter is imperceptible)
- `t_max = 0.50` (anything longer is nag feedback)
- `t_hint_default = 0.30`

**Example calculations:**
- `interact` pressed with no interactable: 0.30s hint ("nothing to interact with") + 100ms cue
- `weapon_slot_2` pressed with only 1 weapon: 0.30s hint ("no weapon in slot 2") + 100ms cue
- `pause` pressed while already paused: NO feedback (state-level rejection; the action has no observable effect to refuse)

**Edge case for the formula**: if the input is refused because the action is not bound in the current state at all, the feedback is `null` (no hint, no audio — the action is invisible). Only states where the action IS bound but context-blocked produce feedback. This distinction prevents feedback spam from key combinations that don't exist in the current state.

### F3. Dash i-frame and Cooldown

**Variables:**
- `dash_duration_frames` = number of frames the dash is active
- `dash_iframes` = number of frames during which collision and damage are disabled
- `dash_cooldown_ms` = milliseconds before another dash can be triggered

**Formula:**
```
dash_duration_frames = 8            # 8 frames at 60 FPS = 133ms
dash_iframes = 6                    # first 75% of dash duration
dash_cooldown_ms = 600              # 0.6s cooldown
```

**Constants:**
- `dash_iframe_ratio = 0.75` (75% of dash duration is i-frames, last 25% is recovery)

**Example calculations:**
- Total dash: 133ms (8 frames active)
- Invulnerable: 0 → 100ms (first 6 frames)
- Vulnerable recovery: 100ms → 133ms (last 2 frames)
- Cooldown: 600ms after the 8th frame ends → next dash possible at frame 45 (8 dash + 36 cooldown ≈ 750ms total cycle)

**Why these numbers**: 8 frames is the minimum perceptible "I moved a meaningful distance" — at 200 px/s player speed, 8 frames = 26.6 pixels. 6 i-frames covers 75% of the dash so the player can NEVER be hit during the visual apex of the dash but CAN be hit during the recovery frames (consequence for sloppy timing — communicates that dashes are not free escape). 600ms cooldown prevents dash-spam while remaining snappy enough for combat weaving (5+ dashes per encounter is possible but every dash is a commitment).

> **Formulas NOT in this GDD** (deferred to other GDDs):
> - Damage calculation → `damage-calc.md` (depends on Weapon & Ammo)
> - Crit rate, miss rate, status-effect duration → `battle-core-loop.md`
> - Hold-to-charge timing curves for `attack_primary` → `weapon-ammo.md`
> - Auto-mode AI decision latency → `enemy-ai.md`
>
> **This GDD only owns the math that Player Input itself produces**: timing, feedback, and movement. Anything that depends on combat values is owned by the combat GDDs.

## Edge Cases

Each case is named, states the trigger, the expected behavior, and which Core Rule (C-R) it depends on or extends.

### E1. Key held across state transition

**Trigger**: Player holds `move_right` in Exploration, then a random encounter triggers and the state transitions to Battle.

**Behavior**: On the transition frame, `action_pressed` for `move_right` is NOT re-fired (the action was already pressed, the transition does not constitute a new press). `action_held` continues to fire in Battle, but Battle does NOT have `move_right` in its action set, so the held signal has no consumer. The InputBus records the held state in `held_actions` for diagnostic purposes but does not synthesize a press.

**Player-visible result**: the character stops moving (Battle has its own camera and the player mech is centered). The `move_right` key is functionally inert in Battle.

**Rule extended**: C-R4 (state subscribers — the held state is observed, not blocked; the absence of a subscriber means no consumer).

### E2. Key pressed on the same frame as state transition

**Trigger**: Player presses `attack_primary` on the same frame Battle state activates.

**Behavior**: The InputBus processes events in scene-tree order. The transition unsubscribes Exploration handlers and subscribes Battle handlers. The `action_pressed` event for `attack_primary` is emitted AFTER the new handlers subscribe (because `_enter_tree` runs before `_process` in Godot 4.6). The press reaches Battle. This is a feature, not a bug — the player expects their input to "carry over" if they pressed it during a transition.

**Player-visible result**: the attack lands on the first frame of Battle.

**Rule extended** (audited 2026-06-12, Blk #3 fix): C-R4 + scene-tree lifecycle. Verified by Godot 4.6's `_enter_tree → _process` ordering. **Required autoload order**: the `InputBus` autoload MUST be listed AFTER the `GameStateMachine` autoload in `Project > Autoload`, so that the InputBus's `_process(delta)` runs AFTER any state transition triggered during the same frame. This guarantees the new state's handlers (which subscribe on `_enter_tree`) are connected before InputBus re-dispatches pending input. **No** `force_dispatch_pending()` call exists in Godot 4.x — do not invent one. If a regression is observed, the fix is to verify autoload order, not to re-buffer the input.

### E3. Controller hot-swap mid-battle

**Trigger**: Player's gamepad battery dies mid-battle. Player picks up a second gamepad.

**Behavior**: Godot 4.6's SDL3 gamepad backend (4.5+) supports device hot-swap. The InputMap re-resolves the binding to the new device ID. The `InputBus` does not need to know — the InputMap handles device rebinding transparently. Battle continues. The HUD's gamepad indicator (if shown) updates to the new device ID.

**Player-visible result**: no interruption. Battle proceeds.

**Rule extended**: C-R3 (InputBus reads from InputMap; device changes are InputMap's responsibility).

### E4. Mouse leaves the game window

**Trigger**: Player moves the cursor outside the game window during Exploration.

**Behavior**: The game window loses OS-level mouse capture. The cursor is still rendered at its last known position (clamped to the window edge) but `Input.is_action_pressed` for mouse-bound actions (e.g., LMB) returns false. When the cursor re-enters the window, the position is the entry point, not the last known position.

**Player-visible result**: clicking outside the window does nothing. Re-entering the window and clicking works normally. No cursor "snap-back" or visual indicator.

**Rule extended**: OS behavior, not Player Input's policy. Documented so QA knows the expected behavior.

### E5. Focus loss to OS (alt-tab, notification)

**Trigger**: Player alt-tabs during Exploration.

**Behavior**: The game window loses focus. `Input.is_action_pressed` returns false for ALL actions (the window doesn't receive input). The `not focused` state is detected by `Notification.WM_WINDOW_FOCUS_OUT` in the GameStateMachine, which auto-pauses the game (matches the "auto-pause on focus loss" convention from the game concept). When the window regains focus (`WM_WINDOW_FOCUS_IN`), the game un-pauses.

**Player-visible result**: alt-tab pauses the game. Returning resumes. No input is dropped (all `action_pressed` events that occurred during focus loss are discarded; none are buffered for re-dispatch).

**Rule extended**: cross-system (GameStateMachine owns the auto-pause policy; Player Input just observes the focus state).

### E6. Modifier keys (Ctrl, Shift, Alt) held

**Trigger**: Player holds Shift while pressing other keys.

**Behavior**: The default Godot 4.6 InputMap does NOT distinguish "shift+W" from "W" unless the action is explicitly bound to the combo. The 47-action closed set does NOT include any combo bindings — all actions are bare keypresses or mouse clicks. Holding a modifier does nothing in itself. If a future GDD adds a "sprint" action, it will be a separate `sprint` action with its own binding, not a Shift-modifier.

**Player-visible result**: Shift held = nothing observable. No input is dropped, no actions are blocked.

**Rule extended**: C-R1 (closed action set). Combo bindings are explicitly OUT of scope for MVP.

### E7. Simultaneous keypress on conflicting actions

**Trigger**: Player presses both `attack_primary` and `attack_secondary` on the same frame.

**Behavior**: Both `action_pressed` signals fire in the same frame. The order is determined by the InputMap's `InputEvent` ordering (alphabetical by action name as a stable tiebreaker). Battle's turn manager receives both and decides what to do — typically, `attack_secondary` is the override (in our design, secondary is the "aimed shot" that consumes the turn, while primary is the "fast shot" that also consumes the turn; the player shouldn't be allowed both, but the engine will dispatch both signals, and the battle logic will consume the first turn-ending action and ignore the second within the same frame).

**Player-visible result**: one attack lands. The second input is absorbed (no refused feedback, no error — the input was valid, just redundant within a single turn).

**Rule extended**: cross-system. Battle's turn manager owns the conflict resolution; Player Input just dispatches both signals.

### E8. Pause pressed while dashing

**Trigger**: Player is in frame 4 of an 8-frame dash, presses `pause`.

**Behavior**: PauseState is pushed on top. The GameStateMachine calls `get_tree().paused = true`. The dash animation continues (animation is `_process`-based and respects pause by default; if the dash logic is in `_physics_process` and the dash is non-pausable, this is a bug to fix in the dash logic, not in Player Input). The InputBus stops dispatching to Battle's subscribers. When the player un-pauses, the dash resumes from where it was paused. The dash cooldown timer also pauses (cooldown is `time-based` and respects `get_tree().paused`).

**Player-visible result**: the game pauses cleanly. The dash is "frozen" mid-animation. Un-pause continues. No input is lost.

**Rule extended**: cross-system (GameStateMachine owns the pause). Player Input just stops dispatching while the tree is paused.

### E9. Subscription lifetime + state pooling (audited 2026-06-12, Rec #7)

**Trigger**: A state node is removed via `queue_free()` (e.g. Battle is dismissed after victory) and the next encounter instantiates a new Battle state.

**Behavior**: InputBus signal connections are **weak references** to Callable targets (Godot 4.6 idiom). When the old state is freed, its connections silently break — no double-connection, no stale-handler crash. The GameStateMachine is the **single point of subscription**: it calls `state.subscribe_to_input_bus(bus)` after the new state is added to the tree, and `state.unsubscribe_from_input_bus(bus)` before the old state is removed. **Required**: each state exposes `subscribe_to_input_bus(bus: InputBus)` and `unsubscribe_from_input_bus(bus: InputBus)` methods (not `_enter_tree`/`_exit_tree` magic, because pooled states re-instantiate and the explicit API is auditable).

**Player-visible result**: no observable difference. The contract holds across pooled state lifetimes.

**Rule extended**: C-R4 explicit API (replaces `_enter_tree`/`_exit_tree` auto-subscription).

### E10. Held-preserved on state transition (audited 2026-06-12, Rec #10)

**Trigger**: Player holds `move_right` while moving; on the same frame, an encounter triggers (Exploration → Battle transition).

**Behavior**:
- **Pressed (just-pressed-this-frame)**: preserved per current behavior. The InputBus dispatches the press to the new state on the same frame.
- **Held (already-pressed-before-transition)**: preserved. The InputBus, on detecting a state transition, snapshots the `is_action_pressed` set, replays it to the new state as `_process`'s first action, then clears the snapshot. The new state may use the held information (e.g. an emergency-mech-pivot animation) or ignore it.
- **Symmetric rule**: every input the player thought they gave at frame N-1 is honored at frame N.

**Player-visible result**: the new state has a 1-frame window to acknowledge held keys. No "I was holding the stick but the battle ignored me" complaint.

**Rule extended**: C-R3 + C-R4. Implementation lives in InputBus's transition handler.

### E11. Refusal fatigue escalation (audited 2026-06-12, Rec #8)

**Trigger**: Player spams `TAB` from BATTLE 6 times in 30 seconds (TAB opens codex, but only in Exploration).

**Behavior**: InputBus maintains `Dictionary[StringName, int] _refusal_count_session`. On the 4th identical refusal within 60s, the audio cue is suppressed. Escalation levels:
- **Level 0** (1st-2nd identical refusal): 0.3s hint + 100ms audio (default).
- **Level 1** (3rd): 0.5s longer hint, no audio.
- **Level 2** (4th-5th): 0.3s hint, subtle 0.1x opacity.
- **Level 3** (6+): subtle visual flicker only, no audio, no text.

`Formula: t_escalation = clamp(refusal_count_session[action] * 0.10, 0.0, 0.50)` (the formula contributes to a per-action escalation weight; the level thresholds are constants).

**Player-visible result**: the player gets quieter feedback as they keep pressing the wrong thing — they're not nagged, but they know the press was registered.

**Rule extended**: G-F4 (acknowledgment is universal) is preserved at L0/L1; gracefully degrades at L2/L3 to prevent fatigue.

> **Edges NOT in this GDD** (deferred to other GDDs or to runtime):
> - **Auto-mode AI timeout** → `enemy-ai.md`
> - **Hold-to-charge weapon** → `weapon-ammo.md`
> - **Save-during-dash corruption** → `save-load.md` (verified by save integrity test)
> - **Networked input lag** → N/A (single-player game, per game concept)
> - **Touchscreen gestures** → explicitly out of scope (per technical-preferences.md: "Touch Support: None")

## Dependencies

### Upstream: what Player Input depends on

| System | Type | Contract |
|---|---|---|
| **Godot 4.6 InputMap** | Engine API | All 47 actions defined in the project-level InputMap resource. The InputBus reads from this. |
| **Godot 4.6 StringName** | Engine API | All action names in code use `&"action_name"` syntax. |
| **Godot 4.6 Autoload** | Engine API | `InputBus` is registered in `Project > Autoload`. The autoload name `InputBus` is reserved. |

**Player Input has no other game-system dependencies.** It is a true Foundation-layer system. The 47-action set is stable; Save/Load does not touch input (bindings are not saved); Settings does not touch input (no rebinding).

### Downstream: what depends on Player Input (9 systems)

The contract for each consumer is the action names they subscribe to and the signal payload expectations. The contract is **stable** — once a consumer GDD references an action name, that name is locked.

| # | Consumer | Action contract | GDD status | Bidirectional note |
|---|---|---|---|---|
| 1 | **Battle Core Loop** | All 16 Battle actions (Combat + Build + Mode) | Not Started | When authored, must list "subscribes to: 玩家输入" and list the 16 action names verbatim |
| 2 | **Weapon & Ammo System** | `weapon_slot_1/2/3`, `cycle_weapons`, `cycle_ammo` | Not Started | Must list "subscribes to: 玩家输入" with the 5 action names |
| 3 | **Level / Dungeon** | All 8 Exploration actions | Not Started | Must list "subscribes to: 玩家输入" with the 8 action names |
| 4 | **Encounter System** | (no direct input) | Not Started | Listed in case future design adds an "ambush" trigger; currently NULL contract |
| 5 | **NPC / Terminal** | `interact`, plus 4 Terminal actions | Not Started | Must list "subscribes to: 玩家输入" with the 5 action names |
| 6 | **Doors / Locks** | `interact` | Not Started | Must list "subscribes to: 玩家输入" with the 1 action name |
| 7 | **HUD** | (no direct input) | Not Started | HUD displays state only; no input contract. Must list "depends on: 玩家输入 (read-only — for mode indicator update signal)" |
| 8 | **Minimap** | `open_minimap` | Not Started | Must list "subscribes to: 玩家输入" with the 1 action name |
| 9 | **Menu / Pause** | 8 Menu actions + `pause` | Not Started | Must list "subscribes to: 玩家输入" with the 9 action names |

### Cross-system contracts (future, not blocking)

| System | What it needs from us | What we need from it |
|---|---|---|
| **Game State Machine** | A single signal `mode_changed(new_mode: StringName)` from InputBus to inform subscribers of state transitions | The state stack — Player Input dispatches based on the current top-of-stack state |
| **Save / Load** | (no contract — bindings are not saved) | Save format includes `bindings_version: int` so future GDD changes can detect stale saves |
| **Settings** | (no contract — no rebinding for MVP) | (no contract) |
| **Resource / Data** | (no contract — actions are not data-driven) | (no contract) |

### Dependency layer position

Player Input sits at **Layer 1: Foundation** in the 5-layer dependency model (Foundation → Core → Feature → Presentation → Polish). It is the **only system in the Foundation layer that the Core layer (Battle Core Loop) directly depends on** alongside Resource/Data. The 4 other Foundation systems (Game State, Camera, Collision) are also Layer 1, but Player Input is unique in that it is the only one that the player interacts with directly during gameplay.

> **Open question deferred to ADR**: the choice of autoload vs. plain singleton for `InputBus` is technical and will be decided in `ADR-0006-player-input-architecture` (proposed in /architecture-decision). This GDD specifies the contract (signal names, payload types, subscription pattern) — the implementation pattern is the ADR's domain.

## Tuning Knobs

Player Input has three categories of tuning knobs: **action bindings** (47), **timing constants** (8), and **focus chain config** (3).

### G1. Action Bindings (47 actions, closed set)

The full binding table is in `design/registry/input-bindings.yaml` (created in Phase 5 alongside the entity registry). The GDD holds the action names + domain + a representative binding summary.

**Summary table (per domain):**

| Domain | Count | Keyboard primary | Gamepad | Refused-feedback hint |
|---|---|---|---|---|
| **Exploration** | 8 | WASD + E (interact) + Shift (dash) + Tab (codex) + M (minimap) | D-pad/left stick + A (interact) + B (dash) + Y (codex) + View (minimap) | "no interactable in range" / "codex locked" |
| **Battle — Combat** | 12 | J (attack) + K (skill) + I (item) + L (defend) + Space (skip) + arrow keys (target) + Esc (cancel) + Shift+Esc (flee) | A (attack) + X (skill) + Y (item) + B (defend) + Start (menu/pause) | "no target" / "no item" / "cannot flee" |
| **Battle — Build** | 4 | 1 / 2 / 3 (weapon slots) + Q (cycle weapons) + R (cycle ammo) | D-pad up/down (cycle weapons) — **no 1/2/3 binding** | "no weapon in slot 2" / "no ammo compatible" |
| **Battle — Mode** | 2 | T (toggle mode) + Backslash (toggle auto-attack) | Select (toggle mode) — **no auto-attack binding** | "auto-mode already on" |
| **Menu / UI** | 8 | Arrow keys + Enter + Esc + Tab | D-pad + A + B + shoulder buttons | "no menu open" |
| **Terminal / Codex** | 4 | Space (play/skip) + F (filter) + Esc (close) | **No gamepad binding** | "no log to play" |
| **System** | 5 | Q (pause_battle) + F5 (save) + F9 (load) + F12 (screenshot) + Ctrl+Q (quit) | Start (pause) — **no save/load binding on gamepad for MVP** | n/a (system actions always valid) |
| **Debug** | 4 | F1-F4 (dev build only) | **No gamepad binding** | n/a |

**Binding change note** (audited 2026-06-12, Blk #1 fix): `Esc` is now bound to **`cancel_target`** (Battle combat cluster) only. The Battle-mode `pause` action (renamed `pause_battle`) moved to **`Q`** with a 0.5s hold-to-confirm to prevent accidental pause during combat. Keyboard `Q` (cycle weapons) was reassigned to `Shift+Q` in Battle; `Q` (no modifier) is now pause_battle. Gamepad `pause_battle` moved from `GAMEPAD_BUTTON_START` to `GAMEPAD_BUTTON_BACK` with 0.5s hold. The exploration-mode `pause` action remains on `Esc` (no hold-to-confirm — exploration pause is non-destructive).

**Gamepad coverage** (audited 2026-06-12, Blk #4 fix — honest per-action matrix):

| Action | Gamepad bound? | Scope |
|---|---|---|
| `move_up` / `move_down` / `move_left` / `move_right` | ✅ Yes | D-pad + left stick (with `analog_deadzone: 0.20`) |
| `dash`, `interact`, `open_codex`, `open_minimap` | ✅ Yes | A / B / Y / View |
| `attack_primary`, `attack_secondary`, `use_item`, `defend` | ✅ Yes | A / X / Y / B (with shift modifier for secondary) |
| `target_next`, `target_prev` | ✅ Yes | D-pad right / left |
| `confirm_target`, `cancel_target` | ✅ Yes | A / B |
| `weapon_slot_1`, `weapon_slot_3` | ✅ Yes | D-pad left / right |
| `weapon_slot_2` | ❌ No | Code-bound but UI-true (the 1/2/3 keyboard row has no gamepad equivalent) |
| `cycle_weapons`, `cycle_ammo` | ✅ Yes | D-pad up/down + right shoulder |
| `toggle_mode` | ✅ Yes | Select+Start hold (0.5s) |
| `toggle_auto_attack` | ❌ No | Code-bound; no gamepad UX for MVP |
| `flee_battle`, `skip_turn`, `pause_battle` | ✅ Yes | D-pad down / Select / Back (0.5s hold) |
| All Menu actions (8) | ✅ Yes | D-pad + A/B + shoulders |
| Terminal/Codex actions (4) | ❌ No | Keyboard-only by design |
| System: `quick_save`, `quick_load`, `screenshot`, `quit_to_title` | ❌ No | Keyboard-only for MVP |
| Debug actions (4) | ❌ No | Keyboard-only |

**Honest coverage summary**: Gamepad covers movement + battle menu (combat + build + mode) per user-approved scope. **Not** full parity. Code-bound actions have stubs that emit `input_refused` on gamepad (the player is told "this action is keyboard-only" via the refused-feedback path).

**Knob effect:** Every key in this table is a tuning knob. Changing a binding requires updating both the GDD summary AND `input-bindings.yaml`. Adding a NEW action requires updating the 47-count invariant.

**Safe range:** bindings can be changed freely (the closed set is the contract, not the specific keys). The "safe range" constraint is **layout consistency** — WASD must stay on movement, QWERTY skill-keys must stay on the left hand, etc. A binding that forces the player to use the same key for move and attack is a binding-collision bug (see G3).

### G2. Timing Constants

| Constant | Value | Safe range | Effect | Source |
|---|---|---|---|---|
| `target_frame_ms` | 16.6 | 16.6 (60 FPS only) | Hard frame budget | F1 |
| `input_to_handler_us_max` | 500 | 200-500 | Profiling trigger | F1 |
| `t_hint_default` | 0.30 | 0.15-0.50 | Refused-feedback duration | F2 |
| `t_audio_refused` | 0.10 | 0.08-0.15 | Refused-feedback audio length | F2 |
| `dash_duration_frames` | 8 | 6-12 | Dash active window | F3 |
| `dash_iframes` | 6 | 4-10 | Dash i-frame count | F3 |
| `dash_cooldown_ms` | 600 | 400-1000 | Dash cooldown | F3 |
| `dash_iframe_ratio` | 0.75 | 0.50-0.90 | I-frame % of dash | F3 (derived) |

**Safe-range rule:** changing a value outside the safe range requires a GDD revision. The ranges are tight on purpose — Player Input is a Foundation system; downstream GDDs that depend on `dash_iframes = 6` would break if this changed silently.

### G3. Focus Chain Configuration

| Knob | Value | Effect | GDD section |
|---|---|---|---|
| `default_focus_neighbor` | `NodePath` to first focusable element | Where focus starts when a menu opens | UI Requirements |
| `focus_wrap` | `true` | D-pad wraps from last element to first | UI Requirements |
| `focus_visual_focus_style` | `pulse` (default), `outline`, `glow` | How the focused element is highlighted | Visual/Audio |

**Safe range:** these are visual / feel knobs. Default values are recommended; players who dislike the pulse can switch to outline or glow in Settings. (Settings menu is a separate GDD; this is a read-only reference.)

## Visual/Audio Requirements

| # | Trigger | Visual | Audio | Source |
|---|---|---|---|---|
| 1 | `action_pressed` (any) — the player's intent reaches the system | Brief 1-frame white-flash on the HUD mode indicator (subtle, 30% alpha) | None — silent confirmation (audio on every press would be cacophonous) | Fantasy §2 |
| 2 | `toggle_mode` pressed | HUD mode indicator flips (MANUAL ↔ AUTO) with a 0.15s scale-pulse animation | Distinctive "click" cue (50ms, mid-frequency) | Fantasy §1 |
| 3 | `weapon_slot_1/2/3` pressed | HUD weapon slot icon highlights; previous slot dims over 0.1s | "slot swap" cue (40ms, low-mid) | Fantasy §1 |
| 4 | Input refused (F2) | 0.3s UI hint near focused element: e.g., "no weapon in slot 2" | "input_refused" cue (100ms, low-frequency buzz) | F2 |
| 5 | Focus moves (D-pad/arrow) on UI element | Focused element: pulse animation (1.0x → 1.05x scale, 0.2s) + outline | None — silent navigation (audio on every focus change is too chatty) | G3 |
| 6 | `pause` pressed (Pause state opens) | Screen ripple + 0.4s desaturation to grayscale | "pause" cue (150ms, low-frequency) | E8 |
| 7 | State transition (any) | Mode indicator updates in HUD | Soft "transition" cue (80ms) | C-R4 |
| 8 | Dash (F3) | Trail of 3-fade sprites for 8 frames | "whoosh" cue synced to dash start | F3 |

**Visual style source**: all visuals align with the art bible's "深空废墟中孤独的霓虹" anchor. Refused-feedback hints are typed in the established monospace text style. No new visual primitives are introduced — these all use existing HUD/scene-graph assets.

**Audio source**: audio cues are placeholders pending the Audio GDD (currently in "Not Started" state per systems-index.md). The 8 cues listed are contract — the actual sound design is the audio director's domain.

## Game Feel

The Fantasy (Section B) is "the controller disappears into the player's intent." Game Feel is the technical implementation of that fantasy.

**G-F1 — Latency is invisible by default, visible by design.** Total input-to-visual latency is held under 16.5ms (F1) for the 99th percentile of inputs. Latency that exceeds 1 frame (16.6ms) is always paired with a visual cue so the player perceives the latency as intentional ("a slow hit-flash") rather than buggy ("a missed input").

**G-F2 — Frame-aligned, not sample-aligned.** All input handling is `_process` or `_physics_process` — never `_input` direct. This guarantees one input read per frame and eliminates the "1ms early, 1ms late" jitter that can make controls feel imprecise.

**G-F3 — No input stutter on scene transitions.** State transitions are atomic (C-R4) — no frame where input is in a "limbo" state. The player either sees the old state's response (within the same frame) or the new state's response (next frame). Never neither.

**G-F4 — Acknowledgment is universal.** Every keypress gets SOME visual response. Either the action lands (audio cue + visual change) or the action is refused (refused cue + UI hint). There is no "silent keypress" — the player never wonders "did the game hear me?"

**G-F5 — Hold-to-skip is always available.** `play_log` and `menu_confirm` both support hold-to-skip. Holding for 1.5 seconds advances the action as if it were repeated. This prevents the "I'm holding the key but nothing's happening" feeling during dialogue or menus.

## UI Requirements

**UI-1 — Focus chain is visible.** When a menu opens, the first focusable element receives `viewport.gui_focus_owner` immediately (no animation, no delay). The focused element displays a visible focus highlight (pulse animation, G3 default).

**UI-2 — Mode indicator is always on screen.** The HUD mode indicator (MANUAL / AUTO) is in the top-left corner of the screen at all times during Battle. It is NEVER hidden by a fullscreen UI overlay (it sits above the CanvasLayer). When the mode changes, the indicator animates (0.15s scale-pulse, H-2).

**UI-2b — State badge is always on screen** (audited 2026-06-12, Blk #1 fix). The state badge (top-left, adjacent to the MANUAL/AUTO mode indicator when in BATTLE) displays the current top-of-stack state as text. Font: art-bible HUD font, weight semibold, color per art-bible "deep-space neon" palette. The badge updates within 1 frame of a state transition. The badge is NEVER hidden by any overlay.

**UI-3 — Refused feedback is positioned contextually.** The refused-hint appears 24px below the focused element (or, in Battle, below the HUD mode indicator for action-refused). It does not appear at a fixed screen position — the player should see the hint relative to the action that was refused.

**UI-4 — Gamepad indicator (subtle).** When the player uses a gamepad, a small icon (12x12px) appears next to the mode indicator showing the active gamepad device. When the player switches to keyboard, the icon fades out over 0.5s. This is a "you're on gamepad" affordance, not a tutorial.

**UI-5 — Menu navigation is exhaustive.** Every menu in the game can be navigated entirely with D-pad/arrow keys + A/Enter. Mouse-only menus are forbidden. The focus chain must include every actionable element.

**UI-6 — Tooltips follow focus, not hover.** Tooltips appear 0.5s after an element receives focus (not on mouse hover). This is consistent with the "controller disappears" fantasy — the player doesn't need to reach for the mouse to learn what a button does.

## Cross-References

### Upstream system GDDs (read by Player Input)

| GDD | Status | What Player Input reads |
|---|---|---|
| `design/gdd/resource-data.md` | **Approved 2026-06-12** | (nothing — Player Input does not consume Resource data) |

Player Input has **no functional dependency on any approved GDD**. This is intentional: Foundation-layer systems are independent of each other in the design, even if they coexist in the codebase.

### Downstream system GDDs (will read Player Input)

| GDD | Status (per systems-index.md) | What it will read from Player Input |
|---|---|---|
| `design/gdd/battle-core-loop.md` | Not Started (planned) | The 16 Battle actions, signal payload, focus-routing rules for the action menu |
| `design/gdd/weapon-ammo.md` | Not Started (planned) | The 5 Build actions (`weapon_slot_1/2/3`, `cycle_weapons`, `cycle_ammo`) |
| `design/gdd/level-dungeon.md` | Not Started (planned) | The 8 Exploration actions, especially `move_*` and `interact` |
| `design/gdd/encounter.md` | Not Started (planned) | (none — no direct input contract) |
| `design/gdd/npc-terminal.md` | Not Started (planned) | The 1 Exploration action (`interact`) + 4 Terminal actions |
| `design/gdd/doors-locks.md` | Not Started (planned) | The 1 Exploration action (`interact`) |
| `design/gdd/hud.md` | Not Started (planned) | The mode-indicator update signal (read-only) |
| `design/gdd/minimap.md` | Not Started (planned) | The 1 action `open_minimap` |
| `design/gdd/menu-pause.md` | Not Started (planned) | The 8 Menu actions + `pause` |

### Adjacent documents (not GDDs, but read for context)

- `design/gdd/game-concept.md` — game concept, pillars, references (Into the Breach, Outer Wilds)
- `design/art/art-bible.md` — "深空废墟中孤独的霓虹" visual anchor; monospace text style for refused hints
- `design/registry/entities.yaml` — no Player Input entries yet (created in Phase 5)
- `design/registry/input-bindings.yaml` — **TO BE CREATED** in Phase 5 (action bindings)
- `.claude/docs/technical-preferences.md` — Godot 4.6, 60 FPS, GDScript/C# mix, no touch
- `docs/engine-reference/godot/VERSION.md` — Godot 4.6 (post-cutoff, HIGH RISK version)
- `docs/engine-reference/godot/modules/input.md` — engine reference for Input system (referenced in /architecture-decision)

### Future ADRs that will reference this GDD

- `ADR-0006-player-input-architecture` — to be created in /architecture-decision (InputBus autoload vs. singleton, dispatch pattern)

## Acceptance Criteria

Each AC is a **contract assertion** (audited 2026-06-12, Blk #2 fix): describes what a player or QA tester can observe, not which API or function name. Format: `AC-N: [observable behavior]`. The "Test method" column tells QA how to verify. **Each AC must be independently verifiable by someone who has not read the GDD.**

| # | AC | Test method | Source |
|---|---|---|---|
| **AC-1** | The InputMap contains exactly **47 actions in dev build** and **43 actions in release build** (the 4 Debug actions are stripped) | Run a linter script that reads `project.godot` for dev build and the stripped release build; assert counts 47 / 43. | C-R1, Rec #6 |
| **AC-2** | Every action name referenced in code is type-stable (the GDScript compiler treats it as `StringName`); no `String` literal matches exist in hot paths | Run `rg '"[a-z_]+_[a-z_]+"' src/input` and assert zero matches in `_input()` / `_physics_process()` paths. | C-R2 |
| **AC-3a** | A key press produces `action_pressed` signal **exactly once** on the press-transition frame (not before, not after, not twice) | Boot, press `weapon_slot_1` for 50ms, release, count `action_pressed` emissions; assert == 1. | C-R3 |
| **AC-3b** | A key release produces `action_released` signal **exactly once** on the release-transition frame | Boot, press then release `weapon_slot_1`; count `action_released` emissions; assert == 1. | C-R3 |
| **AC-3c** | A held key produces `action_held(action, duration)` signal **every frame** with **strictly increasing duration** | Boot, hold `dash` for 5 frames; observe `action_held` emissions; assert (a) emitted every frame, (b) durations form a strictly increasing sequence, (c) last duration ≈ 83ms (5 frames × 16.6ms). | C-R3, Rec #5 |
| **AC-4** | A subscriber in a non-active state receives zero input emissions for actions not in its action set | Boot, place a debug subscriber in Menu state (active state: Exploration), press `move_right` (Exploration action); assert the Menu subscriber's callback was not invoked. | C-R4 |
| **AC-5** | A single press of an action in a single state produces exactly one observable game response (no double-handling, no dropped events) | Press `pause` from Exploration 100 times; assert the pause menu opened exactly 100 times (or 100 close+open cycles, but no doubled events). | C-R5 |
| **AC-6** | A focused UI element intercepts SPACE / ENTER / GAMEPAD-A; the same key does NOT fire its state-level handler | Open a menu with a focused button, press SPACE, assert the button's `pressed` signal fires AND the state-level `confirm_target` was NOT called. | C-R6 |
| **AC-7** | Bindings cannot be changed at runtime — there is no in-game rebinding UI or save-file-driven rebinding | Search the codebase for any API that mutates `InputMap`; assert no such API exists outside the editor. | C-R7 |
| **AC-8** | Total input-to-visual latency is **p99 ≤ 16.5ms (hard ceiling, frame-aligned)** and **median ≤ 33ms (perception threshold, 2 frames)** | Profile a representative battle scene with 1000 input events; measure input-to-handler + handler-to-visual; assert p99 ≤ 16.5ms and median ≤ 33ms. | F1, Rec #5 |
| **AC-9** | **AC-9a** (context-blocked): refused hint appears for 0.30s ± 0.05s + audio cue plays for 100ms ± 8ms. **AC-9b** (bound-elsewhere): cross-state hint appears for 0.50s ± 0.05s, no audio. **AC-9c** (4th identical refusal within 60s): audio cue suppressed, hint remains. | Press `weapon_slot_2` with only 1 weapon (context-blocked); press `TAB` from Battle (bound-elsewhere); repeat same bound-elsewhere 4 times. Measure all three durations. | F2, Rec #8, Blk #1 |
| **AC-10** | Dash: 8 active frames (±0), 6 i-frames (±0), 600ms cooldown (±50ms) | Trigger dash; count invulnerable frames; assert 6. Wait 600ms; trigger again; assert allowed. | F3 |
| **AC-11** | Hot-swap: game continues when a gamepad is disconnected mid-battle and reconnected | Yank gamepad USB during battle; reconnect 5s later; assert the battle is still responsive to gamepad input. | E3 |
| **AC-12** | Every menu in the game is navigable with D-pad/arrows + A/Enter only — no menu is mouse-only | Manual walkthrough: navigate Title → Main Menu → Save/Load → Settings → Codex → Pause using gamepad only. Assert every interactive element is reachable. | UI-5 |
| **AC-13** | **Closed-set policy**: adding a 48th action (or 44th in release) causes the CI linter to fail with `TOO_MANY_ACTIONS` | Edit `project.godot` to add a dummy action; run CI; assert linter exit code 1 + `TOO_MANY_ACTIONS` in stderr. | C-R1 |
| **AC-14** | **Action-name identity**: the action set declared in `project.godot` is a subset of the action set declared in `input-bindings.yaml` (no name drift) | Run a diff script between `project.godot [input]` section and `input-bindings.yaml actions: list`; assert `project.godot ⊆ input-bindings.yaml`. | C-R1, Rec #6 |
| **AC-15** | (see AC-3a/3b/3c — split for granularity) |  | C-R3 |
| **AC-16** | InputBus internal handler invocation is fast: median `input_to_handler_us ≤ 200µs`, p99 `≤ 500µs` | Inject a mock clock; measure `InputBus._input()` → `signal.emit()` time across 10,000 events; assert thresholds. | F1, Rec #5 |
| **AC-17** | A key pressed on the same frame as a state transition reaches the new state within 1 frame (atomic E2) | In a test scene, press `attack_primary` exactly 1 frame before triggering an encounter; assert the attack lands in Battle on the first Battle frame. | E2, Blk #3 |
| **AC-18** | Modifier keys (Shift, Ctrl, Alt) produce only their bound action; Shift+W produces `move_up`, NOT a separate `sprint` | Hold Shift, press W, release W, release Shift; observe signal emissions; assert only `move_up` fired (no `sprint` action). | E6, Blk #3 |
| **AC-19** | The MANUAL/AUTO mode indicator is visible (visible==true) during all fullscreen overlays (Codex, Pause, Menu) | Open Codex during Battle; query the mode indicator's `visible` property; assert == true. | UI-2 |
| **AC-20** | Hold-to-skip threshold: holding `menu_confirm` or `play_log` for 1.5s ± 0.05s triggers the skip | Hold `menu_confirm` from t=0; observe skip fires at t ∈ [1.45s, 1.55s]. | G-F5 |
| **AC-21** | `action_held` is monotonic: 5 held frames produce strictly increasing durations ending at ≈ 83ms | (see AC-3c — same test, different threshold perspective) | C-R3, F1 |
| **AC-22** | Debug actions are stripped from release builds (47 → 43) | Build release binary; run AC-1's linter against the release `project.godot`; assert 43. | C-R1, Rec #6 |
| **AC-23** | The `input_refused` audio cue plays for 100ms ± 8ms | Trigger a refused input; measure audio playback duration; assert 0.092-0.108s. | F2, Blk #1 |
| **AC-24** | No mouse-only menu — every interactive Control has `focus_mode != FOCUS_NONE` | Walk all Control nodes in Main Menu, Settings, Save/Load, Pause, Codex; assert all have `focus_mode != FOCUS_NONE`. | UI-5 |
| **AC-25** | D-pad focus navigation wraps from the last element back to the first | In any menu, focus the last element, press D-pad down; assert focus moves to the first element. | UI-1, UI-5 |

**Test evidence location** (audited 2026-06-12, Blk #2 fix):
- **GUT (`.gd`)** — AC-1, AC-2, AC-3a/3b/3c, AC-4, AC-7, AC-13, AC-14, AC-15, AC-18, AC-19, AC-21, AC-22, AC-24, AC-25 → `tests/unit/player_input/`
- **NUnit (`.cs`)** — AC-16 (latency profiling with mock clock) → `tests/unit-cs/player_input/`
- **Integration (GUT scene tests)** — AC-5, AC-6, AC-9a/9b/9c, AC-10, AC-17, AC-20, AC-23 → `tests/integration/player_input/`
- **Performance** — AC-8 → `tests/performance/input_latency/`
- **Manual evidence** — AC-11, AC-12 → `production/qa/evidence/player_input_2026-MM-DD.md`

**Mock-clock dependency-injection point** (audited 2026-06-12, Blk #2 fix): InputBus exposes a settable `var clock: FuncRef` (or a GDScript `Callable` field) used by `_press_start_times` calculations. Tests inject a mock clock; production wires it to `Time.get_ticks_msec`. This makes AC-3c, AC-16, AC-17, AC-20, AC-21 deterministic. Convention: defer final API to `ADR-0006-player-input-architecture`.

## Open Questions

Three open questions. All are deferred — none block the GDD.

### OQ-1: Input rebinding for accessibility

**Question**: Should the game support runtime rebinding for accessibility (e.g., left-handed players, players with motor impairments)?

**Status**: **DEFERRED to Polish phase / a future GDD.** The current GDD hard-codes bindings (C-R7). If accessibility is required for ship, the design changes required are:
- Settings menu gains a "Controls" tab with a rebinding UI
- Bindings move from `InputMap` resource to a `user://bindings.cfg` save file
- The `bindings_version` field in Save/Load becomes load-bearing (currently placeholder)
- 47-action closed set becomes open (any action can be added or removed by the player)

**Trade-off**: rebinding adds 1-2 weeks of dev time and ~20% more code in Settings + Save. The Fantasy §1 ("predictability") partly conflicts with the "remap to suit the player" promise of accessibility. Resolution: **accessibility wins; the Fantasy is reframed to "predictable within your binding."**

**Decision needed by**: end of Vertical Slice phase (per systems-index.md, Menu/Pause GDD will revisit this in the Vertical Slice tier).

### OQ-2: Controller rumble / haptics support

**Question**: Should the game support controller rumble for combat feedback (hit feedback, low-HP warning, dash impact)?

**Status**: **DEFERRED to Audio GDD / a future GDD.** Godot 4.6 supports rumble via the `Input.start_joy_vibration()` API. The Player Input GDD does not specify rumble — it specifies action signals, not haptic output. If rumble is added, the action consumer (Battle, HUD) will be responsible for calling `start_joy_vibration()` on relevant events.

**Verification note (audited 2026-06-12, Blk #3 fix)**: The SDL3 gamepad backend migration in Godot 4.5 may have changed `Input.start_joy_vibration()` parameter order. Before implementation, the implementer MUST verify the current Godot 4.6 signature against `docs/engine-reference/godot/breaking-changes.md` (see also OQ-2 entry in `docs/consistency-failures.md` if added). The current GDD does not specify the signature — it is the implementer's responsibility to confirm `(device, weak_magnitude, strong_magnitude, duration)` or any updated form.

**Trade-off**: rumble is a 1-2 day implementation per consumer. The Fantasy §2 ("acknowledgment is universal") supports rumble as a feedback channel. The Polish GDD (Audio) is the right place to spec this.

**Decision needed by**: end of Vertical Slice phase (Audio GDD is in the "Polish" tier per systems-index.md, but the rumble behavior is per-action-consumer, so it should be in Battle Core / HUD GDDs).

### OQ-3: Touch / trackpad support

**Question**: Should the game support touch input (Steam Deck LCD touch screen, laptop trackpads)?

**Status**: **OUT OF SCOPE for MVP** per `technical-preferences.md`: "Touch Support: None". The Godot 4.6 InputEvent system supports touch events out of the box, but the 47-action set is designed for keyboard + gamepad. Adding touch would require a virtual-joystick + virtual-button UI overlay, which is a significant design effort.

**Trade-off**: Steam Deck is a primary target (it's a PC handheld, the screen is touch-capable). A future Vertical Slice or Full Vision revision could add a touch layer. For MVP, the assumption is that Steam Deck players use the built-in gamepad.

**Decision needed by**: not blocking. Revisit if user testing on Steam Deck shows friction.
