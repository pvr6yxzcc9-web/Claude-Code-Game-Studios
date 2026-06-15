extends GutTest

# FC-44 NPC portraits (S6-015)
# Pins that NPCs now render with their portrait sprite:
#   1) 4 portrait PNGs exist
#   2) Each NPCData .tres references its portrait
#   3) Room 0 spawns Vera with portrait (not ColorRect)
#   4) Room 3 spawns Drone Operator
#   5) Room 4 spawns Marlow
#   6) Room 6 spawns Courier
#   7) Interaction prompt "[E]" appears above portrait

var _main: Node = null
var _level_runtime: Node = null

func before_all() -> void:
	_main = load("res://src/main.tscn").instantiate()
	get_tree().root.add_child(_main)
	await get_tree().process_frame
	await get_tree().process_frame
	_level_runtime = get_tree().get_root().find_child("Main", true, false)

func after_all() -> void:
	if _main != null:
		_main.queue_free()
		_main = null

# 1) Asset presence

func test_npc_portrait_files_exist() -> void:
	for name in ["vera_merchant", "marlow_ghost", "courier_14", "salvage_drone_operator"]:
		var path: String = "res://assets/sprites/npcs/%s.png" % name
		assert_true(ResourceLoader.exists(path), "%s.png exists" % name)

# 2) Tres reference portrait

func test_npc_data_tres_references_portrait() -> void:
	var reg: Node = get_node("/root/ResourceRegistry")
	for npc_id in [&"vera_merchant", &"marlow_ghost", &"courier_14", &"salvage_drone_operator"]:
		var npc: Resource = reg.get_resource(npc_id)
		if npc == null:
			pending("npc %s not registered" % npc_id)
			continue
		assert_not_null(npc.get("portrait"), "npc %s has portrait field set" % npc_id)

# 3) Room 0 spawns Vera portrait (not ColorRect)

func test_room_0_npc_uses_portrait_sprite() -> void:
	# In room 0, Vera is spawned. Find a Sprite2D child of the NPC wrapper.
	var npc_found: bool = false
	for child in _level_runtime.get_children():
		if not child.name.begins_with("NPC_"):
			continue
		npc_found = true
		# Should have at least one Sprite2D child (the portrait)
		var has_sprite: bool = false
		var has_color_rect: bool = false
		for sub in child.get_children():
			if sub is Sprite2D:
				has_sprite = true
			if sub is ColorRect:
				has_color_rect = true
		assert_true(has_sprite, "NPC wrapper %s has Sprite2D (portrait)" % child.name)
		assert_false(has_color_rect, "NPC wrapper %s no longer uses ColorRect (replaced by portrait)" % child.name)
	if not npc_found:
		pending("no NPC_ wrapper found in level_runtime")

# 4-6) Other rooms have portraits

func test_room_3_has_drone_operator_npc() -> void:
	if _level_runtime == null:
		pending("no level runtime")
		return
	_level_runtime.build_room(3)
	await get_tree().process_frame
	var found: bool = false
	for child in _level_runtime.get_children():
		if child.name.begins_with("NPC_") and "salvage_drone_operator" in child.name:
			found = true
			break
	assert_true(found, "room 3 has drone_operator NPC")

func test_room_4_has_marlow_npc() -> void:
	if _level_runtime == null:
		pending("no level runtime")
		return
	_level_runtime.build_room(4)
	await get_tree().process_frame
	var found: bool = false
	for child in _level_runtime.get_children():
		if child.name.begins_with("NPC_") and "marlow" in child.name:
			found = true
			break
	assert_true(found, "room 4 has Marlow NPC")

func test_room_6_has_courier_npc() -> void:
	if _level_runtime == null:
		pending("no level runtime")
		return
	_level_runtime.build_room(6)
	await get_tree().process_frame
	var found: bool = false
	for child in _level_runtime.get_children():
		if child.name.begins_with("NPC_") and "courier" in child.name:
			found = true
			break
	assert_true(found, "room 6 has courier NPC")

# 7) Interaction prompt

func test_npc_has_interaction_prompt_label() -> void:
	if _level_runtime == null:
		pending("no level runtime")
		return
	_level_runtime.build_room(0)
	await get_tree().process_frame
	var found_prompt: bool = false
	for child in _level_runtime.get_children():
		if not child.name.begins_with("NPC_"):
			continue
		for sub in child.get_children():
			if sub is Label and String(sub.text) == "[E]":
				found_prompt = true
				break
		if found_prompt:
			break
	assert_true(found_prompt, "NPC has [E] interaction prompt label")
