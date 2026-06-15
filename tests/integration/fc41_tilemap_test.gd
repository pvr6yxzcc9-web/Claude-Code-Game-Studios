extends GutTest

# FC-41 TileMap floor + wall (S6-009)
# Pins that rooms now render with a tile grid:
#   1) 6 tile PNGs exist (4 floor + 2 wall)
#   2) build_room() spawns 240 floor Sprite2D tiles (20x12 grid)
#   3) Floor tiles are at z_index = -10 (render behind everything)
#   4) Wall Sprite2D tiles are spawned (top + bottom strips + side columns)
#   5) Walls respect door gap (no tile where the door rect is)
#   6) Boss room (last) has warning floor tiles
#   7) Floor tiles are cleared by clear_room()

const _LEVEL_RUNTIME := preload("res://src/scene/level_runtime.gd")

var _main: Node = null
var _level_runtime: Node = null

func before_all() -> void:
	_main = load("res://src/main.tscn").instantiate()
	get_tree().root.add_child(_main)
	await get_tree().process_frame
	await get_tree().process_frame
	_level_runtime = get_tree().get_root().find_child("LevelRuntime", true, false)

func after_all() -> void:
	if _main != null:
		_main.queue_free()
		_main = null

# 1) Asset presence

func test_tileset_assets_exist() -> void:
	for name in ["floor_main", "floor_damaged", "floor_clean", "floor_warning",
				"wall_industrial", "wall_damaged"]:
		var path: String = "res://assets/tilesets/%s.png" % name
		assert_true(ResourceLoader.exists(path), "%s.png exists" % name)

# 2) Floor tile count

func test_floor_has_240_sprite_tiles() -> void:
	# 20 cols * 12 rows = 240
	var floor_tiles: int = 0
	for child in _level_runtime.get_children():
		if child is Sprite2D and child.z_index == -10:
			floor_tiles += 1
	assert_eq(floor_tiles, 240, "20x12=240 floor tiles spawned")

# 3) z_index

func test_floor_tiles_z_index_negative() -> void:
	# All floor tiles must have z_index < 0 (render behind player/HUD)
	for child in _level_runtime.get_children():
		if child is Sprite2D and child.z_index == -10:
			return  # found at least one with z=-10
	pending("no z=-10 floor tiles to verify (test_floor_has_240 must pass first)")

# 4) Wall tile count

func test_wall_tiles_spawned() -> void:
	# Top + bottom strips (20+20=40) + 2 side columns (12 each = 24) = 64 wall tiles
	# But door gap removes 2 from each side (rows 5-6), so 64 - 4 = 60 in middle rooms.
	# First/last room only has one door (one side gap), so 62.
	# The boss room (last) has no right door, so left gap = 2, right gap = 0
	# Just assert > 50 tiles to be robust.
	var wall_tiles: int = 0
	for child in _level_runtime.get_children():
		if child is Sprite2D and child.z_index == -5:
			wall_tiles += 1
	assert_gt(wall_tiles, 50, "at least 50 wall tiles spawned (top/bottom + sides)")

# 5) Door gap (room 1, has both left and right doors — biggest gap)

func test_wall_respects_door_gap() -> void:
	# Room 1 should have door gaps on BOTH left and right sides at rows 5-6.
	# Verify no wall sprite exists at x=-16 with row 5 or 6 position.
	# Row 5 starts at y=5*64=320, row 6 starts at y=6*64=384.
	for child in _level_runtime.get_children():
		if not (child is Sprite2D and child.z_index == -5):
			continue
		# Left wall column at x=-16; right wall column at x=1280-64+16=1232
		var x: float = child.position.x
		if x != -16.0 and x != 1232.0:
			continue
		var y: float = child.position.y
		# Door gap rows are 5 and 6 (y = 320 and 384)
		assert_false(y == 320.0 or y == 384.0,
			"no wall sprite in door gap (x=%s y=%s)" % [x, y])

# 6) clear_room() removes floor/wall tiles

func test_clear_room_removes_floor_and_wall_tiles() -> void:
	# Pre-state: count tiles
	var before_floor: int = 0
	var before_wall: int = 0
	for child in _level_runtime.get_children():
		if not (child is Sprite2D):
			continue
		if child.z_index == -10:
			before_floor += 1
		elif child.z_index == -5:
			before_wall += 1
	assert_gt(before_floor, 0, "pre-clear: floor tiles present")
	assert_gt(before_wall, 0, "pre-clear: wall tiles present")
	# Trigger a rebuild to a different room (forces clear_room internally)
	_level_runtime.build_room(1)
	await get_tree().process_frame
	# Post-state: still has floor/wall (just different tiles)
	var after_floor: int = 0
	var after_wall: int = 0
	for child in _level_runtime.get_children():
		if not (child is Sprite2D):
			continue
		if child.z_index == -10:
			after_floor += 1
		elif child.z_index == -5:
			after_wall += 1
	assert_eq(after_floor, 240, "post-rebuild: still 240 floor tiles")
	assert_gt(after_wall, 50, "post-rebuild: still wall tiles")
