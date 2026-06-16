extends Node
# Party Battle Controller (Sprint 7-001 S7-001 REAL implementation)
#
# PR 4: Add legacy_1v1_mode flag + state_battle integration.
# Still does NOT modify the existing 1v1 battle_scene.gd.
#
# PR 4 changes:
# - Add _mode flag (default MODE_1V1 for production safety)
# - When _mode = MODE_3V1, the 3v1 path activates on state_battle
# - When _mode = MODE_AUTO, auto-detect based on party size
# - Existing 1v1 BattleScene still works (unchanged)
#
# SAFETY: _mode defaults to MODE_1V1. The 3v1 path is opt-in only.
# Production 1v1 fights in Ch1/Ch2 are unchanged.

# === Signals ===

signal party_battle_started(enemy_id: StringName)
signal party_battle_ended(victory: bool)
signal party_member_attacked(pilot_id: StringName, slot: int, damage: int)
signal active_mech_changed(new_index: int)
signal party_member_knocked_out(pilot_id: StringName)
signal enemy_turn_started()
signal enemy_attacked(target_index: int, damage: int)
signal party_mode_changed(new_mode: int)  # 0=1v1, 1=3v1, 2=auto

# === Mode Configuration ===

const MODE_1V1: int = 0
const MODE_3V1: int = 1
const MODE_AUTO: int = 2  # auto-detect based on party size

# Current mode (default MODE_1V1 for production safety)
var _mode: int = MODE_1V1

# === Party State ===

# 3 mechs in the party. Initially the default 3 (Ranger, Frostbite, Bomber).
# Loaded from MechLoadout (S7-003) at battle start.
var _party: Array[Dictionary] = []
var _active_mech_index: int = 0  # which mech gets the next player action
var _round_number: int = 0
var _party_phase: StringName = &"player"  # "player" or "enemy"
var _mechs_acted_this_round: Array[int] = []  # indices of mechs that have acted
var _enemy: Dictionary = {}
var _in_battle: bool = false

# === Lifecycle ===

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_process_unhandled_input(true)
    var sm: Node = get_node_or_null("/root/GameStateMachine")
    if sm != null:
        sm.state_changed.connect(_on_state_changed)
    print("[PartyBattleController] ready (S7-001 first PR)")

func _on_state_changed(_old: StringName, new: StringName) -> void:
    # S7-001 PR 4: Hook into state_battle with mode-based dispatch.
    # Existing 1v1 BattleScene ALSO listens; we don't suppress it.
    # The 3v1 path is opt-in via set_mode(MODE_3V1) or MODE_AUTO.
    if new == &"state_battle" and not _in_battle:
        var effective_mode: int = _resolve_mode()
        if effective_mode == MODE_3V1:
            var pending_id: StringName = _get_pending_enemy_id()
            if pending_id != &"":
                print("[PartyBattleController] state_battle → 3v1 (enemy: %s)" % pending_id)
                start_party_battle(pending_id)
            else:
                print("[PartyBattleController] state_battle → 3v1 mode, but no pending enemy. Use debug_start_test_battle() to test.")
        # else: MODE_1V1 — existing BattleScene handles it. We stay dormant.

func _resolve_mode() -> int:
    if _mode == MODE_AUTO:
        var pm: Node = get_node_or_null("/root/PartyManager")
        if pm != null and pm.get_party_mechs().size() >= 3:
            return MODE_3V1
        return MODE_1V1
    return _mode

func _get_pending_enemy_id() -> StringName:
    # The encounter_tile sets BattleScene._pending_enemy_id; we
    # can't read that directly. Until encounter_tile exposes a
    # global pending ID, this is empty. Use debug_start_test_battle()
    # to test 3v1 without an encounter_tile trigger.
    return &""

# === Mode API (PR 4 new) ===

func set_mode(mode: int) -> void:
    if mode not in [MODE_1V1, MODE_3V1, MODE_AUTO]:
        push_error("PartyBattleController: invalid mode %d" % mode)
        return
    _mode = mode
    party_mode_changed.emit(mode)
    print("[PartyBattleController] mode → %s" % _mode_name(mode))

func get_mode() -> int:
    return _mode

func _mode_name(mode: int) -> String:
    match mode:
        MODE_1V1: return "1v1 (legacy)"
        MODE_3V1: return "3v1 (party)"
        MODE_AUTO: return "auto"
        _: return "unknown"

# Convenience debug commands
func set_party_mode_3v1() -> void:
    set_mode(MODE_3V1)

func set_party_mode_1v1() -> void:
    set_mode(MODE_1V1)

func set_party_mode_auto() -> void:
    set_mode(MODE_AUTO)

# === Public API ===

func start_party_battle(enemy_id: StringName) -> Error:
    # Loads the enemy + 3 mechs, starts a 3v1 round loop.
    var reg: Node = get_node("/root/ResourceRegistry")
    var enemy_res: Resource = reg.get_resource(enemy_id)
    if enemy_res == null:
        push_error("PartyBattleController: enemy %s not found" % enemy_id)
        return ERR_INVALID_PARAMETER

    # Load 3 mechs from MechLoadout (S7-003 data)
    _party = _load_party_mechs()
    if _party.size() < 1:
        push_error("PartyBattleController: no party mechs loaded")
        return ERR_DOES_NOT_EXIST

    _enemy = {
        "id": enemy_id,
        "max_hp": int(enemy_res.get("max_hp")),
        "hp": int(enemy_res.get("max_hp")),
        "attack": int(enemy_res.get("attack")),
        "accuracy": float(enemy_res.get("accuracy")),
        "display_name": String(enemy_res.get("display_name")),
    }
    _active_mech_index = 0
    _round_number = 1
    _party_phase = &"player"
    _mechs_acted_this_round = []
    _in_battle = true
    party_battle_started.emit(enemy_id)
    print("[PartyBattleController] started 3v1 vs %s (HP=%d)" % [enemy_id, _enemy.hp])
    return OK

func end_party_battle(victory: bool) -> void:
    _in_battle = false
    party_battle_ended.emit(victory)
    print("[PartyBattleController] ended: victory=%s" % victory)

# === Party Loading (S7-003 data) ===

func _load_party_mechs() -> Array[Dictionary]:
    # S7-001 PR 2: Read from PartyManager (the new autoload, stub for now).
    # PartyManager is the data source; MechLoadout (S7-003) will replace
    # it when committed.
    var pm: Node = get_node_or_null("/root/PartyManager")
    if pm == null:
        push_warning("PartyBattleController: PartyManager autoload missing — using hardcoded fallback")
        return _load_party_mechs_fallback()
    return pm.get_party_mechs()

func _load_party_mechs_fallback() -> Array[Dictionary]:
    return [
        {"id": "ranger", "name": "漫游者", "max_hp": 400, "hp": 400, "pilot_id": "ranger", "is_active": true, "parts_hp": {"head": 100, "chest": 100, "arms": 100, "legs": 100}, "weapon_slots": [&"rifle", &"knife", &"throwable"]},
        {"id": "frostbite", "name": "霜尾", "max_hp": 320, "hp": 320, "pilot_id": "frostbite", "is_active": false, "parts_hp": {"head": 80, "chest": 80, "arms": 80, "legs": 80}, "weapon_slots": [&"greatsword", &"cryo_grenade", &""]},
        {"id": "bomber", "name": "轰天", "max_hp": 480, "hp": 480, "pilot_id": "bomber", "is_active": false, "parts_hp": {"head": 120, "chest": 120, "arms": 120, "legs": 120}, "weapon_slots": [&"rail_cannon", &"grenade_launcher", &"repair_drone"]},
    ]

# === Combat Flow ===

func _active_mech_attack() -> void:
    if _active_mech_index < 0 or _active_mech_index >= _party.size():
        return
    var mech: Dictionary = _party[_active_mech_index]
    if mech.hp <= 0:
        print("[PartyBattleController] %s is down, skipping" % mech.name)
        return

    # S7-001 PR 3: Use BattleMathLib.roll_range() for damage
    # (replaces the PR 1 placeholder randi_range(20, 30)).
    # S7-009 will add the full damage formula (weapon, ammo,
    # weakness, crit) — for now we use a simple min/max roll.
    # This is consistent with the existing 1v1 battle_scene.gd
    # pattern (which also uses BattleMathLib).
    var damage: int = BattleMathLib.roll_range(20, 30)
    damage = BattleMathLib.clamp_damage(damage)
    _enemy.hp = max(0, _enemy.hp - damage)
    print("[PartyBattleController] %s attacks %s for %d" % [mech.name, _enemy.display_name, damage])
    party_member_attacked.emit(mech.id, 0, damage)

    if _enemy.hp <= 0:
        end_party_battle(true)
        return

    _mechs_acted_this_round.append(_active_mech_index)
    if _all_living_mechs_acted():
        _start_enemy_turn()

func _all_living_mechs_acted() -> bool:
    for i in _party.size():
        if _party[i].hp > 0 and i not in _mechs_acted_this_round:
            return false
    return true

func _start_enemy_turn() -> void:
    _party_phase = &"enemy"
    enemy_turn_started.emit()
    print("[PartyBattleController] Round %d: Enemy turn" % _round_number)
    # For Sprint 7 PR 1, the enemy attack is automatic (no async timer)
    _execute_enemy_attack()

func _execute_enemy_attack() -> void:
    # Find the active mech (or first living if active is down)
    var target_index: int = _active_mech_index
    if _party[target_index].hp <= 0:
        for i in _party.size():
            if _party[i].hp > 0:
                target_index = i
                break
    if target_index < 0 or _party[target_index].hp <= 0:
        end_party_battle(false)
        return
    var target: Dictionary = _party[target_index]
    # S7-001 PR 3: Use BattleMathLib for accuracy roll + damage
    var accuracy: float = float(_enemy.get("accuracy", 0.85))
    var damage: int = 0
    if BattleMathLib.roll_accuracy(accuracy):
        damage = BattleMathLib.roll_range(
            int(_enemy.get("attack", 10)) - 2,
            int(_enemy.get("attack", 10)) + 2
        )
        damage = BattleMathLib.clamp_damage(damage)
        target.hp = max(0, target.hp - damage)
        print("[PartyBattleController] Enemy attacks %s for %d (acc=%.2f)" % [target.name, damage, accuracy])
    else:
        print("[PartyBattleController] Enemy missed %s (acc=%.2f)" % [target.name, accuracy])
    enemy_attacked.emit(target_index, damage)
    if target.hp <= 0:
        party_member_knocked_out.emit(target.id)
        print("[PartyBattleController] %s knocked out" % target.name)

    # End round
    _round_number += 1
    _mechs_acted_this_round = []
    _party_phase = &"player"
    # Switch to next living mech as the default active
    for i in _party.size():
        if _party[i].hp > 0:
            _active_mech_index = i
            active_mech_changed.emit(i)
            break

# === Input (1/2/3 keys for switching active mech) ===

func _unhandled_input(event: InputEvent) -> void:
    if not _in_battle or _party_phase != &"player":
        return
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_1:
                _set_active_mech(0)
            KEY_2:
                _set_active_mech(1)
            KEY_3:
                _set_active_mech(2)
            KEY_SPACE:
                _active_mech_attack()
            KEY_ESCAPE:
                end_party_battle(false)

func _set_active_mech(index: int) -> void:
    if index < 0 or index >= _party.size():
        return
    if _party[index].hp <= 0:
        print("[PartyBattleController] Cannot switch to %s (knocked out)" % _party[index].name)
        return
    _active_mech_index = index
    active_mech_changed.emit(index)
    print("[PartyBattleController] Active mech: %s" % _party[index].name)

# === Debug ===

func debug_start_test_battle() -> void:
    # Public test entry point. For Sprint 7 testing without a real enemy encounter.
    start_party_battle(&"scavenger")
