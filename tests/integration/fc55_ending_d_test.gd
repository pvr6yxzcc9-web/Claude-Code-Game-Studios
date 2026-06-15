extends GutTest

# FC-55 4th ending (S6-103)
# Pins that ending D is now reachable:
#   1) dlg_ending_D.tres registered
#   2) MetaState has log_fragments_count() method
#   3) log_fragments_count() excludes boss-victory fragments
#   4) EndingController.determine_ending() returns D when 0 logs
#   5) Returns B when 1+ logs
#   6) Returns A when >= 6 fragments (boss + 3 logs)
#   7) dlg_ending_D.tres has the "ignorant victory" text

var _main: Node = null
var _meta: Node = null
var _ending: Node = null
var _reg: Node = null

func before_all() -> void:
	_main = load("res://src/main.tscn").instantiate()
	get_tree().root.add_child(_main)
	await get_tree().process_frame
	await get_tree().process_frame
	_meta = get_node("/root/MetaState")
	_ending = get_node("/root/EndingController")
	_reg = get_node("/root/ResourceRegistry")

func after_all() -> void:
	if _main != null:
		_main.queue_free()
		_main = null

# 1) D ending registered

func test_ending_d_registered() -> void:
	var d: Resource = _reg.get_resource(&"dlg_ending_D")
	assert_not_null(d, "dlg_ending_D registered")

# 2) MetaState has log_fragments_count

func test_meta_state_has_log_fragments_count() -> void:
	assert_true(_meta.has_method("log_fragments_count"),
		"MetaState has log_fragments_count method")

# 3) log_fragments_count excludes boss fragments

func test_log_fragments_count_excludes_boss() -> void:
	# Reset state
	_meta.unlocked.clear()
	# Add 1 boss-victory + 1 log fragment
	_meta.mark_unlocked(&"fragment_what_was_carried")  # boss
	_meta.mark_unlocked(&"fragment_the_convoy")  # log
	assert_eq(int(_meta.log_fragments_count()), 1, "1 log fragment counted")
	# Add 2 more boss, no new logs
	_meta.mark_unlocked(&"fragment_the_truth")
	_meta.mark_unlocked(&"fragment_engineer_last_stand")
	assert_eq(int(_meta.log_fragments_count()), 1, "still 1 log (boss don't count)")

# 4) Determine D with 0 logs

func test_determine_ending_returns_d_for_0_logs() -> void:
	# Reset
	_meta.unlocked.clear()
	# Simulate boss victory (3 boss-victory fragments, 0 logs)
	_meta.mark_unlocked(&"fragment_what_was_carried")
	_meta.mark_unlocked(&"fragment_the_truth")
	_meta.mark_unlocked(&"fragment_engineer_last_stand")
	# Now determine
	var chosen: StringName = _ending.determine_ending()
	assert_eq(chosen, &"dlg_ending_D", "3 boss + 0 logs -> ending D")

# 5) Returns B with 1+ logs

func test_determine_ending_returns_b_with_logs() -> void:
	_meta.unlocked.clear()
	_meta.mark_unlocked(&"fragment_what_was_carried")
	_meta.mark_unlocked(&"fragment_the_truth")
	_meta.mark_unlocked(&"fragment_engineer_last_stand")
	_meta.mark_unlocked(&"fragment_the_convoy")  # 1 log
	var chosen: StringName = _ending.determine_ending()
	assert_eq(chosen, &"dlg_ending_B", "3 boss + 1 log -> ending B (not D)")

# 6) Returns A with 3+ logs

func test_determine_ending_returns_a_with_3_logs() -> void:
	_meta.unlocked.clear()
	_meta.mark_unlocked(&"fragment_what_was_carried")
	_meta.mark_unlocked(&"fragment_the_truth")
	_meta.mark_unlocked(&"fragment_engineer_last_stand")
	_meta.mark_unlocked(&"fragment_the_convoy")
	_meta.mark_unlocked(&"fragment_marlows_daughter")
	_meta.mark_unlocked(&"fragment_the_seal")
	var chosen: StringName = _ending.determine_ending()
	assert_eq(chosen, &"dlg_ending_A", "3 boss + 3 logs -> ending A")

# 7) D ending text mentions "ignorant"

func test_ending_d_text_mentions_ignorant() -> void:
	var d: Resource = _reg.get_resource(&"dlg_ending_D")
	if d == null:
		pending("D not registered")
		return
	# The dialogue tree has a "ending" node
	var nodes: Dictionary = d.get("nodes")
	if nodes == null or not nodes.has("ending"):
		pending("D tree missing 'ending' node")
		return
	var text: String = String(nodes["ending"].get("text", ""))
	assert_true(text.to_lower().contains("ignorant") or text.to_lower().contains("no idea") or text.to_lower().contains("won nothing"),
		"D ending mentions ignorant/no-idea/won-nothing themes")
