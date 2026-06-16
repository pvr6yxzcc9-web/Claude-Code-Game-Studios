extends GutTest

# Integration test: BattleMathLib combat formulas (S7-009, fc59)
# Per party-system.md §4 + sprint-07-009 plan
# Verifies the 7 formulas F1-F7:
#   F1: Dodge (12% at Lv 1, capped 80%)
#   F2: Hit (95% clamped at no-penalty)
#   F3: Crit (clamped 0..1)
#   F4: Final damage (min 1, weakness/crit multipliers)
#   F5: XP to next level (100 × level^1.5)
#   F6: Revival cost (25% of gold, min 100)
#   F7: Mech part damage (no negative)

func test_f1_dodge_at_level_1_no_equipment() -> void:
	# Lv 1, no equip/passive/mech bonuses
	# Expected: base 0.10 + level 1 × 0.02 = 0.12
	var dodge: float = BattleMathLib.ComputeDodgeChance(1, 0.0, 0.0, 0.0)
	assert_almost_eq(dodge, 0.12, 0.001, "Lv 1 dodge = 12%")

func test_f1_dodge_at_level_5_with_bonuses() -> void:
	# Lv 5, +10% equip, +5% passive, +5% mech
	# Expected: 0.10 + 5×0.02 + 0.10 + 0.05 + 0.05 = 0.40
	var dodge: float = BattleMathLib.ComputeDodgeChance(5, 0.10, 0.05, 0.05)
	assert_almost_eq(dodge, 0.40, 0.001, "Lv 5 with bonuses = 40%")

func test_f1_dodge_capped_at_80_percent() -> void:
	# High level + huge bonuses
	var dodge: float = BattleMathLib.ComputeDodgeChance(100, 1.0, 1.0, 1.0)
	assert_almost_eq(dodge, BattleMathLib.MaxDodgeCap, 0.001, "dodge capped at 80%")

func test_f1_dodge_floor_at_0_percent() -> void:
	# Negative bonuses (shouldn't happen, but defensive)
	var dodge: float = BattleMathLib.ComputeDodgeChance(1, -1.0, -1.0, -1.0)
	assert_ge(dodge, 0.0, "dodge floor at 0%")

func test_f2_hit_at_distance_0_no_cover() -> void:
	# base 0.85 + 0.10 accuracy + 0.05 weapon - 0.0 dodge - 0 distance - 0 cover = 1.0
	# Clamped to MaxHitCeiling = 0.95
	var hit: float = BattleMathLib.ComputeHitChance(0.85, 0.10, 0.05, 0.0, 0, false)
	assert_almost_eq(hit, 0.95, 0.001, "hit clamped to 95%")

func test_f2_hit_with_distance_penalty() -> void:
	# base 0.85 + 0.10 + 0.05 - 0.0 - 5×0.05 - 0 = 0.75
	var hit: float = BattleMathLib.ComputeHitChance(0.85, 0.10, 0.05, 0.0, 5, false)
	assert_almost_eq(hit, 0.75, 0.001, "hit with distance = 75%")

func test_f2_hit_with_cover_bonus() -> void:
	# base 0.85 + 0.10 + 0.05 - 0.0 - 0 - 0.05 = 0.95 (clamped)
	var hit: float = BattleMathLib.ComputeHitChance(0.85, 0.10, 0.05, 0.0, 0, true)
	assert_almost_eq(hit, 0.95, 0.001, "hit with cover = 95% (clamped)")

func test_f2_hit_floor_at_5_percent() -> void:
	# All penalties — should clamp to 5%
	var hit: float = BattleMathLib.ComputeHitChance(0.0, -1.0, -1.0, 0.5, 100, true)
	assert_almost_eq(hit, BattleMathLib.MinHitFloor, 0.001, "hit floor at 5%")

func test_f3_crit_all_bonuses_max() -> void:
	# 0.10 + 0.20 + 0.30 + 0.40 = 1.00
	var crit: float = BattleMathLib.ComputeCritChance(0.10, 0.20, 0.30, 0.40)
	assert_almost_eq(crit, 1.00, 0.001, "crit maxed at 100%")

func test_f3_crit_no_bonuses() -> void:
	# 0.05 + 0 + 0 + 0 = 0.05
	var crit: float = BattleMathLib.ComputeCritChance(0.05, 0.0, 0.0, 0.0)
	assert_almost_eq(crit, 0.05, 0.001, "crit base 5%")

func test_f3_crit_clamped_at_1() -> void:
	# Sum > 1 should clamp
	var crit: float = BattleMathLib.ComputeCritChance(0.5, 0.5, 0.5, 0.5)
	assert_almost_eq(crit, 1.00, 0.001, "crit clamped at 100%")

func test_f3_crit_clamped_at_0() -> void:
	# Negative bonuses should clamp to 0
	var crit: float = BattleMathLib.ComputeCritChance(-0.5, 0.0, 0.0, 0.0)
	assert_almost_eq(crit, 0.0, 0.001, "crit floor at 0%")

func test_f4_final_damage_basic() -> void:
	# weapon 50-50, ammo 1.0, weakness 1.0, no crit, armor 0 → 50
	# But RollRange is random — use min == max for deterministic test
	var dmg: int = BattleMathLib.ComputeFinalDamage(50, 50, 1.0, 1.0, 1.5, false, 0)
	assert_eq(dmg, 50, "weapon 50-50 with no crit = 50")

func test_f4_final_damage_with_crit() -> void:
	# weapon 50-50, ammo 1.0, weakness 1.0, crit × 2.0, armor 0 → 100
	var dmg: int = BattleMathLib.ComputeFinalDamage(50, 50, 1.0, 1.0, 2.0, true, 0)
	assert_eq(dmg, 100, "weapon 50-50 with crit × 2.0 = 100")

func test_f4_final_damage_with_armor() -> void:
	# weapon 50-50, no crit, armor 30 → 20
	var dmg: int = BattleMathLib.ComputeFinalDamage(50, 50, 1.0, 1.0, 1.5, false, 30)
	assert_eq(dmg, 20, "weapon 50-50, armor 30 = 20")

func test_f4_final_damage_minimum_1() -> void:
	# weapon 0-0, armor 100 → clamped to 1
	var dmg: int = BattleMathLib.ComputeFinalDamage(0, 0, 1.0, 1.0, 1.5, false, 100)
	assert_eq(dmg, 1, "0 damage weapon still hits for 1 (minimum)")

func test_f4_final_damage_weakness_double() -> void:
	# weapon 50-50, weakness 2.0, no crit → 100
	var dmg: int = BattleMathLib.ComputeFinalDamage(50, 50, 1.0, 2.0, 1.5, false, 0)
	assert_eq(dmg, 100, "weapon × weakness × 2.0 = 100")

func test_f5_xp_to_level_2() -> void:
	# 100 × 2^1.5 = 100 × 2.828 ≈ 283
	var xp: int = BattleMathLib.ComputeXPToNextLevel(2)
	assert_almost_eq(xp, 283.0, 1.0, "Lv 2 XP ≈ 283")

func test_f5_xp_to_level_10() -> void:
	# 100 × 10^1.5 = 100 × 31.62 ≈ 3162
	var xp: int = BattleMathLib.ComputeXPToNextLevel(10)
	assert_almost_eq(xp, 3162.0, 1.0, "Lv 10 XP ≈ 3162")

func test_f5_xp_to_level_1() -> void:
	# 100 × 1^1.5 = 100
	var xp: int = BattleMathLib.ComputeXPToNextLevel(1)
	assert_eq(xp, 100, "Lv 1 XP = 100")

func test_f5_xp_to_level_0_clamps_to_1() -> void:
	# 100 × 1^1.5 = 100 (defensive floor)
	var xp: int = BattleMathLib.ComputeXPToNextLevel(0)
	assert_eq(xp, 100, "Lv 0 clamps to Lv 1 = 100 XP")

func test_f6_revival_cost_50_gold() -> void:
	# max(floor(50 × 0.25), 100) = max(12, 100) = 100
	var cost: int = BattleMathLib.ComputeRevivalCost(50)
	assert_eq(cost, 100, "50 gold → revival cost 100 (min)")

func test_f6_revival_cost_400_gold() -> void:
	# max(floor(400 × 0.25), 100) = max(100, 100) = 100
	var cost: int = BattleMathLib.ComputeRevivalCost(400)
	assert_eq(cost, 100, "400 gold → cost 100")

func test_f6_revival_cost_1000_gold() -> void:
	# max(floor(1000 × 0.25), 100) = max(250, 100) = 250
	var cost: int = BattleMathLib.ComputeRevivalCost(1000)
	assert_eq(cost, 250, "1000 gold → cost 250")

func test_f6_revival_cost_0_gold() -> void:
	# max(floor(0 × 0.25), 100) = max(0, 100) = 100
	var cost: int = BattleMathLib.ComputeRevivalCost(0)
	assert_eq(cost, 100, "0 gold → cost 100 (min)")

func test_f7_mech_part_damage_basic() -> void:
	# 100 dmg × 1.0 - 0 armor = 100
	var dmg: int = BattleMathLib.ComputeMechPartDamage(100, 1.0, 0)
	assert_eq(dmg, 100, "100 dmg × 1.0 - 0 armor = 100")

func test_f7_mech_part_damage_with_armor() -> void:
	# 100 dmg × 1.0 - 50 armor = 50
	var dmg: int = BattleMathLib.ComputeMechPartDamage(100, 1.0, 50)
	assert_eq(dmg, 50, "100 dmg - 50 armor = 50")

func test_f7_mech_part_damage_never_negative() -> void:
	# 0 dmg × 1.0 - 100 armor = max(0, -100) = 0
	var dmg: int = BattleMathLib.ComputeMechPartDamage(0, 1.0, 100)
	assert_eq(dmg, 0, "0 dmg - 100 armor = 0 (not negative)")

func test_f7_mech_part_damage_with_armor_mult() -> void:
	# 100 dmg × 0.5 - 0 armor = 50
	var dmg: int = BattleMathLib.ComputeMechPartDamage(100, 0.5, 0)
	assert_eq(dmg, 50, "100 dmg × 0.5 = 50")

func test_existing_1v1_formulas_unchanged() -> void:
	# Backward compat check: existing 1v1 formulas still work
	assert_eq(BattleMathLib.MinDamage, 10, "MinDamage constant preserved")
	assert_eq(BattleMathLib.MaxDamage, 480, "MaxDamage constant preserved")
	# ClampDamage still works
	assert_eq(BattleMathLib.ClampDamage(5), 10, "ClampDamage still clamps low")
	assert_eq(BattleMathLib.ClampDamage(500), 480, "ClampDamage still clamps high")
	# RollRange still works
	var r: int = BattleMathLib.RollRange(50, 50)
	assert_eq(r, 50, "RollRange with lo == hi returns that value")