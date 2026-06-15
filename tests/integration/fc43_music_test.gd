extends GutTest

# FC-43 Music tracks (S6-011)
# Pins that MusicPlayer autoload works:
#   1) 3 .wav music files exist (title/exploration/battle)
#   2) MusicPlayer autoload exists
#   3) MusicPlayer loads 3 streams on _ready
#   4) state_exploration -> exploration track
#   5) state_battle -> battle track
#   6) state_title -> title track
#   7) state_dialogue keeps current track (no music change)
#   8) set_enabled(false) stops playback
#   9) stop() clears current track

var _mp: Node = null
var _sm: Node = null

func before_all() -> void:
	_mp = get_node_or_null("/root/MusicPlayer")
	if _mp == null:
		var main: Node = load("res://src/main.tscn").instantiate()
		get_tree().root.add_child(main)
		await get_tree().process_frame
		_mp = get_node_or_null("/root/MusicPlayer")
	_sm = get_node("/root/GameStateMachine")

func after_all() -> void:
	pass

# 1) Asset presence

func test_music_files_exist() -> void:
	for name in ["title", "exploration", "battle"]:
		var path: String = "res://assets/audio/music/%s.wav" % name
		assert_true(ResourceLoader.exists(path), "%s.wav exists" % name)

# 2) Autoload registered

func test_music_player_autoload_exists() -> void:
	assert_not_null(_mp, "MusicPlayer autoload registered")

# 3) Streams loaded

func test_music_player_loaded_3_tracks() -> void:
	assert_eq(_mp._streams.size(), 3, "3 music streams loaded")

# 4-6) State -> track mapping

func test_state_exploration_loads_exploration_track() -> void:
	_sm.transition_to(&"state_exploration")
	await get_tree().process_frame
	assert_eq(_mp.current_track(), &"exploration", "state_exploration -> exploration track")

func test_state_battle_loads_battle_track() -> void:
	_sm.transition_to(&"state_battle")
	await get_tree().process_frame
	assert_eq(_mp.current_track(), &"battle", "state_battle -> battle track")

func test_state_title_loads_title_track() -> void:
	_sm.transition_to(&"state_title")
	await get_tree().process_frame
	assert_eq(_mp.current_track(), &"title", "state_title -> title track")

# 7) Dialogue/terminal keep current track (no music swap)

func test_state_dialogue_keeps_current_track() -> void:
	# Setup: get into exploration
	_sm.transition_to(&"state_exploration")
	await get_tree().process_frame
	# Now go to dialogue
	if _sm.ALLOWED_TRANSITIONS[&"state_exploration"].has(&"state_dialogue"):
		_sm.transition_to(&"state_dialogue")
		await get_tree().process_frame
		assert_eq(_mp.current_track(), &"exploration", "state_dialogue keeps exploration track")
		# Cleanup
		_sm.transition_to(&"state_exploration")
		await get_tree().process_frame
	else:
		pending("state_exploration -> state_dialogue not allowed; skipping")

# 8) Disable stops playback

func test_disabled_music_stops_playback() -> void:
	_sm.transition_to(&"state_battle")
	await get_tree().process_frame
	_mp.set_enabled(false)
	await get_tree().process_frame
	# Player should not be playing
	if _mp._player != null:
		assert_false(_mp._player.playing, "disabled music is not playing")
	# Re-enable
	_mp.set_enabled(true)

# 9) stop() clears track

func test_stop_clears_current_track() -> void:
	_sm.transition_to(&"state_exploration")
	await get_tree().process_frame
	_mp.stop()
	assert_eq(_mp.current_track(), &"", "stop() clears current_track")
