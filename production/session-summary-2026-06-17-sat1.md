# Sat-1 Content Session Summary — 2026-06-17

> **Status**: SAT-1 NO LONGER AN EMPTY SHELL
> **Date**: 2026-06-17
> **Author**: suxiu (player) + claude (assistant)
> **Achievement**: 4 NPC portraits + 4 dialogue trees + 7 truth fragments

---

## 1. What This Sprint Built

Sat-1 ("The Drift Wreck") was the only satellite with **zero content** —
chapter1.tres referenced it, but there were 0 NPCs, 0 enemies, 0
fragments, 0 dialogue trees. Sprint 15 fixes that:

| Story | Output | Files |
|---|---|---|
| S15-001 | 4 NPC portraits + 12 anim frames | 16 PNG |
| S15-002 | 4 NPC data .tres | 4 .tres |
| S15-003 | 4 dialogue trees | 4 .tres |
| S15-004 | 7 truth fragments | 7 .tres |
| S15-005 | fc80 tests + runner | 1 .gd + 1 line |
| S15-006 | This summary | 1 .md |

**6 commits, 32 new files.**

## 2. The 4 Sat-1 NPCs

| ID | Theme | Role | Lore |
|---|---|---|---|
| `ch1_derelict_captain` | weathered captain, gray hair, scar, gold rank bars | lore_keeper | "Twenty years of salvage, of cold, of counting crew." |
| `ch1_salvage_engineer` | grease-stained mechanic, yellow hardhat, round goggles | merchant | "Everything breaks. Everything can be fixed." |
| `ch1_frozen_cargo_tech` | blue-tinged skin from cold, frost on hood, icy eyes | lore_keeper | "We were carrying something worse than ourselves." |
| `ch1_marlow_first_mate` | grizzled veteran, eyepatch, scar, dark coat | quest_giver | "The inheritance is yours if you can get out of here alive." |

## 3. The 7 Sat-1 Truth Fragments

| # | Title | Importance | Author | Theme |
|---|---|---|---|---|
| 1 | Captain's Log, Day 0 | 1 | Captain D. Vance | "Forty-two crew aboard. Manifest shows generic salvage." |
| 2 | The Empty Manifest | 2 | First Mate Marlow | "The manifest is a lie. The convoy knew." |
| 3 | Forty-Two | 2 | Eng. R. Kowalski | "There are forty-three people on this ship." |
| 4 | The Cold | 3 | Cryo-Tech L. Park | "The cold isn't the weather. The cold is what's in the hold." |
| 5 | The Seals | 3 | Captain D. Vance | "Whatever's in the hold, it's not waiting anymore." |
| 6 | Marlow's Departure | 4 | Marlow (departure) | "Find me on Sat-2. I'll know the manifest is real." |
| 7 | The Inheritance | 5 | Marlow (final) | "苍穹号 — a pre-Rift vessel, intact, on the upper decks." |

## 4. Story Arc Connected

Sat-1 now connects to the rest of the campaign:
- **Chapter 1 (Sat-1)**: Marrow derelict, 4 NPCs, 7 fragments — **prologue**
- **Chapter 2 (Sat-2)**: Marlow is there, 3 quest givers, 7 fragments
- **Chapter 3 (Sat-3)**: 4 NPCs, 7 fragments
- **Chapter 4 (Sat-4)**: 4 NPCs, 7 fragments
- **Chapter 5 (Sat-5)**: 4 NPCs + 4 ghost parents, 7 fragments

**5 satellites × 7 fragments = 35 total truth fragments** (the 苍穹号 unlocking threshold).

## 5. Files Added

```
assets/sprites/npcs/
  ch1_derelict_captain.png (+ 3 anim frames)
  ch1_salvage_engineer.png (+ 3 anim frames)
  ch1_frozen_cargo_tech.png (+ 3 anim frames)
  ch1_marlow_first_mate.png (+ 3 anim frames)

data/npcs/
  ch1_derelict_captain.tres
  ch1_salvage_engineer.tres
  ch1_frozen_cargo_tech.tres
  ch1_marlow_first_mate.tres
  dlg_ch1_derelict_captain.tres
  dlg_ch1_salvage_engineer.tres
  dlg_ch1_frozen_cargo_tech.tres
  dlg_ch1_marlow_first_mate.tres

data/fragments/
  fragment_ch1_1.tres .. fragment_ch1_7.tres (7 files)

tools/
  gen_sat1_npc_portraits.py
  gen_sat1_fragments.py

tests/integration/
  fc80_sat1_content_test.gd (10 tests)

production/
  session-summary-2026-06-17-sat1.md (this file)
```

## 6. Test Coverage (10 tests)

```
PASS:  test_ch1_npc_portraits_base_files_exist
PASS:  test_ch1_npc_animation_frames_exist
PASS:  test_ch1_npc_tres_files_exist
PASS:  test_ch1_npcs_load_via_resource_registry
PASS:  test_ch1_dialogue_trees_exist
PASS:  test_ch1_dialogue_trees_have_start_node
PASS:  test_ch1_fragments_all_7_exist
PASS:  test_ch1_fragments_have_required_fields
PASS:  test_ch1_fragments_have_lore_content
PASS:  test_total_sat1_assets_at_least_30
```

**10/10 tests pass.** Updated tests/runners/sprint7_plus_runner.gd (25 test files, ~378 tests).

## 7. Cumulative Sprint 7-15 Numbers

| Metric | Sprint 7-14 | + Sprint 15 | Total |
|---|---|---|---|
| Stories shipped | 84 | 6 | **90** |
| Implementation sprints | 8 | 1 | **9** |
| New autoloads | 10 | 0 | **10** |
| Total commits this campaign | 45 | 6 | **51** |
| Total LOC added | ~15,900 | ~800 | **~16,700** |
| Total tests | ~368 | +10 | **~378** |
| PNG assets | 127 | +16 | **143** |
| Sat-1 NPCs | 0 | 4 | **4** |
| Sat-1 dialogue trees | 0 | 4 | **4** |
| Sat-1 fragments | 0 | 7 | **7** |
| Total fragments (5 sats × 7) | 28 | +7 | **35** |
| Sat-1 NPC anim frames | 0 | 12 | **12** |

## 8. What Sat-1 Still Needs (P1+)

- **Enemies** (Sat-1 has 0 — only the boss_marrow_sentinel exists in enemies/)
- **Terminal logs** (Sat-1 has 0 — ch3-5 have 4)
- **Side quests** (Sat-1 has 0 — Sat-2/3/4/5 have 12)
- **Bounty** (Sat-1 has 0 — ch2's Traitor's Legacy is plot-gated)
- **Room layouts** (chapter1.tres has room_ids c1_r1..c1_r10, but the rooms may not be built)

These are P1+ — Sat-1 is now narratively complete, just mechanically
sparse. Can be tackled in Sprint 16+.

## 9. Final State

- **Sat-1**: 4 NPCs, 4 dialogues, 7 fragments, 16 portrait files — **COMPLETE**
- **Cumulative**: 90 stories, 51 commits, ~16,700 LOC, ~378 tests
- **Build**: Windows .exe (104 MB) verified (from Sprint 14)
- **Fork**: Synced to `pvr6yxzcc9-web/Claude-Code-Game-Studios`

---

*Generated 2026-06-17 by Claude Sonnet 3.5 for the Railhunter Sat-1 content sprint.*
