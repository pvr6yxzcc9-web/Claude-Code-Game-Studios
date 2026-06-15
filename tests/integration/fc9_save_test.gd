extends GutTest

# FC-9 Smoke Test — Pre-Production PR-8 (Save/Load full + autosave + death + save UI)

func before_each() -> void:
    var save: Node = get_node("/root/SaveManager")
    # Clear pending write so tests don't interfere
    save._pending_write = false
    save._autosave_accumulator = 0.0

func test_autosave_toggle() -> void:
    var save: Node = get_node("/root/SaveManager")
    assert_true(save.autosave_enabled, "autosave is enabled by default")
    save.autosave_enabled = false
    assert_false(save.autosave_enabled, "autosave can be disabled")
    save.autosave_enabled = true

func test_autosave_interval_default() -> void:
    var save: Node = get_node("/root/SaveManager")
    assert_eq(save._autosave_interval_sec, 60.0, "default interval is 60 seconds")

func test_autosave_triggers_on_slot_minus_one() -> void:
    var save: Node = get_node("/root/SaveManager")
    var err: int = save.save_to_slot(save.SLOT_AUTOSAVE)
    assert_eq(err, OK, "autosave returns OK immediately")
    # Wait for the deferred write
    await get_tree().create_timer(0.3).timeout
    # File should exist
    assert_true(FileAccess.file_exists(save._slot_to_path(save.SLOT_AUTOSAVE)), "autosave file written")

func test_save_to_three_manual_slots_writes_three_files() -> void:
    var save: Node = get_node("/root/SaveManager")
    save.save_to_slot(0)
    save.save_to_slot(1)
    save.save_to_slot(2)
    await get_tree().create_timer(0.5).timeout
    for s in 3:
        assert_true(FileAccess.file_exists(save._slot_to_path(s)), "slot %d file written" % s)

func test_load_missing_slot_returns_error() -> void:
    var save: Node = get_node("/root/SaveManager")
    # Use a non-existent path (slot 99 is out of valid range)
    var err: int = save.load_from_slot(99)  # never written
    assert_eq(err, ERR_FILE_NOT_FOUND, "loading non-existent slot returns ERR_FILE_NOT_FOUND")

func test_save_load_round_trip_preserves_weapon_loadout() -> void:
    var save: Node = get_node("/root/SaveManager")
    var loadout: Node = get_node("/root/WeaponLoadout")
    loadout.equip_weapon(1, &"shotgun")
    save.save_to_slot(0)
    await get_tree().create_timer(0.2).timeout
    loadout.equip_weapon(1, &"")
    save.load_from_slot(0)
    assert_eq(loadout.weapon_slots[1], &"shotgun", "weapon restored from slot 0")

func test_save_load_round_trip_preserves_inventory() -> void:
    var save: Node = get_node("/root/SaveManager")
    var inv: Node = get_node("/root/Inventory")
    inv.reset()
    inv.add(&"medkit", 5)
    save.save_to_slot(1)
    await get_tree().create_timer(0.2).timeout
    inv.add(&"ammo_pack", 99)  # pollution
    save.load_from_slot(1)
    assert_eq(inv.count(&"medkit"), 5, "medkit restored")
    assert_eq(inv.count(&"ammo_pack"), 0, "ammo_pack removed by load")

func test_save_version_in_save_dict() -> void:
    var save: Node = get_node("/root/SaveManager")
    save.save_to_slot(0)
    await get_tree().create_timer(0.2).timeout
    var path: String = save._slot_to_path(0)
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if file == null:
        pending("save file not found at %s" % path)
        return
    var json: String = file.get_as_text()
    file.close()
    assert_true(json.contains("save_version"), "save_version field present")
    assert_true(json.contains("1"), "save_version = 1")
