# Sprint 11 — Bounty + Racing Implementation

## Sprint Goal

Implement the two **side content systems** specified in the GDDs: **6 bounties** (1 plot + 5 optional + 1 post-game) and **6 racing tracks** (with 4 racing mechs, fixed-odds betting, deterministic outcomes). Both systems are **side content** — they don't block the main story, but they provide the "found family of mech pilots" fantasy with money-earning, gambling, and tougher-than-main challenges. After this sprint, the player can earn gold by racing, spend it on bounty attempts, and unlock **5 unique Special Tools** that provide QoL boosts in subsequent play. This is the **last implementation sprint** before post-launch marketing.

## Milestone Context

- **Current Milestone**: Production (started 2026-06-13)
- **Sprint 10 Status**: Should be complete or near-complete (Sat-5 起源号 + 4 endings)
- **Sprint 11 Deadline**: 2026-10-05 (3 weeks from Sprint 10 close)
- **Roadmap Position**: Fifth and **last implementation sprint** in the post-GDD phase

## Why This Sprint Last (After Sat-5 + 4 Endings)

The roadmap (see `production/roadmap-2026-q3.md`) ordered **content first (Sprint 8-10), then systems (Sprint 11)** because:
- Sprint 10 makes the game **feature-complete** — all main story content, all 4 endings reachable
- Sprint 11 adds **side content** that doesn't block the main story
- Players can complete the game without touching bounties or racing, but the side content adds replay value
- **Bounty #2 is the only required bounty** — it's the Sat-2 → Sat-3 transition (per multi-satellite-arc.md §3.3). The other 5 bounties are optional.

Sprint 11 also adds **5 unique Special Tools** (1 per optional bounty) that provide QoL boosts:
- 冰封探测器 (reveals hidden enemies)
- 蜂巢扫描器 (reveals hidden paths)
- 军用干扰器 (disables enemy attack 1/turn)
- 造物者定位器 (reveals Creator dialogue options — **required for True Ending A**)
- 苍穹号强化部件 (post-game only — +1 weapon slot for 苍穹号)

The 造物者定位器 is the **most strategically important** tool — it's required for the True Ending A. Sprint 10's True Ending code already references this tool (Sprint 10, OQ10), so Sprint 11 must deliver it.

## Capacity

- **Total days**: 21 (3 weeks × 7 days)
- **Buffer (20%)**: 4.2 days
- **Available**: 16.8 days
- **Estimated total work**: 17 days. **At capacity.** If any L story slips by 1+ day, the sprint slips.

## Sprint Scope (one-liner per story)

The 20 stories below are organized into **4 critical-path waves**.

- **Wave 1 (Days 1-5): Town boards + bounty UI**
  - S11-001 BountyBoard UI (town interaction) (M)
  - S11-002 Bounty acceptance / tracking / abandonment (M)
  - S11-003 Bounty medal collectible (S)
  - S11-004 Pre-fight setup screen (M)
  - S11-005 Fool's Bounty safety valve (S)

- **Wave 2 (Days 6-12): 6 bounty bosses + 5 special tools**
  - S11-006 Bounty #1: 隐藏的猎手 (Sat-1) (M)
  - S11-007 Bounty #2: 叛徒的遗产 (Sat-2, PLOT) (L)
  - S11-008 Bounty #3: 蜂后守卫 (Sat-3) (M)
  - S11-009 Bounty #4: AI 残响 (Sat-4) (M)
  - S11-010 Bounty #5: 造物者的回声 (Sat-5) (M)
  - S11-011 Bounty #6: post-game hidden (Sat-5) (M)
  - S11-012 5 Special Tools (consumable items) (M)

- **Wave 3 (Days 13-18): Racing arena + 6 tracks + 4 mechs**
  - S11-013 Racing Arena (town room) (M)
  - S11-014 Betting counter UI (M)
  - S11-015 4 racing mech assets (M)
  - S11-016 6 track assets (M)
  - S11-017 Race animation (30-60s top-down) (L)
  - S11-018 Race outcome formula (deterministic seed) (M)
  - S11-019 NPC bettors (S)

- **Wave 4 (Days 19-21): Tests + verification**
  - S11-020 Tests fc85-fc92 (S)

---

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|--------------|-------------------|--------|
| S11-001 | BountyBoard UI (town interaction) | ui-programmer | 1.0 | None | A new object "BountyBoard" exists in every major town; player presses E to open a UI showing all available bounties for the current satellite; UI shows: bounty name, target portrait, location, threat level, reward summary, weaknesses, recommended level, status (AVAILABLE / ACCEPTED / COMPLETED); per bounty-system.md §3.2 | Not Started |
| S11-002 | Bounty acceptance / tracking / abandonment flow | godot-gdscript-specialist | 1.0 | S11-001 | Player can accept a bounty from the board; the bounty is added to the Quest menu's "BOUNTIES" tab; the bounty arena is marked on the minimap with a skull icon; player can abandon a non-plot bounty; plot bounty (Bounty #2) cannot be abandoned; per bounty-system.md §3.8 | Not Started |
| S11-003 | Bounty medal collectible | systems-designer | 0.5 | S11-002 | A new resource type "BountyMedal" with id/display_name/description/icon; 6 medals exist (1 per bounty); medals are auto-granted on bounty completion; the player's collection is visible in the main menu ("Bounty Medals: 3/6") | Not Started |
| S11-004 | Pre-fight setup screen (Mech Bay access + consumable use + intel) | godot-gdscript-specialist | 1.5 | S11-002 | Before each bounty fight, the player enters a "Pre-fight Setup" screen; can access the Mech Bay (Sprint 7's party system), can swap weapons between mechs, can use consumables, can read the boss's full stats and weaknesses on an "Intel" screen; the player presses "BEGIN FIGHT" to start; per bounty-system.md §3.7 | Not Started |
| S11-005 | Fool's Bounty safety valve (5 failures → buff) | systems-designer | 0.5 | S11-004 | Track per-bounty `consecutive_failures`; after 5 failures, the next attempt grants the Fool's Bounty buff (+25% damage, +10% dodge, -20% boss HP); buff does NOT apply to the plot bounty (Bounty #2); per bounty-system.md §3.9 | Not Started |
| S11-006 | Bounty #1: 隐藏的猎手 (Sat-1) | systems-designer + godot-gdscript-specialist | 1.0 | S11-004 | 1 .tres in `data/enemies/bounty_hidden_hunter.tres`; HP=1200 (2.5x Sat-1 normal boss), ATK=25, ACC=0.85; **special mechanic**: invisibility every 2 turns; weakness: fire (×2); fight arena: Sat-1 Room 5 (hidden mech bay); drops: 冰封探测器 (Special Tool #1) + 1 unique weapon (Frostbite Knife); recommended level 5+ | Not Started |
| S11-007 | Bounty #2: 叛徒的遗产 (Sat-2, PLOT) — required for Sat-2 → Sat-3 | godot-gdscript-specialist + writer | 1.5 | S11-004, S10-013 reference | 1 .tres in `data/enemies/bounty_dr_lyra.tres`; HP=1500, ATK=30, ACC=0.90; **special mechanics**: parasite swarm (every 3 turns, summon 3 weak parasites), frost aura (-25% damage from non-ice weapons); phase 2 at 50% HP (+50% ATK, +20% ACC, heals 200 HP); fight arena: Sat-2 Room 9 (Dr. Lyra's hidden lab); drops: Chen Family Rifle + Lyra's Datachit (Special Tool #0, plot-required); recommended level 12+; **PLOT-REQUIRED** for Sat-2 → Sat-3 transition (failing = game over) | Not Started |
| S11-008 | Bounty #3: 蜂后守卫 (Sat-3) | systems-designer + godot-gdscript-specialist | 1.0 | S11-004 | 1 .tres in `data/enemies/bounty_hive_guardian.tres`; HP=2000, ATK=35, ACC=0.85; **special mechanic**: regenerates 5% HP per turn (must be killed quickly); weakness: fire (×2); fight arena: Sat-3 Room 8 (hive's deepest chamber); drops: 蜂巢扫描器 (Special Tool #2) + 1 unique weapon (Hive Knife); recommended level 18+ | Not Started |
| S11-009 | Bounty #4: AI 残响 (Sat-4) | systems-designer + godot-gdscript-specialist | 1.0 | S11-004 | 1 .tres in `data/enemies/bounty_ai_remnant.tres`; HP=2800, ATK=40, ACC=0.88; **special mechanic**: disables 1 player ability per turn (random); weakness: EMP (×2); fight arena: Sat-4 Room 7; drops: 军用干扰器 (Special Tool #3) + 1 unique weapon (Plasma Saw); recommended level 25+ | Not Started |
| S11-010 | Bounty #5: 造物者的回声 (Sat-5) | systems-designer + godot-gdscript-specialist | 1.0 | S11-004 | 1 .tres in `data/enemies/bounty_creator_echo.tres`; HP=3500, ATK=45, ACC=0.90; **special mechanic**: mirrors the party's last 3 actions (uses the same attacks the party used last turn, but stronger); weakness: 苍穹号 (+50% damage); fight arena: Sat-5 Room 10; drops: 造物者定位器 (Special Tool #4, **required for True Ending A**) + 1 unique weapon (Echo Blade); recommended level 35+ | Not Started |
| S11-011 | Bounty #6: post-game hidden (Sat-5) | systems-designer + godot-gdscript-specialist | 1.0 | S11-010 | 1 .tres in `data/enemies/bounty_what_if.tres`; HP=5000, ATK=50, ACC=0.92; **5 phases**, each mirroring a main-story boss attack pattern (Sat-1 / Sat-2 / Sat-3 / Sat-4 / Creator); fight arena: a new "Dream Arena" room unlocked in Sat-5; drops: 苍穹号强化部件 (Special Tool #5) + 1 unique weapon (Final Blade); **unlocked only after completing the main story**; recommended level 40+ | Not Started |
| S11-012 | 5 Special Tools (consumable items) | systems-designer | 1.0 | S11-006..S11-011 | 5 .tres in `data/tools/special_*.tres`; 冰封探测器 (3 uses, reveals hidden enemies), 蜂巢扫描器 (3 uses, reveals hidden paths), 军用干扰器 (1 use, disables 1 enemy attack/turn), 造物者定位器 (1 use, reveals Creator dialogue in Ch15), 苍穹号强化部件 (1 use, +1 weapon slot for 苍穹号); each tool has an icon, description, and use count; tools are consumable and have unique use effects in combat/exploration | Not Started |
| S11-013 | Racing Arena (town room) | level-designer | 1.0 | None | A new room type "Racing Arena" exists in every major town (5 arenas total); each arena has: a central holographic display, a betting counter with a friendly NPC bookie, 3-5 NPC bettors, a small lounge area; per racing-minigame.md §3.1 | Not Started |
| S11-014 | Betting counter UI | ui-programmer | 1.0 | S11-013 | Player opens betting counter, sees 4 mechs (left) and 6 tracks (right) and bet amount input (center); selecting a track shows odds for each mech; selecting a mech shows potential payout; player enters bet amount (100-5,000 gold); confirms and race begins; per racing-minigame.md §3.4 | Not Started |
| S11-015 | 4 racing mech assets | technical-artist (Python synth) | 1.0 | None | 4 PNGs in `assets/sprites/racing/`: 铁驭 (heavy, dark grey + orange), 星尘 (light, silver + blue), 战狼 (medium, red + black), 鬼影 (trickster, sleek black with neon highlights); each has 4-direction animation frames (left, right, forward, back) for the race animation; stats per racing-minigame.md §3.2 | Not Started |
| S11-016 | 6 track assets | technical-artist (Python synth) | 1.0 | None | 6 track backgrounds in `assets/sprites/racing/tracks/`: 极星赛道 (Polar Star, frozen industrial), 迷雾赛道 (Mist, foggy corridor), 深空赛道 (Deep Space, floating platform), 岩浆赛道 (Lava, volcanic), 幻影赛道 (Phantom, color-shifting), 极光赛道 (Aurora, alien landscape); each is a top-down background that the 4 mechs race across; hazards are visual (lava jets, phasing, etc.) | Not Started |
| S11-017 | Race animation (30-60s top-down) | gameplay-programmer + animator | 2.0 | S11-015, S11-016 | A 30-60 second race animation per racing-minigame.md §3.5: pre-race (3-5s, mechs lined up), start gun (1s), laps (5-15 laps, 2-5s each), final stretch (3-5s), finish line (2s), results (3s), payout (2s); SPACE skips the animation; per-track BGM plays during the race; visual quality: top-down pixel art, simple but readable | Not Started |
| S11-018 | Race outcome formula (deterministic seed + stat-based) | systems-designer | 1.0 | S11-014, S11-015, S11-016 | Implementation of the formula per racing-minigame.md §4 F1: race_seed = hash(track_id, save.race_counter, track_secret); per lap, per mech, lap_time = base - (speed × 0.05) + stamina_penalty + hazard_penalty + lucky_event; winner = mech with lowest cumulative_time; payout = bet × odds (1.5x-8x); gold cap = 999,999; book edge ~5% (favorites win ~45% of the time but pay 1.5x) | Not Started |
| S11-019 | NPC bettors (3-5 per arena) | writer + ui-programmer | 0.5 | S11-013 | 3-5 NPC bettors per arena, with visual variety (different sprites per town theme: Sat-1 dock workers, Sat-2 cold merchants, Sat-3 hive observers, Sat-4 veterans, Sat-5 cultists); NPCs have 2-3 idle dialogue lines; NPCs react to races (cheers, groans) but don't actually bet; per racing-minigame.md §3.7 | Not Started |
| S11-020 | Tests fc85-fc92 — bounty + racing | qa-tester | 0.5 | All S11-001..S11-019 | 8 new integration test files created; 558 existing tests still pass (532 Sprint 6 + 8 Sprint 7 + 6 Sprint 8 + 6 Sprint 9 + 6 Sprint 10); all 8 new tests pass; tests cover: BountyBoard UI shows bounties correctly, all 6 bounties reachable, Bounty #2 is plot-required (failing = game over), all 5 Special Tools work, Racing Arena opens, betting UI works, race animation plays, deterministic race outcomes, NPC bettors present | Not Started |

**Subtotal**: 20 stories, ~17 days estimated. **At capacity** (16.8 days). 0.2 day buffer.

### Should Have (cut if time-pressed)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|--------------|-------------------|--------|
| S11-021 | High-stakes mode (post-game 50k bet cap) | ui-programmer | 0.5 | S11-014 | After completing the main story, a "high-stakes" mode unlocks in the betting counter; max bet is 50,000 gold; same tracks and mechs (no new content); per racing-minigame.md §3.4 | Not Started |
| S11-022 | Intel screen hints scale with consecutive failures (1 hint per failure) | ui-programmer | 0.5 | S11-004 | The Intel screen shows 1 hint on first attempt; each failed attempt adds 1 more hint (up to 5 hints); per bounty-system.md §3.9 | Not Started |
| S11-023 | Bounty medal showcase (menu) | ui-programmer | 0.5 | S11-003 | A new "Bounty Hall" menu in the main menu shows all 6 bounty medals with their bosses' portraits and lore; cosmetic but satisfying for completionists | Not Started |
| S11-024 | Racing record / stats menu (per-track win rate, etc.) | ui-programmer | 0.5 | S11-014 | A "Racing Record" menu shows: total races run on each track, win rate, largest payout, total gold won/lost; visible from the betting counter | Not Started |

### Nice to Have (Cut First)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|-----------|-------------------|--------|
| S11-030 | Player mech can enter races (replacing 1 of 4 NPC mechs) | godot-gdscript-specialist | 1.5 | S11-018 | The player can choose to enter their own mech (any from the player's roster) in a race, replacing 1 of the 4 NPC mechs; the player's mech is the favorite (1.5x odds); player can bet on their own mech (self-bet) | Not Started |
| S11-031 | Racing leaderboard (online / offline) | systems-designer | 2.0 | S11-018 | An offline leaderboard tracks the best race times per track across the player's save files; an online leaderboard (Steam) would compare against other players (deferred to post-launch) | Not Started |
| S11-032 | Bounty board random events (limited-time bounties) | systems-designer | 1.0 | S11-001 | Once per in-game week, a random "limited-time" bounty appears on the board with a 2x reward multiplier; the player has 7 in-game days to complete it; if not completed, it disappears | Not Started |

## Risks to This Sprint

| Risk | Probability | Impact | Mitigation | Owner |
|------|------------|--------|-----------|-------|
| 6 bounty bosses are too grindy to implement (each has unique mechanics) | High | High | Use a **shared boss template** (1 day) that handles HP, attack pattern, special ability trigger; each bounty is then mostly data (.tres file) + a small "ability script" for unique mechanics; reduces 6 bosses from 6×2 days to 1 + 6×0.5 days | systems-designer + godot-gdscript-specialist |
| Race animation (S11-017) is art-heavy (2 days) and may slip | High | High | Use a **simple top-down view** with 4 mechs as colored squares (not detailed sprites); focus on smooth movement + lap counting, not visual polish; can be enhanced post-launch | gameplay-programmer + animator |
| Bounty #2 (S11-007) is plot-required and breaks the Sat-2 → Sat-3 transition if not implemented | Medium | Critical | Sprint 10 already references Bounty #2 (multi-satellite-arc.md §3.3); verify the Sat-2 → Sat-3 jump point triggers after Bounty #2 completion; if Bounty #2 slips, the game cannot be completed past Sat-2 | godot-gdscript-specialist + lead-programmer |
| 20 stories in 16.8 days is at capacity — sprint slips if any L story takes longer | Very High | High | Cut Should-Haves aggressively (S11-021/22/23/24 are the buffer); if S11-007 (plot bounty) slips, the entire game is broken — do not cut this one | user decision |
| Deterministic race outcome (S11-018) might not feel "random" enough | Low | Low | Test the formula with multiple seeds; verify that the same save + race counter always produces the same outcome; verify that different save files produce different outcomes; tune the "lucky event" probability | systems-designer |
| Special Tools (S11-012) have effects that touch many systems (especially 造物者定位器) | Medium | High | Each tool's effect is **isolated** (a new `special_tool.gd` script per tool); the 造物者定位器 integrates with the Ch15 Creator chamber's dialogue (Sprint 10's S10-013); verify the integration works in S11-020 tests | systems-designer |
| Bounty board UI (S11-001) and betting counter UI (S11-014) are both complex — risk of one slipping | High | Medium | Both are M (1 day) — schedule them at the start of their respective waves (Wave 1 and Wave 3); do not let them drag into other waves | ui-programmer |
| Save/load: bounty state (accepted, completed, fail counter) must persist | Medium | Medium | Save schema extends Sprint 7's party state with: bounty state per slot, race counter, racing record; old saves are unaffected (bounty/racing is new content) | godot-gdscript-specialist |
| Race BGM (per racing-minigame.md §3.5) needs 6 unique tracks | Low | Low | Use a single BGM with subtle variation per track; or use one BGM and have the visual carry the variety; defer 6 unique BGMs to post-launch | audio-director |

## Open Questions (need user input before or during sprint)

- **OQ1**: How many hours/week will the user commit to Sprint 11? (3 weeks of 16.8 days = ~5.6 days/week = ~45 hours/week.) Same as Sprint 7-10 question.
- **OQ2**: The **race animation (S11-017)** is 30-60 seconds. Is this the right length? Currently planned: 30-60s per racing-minigame.md §3.5. If too long, reduce to 15-30s.
- **OQ3**: The **Special Tools (S11-012)** — should the **造物者定位器 be available BEFORE Sprint 10's Ch15?** If yes, the player can find it in Sat-5 exploration. If no, it's bounty-only. Currently planned: bounty-only. Confirm.
- **OQ4**: The **Fool's Bounty safety valve (S11-005)** — is 5 failures the right number? Currently per bounty-system.md §3.9. If the user wants a different number, change in S11-005.
- **OQ5**: The **6 bounty bosses** — are the recommended levels (5/12/18/25/35/40) correct? Currently per bounty-system.md §3.1. Confirm.
- **OQ6**: The **Bounty #6 (post-game hidden)** — should it be **in scope for Sprint 11** or **deferred to post-launch DLC**? Currently planned: in Sprint 11. If deferred, mark as Nice-to-Have.
- **OQ7**: The **"Player mech can enter races" (S11-030)** is currently Nice-to-Have. Should it be **in Sprint 11** or **deferred**? Currently: defer.
- **OQ8**: The **6 racing tracks' BGMs** — should they be 6 unique tracks, 1 shared track, or 1 track per zone? Currently planned: 1 shared track with subtle variation. If the user wants 6 unique, this becomes a 1-2 day additional task.
- **OQ9**: The **"造物者定位器" effect on the True Ending** — currently per multi-satellite-arc.md §5.3, the Locator unlocks the "Transcend" option. Sprint 10's S10-013 references this. Confirm the integration works (Sprint 11 must deliver the tool, Sprint 10 must read it).
- **OQ10**: The **"online leaderboard" (S11-031)** is currently Nice-to-Have. Should it be **in scope** (Steam integration) or **deferred to post-launch**? Currently: defer to post-launch.

## Definition of Done

- [ ] All 20 Must-Have tasks completed (S11-001 to S11-020)
- [ ] All tasks pass acceptance criteria
- [ ] 558 existing tests still pass (no regressions)
- [ ] 8 new tests (fc85-fc92) all pass
- [ ] F5 walkthrough bounty: accept Bounty #1 in Sat-1 town, complete fight, receive 冰封探测器
- [ ] F5 walkthrough bounty: complete Bounty #2 (plot), unlock Sat-2 → Sat-3 jump point
- [ ] F5 walkthrough bounty: complete Bounty #5, receive 造物者定位器
- [ ] F5 walkthrough: True Ending A still works (player has 造物者定位器, Transcend option visible)
- [ ] F5 walkthrough racing: enter arena, bet on 鬼影, win, receive payout
- [ ] F5 walkthrough: all 5 Special Tools work correctly (consumed in 1 use)
- [ ] F5 walkthrough: Fool's Bounty triggers after 5 consecutive failures
- [ ] Visual: 4 racing mechs are visually distinct; 6 tracks have unique backgrounds
- [ ] Audio: race BGM plays during races (loops seamlessly)
- [ ] Save/Load roundtrip: save after completing Bounty #1, reload, bounty marked complete + medal awarded
- [ ] Sprint 11 close report written (`production/sprints/sprint-11-close.md`)

## Sprint Risks (summary)

The 20 Must-Have stories total **~17 days** of work, with capacity **16.8 days**. **Buffer: 0.2 days.** **Extremely tight.** Sprint is at significant risk of slippage.

The biggest risks are:
1. **6 bounty bosses** — 6 unique enemies with special mechanics. If each takes 1.5 days (as listed), 6×1.5 = 9 days alone, which is 50% of the sprint. The **shared boss template** mitigation reduces this to ~4 days.
2. **Race animation (S11-017)** is 2 days. Art-heavy. Can slip easily.
3. **S11-001 (BountyBoard UI) + S11-014 (Betting counter UI)** are 2 days each, complex. If either slips, the sprint is in trouble.

If the sprint slips by 1+ day, cut Should-Haves aggressively (S11-021/22/23/24 are the buffer). If S11-007 (Bounty #2, plot-required) slips, the game is broken past Sat-2 — do not cut this one.

## Carryover from Sprint 10

- **4 endings complete** — the game is feature-complete; Sprint 11 adds side content
- **Save format** — Sprint 7's save format must accommodate bounty state, race counter, and special tool inventory
- **Party system** — bounty fights use the full party (3 pilots + 4 mechs after 苍穹号 inheritance)
- **Truth system** — bounty state does NOT affect truth collection; bounties are separate from main story

## My Recommendation: How to Start This Sprint

1. **Day 1**: Resolve OQ5 (recommended levels), OQ9 (Locator integration with Sprint 10's S10-013).
2. **Day 1-2**: S11-001 + S11-002 (BountyBoard UI + acceptance flow) — together they form the "bounty entry point."
3. **Day 2-3**: S11-004 (Pre-fight setup screen) — the most complex UI in this sprint.
4. **Day 3**: S11-003 (Bounty medal) + S11-005 (Fool's Bounty) — quick wins.
5. **Day 4-5**: **Build the shared boss template** (1 day) — this is the **mitigation** for the 6-bounty-boss risk. After the template is done, each bounty is mostly data + small ability scripts.
6. **Day 5-9**: S11-006..S11-011 (6 bounty bosses) — using the shared template, each is 0.5-1 day.
7. **Day 9-10**: S11-007 (Bounty #2, plot) — the most critical. **Don't skip this.**
8. **Day 10-11**: S11-012 (5 Special Tools) — needed for True Ending A.
9. **Day 11-13**: S11-013 + S11-014 (Racing Arena + Betting counter UI).
10. **Day 13-16**: S11-015 + S11-016 + S11-017 + S11-018 (racing assets + animation + formula).
11. **Day 16-17**: S11-019 (NPC bettors) — quick.
12. **Day 17-19**: S11-020 (tests) + F5 walkthrough (4 bounty + 1 race minimum) + sprint close report.

## Verdict

**Ready to start** — pending OQ5 (recommended levels) and OQ9 (Locator integration) resolution.

- 20 Must-Have stories clearly defined
- 4 Should-Have stories as buffer
- 3 Nice-to-Have stories that are likely cut
- All ACs are testable
- 0.2 day buffer — **sprint is at significant risk of slippage**
- The shared boss template mitigation is critical for the 6-bounty-boss risk
- Bounty #2 (plot) is non-negotiable — do not cut

**This sprint is the most "execution-heavy" sprint** — most of the work is implementation, not design. The user should expect:
- 18-20 hour weeks for 3 weeks
- Significant risk of slippage; ready to extend to 4 weeks
- Some Should-Haves cut
- After this sprint, the game is **fully complete** — all main story + all side content + all 4 endings + all 6 bounties + all 6 racing tracks

The next step after Sprint 11 is **post-launch** (Steam / itch.io / trailer / marketing), which is 2 weeks and not implementation-heavy.
