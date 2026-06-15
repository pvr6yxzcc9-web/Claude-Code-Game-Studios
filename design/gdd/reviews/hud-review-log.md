# Review Log — HUD

> Source: `design/gdd/hud.md`
> Review mode: solo (per `production/review-mode.txt`)
> Analyst depth: lean (per `--depth lean`)
> **Prototype-validated:** no (HUD is Presentation layer; layout will be validated via `/ux-review` per-screen)

---

## Review — 2026-06-12 (first review) — Verdict: APPROVED

**Scope signal:** M
**Specialists consulted:** None (lean mode, per user direction)
**Analyst:** main session
**Blocking items:** 0 | **Recommended:** 6 | **Nice-to-have:** 9

### Summary

First review of the HUD GDD (346 lines, 8 required sections + Visual/Audio + UI + Dependencies bonus sections). 7 invariants, 4 formulas, 10 edge cases, 8 tuning knobs, 20 acceptance criteria. Carries **Pillar 1 (探索密度)** through the "always visible state" principle + "14 HUD elements" table. C-R5 "stateless view" is the canonical state-consumer pattern. C-R3 "永远可见" + C-R2 "shake 0.5x" + F3 "0.20 lerp" are thoughtful UI design. 20 ACs covering state visibility / HUD variations / performance budgets is the right AC count for a Presentation GDD. Cross-doc consistency to 8 Approved GDDs (3 Foundation + 1 Core + 4 Feature) verified — the most cross-doc-consuming GDD in the project. **The 7th GDD in a row with a bidirectional cross-doc constraints table — project standard fully established.**

**Prior verdict resolved:** N/A (first review)

### Key decisions reaffirmed
- **Lean mode accepted** — no specialist agents spawned. HUD is Presentation layer; specialist design validation comes from `/ux-review` per-screen, not `/design-review`.
- **7 invariants cleanly define the contract**: CanvasLayer placement (C-R1), shake 0.5x (C-R2), always-visible (C-R3), priority order (C-R4), stateless consumer (C-R5), 60 FPS (C-R6), art-bible fonts (C-R7).
- **14 HUD elements table** with position + visibility + data source is exemplary. This is the right granularity for a Presentation GDD.
- **C-R5 "HUD 不持有游戏状态，只消费 state: Dictionary"** is the canonical state-consumer pattern. Should be promoted to ADR: "ADR-STATELESS-VIEW — HUD elements read from state dicts pushed by owners; never write to game state."
- **C-R3 "永远可见" + E9 exception for chapter summary** is the right principle. Player always oriented. Rec #6 enumerates 3 more potential exceptions (cutscenes, save/load, quit).
- **F1 1.95ms total render budget** is well within 16.6ms frame budget. Per-element breakdown is concrete and implementable.
- **F2 飘字 0.5s + 50px + ease_out_quad** is a concrete, implementable animation spec. The "0 damage不飘字" (E10) is a thoughtful UX choice.
- **F3 0.20 lerp factor for HP bar** is a "no jump" pattern that should be replicated for any animated UI state.
- **F4 weapon slot pulse 0.5 Hz** is a subtle visual hint for active weapon. The 8 Hz `sin(time * 8.0)` formula is concrete and implementable.
- **C-R7 "art-bible 字体 + 禁止默认系统字体"** is a great explicit non-feature.
- **20 ACs** is appropriate for M scope. AC-18 (chapter summary with X/10 + Y/16 + Z/4) is a great "completion %" validation. AC-19/-20 (performance) are exemplary.
- **7th GDD in a row** with cross-doc bidirectional constraints table. Project standard fully established.

### Recommended (non-blocking) follow-ups
1. **Rec #1** (HUD needs to commit to #16 "X / Y" per-tile-unique semantics): Random-encounter.md OQ Rec #5 already flags "per-tile-unique vs total-triggers" as a HUD GDD decision. HUD should commit to **per-tile-unique** and document in C-R or F. **Appended to Open Questions for tracking.**
2. **Rec #2** (14 elements + 2 overlay behaviors note): F4 (weapon slot pulse) + C-R2 (shake) are behaviors that overlay on multiple elements. Add note: "14 elements + 2 overlay behaviors (shake + pulse)". **Deferred to GDD update (no implementation block).**
3. **Rec #3** (AC-18 "Z/4 真相碎片" may break with #18 shared fragment count): #18 npc-terminal F1 says "4 fragments from 6 terminals + 1 NPC" with **2 shared** (Rec #2 from #18 review). If shared fragments are 1:1 strict, count differs. HUD should use `unlocked_fragments.size()` not hardcoded "4". Add AC-18b. **Appended to Open Questions for tracking.**
4. **Rec #4** (HUD save/load — 1 line, no AC): Add AC-21: "GIVEN 玩家章节 1 末尾存档 + 重新载入 WHEN 测 HUD THEN 所有 14 元素 = 保存时状态 (HP / weapon slots / encounter count / fragment count) 重现." **Appended to Open Questions for tracking.**
5. **Rec #5** (F1 1.95ms total — empirical test, not theoretical): F1 is planning estimate. Add AC-19b (ADVISORY): "GIVEN 14 elements rendered on RTX 3060 / 4K WHEN profile THEN avg hud_render_time_ms ≤ 4ms". **Deferred (no MVP block).**
6. **Rec #6** (C-R3 "永远可见" needs explicit exception enumeration): C-R3 + E9 has 1 exception. Other potential exceptions: cutscenes, save/load modal, quit dialog. Recommend: enumerate in C-R3. **Appended to Open Questions for tracking.**

### Nice-to-have
- "14 elements" table is exemplary — element name + position + visibility condition + data source. Replicate in any "state visualization" GDD.
- C-R5 "stateless view" pattern is canonical. Promote to `docs/architecture/patterns.md`.
- C-R3 "永远可见" + E9 exception + Rec #6 enumerated exceptions is the right principle.
- F3 0.20 lerp factor is a thoughtful "no jump" pattern. Replicate for any animated UI state.
- F2 飘字 0.5s + 50px + ease_out_quad is concrete. Replicate for any "feedback float" (XP gain, gold gain).
- C-R7 "art-bible 字体 + 禁止默认系统字体" is a great explicit non-feature.
- C-R2 "shake 0.5x 跟" + AC-16 is a layered-defense against visual tear.
- E10 "0 伤害不飘字" is a thoughtful UX choice. 0-damage spam would dilute "hit" feel.
- 14 ACs covering state visibility / HUD variations / performance is right AC count for Presentation.

### Manual checks deferred
- #21 save-load cross-check on HUD state serialization schema — verify in `/review-all-gdds` (Phase 1l)
- #16 encounter count per-tile-unique vs total-triggers — verify in `/review-all-gdds`
- #18 NPCData as #1 10th subtype — verify in `/review-all-gdds`
- #18 shared fragment count semantics — verify in `/review-all-gdds`
- #23 menu/pause (VS) cross-check on HUD interaction — defer until VS authoring
- #20 codex (VS) cross-check on Codex UI vs HUD — defer until VS authoring
- C-R6 60 FPS performance — verify in `/perf-profile` post-implementation

### Post-Approval
- Status in `systems-index.md`: Approved (line 44 updated, HUD). **Presentation layer 1/2 complete (HUD).** Foundation 5/5 + Core 1/1 = 6. Feature 4/4 = 4. Presentation 1/2 = 1. Total = 11.
- GDD frontmatter: updated to `Status: Approved` + `Review Verdict: APPROVED (first review 2026-06-12, lean)`
- Open Questions: Rec #1 (per-tile-unique encounter), #3 (fragment count defensive), #4 (save/load AC-21), #6 (always-visible exceptions) appended for tracking. Rec #2, #5 deferred.
- Tracking: **11/12 MVP GDDs approved**. 1 remaining GDD in pipeline (1 Presentation SaveLoad).
- Next pipeline step: Phase 1l — `/design-review save-load.md` (Presentation layer, M scope, all system state serializes through this).
