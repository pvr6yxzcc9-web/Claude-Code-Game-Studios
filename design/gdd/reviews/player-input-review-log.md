# Review Log — Player Input (玩家输入)

> Source: `design/gdd/player-input.md`
> Review mode: solo (per `production/review-mode.txt`)
> Analyst depth: full (prior) + lean (re-review)

---

## Review — 2026-06-12 (lean re-review) — Verdict: APPROVED

**Scope signal:** L
**Specialists consulted:** None (lean mode, per user direction)
**Analyst:** main session
**Blocking items:** 0 | **Recommended:** 3 | **Nice-to-have:** 3

### Summary

Post-revision re-review of Player Input GDD on the same day (2026-06-12), triggered by user's `/gate-check` invocation that flagged "0/12 GDDs Approved" as a gate blocker. Prior review verdict (also 2026-06-12) was **MAJOR REVISION NEEDED** with 4 blocking items (Blk #1 modal transparency, Blk #2 untestable ACs, Blk #3 Godot 4.6 API mis-description, Blk #4 dishonest gamepad coverage) and 6 important recommendations (Rec #5-#10). All 4 blockers + all 6 recommendations were resolved in the same session via a complete revision plan at `design/gdd/reviews/player-input-revision-plan-2026-06-12.md` and applied edits to the GDD body. This lean re-review verifies that all 10 items are correctly applied.

**Prior verdict resolved:** Yes (MAJOR REVISION NEEDED → APPROVED)

### Key decisions reaffirmed
- **Lean mode accepted** — no specialist agents spawned. Each prior item was verified by reading the relevant GDD section and confirming the resolution is present at root cause (not symptom-level patches).
- **47-action closed set is stable** — confirmed via `input-bindings.yaml` (47 actions, 8 input constants + 3 formulas registered in `entities.yaml`).
- **ADR-0006 deferral is correct** — Player Input's `InputBus` autoload vs. singleton decision is technical and belongs in architecture, not design.

### Items verified
- **Blk #1** (modal transparency): UI-2b state badge always-visible, C-R6 focus routing, G1 binding change note (Esc→Q in Battle), "bound-elsewhere" refusal category in C-R3 input refused feedback.
- **Blk #2** (testable ACs + 13 new): AC-1 to AC-25 all present, mock-clock DI point documented, test evidence location split GUT vs NUnit.
- **Blk #3** (Godot 4.6 API correctness): E2 removes `force_dispatch_pending` entirely + requires InputBus autoload listed after GameStateMachine; C-R3 documents `action_held` custom timer implementation; OQ-2 has 4.6 verification note for `start_joy_vibration`.
- **Blk #4** (gamepad coverage honest): G1 lines 454-474 contain explicit per-action matrix with ✅/❌ + honest partial-parity summary.
- **Rec #5** (latency framing): AC-8 splits p99 ≤ 16.5ms (hard ceiling) + median ≤ 33ms (perception threshold).
- **Rec #6** (action-count split): AC-1 = 47 dev / 43 release; AC-22 debug stripping; `input_action_count_release: 43` in registry.
- **Rec #7** (autoload + subscription): E9 explicit `subscribe_to_input_bus` / `unsubscribe_from_input_bus` API replaces `_enter_tree`/`_exit_tree` magic.
- **Rec #8** (refusal fatigue): E11 4-level escalation (L0 audio + hint → L3 visual flicker only).
- **Rec #10** (held-preserved): E10 snapshot+replay on state transition.

### Recommended (non-blocking) follow-ups
1. OQ-2 verification note: add a file anchor (`docs/engine-reference/godot/breaking-changes.md#input-start-joy-vibration`) so the implementer doesn't have to grep.
2. Add AC-26: changing `focus_visual_focus_style` in Settings changes the focus highlight style within 0.5s.
3. C-R4 should explicitly state that System actions (pause, save, load, screenshot, quit_to_title) are subscribed by every state — the only C-R4 exception.

### Manual checks deferred
- The 8 input constants in `entities.yaml` are all self-referencing. Expand `referenced_by` to downstream consumers (Battle Core, Weapon, etc.) as they're reviewed.
- E11's 60s window vs `_refusal_count_session` per-action/per-state/per-session semantics — quick check during implementation.

### Post-Approval
- Status in `systems-index.md`: Approved (line 23 updated)
- GDD frontmatter: updated to `Status: Approved` + `Review Verdict: APPROVED (post-revision, lean re-review 2026-06-12)`
- Tracking: **2/12 MVP GDDs approved** (Resource/Data, Player Input). 10 remaining GDDs in pipeline.
- Next pipeline step: review the other Foundation GDDs (game-state-machine, camera, collision) before moving to Core (battle-core-loop).
