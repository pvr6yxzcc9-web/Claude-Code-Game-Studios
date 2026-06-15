# S7-002 Implementation Plan — WeaponLoadout Pilot-Mech Decoupling

> **Sprint 7 Story**: S7-002 (3 days, godot-gdscript-specialist)
> **Depends on**: S7-001 (BattleScene 3v1 data model) — the new `_state.party_mechs` is the data source
> **Goal**: Refactor `src/autoload/weapon_loadout.gd` from a **single-pilot 3-slot weapon system** to a **mech-mounted, multi-pilot weapon system**. Each mech has its own 3-4 weapon slots; weapons are mounted on mechs (not pilots); any pilot can use any mech's weapons.

## Current State (Baseline)

- **File**: `src/autoload/weapon_loadout.gd` (209 lines)
- **Data model**: 1 global `weapon_slots: Array[StringName]` (3 slots), 1 `ammo_slots`, 1 `active_slot`
- **Trigger**: `trigger_attack(slot)` is called from `BattleScene.on_player_attack(slot)`
- **Auto mode**: 1-pilot auto-attack loop
- **No concept of "per-mech" weapons** — all 3 slots belong to "the player"

## Target State (After S7-002)

- **Data model**: **Per-mech weapon slots**. Each mech has its own `Array[StringName]` of 3-4 weapon IDs
- **Active mech context**: The "active slot" refers to the **active mech's** slots, not a global slot
- **Pilot-independence**: Any pilot can fire any mech's weapons (weapons don't care who's driving)
- **Cross-pilot weapons**: A weapon equipped on Mech A can be used by Pilot X, Y, or Z
- **Save format**: Weapons are saved **per mech** (not per pilot)

## File Changes (Summary)

| File | Lines added | Lines removed | Net |
|------|-------------|---------------|-----|
| `src/autoload/weapon_loadout.gd` | +180 | -80 | +100 |
| `data/schemas/mech_loadout.gd` (NEW) | +120 | 0 | +120 |
| `data/schemas/weapon_slot.gd` (NEW) | +40 | 0 | +40 |
| `tests/integration/fc60_weapon_decoupling_test.gd` (NEW) | +100 | 0 | +100 |

**Total**: ~440 lines added, ~80 lines removed. **Net: +360 lines** across 4 files.

---

## Sub-Task Breakdown (Days 1-3)

### Day 1: Data Model — Per-Mech Slots

**Sub-task 1.1: Create `data/schemas/mech_loadout.gd`** (0.5 day)

A new resource type that holds one mech's weapons + ammo + parts:

```gdscript
# data/schemas/mech_loadout.gd
class_name MechLoadout
extends Resource

# 3 weapon slots (4 for 苍穹号)
var weapon_slots: Array[StringName] = [&"", &"", &""]
var ammo_slots: Array[StringName] = [&"", &"", &""]
var active_slot: int = 0

# 4 parts HP
var head_hp: int = 100
var chest_hp: int = 100
var arms_hp: int = 100
var legs_hp: int = 100

# Special module
var module_id: StringName = &""

# Max weapon slots (3 or 4)
var max_weapon_slots: int = 3
```

**Why a new file**: Separates mech data from pilot data. Multiple mechs in the party each have their own `MechLoadout` instance.

**Sub-task 1.2: Create `data/schemas/weapon_slot.gd`** (0.25 day)

A simple value type for a single weapon slot:

```gdscript
# data/schemas/weapon_slot.gd
class_name WeaponSlot
extends Resource

var weapon_id: StringName = &""
var ammo_id: StringName = &""
var is_locked: bool = false  # some weapons require certain pilots
var charge_uses: int = 0  # for special weapons with limited uses
```

**Sub-task 1.3: Refactor `weapon_loadout.gd` to hold a dict of mech loadouts** (0.75 day)

Replace the global `weapon_slots` with:

```gdscript
# In weapon_loadout.gd (after refactor)
var _mech_loadouts: Dictionary = {}  # mech_id (StringName) → MechLoadout
var _active_mech_id: StringName = &""

# New methods
func register_mech(mech_id: StringName, max_weapon_slots: int = 3) -> void
func get_mech_loadout(mech_id: StringName) -> MechLoadout
func get_active_mech_loadout() -> MechLoadout
func set_active_mech(mech_id: StringName) -> void
func equip_weapon_to_mech(mech_id: StringName, slot: int, weapon_id: StringName) -> void
func equip_ammo_to_mech(mech_id: StringName, slot: int, ammo_id: StringName) -> void
```

The old methods (`equip_weapon(slot, weapon_id)`, etc.) are kept as **convenience wrappers** that delegate to the active mech:

```gdscript
func equip_weapon(slot: int, weapon_id: StringName) -> void:
    equip_weapon_to_mech(_active_mech_id, slot, weapon_id)
```

This is **backward compatible** — existing callers of `equip_weapon` still work.

### Day 2: Trigger Logic + Save/Load

**Sub-task 2.1: Update `trigger_attack(slot)` to use active mech** (0.5 day)

The new `trigger_attack` reads the **active mech's** weapon slot:

```gdscript
func trigger_attack(slot: int) -> void:
    var loadout: MechLoadout = get_active_mech_loadout()
    if loadout == null:
        return  # no active mech
    var weapon_id: StringName = loadout.weapon_slots[slot]
    if weapon_id == &"":
        return  # empty slot
    # ... rest of attack logic (existing)
```

**Key change**: The function no longer reads from a global `weapon_slots`. It reads from the active mech's loadout.

**Sub-task 2.2: Cross-pilot weapon usage** (0.5 day)

Weapons don't care which pilot is using them. The `trigger_attack` function **doesn't reference the pilot** — it only uses the mech's weapons. The pilot's abilities (e.g., 霜尾's Flank) are separate, triggered by `BattleScene` (S7-001's data model) using the **pilot_id** from `_state.party_mechs[active_mech_index]`.

**Sub-task 2.3: Save/Load for per-mech weapons** (0.5 day)

Update `get_state_snapshot()` and `load_snapshot()`:

```gdscript
func get_state_snapshot() -> Dictionary:
    var mechs: Dictionary = {}
    for mech_id in _mech_loadouts:
        var loadout: MechLoadout = _mech_loadouts[mech_id]
        mechs[mech_id] = {
            "weapon_slots": loadout.weapon_slots.duplicate(),
            "ammo_slots": loadout.ammo_slots.duplicate(),
            "active_slot": loadout.active_slot,
            "head_hp": loadout.head_hp,
            "chest_hp": loadout.chest_hp,
            "arms_hp": loadout.arms_hp,
            "legs_hp": loadout.legs_hp,
            "module_id": loadout.module_id,
        }
    return {
        "active_mech_id": _active_mech_id,
        "mechs": mechs,
    }
```

The save format change is handled by S7-010 (which already includes save versioning per the roadmap adjustments).

**Sub-task 2.4: Auto mode (1-pilot) still works for legacy 1v1 fights** (0.5 day)

The `legacy_1v1_mode` flag (from S7-001) is also relevant here. When on, the active mech is hard-coded to `&"ranger_mech"`, and the old 1-pilot logic applies. When off, the new 3-pilot logic applies.

### Day 3: Mech Bay Menu + Tests

**Sub-task 3.1: Mech Bay menu hookup** (0.5 day)

S7-007 (Mech Bay menu) needs to read/write per-mech weapons. The new `equip_weapon_to_mech` and `equip_ammo_to_mech` are the entry points. S7-007 will use these.

**Sub-task 3.2: Tests fc60_weapon_decoupling_test.gd** (0.5 day)

8 tests covering the new weapon system:
- 1) Each mech has its own weapon_slots
- 2) Active mech is settable
- 3) equip_weapon_to_mech changes only the specified mech's slot
- 4) trigger_attack uses the active mech's slot, not a global slot
- 5) Cross-pilot: Pilot A in Mech X can use Mech X's weapons
- 6) Save/Load roundtrip preserves per-mech weapons
- 7) Switching active mech changes which weapons are "active"
- 8) Legacy 1v1 mode still works (backward compat)

---

## Code Patterns to Reuse (from existing codebase)

| Pattern | Existing location | Reuse for S7-002 |
|--------|-------------------|------------------|
| Resource loading | `ResourceRegistry.get_resource(weapon_id)` | Same — works for new weapons |
| Attack signal | `attack_triggered(slot_index)` | Same signal, but now scoped to active mech |
| Auto mode timer | `AUTO_INTERVAL_SEC` constant | Reuse, but with new active-mech context |
| Save snapshot pattern | `get_state_snapshot()` | Extend, don't replace |
| State restore pattern | `load_snapshot(snap)` | Extend, don't replace |

## Risks Specific to S7-002

1. **Backward compatibility with old saves**: Old saves have a global `weapon_slots` array. The new format has per-mech slots. S7-010 (save/load) handles this, but S7-002 must be **savvy**:
   - On load, if the old format is detected, migrate to the new format (assign old weapons to `ranger_mech`)
   - This is a one-line migration; should not fail

2. **Cross-pilot weapon usage might break the existing damage formula**: The current `BattleMathLib` doesn't reference the pilot. After S7-002, it still doesn't. But the **pilot's stats** (e.g., crit bonus from 漫游者's "精准打击") might apply to attacks regardless of which mech is active. Verify in tests.

3. **Weapon abilities that target enemies by position**: Some weapons have AOE. The AOE target is independent of pilot. So a weapon equipped on 漫游者号 can be fired by 霜尾 (when she's driving 漫游者号), and the AOE works the same. Verify in tests.

4. **The "active slot" semantics change**: In the old code, `active_slot` was a global index. In the new code, it's an index **within the active mech's slots**. The signal `weapon_changed(slot_index, weapon_id)` should still work, but the `slot_index` is now 0-3 (per active mech) instead of 0-2 (global).

## Out of Scope (for S7-002 only)

- Pilot ability execution (S7-001 + S7-011)
- Mech-specific weapon abilities (S7-014)
- AOE / friendly fire logic (S7-014)
- Save versioning (S7-010)

## Acceptance Test (Manual F5 Verification)

1. Start a new game, F5.
2. Open the Mech Bay menu (M key) — see S7-007.
3. Equip a weapon in Mech 1's slot 1.
4. Switch to Mech 2 (1/2/3 keys in Mech Bay) — Mech 2's slot 1 should be empty (or have its own weapon).
5. Switch back to Mech 1 — slot 1 still has the weapon.
6. Save the game.
7. Quit, reload.
8. Mech 1's slot 1 still has the weapon.
9. Trigger an attack (E key in combat) — the attack uses the active mech's weapon.
10. Switch pilots (Tab key in combat) — the attack still uses the mech's weapon, but pilot abilities are different.

If all 10 steps work without crash or wrong weapon firing, S7-002 is complete.
