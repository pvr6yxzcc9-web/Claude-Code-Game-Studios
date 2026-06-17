extends GutTest

# Sat-1 content integration test (Sprint 15, fc80) — verifies Sat-1
# is no longer an empty shell: 4 NPC portraits + 12 anim frames,
# 4 NPC .tres, 4 dialogue trees, 7 truth fragments.

const REG_PATH: String = "/root/ResourceRegistry"
const NPCS: Array[StringName] = [
	&"ch1_derelict_captain",
	&"ch1_salvage_engineer",
	&"ch1_frozen_cargo_tech",
	&"ch1_marlow_first_mate",
]
const DIALOGUES: Array[StringName] = [
	&"dlg_ch1_derelict_captain",
	&"dlg_ch1_salvage_engineer",
	&"dlg_ch1_frozen_cargo_tech",
	&"dlg_ch1_marlow_first_mate",
]

func _reg() -> Node: return get_node_or_null(REG_PATH)

# === Portrait assets ===

func test_ch1_npc_portraits_base_files_exist() -> void:
	for npc in NPCS:
		var path: String = "res://assets/sprites/npcs/%s.png" % String(npc)
		assert_true(FileAccess.file_exists(path), "%s base portrait exists" % String(npc))

func test_ch1_npc_animation_frames_exist() -> void:
	# Each NPC has 3 anim frames: _mouth_open, _eyes_blink, _mouth_open_blink
	for npc in NPCS:
		for suffix in ["_mouth_open", "_eyes_blink", "_mouth_open_blink"]:
			var path: String = "res://assets/sprites/npcs/%s%s.png" % [String(npc), suffix]
			assert_true(FileAccess.file_exists(path),
				"%s%s exists" % [String(npc), suffix])

# === NPC data files ===

func test_ch1_npc_tres_files_exist() -> void:
	for npc in NPCS:
		var path: String = "res://data/npcs/%s.tres" % String(npc)
		assert_true(FileAccess.file_exists(path), "%s.tres exists" % String(npc))

func test_ch1_npcs_load_via_resource_registry() -> void:
	var reg: Node = _reg()
	if reg == null:
		pending("ResourceRegistry missing")
		return
	for npc in NPCS:
		var resource: Resource = reg.get_resource(npc)
		assert_not_null(resource, "%s loaded via registry" % String(npc))
		if resource != null:
			assert_eq(String(resource.get("location", "")), "chapter1_scrapyard",
				"%s located in chapter1_scrapyard" % String(npc))
			assert_ne(String(resource.get("display_name", "")), "",
				"%s has display_name" % String(npc))

# === Dialogue trees ===

func test_ch1_dialogue_trees_exist() -> void:
	for dlg in DIALOGUES:
		var path: String = "res://data/npcs/%s.tres" % String(dlg)
		assert_true(FileAccess.file_exists(path), "%s.tres exists" % String(dlg))

func test_ch1_dialogue_trees_have_start_node() -> void:
	for dlg in DIALOGUES:
		var path: String = "res://data/npcs/%s.tres" % String(dlg)
		if not FileAccess.file_exists(path):
			continue
		var f: FileAccess = FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		var text: String = f.get_as_text()
		f.close()
		assert_true(text.contains("start_node_id"), "%s has start_node_id" % String(dlg))
		assert_true(text.contains("&\"greet\""), "%s starts at greet" % String(dlg))

# === Truth fragments ===

func test_ch1_fragments_all_7_exist() -> void:
	for i in 7:
		var frag_id: String = "fragment_ch1_%d" % (i + 1)
		var path: String = "res://data/fragments/%s.tres" % frag_id
		assert_true(FileAccess.file_exists(path), "%s.tres exists" % frag_id)

func test_ch1_fragments_have_required_fields() -> void:
	for i in 7:
		var frag_id: String = "fragment_ch1_%d" % (i + 1)
		var path: String = "res://data/fragments/%s.tres" % frag_id
		if not FileAccess.file_exists(path):
			continue
		var f: FileAccess = FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		var text: String = f.get_as_text()
		f.close()
		assert_true(text.contains("id = &\"%s\"" % frag_id), "%s has correct id" % frag_id)
		assert_true(text.contains("title ="), "%s has title" % frag_id)
		assert_true(text.contains("body ="), "%s has body" % frag_id)
		assert_true(text.contains("author ="), "%s has author" % frag_id)
		assert_true(text.contains("importance ="), "%s has importance" % frag_id)

func test_ch1_fragments_have_lore_content() -> void:
	# Verify the fragments are not just stubs — must contain
	# the Marrow / cargo / convoy / 苍穹号 lore themes
	var themes: Array[String] = [
		"manifest", "cargo", "convoy", "cold", "seals", "Marlow", "苍穹号",
	]
	var matched: int = 0
	for i in 7:
		var path: String = "res://data/fragments/fragment_ch1_%d.tres" % (i + 1)
		if not FileAccess.file_exists(path):
			continue
		var f: FileAccess = FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		var text: String = f.get_as_text()
		f.close()
		for theme in themes:
			if text.contains(theme):
				matched += 1
				break
	# At least 5 of 7 fragments should mention a lore theme
	assert_gte(matched, 5, "at least 5/7 fragments mention lore themes")

# === Cumulative check ===

func test_total_sat1_assets_at_least_30() -> void:
	# 4 base portraits + 12 anim + 4 NPC .tres + 4 dialogues + 7 fragments
	# = 31 new assets
	var count: int = 0
	# Base + anim
	for npc in NPCS:
		if FileAccess.file_exists("res://assets/sprites/npcs/%s.png" % String(npc)):
			count += 1
		for suffix in ["_mouth_open", "_eyes_blink", "_mouth_open_blink"]:
			if FileAccess.file_exists("res://assets/sprites/npcs/%s%s.png" % [String(npc), suffix]):
				count += 1
	# NPC .tres
	for npc in NPCS:
		if FileAccess.file_exists("res://data/npcs/%s.tres" % String(npc)):
			count += 1
	# Dialogues
	for dlg in DIALOGUES:
		if FileAccess.file_exists("res://data/npcs/%s.tres" % String(dlg)):
			count += 1
	# Fragments
	for i in 7:
		if FileAccess.file_exists("res://data/fragments/fragment_ch1_%d.tres" % (i + 1)):
			count += 1
	assert_gte(count, 31, "at least 31 Sat-1 assets present (got %d)" % count)
