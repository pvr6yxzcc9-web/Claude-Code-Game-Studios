extends GutTest

# Sat-1 mechanical content integration test (Sprint 16, fc81) —
# verifies Sat-1 is now mechanically complete: 6 enemies, 10 rooms
# (connected graph), 4 terminal logs, boss in r10.

const REG_PATH: String = "/root/ResourceRegistry"
const ENEMIES: Array[StringName] = [
	&"ch1_feral_scavenger",
	&"ch1_drone_remnant",
	&"ch1_cargo_bot",
	&"ch1_frozen_crew",
	&"ch1_warden_construct",
	&"ch1_hollow_tech",
]
const ROOMS: Array[StringName] = [
	&"c1_r1", &"c1_r2", &"c1_r3", &"c1_r4", &"c1_r5",
	&"c1_r6", &"c1_r7", &"c1_r8", &"c1_r9", &"c1_r10",
]
const LOGS: Array[StringName] = [
	&"log_sat1_manifest_v1",
	&"log_sat1_manifest_v2",
	&"log_sat1_manifest_v3",
	&"log_sat1_marlow_note",
]

func _reg() -> Node: return get_node_or_null(REG_PATH)

# === Enemy assets ===

func test_ch1_enemies_all_6_exist() -> void:
	for eid in ENEMIES:
		var path: String = "res://data/enemies/%s.tres" % String(eid)
		assert_true(FileAccess.file_exists(path), "%s.tres exists" % String(eid))
		var sprite_path: String = "res://assets/sprites/enemies/%s.png" % String(eid)
		assert_true(FileAccess.file_exists(sprite_path), "%s.png sprite exists" % String(eid))

func test_ch1_enemies_have_required_fields() -> void:
	for eid in ENEMIES:
		var path: String = "res://data/enemies/%s.tres" % String(eid)
		if not FileAccess.file_exists(path):
			continue
		var f: FileAccess = FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		var text: String = f.get_as_text()
		f.close()
		assert_true(text.contains("max_hp ="), "%s has max_hp" % String(eid))
		assert_true(text.contains("attack ="), "%s has attack" % String(eid))
		assert_true(text.contains("weaknesses ="), "%s has weaknesses" % String(eid))

# === Room layouts ===

func test_ch1_rooms_all_10_exist() -> void:
	for rid in ROOMS:
		var path: String = "res://data/levels/ch1/%s.tres" % String(rid)
		assert_true(FileAccess.file_exists(path), "%s.tres exists" % String(rid))

func test_ch1_rooms_have_required_fields() -> void:
	for rid in ROOMS:
		var path: String = "res://data/levels/ch1/%s.tres" % String(rid)
		if not FileAccess.file_exists(path):
			continue
		var f: FileAccess = FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		var text: String = f.get_as_text()
		f.close()
		assert_true(text.contains("display_name ="), "%s has display_name" % String(rid))
		assert_true(text.contains("chapter = 1"), "%s is chapter 1" % String(rid))
		assert_true(text.contains("tile_set = &\"ch1\""), "%s uses ch1 tile_set" % String(rid))
		assert_true(text.contains("exits ="), "%s has exits" % String(rid))

func test_ch1_room_graph_connected() -> void:
	# Every room (except r1) must be reachable from r1
	var reachable: Dictionary = {&"c1_r1": true}
	var frontier: Array[StringName] = [&"c1_r1"]
	while frontier.size() > 0:
		var next_frontier: Array[StringName] = []
		for rid in frontier:
			var path: String = "res://data/levels/ch1/%s.tres" % String(rid)
			if not FileAccess.file_exists(path):
				continue
			var f: FileAccess = FileAccess.open(path, FileAccess.READ)
			if f == null:
				continue
			var text: String = f.get_as_text()
			f.close()
			# Find all &"c1_rN" in exits
			var pattern: RegEx = RegEx.new()
			pattern.compile("&\"(c1_r\\d+)\"")
			for m in pattern.search_all(text.substr(text.find("exits ="))):
				var target: String = m.get_string(1)
				if not reachable.has(StringName(target)):
					reachable[StringName(target)] = true
					next_frontier.append(StringName(target))
		frontier = next_frontier
	# All 10 rooms should be reachable from r1
	assert_eq(reachable.size(), 10, "all 10 rooms reachable from r1 (got %d)" % reachable.size())

func test_ch1_r10_has_boss() -> void:
	var path: String = "res://data/levels/ch1/c1_r10.tres"
	if not FileAccess.file_exists(path):
		return
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var text: String = f.get_as_text()
	f.close()
	assert_true(text.contains("has_boss = true"), "r10 has has_boss = true")
	assert_true(text.contains("&\"boss_marrow_sentinel\""), "r10 has marrow_sentinel boss")

# === Terminal logs ===

func test_ch1_terminal_logs_all_4_exist() -> void:
	for log_id in LOGS:
		var path: String = "res://data/fragments/%s.tres" % String(log_id)
		assert_true(FileAccess.file_exists(path), "%s.tres exists" % String(log_id))

# === Cumulative ===

func test_total_sat1_mech_assets_at_least_20() -> void:
	var count: int = 0
	for eid in ENEMIES:
		if FileAccess.file_exists("res://data/enemies/%s.tres" % String(eid)):
			count += 1
	for rid in ROOMS:
		if FileAccess.file_exists("res://data/levels/ch1/%s.tres" % String(rid)):
			count += 1
	for log_id in LOGS:
		if FileAccess.file_exists("res://data/fragments/%s.tres" % String(log_id)):
			count += 1
	# 6 enemies + 10 rooms + 4 logs = 20
	assert_gte(count, 20, "at least 20 Sat-1 mechanical assets (got %d)" % count)
