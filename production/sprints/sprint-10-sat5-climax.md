# Sprint 10 — Sat-5 起源号 + 4 Endings (CLIMAX)

## Sprint Goal

Implement the **climax** of the game — **Sat-5 起源号** (the Creator's origin satellite) — with 3 new chapters (Ch13-Ch15), 7 truth fragments (Truth 5: "The Creator Sleeps"), the 苍穹号 inheritance scene (Ch13 end), the **Creator encounter in Ch15** (a 5-phase boss fight that mirrors the previous 4 satellites' boss patterns + an original 5th phase), and the **4 endings rewrite** (A Merciful / B Cycle / C Fusion / D Hidden) with full post-credit scenes. After this sprint, the game is **feature-complete** — the player can play through all 15 chapters, fight the final boss, and reach all 4 endings. This is the **most critical sprint in the project**.

## Milestone Context

- **Current Milestone**: Production (started 2026-06-13)
- **Sprint 9 Status**: Should be complete or near-complete (Sat-4 断魂号 content)
- **Sprint 10 Deadline**: 2026-09-14 (4 weeks from Sprint 9 close)
- **Roadmap Position**: Fourth sprint in the **post-GDD implementation phase** — see `production/roadmap-2026-q3.md`

## Why 4 Weeks (Not 3)

Sprint 10 is the **most content-heavy** sprint:
- 3 new chapters (Ch13-Ch15) with 10 rooms
- 7 truth fragments
- 1 final boss (the Creator) with 5 phases
- 苍穹号 inheritance scene
- 4 distinct ending scenes (each with unique post-credit scene)
- EndingController rewrite (4 endings → 4 endings, but with full narrative weight)
- 苍穹号's 4 unique weapons

**3 weeks would not be enough.** The 4-week sprint is the longest in the project.

## Capacity

- **Total days**: 28 (4 weeks × 7 days)
- **Buffer (20%)**: 5.6 days
- **Available**: 22.4 days
- **Estimated total work**: 20.5 days (within capacity)
- **Buffer**: 1.9 days. **Tight sprint but achievable.** If any L story slips by 2+ days, the sprint slips.

## Sprint Scope (one-liner per story)

The 16 stories below are organized into **6 critical-path waves**.

- **Wave 1 (Days 1-5): Art pipeline + tile + title + BGM**
  - S10-001 Sat-5 tile assets (4 tiles) (S)
  - S10-002 Sat-5 title background (S)
  - S10-003 苍穹号 4 weapons (M)
  - S10-010 Asset generation script (Python) (S)
  - S10-011 1 BGM (造物者之梦) (S)

- **Wave 2 (Days 6-10): Boss + NPCs + fragments**
  - S10-004 1 final boss: 造物者本体 (5 phases) (L)
  - S10-005 1 boss sprite (M, but the 5-phase visuals need extra work)
  - S10-006 4 NPCs (3 returning + 1 new) (M)
  - S10-007 4 NPC portrait PNGs (S)
  - S10-008 7 Truth 5 fragments (M)

- **Wave 3 (Days 11-16): Levels + 苍穹号 inheritance + Creator chamber**
  - S10-009 10 room data files (Ch13-15) (L)
  - S10-012 苍穹号 inheritance scene (Ch13, Room 9) (M)
  - S10-013 Creator chamber (Ch15) — non-combat dialogue + 5-phase boss arena (L)

- **Wave 4 (Days 17-22): 4 endings + EndingController rewrite**
  - S10-014 Ending A scene: "仁慈的终结" (10 years later) (M)
  - S10-015 Ending B scene: "循环延续" (1,000 years later) (M)
  - S10-016 Ending C scene: "融合" (50 years later) (M)
  - S10-017 Ending D scene: "隐藏之路" (1 year later) (M)
  - S10-018 EndingController rewrite (4 endings, 4 post-credit scenes, save stamps) (L)

- **Wave 5 (Days 23-26): Tests + verification**
  - S10-019 Tests fc79-fc84 (M)

---

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|--------------|-------------------|--------|
| S10-001 | Sat-5 tile assets (4 tiles: floor_ancient, floor_ancient_glowing, wall_ancient, wall_ancient_glowing) | technical-artist (Python synth) | 0.5 | None | 4 PNGs in `assets/tilesets/ch5/`; 32×32 each; ancient aesthetic (gold + deep purple, alien geometric patterns, glowing runes); tiles register in `data/tilesets/ch5.tres`; existing tile-loading code accepts new tile_dir = `ch5/` | Not Started |
| S10-002 | Sat-5 title background (title_creator.png, 1280×720) | technical-artist (Python synth) | 0.5 | None | 1 PNG in `assets/sprites/title/title_ch5.png`; 1280×720; gold + deep purple palette; the Creator's chamber visual (vast alien space, geometric patterns, golden glow); follows S6-016 title art conventions | Not Started |
| S10-003 | 苍穹号's 4 unique weapons (苍穹炮, 光刃, 信号干扰器, 造物者信号接收器) | systems-designer + technical-artist | 1.5 | None | 4 .tres files in `data/weapons/cangqiong_*.tres`; each has id/display_name/min_damage/max_damage/crit_chance/crit_multiplier/element/special_ability; stats per party-system.md §3.6; sprites 32×32 each; weapons can be equipped to 苍穹号 (or any mech, but with reduced effect on non-苍穹号 mechs); weapons have unique visual effects (e.g., 苍穹炮 has a long-range laser, 光刃 has a glowing blade) | Not Started |
| S10-004 | 1 final boss: 造物者本体 (the Creator, 5 phases) | systems-designer + lead-programmer | 3.0 | None (parallel to S10-003) | 1 .tres in `data/enemies/boss_creator.tres`; id=boss_creator, display_name=造物者本体, max_hp=5000, attack=50, accuracy=0.90, boss=true, element=creator; **5 phases**, each at 100% / 75% / 50% / 25% / 10% HP thresholds: Phase 1 (Signal Wave) — uses signal-themed attacks (like Sat-1 boss); Phase 2 (Frozen Genome) — uses ice attacks (like Sat-2 boss); Phase 3 (Hive Mind) — summons 2-3 weak hive creatures (like Sat-3 boss); Phase 4 (AI Awakening) — disables 1 player ability/turn (like Sat-4 boss); Phase 5 (Creator) — original phase, all attacks + 1 new attack (`Creator's Voice` — AOE that inflicts "doubt" status, -10% accuracy for 3 turns); the boss appears in Ch15 Room 9 (Creator's chamber); drops: nothing (the fight is story-finale, not loot) | Not Started |
| S10-005 | 1 boss sprite PNG (造物者.png, 96×96, larger than other bosses) | technical-artist (Python synth) | 1.0 | S10-004 | 1 PNG in `assets/sprites/enemies/boss_creator.png`; **96×96** (vs 64×64 for other bosses — the Creator is "larger than life"); visual: alien cosmic organism, golden glow, abstract geometric forms; 5 phase variations are sprite swaps (or color tints) — e.g., Phase 1 has signal-blue glow, Phase 2 has ice-white glow, etc. | Not Started |
| S10-006 | 4 NPCs (3 returning + 1 new) | writer | 1.0 | None (parallel to S10-004) | 4 NPCs: **苍穹号 (deceased, the legendary pilot)** in Ch13 Room 9 (next to his mech), **漫游者's father (ghost)** in Ch14 Room 1, **Frostbite's mother (merged with frozen fragment)** in Ch14 Room 3, **Bomber's father (ghost)** in Ch14 Room 5; the 3 ghosts are "post-human" entities that can communicate in broken phrases; 苍穹号 is a dead body (with a final letter); each has 2-3 dialogue lines that hint at Truth 5 | Not Started |
| S10-007 | 4 NPC portrait PNGs (64×64 each) | technical-artist (Python synth) | 0.5 | S10-006 | 4 PNGs in `assets/sprites/npcs/ch5_*.png`; 64×64; 苍穹号 is a weathered old mech pilot (deceased), the 3 ghosts have partial-translucent effects | Not Started |
| S10-008 | 7 Truth 5 fragments | writer | 1.5 | None (parallel to S10-004) | 7 .tres files in `data/fragments/fragment_ch5_*.tres`; collectively tell Truth 5 ("The Creator Sleeps") per `multi-satellite-arc.md` §4.5; at least 3 fragments have importance=2 (significant for ending logic); fragments are scattered: 2 via terminal logs, 2 via NPC dialogue, 1 via 苍穹号's letter, 2 via environmental storytelling (e.g., a wall mural that the player can examine) | Not Started |
| S10-009 | 10 room data files (Ch13: 3 rooms, Ch14: 3 rooms, Ch15: 3 rooms + 1 boss arena) | level-designer | 2.5 | S10-001, S10-006 | 10 .tres files in `data/levels/chapters/chapter5.tres`; **Ch13 Room 9** is the 苍穹号 inheritance room (S10-012); **Ch15 Room 9** is the Creator's chamber (S10-013); layout: ancient alien architecture, vast open spaces (vs cramped Sat-1/2/3/4), non-Euclidean in places; boss arena is Ch15 Room 9 | Not Started |
| S10-010 | Asset generation script (Python) for all Sat-5 assets | tools-programmer | 0.5 | None | 1 Python file in `tools/gen_ch5_assets.py`; generates all 4 tiles + 4 苍穹号 weapons + 1 boss sprite + 1 title background + 1 BGM; follows the pattern of `tools/gen_ch4_assets.py`; deterministic seeds | Not Started |
| S10-011 | 1 BGM (造物者之梦 / Creator's Dream, 60s loop) | audio-director (Python synth) | 0.5 | None | 1 .wav in `assets/audio/music/creators_dream.wav`; **60s loop** (vs 30s for other BGMs — this is the climactic BGM, should feel more "epic"); cosmic ambient aesthetic (low frequency hum, occasional "voice"-like synth, vast reverb); plays during Sat-5 exploration | Not Started |
| S10-012 | 苍穹号 inheritance scene (Ch13, Room 9) | godot-gdscript-specialist + writer | 1.5 | S10-006, S10-009 | 7-beat cutscene per party-system.md §3.3: (1) party finds 苍穹号's destroyed cockpit; (2) 苍穹号's body is visible, with a final letter; (3) letter is read (text overlay); (4) party mourns briefly (no dialogue, just visual — 1-2 seconds of silence); (5) 苍穹号 mech power-on sequence (golden glow); (6) mech bonds to 漫游者 (via Creator Receiver code); (7) party receives 苍穹号, exit scene with 4 mechs in party; total scene length: 30-60 seconds | Not Started |
| S10-013 | Creator chamber (Ch15, Room 9) — dialogue + 5-phase boss arena | godot-gdscript-specialist + writer | 2.5 | S10-004, S10-008, S10-009 | The Creator chamber is Ch15's final room; **non-combat dialogue phase** (1-2 minutes): player enters the chamber; the Creator is visible (vast, silent, golden); using 苍穹号 + 造物者定位器, the player can "speak" to the Creator; dialogue options appear: Transcend (only if all conditions met per multi-satellite-arc.md §5.3), Understand, Destroy, Flee; if player chooses Transcend or Understand → no combat, ending plays; if player chooses Destroy → **5-phase boss fight** with 苍穹号; if player chooses Flee → escape sequence (D ending); the chamber's visual is "non-Euclidean" — geometry bends, gravity is uncertain; the chamber is the largest single room in the game (5-10× normal room size) | Not Started |
| S10-014 | Ending A scene: "仁慈的终结" (10 years later) | godot-gdscript-specialist + writer | 1.0 | S10-013 | Post-credits scene, 60-90 seconds; set 10 years after the main story; player is shown running a small museum of the 5 satellites, teaching the next generation; includes voiceover-style text overlay (no voice acting); visual: the museum, the player's weathered face, children asking questions; ends with the player looking up at the stars | Not Started |
| S10-015 | Ending B scene: "循环延续" (1,000 years later) | godot-gdscript-specialist + writer | 1.0 | S10-013 | Post-credits scene, 60-90 seconds; set 1,000 years after the main story; player's descendant is on a new world, encountering a **new Creator** that was seeded from the old Creator's fragments; the cycle continues; ends with the descendant looking up at the sky, seeing the new Creator's signal | Not Started |
| S10-016 | Ending C scene: "融合" (50 years later) | godot-gdscript-specialist + writer | 1.0 | S10-013 | Post-credits scene, 60-90 seconds; set 50 years after the main story; **Frostbite** and **Bomber** (the 2 remaining pilots) are shown tending a small shrine on Sat-1 where the player's father used to work; they share a quiet moment; ends with Frostbite saying "He's still out there, isn't he?" | Not Started |
| S10-017 | Ending D scene: "隐藏之路" (1 year later) | godot-gdscript-specialist + writer | 1.0 | S10-013 | Post-credits scene, 60-90 seconds; set 1 year after the main story; the Creator has left the solar system; humanity is left alone, without the Creator's seed-life; the biosphere is collapsing; the party is shown as the only humans who know what happened; ends with a silent shot of the empty Creator's chamber | Not Started |
| S10-018 | EndingController rewrite (4 endings, save stamps, post-credit) | lead-programmer | 2.0 | S10-013, S10-014..S10-017 | `src/autoload/ending_controller.gd` is rewritten to handle 4 endings with full narrative weight; each ending: (1) sets the post-credits scene, (2) plays the ending's audio, (3) plays the post-credit scene, (4) saves a "ending_reached" stamp to the save file; old save files migrate to the new format (the existing 4 endings are remapped to the new 4); the controller is called by the dialogue system when the player chooses an ending in Ch15 | Not Started |
| S10-019 | Tests fc79-fc84 — Sat-5, 4 endings, Creator dialogue, 苍穹号 scene | qa-tester | 0.5 | All S10-001..S10-018 | 6 new integration test files created; 552 existing tests still pass (532 Sprint 6 + 8 Sprint 7 + 6 Sprint 8 + 6 Sprint 9); all 6 new tests pass; tests cover: room traversal Ch13-15, all 7 Truth 5 fragments collectible, 苍穹号 inheritance triggers correctly, Creator chamber dialogue options appear/hide based on conditions, all 4 endings reachable, post-credit scenes play correctly, save stamps work | Not Started |

**Subtotal**: 19 stories, ~21 days estimated. **At capacity** (22.4 days). 1.4 days buffer.

### Should Have (cut if time-pressed)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|--------------|-------------------|--------|
| S10-020 | Boss 5-phase voiceover (text-only, no VO) | writer | 0.5 | S10-004 | Each phase transition plays a 1-2 sentence text overlay explaining the phase's theme (e.g., Phase 3: "The Creator remembers the hive mind."); purely text, no voice acting; adds gravitas | Not Started |
| S10-021 | Ancient ambient SFX (chimes, low hum, distant voice) | audio-director | 0.5 | None | 2-3 ambient SFX for Sat-5; matches the ancient cosmic aesthetic; volume lower than BGM; ~30s each | Not Started |
| S10-022 | "Fool's Bounty" integration (post-credits reward) | systems-designer | 0.5 | None | After completing the game (any ending), the post-credits screen shows a "Fool's Bounty" reward: a unique 1-time buff that gives +25% damage for the next play; players who reach the True Ending (A) get a different reward (e.g., a unique cosmetic mech skin) | Not Started |
| S10-023 | Multiple playthroughs support (NG+ mode) | lead-programmer | 2.0 | S10-018 | After completing the game, the player can start a New Game+ with carry-over: starting mechs from the previous run, +1 starting weapon slot, but enemies are 1.5× tougher; NG+ unlocks the hidden 6th boss (Bounty #6) in the post-game town | Not Started |

### Nice to Have (Cut First)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|-----------|-------------------|--------|
| S10-030 | 5 unique ending credits songs (1 per ending) | audio-director | 2.0 | S10-014..S10-017 | Each ending has its own 30s credits song; matches the ending's tone (e.g., A is hopeful, B is haunting, C is melancholic, D is bleak) | Not Started |
| S10-031 | Hidden post-credits scene (after Ending A) | godot-gdscript-specialist + writer | 1.0 | S10-014 | After Ending A's standard post-credits, a hidden 30-second scene plays: a child asks the player "What was the Creator like?" and the player responds "It was lonely. Like us." Adds a "twist" to the True Ending | Not Started |
| S10-032 | Ending statistics screen ("Your journey: 47 hours, 5 satellites, 4 endings") | lead-programmer | 1.0 | S10-018 | After any ending, a stats screen shows: total playtime, number of fragments collected, ending reached, kill count, deaths, gold earned, etc.; purely flavor | Not Started |

## Risks to This Sprint

| Risk | Probability | Impact | Mitigation | Owner |
|------|------------|--------|-----------|-------|
| Creator 5-phase boss fight is too long (5+ minutes of combat) | High | High | Each phase has a **clear visual cue** (color tint, particle effect) so the player knows when phases change; phase 5 (Creator) is shorter than phases 1-4 (boss has less HP at 10% threshold); total fight time: 3-5 minutes | systems-designer + godot-gdscript-specialist |
| 4 ending scenes are too similar (visual style, pacing) | Medium | Medium | Each ending has a **distinct visual mood**: A is warm/sepia, B is cold/blue, C is golden/translucent, D is monochrome; each has a unique musical cue; each uses different camera angles (close-up, wide shot, etc.) | writer + art-director |
| 苍穹号 inheritance scene is too long (current 30-60s) and breaks pacing | Low | Medium | If too long, cut the "letter reading" beat (3-5 seconds saved); if still too long, cut the "party mourns" beat (1-2 seconds saved); minimum: 7-beat scene is non-negotiable | godot-gdscript-specialist + writer |
| The "造物者定位器" requirement for Ending C confuses players | Medium | Medium | Document the requirement in the Codex (after the player gets the Locator); add a tutorial hint when the Locator is acquired; the dialogue UI in Ch15 shows "Transcend" option only if all conditions are met (clear feedback) | godot-gdscript-specialist |
| Sat-5's "non-Euclidean" geometry is hard to implement in 2D tile-based | High | Medium | Use **tilting screen** (subtle camera rotation in the chamber) + **gravity shift** (player walks on walls briefly); these are 2D-friendly approximations of non-Euclidean; full non-Euclidean 2D is very hard; document as "stylized 2D interpretation" | gameplay-programmer |
| 4 ending scenes (S10-014..S10-017) are 4 separate tasks — risk of one slipping, others must wait | High | High | Build a **shared "ending player"** component (1 day) that handles the post-credit scene playback; then each ending just provides its own scene content (1 day each); if 1 ending slips, the other 3 still work | godot-gdscript-specialist |
| EndingController rewrite (S10-018) breaks existing 4-ending logic | Medium | High | Keep the existing 4 endings as fallbacks (D ending especially — it has a working path); rewrite to add full narrative; test with old saves in S10-019 | lead-programmer |
| Save file format change in EndingController breaks old saves | Medium | Medium | Old saves can replay endings they had not yet reached; saves that already have an ending stamp preserve it | lead-programmer |
| 19 stories in 22.4 days is at capacity — sprint slips if any L story takes longer | High | High | Cut Should-Haves aggressively (S10-020/21/22/23 are the buffer); if S10-013 (Creator chamber) slips, the entire sprint is at risk | user decision |
| The "造物者之梦" BGM is 60s loop — twice as long as other BGMs, more memory | Low | Low | Test audio file size; if too large, use 45s loop with subtle variation; ensure it loops seamlessly | audio-director |
| Boss 96×96 sprite is large for 2D rendering (some devices may have issues) | Low | Low | Test on target hardware; if issues, use 80×80 instead; document sprite size in asset manifest | technical-artist |

## Open Questions (need user input before or during sprint)

- **OQ1**: How many hours/week will the user commit to Sprint 10? (4 weeks of 22.4 days = ~5.6 days/week = ~45 hours/week.) Same as Sprint 7/8/9 question.
- **OQ2**: The **Creator 5-phase boss fight** — is the 5-phase design correct, or should it be simpler (3 phases)? Currently planned: 5 phases. If too long, reduce to 3.
- **OQ3**: The **4 ending scenes** are 4 separate tasks. Should the user review each ending's tone/writing **before** S10-014 starts (during Sprint 10 planning) or **after** the implementation is done? Recommend: review writing before implementation (saves rework).
- **OQ4**: The **"非欧几里得" Creator chamber** is a big artistic ask. Should the user accept a "stylized 2D interpretation" (subtle camera rotation + gravity shift) or aim for full non-Euclidean (which is very hard in 2D)? Currently planned: stylized 2D interpretation.
- **OQ5**: The **NG+ mode (S10-023)** is currently a Should-Have. Should it be **in Sprint 10** (gives players replay value) or **deferred to post-launch**? Currently planned: in Sprint 10 (Should-Have).
- **OQ6**: The **ending statistics screen (S10-032)** is currently Nice-to-Have. Is the user OK without it? Currently: defer to post-launch.
- **OQ7**: The **"造物者之梦" BGM at 60s** — is the longer length necessary, or is 30s enough? Currently planned: 60s (for epic feel). If too long, drop to 30s.
- **OQ8**: The **"Fool's Bounty" integration (S10-022)** is currently Should-Have. Should it be **in Sprint 10** or **deferred to Sprint 11** (where the bounty system is implemented)? Currently planned: in Sprint 10 (simpler integration).
- **OQ9**: The **4 ending scenes' visual style** (warm/sepia for A, etc.) — is the user OK with this color-coding? Currently planned: yes. If the user wants different moods, change during Sprint 10 writing.
- **OQ10**: Should the **"True Ending" (A)** require the **造物者定位器** (from Bounty #5) or just the **5 truths + 苍穹号**? Currently per multi-satellite-arc.md §5.3, BOTH are required. Confirm this is correct.

## Definition of Done

- [ ] All 19 Must-Have tasks completed (S10-001 to S10-019)
- [ ] All tasks pass acceptance criteria
- [ ] 552 existing tests still pass (no regressions)
- [ ] 6 new tests (fc79-fc84) all pass
- [ ] F5 walkthrough Sat-5: enter Sat-5 from Sat-4, traverse Ch13-15, get 苍穹号, fight Creator (each of 5 phases reachable), reach all 4 endings
- [ ] F5 walkthrough: Ending A — 5 truths + Understand dialogue + post-credit scene
- [ ] F5 walkthrough: Ending B — 3+ truths + Destroy dialogue + 5-phase boss fight + post-credit scene
- [ ] F5 walkthrough: Ending C — 5 truths + Locator + Transcend dialogue + post-credit scene
- [ ] F5 walkthrough: Ending D — flee + escape + post-credit scene
- [ ] Visual: 4 Sat-5 tiles render correctly; 苍穹号's 4 weapons are distinct; Creator boss sprite is 96×96 and visually imposing; 4 ending post-credit scenes have unique visual styles
- [ ] Audio: BGM plays in 60s loop; ambient SFX (if implemented) plays at low volume
- [ ] Save/Load roundtrip: save after reaching each ending, reload, ending stamp preserved
- [ ] Sprint 10 close report written (`production/sprints/sprint-10-close.md`)

## Sprint Risks (summary)

The 19 Must-Have stories total **~21 days** of work, with capacity **22.4 days**. **Buffer: 1.4 days** (very tight).

The biggest risks are:
1. **S10-013 (Creator chamber)** is the climax — 2.5 days, highest risk
2. **S10-018 (EndingController rewrite)** is complex — 2 days, high risk
3. **S10-014..S10-017 (4 ending scenes)** are 4 separate tasks — if 1 slips, the others must still finish

If the sprint slips by 1+ day, cut Should-Haves aggressively (S10-020/21/22/23 are the buffer). The sprint is **at risk of slippage** — be ready to extend to 5 weeks if needed.

## Carryover from Sprint 9

- **Sat-3 + Sat-4 workflow** — Sat-5 follows the same pattern (Wave 1: art, Wave 2: enemies + boss, Wave 3: rooms + NPCs, Wave 4: truth + mechanic, Wave 5: tests). Reusing the structure reduces decision fatigue.
- **3-pilot party** — Sat-5 is the first sprint where the **4-pilot party is fully active** (Ranger / Frostbite / Bomber / 苍穹号). The 苍穹号 inheritance in Ch13 is the trigger.
- **4 of 5 truths collected** — Sat-5's Truth 5 is the **final** truth, completing the picture.
- **Save format** — Sprint 7's party-aware save format must accommodate 4 mechs + 4 pilots + the 苍穹号 inheritance flag.

## My Recommendation: How to Start This Sprint

1. **Day 1**: Resolve OQ2 (5 phases vs 3) and OQ10 (True Ending requirements).
2. **Day 1-2**: S10-010 (asset script) + S10-001 (tiles) + S10-002 (title) + S10-011 (BGM) — pure asset work.
3. **Day 2-3**: S10-003 (苍穹号's 4 weapons).
4. **Day 3-5**: S10-004 + S10-005 (Creator boss + sprite) — the climactic boss.
5. **Day 5-7**: S10-006 + S10-007 + S10-008 (NPCs + portraits + truth fragments) — content writing.
6. **Day 7-10**: S10-009 (10 rooms) — level design.
7. **Day 10-12**: S10-012 (苍穹号 inheritance scene).
8. **Day 12-15**: S10-013 (Creator chamber + dialogue + 5-phase boss arena).
9. **Day 15-19**: S10-014..S10-017 (4 ending scenes) in parallel.
10. **Day 19-22**: S10-018 (EndingController rewrite).
11. **Day 22-26**: S10-019 (tests) + F5 walkthrough (4 endings) + sprint close report.

## Verdict

**Ready to start** — pending OQ2 (5 phases) and OQ10 (True Ending requirements) resolution.

- 19 Must-Have stories clearly defined
- 4 Should-Have stories as buffer
- 3 Nice-to-Have stories that are likely cut
- All ACs are testable
- 1.4 days buffer — very tight, sprint is at risk of slippage
- The 5-phase Creator fight is the climactic moment — high risk, high reward
- The 4 endings are the emotional payoff — high risk, high reward

**This sprint is the climax of the project.** The user should expect:
- 18-20 hour weeks for 4 weeks
- Some Should-Haves cut (likely NG+ mode + ending stats)
- A polished, fully playable Sat-5 at the end
- 4 endings all reachable from a single playthrough
- The game is **feature-complete** after this sprint (Sprint 11 adds bounty + racing, post-launch adds marketing)

If this sprint slips by 1-2 days, extend to 5 weeks. If it slips by more, defer S10-023 (NG+) to post-launch.
