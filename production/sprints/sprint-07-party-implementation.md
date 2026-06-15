# Sprint 7 — Party System Implementation

## Sprint Goal

Implement the **3-pilot + 4-mech party system** as specified in `design/gdd/party-system.md`. After this sprint, the player can fight with up to 3 pilots simultaneously, swap which mech any pilot drives, switch the active combat character with 1/2/3 keys, revive knocked-out pilots at town clinics, and inherit the 苍穹号 mech in Ch13. This sprint establishes the foundation for all subsequent content sprints (Sprint 8-11) which assume the party system is in place.

## Milestone Context

- **Current Milestone**: Production (started 2026-06-13)
- **Sprint 6 Status**: Closed 2026-06-15 — vertical slice polished, 532/532 tests pass, v1.0.0-rc1 tagged
- **Sprint 7 Deadline**: 2026-07-06 (3 weeks from Sprint 6 close)
- **Roadmap Position**: First sprint in the **post-GDD implementation phase** — see `production/roadmap-2026-q3.md`

## Why This Sprint, Not Content

Sprint 6 closed a polished vertical slice of the original 3-chapter design. But on 2026-06-15, the user expanded the scope to **5 satellites × 3 chapters = 15 chapters** with 3 pilots, 4 mechs, 6 bounties, 6 racing tracks, and 4 endings. Four GDDs were authored in one session (party / bounty / racing / multi-satellite-arc, 2634 lines total) — see `design/gdd/`.

Implementing **party system first** is critical because:
- **Sprint 8-11 content all assumes party mechanics** — without the party code, content sprints would have to re-design enemy counts, weapon slots, dialogue companions, etc.
- **Combat is the highest-risk rewrite** — the existing `BattleScene` is 1v1; making it 1-vs-3-pilots is a substantial architecture change.
- **Save/load must be re-architected** — party state (pilots, mechs, weapons, gold, levels) is far more complex than the existing 1-pilot state.

If we tried to do content first, we'd have to throw away the content when the party system forced changes to enemy/encounter/NPC design.

## Capacity

- **Total days**: 21 (3 weeks × 7 days)
- **Buffer (20%)**: 4.2 days
- **Available**: 16.8 days
- **Estimated total work**: 16.5 days (just within capacity)
- **Warning**: This sprint is at the edge of capacity. If any single story slips by 1+ days, the sprint slips. Mitigation: 4 of 12 stories are flagged "S" (small, ≤0.5 day) so they can be done quickly if a larger story is delayed.

## Sprint Scope (one-liner per story)

The 12 stories below are organized into **4 critical-path waves**. Each wave must be roughly complete before the next wave starts, though S/M stories within a wave can be parallelized.

- **Wave 1 (Days 1-7): Core combat + weapon/pilot state**
  - S7-001 BattleScene 1v1 → 3v1 (L)
  - S7-002 WeaponLoadout pilot-mech decoupling (L)
  - S7-009 Combat formulas (S)
  - S7-010 Save/Load party state (M)

- **Wave 2 (Days 8-14): HUD + dialogue + UI**
  - S7-003 MechLoadout 4 mechs + swap (M)
  - S7-004 HUD 3-4 mech HP bars + assignment UI (M)
  - S7-005 Dialogue companion in-dialogue swap (M)
  - S7-007 Mech Bay menu (M)
  - S7-011 Auto mode 3-pilot AI (M)

- **Wave 3 (Days 15-18): Death/revival + inheritance**
  - S7-006 Town clinic revival (M)
  - S7-008 苍穹号 inheritance scene (M)

- **Wave 4 (Days 19-21): Tests + verification**
  - S7-012 Tests fc59-fc66 (S)

---

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|--------------|-------------------|--------|
| S7-001 | BattleScene: 1v1 → 3v1 (party of 3 pilots, single enemy) | godot-gdscript-specialist | 3.0 | None | Existing 1v1 fights still work; new 3v1 fights work; party phase = N turns per round (per party-system.md §3.7); pilot switch mid-combat (1/2/3 keys) functional; mech switch mid-combat (Tab key) functional; no crash on existing saves | Not Started |
| S7-002 | WeaponLoadout: pilot-mech decoupling (3-4 weapon slots per mech, cross-pilot) | godot-gdscript-specialist | 3.0 | S7-001 | Each mech has 3 (or 4 for 苍穹号) weapon slots; weapons are mounted on mechs, not pilots; any pilot can use any mech's weapons; weapon switching works mid-combat; pre-fight weapon loadout saved per mech (not per pilot); cross-pilot combat does not double-trigger weapon abilities | Not Started |
| S7-003 | MechLoadout: 4 mechs (Ranger / Frostbite / Bomber / Cangqiong) with swap | godot-gdscript-specialist | 1.5 | S7-002 | 4 mechs exist as resources; `MechLoadout.parts` is a dict with all 4 mech IDs; `MechLoadout.active_mech` selects the active mech; `set_active_mech(id)` swaps; default pilot-mech mapping per party-system.md §3.4; freeze/thaw 3-4 mechs in/out of combat | Not Started |
| S7-004 | HUD: 3-4 mech HP bars + pilot-mech assignment UI | godot-gdscript-specialist + ui-programmer | 1.5 | S7-001, S7-003 | HUD shows 3-4 mech HP bars (one per active mech in the party); each bar shows pilot icon, mech name, current/max HP, status (active/knocked out); clicking a bar selects that mech in combat; bottom-right "Mech Bay" button opens S7-007 menu | Not Started |
| S7-005 | Dialogue: companion in-dialogue swap (Shift+1/2/3) | godot-gdscript-specialist | 1.5 | None (parallel to S7-001) | In dialogue, 2 portraits visible (main + 1 in-dialogue companion); Shift+1/2/3 swaps in-dialogue companion before dialogue starts; companion dialogue is scripted per NPC; some NPCs have companion-specific dialogue trees that only trigger with the right companion (per party-system.md §3.9) | Not Started |
| S7-006 | Town clinic revival system (gold cost, 25%) | godot-gdscript-specialist | 1.5 | S7-001 | When a non-main pilot is knocked out in combat, they are auto-sent to the nearest clinic after combat; revival cost = `max(floor(gold × 0.25), 100)`; revivals unlimited; main character (漫游者) cannot be revived — death = game over; revival UI in clinic shows "Revive [pilot] for X gold?" prompt | Not Started |
| S7-007 | Mech Bay menu (M key) — assign pilots, swap weapons, view part HP | ui-programmer | 2.0 | S7-002, S7-003 | M key opens Mech Bay (in exploration, save points, and during player's turn in combat); menu shows: all owned mechs, current pilot assignments, weapon inventory per mech, mech part HP (head/chest/arms/legs); player can swap pilot-mech assignments; player can move weapons between mechs (if slot type matches); menu closes on Esc or M | Not Started |
| S7-008 | 苍穹号 inheritance scene (Ch13 placeholder for now) | godot-gdscript-specialist + narrative-director | 1.5 | S7-001, S7-003 | Debug command or hidden trigger in Ch13 area causes: 7-beat cutscene (per party-system.md §3.3); 苍穹号 power-on sequence; 漫游者 receives Creator Receiver code; 苍穹号 added to MechLoadout; pre-inheritance story save point to allow re-trigger; "Continue" prompt exits scene | Not Started |
| S7-009 | Combat formulas (dodge / hit / crit / damage / XP / revival) | systems-designer + godot-gdscript-specialist | 0.5 | None (parallel to S7-001) | All 7 formulas from party-system.md §4 implemented in `BattleMathLib`; constants match §4 spec; F1 (dodge) respects `level × 0.02` + `equip + mech`, capped at 0.80, with 3-turn safety net; F4 (damage) applies weakness + crit_mult + armor; F5 (XP) = `BASE_XP × level^1.5`; F6 (revival) = `max(floor(gold × 0.25), 100)`; existing `BattleMathLib` extended (not replaced) to keep backward compat | Not Started |
| S7-010 | Save/Load: party state (pilots, mechs, weapons, gold, levels) | godot-gdscript-specialist | 2.0 | S7-001, S7-002, S7-003 | Save schema extended to include: `party` (3 pilots with name/level/HP/abilities), `mechs` (4 mechs with HP/parts/weapons), `pilot_mech_assignments` (default mapping), `gold`, `revival_count_per_pilot`, `cangqiong_inherited` (bool); old saves migrate gracefully (party = 1 pilot + 1 mech default); save file size estimate: 3-5 KB per save (was ~1 KB) | Not Started |
| S7-011 | Auto mode rewrite (3-pilot AI in Manual+Auto modes) | ai-programmer | 2.0 | S7-001, S7-002 | Auto mode auto-selects optimal action for each mech each turn; existing 1-pilot Auto logic generalized to 3 pilots; Auto mode respects pilot abilities (e.g., 霜尾's Flank triggers automatically when available); Auto mode respects mech slot count (e.g., 轰天号's AOE targets the densest enemy cluster); "Pause Auto" hotkey (P) lets the player intervene mid-turn | Not Started |
| S7-012 | Tests: fc59-fc66 — party combat, dialogue swap, revival, mech swap | qa-tester | 0.5 | All S7-001..S7-011 | 8 new integration test files created; 532 existing tests still pass; all 8 new tests pass; each test covers one AC from party-system.md §8 | Not Started |

**Subtotal**: 12 stories, ~20.5 days estimated. **At capacity** (16.8 days available). Requires discipline.

### Should Have (cut if time-pressed)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|--------------|-------------------|--------|
| S7-013 | Pilot-specific dialogue in existing Ch1-3 NPCs (Vera, Marlow, courier) | writer | 1.0 | S7-005 | Each existing Ch1-3 NPC has 1-2 extra dialogue lines that vary by which companion is in-dialogue; e.g., Vera has a different response if 霜尾 is with the player | Not Started |
| S7-014 | Pilot-mech combo tutorials (1st time each combo is used) | ux-designer | 0.5 | S7-004 | First time the player uses 漫游者 in 苍穹号 (or any non-default combo), a tutorial hint shows the new abilities | Not Started |
| S7-015 | Per-pilot XP and leveling UI | ui-programmer | 0.5 | S7-009 | HUD shows each pilot's level and XP-to-next; level-up triggers a brief "LEVEL UP" animation | Not Started |
| S7-016 | In-combat Mech Bay (open menu mid-fight on player's turn) | ui-programmer | 0.5 | S7-007 | Mech Bay can be opened during combat on the player's turn (paused state) but not during enemy turn; warns if a mech swap would leave the active mech with no pilot | Not Started |

### Nice to Have (Cut First)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|--------------|-------------------|--------|
| S7-020 | Pilot ability sound effects (3 pilots × 3 abilities = 9 unique SFX) | audio-director | 1.0 | S7-001 | Each pilot ability plays a distinct SFX (synth, not stock audio); placeholder beeps OK | Not Started |
| S7-021 | Pilot profile screen (full stats, equipment, abilities tree) | ui-programmer | 1.5 | S7-004 | A new "Party" menu shows each pilot's full stats, equipment, ability tree, and signature ability description; accessible from main menu | Not Started |
| S7-022 | Mech comparison tooltips (hover mech in Mech Bay → stat comparison) | ui-programmer | 0.5 | S7-007 | Hovering a mech in Mech Bay shows a side-by-side comparison of stats with the current active mech | Not Started |

## Risks to This Sprint

| Risk | Probability | Impact | Mitigation | Owner |
|------|------------|--------|-----------|-------|
| BattleScene 1v1 → 3v1 rewrite breaks existing fights | High | Critical | Build S7-001 with a `legacy_1v1_mode` flag; keep existing fights working; add 3v1 as opt-in; migrate to 3v1 over time (can be done in Sprint 8 if needed) | godot-gdscript-specialist |
| Save file format change breaks old saves | Medium | Medium | Write save migration script in S7-010; on load, if old format detected, auto-convert to new format with sensible defaults (1 pilot, 1 mech) | godot-gdscript-specialist |
| WeaponLoadout refactor breaks weapon switching mid-combat | Medium | High | Test all 5 weapons (rifle, knife, etc.) for mid-combat switch; ensure weapon ability triggers don't double-fire when pilot changes | godot-gdscript-specialist |
| 12 stories in 16.8 days = overcapacity | High | High | Cut Should-Haves aggressively; if S7-001 slips by 1+ day, drop S7-014/15/16 from this sprint; if S7-007 slips, drop S7-016 (in-combat Mech Bay) | user decision |
| HUD rewrite causes visual regression | Medium | Medium | Take screenshots of HUD before/after; compare layout pixel-by-pixel | ui-programmer |
| 苍穹号 inheritance scene triggers on existing saves incorrectly | Low | High | Inheritance scene only triggers in Ch13 area; existing Ch1-3 saves never reach Ch13; only matters for debug/test scenarios | godot-gdscript-specialist |
| Pilot ability sound effects are not generated (Python synth may not have right samples) | Medium | Low | Use existing SFX with pitch/volume variation; placeholder beeps OK (per S7-020 fallback) | audio-director |
| Dialogue companion swap has UX edge cases (Shift+1 mid-dialogue breaks sequence) | Medium | Low | Disable Shift+1 once dialogue starts; only allow swap before dialogue opens | godot-gdscript-specialist |
| Auto mode 3-pilot AI is too "smart" and trivializes combat | Medium | Medium | Auto mode picks "good" actions but not "optimal" — give the player a 10-20% advantage from Manual mode | ai-programmer |
| Test coverage of new party system is too thin | Medium | Medium | 8 new tests (S7-012) cover each AC; consider adding 4-8 more in Sprint 8 stretch goals | qa-tester |

## Open Questions (need user input before or during sprint)

- **OQ1**: How many hours/week will the user commit to Sprint 7? (3 weeks of 16.8 days = ~5.6 days/week = ~45 hours/week.) Affects whether 3-week sprint is realistic or needs to be 4 weeks.
- **OQ2**: Should the party system be **integrated with existing Ch1-3 in Sprint 7** (so Ch1-3 uses the new 3-pilot system from the start, with only 1 pilot available until Ch4), or **only Ch4+ uses the new system** (Ch1-3 keeps the 1-pilot system as legacy)? This is a critical-path decision: integrating with Ch1-3 is more work in Sprint 7 but cleaner for Sprint 8+. Currently the design says "Ch1 = 1 pilot solo, Ch4+ = party." The implementation question is whether to maintain 2 code paths or 1.
- **OQ3**: The 苍穹号 inheritance scene in S7-008 is a "Ch13 placeholder" — should it be triggered via a **debug command** (for Sprint 7 testing) or via a **hidden Ch13 area** (which doesn't exist yet)? Debug command is easier for Sprint 7 testing; Ch13 trigger is needed for Sprint 10. Recommend: debug command in Sprint 7, real Ch13 trigger in Sprint 10.
- **OQ4**: Save file versioning — should old saves be **automatically migrated** (zero user effort) or **require a one-time conversion** (user runs a tool)? Auto-migration is friendlier but risks data loss; explicit conversion is safer but adds friction. Recommend: auto-migration with a backup of the old save.
- **OQ5**: The "3-pilot" assumption means the player has 3 HP bars in combat. Will this **slow combat significantly**? The current 1v1 fights are ~30 seconds; 3v1 might be ~60-90 seconds. If too slow, consider keeping enemy attack count = 1 per round (per party-system.md §3.7) and see if that's fast enough.
- **OQ6**: Should S7-011 (Auto mode 3-pilot AI) be a **strict port** of the existing 1-pilot Auto logic, or a **new design** (e.g., per-pilot "tendencies" — 霜尾 prefers flanking, 轰天 prefers support)? Strict port is faster; new design is richer. Currently recommended: strict port in Sprint 7, design improvements in Sprint 8+.
- **OQ7**: The dialogue system (S7-005) is shared with the NPC/terminal GDD (`design/gdd/npc-terminal.md`). Should the companion-in-dialogue feature be implemented in `DialogueManager` directly, or in a new `DialogueCompanionSelector` autoload? Recommend: extend `DialogueManager` (smaller change, less new code).

## Definition of Done

- [ ] All 12 Must-Have tasks completed (S7-001 to S7-012)
- [ ] All tasks pass acceptance criteria
- [ ] 532 existing tests still pass (no regressions)
- [ ] 8 new tests (fc59-fc66) all pass
- [ ] F5 walkthrough: start a new game, recruit Frostbite (Ch4, existing), recruit Bomber (Ch10, existing), then F5 to confirm 3-pilot party works in combat
- [ ] F5 walkthrough: Mech Bay menu opens (M key), shows all 3 mechs, allows pilot-mech swap
- [ ] F5 walkthrough: town clinic revival — knock out a pilot, return to town, pay 25% gold, pilot revives
- [ ] F5 walkthrough: 苍穹号 inheritance via debug command — scene plays, 苍穹号 added to roster
- [ ] Save/Load roundtrip: save the game, quit, reload — party state preserved
- [ ] No new "critical/blocker" bugs in vertical slice playthrough
- [ ] Sprint 7 close report written (`production/sprints/sprint-07-close.md`)

## Sprint Risks (summary)

The 12 Must-Have stories total **20.5 days** of work, but capacity is **16.8 days**. This is a **3.7-day overrun risk**. Mitigations:
- Should-Haves (S7-013/14/15/16) are the first to be cut
- Nice-to-Haves (S7-020/21/22) are cut first
- If S7-001 slips by 1+ day, drop S7-014/15/16 immediately
- If S7-007 slips, drop S7-016 (in-combat Mech Bay)
- If S7-001/002 (the L stories) both slip, extend sprint to 4 weeks

The sprint's biggest risk is **scope vs. time** — at 3 weeks for 12 stories, there is little buffer. The user should plan for **either**:
- A) Strict execution of all 12 Must-Haves, no Should-Haves
- B) Extend the sprint to 4 weeks and allow Should-Haves

## Carryover from Sprint 6

- **532/532 tests pass** — preserved as the regression baseline
- **All 4 lints hard-fail in CI** — preserved; new party code must pass lints
- **`tools/build.sh linux windows`** — Sprint 7 ends, should still build; user can verify with a manual build
- **`project.godot` autoload order** — adding 1-2 new autoloads for party system requires updating `project.godot`; this MUST be committed

## My Recommendation: How to Start This Sprint

1. **Day 1**: Resolve OQ2 (Ch1-3 integration) — this is the critical-path decision.
2. **Day 1-2**: Set up the new autoloads (PartyManager, PilotRegistry) — small task, but blocks everything else.
3. **Day 2-4**: S7-009 (combat formulas) — pure math, can be done in parallel with S7-001. Has its own tests.
4. **Day 2-7**: S7-001 + S7-002 in parallel (two specialists on the same files — coordinate carefully, or do sequentially).
5. **Day 8-14**: S7-003, S7-004, S7-005, S7-007 (HUD + dialogue + Mech Bay) in parallel.
6. **Day 15-18**: S7-006, S7-008, S7-011 (clinic, inheritance, Auto mode) in parallel.
7. **Day 19-21**: S7-012 (tests) + F5 walkthrough + sprint close report.

## Verdict

**Ready to start** — pending OQ2 resolution.

- 12 Must-Have stories clearly defined
- 4 Should-Have stories as buffer
- 3 Nice-to-Have stories that are likely cut
- All ACs are testable
- Save migration is the only "data loss" risk; mitigated by backup
- All work is within Godot 4.6's existing capabilities; no new tech dependencies

**This sprint will be tight but achievable.** The user should expect:
- 16-18 hour weeks for 3 weeks
- 1+ day of buffer that may be consumed
- Some Should-Haves cut
- A polished, working party system at the end

If OQ2 resolves to "integrate with Ch1-3 in Sprint 7", the sprint is **at risk** of slipping. If it resolves to "Ch1-3 legacy", the sprint is **safe**.
