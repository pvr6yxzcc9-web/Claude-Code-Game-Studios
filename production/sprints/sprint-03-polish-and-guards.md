# Sprint 3 — Polish + Guards

> **Sprint Goal**: Make the vertical slice feel like a real game (visual polish on existing UI) AND add structural guards (CI/lint) that prevent the HiDPI / indent / missing-F5-verify classes of bugs from recurring.

> **Dates**: 2026-06-14 (proposed, 1-2 days)
> **Capacity**: ~3-4 days equivalent (we work at your direct-execution pace, so 1 day wall-clock)

## Context

Sprint 2 closed at 348/348 tests passing, but the build still has visible rough edges:
- PauseMenu items render in wrong positions (VBoxContainer + absolute positioning clash)
- HUD shows "EXPLORING" badge even when paused (state listener doesn't refresh state_text properly)
- DialogueUI has no choice highlight (player can't tell which 1/2/3 is selected)
- No in-game way to open Codex (only via state machine in tests)
- SaveUI slot highlight position is hardcoded (doesn't move with selection)

We also discovered during S2-001 that:
- GUT headless tests don't catch Godot 4.6 HiDPI native crashes
- We had 3 rounds of "fix" announcements for the same indent issue (tabs / CRLF / mixed)
- Diagnostic prints leaked into final code multiple times

This sprint fixes the visible polish issues AND adds structural guards to prevent recurrence.

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|-------------------|
| S3-001 | Fix PauseMenu layout (centered vbox, no overlap) | gameplay-programmer | 0.25 | None | F5: pause menu items visible + centered; Esc/Up/Down navigable; all 5 menu items fit on screen |
| S3-002 | Fix HUD "PAUSED" state badge | gameplay-programmer | 0.1 | None | F5: Esc to pause → HUD shows "PAUSED" badge with correct color; resume → "EXPLORING" |
| S3-003 | DialogueUI choice highlight | ui-programmer | 0.25 | None | F5: Vera dialogue → 1/2/3 options visible; current selection has arrow/highlight; W/S or 1/2/3 changes selection |
| S3-004 | Add Codex in-game opener (press C) | gameplay-programmer | 0.5 | None | F5: press C in exploration → CodexUI visible with all 6 weapons + 5 enemies; press C again or Esc closes |
| S3-005 | Add indent lint guard (CI) | devops-engineer | 0.5 | None | New `tools/lint_indent.gd` runs on every commit via GitHub Actions; fails build if tabs/CRLF/mixed indent found in src/ tests/ or data/ |
| S3-006 | Add "no _draw in UI" lint guard | devops-engineer | 0.25 | S2-001 (root cause) | Lint rule in `tools/lint_no_draw.gd` scans src/ui/ and src/battle/ for `func _draw` and `draw_string`; fails build if any found; documentation comment links to the HiDPI crash in the agent memory file |
| S3-007 | F5 smoke test gate before sprint close | qa-tester | 0.25 | None | Sprint close report includes F5 verification log: each Must Have task was F5-tested, not just GUT-passed |

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|-------------------|
| S3-010 | SaveUI slot highlight moves with selection | ui-programmer | 0.25 | None | F5: open save UI → highlight follows selected slot when arrow keys pressed |
| S3-011 | PauseMenu confirm dialog (quit to title) | gameplay-programmer | 0.25 | S3-001 | F5: Esc → pause → "QUIT TO TITLE" → confirm YES/NO dialog; YES goes to title, NO stays in pause |
| S3-012 | Onboarding hint visual (centered, larger text) | ux-designer | 0.25 | None | F5: room 0 first 10s shows centered, readable hint at screen center; not overlapping HUD |
| S3-013 | Diagnostics: add sprint-close checklist | producer | 0.25 | None | New `production/sprints/close-checklist.md` with required F5 verification log section; reference in close report template |

### Nice to Have (Cut First)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|-------------------|
| S3-020 | Mech part equipment in HUD | gameplay-programmer | 1.0 | None | F5: cycle 1/2/3 → mech parts swap, stats update, attack+defense change |
| S3-021 | Add a 11th secret room (post-boss) | level-designer | 1.0 | None | F5: beat boss → secret room unlocks; contains rare weapon |

## Risks to This Sprint

| Risk | Probability | Impact | Mitigation | Owner |
|------|------------|--------|-----------|-------|
| Sprint 2 polish touches _draw (re-introduces HiDPI crash) | Medium | High | S3-006 lint guard before any sprint work; F5 verify in S3-007 | qa-tester |
| F5 verify step gets skipped again | Medium | Medium | S3-007 makes it part of the Definition of Done for every task | producer |
| Codex in-game opener conflicts with input bindings | Low | Low | C key not currently bound; if conflict, use Tab | gameplay-programmer |

## Definition of Done

- [ ] All Must Have tasks completed
- [ ] Each Must Have task has F5 verification log entry (not just GUT pass)
- [ ] Indent lint guard installed + tested (commit a file with tab → build fails)
- [ ] No-draw lint guard installed + tested (introduce a `func _draw` → build fails)
- [ ] No new HiDPI / state_changed / indent regressions
- [ ] 348+ tests still pass
- [ ] Code health: no TODO/FIXME residue from S2-001 diagnostic prints
