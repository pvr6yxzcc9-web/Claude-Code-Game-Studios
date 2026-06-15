# Review Log — 暗雷遇敌 (Random Encounter)

> Source: `design/gdd/random-encounter.md`
> Review mode: solo (per `production/review-mode.txt`)
> Analyst depth: lean (per `--depth lean`)
> **Prototype-validated:** no (trigger mechanic not prototype-validated; gameplay validated via #7 battle-core prototype, encounter rate needs playtest data)

---

## Review — 2026-06-12 (first review) — Verdict: APPROVED

**Scope signal:** S
**Specialists consulted:** None (lean mode, per user direction)
**Analyst:** main session
**Blocking items:** 0 | **Recommended:** 5 | **Nice-to-have:** 5

### Summary

First review of the Random Encounter GDD (273 lines, 8 required sections + Visual/Audio + UI + Dependencies bonus sections). 6 invariants, 4 formulas, 8 edge cases, 6 tuning knobs, 11 acceptance criteria. Carries **Pillar 1 (探索密度)** and **Pillar 3 (build 试验)** through the encounter trigger mechanic + EncounterTable. The 4-state tile lifecycle (READY/COOLDOWN/TRIGGERED/RESETTING) is exemplary. C-R2's "禁止绕过状态机直接调战斗" + C-R6 + #5 E7 cross-doc double-belt for battle-storm prevention is the right layered-defense pattern. AC-7 Monte Carlo validation (with revised N=10000 95% CI, per resource-data AC-7 pattern) is the strongest statistical AC in the project after #1. Cross-doc bidirectional constraints to all 4 Foundation GDDs + #7 Battle Core + #15 Level-Dungeon (all Approved 2026-06-12) verified clean. **The 5th GDD in a row with a bidirectional cross-doc constraints table — project standard solidified.**

**Prior verdict resolved:** N/A (first review)

### Key decisions reaffirmed
- **Lean mode accepted** — no specialist agents spawned. Cross-doc consistency to 5 already-Approved GDDs is sufficient inline. The trigger mechanic is small enough to verify in one pass.
- **4-state tile lifecycle (READY/COOLDOWN/TRIGGERED/RESETTING)** is a clean LOCAL state machine, complementing global #3. The COOLDOWN → TRIGGERED transition is implicit (same frame) — could be made explicit, but not blocking.
- **C-R3 "玩家离开 reset"** correctly preserves Pillar 1 "回头探索" — repeated trigger is intentional (per OQ #5). HUD `X / Y` semantics need clarification (Rec #5).
- **C-R2 routes through `GameStateMachine.transition_to(BATTLE, payload={enemy_data})`** per #3 transition API. This is the right architectural invariant — promote to ADR: "ADR-STATE-MACHINE-MEDIATION — All state transitions go through GameStateMachine."
- **C-R5 EncounterTable data-driven + hand-crafted (per #15 C-R1)** is the right combination — no procedural generation, but YAML structure allows easy authoring.
- **C-R6 + #5 E7 cross-doc double-belt** is the layered-defense pattern: tile.monitoring = false (this GDD) + physical layer monitoring = false (Collision E8) + transition_to(BATTLE) state change (State Machine). All three together = battle-storm prevention.
- **F2 enemy distribution (88% grunt / 12% elite / 0% boss in chapter 1)** + AC-7 Monte Carlo validation is the right calibration. N=10000 95% CI for binomial(10000, 0.8) is the correct sample size for statistical validity.
- **F3 "dash 加速让遇敌翻倍——激励玩家'安全慢走'"** is a thoughtful emergent game design (exploitable but intentional, per OQ #5). Dash farm is a design tradeoff.
- **Rec #7 cross-doc check verified:** random-encounter.md is consistent with #15 F1 (chapter 1 = 1 weapon drop). The "4 ≠ 12" inconsistency is in #11/#15 cross-doc, NOT in random-encounter. Tracked in #15 Open Questions (Rec #7) for `/review-all-gdds`.

### Recommended (non-blocking) follow-ups
1. **Rec #1** (E4 1000 次 Monte Carlo 验证 — needs implementation note): AC-7 specifies "1000 次 Monte Carlo" but doesn't say "with fixed seed for determinism". Recommend: "AC-7b: GIVEN chapter 1 EncounterTable + fixed RNG seed = 42, run 1000 encounters, assert grunt count ∈ [840, 920] (88% ± 4%) + elite count ∈ [80, 160] (12% ± 4%) + boss count = 0." Per Coding Standards: "Tests must produce the same result every run — no random seeds". **Deferred to QA/test-setup phase (no implementation block).**
2. **Rec #2** (C-R3 cooldown reset semantics — needs explicit cooldown duration): C-R3 says "玩家离开 tile 区域 → cooldown = false". Is "离开" instant? Or after N seconds (anti-instant-retrigger)? Recommend: `cooldown_reset_delay_s = 0.2` (tunable). Prevents pixel-perfect exploit of "leave 1 pixel → re-enter". **Appended to Open Questions for tracking.**
3. **Rec #3** (F3 dash + 遇敌翻倍 — exploitable): F3 says "dash 加速让遇敌翻倍——激励玩家'安全慢走'". This is a **double-edged sword**: 8 tile/s = 1 encounter / 12s = farm encounters too fast. Recommend add a check: "Auto-mode + EncounterTileFarm = true → RNG seed advances (per chapter save point), preventing infinite farm." **Deferred to playtest phase (design tradeoff, no implementation block).**
4. **Rec #4** (C-R5 EncounterTable 缺 `enemies_defeated_this_tile` 跟踪): For "X / Y" HUD display, need to track which tiles have been triggered. Add to EncounterTable: `tiles_triggered: Array[bool]` or per-tile `cooldown` is sufficient. C-R3's "离开 reset" means cooldown IS the trigger history — clarify. **Deferred to HUD GDD review phase (no implementation block).**
5. **Rec #5** (OQ #5 "刷怪" 是有意的 — needs GDD reinforcement): C-R3 says "禁止永久禁用". Add explicit: "**C-R3b**: Repeat-trigger (re-enter same tile after leaving) is **intentional** (per Pillar 1 回头探索 + auto-mode farming). HUD `X / Y` counter should NOT increment on re-trigger (per chapter unique count, not total triggers)." **Appended to Open Questions for tracking.**

### Nice-to-have
- 4-state tile lifecycle is exemplary. Replicate for any trigger-based system (e.g., pressure plates, scripted events).
- C-R2's "禁止绕过状态机直接调战斗" is a great architectural invariant. Should be promoted to ADR: "ADR-STATE-MACHINE-MEDIATION — All state transitions go through GameStateMachine. No direct scene change."
- C-R6 + #5 E7 cross-doc double-belt is a great example of layered defense.
- EncounterTable YAML structure is a good example of data-driven design. Promote to `design/registry/encounter-tables.yaml` as code, like `entities.yaml` and `input-bindings.yaml`.
- F2 enemy distribution ratio (88/12/0) + AC-7 Monte Carlo validation is exemplary statistical verification.
- F3 "dash 加速让遇敌翻倍——激励玩家'安全慢走'" is a thoughtful emergent game design (exploitable but intentional, per OQ #5).
- V/A "DEFEAT rig + 3° roll + 灰度" is concrete and implementable. Replicate in `battle-core-loop.md` defeat feedback.

### Manual checks deferred
- HUD push API (`encounter_count: int` / `encounter_total: int`) — verify in `/review-all-gdds` (Phase 1k: HUD review)
- #21 save-load cross-check on `encounter_count` serialization — verify in `/review-all-gdds` (Phase 1l: save-load review)
- Battle Core #7 cross-check on BATTLE transition payload contract — verify in `/review-all-gdds`
- #15 level-dungeon Rec #7 cross-doc consistency (Chapter 1 weapon count vs weapon-ammo TOTAL = 12) — tracked in #15 Open Questions, NOT a blocker for this GDD

### Post-Approval
- Status in `systems-index.md`: Approved (line 38 updated, Random Encounter). **Feature layer 4/4 complete (Weapon+Ammo + Level/Dungeon + Random Encounter = 3 GDDs in 4 layer).** Foundation 5/5 + Core 1/1 = 6. Feature 3/3 = 3. Total = 9.
- GDD frontmatter: updated to `Status: Approved` + `Review Verdict: APPROVED (first review 2026-06-12, lean)`
- Open Questions: Rec #2 (cooldown reset duration 0.2s) + Rec #5 (HUD "X / Y" per-tile-unique semantics) appended for tracking. Rec #1, #3, #4 deferred.
- Tracking: **9/12 MVP GDDs approved**. 3 remaining GDDs in pipeline (1 Feature NPC + 2 Presentation HUD + SaveLoad).
- Next pipeline step: Phase 1j — `/design-review npc-terminal.md` (Feature layer, Pillar 4 narrative logs, S scope).
