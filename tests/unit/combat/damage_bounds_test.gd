extends GutTest

# Unit test: Damage Bounds (per ADR-0011 + battle-core-loop.md F1)
# Verifies that BattleMathLib static methods enforce MIN=10, MAX=480, and
# boss one-shot immunity.

func test_clamp_damage_below_min() -> void:
    assert_eq(BattleMathLib.clamp_damage(5), 10, "below MIN clamps to 10")
    assert_eq(BattleMathLib.clamp_damage(-100), 10, "negative clamps to 10")
    assert_eq(BattleMathLib.clamp_damage(0), 10, "zero clamps to 10")

func test_clamp_damage_above_max() -> void:
    assert_eq(BattleMathLib.clamp_damage(481), 480, "above MAX clamps to 480")
    assert_eq(BattleMathLib.clamp_damage(9999), 480, "very large clamps to 480")

func test_clamp_damage_in_range() -> void:
    assert_eq(BattleMathLib.clamp_damage(10), 10, "MIN boundary preserved")
    assert_eq(BattleMathLib.clamp_damage(480), 480, "MAX boundary preserved")
    assert_eq(BattleMathLib.clamp_damage(150), 150, "mid value unchanged")
    assert_eq(BattleMathLib.clamp_damage(240), 240, "mid value unchanged")

func test_compute_base_damage_within_bounds() -> void:
    # Various weapon/ammo/crit combos — all should land in [10, 480]
    for i in 50:
        var wmin: int = randi_range(20, 80)
        var wmax: int = wmin + randi_range(0, 40)
        var ammo_mult: float = randf_range(0.5, 1.5)
        var is_crit: bool = (i % 3) == 0
        var crit_mult: float = 2.0 if is_crit else 1.0
        var dmg: int = BattleMathLib.compute_base_damage(wmin, wmax, ammo_mult, is_crit, crit_mult)
        assert_true(dmg >= 10 and dmg <= 480, "computed damage %d in [10, 480]" % dmg)

func test_apply_boss_immunity_blocks_one_shot() -> void:
    # Boss with 200 HP, immune to one-shot
    var damage: int = 480
    var result: int = BattleMathLib.apply_boss_immunity(damage, 200, true)
    # Cap = 200 * 50% = 100
    assert_eq(result, 100, "boss immune one-shot capped to 50% max HP")

func test_apply_boss_immunity_allows_under_cap() -> void:
    # Damage below boss HP — not a one-shot, no reduction
    var damage: int = 50
    var result: int = BattleMathLib.apply_boss_immunity(damage, 200, true)
    assert_eq(result, 50, "sub-one-shot damage passes through unchanged")

func test_apply_boss_immunity_disabled() -> void:
    # Boss without immunity — full damage allowed
    var damage: int = 480
    var result: int = BattleMathLib.apply_boss_immunity(damage, 200, false)
    assert_eq(result, 480, "non-immune boss takes full damage")

func test_apply_defense_basic() -> void:
    # 100 damage, 50 defense → 50% reduction → 50 damage
    var result: int = BattleMathLib.apply_defense(100, 50)
    assert_eq(result, 50, "50 defense halves 100 damage")

func test_apply_defense_caps_at_75_percent() -> void:
    # 100 damage, 1000 defense → would be 900% reduction, capped at 75% → 25 damage
    var result: int = BattleMathLib.apply_defense(100, 1000)
    assert_eq(result, 25, "defense reduction capped at 75% (100 → 25)")

func test_apply_defense_minimum_one() -> void:
    # 1 damage, 1000 defense → would be 0.25, floor to 0, but minimum 1
    var result: int = BattleMathLib.apply_defense(1, 1000)
    assert_eq(result, 1, "defense mitigation floors at 1 damage (1 dmg × 0.25 = 0.25 → 0 → max 1)")

func test_apply_defense_zero() -> void:
    var result: int = BattleMathLib.apply_defense(100, 0)
    assert_eq(result, 100, "0 defense = no reduction")
