# Review Log — 相机系统 (Camera)

> Source: `design/gdd/camera.md`
> Review mode: solo (per `production/review-mode.txt`)
> Analyst depth: lean (per `--depth lean`)

---

## Review — 2026-06-12 (first review) — Verdict: APPROVED

**Scope signal:** M
**Specialists consulted:** None (lean mode, per user direction)
**Analyst:** main session
**Blocking items:** 0 | **Recommended:** 7 | **Nice-to-have:** 4

### Summary

First review of the Camera GDD (340 lines, 8 required sections + Visual/Audio + UI bonus sections). 7 invariants, 5 formulas, 10 edge cases, 13 tuning knobs, 15 acceptance criteria. All cross-doc bidirectional constraints to `game-state-machine.md` (STATE_TO_RIG_MAP, C-R3 rig signal, MENU/PAUSE preservation) verified against the Approved 2026-06-12 version. GDD is structurally clean — no blockers. Recommended follow-ups are: (1) TITLE → RIG_CODEX_WIDE mapping semantic clarification (Rec #1, user-attention needed), (2) Godot 4.6 `Camera2D.enabled` API verification (Rec #2, implementation-time check), and (3) cross-doc API consistency checks (Rec #7, to be verified in `/review-all-gdds`).

**Prior verdict resolved:** N/A (first review)

### Key decisions reaffirmed
- **Lean mode accepted** — no specialist agents spawned. Cross-doc consistency to `game-state-machine.md` is sufficient inline (already Approved). Godot 4.6 API flags are tracked as Rec #2 (verify at implementation time, not block approval).
- **State→Rig mapping with single exception (C-R3 + C-R5)** is the right architecture. Battle system is the only system allowed to override the default rig (for VICTORY/DEFEAT). This single-exception pattern prevents the typical "every system wants to control the camera" antipattern.
- **5 transition effects** (INSTANT / FADE_BLACK / ZOOM / FLASH_WHITE / SHAKE_AND_FADE) is a small enough set to be implementable cleanly. Each has a clear use case in the Player Fantasy.
- **Shake accumulation budget** (C-R6, F1) is a precise constraint with AC-8 testing it. This is the kind of discipline a "feel" system needs — without a budget, shakes can stack into a strobe effect that causes motion sickness.
- **UI independence** (C-R7, AC-13, AC-14) correctly uses Godot 4.6's CanvasLayer model. The 0.5× shake allowance is a thoughtful concession — fully static UI during shake would create visual tearing.

### Recommended (non-blocking) follow-ups
1. **Rec #1** (TITLE → RIG_CODEX_WIDE semantic clarification): STATE_TO_RIG_MAP maps TITLE to RIG_CODEX_WIDE. Is TITLE the main menu (in which case a separate RIG_TITLE_MENU might be cleaner) or a fade-in to the satellite in-world view? **Added to Open Questions for user adjudication.** (Source: cross-doc review of #3 GDD C-R3 + this GDD's STATE_TO_RIG_MAP.)
2. **Rec #2** (Godot 4.6 `Camera2D.enabled` API): C-R2 specifies "all rigs保留在树中但 `enabled = false`" but Godot 4.6 canonical API is `Camera2D.make_current()`. Verify against `docs/engine-reference/godot/breaking-changes.md` at implementation time. (Source: 4.6 high-risk engine version, post-cutoff.)
3. **Rec #3** (Transition Lock + UX feedback): Edge case #8's "0.6s 切换锁定" may feel like "input ignored" if not surfaced. Add audio refused-feedback per `player-input.md` F2. (Source: cross-doc consistency.)
4. **Rec #4** (Shake accumulation math clarity): F1 says "连续 2 秒窗口内累积幅度 ≤ 30px" but reset semantics are unclear (sliding window vs fixed). Specify: "2s sliding window; over-budget scales down most recent shake by over-budget ratio." (Source: implicit ambiguity in F1.)
5. **Rec #5** (Boss战 auto-zoom 0.8× vs tuning knob range): Edge case #5 auto-zooms to 0.8× for large battlefields, but BATTLE_OVERHEAD_ZOOM tuning knob safe range is 1.0-1.5. Lower the safe range to 0.8-1.5 or add a separate `BATTLE_OVERHEAD_AUTO_ZOOM_MAX` knob. (Source: AC doesn't explicitly test 0.8×.)
6. **Rec #6** (DEFEAT grayscale implementation note): Specify "DEFEAT grayscale: full-screen ColorRect with `material = ShaderMaterial { shader = grayscale_shader }` on a separate CanvasLayer above game world, below HUD." (Source: C-R7 UI independence + pixel-art NEAREST filter compatibility.)
7. **Rec #7** (Cross-doc API verification in `/review-all-gdds`): Verify `set_rig(X)`, `set_closeup_target(node)`, `set_follow_target(node)` API contracts match downstream GDDs (battle-core-loop, npc-terminal, level-dungeon). (Source: `rules/design-docs.md` "Dependencies must be bidirectional".)

### Nice-to-have
- ASCII diagram per rig (where pointed, what it includes, what it excludes).
- Wireframe storyboard for full battle sequence: `EXPLORATION_FOLLOW → FADE_BLACK 0.4s → BATTLE_OVERHEAD → ZOOM 0.6s → VICTORY → FADE_BLACK 0.4s → EXPLORATION_FOLLOW`.
- Code comment in rig resource: "2.0× is the NEAREST pixel-art ceiling; do not exceed without changing texture filter."
- AC-11 (Light2D performance negative test) is exemplary — replicate this pattern in other GDDs.

### Manual checks deferred
- `npc-terminal.md` cross-check on `set_closeup_target()` API — verify in `/review-all-gdds`.
- `battle-core-loop.md` cross-check on `set_rig(VICTORY/DEFEAT)` trigger — verify in `/review-all-gdds`.
- `level-dungeon.md` cross-check on `set_follow_target(player_mech)` timing — verify in `/review-all-gdds`.
- Godot 4.6 `Camera2D.enabled` post-cutoff behavior — verify at implementation time against `docs/engine-reference/godot/`.

### Post-Approval
- Status in `systems-index.md`: Approved (line 26 updated)
- GDD frontmatter: updated to `Status: Approved` + `Review Verdict: APPROVED (first review 2026-06-12, lean)`
- Open Questions: Rec #1 (TITLE → RIG_CODEX_WIDE semantic) appended for user adjudication
- Tracking: **4/12 MVP GDDs approved** (Resource/Data, Player Input, Game State Machine, Camera). 8 remaining GDDs in pipeline.
- Next pipeline step: Phase 1e — `/design-review collision.md` (final Foundation GDD).
