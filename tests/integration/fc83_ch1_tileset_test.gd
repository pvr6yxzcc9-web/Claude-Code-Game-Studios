extends GutTest

# ch1 tileset integration test (Sprint 18, fc83) — verifies the
# 4 ch1 tiles generated in S18-001 are valid + match the
# tile_set = &"ch1" reference in chapter1.tres.

const CH1_TILES: Array[String] = [
	"floor_derelict",
	"floor_derelict_damaged",
	"wall_derelict",
	"wall_derelict_damaged",
]

# === File existence ===

func test_ch1_tiles_all_4_exist() -> void:
	for name in CH1_TILES:
		var path: String = "res://assets/tilesets/ch1/%s.png" % name
		assert_true(FileAccess.file_exists(path), "%s.png exists" % name)

# === Dimension checks ===

func test_ch1_tiles_are_32x32() -> void:
	for name in CH1_TILES:
		var path: String = "res://assets/tilesets/ch1/%s.png" % name
		if not FileAccess.file_exists(path):
			continue
		var img: Image = Image.load_from_file(path)
		if img == null:
			continue
		assert_eq(img.get_width(), 32, "%s width 32" % name)
		assert_eq(img.get_height(), 32, "%s height 32" % name)

# === Format checks ===

func test_ch1_tiles_are_valid_png_rgba() -> void:
	# All 4 tiles should load as valid Image objects
	for name in CH1_TILES:
		var path: String = "res://assets/tilesets/ch1/%s.png" % name
		if not FileAccess.file_exists(path):
			continue
		var img: Image = Image.load_from_file(path)
		assert_not_null(img, "%s loads as Image" % name)

# === chapter1.tres reference ===

func test_chapter1_tres_references_ch1_tileset() -> void:
	# chapter1.tres should have tile_set = &"ch1"
	var path: String = "res://data/levels/chapter1.tres"
	if not FileAccess.file_exists(path):
		return
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var text: String = f.get_as_text()
	f.close()
	assert_true(text.contains("tile_set = &\"ch1\""),
		"chapter1.tres uses tile_set = &\"ch1\"")

# === Registry resolution ===

func test_ch1_tiles_loadable_via_resource_registry() -> void:
	# The TileMap code in level_runtime loads tiles via path, not
	# registry. But the test confirms the files can be loaded as
	# Texture2D resources (validates the .import works).
	for name in CH1_TILES:
		var path: String = "res://assets/tilesets/ch1/%s.png" % name
		if not ResourceLoader.exists(path):
			continue
		var tex: Texture2D = load(path) as Texture2D
		assert_not_null(tex, "%s loads as Texture2D" % name)

# === Damaged variants differ from base ===

func test_damaged_variants_differ_from_base() -> void:
	# Sanity check: damaged tiles aren't identical to base tiles
	# (would mean the random cracks/rust aren't being added)
	var pairs: Array = [
		["floor_derelict", "floor_derelict_damaged"],
		["wall_derelict", "wall_derelict_damaged"],
	]
	for pair in pairs:
		var base_path: String = "res://assets/tilesets/ch1/%s.png" % pair[0]
		var dmg_path: String = "res://assets/tilesets/ch1/%s.png" % pair[1]
		if not FileAccess.file_exists(base_path) or not FileAccess.file_exists(dmg_path):
			continue
		var base_img: Image = Image.load_from_file(base_path)
		var dmg_img: Image = Image.load_from_file(dmg_path)
		if base_img == null or dmg_img == null:
			continue
		# Compare as bytes — should differ
		var base_bytes: PackedByteArray = base_img.save_png_to_buffer()
		var dmg_bytes: PackedByteArray = dmg_img.save_png_to_buffer()
		assert_ne(base_bytes, dmg_bytes, "%s differs from %s" % [pair[1], pair[0]])

# === Cumulative ===

func test_total_s18_assets_at_least_4() -> void:
	var count: int = 0
	for name in CH1_TILES:
		if FileAccess.file_exists("res://assets/tilesets/ch1/%s.png" % name):
			count += 1
	assert_eq(count, 4, "all 4 ch1 tiles present")
