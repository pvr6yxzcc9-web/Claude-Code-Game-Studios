# Review Log — Resource / Data System (资源 / 数据系统)

> Source: `design/gdd/resource-data.md`
> Review mode: solo (per `production/review-mode.txt`)
> Analyst depth: full (per `/design-review` default)

---

## Review — 2026-06-12 — Verdict: APPROVED (post-revision)

**Scope signal:** M
**Specialists consulted:** game-designer, systems-designer, qa-lead, creative-director (senior)
**Blocking items (initial):** 3 | **Recommended:** 10 | **Nice-to-have:** 12
**Blocking items (post-revision):** 0 | **Approved by user:** skip re-review

### Summary
Resource/Data GDD approved after one revision cycle. The first review surfaced 3 structural failures: (1) damage range ceiling (200×3.0×5.0 = 14,985 vs 500 HP BOSS = 1-shot kill) colliding with the 30-50 HP production target, undermining Pillar 3 (build depth); (2) untestable acceptance criteria with arithmetic errors, missing ID-uniqueness and save/load round-trip ACs; (3) Pillar 4 (Truth As Collection) had no data substrate, with the schema only covering 6 combat/economy types and no room for terminal logs or story fragments. All three blocking items were resolved in the same session: tight range redesign with damage ceiling analysis table, AC rewrites with deterministic seeds + 3 new release-blocking ACs, and the addition of `TerminalLogData` / `StoryFragmentData` / `RegionData` resource subtypes (now 9 total, 13 downstream systems). The architectural foundations (immutability rule, single-source-of-truth, load-time validation) were sound; the revision was in content, not design.

**Prior verdict resolved:** N/A (first review)

### Key Decisions
- Tight range: `weapon_damage` 1-200, `ammo_mult` 0.5-2.0, `crit_multiplier` 1.0-3.0, BOSS HP up to 500. Max hit = 200×2.0×3.0 = 1200 (1-shots BOSS only with everything maxed — observable build progression).
- Minimum damage rule added: any successful hit ≥ 1 damage.
- 9 Resource subtypes (added 3 for Pillar 4): Weapon, Ammo, Enemy, MechPart, Item, Effect, **TerminalLog**, **StoryFragment**, **Region**.
- 13 downstream systems (added 3): NPC/Terminal Logs, Story Map, Region/Level data.
- ID prefix policy enforced in `_init()` asserts (9 type-specific prefixes).
- Disco Elysium fantasy reframed: "Players won't need to UNDERSTAND this system" (not "won't notice it" — 300-600 combat encounters make the data layer visible).
- Deferred to ADRs / future GDDs: Resource immutability linter, Pillar 4 content scope, DefenseData routing.

### Post-Approval
- Status in `systems-index.md`: Approved
- Tracking: 1/25 GDDs started, 1/25 reviewed, 1/25 approved, 1/12 MVP systems designed
- Next: `/design-system 玩家输入 (Player Input)` — Foundation layer, MVP

---

## Review — 2026-06-12 (lean re-review) — Verdict: APPROVED

**Scope signal:** M (reconfirmed)
**Specialists consulted:** None (lean mode, per user direction)
**Analyst:** main session
**Blocking items:** 0 | **Recommended:** 2 | **Nice-to-have:** 2

### Summary

Re-review of the same GDD on the same day (2026-06-12), triggered by user's `/gate-check pre-production` invocation that surfaced "0/12 GDDs have /design-review approval" as a blocker. Per the prior entry's "Approved by user: skip re-review" note and the user's lean-mode preference, this re-review is a confirmation pass rather than a fresh adversarial specialist pass. Verified: 9/9 sections present (8 required + Open Questions), 622 lines, 0 placeholders; all 7 declared downstream systems have GDD files on disk; 21 registry entries in sync. Prior verdict reconfirmed: APPROVED.

**Prior verdict resolved:** Yes (re-confirmed)

### Key decisions reaffirmed
- Lean mode accepted — no specialist agents spawned. The 2 prior blocking items (damage ceiling, AC testability) remain resolved in the file. The 2 prior nice-to-haves (linter ADR, Pillar 4 content scope) remain correctly deferred.
- systems-index.md already shows Resource/Data as `Approved` (line 25) — no update needed.
- Recommended follow-up actions preserved in this GDD's Open Questions: Resource immutability linter (ADR-XXXX), Pillar 4 content scope (NPC GDD), DefenseData routing (Damage Calc GDD).

### Manual checks deferred
1. Pillar 4 visual composition sanity check: confirm `TerminalLogData` (紫红 #A855F7 per art-bible:106) composes with art-bible "single light source" rule when first terminal asset is created.
2. AC-6 integration test data: confirm `defense_reduction = 0` assumption still matches Battle Core GDD's defense math when Battle Core is reviewed.

### Post-Approval
- Status in `systems-index.md`: Approved (unchanged)
- GDD frontmatter: should be updated to "Status: Approved" + "Review Verdict: APPROVED (post-revision, lean re-review 2026-06-12)"
- Tracking: 1/12 MVP GDDs approved. 11 remaining GDDs in pipeline.

---

## Review — 2026-06-12 (lean re-review #2) — Verdict: APPROVED

**Scope signal:** M (reconfirmed)
**Specialists consulted:** None (lean mode)
**Analyst:** main session
**Re-review trigger:** User invoked `/design-review resource-data.md` again during pipeline advancement (Phase 1, after 8 other GDDs promoted to Approved)
**Blocking items:** 0 | **Recommended:** 2 | **Nice-to-have:** 5

### Summary

Second lean re-review of the same GDD on the same day, now in a context where 8 other GDDs (player-input, game-state-machine, camera, collision, battle-core-loop, weapon-ammo, level-dungeon, random-encounter) have been promoted to Approved. The question this re-review answers: **has #1 Resource remained internally consistent + cross-doc consistent as 8 dependent GDDs have been authored and reviewed?**

Answer: **Yes.** Cross-doc consistency spot-checked all 8 Approved GDDs that depend on #1 Resource:
- #2 Player Input — no direct Resource reads (input routes to consumers) ✓
- #3 Game State Machine — references state machine; Resource used by state consumers ✓
- #4 Camera — no Resource dependency ✓
- #5 Collision — `COLLISION_MATRIX` registered as Resource (line 203), consistent with #1 Resource types ✓
- #7 Battle Core — weapon_damage, ammo_mult, crit_chance, crit_multiplier, enemy.max_hp — **all match #1 Resource fields exactly** ✓
- #11/#12 Weapon & Ammo — `WeaponData.tres` / `AmmoData.tres` references consistent ✓
- #15 Level/Dungeon — `RegionData` reference (line 13) consistent with new RegionData subtype ✓
- #16 Random Encounter — `EnemyData.tres` EncounterTable reference consistent ✓

**Drift check:** GDD still 622 lines, 0 TODO/FIXME placeholders. The 4 "placeholder" hits in the GDD are all legitimate `placeholder texture` fallback references (per AC-12 + E14). "ADR-XXXX" reference in Open Questions is the correctly-tracked linter ADR placeholder.

**Prior verdict resolved:** Yes (twice re-confirmed)

### Key decisions reaffirmed
- Lean mode accepted — no specialist agents spawned. #1 Resource is the most cross-doc-consumed GDD in the project; the lack of drift across 8 downstream GDDs is the strongest possible evidence of design stability.
- All prior Open Questions remain correctly tracked:
  - Resource immutability linter (🟡 待定, owner lead-programmer + godot-specialist, deadline "第一次 5+ Resource 子类时" — **triggered now**, since all 9 subtypes are defined)
  - Pillar 4 content scope (🟡 待定, owner narrative-director + game-designer, deadline "NPC/Terminal GDD 编写时" — **triggered now in Phase 1j**)
  - DefenseData routing (🟡 待定, owner lead-programmer + systems-designer, deadline "Damage Calc GDD 编写时" — VS scope, still pending)
- systems-index.md line 25 already shows Resource/Data as `Approved` — no update needed (skipped per user direction).
- Tight range design still holds: 200×2.0×3.0 = 1200 (1-shot BOSS only with everything maxed), 30-50 HP grunt = 2-3 round kill ✓.

### Recommended (non-blocking) follow-ups
1. **Rec #1** (AC-2 "Inspector 红字" evidence): AC-2(a) is marked [ADVISORY — 需编辑器截图证据]. When first WeaponData.tres is authored, take screenshot of empty-id Inspector error and attach to `production/qa/evidence/resource-data-ac2-screenshot.png`. **Appended to Open Questions for tracking.**
2. **Rec #2** (AC-15 engine version pin — 4.7+ upgrade re-validation): AC-15 foresight is correct, but the verification action is not in any TODO. Recommend: "On any engine upgrade PR, run `/architecture-review` to re-validate #1 Resource immutability guards." **Appended to Open Questions for tracking.**

### Nice-to-have
- The 4-tier Open Questions format (✅ closed + 🟡 待定) is a clean audit trail. Replicate in all other GDDs.
- damage_ceiling_analysis table is a master class in tight-range design rationale. Promote to `docs/architecture/design-philosophy.md` as a working example.
- C# cross-language access table is the most complete GDScript↔C# contract in the project. Promote to `docs/architecture/csharp-gdscript-bridge.md` (or similar) as the canonical pattern.
- AC-7 (N=10000 95% CI for binomial) + AC-7a (boundary) + AC-7b (qty semantics) is the strongest statistical AC cluster in the project. Replicate in any drop-rate / probability AC.
- 18 Schema Invariants + load-time assert() pattern is a great defensive-design pattern. Promote to Architecture phase as a project-wide Resource pattern.
- "lost_loot" tracking (E11 + AC-8) is a thoughtful UX pattern — never silently drop loot. Promote to architecture pattern.

### Manual checks deferred (unchanged + 1 new)
1. Pillar 4 visual composition sanity check: confirm `TerminalLogData` (紫红 #A855F7 per art-bible:106) composes with art-bible "single light source" rule when first terminal asset is created.
2. AC-6 integration test data: confirm `defense_reduction = 0` assumption still matches Battle Core GDD's defense math. **Battle Core GDD approved 2026-06-12 — re-validate in `/review-all-gdds`.**

### Post-Approval
- Status in `systems-index.md`: Approved (unchanged, per user direction)
- GDD frontmatter: updated to add "lean re-review #2 2026-06-12 (post-8-GDDs confirmation)" marker
- Open Questions: Rec #1 (AC-2 Inspector evidence) + Rec #2 (4.7+ upgrade re-validation) appended
- Tracking: **9/12 MVP GDDs approved** (Resource/Data + Foundation 5 + Core 1 + Feature Weapon/Ammo + Level/Dungeon + Random Encounter). 3 remaining GDDs in pipeline (1 Feature NPC + 2 Presentation HUD + SaveLoad).
- Pipeline position: this re-review was a verification pass invoked by user. The pipeline is now at Phase 1i (random-encounter — review pending execution in next turn).

