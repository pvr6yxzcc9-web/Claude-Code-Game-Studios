# Sprint 1 — Foundation + Vertical Slice Polish

## Sprint Goal

Lock in the Foundation layer (5 autoloads + 10 Resource subtypes + Camera + Collision) and Core Battle Loop, plus polish the Vertical Slice build (clean up debug prints, fix any blockers, document playtest).

## Milestone Context

- **Current Milestone**: Pre-Production → Production transition
- **Milestone Deadline**: 2026-06-20 (Production start)
- **Sprints Remaining**: 1 (this is the first sprint)

## Capacity

- **Total days**: 7
- **Buffer (20%)**: 1.4 days reserved for unplanned work
- **Available**: 5.6 days

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|--------------|-------------------|--------|
| S1-001 | Clean up debug prints in level_runtime.gd | solo-dev | 0.5 | None | `_process tick` removed; only `POLL: door/encounter trigger` prints remain (or are also removed) | Not Started |
| S1-002 | Test full 10-room vertical slice playthrough | solo-dev | 0.5 | S1-001 | Player can walk from room 0 to room 9; encounter triggers battle; boss room loads | Not Started |
| S1-003 | Create design/ux/hud.md UX spec | ux-designer | 1.0 | None | 8-section UX spec covering HP bar, weapon slot, mode badge, encounter count, fragment count | Not Started |
| S1-004 | Create main menu UX spec | ux-designer | 0.5 | None | `design/ux/main-menu.md` with title screen, new game, load game, settings, quit | Not Started |
| S1-005 | Create pause menu UX spec | ux-designer | 0.5 | None | `design/ux/pause.md` with resume, save, load, settings, quit | Not Started |
| S1-006 | Write playtest report for solo playthrough | solo-dev | 0.5 | S1-002 | `production/playtests/2026-06-13-solo-playthrough.md` with hypothesis, observations, verdict | Not Started |
| S1-007 | Re-run /gate-check pre-production | solo-dev | 0.5 | S1-001..S1-006 | Verdict: PASS | Not Started |

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|--------------|-------------------|--------|
| S1-010 | Vertical Slice REPORT.md | solo-dev | 0.5 | S1-002 | `prototypes/暗雷回合制战斗-concept/REPORT.md` written with PROCEED verdict | Not Started |
| S1-011 | Entity inventory (lightweight) | lead-programmer | 1.0 | None | `design/assets/entity-inventory.md` lists weapon/ammo/enemy/mech/etc. by ID | Not Started |
| S1-012 | Run FC-1..FC-11 regression suite | qa-tester | 0.5 | S1-001 | All 206+ tests pass | Not Started |

### Nice to Have (Cut First)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|--------------|-------------------|--------|
| S1-020 | Replace AABB polling with proper Area2D signal | gameplay-programmer | 0.5 | None | Once Godot 4.6.4+ lands with the fix, swap polling for signal-based door | Not Started |
| S1-021 | Reduce encounter encounter rate from 50% to 6% per room | game-designer | 0.25 | None | Encounters feel rare, not constant | Not Started |

## Carryover from Sprint 0 (Pre-Production)

| Original ID | Task | Reason for Carryover | New Estimate | Priority Change |
|------------|------|---------------------|-------------|----------------|
| — | (none) | Pre-Production was implementation, not a sprint | — | — |

## Risks to This Sprint

| Risk | Probability | Impact | Mitigation | Owner |
|------|------------|--------|-----------|-------|
| 4.6 Area2D bug still present | Low | Medium | AABB polling fallback already in place; defer signal-based fix to S1-020 | solo-dev |
| 47-action InputMap too complex for first-time players | Medium | Low | Onboarding tutorial deferred to Polish layer; visual cues in HUD (slot highlight) | ux-designer |
| Solo dev time over budget on UX specs | Medium | Low | Cut S1-010/011/012 to Should Have; S1-001..007 are the must-haves for gate | producer |

## External Dependencies

| Dependency | Status | Impact if Delayed | Contingency |
|-----------|--------|------------------|-------------|
| Godot 4.6 stable | Available | Build/compile failures | Pin to 4.6.3 per ADR-0006 |
| GUT 9.6 plugin | Enabled | Tests can't run | Manual smoke test fallback |

## Definition of Done

- [ ] All Must Have tasks completed
- [ ] All tasks pass acceptance criteria
- [ ] QA plan exists (`production/qa/qa-plan-sprint-1.md`)
- [ ] All Logic/Integration stories have passing unit/integration tests
- [ ] Re-run `/gate-check pre-production` returns PASS
- [ ] User approval to advance to Production
