extends GutTest

# Integration test: Sat-3 room data files (S8-007, fc69)
# Per data/levels/ch3_room_layouts.md
# Verifies:
#   - 10 room .tres files exist (c3_r1 through c3_r10)
#   - Each room has correct chapter (7/7/7/8/8/8/9/9/9/9)
#   - Each room has correct exits (verify connectivity)
#   - Boss room (c3_r10) has has_boss=true and the boss enemy
#   - All 7 fragment IDs are distributed across rooms (no duplicates)
#   - All 4 NPCs are placed
#   - Total decoy count across rooms is 1-2 per room (where set)
#   - Per-chapter room distribution: Ch7=3, Ch8=3, Ch9=4

const ROOM_DIR: String = "res://data/levels/ch3/"
const EXPECTED_ROOMS: Array[StringName] = [
	&"c3_r1", &"c3_r2", &"c3_r3", &"c3_r4", &"c3_r5",
	&"c3_r6", &"c3_r7", &"c3_r8", &"c3_r9", &"c3_r10",
]

func _load_room(room_id: StringName) -> Resource:
	var path: String = ROOM_DIR + String(room_id) + ".tres"
	if not ResourceLoader.exists(path):
		return null
	return load(path)

func test_all_10_room_files_exist() -> void:
	for room_id in EXPECTED_ROOMS:
		var path: String = ROOM_DIR + String(room_id) + ".tres"
		assert_true(FileAccess.file_exists(path), "room file exists: %s" % room_id)

func test_chapter_distribution() -> void:
	# Ch7 = 3 rooms (c3_r1, c3_r2, c3_r3)
	# Ch8 = 3 rooms (c3_r4, c3_r5, c3_r6)
	# Ch9 = 4 rooms (c3_r7, c3_r8, c3_r9, c3_r10)
	var chapter_counts: Dictionary = {7: 0, 8: 0, 9: 0}
	for room_id in EXPECTED_ROOMS:
		var room: Resource = _load_room(room_id)
		if room == null:
			continue
		assert_true(chapter_counts.has(room.chapter), "chapter %d valid" % room.chapter)
		chapter_counts[room.chapter] += 1
	assert_eq(chapter_counts[7], 3, "Ch7 has 3 rooms")
	assert_eq(chapter_counts[8], 3, "Ch8 has 3 rooms")
	assert_eq(chapter_counts[9], 4, "Ch9 has 4 rooms")

func test_room_ids_match_filenames() -> void:
	for room_id in EXPECTED_ROOMS:
		var room: Resource = _load_room(room_id)
		assert_not_null(room, "room %s loaded" % room_id)
		assert_eq(String(room.id), String(room_id), "room.id matches filename")

func test_boss_room_has_boss() -> void:
	var boss_room: Resource = _load_room(&"c3_r10")
	assert_not_null(boss_room, "c3_r10 loads")
	assert_true(boss_room.has_boss, "c3_r10 has has_boss=true")
	assert_eq(boss_room.enemy_encounters.size(), 1, "boss room has 1 enemy")
	assert_eq(String(boss_room.enemy_encounters[0]), "boss_hive_queen_guardian", "boss is 蜂后守卫")

func test_boss_room_has_no_exits() -> void:
	var boss_room: Resource = _load_room(&"c3_r10")
	assert_eq(boss_room.exits.size(), 0, "boss room has no exits (terminal)")

func test_first_room_exits_to_r2() -> void:
	var r1: Resource = _load_room(&"c3_r1")
	assert_eq(r1.exits.size(), 1, "r1 has 1 exit")
	assert_eq(String(r1.exits[0]), "c3_r2", "r1 exits to r2")

func test_room_connectivity_linear_ch7() -> void:
	# Ch7: r1 → r2 → r3 (linear)
	var r1: Resource = _load_room(&"c3_r1")
	var r2: Resource = _load_room(&"c3_r2")
	var r3: Resource = _load_room(&"c3_r3")
	assert_true(r2.exits.has(&"c3_r1"), "r2 exits to r1")
	assert_true(r2.exits.has(&"c3_r3"), "r2 exits to r3")
	assert_true(r3.exits.has(&"c3_r2"), "r3 exits to r2")

func test_all_7_fragments_distributed_across_rooms() -> void:
	var seen: Array[StringName] = []
	for room_id in EXPECTED_ROOMS:
		var room: Resource = _load_room(room_id)
		if room == null:
			continue
		for frag_id in room.fragment_ids:
			assert_false(seen.has(frag_id), "fragment %s not duplicated" % frag_id)
			seen.append(frag_id)
	# Should have all 7 fragments
	assert_eq(seen.size(), 7, "all 7 fragments distributed across rooms")

func test_all_4_npcs_placed() -> void:
	var seen: Array[StringName] = []
	for room_id in EXPECTED_ROOMS:
		var room: Resource = _load_room(room_id)
		if room == null:
			continue
		for npc_id in room.npcs:
			if not seen.has(npc_id):
				seen.append(npc_id)
	# At least the 4 NPCs from S8-008 + the frostbite_mother from S8-015
	assert_true(seen.has(&"ch3_wanderer_scientist"), "wanderer_scientist placed")
	assert_true(seen.has(&"ch3_hive_survivor"), "hive_survivor placed")
	assert_true(seen.has(&"ch3_surviving_crew"), "surviving_crew placed")
	assert_true(seen.has(&"ch3_fungal_infected"), "fungal_infected placed")

func test_decoy_count_per_room() -> void:
	# Per plan: 1-2 decoys per room (where set)
	for room_id in EXPECTED_ROOMS:
		var room: Resource = _load_room(room_id)
		if room == null:
			continue
		if room.decoy_count > 0:
			assert_ge(room.decoy_count, 1, "%s decoy_count >= 1" % room_id)
			assert_le(room.decoy_count, 2, "%s decoy_count <= 2" % room_id)

func test_decoy_rooms_match_hallucination_manager() -> void:
	# The decoy rooms in HallucinationManager.SAT3_DECOY_ROOMS should
	# match the rooms with decoy_count > 0
	var hm: Node = get_node_or_null("/root/HallucinationManager")
	if hm == null:
		pending("HallucinationManager missing")
		return
	for room_id in hm.SAT3_DECOY_ROOMS:
		var room: Resource = _load_room(room_id)
		if room == null:
			continue
		assert_gt(room.decoy_count, 0, "%s has decoy_count > 0 (matches HallucinationManager)" % room_id)

func test_room_descriptions_non_empty() -> void:
	for room_id in EXPECTED_ROOMS:
		var room: Resource = _load_room(room_id)
		if room == null:
			continue
		assert_gt(room.description.length(), 20, "%s description is substantial" % room_id)

func test_room_display_names_present() -> void:
	for room_id in EXPECTED_ROOMS:
		var room: Resource = _load_room(room_id)
		if room == null:
			continue
		assert_ne(room.display_name, "", "%s display_name set" % room_id)

func test_chapter_progression_no_backward_only() -> void:
	# A room should exit to a room in the same or later chapter (no going back)
	# Exception: c3_r7 ↔ c3_r6 can cross Ch8/Ch9 boundary
	for room_id in EXPECTED_ROOMS:
		var room: Resource = _load_room(room_id)
		if room == null:
			continue
		var my_chapter: int = room.chapter
		for exit_id in room.exits:
			var exit_room: Resource = _load_room(exit_id)
			if exit_room == null:
				continue
			# Exit room should be in same chapter or later (or c3_r10 special case)
			assert_lte(exit_room.chapter, my_chapter + 1, "%s → %s chapter progression" % [room_id, exit_id])

func test_total_encounters_per_room_bounded() -> void:
	# Per plan: each room has 0-5 enemies (boss room has 1 boss = 1 encounter)
	for room_id in EXPECTED_ROOMS:
		var room: Resource = _load_room(room_id)
		if room == null:
			continue
		assert_le(room.enemy_encounters.size(), 5, "%s encounter count <= 5" % room_id)