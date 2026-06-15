# Sprint 8 — Sat-3 蜂巢号 Content

## Sprint Goal

Implement the first new content satellite — **Sat-3 蜂巢号** (the alien hive satellite) — with 3 new chapters (Ch7-Ch9), 6 enemy types, 1 boss, 4 NPCs, 7 truth fragments, 1 BGM, and the **hallucination mechanic**. After this sprint, the player can play through Ch7-Ch9 in approximately 2-3 hours, experiencing the alien hive aesthetic, the hallucination visual confusion, the 蜂后守卫 boss fight, and the Truth 3 ("Hive Mind") story arc that ties into the Creator mystery.

## Milestone Context

- **Current Milestone**: Production (started 2026-06-13)
- **Sprint 7 Status**: Should be complete or near-complete (party system implemented)
- **Sprint 8 Deadline**: 2026-07-27 (3 weeks from Sprint 7 close)
- **Roadmap Position**: Second sprint in the **post-GDD implementation phase** — see `production/roadmap-2026-q3.md`

## Why This Sprint, Not Sprint 11 (Bounty + Racing)

The roadmap (see Q3 in `roadmap-2026-q3.md` §10) ordered **content (Sprint 8-10) before systems (Sprint 11)** because:
- **Sat-3, Sat-4, Sat-5 content can be played** even before bounty/racing systems are added (they're side content)
- The **bounty system needs Sat-3 to be playable** — bounty #3 ("蜂后守卫") is set in Sat-3
- After Sprint 10 (Sat-5 + 4 endings), the game is **feature-complete**; Sprint 11 is the polish
- Doing content first means by Sprint 11 the user can see the full game world and add bounty/racing on top

This sprint specifically targets Sat-3 because:
- It's the **first new content** — the team needs a workflow for "create a new satellite from scratch"
- The **hallucination mechanic** is novel (not in Sat-1 or Sat-2) — testing the workflow with one new mechanic
- **Bomber is not yet in the party** — Sat-3 is mid-game, party is 2 pilots (Ranger + Frostbite)

## Capacity

- **Total days**: 21 (3 weeks × 7 days)
- **Buffer (20%)**: 4.2 days
- **Available**: 16.8 days
- **Estimated total work**: 16.5 days (just within capacity)
- **Warning**: Tight sprint. If any L story slips by 1+ day, the sprint slips. Mitigation: 5 of 13 stories are S or M (≤1 day), so they can be done quickly if a larger story is delayed.

## Sprint Scope (one-liner per story)

The 13 stories below are organized into **5 critical-path waves**.

- **Wave 1 (Days 1-4): Art pipeline + tile + title assets**
  - S8-001 Sat-3 tile assets (4 tiles) (S)
  - S8-002 Sat-3 title background (S)
  - S8-009 Asset generation script (Python) (S)

- **Wave 2 (Days 5-9): Enemies + Boss**
  - S8-003 6 enemy types (6 .tres) (M)
  - S8-004 6 enemy sprite PNGs (S)
  - S8-005 1 boss: 蜂后守卫 (蜂后守卫.boss.tres) (M)
  - S8-006 1 boss sprite PNG (蜂后守卫.png) (S)

- **Wave 3 (Days 10-14): Levels + dialogue**
  - S8-007 10 room data files (10 .tres) (L)
  - S8-008 4 NPCs (4 .tres + 4 dialogue .tres) (M)
  - S8-010 4 NPC portrait PNGs (S)

- **Wave 4 (Days 15-18): Truth fragments + BGM + hallucination mechanic**
  - S8-011 7 Truth 3 fragments (7 .tres) (M)
  - S8-012 1 BGM (frozen_reactor-equivalent) (S)
  - S8-013 Hallucination mechanic (visual decoy enemies) (M)

- **Wave 5 (Days 19-21): Tests + verification**
  - S8-014 Tests fc67-fc72 (S)

---

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|--------------|-------------------|--------|
| S8-001 | Sat-3 tile assets (4 tiles: floor_hive, floor_hive_damaged, wall_hive, wall_hive_damaged) | technical-artist (Python synth) | 0.5 | None | 4 PNGs in `assets/tilesets/ch3/`; 32x32 px each; hive aesthetic (deep purple + viscous yellow + organic shapes); tiles register in `data/tilesets/ch3.tres`; TileMap can load them via `level_runtime.gd`; existing tile-loading code in `level_runtime.gd` accepts new tile_dir = `ch3/` (per party-system.md / level_runtime.gd chapter-aware logic added in S6-102) | Not Started |
| S8-002 | Sat-3 title background (title_hive.png, 1280×720) | technical-artist (Python synth) | 0.5 | None | 1 PNG in `assets/sprites/title/title_ch3.png`; 1280×720; deep purple + viscous yellow palette; alien hive visual (organic shapes, no human structures); file referenced in `src/ui/main_menu.gd` (or wherever title screen art is loaded — see S6-016 reference) | Not Started |
| S8-003 | 6 enemy types (蜂巢守卫, 蜂巢炮手, 蜂巢寄生, 蜂巢菌丝, 蜂巢幼虫, 蜂巢繁殖体) | systems-designer | 1.0 | None | 6 .tres files in `data/enemies/ch3_*.tres`; each has id/display_name/max_hp/attack/accuracy/boss=false/element=hive/drops/weakness; each id is unique; weaknesses include fire (×2) and ice (×0.5) per multi-satellite-arc.md §3.3; all 6 are loadable via `ResourceRegistry.get_resource(id)`; existing `data/enemies/` schema from `resource-data.md` is preserved | Not Started |
| S8-004 | 6 enemy sprite PNGs (32x32 px each) | technical-artist (Python synth) | 0.5 | S8-003 | 6 PNGs in `assets/sprites/enemies/ch3_*.png`; 32×32; visual variety (different shapes, sizes, palettes within purple/yellow range); enemy sprites are distinguishable at combat zoom | Not Started |
| S8-005 | 1 boss: 蜂后守卫 (Hive Queen's Guard) | systems-designer | 1.5 | S8-003 | 1 .tres in `data/enemies/boss_hive_guardian.tres`; id=boss_hive_guardian, display_name=蜂后守卫, max_hp=2400, attack=35, accuracy=0.85, boss=true, element=hive, drops=陈家步枪 (from Sat-2 Bounty #2 — but for Sat-3, drops a unique weapon: 蜂巢之心), weakness=fire (×2), regenerates 5% HP per turn (special ability); boss appears in Sat-3 Room 9 (Ch9 boss arena); previous Ch1-2 bosses have ~1500 HP, so 2400 is appropriately bigger | Not Started |
| S8-006 | 1 boss sprite PNG (蜂后守卫.png, 64×64) | technical-artist (Python synth) | 0.5 | S8-005 | 1 PNG in `assets/sprites/enemies/boss_hive_guardian.png`; 64×64 (vs 32×32 for normal enemies); visually imposing (larger, more detail, central eye or hive node); follows the existing boss sprite conventions from S6-007 (Marrow Sentinel) | Not Started |
| S8-007 | 10 room data files (Ch7: 3 rooms, Ch8: 3 rooms, Ch9: 3 rooms + 1 boss arena) | level-designer | 3.0 | S8-001, S8-003, S8-005 | 10 .tres files in `data/levels/chapters/chapter3.tres` (or similar structure per existing pattern); each room has room_id/name/description/tile_set/enemy_encounters/npcs/terminals/exits; layout follows Ch1/2 pattern (encounter rooms, terminal rooms, NPC rooms, empty traversal rooms, boss arena); rooms connect logically (e.g., Ch7 Room 0 → Ch7 Room 1 → ...); boss arena is Room 9 (Ch9 final room) | Not Started |
| S8-008 | 4 NPCs (流浪科学家, 蜂巢幸存者, 残存船员, 真菌感染者) | narrative-director + writer | 1.5 | None (parallel to S8-007) | 4 .tres in `data/npcs/ch3_*.tres`; each has id/display_name/portrait_path/dialogue_tree_id; each has 1-2 dialogue lines (matching Sat-1/2 NPC style); NPCs placed in: Ch7 Room 2 (流浪科学家), Ch8 Room 0 (蜂巢幸存者), Ch8 Room 2 (残存船员), Ch9 Room 1 (真菌感染者) | Not Started |
| S8-009 | Asset generation script (Python) for all Sat-3 assets | tools-programmer | 0.5 | None | 1 Python file in `tools/gen_ch3_assets.py`; generates all 4 tiles + 6 enemy sprites + 1 boss sprite + 1 title background + 1 BGM (S8-012); follows the pattern of existing `tools/gen_ch2_assets.py`; runs from CLI; deterministic seeds for reproducible output | Not Started |
| S8-010 | 4 NPC portrait PNGs (64×64 each) | technical-artist (Python synth) | 0.5 | S8-008 | 4 PNGs in `assets/sprites/npcs/ch3_*.png`; 64×64; matches the NPC .tres `portrait_path`; visual variety (different clothing, posture, expression); follows the S6-015 portrait conventions | Not Started |
| S8-011 | 7 Truth 3 fragments (7 .tres files) | writer + systems-designer | 1.5 | None (parallel to S8-008) | 7 .tres files in `data/fragments/fragment_ch3_*.tres`; each has id/title/body/author/date_in_world/unlock_fragment_id/importance per existing fragment schema; 7 fragments collectively tell Truth 3 ("Hive Mind") per `multi-satellite-arc.md` §4.3; at least 2 fragments have importance=2 (significant for ending logic); fragments are scattered across rooms (not all in one room); collected via terminal logs (4 fragments) + NPC dialogue (2 fragments) + hidden find (1 fragment) | Not Started |
| S8-012 | 1 BGM (蜂巢之心 / Hive Heart, 30s loop) | audio-director (Python synth) | 0.5 | None | 1 .wav in `assets/audio/music/hive_heart.wav`; 30s loop; organic drone aesthetic (low-frequency hum, occasional "pulse" sounds); deep purple + yellow visual match; referenced in `MusicPlayer` autoload; plays during Sat-3 exploration (similar to how `frozen_reactor.wav` plays during Sat-2); same volume/length as existing BGM tracks | Not Started |
| S8-013 | Hallucination mechanic (1-2 visual decoy enemies per hive room) | gameplay-programmer | 1.5 | S8-003, S8-004 | In Sat-3 rooms, 1-2 enemies per room are **decoys**: visually distinct (different color from real enemies, e.g., translucent purple instead of solid purple), spawn in a "fake" position (often behind a wall or in an unreachable area); when the player attacks a decoy, the decoy **fades away** without dealing damage; no HP is deducted; after a decoy is "killed", the player sees a brief "REVEALED" flash; the player learns to identify decoys (e.g., decoys don't have enemy names when hovered, or they have a "?" label); decoy spawning is deterministic per room (save/load doesn't randomize them) | Not Started |
| S8-014 | Tests fc67-fc72 — Sat-3 content, hallucination mechanic | qa-tester | 0.5 | All S8-001..S8-013 | 6 new integration test files created; 540 existing tests still pass (532 Sprint 6 baseline + 8 Sprint 7); all 6 new tests pass; tests cover: room traversal Ch7-9, all 6 enemies loadable, boss fight, hallucination decoy mechanic (attack a decoy, verify no HP loss, verify decoy fades) | Not Started |

**Subtotal**: 14 stories, ~13.5 days estimated. **Within capacity** (16.8 days). 3.3 days of buffer.

### Should Have (cut if time-pressed)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|--------------|-------------------|--------|
| S8-015 | Frostbite's mother encounter in Ch9 (merged with frozen fragment) | writer + godot-gdscript-specialist | 1.0 | S8-008 | In Ch9 Room 8 (just before boss), Frostbite's mother is encountered as a **partial-biological entity** (NPC, but with hive aesthetic — partially translucent, partial hive growth); she can communicate in broken phrases; she gives Frostbite a special item (e.g., "母亲的遗物" / Mother's Keepsake) that boosts Frostbite's stats in the boss fight; 3-beat cutscene; does NOT join the party permanently | Not Started |
| S8-016 | Hallucination: full visual distortion (screen tilts/warps in hive rooms) | technical-artist | 1.0 | S8-013 | In Sat-3 rooms, the screen has a **subtle visual distortion** (e.g., wavy edges, color shift, slight rotation); intensity scales with room depth (Ch7 mild → Ch9 strong); implemented via CanvasLayer + Shader; ~5 fps performance cost (acceptable); does not affect gameplay (just visual) | Not Started |
| S8-017 | Hive room ambient SFX (background buzz + drip) | audio-director | 0.5 | None | 2-3 ambient SFX (low buzz, organic drip, distant hum); play in Sat-3 rooms; loop seamlessly; ~30s each; volume lower than BGM | Not Started |
| S8-018 | Boss phase 2 (at 50% HP) — second form | systems-designer | 1.0 | S8-005 | At 50% HP, 蜂后守卫 enters phase 2: +30% attack, +20% armor, regenerates 10% HP per turn (was 5% in phase 1); visual: boss grows extra limbs / glows brighter; adds a new attack pattern (e.g., "spore cloud" — AoE that inflicts poison status); player must adapt strategy | Not Started |

### Nice to Have (Cut First)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|-----------|-------------------|--------|
| S8-020 | Hidden room in Ch8 (1 secret room with extra loot) | level-designer | 0.5 | S8-007 | Ch8 has 1 hidden room accessible only via a hallucination decoy (player attacks the decoy, the decoy "dies" and reveals a passage to the hidden room); hidden room contains 1 rare weapon + 1 bonus fragment | Not Started |
| S8-021 | Hive-organic walking animation (player mech has hive-influenced walk cycle) | animator | 1.0 | S8-002 | In Sat-3, the player mech's walking animation has slight hive-influence (e.g., swaying, occasional twitch); cosmetic only; reverts to normal in Sat-4+ | Not Started |
| S8-022 | Enemy variant: "elite" versions of 蜂巢守卫 / 蜂巢炮手 (1.5x HP, 1.2x damage) | systems-designer | 0.5 | S8-003 | 2 additional .tres files (ch3_hive_guardian_elite, ch3_hive_cannon_elite); spawn in 1-2 specific rooms (not random); drop 1.5x gold; for experienced players who want more challenge | Not Started |

## Risks to This Sprint

| Risk | Probability | Impact | Mitigation | Owner |
|------|------------|--------|-----------|-------|
| Hallucination mechanic confuses players (they think decoys are real, waste attacks) | Medium | High | Make decoys **visually distinct** (e.g., translucent purple vs solid purple); add a "?" label when hovered; play a distinct SFX when attacking a decoy (different from real enemy SFX); playtest with 2-3 users before finalizing | gameplay-programmer |
| Hallucination mechanic feels cheap / frustrating (player feels cheated) | Medium | Medium | Limit decoys to 1-2 per room (not more); only in hive-themed rooms (not in terminals/NPC rooms); document the mechanic in a tutorial hint in Ch7 Room 0 | gameplay-programmer |
| Sat-3 room count (10) is too low — pacing feels rushed | Low | Medium | If too short, add 1-2 hidden rooms or extend Ch9 to 4 rooms; defer to S8-020 or add as a story in Sprint 9 | level-designer |
| Python synth can't produce convincing hive-organic visuals (purple textures look like "regular purple" not "alien hive") | Medium | Medium | Iterate on the synth with 2-3 different palettes; if needed, use base PNG + shader for additional "organic" overlay; reference: H.R. Giger's alien aesthetic (subtle, not gory) | technical-artist |
| BGM hive_heart.wav sounds too similar to existing BGM (frozen_reactor) | Low | Low | Use different frequency range (higher-pitched for hive) + different rhythm (pulsing for hive, drone for frozen) | audio-director |
| Frostbite's mother encounter (S8-015) is too emotional for the sprint's "first new content" tone | Low | Low | Keep it brief (1-2 lines of dialogue, 1 item); full emotional arc happens in Sat-4 or Sat-5; defer to S8-015 if needed | writer |
| Boss phase 2 (S8-018) makes the boss too hard for Sprint 8's "match Sat-1/2 difficulty" target | Low | Medium | If phase 2 is too hard, lower phase 2 regen from 10% to 7%; or skip phase 2 entirely; defer to S8-018 if tight on time | systems-designer |
| 7 Truth 3 fragments are too "info-dumpy" (read like a wiki article) | Medium | Medium | Use **environmental narrative**: fragments are scattered across different media types (terminal logs, NPC dialogue, hidden recordings); each fragment is a "piece" the player assembles; vary writing style per fragment (some terse, some poetic) | writer |
| Asset generation script (S8-009) breaks on Windows due to PIL/wave path issues | Low | Low | Test on Windows before generating; use absolute paths in the script; check existing `tools/gen_ch2_assets.py` for Windows compatibility patterns | tools-programmer |
| 14 stories in 16.8 days is tight — sprint slips if S8-007 (rooms) or S8-005 (boss) take longer | High | High | Cut Should-Haves (S8-015/16/17/18) if needed; if S8-007 slips by 2+ days, defer 1-2 rooms to Sprint 9 as a stretch goal | user decision |
| Save/load: old saves don't have Sat-3 unlocked, but party system (Sprint 7) made save format changes | Low | Medium | Old saves (pre-Sat-3) work fine (no Sat-3 content); new saves after Sprint 7 work fine; cross-sprint save compatibility verified by S8-014 tests | qa-tester |

## Open Questions (need user input before or during sprint)

- **OQ1**: How many hours/week will the user commit to Sprint 8? (3 weeks of 16.8 days = ~5.6 days/week = ~45 hours/week.) Same as Sprint 7 question.
- **OQ2**: Should the **hallucination mechanic** be a **harder** version (decoys deal damage, are real enemies with low HP) or a **softer** version (decoys are pure visual, no damage)? Currently planned: softer (no damage). The user chose "lightweight hallucination" but the implementation detail of "do decoys deal damage" is a sub-question. Currently recommended: pure visual.
- **OQ3**: The boss 蜂后守卫 drops the **unique weapon "蜂巢之心"** (Hive Heart). Should this weapon be **required for the Sat-3 → Sat-4 transition** (a la Ch5 plot bounty required for Sat-2 → Sat-3), or just a **reward**? Currently planned: just a reward (no transition requirement). The transition is via the existing plot bounty (Sprint 11) or via boss kill.
- **OQ4**: Should the **hallucination mechanic** be **per-room or per-save**? If per-save (player sees decoys in all hive rooms across the playthrough), the mechanic is always-on. If per-room (player sees decoys only in rooms flagged as "hive"), the mechanic is local. Currently planned: per-room (decoys only in Sat-3 rooms).
- **OQ5**: The **Frostbite's mother encounter (S8-015)** is currently a Should-Have. If we cut it, Frostbite's arc feels unresolved (his mother was promised in S6-102 but the encounter was deferred to "see in Sat-3"). Is the user OK with the cut? Currently: I'll proceed without it for Sprint 8; if the user wants it, S8-015 is a 1-day task and can be added.
- **OQ6**: Should the **new BGM (蜂巢之心) be at 30s or 60s**? 30s is standard; 60s is more "epic" but uses more disk space. Currently planned: 30s (match Sat-1/2 BGM length).
- **OQ7**: The **"6 enemy types"** for Sat-3 — should any of them be **reskins of Sat-1/2 enemies** (e.g., a "hive-flavored" version of scavenger) for faster implementation? Currently planned: 6 new unique enemies (no reskins). If tight on time, 2 could be reskins.
- **OQ8**: The **hidden room (S8-020)** is currently Nice-to-Have. Should it be in scope (for Sprint 8) or deferred to Sprint 9? The "density audit" principle in `game-concept.md` Pillar 1 says every room should have a payoff — a hidden room would be a major payoff. Currently: defer to Sprint 9 (consistent with Sprint 8's tight capacity).

## Definition of Done

- [ ] All 14 Must-Have tasks completed (S8-001 to S8-014)
- [ ] All tasks pass acceptance criteria
- [ ] 540 existing tests still pass (no regressions)
- [ ] 6 new tests (fc67-fc72) all pass
- [ ] F5 walkthrough Sat-3: enter Sat-3 from Sat-2, traverse Ch7-9, fight boss, collect all 7 Truth 3 fragments
- [ ] F5 walkthrough: hallucination mechanic — attack a decoy, verify it fades without damage; attack a real enemy, verify normal combat
- [ ] F5 walkthrough: 4 NPCs have dialogue that triggers when player is in their room
- [ ] F5 walkthrough: BGM plays correctly when entering Sat-3 rooms (switches from Sat-2 BGM)
- [ ] Visual: 4 Sat-3 tiles render correctly; 6 enemy sprites are distinguishable; boss sprite is imposing
- [ ] Audio: BGM plays in a loop without crackle; ambient SFX (if implemented) plays at low volume
- [ ] Save/Load roundtrip: save after killing boss, reload, boss is dead, fragments preserved
- [ ] Sprint 8 close report written (`production/sprints/sprint-08-close.md`)

## Sprint Risks (summary)

The 14 Must-Have stories total **13.5 days** of work, with capacity **16.8 days**. **Buffer: 3.3 days** (healthy but not huge).

The biggest risk is the **hallucination mechanic** (S8-013) — it's the only "new mechanic" in this sprint, and if it doesn't work, the sprint's "new content" feel is diminished. Mitigation: prioritize S8-013 with a 0.5-day spike before full implementation.

The second biggest risk is **S8-007 (10 rooms)** — level design is labor-intensive. Mitigation: design the room connections first, then fill in details; if needed, defer 1-2 rooms to S8-020 (hidden room) as a stretch goal.

If the sprint slips by 1+ day, cut Should-Haves aggressively (especially S8-015 "Frostbite's mother" — important for story but not for sprint completion).

## Carryover from Sprint 7

- **Party system (Sprint 7 output)** — Sprint 8's content assumes the 3-pilot + 4-mech party works. If Sprint 7's party system has bugs, they will surface in Sprint 8 (e.g., combat in Sat-3 with the wrong number of pilots).
- **Save/Load format from Sprint 7** — Sprint 8's new enemies/rooms/NPCs must be serializable in the new save format. Verify in S8-014 tests.
- **`MechLoadout.parts` dict from Sprint 7** — if Sprint 7 added 4 mechs (Ranger / Frostbite / Bomber / Cangqiong), Sprint 8 should NOT add more (Cangqiong is a Sprint 10 unlock). Sprint 8 stays at 3 mechs (Ranger / Frostbite / Bomber).
- **Hallucination visual style** — if Sprint 7's HUD rewrite established a "color palette per chapter" convention, Sat-3 (deep purple + yellow) follows that convention.

## My Recommendation: How to Start This Sprint

1. **Day 1**: Resolve OQ2 (hallucination damage rule) — critical for S8-013 design.
2. **Day 1-2**: S8-009 (asset generation script) + S8-001 (tiles) + S8-002 (title) — pure asset work, can be done in parallel.
3. **Day 2-4**: S8-003 + S8-004 (6 enemies + sprites) — generate via S8-009 script.
4. **Day 4-5**: S8-005 + S8-006 (boss + boss sprite).
5. **Day 5-8**: S8-007 (10 rooms) — level design. This is the bottleneck.
6. **Day 5-8 (parallel)**: S8-008 + S8-010 + S8-011 (NPCs + portraits + fragments) — content writing.
7. **Day 8-9**: S8-012 (BGM).
8. **Day 9-11**: S8-013 (hallucination mechanic) — the new mechanic. Spike first.
9. **Day 11-13**: Integration, F5 walkthrough, bug fixes.
10. **Day 13-14**: S8-014 (tests) + F5 verification + sprint close report.

## Verdict

**Ready to start** — pending OQ2 (hallucination damage) resolution.

- 14 Must-Have stories clearly defined
- 4 Should-Have stories as buffer (Frostbite's mother, full visual distortion, ambient SFX, boss phase 2)
- 3 Nice-to-Have stories (hidden room, walking animation, elite variants) that are likely cut
- All ACs are testable
- 3.3 days buffer — healthy sprint
- The hallucination mechanic is the only "new mechanic" — manageable
- Frostbite's mother encounter is Should-Have; can be deferred to Sprint 9 if tight

**This sprint is well-scoped.** The user should expect:
- 16-18 hour weeks for 3 weeks
- Some Should-Haves cut (Frostbite's mother is the most likely cut)
- A polished, fully playable Sat-3 at the end
- A reusable workflow for "create a new satellite from scratch" that Sprint 9 and 10 will follow
