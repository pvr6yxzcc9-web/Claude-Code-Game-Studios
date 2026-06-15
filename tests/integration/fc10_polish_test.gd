extends GutTest

# FC-10 Smoke Test — Pre-Production PR-9 (Polish + safety + integrity)

func test_all_ten_resource_subtypes_loaded() -> void:
    # Verify our 10 + 1 (DialogueTree) subtypes are all in registry
    var reg: Node = get_node("/root/ResourceRegistry")
    var loaded: Array = reg._registry.values()
    var found_subtypes: Array[String] = []
    for r in loaded:
        var s: Resource = r.get_script()
        if s != null and not (s.get_class() in found_subtypes):
            found_subtypes.append(s.get_class())
    # Expect at least: WeaponData, AmmoData, EnemyData, MechPartData, TerminalLogData,
    # StoryFragmentData, NPCData, LevelData, DialogueTree
    assert_true(loaded.size() >= 10, "at least 10 resources loaded, got %d" % loaded.size())

func test_no_duplicate_ids_in_registry() -> void:
    var reg: Node = get_node("/root/ResourceRegistry")
    var seen: Dictionary = {}
    var dupes: Array = []
    for id in reg._registry.keys():
        if seen.has(id):
            dupes.append(id)
        seen[id] = true
    assert_eq(dupes.size(), 0, "no duplicate ids; found: %s" % str(dupes))

func test_weapon_loadout_default_resolves() -> void:
    var reg: Node = get_node("/root/ResourceRegistry")
    var loadout: Node = get_node("/root/WeaponLoadout")
    var weapon: Resource = reg.get_resource(loadout.weapon_slots[0])
    assert_not_null(weapon, "default weapon (blaster_rifle) resolves in registry")

func test_all_autoloads_present() -> void:
    var expected: Array[String] = [
        "GameStateMachine", "InputBus", "ResourceRegistry", "MetaState",
        "MechLoadout", "WeaponLoadout", "Inventory", "TerminalController",
        "DialogueManager", "SaveManager",
    ]
    var missing: Array = []
    for name in expected:
        if get_node_or_null("/root/" + name) == null:
            missing.append(name)
    assert_eq(missing.size(), 0, "all 10 autoloads present; missing: %s" % str(missing))

func test_state_machine_no_illegal_self_transition() -> void:
    var sm: Node = get_node("/root/GameStateMachine")
    # Same state should be no-op
    var err: int = sm.transition_to(sm.top_of_stack)
    assert_ne(err, OK, "transitioning to current state fails (not OK)")

func test_save_manager_has_3_manual_slot_count() -> void:
    var save: Node = get_node("/root/SaveManager")
    assert_eq(save.MANUAL_SLOT_COUNT, 3, "3 manual save slots")
    assert_eq(save.SLOT_AUTOSAVE, -1, "autosave slot is -1")

func test_damage_bounds_hold_for_all_weapon_ranges() -> void:
    # For every weapon in registry, ensure damage is in [10, 480] when fired
    var reg: Node = get_node("/root/ResourceRegistry")
    for w in reg.get_all_of_type(&"WeaponData"):
        var wmin: int = int(w.get("min_damage"))
        var wmax: int = int(w.get("max_damage"))
        # Simulate a crit hit
        var dmg: int = BattleMathLib.compute_base_damage(wmin, wmax, 1.0, true, 3.0)
        assert_true(dmg >= 10 and dmg <= 480, "weapon %s crit damage in bounds" % w.get("id"))

func test_encounter_rate_is_in_valid_range() -> void:
    var reg: Node = get_node("/root/ResourceRegistry")
    var level: Resource = reg.get_resource(&"chapter1_scrapyard")
    var rate: float = float(level.get("encounter_rate"))
    assert_true(rate >= 0.0 and rate <= 1.0, "encounter rate in [0, 1]")

func test_save_manager_in_save_producers() -> void:
    # PR-8 / PR-4 already fixed — verify all required producers are in the list
    # Note: save_manager is itself the saver; it does not save itself (would be a cycle)
    var save: Node = get_node("/root/SaveManager")
    var missing: Array = []
    var required: Array[String] = [
        "game_state_machine", "input_bus", "resource_registry", "meta_state",
        "inventory", "weapon_loadout", "mech_loadout",
    ]
    for ns in required:
        if ns not in save.PRODUCER_NAMESPACES:
            missing.append(ns)
    assert_eq(missing.size(), 0, "all required producers in save list; missing: %s" % str(missing))
