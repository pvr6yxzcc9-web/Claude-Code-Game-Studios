# 3v1 Battle Prototype (Sprint 7-001 MVP)

> **Status**: Prototype (NOT production code)
> **Created**: 2026-06-16
> **Author**: suxiu + claude
> **Purpose**: Verify the 3-pilot + 1-enemy combat loop works before committing to the full S7-001 implementation.

## What This Is

A **minimal viable prototype** of the 3v1 combat system specified in `design/gdd/party-system.md` §3.7. This prototype:

- ✅ Tests the **3-pilot data model** (3 mechs in a roster)
- ✅ Tests **1/2/3 key switching** between mechs
- ✅ Tests the **3-pilot per round** economy (each mech gets 1 turn, then enemy attacks)
- ✅ Tests **HP tracking** (mech and enemy)
- ✅ Tests **active mech highlighting** (visual UI)
- ❌ Does NOT test weapons, ammo, parts, pilot abilities, town clinic, save/load, Mech Bay

This prototype **overlays** on top of the existing 1v1 BattleScene — it doesn't replace it. Both can coexist.

## How to Use

### Option 1: Run the prototype standalone (recommended for testing)

1. Open `src/main.tscn` in the Godot editor
2. Add a new node: `Control` with the script `res://src/battle/_prototype_3v1.gd`
3. Or use the provided scene: `res://src/battle/_prototype_3v1.tscn`
4. Save and run the project (F5)
5. In any state, press **T** to start a test battle
6. Use the controls below

### Option 2: Add to the existing main scene

1. Open `src/main.tscn` in the Godot editor
2. Instance the scene `res://src/battle/_prototype_3v1.tscn` as a child of the root
3. Run the project (F5)

## Controls

| Key | Action |
|-----|--------|
| **T** | Start a test battle (works in any state) |
| **1** | Switch active mech to slot 1 (漫游者) |
| **2** | Switch active mech to slot 2 (霜尾) |
| **3** | Switch active mech to slot 3 (轰天) |
| **SPACE** | Active mech attacks the enemy (1 attack per turn) |
| **ESC** | End the test battle |

## What to Verify

When you run the prototype, verify these design assumptions:

1. **3-pilot combat feels right**: Each round, all 3 mechs can attack before the enemy attacks once. Does this feel like the "found family" fantasy, or does it feel slow?
2. **1/2/3 key switching is intuitive**: Can you switch between mechs mid-combat without confusion?
3. **Active mech highlighting is clear**: Is the yellow border enough, or does it need more visual weight?
4. **Enemy attacks 1 mech per round**: This is the "many vs one" tempo. Does it feel tense or trivial?
5. **Defeating a mech switches to the next**: When 漫游者 (active) is defeated, does the prototype auto-switch to 霜尾? (Test by reducing 漫游者's HP via repeated enemy attacks.)

## What This Prototype Does NOT Do

The following are **deferred** to the full S7-001 implementation:

- Weapons / ammo (S7-002) — currently the attack is a fixed 20-30 damage
- 4 parts HP per mech (S7-003) — currently each mech has 1 total HP
- Pilot abilities (S7-001 + S7-011) — no 霜尾's Flank or 轰天's Iron Wall
- Weapons loadout per mech (S7-002)
- HUD with 3-4 mech bars (S7-004)
- Save/Load (S7-010)
- Town clinic revival (S7-006)
- Mech Bay menu (S7-007)
- Dialogue companion swap (S7-005)
- 苍穹号 inheritance (S7-008)
- Auto mode 3-pilot AI (S7-011)

## After Testing

Once you've tested the prototype, **report back**:

1. **Does the 3-pilot per round tempo feel right?**
   - Too slow (each mech attacking individually is tedious)?
   - Too fast (no strategy needed)?
   - Just right (squad coordination matters)?

2. **Is the active mech highlighting clear?**
   - Yes, obvious
   - Could be better (need bigger border, sound effect, etc.)
   - Not clear at all

3. **Does the "many vs one" enemy attack work?**
   - Yes, feels tense
   - Too easy (enemy attacks 1 of 3 mechs = trivial)
   - Too hard (1 mech can't survive)

4. **Any bugs / crashes during testing?**
   - Note which scenario

5. **Time spent testing** (rough estimate)

Based on the feedback, the full S7-001 implementation can adjust:
- Combat tempo (number of mechs per round)
- Active mech visual feedback
- Enemy attack frequency
- Any bug fixes

## Files

- `src/battle/_prototype_3v1.gd` — 323 lines, the prototype script
- `src/battle/_prototype_3v1.tscn` — 16 lines, the prototype scene (optional)
- `src/battle/_prototype_3v1_README.md` — this file

## Why an Underscore Prefix?

The `_prototype_` prefix follows the existing codebase convention (e.g., `_unhandled_input` for internal methods). It signals that this is **not production code** and can be removed once the full S7-001 is implemented.

When the full S7-001 is done, delete these 3 files.
