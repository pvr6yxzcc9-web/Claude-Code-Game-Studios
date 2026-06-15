# Sprint 9 — Sat-4 断魂号 Content

## Sprint Goal

Implement the second new content satellite — **Sat-4 断魂号** (the war-zone military satellite) — with 3 new chapters (Ch10-Ch12), 6 enemy types (3 AI mechs + 3 human survivor types), 1 boss (冥王残响), 4 NPCs, 7 truth fragments, 1 BGM, and the **AI enemy mechanic** (3 of the 6 enemies are AI mechs that have additional combat abilities). This sprint also fully realizes **Bomber's recruitment** (the 3rd party member, joining mid-Ch10) and includes the holo-recording of Bomber's father. After this sprint, the party is 3 pilots (Ranger + Frostbite + Bomber) and the player has access to 3 mechs (Ranger / Frostbite / Bomber — 苍穹号 is still Sprint 10).

## Milestone Context

- **Current Milestone**: Production (started 2026-06-13)
- **Sprint 8 Status**: Should be complete or near-complete (Sat-3 蜂巢号 content)
- **Sprint 9 Deadline**: 2026-08-17 (3 weeks from Sprint 8 close)
- **Roadmap Position**: Third sprint in the **post-GDD implementation phase** — see `production/roadmap-2026-q3.md`

## Why This Sprint, Not Sprint 10

Following the **content-first** strategy (see Sprint 8 doc for rationale):
- Sat-4 introduces the **AI enemy mechanic** (not in Sat-1/2/3) — a different kind of "new mechanic" from Sat-3's hallucination
- The team has now done Sat-3 once, so the workflow is established (Sprint 8 was the "first new satellite" practice)
- Sat-4 is the **third act** of the 5-satellite story — milestone-wise, the player is now close to the climax
- Sprint 10 (Sat-5 + 4 endings) is the **climax** — Sprint 9 sets it up by completing Truth 4

## Capacity

- **Total days**: 21 (3 weeks × 7 days)
- **Buffer (20%)**: 4.2 days
- **Available**: 16.8 days
- **Estimated total work**: 16 days (within capacity)
- **Buffer**: 0.8 days. **Tight sprint.** If any L story slips by 1+ day, the sprint slips.

## Sprint Scope (one-liner per story)

The 14 stories below are organized into **5 critical-path waves**.

- **Wave 1 (Days 1-4): Art pipeline + tile + title + BGM**
  - S9-001 Sat-4 tile assets (4 tiles) (S)
  - S9-002 Sat-4 title background (S)
  - S9-009 Asset generation script (Python) (S)
  - S9-012 1 BGM (S)

- **Wave 2 (Days 5-9): Enemies + Boss**
  - S9-003 6 enemy types (3 AI + 3 human) (M)
  - S9-004 6 enemy sprite PNGs (S)
  - S9-005 1 boss: 冥王残响 (M)
  - S9-006 1 boss sprite PNG (S)

- **Wave 3 (Days 10-14): Levels + dialogue + Bomber recruitment**
  - S9-007 10 room data files (L)
  - S9-008 4 NPCs (M)
  - S9-010 4 NPC portrait PNGs (S)
  - S9-011 Bomber recruitment scene rewrite + Mei holo-recording (M)

- **Wave 4 (Days 15-18): Truth fragments + AI enemy mechanic**
  - S9-013 7 Truth 4 fragments (M)
  - S9-014 AI enemy combat mechanic (M)

- **Wave 5 (Days 19-21): Tests + verification**
  - S9-015 Tests fc73-fc78 (S)

---

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|--------------|-------------------|--------|
| S9-001 | Sat-4 tile assets (4 tiles: floor_military, floor_military_damaged, wall_military, wall_military_damaged) | technical-artist (Python synth) | 0.5 | None | 4 PNGs in `assets/tilesets/ch4/`; 32x32 px each; military aesthetic (dark grey + warning red, blast marks, scorch patterns); tiles register in `data/tilesets/ch4.tres`; existing tile-loading code in `level_runtime.gd` accepts new tile_dir = `ch4/` | Not Started |
| S9-002 | Sat-4 title background (title_military.png, 1280×720) | technical-artist (Python synth) | 0.5 | None | 1 PNG in `assets/sprites/title/title_ch4.png`; 1280×720; dark grey + warning red palette; war-zone visual (broken walls, military insignia, smoke); follows S6-016 title art conventions | Not Started |
| S9-003 | 6 enemy types (3 AI: 冥王残兵, 叛变哨兵, 失控无人机; 3 human: 战损机甲, 残骸机器人, 自毁程序) | systems-designer | 1.0 | None | 6 .tres files in `data/enemies/ch4_*.tres`; 3 AI mechs have additional `ai_abilities` field (e.g., `disable_player_ability_1_turn`, `force_recalculate_aim`); 3 human survivor types have standard stats; all 6 have weaknesses (e.g., AI mechs weak to EMP ×2, human mechs weak to fire ×2); ids are unique; loadable via `ResourceRegistry.get_resource(id)` | Not Started |
| S9-004 | 6 enemy sprite PNGs (32x32 px each) | technical-artist (Python synth) | 0.5 | S9-003 | 6 PNGs in `assets/sprites/enemies/ch4_*.png`; 32×32; visual variety: 3 AI mechs are angular/mechanical (red glow), 3 human survivors are bulkier/worn (grey, broken); matches the S6-006 sprite conventions | Not Started |
| S9-005 | 1 boss: 冥王残响 (Pluto Remnant) | systems-designer | 1.5 | S9-003 | 1 .tres in `data/enemies/boss_pluto_remnant.tres`; id=boss_pluto_remnant, display_name=冥王残响, max_hp=2800, attack=40, accuracy=0.88, boss=true, element=tech, drops=军用干扰器 (from Bounty #4) AND a unique weapon: 冥王残刃, weakness=EMP (×2), special_abilities: `disable_player_ability_per_turn` (random, 1 per turn); regenerates 3% HP per turn (less than Sat-3 boss); boss appears in Sat-4 Room 9 (Ch12 boss arena); 2800 HP is slightly higher than Sat-3 boss (2400) to reflect "stronger story enemy" | Not Started |
| S9-006 | 1 boss sprite PNG (冥王残响.png, 64×64) | technical-artist (Python synth) | 0.5 | S9-005 | 1 PNG in `assets/sprites/enemies/boss_pluto_remnant.png`; 64×64; visually imposing (large AI mech, red glowing eye, fragmented appearance — "remnant" feel); follows S6-007 boss conventions | Not Started |
| S9-007 | 10 room data files (Ch10: 3 rooms, Ch11: 3 rooms, Ch12: 3 rooms + 1 boss arena) | level-designer | 3.0 | S9-001, S9-003, S9-005 | 10 .tres files in `data/levels/chapters/chapter4.tres`; each room has room_id/name/description/tile_set/enemy_encounters/npcs/terminals/exits; **Ch10 Room 5 is Bomber's recruitment room** (existing Sprint 1 scene rewritten in S9-011); **Ch12 Room 8 has Mei's holo-recording** (S9-011); layout: war-zone themed (open arenas, blast damage, military corridors); boss arena is Ch12 Room 9 | Not Started |
| S9-008 | 4 NPCs (老兵, AI 残骸修复师, 冥王碎片, 战时遗孤) | narrative-director + writer | 1.5 | None (parallel to S9-007) | 4 .tres in `data/npcs/ch4_*.tres`; 老兵 in Ch10 Room 2, AI 残骸修复师 in Ch11 Room 1, 冥王碎片 in Ch11 Room 3, 战时遗孤 in Ch12 Room 2; each has 1-2 dialogue lines; 老兵 is a military veteran who fought in the rebellion; AI 残骸修复师 is sympathetic to AIs (foreshadows Truth 4); 冥王碎片 is a fragment of Pluto that survived (foreshadows the AI awakening story) | Not Started |
| S9-009 | Asset generation script (Python) for all Sat-4 assets | tools-programmer | 0.5 | None | 1 Python file in `tools/gen_ch4_assets.py`; generates all 4 tiles + 6 enemy sprites + 1 boss sprite + 1 title background + 1 BGM (S9-012); follows the pattern of `tools/gen_ch3_assets.py` (added in Sprint 8); runs from CLI; deterministic seeds | Not Started |
| S9-010 | 4 NPC portrait PNGs (64×64 each) | technical-artist (Python synth) | 0.5 | S9-008 | 4 PNGs in `assets/sprites/npcs/ch4_*.png`; 64×64; visual variety; 老兵 has military uniform, AI 残骸修复师 has technical clothing, 冥王碎片 is more abstract (red glow), 战时遗孤 is a child | Not Started |
| S9-011 | Bomber recruitment scene rewrite + Mei Zhang holo-recording | godot-gdscript-specialist + writer | 1.5 | S9-007, S9-008 | (a) Rewrite Bomber's recruitment scene in Ch10 Room 5: 3-beat cutscene matches the party-system.md §3.3 spec; Bomber (45-year-old woman) climbs out of cockpit pointing gun at the player; player answers 1 of 3 questions (designed choices: "We're not here to recover Pluto" / "We came for the truth" / "Stand down, we're allies"); answer 1 or 2 = Bomber accepts; answer 3 = Bomber fights for 1 round, then accepts (test of strength); (b) Mei Zhang's holo-recording plays in Ch12 Room 8: 30-second holo-recording of Bomber's father explaining his choice to die with Pluto; Bomber's reaction dialogue (1 line) follows the recording; recording is found via E prompt in the room | Not Started |
| S9-012 | 1 BGM (残骸回响 / Wreckage Echo, 30s loop) | audio-director (Python synth) | 0.5 | None | 1 .wav in `assets/audio/music/wreckage_echo.wav`; 30s loop; military march aesthetic (drums, brass-like synth, but distorted/hollow); matches dark grey + warning red visual; plays during Sat-4 exploration; same volume/length as existing BGM tracks | Not Started |
| S9-013 | 7 Truth 4 fragments (7 .tres files) | writer + systems-designer | 1.5 | None (parallel to S9-008) | 7 .tres files in `data/fragments/fragment_ch4_*.tres`; each has id/title/body/author/date_in_world/unlock_fragment_id/importance per existing fragment schema; 7 fragments collectively tell Truth 4 ("AI Awakening") per `multi-satellite-arc.md` §4.4; at least 2 fragments have importance=2; fragments are scattered: 4 via terminal logs, 2 via NPC dialogue, 1 via Mei's holo-recording (S9-011) | Not Started |
| S9-014 | AI enemy combat mechanic (3 AI mechs have special abilities) | gameplay-programmer + ai-programmer | 1.5 | S9-003 | AI mechs (3 enemies: 冥王残兵, 叛变哨兵, 失控无人机) have additional combat abilities triggered by their `ai_abilities` field; example: 叛变哨兵 has `disable_player_ability_1_turn` (random target, 1 per turn, locks the player's Q/W/E/R/T/Y for 1 turn); 冥王残兵 has `force_recalculate_aim` (reroll all player attacks this turn, taking the lower damage); 失控无人机 has `summon_scrap_drone` (every 3 turns, summon 1 weak ally); abilities are documented in enemy .tres; visual cue when triggered (e.g., 叛变哨兵 glows red when disabling) | Not Started |
| S9-015 | Tests fc73-fc78 — Sat-4 content, AI mechanic, Bomber recruit | qa-tester | 0.5 | All S9-001..S9-014 | 6 new integration test files created; 546 existing tests still pass (532 Sprint 6 + 8 Sprint 7 + 6 Sprint 8); all 6 new tests pass; tests cover: room traversal Ch10-12, all 6 enemies loadable, AI abilities trigger correctly, boss fight, Bomber's recruitment (each of 3 question answers), Mei's holo-recording triggers | Not Started |

**Subtotal**: 15 stories, ~14.5 days estimated. **Within capacity** (16.8 days). 2.3 days buffer.

### Should Have (cut if time-pressed)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|--------------|-------------------|--------|
| S9-016 | Boss phase 2 (at 50% HP) — Pluto awakens further | systems-designer | 1.0 | S9-005 | At 50% HP, 冥王残响 enters phase 2: +25% attack, +15% armor, summons 1 weak AI ally per turn (vs the phase 1 "no summoning"); visual: boss's eye glows brighter red, fragments reassemble around the cockpit; adds a new ability `disable_2_player_abilities_1_turn` (locks 2 player abilities for 1 turn) | Not Started |
| S9-017 | AI ally recruit (1 friendly AI joins in Ch11) | godot-gdscript-specialist + writer | 1.5 | S9-003, S9-014 | In Ch11 Room 3, 冥王碎片 (an AI fragment) can be **recruited** as a temporary ally for 3 fights (Ch11 final boss + Ch12 mid-boss + Ch12 boss); not a permanent party member; ally auto-fights alongside the party; loses HP separately; if ally dies, no penalty; player can decline to recruit (ally stays passive); this is a **nice flavor** that gives the "AI awakening" theme weight | Not Started |
| S9-018 | Military environment SFX (gunfire echoes, distant explosions) | audio-director | 0.5 | None | 2-3 ambient SFX (distant gunfire, low explosions, radio chatter); play in Sat-4 rooms; loop seamlessly; ~30s each; volume lower than BGM; matches war-zone aesthetic | Not Started |
| S9-019 | Mei Zhang's full backstory (terminal logs in Ch11-Ch12) | writer | 1.0 | S9-013 | In addition to the 7 Truth 4 fragments, 3 additional "lore" terminal logs tell Mei Zhang's personal story: his early career, his relationship with Bomber, his internal conflict about creating Pluto; these are NOT truth fragments (don't count toward ending) but provide emotional depth | Not Started |

### Nice to Have (Cut First)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|-----------|-------------------|--------|
| S9-020 | Hidden room in Ch11 (1 secret room with rare weapon) | level-designer | 0.5 | S9-007 | Ch11 has 1 hidden room accessible via a destroyed wall (player must use 1 weapon to break it); hidden room contains 1 rare weapon + 1 bonus fragment; tutorial hint shows how to break walls (already implemented from S6-028) | Not Started |
| S9-021 | Bomber-specific dialogue in existing Ch1-3 NPCs (when revisited with party) | writer | 1.0 | None | If the player has Bomber in the party and revisits Ch1-3, existing NPCs (Vera, Marlow, courier) have 1-2 extra dialogue lines that mention Bomber; gives the "post-recruitment" world some life | Not Started |
| S9-022 | "War memorial" wall in Ch10 (1 special room with 47 names of dead soldiers) | level-designer + writer | 0.5 | S9-007 | Ch10 has 1 special room with a wall listing the 47 soldiers who died in the rebellion; the player can press E to read 3-4 names (each with a 1-line biography); purely flavor, no gameplay effect; adds gravitas to the war-zone theme | Not Started |

## Risks to This Sprint

| Risk | Probability | Impact | Mitigation | Owner |
|------|------------|--------|-----------|-------|
| AI enemy mechanic (S9-014) is too punishing — players lose abilities too often | Medium | High | Limit `disable_player_ability` to **once per 3 turns** per AI mech (not every turn); visual cue when player is disabled (UI shows "DISABLED!" for 1 turn); playtest with 2-3 users | gameplay-programmer |
| Bomber's recruitment scene rewrite (S9-011) breaks existing saves that have already recruited Bomber | Low | High | The rewrite is **only** a dialogue + cutscene change; does not change `party.add_pilot("bomber")` logic; existing saves should work fine; verify with S9-015 tests | godot-gdscript-specialist |
| Mei's holo-recording is too emotional for Sprint 9's "war-zone" tone | Low | Low | Keep it brief (30s); let the player replay it from the pause menu if they want; don't make it the emotional peak of the game (that's Sat-5) | writer |
| Sat-4 has 6 enemies and 3 AI mechs, but only 3 enemies are "interesting" (the AI mechs) — the human survivors are bland | Medium | Medium | Make the 3 human survivor enemies have **distinct visual + tactical profiles** (e.g., 战损机甲 is a slow tank, 残骸机器人 is a fast scout, 自毁程序 kamikazes); don't make them "just melee bots" | systems-designer |
| BGM "残骸回响" sounds too similar to existing military-style BGM (if any) | Low | Low | Use a different frequency range (mid-frequency for military) + different rhythm (march for military); currently no military BGM exists, so this is moot | audio-director |
| 7 Truth 4 fragments feel "redundant" with Sat-3's 7 Truth 3 fragments | Low | Medium | Use a different **medium** for Truth 4 (e.g., 4 are military briefings, 2 are personal logs, 1 is a recording); vary the writing style (terse, military, less poetic) | writer |
| AI ally recruit (S9-017) complicates the party system (Sprint 7's party logic doesn't support temporary allies) | High | High | If implementing, use a **simple "is_ally" flag** on a mech, with simple HP/attack; do not integrate with the full pilot-mech swap system; if Sprint 7 didn't anticipate this, defer S9-017 to a later sprint | godot-gdscript-specialist |
| 15 stories in 16.8 days is tight — sprint slips if S9-007 (rooms) or S9-014 (AI mechanic) take longer | High | High | Cut Should-Haves aggressively (S9-016/17/18/19 are the buffer); if S9-014 slips, fall back to a simpler AI ability (`disable_1_ability_1_turn` only) | user decision |
| Save/load: Bomber's recruitment state from Sprint 7's save format must be tested | Medium | Medium | S9-015 tests must include "save before recruitment, save after recruitment, reload both" cases | qa-tester |

## Open Questions (need user input before or during sprint)

- **OQ1**: How many hours/week will the user commit to Sprint 9? (3 weeks of 16.8 days = ~5.6 days/week = ~45 hours/week.) Same as Sprint 7 and 8 question.
- **OQ2**: The **AI enemy mechanic (S9-014)** has 3 different AI abilities. Should they all be implemented in Sprint 9, or is 1-2 enough? Currently planned: all 3. If tight on time, 1 (`disable_player_ability`) is the most iconic.
- **OQ3**: The **AI ally recruit (S9-017)** is currently a Should-Have. Should it be **in Sprint 9** (for Sat-4's "AI awakening" theme) or **deferred to a later sprint** (since it requires party system extensions)? Currently: defer to Sprint 11+ (party system extension is risky).
- **OQ4**: **Bomber's recruitment (S9-011)** — the player answers 1 of 3 questions. Should the **wrong answer (answer 3)** trigger a 1-round combat (test of strength) or just a "she's skeptical for 1 turn"? Currently planned: 1-round combat. If the user prefers non-violent (no combat on recruitment), change to "skeptical for 1 turn" (no damage, just dialogue continues).
- **OQ5**: The **boss 冥王残响's drop "冥王残刃"** — should this be a **weapon usable by all pilots**, or **pilot-specific** (only Bomber can use it effectively)? Currently planned: usable by all, but Bomber gets +20% damage bonus. This rewards putting Bomber in combat but doesn't lock out other pilots.
- **OQ6**: The **Mei Zhang holo-recording** is currently 30 seconds. Should it be **longer (60-90s)** for more emotional impact, or **shorter (15-20s)** to keep pacing? Currently planned: 30s. If the user wants more weight, expand to 60s.
- **OQ7**: The **"war memorial" wall (S9-022)** is Nice-to-Have. Should it be in scope (for Sprint 9) or deferred? Currently: defer (Sprint 9 is tight on capacity).
- **OQ8**: Should **Bomber's pilot ability** (currently: `Iron Wall` taunt) be tested in Sprint 9 (by the AI recruit / boss fight) or deferred to a balance pass? Currently planned: tested in S9-015.

## Definition of Done

- [ ] All 15 Must-Have tasks completed (S9-001 to S9-015)
- [ ] All tasks pass acceptance criteria
- [ ] 546 existing tests still pass (no regressions)
- [ ] 6 new tests (fc73-fc78) all pass
- [ ] F5 walkthrough Sat-4: enter Sat-4 from Sat-3, traverse Ch10-12, recruit Bomber (each of 3 question answers), fight boss, collect all 7 Truth 4 fragments
- [ ] F5 walkthrough: AI enemy mechanic — fight 叛变哨兵, observe ability disable, then continue combat
- [ ] F5 walkthrough: Mei's holo-recording — enter Ch12 Room 8, press E, recording plays, Bomber's reaction dialogue follows
- [ ] Visual: 4 Sat-4 tiles render correctly; 6 enemy sprites are distinguishable; boss sprite is imposing
- [ ] Audio: BGM plays in a loop; ambient SFX (if implemented) plays at low volume
- [ ] Save/Load roundtrip: save after Bomber's recruitment, reload, party is 3 pilots
- [ ] Sprint 9 close report written (`production/sprints/sprint-09-close.md`)

## Sprint Risks (summary)

The 15 Must-Have stories total **14.5 days** of work, with capacity **16.8 days**. **Buffer: 2.3 days** (healthy but not huge).

The biggest risk is **S9-014 (AI enemy mechanic)** — it's the only "new mechanic" in this sprint (Sat-3 had hallucination, Sat-4 has AI). If it doesn't work, the AI enemies feel like "regular enemies with extra text." Mitigation: spike the mechanic first (0.5 day), test it, then add to all 3 AI mechs.

The second biggest risk is **S9-007 (10 rooms)** — same as Sat-3. Mitigation: design room connections first, then fill in details.

If the sprint slips by 1+ day, cut Should-Haves aggressively (S9-016 boss phase 2, S9-019 Mei's full backstory, S9-018 ambient SFX).

## Carryover from Sprint 8

- **Sat-3 (蜂巢号) workflow** — Sat-4 follows the same pattern (Wave 1: art, Wave 2: enemies, Wave 3: rooms + NPCs, Wave 4: truth + mechanic, Wave 5: tests). Reusing the structure reduces decision fatigue.
- **Asset generation script pattern** — `tools/gen_ch3_assets.py` from Sprint 8 is the template for `tools/gen_ch4_assets.py` (S9-009).
- **Hallucination mechanic** — Sprint 8's hallucination mechanic is **not used in Sat-4**; each satellite has its own theme. AI enemy mechanic (S9-014) is the new mechanic.
- **Party system from Sprint 7** — Sat-4 is the first sprint where the **3-pilot party is fully active** (Ranger + Frostbite + Bomber). Sprint 8 had 2 pilots only.

## My Recommendation: How to Start This Sprint

1. **Day 1**: Resolve OQ2 (AI ability scope) and OQ4 (Bomber's wrong answer behavior).
2. **Day 1-2**: S9-009 (asset script) + S9-001 (tiles) + S9-002 (title) + S9-012 (BGM) — pure asset work, can be done in parallel.
3. **Day 2-3**: S9-003 + S9-004 (6 enemies + sprites) — generate via S9-009 script.
4. **Day 3-4**: S9-005 + S9-006 (boss + boss sprite).
5. **Day 4-5**: S9-014 (AI mechanic) — **spike first** (0.5 day), then implement.
6. **Day 5-8**: S9-007 (10 rooms) — level design. The bottleneck.
7. **Day 5-8 (parallel)**: S9-008 + S9-010 + S9-013 (NPCs + portraits + truth fragments) — content writing.
8. **Day 8-10**: S9-011 (Bomber recruitment rewrite + Mei holo-recording) — important cutscene.
9. **Day 10-12**: Integration, F5 walkthrough, bug fixes.
10. **Day 12-14**: S9-015 (tests) + F5 verification + sprint close report.

## Verdict

**Ready to start** — pending OQ2 (AI scope) and OQ4 (Bomber's wrong answer) resolution.

- 15 Must-Have stories clearly defined
- 4 Should-Have stories as buffer
- 3 Nice-to-Have stories that are likely cut
- All ACs are testable
- 2.3 days buffer — adequate sprint
- The AI enemy mechanic is the only "new mechanic" — manageable
- Bomber's recruitment is the only major cutscene — manageable
- The "war-zone" theme is a nice change of pace from "alien hive" (Sat-3)

**This sprint is well-scoped.** The user should expect:
- 16-18 hour weeks for 3 weeks
- Some Should-Haves cut (likely the Mei full backstory + ambient SFX)
- A polished, fully playable Sat-4 at the end
- The 3-pilot party (Ranger + Frostbite + Bomber) fully operational
- 4 of 5 truths collected, with Truth 5 (Creator) still in Sat-5
