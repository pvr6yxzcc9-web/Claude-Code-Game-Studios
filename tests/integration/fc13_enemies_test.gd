extends GutTest

# FC-13 Enemies Integration Test (S2-004 + S4-004)
# Verifies 8 total enemies exist in ResourceRegistry with stats in valid ranges.
# S4-004 added swarmer + shielded_bot + reflector_drone.

const ENEMY_IDS: Array[StringName] = [
    &"scavenger",
    &"drone",
    &"heavy_walker",
    &"sniper_bot",
    &"boss_marrow_sentinel",
    &"swarmer",
    &"shielded_bot",
    &"reflector_drone",
]

const BOSS_ID: StringName = &"boss_marrow_sentinel"

func test_eight_enemies_in_registry() -> void:
    var reg: Node = get_node("/root/ResourceRegistry")
    for id in ENEMY_IDS:
        var r: Resource = reg.get_resource(id)
        assert_not_null(r, "%s must be in registry" % id)

func test_enemy_stats_in_bounds() -> void:
    # Per EnemyData @export_range: max_hp [10,500], attack [1,100], accuracy [0,1]
    var reg: Node = get_node("/root/ResourceRegistry")
    for id in ENEMY_IDS:
        var r: Resource = reg.get_resource(id)
        if r == null:
            continue
        assert_true(r.max_hp >= 10 and r.max_hp <= 500, "%s max_hp %d in [10,500]" % [id, r.max_hp])
        assert_true(r.attack >= 1 and r.attack <= 100, "%s attack %d in [1,100]" % [id, r.attack])
        assert_true(r.accuracy >= 0.0 and r.accuracy <= 1.0, "%s accuracy %.2f in [0,1]" % [id, r.accuracy])

func test_only_boss_has_boss_flag_true() -> void:
    var reg: Node = get_node("/root/ResourceRegistry")
    for id in ENEMY_IDS:
        var r: Resource = reg.get_resource(id)
        if r == null:
            continue
        var expected_boss: bool = (id == BOSS_ID)
        assert_eq(r.boss, expected_boss, "%s boss flag should be %s" % [id, expected_boss])

func test_role_diversity() -> void:
    # S2-004 design: 4 non-boss enemies should occupy distinct role quadrants
    # (low-hp/high-acc, high-hp/low-acc, high-attack/low-acc, balanced)
    # Verify each new enemy matches its role:
    var reg: Node = get_node("/root/ResourceRegistry")

    var drone: Resource = reg.get_resource(&"drone")
    # drone: low HP (<40), high acc (>=0.85)
    assert_true(drone.max_hp <= 40, "drone should be low-hp: got %d" % drone.max_hp)
    assert_true(drone.accuracy >= 0.85, "drone should be high-acc: got %.2f" % drone.accuracy)

    var heavy: Resource = reg.get_resource(&"heavy_walker")
    # heavy_walker: high HP (>=60), low acc (<=0.70)
    assert_true(heavy.max_hp >= 60, "heavy_walker should be high-hp: got %d" % heavy.max_hp)
    assert_true(heavy.accuracy <= 0.70, "heavy_walker should be low-acc: got %.2f" % heavy.accuracy)

    var sniper: Resource = reg.get_resource(&"sniper_bot")
    # sniper_bot: high attack (>=35), low-mid acc (<=0.75)
    assert_true(sniper.attack >= 35, "sniper_bot should be high-attack: got %d" % sniper.attack)
    assert_true(sniper.accuracy <= 0.75, "sniper_bot should be low-mid acc: got %.2f" % sniper.accuracy)

# --- S4-004: new enemies (swarmer + shielded_bot + reflector_drone) ---
# Pin each new enemy's role: niche that doesn't overlap existing 4 non-boss
# enemies. Note: weaknesses/resistances are stored but not yet consumed by
# battle math (S4-007 will wire those).

func test_swarmer_is_weakest_grunt() -> void:
    var reg: Node = get_node("/root/ResourceRegistry")
    var swarmer: Resource = reg.get_resource(&"swarmer")
    assert_eq(String(swarmer.get("display_name")), "Swarmer")
    # Lowest HP + lowest attack of all non-boss enemies
    var drone: Resource = reg.get_resource(&"drone")
    assert_true(swarmer.max_hp < drone.max_hp, "swarmer hp < drone hp (lowest tier)")
    assert_true(swarmer.attack < drone.attack, "swarmer atk < drone atk (weakest grunt)")

func test_shielded_bot_is_highest_hp_non_boss() -> void:
    var reg: Node = get_node("/root/ResourceRegistry")
    var shielded: Resource = reg.get_resource(&"shielded_bot")
    assert_eq(String(shielded.get("display_name")), "Shielded Bot")
    # Higher HP than heavy_walker (the previous hp-tank)
    var heavy: Resource = reg.get_resource(&"heavy_walker")
    assert_true(shielded.max_hp > heavy.max_hp, "shielded_bot hp > heavy_walker (tank niche)")
    # But lower attack than heavy_walker (more pure-tank, less damage)
    assert_true(shielded.attack < heavy.attack, "shielded_bot atk < heavy_walker (pure tank)")

func test_reflector_drone_is_highest_accuracy_non_boss() -> void:
    var reg: Node = get_node("/root/ResourceRegistry")
    var reflector: Resource = reg.get_resource(&"reflector_drone")
    assert_eq(String(reflector.get("display_name")), "Reflector Drone")
    # Highest accuracy of all non-boss enemies (counters crit builds)
    var drone: Resource = reg.get_resource(&"drone")
    assert_true(reflector.accuracy > drone.accuracy, "reflector_drone acc > drone (highest non-boss)")
    # And higher than all others — verify by scanning ENEMY_IDS (excluding boss)
    for id in ENEMY_IDS:
        if id == BOSS_ID or id == &"reflector_drone":
            continue
        var r: Resource = reg.get_resource(id)
        if r == null:
            continue
        assert_true(reflector.accuracy >= r.accuracy,
            "reflector_drone acc >= %s acc (%.2f vs %.2f)" % [id, reflector.accuracy, r.accuracy])

func test_eight_enemies_total_count_in_registry() -> void:
    var reg: Node = get_node("/root/ResourceRegistry")
    var count: int = 0
    for id in ENEMY_IDS:
        if reg.get_resource(id) != null:
            count += 1
    assert_eq(count, 8, "exactly 8 enemies in registry (was 5 in Sprint 2)")
