extends GutTest

# FC-21 SaveUI highlight + slot navigation (S3-010 + Sprint 4 carryover)
# Verifies:
#   - SaveUI exists in main scene, hidden by default
#   - Highlight Y position tracks selected_slot (regression for the
#     highlight-y-was-absolute bug: 60 + i*40 instead of PANEL_Y + 80 + i*40)
#   - Up/Down navigation via InputBus
#   - save_slot / load_slot emit the right signals

const MAIN_SCENE := "res://src/main.tscn"

var _main: Node = null
var _save_ui: Node = null
var _save_mgr: Node = null
var _input_bus: Node = null

func before_all() -> void:
    _main = load(MAIN_SCENE).instantiate()
    get_tree().root.add_child(_main)
    await get_tree().process_frame
    await get_tree().process_frame
    _save_ui = get_tree().get_root().find_child("SaveUI", true, false)
    _save_mgr = get_node("/root/SaveManager")
    _input_bus = get_node("/root/InputBus")

func after_all() -> void:
    if _main != null:
        _main.queue_free()
        _main = null

func test_save_ui_present_and_hidden_by_default() -> void:
    assert_not_null(_save_ui, "SaveUI in scene tree")
    assert_false(_save_ui.visible, "SaveUI hidden by default")
    assert_false(_save_ui.is_open, "SaveUI is_open=false by default")
    assert_eq(_save_ui.selected_slot, 0, "default selected_slot is 0")

# S3-010 regression: highlight Y must match the slot label Y for the
# currently selected slot, NOT some hardcoded absolute value.
# The old code was `_highlight.position.y = 60 + selected_slot * 40`, which
# placed the highlight at y=60..160 — above the panel (which starts at y=160).
func test_highlight_y_matches_slot_0_label_y_when_selected() -> void:
    _save_ui.open()
    await get_tree().process_frame
    var highlight_y: float = _save_ui._highlight.position.y
    var slot0_y: float = _save_ui._slot_labels[0].position.y
    # Highlight is a band that visually wraps a slot row — top of highlight
    # should equal the slot label's y (allow 1px slack for sub-pixel drift).
    var diff0: float = absf(highlight_y - slot0_y)
    assert_true(diff0 <= 1.0,
        "highlight y matches slot 0 label y within 1px (got diff=%.2f, was 60, should be panel_y+80)" % diff0)

func test_highlight_y_moves_with_selected_slot() -> void:
    _save_ui.open()
    await get_tree().process_frame
    # Default slot 0
    var slot0_y: float = _save_ui._slot_labels[0].position.y
    var diff0: float = absf(_save_ui._highlight.position.y - slot0_y)
    assert_true(diff0 <= 1.0, "highlight at slot 0 on open (diff=%.2f)" % diff0)
    # Simulate menu_down via InputBus
    _input_bus.action_pressed.emit(&"menu_down")
    await get_tree().process_frame
    var slot1_y: float = _save_ui._slot_labels[1].position.y
    assert_eq(_save_ui.selected_slot, 1, "selected_slot advanced to 1")
    var diff1: float = absf(_save_ui._highlight.position.y - slot1_y)
    assert_true(diff1 <= 1.0, "highlight moved to slot 1 (diff=%.2f)" % diff1)
    # Up should wrap 0 -> 2
    _input_bus.action_pressed.emit(&"menu_up")
    _input_bus.action_pressed.emit(&"menu_up")
    await get_tree().process_frame
    var slot2_y: float = _save_ui._slot_labels[2].position.y
    assert_eq(_save_ui.selected_slot, 2, "selected_slot wrapped up to 2")
    var diff2: float = absf(_save_ui._highlight.position.y - slot2_y)
    assert_true(diff2 <= 1.0, "highlight moved to slot 2 (diff=%.2f)" % diff2)

func test_save_slot_emits_signal() -> void:
    _save_ui.open()
    await get_tree().process_frame
    _save_ui.selected_slot = 0
    var received: Array = []
    _save_ui.slot_saved.connect(func(s: int) -> void: received.append(s))
    _save_ui.save_slot(0)
    assert_eq(received, [0], "slot_saved emitted with slot 0")
    _save_ui.close()

func test_load_existing_slot_emits_signal_and_closes() -> void:
    # Write a save first
    _save_mgr.save_to_slot(1)
    await get_tree().create_timer(0.3).timeout
    _save_ui.open()
    await get_tree().process_frame
    _save_ui.selected_slot = 1
    var received: Array = []
    _save_ui.slot_loaded.connect(func(s: int) -> void: received.append(s))
    _save_ui.load_slot(1)
    assert_eq(received, [1], "slot_loaded emitted with slot 1")
    assert_false(_save_ui.is_open, "SaveUI closed after successful load")

func test_highlight_stays_inside_panel_bounds() -> void:
    # Defensive: even at last slot, highlight must still be within the panel.
    _save_ui.open()
    await get_tree().process_frame
    _save_ui.selected_slot = 2
    _save_ui._refresh()
    var h: Control = _save_ui._highlight
    var panel_top: float = _save_ui.PANEL_Y
    var panel_bot: float = _save_ui.PANEL_Y + _save_ui.PANEL_H
    assert_true(h.position.y > panel_top,
        "highlight top is below panel top (no clip above)")
    assert_true(h.position.y + h.size.y < panel_bot,
        "highlight bottom is above panel bottom (no clip below)")
    _save_ui.close()
