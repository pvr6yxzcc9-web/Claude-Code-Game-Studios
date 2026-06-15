# STORY-002: get_state_snapshot / load_snapshot for save/load

> **Epic**: game-state-machine
> **Layer**: Foundation
> **TR**: TR-STM-006
> **Status**: Done (verified 2026-06-13)

## Acceptance Criteria

- [x] `get_state_snapshot() -> Dictionary` returns `{schema_version, top_of_stack, stack}`
- [x] `load_snapshot(snap: Dictionary) -> Error` restores the state stack
- [x] `SaveManager` calls these on save/load round-trip
- [x] All 13 producer namespaces persist their state via this contract

## Implementation

- `src/autoload/game_state_machine.gd:get_state_snapshot()` — returns top of stack
- `src/autoload/game_state_machine.gd:load_snapshot(snap)` — restores top from dict
- `src/autoload/save_manager.gd` — calls all producers on save/load

## Verification Evidence

- FC-9 (save/load) tests pass
- Save → load → continue from autosave after defeat (verified in BattleScene._resolve_battle)
