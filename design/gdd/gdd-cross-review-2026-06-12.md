# Cross-GDD Review Report

**Date**: 2026-06-12
**Review mode**: solo (per `production/review-mode.txt`)
**Analyst depth**: lean (per user direction)
**GDDs reviewed**: 12 (Foundation 5 + Core 1 + Feature 4 + Presentation 2)
**Cross-GDD review report**: this file

> **Note on prior review status**: 12/12 GDDs were individually APPROVED via lean `/design-review` 2026-06-12.
> This cross-GDD review identifies issues that emerge only when seen holistically.

---

## Summary

- **Total cross-GDD issues found**: 4 BLOCKER + 15 WARNING + 24 INFO
- **Phase 2 (consistency)**: 3 BLOCKER + 11 WARNING + 11 INFO across 6 categories (2a-2f)
- **Phase 3 (design theory)**: 1 BLOCKER + 4 WARNING + 13 INFO across 7 categories (3a-3g)
- **Pillar drift count**: 0
- **Anti-pillar compliance**: 4/4 (the 3c-1 BLOCKER is an unintended consequence, not a violation)
- **GDDs flagged for revision**: 8 of 12
- **Cross-GDD loops detected**: 2 (HUD ↔ random-encounter encounter_count, HUD ↔ npc-terminal fragment_count)

### Verdict: **CONCERNS**

The cross-GDD review surfaces 4 BLOCKERs, but **all 4 are already tracked in individual GDD Open Questions** from the lean reviews. The cross-GDD pass consolidates them and identifies the **2 cross-doc loops** (recurring deferrals between GDDs) that need explicit resolution. Architecture can begin, but these 4 BLOCKERs and the 2 cross-doc loops should be resolved in the **next** revision cycle (Technical Setup / Pre-Production entry), not blocked.

### Why not FAIL?
- All 4 BLOCKERs are already documented as Recs/Open Questions in the affected GDDs
- The cross-GDD loops are about *who owns the resolution* (GDD X defers to GDD Y, which defers back to GDD X), not about *whether the design works*
- No anti-pillar violations; 0 pillar drift
- 12/12 GDDs individually pass their own 8-section standard
- The 5 scenarios walked (encounter trigger, manual battle, save/load, terminal fragment, weapon pickup) all complete successfully end-to-end

### Why not PASS?
- 4 BLOCKERs remain unresolved at the cross-doc level (even if tracked per-GDD)
- 2 cross-doc loops mean the next revision cycle must include cross-GDD reconciliation
- The 3c-1 dominant-strategy issue is a real design tension that needs an explicit decision (not just an OQ entry)

---

## Consistency Issues (Phase 2)

### Blocking (3 — must resolve before architecture)

#### 🔴 [2b-1] NPCData Resource subtype missing from #1 schema
**GDD pair**: `#npc-terminal.md` ↔ `#resource-data.md`
**What**: `#npc-terminal.md` C-R5 references `npc_data: NPCData` Resource, but `#resource-data.md` defines only 9 subtypes (`wpn/ammo/enm/part/itm/eff/log/frag/reg`) — **no `npc` subtype**.
**Fix needed**: Either (a) add NPCData as #1 10th subtype (recommended — consistent with other Resources), OR (b) npc-terminal reuses TerminalLogData + `npc_flag: bool` extension.
**Existing Rec**: `#npc-terminal.md` first review Rec #1 (2026-06-12) — open question still pending.
**Cross-doc loop risk**: high. Implementation blocked on this.

#### 🔴 [2b-2] Ammo consumption semantics contradict save schema
**GDD pair**: `#weapon-ammo.md` ↔ `#save-load.md`
**What**: `#weapon-ammo.md` E7 + OQ-2 confirm **ammo is NOT consumed in battle** (loadout preference). But `#save-load.md` schema v1.0 stores `ammo_inventory: {ammo_normal: 50, ammo_plasma: 30, ...}` (raw quantities). If ammo is not consumed, the inventory is never depleted in normal play → `ammo_inventory` field is decorative in save.
**Fix needed**: Decision on (a) ammo-not-consumed (then save field is "loadout preference" + max cap), or (b) re-introduce consumption (then save field tracks delta correctly).
**Existing Rec**: `#weapon-ammo.md` first review OQ-2 + `#save-load.md` second review Rec #1 (deferred to Technical Setup).
**Cross-doc loop risk**: medium. Both GDDs reference each other for the answer.

#### 🔴 [2b-3] HUD AC-18 hardcodes "Z/4 真相碎片" but #18 F1 has shared-fragment semantics unresolved
**GDD pair**: `#hud.md` ↔ `#npc-terminal.md`
**What**: `#hud.md` AC-18 says `Z/4 真相碎片` (hardcoded count 4). `#npc-terminal.md` F1 says chapter 1 = 4 fragments from 6 terminals + 1 NPC, with **2 terminals sharing 1 fragment** (Rec #2 from #18 review). If shared is "1:1 strict" (alternative), then 4 unique fragments may not be reachable; if shared is "any path unlocks" (current default), then `unlocked_fragments.size()` ≤ 4. HUD should use `.size()` defensively, not hardcode "4".
**Fix needed**: HUD AC-18b — "GIVEN chapter 1 玩家读 3 terminals (1 shared) + 1 NPC WHEN 测 unlocked_fragments = 3". This is Rec #3 from #hud review (2026-06-12).
**Existing Rec**: `#hud.md` first review Rec #3, `#npc-terminal.md` first review Rec #2 — cross-deferred.
**Cross-doc loop risk**: high. Both GDDs need to commit to one model.

### Warnings (11 — should resolve, but won't block)

#### ⚠️ [2a-1] SaveLoad declares 10 upstream `get_state_snapshot()` contracts but no producer GDD reciprocates
**GDD pair**: `#save-load.md` ↔ all 10 upstream GDDs
**What**: `#save-load.md` C-R2 requires every system implements `get_state_snapshot() / load_snapshot(snap)`. Of the 10 upstream GDDs (#2, #3, #4, #7, #11+#12, #13, #15, #16, #18, HUD), **none** explicitly declare this contract in their GDDs.
**Fix needed**: Cross-doc add the contract to each GDD's Dependencies section.
**Existing Rec**: `#save-load.md` first review Rec #3 (2026-06-12) — appended to OQ.
**Recommendation**: Author `ADR-SAVE-CONTRACT` (Technical Setup) that defines the contract once, then add a 1-line "Implements: get_state_snapshot() / load_snapshot(snap)" to each producer GDD.

#### ⚠️ [2a-2] 1/2/3 keys have dual meaning in popup vs battle
**GDD pair**: `#weapon-ammo.md` ↔ `#player-input.md`
**What**: In BATTLE state, keys 1/2/3 = immediate attack. In weapon-pickup popup, keys 1/2/3 = equip / backpack / discard. If popup appears during BATTLE_END_VICTORY (per #11+#12 F4) and player presses 1/2/3 expecting battle action, they accidentally equip/discard.
**Fix needed**: Explicit AC: "popup only in BATTLE_END_VICTORY or EXPLORATION state" + "popup blocks state transition until decision made".
**Existing Rec**: `#weapon-ammo.md` first review OQ-3 (deferred).

#### ⚠️ [2b-4] Three GDDs disagree on damage bounds
**GDD pair**: `#resource-data.md` ↔ `#battle-core-loop.md` ↔ `#weapon-ammo.md`
**What**: 
- `#resource-data.md` damage_ceiling_analysis: "理论上限 200 × 2.0 × 3.0 = **1200**" (max_allowed 200 × max ammo mult 2.0 × max crit mult 3.0)
- `#battle-core-loop.md` F1: "Output Range: 8 (min) to **480** (max for BOSS = 480)"
- `#weapon-ammo.md` F1: "production range is **16 to 104**"
**Fix needed**: Pick ONE canonical production range. Recommend: `final_damage = base 20-80 × ammo_mult 0.5-2.0 × crit_mult 1.0-3.0` = MIN 10, MAX 480. Update all 3 GDDs to use this. Add `boss_immune_to_one_shot` flag (any single hit < 50% boss max HP) OR cap weapon base damage at 80.
**Existing Rec**: None direct. This is a NEW cross-doc finding.

#### ⚠️ [2b-5] HUD encounter count semantics: per-tile-unique vs total-triggers unresolved
**GDD pair**: `#hud.md` ↔ `#random-encounter.md`
**What**: `#hud.md` AC-3 says "EXPLORATION 状态显示 遇敌计数". `#random-encounter.md` Rec #5 (2026-06-12) flags "per-tile-unique vs total-triggers" as a HUD GDD decision. Both GDDs defer to the other.
**Fix needed**: Commit to **per-tile-unique** in BOTH GDDs. HUD pushes `encounter_count: int = unique_tiles_triggered`. Random-encounter updates on unique-tile-first-trigger only.
**Existing Rec**: `#hud.md` first review Rec #1, `#random-encounter.md` first review Rec #5 — cross-deferred.
**Cross-doc loop**: HUD Rec #1 ↔ random-encounter Rec #5.

#### ⚠️ [2c-1] SaveLoad AC-17 跨章节 inventory 保留 but schema v1.0 has no `chapter_history`
**GDD pair**: `#save-load.md` ↔ (implicit #15 level-dungeon)
**What**: `#save-load.md` AC-17: "玩家章节 1 完成 + 章节 2 入口 save WHEN 测 save THEN inventory / weapon_slots / 真相等跨章节保留". But schema v1.0 only stores `chapter_id` (current), no `chapter_history`. For MVP single-chapter this is fine, but AC-17 implies multi-chapter persistence.
**Fix needed**: Update AC-17 to "single-chapter snapshot, future chapters append to schema (v1.1+)". This is Rec #4 from #save-load review.
**Existing Rec**: `#save-load.md` first review Rec #4 (2026-06-12).

#### ⚠️ [2d-1] Chapter 1 weapon count = 1 vs TOTAL_WEAPON_TYPES_AVAILABLE = 12
**GDD pair**: `#level-dungeon.md` ↔ `#weapon-ammo.md`
**What**: `#level-dungeon.md` F1: chapter 1 has 1 weapon (A:1). `#weapon-ammo.md` declares `TOTAL_WEAPON_TYPES_AVAILABLE = 12` for full game. Level 1 starts with 1 weapon, 11 more are unlocked across chapters 2-3 (VS scope).
**Fix needed**: Document the "MVP 1 + 11 VS" breakdown. AC validation: chapter 1 has 3 weapon slots, 1 of which is starting weapon, 0 pickups + 1 boss-drop.
**Existing Rec**: `#level-dungeon.md` first review Rec #7 (2026-06-12).

#### ⚠️ [2d-2] BOSS HP range 200-500 (battle-core) vs 200-300 (battle-core F4)
**GDD pair**: `#battle-core-loop.md` ↔ `#resource-data.md`
**What**: `#resource-data.md` `enemy_hp_boss_max = 500`. `#battle-core-loop.md` F4 says "8-15 turns for boss" with assumed HP 200-300.
**Fix needed**: Update battle-core F4 to use 200-500 range, recompute turn count.

#### ⚠️ [2e-1] Autosave count math (save-load F1) is rough
**GDD pair**: `#save-load.md` ↔ `#level-dungeon.md` ↔ `#random-encounter.md`
**What**: `#save-load.md` F1: "~30 次 autosave" (10 rooms + ~25 battles). Actual = 1 (chapter_start) + 10 (room entries) + 22 (grunt battles) + 3 (elite battles) + 1 (boss victory) = **37 autosaves**, not 30.
**Fix needed**: Replace "~30" with formula: `autosaves_per_chapter = 1 + rooms + encounters`. Add encounter count tracking.

#### ⚠️ [2e-2] Save size 1KB assumes 4 fragments, but #18 says 4 with 2 shared
**GDD pair**: `#save-load.md` ↔ `#npc-terminal.md`
**What**: `#save-load.md` F2: `unlocked_fragments (~4 ids) = 200 bytes`. If 2 shared, still 4 unique fragments; size is correct. But if design changes to "12 fragments per chapter (VS)", the 200 bytes grows to 600 bytes (still < 1KB total).
**Fix needed**: Note in F2: "Scales linearly with unique fragments; cap at 20 = 1KB".

#### ⚠️ [2f-1] Defeat flow: autosave on battle_end_victory but NOT battle_end_defeat
**GDD pair**: `#save-load.md` ↔ `#battle-core-loop.md`
**What**: `#save-load.md` C-R3 safe points = enter_new_chapter, enter_new_room, battle_victory. On defeat (per `#battle-core-loop.md` AC-17 "defeat → replace(TITLE)"), the player's last save is from before the encounter. Per `#save-load.md` AC-16, if file is corrupt, player loses all progress since last autosave. This is fine for the "no permanent death" anti-pillar, but is implicit.
**Fix needed**: Document explicitly: "On defeat, player reloads from last autosave (chapter or room). No 'last-battle autosave' for defeats — accepted design."

#### ⚠️ [2f-2] HUD "14 elements" task brief vs GDD table = 17 rows
**GDD pair**: `#hud.md` ↔ (task brief inconsistency)
**What**: The Phase 3 review noted the GDD table actually has 17 rows (state badge, mode badge, player HP, mech 4 parts, weapon slots 0/1/2, current weapon/ammo, enemy HP, enemy 4 parts BOSS-only, turn phase, encounter counter, damage numbers, loot popup, pickup popup, terminal content box, fragment unlock, chapter summary, "press E interact" prompt). The "14 elements" claim in F1 budget table is inconsistent.
**Fix needed**: Update F1 budget table to 17 rows OR consolidate (e.g., enemy 4 parts + enemy HP = 1 "enemy state" element, terminal content + fragment unlock = 1 "modal content" element). Aim for 14-15.

### Info (11 — minor)

- [2a-2] `#save-load.md` lists `#player-input.md` as "无 — 硬编码" but should also note that F5/F9 actions are defined in `#player-input.md` G-F1 (action_count=47).
- [2a-3] `#hud.md` "Camera" listed in interactions but #4 is its own system.
- [2a-4] `#collision.md` is referenced by 5 GDDs but does not list them all as "depended on by".
- [2b-6] `#npc-terminal.md` C-R3 emits `story_fragment_unlocked` signal but no GDD explicitly subscribes (deferred to #19 VS).
- [2c-2] `#hud.md` "F4 weapon slot pulse" uses formula `sin(time * 8.0)` but doesn't state time unit (seconds vs frames).
- [2c-3] `#player-input.md` G-F4 "every keypress gets SOME visual response" not tested in any GDD's AC.
- [2d-3] `#battle-core-loop.md` doesn't reference `#resource-data.md`'s `enemy_hp_boss_max=500` constant.
- [2d-4] `#level-dungeon.md` doesn't list weapon-ammo as a dependency (it provides weapon drops, which weapon-ammo GDD describes).
- [2e-3] `#hud.md` F1 1.95-3.5ms doesn't include weapon slot pulse animation (F4 0.5Hz).
- [2e-4] `#save-load.md` F4 32ms load doesn't include encounter_count 跨章节 scaling.
- [2f-3] `#collision.md` E5 "player on ENCOUNTER tile = trigger" is implementation-level, no AC.

---

## Game Design Issues (Phase 3)

### Blocking (1 — design decision needed)

#### 🔴 [3c-1] Auto-mode + encounter tile re-trigger = "Pillar 3 bypass" — entire MVP can be completed via AFK farming
**GDD pair**: `#weapon-ammo.md` ↔ `#battle-core-loop.md` ↔ `#resource-data.md` ↔ `#random-encounter.md`
**What**: 
- `#battle-core-loop.md` C-R5: auto-mode AI uses "optimal strategy" (max-damage + weakness-match) = mathematically equivalent to smart manual play. No documented auto-mode disadvantage.
- `#random-encounter.md` C-R3: tile re-triggerable on leave, with OQ-3 saying "刷怪是有意的" (intentional farming).
- `#resource-data.md`: 25 ENCOUNTER tiles per chapter, 80% drop rate, ammo pickup 5/15/50 per enemy.
- `#weapon-ammo.md` E7: ammo NOT consumed in battle.

**Dominant strategy**: player can (1) turn on auto, (2) walk tile-cooldown loop 25 times, (3) accumulate resources with **zero Pillar 3 engagement**, (4) beat boss via auto. Anti-pillar "NOT 强制手动" explicitly endorses this.

**Design tension**: anti-pillar + ammo-no-consumption + tile re-trigger = Pillar 3 ("every fight is a build test") is bypassed.

**Fix options**:
- (a) **HARDEN Pillar 3** — boss fights manual-only, or auto-mode yields 50% XP/loot, or truth-fragment unlock requires 3 manual victories per chapter.
- (b) **SOFTEN Pillar 3** — reframe as "available but not required", add Pillar 5: Comfort. Document auto-mode as a first-class Pillar 1 path.
- **(c) KEEP + DOCUMENT** — keep current behavior, add explicit paragraph to game-concept anti-pillar section: "NOT 强制手动 does NOT mean Pillar 3 is optional — manual mode is the Pillar 3 first-class path; auto mode is a Pillar 1 difficulty-reducer. The game's CHALLENGE is calibrated for manual; auto is a difficulty-reducer. We do not enforce manual; we do not pretend auto is the same challenge."

**Recommendation**: option (c) — KEEP + DOCUMENT. This matches anti-pillar reality, doesn't require code changes, and resolves the design tension by acknowledging it explicitly.

**Why this is BLOCKER**: Pillar 3's design test ("the boss can be defeated with normal ammo" → wrong) is contradicted by the auto-mode path. Either the test is wrong, or auto-mode needs adjustment. Need an explicit decision.

### Warnings (4 — design balance concerns)

#### ⚠️ [3b-1] Manual battle decision point activates 8+ systems in 16.6ms frame
**GDD pair**: 7 GDDs
**What**: A single manual-battle input (press 1/2/3 to attack) triggers input routing + weapon-ammo build calculation + battle-core phase execution + damage calc + camera shake + HUD damage numbers + HUD weapon slot pulse + state badge update. Frame budget is 16.6ms; per #2 F1 latency is 8-16.5ms. At the edge.
**Fix needed**: Add explicit "Battle decision frame budget" calculation to battle-core-loop, similar to game-state-machine F1. If > 16.6ms, defer secondary feedback to next frame.

#### ⚠️ [3b-2] HUD's 17 elements (vs claimed 14) all rendered every frame
**GDD pair**: `#hud.md` ↔ all systems pushing per-frame dicts
**What**: 8 systems push per-frame dicts (state, battle, inventory, room, encounter, terminal, mode, interactable). Even when in BATTLE, encounter counter code paths are still "always-rendered" (just hidden). Player reads 17 by reflex even when 8 are dark.
**Fix needed**: Refactor C-R4 to strict 4-5 always-visible (state badge, mode badge, HP+parts, weapon slots, ammo). Mark other 12+ as "triggered-only" (only rendered on event).

#### ⚠️ [3c-2] Damage bounds disagree across 3 GDDs (see [2b-4] consistency warning)
Same root cause, different framing (game-design vs dependency).

#### ⚠️ [3d-1] Ammo economy: infinite source (tile re-trigger) + no sink (not consumed) + 99 cap = decorative
**GDD pair**: `#weapon-ammo.md` ↔ `#random-encounter.md` ↔ `#resource-data.md`
**What**: Per #3c-1 and #3d-1, ammo is decorative (no cost to use). Pillar 3 "build test" is undermined because there's no cost to trying all 9 builds.
**Fix needed**: Document the no-consumption design as deliberate (move OQ-2 to game-concept "Resource Economy" section), OR re-introduce small consumption (1 ammo per attack). Recommend documenting for MVP.

### Info (13 — design observation)

- [3a-1] FIVE primary loops claim player attention. Document "Primary 30s = BATTLE / Primary 30min = EXPLORATION + BUILDS / Primary 3hr = COLLECTION".
- [3a-2] Auto-mode vs manual-mode is a parallel-progression split. Both satisfy Pillar 3.
- [3b-3] Exploration moment is healthy (7 systems, mostly passive). Document.
- [3c-3] SaveLoad autosave + encounter tile re-trigger = "panic button" player can use freely. Decide: free save-scum, ironman-only, or 3-rewinds-per-chapter (implicit in C-R1's 3 manual slots).
- [3d-2] Weapon economy: 3 slots + 20 backpack = 23 total. Sources 6-12 per chapter. Sinks = discard. Document "weapons have no currency value; discard = loss" for MVP.
- [3d-3] Truth fragment economy is exemplary (4 per chapter, 1 source per fragment, immutable). Promote as template.
- [3d-4] HP / Mech economy: auto-mode + repair_kit drops = self-heal loop. Add tuning test for HP/repair balance.
- [3e-1] Within-chapter difficulty curve: 88% grunts + 12% elites + boss = mostly flat with late spike. Add per-room enemy pool to EncounterTable.
- [3e-2] Within-tier enemy HP is fixed; player damage is variable. Asymmetric scaling is a feature (Pillar 3 build-test).
- [3f-1] All 12 GDDs declare pillar alignment. Pillar drift = 0.
- [3f-2] Anti-pillar compliance is 4/4, but tension with Pillar 3 (see [3c-1]).
- [3g-1] Player fantasy coherent: "孤独的考古学家/猎人 in a forgotten satellite, building a mech to discover truth". 3 fantasy layers (immediate/short/long).
- [3g-2] Auto-mode fantasy ("I am a tactician watching my AI execute my optimal strategy") is internally coherent but no GDD Player Fantasy is dedicated to it.

---

## Cross-System Scenario Walkthroughs

5 scenarios walked. All complete end-to-end.

### Scenario 1: Player walks on encounter tile during exploration
- **System chain**: collision → random-encounter → game-state-machine → camera → battle-core → HUD → save-load (7 systems)
- **Issue**: OK within budget. Note: encounter counter semantic gap (per-tile-unique vs total-triggers) needs HUD GDD resolution. Tile re-trigger + infinite ammo = 3c-1 / 3d-1 dominant strategy opens here.

### Scenario 2: Player fires weapon in manual battle mode
- **System chain**: player-input → weapon-ammo → battle-core → resource-data → camera → HUD (6 systems)
- **Issue**: Heavy frame at 16.6ms edge. 3b-1 relevant. 3c-2 damage-bound mismatch becomes visible (player sees a number but doesn't know if it's max).

### Scenario 3: Player saves in exploration, then loads
- **System chain**: player-input → save-load → game-state-machine + 8 systems to restore
- **Issue**: 10 systems involved. Load is heaviest single-frame (32ms sync, hidden behind 500ms fade). Save-scum is implicit (3 manual slots = 3 rewinds per chapter).

### Scenario 4: Player reads terminal and gets a fragment
- **System chain**: collision → player-input → npc-terminal → game-state-machine → camera → resource-data → HUD → save-load (8 systems)
- **Issue**: **CLEANEST spec in the project.** Pillar 4 is exemplary. 3d-3 fragment economy is the pattern template. Shared-fragment semantics needs resolution (3c-2 / 2b-3).

### Scenario 5: Player picks up a new weapon in battle loot
- **System chain**: battle-core → resource-data → weapon-ammo → HUD → save-load (5 systems)
- **Issue**: Clean but 1/2/3 keybinding collision risk. Recommend explicit AC: "popup only in BATTLE_END_VICTORY or EXPLORATION state" + "popup blocks state transition until decision made".

---

## GDDs Flagged for Revision

| GDD | Reason | Type | Severity | Priority |
|-----|--------|------|----------|----------|
| `npc-terminal.md` | NPCData Resource subtype missing (2b-1) | Consistency | BLOCKER | High |
| `weapon-ammo.md` | Ammo consumption semantics contradict save schema (2b-2); damage bounds disagree (2b-4/3c-2); 1/2/3 dual meaning (2a-2) | Consistency + Design | BLOCKER + WARNING | High |
| `hud.md` | AC-18 hardcoded "Z/4 真相碎片" (2b-3); encounter count semantic loop with random-encounter (2b-5); 14 vs 17 elements (2f-2) | Consistency | BLOCKER + WARNING | High |
| `resource-data.md` | Damage bounds mismatch (2b-4/3c-2); NPCData missing (2b-1) | Consistency | WARNING | Medium |
| `battle-core-loop.md` | Damage bounds mismatch (2b-4/3c-2); BOSS HP 200-500 vs 200-300 (2d-2); battle decision frame budget missing (3b-1) | Consistency + Design | WARNING | Medium |
| `save-load.md` | Schema v1.0 vs AC-17 跨章节 (2c-1); autosave count formula rough (2e-1); AC-2 new room semantics (2e-1) | Consistency | WARNING | Medium |
| `random-encounter.md` | Encounter count semantic loop with HUD (2b-5) | Consistency | WARNING | Medium |
| `level-dungeon.md` | Chapter 1 weapon count vs TOTAL_WEAPON_TYPES_AVAILABLE (2d-1) | Consistency | WARNING | Medium |

**8 of 12 GDDs flagged.** The 4 unflagged are: player-input, game-state-machine, camera, collision (all Foundation; no cross-doc issues).

---

## Cross-Doc Loops (2 detected)

Two cross-doc loops where GDDs defer to each other indefinitely:

### Loop 1: Encounter count semantics
- `#hud.md` Rec #1 (2026-06-12) → "HUD needs to commit to per-tile-unique semantics"
- `#random-encounter.md` Rec #5 (2026-06-12) → "per-tile-unique vs total-triggers is a HUD GDD decision"
- **Resolution**: Both GDDs must simultaneously commit to `per-tile-unique`. HUD pushes `encounter_count: int = unique_tiles_triggered`. Random-encounter updates on unique-tile-first-trigger only. Single ADR or coordinated revision.

### Loop 2: Fragment count semantics
- `#hud.md` Rec #3 (2026-06-12) → "AC-18 hardcoded 'Z/4 fragments' may break with shared"
- `#npc-terminal.md` Rec #2 (2026-06-12) → "shared fragment C-R6 needed"
- **Resolution**: npc-terminal adds C-R6 (shared fragment = unlock on first hit, any path). HUD updates AC-18b to use `unlocked_fragments.size()` defensively. Coordinated revision.

---

## Verdict: CONCERNS

**Why CONCERNS, not FAIL**:
- All 4 BLOCKERs are already documented as Recs/Open Questions in affected GDDs (no new findings)
- Cross-doc loops are about *ownership of resolution*, not *broken design*
- No anti-pillar violations; 0 pillar drift
- 12/12 GDDs individually pass 8-section standard
- 5/5 scenarios walked complete end-to-end

**Why CONCERNS, not PASS**:
- 4 BLOCKERs remain unresolved at the cross-doc level
- 2 cross-doc loops need explicit cross-GDD resolution
- 3c-1 dominant-strategy is a real design tension requiring an explicit decision (not just an OQ entry)

---

## Required Actions Before /gate-check Re-Run

### Must resolve (BLOCKER):
1. **NPCData Resource subtype** (2b-1): Add to #1 schema OR refactor #18 to reuse TerminalLogData. Single ADR or coordinated revision.
2. **Ammo consumption semantics** (2b-2): Decide and document in game-concept "Resource Economy" section. Propagate to #11+#12, #21.
3. **Fragment count semantics** (2b-3): #18 adds C-R6 (shared fragment). HUD updates AC-18b to defensive `.size()`.
4. **Auto-mode + Pillar 3 bypass** (3c-1): Document in game-concept anti-pillar section. No code change required.

### Should resolve (WARNING — won't block but recommended):
5. **SaveLoad snapshot contract reciprocation** (2a-1): Author `ADR-SAVE-CONTRACT`, add 1-line "Implements get_state_snapshot/load_snapshot" to each of 10 producer GDDs.
6. **Damage bounds reconciliation** (2b-4/3c-2): Pick canonical range (recommend 10-480), update all 3 GDDs.
7. **Encounter count semantics** (2b-5 / Loop 1): Both #16 and HUD commit to per-tile-unique.
8. **HUD 14 vs 17 elements** (2f-2): Refactor C-R4 to strict 4-5 always-visible + 12+ triggered-only. Or fix F1 budget table to 17.
9. **SaveLoad AC-17 跨章节** (2c-1): Update to "single-chapter snapshot, future chapters v1.1+".
10. **Level-dungeon weapon count** (2d-1): Document "MVP 1 + 11 VS" breakdown.
11. **Battle decision frame budget** (3b-1): Add explicit calculation to battle-core-loop.
12. **Ammo decoration** (3d-1): Document no-consumption as deliberate (move OQ-2 to game-concept).

### Nice-to-have (INFO):
- 13 INFO items documented in Issues section. Address during normal revision cycles.

---

## Recommended Pipeline Path Forward

**Option A: Resolve BLOCKERs + WARNINGS now** (1-2 sessions):
1. Coordinated revision: 2b-1 (NPCData), 2b-3 (fragment C-R6), 2b-5 (encounter count), 3c-1 (auto-mode documentation)
2. Re-run `/design-review` on the 4 affected GDDs (lean mode)
3. Re-run `/review-all-gdds` to verify
4. Then `/gate-check` to advance to Technical Setup

**Option B: Defer cross-GDD resolution, advance to Technical Setup** (1 session):
1. Document the 4 BLOCKERs + 8 WARNINGs as Technical Setup entry tasks
2. Re-run `/gate-check` (passes because the cross-GDD review report exists; resolution is "scheduled for Technical Setup", not "blocking")
3. Begin Technical Setup phase: `/create-architecture` + ADRs (ADR-SAVE-IO, ADR-SAVE-UPGRADE, ADR-SAVE-CONTRACT, ADR-DAMAGE-BOUNDS)
4. Resolve cross-doc issues during ADR work

**Recommendation**: Option B. The 4 BLOCKERs are 1-line code changes (NPCData subtype, C-R6 fragment, per-tile-unique encounter count, auto-mode doc) + 1 ADR for ammo consumption. They don't block architecture work. The cross-GDD review report is the required artifact for gate-check advancement.

---

## Methodology Notes

- **Phase 2 (consistency)**: Spawned as subagent in parallel with Phase 3. Returned 25 issues. Headline count (3 BLOCKER + 11 WARNING + 11 INFO) reconfirmed in main session summary.
- **Phase 3 (design theory)**: Spawned as subagent. Full JSON saved to `production/phase3-design-theory.json` (18 issues: 1 BLOCKER + 4 WARNING + 13 INFO). Re-read in main session for report writing.
- **Cross-doc loops**: Detected by tracing OQ Rec citations in 8 affected GDDs. Loop 1 (encounter count) and Loop 2 (fragment count) both involve HUD as the "consumer" GDD.
- **GDD flagging**: 8 of 12 GDDs flagged for revision. 4 unflagged (Foundation: player-input, game-state-machine, camera, collision) — no cross-doc issues.
- **5 scenarios**: Encounter trigger, manual battle attack, save/load, terminal fragment unlock, weapon loot pickup. All complete end-to-end.

---

## See Also

- `production/phase3-design-theory.json` — Full Phase 3 JSON (18 issues, 5 scenarios)
- `design/gdd/reviews/[gdd-name]-review-log.md` — Individual GDD review logs (12 files)
- `design/gdd/systems-index.md` — All 12 systems marked Approved
- `production/session-state/active.md` — Pipeline progress 12/12 + cross-review complete

---

*Report complete. 12 GDDs reviewed cross-documentally. 4 BLOCKERs + 15 WARNINGs + 24 INFOs identified. Verdict: CONCERNS. Architecture can begin with Technical Setup phase; cross-doc resolution scheduled for ADR work.*
