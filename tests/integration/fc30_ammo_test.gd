extends GutTest

# FC-30 Ammo registry + plasma_burn (S4-010)
# Pins:
#   1) 5 ammo total in registry (4 Sprint 2 + plasma_burn new)
#   2) plasma_burn has damage_mult 1.4 + references burn effect
#   3) Burn effect has duration 3 turns + 5 damage_per_turn
#   4) Ammo damage_mult in valid range [0.1, 3.0] per @export_range

const AMMO_IDS: Array[StringName] = [
    &"basic_cell",
    &"acid_round",
    &"emp_charge",
    &"plasma_cell",
    &"plasma_burn",  # S4-010 addition
]

const BURN_EFFECT_ID: StringName = &"burn"

# --- A) All ammo loaded ---

func test_five_ammo_in_registry() -> void:
    var reg: Node = get_node("/root/ResourceRegistry")
    for id in AMMO_IDS:
        var r: Resource = reg.get_resource(id)
        assert_not_null(r, "%s must be in registry" % id)

# --- B) plasma_burn specifics ---

func test_plasma_burn_is_high_damage_with_effect() -> void:
    var reg: Node = get_node("/root/ResourceRegistry")
    var ammo: Resource = reg.get_resource(&"plasma_burn")
    assert_eq(String(ammo.get("display_name")), "Plasma Burn Cell")
    var dmg_mult: float = ammo.get("damage_mult")
    assert_true(dmg_mult > 1.0, "plasma_burn is damage-mult buffing ammo: %.2f > 1.0" % dmg_mult)

func test_plasma_burn_attaches_burn_effect() -> void:
    var reg: Node = get_node("/root/ResourceRegistry")
    var ammo: Resource = reg.get_resource(&"plasma_burn")
    var effect: Resource = ammo.get("effect")
    assert_not_null(effect, "plasma_burn has attached effect")
    assert_eq(StringName(effect.get("id")), BURN_EFFECT_ID, "attached effect is the burn effect")

func test_burn_effect_has_damage_over_time() -> void:
    var reg: Node = get_node("/root/ResourceRegistry")
    var effect: Resource = reg.get_resource(BURN_EFFECT_ID)
    assert_not_null(effect, "burn effect loaded in registry")
    assert_eq(int(effect.get("duration_turns")), 3, "burn lasts 3 turns")
    assert_eq(int(effect.get("damage_per_turn")), 5, "burn deals 5 dmg/turn")

# --- C) All ammo stats in bounds ---

func test_all_ammo_damage_mult_in_bounds() -> void:
    var reg: Node = get_node("/root/ResourceRegistry")
    for id in AMMO_IDS:
        var ammo: Resource = reg.get_resource(id)
        if ammo == null:
            continue
        var mult: float = ammo.get("damage_mult")
        assert_true(mult >= 0.1 and mult <= 3.0,
            "%s damage_mult %.2f in [0.1, 3.0]" % [id, mult])
