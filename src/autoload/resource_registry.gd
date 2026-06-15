extends Node

# ResourceRegistry (autoload #3)
# Per ADR-0008 Resource Schema + architecture §4a.
# Loads all .tres files at boot; provides id-based lookup.
# Resources are immutable at runtime (per ADR-0007 — see resource/immutable_resource.gd).

var _registry: Dictionary[StringName, Resource] = {}

func _ready() -> void:
    # ADR-0001: assert upstream autoloads exist (GameStateMachine is #1, this is #3)
    if get_node_or_null("/root/GameStateMachine") == null:
        push_error("ResourceRegistry: GameStateMachine must load before ResourceRegistry")
    if get_node_or_null("/root/InputBus") == null:
        push_error("ResourceRegistry: InputBus must load before ResourceRegistry")

    # Load all .tres files in res://data/ recursively
    _load_all_resources()
    print("[ResourceRegistry] ready, %d resources loaded" % _registry.size())

func _load_all_resources() -> void:
    var paths: Array[String] = _scan_directory("res://data/")
    for path in paths:
        # S6-020 fix: in pck context, the scan returns .tres.remap paths.
        # The original .tres path (without .remap) works because Godot
        # transparently resolves remaps. Try the canonical .tres path.
        if not path.ends_with(".tres") and not path.ends_with(".tres.remap"):
            continue
        var load_path: String = path
        if path.ends_with(".tres.remap"):
            load_path = path.replace(".tres.remap", ".tres")
        var res: Resource = ResourceLoader.load(load_path)
        if res == null:
            continue
        if not ("id" in res):
            continue
        var id: StringName = res.get("id")
        if id in _registry:
            push_error("ResourceRegistry: duplicate id %s in %s" % [id, path])
            continue
        _registry[id] = res

func _scan_directory(dir: String) -> Array[String]:
    var paths: Array[String] = []
    var d: DirAccess = DirAccess.open(dir)
    if d == null:
        return paths
    d.list_dir_begin()
    var entry: String = d.get_next()
    while entry != "":
        if entry.begins_with("."):
            entry = d.get_next()
            continue
        var full_path: String = dir.path_join(entry)
        if d.current_is_dir():
            paths.append_array(_scan_directory(full_path))
        else:
            paths.append(full_path)
        entry = d.get_next()
    d.list_dir_end()
    return paths

func get_resource(id: StringName) -> Resource:
    if not _registry.has(id):
        push_warning("ResourceRegistry: id %s not found" % id)
        return null
    return _registry[id]

func get_all_of_type(type: StringName) -> Array[Resource]:
    var result: Array[Resource] = []
    for res in _registry.values():
        # S6-020 fix: also check get_script().get_class() because
        # custom resource subtypes' is_class may not work in pck context
        # until the script is recompiled.
        if res.is_class(type):
            result.append(res)
            continue
        var script: Script = res.get_script()
        if script != null and script.get_class() == String(type):
            result.append(res)
    return result

func has(id: StringName) -> bool:
    return _registry.has(id)
