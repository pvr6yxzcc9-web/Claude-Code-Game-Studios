extends GutTest

# Combat math stress test (Sprint 12, fc77) — exercises BattleMathLib formulas
# with extreme values to verify boundary handling.

# === Dodge (F1) ===

func test_f1_dodge_with_max_level() -> void:
	# Level 100 + huge bonuses — should clamp to 0.80
	var dodge: float = BattleMathLib.ComputeDodgeChance(100, 5.0, 5.0, 5.0)
	assert_almost_eq(dodge, 0.80, 0.001, "maxed dodge clamps to 0.80")

func test_f1_dodge_with_huge_negative_bonuses() -> void:
	var dodge: float = BattleMathLib.ComputeDodgeChance(1, -10.0, -10.0, -10.0)
	assert_almost_eq(dodge, 0.0, 0.001, "negative bonuses floor at 0")

# === Hit (F2) ===

func test_f2_hit_with_huge_distance() -> void:
	# Distance 100 tiles = 500% penalty — clamped to 5% min
	var hit: float = BattleMathLib.ComputeHitChance(0.85, 0.0, 0.0, 0.0, 100, false)
	assert_almost_eq(hit, BattleMathLib.MinHitFloor, 0.001, "huge distance clamps to 5%")

func test_f2_hit_with_huge_accuracy() -> void:
	# baseHit 100% + huge bonuses — clamped to 95%
	var hit: float = BattleMathLib.ComputeHitChance(1.0, 5.0, 5.0, 0.0, 0, false)
	assert_almost_eq(hit, BattleMathLib.MaxHitCeiling, 0.001, "huge accuracy clamps to 95%")

func test_f2_hit_with_huge_dodge() -> void:
	# 0% accuracy + huge dodge — clamped to 5%
	var hit: float = BattleMathLib.ComputeHitChance(0.0, 0.0, 0.0, 10.0, 0, false)
	assert_almost_eq(hit, BattleMathLib.MinHitFloor, 0.001, "huge dodge clamps to 5%")

# === Crit (F3) ===

func test_f3_crit_with_huge_bonuses() -> void:
	# 5% + 50% + 50% + 50% = 155% — clamped to 100%
	var crit: float = BattleMathLib.ComputeCritChance(0.05, 0.50, 0.50, 0.50)
	assert_almost_eq(crit, 1.0, 0.001, "crit clamps to 100%")

# === Final damage (F4) ===

func test_f4_damage_with_zero_weapon_min_max() -> void:
	# 0 damage weapon — minimum 1 damage
	var dmg: int = BattleMathLib.ComputeFinalDamage(0, 0, 1.0, 1.0, 1.5, false, 0)
	assert_eq(dmg, 1, "0 damage weapon still deals 1 (minimum)")

func test_f4_damage_with_huge_armor() -> void:
	# 100 damage weapon + 999 armor — minimum 1 damage
	var dmg: int = BattleMathLib.ComputeFinalDamage(100, 100, 1.0, 1.0, 1.5, false, 999)
	assert_eq(dmg, 1, "huge armor still allows 1 damage minimum")

func test_f4_damage_with_weakness_and_crit() -> void:
	# 50 damage × 1.0 ammo × 2.0 weakness × 2.0 crit = 200, minus 10 armor = 190
	var dmg: int = BattleMathLib.ComputeFinalDamage(50, 50, 1.0, 2.0, 2.0, true, 10)
	assert_eq(dmg, 190, "weakness × crit combo")

# === XP (F5) ===

func test_f5_xp_to_level_50() -> void:
	# 100 × 50^1.5 = 100 × 353.55 ≈ 35355
	var xp: int = BattleMathLib.ComputeXPToNextLevel(50)
	assert_gt(xp, 35000, "Lv 50 XP > 35000")
	assert_lt(xp, 36000, "Lv 50 XP < 36000")

func test_f5_xp_curve_grows() -> void:
	# XP requirements should grow monotonically
	var xp1: int = BattleMathLib.ComputeXPToNextLevel(1)
	var xp5: int = BattleMathLib.ComputeXPToNextLevel(5)
	var xp10: int = BattleMathLib.ComputeXPToNextLevel(10)
	var xp20: int = BattleMathLib.ComputeXPToNextLevel(20)
	assert_lt(xp1, xp5, "Lv 1 → Lv 5: XP grows")
	assert_lt(xp5, xp10, "Lv 5 → Lv 10: XP grows")
	assert_lt(xp10, xp20, "Lv 10 → Lv 20: XP grows")

# === Revival cost (F6) ===

func test_f6_revival_cost_floor() -> void:
	# Even 0 gold → cost = 100 (floor)
	for gold in [0, 1, 50, 99]:
		var cost: int = BattleMathLib.ComputeRevivalCost(gold)
		assert_eq(cost, 100, "%d gold → cost 100" % gold)

func test_f6_revival_cost_proportional() -> void:
	# 400 gold → 100, 800 gold → 200, 1000 gold → 250
	assert_eq(BattleMathLib.ComputeRevivalCost(400), 100, "400 → 100")
	assert_eq(BattleMathLib.ComputeRevivalCost(800), 200, "800 → 200")
	assert_eq(BattleMathLib.ComputeRevivalCost(1000), 250, "1000 → 250")
	assert_eq(BattleMathLib.ComputeRevivalCost(10000), 2500, "10000 → 2500")

# === Mech part damage (F7) ===

func test_f7_part_damage_never_negative() -> void:
	# Test edge cases that would result in negative damage
	var dmg1: int = BattleMathLib.ComputeMechPartDamage(0, 1.0, 100)  # 0 dmg - 100 armor
	var dmg2: int = BattleMathLib.ComputeMechPartDamage(50, 0.0, 100)  # 0 mult - 100 armor
	var dmg3: int = BattleMathLib.ComputeMechPartDamage(0, 0.0, 0)
	assert_eq(dmg1, 0, "0 dmg - 100 armor = 0")
	assert_eq(dmg2, 0, "0 mult - 100 armor = 0")
	assert_eq(dmg3, 0, "0 dmg + 0 armor = 0")

func test_f7_part_damage_with_armor_mult() -> void:
	# 100 dmg × 0.5 mult - 0 armor = 50
	var dmg: int = BattleMathLib.ComputeMechPartDamage(100, 0.5, 0)
	assert_eq(dmg, 50, "100 × 0.5 = 50")

func test_f7_part_damage_full_pipeline() -> void:
	# 100 dmg × 1.0 - 30 armor = 70
	var dmg: int = BattleMathLib.ComputeMechPartDamage(100, 1.0, 30)
	assert_eq(dmg, 70, "100 - 30 = 70")

# === Cross-formula integration ===

func test_full_damage_pipeline_with_all_modifiers() -> void:
	# Realistic scenario:
	# - weapon 80-100
	# - ammo × 1.5
	# - weakness × 2.0
	# - crit × 2.5
	# - target armor 50
	# Force min=max=90 for determinism
	var dmg: int = BattleMathLib.ComputeFinalDamage(90, 90, 1.5, 2.0, 2.5, true, 50)
	# 90 × 1.5 × 2.0 × 2.5 = 675, minus 50 = 625
	assert_eq(dmg, 625, "full pipeline")

func test_dodge_then_hit_integration() -> void:
	# Compute dodge, then hit — verify they're independent
	var dodge: float = BattleMathLib.ComputeDodgeChance(5, 0.0, 0.0, 0.0)
	var hit: float = BattleMathLib.ComputeHitChance(0.85, 0.0, 0.0, dodge, 0, false)
	# Lv 5 dodge = 10% + 5 × 2% = 20%
	# Hit = 0.85 - 0.20 = 0.65
	assert_almost_eq(dodge, 0.20, 0.001, "Lv 5 dodge = 20%")
	assert_almost_eq(hit, 0.65, 0.001, "hit = 85% - 20% dodge = 65%")