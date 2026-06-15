extends RefCounted
class_name BattleMathLib

# BattleMathLib — per ADR-0011 damage bounds + battle-core-loop GDD.
# Static utility; pure functions only; no state.
# (Originally written in C# for "performance-critical" per ADR — but ADR-0011
# bounds are O(1) and tests are infrequent. GDScript version keeps PR-1
# unblocked until C# infra is built in PR-2.)

# Per ADR-0011: damage MUST be in [10, 480]
const MIN_DAMAGE: int = 10
const MAX_DAMAGE: int = 480

# Per ADR-0011: bosses are immune to one-shot
const BOSS_ONE_SHOT_IMMUNE_THRESHOLD: int = 50  # % of boss max HP

# S5-002/003/004 fix: Godot 4.6 `Object.get()` returns Variant with NO
# default-arg overload (only Dictionary does). This helper provides the
# "return default if property is missing or null" pattern for any
# Resource/Object lookup. Use this instead of `obj.get(key, default)`.
static func _prop(obj: Object, key: StringName, default: Variant) -> Variant:
	if obj == null:
		return default
	var v: Variant = obj.get(key)
	if v == null:
		return default
	return v

static func clamp_damage(raw: int) -> int:
	if raw < MIN_DAMAGE:
		return MIN_DAMAGE
	if raw > MAX_DAMAGE:
		return MAX_DAMAGE
	return raw

static func roll_range(lo: int, hi: int) -> int:
	if lo > hi:
		var tmp: int = lo
		lo = hi
		hi = tmp
	return randi_range(lo, hi)

static func compute_base_damage(weapon_min: int, weapon_max: int, ammo_mult: float, is_crit: bool, crit_mult: float) -> int:
	if weapon_max < weapon_min:
		var tmp: int = weapon_min
		weapon_min = weapon_max
		weapon_max = tmp
	var raw: int = roll_range(weapon_min, weapon_max)
	var scaled: float = float(raw) * ammo_mult
	if is_crit:
		scaled *= crit_mult
	return clamp_damage(int(round(scaled)))

static func roll_accuracy(accuracy: float) -> bool:
	if accuracy < 0.0:
		accuracy = 0.0
	if accuracy > 1.0:
		accuracy = 1.0
	return randf() <= accuracy

static func apply_boss_immunity(incoming_damage: int, boss_max_hp: int, boss_immune: bool) -> int:
	if not boss_immune:
		return incoming_damage
	if incoming_damage < boss_max_hp:
		return incoming_damage
	var cap: int = int(round(float(boss_max_hp) * float(BOSS_ONE_SHOT_IMMUNE_THRESHOLD) / 100.0))
	return min(incoming_damage, cap)

static func apply_defense(incoming_damage: int, defense: int) -> int:
	if defense < 0:
		defense = 0
	var reduction: float = min(float(defense) / 100.0, 0.75)
	# Use floor (not round) so that 10 * 0.25 = 2.5 floors to 2, not rounds to 3.
	# The max(1, ...) ensures the result is always at least 1 (per ADR-0011 spirit).
	var mitigated: int = int(floor(float(incoming_damage) * (1.0 - reduction)))
	return max(1, mitigated)

# --- S5-002: ammo effect damage bonus ---
# If the active ammo has an attached effect with damage_per_turn > 0,
# return a flat bonus = damage_per_turn * duration_turns (i.e., the total
# extra damage that effect would do over its lifetime). This avoids
# requiring a real multi-turn DoT state machine. (S5-002 scoping:
# effect's damage is folded into the per-hit damage rather than ticking
# across turns; this is the simplest faithful interpretation.)
static func apply_ammo_effect_bonus(ammo: Resource) -> int:
	if ammo == null:
		return 0
	var effect: Resource = _prop(ammo, &"effect", null)
	if effect == null:
		return 0
	var dpt: int = int(_prop(effect, &"damage_per_turn", 0))
	if dpt <= 0:
		return 0
	var duration: int = int(_prop(effect, &"duration_turns", 1))
	return dpt * duration

# --- S5-003: weakness / resistance damage mod ---
# If ammo_id or weapon_id is in the enemy's weaknesses list, dmg *= 1.5.
# If in resistances, dmg *= 0.5 (floor, min 1).
# Otherwise return damage unchanged.
static func apply_weakness_resistance(damage: int, weapon: Resource, ammo: Resource, enemy: Resource) -> int:
	if enemy == null or damage <= 0:
		return damage
	var weaknesses: Array = _prop(enemy, &"weaknesses", [])
	var resistances: Array = _prop(enemy, &"resistances", [])
	var attacker_id: StringName = &""
	if ammo != null:
		attacker_id = StringName(_prop(ammo, &"id", &""))
	elif weapon != null:
		attacker_id = StringName(_prop(weapon, &"id", &""))
	if attacker_id == &"":
		return damage
	if attacker_id in weaknesses:
		return clamp_damage(int(round(float(damage) * 1.5)))
	if attacker_id in resistances:
		var reduced: int = int(floor(float(damage) * 0.5))
		return max(1, reduced)
	return damage

# --- S5-004: weapon special_effects bonus ---
# Iterates the weapon's special_effects array. Effects with
# stat_modifiers["chain_bonus"] or ["aoe_bonus"] apply multiplicatively;
# effects with damage_per_turn add flat bonus. S5-004 scope: per-hit
# bonus only (no actual multi-target); mirrors S5-002 pragmatic fallback.
static func apply_weapon_effects_bonus(damage: int, weapon: Resource) -> int:
	if weapon == null or damage <= 0:
		return damage
	var effects: Array = _prop(weapon, &"special_effects", [])
	if effects.is_empty():
		return damage
	var total_bonus: int = 0
	var mult: float = 1.0
	for eff in effects:
		if eff == null:
			continue
		var dpt: int = int(_prop(eff, &"damage_per_turn", 0))
		if dpt > 0:
			var dur: int = int(_prop(eff, &"duration_turns", 1))
			total_bonus += dpt * dur
		var mods: Dictionary = _prop(eff, &"stat_modifiers", {})
		for key in mods.keys():
			if String(key) in ["chain_bonus", "aoe_bonus"]:
				mult *= float(mods[key])
	return clamp_damage(int(round(float(damage) * mult)) + total_bonus)
