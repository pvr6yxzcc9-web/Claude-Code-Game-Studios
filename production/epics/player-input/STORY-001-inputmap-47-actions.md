# STORY-001: 47-action InputMap registered

> **Epic**: player-input
> **Layer**: Foundation
> **TR**: TR-INP-001
> **Status**: Done (verified 2026-06-13)

## Acceptance Criteria

- [x] 47 actions registered in `project.godot` InputMap
- [x] Each action has default + alternative key bindings
- [x] `InputMap.get_actions()` returns 47 actions
- [x] Per-state subscriber routing works via `InputBus`

## Implementation

- `project.godot` — `input/` section with 47 action definitions
- `design/registry/input-bindings.yaml` — canonical reference
- `src/autoload/input_bus.gd` — owns subscriber list per state, dispatches signals

## Verification Evidence

- F5 boot: `[InputBus] ready as autoload #2`
- `EXPECTED_ACTION_COUNT: int = 47` enforced in `input_bus.gd:13`
- Manual play: WASD moves player, 1/2/3 switch weapons, E interact, Esc pause — all functional
