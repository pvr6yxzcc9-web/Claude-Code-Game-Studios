# Epic: Battle Core Loop

> **Layer**: Core
> **GDD**: design/gdd/battle-core-loop.md (Approved)
> **Architecture Module**: `BattleCore` (autoload, C# math + GDScript orchestration) + `BattleMathLib` (C# static)
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories battle-core-loop`

## Overview

Implement the turn-based battle loop that drives the player's moment-to-moment engagement. Battle runs on a deterministic turn cycle: player turn (manual mode: choose action via 1/2/3, item hotbar, defend) → enemy turn (AI decision tree attack) → loop until victory or defeat. Players can switch between MANUAL mode (player chooses every action) and AUTO mode (AI takes over with optimal play) mid-battle via a hotkey. Damage calculation lives in C# `BattleMathLib` (pure functions, testable, no Node dependencies) and is called by GDScript orchestration that emits signals. Boss enemies are immune to one-shot kills per ADR-0011 (damage bounded to `min(damage, enemy.max_hp - 1)`). Battle victory triggers return to exploration + loot. Battle defeat triggers autosave restore + return to last save point.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|------------|
| ADR-0002: Event Architecture | Battle emits `battle_resolved(victory, dmg_dealt, dmg_taken)` signal | LOW |
| ADR-0011: Damage Bounds | Damage bounded 10-480; boss immune to one-shot | MEDIUM (4.6 + cross-language C# bound) |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-BAT-001 | Turn cycle: player turn → enemy turn → loop | ADR-0002 ✅ |
| TR-BAT-002 | MANUAL mode (player picks action) + AUTO mode (AI plays) | ADR-0002 ✅ |
| TR-BAT-003 | Mode switch mid-battle via hotkey | ADR-0002 ✅ |
| TR-BAT-004 | Damage calc in C# `BattleMathLib.CalcDamage(weapon, ammo, target)` | ADR-0011 ✅ |
| TR-BAT-005 | Boss immune to one-shot (damage capped to `max_hp - 1`) | ADR-0011 ✅ |
| TR-BAT-006 | Victory returns to exploration; defeat autosave-restores | ADR-0002 ✅ |
| TR-BAT-007 | Battle state transition via `GameStateMachine.transition_to(state_battle)` | ADR-0002 ✅ |

## Definition of Done

- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/battle-core-loop.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories battle-core-loop` to break this epic into implementable stories.
