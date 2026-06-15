extends Node

# WeaponLoadout (per player-input.md + weapon-ammo.md)
# Tracks the player's current 3 weapon slots + 3 ammo slots.
# Per battle-core-loop.md manual mode: 1/2/3 keys immediately attack with that slot.

signal weapon_changed(slot_index: int, weapon_id: StringName)
signal ammo_changed(slot_index: int, ammo_id: StringName)
signal attack_triggered(slot_index: int)  # per player-input.md: 1/2/3 = select + attack

const SLOT_COUNT: int = 3

# weapon_slots[i] = WeaponData resource id, or &"" if empty
var weapon_slots: Array[StringName] = [&"", &"", &""]
# ammo_slots[i] = AmmoData resource id, or &"" if empty
var ammo_slots: Array[StringName] = [&"", &"", &""]
# active weapon slot index (0/1/2) — manual mode focus
var active_slot: int = 0

func _ready() -> void:
	if get_node_or_null("/root/GameStateMachine") == null:
		push_error("WeaponLoadout: GameStateMachine must load first")

	# Default loadout for FC-1: slot 0 = blaster_rifle
	weapon_slots[0] = &"blaster_rifle"
	print("[WeaponLoadout] ready, default loadout: blaster_rifle")

	# Per player-input.md AC-3: 1/2/3 = select + attack immediately.
	# Wire to InputBus.action_pressed (ADR-0009 + ADR-0002).
	var input_bus: Node = get_node_or_null("/root/InputBus")
	if input_bus != null:
		input_bus.action_pressed.connect(_on_action_pressed)

func _on_action_pressed(action: StringName) -> void:
	print("[WeaponLoadout] _on_action_pressed action=", action)
	# Per player-input.md: 1/2/3 in EXPLORATION = select slot + attack (if weapon
	# equipped). The "attack" in exploration triggers for environment
	# interactions (e.g., breakable walls in room 4 — S4-008). Subscribers
	# (breakable_wall, etc.) check proximity and decide if the attack counts.
	# In BATTLE, attack always triggers (per UX feedback: no spacebar confirm).
	var sm: Node = get_node("/root/GameStateMachine")
	var in_battle: bool = sm.top_of_stack == &"state_battle"
	match action:
		&"battle_attack_slot1":
			if in_battle:
				trigger_attack(0)
			else:
				select_slot(0)
				if weapon_slots[0] != &"":
					attack_triggered.emit(0)
		&"battle_attack_slot2":
			if in_battle:
				trigger_attack(1)
			else:
				select_slot(1)
				if weapon_slots[1] != &"":
					attack_triggered.emit(1)
		&"battle_attack_slot3":
			if in_battle:
				trigger_attack(2)
			else:
				select_slot(2)
				if weapon_slots[2] != &"":
					attack_triggered.emit(2)
		&"toggle_mode":
			# S4-007: M key toggles AUTO/MANUAL. Always works (even out of
			# battle) so player can pre-set mode before next encounter.
			toggle_mode()

func equip_weapon(slot: int, weapon_id: StringName) -> void:
	if slot < 0 or slot >= SLOT_COUNT:
		push_error("WeaponLoadout: invalid slot %d" % slot)
		return
	weapon_slots[slot] = weapon_id
	weapon_changed.emit(slot, weapon_id)

func equip_ammo(slot: int, ammo_id: StringName) -> void:
	if slot < 0 or slot >= SLOT_COUNT:
		push_error("WeaponLoadout: invalid slot %d" % slot)
		return
	ammo_slots[slot] = ammo_id
	ammo_changed.emit(slot, ammo_id)

func select_slot(slot: int) -> void:
	if slot < 0 or slot >= SLOT_COUNT:
		return
	active_slot = slot
	# Emit so HUD can update active-slot highlight
	weapon_changed.emit(slot, weapon_slots[slot])

func get_active_weapon() -> Resource:
	if weapon_slots[active_slot] == &"":
		return null
	return get_node("/root/ResourceRegistry").get_resource(weapon_slots[active_slot])

func get_active_ammo() -> Resource:
	if ammo_slots[active_slot] == &"":
		return null
	return get_node("/root/ResourceRegistry").get_resource(ammo_slots[active_slot])

# Per player-input.md AC-3: 1/2/3 select slot AND trigger attack immediately
# (per your explicit UX feedback: no spacebar confirm)
func trigger_attack(slot: int) -> void:
	if slot < 0 or slot >= SLOT_COUNT:
		return
	select_slot(slot)
	if weapon_slots[slot] == &"":
		return  # empty slot — no attack
	attack_triggered.emit(slot)

func get_state_snapshot() -> Dictionary:
	return {
		"schema_version": 1,
		"weapon_slots": weapon_slots.duplicate(),
		"ammo_slots": ammo_slots.duplicate(),
		"active_slot": active_slot,
	}

func load_snapshot(snap: Dictionary) -> Error:
	if not snap.has("weapon_slots"):
		return OK
	var ws: Array = snap["weapon_slots"]
	for i in range(min(ws.size(), SLOT_COUNT)):
		weapon_slots[i] = StringName(ws[i])
	if snap.has("ammo_slots"):
		var as_: Array = snap["ammo_slots"]
		for i in range(min(as_.size(), SLOT_COUNT)):
			ammo_slots[i] = StringName(as_[i])
	if snap.has("active_slot"):
		active_slot = int(snap["active_slot"])
	return OK

# --- S4-007: AUTO mode AI ---
# Manual mode: 1/2/3 keys directly trigger attack (existing behavior).
# AUTO mode: a SceneTreeTimer ticks every AUTO_INTERVAL_SEC and triggers
# an AI-picked slot (highest max_damage). M key toggles between modes.
# AI policy: pick the non-empty slot with highest max_damage. Ties broken
# by min_damage (higher floor = safer on rolls). 0 valid slots = skip tick.

signal mode_changed(new_mode: StringName)  # &"MANUAL" or &"AUTO"

const AUTO_INTERVAL_SEC: float = 1.2

var _auto_mode: bool = false
var _auto_timer: SceneTreeTimer = null

func toggle_mode() -> StringName:
	set_auto_mode(not _auto_mode)
	return &"AUTO" if _auto_mode else &"MANUAL"

func set_auto_mode(enabled: bool) -> void:
	if _auto_mode == enabled:
		return
	_auto_mode = enabled
	if _auto_mode:
		_start_auto_timer()
	else:
		_stop_auto_timer()
	mode_changed.emit(&"AUTO" if _auto_mode else &"MANUAL")

func is_auto_mode() -> bool:
	return _auto_mode

func _start_auto_timer() -> void:
	_stop_auto_timer()  # ensure no double timer
	_auto_timer = get_tree().create_timer(AUTO_INTERVAL_SEC)
	_auto_timer.timeout.connect(_on_auto_tick, CONNECT_ONE_SHOT)

func _stop_auto_timer() -> void:
	if _auto_timer != null and is_instance_valid(_auto_timer):
		_auto_timer.timeout.disconnect(_on_auto_tick) if _auto_timer.timeout.is_connected(_on_auto_tick) else null
	_auto_timer = null

func _on_auto_tick() -> void:
	# Only fire in battle (matches manual mode's 1/2/3 behavior).
	var sm: Node = get_node_or_null("/root/GameStateMachine")
	if sm == null or sm.top_of_stack != &"state_battle":
		# Re-arm for when battle starts
		if _auto_mode:
			_start_auto_timer()
		return
	var picked: int = _ai_pick_slot()
	if picked >= 0:
		trigger_attack(picked)
	# Re-arm
	if _auto_mode:
		_start_auto_timer()

# AI policy: highest max_damage, tiebreak by highest min_damage.
# Returns -1 if no non-empty slot.
func _ai_pick_slot() -> int:
	var reg: Node = get_node("/root/ResourceRegistry")
	var best_slot: int = -1
	var best_max: int = -1
	var best_min: int = -1
	for i in SLOT_COUNT:
		var wid: StringName = weapon_slots[i]
		if wid == &"":
			continue
		var w: Resource = reg.get_resource(wid)
		if w == null:
			continue
		var mx: int = int(w.get("max_damage"))
		var mn: int = int(w.get("min_damage"))
		if mx > best_max or (mx == best_max and mn > best_min):
			best_slot = i
			best_max = mx
			best_min = mn
	return best_slot
