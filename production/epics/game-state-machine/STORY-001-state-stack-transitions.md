# STORY-001: state_stack with push/pop/transition_to

> **Epic**: game-state-machine
> **Layer**: Foundation
> **TR**: TR-STM-001, TR-STM-002, TR-STM-003
> **Status**: Done (verified 2026-06-13)

## Acceptance Criteria

- [x] `state_stack: Array[StringName]` initialized to `["state_exploration"]`
- [x] `transition_to(state)` replaces top of stack and emits `state_changed(old, new)` signal
- [x] `push(state)` adds to top; `pop()` removes top
- [x] `ALLOWED_TRANSITIONS` table enforces valid transitions (invalid raises error)
- [x] States defined: title, exploration, battle, dialogue, terminal, codex, menu, save_load, game_over

## Implementation

- `src/autoload/game_state_machine.gd` — autoload #1
- ALLOWED_TRANSITIONS table maps from-state to set of valid to-states
- `transition_to()` checks table before replacing; raises Error on invalid

## Verification Evidence

- F5 boot: `[GameStateMachine] ready as autoload #1`
- Encounter triggers `transition_to(&"state_battle")` (verified in level_runtime.gd:_on_encounter_body_entered)
- Esc in battle triggers `transition_to(&"state_exploration")` (verified in battle_scene.gd:_unhandled_input)
