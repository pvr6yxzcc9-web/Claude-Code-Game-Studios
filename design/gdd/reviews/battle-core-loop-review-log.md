# Review Log — 战斗核心循环 (Battle Core Loop)

> Source: `design/gdd/battle-core-loop.md`
> Review mode: solo (per `production/review-mode.txt`)
> Analyst depth: lean (per `--depth lean`)
> **Prototype-validated**: yes (PARTIALLY CONFIRMED for manual/auto dual-mode)

---

## Review — 2026-06-12 (first review) — Verdict: APPROVED

**Scope signal:** L
**Specialists consulted:** None (lean mode, per user direction)
**Analyst:** main session
**Blocking items:** 0 | **Recommended:** 7 | **Nice-to-have:** 5

### Summary

First review of the Battle Core Loop GDD (406 lines, 8 required sections + Visual/Audio + UI bonus sections). 8 invariants, 5 formulas, 13 edge cases, 16 tuning knobs, 28 acceptance criteria. **The strongest GDD in the project**: largest, most-tested, only one that's prototype-validated, has the most tuning knobs. The 4-phase turn structure (PLAYER_INPUT → PLAYER_ACTION → ENEMY_INPUT → ENEMY_ACTION) is rigid and explicit. C-R3 "1/2/3 = 立即攻击" explicitly cites prototype player feedback. C-R4 mode-toggle non-interruption is precisely specified. All 6 cross-doc bidirectional constraints to the 5 Foundation GDDs (all Approved 2026-06-12) are correctly maintained. **Core layer 1/1 complete.**

**Prior verdict resolved:** N/A (first review, prototype-validated)

### Key decisions reaffirmed
- **Lean mode accepted** — no specialist agents spawned. The GDD is prototype-validated and all Foundation cross-doc constraints verified inline. Specialist review would be lower-value than usual for a Core-layer system with prototype learnings baked in.
- **4-phase turn structure (C-R1)** is rigid and explicit. The "1 turn = 4 phases" equation is the right granularity. No "interrupting enemy turn" deferred to OQ #1 for MVP.
- **Mode-toggle non-interruption (C-R4)** is precisely specified with the "玩家可立刻反悔" edge case. This is the kind of detail that prevents "did my mode toggle work?" confusion.
- **Defend 0.5x with single-use (C-R8)** is correct for a tactical RPG (Into the Breach precedent). Edge case #12 (multi-AOE same frame) handles the multi-hit ambiguity cleanly.
- **F1 Final Damage formula** cross-verified with `resource-data.md` tight range (weapon_damage 1-200, ammo_mult 0.5-2.0, crit_mult 1.0-3.0, BOSS HP up to 500). The 5 multiplicative factors with explicit ranges + min/max bounds + worked example is exemplary.
- **C-R6 "battle end = state machine transition_to(EXPLORATION)"** is correct single-responsibility. Death flow delegated to state machine per #3's OQ #2 decision.
- **Visual feedback for "AI thinking"** (0.3s "思考"姿态) is a thoughtful player-facing touch.
- **AC-21 (Monte Carlo 1000-iteration drop rate test)** is exemplary — RNG fairness testing pattern.
- **6-row cross-doc traceability table** is the **gold standard** for cross-doc references. Replicate this pattern in all subsequent GDDs.

### Recommended (non-blocking) follow-ups
1. **Rec #1** (1v1 enemy constraint — multi-enemy formula placeholder): OQ #2 defers multi-enemy to VS, but no F-formula exists for it. Add a "F1b. Multi-enemy spread damage (VS placeholder)" or document the open question. **Appended to Open Questions for tracking.**
2. **Rec #2** (Defend + multi-AOE determinism): AC-26 doesn't specify which hit is "first" when 3 AOE areas overlap same frame. Add AC-26b: "lowest-tick-id hit gets 0.5x (deterministic ordering)."
3. **Rec #3** (BOSS 50% HP behavior change): MVP single-phase BOSS (200-300 HP) risks "trash BOSS" feel. Add threshold-based behavior change at BOSS HP < 50% (new attack pattern + new AOE) for MVP. **Appended to Open Questions for tracking.**
4. **Rec #4** (AI flee ban design intent): C-R5 should document "AI does not flee by design — auto-mode is passive-optimal play, not surrender option" to prevent implementation accidents.
5. **Rec #5** (HP defense × weakness math): F1 formula order is `base × ammo × crit × weakness × defense`. Clarify with worked example: "Defending vs weakness: 25 × 1.5 × 0.5 = 18.75 → 18 (both apply multiplicatively)."
6. **Rec #6** (Battle duration budget test): 15+ turn BOSS with 50ms AI × 4 phases = 45+ seconds of non-interactive AI. Add AC-29: "BOSS battle total player-waiting time ≤ 10s excluding player input time."
7. **Rec #7** (Cross-doc API verification in `/review-all-gdds`): 12 declared API contracts. Highest cross-doc risk of any GDD.

### Nice-to-have
- 4-phase turn structure ASCII diagram (lines 95-104) is a great visual aid. Replicate in `weapon-ammo.md` and `hud.md`.
- AC-21 (Monte Carlo 1000-iteration test) is exemplary — replicate in `weapon-ammo.md` and `random-encounter.md`.
- 6-row cross-doc traceability table is the **gold standard** for cross-doc references. Replicate in all subsequent GDDs.
- "AI thinking" animation (0.3s) worth mentioning in `art-bible.md`.
- 16 tuning knobs are well-organized: HP ranges, attack values, defend mult, flee rate, AI thresholds, rewards, drop rates. Complete balance surface.

### Manual checks deferred
- `weapon-ammo.md` cross-check on `Inventory.get_equipped_weapon()` / `cycle_ammo()` — verify in `/review-all-gdds`.
- `hud.md` cross-check on `battle_state: Dictionary` schema (12 keys) — verify in `/review-all-gadss`.
- `level-dungeon.md` / `random-encounter.md` cross-check on encounter → `transition_to(BATTLE)` + enemy_data flow — verify in `/review-all-gdds`.
- `save-load.md` cross-check on `battle_state` serialization — verify in `/review-all-gdds`.
- 6 Vertical Slice GDDs (damage-calc, enemy-ai, mech-upgrade, items, doors, story-map) cross-check on API signatures — verify in `/review-all-gdds` once those GDDs are authored.

### Post-Approval
- Status in `systems-index.md`: Approved (line 29 updated). **Core layer 1/1 complete.**
- GDD frontmatter: updated to `Status: Approved` + `Review Verdict: APPROVED (first review 2026-06-12, lean, prototype-validated)`
- Open Questions: Rec #1 (multi-enemy formula placeholder) + Rec #3 (BOSS 50% HP behavior change) appended for tracking
- Tracking: **6/12 MVP GDDs approved** (Resource/Data, Player Input, Game State Machine, Camera, Collision, Battle Core Loop). 6 remaining GDDs in pipeline (4 Feature + 2 Presentation).
- Next pipeline step: Phase 1g — `/design-review weapon-ammo.md` (Feature layer, combined Weapon+Ammo GDD).
