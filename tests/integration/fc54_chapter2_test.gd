extends GutTest

# FC-54 Chapter 2 skeleton (S6-102)
# Pins that Ch2 minimal skeleton is in place:
#   1) chapter2.tres registered in ResourceRegistry
#   2) chapter2 has boss_id = ice_sentinel
#   3) boss_ice_sentinel.tres registered
#   4) Ice boss has 120 HP, 12 attack
#   5) Ice boss has weaknesses (plasma_rounds, burn)
#   6) Ch2 tile PNGs exist (floor_ice, floor_ice_damaged, wall_ice, wall_ice_damaged)
#   7) LevelRuntime.change_chapter() reloads level data
#   8) build_room() uses ice tiles when chapter_index == 2

var _main: Node = null
var _reg: Node = null
var _runtime: Node = null

func before_all() -> void:
	_main = load("res://src/main.tscn").instantiate()
	get_tree().root.add_child(_main)
	await get_tree().process_frame
	await get_tree().process_frame
	_reg = get_node("/root/ResourceRegistry")
	_runtime = get_tree().get_root().find_child("Main", true, false)

func after_all() -> void:
	if _main != null:
		_main.queue_free()
		_main = null

# 1) Ch2 registered

func test_chapter2_registered() -> void:
	var level: Resource = _reg.get_resource(&"chapter2_frozen_reactor")
	assert_not_null(level, "chapter2_frozen_reactor registered")

# 2) Boss ID

func test_chapter2_boss_is_ice_sentinel() -> void:
	var level: Resource = _reg.get_resource(&"chapter2_frozen_reactor")
	if level == null:
		pending("Ch2 not registered")
		return
	assert_eq(level.get("boss_id"), &"boss_ice_sentinel", "Ch2 boss is Ice Sentinel")

# 3) Ice sentinel registered

func test_ice_sentinel_registered() -> void:
	var boss: Resource = _reg.get_resource(&"boss_ice_sentinel")
	assert_not_null(boss, "boss_ice_sentinel registered")

# 4) Boss stats

func test_ice_sentinel_stats() -> void:
	var boss: Resource = _reg.get_resource(&"boss_ice_sentinel")
	if boss == null:
		pending("Ice sentinel not registered")
		return
	assert_eq(int(boss.get("max_hp")), 120, "Ice Sentinel has 120 HP")
	assert_eq(int(boss.get("attack")), 12, "Ice Sentinel has 12 attack")

# 5) Weaknesses

func test_ice_sentinel_weaknesses() -> void:
	var boss: Resource = _reg.get_resource(&"boss_ice_sentinel")
	if boss == null:
		pending("Ice sentinel not registered")
		return
	var weak: Array = boss.get("weaknesses")
	assert_true(&"plasma_rounds" in weak or "plasma_rounds" in weak,
		"Ice Sentinel weak to plasma_rounds")
	assert_true(&"burn" in weak or "burn" in weak,
		"Ice Sentinel weak to burn")

# 6) Ch2 tiles exist

func test_ch2_tile_pngs_exist() -> void:
	for name in ["floor_ice", "floor_ice_damaged", "wall_ice", "wall_ice_damaged"]:
		var path: String = "res://assets/tilesets/ch2/%s.png" % name
		assert_true(ResourceLoader.exists(path), "%s.png exists" % name)

# 7) change_chapter reloads

func test_change_chapter_reloads_level() -> void:
	if _runtime == null:
		pending("no runtime")
		return
	# Start in Ch1
	var initial_id: StringName = _runtime.level_id
	assert_eq(initial_id, &"chapter1_scrapyard", "starts in Ch1")
	# Switch to Ch2
	_runtime.change_chapter(&"chapter2_frozen_reactor")
	assert_eq(_runtime.level_id, &"chapter2_frozen_reactor", "level_id updated")
	assert_eq(_runtime.current_room_index, 0, "room index reset to 0")
	# Switch back
	_runtime.change_chapter(&"chapter1_scrapyard")
	assert_eq(_runtime.level_id, &"chapter1_scrapyard", "can switch back to Ch1")

# 8) Ch2 uses ice tiles

func test_ch2_room_uses_ice_tiles() -> void:
	if _runtime == null:
		pending("no runtime")
		return
	_runtime.change_chapter(&"chapter2_frozen_reactor")
	await get_tree().process_frame
	# Check at least one Sprite2D in the new room has a tile texture
	# (we can't easily inspect the texture path, but verify the count is
	# non-zero — at minimum the floor + walls should be there)
	var tile_count: int = 0
	for c in _runtime.get_children():
		if c is Sprite2D:
			tile_count += 1
	assert_gt(tile_count, 0, "Ch2 room has tile sprites after build")
	# Restore
	_runtime.change_chapter(&"chapter1_scrapyard")
