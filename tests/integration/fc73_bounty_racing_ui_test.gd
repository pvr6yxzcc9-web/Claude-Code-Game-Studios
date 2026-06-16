extends GutTest

# Integration test: BountyBoard + RacingArena UI (Sprint 11 UI layer, fc73)
# Verifies the UI scenes exist, can be instantiated, and have correct
# structure for in-game interaction.

const BM_PATH: String = "/root/BountyManager"
const RM_PATH: String = "/root/RacingManager"

func _bm() -> Node:
	return get_node_or_null(BM_PATH)

func _rm() -> Node:
	return get_node_or_null(RM_PATH)

func test_bounty_board_ui_script_exists() -> void:
	assert_true(FileAccess.file_exists("res://src/ui/bounty_board_ui.gd"),
		"BountyBoardUI script exists")

func test_racing_arena_ui_script_exists() -> void:
	assert_true(FileAccess.file_exists("res://src/ui/racing_arena_ui.gd"),
		"RacingArenaUI script exists")

func test_bounty_board_ui_can_instantiate() -> void:
	var BountyBoardUI: Script = load("res://src/ui/bounty_board_ui.gd")
	if BountyBoardUI == null:
		pending("Could not load BountyBoardUI script")
		return
	var ui: Control = BountyBoardUI.new()
	assert_not_null(ui, "BountyBoardUI instantiated")
	assert_true(ui.has_method("open_bounty_board"), "has open method")
	assert_true(ui.has_method("close_bounty_board"), "has close method")
	ui.queue_free()

func test_racing_arena_ui_can_instantiate() -> void:
	var RacingArenaUI: Script = load("res://src/ui/racing_arena_ui.gd")
	if RacingArenaUI == null:
		pending("Could not load RacingArenaUI script")
		return
	var ui: Control = RacingArenaUI.new()
	assert_not_null(ui, "RacingArenaUI instantiated")
	assert_true(ui.has_method("open_arena"), "has open method")
	assert_true(ui.has_method("close_arena"), "has close method")
	ui.queue_free()

func test_bounty_board_handles_all_six_bounties() -> void:
	var bm: Node = _bm()
	if bm == null:
		pending("BountyManager missing")
		return
	# All 6 bounties have info, status, and special tool drops
	for bid in bm.ALL_BOUNTIES:
		var info: Dictionary = bm.get_bounty_info(bid)
		assert_gt(info.size(), 0, "%s has info" % bid)
		assert_ne(bm.get_bounty_status(bid), "", "%s has status" % bid)
		assert_ne(String(bm.get_special_tool_drop(bid)), "", "%s has tool drop" % bid)

func test_racing_arena_track_mech_pairings() -> void:
	var rm: Node = _rm()
	if rm == null:
		pending("RacingManager missing")
		return
	# All 6 tracks × 4 mechs = 24 valid pairings
	for tid in rm.ALL_TRACKS:
		for mid in rm.ALL_RACING_MECHS:
			var t: float = rm.calculate_race_time(tid, mid)
			assert_gt(t, 0.0, "%s × %s has valid race time" % [tid, mid])

func test_bounty_2_plots_correctness() -> void:
	# Bounty #2 is the ONLY plot-required bounty — Sat-2 → Sat-3 transition
	var bm: Node = _bm()
	if bm == null:
		return
	var plot_bounties: Array[StringName] = []
	for bid in bm.ALL_BOUNTIES:
		var info: Dictionary = bm.get_bounty_info(bid)
		if bool(info.get("is_plot", false)):
			plot_bounties.append(bid)
	assert_eq(plot_bounties.size(), 1, "exactly 1 plot bounty")
	assert_eq(String(plot_bounties[0]), "b2_traitors_legacy", "plot bounty is Traitor's Legacy")

func test_racing_payout_odds_vary() -> void:
	var rm: Node = _rm()
	if rm == null:
		return
	for tid in rm.ALL_TRACKS:
		var info: Dictionary = rm.get_track_info(tid)
		var odds: float = float(info.get("base_payout_odds", 0))
		assert_gt(odds, 1.0, "%s has payout odds > 1.0" % tid)
		assert_lt(odds, 5.0, "%s has payout odds < 5.0" % tid)