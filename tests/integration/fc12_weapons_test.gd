extends GutTest

# FC-12 Weapons Integration Test (S2-003 + S4-003)
# Verifies 8 total weapons exist in ResourceRegistry and can be equipped into any of 3 slots.
# S4-003 added mine_layer + arc_emitter.

const WEAPON_IDS: Array[StringName] = [
    &"blaster_rifle",
    &"shotgun",
    &"sniper_rifle",
    &"plasma_cannon",
    &"railgun",
    &"shotgun_spread",
    &"mine_layer",
    &"arc_emitter",
]

func test_eight_weapons_in_registry() -> void:
    var reg: Node = get_node("/root/ResourceRegistry")
    for id in WEAPON_IDS:
        var r: Resource = reg.get_resource(id)
        assert_not_null(r, "%s must be in registry" % id)

func test_weapon_stats_in_bounds() -> void:
    # Per weapon-ammo.md: damage 10..480, accuracy 0.5..1.0, crit 0..0.5
    var reg: Node = get_node("/root/ResourceRegistry")
    for id in WEAPON_IDS:
        var r: Resource = reg.get_resource(id)
        if r == null:
            continue
        assert_true(r.min_damage >= 10 and r.min_damage <= 480, "%s min_damage %d in [10,480]" % [id, r.min_damage])
        assert_true(r.max_damage >= r.min_damage, "%s max >= min" % id)
        assert_true(r.accuracy >= 0.5 and r.accuracy <= 1.0, "%s accuracy %.2f in [0.5,1.0]" % [id, r.accuracy])
        assert_true(r.crit_chance >= 0.0 and r.crit_chance <= 0.5, "%s crit %.2f in [0,0.5]" % [id, r.crit_chance])

func test_all_weapons_loadable_into_slot_0() -> void:
    var loadout: Node = get_node("/root/WeaponLoadout")
    for id in WEAPON_IDS:
        loadout.weapon_slots[0] = id
        var w: Resource = loadout.get_active_weapon()
        assert_not_null(w, "slot 0 set to %s, get_active_weapon must return non-null" % id)

func test_all_weapons_loadable_into_slot_1() -> void:
    var loadout: Node = get_node("/root/WeaponLoadout")
    loadout.weapon_slots[0] = &""  # clear slot 0
    for id in WEAPON_IDS:
        loadout.weapon_slots[1] = id
        loadout.active_slot = 1
        var w: Resource = loadout.get_active_weapon()
        assert_not_null(w, "slot 1 set to %s, get_active_weapon must return non-null" % id)
    loadout.active_slot = 0  # restore default
    loadout.weapon_slots[1] = &""

func test_all_weapons_loadable_into_slot_2() -> void:
    var loadout: Node = get_node("/root/WeaponLoadout")
    for id in WEAPON_IDS:
        loadout.weapon_slots[2] = id
        loadout.active_slot = 2
        var w: Resource = loadout.get_active_weapon()
        assert_not_null(w, "slot 2 set to %s, get_active_weapon must return non-null" % id)
    loadout.active_slot = 0  # restore default
    loadout.weapon_slots[2] = &""

# --- S4-003: new weapons have distinct stat profiles (not stat clones) ---

func test_mine_layer_is_mid_range_steady() -> void:
    var reg: Node = get_node("/root/ResourceRegistry")
    var w: Resource = reg.get_resource(&"mine_layer")
    assert_eq(String(w.get("display_name")), "Mine Layer")
    assert_eq(StringName(w.get("range")), &"mid", "mine_layer range = mid")
    # Mine Layer fills a "steady mid" niche: lower damage than plasma/rail,
    # higher acc than shotgun. Verify it doesn't overlap blaster_rifle.
    var blaster: Resource = reg.get_resource(&"blaster_rifle")
    assert_true(w.accuracy >= blaster.accuracy,
        "mine_layer acc >= blaster_rifle acc (steady mid niche)")
    assert_true(w.min_damage > blaster.min_damage,
        "mine_layer min_damage > blaster (higher floor)")

func test_arc_emitter_is_high_variance_crit() -> void:
    var reg: Node = get_node("/root/ResourceRegistry")
    var w: Resource = reg.get_resource(&"arc_emitter")
    assert_eq(String(w.get("display_name")), "Arc Emitter")
    assert_eq(StringName(w.get("range")), &"near", "arc_emitter range = near")
    # Arc Emitter fills "high crit near" niche — verify it doesn't overlap
    # the existing near weapon (shotgun, crit=0.15).
    var shotgun: Resource = reg.get_resource(&"shotgun")
    assert_true(w.crit_chance > shotgun.crit_chance,
        "arc_emitter crit > shotgun crit (crit-focused niche)")
    assert_true(w.max_damage > shotgun.max_damage,
        "arc_emitter max > shotgun max (higher ceiling)")

func test_eight_weapons_total_count_in_registry() -> void:
    # Pin the actual count so future weapon additions update both the
    # WEAPON_IDS list and this assertion together.
    var reg: Node = get_node("/root/ResourceRegistry")
    var count: int = 0
    for id in WEAPON_IDS:
        if reg.get_resource(id) != null:
            count += 1
    assert_eq(count, 8, "exactly 8 weapons in registry (was 6 in Sprint 2)")
