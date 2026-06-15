# Sprint 5 — Release Readiness

> **Sprint Goal**: Make the build verifiable (F5 sweep), pay down schema extension debt (5 unused fields), polish the visible rough edges, and ship a build that a real person can pick up and play to one of 3 endings.

> **Dates**: 2026-06-15 → 2026-06-28 (2 weeks, solo-direct-execution)
> **Capacity**: ~10-12 working days at user's real pace
> **Scope target**: shippable demo build by end of sprint — F5-verified, schema debts cleared, no critical bugs

## Milestone Context

- **Current Milestone**: Pre-release polish
- **Target Ship**: 2026-07-15 (public release candidate)
- **Sprints Remaining**: 1 (Sprint 5 = release-readiness; post-launch patches are not "sprints")
- **Prior sprints**: S1 vertical slice / S2 content+UX / S3 polish+guards / S4 content+systems

## Starting Conditions (Measured 2026-06-15, from Sprint 4 close)

| Metric | Value | Status |
|--------|-------|--------|
| Weapons | 8 | Sprint 4 ✅ |
| Ammo | 5 | Sprint 4 ✅ |
| Enemies | 8 | Sprint 4 ✅ |
| Mech parts | 3 | Sprint 4 ✅ |
| NPCs | 4 | Sprint 4 ✅ |
| Fragments | 7 (4 active + 3 tbd) | Sprint 4 ✅ |
| Dialogue trees | 7 | Sprint 4 ✅ |
| Endings | 3 | Sprint 4 ✅ |
| Hidden areas | 1 (room 4) | Sprint 4 ✅ |
| Autoloads | 13 | Sprint 4 ✅ |
| Test scripts | 30 | Sprint 4 ✅ |
| Lint guards | 9 (saturated) | Sprint 4 ✅ |
| TODOs in src/ | 0 | Sprint 4 ✅ |
| **F5 verification of Sprint 4** | **NOT DONE** | **Critical** |
| Schema fields without consumers | 5 (Sprint 4 carryover) | High |
| Real SFX | 0 (placeholder beeps) | Medium |
| Pixel art | 0 (ColorRect) | High if shipping |
| Build export (Win/Mac/Linux) | Untested | Medium |
| Public playtest | 0 testers | High if shipping |

## Capacity

- **Total days**: 10-12 (depends on whether F5 environment is available)
- **Buffer (20%)**: 2-2.5 days for unplanned F5 fixes, schema-consumer edge cases
- **Available**: 8-10 days for tasks
- **Pace**: Solo, direct-execution. The Sprint 4 lesson: ask "how long today?" before assuming 1-day tasks. Sprint 5 sized for **wall-clock time the user has**, not psychological complexity.

## Tasks

### Must Have (Critical Path — release gates)

| ID | Task | Agent/Owner | Est. (wall-clock) | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-------------------|-------------|-------------------|--------|
| S5-001 | **F5 environment setup + Sprint 4 verification sweep** | user + gameplay-programmer | 1 day | User has Godot 4.6 installed runnable | F5 main.tscn works; user runs through all 10 rooms; Sprint 4 close report F5 log filled with PASS/FAIL observations; any FAIL becomes a new bug-fix task | Not Started |
| S5-002 | Wire `effect_data.damage_per_turn` to battle math (real DoT) | gameplay-programmer | 0.5 day | None | plasma_burn's burn effect ticks 5 dmg/turn for 3 turns on the enemy; new fc31 test pin | Not Started |
| S5-003 | Wire `enemy_data.weaknesses` + `resistances` to damage calc | gameplay-programmer | 0.5 day | None | Weakness: x1.5 dmg; resistance: x0.5 dmg; fc32 test pin; reflected in HUD log | Not Started |
| S5-004 | Wire `weapon_data.special_effects` (chain/AoE for mine_layer + arc_emitter) | gameplay-programmer | 1 day | S5-003 (shares consumer infra) | mine_layer hits 2 adjacent enemies (AoE-lite); arc_emitter chains to 1 nearest enemy at 50% dmg; fc33 test pin | Not Started |
| S5-005 | Rewrite the 3 tbd fragments (what_was_carried, the_truth, engineer_last_stand) | writer | 0.5 day | User provides direction | unlock_condition removed from "tbd_sprint5"; new log or dialogue trigger path; fc25 test updates | Not Started |
| S5-006 | Boss ending UI integration test (S4-009 untested visually) | gameplay-programmer | 0.25 day | S5-001 | F5: defeat boss, ending A/B/C dialogue shows; close dialogue returns to exploration; no visible UI child left over | Not Started |
| S5-007 | Hidden area discoverability hint | ux-designer + gameplay-programmer | 0.1 day | None | courier_14 dialogue mentions "the wall in room 4 has been weak"; OR a sparkle/dust particle on the wall in room 4 | Not Started |
| S5-008 | `tools/sync_input_bindings.py` and `tools/lint_autoload_order.py` (both missing from CI) | devops-engineer | 0.25 day | None | Both scripts exist; CI workflow updated to not error on missing tools; Sprint 5 lint gate stays clean | Not Started |
| S5-009 | Build export pipeline (Win + Linux minimum) | devops-engineer | 0.5 day | Godot export templates installed | `godot --headless --export-release "Linux/X11" build/railhunter.x86_64` produces a runnable binary; same for Windows; F5 on exported build = same as editor | Not Started |
| S5-010 | F5 close on Sprint 5 deliverable | user | 0.5 day | S5-001 through S5-009 | Updated F5 verification log in Sprint 5 close report, every Must Have has PASS row | Not Started |

**Must Have total: ~5 days wall-clock.** Fits in 8-10 day available window.

### Should Have (if capacity allows — quality + polish)

| ID | Task | Agent/Owner | Est. | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|------|-------------|-------------------|--------|
| S5-011 | Real SFX (replace procedural beeps) | sound-designer | 1 day | None | 6+ distinct .ogg files (attack/damage/UI/door/open/terminal/fragment); SFXPlayer switched from _make_beep to AudioStream; fc18 still passes | Not Started |
| S5-012 | TerminalUI y_offset + CodexUI scrollbar geometry tighten (constants, no hardcodes) | godot-gdscript-specialist | 0.25 day | None | Both files use named constants; no hardcoded numbers drift from panel position; existing tests pass | Not Started |
| S5-013 | Add 2 ammo (tracking_round, explosive_shell) | gameplay-programmer | 0.25 day | S5-004 (for consistency) | 2 new .tres; fc30 update; both have unique effect | Not Started |
| S5-014 | Add 1 mid-game boss (corrupted_engineer) | level-designer + ai-programmer | 0.75 day | None | New .tres with boss=true; spawn in room 5 (was scavenger encounter); fc15 verifies boss_immune_to_one_shot | Not Started |
| S5-015 | 3 tbd fragments are now 0 tbd + S4-005 fragment_who_we_were Lore layer audit | writer | 0.25 day | S5-005 | All 7 fragments have working unlock paths; lore_layer ladder is monotonic | Not Started |

**Should Have total: ~2.5 days.** If Must takes 5, fits with 2.5 day buffer. If Must slips, Should is cut.

### Nice to Have (cut first — defer to post-launch or sprint 6)

| ID | Task | Agent/Owner | Est. | Notes |
|----|------|-------------|------|-------|
| S5-020 | Pixel art pass (replace ColorRect placeholders) | art-director | 5-10 days | **NOT planned for Sprint 5.** If shipping is required, this becomes the only thing that matters. Decision point at end of Sprint 5. |
| S5-021 | Steam page + marketing trailer | release-manager | 1-2 days | Depends on art being final |
| S5-022 | Localization scaffold | localization-lead | 1-2 days | English-only first; add if timeline allows |
| S5-023 | Tutorial overlay | ux-designer | 0.5 day | onboarding hint already does some of this; formalize if time |
| S5-024 | Add second biome (engine_room) | level-designer | 1 day | Replaces chapter 2 — full content scope |
| S5-025 | New ending D (no fragments + boss kill = even more bleak than C) | writer | 0.25 day | Possible if A/B/C all feel tonally close |

**Nice to Have: NOT planned for Sprint 5.** S5-020 (art) is the ship-or-not variable — if required, scope shifts and timeline slips 2-4 weeks.

## Carryover from Sprint 4 (organized by priority)

| Original ID | Item | Now Where |
|-------------|------|-----------|
| S4-F5 | F5 verification of all Sprint 4 Must Haves | S5-001 (now the #1 priority) |
| S4-debt | Wire 5 unused schema fields | S5-002 / S5-003 / S5-004 |
| S4-005-tbd | 3 tbd fragments | S5-005 + S5-015 |
| S4-009-uitest | Boss ending UI integration | S5-006 |
| S4-008-hint | Hidden area discoverability | S5-007 |
| S4-ci-tools | sync_input_bindings.py + lint_autoload_order.py missing | S5-008 |
| S4-export | Build export pipeline | S5-009 |
| S2-001-hud | HUD weapon slot contrast carryover | Trivial — DEFERRED indefinitely (cosmetic) |
| S3-011 / S3-012 | PauseMenu confirm visual / onboarding hint visual | Trivial polish — Sprint 6+ if at all |
| S3-013 | close-checklist.md standalone | Redundant with S3-007 template — DROP |

## Risks to This Sprint

| Risk | Probability | Impact | Mitigation | Owner |
|------|------------|--------|-----------|------|
| **No F5 environment in this conversation** | **High** | **Critical** | Sprint 4 was COMPLETE-without-F5; Sprint 5 must NOT start tasks until F5 is feasible. S5-001 is the gating task — if it can't be done, sprint is BLOCKED not PARTIAL. | user |
| F5 reveals HiDPI / visual bugs that require rework | High | High | Reserve buffer day for fixes; pause and surface rather than rushing | user + gameplay-programmer |
| S5-004 (chain/AoE) requires battle_math refactor | Medium | High | Scope-limit: mine_layer becomes "x1.3 dmg to single target with bonus if enemy has weakness" (still flavor, less risky than true AoE) | gameplay-programmer |
| S5-005 tbd fragment rewrite needs user direction | High | Medium | Default to "synthesized Marlow's last will" theme if user not available; document for review | writer |
| User changes direction mid-sprint | Medium | High | Sprint plan is a contract; revisions need trade-off visible to user | producer |
| S5-009 export pipeline fails on user's machine | Low | High | Document export steps; if Godot export templates missing, defer to "build-ready" state and ship from CI | devops-engineer |

## External Dependencies

| Dependency | Status | Impact if Delayed | Contingency |
|-----------|--------|------------------|-------------|
| **User has Godot 4.6 runnable + can F5** | **Required for S5-001** | **Sprint BLOCKED** | Cannot do release readiness without F5 — Sprint 5 must wait for environment |
| Godot export templates (Linux X11 + Windows) | Need to install | S5-009 slips | Document build steps; ship editor-built demo only |
| User direction on S5-005 tbd fragments | Pending | Medium | Use existing "convoy was family" theme as scaffold |
| User OK with shipping without art (ColorRect) | Required for S5-009 | High | Indie pixel is acceptable; if not, S5-020 scope enters |

## Definition of Done (S3-007 enforced)

- [ ] All Must Have tasks completed (S5-001 through S5-010)
- [ ] **Each Must Have task has F5 verification log entry in Sprint 5 close report** (real F5, not N/A)
- [ ] All tasks pass acceptance criteria (autotest + F5)
- [ ] Test suite PASS (30 scripts + new fc31-33, target: 32-33 scripts)
- [ ] No regression vs. Sprint 4 (all fc1-fc30 still pass)
- [ ] Lint guards PASS (9/9, including the 13 files reformatted by linter post-Sprint 4)
- [ ] No new TODOs in src/
- [ ] Build export produces runnable binary (S5-009)
- [ ] Schema debt cleared (5 unused fields all wired or removed)
- [ ] All 7 fragments have working unlock paths (S4-005 tbd cleared)
- [ ] F5 close report filled for Sprint 5 deliverable

## Out of Scope (Explicitly)

- **Art (S5-020)** — biggest variable; if required, this sprint slips 2-4 weeks
- **Steam page + marketing trailer** — Sprint 6+ or post-launch
- **Real SFX** (S5-011) — if cut, ship with procedural beeps
- **Localization** — English-only first
- **Second biome** (S5-024) — chapter 2 scope, not this sprint
- **Multiplayer / Steam achievement / leaderboard** — out of MVP entirely

If any of these become blocking, this sprint plan should be revised before continuing.

## Recommended Sprint Start Order

1. **S5-001** (F5 sweep) — **gate everything else on this**. If F5 isn't possible, the rest of the sprint is academic.
2. **S5-002 / S5-003 / S5-004** (schema debt) — small, low-risk, code-only, independent
3. **S5-007** (hidden area hint) — tiny, just copy a line + particle
4. **S5-005** (tbd fragments) — needs user direction
5. **S5-006** (boss ending UI) — F5-dependent on S5-001
6. **S5-008** (missing CI tools) — independent
7. **S5-009** (build export) — can be late since it ships the final artifact
8. **S5-010** (F5 close on Sprint 5) — last task; closes the sprint

Should Have (S5-011 through S5-015) picked up in any remaining capacity.

## Process Notes (Sprint 4 Carryover)

- **Time estimates must be wall-clock for the user, not for me.** This plan uses "~X days" labels that mean **the user's wall-clock days**, not my psychological-complexity days. If user says "I have 30 min today", trim plan to 1-2 items.
- **F5 verification needs an environment.** Sprint 4 shipped without F5 because Godot wasn't installed. Sprint 5 is built around F5 — S5-001 is the gate.
- **Schema-extension debt compounds.** S5-002/003/004 specifically target the 5 unused fields identified in Sprint 4. After this sprint, no more schema-without-consumer.
- **Multi-tasking LLM, single-tasking user.** Recommended cadence: do 1-3 tasks, summarize, ask "continue or pause?" — do not chain 10 tasks before check-in.
- **Sprint 5 should end with a decision: ship or iterate?** After S5-010, the user has a real call to make: ship as-is (ColorRect, no art) or commit to another sprint for art + audio. The plan should be honest about this.
