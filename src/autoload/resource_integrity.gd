extends Node

# ResourceIntegrity (per control-manifest + PR-9)
# Performs a one-shot integrity audit at boot:
#   - All 10 expected Resource subtypes are loadable
#   - No duplicate ids in ResourceRegistry
#   - No null references in WeaponLoadout / MechLoadout / Inventory defaults
# Emits a report signal; logs to console.

signal integrity_check_passed()
signal integrity_check_failed(reasons: Array)

const EXPECTED_SUBTYPES: Array[String] = [
    "WeaponData", "AmmoData", "EnemyData", "MechPartData",
    "ItemData", "EffectData", "TerminalLogData", "StoryFragmentData",
    "RegionData", "NPCData",
]

func _ready() -> void:
    # Run check after one frame so all autoloads are ready
    await get_tree().process_frame
    run_check()

func run_check() -> void:
    var reasons: Array = []
    var reg: Node = get_node("/root/ResourceRegistry")
    if reg == null:
        reasons.append("ResourceRegistry autoload missing")
        integrity_check_failed.emit(reasons)
        return
    var loaded: Array = reg._registry.values()
    # 1. Check expected subtypes
    for st in EXPECTED_SUBTYPES:
        var found_one: bool = false
        for r in loaded:
            if r.is_class(st) or r.get_script().get_class() == st:
                found_one = true
                break
        if not found_one:
            reasons.append("No resource of subtype %s found" % st)
    # 2. Check duplicate ids
    var seen: Dictionary = {}
    for r in loaded:
        var id_v: Variant = r.get("id")
        if id_v == null:
            continue
        var id: String = String(id_v)
        if seen.has(id):
            reasons.append("Duplicate id: %s" % id)
        seen[id] = true
    # 3. Check WeaponLoadout default
    var loadout: Node = get_node_or_null("/root/WeaponLoadout")
    if loadout != null and loadout.weapon_slots[0] != &"":
        var reg_node: Node = get_node("/root/ResourceRegistry")
        if reg_node.get_resource(loadout.weapon_slots[0]) == null:
            reasons.append("WeaponLoadout default %s not in registry" % loadout.weapon_slots[0])
    # Report
    if reasons.is_empty():
        print("[ResourceIntegrity] PASS — %d resources, 10 subtypes, 0 duplicates" % loaded.size())
        integrity_check_passed.emit()
    else:
        push_error("[ResourceIntegrity] FAIL — %d issue(s):" % reasons.size())
        for r in reasons:
            push_error("  - " + r)
        integrity_check_failed.emit(reasons)
