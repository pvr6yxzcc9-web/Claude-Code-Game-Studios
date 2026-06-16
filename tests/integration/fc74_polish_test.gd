extends GutTest

# Polish test (Sprint 12, fc74) — verifies the polish deliverables:
#   - RaceAnimation UI exists and instantiates
#   - PostCreditScene UI exists and has 4 endings data
#   - Generated BGMs exist on disk
#   - BGM file sizes are reasonable
#
# Per the post-feature-complete polish phase.

func test_race_animation_script_exists() -> void:
	assert_true(FileAccess.file_exists("res://src/ui/race_animation.gd"),
		"race_animation.gd exists")

func test_race_animation_can_instantiate() -> void:
	var RaceAnimation: Script = load("res://src/ui/race_animation.gd")
	if RaceAnimation == null:
		pending("Could not load RaceAnimation script")
		return
	var anim: Control = RaceAnimation.new()
	assert_not_null(anim, "RaceAnimation instantiated")
	assert_true(anim.has_method("start_animation"), "has start_animation method")
	assert_true(anim.has_method("close_animation"), "has close_animation method")
	anim.queue_free()

func test_race_animation_has_4_mech_lanes() -> void:
	var RaceAnimation: Script = load("res://src/ui/race_animation.gd")
	if RaceAnimation == null:
		return
	var anim: Control = RaceAnimation.new()
	anim._ready()
	assert_eq(anim.MECH_ORDER.size(), 4, "4 mech lanes")
	assert_eq(anim._mech_sprites.size(), 4, "4 mech sprites built")
	assert_eq(anim._progress_bars.size(), 4, "4 progress bars built")
	assert_eq(anim._track_lines.size(), 4, "4 track lanes built")
	anim.queue_free()

func test_post_credit_scene_script_exists() -> void:
	assert_true(FileAccess.file_exists("res://src/ui/post_credit_scene.gd"),
		"post_credit_scene.gd exists")

func test_post_credit_scene_can_instantiate() -> void:
	var PostCreditScene: Script = load("res://src/ui/post_credit_scene.gd")
	if PostCreditScene == null:
		pending("Could not load PostCreditScene script")
		return
	var pcs: Control = PostCreditScene.new()
	assert_not_null(pcs, "PostCreditScene instantiated")
	assert_true(pcs.has_method("play_post_credit"), "has play_post_credit method")
	assert_true(pcs.has_method("close_scene"), "has close_scene method")
	pcs.queue_free()

func test_post_credit_data_has_4_endings() -> void:
	var PostCreditScene: Script = load("res://src/ui/post_credit_scene.gd")
	if PostCreditScene == null:
		return
	var pcs: Control = PostCreditScene.new()
	assert_eq(pcs.POSTCREDIT_DATA.size(), 4, "4 endings in POSTCREDIT_DATA")
	for letter in ["A", "B", "C", "D"]:
		assert_true(pcs.POSTCREDIT_DATA.has(letter), "%s has data" % letter)
		var data: Dictionary = pcs.POSTCREDIT_DATA[letter]
		assert_true(data.has("title"), "%s has title" % letter)
		assert_true(data.has("subtitle"), "%s has subtitle" % letter)
		assert_true(data.has("body"), "%s has body text" % letter)
		assert_true(data.has("years_later"), "%s has years_later" % letter)
	pcs.queue_free()

func test_ending_a_years_later_is_10() -> void:
	var PostCreditScene: Script = load("res://src/ui/post_credit_scene.gd")
	var pcs: Control = PostCreditScene.new()
	var data: Dictionary = pcs.POSTCREDIT_DATA["A"]
	assert_eq(int(data["years_later"]), 10, "Ending A = 10 years later")
	pcs.queue_free()

func test_ending_b_years_later_is_1000() -> void:
	var PostCreditScene: Script = load("res://src/ui/post_credit_scene.gd")
	var pcs: Control = PostCreditScene.new()
	var data: Dictionary = pcs.POSTCREDIT_DATA["B"]
	assert_eq(int(data["years_later"]), 1000, "Ending B = 1000 years later")
	pcs.queue_free()

func test_ending_c_years_later_is_50() -> void:
	var PostCreditScene: Script = load("res://src/ui/post_credit_scene.gd")
	var pcs: Control = PostCreditScene.new()
	var data: Dictionary = pcs.POSTCREDIT_DATA["C"]
	assert_eq(int(data["years_later"]), 50, "Ending C = 50 years later")
	pcs.queue_free()

func test_ending_d_years_later_is_1() -> void:
	var PostCreditScene: Script = load("res://src/ui/post_credit_scene.gd")
	var pcs: Control = PostCreditScene.new()
	var data: Dictionary = pcs.POSTCREDIT_DATA["D"]
	assert_eq(int(data["years_later"]), 1, "Ending D = 1 year later")
	pcs.queue_free()

# === BGM file existence + size verification ===

func test_all_bgms_exist() -> void:
	var bgms: Array[String] = [
		"res://assets/audio/music/frozen_reactor.wav",
		"res://assets/audio/music/hive_heart.wav",
		"res://assets/audio/music/wreckage_echo.wav",
		"res://assets/audio/music/creators_dream.wav",
	]
	for bgm in bgms:
		assert_true(FileAccess.file_exists(bgm), "%s exists" % bgm)

func test_creators_dream_is_60s_longer() -> void:
	# Per S10-011, creators_dream should be 60s (vs 30s for others)
	# Read WAV header to get duration
	var f: FileAccess = FileAccess.open("res://assets/audio/music/creators_dream.wav", FileAccess.READ)
	if f == null:
		pending("Could not open creators_dream.wav")
		return
	# WAV header: byte_rate at offset 28, sample count at offset 40
	f.seek(28)
	var byte_rate: int = f.get_32()
	f.seek(40)
	var data_size: int = f.get_32()
	# 16-bit mono → 2 bytes per sample
	var duration_sec: float = float(data_size) / float(byte_rate)
	# Should be ~60s
	assert_gt(duration_sec, 55.0, "creators_dream ≥ 55s")
	assert_lt(duration_sec, 65.0, "creators_dream ≤ 65s")
	f.close()

func test_satellite_bgms_are_30s() -> void:
	var bgms: Array[String] = [
		"res://assets/audio/music/frozen_reactor.wav",
		"res://assets/audio/music/hive_heart.wav",
		"res://assets/audio/music/wreckage_echo.wav",
	]
	for bgm in bgms:
		var f: FileAccess = FileAccess.open(bgm, FileAccess.READ)
		if f == null:
			continue
		f.seek(28)
		var byte_rate: int = f.get_32()
		f.seek(40)
		var data_size: int = f.get_32()
		var duration_sec: float = float(data_size) / float(byte_rate)
		assert_gt(duration_sec, 25.0, "%s ≥ 25s" % bgm)
		assert_lt(duration_sec, 35.0, "%s ≤ 35s" % bgm)
		f.close()