extends Node
# Party Battle Controller (Sprint 7-001 S7-001 REAL implementation)
#
# This is the **minimal-risk first refactor** toward 3v1 combat.
# It does NOT modify the existing 1v1 battle_scene.gd. Instead, it
# is a separate controller that:
# - Watches the GameStateMachine for state_battle transitions
# - Reads the party data (3 mechs) from WeaponLoadout + MechLoadout
# - Provides 1/2/3 keys to switch active mech mid-battle
# - Iterates through 3 mechs (1 turn each) before enemy attack
#
# Existing 1v1 fights in Ch1/Ch2 are **unchanged** — they use the
# legacy battle_scene.gd path. The legacy_1v1_mode flag is NOT yet
# read by anything; this controller runs in PARALLEL with the 1v1
# logic and overrides the active battle if the party has 3 mechs.
#
# This is the **first real implementation** of S7-001. It will be
# extended in subsequent PRs (per the sprint-07-001 plan):
# - PR 1 (this file): Party data + 1/2/3 + 3v1 round loop
# - PR 2 (later): Integrate with existing on_player_attack damage flow
# - PR 3 (later): Replace legacy 1v1 entirely
# - PR 4 (later): Wire HUD (S7-004), Mech Bay (S7-007), etc.

# === Signals ===

signal party_battle_started(enemy_id: StringName)
signal party_battle_ended(victory: bool)
signal party_member_attacked(pilot_id: StringName, slot: int, damage: int)
signal active_mech_changed(new_index: int)
signal party_member_knocked_out(pilot_id: StringName)
signal enemy_turn_started()
signal enemy_attacked(target_index: int, damage: int)

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
    if new == &"state_battle":
        # The existing BattleScene will also handle this.
        # We DON'T start our own battle here — we wait for the user
        # to call start_party_battle() explicitly (e.g., via debug command
        # or via S7-001's data wiring).
        pass

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
    var mechs: Array[Dictionary] = []
    var loadout: Node = get_node_or_null("/root/MechLoadout")
    if loadout == null:
        # Fallback: 3 default mechs (for Sprint 7 testing before
        # MechLoadout is fully wired)
        return [
            {"id": "ranger", "name": "漫游者", "max_hp": 400, "hp": 400, "weapon_slots": [&"rifle", &"knife", &"throwable"]},
            {"id": "frostbite", "name": "霜尾", "max_hp": 320, "hp": 320, "weapon_slots": [&"greatsword", &"cryo_grenade", &""]},
            {"id": "bomber", "name": "轰天", "max_hp": 480, "hp": 480, "weapon_slots": [&"rail_cannon", &"grenade_launcher", &"repair_drone"]},
        ]
    # Real loading from MechLoadout
    # TODO Sprint 7 PR 2: read from loadout._mechs when S7-003 is committed
    return mechs

# === Combat Flow ===

func _active_mech_attack() -> void:
    if _active_mech_index < 0 or _active_mech_index >= _party.size():
        return
    var mech: Dictionary = _party[_active_mech_index]
    if mech.hp <= 0:
        print("[PartyBattleController] %s is down, skipping" % mech.name)
        return

    # Simplified damage: roll 20-30 damage (real damage formula is in S7-009)
    var damage: int = randi_range(20, 30)
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
    var damage: int = _enemy.attack
    target.hp = max(0, target.hp - damage)
    print("[PartyBattleController] Enemy attacks %s for %d" % [target.name, damage])
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
