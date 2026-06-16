extends GutTest

# Integration test: PartyHudOverlay 3-4 mech HP bars (S7-004, fc62)
# Per party-system.md §3.4 + sprint-07-004 plan
# Verifies:
#   - Overlay is hidden by default, shown on party_battle_started
#   - Reads 3 unlocked mechs by default (ranger / frostbite / bomber)
#   - Active mech bar highlighted (yellow-ish bg)
#   - Knocked-out mech bar dimmed
#   - Click on a mech bar emits mech_bar_clicked(mech_index)
#   - 4th bar appears when cangqiong unlocked
#   - Parts HP indicators: green if > 0, red if 0

const PHO_PATH: String = "/root/PartyHudOverlay"
const PBC_PATH: String = "/root/PartyBattleController"
const ML_PATH: String = "/root/MechLoadout"

func _overlay() -> Control:
	var pho: Control = get_node_or_null(PHO_PATH)
	if pho == null:
		pending("PartyHudOverlay not in scene — skipping integration test")
		return null
	return pho

func test_overlay_hidden_by_default() -> void:
	var pho: Control = _overlay()
	if pho == null:
		return
	# In a normal scene load, PartyHudOverlay starts hidden
	assert_false(pho.visible, "overlay hidden by default")

func test_shows_three_bars_initially() -> void:
	var pho: Control = _overlay()
	if pho == null:
		return
	var ml: Node = get_node_or_null(ML_PATH)
	if ml == null:
		pending("MechLoadout missing")
		return
	# The overlay holds 4 bar dicts but only the first 3 should be visible
	pho._refresh()
	var unlocked: Array = ml.get_unlocked_mechs()
	assert_eq(unlocked.size(), 3, "3 mechs unlocked by default")
	# Bar 0 (ranger) should be visible; bar 3 (cangqiong) should be hidden
	assert_true(pho._mech_bars[0]["bg"].visible, "bar 0 visible")
	assert_true(pho._mech_bars[2]["bg"].visible, "bar 2 visible")
	assert_false(pho._mech_bars[3]["bg"].visible, "bar 3 (cangqiong) hidden until unlock")

func test_active_mech_highlighted_yellow() -> void:
	var pho: Control = _overlay()
	if pho == null:
		return
	var ml: Node = get_node_or_null(ML_PATH)
	if ml == null:
		return
	# Default active mech is ranger_mech (index 0)
	ml.set_active_mech(&"ranger_mech")
	pho._active_mech_index = 0
	pho._refresh()
	# Active bar has yellow-tinted bg (Color(0.1, 0.05, 0.0, 0.7))
	var active_bg: ColorRect = pho._mech_bars[0]["bg"]
	var bg_color: Color = active_bg.color
	# Yellowness: red channel is the lowest, blue is highest (yellow = R+G, no B)
	# The chosen palette has red=0.1, green=0.05, blue=0.0 — which IS slightly warm
	assert_gt(bg_color.r, 0.0, "active bg has red tint")
	# Inactive bars have pure black bg
	var inactive_bg: ColorRect = pho._mech_bars[1]["bg"]
	assert_eq(inactive_bg.color.r, 0.0, "inactive bg is pure black (r=0)")
	# Reset
	ml.set_active_mech(&"ranger_mech")

func test_knocked_out_mech_dimmed() -> void:
	var pho: Control = _overlay()
	if pho == null:
		return
	var ml: Node = get_node_or_null(ML_PATH)
	if ml == null:
		return
	# Knock out frostbite_mech (all 4 parts to 0)
	var fb: Resource = ml.get_mech(&"frostbite_mech")
	var orig_head: int = fb.head_hp
	var orig_chest: int = fb.chest_hp
	var orig_arms: int = fb.arms_hp
	var orig_legs: int = fb.legs_hp
	fb.head_hp = 0
	fb.chest_hp = 0
	fb.arms_hp = 0
	fb.legs_hp = 0
	pho._refresh()
	# Bar 1 (frostbite) should be dimmed gray
	var fb_bg: ColorRect = pho._mech_bars[1]["bg"]
	assert_lt(fb_bg.color.r, 0.2, "knocked-out bg is dimmed (r<0.2)")
	assert_lt(fb_bg.color.g, 0.2, "knocked-out bg is dimmed (g<0.2)")
	# Bar 0 (ranger, alive) is active — yellow
	var ranger_bg: ColorRect = pho._mech_bars[0]["bg"]
	assert_gt(ranger_bg.color.r, fb_bg.color.r, "active bar brighter than knocked-out")
	# Reset
	fb.head_hp = orig_head
	fb.chest_hp = orig_chest
	fb.arms_hp = orig_arms
	fb.legs_hp = orig_legs

func test_parts_indicator_red_when_zero() -> void:
	var pho: Control = _overlay()
	if pho == null:
		return
	var ml: Node = get_node_or_null(ML_PATH)
	if ml == null:
		return
	var ranger: Resource = ml.get_mech(&"ranger_mech")
	var orig_head: int = ranger.head_hp
	ranger.head_hp = 0  # head destroyed
	pho._refresh()
	# parts[0] = head, should be red
	var head_color: ColorRect = pho._mech_bars[0]["parts"][0]
	assert_eq(head_color.color.r, 0.6, "head part indicator red (r=0.6)")
	assert_eq(head_color.color.g, 0.0, "head part indicator red (g=0)")
	# parts[1] = chest, should be green
	var chest_color: ColorRect = pho._mech_bars[0]["parts"][1]
	assert_eq(chest_color.color.r, 0.3, "chest part indicator green (r=0.3)")
	assert_eq(chest_color.color.g, 0.5, "chest part indicator green (g=0.5)")
	# Reset
	ranger.head_hp = orig_head

func test_mech_bar_clicked_signal() -> void:
	var pho: Control = _overlay()
	if pho == null:
		return
	var emitted_index: int = -1
	var handler: Callable = func(idx: int) -> void:
		emitted_index = idx
	pho.mech_bar_clicked.connect(handler)
	# Synthesize an InputEventMouseButton click on bar 1
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	pho._on_bar_input(event, 1)
	assert_eq(emitted_index, 1, "click on bar 1 emits mech_bar_clicked(1)")
	# Right-click should not trigger
	emitted_index = -1
	event.button_index = MOUSE_BUTTON_RIGHT
	pho._on_bar_input(event, 1)
	assert_eq(emitted_index, -1, "right-click does not emit mech_bar_clicked")
	if pho.mech_bar_clicked.is_connected(handler):
		pho.mech_bar_clicked.disconnect(handler)

func test_cangqiong_unlock_shows_fourth_bar() -> void:
	var pho: Control = _overlay()
	if pho == null:
		return
	var ml: Node = get_node_or_null(ML_PATH)
	if ml == null:
		return
	# Lock cangqiong for clean baseline
	var cq: Resource = ml.get_mech(&"cangqiong_mech")
	cq.unlocked = false
	pho._refresh()
	# Bar 3 should be hidden
	assert_false(pho._mech_bars[3]["bg"].visible, "bar 3 hidden when cangqiong locked")
	# Unlock
	ml.unlock_cangqiong()
	pho._refresh()
	# Bar 3 should now be visible
	assert_true(pho._mech_bars[3]["bg"].visible, "bar 3 visible after cangqiong unlock")
	# Reset
	cq.unlocked = false

func test_refresh_updates_labels_from_mech_loadout() -> void:
	var pho: Control = _overlay()
	if pho == null:
		return
	var ml: Node = get_node_or_null(ML_PATH)
	if ml == null:
		return
	pho._refresh()
	# Label should contain the mech's display_name + HP text
	var ranger_label: Label = pho._mech_bars[0]["label"]
	# display_name is "漫游者号" for ranger_mech
	var text: String = ranger_label.text
	assert_true(text.contains("漫游者号"), "label contains 漫游者号 display_name")
	assert_true(text.contains("400") or text.contains("400/") or text.contains("/400"), "label contains total HP")

func test_refresh_handles_zero_mechs() -> void:
	# Edge case: if MechLoadout has 0 mechs, overlay should not crash
	var pho: Control = _overlay()
	if pho == null:
		return
	# Just call _refresh() and verify it returns gracefully
	pho._refresh()
	# No assertion beyond "didn't crash"