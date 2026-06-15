# Epic: Game State Machine

> **Layer**: Foundation
> **GDD**: design/gdd/game-state-machine.md (Approved)
> **Architecture Module**: `GameStateMachine` (autoload)
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories game-state-machine`

## Overview

Own the canonical state stack (`state_stack: Array[StringName]`) that drives every mode-switch in the game: `state_title → state_exploration ⇄ state_battle / state_dialogue / state_terminal / state_codex / state_menu / state_save_load / state_game_over`. `GameStateMachine` is the first autoload to load and is the only module that knows the full state graph. It exposes `transition_to(state) -> Error`, `push(state) -> Error`, `pop() -> Error`, plus `get_state_snapshot() / load_snapshot(snap)` for save/load. The `ALLOWED_TRANSITIONS` table is a hard constraint (ADR-0001) — invalid transitions raise error and abort. All other systems (InputBus routing, BattleScene visibility, HUD mode badge, save triggers) read `top_of_stack` rather than maintaining their own state. State badges (TITLE/EXPLORING/IN BATTLE/PAUSED) appear in the HUD.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|------------|
| ADR-0001: Scene Management & Autoload Order | `GameStateMachine` is autoload #1; load order is non-negotiable | LOW |
| ADR-0002: Event Architecture | State transitions emit `state_changed(old, new)` signal; cross-module communication via signal | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-STM-001 | `state_stack` is a typed `Array[StringName]` | ADR-0001 ✅ |
| TR-STM-002 | `ALLOWED_TRANSITIONS` table enforced on every transition | ADR-0001 ✅ |
| TR-STM-003 | `transition_to` replaces top of stack; `push` adds; `pop` removes | ADR-0001 ✅ |
| TR-STM-004 | `state_changed(old, new)` signal emitted on every transition | ADR-0002 ✅ |
| TR-STM-005 | States: title, exploration, battle, dialogue, terminal, codex, menu, save_load, game_over | ADR-0001 ✅ |
| TR-STM-006 | `get_state_snapshot() / load_snapshot(snap)` for save/load round-trip | ADR-0002 ✅ |
| TR-STM-007 | `GameStateMachine` is autoload #1; load order enforced at boot | ADR-0001 ✅ |

## Definition of Done

- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/game-state-machine.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories game-state-machine` to break this epic into implementable stories.
