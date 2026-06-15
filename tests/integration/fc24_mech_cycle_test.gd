extends GutTest

# FC-24 Mech part cycle (S4-002)
# Pins:
#   1) mech_cycle input action exists in InputMap
#   2) MechLoadout.cycle_equipped_part() rotates through equipped slots
#   3) LevelRuntime equips 3 starting parts in _ready
#   4) HUD shows mech part labels with active-slot highlight
#   5) EXPECTED_ACTION_COUNT was bumped 47 -> 48 (mech_cycle added)
#   6) Empty-slot cycle is a no-op, single-part cycle is a no-op

const MAIN_SCENE := "res://src/main.tscn"

var _main: Node = null
var _mech: Node = null
var _hud: Node = null
var _input_bus: Node = null
var _level_runtime: Node = null

func before_all() -> void:
    _main = load(MAIN_SCENE).instantiate()
    get_tree().root.add_child(_main)
    await get_tree().process_frame
    await get_tree().process_frame
    _mech = get_node("/root/MechLoadout")
    _hud = get_tree().get_root().find_child("HUD", true, false)
    _input_bus = get_node("/root/InputBus")
    _level_runtime = get_tree().get_root().find_child("Main", true, false)

func after_all() -> void:
    if _main != null:
        _main.queue_free()
        _main = null

func before_each() -> void:
    # Reset mech state (level_runtime._ready runs on first instantiation and
    # sets starter parts, but test re-runs need a clean baseline)
    for s in _mech.SLOTS:
        _mech.unequip_part(s)
    _mech._cycle_index = 0

# --- A) Input action exists ---

func test_mech_cycle_input_action_registered() -> void:
    assert_true(InputMap.has_action("mech_cycle"), "mech_cycle action exists in InputMap")

func test_input_bus_expected_action_count_is_49() -> void:
    # Updated 47 -> 48 when mech_cycle was added, then 48 -> 49 when
    # toggle_mode was added in S4-007. Pin the current expected value;
    # future additions must bump this in lockstep.
    assert_eq(_input_bus.EXPECTED_ACTION_COUNT, 49, "EXPECTED_ACTION_COUNT = 49 after mech_cycle + toggle_mode additions")

# --- B) LevelRuntime equips 3 starting parts ---

func test_level_runtime_equips_starting_parts() -> void:
    # Re-equip via the same path LevelRuntime._ready does (idempotent check)
    _level_runtime._equip_starting_mech_parts()
    assert_eq(_mech.parts[&"torso"], &"starter_torso", "torso equipped by level_runtime")
    assert_eq(_mech.parts[&"left_arm"], &"steady_arm", "left_arm equipped by level_runtime")
    assert_eq(_mech.parts[&"right_arm"], &"plated_arm", "right_arm equipped by level_runtime")

# --- C) cycle_equipped_part() rotation ---

func test_cycle_with_three_parts_rotates_through() -> void:
    _mech.equip_part(&"torso", &"starter_torso")
    _mech.equip_part(&"left_arm", &"steady_arm")
    _mech.equip_part(&"right_arm", &"plated_arm")
    _mech._cycle_index = 0
    # Cycle 0 -> 1: left_arm (next equipped after torso)
    var r1: Dictionary = _mech.cycle_equipped_part()
    assert_eq(r1["slot"], &"left_arm", "first cycle -> left_arm")
    # Cycle 1 -> 2: right_arm
    var r2: Dictionary = _mech.cycle_equipped_part()
    assert_eq(r2["slot"], &"right_arm", "second cycle -> right_arm")
    # Cycle 2 -> 0 (wrap): torso
    var r3: Dictionary = _mech.cycle_equipped_part()
    assert_eq(r3["slot"], &"torso", "third cycle wraps back to torso")
    # And again: left_arm
    var r4: Dictionary = _mech.cycle_equipped_part()
    assert_eq(r4["slot"], &"left_arm", "fourth cycle -> left_arm")

func test_cycle_with_one_part_returns_same() -> void:
    _mech.equip_part(&"torso", &"starter_torso")
    _mech._cycle_index = 0
    var r1: Dictionary = _mech.cycle_equipped_part()
    var r2: Dictionary = _mech.cycle_equipped_part()
    assert_eq(r1["slot"], &"torso", "only equipped slot returned")
    assert_eq(r2["slot"], &"torso", "cycle with one part is idempotent (no rotation)")

func test_cycle_with_no_parts_returns_empty() -> void:
    var r: Dictionary = _mech.cycle_equipped_part()
    assert_eq(r["slot"], &"", "no parts -> empty slot")
    assert_eq(r["part_id"], &"", "no parts -> empty part_id")

func test_cycle_skips_empty_slots() -> void:
    # Equip torso + right_arm, but leave left_arm empty
    _mech.equip_part(&"torso", &"starter_torso")
    _mech.equip_part(&"right_arm", &"plated_arm")
    _mech._cycle_index = 0
    var r1: Dictionary = _mech.cycle_equipped_part()
    # First call should return one of the equipped; subsequent calls should
    # only return the OTHER (not the empty left_arm).
    var first_slot: StringName = r1["slot"]
    var r2: Dictionary = _mech.cycle_equipped_part()
    var second_slot: StringName = r2["slot"]
    assert_ne(first_slot, second_slot, "cycle alternates between equipped slots")
    assert_true(first_slot == &"torso" or first_slot == &"right_arm",
        "first slot is equipped")
    assert_true(second_slot == &"torso" or second_slot == &"right_arm",
        "second slot is equipped")
    assert_ne(first_slot, &"left_arm", "empty left_arm is skipped")
    assert_ne(second_slot, &"left_arm", "empty left_arm is skipped on wrap")

# --- D) HUD mech display ---

func test_hud_has_mech_labels_for_three_slots() -> void:
    assert_not_null(_hud, "HUD present in scene tree")
    assert_true(_hud._mech_labels.has(&"T"), "HUD has T label (torso)")
    assert_true(_hud._mech_labels.has(&"L"), "HUD has L label (left_arm)")
    assert_true(_hud._mech_labels.has(&"R"), "HUD has R label (right_arm)")

func test_hud_mech_labels_show_part_names() -> void:
    _level_runtime._equip_starting_mech_parts()
    _hud._refresh_mech_status()
    var t_text: String = _hud._mech_labels[&"T"].text
    var l_text: String = _hud._mech_labels[&"L"].text
    var r_text: String = _hud._mech_labels[&"R"].text
    assert_true(t_text.contains("Scrap") or t_text.contains("starter"),
        "T label shows torso part (got: %s)" % t_text)
    assert_true(l_text.contains("Steady") or l_text.contains("steady"),
        "L label shows left_arm part (got: %s)" % l_text)
    assert_true(r_text.contains("Plated") or r_text.contains("plated"),
        "R label shows right_arm part (got: %s)" % r_text)

func test_hud_active_slot_highlighted() -> void:
    _level_runtime._equip_starting_mech_parts()
    _hud._on_mech_cycled(&"left_arm", &"steady_arm")
    # L label should be yellow (active), T + R should be light gray
    var active_color: Color = _hud._mech_labels[&"L"].get_theme_color("font_color")
    var inactive_color: Color = _hud._mech_labels[&"T"].get_theme_color("font_color")
    # Active = (1, 0.9, 0.2) yellow; inactive = (0.85, 0.85, 0.85) light gray
    assert_gt(active_color.r, 0.9, "active L is reddish/yellow (r > 0.9)")
    assert_lt(inactive_color.r, 0.9, "inactive T is gray (r < 0.9)")

func test_hud_empty_slot_label_format() -> void:
    _mech.unequip_part(&"left_arm")
    _hud._refresh_mech_status()
    assert_eq(_hud._mech_labels[&"L"].text, "L:-", "empty left_arm shows 'L:-'")
