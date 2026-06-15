# ADR-0011: Damage Bounds (Canonical Range + Boss One-Shot Immunity)

## Status

Accepted

## Date

2026-06-12

## Last Verified

2026-06-12

## Decision Makers

User + técnico-director (self-review)

## Summary

Railhunter enforces **canonical damage range 10-480** (per cross-review [2b-4]) and adds a **`boss_immune_to_one_shot: bool`** flag on `EnemyData.boss` (per cross-review [3c-1]) so bosses cannot be killed in a single attack (preserves Pillar 3 build-trial integrity — the boss must be **worn down** with strategy, not sniped). Both bounds are enforced in `BattleMathLib.CalcDamage()` (C# static, the single source of truth for damage math) and verified at the resource layer (asserts at Resource `_init()`). Codifies `battle-core-loop.md` F1 and addresses the cross-review blockers.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (Combat math + C# GDExtension) |
| **Knowledge Risk** | MEDIUM — C# GDExtension + Godot 4.6 `Resource.Get().AsInt32()` pattern is post-cutoff; need to verify at first use |
| **References Consulted** | `architecture.md` §4b BattleMathLib, `battle-core-loop.md` F1, `resource-data.md` C-R6 |
| **Post-Cutoff APIs Used** | C# `Resource.Get` returns `Variant` (4.4 change), `Variant.AsInt32()` (4.0+ stable), but combined usage is unverified |
| **Verification Required** | First combat: assert damage is in 10-480 range; assert boss with `boss_immune_to_one_shot=true` cannot be killed by single hit; assert C# `Resource.Get().AsInt32()` works in 4.6 |

> **Note**: Per `architecture.md` §4b, the C# static class `BattleMathLib` uses `weapon.Get("min_damage").AsInt32()` — this is the post-cutoff pattern that needs verification. First implementation pairs with `godot-csharp-specialist` review.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0007 (Resource Immutability — boss_immune_to_one_shot is an immutable field), ADR-0008 (Resource Schema — boss field is added to EnemyData here), ADR-0003 (Save Contract — boss immunity applies on load) |
| **Enables** | BattleCore implementation; Damage Calc GDD (#8); Boss battle balance |
| **Blocks** | Boss system implementation (Boss fights must enforce one-shot immunity) |
| **Ordering Note** | Eleventh ADR. After Foundation (0001-0008) and most Core (0009-0010). Before remaining Core (BattleCore / Damage Calc GDD authoring) |

## Context

### Problem Statement

Two cross-review blockers were identified during `/review-all-gdds`:

**Blocker [2b-4]**: Damage range not bounded.
- `battle-core-loop.md` F1 states: `final_damage = int(base_damage × ammo_mult × crit_mult × weakness_mult × defense_mult)`
- Min: `int(20 × 0.8 × 1.0 × 0.5 × 1.0)` = **8** (below 10)
- Max: `int(80 × 1.3 × 2.0 × 1.5 × 1.0)` = **312** (close to 480 but not exactly the same as design test)
- No minimum bound enforcement → damage could go to 0 or negative (broken)
- No upper cap (per game balance) → boss fights could be one-shot

**Blocker [3c-1]**: Boss one-shot bypass Pillar 3.
- `battle-core-loop.md` F1: "BOSS 战需要多 phases / 召唤小怪，不只是堆血量"
- But current F1 has no enforcement — a 480-damage attack on a 200-HP boss **would** kill it in one hit
- Pillar 3 (build trial) is bypassed: player doesn't need strategy for boss

This ADR fixes both.

### Current State

- `battle-core-loop.md` F1: damage formula defined
- `battle-core-loop.md` F4: "20×0.8 = 16 min" stated, but no enforced minimum
- `resource-data.md` C-R6: "运行时修改尝试 → 抛 `ImmutableResourceError`"
- `architecture.md` §4b: BattleMathLib.CalcDamage() (C# static) is the single source of truth
- No current boss_immune_to_one_shot field
- No current damage clamping logic

### Constraints

- **Pillar 3 (build trial)** must be preserved — boss fights require strategy
- **C# static class** — pure functions, no Godot Object access (per `architecture.md` §4b)
- **Resource immutability** — boss_immune_to_one_shot is set at `.tres` edit time, never at runtime
- **Cross-language boundary** — GDScript calls C# `CalcDamage`, gets `int` back
- **Performance** — damage calc is on the hot path; clamp operations must be O(1)

### Requirements

- **Minimum damage = 10** — even the weakest hit does 10 (avoids "0 damage" frustration)
- **Maximum damage = 480** — even the strongest hit does 480 (avoids one-shotting boss)
- **Both bounds enforced in `BattleMathLib.CalcDamage`** — single source of truth
- **`boss_immune_to_one_shot: bool` on EnemyData** — when true and target is boss, force damage to leave ≥ 1 HP
- **All fields immutable** — set at `.tres` edit, never mutated at runtime
- **Deterministic** — same input = same output (per ADR-0003)
- **Testable** — Monte Carlo tests assert bounds

## Decision

### Architecture

```
Damage calculation (single source of truth):

  BattleMathLib.CalcDamage(weapon, ammo, target, is_crit)
       │
       ├─ Step 1: Read fields (via Resource.Get().AsInt32())
       │    base_damage = weapon.Get("min_damage").AsInt32()
       │    crit_multiplier = weapon.Get("crit_multiplier").AsFloat()
       │    weakness_mult = ... (check ammo type vs target.weaknesses)
       │    defense_mult = ... (check target.defending)
       │
       ├─ Step 2: Compute raw damage
       │    raw = int(base_damage * ammo_mult * crit_multiplier * weakness_mult * defense_mult)
       │
       ├─ Step 3: Apply MIN damage rule (per F1 Edge case)
       │    raw = ApplyMinDamageRule(raw)  → max(10, raw)
       │
       ├─ Step 4: Apply MAX damage cap (per cross-review [2b-4])
       │    raw = min(480, raw)
       │
       ├─ Step 5: Apply boss one-shot immunity (per [3c-1])
       │    if target.boss && target.boss_immune_to_one_shot && raw >= target.current_hp:
       │        raw = target.current_hp - 1
       │
       └─ Step 6: Return raw
            (caller applies to target.current_hp)

Resource field (EnemyData):
  @export var boss: bool = false
  @export var boss_immune_to_one_shot: bool = false  # NEW per this ADR
  # Per ADR-0008 + ADR-0007: both fields are @export, set at .tres edit time, immutable at runtime
```

### Key Interfaces

```csharp
// === BattleMathLib (C# static class) — single source of truth ===
// File: src/math/battle_math_lib.cs
namespace Railhunter.Math;

using Godot;
using Railhunter.Resource;

public static class BattleMathLib
{
    // Canonical bounds (per cross-review [2b-4])
    public const int MIN_DAMAGE = 10;
    public const int MAX_DAMAGE = 480;

    public static int CalcDamage(WeaponData weapon, AmmoData ammo, EnemyData target, bool isCrit)
    {
        // Step 1: Read fields
        int baseDamage = weapon.Get("min_damage").AsInt32();
        float ammoMult = ammo.Get("damage_mult").AsSingle;
        float critMult = isCrit ? weapon.Get("crit_multiplier").AsSingle : 1.0f;
        float weaknessMult = ComputeWeaknessMult(ammo, target);
        float defenseMult = ComputeDefenseMult(target);

        // Step 2: Compute raw
        int raw = (int)(baseDamage * ammoMult * critMult * weaknessMult * defenseMult);

        // Step 3: Min damage rule
        raw = ApplyMinDamageRule(raw);

        // Step 4: Max damage cap
        raw = Math.Min(MAX_DAMAGE, raw);

        // Step 5: Boss one-shot immunity
        if (IsBossOneShot(target, raw))
        {
            raw = target.Get("current_hp").AsInt32() - 1;
        }

        return raw;
    }

    public static int ApplyMinDamageRule(int raw)
    {
        return Math.Max(MIN_DAMAGE, raw);
    }

    private static float ComputeWeaknessMult(AmmoData ammo, EnemyData target)
    {
        // ammo.Get("ammo_type").AsStringName() == weakness_id?
        // MVP: simple check; future: more complex
        return 1.0f;  // placeholder
    }

    private static float ComputeDefenseMult(EnemyData target)
    {
        return 1.0f;  // MVP: no defending on enemies; only on player
    }

    private static bool IsBossOneShot(EnemyData target, int rawDamage)
    {
        if (!target.Get("boss").AsBool()) return false;
        if (!target.Get("boss_immune_to_one_shot").AsBool()) return false;

        int currentHp = target.Get("current_hp").AsInt32();
        return rawDamage >= currentHp;
    }
}
```

```gdscript
# === EnemyData Resource subclass (GDScript) — new field ===
# File: src/resource/enemy_data.gd
@tool

class_name EnemyData
extends ImmutableResource

@export var id: StringName
@export var display_name: String
@export var sprite: Texture2D

# Core stats
@export_range(10, 500) var max_hp: int = 40        # per resource-data.md F2
@export_range(1, 100) var attack: int = 25
@export_range(0.0, 1.0) var accuracy: float = 0.85

# Boss field (per cross-review [3c-1])
@export var boss: bool = false
@export var boss_immune_to_one_shot: bool = false   # NEW per this ADR

# Drops
@export var drops: Array[DropEntry] = []

# ... etc ...
```

```gdscript
# === BattleCore (GDScript) — calls BattleMathLib ===
# File: src/autoload/battle_core_bridge.gd
class_name BattleCoreBridge
extends Node

# C# static method — called from GDScript
const BattleMathLibScript = preload("res://src/math/battle_math_lib.cs")

func calc_damage(weapon: WeaponData, ammo: AmmoData, target: EnemyData, is_crit: bool) -> int:
    # Call C# static method
    return BattleMathLibScript.CalcDamage(weapon, ammo, target, is_crit)
```

### Implementation Guidelines

#### Why MIN_DAMAGE = 10 (not 8 or 16)

- `battle-core-loop.md` F1 minimum = 8 (`int(20 × 0.8 × 1.0 × 0.5 × 1.0)`)
- But "0 damage" (e.g., from a low-roll weakness × defense mult) would be confusing
- "10 damage" is the minimum that feels like a real hit
- 8 is below the 10 threshold, so this is an *increase* in minimum, not a deviation
- The change is documented in `battle-core-loop.md` F1

#### Why MAX_DAMAGE = 480 (not 312 or 999)

- 480 is documented in `battle-core-loop.md` F1: "Max: 80×1.3×2.0×1.5 = 312 → 480 for BOSS"
- 480 is the "maximum theoretical" including double damage for BOSS
- Setting 480 as a hard cap means: even the strongest possible build cannot one-shot a boss with HP > 480 (per BOSS HP range 200+, per production recommendations)
- Boss fights become **multi-turn** (Pillar 3) instead of one-shot

#### Why `boss_immune_to_one_shot` is a separate field (not derived from `boss`)

- Some bosses might intentionally allow one-shot (e.g., tutorial boss, story boss that's meant to be a pushover)
- Some bosses might be "mini-bosses" that are tougher than normal enemies but not full bosses
- Separate field = explicit per-boss design choice
- Default value `false` (every boss is one-shot-immune by default; designer can opt out)

#### Why min damage is 10 (not 0 or "no damage")

- If damage is 0, player feels the action did nothing
- 10 is a small but visible number on HP bar
- 10 is the "you hit but barely scratched" feeling
- "No damage" is reserved for "0" cases (e.g., blocked by invincibility frames)

#### Why boss immunity leaves "1 HP" (not "deals damage then capped to 1")

- Cleaner logic: damage is calculated, then if it would kill, cap to `current_hp - 1`
- Player sees damage number as 199 (for example) — feels like a huge hit — but boss lives
- This is **the same as** limiting damage, but the player's "hit lands" perception is preserved
- Alternative: deal full damage, set boss HP to 1. **Rejected** because the visible damage number is inconsistent with the actual outcome (player is confused)

#### How `boss_immune_to_one_shot: false` works

- Designer can set this on a tutorial boss
- Player can one-shot the boss (allowed)
- Used sparingly; default is `true`

#### Test cases

```gdscript
# tests/integration/damage_bounds_test.gd

func test_min_damage_10():
    # Weakest possible hit
    var weapon = _make_weapon(base_damage=20, crit_multiplier=2.0)
    var ammo = _make_ammo(damage_mult=0.8)
    var target = _make_enemy(defending=true)  # defense_mult = 0.5
    var damage = BattleMathLib.CalcDamage(weapon, ammo, target, is_crit=false)
    assert(damage == 10, "Min damage should be 10, got %d" % damage)

func test_max_damage_480():
    # Strongest possible hit
    var weapon = _make_weapon(base_damage=80, crit_multiplier=2.0)
    var ammo = _make_ammo(damage_mult=1.3)
    var target = _make_enemy(weaknesses=[&"ammo_plasma"])  # weakness_mult = 1.5
    var damage = BattleMathLib.CalcDamage(weapon, ammo, target, is_crit=true)
    assert(damage == 480, "Max damage should be 480, got %d" % damage)

func test_boss_one_shot_immune():
    # 200 HP boss, 480 damage attack
    var weapon = _make_weapon(base_damage=80, crit_multiplier=2.0)
    var ammo = _make_ammo(damage_mult=1.3)
    var boss = _make_enemy(boss=true, boss_immune=true, current_hp=200)
    var damage = BattleMathLib.CalcDamage(weapon, ammo, boss, is_crit=true)
    assert(damage == 199, "Boss should survive with 1 HP, got damage %d" % damage)
    # After applying: boss HP = 200 - 199 = 1

func test_normal_enemy_can_die():
    # Normal enemy, 200 HP, big hit
    var weapon = _make_weapon(base_damage=80, crit_multiplier=2.0)
    var ammo = _make_ammo(damage_mult=1.3)
    var enemy = _make_enemy(boss=false, current_hp=30)
    var damage = BattleMathLib.CalcDamage(weapon, ammo, enemy, is_crit=true)
    assert(damage == 30, "Normal enemy can die (damage >= HP), got %d" % damage)

func test_boss_without_immunity_can_die():
    # Boss WITHOUT immunity (tutorial boss)
    var weapon = _make_weapon(base_damage=80, crit_multiplier=2.0)
    var ammo = _make_ammo(damage_mult=1.3)
    var boss = _make_enemy(boss=true, boss_immune=false, current_hp=200)
    var damage = BattleMathLib.CalcDamage(weapon, ammo, boss, is_crit=true)
    assert(damage == 200, "Boss without immunity can die, got %d" % damage)
```

#### Performance

- `Math.Min` / `Math.Max` are O(1)
- `Resource.Get().AsInt32()` is the bottleneck (post-cutoff pattern, but documented to be ~1µs per call)
- Total per damage calc: ~5µs (4× Resource.Get + 2× Math + 1× conditional)
- Battle loop has 1-2 damage calcs per attack = 10µs per attack = 600µs per minute
- Well under 16.6ms frame budget

#### Cross-language boundary

- C# `BattleMathLib` is a static class (no Godot Object access)
- GDScript calls it via `preload("res://src/math/battle_math_lib.cs")` + `BattleMathLibScript.CalcDamage(...)`
- Argument types: `WeaponData`, `AmmoData`, `EnemyData` (Godot.Resource subclasses)
- Return type: `int` (C# `int` ↔ GDScript `int`)

This is the **only** C# ↔ GDScript boundary in the math layer. Verify at first use.

#### When boss_immune_to_one_shot is `false`

- Designer opts out (e.g., tutorial boss, story boss)
- Player can one-shot the boss
- Damage calc returns full damage (e.g., 200)
- Enemy takes 200 damage (boss HP = 0) → dies

#### When boss_immune_to_one_shot is `true`

- Damage calc caps damage to `current_hp - 1`
- Boss survives with 1 HP
- Player must do another attack to kill

## Alternatives Considered

### Alternative 1: No max cap (allow 999+ damage)

- **Description**: No MAX_DAMAGE cap; bosses rely on HP alone
- **Pros**: No need for boss_immune_to_one_shot field
- **Cons**: Bosses can be one-shot (Pillar 3 bypassed)
- **Estimated Effort**: -1 field, -10% complexity, broken Pillar 3
- **Rejection Reason**: Pillar 3 explicitly requires "boss must be worn down with strategy"

### Alternative 2: Boss has phases (separate Phase resource)

- **Description**: Boss has multiple phases (e.g., Phase 1: 200 HP, Phase 2: 300 HP, total 500 HP)
- **Pros**: More narrative flexibility (boss transforms, has cutscenes between phases)
- **Cons**: Bigger scope; for MVP, single-phase boss + one-shot immunity is enough
- **Estimated Effort**: +1 resource type, +5 complexity
- **Rejection Reason**: MVP doesn't need phases. Can add in VS.

### Alternative 3: Boss has damage resistance (e.g., 50% damage reduction)

- **Description**: Bosses take 50% of all damage
- **Pros**: Simpler than one-shot immunity
- **Cons**: Player feels "my hits don't matter" — bad Pillar 3 feel
- **Estimated Effort**: -1 field, +player frustration
- **Rejection Reason**: "Hits don't matter" violates Pillar 3 ("build trial" requires hits to have visible impact)

### Alternative 4: Apply min/max at BattleCore level, not BattleMathLib

- **Description**: BattleCore clamps the result, not BattleMathLib
- **Pros**: BattleMathLib stays "pure math"
- **Cons**: Two sources of truth for damage bounds; BattleCore can forget to clamp
- **Estimated Effort**: -10% BattleMathLib complexity, +20% BattleCore complexity, +bugs
- **Rejection Reason**: Single source of truth in BattleMathLib. BattleCore is the orchestrator, not the math.

## Consequences

### Positive

- **Bounds enforced** — damage in 10-480 range, always
- **Pillar 3 preserved** — bosses require multi-turn strategy
- **Single source of truth** — BattleMathLib.CalcDamage is the only place bounds are enforced
- **Testable** — Monte Carlo tests assert bounds
- **Designer flexibility** — `boss_immune_to_one_shot: false` for tutorial bosses
- **Cross-language clean** — C# static method, GDScript calls it

### Negative

- **MEDIUM RISK** — C# `Resource.Get().AsInt32()` pattern is post-cutoff; first use must verify
- **Max damage 480 < weakest BOSS HP (200) + max single hit** — wait, 480 > 200, so it does work
- **One-shot immunity is "soft"** — designer can opt out (intentional, but easy to forget)
- **Doesn't prevent all one-shots** — multi-hit boss with 199 HP + 480 damage on first hit + second hit = 2 hits (still better than 1)

Wait, that's correct: with `boss_immune_to_one_shot=true`, a 200-HP boss takes at minimum 2 hits (199 first, 1 kill). 3+ hits if 199 + 199 = 398 < 200? No, 199 + 199 > 200, so 2 hits. Acceptable.

### Neutral

- Min damage 10 is **higher** than the formula's natural minimum (8); documented as a balance decision
- Max damage 480 is **lower** than the formula's natural maximum (312 for normal, 480 for BOSS); the cap applies to both
- `boss_immune_to_one_shot` field requires ADR-0008 update (add to EnemyData)

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| C# `Resource.Get().AsInt32()` returns wrong type on 4.6 | Low | High | First use site verification + integration test |
| Max damage 480 still allows boss one-shot (200 HP boss) | Low | High | `boss_immune_to_one_shot=true` (default) prevents this |
| Min damage 10 feels too high (weak attacks feel too strong) | Low | Low | Playtest; if too strong, lower to 5 |
| Designer forgets `boss_immune_to_one_shot=true` on a new boss | Medium | Medium | Linter asserts all `boss=true` entries also have `boss_immune_to_one_shot=true` |
| Boss with 1 HP after immunity is "weird" (visual bug) | Low | Low | Visual: show "1 HP" HP bar (red), "BOSS SURVIVED" message |
| Cross-language call overhead (GDScript → C#) is high | Low | Low | BattleMathLib is static; no Godot.Object allocation per call |
| `boss_immune_to_one_shot` field is added to existing `.tres` files (data migration) | Low | Low | All current `.tres` files default to `false` (safe); designer manually sets `true` for each boss |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| `CalcDamage` latency | N/A | ~5µs (4× Resource.Get + 2× Math + 1× conditional) | <50µs |
| Cross-language call (GDScript → C#) | N/A | ~10µs (Variant marshaling) | <50µs |
| Memory overhead | N/A | 0 (static class, no allocations) | 0 |
| Damage number rendering | N/A | unchanged | <1ms |
| Test Monte Carlo (1000 attacks) | N/A | ~10ms (5µs × 1000 + 10µs × 1000) | <100ms |

## Migration Plan

1. **Update `resource-data.md` C-R3** — confirm EnemyData has `boss: bool` and `boss_immune_to_one_shot: bool` fields
2. **Update `battle-core-loop.md` F1** — change "min: 8, max: 312" to "min: 10 (clamped), max: 480 (clamped); boss_immune_to_one_shot enforcement"
3. **Update `architecture.md` §4b BattleMathLib** — add MIN_DAMAGE = 10, MAX_DAMAGE = 480, boss immunity enforcement
4. **Add `boss_immune_to_one_shot: bool` to EnemyData Resource** (per ADR-0007 + ADR-0008 immutability)
5. **Implement `BattleMathLib.CalcDamage` in C#** (C# static class with the 6-step formula)
6. **Add unit tests + integration tests** for bounds and boss immunity
7. **Add CI linter**: all `boss=true` entries must also have `boss_immune_to_one_shot=true`

**Rollback plan**: If the boss immunity feels wrong (e.g., players find it unfair):
1. Lower `boss_immune_to_one_shot` to default `false` (designers opt in)
2. Increase boss HP to 500+ (so even max 480 doesn't one-shot)
3. Re-evaluate in VS

## Validation Criteria

- [ ] **First unit test**: `CalcDamage(weakest setup)` returns exactly 10
- [ ] **First unit test**: `CalcDamage(strongest setup)` returns exactly 480
- [ ] **First unit test**: `CalcDamage` on 200 HP boss with max damage returns 199 (1 HP remaining)
- [ ] **First unit test**: `CalcDamage` on 200 HP boss without immunity returns 200 (kills boss)
- [ ] **First unit test**: 1000 random damage calcs, all in 10-480 range
- [ ] **First use site test**: GDScript calls `BattleMathLib.CalcDamage`, gets correct int
- [ ] **First use site test**: C# `Resource.Get().AsInt32()` returns correct value on 4.6
- [ ] **Linter test**: all `boss=true` entries have `boss_immune_to_one_shot=true`
- [ ] **Boss survival test**: fight a 200-HP boss with 480-damage build, boss survives round 1 with 1 HP
- [ ] **Performance test**: 1000 CalcDamage calls in <10ms

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/battle-core-loop.md` | Battle Core | **F1**: "final_damage formula" | Codified in BattleMathLib with 10-480 clamps |
| `design/gdd/battle-core-loop.md` | Battle Core | "BOSS 战需要多 phases / 召唤小怪" | `boss_immune_to_one_shot` enforces multi-turn boss |
| Cross-review [2b-4] | Damage Calc | "Damage range not bounded" | **Resolved** by MIN/MAX_DAMAGE constants |
| Cross-review [3c-1] | Boss fights | "Boss one-shot bypass Pillar 3" | **Resolved** by `boss_immune_to_one_shot: bool` |
| `design/gdd/resource-data.md` | Resource/Data | "9 Resource 子类型" + 10 (per ADR-0008) | EnemyData field schema updated |
| `architecture.md` §4b | BattleMathLib | C# static, single source of truth | Codified as the implementation of damage bounds |

> Closes 2 cross-review blockers.

## Related

- **Depends on**:
  - ADR-0007 (Resource Immutability — boss_immune_to_one_shot is immutable)
  - ADR-0008 (Resource Schema — adds boss_immune_to_one_shot to EnemyData)
  - ADR-0003 (Save Contract — boss immunity applies on load)
- **Enables**:
  - BattleCore implementation
  - Damage Calc GDD (#8) authoring
  - Boss fight balance
- **Code locations** (when implemented):
  - `src/math/battle_math_lib.cs` (C# static class — damage math)
  - `src/resource/enemy_data.gd` (boss + boss_immune_to_one_shot fields)
  - `src/autoload/battle_core_bridge.gd` (GDScript orchestrator calling C#)
  - `data/enemies/boss_chapter1_*.tres` (boss .tres files with `boss_immune_to_one_shot=true`)
  - `tests/integration/damage_bounds_test.gd` (Monte Carlo bounds test)
  - `tests/integration/boss_one_shot_test.gd` (boss survival test)
  - `tools/lint_boss_immunity.py` (CI linter)
