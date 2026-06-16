extends GutTest

# Integration test: Sat-3 hallucination mechanic + content loading (S8-013 + S8-014, fc68)
# Per sprint-08-sat3-hive.md
# Verifies:
#   - HallucinationManager is registered as autoload
#   - Sat-3 rooms have decoy configurations
#   - Decoys are deterministic per room (per OQ4)
#   - is_decoy() returns true for halluccinated entities
#   - on_attack() returns true for decoys, false for real enemies
#   - Decoy visual properties (translucent purple, ? label)
#   - Revealed decoys don't reappear after save/load
#   - Sat-3 6 enemy .tres load via ResourceRegistry
#   - Boss .tres loads
#   - 7 fragment .tres load
#   - chapter3.tres loads

const HM_PATH: String = "/root/HallucinationManager"

func _hm() -> Node:
	var hm: Node = get_node_or_null(HM_PATH)
	if hm == null:
		pending("HallucinationManager autoload missing")
		return null
	return hm

func test_sat3_decoy_rooms_configured() -> void:
	var hm: Node = _hm()
	if hm == null:
		return
	# At least 4 rooms should have decoys
	assert_true(hm.SAT3_DECOY_ROOMS.has(&"c3_r2"), "Ch7 Room 2 has decoys")
	assert_true(hm.SAT3_DECOY_ROOMS.has(&"c3_r4"), "Ch8 Room 1 has decoys")
	assert_true(hm.SAT3_DECOY_ROOMS.has(&"c3_r7"), "Ch9 Room 1 has decoys")
	assert_true(hm.SAT3_DECOY_ROOMS.has(&"c3_r9"), "Boss arena has 1 decoy")

func test_decoys_are_deterministic() -> void:
	var hm: Node = _hm()
	if hm == null:
		return
	# Same room should always return the same decoys
	var decoys1: Array = hm.get_decoys_in_room(&"c3_r2")
	var decoys2: Array = hm.get_decoys_in_room(&"c3_r2")
	assert_eq(decoys1.size(), decoys2.size(), "deterministic count")
	for i in decoys1.size():
		assert_eq(String(decoys1[i]), String(decoys2[i]), "deterministic id at %d" % i)

func test_decoys_per_room_count() -> void:
	var hm: Node = _hm()
	if hm == null:
		return
	# Per the plan: 1-2 decoys per room
	for room_id in hm.SAT3_DECOY_ROOMS:
		var decoys: Array = hm.get_decoys_in_room(room_id)
		assert_ge(decoys.size(), 1, "%s has ≥1 decoy" % room_id)
		assert_le(decoys.size(), 2, "%s has ≤2 decoys" % room_id)

func test_is_decoy_returns_true_for_hallucinated_entity() -> void:
	var hm: Node = _hm()
	if hm == null:
		return
	var decoys: Array = hm.get_decoys_in_room(&"c3_r2")
	assert_gt(decoys.size(), 0, "c3_r2 has decoys")
	var first_decoy: StringName = decoys[0]
	assert_true(hm.is_decoy(first_decoy, &"c3_r2"), "is_decoy returns true for hallucinated entity")

func test_is_decoy_returns_false_for_real_enemy() -> void:
	var hm: Node = _hm()
	if hm == null:
		return
	# A real enemy id (not in the decoy list)
	assert_false(hm.is_decoy(&"ch3_hive_guardian", &"c3_r2"), "real enemy not a decoy")

func test_is_decoy_returns_false_for_wrong_room() -> void:
	var hm: Node = _hm()
	if hm == null:
		return
	# decoy_1 is in c3_r2; checking c3_r4 should return false
	assert_false(hm.is_decoy(&"decoy_1", &"c3_r4"), "decoy in wrong room not flagged")

func test_on_attack_decoy_returns_true() -> void:
	var hm: Node = _hm()
	if hm == null:
		return
	hm.register_decoy_position(&"decoy_1", &"c3_r2", Vector2(100, 100))
	var is_decoy_attack: bool = hm.on_attack(&"decoy_1", &"c3_r2")
	assert_true(is_decoy_attack, "attacking decoy returns true")

func test_on_attack_real_enemy_returns_false() -> void:
	var hm: Node = _hm()
	if hm == null:
		return
	var is_decoy_attack: bool = hm.on_attack(&"ch3_hive_guardian", &"c3_r2")
	assert_false(is_decoy_attack, "attacking real enemy returns false")

func test_decoy_attacked_signal_fires() -> void:
	var hm: Node = _hm()
	if hm == null:
		return
	hm.register_decoy_position(&"decoy_1", &"c3_r2", Vector2(100, 100))
	var emitted: bool = false
	var handler: Callable = func(_id: StringName, _room: StringName) -> void:
		emitted = true
	hm.decoy_attacked.connect(handler)
	hm.on_attack(&"decoy_1", &"c3_r2")
	assert_true(emitted, "decoy_attacked signal emitted")
	if hm.decoy_attacked.is_connected(handler):
		hm.decoy_attacked.disconnect(handler)

func test_decoy_revealed_signal_fires() -> void:
	var hm: Node = _hm()
	if hm == null:
		return
	hm.register_decoy_position(&"decoy_1", &"c3_r2", Vector2(100, 100))
	var emitted: bool = false
	var handler: Callable = func(_id: StringName, _room: StringName) -> void:
		emitted = true
	hm.decoy_revealed.connect(handler)
	hm.on_attack(&"decoy_1", &"c3_r2")
	assert_true(emitted, "decoy_revealed signal emitted")
	if hm.decoy_revealed.is_connected(handler):
		hm.decoy_revealed.disconnect(handler)

func test_decoy_removed_after_attack() -> void:
	var hm: Node = _hm()
	if hm == null:
		return
	hm.register_decoy_position(&"decoy_1", &"c3_r2", Vector2(100, 100))
	assert_true(hm.get_decoy_info(&"decoy_1").has("room_id"), "decoy_1 registered")
	hm.on_attack(&"decoy_1", &"c3_r2")
	assert_false(hm.get_decoy_info(&"decoy_1").has("room_id"), "decoy_1 removed after attack")

func test_decoy_color_is_translucent_purple() -> void:
	var hm: Node = _hm()
	if hm == null:
		return
	var color: Color = hm.get_decoy_color()
	assert_lt(color.a, 1.0, "decoy is translucent (alpha < 1)")
	assert_gt(color.r, 0.4, "decoy has red tint")
	assert_gt(color.b, 0.4, "decoy has blue tint (purple)")

func test_decoy_label_is_question_mark() -> void:
	var hm: Node = _hm()
	if hm == null:
		return
	assert_eq(hm.get_decoy_label(), "?", "decoy label is '?'")

func test_save_load_preserves_revealed_decoys() -> void:
	var hm: Node = _hm()
	if hm == null:
		return
	hm.register_decoy_position(&"decoy_1", &"c3_r2", Vector2(100, 100))
	hm.register_decoy_position(&"decoy_3", &"c3_r4", Vector2(200, 200))
	# Reveal decoy_1 by attacking it
	hm.on_attack(&"decoy_1", &"c3_r2")
	# Snapshot
	var snap: Dictionary = hm.get_state_snapshot()
	var revealed: Array = snap["revealed_decoys"]
	assert_eq(revealed.size(), 1, "1 decoy revealed in snap")
	# Re-register
	hm.register_decoy_position(&"decoy_1", &"c3_r2", Vector2(100, 100))
	# Load
	var err: int = hm.load_snapshot(snap)
	assert_eq(err, OK, "load returns OK")
	# decoy_1 should be marked revealed (already attacked)
	assert_true(hm.get_decoy_info(&"decoy_1").get("revealed", false), "decoy_1 marked revealed after load")

func test_reset_all_decoys() -> void:
	var hm: Node = _hm()
	if hm == null:
		return
	hm.register_decoy_position(&"decoy_1", &"c3_r2", Vector2(100, 100))
	hm.register_decoy_position(&"decoy_3", &"c3_r4", Vector2(200, 200))
	hm.reset_all_decoys()
	assert_eq(hm._active_decoys.size(), 0, "all decoys cleared")

# === Sat-3 content resource tests ===

func test_sat3_enemy_resources_exist() -> void:
	var reg: Node = get_node_or_null("/root/ResourceRegistry")
	if reg == null:
		pending("ResourceRegistry missing")
		return
	var enemy_ids: Array[StringName] = [
		&"ch3_hive_guardian",
		&"ch3_hive_cannon",
		&"ch3_hive_parasite",
		&"ch3_hive_mycelium",
		&"ch3_hive_larva",
		&"ch3_hive_breeder",
	]
	for eid in enemy_ids:
		var resource: Resource = reg.get_resource(eid)
		assert_not_null(resource, "%s registered" % eid)

func test_sat3_boss_resource_exists() -> void:
	var reg: Node = get_node_or_null("/root/ResourceRegistry")
	if reg == null:
		return
	var boss: Resource = reg.get_resource(&"boss_hive_queen_guardian")
	assert_not_null(boss, "boss_hive_queen_guardian registered")

func test_sat3_fragment_resources_exist() -> void:
	var reg: Node = get_node_or_null("/root/ResourceRegistry")
	if reg == null:
		return
	for i in 7:
		var fid: StringName = StringName("fragment_hive_%d" % (i + 1))
		var frag: Resource = reg.get_resource(fid)
		assert_not_null(frag, "%s registered" % fid)

func test_sat3_chapter3_resource_exists() -> void:
	var reg: Node = get_node_or_null("/root/ResourceRegistry")
	if reg == null:
		return
	var chapter: Resource = reg.get_resource(&"chapter3_hive")
	assert_not_null(chapter, "chapter3_hive registered")

func test_sat3_npcs_have_portraits() -> void:
	var reg: Node = get_node_or_null("/root/ResourceRegistry")
	if reg == null:
		return
	for npc_id in [&"ch3_wanderer_scientist", &"ch3_hive_survivor", &"ch3_surviving_crew", &"ch3_fungal_infected"]:
		var npc: Resource = reg.get_resource(StringName(npc_id))
		assert_not_null(npc, "%s registered" % npc_id)
		assert_not_null(npc.portrait, "%s has portrait" % npc_id)

func test_sat3_assets_exist_on_disk() -> void:
	# Verify the generated sprite files exist
	var paths: Array[String] = [
		"res://assets/tilesets/ch3/floor_hive.png",
		"res://assets/tilesets/ch3/floor_hive_damaged.png",
		"res://assets/tilesets/ch3/wall_hive.png",
		"res://assets/tilesets/ch3/wall_hive_damaged.png",
		"res://assets/sprites/enemies/ch3_hive_guardian.png",
		"res://assets/sprites/enemies/ch3_hive_cannon.png",
		"res://assets/sprites/enemies/ch3_hive_parasite.png",
		"res://assets/sprites/enemies/ch3_hive_mycelium.png",
		"res://assets/sprites/enemies/ch3_hive_larva.png",
		"res://assets/sprites/enemies/ch3_hive_breeder.png",
		"res://assets/sprites/enemies/boss_hive_queen_guardian.png",
		"res://assets/sprites/npcs/ch3_wanderer_scientist.png",
		"res://assets/sprites/npcs/ch3_hive_survivor.png",
		"res://assets/sprites/npcs/ch3_surviving_crew.png",
		"res://assets/sprites/npcs/ch3_fungal_infected.png",
		"res://assets/sprites/title/title_ch3.png",
		"res://assets/audio/music/hive_heart.wav",
	]
	for path in paths:
		assert_true(FileAccess.file_exists(path), "asset exists: %s" % path)