extends GutTest

# FC-27 Auto-mode AI (S4-007)
# Pins:
#   1) toggle_mode action exists, EXPECTED_ACTION_COUNT = 49
#   2) Default mode = MANUAL
#   3) toggle_mode() flips to AUTO and back; mode_changed signal fires
#   4) _ai_pick_slot() picks highest max_damage (tiebreak: min_damage)
#   5) AUTO mode timer fires trigger_attack at the AI-picked slot
#   6) Timer is only active in state_battle (no attack outside battle)
#   7) HUD listens to mode_changed

const MAIN_SCENE := "res://src/main.tscn"

var _main: Node = null
var _loadout: Node = null
var _hud: Node = null
var _input_bus: Node = null

func before_all() -> void:
    _main = load(MAIN_SCENE).instantiate()
    get_tree().root.add_child(_main)
    await get_tree().process_frame
    await get_tree().process_frame
    _loadout = get_node("/root/WeaponLoadout")
    _hud = get_tree().get_root().find_child("HUD", true, false)
    _input_bus = get_node("/root/InputBus")

func after_all() -> void:
    if _main != null:
        _main.queue_free()
        _main = null

func before_each() -> void:
    # Reset to MANUAL, equip a known loadout
    if _loadout.is_auto_mode():
        _loadout.set_auto_mode(false)
    _loadout.weapon_slots[0] = &"blaster_rifle"  # max 35
    _loadout.weapon_slots[1] = &"railgun"        # max 75 (highest)
    _loadout.weapon_slots[2] = &"shotgun_spread" # max 25 (lowest)

# --- A) Input + count ---

func test_toggle_mode_input_action_registered() -> void:
    assert_true(InputMap.has_action("toggle_mode"), "toggle_mode action exists")

func test_input_bus_expected_action_count_is_49() -> void:
    assert_eq(_input_bus.EXPECTED_ACTION_COUNT, 49, "EXPECTED_ACTION_COUNT = 49 after toggle_mode addition")

# --- B) Default mode ---

func test_default_mode_is_manual() -> void:
    assert_false(_loadout.is_auto_mode(), "loadout starts in MANUAL mode")

# --- C) Toggle ---

func test_toggle_mode_flips_manual_to_auto() -> void:
    var result: StringName = _loadout.toggle_mode()
    assert_true(_loadout.is_auto_mode(), "now in AUTO mode")
    assert_eq(result, &"AUTO", "toggle_mode() returns new mode name")

func test_toggle_mode_flips_auto_to_manual() -> void:
    _loadout.set_auto_mode(true)
    var result: StringName = _loadout.toggle_mode()
    assert_false(_loadout.is_auto_mode(), "back to MANUAL")
    assert_eq(result, &"MANUAL", "toggle_mode() returns MANUAL")

func test_mode_changed_signal_fires() -> void:
    var received: Array = []
    _loadout.mode_changed.connect(func(new_mode: StringName) -> void: received.append(new_mode))
    _loadout.set_auto_mode(true)
    _loadout.set_auto_mode(false)
    assert_eq(received, [&"AUTO", &"MANUAL"], "mode_changed emitted for each transition")

# --- D) AI slot pick ---

func test_ai_pick_picks_highest_max_damage() -> void:
    # blaster 35, railgun 75, shotgun_spread 25
    var picked: int = _loadout._ai_pick_slot()
    assert_eq(picked, 1, "AI picked slot 1 (railgun, max 75)")

func test_ai_pick_tiebreak_by_min_damage() -> void:
    # Slot 0 = blaster 25-35 (min 25)
    # Slot 1 = railgun 55-75 (min 55) — already highest max
    # Force tie: make slot 2 also have max 75 (synthetic test)
    _loadout.weapon_slots[2] = &"railgun"  # now slot 1 AND 2 both max 75
    var picked: int = _loadout._ai_pick_slot()
    # Tiebreak by min_damage: railgun has min 55, blaster has min 25.
    # railgun (min 55) wins over blaster (min 25), so first slot
    # with railgun = slot 1
    assert_eq(picked, 1, "AI tiebreak picks slot with higher min_damage (slot 1 first)")

func test_ai_pick_returns_minus_one_for_no_weapons() -> void:
    _loadout.weapon_slots[0] = &""
    _loadout.weapon_slots[1] = &""
    _loadout.weapon_slots[2] = &""
    var picked: int = _loadout._ai_pick_slot()
    assert_eq(picked, -1, "no weapons -> -1 (skip tick)")

# --- E) Timer fires in battle ---

func test_auto_mode_timer_does_not_fire_outside_battle() -> void:
    _loadout.set_auto_mode(true)
    var attacks: Array = []
    _loadout.attack_triggered.connect(func(slot: int) -> void: attacks.append(slot))
    # AUTO timer should be running but not fire because not in battle.
    # Wait for AUTO_INTERVAL_SEC + slack to confirm no attack.
    await get_tree().create_timer(_loadout.AUTO_INTERVAL_SEC + 0.3).timeout
    assert_eq(attacks.size(), 0, "no attack outside battle")
    _loadout.set_auto_mode(false)

func test_auto_mode_timer_fires_attack_in_battle() -> void:
    var sm: Node = get_node("/root/GameStateMachine")
    sm.transition_to(&"state_battle")
    await get_tree().process_frame
    _loadout.set_auto_mode(true)
    var attacks: Array = []
    _loadout.attack_triggered.connect(func(slot: int) -> void: attacks.append(slot))
    # Wait for at least 1 tick (AUTO_INTERVAL_SEC + slack)
    await get_tree().create_timer(_loadout.AUTO_INTERVAL_SEC + 0.3).timeout
    assert_gt(attacks.size(), 0, "auto mode fired at least one attack in battle")
    assert_eq(attacks[0], 1, "first attack was slot 1 (railgun = AI-picked max_damage)")
    _loadout.set_auto_mode(false)
    sm.transition_to(&"state_exploration")

# --- F) HUD listens ---

func test_hud_label_reflects_mode_change() -> void:
    assert_eq(_hud._mode_label, "MANUAL", "HUD starts in MANUAL")
    _loadout.set_auto_mode(true)
    assert_eq(_hud._mode_label, "AUTO", "HUD label flipped to AUTO after mode_changed")
    _loadout.set_auto_mode(false)
    assert_eq(_hud._mode_label, "MANUAL", "HUD label flipped back to MANUAL")
