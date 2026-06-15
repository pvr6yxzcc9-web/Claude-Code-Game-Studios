extends GutTest

# FC-7 Smoke Test — Pre-Production PR-6 (NPC + Dialogue Tree)

func test_npc_data_resource_loaded() -> void:
    var reg: Node = get_node("/root/ResourceRegistry")
    var npc: Resource = reg.get_resource(&"vera_merchant")
    assert_not_null(npc, "vera_merchant loaded")
    assert_eq(String(npc.get("display_name")), "Vera the Salvage-Monger", "display name")
    assert_eq(StringName(npc.get("role")), &"merchant", "role = merchant")

func test_dialogue_tree_resource_loaded() -> void:
    var reg: Node = get_node("/root/ResourceRegistry")
    var tree: Resource = reg.get_resource(&"dlg_vera_greeting")
    assert_not_null(tree, "dlg_vera_greeting loaded")
    var nodes: Dictionary = tree.get("nodes")
    assert_true(nodes.has(&"greet"), "greet node exists")
    assert_true(nodes.has(&"lore"), "lore node exists")
    assert_true(nodes.has(&"bye"), "bye node exists")
    var greet: Dictionary = nodes[&"greet"]
    var choices: Array = greet.get("choices", [])
    assert_eq(choices.size(), 3, "greet has 3 choices")

func test_dialogue_manager_start_emits_signal() -> void:
    var dm: Node = get_node("/root/DialogueManager")
    var npc: Resource = get_node("/root/ResourceRegistry").get_resource(&"vera_merchant")
    var received: Array = []
    dm.dialogue_started.connect(func(n: Resource) -> void: received.append(n))
    dm.start_dialogue(npc)
    assert_true(dm.is_active, "dialogue is active")
    assert_eq(received.size(), 1, "dialogue_started emitted once")
    assert_eq(received[0], npc, "started with vera_merchant")

func test_dialogue_manager_enters_state_dialogue() -> void:
    var sm: Node = get_node("/root/GameStateMachine")
    var dm: Node = get_node("/root/DialogueManager")
    var npc: Resource = get_node("/root/ResourceRegistry").get_resource(&"vera_merchant")
    # Ensure we're in exploration (default state after FC-1 init)
    # pop any leftover push state
    while sm.state_stack.size() > 1:
        sm.pop()
    dm.start_dialogue(npc)
    assert_eq(sm.top_of_stack, &"state_dialogue", "top of stack is dialogue")

func test_dialogue_manager_choose_advances_node() -> void:
    var dm: Node = get_node("/root/DialogueManager")
    var npc: Resource = get_node("/root/ResourceRegistry").get_resource(&"vera_merchant")
    dm.start_dialogue(npc)
    # greet has 3 choices: 0=shop, 1=lore, 2=bye
    var nodes_received: Array = []
    dm.node_entered.connect(func(nid: StringName, text: String, choices: Array) -> void: nodes_received.append(nid))
    dm.choose(1)  # lore
    assert_eq(dm.current_node_id, &"lore", "advanced to lore node")
    assert_eq(nodes_received, [&"lore"], "node_entered emitted for lore")

func test_dialogue_manager_choose_end_ends_dialogue() -> void:
    var dm: Node = get_node("/root/DialogueManager")
    var npc: Resource = get_node("/root/ResourceRegistry").get_resource(&"vera_merchant")
    dm.start_dialogue(npc)
    # greet -> 2 = bye (which has 0 choices, ends dialogue)
    dm.choose(2)
    assert_false(dm.is_active, "dialogue ended after bye")
    var sm: Node = get_node("/root/GameStateMachine")
    assert_eq(sm.top_of_stack, &"state_exploration", "back to exploration after bye")

func test_dialogue_manager_invalid_choice_no_op() -> void:
    var dm: Node = get_node("/root/DialogueManager")
    var npc: Resource = get_node("/root/ResourceRegistry").get_resource(&"vera_merchant")
    dm.start_dialogue(npc)
    dm.choose(99)  # out of range
    assert_eq(dm.current_node_id, &"greet", "stayed on greet after invalid choice")
    assert_true(dm.is_active, "still active after invalid choice")

# --- S3-003 regression: DialogueUI choice navigation (W/S/Up/Down/Enter) ---
# These lock in the visual highlight navigation that was previously F5-only.
# We drive the UI via Input.parse_input_event() so the full _unhandled_input
# path (keycode match -> focus change -> _refresh_focus) is exercised.

func _send_key(keycode: int) -> void:
    var ev: InputEventKey = InputEventKey.new()
    ev.keycode = keycode
    ev.pressed = true
    ev.echo = false
    Input.parse_input_event(ev)

func test_dialogue_ui_initial_choice_focus_is_zero() -> void:
    var dm: Node = get_node("/root/DialogueManager")
    var npc: Resource = get_node("/root/ResourceRegistry").get_resource(&"vera_merchant")
    var dui: Node = get_tree().get_root().find_child("DialogueUI", true, false)
    assert_not_null(dui, "DialogueUI in scene tree")
    dm.start_dialogue(npc)
    await get_tree().process_frame
    assert_eq(dui._choice_focus, 0, "initial focus is 0 on dialogue start")

func test_dialogue_ui_move_down_advances_focus() -> void:
    var dm: Node = get_node("/root/DialogueManager")
    var npc: Resource = get_node("/root/ResourceRegistry").get_resource(&"vera_merchant")
    var dui: Node = get_tree().get_root().find_child("DialogueUI", true, false)
    dm.start_dialogue(npc)
    await get_tree().process_frame
    _send_key(KEY_S)
    await get_tree().process_frame
    assert_eq(dui._choice_focus, 1, "S key advances focus 0 -> 1")
    _send_key(KEY_S)
    await get_tree().process_frame
    assert_eq(dui._choice_focus, 2, "S key advances focus 1 -> 2")
    # Wrap: 2 + 1 = 3 mod 3 = 0
    _send_key(KEY_S)
    await get_tree().process_frame
    assert_eq(dui._choice_focus, 0, "S key wraps focus 2 -> 0")

func test_dialogue_ui_move_up_wraps_focus() -> void:
    var dm: Node = get_node("/root/DialogueManager")
    var npc: Resource = get_node("/root/ResourceRegistry").get_resource(&"vera_merchant")
    var dui: Node = get_tree().get_root().find_child("DialogueUI", true, false)
    dm.start_dialogue(npc)
    await get_tree().process_frame
    # From 0, W should wrap to last (2)
    _send_key(KEY_W)
    await get_tree().process_frame
    assert_eq(dui._choice_focus, 2, "W key from 0 wraps to 2")
    _send_key(KEY_W)
    await get_tree().process_frame
    assert_eq(dui._choice_focus, 1, "W key from 2 -> 1")

func test_dialogue_ui_enter_confirms_focused_choice() -> void:
    var dm: Node = get_node("/root/DialogueManager")
    var npc: Resource = get_node("/root/ResourceRegistry").get_resource(&"vera_merchant")
    var dui: Node = get_tree().get_root().find_child("DialogueUI", true, false)
    dm.start_dialogue(npc)
    await get_tree().process_frame
    # Move to choice 1 (lore) and confirm
    _send_key(KEY_S)
    await get_tree().process_frame
    assert_eq(dui._choice_focus, 1, "focused lore (idx 1)")
    _send_key(KEY_ENTER)
    await get_tree().process_frame
    assert_eq(dm.current_node_id, &"lore", "Enter confirmed focused choice -> lore node")
    assert_true(dm.is_active, "dialogue still active at lore (lore has 2 more choices)")
