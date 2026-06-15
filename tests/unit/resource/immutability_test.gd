extends GutTest

# Unit test: Resource Immutability (per ADR-0007)
# Verifies that ImmutableResource base class enforces the immutability
# contract to the extent that Godot 4.6 allows.
#
# Godot 4.6 limitation (per ADR-0007): _set() virtual is bypassed for
# @export-declared properties. Runtime writes to declared properties go
# directly through the native setter. The immutability guarantee is
# therefore enforced by CONVENTION, not by the language.
# _set() serves as a safety net for undeclared property writes (typos).

const WEAPON_SCRIPT = "res://src/resource/weapon_data.gd"

func test_resource_load_succeeds() -> void:
	# Resource can be created and populated (engine deserialization path)
	var weapon: WeaponData = load(WEAPON_SCRIPT).new()
	weapon.id = &"test_resource"
	weapon.min_damage = 50
	weapon.max_damage = 50

	assert_eq(weapon.id, &"test_resource", "Resource has correct id")
	assert_eq(weapon.min_damage, 50, "Resource has correct min_damage")
	assert_eq(weapon.max_damage, 50, "Resource has correct max_damage")

func test_undeclared_property_write_is_rejected() -> void:
	# _set() override catches undeclared property writes (typos, accidents)
	var weapon: WeaponData = load(WEAPON_SCRIPT).new()
	weapon.id = &"test_resource"
	var pl_before: Array = weapon.get_property_list()

	# Undeclared property — _set() should reject
	weapon.set("totally_made_up_field_xyz", "hacked")

	var pl_after: Array = weapon.get_property_list()
	assert_eq(
		pl_before.size(), pl_after.size(),
		"undeclared property write must not add a new property"
	)

func test_declared_property_in_property_list() -> void:
	# All @export properties must be discoverable
	var weapon: WeaponData = load(WEAPON_SCRIPT).new()
	var pl: Array = weapon.get_property_list()
	var names: Array = []
	for p in pl:
		names.append(p.get("name", ""))
	assert_true(&"id" in names, "'id' is in get_property_list()")
	assert_true(&"min_damage" in names, "'min_damage' is in get_property_list()")
	assert_true(&"max_damage" in names, "'max_damage' is in get_property_list()")
	assert_true(&"accuracy" in names, "'accuracy' is in get_property_list()")

func test_resource_instance_is_unique() -> void:
	# Two .new() calls produce distinct instances (no shared state)
	var a: WeaponData = load(WEAPON_SCRIPT).new()
	var b: WeaponData = load(WEAPON_SCRIPT).new()
	a.id = &"alpha"
	b.id = &"beta"
	assert_ne(a, b, "two .new() instances are distinct")
	assert_eq(a.id, &"alpha", "alpha instance has alpha id")
	assert_eq(b.id, &"beta", "beta instance has beta id")
