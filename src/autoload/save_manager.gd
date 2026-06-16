extends Node

# SaveManager (autoload #5)
# Per ADR-0003 (Contract) + ADR-0004 (I/O) + ADR-0005 (Upgrade).
# Composes 10 producer snapshots; async write via WorkerThreadPool.

signal save_completed(slot: int)
signal save_failed(slot: int, error: String)
signal load_completed(slot: int)
signal load_failed(slot: int, error: String)

const SAVE_VERSION_CURRENT: int = 2
const SLOT_AUTOSAVE: int = -1
const MANUAL_SLOT_COUNT: int = 3

# Per ADR-0003: namespaces ordered by dependency
const PRODUCER_NAMESPACES: Array[StringName] = [
    &"game_state_machine",
    &"input_bus",
    &"resource_registry",
    &"meta_state",
    &"inventory",
    &"weapon_loadout",
    &"mech_loadout",
    &"level",
    &"encounters",
    &"npc_terminal",
    &"player_controller",
    &"battle_core",
    &"hud_settings",
    &"clinic_manager",
]

var _pending_slot: int = -2  # -2 = idle, -1 = autosave, 0-2 = manual
var _pending_write: bool = false
var _pending_json: String = ""
var _pending_result: Dictionary = {}

# Autosave timer (per PR-8)
var _autosave_interval_sec: float = 60.0
var _autosave_accumulator: float = 0.0
var autosave_enabled: bool = true

# Per ADR-0005: upgrade functions
var _upgrade_chain: Dictionary = {}

func _ready() -> void:
    # ADR-0001: assert all upstream autoloads exist
    if get_node_or_null("/root/GameStateMachine") == null:
        push_error("SaveManager: GameStateMachine must load before SaveManager")
    if get_node_or_null("/root/InputBus") == null:
        push_error("SaveManager: InputBus must load before SaveManager")
    if get_node_or_null("/root/ResourceRegistry") == null:
        push_error("SaveManager: ResourceRegistry must load before SaveManager")
    if get_node_or_null("/root/MetaState") == null:
        push_error("SaveManager: MetaState must load before SaveManager")
    set_process(true)
    print("[SaveManager] ready as autoload #5; autosave interval=%ss" % _autosave_interval_sec)

func _process(delta: float) -> void:
    var _sm: Node = get_node_or_null("/root/GameStateMachine")
    if _sm != null and _sm.is_paused():
        return
    if not _pending_write:
        # Autosave tick (per PR-8)
        if autosave_enabled:
            _autosave_accumulator += delta
            if _autosave_accumulator >= _autosave_interval_sec:
                _autosave_accumulator = 0.0
                save_to_slot(SLOT_AUTOSAVE)
        return
    # ADR-0004: async write via deferred coroutine — 4.6 has no thread-pool API for Callable
    # Schedule the actual write on next idle frame
    _pending_write = false
    var slot: int = _pending_slot
    var json: String = _pending_json
    var ok: bool = _write_to_disk_sync(slot, json)
    if ok:
        save_completed.emit(slot)
    else:
        save_failed.emit(slot, "write failed — see prior error")
    _pending_slot = -2
    _pending_json = ""

# Per ADR-0004 + ADR-0003: write on next idle frame (avoids frame hitches without WorkerThreadPool)
func save_to_slot(slot: int) -> Error:
    if _pending_slot != -2:
        push_warning("SaveManager: save already in flight for slot %d" % _pending_slot)
        return ERR_BUSY
    var save_dict: Dictionary = serialize_all()
    var json: String = JSON.stringify(save_dict, "  ")
    _pending_slot = slot
    _pending_json = json
    _pending_write = true
    return OK

func _write_to_disk_sync(slot: int, json: String) -> bool:
    var path: String = _slot_to_path(slot)
    # Godot 4.6: use FileAccess.open(path, mode) — the canonical static factory
    var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        var err: Error = FileAccess.get_open_error()
        push_error("SaveManager: open WRITE failed for %s: %d" % [path, err])
        return false
    # Per ADR-0004: 4.4+ returns bool — MUST check
    var ok: bool = file.store_string(json)
    if not ok:
        push_error("SaveManager: store_string returned false")
        file.close()
        return false
    file.flush()
    file.close()
    return true

func load_from_slot(slot: int) -> Error:
    var path: String = _slot_to_path(slot)
    if not FileAccess.file_exists(path):
        return ERR_FILE_NOT_FOUND
    # Godot 4.6: canonical static factory
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("SaveManager: open READ failed")
        return ERR_FILE_CANT_OPEN
    var json: String = file.get_as_text()
    file.close()
    var parsed: Variant = JSON.parse_string(json)
    if parsed == null or not parsed is Dictionary:
        push_error("SaveManager: parse failed")
        return ERR_PARSE_ERROR
    var snap: Dictionary = parsed
    # Per ADR-0005: version check + upgrade
    var save_version: int = snap.get("save_version", 0)
    if save_version > SAVE_VERSION_CURRENT:
        push_error("SaveManager: save too new")
        return ERR_INVALID_DATA
    if save_version < SAVE_VERSION_CURRENT:
        snap = _upgrade_snapshot(snap, save_version, SAVE_VERSION_CURRENT)
    var err: Error = restore_all(snap)
    if err != OK:
        return err
    load_completed.emit(slot)
    return OK

func serialize_all() -> Dictionary:
    var save: Dictionary = {
        "save_version": SAVE_VERSION_CURRENT,
        "saved_at_unix": Time.get_unix_time_from_system(),
    }
    for ns in PRODUCER_NAMESPACES:
        var producer: Node = get_node_or_null("/root/%s" % _pascalize(String(ns)))
        if producer == null or not producer.has_method("get_state_snapshot"):
            push_warning("SaveManager: producer %s missing" % ns)
            continue
        save[ns] = producer.get_state_snapshot()
    return save

func restore_all(snap: Dictionary) -> Error:
    var first_error: Error = OK
    for ns in PRODUCER_NAMESPACES:
        if not snap.has(ns):
            continue  # missing namespace = OK
        var producer: Node = get_node_or_null("/root/%s" % _pascalize(String(ns)))
        if producer == null or not producer.has_method("load_snapshot"):
            continue
        var err: Error = producer.load_snapshot(snap[ns])
        if err != OK and first_error == OK:
            first_error = err
    return first_error

func get_autosave() -> Error:
    return load_from_slot(SLOT_AUTOSAVE)

func _slot_to_path(slot: int) -> String:
    if slot == SLOT_AUTOSAVE:
        return "user://save_autosave.json"
    return "user://save_%d.json" % slot

func _pascalize(s: String) -> String:
    # snake_case → PascalCase (e.g., game_state_machine → GameStateMachine)
    var parts: Array = s.split("_")
    var out: String = ""
    for p in parts:
        if p == "":
            continue
        out += p.capitalize()
    return out

func _upgrade_snapshot(snap: Dictionary, from: int, to: int) -> Dictionary:
    # Per ADR-0005: chain upgrades. v1 → v2 adds party state (S7-010).
    if from == to:
        return snap
    if from == 1 and to == 2:
        return _upgrade_v1_to_v2(snap)
    push_warning("SaveManager: no upgrade path from v%d to v%d" % [from, to])
    return snap

# S7-010: v1 → v2 migration. Adds party state (per-pilot level/XP/abilities,
# 4 mechs), cangqiong_unlocked flag (always false for migrated saves), and
# pilot states (defaults to all ACTIVE).
func _upgrade_v1_to_v2(snap: Dictionary) -> Dictionary:
    # Add party state under "party" namespace (not in PRODUCER_NAMESPACES yet,
    # so we create it inline)
    if not snap.has("party"):
        snap["party"] = _default_party_state_v2()
    # Ensure mech_loadout has cangqiong_unlocked (false for migrated saves)
    if not snap.has("mech_loadout"):
        snap["mech_loadout"] = {}
    if not snap["mech_loadout"].has("cangqiong_unlocked"):
        snap["mech_loadout"]["cangqiong_unlocked"] = false
    # Ensure clinic has pilot_states (all ACTIVE for migrated saves)
    if not snap.has("clinic"):
        snap["clinic"] = {}
    if not snap["clinic"].has("pilot_states"):
        snap["clinic"]["pilot_states"] = {
            "ranger": 0,  # PilotState.ACTIVE
            "frostbite": 0,
            "bomber": 0,
        }
    # Bump version
    snap["save_version"] = 2
    print("[SaveManager] upgraded snapshot v1 → v2 (party state added)")
    return snap

# Default party state for new games and v1 migrations
func _default_party_state_v2() -> Dictionary:
    return {
        "ranger": {"level": 1, "xp": 0, "abilities": []},
        "frostbite": {"level": 1, "xp": 0, "abilities": [], "recruited": false},
        "bomber": {"level": 1, "xp": 0, "abilities": [], "recruited": false},
        "active_pilot": "ranger",
    }
