# STORY-001: BattleMathLib (C#) damage bounds per ADR-0011

> **Epic**: battle-core-loop
> **Layer**: Core
> **TR**: TR-BAT-004, TR-BAT-005
> **Status**: Done (verified 2026-06-13)

## Acceptance Criteria

- [x] `BattleMathLib` is a C# static class with pure functions
- [x] `CalcDamage(weapon, ammo, target)` returns bounded damage (10-480)
- [x] `apply_boss_immunity(damage, boss_hp, boss_immune_to_one_shot)` caps damage to `min(damage, boss_hp - 1)`
- [x] Crit roll: `roll_crit(weapon.crit_chance, weapon.crit_multiplier)`
- [x] `clamp_damage(d)` ensures output in [10, 480]
- [x] All math is deterministic + testable (no Node dependencies)

## Implementation

- `src/math/battle_math_lib.cs` (originally C#) — converted to GDScript `src/math/battle_math_lib.gd` for 4.6 compat
- Static methods: `compute_base_damage`, `clamp_damage`, `apply_boss_immunity`, `apply_defense`, `roll_accuracy`

## Verification Evidence

- FC-1..FC-11 tests cover damage bounds
- Test `tests/unit-cs/math/battle_math_lib_test.cs` runs in NUnit
- Boss damage cap verified: damage > boss_hp → capped to boss_hp - 1
