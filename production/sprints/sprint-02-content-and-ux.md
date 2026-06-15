# Sprint 2 — Content Depth + UX Polish

## Sprint Goal

Expand content (weapons, enemies, NPC Vera) and add critical UX features (pause menu fixed, onboarding hints) so the vertical slice is a more complete demonstration of the game's vision.

## Milestone Context

- **Current Milestone**: Production (started 2026-06-13)
- **Sprint 1 Status**: Foundation + vertical slice + main menu + pause menu (pause disabled in Sprint 1 due to Godot 4.6 debugger-detach issue)
- **Sprint 2 Deadline**: 2026-06-20 (1 week from Sprint 1 close)

## Capacity

- **Total days**: 7
- **Buffer (20%)**: 1.4 days
- **Available**: 5.6 days

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|--------------|-------------------|--------|
| S2-001 | Re-add pause menu (fixed approach) | gameplay-programmer | 0.5 | None | Esc in exploration opens pause; Esc in pause closes; no Godot debugger detach | Not Started |
| S2-002 | Verify FC-1..FC-11 + sprint1 regression | qa-tester | 0.5 | S2-001 | All tests pass; no regression | Not Started |
| S2-003 | Add 3 more weapons (plasma, railgun, shotgun-spread) | systems-designer | 1.0 | None | 6 total weapons, all loadable into 3 slots | Not Started |
| S2-004 | Add 3 more enemies (drone, heavy_walker, sniper_bot) | systems-designer | 1.0 | None | 5 total enemies, all spawnable via encounter | Not Started |
| S2-005 | NPC Vera dialogue (1-2 lines) | narrative-director | 0.5 | None | Press E near Vera → dialogue UI shows + increments fragment count | Not Started |
| S2-006 | Terminal log interaction | gameplay-programmer | 0.5 | None | Press E near terminal → transcript UI shows | Not Started |

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|--------------|-------------------|--------|
| S2-010 | Onboarding hints (first room text overlay) | ux-designer | 0.5 | None | First 10s in room 0 show "WASD to move, 1/2/3 to attack, E to interact" | Not Started |
| S2-011 | Encounter rate tuning (50% → 6% per room) | game-designer | 0.25 | None | Rooms 3-8 have 0 encounters, rate feels intentional | Not Started |
| S2-012 | Boss fight verify (room 9) | qa-tester | 0.5 | S2-004 | Walk to room 9 → boss battle → boss_immune_to_one_shot works | Not Started |
| S2-013 | Reset sprint 1 main scene to run main.tscn on F5 | gameplay-programmer | 0.1 | None | project.godot run/main_scene = res://src/main.tscn | Not Started |

### Nice to Have (Cut First)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|--------------|-------------------|--------|
| S2-020 | Codex entry population | systems-designer | 1.0 | S2-003, S2-004 | Codex shows all 6 weapons + 5 enemies with stats | Not Started |
| S2-021 | Audio: SFX for attack/damage | audio-director | 0.5 | None | Attack plays a sound (placeholder beep) | Not Started |

## Risks to This Sprint

| Risk | Probability | Impact | Mitigation | Owner |
|------|------------|--------|-----------|-------|
| Godot 4.6 pause issue requires architectural rework | Medium | High | Try process_mode=ALWAYS + 1-frame defer unpause; if fails, implement as CanvasLayer with own input handling | gameplay-programmer |
| New weapons/enemies break damage math | Low | Medium | Run FC-1 + FC-5 + FC-8 tests after each addition | qa-tester |
| NPC dialogue scope creep | Medium | Low | Limit Vera to 2-3 lines, defer more complex trees to Sprint 3 | narrative-director |

## Definition of Done

- [ ] All Must Have tasks completed
- [ ] All tasks pass acceptance criteria
- [ ] FC-1..FC-11 + sprint1_runner all PASS
- [ ] No "confusion loops" — first-time players can figure out controls in < 2 minutes
- [ ] No critical/blocker bugs in vertical slice build
