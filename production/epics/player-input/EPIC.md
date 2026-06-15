# Epic: Player Input

> **Layer**: Foundation
> **GDD**: design/gdd/player-input.md (Approved)
> **Architecture Module**: `InputBus` (autoload)
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories player-input`

## Overview

Route all 47 player actions (WASD movement, 1/2/3 weapon switching, E interact, Tab codex, Esc pause, etc.) from the engine InputMap to the correct subscribers based on the current `GameStateMachine.top_of_stack`. `InputBus` is a Foundation autoload that owns the subscriber list per state, dispatches `action_pressed` / `action_released` / `action_held` signals, and supports an "always_dispatch" whitelist for cross-state actions (e.g., `pause` works in every state, `1/2/3` work in both exploration and battle). Visual focus for HUD widgets is handled separately (4.6 dual-focus semantics) and tested with both keyboard/mouse and gamepad inputs. The 47-action InputMap is defined in `design/registry/input-bindings.yaml` and registered in `project.godot`.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|------------|
| ADR-0009: Input Binding | 47 actions, signal-based dispatch, always-dispatch whitelist for cross-state | MEDIUM (4.6 dual-focus) |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-INP-001 | 47-action InputMap registered in `project.godot` | ADR-0009 ✅ |
| TR-INP-002 | `InputBus` dispatches `action_pressed/released/held` signals | ADR-0009 ✅ |
| TR-INP-003 | Per-state subscriber routing via `GameStateMachine.top_of_stack` | ADR-0009 ✅ |
| TR-INP-004 | `always_dispatch` whitelist for cross-state actions (`pause`, `1/2/3`) | ADR-0009 ✅ |
| TR-INP-005 | Visual focus (HUD) tested with keyboard + gamepad (4.6 dual-focus) | ADR-0009 ✅ |
| TR-INP-006 | Hold timer with `action_held` signal emitting duration | ADR-0009 ✅ |

## Definition of Done

- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/player-input.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories player-input` to break this epic into implementable stories.
