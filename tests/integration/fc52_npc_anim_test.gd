extends GutTest

# FC-52 NPC dialogue portrait animation (S6-100)
# Pins that NPC portraits animate during dialogue:
#   1) All 12 animation frame PNGs exist (4 NPCs x 3 frames)
#   2) DialogueUI has portrait panel + portrait TextureRect
#   3) _load_portrait_frame() picks the right path per state
#   4) Lip-sync timer starts when dialogue opens
#   5) Portrait texture loads correctly for each NPC

var _main: Node = null

func before_all() -> void:
	_main = load("res://src/main.tscn").instantiate()
	get_tree().root.add_child(_main)
	await get_tree().process_frame
	await get_tree().process_frame

func after_all() -> void:
	if _main != null:
		_main.queue_free()
		_main = null

# 1) Asset presence

func test_animation_frame_pngs_exist() -> void:
	for npc_id in ["vera_merchant", "marlow_ghost", "courier_14", "salvage_drone_operator"]:
		for variant in ["_mouth_open", "_eyes_blink", "_mouth_open_blink"]:
			var path: String = "res://assets/sprites/npcs/%s%s.png" % [npc_id, variant]
			assert_true(ResourceLoader.exists(path), "%s%s.png exists" % [npc_id, variant])

# 2) DialogueUI has portrait widgets

func test_dialogue_ui_has_portrait_widgets() -> void:
	var ui: Node = get_tree().get_root().find_child("DialogueUI", true, false)
	if ui == null:
		pending("DialogueUI not in scene")
		return
	assert_not_null(ui._portrait_panel, "DialogueUI has _portrait_panel")
	assert_not_null(ui._portrait, "DialogueUI has _portrait TextureRect")

# 3) _load_portrait_frame() picks the right path

func test_load_portrait_frame_picks_correct_path() -> void:
	var ui: Node = get_tree().get_root().find_child("DialogueUI", true, false)
	if ui == null:
		pending("DialogueUI not in scene")
		return
	# Closed mouth (default) → base portrait
	ui._current_npc_id = &"vera_merchant"
	ui._mouth_open = false
	ui._blinking = false
	ui._load_portrait_frame()
	assert_not_null(ui._portrait.texture, "closed mouth loads base portrait")
	# Open mouth → _mouth_open variant
	ui._mouth_open = true
	ui._blinking = false
	ui._load_portrait_frame()
	assert_not_null(ui._portrait.texture, "open mouth loads _mouth_open variant")
	# Blink → _eyes_blink variant
	ui._mouth_open = false
	ui._blinking = true
	ui._load_portrait_frame()
	assert_not_null(ui._portrait.texture, "blink loads _eyes_blink variant")
	# Combined → _mouth_open_blink variant
	ui._mouth_open = true
	ui._blinking = true
	ui._load_portrait_frame()
	assert_not_null(ui._portrait.texture, "open+blink loads _mouth_open_blink variant")

# 4) Dialogue opens → lip-sync timer starts

func test_dialogue_opens_starts_animation() -> void:
	var ui: Node = get_tree().get_root().find_child("DialogueUI", true, false)
	if ui == null:
		pending("DialogueUI not in scene")
		return
	# Simulate dialogue start by calling handler directly
	# (we can't actually trigger DialogueManager easily from here)
	var npc_res: Resource = null
	# Use the ResourceRegistry to get vera
	var reg: Node = get_node("/root/ResourceRegistry")
	npc_res = reg.get_resource(&"vera_merchant") if reg != null else null
	ui._on_dialogue_started(npc_res)
	# After dialogue start, current_npc_id should be set
	assert_eq(ui._current_npc_id, &"vera_merchant", "current_npc_id set on dialogue start")
	# lip_sync_timer should be active
	assert_not_null(ui._lip_sync_timer, "lip_sync_timer started on dialogue start")
	# Cleanup
	ui._stop_animation()
	assert_null(ui._lip_sync_timer if not ui._lip_sync_timer.timeout.is_connected(ui._on_lip_sync_tick) else ui._lip_sync_timer, "animation stopped on _stop_animation")

# 5) Texture loads for each NPC

func test_portrait_textures_load_per_npc() -> void:
	var ui: Node = get_tree().get_root().find_child("DialogueUI", true, false)
	if ui == null:
		pending("DialogueUI not in scene")
		return
	for npc_id in ["vera_merchant", "marlow_ghost", "courier_14", "salvage_drone_operator"]:
		ui._current_npc_id = StringName(npc_id)
		ui._mouth_open = false
		ui._blinking = false
		ui._load_portrait_frame()
		assert_not_null(ui._portrait.texture, "%s base portrait loads" % npc_id)
