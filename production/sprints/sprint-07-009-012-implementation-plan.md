# S7-009, S7-010, S7-011, S7-012 Combined Implementation Plans

> **Purpose**: This document combines the remaining 4 Sprint 7 stories into one consolidated plan. S7-009 (combat formulas), S7-010 (save/load party state), S7-011 (auto mode 3-pilot AI), and S7-012 (tests fc59-fc66) are the **finishers** of Sprint 7 — they don't introduce new player-facing systems, but they make the new party system **playable and testable**.

---

## S7-009 — Combat Formulas (Dodge / Hit / Crit / Damage / XP / Revival)

> **Sprint 7 Story**: S7-009 (0.5 day, systems-designer + godot-gdscript-specialist)
> **Goal**: Implement the 7 combat formulas from `party-system.md` §4 in `BattleMathLib` (C#). Adds new constants and helper functions. Must be **backward compatible** with existing 1v1 fights.

### Current State

- **File**: `src/math/battle_math_lib.cs` (C# static math)
- **Existing functions** (assumed): `compute_base_damage()`, `apply_weakness_resistance()`, `apply_boss_immunity()` (per the existing `battle_scene.gd` call sites)
- **No dodge / hit / crit / XP / revival formulas yet** — these are NEW in Sprint 7

### Target State

- All 7 formulas from `party-system.md` §4 implemented as static functions
- Backward compat: existing 1v1 calls still work
- New helper functions: `compute_dodge_chance()`, `compute_hit_chance()`, `compute_crit_chance()`, `compute_xp_to_next_level()`, `compute_revival_cost()`

### File Changes

| File | Lines added | Net |
|------|-------------|-----|
| `src/math/battle_math_lib.cs` | +120 | +120 |
| `tests/integration/fc59_formulas_test.gd` | +60 | +60 |

**Total**: +180 lines across 2 files.

### Formulas (per `party-system.md` §4)

#### F1. Dodge

```csharp
public static float ComputeDodgeChance(
    int pilotLevel, float equipDodgeBonus, float passiveSkillBonus, float mechDodgeBonus)
{
    float base = 0.10f;
    float levelBonus = pilotLevel * 0.02f;
    float raw = base + levelBonus + equipDodgeBonus + passiveSkillBonus + mechDodgeBonus;
    return Math.Min(raw, 0.80f);  // MAX_DODGE_CAP = 0.80
}
```

#### F2. Hit

```csharp
public static float ComputeHitChance(
    float baseHit, float attackerAccuracy, float weaponAccuracy,
    float targetDodge, int distance, bool targetInCover)
{
    float distancePenalty = distance * 0.05f;  // 5% per tile
    float coverBonus = targetInCover ? 0.05f : 0.0f;
    float raw = baseHit + attackerAccuracy + weaponAccuracy - targetDodge - distancePenalty - coverBonus;
    return Math.Clamp(raw, 0.05f, 0.95f);  // MIN_HIT 5%, MAX_HIT 95%
}
```

#### F3. Crit

```csharp
public static float ComputeCritChance(
    float baseCrit, float pilotCritBonus, float weaponCritBonus, float ammoCritBonus)
{
    float raw = baseCrit + pilotCritBonus + weaponCritBonus + ammoCritBonus;
    return Math.Clamp(raw, 0.0f, 1.0f);
}
```

#### F4. Damage

```csharp
public static int ComputeFinalDamage(
    int weaponMinDmg, int weaponMaxDmg, float ammoMult,
    float weaknessMult, float critMult, bool isCrit, int targetArmor)
{
    Random rng = new Random();
    int baseDmg = rng.Next(weaponMinDmg, weaponMaxDmg + 1);
    float withAmmo = baseDmg * ammoMult;
    float withWeakness = withAmmo * weaknessMult;
    float withCrit = isCrit ? withWeakness * critMult : withWeakness;
    int final = (int)Math.Max(withCrit - targetArmor, 1);  // minimum 1 damage
    return final;
}
```

#### F5. XP

```csharp
public static int ComputeXPToNextLevel(int currentLevel)
{
    const int BASE_XP = 100;
    return (int)(BASE_XP * Math.Pow(currentLevel, 1.5));
}
```

#### F6. Revival Cost

```csharp
public static int ComputeRevivalCost(int currentGold)
{
    int cost = (int)Math.Floor(currentGold * 0.25f);
    return Math.Max(cost, 100);  // 25% of gold, minimum 100
}
```

#### F7. Mech Part Damage

```csharp
public static int ComputeMechPartDamage(int incomingDmg, float partArmorMult, int partArmor)
{
    return Math.Max(0, (int)(incomingDmg * partArmorMult) - partArmor);
}
```

### Acceptance Test

1. F1: Lv 1, no equipment → 12% dodge (and 3-turn safety net documented separately)
2. F2: Distance 0, no cover → 95% hit (clamped)
3. F3: All crits at 100% → 100% crit
4. F4: 0 damage weapon → minimum 1 damage
5. F5: Lv 2 → 283 XP; Lv 10 → 3,162 XP
6. F6: 50 gold → 100 (clamped); 1000 gold → 250
7. F7: 0 HP part → no negative damage

---

## S7-010 — Save/Load Party State (with Migration)

> **Sprint 7 Story**: S7-010 (2 days, godot-gdscript-specialist)
> **Goal**: Extend the existing save format to include party state (3 pilots, 4 mechs, weapons, gold, levels). Implement save versioning for migrations from old saves.

### Current State

- **File**: `src/autoload/save_manager.gd` (192 lines)
- **14 producer namespaces** (after S7-006 adds clinic)
- **SAVE_VERSION_CURRENT = 1**
- **No versioning migrations** yet

### Target State

- Save format version bumped to **v2** (includes party state)
- Migration function `_upgrade_snapshot` actually does work (v1 → v2)
- Per-mech state preserved across save/load
- Per-pilot state preserved
- Gold state preserved (per S7-006)
- 14 producer namespaces updated

### File Changes

| File | Lines added | Net |
|------|-------------|-----|
| `src/autoload/save_manager.gd` | +50 | +50 |
| `src/autoload/mech_loadout.gd` (S7-003) | +30 | +30 |
| `src/autoload/weapon_loadout.gd` (S7-002) | +20 | +20 |
| `src/autoload/clinic_manager.gd` (S7-006) | +20 | +20 |
| `tests/integration/fc60_save_load_test.gd` | +80 | +80 |

**Total**: +200 lines across 5 files.

### Save Format (v2)

```gdscript
# In save_manager.gd
const SAVE_VERSION_CURRENT: int = 2  # bumped from 1

func _upgrade_snapshot(snap: Dictionary, from: int, to: int) -> Dictionary:
    if from == to:
        return snap
    if from == 1 and to == 2:
        # Migration v1 → v2: add party state
        snap["party"] = _default_party_state_v2()
        # Add cangqiong_unlocked (always false for migrated saves)
        snap["mech_loadout"] = snap.get("mech_loadout", {})
        snap["mech_loadout"]["cangqiong_unlocked"] = false
        # Add per-pilot states
        snap["clinic"] = snap.get("clinic", {})
        snap["clinic"]["pilot_states"] = {"ranger": "ACTIVE", "frostbite": "ACTIVE", "bomber": "ACTIVE"}
        snap["save_version"] = 2
    return snap

func _default_party_state_v2() -> Dictionary:
    return {
        "ranger": {"level": 1, "xp": 0, "abilities": []},
        "frostbite": {"level": 1, "xp": 0, "abilities": [], "recruited": false},
        "bomber": {"level": 1, "xp": 0, "abilities": [], "recruited": false},
        "active_pilot": "ranger",
    }
```

### Per-Mech Snapshot

```gdscript
# In mech_loadout.gd (S7-003)
func get_state_snapshot() -> Dictionary:
    var mechs: Dictionary = {}
    for mech_id in _mechs:
        var m: MechData = _mechs[mech_id]
        mechs[mech_id] = {
            "head_hp": m.head_hp,
            "chest_hp": m.chest_hp,
            "arms_hp": m.arms_hp,
            "legs_hp": m.legs_hp,
            "pilot_id": m.pilot_id,
            "module_ids": m.module_ids.duplicate(),
        }
    return {
        "schema_version": 2,
        "mechs": mechs,
        "active_mech_id": _active_mech_id,
        "cangqiong_unlocked": _cangqiong_unlocked,
    }

func load_snapshot(snap: Dictionary) -> Error:
    if "mechs" in snap:
        for mech_id in snap["mechs"]:
            if not _mechs.has(mech_id):
                continue
            var m: MechData = _mechs[mech_id]
            var data: Dictionary = snap["mechs"][mech_id]
            m.head_hp = data.get("head_hp", m.max_head_hp)
            m.chest_hp = data.get("chest_hp", m.max_chest_hp)
            m.arms_hp = data.get("arms_hp", m.max_arms_hp)
            m.legs_hp = data.get("legs_hp", m.max_legs_hp)
            m.pilot_id = data.get("pilot_id", m.pilot_id)
    if "active_mech_id" in snap:
        _active_mech_id = snap["active_mech_id"]
    if "cangqiong_unlocked" in snap:
        _cangqiong_unlocked = snap["cangqiong_unlocked"]
    return OK
```

### Acceptance Test

1. Save with 3 pilots in party, 4 mechs, 100 gold → load → state preserved
2. Save v1 (old format) → load → triggers v1 → v2 migration, default party state created
3. Save v1 → load → cangqiong_unlocked = false (correct default for migrated)
4. Save v2 (current format) → load → no migration needed
5. Save with 苍穹号 unlocked → load → cangqiong_unlocked = true, 4 mechs in roster
6. Save file size: ~3-5 KB (vs 1 KB v1)

---

## S7-011 — Auto Mode 3-Pilot AI

> **Sprint 7 Story**: S7-011 (2 days, ai-programmer)
> **Goal**: Extend Auto mode to handle 3 pilots + 4 mechs. Currently Auto mode only auto-picks actions for 1 pilot.

### Current State

- **File**: `src/autoload/weapon_loadout.gd` (existing `set_auto_mode`, `is_auto_mode`, `AUTO_INTERVAL_SEC`)
- **Existing Auto mode**: auto-triggers attack with the best weapon for the active pilot
- **1-pilot only** — does NOT handle 3 pilots

### Target State

- Auto mode auto-picks actions for **each of the 3 pilots** in sequence (within a single round)
- AI considers: pilot abilities (e.g., 霜尾's Flank), mech slot count, weapon AOE radius
- "Pause Auto" hotkey (P) lets the player intervene mid-turn
- AI difficulty: "good but not optimal" (give Manual a 10-20% advantage)

### File Changes

| File | Lines added | Net |
|------|-------------|-----|
| `src/autoload/auto_mode_ai.gd` (NEW) | +200 | +200 |
| `src/autoload/weapon_loadout.gd` (existing) | +20 | +20 |
| `tests/integration/fc61_auto_mode_test.gd` | +60 | +60 |

**Total**: +280 lines across 3 files.

### Auto Mode AI Loop

```gdscript
# src/autoload/auto_mode_ai.gd
extends Node

const AUTO_INTERVAL_SEC: float = 1.2

var _auto_mode: bool = false
var _auto_timer: SceneTreeTimer

signal auto_action_executed(pilot_id: StringName, action: String, target_id: StringName)
signal auto_turn_complete(pilot_id: StringName)

func start_auto_mode() -> void:
    _auto_mode = true
    _run_auto_loop()

func stop_auto_mode() -> void:
    _auto_mode = false
    if _auto_timer != null:
        _auto_timer.timeout.disconnect(_run_next_action)

func _run_auto_loop() -> void:
    var state: Node = get_node("/root/BattleState")
    while _auto_mode and state.phase == &"player":
        # Iterate through pilots in order
        for i in state.party_mechs.size():
            if not _auto_mode:
                return
            var mech: Dictionary = state.party_mechs[i]
            if mech.pilot_id in state.mechs_acted_this_round:
                continue
            if mech.current_hp <= 0:
                continue
            await get_tree().create_timer(AUTO_INTERVAL_SEC).timeout
            if not _auto_mode:
                return
            _execute_ai_action(mech)
        # All pilots acted → end round
        return
```

### AI Action Selection

```gdscript
func _execute_ai_action(mech: Dictionary) -> void:
    var pilot_id: StringName = mech.pilot_id
    var target: StringName = _pick_target(mech)
    var weapon_slot: int = _pick_weapon_slot(mech, target)

    # Pilot-specific AI
    match pilot_id:
        &"ranger":
            # 漫游者: balanced, prefer high-damage weapons
            _execute_attack(mech, weapon_slot, target)
        &"frostbite":
            # 霜尾: prefer flanking (target weakest enemy)
            var weakest: StringName = _find_weakest_enemy()
            _execute_attack(mech, weapon_slot, weakest)
        &"bomber":
            # 轰天: prefer AOE (multi-target)
            _execute_aoe_attack(mech, weapon_slot)

    auto_action_executed.emit(pilot_id, "attack", target)
    auto_turn_complete.emit(pilot_id)
```

### Acceptance Test

1. Enable Auto mode in combat → AI takes over for 3 pilots
2. Each pilot attacks the appropriate target (Frostbite targets weakest, Bomber uses AOE)
3. Disable Auto mode (P key) → control returns to player
4. Manual mode is 10-20% more effective than Auto (per `party-system.md` §3.7)
5. Save/Load roundtrip preserves auto_mode state

---

## S7-012 — Tests fc59-fc66 (8 test files)

> **Sprint 7 Story**: S7-012 (0.5 day, qa-tester)
> **Goal**: Add 8 new integration test files, each covering one AC from `party-system.md` §8.

### Current State

- **532 existing tests pass** (Sprint 6 baseline)
- **Test framework**: GUT (Godot Unit Test)
- **Existing test files**: fc1-fc58, plus sprint1_runner

### Target State

- **8 new test files**: fc59, fc60, fc61, fc62, fc63, fc64, fc65, fc66
- **All pass**: 532 + 8 = 540 tests
- Each test covers one Acceptance Criterion from `party-system.md` §8

### File Changes

| File | Lines added |
|------|-------------|
| `tests/integration/fc59_battle_3v1_test.gd` | +60 |
| `tests/integration/fc60_save_load_test.gd` | +80 |
| `tests/integration/fc61_auto_mode_test.gd` | +60 |
| `tests/integration/fc62_hud_3mech_test.gd` | +70 |
| `tests/integration/fc63_dialogue_companion_test.gd` | +80 |
| `tests/integration/fc64_clinic_revive_test.gd` | +60 |
| `tests/integration/fc65_mech_bay_test.gd` | +70 |
| `tests/integration/fc66_cangqiong_inheritance_test.gd` | +70 |

**Total**: +550 lines across 8 files.

### Test Coverage (per `party-system.md` §8 ACs)

| AC | Test File | What It Verifies |
|----|-----------|------------------|
| AC1. Three-pilot party | fc59 | 3 pilots exist, all player-controlled, Ranger always in party |
| AC2. Mech acquisition | fc60 | 4 mechs in roster after Ch13 inheritance |
| AC3. Free mech switching | fc59 | 1/2/3/4 keys + Tab work mid-combat |
| AC4. Combat turn structure | fc59 | 1 enemy turn + N party turns, only 1 enemy attacks |
| AC5. 苍穹号 pilot lock | fc66 | 苍穹号 refuses non-Ranger pilots |
| AC6. Dodge formula | fc59 | 12% at Lv 1, 80% cap, 3-turn safety net |
| AC7. Damage formula | fc59 | min 1 damage, weakness ×2, crit ×1.5-2.5 |
| AC8. Revival system | fc64 | non-main knockouts send to clinic, Ranger death = game over |
| AC9. Mech durability | fc59 | 4 parts HP, debuffs at 0 |
| AC10. In-dialogue companion | fc63 | Shift+1/2/3 swaps companion |
| AC11. Mech Bay menu | fc65 | M key opens, shows all 4 mechs |
| AC12. Trust/affinity | (deferred) | Not in this sprint |

### Acceptance Test

1. Run `tests/runners/regression_runner.gd` (existing) — 532 existing tests still pass
2. Run new fc59-fc66 — 8 new tests pass
3. Total: 540 tests pass (100%)

---

## Combined Sprint 7 Summary (S7-001 through S7-012)

| Story | Status | Days |
|-------|--------|------|
| S7-001 BattleScene 1v1 → 3v1 | ✅ Plan (sprint-07-001 plan + 3v1 prototype) | 3 |
| S7-002 WeaponLoadout pilot-mech decoupling | ✅ Plan (sprint-07-002) | 3 |
| S7-003 MechLoadout 4 mechs | ✅ Plan (sprint-07-003) | 1.5 |
| S7-004 HUD 3-4 mech bars | ✅ Plan (sprint-07-004) | 1.5 |
| S7-005 Dialogue companion swap | ✅ Plan (sprint-07-005) | 1.5 |
| S7-006 Town clinic revival | ✅ Plan (sprint-07-006) | 1.5 |
| S7-007 Mech Bay menu | ✅ Plan (sprint-07-007) | 2 |
| S7-008 苍穹号 inheritance | ✅ Plan (sprint-07-008) | 1.5 |
| S7-009 Combat formulas | ✅ Plan (this doc) | 0.5 |
| S7-010 Save/Load | ✅ Plan (this doc) | 2 |
| S7-011 Auto mode 3-pilot AI | ✅ Plan (this doc) | 2 |
| S7-012 Tests fc59-fc66 | ✅ Plan (this doc) | 0.5 |
| **Total** | | **20.5 days** |

**Capacity**: 22.4 days (4 weeks × 80% utilization, per the roadmap adjustments). **Buffer: 1.9 days** — healthy.

**After Sprint 7**: 540 tests pass, 4 mechs, 3 pilots, 1 inheritance cutscene, 1 town clinic, 1 mech bay menu. **Foundation for Sprint 8-11 is complete**.
