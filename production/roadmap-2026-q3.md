# 2026 Q3 Roadmap — Post-GDD Implementation Plan

> **Status**: Active
> **Created**: 2026-06-15
> **Last Updated**: 2026-06-15
> **Owner**: suxiu (solo dev + on-demand external help)
> **Inputs**:
> - 4 GDDs written 2026-06-15 (party / bounty / racing / multi-satellite-arc) = 2634 lines
> - Sprint 6 close report (2026-06-15): 532/532 tests pass, 14/15 must-haves done
> - game-concept.md (original 3-5 hour scope) — **superseded** by multi-satellite-arc.md

---

## 1. Strategic Pivot (what changed in 2026-06-15)

**The 2026-06-15 conversation redefined the game's scope.**

| Dimension | Old plan (Sprint 6 close) | New plan (this roadmap) |
|-----------|--------------------------|--------------------------|
| **Chapter count** | 6 (Ch1-Ch6 of Sat-1 + Sat-2) | **15 (3 per satellite × 5)** |
| **Playtime** | 3-5 hours | **15-25 hours** |
| **Satellites** | 1 (Sat-1 + Sat-2 partial) | **5 (Sat-1 + Sat-2 + Sat-3 + Sat-4 + Sat-5)** |
| **Party** | 1 pilot + 1 mech | **3 pilots + 4 mechs** (free pilot-mech switching) |
| **Bounties** | 0 | **6 (1 plot + 5 optional + 1 post-game)** |
| **Racing** | 0 | **6 tracks + 4 racing mechs + betting** |
| **Truths** | 19 fragments (decoration) | **35 fragments (drive 4 endings)** |
| **Endings** | 4 (D = "low-log" stub) | **4 (A Merciful / B Cycle / C Fusion / D Hidden)** |

**What did NOT change**:
- Engine: Godot 4.6.3 Mono
- Language: GDScript (gameplay) + C# (perf-critical) — unchanged
- Pillar 1 (探索密度), Pillar 2 (发现 > 数值), Pillar 3 (build 试验), Pillar 4 (真相 = 收集) — all 4 still core
- Code quality standards (test-first, lint system, 8-section GDDs) — unchanged
- Visual / audio pipeline (Python synth) — unchanged
- No new tech dependencies

**What this means for sprint planning**:
- Sprint 7-11 are now **content-and-systems** sprints (party + Sat-3/4/5 + bounty + racing + ending rewrite)
- Store launch (Steam / itch.io) is **deferred** to post-Sprint 11 — the game is no longer "ship-ready" in Sprint 6; it needs 4-5 more months of work to be ship-ready

---

## 2. Sprint Plan Overview (Sprint 7-11 + post-launch)

| Sprint | Goal | Duration | Output | Risk |
|--------|------|----------|--------|------|
| **Sprint 7** | Party system implementation (code) | 3 weeks | 3-pilot + 4-mech combat working in Sat-1+Sat-2 | High (core combat rewrite) |
| **Sprint 8** | Sat-3 蜂巢号 content | 3 weeks | 3 new chapters (Ch7-9), 6 enemies + 1 boss + 4 NPCs + 7 fragments + 1 BGM | High (first new content) |
| **Sprint 9** | Sat-4 断魂号 content | 3 weeks | 3 new chapters (Ch10-12), 6 enemies + 1 boss + 4 NPCs + 7 fragments + 1 BGM | Medium (military theme established) |
| **Sprint 10** | Sat-5 起源号 content + 4 endings rewrite | 4 weeks | 3 new chapters (Ch13-15) + 1 boss + 4 NPCs + 7 fragments + 1 BGM + 4 endings | High (climax + 4 endings) |
| **Sprint 11** | Bounty + Racing systems (code) | 3 weeks | 6 bounties (1 plot + 5 optional + 1 post-game) + 6 tracks + 4 racing mechs | Medium (parallel to content work) |
| **Post-launch** | Store launch, trailer, marketing | 2 weeks | Steam page live, itch.io upload, trailer video, capsule art | Low (mostly content) |
| **Total** | | **~18 weeks** (4.5 months) | **15 chapters + 4 endings + bounty + racing** | |

**Total elapsed: 2026-06-15 → 2026-10-15** (approximately 4 months)

---

## 3. Sprint 7 — Party System Implementation (3 weeks)

> **Why first**: The 3-pilot + 4-mech system is the foundation for everything else. Sat-3/4/5 content can be designed around it, but the code must be ready first.

### 3.1 Goals

- **Combat rewrite**: `BattleScene` and `WeaponLoadout` support 3 pilots + 4 mechs with free pilot-mech switching (per `party-system.md` §3.4)
- **Dialogue rewrite**: `DialogueManager` supports "main + 1 in-dialogue companion" (per `party-system.md` §3.9)
- **HUD rewrite**: Show 3-4 mech HP bars, pilot assignment, mech cycle UI
- **Death/revival**: Town clinic revival system (per `party-system.md` §3.8)

### 3.2 Stories

| ID | Title | Reference | Effort |
|----|-------|-----------|--------|
| S7-001 | BattleScene: 1v1 → 3v1 (party of 3, single enemy) | party-system.md §3.7 | L |
| S7-002 | WeaponLoadout: pilot-mech decoupling (3-4 weapon slots per mech, cross-pilot) | party-system.md §3.4 | L |
| S7-003 | MechLoadout: 4 mechs (Ranger / Frostbite / Bomber / Cangqiong) with swap | party-system.md §3.5 | M |
| S7-004 | HUD: 3-4 mech HP bars + pilot-mech assignment UI | party-system.md §3.4 | M |
| S7-005 | Dialogue: companion in-dialogue swap (Shift+1/2/3) | party-system.md §3.9 | M |
| S7-006 | Town clinic revival system (gold cost, 25%) | party-system.md §3.8 | M |
| S7-007 | Mech Bay menu (M key) — assign pilots, swap weapons, view part HP | party-system.md §3.4 | M |
| S7-008 | 苍穹号 inheritance scene (Ch13 placeholder for now) | party-system.md §3.6 | M |
| S7-009 | Combat formulas (dodge / hit / crit / damage / XP / revival) | party-system.md §4 | S |
| S7-010 | Save/Load: party state (pilots, mechs, weapons, gold, levels) | party-system.md §6.1 | M |
| S7-011 | Auto mode rewrite (3-pilot AI in Manual+Auto modes) | party-system.md §3.7 | M |
| S7-012 | Tests: fc59-fc66 — party combat, dialogue swap, revival, mech swap | — | S |

**Sprint 7 exit criteria**:
- [ ] 532 existing tests still pass (no regressions)
- [ ] All new tests pass (fc59-fc66)
- [ ] F5 walkthrough: start a new game, recruit Frostbite in Ch4 (existing), recruit Bomber in Ch10 (existing), then F5 to confirm 3-pilot party works in combat
- [ ] 苍穹号 inheritance triggered manually (debug command) — works correctly

**Sprint 7 risks**:
- **R1 (high)**: BattleScene rewrite is large. Risk of breaking existing fights. Mitigation: keep existing 1v1 fights working, add 3v1 as opt-in, then migrate to 3v1 over time.
- **R2 (medium)**: Save file format changes (party state). Old saves may be incompatible. Mitigation: write a save migration script.

---

## 4. Sprint 8 — Sat-3 蜂巢号 Content (3 weeks)

> **Why second**: After Sprint 7, the party system is in place. Now we add the first new content satellite.

### 4.1 Goals

- **Sat-3 蜂巢号** — 3 new chapters (Ch7-Ch9)
- 6 new enemy types, 1 new boss, 4 new NPCs, 7 new truth fragments, 1 new BGM
- New mechanic: 致幻/错觉 (hallucination system)
- New color palette: deep purple + viscous yellow

### 4.2 Stories

| ID | Title | Reference | Effort |
|----|-------|-----------|--------|
| S8-001 | Sat-3 tile assets (4 tiles: floor_hive, floor_hive_damaged, wall_hive, wall_hive_damaged) | — | S |
| S8-002 | Sat-3 title background (title_hive.png) | — | S |
| S8-003 | Sat-3 BGM: "蜂巢之心 (Hive Heart)" — organic drone, 30s loop | — | S |
| S8-004 | 6 enemy types (蜂巢守卫, 蜂巢炮手, 蜂巢寄生, 蜂巢菌丝, 蜂巢幼虫, 蜂巢繁殖体) | — | M |
| S8-005 | 1 boss: 蜂后守卫 (Hive Queen's Guard) — partial-biological, regenerates 5% HP per turn | bounty-system.md §3.4 | M |
| S8-006 | 4 NPCs: 流浪科学家, 蜂巢幸存者, 残存船员, 真菌感染者 | — | M |
| S8-007 | 7 Truth 3 fragments: "Hive Mind" — the hive is the Creator's thinking lobe | multi-satellite-arc.md §4.3 | M |
| S8-008 | 10 rooms (3 per chapter × 3 + 1 boss arena) | — | L |
| S8-009 | New mechanic: hallucination tiles — visual distort, false enemies, false NPCs | — | L |
| S8-010 | Sat-3 dialogue trees (4 NPCs × ~10 lines each) | — | M |
| S8-011 | Tests: fc67-fc72 — Sat-3 content, hallucination mechanic | — | S |

**Sprint 8 exit criteria**:
- [ ] F5 walkthrough Sat-3: enter Sat-3 from Sat-2, traverse 3 chapters, kill boss, collect all 7 Truth 3 fragments
- [ ] Hallucination mechanic testable in F5 (e.g., 蜂巢感染 tile shows 1 false enemy)
- [ ] 532 + 8 (Sprint 7) + 6 (this sprint) tests pass = 546 tests

**Sprint 8 risks**:
- **R1 (high)**: Hallucination mechanic is new. If it's confusing, players will hate it. Mitigation: keep it mild (1-2 false enemies per room, clearly visually distinct from real).
- **R2 (medium)**: 10 rooms of Sat-3 + 4 NPCs + 6 enemies + 1 boss is a lot of content. If pacing is slow, the 3-week sprint slips. Mitigation: scope reduction — drop 1 NPC if needed.

---

## 5. Sprint 9 — Sat-4 断魂号 Content (3 weeks)

> **Why third**: After Sat-3, the team has the workflow down. Sat-4 is a different theme (military/war), so it's a variety break.

### 5.1 Goals

- **Sat-4 断魂号** — 3 new chapters (Ch10-Ch12)
- 6 new enemy types, 1 new boss, 4 new NPCs, 7 new truth fragments, 1 new BGM
- Bomber (轰天) joins in Ch10 (planned since Sprint 6)
- New color palette: dark grey + warning red

### 5.2 Stories

| ID | Title | Reference | Effort |
|----|-------|-----------|--------|
| S9-001 | Sat-4 tile assets (4 tiles: floor_military, floor_military_damaged, wall_military, wall_military_damaged) | — | S |
| S9-002 | Sat-4 title background (title_military.png) | — | S |
| S9-003 | Sat-4 BGM: "残骸回响 (Wreckage Echo)" — distorted military march, 30s loop | — | S |
| S9-004 | 6 enemy types (冥王残兵, 叛变哨兵, 失控无人机, 战损机甲, 残骸机器人, 自毁程序) | — | M |
| S9-005 | 1 boss: 冥王残响 (Pluto Remnant) — fragmented AI, disables one party ability per turn | bounty-system.md §3.4 | M |
| S9-006 | 4 NPCs: 老兵, AI 残骸修复师, 冥王碎片, 战时遗孤 | — | M |
| S9-007 | 7 Truth 4 fragments: "AI Awakening" — Pluto achieved self-awareness | multi-satellite-arc.md §4.4 | M |
| S9-008 | 10 rooms (Ch10-Ch12) | — | L |
| S9-009 | New mechanic: AI-controlled enemy mechs (some ally with the party) | — | M |
| S9-010 | Bomber's recruitment scene (Ch10 mid, Room 5) | party-system.md §3.3 | M |
| S9-011 | Holo-recording of Mei Zhang (Bomber's father) | multi-satellite-arc.md §11 Q5 | S |
| S9-012 | Tests: fc73-fc78 — Sat-4 content, AI mechanic, Bomber recruit | — | S |

**Sprint 9 exit criteria**:
- [ ] F5 walkthrough Sat-4: recruit Bomber in Ch10, traverse 3 chapters, kill Pluto Remnant boss, collect all 7 Truth 4 fragments
- [ ] AI-controlled enemies can be allied with (1-2 cases)
- [ ] 552 tests pass (added 6 in this sprint)

**Sprint 9 risks**:
- **R1 (medium)**: "AI as enemy / sometimes ally" is a morally nuanced mechanic. Players may be confused. Mitigation: visual cue (allied AI glow blue, enemy AI glow red).
- **R2 (low)**: Sat-4 is the 2nd new content satellite. The team should be in a rhythm. If slipped, smaller scope.

---

## 6. Sprint 10 — Sat-5 起源号 + 4 Endings (4 weeks)

> **Why 4 weeks (not 3)**: Sat-5 is the climax, AND the 4-ending rewrite is non-trivial. Need extra time.

### 6.1 Goals

- **Sat-5 起源号** — 3 new chapters (Ch13-Ch15) — the **climax** of the game
- 1 final boss (the Creator), 4 NPCs (3 returning + 1 new), 7 new truth fragments, 1 new BGM
- The 苍穹号 inheritance scene (Ch13 end)
- 4 endings rewrite (A / B / C / D) — full narrative
- The Creator encounter in Ch15 (Transcend / Understand / Destroy / Flee dialogue)

### 6.2 Stories

| ID | Title | Reference | Effort |
|----|-------|-----------|--------|
| S10-001 | Sat-5 tile assets (4 tiles: floor_ancient, floor_ancient_glowing, wall_ancient, wall_ancient_glowing) | — | S |
| S10-002 | Sat-5 title background (title_creator.png — gold + deep purple) | — | S |
| S10-003 | Sat-5 BGM: "造物者之梦 (Creator's Dream)" — cosmic ambient, 60s loop | — | S |
| S10-004 | 1 final boss: 造物者本体 (the Creator) — multiple phases, 5 attack patterns | multi-satellite-arc.md §3.5 | L |
| S10-005 | 4 NPCs: 苍穹号 (NPC, deceased), 漫游者父亲 (ghost), 霜尾母亲 (merged with frozen fragment), 轰天父亲 (ghost) | — | M |
| S10-006 | 7 Truth 5 fragments: "The Creator Sleeps" — ancient cosmic organism | multi-satellite-arc.md §4.5 | M |
| S10-007 | 10 rooms (Ch13-Ch15) | — | L |
| S10-008 | 苍穹号 inheritance scene (Ch13, Room 9) — find dead pilot, claim mech | party-system.md §3.3 | L |
| S10-009 | The Creator chamber (Ch15) — dialogue + boss fight | multi-satellite-arc.md §5 | L |
| S10-010 | Ending A scene: 10 years later, museum | — | M |
| S10-011 | Ending B scene: 1,000 years later, descendant on new world | — | M |
| S10-012 | Ending C scene: 50 years later, Frostbite + Bomber at shrine | — | M |
| S10-013 | Ending D scene: 1 year later, Creator leaves solar system | — | M |
| S10-014 | 造物者定位器 (from Bounty #5) integration — unlocks Transcend option | multi-satellite-arc.md §5.3 | M |
| S10-015 | EndingController rewrite: 4 endings, 4 post-credit scenes, 4 save stamps | multi-satellite-arc.md §5 + existing controller | L |
| S10-016 | Tests: fc79-fc84 — Sat-5, 4 endings, Creator dialogue, 苍穹号 scene | — | S |

**Sprint 10 exit criteria**:
- [ ] F5 walkthrough Sat-5: get 苍穹号, traverse 3 chapters, reach Creator, all 4 endings reachable
- [ ] 4 endings all have unique post-credit scenes
- [ ] All 35 truth fragments collectible
- [ ] 558 tests pass (added 6 in this sprint)

**Sprint 10 risks**:
- **R1 (very high)**: This is the climax. Quality bar is highest. If pacing is wrong, the climax falls flat. Mitigation: 4 weeks (not 3) for extra time.
- **R2 (high)**: The Creator dialogue must be carefully written — it's the emotional peak. Mitigation: draft dialogue in week 1, polish in week 2, voice-over considerations in week 3 (deferred).
- **R3 (medium)**: Save/load complexity: each ending needs a save stamp. Old saves need migration. Mitigation: write migration script in week 1.

---

## 7. Sprint 11 — Bounty + Racing Implementation (3 weeks)

> **Why now**: Party + 5 satellites are done. Now the **side content** (bounty + racing) can be added without blocking the main story.

### 7.1 Goals

- **Bounty system implementation** — 6 bounties, town boards, special tool drops
- **Racing minigame implementation** — 6 tracks, 4 mechs, betting UI
- All bounties and tracks accessible from appropriate town/arena locations

### 7.2 Stories

| ID | Title | Reference | Effort |
|----|-------|-----------|--------|
| S11-001 | BountyBoard UI (town interaction) | bounty-system.md §3.2 | M |
| S11-002 | Bounty acceptance / tracking / abandonment flow | bounty-system.md §3.8 | M |
| S11-003 | Bounty #1: 隐藏的猎手 (Sat-1) — boss + reward (冰封探测器) | bounty-system.md §3.4 | M |
| S11-004 | Bounty #2: 叛徒的遗产 (Sat-2, PLOT) — required for Sat-2 → Sat-3 | bounty-system.md §3.3 | L |
| S11-005 | Bounty #3: 蜂后守卫 (Sat-3) — boss + reward (蜂巢扫描器) | bounty-system.md §3.4 | M |
| S11-006 | Bounty #4: AI 残响 (Sat-4) — boss + reward (军用干扰器) | bounty-system.md §3.4 | M |
| S11-007 | Bounty #5: 造物者的回声 (Sat-5) — boss + reward (造物者定位器) | bounty-system.md §3.4 | M |
| S11-008 | Bounty #6: post-game hidden bounty (Sat-5) | bounty-system.md §3.1 | M |
| S11-009 | Special tools: 冰封探测器, 蜂巢扫描器, 军用干扰器, 造物者定位器, 苍穹号强化部件 | bounty-system.md §3.6 | M |
| S11-010 | Bounty medal collectible + UI display | bounty-system.md §3.5 | S |
| S11-011 | Fool's Bounty safety valve (5 failures → buff) | bounty-system.md §3.9 | S |
| S11-012 | Racing Arena (town room + betting counter UI) | racing-minigame.md §3.1 | M |
| S11-013 | 4 racing mech assets (铁驭, 星尘, 战狼, 鬼影) | racing-minigame.md §3.2 | S |
| S11-014 | 6 track assets (visual themes) | racing-minigame.md §3.3 | M |
| S11-015 | Race animation (top-down 30-60s) | racing-minigame.md §3.5 | L |
| S11-016 | Betting UI (odds display, bet amount) | racing-minigame.md §3.4 | M |
| S11-017 | Race outcome formula (deterministic seed + stat-based) | racing-minigame.md §4 | M |
| S11-018 | NPC bettors (3-5 per arena, visual flavor) | racing-minigame.md §3.7 | S |
| S11-019 | Post-game high-stakes mode (50k bet cap) | racing-minigame.md §3.4 | S |
| S11-020 | Tests: fc85-fc92 — bounty + racing | — | S |

**Sprint 11 exit criteria**:
- [ ] F5 walkthrough bounty: accept Bounty #1 in Sat-1 town, complete fight, receive reward
- [ ] F5 walkthrough racing: enter arena, bet on 鬼影, win, receive payout
- [ ] All 6 bounties accessible (Bounty #6 is post-game)
- [ ] All 6 tracks playable
- [ ] 564 tests pass (added 6 in this sprint)

**Sprint 11 risks**:
- **R1 (high)**: Bounty #2 is plot-required. The transition from "optional side content" to "story-blocking required content" needs careful design. Mitigation: integrate Bounty #2 with Sat-2 → Sat-3 transition narrative (already done in bounty-system.md §3.3).
- **R2 (medium)**: Race animation is a non-trivial art task. The 30-60s race is a lot of frames. Mitigation: use simple top-down + particle effects, don't aim for cinematic quality.

---

## 8. Post-Launch Sprint — Store + Trailer (2 weeks)

> **Why post-launch**: After 5 months of work, the game is **feature-complete** (15 chapters, 4 endings, bounty, racing, party). Now we can ship.

### 8.1 Goals

- Real F5 sweep in Godot editor (visual + audio verification)
- Capture 6+ screenshots for Steam/itch.io
- Run `tools/build.sh linux windows mac` to produce first binaries
- Upload to itch.io
- Steam page live (existing draft)
- 30-60s trailer video

### 8.2 Stories

| ID | Title | Reference | Effort |
|----|-------|-----------|--------|
| PL-001 | Real F5 sweep — all 15 chapters, 4 endings, bounty, racing | — | L |
| PL-002 | Capture 6 screenshots (1920×1080, one per satellite + 1 ending scene) | — | M |
| PL-003 | Capture 30-60s trailer (1-2 minutes of gameplay + ending tease) | — | M |
| PL-004 | Edit trailer (cut + music + captions) | — | M |
| PL-005 | Run `tools/build.sh linux windows mac` — first binaries | — | M |
| PL-006 | Upload to itch.io via butler | — | S |
| PL-007 | Steam page submit (existing draft, fill metadata) | — | S |
| PL-008 | Capsule art (paid designer, ~$50-200) | — | External |
| PL-009 | Final test sweep: 564 + any new tests | — | S |

**Post-launch exit criteria**:
- [ ] itch.io page live
- [ ] Steam page submitted for review
- [ ] Trailer video on YouTube
- [ ] 3 binaries (Linux, Windows, Mac) downloadable

**Post-launch risks**:
- **R1 (medium)**: Steam review can take 1-4 weeks. Plan for this.
- **R2 (low)**: itch.io upload is straightforward (butler push).

---

## 9. Critical Path (what MUST be done in order)

```
Sprint 7 (Party implementation)
  └─ Required for Sprint 8 (party must work before content uses it)
      └─ Required for Sprint 9 (same reason)
          └─ Required for Sprint 10 (苍穹号 inheritance + Creator encounter use party)
              └─ Required for Sprint 11 (bounty + racing assume party)
                  └─ Required for Post-launch (full game)
```

**No parallelism** between these sprints. Sprint 7-11 are **strictly sequential**.

**Within each sprint**, parallelism is possible:
- Sprint 8: art (tiles + sprites) parallel to coding (hallucination mechanic) parallel to dialogue writing
- Sprint 9: same
- Sprint 10: art + dialogue + ending scenes can be parallel

---

## 10. Open Questions (to resolve before Sprint 7 starts)

- **OQ1**: How much time per week is the user committing? (3 weeks of Sprint 7 = how many hours/week?) Affects whether 3-week sprint is realistic.
- **OQ2**: Are there any external help (paid contractors, AI assistance beyond Claude) planned? Currently: solo + Claude.
- **OQ3**: Is the "5 satellites × 3 chapters = 15 chapters" the FINAL scope, or could the user add Sat-6+ in the future? Affects how much "future-proofing" the code needs.
- **OQ4**: The 苍穹号 inheritance is currently Ch13 end. If the user plays through Ch1-12 in one session, they hit it at the right time. But if they save and quit, the inheritance scene still triggers. Is this OK? (Currently: yes, per party-system.md §3.3.)
- **OQ5**: The post-launch "trailer" — who records it? Currently: user F5s, Claude edits. If user is not comfortable editing video, may need external help.
- **OQ6**: Should we **integrate Sprint 7's party system with the existing 1-pilot Ch1-3 BEFORE Sprint 8 starts**, or **add party to Ch1-3 as a Sprint 7 stretch goal**? Affects whether Sat-1/Sat-2 party mechanics are available from the start.
- **OQ7**: The bounty system's "Fool's Bounty" safety valve (5 failures) — is 5 the right number? Could be tuned. Defer to Sprint 11.
- **OQ8**: The racing minigame's 6 tracks — is 6 the right number for the final game, or should we ship with 3 and add 3 more later? Currently: 6. Defer to Sprint 11.

---

## 11. Total Effort Estimate

| Sprint | Weeks | Stories | New Tests | New Lines (est) |
|--------|-------|---------|-----------|-----------------|
| 7 | 3 | 12 | 8 | ~3000 |
| 8 | 3 | 11 | 6 | ~2500 |
| 9 | 3 | 12 | 6 | ~2500 |
| 10 | 4 | 16 | 6 | ~3500 |
| 11 | 3 | 20 | 8 | ~4000 |
| Post-launch | 2 | 9 | 0 | ~500 |
| **Total** | **18 weeks (~4.5 months)** | **80 stories** | **34 new tests** | **~16,000 new lines** |

**Test count progression**: 532 → 540 → 546 → 552 → 558 → 564 (Sprint 11 end)

**At end of post-launch**: 564 tests + game complete + 4 endings reachable + all side content.

---

## 12. Dependencies on Outside Help

- **Capsule art (Post-launch PL-008)**: $50-200 paid designer. Optional but recommended for Steam.
- **Trailer music** (Post-launch PL-004): If the user wants a custom music track, may need a composer. Or use royalty-free from the existing 3 ambient tracks + new Sat-3/4/5 music.
- **Voice-over**: If the user wants voice acting, would need voice actors. Currently: NO voice acting planned. Dialogue is text-only.
- **Localization beyond EN+ZH**: Would need translators. Currently: EN + ZH (existing strings.csv). Adding JA/KO would be Sprint 12+.

**User's current capabilities** (per Sprint 6 close):
- Solo dev + Claude (me) as on-demand help
- F5 in Godot editor (yes, user can do this)
- Basic video editing (assumed yes)
- Marketing / Steam page setup (assumed yes)

---

## 13. Success Criteria (this roadmap's success)

The roadmap succeeds when:

1. **Sprint 7-11 exit criteria are all met** (per each sprint's checklist).
2. **All 4 endings are reachable** in a fresh playthrough (15-25 hours).
3. **All 6 bounties are completable** with reasonable challenge.
4. **All 6 tracks are playable** with reasonable fun.
5. **564 tests pass** (100% pass rate).
6. **The game can be F5'd from start to finish** without crashes.
7. **Post-launch**: 3 binaries downloadable, Steam/itch.io pages live.

**The roadmap fails** if:
- Sprints slip by >2 weeks (overall plan is no longer valid)
- 4 endings are not all reachable (story is broken)
- Critical bugs in combat (party / mech swap) prevent progression
- Save/load corruption (player progress lost)

---

## 14. Versioning

This roadmap corresponds to:
- **Game version target**: **v1.5.0** (was v1.0.0-rc1)
- **Sprint versions**: 7, 8, 9, 10, 11 (vs 1, 2, 3, 4, 5, 6 of the original plan)
- **Story IDs**: S7-XXX, S8-XXX, S9-XXX, S10-XXX, S11-XXX, PL-XXX

The version bump from v1.0.0-rc1 to v1.5.0 reflects the **scope expansion** (3 chapters → 15 chapters, 0 bounty → 6, 0 racing → 6 tracks, 1 pilot → 3).

---

## 15. Next Action (this week)

**Before Sprint 7 starts, decide**:

1. **Commit Sprint 6 close** (you deferred S6-000 + S6-001) — should we commit now?
2. **Tag v1.0.0-rc1** — confirmed in the conversation earlier today; needs the commit to land.
3. **Start Sprint 7** — first story: S7-001 (BattleScene 1v1 → 3v1).

**Recommended sequence for the rest of this week**:
1. Review this roadmap with the user (you're reading it now).
2. Resolve OQ1 (weekly time commitment).
3. Resolve OQ6 (integrate party with Ch1-3 in Sprint 7, or just Ch4+).
4. Tag Sprint 6 close as v1.0.0-rc1 (the commit is already there).
5. Start Sprint 7 planning — break down S7-001 to S7-012 into individual task entries.

**If you want to start now**: I can begin the Sprint 7 entry — write `production/sprints/sprint-07-party-implementation.md` with the same structure as the existing sprint docs.

---

*Roadmap created. Update this file at the end of each sprint with: actual dates, actual effort, lessons learned, scope adjustments.*
