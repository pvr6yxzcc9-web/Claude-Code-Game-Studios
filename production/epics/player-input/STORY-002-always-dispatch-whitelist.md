# STORY-002: always_dispatch whitelist for cross-state actions

> **Epic**: player-input
> **Layer**: Foundation
> **TR**: TR-INP-004
> **Status**: Done (verified 2026-06-13 — pause + battle inputs work in any state)

## Acceptance Criteria

- [x] `always_dispatch` whitelist contains: `pause`, `battle_attack_slot1/2/3`
- [x] Whitelisted actions dispatch regardless of `GameStateMachine.top_of_stack`
- [x] Non-whitelisted actions only dispatch to subscribers of current state
- [x] Pressing `1/2/3` in exploration switches weapon slot; in battle triggers immediate attack

## Implementation

- `src/autoload/input_bus.gd:53-71` — `_dispatch_to_subscribers()` checks `always_dispatch` first
- If `always_dispatch.get(action, false)`, signal is emitted regardless of state
- Otherwise, only emit if `_subscribers.has(top)`

## Verification Evidence

- Manual play: 1/2/3 work in both `state_exploration` and `state_battle` (verified 2026-06-13)
- Esc pause works in any state (verified in BattleScene._unhandled_input)
