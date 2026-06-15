# Sprint 4 — Content & Systems Completion

> **Sprint Goal**: Fill the content gap and complete the remaining game systems so that the vertical slice is a complete game, ready for release-readiness work in Sprint 5.

> **Dates**: 2026-06-14 (proposed, 1-2 weeks at solo-direct-execution pace)
> **Capacity**: ~5-7 working days (A content) + 2-3 buffer (B systems / unplanned) = ~7-10 days
> **Scope target**: 6-week ship window → content + systems done, polish in Sprint 5

## Milestone Context

- **Current Milestone**: Pre-release content + systems completion
- **Milestone Deadline**: target ship 2026-08-01 (≈6 weeks from 2026-06-14)
- **Sprints Remaining**: 2 (Sprint 4 = content+systems, Sprint 5 = release-readiness)
- **Prior sprints**: Sprint 1 (vertical slice foundation), Sprint 2 (content + UX), Sprint 3 (polish + guards)

## Current State (Measured 2026-06-14)

| Metric | Value | Target | Gap |
|--------|-------|--------|-----|
| Weapons | 6 | 8-10 | 2-4 |
| Ammo | 4 | 5-6 | 1-2 |
| Enemies | 5 | 8-10 | 3-5 |
| Bosses | 1 | 2-3 | 1-2 |
| Mech parts | 1 | 4 (head/chest/arm/leg) | 3 |
| NPCs | 2 | 5-6 | 3-4 |
| Story fragments | 2 | 8-12 | 6-10 |
| Levels/biomes | 1 | 3-5 | 2-4 |
| Test scripts | 23 | 25-30 | 2-7 |
| Lint guards | 9 | 9 (saturated) | 0 |
| 0 TODOs in src/ | ✅ | ✅ | — |

Sprint 3 carryover cleared: S3-010 SaveUI ✅, fc7 dialogue choice ✅, HiDPI sweep ✅, S2-005 fragment test + impl ✅, Door TODO ✅ (deleted as simplification).

## Capacity

- **Total days**: 7-10
- **Buffer (20%)**: 1.5-2 days for unplanned F5 fixes, dependency surprises
- **Available**: 5.5-8 days for tasks
- **Pace**: Solo, direct-execution (no agent hand-offs needed for small scope; large content batches may delegate to gameplay-programmer / content-audit)

## Tasks

### Must Have (Critical Path — content & systems ship-blockers)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|-------------|-------------------|--------|
| S4-001 | Add 2 mech part resources (arm + leg) | gameplay-programmer | 0.25 | None | `data/mech/arm_part.tres` + `leg_part.tres` registered; fc5_mech_test verifies load + cycle into slot 0/1/2 | Not Started |
| S4-002 | Mech part swap HUD integration (cycle 1/2/3 to swap parts in slots) | gameplay-programmer | 0.5 | S4-001 | F5: in exploration, press Q to cycle mech parts; HUD shows new part + updated stats; save/load round-trips equipped parts | Not Started |
| S4-003 | Add 2 weapons (mine_layer + arc_emitter) — new roles, not stat clones | gameplay-programmer | 0.5 | None | `data/weapons/{mine_layer,arc_emitter}.tres`; fc12 verifies all 8 weapons loadable; each has unique role tag (AoE / chain) | Not Started |
| S4-004 | Add 3 enemies (swarmer, shielded_bot, reflector_drone) — fill role quadrants | gameplay-programmer | 0.5 | None | `data/enemies/{swarmer,shielded_bot,reflector_drone}.tres`; fc13 verifies 8-enemy role diversity; encounter integration with level_runtime | Not Started |
| S4-005 | Add 6 story fragments (write the 6 chapters of "the convoy was family" arc) | writer + narrative-director | 0.75 | None | 6 new `data/fragments/*.tres`; each unlocked by reading a specific terminal log or dialogue node; HUD counter goes 0→6 across a play session; existing fc6 + fc22 tests still pass | Not Started |
| S4-006 | Add 3 NPCs (Marlow's ghost, salvage drone operator, last surviving crew) + their dialogue trees | narrative-director + writer | 1.0 | S4-005 (some fragments tied to NPC dialogue) | 3 new `data/npcs/*.tres`; each with 4-6 node tree; NPC spawn wired in level_runtime; existing fc7 + fc14 still pass; new test for each NPC's unique dialogue branch | Not Started |
| S4-007 | Auto-mode battle AI (decide attack slot + ammo choice + defend based on enemy weakness) | ai-programmer | 1.0 | None | Auto mode now picks best weapon+ammo against enemy armor type; if HP<30% defends; current "auto mode is stub" comment removed; F5: set mode to AUTO, fight 3 battles, see non-trivial decisions | Not Started |
| S4-008 | Hidden room + breakable wall system | level-designer | 1.0 | None | Wall segment can be marked breakable (resource or marker); on hit_by_weapon with right damage type, wall removed; door opens to hidden area; F5: find + break into at least 1 hidden room | Not Started |
| S4-009 | Multiple ending sequence (based on fragment count threshold) | narrative-director + gameplay-programmer | 1.0 | S4-005 | After defeating final boss, if unlocked_fragments >= 6 → ending A (revelation), elif >= 3 → ending B (partial), else → ending C (default); 3 distinct ending .tres resources; existing fc15 still passes | Not Started |
| S4-010 | Add 1 ammo type (emp_charge — already there, but ADD: plasma_burn for DoT) | gameplay-programmer | 0.25 | None | `data/ammo/plasma_burn.tres` with DoT effect; existing fc12 still passes; new test for damage_over_time tick | Not Started |

**Must Have total: ~7 working days.** Fits the 5.5-8 day available window.

### Should Have (if capacity allows — quality & polish)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|-------------|-------------------|--------|
| S4-011 | Add 2 ammo types (tracking_round, explosive_shell) | gameplay-programmer | 0.25 | None | 2 new `data/ammo/*.tres`; fills 3-of-4 damage type quadrants | Not Started |
| S4-012 | Add 1 boss (corrupted_engineer) for mid-game, pre-final | level-designer + ai-programmer | 0.75 | None | New `data/enemies/corrupted_engineer.tres` with boss=true + unique phase transition; spawn in room 5; new fc verifies boss_immune_to_one_shot | Not Started |
| S4-013 | Add 1 biome (engine_room — different tile palette, enemy mix) | level-designer | 1.0 | None | `data/levels/chapter2_engine_room.tres`; new tile colors; different enemy mix; transition from chapter 1 to chapter 2 | Not Started |
| S4-014 | TerminalUI/CodexUI fragile geometry refactor (y_offset=80 + 600.0 hardcodes → constants) | godot-gdscript-specialist | 0.25 | None | Both files use named constants; no hardcoded numbers drift from panel position; existing tests pass | Not Started |
| S4-015 | S3-011 PauseMenu confirm dialog visual polish (centered title, no overlap with menu) | ui-programmer | 0.25 | None | F5: confirm dialog visually distinct from menu; YES/NO clearly aligned | Not Started |
| S4-016 | S3-012 onboarding hint visual (centered, larger font, doesn't overlap HUD) | ui-programmer + ux-designer | 0.25 | None | F5: room 0 first 10s shows hint at screen center, readable | Not Started |
| S4-017 | Add 1 boss (warden_construct) for chapter 2 final | level-designer + ai-programmer | 0.75 | S4-013 | Similar to S4-012 for chapter 2 | Not Started |

**Should Have total: ~3.5 days.** If Must takes 7, Should fits in 1-2 day buffer. If Must takes 8+, Should is cut.

### Nice to Have (cut first — defer to Sprint 5 polish or post-launch)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria | Status |
|----|------|-------------|-----------|-------------|-------------------|--------|
| S4-020 | HUD weapon slot highlight contrast tuning (S3-002 carryover "先这样吧") | ui-programmer | 0.1 | None | Visual only; F5 verify | Not Started |
| S4-021 | Real audio SFX (replace placeholder beeps with .wav or .ogg) | sound-designer | 1-2 | None | 6+ distinct SFX (attack/damage/UI/door/open/terminal/fragment); volume balanced | Not Started |
| S4-022 | Pixel art pass (replace ColorRect placeholders with real sprites) | art-director | 5-10 | None | Player + 3 enemy types + 2 NPCs + tileset + UI icons | Not Started |
| S4-023 | Localization scaffold (i18n keys extracted from hardcoded strings) | localization-lead | 1-2 | None | All user-facing strings in a strings table; switch language at runtime | Not Started |
| S4-024 | Tutorial / first-time player guidance overlay | ux-designer | 0.5 | None | First-time players see overlay explaining combat + inventory; skippable on subsequent runs | Not Started |

**Nice to Have: NOT planned for Sprint 4.** S4-022 (art) is the biggest variable for ship-readiness. If art is required, this becomes Sprint 5 priority and ship slips 2-4 weeks.

## Carryover from Sprint 3

| Original ID | Task | Reason for Carryover | New Estimate | Priority Change |
|------------|------|---------------------|-------------|----------------|
| HUD weapon slot highlight contrast | User said "先这样吧" on S3-002 | 0.1 day | Now S4-020 (Nice Have) |
| S3-010 SaveUI highlight | Sprint 3 cut | 0.5 day | **DONE** in S4 retro — carried forward into backlog after fc21 shipped |
| S3-011 PauseMenu confirm polish | Sprint 3 cut | 0.25 day | Now S4-015 (Should Have) |
| S3-012 Onboarding hint visual | Sprint 3 cut | 0.25 day | Now S4-016 (Should Have) |
| S2-005 fragment-count test | Sprint 2 carryover | 0.5 day | **DONE** in S4 retro — fc22 + DialogueManager per-node unlock shipped |
| Door TODO (locked + key) | User said "不用钥匙" | 0.1 day | **DONE** in S4 retro — fields removed (减法) |
| HiDPI sweep | Sprint 3 retro | 0.25 day | **DONE** — `docs/architecture/hidpi-sweep-2026-06-14.md` shipped |
| TerminalUI/CodexUI fragile geometry | Hidden in HiDPI sweep | 0.25 day | Now S4-014 (Should Have) |

## Risks to This Sprint

| Risk | Probability | Impact | Mitigation | Owner |
|------|------------|--------|-----------|------|
| S4-005 fragments + S4-006 NPCs require writing 6+ story arcs from scratch | High | Medium | Use "the convoy was family" arc as scaffold; writer fills in prose variations; if blocking, ship with 3 fragments and add remaining in Sprint 5 | writer |
| S4-007 auto-mode AI is open-ended (could be 0.5 day or 3 days) | High | High | Set minimal AC: "auto mode uses different slot per enemy weakness"; skip learning/adaptation; ship MVP that "looks like AI" | ai-programmer |
| S4-008 hidden rooms needs level redesign | Medium | Medium | Scope-limit to 1 hidden room in chapter 1; the system supports more, but only 1 is built | level-designer |
| S4-009 multiple endings requires all 6 fragments to be findable | Medium | High | Tie endings to fragment count thresholds (3/6/all) so partial content still works | narrative-director |
| User changes direction mid-sprint (as in Sprint 2 / 3) | Medium | High | Sprint plan is a contract; revisions allowed only with trade-off visible to user | producer |
| Sprint 4 test count grows beyond 25 (current 23) | Low | Low | S4 tests should be additive not replacing; new test per new feature | qa-tester |

## External Dependencies

| Dependency | Status | Impact if Delayed | Contingency |
|-----------|--------|------------------|-------------|
| User provides content direction (what 6 fragments say, what 3 NPCs do) | Pending | High — writer/narrative-director blocked | Use existing "convoy was family" arc from fragment_who_we_were.tres as template; auto-generate variations |
| User provides 1-2 boss designs | Pending | Medium | S4-012, S4-017 reuse marrow_sentinel template; new bosses are stat variations + flavor text |
| Godot 4.6.1 stable (current) | Confirmed | N/A | Already pinned in docs/engine-reference/godot/VERSION.md |
| Lint + F5 gate (S3-007) | Available | N/A | Use for all Must Have deliverables |

## Definition of Done (S3-007 enforced)

- [ ] All Must Have tasks completed (S4-001 through S4-010)
- [ ] **Each Must Have task has F5 verification log entry** in the Sprint 4 close report (use `.claude/docs/templates/sprint-close-report.md`)
- [ ] All tasks pass acceptance criteria (autotest + F5)
- [ ] Test suite PASS — current 23 scripts + new tests for S4 features (target: 25-27 scripts)
- [ ] No regression vs. Sprint 3 (existing fc1-fc23 still PASS)
- [ ] Lint guards PASS (indent + no-draw + 7 others = 9/9)
- [ ] No new TODOs introduced in src/
- [ ] Total content count meets at least 75% of target (so: weapons ≥ 8, enemies ≥ 8, NPCs ≥ 5, fragments ≥ 8, mech parts = 4, levels ≥ 2)
- [ ] Existing door lock-fields stay removed (fc23 regression test PASS)

## Sprint 5 Preview (Release Readiness)

- [ ] Public playtest (5-10 testers) + feedback integration
- [ ] Steam/Epic store page + assets
- [ ] Marketing trailer
- [ ] Bug bash + final regression
- [ ] Build pipeline (Win/Mac/Linux export)
- [ ] Certification checklist
- [ ] Final F5 on release build

Sprint 5 scope will be set after Sprint 4 completes and the actual ship-blocker delta is known.

## Recommended Sprint Start Order

1. **S4-001 + S4-002 (mech parts)** — foundation; small, fast, unblocks HUD
2. **S4-003 + S4-004 (weapons + enemies)** — content; parallel-safe
3. **S4-010 (plasma_burn ammo)** — small; do with S4-003
4. **S4-005 + S4-006 (fragments + NPCs)** — biggest content lift; do in parallel
5. **S4-007 (auto-mode AI)** — independent; can run while writer works
6. **S4-008 (hidden rooms)** — independent; can run late
7. **S4-009 (multiple endings)** — depends on S4-005 fragments being placed

S4-011 through S4-017 (Should Have) picked up in any remaining capacity, in any order.

S4-020 through S4-024 (Nice Have) — defer to Sprint 5 explicitly.

## Out of Scope (Explicitly)

- Marketing / store page work (Sprint 5)
- Real audio SFX (S4-021, Nice Have)
- Pixel art (S4-022, Nice Have) — **biggest ship risk if required**
- Localization (S4-023, Nice Have)
- New biome chapter 2 (S4-013, S4-017, Nice Have)
- Steam achievement integration
- Mod support
- Speedrun mode / leaderboard

If any of these become blocking, this sprint plan should be revised before sprint start.
