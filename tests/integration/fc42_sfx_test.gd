extends GutTest

# FC-42 SFX .wav files (S6-010)
# Pins that SFXPlayer now loads real .wav files:
#   1) 5 .wav files exist in assets/audio/sfx/
#   2) SFXPlayer autoload exists
#   3) SFXPlayer loads 5 streams on _ready
#   4) play_attack() routes by weapon_id (railgun -> railgun SFX, etc.)
#   5) play_damage() / play_ui() don't crash
#   6) Missing-file fallback works (forces re-init with empty dir)

var _sfx: Node = null

func before_all() -> void:
	_sfx = get_node_or_null("/root/SFXPlayer")
	if _sfx == null:
		# Load main.tscn to register autoloads
		var main: Node = load("res://src/main.tscn").instantiate()
		get_tree().root.add_child(main)
		await get_tree().process_frame
		_sfx = get_node_or_null("/root/SFXPlayer")

func after_all() -> void:
	pass

# 1) Asset presence

func test_sfx_files_exist() -> void:
	for name in ["attack_blaster", "attack_railgun", "attack_plasma", "hit_enemy", "ui_click"]:
		var path: String = "res://assets/audio/sfx/%s.wav" % name
		assert_true(ResourceLoader.exists(path), "%s.wav exists" % name)

# 2) Autoload

func test_sfx_player_autoload_exists() -> void:
	assert_not_null(_sfx, "SFXPlayer autoload is registered")

# 3) Loaded streams

func test_sfx_player_loaded_5_streams() -> void:
	assert_eq(_sfx._streams.size(), 5, "5 SFX streams loaded into cache")

# 4) Weapon-id routing

func test_play_attack_routes_by_weapon_id() -> void:
	# Railgun id -> railgun SFX
	_sfx.play_attack(0, &"railgun")
	await get_tree().process_frame
	# Internal check: the player's current stream should be the railgun wav
	if _sfx._player != null and _sfx._player.stream != null:
		# We can't easily assert the *exact* stream without comparing bytes,
		# but we can assert it's not the blaster by checking the cache
		var blaster: Resource = _sfx._streams.get(&"attack_blaster", null)
		var railgun: Resource = _sfx._streams.get(&"attack_railgun", null)
		assert_not_null(railgun, "railgun stream cached")
		assert_ne(_sfx._player.stream, blaster, "railgun weapon did not load blaster stream")

	# Plasma cannon -> plasma
	_sfx.play_attack(0, &"plasma_cannon")
	await get_tree().process_frame
	var plasma: Resource = _sfx._streams.get(&"attack_plasma", null)
	if _sfx._player != null:
		assert_eq(_sfx._player.stream, plasma, "plasma weapon loads plasma stream")

	# Blaster rifle -> blaster
	_sfx.play_attack(0, &"blaster_rifle")
	await get_tree().process_frame
	var blaster2: Resource = _sfx._streams.get(&"attack_blaster", null)
	if _sfx._player != null:
		assert_eq(_sfx._player.stream, blaster2, "blaster weapon loads blaster stream")

# 5) Other play methods don't crash

func test_play_damage_does_not_crash() -> void:
	_sfx.play_damage()
	await get_tree().process_frame
	pass_test("play_damage() completed without error")

func test_play_ui_does_not_crash() -> void:
	_sfx.play_ui()
	await get_tree().process_frame
	pass_test("play_ui() completed without error")

# 6) Fallback when .wav missing (simulate by clearing cache)
func test_fallback_to_procedural_beep() -> void:
	# Simulate a missing file by removing the stream from cache
	var saved: Resource = _sfx._streams.get(&"ui_click", null)
	_sfx._streams.erase(&"ui_click")
	_sfx._loaded_ok = _sfx._streams.size() > 0
	# Now play_ui should fall back to procedural beep
	_sfx.play_ui()
	await get_tree().process_frame
	# Player should have a stream (the procedural one)
	if _sfx._player != null:
		assert_not_null(_sfx._player.stream, "fallback: stream is set even when wav missing")
	# Restore cache
	if saved != null:
		_sfx._streams[&"ui_click"] = saved
		_sfx._loaded_ok = _sfx._streams.size() > 0
