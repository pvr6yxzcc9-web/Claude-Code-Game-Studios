extends GutTest

# FC-40 HUD element sprites (S6-008)
# Pins that the HUD now has actual sprite art for:
#   1) Fragment diamond icon
#   2) 3 weapon slot TextureRects
#   3) 4 mech part TextureRects
#   4) Weapon icon loading by id

var _main: Node = null
var _hud: Node = null

func before_all() -> void:
	_main = load("res://src/main.tscn").instantiate()
	get_tree().root.add_child(_main)
	await get_tree().process_frame
	await get_tree().process_frame
	_hud = get_tree().get_root().find_child("HUD", true, false)

func after_all() -> void:
	if _main != null:
		_main.queue_free()
		_main = null

func test_hud_has_fragment_icon_sprite() -> void:
	assert_not_null(_hud._fragment_icon,
		"HUD has _fragment_icon TextureRect")
	if _hud._fragment_icon != null:
		var tex: Texture2D = _hud._fragment_icon.texture
		assert_not_null(tex, "fragment_icon texture is loaded")

func test_hud_has_3_weapon_icon_texture_rects() -> void:
	assert_eq(_hud._weapon_icons.size(), 3,
		"HUD has 3 weapon icon slots")
	for i in 3:
		assert_true(_hud._weapon_icons[i] is TextureRect,
			"slot %d is TextureRect" % i)

func test_hud_weapon_icon_loads_per_weapon_id() -> void:
	var reg: Node = get_node("/root/ResourceRegistry")
	var blaster: Resource = reg.get_resource(&"blaster_rifle")
	var icon: Texture2D = _hud._load_weapon_icon(&"blaster_rifle")
	assert_not_null(icon, "blaster_rifle icon loads")
	var railgun: Resource = reg.get_resource(&"railgun")
	var icon2: Texture2D = _hud._load_weapon_icon(&"railgun")
	assert_not_null(icon2, "railgun icon loads")

func test_hud_weapon_icon_returns_null_for_empty_id() -> void:
	var icon: Texture2D = _hud._load_weapon_icon(&"")
	assert_null(icon, "empty id returns null")

func test_hud_weapon_icon_returns_null_for_unknown_id() -> void:
	var icon: Texture2D = _hud._load_weapon_icon(&"nonexistent_weapon")
	assert_null(icon, "unknown weapon id returns null (graceful fallback)")

func test_hud_sprites_dir_has_8_weapon_icons() -> void:
	var dir: DirAccess = DirAccess.open("res://assets/sprites/hud/weapons/")
	assert_not_null(dir, "weapons sprite dir exists")
	var count: int = 0
	for entry in dir.get_files():
		if entry.ends_with(".png"):
			count += 1
	assert_eq(count, 8, "8 weapon sprite PNGs generated")

func test_hud_sprites_dir_has_hud_elements() -> void:
	# fragment icon, hp bar bg/fill/frame, 4 mech parts
	for name in ["fragment_icon", "hp_bar_bg", "hp_bar_fill", "hp_bar_frame",
				"mech_part_torso", "mech_part_legs", "mech_part_left_arm", "mech_part_right_arm"]:
		var path: String = "res://assets/sprites/hud/%s.png" % name
		assert_true(ResourceLoader.exists(path), "%s.png exists" % name)
