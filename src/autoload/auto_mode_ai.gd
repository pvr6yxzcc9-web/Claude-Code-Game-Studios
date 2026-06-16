extends Node

# AutoModeAI (S7-011) — 3-pilot AI for combat auto mode.
# Per party-system.md §3.7 + sprint-07-011 plan
# Pilot-specific behaviors:
#   ranger: balanced, prefer high-damage weapons
#   frostbite: prefer flanking (target weakest enemy)
#   bomber: prefer AOE (multi-target)
# AI difficulty: "good but not optimal" (gives Manual a 10-20% advantage)

const AUTO_INTERVAL_SEC: float = 1.2
const PILOT_ROSTER: Array[StringName] = [&"ranger", &"frostbite", &"bomber"]
const DEFAULT_TARGET: StringName = &"enemy_1"

# AI state
var _auto_mode: bool = false
var _current_pilot_index: int = 0
var _timer: SceneTreeTimer = null
var _enemy_targets: Array[StringName] = []  # populated by BattleState

# Signals
signal auto_action_executed(pilot_id: StringName, weapon_slot: int, target_id: StringName)
signal auto_turn_complete(pilot_id: StringName)
signal auto_round_complete()
signal auto_mode_changed(enabled: bool)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[AutoModeAI] ready")

func start_auto_mode() -> void:
	if _auto_mode:
		return
	_auto_mode = true
	_current_pilot_index = 0
	auto_mode_changed.emit(true)
	_run_next_action()

func stop_auto_mode() -> void:
	if not _auto_mode:
		return
	_auto_mode = false
	if _timer != null and is_instance_valid(_timer):
		if _timer.timeout.is_connected(_run_next_action):
			_timer.timeout.disconnect(_run_next_action)
	auto_mode_changed.emit(false)

func is_auto_mode() -> bool:
	return _auto_mode

# Set enemy targets (called by BattleState at start of combat)
func set_enemy_targets(targets: Array[StringName]) -> void:
	_enemy_targets = targets.duplicate()

# === AI logic ===

func _run_next_action() -> void:
	if not _auto_mode:
		return
	# Skip knocked-out pilots
	while _current_pilot_index < PILOT_ROSTER.size():
		var pilot_id: StringName = PILOT_ROSTER[_current_pilot_index]
		var cm: Node = get_node_or_null("/root/ClinicManager")
		if cm != null and cm.is_knocked_out(pilot_id):
			_current_pilot_index += 1
			continue
		# Execute action for this pilot
		_execute_ai_action(pilot_id)
		_current_pilot_index += 1
		# Schedule next action
		_timer = get_tree().create_timer(AUTO_INTERVAL_SEC)
		_timer.timeout.connect(_run_next_action, CONNECT_ONE_SHOT)
		return
	# All pilots acted → round complete
	auto_round_complete.emit()
	_current_pilot_index = 0
	# If still in auto mode, start next round after a delay
	if _auto_mode:
		_timer = get_tree().create_timer(AUTO_INTERVAL_SEC * 2)
		_timer.timeout.connect(_run_next_action, CONNECT_ONE_SHOT)

func _execute_ai_action(pilot_id: StringName) -> void:
	var target: StringName = _pick_target(pilot_id)
	var weapon_slot: int = _pick_weapon_slot(pilot_id, target)
	auto_action_executed.emit(pilot_id, weapon_slot, target)
	auto_turn_complete.emit(pilot_id)

func _pick_target(pilot_id: StringName) -> StringName:
	# If no enemy targets known, fall back to default
	if _enemy_targets.is_empty():
		return DEFAULT_TARGET
	match pilot_id:
		&"frostbite":
			# Frostbite prefers the weakest enemy (target index 0 in our
			# simple "sorted by HP" heuristic — actual sorting is in
			# BattleState. For now, just pick the last one in the list
			# which often corresponds to "lowest HP left after earlier
			# attacks").
			return _enemy_targets[_enemy_targets.size() - 1]
		&"bomber":
			# Bomber prefers AOE — the attack picks all targets, but
			# we still return one as the "primary target" for the
			# signal payload.
			return _enemy_targets[0]
		_:
			# Ranger + default: pick first available
			return _enemy_targets[0]

func _pick_weapon_slot(pilot_id: StringName, _target: StringName) -> int:
	# Pilot-specific weapon preferences
	var wl: Node = get_node_or_null("/root/WeaponLoadout")
	if wl == null:
		return 0
	var loadout: Resource = wl.get_active_mech_loadout()
	if loadout == null:
		return 0
	match pilot_id:
		&"ranger":
			# Prefer highest max_damage weapon
			return _slot_with_highest_damage(loadout)
		&"frostbite":
			# Prefer weapons with AOE / multi-hit (heuristic: highest slot)
			return _slot_with_highest_damage(loadout)
		&"bomber":
			# Prefer slot 0 (typically AOE in our mechs)
			if loadout.weapon_slots.size() > 0:
				return 0
			return 0
		_:
			return 0

func _slot_with_highest_damage(loadout: Resource) -> int:
	var reg: Node = get_node_or_null("/root/ResourceRegistry")
	if reg == null or loadout == null:
		return 0
	var best_slot: int = -1
	var best_max: int = -1
	for i in loadout.weapon_slots.size():
		var wid: StringName = StringName(loadout.weapon_slots[i])
		if wid == &"":
			continue
		var w: Resource = reg.get_resource(wid)
		if w == null:
			continue
		var mx: int = int(w.get("max_damage"))
		if mx > best_max:
			best_slot = i
			best_max = mx
	return best_slot if best_slot >= 0 else 0

# === Toggle for input handler integration ===

func toggle_auto_mode() -> bool:
	if _auto_mode:
		stop_auto_mode()
	else:
		start_auto_mode()
	return _auto_mode