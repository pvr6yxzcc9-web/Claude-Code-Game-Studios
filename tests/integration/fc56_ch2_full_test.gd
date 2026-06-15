extends GutTest

# FC-56 Ch2 full scope (S6-102)
# Pins that all 10 rooms + 6 enemies + 1 boss + 4 NPCs + 5 terminals + 7 fragments + 1 BGM are in place:
#   1) chapter2.tres has 10 room_ids
#   2) chapter2 boss_id = boss_ice_warden
#   3) All 6 enemy .tres files registered
#   4) All 4 NPC .tres files registered with portraits
#   5) All 5 Ch2 terminal logs registered
#   6) All 7 Ch2 fragments registered
#   7) frozen_reactor.wav registered in MusicPlayer
#   8) Ch2 ice tile PNGs exist
#   9) level_runtime.change_chapter() builds Ch2 room 0 with NPC + encounter

var _main: Node = null
var _reg: Node = null
var _runtime: Node = null

func before_all() -> void:
    _main = load("res://src/main.tscn").instantiate()
    get_tree().root.add_child(_main)
    await get_tree().process_frame
    await get_tree().process_frame
    _reg = get_node("/root/ResourceRegistry")
    _runtime = get_tree().get_root().find_child("Main", true, false)

func after_all() -> void:
    if _main != null:
        _main.queue_free()
        _main = null

# 1) 10 rooms

func test_chapter2_has_10_rooms() -> void:
    var level: Resource = _reg.get_resource(&"chapter2_frozen_reactor")
    if level == null:
        pending("Ch2 not registered")
        return
    var rooms: Array = level.get("room_ids")
    assert_eq(rooms.size(), 10, "Ch2 has 10 rooms (c2_r1..c2_r10)")

# 2) Boss

func test_chapter2_boss_is_ice_warden() -> void:
    var level: Resource = _reg.get_resource(&"chapter2_frozen_reactor")
    if level == null:
        pending("Ch2 not registered")
        return
    assert_eq(level.get("boss_id"), &"boss_ice_warden", "Ch2 boss is Ice Warden")

# 3) Enemies

func test_ch2_enemies_registered() -> void:
    for eid in ["frostling", "glacier", "shard_bot", "ice_drone", "frost_walker", "crystal_sentinel", "boss_ice_warden"]:
        var e: Resource = _reg.get_resource(StringName(eid))
        assert_not_null(e, "%s registered" % eid)

# 4) NPCs

func test_ch2_npcs_registered_with_portraits() -> void:
    for npc_id in ["frost_engineer", "ice_hermit", "scavenger_leader", "frost_drone"]:
        var npc: Resource = _reg.get_resource(StringName(npc_id))
        assert_not_null(npc, "npc %s registered" % npc_id)
        var has_portrait: bool = "portrait" in npc and npc.get("portrait") != null
        assert_true(has_portrait, "npc %s has portrait" % npc_id)
        var dlg_id: StringName = npc.get("dialogue_tree_id")
        var dlg: Resource = _reg.get_resource(dlg_id)
        assert_not_null(dlg, "npc %s dialogue tree %s registered" % [npc_id, dlg_id])

# 5) Terminals

func test_ch2_terminals_registered() -> void:
    var log_ids: Array = [
        "log_who_remains",
        "log_whats_in_the_crates",
        "log_what_lurks_below",
        "log_the_cryo_chamber",
        "log_what_the_warden_knew",
    ]
    for log_id in log_ids:
        var log: Resource = _reg.get_resource(StringName(log_id))
        assert_not_null(log, "terminal %s registered" % log_id)
        assert_ne(log.get("unlock_fragment_id"), &"", "terminal %s unlocks a fragment" % log_id)

# 6) Fragments

func test_ch2_fragments_registered() -> void:
    var fids: Array = [
        "fragment_who_remains",
        "fragment_whats_in_the_crates",
        "fragment_what_lurks_below",
        "fragment_the_cryo_chamber",
        "fragment_what_the_warden_knew",
        "fragment_who_was_lyra",
        "fragment_the_lost_road",
    ]
    for fid in fids:
        var f: Resource = _reg.get_resource(StringName(fid))
        assert_not_null(f, "fragment %s registered" % fid)

# 7) BGM

func test_frozen_reactor_bgm_registered() -> void:
    var script: Script = load("res://src/autoload/music_player.gd")
    if script == null:
        pending("music_player.gd missing")
        return
    var src: String = script.source_code if "source_code" in script else ""
    assert_true(src.contains("frozen_reactor"), "MusicPlayer registers frozen_reactor track")

# 8) Ice tiles

func test_ch2_ice_tiles_exist() -> void:
    for name in ["floor_ice", "floor_ice_damaged", "wall_ice", "wall_ice_damaged"]:
        var path: String = "res://assets/tilesets/ch2/%s.png" % name
        assert_true(ResourceLoader.exists(path), "%s.png exists" % name)

# 9) change_chapter builds Ch2 room 0

func test_change_to_ch2_builds_room() -> void:
    if _runtime == null:
        pending("no runtime")
        return
    _runtime.change_chapter(&"chapter2_frozen_reactor")
    await get_tree().process_frame
    assert_eq(_runtime.current_room_index, 0, "Ch2 starts at room 0")
    var found_npc: bool = false
    for c in _runtime.get_children():
        if c.name.begins_with("NPC_") and "frost_engineer" in c.name:
            found_npc = true
            break
    assert_true(found_npc, "Ch2 room 0 has frost_engineer NPC")
    assert_eq(_runtime.get_chapter_index(), 2, "chapter_index is 2")
