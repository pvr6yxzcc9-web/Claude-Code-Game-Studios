# Sprint [N] — Close Report

> **Sprint**: [N] — [Name]
> **Dates**: [start date] → [end date]
> **Outcome**: **[COMPLETE | PARTIAL | BLOCKED]** — [N]/[M] tasks done, [test count] tests pass

> **This template is the source of truth for sprint close reports** (per S3-007).
> The F5 verification log section is **required** — closing a sprint without it
> is a process violation. GUT headless tests cannot catch every class of bug
> (HiDPI _draw crashes, missing visual elements, layout regressions), so the
> F5 log is the only proof that user-facing behavior actually works.

## Summary

[1-2 paragraphs: what was the goal, what was actually delivered, headline numbers.]

**Final test count: [N] / [N] PASS** (was [X] at end of Sprint [N-1]).

## Task Status

### Must Have — [X]/[X] Done

| ID | Task | Status | GUT Evidence | F5 Evidence |
|----|------|--------|--------------|-------------|
| S[N]-001 | [name] | Done / Partial / Blocked | [test runner + count] | [F5 date + verifier + observation] |

### Should Have — [X]/[X] Done

[Same column layout as Must Have.]

### Nice to Have — [X]/[X] Done

[Same column layout.]

**Total: [X]/[X] tasks complete.**

## F5 Verification Log (Required)

> **F5** = the user pressing F5 in the Godot editor (or running `godot`
> on the project's main scene) and exercising the feature end-to-end in the
> actual windowed editor / standalone runtime. GUT runs headless and does not
> execute `_draw` callbacks, so HiDPI crashes, visual layout issues, and
> missing UI children are invisible to the test suite. F5 is the only check
> that catches them.
>
> **Each Must Have task MUST have an F5 row below.** The "observation" column
> is the actual thing the verifier saw on screen, not a paraphrase of the task
> description. If a task cannot be F5-verified, explain why in the row and
> mark the verdict "N/A" (e.g., a CI-only lint guard has no UI to F5).

| ID | F5 Date | Verifier | Scene / Trigger | Observation (what was actually seen) | Screenshot | Verdict |
|----|---------|----------|-----------------|---------------------------------------|------------|---------|
| S[N]-001 | 2026-MM-DD | user | main.tscn → Esc in room 0 | [e.g., "Pause menu visible; 5 items listed; arrow keys move highlight; Enter activates RESUME; Esc closes; no debugger detach"] | production/qa/evidence/s[N]-001-pause.png | PASS |
| S[N]-002 | ... | ... | ... | ... | ... | ... |

**Verdict legend**: PASS = behavior matches AC, FAIL = behavior diverges, N/A = task is non-visual (e.g., CI lint).

## What Went Well

1. ...

## What Didn't Go Well

1. ...

## Acceptance Criteria Audit

| Sprint AC | Met? | Notes |
|-----------|------|-------|
| [AC 1] | Yes / Partial / No | [evidence] |

## Definition of Done

- [ ] All Must Have tasks completed
- [ ] **Each Must Have task has an F5 verification log entry above** (S3-007)
- [ ] All tasks pass acceptance criteria
- [ ] Test suite PASS ([N]/[N])
- [ ] No regression vs. prior sprint's tests
- [ ] Lint guards PASS (indent, no-_draw, etc. — whichever apply)
- [ ] No new HiDPI / state machine / indent / TODO-FIXME regressions

## Code Stats

| Category | Sprint [N-1] | Sprint [N] | Delta |
|----------|--------------|------------|-------|
| Test scripts | | | |
| Test count | | | |
| ... | | | |

## Carryover / Backlog for Sprint [N+1]

| Item | Reason | Priority |
|------|--------|----------|
| | | |

## Process Observations for Sprint [N+1]

- ...

## Verdict

**[COMPLETE | PARTIAL | BLOCKED]** — [one-paragraph summary: what was delivered, what slipped, what the next sprint should know.]

---

> **Template notes** (delete before publishing):
> - The F5 verification log is the structural fix for the S2-001 lesson (3 sessions
>   to ship a feature because GUT passed but F5 crashed). It is the cheapest,
>   highest-signal addition to a sprint close: a one-line observation per Must
>   Have task. Skipping it is how HiDPI-class bugs ship.
> - "Verifier" is whoever actually pressed F5. For solo work, that's the user.
> - "Observation" must be the actual on-screen behavior. "It worked" is not an
>   observation; "Pause menu items appeared centered; arrow keys moved the
>   highlight from RESUME to SAVE" is.
> - Screenshots are optional but strongly recommended for visual changes. Save
>   under `production/qa/evidence/`.
