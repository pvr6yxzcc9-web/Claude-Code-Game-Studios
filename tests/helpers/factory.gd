extends Node
class_name TestFactory

# Shared test factory functions for Railhunter tests.
#
# Usage:
#   extends GutTest
#   var factory: TestFactory = TestFactory.new()
#
#   func test_something():
#       var weapon := factory.make_weapon(min_damage=80)
#       var enemy := factory.make_enemy(boss=false)
#       var dmg = BattleMathLib.CalcDamage(weapon, ammo, enemy, false)
#       assert_eq(dmg, 80)

const WEAPON_SCRIPT = "res://src/resource/weapon_data.gd"
const ENEMY_SCRIPT = "res://src/resource/enemy_data.gd"
const AMMO_SCRIPT = "res://src/resource/ammo_data.gd"

# Default test weapon
func make_weapon(
    id: StringName = &"test_weapon",
    display_name: String = "Test Weapon",
    min_damage: int = 20,
    max_damage: int = 20,
    accuracy: float = 0.9,
    crit_chance: float = 0.05,
    crit_multiplier: float = 2.0
) -> WeaponData:
    var w: WeaponData = load(WEAPON_SCRIPT).new()
    w.id = id
    w.display_name = display_name
    w.min_damage = min_damage
    w.max_damage = max_damage
    w.accuracy = accuracy
    w.crit_chance = crit_chance
    w.crit_multiplier = crit_multiplier
    return w

# Default test enemy
func make_enemy(
    id: StringName = &"test_enemy",
    display_name: String = "Test Enemy",
    max_hp: int = 40,
    attack: int = 25,
    accuracy: float = 0.85,
    boss: bool = false,
    boss_immune_to_one_shot: bool = true,
    current_hp: int = 40,
    weaknesses: Array = [],
    resistances: Array = []
) -> EnemyData:
    var e: EnemyData = load(ENEMY_SCRIPT).new()
    e.id = id
    e.display_name = display_name
    e.max_hp = max_hp
    e.attack = attack
    e.accuracy = accuracy
    e.boss = boss
    e.boss_immune_to_one_shot = boss_immune_to_one_shot
    e.current_hp = current_hp
    e.weaknesses = weaknesses
    e.resistances = resistances
    return e

# Default test ammo
func make_ammo(
    id: StringName = &"test_ammo",
    display_name: String = "Test Ammo",
    damage_mult: float = 1.0,
    stack_size: int = 99
) -> AmmoData:
    var a: AmmoData = load(AMMO_SCRIPT).new()
    a.id = id
    a.display_name = display_name
    a.damage_mult = damage_mult
    a.stack_size = stack_size
    return a
