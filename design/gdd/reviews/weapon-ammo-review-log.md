# Review Log — 武器与弹药 (Weapon & Ammo)

> Source: `design/gdd/weapon-ammo.md` (combined GDD covers both Weapon and Ammo systems)
> Review mode: solo (per `production/review-mode.txt`)
> Analyst depth: lean (per `--depth lean`)
> **Prototype-validated**: yes (3×3 = 9 builds confirmed in concept prototype)

---

## Review — 2026-06-12 (first review) — Verdict: APPROVED

**Scope signal:** M-L
**Specialists consulted:** None (lean mode, per user direction)
**Analyst:** main session
**Blocking items:** 0 | **Recommended:** 7 | **Nice-to-have:** 6

### Summary

First review of the Weapon & Ammo GDD (350 lines, 8 required sections + Visual/Audio + UI bonus sections). 8 invariants, 5 formulas, 12 edge cases, 12 tuning knobs, 15 acceptance criteria. Captures the Pillar 3 "build 试验" essence with a clean 3×3=9 MVP granularity (F2 explicitly contrasts MVP 9 vs VS 20). The 8-state weapon lifecycle diagram is exemplary. C-R5 (post-battle popup) + C-R6 (no undo) combination correctly establishes "loot has weight" as a design principle. C-R8 ammo compatibility is data-driven. All 5 cross-doc bidirectional constraints to the 5 Foundation GDDs + #7 Battle Core (all Approved 2026-06-12) are correctly maintained. **The 5-row cross-doc traceability table is now a project standard** (4 GDDs in a row with this pattern).

**Prior verdict resolved:** N/A (first review, prototype-validated)

### Key decisions reaffirmed
- **Lean mode accepted** — no specialist agents spawned. Cross-doc consistency to 6 already-Approved GDDs is sufficient inline. The GDD is prototype-validated for the 3×3 build system.
- **3 weapon slots × 3 ammo types = 9 builds MVP** is the right granularity for a 3-5 hour RPG (Pillar 3 "build 试验" depth without overwhelming).
- **F1 Build Damage preview** is a separate formula from #7 F1 Final Damage. Preview = `base × ammo_mult` only. This separation makes build choice **understandable** (no hidden modifiers per C-R3).
- **C-R5 (post-battle popup, never auto-inventory)** + **C-R6 (no undo for discard)** are the **key gameplay-feel** invariants — they ensure "loot has weight" (per Player Fantasy).
- **C-R8 ammo compatibility via WeaponData.ammo_slot** is data-driven (per #1) and explicit. `AmmoData.Type.ANY` (blast) exception is the right escape hatch.
- **Pickup decision tree (F4)** with 0.5s timeout defaulting to "in_inventory" is a thoughtful UX choice — prevents panic-discard.
- **Edge case #7 (ammo = "装填模式偏好" not consumption)** is a critical clarification. MVP 弹药不消耗 = "你可以随时切换 build 试错" without resource pressure.
- **8-state weapon lifecycle** (Not Obtained → Offered → Inventory → Equipped [3 slots] → Active in Battle → Discarded) is the right granularity with an exemplary ASCII state diagram.
- **TOTAL_WEAPON_TYPES_AVAILABLE = 12** tuning knob implies a 4-chapter structure (4 × 3 weapons/chapter). This is a hidden structural commitment that should be reflected in `level-dungeon.md` chapter count.

### Recommended (non-blocking) follow-ups
1. **Rec #1** (F1 build damage preview vs #7 F1 final damage confusion): Rename F1 to "Build Damage Preview" with explicit "(pre-combat, no crit/weakness/defense)" subtitle. Or use different variable name like `expected_damage`.
2. **Rec #2** (Ammo consumption decision — UX onboarding risk): OQ #2 says "弹药不消耗" but players from classic RPGs will expect depletion. Add onboarding hint (in 1st terminal log per Pillar 4) explaining "弹药不会消耗——你可以随时切换 build 试错". **Appended to Open Questions for tracking.**
3. **Rec #3** (Pickup popup state interaction): OQ #6 says "[1] 装备 / [2] 入背包 / [3] 丢弃" but this conflicts with #7's "1/2/3 = 立即攻击" in BATTLE state. Clarify that pickup popups are **only shown post-battle** (BATTLE_END_VICTORY or EXPLORATION), not during BATTLE. Add explicit AC. **Appended to Open Questions for tracking.**
4. **Rec #4** (Drop rate anti-duplicate logic): Elite 0.40 + Grunt 0.10 means most grunts give no weapons. Add anti-duplicate logic: drop weapons the player doesn't own first. Pillar 1 "发现回报" + Pillar 3 build variety.
5. **Rec #5** (Cross-doc API verification in `/review-all-gdds`): 8 declared API contracts. Verify against 4 pending GDDs.
6. **Rec #6** (Weapon visual differentiation strategy): 12 weapons in 23 slots (3 equipped + 20 backpack). Add brief note in V/A: "12 weapons grouped into 3 archetypes (laser/cannon/missile) × 4 tiers (T1-T4), differentiated by color + small icon overlay."
7. **Rec #7** (Codex discovery trigger timing): `new_weapon_discovered` should defer "新发现！" popup to BATTLE_END_VICTORY or EXPLORATION (state-coherent UX). Add AC-14b.

### Nice-to-have
- 8-state weapon lifecycle diagram is exemplary. Replicate in `hud.md` and `save-load.md`.
- Pickup decision tree (F4) is a clean UX flowchart. Replicate for any "player decision" moment in other GDDs.
- F1 + #7 F1 separation (preview vs final) is a great pattern for "what the player sees" vs "what the engine computes".
- TOTAL_WEAPON_TYPES_AVAILABLE = 12 implies 4-chapter structure. Reflect in `level-dungeon.md` chapter count.
- AC-15 (save data structure) is a great example of explicit serialization. Replicate in `save-load.md`.
- "Loot has weight" design (C-R6, F3, E1) is the right feel for a "build 试验" game. Highlight in game concept doc.

### Manual checks deferred
- `level-dungeon.md` cross-check on `weapon_pickup_offered` / `ammo_pickup_offered` triggers — verify in `/review-all-gdds`.
- `random-encounter.md` cross-check on `signal battle_ended` consumer — verify in `/review-all-gdds`.
- `hud.md` cross-check on `inventory_state: Dictionary` schema (8 fields) — verify in `/review-all-gdds`.
- `save-load.md` cross-check on weapon_slots / ammo_inventory / current_ammo serialization — verify in `/review-all-gdds`.
- 3 Vertical Slice GDDs (codex, doors/locks, mech-upgrade) cross-check on API signatures — verify in `/review-all-gdds` once authored.

### Post-Approval
- Status in `systems-index.md`: Approved (lines 33-34 updated, both Weapon + Ammo). **Feature layer 2/4 complete (Weapon + Ammo).**
- GDD frontmatter: updated to `Status: Approved` + `Review Verdict: APPROVED (first review 2026-06-12, lean, prototype-validated)`
- Open Questions: Rec #2 (ammo no-consume UX onboarding) + Rec #3 (pickup popup state interaction) appended for tracking
- Tracking: **7/12 MVP GDDs approved** (Foundation 5 + Core 1 + Feature Weapon/Ammo 1 combined). 5 remaining GDDs in pipeline (3 Feature + 2 Presentation).
- Next pipeline step: Phase 1h — `/design-review level-dungeon.md` (Feature layer, level/dungeon design).
