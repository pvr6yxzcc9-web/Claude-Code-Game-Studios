# Review Log — 游戏状态机 (Game State Machine)

> Source: `design/gdd/game-state-machine.md`
> Review mode: solo (per `production/review-mode.txt`)
> Analyst depth: lean (per `--depth lean`)

---

## Review — 2026-06-12 (first review) — Verdict: APPROVED

**Scope signal:** M
**Specialists consulted:** None (lean mode, per user direction)
**Analyst:** main session
**Blocking items:** 0 | **Recommended:** 7 | **Nice-to-have:** 3

### Summary

First review of the Game State Machine GDD (367 lines, 8 required sections + Visual/Audio + UI bonus sections). 7 invariants, 4 formulas, 11 edge cases, 8 tuning knobs, 15 acceptance criteria. All cross-doc bidirectional constraints to `player-input.md` (C-R6 autoload order, C-R4 subscribe API, F4 pause input drop) verified against the Approved 2026-06-12 version. GDD is structurally clean — no blockers. Recommended follow-ups are operational hygiene around Godot pause semantics (Rec #4) and timing budget enforcement (Rec #2). The 9 downstream systems are all interface contracts, not implementation complexity, justifying scope signal M.

**Prior verdict resolved:** N/A (first review)

### Key decisions reaffirmed
- **Lean mode accepted** — no specialist agents spawned. Cross-doc consistency to `player-input.md` is sufficient inline (player-input is already Approved). Godot 4.6 API reference for `NOTIFICATION_WM_WINDOW_FOCUS_*` is version-pinned in the engine reference directory.
- **Stack-based state model** (LIFO, not dictionary) is the right call for this game — modal overlays (PAUSE/CODEX/TERMINAL) require stack semantics for clean push/pop, and the 3-layer cap (F2) is a clear UX constraint.
- **Autoload ordering as a hard rule** (C-R6) with explicit error reporting (AC-7) is a Foundation-layer discipline. The GDD is authoritative; a separate ADR is likely **redundant** — flagged for `technical-director` to confirm.
- **No "transition_class" concept in MVP** (Open Q #1) — all transitions are instant. This is correct for MVP; deferred decision is appropriate.

### Recommended (non-blocking) follow-ups
1. **Rec #1** (autoload error frequency): AC-7 says "console 每秒 warning 一次" — clarify log level + release-build downgrade + fix instruction.
2. **Rec #2** (F1 budget upper bound on `_ready`): new state's `_ready` ≤ 5ms constraint needs explicit lazy-init partitioning if exceeded.
3. **Rec #3** (F4 weak ref semantics): AC-12 should explicitly require `is_instance_valid()` check in addition to `Callable.is_null()`.
4. **Rec #4** (Godot pause semantics): add code-review checklist rule that every `state_*.gd` `_process`/`_physics_process` starts with `if get_tree().paused: return`.
5. **Rec #5** (audio feedback): defer illegal-transition silence to `player-input.md` F2 refused feedback to avoid double-feedback.
6. **Rec #6** (cross-doc API check): verify `push(TERMINAL)` vocabulary matches `npc-terminal.md` API in `/review-all-gdds`.
7. **Rec #7** (Open Q #1 deadline): rename "VS 阶段" → "α 评估" with explicit decision point at α gate.

### Nice-to-have
- ASCII flowchart of legal transition graph in an appendix (helpful for new implementers).
- AC-15 references `player-input.md` "UI-2 / UI-2b" but the actual section heading is "UI Requirements UI-2b" — cosmetic anchor fix.
- Add ADR reference for "closed-set states in MVP" rationale (separate from the autoload ordering decision).

### Manual checks deferred
- `npc-terminal.md` cross-check on `push(TERMINAL)` API vocabulary — verify in `/review-all-gdds`.
- `technical-director` confirmation: does the autoload ordering rule warrant a separate ADR, or is the GDD authoritative?
- Rec #4's "no `_process` in paused state" rule — implement as a custom linter or rely on code review? Decision belongs in implementation.

### Post-Approval
- Status in `systems-index.md`: Approved (line 24 updated)
- GDD frontmatter: updated to `Status: Approved` + `Review Verdict: APPROVED (first review 2026-06-12)`
- Tracking: **3/12 MVP GDDs approved** (Resource/Data, Player Input, Game State Machine). 9 remaining GDDs in pipeline.
- Next pipeline step: Phase 1d — `/design-review camera.md` (next Foundation GDD).
