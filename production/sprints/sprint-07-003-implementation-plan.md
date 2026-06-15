# S7-003 Implementation Plan — MechLoadout 4 Mechs + Swap

> **Sprint 7 Story**: S7-003 (1.5 days, godot-gdscript-specialist)
> **Depends on**: S7-002 (per-mech weapon slots) — each mech needs weapons + parts HP
> **Goal**: Refactor `src/autoload/mech_loadout.gd` from a **single-mech 5-part system** (torso / left_arm / right_arm / legs / core) to a **4-mech roster** (漫游者号 / 霜尾号 / 轰天号 / 苍穹号), each with its own parts HP. Default pilot-mech mapping per `party-system.md` §3.4.

## Current State (Baseline)

- **File**: `src/autoload/mech_loadout.gd` (97 lines)
- **Data model**: 1 global `parts: Dictionary` (5 slots: torso / left_arm / right_arm / legs / core), 1 `_cycle_index`
- **Stats**: `get_aggregated_stats()` returns hp_bonus / attack_bonus / defense_bonus from equipped parts
- **1 mech only** — no concept of multiple mechs in the roster

## Target State (After S7-003)

- **Data model**: **4 mechs** in a roster. Each mech has its own parts HP (head / chest / arms / legs, **4 parts per mech**, total 16 parts)
- **4-mech roster**: `&"ranger_mech"`, `&"frostbite_mech"`, `&"bomber_mech"`, `&"cangqiong_mech"`
- **Default pilot mapping**: 漫游者 → ranger_mech, 霜尾 → frostbite_mech, 轰天 → bomber_mech, 苍穹号 is unlocked late-game and not a 4th pilot
- **Active mech** selection (s7-001's `_state.active_mech_index` references this)
- **Mech swap**: `set_active_mech(mech_id)` swaps the active mech
- **Save/load**: Per-mech parts HP saved

## File Changes (Summary)

| File | Lines added | Lines removed | Net |
|------|-------------|---------------|-----|
| `src/autoload/mech_loadout.gd` | +150 | -50 | +100 |
| `data/schemas/mech_data.gd` (NEW) | +90 | 0 | +90 |
| `tests/integration/fc61_mech_swap_test.gd` (NEW) | +80 | 0 | +80 |

**Total**: ~320 lines added, ~50 lines removed. **Net: +270 lines** across 3 files.

---

## Sub-Task Breakdown (Days 1-1.5)

### Day 1 Morning: Data Model

**Sub-task 1.1: Create `data/schemas/mech_data.gd`** (0.25 day)

A new resource type for one mech:

```gdscript
# data/schemas/mech_data.gd
class_name MechData
extends Resource

# Identity
var mech_id: StringName = &""  # &"ranger_mech", etc.
var display_name: String = ""
var class_type: StringName = &"infantry"  # infantry/cavalry/artillery/legendary

# 4 parts HP
var head_hp: int = 100
var chest_hp: int = 100
var arms_hp: int = 100
var legs_hp: int = 100
var max_head_hp: int = 100
var max_chest_hp: int = 100
var max_arms_hp: int = 100
var max_legs_hp: int = 100

# Stats
var mobility: int = 3
var armor: int = 3
var firepower: int = 3

# Special module (1 slot for non-legendary, 2 for 苍穹号)
var module_ids: Array[StringName] = [&""]

# Reference to weapon loadout (S7-002's MechLoadout for this mech)
# The weapon loadout is stored separately in WeaponLoadout._mech_loadouts
```

**Why a new file**: Each mech is a self-contained resource. 4 instances in the game.

**Sub-task 1.2: Refactor `mech_loadout.gd` to hold 4 mechs** (0.5 day)

Replace the global `parts` with:

```gdscript
# In mech_loadout.gd (after refactor)
const ROSTER: Array[StringName] = [&"ranger_mech", &"frostbite_mech", &"bomber_mech", &"cangqiong_mech"]
const DEFAULT_PILOT_MAPPING: Dictionary = {
    &"ranger": &"ranger_mech",
    &"frostbite": &"frostbite_mech",
    &"bomber": &"bomber_mech",
}

var _mechs: Dictionary = {}  # mech_id (StringName) → MechData
var _active_mech_id: StringName = &"ranger_mech"
var _cangqiong_unlocked: bool = false  # false until Ch13 inheritance

# New methods
func register_mech(mech_id: StringName) -> MechData
func get_mech(mech_id: StringName) -> MechData
func get_active_mech() -> MechData
func set_active_mech(mech_id: StringName) -> void
func unlock_cangqiong() -> void  # called in S7-008
```

The old methods (`equip_part`, `cycle_equipped_part`, etc.) are **deprecated** but kept for backward compat. They delegate to the active mech.

### Day 1 Afternoon: Combat Integration

**Sub-task 1.3: HUD integration** (0.25 day)

The HUD (already shows weapon slots, per S6-008) needs to show **mech-specific HP** (4 parts per active mech, not 5 parts for one mech). The HUD reads `_mech_loadout.get_active_mech()` and displays the 4 parts HP.

**Sub-task 1.4: Combat integration with S7-001's `_state.party_mechs`** (0.25 day)

S7-001's `BattleState.party_mechs` references the mech's HP. The HP is read from `MechLoadout._mechs[mech_id].{head,chest,arms,legs}_hp`. Damage in combat updates the mech's parts HP. Knocked-out mechs (all 4 parts at 0) are removed from combat.

**Sub-task 1.5: 4-part death rule** (0.25 day)

Per `party-system.md` §3.5:
- **Head at 0 HP**: -50% accuracy, crits deal +100% damage
- **Chest at 0 HP**: total HP cap halved, all parts' HP capped at 50%
- **Arms at 0 HP**: cannot attack, pilot abilities disabled
- **Legs at 0 HP**: cannot move (skips movement phase)
- **All 4 at 0**: mech is "destroyed" — pilot is knocked out, falls back to next mech in order

### Day 1.5: Tests + Verification

**Sub-task 1.6: Tests fc61_mech_swap_test.gd** (0.5 day)

6 tests covering the new mech system:
- 1) 4 mechs are registered in the roster
- 2) 3 mechs are unlocked by default; 苍穹号 is locked until unlock_cangqiong() is called
- 3) set_active_mech changes the active mech
- 4) Each mech has 4 parts HP (head/chest/arms/legs)
- 5) Damage to a mech's parts HP reduces the part's HP, with debuffs applied at 0
- 6) Save/Load roundtrip preserves all 4 mechs' state

---

## Code Patterns to Reuse (from existing codebase)

| Pattern | Existing location | Reuse for S7-003 |
|--------|-------------------|------------------|
| Signal-based events | `part_equipped.emit(slot, part_id)` | Reuse pattern, but per-mech |
| Resource lookup | `ResourceRegistry.get_resource(mech_id)` | Same |
| Save format | `get_state_snapshot()` / `load_snapshot(snap)` | Extend, don't replace |
| HP bar rendering | `hud.gd` `_hp_fill` | Reuse the pattern for 4 parts per mech |
| Hit flash | `battle_scene.gd` `_flash_enemy()` | Reuse for mech hit feedback |

## Risks Specific to S7-003

1. **The 5-part → 4-part rename**: The current code has 5 slots (torso, left_arm, right_arm, legs, core). The new code has 4 slots (head, chest, arms, legs). The slot names change. This breaks any code that references the old slot names.
   - **Mitigation**: Search the codebase for `&"torso"`, `&"left_arm"`, `&"right_arm"`, `&"core"` and rename. Document the rename in the sprint close report.

2. **苍穹号 unlock timing**: The 苍穹号 is locked until Ch13 inheritance. The game must work without 苍穹号 from Ch1-Ch12. Verify the 4-mech roster is correctly initialized (3 mechs unlocked, 1 locked) and 苍穹号 is not accidentally used in early-game combat.

3. **Save format migration**: Old saves have 1 mech (5 parts). New saves have 4 mechs (4 parts each). S7-010 (save/load) handles this, but the migration is non-trivial. Test with old saves.

4. **Pilot-mech mapping**: The default mapping is hard-coded. What if the user wants to swap pilots to different mechs in Mech Bay? S7-007 handles this (Mech Bay menu). S7-003 just provides the data model + default mapping.

## Out of Scope (for S7-003 only)

- Mech Bay menu UI (S7-007)
- Pilot assignment UI (S7-007)
- 苍穹号 inheritance cutscene (S7-008)
- Save/load versioning (S7-010)
- Pilot-specific abilities in combat (S7-001 + S7-011)

## Acceptance Test (Manual F5 Verification)

1. Start a new game, F5.
2. Open the Mech Bay menu (M key) — see S7-007. Should show 3 mechs (Ranger / Frostbite / Bomber), 苍穹号 should be locked.
3. Switch active mech (1/2/3 keys in Mech Bay) — the HUD updates to show the new mech's 4 parts HP.
4. Enter combat (encounter tile). Trigger an attack.
5. The combat uses the active mech's HP. Damage is taken on the active mech.
6. Reduce the active mech's head HP to 0 — the mech now has -50% accuracy (visual indicator: head HP bar grayed out).
7. Reduce all 4 parts to 0 — the mech is "destroyed," pilot is knocked out.
8. Pilot falls back to the next mech in the roster.
9. Reach Ch13 (or trigger debug command for Ch13 inheritance) — 苍穹号 is unlocked and added to the roster.
10. Switch to 苍穹号 in Mech Bay — 4 weapon slots are visible (vs 3 for other mechs).

If all 10 steps work, S7-003 is complete.
