extends GutTest

# Integration test: ClinicManager revival system (S7-006, fc64)
# Per party-system.md §3.8 + sprint-07-006 plan
# Verifies:
#   - 3 pilots start ACTIVE
#   - knock_out_pilot transitions ACTIVE → KNOCKED_OUT
#   - Cannot knock out main character (ranger)
#   - Revival cost = max(floor(gold × 0.25), 100)
#   - revive_pilot with insufficient gold fails (ERR_DOES_NOT_EXIST)
#   - revive_pilot with sufficient gold succeeds, pilot returns to ACTIVE
#   - get_knocked_out_pilots returns the queue
#   - mark_pilot_dead is permanent (cannot be revived)
#   - Save/Load roundtrip preserves gold + pilot states + queue

const CM_PATH: String = "/root/ClinicManager"

func _cm() -> Node:
	var cm: Node = get_node_or_null(CM_PATH)
	if cm == null:
		pending("ClinicManager autoload missing")
		return null
	return cm

func test_three_pilots_start_active() -> void:
	var cm: Node = _cm()
	if cm == null:
		return
	assert_eq(int(cm.get_pilot_state(&"ranger")), 0, "ranger ACTIVE")
	assert_eq(int(cm.get_pilot_state(&"frostbite")), 0, "frostbite ACTIVE")
	assert_eq(int(cm.get_pilot_state(&"bomber")), 0, "bomber ACTIVE")
	assert_false(cm.has_pending_revivals(), "no pending revivals at start")

func test_knock_out_pilot() -> void:
	var cm: Node = _cm()
	if cm == null:
		return
	cm.knock_out_pilot(&"frostbite")
	assert_true(cm.is_knocked_out(&"frostbite"), "frostbite knocked out")
	assert_true(cm.has_pending_revivals(), "has pending revivals")
	var queue: Array = cm.get_knocked_out_pilots()
	assert_eq(queue.size(), 1, "1 pilot in queue")
	assert_eq(String(queue[0]), "frostbite", "frostbite in queue")
	# Other pilots unaffected
	assert_true(cm.is_active(&"ranger"), "ranger still active")
	assert_true(cm.is_active(&"bomber"), "bomber still active")

func test_cannot_knock_out_main_character() -> void:
	var cm: Node = _cm()
	if cm == null:
		return
	cm.knock_out_pilot(&"ranger")
	# Should be rejected (push_error fires, but state preserved)
	assert_true(cm.is_active(&"ranger"), "ranger cannot be knocked out")
	assert_false(cm.is_knocked_out(&"ranger"), "ranger is not knocked out")
	assert_false(cm.has_pending_revivals(), "no pending revivals")

func test_revival_cost_25_percent_with_minimum() -> void:
	var cm: Node = _cm()
	if cm == null:
		return
	# 100 gold → cost = max(floor(100 × 0.25), 100) = max(25, 100) = 100
	cm._gold = 100
	assert_eq(cm.get_revival_cost(), 100, "100 gold → cost 100 (min kicks in)")
	# 400 gold → cost = max(floor(400 × 0.25), 100) = max(100, 100) = 100
	cm._gold = 400
	assert_eq(cm.get_revival_cost(), 100, "400 gold → cost 100")
	# 800 gold → cost = max(floor(800 × 0.25), 100) = max(200, 100) = 200
	cm._gold = 800
	assert_eq(cm.get_revival_cost(), 200, "800 gold → cost 200")
	# 1000 gold → cost = max(floor(1000 × 0.25), 100) = max(250, 100) = 250
	cm._gold = 1000
	assert_eq(cm.get_revival_cost(), 250, "1000 gold → cost 250")
	# 50 gold → cost = max(floor(50 × 0.25), 100) = max(12, 100) = 100
	cm._gold = 50
	assert_eq(cm.get_revival_cost(), 100, "50 gold → cost 100 (min kicks in)")
	# 0 gold → cost = max(0, 100) = 100
	cm._gold = 0
	assert_eq(cm.get_revival_cost(), 100, "0 gold → cost 100")

func test_revive_insufficient_gold_fails() -> void:
	var cm: Node = _cm()
	if cm == null:
		return
	cm.add_gold(50)  # not enough (cost = 100)
	cm.knock_out_pilot(&"frostbite")
	var err: int = cm.revive_pilot(&"frostbite")
	assert_ne(err, OK, "revive fails with insufficient gold")
	assert_eq(cm.get_gold(), 50, "gold not deducted")
	assert_true(cm.is_knocked_out(&"frostbite"), "frostbite still knocked out")

func test_revive_sufficient_gold_succeeds() -> void:
	var cm: Node = _cm()
	if cm == null:
		return
	cm.add_gold(500)  # cost will be 125
	cm.knock_out_pilot(&"frostbite")
	var expected_cost: int = cm.get_revival_cost()
	var err: int = cm.revive_pilot(&"frostbite")
	assert_eq(err, OK, "revive succeeds")
	assert_eq(cm.get_gold(), 500 - expected_cost, "gold deducted")
	assert_true(cm.is_active(&"frostbite"), "frostbite ACTIVE again")
	assert_false(cm.has_pending_revivals(), "queue empty after revive")

func test_revive_only_knocked_out_can_be_revived() -> void:
	var cm: Node = _cm()
	if cm == null:
		return
	cm.add_gold(500)
	# frostbite is ACTIVE — can't revive
	var err: int = cm.revive_pilot(&"frostbite")
	assert_ne(err, OK, "cannot revive active pilot")

func test_revive_unknown_pilot_fails() -> void:
	var cm: Node = _cm()
	if cm == null:
		return
	var err: int = cm.revive_pilot(&"unknown_pilot")
	assert_eq(err, ERR_INVALID_PARAMETER, "unknown pilot returns ERR_INVALID_PARAMETER")

func test_mark_pilot_dead() -> void:
	var cm: Node = _cm()
	if cm == null:
		return
	cm.knock_out_pilot(&"frostbite")
	cm.mark_pilot_dead(&"frostbite")
	assert_true(cm.is_dead(&"frostbite"), "frostbite is dead")
	# Cannot revive a dead pilot
	cm.add_gold(500)
	var err: int = cm.revive_pilot(&"frostbite")
	assert_ne(err, OK, "dead pilot cannot be revived")

func test_save_load_roundtrip() -> void:
	var cm: Node = _cm()
	if cm == null:
		return
	cm.add_gold(750)
	cm.knock_out_pilot(&"frostbite")
	cm.knock_out_pilot(&"bomber")
	var snap: Dictionary = cm.get_state_snapshot()
	assert_eq(int(snap.get("gold", 0)), 750, "gold in snap")
	# pilot_states stored as Dict[str, int]
	var states: Dictionary = snap["pilot_states"]
	assert_eq(int(states.get("frostbite", -1)), 1, "frostbite state = KNOCKED_OUT in snap")
	assert_eq(int(states.get("bomber", -1)), 1, "bomber state = KNOCKED_OUT in snap")
	assert_eq(int(states.get("ranger", -1)), 0, "ranger state = ACTIVE in snap")
	# queue has both
	var queue: Array = snap["revival_queue"]
	assert_eq(queue.size(), 2, "2 pilots in queue")
	# Mutate
	cm.add_gold(10000)
	cm.knock_out_pilot(&"ranger")  # rejected, but state still ACTIVE
	# Reload
	var result: int = cm.load_snapshot(snap)
	assert_eq(result, OK, "load returns OK")
	assert_eq(cm.get_gold(), 750, "gold restored")
	assert_true(cm.is_knocked_out(&"frostbite"), "frostbite restored as knocked out")
	assert_true(cm.is_knocked_out(&"bomber"), "bomber restored as knocked out")
	assert_true(cm.is_active(&"ranger"), "ranger restored as active")

func test_load_snapshot_migration_default_all_active() -> void:
	# Old saves without pilot_states should default all to ACTIVE
	var cm: Node = _cm()
	if cm == null:
		return
	var old_snap: Dictionary = {"gold": 100}  # no pilot_states key
	var err: int = cm.load_snapshot(old_snap)
	assert_eq(err, OK, "load returns OK")
	assert_eq(cm.get_gold(), 100, "gold loaded")
	# All 3 default pilots should be ACTIVE
	assert_true(cm.is_active(&"ranger"), "ranger defaulted to active")
	assert_true(cm.is_active(&"frostbite"), "frostbite defaulted to active")
	assert_true(cm.is_active(&"bomber"), "bomber defaulted to active")

func test_add_and_spend_gold() -> void:
	var cm: Node = _cm()
	if cm == null:
		return
	cm.add_gold(1000)
	assert_eq(cm.get_gold(), 1000, "gold added")
	assert_true(cm.spend_gold(300), "spend 300 succeeds")
	assert_eq(cm.get_gold(), 700, "gold after spend")
	assert_false(cm.spend_gold(9999), "spend too much fails")
	assert_eq(cm.get_gold(), 700, "gold unchanged after failed spend")

func test_add_negative_gold_ignored() -> void:
	var cm: Node = _cm()
	if cm == null:
		return
	cm.add_gold(100)
	cm.add_gold(-50)
	assert_eq(cm.get_gold(), 100, "negative add ignored")

func test_pilot_state_changed_signal_fires() -> void:
	var cm: Node = _cm()
	if cm == null:
		return
	var emitted_pid: StringName = &""
	var emitted_state: int = -1
	var handler: Callable = func(pid: StringName, new_state: int) -> void:
		emitted_pid = pid
		emitted_state = new_state
	cm.pilot_state_changed.connect(handler)
	cm.knock_out_pilot(&"frostbite")
	assert_eq(String(emitted_pid), "frostbite", "signal fired with frostbite")
	assert_eq(emitted_state, 1, "signal fired with KNOCKED_OUT state")
	cm.pilot_state_changed.disconnect(handler)

func test_gold_changed_signal_fires() -> void:
	var cm: Node = _cm()
	if cm == null:
		return
	var emitted_amount: int = -1
	var handler: Callable = func(amount: int) -> void:
		emitted_amount = amount
	cm.gold_changed.connect(handler)
	cm.add_gold(500)
	assert_eq(emitted_amount, 500, "gold_changed signal fired with 500")
	cm.gold_changed.disconnect(handler)

func test_pilot_revived_signal_fires_with_gold_spent() -> void:
	var cm: Node = _cm()
	if cm == null:
		return
	cm.add_gold(800)
	cm.knock_out_pilot(&"frostbite")
	var emitted_pid: StringName = &""
	var emitted_cost: int = -1
	var handler: Callable = func(pid: StringName, gold_spent: int) -> void:
		emitted_pid = pid
		emitted_cost = gold_spent
	cm.pilot_revived.connect(handler)
	cm.revive_pilot(&"frostbite")
	assert_eq(String(emitted_pid), "frostbite", "revived signal with frostbite")
	assert_eq(emitted_cost, 200, "revived signal with cost 200 (800 × 0.25)")
	cm.pilot_revived.disconnect(handler)

func test_revival_cost_decreases_with_gold() -> void:
	# Each revival deducts gold, so the next cost is lower
	var cm: Node = _cm()
	if cm == null:
		return
	cm.add_gold(1000)
	cm.knock_out_pilot(&"frostbite")
	cm.knock_out_pilot(&"bomber")
	# First revival: cost = max(floor(1000 × 0.25), 100) = 250
	var cost1: int = cm.get_revival_cost()
	assert_eq(cost1, 250, "first revival cost 250")
	cm.revive_pilot(&"frostbite")
	# After first revive: gold = 750, second revival cost = max(floor(750 × 0.25), 100) = 187
	var cost2: int = cm.get_revival_cost()
	assert_eq(cost2, 187, "second revival cost 187 (gold 750 × 0.25)")