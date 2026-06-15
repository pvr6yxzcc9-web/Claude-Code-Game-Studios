extends GutTest


# FC-6 Smoke Test — Pre-Production PR-5 (Terminal + Codex + StoryFragment)

func before_each() -> void:
	var meta: Node = get_node_or_null("/root/MetaState")
	if meta != null:
		meta.unlocked.clear()
		meta.discovered.clear()

func test_terminal_log_resource_loaded() -> void:
	var reg: Node = get_node("/root/ResourceRegistry")
	var log: Resource = reg.get_resource(&"log_scrapyard_intro")
	assert_not_null(log, "log_scrapyard_intro loaded")
	assert_eq(String(log.get("title")), "JOURNAL ENTRY 0042", "title correct")
	assert_eq(int(log.get("importance")), 3, "importance 3")

func test_story_fragment_resource_loaded() -> void:
	var reg: Node = get_node("/root/ResourceRegistry")
	var frag: Resource = reg.get_resource(&"fragment_who_we_were")
	assert_not_null(frag, "fragment loaded")
	assert_eq(int(frag.get("lore_layer")), 1, "lore_layer 1")

func test_terminal_controller_open_unlocks_fragment() -> void:
	var tc: Node = get_node("/root/TerminalController")
	var log: Resource = get_node("/root/ResourceRegistry").get_resource(&"log_scrapyard_intro")
	tc.open_log(log)
	assert_true(tc.is_open, "terminal is open after open_log")
	assert_true(get_node("/root/MetaState").is_unlocked(&"fragment_who_we_were"), "fragment unlocked")

func test_terminal_controller_open_idempotent() -> void:
	# Opening the same log twice should not emit fragment_unlocked twice
	var tc: Node = get_node("/root/TerminalController")
	var log: Resource = get_node("/root/ResourceRegistry").get_resource(&"log_scrapyard_intro")
	var received: Array = []
	var meta: Node = get_node("/root/MetaState")
	meta.fragment_unlocked.connect(func(id: StringName) -> void: received.append(id))
	tc.open_log(log)
	tc.open_log(log)  # second time, already unlocked
	assert_eq(received.size(), 1, "fragment_unlocked fired only once")

func test_terminal_controller_close() -> void:
	var tc: Node = get_node("/root/TerminalController")
	var log: Resource = get_node("/root/ResourceRegistry").get_resource(&"log_scrapyard_intro")
	tc.open_log(log)
	tc.close()
	assert_false(tc.is_open, "terminal closed")

func test_terminal_controller_open_transitions_to_state_terminal() -> void:
	# Post-S5 F5 sweep fix: open_log() must transition to state_terminal
	# so TerminalUI (visibility-gated on state_terminal per ui/terminal_ui.gd:57)
	# actually displays the log body. Without this, fragment unlocks silently
	# and player sees nothing.
	var sm: Node = get_node("/root/GameStateMachine")
	# Reset to exploration first
	if sm.top_of_stack != &"state_exploration":
		sm.transition_to(&"state_exploration")
	var tc: Node = get_node("/root/TerminalController")
	var log: Resource = get_node("/root/ResourceRegistry").get_resource(&"log_scrapyard_intro")
	tc.open_log(log)
	assert_eq(sm.top_of_stack, &"state_terminal", "open_log transitions to state_terminal")

func test_terminal_controller_open_idempotent_on_state() -> void:
	# Calling open_log while already in state_terminal should not
	# re-transition (which would fail per ALLOWED_TRANSITIONS).
	var sm: Node = get_node("/root/GameStateMachine")
	if sm.top_of_stack != &"state_exploration":
		sm.transition_to(&"state_exploration")
	var tc: Node = get_node("/root/TerminalController")
	var log: Resource = get_node("/root/ResourceRegistry").get_resource(&"log_scrapyard_intro")
	tc.open_log(log)
	assert_eq(sm.top_of_stack, &"state_terminal", "first call -> state_terminal")
	# Second call should not error
	tc.open_log(log)
	assert_eq(sm.top_of_stack, &"state_terminal", "second call stays in state_terminal")

func test_meta_state_fragment_unlocked_signal() -> void:
	var meta: Node = get_node("/root/MetaState")
	var received: Array = []
	meta.fragment_unlocked.connect(func(id: StringName) -> void: received.append(id))
	meta.mark_unlocked(&"test_fragment_1")
	meta.mark_unlocked(&"test_fragment_2")
	assert_eq(received, [&"test_fragment_1", &"test_fragment_2"], "both fragments signal")

func test_save_load_with_unlocked_fragments() -> void:
	var meta: Node = get_node("/root/MetaState")
	meta.mark_unlocked(&"fragment_who_we_were")
	var save: Node = get_node("/root/SaveManager")
	save.save_to_slot(3)
	await get_tree().create_timer(0.2).timeout
	meta.unlocked.clear()
	save.load_from_slot(3)
	assert_true(meta.is_unlocked(&"fragment_who_we_were"), "fragment persisted across save/load")
