extends Node

# WeaponLoadout (per player-input.md + weapon-ammo.md + party-system.md §3.4)
# S7-002: Refactored to per-mech weapon slots. Each mech has its own
# MechCombatLoadout (3-4 weapons, 4 parts HP, special module). Any pilot can
# drive any mech; weapons are mounted on mechs, not pilots.
#
# NOTE: Distinct from the `MechLoadout` autoload (src/autoload/mech_loadout.gd),
# which tracks the 5 equipable mech parts. The class here is MechCombatLoadout.
#
# BACKWARD COMPATIBILITY: The old global weapon_slots / ammo_slots /
# active_slot still exist. They are now a *legacy* view that delegates
# to the active mech's MechCombatLoadout. Old code (battle_scene.gd) still
# works via the old API.

signal weapon_changed(slot_index: int, weapon_id: StringName)
signal ammo_changed(slot_index: int, ammo_id: StringName)
signal attack_triggered(slot_index: int)  # per player-input.md: 1/2/3 = select + attack
signal mode_changed(new_mode: StringName)  # &"MANUAL" or &"AUTO"
signal mech_loadout_registered(mech_id: StringName)
signal active_mech_changed(mech_id: StringName)

const SLOT_COUNT: int = 3

# === Per-mech data (S7-002 new) ===

# mech_id (StringName) → MechCombatLoadout
var _mech_loadouts: Dictionary = {}

# Active mech (defaults to "ranger" for legacy compat)
var _active_mech_id: StringName = &"ranger"

# === Legacy global slots (deprecated but kept for backward compat) ===
# These are now a VIEW onto the active mech's slots. New code should
# use the per-mech API (get_active_mech_loadout, etc.).

var weapon_slots: Array[StringName] = [&"", &"", &""]
var ammo_slots: Array[StringName] = [&"", &"", &""]
var active_slot: int = 0

# === Lifecycle ===

func _ready() -> void:
	if get_node_or_null("/root/GameStateMachine") == null:
		push_error("WeaponLoadout: GameStateMachine must load first")

	# Default loadout for FC-1: slot 0 = blaster_rifle (legacy)
	weapon_slots[0] = &"blaster_rifle"

	# S7-002 + S7-003: Register the 3 default mechs with starter loadouts.
	# Mech IDs match the MechLoadout roster (ranger_mech / frostbite_mech /
	# bomber_mech). 苍穹号 (cangqiong_mech) is registered with its 4 slots
	# but the player can't equip it until Ch13 inheritance.
	register_mech(&"ranger_mech", 3, [&"blaster_rifle", &"", &""], [&"basic_cell", &"", &""])
	register_mech(&"frostbite_mech", 3, [&"rifle", &"knife", &"throwable"], [&"basic_cell", &"", &""])
	register_mech(&"bomber_mech", 3, [&"rail_cannon", &"grenade_launcher", &"repair_drone"], [&"heavy_round", &"", &""])
	register_mech(&"cangqiong_mech", 4, [&"plasma_cannon", &"laser_lance", &"missile_pod", &"emp_blaster"], [&"plasma_cell", &"energy_cell", &"missile", &"emp_charge"])

	# S7-002: Set ranger_mech as the active mech (legacy compat)
	set_active_mech(&"ranger_mech")

	print("[WeaponLoadout] ready (S7-002 — per-mech loadouts)")

	# Per player-input.md AC-3: 1/2/3 = select + attack immediately.
	var input_bus: Node = get_node_or_null("/root/InputBus")
	if input_bus != null:
		input_bus.action_pressed.connect(_on_action_pressed)

# === Per-mech API (S7-002 new) ===

func register_mech(mech_id: StringName, max_weapon_slots: int = 3,
		weapon_slot_ids: Array = [], ammo_slot_ids: Array = []) -> void:
	# Idempotent: if mech already registered, don't overwrite.
	if _mech_loadouts.has(mech_id):
		return
	var loadout: MechCombatLoadout = MechCombatLoadout.new()
	loadout.max_weapon_slots = max_weapon_slots
	# Resize weapon_slots / ammo_slots to match max
	if weapon_slot_ids.size() >= max_weapon_slots:
		for i in max_weapon_slots:
			loadout.weapon_slots[i] = StringName(weapon_slot_ids[i])
	if ammo_slot_ids.size() >= max_weapon_slots:
		for i in max_weapon_slots:
			loadout.ammo_slots[i] = StringName(ammo_slot_ids[i])
	_mech_loadouts[mech_id] = loadout
	mech_loadout_registered.emit(mech_id)

func get_mech_loadout(mech_id: StringName) -> MechCombatLoadout:
	return _mech_loadouts.get(mech_id, null)

func get_active_mech_loadout() -> MechCombatLoadout:
	return _mech_loadouts.get(_active_mech_id, null)

func set_active_mech(mech_id: StringName) -> void:
	if not _mech_loadouts.has(mech_id):
		push_warning("WeaponLoadout: cannot set active to unregistered mech %s" % mech_id)
		return
	_active_mech_id = mech_id
	# Sync the legacy global view to the new active mech
	_sync_legacy_view_from_active()
	active_mech_changed.emit(mech_id)
	# Emit slot 0 weapon change so HUD can refresh
	weapon_changed.emit(0, weapon_slots[0])

func equip_weapon_to_mech(mech_id: StringName, slot: int, weapon_id: StringName) -> void:
	var loadout: MechCombatLoadout = get_mech_loadout(mech_id)
	if loadout == null:
		push_warning("WeaponLoadout: equip_weapon_to_mech: unknown mech %s" % mech_id)
		return
	if slot < 0 or slot >= loadout.max_weapon_slots:
		push_warning("WeaponLoadout: invalid slot %d for mech %s" % [slot, mech_id])
		return
	loadout.weapon_slots[slot] = weapon_id
	# If this is the active mech, update legacy view
	if mech_id == _active_mech_id:
		_sync_legacy_view_from_active()
	weapon_changed.emit(slot, weapon_id)

func equip_ammo_to_mech(mech_id: StringName, slot: int, ammo_id: StringName) -> void:
	var loadout: MechCombatLoadout = get_mech_loadout(mech_id)
	if loadout == null:
		return
	if slot < 0 or slot >= loadout.max_weapon_slots:
		return
	loadout.ammo_slots[slot] = ammo_id
	if mech_id == _active_mech_id:
		_sync_legacy_view_from_active()
	ammo_changed.emit(slot, ammo_id)

func get_active_mech_id() -> StringName:
	return _active_mech_id

func get_all_mech_loadouts() -> Dictionary:
	return _mech_loadouts.duplicate()

# === Legacy API (backward compat for battle_scene.gd + 1v1 path) ===

# These methods now delegate to the active mech's MechCombatLoadout.
# Existing callers (battle_scene.gd, etc.) still work.

func equip_weapon(slot: int, weapon_id: StringName) -> void:
	# Legacy: equip to active mech
	equip_weapon_to_mech(_active_mech_id, slot, weapon_id)

func equip_ammo(slot: int, ammo_id: StringName) -> void:
	equip_ammo_to_mech(_active_mech_id, slot, ammo_id)

func select_slot(slot: int) -> void:
	active_slot = slot
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
func trigger_attack(slot: int) -> void:
	if slot < 0 or slot >= SLOT_COUNT:
		return
	select_slot(slot)
	if weapon_slots[slot] == &"":
		return  # empty slot — no attack
	attack_triggered.emit(slot)

# === Internal: sync legacy global view from active mech ===

func _sync_legacy_view_from_active() -> void:
	var loadout: MechCombatLoadout = get_active_mech_loadout()
	if loadout == null:
		return
	# Copy per-mech data into the legacy global arrays
	weapon_slots = loadout.weapon_slots.duplicate()
	ammo_slots = loadout.ammo_slots.duplicate()
	active_slot = loadout.active_slot

# === Input (1/2/3 keys) — unchanged ===

func _on_action_pressed(action: StringName) -> void:
	# Per player-input.md: 1/2/3 in EXPLORATION = select slot + attack.
	# In BATTLE, attack always triggers.
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
			toggle_mode()

# === Save/Load (upgraded to v2 for S7-002) ===

# Bump save version (existing 1 → 2 with per-mech data)
const SCHEMA_VERSION: int = 2

func get_state_snapshot() -> Dictionary:
	# v2 format: { schema_version, active_mech_id, mechs: {id: loadout_dict} }
	var mechs_data: Dictionary = {}
	for mech_id in _mech_loadouts:
		var loadout: MechCombatLoadout = _mech_loadouts[mech_id]
		mechs_data[String(mech_id)] = {
			"weapon_slots": loadout.weapon_slots.duplicate(),
			"ammo_slots": loadout.ammo_slots.duplicate(),
			"active_slot": loadout.active_slot,
			"head_hp": loadout.head_hp,
			"chest_hp": loadout.chest_hp,
			"arms_hp": loadout.arms_hp,
			"legs_hp": loadout.legs_hp,
			"max_head_hp": loadout.max_head_hp,
			"max_chest_hp": loadout.max_chest_hp,
			"max_arms_hp": loadout.max_arms_hp,
			"max_legs_hp": loadout.max_legs_hp,
			"module_ids": loadout.module_ids.duplicate(),
			"max_weapon_slots": loadout.max_weapon_slots,
		}
	return {
		"schema_version": SCHEMA_VERSION,
		"active_mech_id": _active_mech_id,
		"mechs": mechs_data,
	}

func load_snapshot(snap: Dictionary) -> Error:
	# Support v1 (legacy) and v2 (per-mech) snapshots.
	var version: int = int(snap.get("schema_version", 1))
	if version == 1:
		# Legacy: just load the global slots
		if snap.has("weapon_slots"):
			var ws: Array = snap["weapon_slots"]
			for i in range(min(ws.size(), SLOT_COUNT)):
				weapon_slots[i] = StringName(ws[i])
		if snap.has("ammo_slots"):
			var as_: Array = snap["ammo_slots"]
			for i in range(min(as_.size(), SLOT_COUNT)):
				ammo_slots[i] = StringName(as_[i])
		if snap.has("active_slot"):
			active_slot = int(snap["active_slot"])
		# Migrate to v2: load the legacy global into the active mech
		var loadout: MechCombatLoadout = get_active_mech_loadout()
		if loadout != null:
			loadout.weapon_slots = weapon_slots.duplicate()
			loadout.ammo_slots = ammo_slots.duplicate()
			loadout.active_slot = active_slot
		return OK
	# v2: per-mech
	if snap.has("active_mech_id"):
		_active_mech_id = StringName(snap["active_mech_id"])
	if snap.has("mechs"):
		var mechs_data: Dictionary = snap["mechs"]
		for mech_id in mechs_data:
			var md: Dictionary = mechs_data[mech_id]
			var loadout: MechCombatLoadout = get_mech_loadout(StringName(mech_id))
			if loadout == null:
				# Auto-register if not present
				register_mech(StringName(mech_id))
				loadout = get_mech_loadout(StringName(mech_id))
			if loadout == null:
				continue
			if md.has("weapon_slots"):
				var ws2: Array = md["weapon_slots"]
				for i in range(min(ws2.size(), loadout.max_weapon_slots)):
					loadout.weapon_slots[i] = StringName(ws2[i])
			if md.has("ammo_slots"):
				var as2: Array = md["ammo_slots"]
				for i in range(min(as2.size(), loadout.max_weapon_slots)):
					loadout.ammo_slots[i] = StringName(as2[i])
			if md.has("active_slot"):
				loadout.active_slot = int(md["active_slot"])
			if md.has("head_hp"):
				loadout.head_hp = int(md["head_hp"])
			if md.has("chest_hp"):
				loadout.chest_hp = int(md["chest_hp"])
			if md.has("arms_hp"):
				loadout.arms_hp = int(md["arms_hp"])
			if md.has("legs_hp"):
				loadout.legs_hp = int(md["legs_hp"])
			if md.has("module_ids"):
				var mods: Array = md["module_ids"]
				loadout.module_ids.clear()
				for m in mods:
					loadout.module_ids.append(StringName(m))
	# Sync legacy view to active mech
	_sync_legacy_view_from_active()
	return OK

# === AUTO mode (S4-007 — unchanged behavior) ===

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
	_stop_auto_timer()
	_auto_timer = get_tree().create_timer(AUTO_INTERVAL_SEC)
	_auto_timer.timeout.connect(_on_auto_tick, CONNECT_ONE_SHOT)

func _stop_auto_timer() -> void:
	if _auto_timer != null and is_instance_valid(_auto_timer):
		if _auto_timer.timeout.is_connected(_on_auto_tick):
			_auto_timer.timeout.disconnect(_on_auto_tick)
	_auto_timer = null

func _on_auto_tick() -> void:
	var sm: Node = get_node_or_null("/root/GameStateMachine")
	if sm == null or sm.top_of_stack != &"state_battle":
		if _auto_mode:
			_start_auto_timer()
		return
	var picked: int = _ai_pick_slot()
	if picked >= 0:
		trigger_attack(picked)
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



}
