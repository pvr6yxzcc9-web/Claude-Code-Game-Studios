# Prototype Report — 暗雷回合制战斗 (Railhunter Vertical Slice)

> **Concept**: Railhunter (钢轨猎人) — turn-based 2D pixel sci-fi RPG
> **Date**: 2026-06-13
> **Author**: solo developer
> **Path**: Engine (Godot 4.6.3 stable.mono)
> **Hypothesis tested**: Core exploration + battle loop is technically functional end-to-end (functional validation only; fun validation deferred to external playtest)

## Concept Summary

A turn-based 2D sci-fi RPG where the player explores procedurally-built dungeons, encounters enemies via encounter tiles, and engages in turn-based combat with a 3-slot weapon/ammo loadout. The setting is a post-collapse rail network where mech pilots scavenge and trade.

## Hypothesis

> If the player can walk through rooms, trigger encounters that start battles, and switch weapons in real-time, the core loop is **technically functional**. The "is it fun?" question requires external playtester validation.

## Riskiest Assumption

**Can the 3-slot weapon/ammo system + encounter triggers + door transitions all work in the same Godot 4.6 build without state machine conflicts?**

This was the highest-risk technical assumption. We validated it by:
1. Building 11 autoloads with explicit load order (ADR-0001)
2. Wiring 47 actions through `InputBus` with `always_dispatch` whitelist (ADR-0009)
3. Implementing encounter triggers via `Area2D` with `set_deferred("monitoring", true)` to avoid spawn-time false triggers
4. Implementing door transitions via manual AABB polling in `_process` (workaround for 4.6 Area2D reliability issue)

## What Was Built

- **5 autoloads**: `GameStateMachine`, `InputBus`, `ResourceRegistry`, `MetaState`, `SaveManager`
- **10 Resource subtypes** with immutability guard
- **C# battle math lib** (GDScript for 4.6 compat) with damage bounds 10-480
- **5 scene scripts**: player controller, level runtime, battle scene, HUD, UI
- **10 rooms** of procedural dungeon (1 chapter: Scrapyard)
- **1 boss room** (room 9) with `boss_marrow_sentinel`
- **11 GUT test suites** (FC-1..FC-11, 206+ tests, all passing)
- **47-action InputMap** with always-dispatch whitelist
- **Save/Load** with autosave, 3 manual slots, version upgrade path

## What Was Validated (technical)

- ✅ Player movement (WASD + arrows, 120 px/s)
- ✅ Camera follow + room snap on door transition
- ✅ 5 of 10 rooms traversed in one F5 session
- ✅ Encounter tile → battle trigger works
- ✅ Battle stub: 1/2/3 weapon attacks, damage calc, enemy counter-attack
- ✅ State machine: state_exploration ⇄ state_battle
- ✅ Save/load round-trip preserves state
- ✅ Door transition via AABB polling (verified 2026-06-13)
- ✅ All 206+ GUT tests pass
- ✅ F5 boot succeeds, no engine errors

## What Was NOT Validated

- ❌ **Fun**: No independent player feedback. Subjective assessment only.
- ❌ **Onboarding**: No tutorial; player must intuit controls.
- ❌ **Boss fight**: Room 9 not yet visited in solo test.
- ❌ **Mech system**: 5 parts defined but not exercised.
- ❌ **NPC dialogue**: Not triggered.
- ❌ **Codex**: Tab key opens but no entries.
- ❌ **10-room full traversal**: Only 5 rooms traversed in solo test.
- ❌ **Audio**: No music or SFX implemented.

## Surprises

- **Typed array bug in 4.6**: `Array[Area2D]` silently rejected `Node2D` wrapper on `append()`, leaving `_doors` empty. Took 1+ hour to debug. Fix: `Array[Node2D]`. This is a post-cutoff 4.6 behavior that may bite other teams.
- **Area2D `body_entered` reliability**: Godot 4.6 sometimes doesn't fire `body_entered` if the body is already inside when monitoring is enabled. Workaround: manual AABB polling in `_process`. Should be revisited when Godot 4.6.4+ ships.
- **Player spawn direction was wrong on first door traversal**: `door_dir` was set to `"left"` when player came from right, but spawn used it as "place on left side of new room", which put the player on the wrong side. Fix: swap the conditional.

## Verdict: **PROCEED** (with documented concerns)

The vertical slice is **technically functional** end-to-end. All hard blockers have been resolved (see `production/gate-checks/2026-06-13-pre-production-to-production-RECHECK.md`). The remaining concerns are around fun validation, onboarding, and content depth — all addressable in Sprint 1 of Production.

## Recommendations for Production Sprint 1

1. **Clean up debug prints** in `src/scene/level_runtime.gd` (S1-001)
2. **Full 10-room playthrough test** with boss fight (S1-002)
3. **Run FC-1..FC-11 regression** to confirm no regressions (S1-012)
4. **Reduce encounter rate** from 50% (dev default) to ~6% (design target) (S1-021)
5. **Add onboarding hints** in HUD or first room (e.g., "Press 1/2/3 to switch weapons")
6. **Update playtest report** after the 10-room test (S1-006)
7. **Get external playtester** for fun validation (Sprint 1+ should-have)

## Files Referenced

### Source code
- `src/main.tscn` — root scene
- `src/scene/level_runtime.gd` — procedural room builder
- `src/scene/player_controller.gd` — CharacterBody2D
- `src/battle/battle_scene.gd` — battle stub
- `src/math/battle_math_lib.gd` — damage calc
- `src/autoload/*.gd` — 11 autoloads
- `src/resource/*.gd` — 10 Resource subtypes

### Design
- `design/gdd/*.md` — 12 GDDs
- `design/registry/entities.yaml` — cross-system facts
- `design/art/art-bible.md` — visual identity
- `design/ux/hud.md` — HUD UX spec
- `design/ux/main-menu.md` — main menu UX spec
- `design/ux/pause-menu.md` — pause menu UX spec
- `design/assets/entity-inventory.md` — content inventory

### Architecture
- `docs/architecture/ADR-0001..0011-*.md` — 11 ADRs, all Accepted
- `docs/architecture/architecture.md` — master architecture
- `docs/architecture/control-manifest.md` — programmer rules

### Tests
- `tests/integration/fc1_smoke_test.gd` .. `fc11_vertical_slice_test.gd` — 11 test suites

### Playtest
- `production/playtests/2026-06-13-solo-playthrough.md`

### Gate checks
- `production/gate-checks/2026-06-12-technical-setup-to-pre-production.md` (PASS)
- `production/gate-checks/2026-06-13-pre-production-to-production.md` (initial FAIL)
- `production/gate-checks/2026-06-13-pre-production-to-production-RECHECK.md` (CONCERNS, after artifacts added)

## Next Step

Re-run `/gate-check pre-production` to confirm PASS after the 3 soft items in this session are complete. If PASS, write "Production" to `production/stage.txt` and begin Sprint 1.
