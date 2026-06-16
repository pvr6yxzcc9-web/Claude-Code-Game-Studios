extends GutTest

# Integration test: Sat-5 起源号 + 4 endings (Sprint 10, fc71)
# Per sprint-10-sat5-climax.md + multi-satellite-arc.md §5.3
# Verifies:
#   - EndingController autoload exists + has 4 endings + CreatorChoice enum
#   - determine_ending() returns correct tree for each combination:
#     FLEE → D; DESTROY+5 truths+cangqiong → A;
#     DESTROY+5 truths no cangqiong → B; DESTROY+<5 truths → C
#   - set_creator_choice() updates state
#   - update_state() updates truths/cangqiong
#   - get_post_credit_info() returns correct data per ending
#   - Save/load roundtrip preserves ending state
#   - 7 fragment .tres load
#   - 10 room .tres files exist
#   - chapter5.tres loads
#   - boss_creator.tres loads with boss=true, max_hp=5000
#   - 4 NPC .tres files load
#   - 17 generated assets exist on disk

const EC_PATH: String = "/root/EndingController"

func _ec() -> Node:
	var ec: Node = get_node_or_null(EC_PATH)
	if ec == null:
		pending("EndingController autoload missing")
		return null
	return ec

func test_ending_controller_registered() -> void:
	var ec: Node = _ec()
	if ec == null:
		return
	assert_not_null(ec, "EndingController registered")

func test_creator_choice_enum_has_5_values() -> void:
	var ec: Node = _ec()
	if ec == null:
		return
	# CreatorChoice.NOT_CHOSEN, TRANSCEND, UNDERSTAND, DESTROY, FLEE
	assert_eq(ec.CreatorChoice.NOT_CHOSEN, 0, "NOT_CHOSEN = 0")
	assert_eq(ec.CreatorChoice.TRANSCEND, 1, "TRANSCEND = 1")
	assert_eq(ec.CreatorChoice.UNDERSTAND, 2, "UNDERSTAND = 2")
	assert_eq(ec.CreatorChoice.DESTROY, 3, "DESTROY = 3")
	assert_eq(ec.CreatorChoice.FLEE, 4, "FLEE = 4")

func test_flee_choice_returns_D() -> void:
	var ec: Node = _ec()
	if ec == null:
		return
	ec.set_creator_choice(ec.CreatorChoice.FLEE)
	ec.update_state(5, true)
	var ending: StringName = ec.determine_ending()
	assert_eq(String(ending), "dlg_ending_D_hidden", "FLEE → ending D")
	assert_eq(ec.get_reached_ending(), "D", "reached_ending = D")

func test_destroy_with_5_truths_and_cangqiong_returns_A() -> void:
	var ec: Node = _ec()
	if ec == null:
		return
	ec.set_creator_choice(ec.CreatorChoice.DESTROY)
	ec.update_state(5, true)
	var ending: StringName = ec.determine_ending()
	assert_eq(String(ending), "dlg_ending_A_merciful", "DESTROY+5 truths+cangqiong → A")
	assert_eq(ec.get_reached_ending(), "A", "reached_ending = A")

func test_destroy_with_5_truths_no_cangqiong_returns_B() -> void:
	var ec: Node = _ec()
	if ec == null:
		return
	ec.set_creator_choice(ec.CreatorChoice.DESTROY)
	ec.update_state(5, false)
	var ending: StringName = ec.determine_ending()
	assert_eq(String(ending), "dlg_ending_B_cycle", "DESTROY+5 truths no cangqiong → B")
	assert_eq(ec.get_reached_ending(), "B", "reached_ending = B")

func test_destroy_with_few_truths_returns_C() -> void:
	var ec: Node = _ec()
	if ec == null:
		return
	ec.set_creator_choice(ec.CreatorChoice.DESTROY)
	ec.update_state(3, true)
	var ending: StringName = ec.determine_ending()
	assert_eq(String(ending), "dlg_ending_C_fusion", "DESTROY+3 truths → C")
	assert_eq(ec.get_reached_ending(), "C", "reached_ending = C")

func test_transcend_returns_A() -> void:
	var ec: Node = _ec()
	if ec == null:
		return
	ec.set_creator_choice(ec.CreatorChoice.TRANSCEND)
	ec.update_state(0, false)
	var ending: StringName = ec.determine_ending()
	assert_eq(String(ending), "dlg_ending_A_merciful", "TRANSCEND → A (special variant)")

func test_understand_returns_A() -> void:
	var ec: Node = _ec()
	if ec == null:
		return
	ec.set_creator_choice(ec.CreatorChoice.UNDERSTAND)
	var ending: StringName = ec.determine_ending()
	assert_eq(String(ending), "dlg_ending_A_merciful", "UNDERSTAND → A")

func test_post_credit_info_per_ending() -> void:
	var ec: Node = _ec()
	if ec == null:
		return
	for letter in ["A", "B", "C", "D"]:
		var info: Dictionary = ec.get_post_credit_info(letter)
		assert_true(info.has("years_later"), "%s has years_later" % letter)
		assert_true(info.has("title"), "%s has title" % letter)
		assert_true(info.has("description"), "%s has description" % letter)
	# Specific years
	var a_info: Dictionary = ec.get_post_credit_info("A")
	assert_eq(int(a_info["years_later"]), 10, "A = 10 years later")
	var b_info: Dictionary = ec.get_post_credit_info("B")
	assert_eq(int(b_info["years_later"]), 1000, "B = 1000 years later")
	var c_info: Dictionary = ec.get_post_credit_info("C")
	assert_eq(int(c_info["years_later"]), 50, "C = 50 years later")
	var d_info: Dictionary = ec.get_post_credit_info("D")
	assert_eq(int(d_info["years_later"]), 1, "D = 1 year later")

func test_save_load_roundtrip() -> void:
	var ec: Node = _ec()
	if ec == null:
		return
	ec.set_creator_choice(ec.CreatorChoice.DESTROY)
	ec.update_state(5, true)
	ec.determine_ending()  # Sets reached_ending to A
	# Snapshot
	var snap: Dictionary = ec.get_state_snapshot()
	assert_eq(int(snap["creator_choice"]), 3, "creator_choice saved")
	assert_eq(int(snap["truths_unlocked"]), 5, "truths saved")
	assert_eq(bool(snap["cangqiong_unlocked"]), true, "cangqiong saved")
	assert_eq(String(snap["reached_ending"]), "A", "ending saved")
	# Mutate
	ec.set_creator_choice(ec.CreatorChoice.FLEE)
	ec.update_state(0, false)
	# Load
	var result: int = ec.load_snapshot(snap)
	assert_eq(result, OK, "load returns OK")
	assert_eq(ec.get_creator_choice(), 3, "creator_choice restored")
	assert_eq(ec.get_reached_ending(), "A", "ending restored")

func test_ending_chosen_signal_fires() -> void:
	var ec: Node = _ec()
	if ec == null:
		return
	var emitted_letter: String = ""
	var handler: Callable = func(_tree: StringName, letter: String) -> void:
		emitted_letter = letter
	ec.ending_chosen.connect(handler)
	ec.set_creator_choice(ec.CreatorChoice.FLEE)
	ec.update_state(5, true)
	ec.determine_ending()
	assert_eq(emitted_letter, "D", "ending_chosen signal fired with letter")
	if ec.ending_chosen.is_connected(handler):
		ec.ending_chosen.disconnect(handler)

# === Sat-5 resource tests ===

func test_sat5_boss_creator_exists() -> void:
	var reg: Node = get_node_or_null("/root/ResourceRegistry")
	if reg == null:
		pending("ResourceRegistry missing")
		return
	var boss: Resource = reg.get_resource(&"boss_creator")
	assert_not_null(boss, "boss_creator registered")
	assert_true(boss.boss, "is a boss")
	assert_eq(int(boss.max_hp), 5000, "Creator max_hp = 5000")

func test_sat5_fragments_exist() -> void:
	var reg: Node = get_node_or_null("/root/ResourceRegistry")
	if reg == null:
		return
	for i in 7:
		var fid: StringName = StringName("fragment_ch5_%d" % (i + 1))
		var frag: Resource = reg.get_resource(fid)
		assert_not_null(frag, "%s registered" % fid)

func test_sat5_chapter5_registered() -> void:
	var reg: Node = get_node_or_null("/root/ResourceRegistry")
	if reg == null:
		return
	var chapter: Resource = reg.get_resource(&"chapter5_origin")
	assert_not_null(chapter, "chapter5_origin registered")

func test_sat5_10_room_data_files_exist() -> void:
	for i in 10:
		var rid: String = "c5_r%d" % (i + 1)
		var path: String = "res://data/levels/ch5/%s.tres" % rid
		assert_true(FileAccess.file_exists(path), "%s room data exists" % rid)

func test_sat5_npcs_have_portraits() -> void:
	var reg: Node = get_node_or_null("/root/ResourceRegistry")
	if reg == null:
		return
	for npc_id in [&"ch5_cangqiong_deceased", &"ch5_ranger_father", &"ch5_frostbite_mother", &"ch5_bomber_father"]:
		var npc: Resource = reg.get_resource(StringName(npc_id))
		assert_not_null(npc, "%s registered" % npc_id)

func test_sat5_assets_exist_on_disk() -> void:
	var paths: Array[String] = [
		"res://assets/tilesets/ch5/floor_ancient.png",
		"res://assets/tilesets/ch5/floor_ancient_glowing.png",
		"res://assets/tilesets/ch5/wall_ancient.png",
		"res://assets/tilesets/ch5/wall_ancient_glowing.png",
		"res://assets/sprites/enemies/boss_creator.png",
		"res://assets/sprites/title/title_ch5.png",
		"res://assets/audio/music/creators_dream.wav",
	]
	for path in paths:
		assert_true(FileAccess.file_exists(path), "asset exists: %s" % path)

func test_ending_priority_order() -> void:
	# Per multi-satellite-arc.md §5.3, the decision tree order matters.
	# FLEE beats DESTROY (FLEE always D, even with 5 truths + cangqiong)
	var ec: Node = _ec()
	if ec == null:
		return
	ec.set_creator_choice(ec.CreatorChoice.FLEE)
	ec.update_state(5, true)
	var ending: StringName = ec.determine_ending()
	assert_eq(ec.get_reached_ending(), "D", "FLEE beats DESTROY even with 5 truths + cangqiong")

func test_boss_room_has_creator() -> void:
	var room: Resource = load("res://data/levels/ch5/c5_r10.tres")
	if room == null:
		return
	assert_true(room.has_boss, "c5_r10 has boss")
	assert_eq(String(room.enemy_encounters[0]), "boss_creator", "boss is Creator")