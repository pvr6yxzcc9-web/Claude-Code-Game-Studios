extends GutTest

# Boss animation frames integration test (Sprint 19, fc84) — verifies
# 5 bosses × 5 frames = 25 boss animation PNGs exist and are valid.

const BOSSES: Array[String] = [
	"boss_marrow_sentinel",
	"boss_ice_warden",
	"boss_hive_queen_guardian",
	"boss_pluto_remnant",
	"boss_creator",
]
const FRAMES: Array[String] = [
	"idle", "attack_windup", "attack_strike", "hit", "death",
]

# === File existence (5 bosses × 5 frames = 25) ===

func test_boss_animation_frames_all_25_exist() -> void:
	for boss in BOSSES:
		for frame in FRAMES:
			var path: String = "res://assets/sprites/enemies/%s_%s.png" % [boss, frame]
			assert_true(FileAccess.file_exists(path),
				"%s_%s.png exists" % [boss, frame])

# === Each boss has all 5 frames ===

func test_each_boss_has_all_5_frames() -> void:
	for boss in BOSSES:
		for frame in FRAMES:
			var path: String = "res://assets/sprites/enemies/%s_%s.png" % [boss, frame]
			assert_true(FileAccess.file_exists(path),
				"%s_%s exists" % [boss, frame])

# === All frames load as valid images ===

func test_all_boss_frames_load_as_images() -> void:
	var loaded: int = 0
	for boss in BOSSES:
		for frame in FRAMES:
			var path: String = "res://assets/sprites/enemies/%s_%s.png" % [boss, frame]
			if not FileAccess.file_exists(path):
				continue
			var img: Image = Image.load_from_file(path)
			if img == null:
				continue
			loaded += 1
	# All 25 should load
	assert_gte(loaded, 25, "all 25 boss frames load as Image (got %d)" % loaded)

# === Frame dimension matches base boss sprite ===

func test_boss_frames_match_base_dimensions() -> void:
	for boss in BOSSES:
		var base_path: String = "res://assets/sprites/enemies/%s.png" % boss
		if not FileAccess.file_exists(base_path):
			continue
		var base_img: Image = Image.load_from_file(base_path)
		if base_img == null:
			continue
		for frame in FRAMES:
			var frame_path: String = "res://assets/sprites/enemies/%s_%s.png" % [boss, frame]
			if not FileAccess.file_exists(frame_path):
				continue
			var frame_img: Image = Image.load_from_file(frame_path)
			if frame_img == null:
				continue
			assert_eq(frame_img.get_width(), base_img.get_width(),
				"%s_%s width matches base" % [boss, frame])
			assert_eq(frame_img.get_height(), base_img.get_height(),
				"%s_%s height matches base" % [boss, frame])

# === Frames differ from each other (not all identical) ===

func test_attack_strike_differs_from_idle() -> void:
	# Sanity check: attack_strike should look different from idle
	# (we added radial impact lines + flash overlay)
	for boss in BOSSES:
		var idle_path: String = "res://assets/sprites/enemies/%s_idle.png" % boss
		var strike_path: String = "res://assets/sprites/enemies/%s_attack_strike.png" % boss
		if not FileAccess.file_exists(idle_path) or not FileAccess.file_exists(strike_path):
			continue
		var idle_img: Image = Image.load_from_file(idle_path)
		var strike_img: Image = Image.load_from_file(strike_path)
		if idle_img == null or strike_img == null:
			continue
		var idle_bytes: PackedByteArray = idle_img.save_png_to_buffer()
		var strike_bytes: PackedByteArray = strike_img.save_png_to_buffer()
		assert_ne(idle_bytes, strike_bytes,
			"%s attack_strike differs from idle" % boss)

func test_death_differs_from_idle() -> void:
	# Death should differ from idle (tilted + desaturated + lower opacity)
	for boss in BOSSES:
		var idle_path: String = "res://assets/sprites/enemies/%s_idle.png" % boss
		var death_path: String = "res://assets/sprites/enemies/%s_death.png" % boss
		if not FileAccess.file_exists(idle_path) or not FileAccess.file_exists(death_path):
			continue
		var idle_img: Image = Image.load_from_file(idle_path)
		var death_img: Image = Image.load_from_file(death_path)
		if idle_img == null or death_img == null:
			continue
		var idle_bytes: PackedByteArray = idle_img.save_png_to_buffer()
		var death_bytes: PackedByteArray = death_img.save_png_to_buffer()
		assert_ne(idle_bytes, death_bytes,
			"%s death differs from idle" % boss)

# === Cumulative ===

func test_total_s19_assets_at_least_25() -> void:
	var count: int = 0
	for boss in BOSSES:
		for frame in FRAMES:
			if FileAccess.file_exists("res://assets/sprites/enemies/%s_%s.png" % [boss, frame]):
				count += 1
	assert_eq(count, 25, "all 25 boss animation frames present (got %d)" % count)
