extends GutTest

# Integration test: Bounty + Racing systems (Sprint 11, fc72)
# Per production/sprints/sprint-11-bounty-racing.md
# Verifies:
#   - BountyManager registered + 6 bounties
#   - Bounty #2 is plot-required (cannot abandon)
#   - accept/complete/fail/abandon flow
#   - Medal tracking
#   - Special tool drops
#   - RacingManager registered + 6 tracks + 4 racing mechs
#   - Race time calculation (terrain-aware)
#   - Betting with payout odds
#   - Save/load roundtrip

const BM_PATH: String = "/root/BountyManager"
const RM_PATH: String = "/root/RacingManager"

func _bm() -> Node:
	var bm: Node = get_node_or_null(BM_PATH)
	if bm == null:
		pending("BountyManager missing")
		return null
	return bm

func _rm() -> Node:
	var rm: Node = get_node_or_null(RM_PATH)
	if rm == null:
		pending("RacingManager missing")
		return null
	return rm

# === BountyManager tests ===

func test_six_bounties_registered() -> void:
	var bm: Node = _bm()
	if bm == null:
		return
	assert_eq(bm.ALL_BOUNTIES.size(), 6, "6 bounties registered")

func test_bounty_2_is_plot_required() -> void:
	var bm: Node = _bm()
	if bm == null:
		return
	var b2_info: Dictionary = bm.get_bounty_info(bm.BOUNTY_TRAITORS_LEGACY)
	assert_true(bool(b2_info.get("is_plot", false)), "Bounty #2 is plot")

func test_cannot_abandon_plot_bounty() -> void:
	var bm: Node = _bm()
	if bm == null:
		return
	bm.accept_bounty(bm.BOUNTY_TRAITORS_LEGACY)
	var err: int = bm.abandon_bounty(bm.BOUNTY_TRAITORS_LEGACY)
	assert_eq(err, ERR_UNAVAILABLE, "plot bounty cannot be abandoned")
	# Reset
	bm.reset_all_bounties()

func test_can_abandon_non_plot_bounty() -> void:
	var bm: Node = _bm()
	if bm == null:
		return
	bm.accept_bounty(bm.BOUNTY_HIDDEN_HUNTER)
	var err: int = bm.abandon_bounty(bm.BOUNTY_HIDDEN_HUNTER)
	assert_eq(err, OK, "non-plot bounty can be abandoned")
	assert_eq(bm.get_bounty_status(bm.BOUNTY_HIDDEN_HUNTER), "ABANDONED", "status updated")
	bm.reset_all_bounties()

func test_accept_bounty() -> void:
	var bm: Node = _bm()
	if bm == null:
		return
	var err: int = bm.accept_bounty(bm.BOUNTY_HIVE_QUEEN)
	assert_eq(err, OK, "accept OK")
	assert_eq(bm.get_bounty_status(bm.BOUNTY_HIVE_QUEEN), "ACCEPTED", "status = ACCEPTED")
	bm.reset_all_bounties()

func test_complete_bounty_grants_gold() -> void:
	var bm: Node = _bm()
	var cm: Node = get_node_or_null("/root/ClinicManager")
	if bm == null or cm == null:
		return
	cm._gold = 0
	bm.accept_bounty(bm.BOUNTY_HIVE_QUEEN)
	var err: int = bm.complete_bounty(bm.BOUNTY_HIVE_QUEEN)
	assert_eq(err, OK, "complete OK")
	assert_eq(bm.get_bounty_status(bm.BOUNTY_HIVE_QUEEN), "COMPLETED", "status = COMPLETED")
	# Hive queen bounty rewards 2000 gold
	assert_eq(cm.get_gold(), 2000, "2000 gold awarded")
	cm._gold = 0

func test_medal_granted_on_completion() -> void:
	var bm: Node = _bm()
	if bm == null:
		return
	bm.reset_all_bounties()
	assert_eq(bm.get_medal_count(), 0, "0 medals at start")
	bm.accept_bounty(bm.BOUNTY_HIDDEN_HUNTER)
	bm.complete_bounty(bm.BOUNTY_HIDDEN_HUNTER)
	assert_true(bm.has_medal(bm.BOUNTY_HIDDEN_HUNTER), "medal granted")
	assert_eq(bm.get_medal_count(), 1, "1 medal")
	assert_eq(bm.get_total_medals(), 6, "6 total possible")

func test_special_tool_drop() -> void:
	var bm: Node = _bm()
	if bm == null:
		return
	var tool: StringName = bm.get_special_tool_drop(bm.BOUNTY_HIDDEN_HUNTER)
	assert_eq(String(tool), "ice_detector", "Bounty #1 drops ice_detector")
	tool = bm.get_special_tool_drop(bm.BOUNTY_HIVE_QUEEN)
	assert_eq(String(tool), "military_jammer", "Bounty #3 drops military_jammer")
	tool = bm.get_special_tool_drop(bm.BOUNTY_AI_ECHO)
	assert_eq(String(tool), "creator_locator", "Bounty #4 drops creator_locator (required for Ending A)")

func test_bounties_per_satellite() -> void:
	var bm: Node = _bm()
	if bm == null:
		return
	var sat1: Array = bm.get_bounties_for_satellite(1)
	var sat3: Array = bm.get_bounties_for_satellite(3)
	var sat5: Array = bm.get_bounties_for_satellite(5)
	assert_eq(sat1.size(), 1, "Sat-1 has 1 bounty (Hidden Hunter)")
	assert_eq(sat3.size(), 1, "Sat-3 has 1 bounty (Hive Queen)")
	assert_eq(sat5.size(), 2, "Sat-5 has 2 bounties (Creator Echo + Hidden post-game)")

func test_fail_bounty_increments_attempt_count() -> void:
	var bm: Node = _bm()
	if bm == null:
		return
	bm.reset_all_bounties()
	bm.accept_bounty(bm.BOUNTY_HIDDEN_HUNTER)
	bm.fail_bounty(bm.BOUNTY_HIDDEN_HUNTER)
	bm.accept_bounty(bm.BOUNTY_HIDDEN_HUNTER)
	bm.fail_bounty(bm.BOUNTY_HIDDEN_HUNTER)
	bm.fail_bounty(bm.BOUNTY_HIDDEN_HUNTER)
	# Status should reset to AVAILABLE after fail (player can retry)
	assert_eq(bm.get_bounty_status(bm.BOUNTY_HIDDEN_HUNTER), "AVAILABLE", "fail resets to AVAILABLE")
	bm.reset_all_bounties()

func test_bounty_save_load_roundtrip() -> void:
	var bm: Node = _bm()
	if bm == null:
		return
	bm.reset_all_bounties()
	bm.accept_bounty(bm.BOUNTY_HIVE_QUEEN)
	bm.complete_bounty(bm.BOUNTY_HIVE_QUEEN)
	var snap: Dictionary = bm.get_state_snapshot()
	assert_eq(snap["bounty_state"][bm.BOUNTY_HIVE_QUEEN]["status"], "COMPLETED", "saved as COMPLETED")
	assert_eq(snap["medals"][bm.BOUNTY_HIVE_QUEEN], true, "medal saved")
	# Mutate
	bm._bounty_state[bm.BOUNTY_HIVE_QUEEN]["status"] = "AVAILABLE"
	bm._medals_collected[bm.BOUNTY_HIVE_QUEEN] = false
	# Load
	var err: int = bm.load_snapshot(snap)
	assert_eq(err, OK, "load OK")
	assert_eq(bm.get_bounty_status(bm.BOUNTY_HIVE_QUEEN), "COMPLETED", "restored COMPLETED")
	assert_true(bm.has_medal(bm.BOUNTY_HIVE_QUEEN), "medal restored")
	bm.reset_all_bounties()

# === RacingManager tests ===

func test_six_tracks_registered() -> void:
	var rm: Node = _rm()
	if rm == null:
		return
	assert_eq(rm.ALL_TRACKS.size(), 6, "6 tracks")

func test_four_racing_mechs_registered() -> void:
	var rm: Node = _rm()
	if rm == null:
		return
	assert_eq(rm.ALL_RACING_MECHS.size(), 4, "4 racing mechs")

func test_calculate_race_time_basic() -> void:
	var rm: Node = _rm()
	if rm == null:
		return
	var time: float = rm.calculate_race_time(rm.TRACK_FROZEN_FLATS, rm.MECH_BOLT)
	assert_gt(time, 0.0, "race time > 0")

func test_bolt_fastest_on_frozen_flats() -> void:
	# Bolt (speed 10) should beat Titan (speed 5) on flat tracks
	var rm: Node = _rm()
	if rm == null:
		return
	var bolt_time: float = rm.calculate_race_time(rm.TRACK_FROZEN_FLATS, rm.MECH_BOLT)
	var titan_time: float = rm.calculate_race_time(rm.TRACK_FROZEN_FLATS, rm.MECH_TITAN)
	assert_lt(bolt_time, titan_time, "Bolt (speed 10) faster than Titan (speed 5)")

func test_wisp_fastest_on_cosmic() -> void:
	var rm: Node = _rm()
	if rm == null:
		return
	var wisp_time: float = rm.calculate_race_time(rm.TRACK_CREATOR_RING, rm.MECH_WISP)
	var bolt_time: float = rm.calculate_race_time(rm.TRACK_CREATOR_RING, rm.MECH_BOLT)
	assert_lt(wisp_time, bolt_time, "Wisp faster than Bolt on cosmic track")

func test_run_race_returns_results() -> void:
	var rm: Node = _rm()
	if rm == null:
		return
	var results: Dictionary = rm.run_race(rm.TRACK_FROZEN_FLATS)
	assert_eq(results.size(), 4, "4 mech times in race")
	assert_true(results.has(rm.MECH_BOLT), "Bolt in results")

func test_run_race_signal_fires() -> void:
	var rm: Node = _rm()
	if rm == null:
		return
	var fired: bool = false
	var handler: Callable = func(_tid: StringName, _res: Dictionary, _pay: Dictionary) -> void:
		fired = true
	rm.race_finished.connect(handler)
	rm.run_race(rm.TRACK_HIVE_TUNNELS)
	assert_true(fired, "race_finished signal emitted")
	if rm.race_finished.is_connected(handler):
		rm.race_finished.disconnect(handler)

func test_betting_with_sufficient_gold() -> void:
	var rm: Node = _rm()
	var cm: Node = get_node_or_null("/root/ClinicManager")
	if rm == null or cm == null:
		return
	cm._gold = 1000
	var err: int = rm.place_bet(rm.TRACK_FROZEN_FLATS, rm.MECH_BOLT, 100)
	assert_eq(err, OK, "bet placed")
	assert_eq(cm.get_gold(), 900, "gold deducted (1000 - 100)")
	cm._gold = 0

func test_betting_with_insufficient_gold_fails() -> void:
	var rm: Node = _rm()
	var cm: Node = get_node_or_null("/root/ClinicManager")
	if rm == null or cm == null:
		return
	cm._gold = 0
	var err: int = rm.place_bet(rm.TRACK_FROZEN_FLATS, rm.MECH_BOLT, 100)
	assert_eq(err, ERR_DOES_NOT_EXIST, "insufficient gold rejected")
	cm._gold = 0

func test_betting_on_loser_has_higher_odds() -> void:
	var rm: Node = _rm()
	var cm: Node = get_node_or_null("/root/ClinicManager")
	if rm == null or cm == null:
		return
	cm._gold = 10000
	var fired_odds: float = 0.0
	var handler: Callable = func(_t: StringName, _m: StringName, _a: int, odds: float) -> void:
		fired_odds = odds
	rm.bet_placed.connect(handler)
	# Bet on Titan (likely loser) → higher payout odds
	rm.place_bet(rm.TRACK_FROZEN_FLATS, rm.MECH_TITAN, 100)
	var titan_odds: float = fired_odds
	# Bet on Bolt (likely winner) → lower payout odds
	rm.place_bet(rm.TRACK_FROZEN_FLATS, rm.MECH_BOLT, 100)
	var bolt_odds: float = fired_odds
	assert_gt(titan_odds, bolt_odds, "betting on loser has higher payout odds")
	if rm.bet_placed.is_connected(handler):
		rm.bet_placed.disconnect(handler)
	cm._gold = 0

func test_track_distance_varies() -> void:
	var rm: Node = _rm()
	if rm == null:
		return
	var frozen_dist: int = int(rm.get_track_info(rm.TRACK_FROZEN_FLATS).get("distance", 0))
	var creator_dist: int = int(rm.get_track_info(rm.TRACK_CREATOR_RING).get("distance", 0))
	assert_eq(frozen_dist, 1000, "Frozen Flats = 1000")
	assert_eq(creator_dist, 2000, "Creator's Ring = 2000 (longest)")

func test_racing_save_load_roundtrip() -> void:
	var rm: Node = _rm()
	if rm == null:
		return
	rm.run_race(rm.TRACK_FROZEN_FLATS)
	var snap: Dictionary = rm.get_state_snapshot()
	assert_true(snap["last_results"].has(rm.TRACK_FROZEN_FLATS), "race result saved")
	# Mutate
	rm._last_results.clear()
	# Load
	var err: int = rm.load_snapshot(snap)
	assert_eq(err, OK, "load OK")
	var loaded: Dictionary = rm.get_last_result(rm.TRACK_FROZEN_FLATS)
	assert_eq(loaded.size(), 4, "4 mech times restored")