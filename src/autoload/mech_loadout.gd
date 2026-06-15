extends Node

# MechLoadout (per mech GDD)
# Tracks the player's 5 mech parts: torso / left_arm / right_arm / legs / core.
# Aggregates stats (hp_bonus, attack_bonus, defense_bonus) from equipped parts.
# Slots not yet implemented (per MVP — PR-4 stub).

signal part_equipped(slot: StringName, part_id: StringName)
signal part_unequipped(slot: StringName)

const SLOTS: Array[StringName] = [&"torso", &"left_arm", &"right_arm", &"legs", &"core"]

# slot -> part_id (or &"" if empty)
var parts: Dictionary[StringName, StringName] = {}

func _ready() -> void:
    if get_node_or_null("/root/GameStateMachine") == null:
        push_error("MechLoadout: GameStateMachine must load first")
    for s in SLOTS:
        parts[s] = &""
    print("[MechLoadout] ready, %d slots (empty)" % SLOTS.size())

func equip_part(slot: StringName, part_id: StringName) -> void:
    if slot not in parts:
        push_error("MechLoadout: invalid slot %s" % slot)
        return
    parts[slot] = part_id
    part_equipped.emit(slot, part_id)

func unequip_part(slot: StringName) -> void:
    if slot not in parts:
        return
    parts[slot] = &""
    part_unequipped.emit(slot)

# S4-002: Cycle which slot is "active" for a given part_id, returning the
# newly-active slot. Only cycles between slots that have a part equipped;
# empty slots are skipped. The cycle order is the SLOTS array order.
# (Future: this could rotate to different parts within the same slot if
# multiple part variants exist. For now there's only one part per slot, so
# cycling is mostly a no-op for 3+ parts all in different slots — but the
# API is ready for when multiple variants per slot land.)
var _cycle_index: int = 0
func cycle_equipped_part() -> Dictionary:
    var equipped_slots: Array[StringName] = []
    for s in SLOTS:
        if parts[s] != &"":
            equipped_slots.append(s)
    if equipped_slots.is_empty():
        return {"slot": &"", "part_id": &""}
    if equipped_slots.size() == 1:
        # Only one part — nothing to cycle, but return current for HUD
        var only_slot: StringName = equipped_slots[0]
        return {"slot": only_slot, "part_id": parts[only_slot]}
    _cycle_index = (_cycle_index + 1) % equipped_slots.size()
    var new_slot: StringName = equipped_slots[_cycle_index]
    return {"slot": new_slot, "part_id": parts[new_slot]}

# Aggregate stats from all equipped parts.
# Each MechPart contributes hp_bonus / attack_bonus / defense_bonus (ints).
# WeaponLoadout weapon stats are applied separately.
func get_aggregated_stats() -> Dictionary:
    var total_hp: int = 0
    var total_attack: int = 0
    var total_defense: int = 0
    var reg: Node = get_node("/root/ResourceRegistry")
    for slot in SLOTS:
        var part_id: StringName = parts[slot]
        if part_id == &"":
            continue
        var part_res: Resource = reg.get_resource(part_id)
        if part_res == null:
            continue
        if "hp_bonus" in part_res:
            total_hp += int(part_res.get("hp_bonus"))
        if "attack_bonus" in part_res:
            total_attack += int(part_res.get("attack_bonus"))
        if "defense_bonus" in part_res:
            total_defense += int(part_res.get("defense_bonus"))
    return {
        "hp_bonus": total_hp,
        "attack_bonus": total_attack,
        "defense_bonus": total_defense,
    }

func get_state_snapshot() -> Dictionary:
    return {
        "schema_version": 1,
        "parts": parts.duplicate(),
    }

func load_snapshot(snap: Dictionary) -> Error:
    if not snap.has("parts"):
        return OK
    for key in snap["parts"].keys():
        parts[StringName(key)] = StringName(snap["parts"][key])
    return OK
