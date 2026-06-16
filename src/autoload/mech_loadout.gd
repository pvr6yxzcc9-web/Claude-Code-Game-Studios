extends Node

# MechLoadout (S7-003) — roster of 4 mechs (漫游者号 / 霜尾号 / 轰天号 / 苍穹号).
# Each mech has a MechCombatLoadout (identity + weapons + parts HP + stats + modules).
# Holds an active-mech pointer; provides aggregate-stats API for the legacy
# equip-parts system (kept for backward compat with S6-018 sprite preview).
#
# Per party-system.md §3.4 + sprint-07-003-implementation-plan.

signal mech_registered(mech_id: StringName)
signal active_mech_changed(mech_id: StringName)
signal part_equipped(slot: StringName, part_id: StringName)  # legacy, delegates to active mech
signal part_unequipped(slot: StringName)  # legacy
signal cangqiong_unlocked(mech_id: StringName)  # fired when unlock_cangqiong() runs

# === Roster (S7-003) ===

# mech_id (StringName) → MechCombatLoadout
var _mechs: Dictionary = {}

# Active mech (defaults to ranger_mech)
var _active_mech_id: StringName = &"ranger_mech"

# 4-mech roster — 苍穹号 is locked until Ch13 inheritance
const ROSTER: Array[StringName] = [
	&"ranger_mech",
	&"frostbite_mech",
	&"bomber_mech",
	&"cangqiong_mech",
]

# Default pilot → mech mapping (per party-system.md §3.4)
const DEFAULT_PILOT_MAPPING: Dictionary = {
	&"ranger": &"ranger_mech",
	&"frostbite": &"frostbite_mech",
	&"bomber": &"bomber_mech",
	# 苍穹号 has no default pilot — it inherits from the dead pilot
}

# Legacy 5-slot model (kept for backward compat with S6-018 sprite preview)
# Each slot holds a part_id (StringName)
const LEGACY_SLOTS: Array[StringName] = [&"torso", &"left_arm", &"right_arm", &"legs", &"core"]
var parts: Dictionary[StringName, StringName] = {}

# === Lifecycle ===

func _ready() -> void:
	if get_node_or_null("/root/GameStateMachine") == null:
		push_error("MechLoadout: GameStateMachine must load first")

	# Legacy slots — initialize as empty
	for s in LEGACY_SLOTS:
		parts[s] = &""

	# Register the 3 default mechs (S7-003)
	_register_default_mech(&"ranger_mech", "漫游者号", &"infantry", 3, 100,
			[&"head", &"chest", &"arms", &"legs"])
	_register_default_mech(&"frostbite_mech", "霜尾号", &"cavalry", 3, 100,
			[&"head", &"chest", &"arms", &"legs"])
	_register_default_mech(&"bomber_mech", "轰天号", &"artillery", 3, 100,
			[&"head", &"chest", &"arms", &"legs"])

	# 苍穹号 is registered but locked (unlock via Ch13 inheritance)
	_register_default_mech(&"cangqiong_mech", "苍穹号", &"legendary", 4, 150,
			[&"head", &"chest", &"arms", &"legs"])
	_mechs[&"cangqiong_mech"].unlocked = false
	_mechs[&"cangqiong_mech"].module_ids = [&"", &""]  # 2 module slots

	# Set ranger_mech as active by default
	_active_mech_id = &"ranger_mech"

	print("[MechLoadout] ready, %d mechs in roster (1 locked: 苍穹号)" % _mechs.size())

# Internal: register a mech with default stats
func _register_default_mech(mech_id: StringName, display_name: String,
		class_type: StringName, max_weapon_slots: int, base_hp: int,
		_part_names: Array[StringName]) -> MechCombatLoadout:
	if _mechs.has(mech_id):
		return _mechs[mech_id]
	var loadout: MechCombatLoadout = MechCombatLoadout.new()
	loadout.mech_id = mech_id
	loadout.display_name = display_name
	loadout.class_type = class_type
	loadout.max_weapon_slots = max_weapon_slots
	loadout.weapon_slots = []
	loadout.ammo_slots = []
	for i in max_weapon_slots:
		loadout.weapon_slots.append(&"")
		loadout.ammo_slots.append(&"")
	loadout.head_hp = base_hp
	loadout.chest_hp = base_hp
	loadout.arms_hp = base_hp
	loadout.legs_hp = base_hp
	loadout.max_head_hp = base_hp
	loadout.max_chest_hp = base_hp
	loadout.max_arms_hp = base_hp
	loadout.max_legs_hp = base_hp
	loadout.module_ids = [&""]
	# S7-007: assign default pilot from DEFAULT_PILOT_MAPPING
	for pilot_id in DEFAULT_PILOT_MAPPING:
		if DEFAULT_PILOT_MAPPING[pilot_id] == mech_id:
			loadout.pilot_id = pilot_id
			break
	# Class-specific stats
	match class_type:
		&"infantry":
			loadout.mobility = 4
			loadout.armor = 3
			loadout.firepower = 3
		&"cavalry":
			loadout.mobility = 5
			loadout.armor = 2
			loadout.firepower = 3
		&"artillery":
			loadout.mobility = 2
			loadout.armor = 3
			loadout.firepower = 5
		&"legendary":
			loadout.mobility = 5
			loadout.armor = 5
			loadout.firepower = 5
	_mechs[mech_id] = loadout
	mech_registered.emit(mech_id)
	return loadout

# === Public API (S7-003) ===

# Get a mech's loadout. Returns null if not registered.
func get_mech(mech_id: StringName) -> MechCombatLoadout:
	return _mechs.get(mech_id, null)

# Get the active mech's loadout.
func get_active_mech() -> MechCombatLoadout:
	return _mechs.get(_active_mech_id, null)

# Get the active mech's ID.
func get_active_mech_id() -> StringName:
	return _active_mech_id

# Switch active mech. No-op if not registered, or if locked, or invalid.
func set_active_mech(mech_id: StringName) -> void:
	if not _mechs.has(mech_id):
		push_warning("MechLoadout: cannot set active to unregistered mech %s" % mech_id)
		return
	var mech: MechCombatLoadout = _mechs[mech_id]
	if not mech.unlocked:
		push_warning("MechLoadout: cannot set active to locked mech %s" % mech_id)
		return
	_active_mech_id = mech_id
	active_mech_changed.emit(mech_id)

# Get all registered mechs (includes locked 苍穹号).
func get_all_mechs() -> Dictionary:
	return _mechs.duplicate()

# Get only unlocked mechs (for combat / Mech Bay UI).
func get_unlocked_mechs() -> Array[MechCombatLoadout]:
	var out: Array[MechCombatLoadout] = []
	for id in _mechs:
		var mech: MechCombatLoadout = _mechs[id]
		if mech.unlocked:
			out.append(mech)
	return out

# Unlock 苍穹号 (called from S7-008 inheritance cutscene).
func unlock_cangqiong() -> void:
	var cangqiong: MechCombatLoadout = _mechs.get(&"cangqiong_mech", null)
	if cangqiong == null:
		push_warning("MechLoadout: cangqiong_mech not registered")
		return
	if cangqiong.unlocked:
		return  # already unlocked — idempotent
	cangqiong.unlocked = true
	cangqiong_unlocked.emit(&"cangqiong_mech")
	print("[MechLoadout] 苍穹号 unlocked")

# Check if a mech is unlocked.
func is_unlocked(mech_id: StringName) -> bool:
	var mech: MechCombatLoadout = _mechs.get(mech_id, null)
	if mech == null:
		return false
	return mech.unlocked

# Get the mech that a given pilot is currently assigned to.
# Iterates _mechs to find the one with matching pilot_id (S7-007: pilot
# assignment can be changed via Mech Bay, so static mapping is insufficient).
func get_mech_for_pilot(pilot_id: StringName) -> MechCombatLoadout:
	if pilot_id == &"":
		return null
	for mech_id in _mechs:
		var mech: MechCombatLoadout = _mechs[mech_id]
		if mech.pilot_id == pilot_id:
			return mech
	# Fall back to default mapping if no per-mech assignment was found
	# (handles newly-registered mechs whose _register_default_mech set pilot_id)
	var default_mech_id: StringName = DEFAULT_PILOT_MAPPING.get(pilot_id, &"")
	if default_mech_id != &"":
		return _mechs.get(default_mech_id, null)
	return null

# === Parts HP helpers (S7-003) ===

# Damage a part. Returns true if the part just reached 0.
func damage_part(mech_id: StringName, part: StringName, amount: int) -> bool:
	var mech: MechCombatLoadout = _mechs.get(mech_id, null)
	if mech == null:
		return false
	match part:
		&"head":
			mech.head_hp = max(0, mech.head_hp - amount)
			return mech.head_hp == 0
		&"chest":
			mech.chest_hp = max(0, mech.chest_hp - amount)
			return mech.chest_hp == 0
		&"arms":
			mech.arms_hp = max(0, mech.arms_hp - amount)
			return mech.arms_hp == 0
		&"legs":
			mech.legs_hp = max(0, mech.legs_hp - amount)
			return mech.legs_hp == 0
	return false

# Heal a part. Caps at max.
func heal_part(mech_id: StringName, part: StringName, amount: int) -> void:
	var mech: MechCombatLoadout = _mechs.get(mech_id, null)
	if mech == null:
		return
	match part:
		&"head":
			mech.head_hp = min(mech.max_head_hp, mech.head_hp + amount)
		&"chest":
			mech.chest_hp = min(mech.max_chest_hp, mech.chest_hp + amount)
		&"arms":
			mech.arms_hp = min(mech.max_arms_hp, mech.arms_hp + amount)
		&"legs":
			mech.legs_hp = min(mech.max_legs_hp, mech.legs_hp + amount)

# Check if all 4 parts are at 0 (mech is "destroyed").
func is_mech_destroyed(mech_id: StringName) -> bool:
	var mech: MechCombatLoadout = _mechs.get(mech_id, null)
	if mech == null:
		return true
	return mech.head_hp == 0 and mech.chest_hp == 0 and mech.arms_hp == 0 and mech.legs_hp == 0

# === Legacy API (backward compat for S6-018 sprite preview + cycle_equipped_part) ===

func equip_part(slot: StringName, part_id: StringName) -> void:
	# Legacy 5-slot model — kept for S6-018 compat
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

# S4-002: cycle the legacy 5-slot system (kept for HUD).
var _cycle_index: int = 0
func cycle_equipped_part() -> Dictionary:
	var equipped_slots: Array[StringName] = []
	for s in LEGACY_SLOTS:
		if parts[s] != &"":
			equipped_slots.append(s)
	if equipped_slots.is_empty():
		return {"slot": &"", "part_id": &""}
	if equipped_slots.size() == 1:
		var only_slot: StringName = equipped_slots[0]
		return {"slot": only_slot, "part_id": parts[only_slot]}
	_cycle_index = (_cycle_index + 1) % equipped_slots.size()
	var new_slot: StringName = equipped_slots[_cycle_index]
	return {"slot": new_slot, "part_id": parts[new_slot]}

# Aggregate stats from equipped parts (legacy).
# New S7-003 systems should use per-mech stats (loadout.mobility/armor/firepower)
# directly. This legacy API is kept for old callers.
func get_aggregated_stats() -> Dictionary:
	var total_hp: int = 0
	var total_attack: int = 0
	var total_defense: int = 0
	var reg: Node = get_node("/root/ResourceRegistry")
	for slot in LEGACY_SLOTS:
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

# === Save/Load (S7-003 — bump schema to v2) ===

const SCHEMA_VERSION: int = 2

func get_state_snapshot() -> Dictionary:
	# v2: roster of 4 mechs with full per-mech state + legacy parts
	var mechs_data: Dictionary = {}
	for mech_id in _mechs:
		var loadout: MechCombatLoadout = _mechs[mech_id]
		mechs_data[String(mech_id)] = {
			"mech_id": loadout.mech_id,
			"display_name": loadout.display_name,
			"class_type": loadout.class_type,
			"unlocked": loadout.unlocked,
			"pilot_id": loadout.pilot_id,  # S7-007
			"weapon_slots": loadout.weapon_slots.duplicate(),
			"ammo_slots": loadout.ammo_slots.duplicate(),
			"max_weapon_slots": loadout.max_weapon_slots,
			"head_hp": loadout.head_hp,
			"chest_hp": loadout.chest_hp,
			"arms_hp": loadout.arms_hp,
			"legs_hp": loadout.legs_hp,
			"max_head_hp": loadout.max_head_hp,
			"max_chest_hp": loadout.max_chest_hp,
			"max_arms_hp": loadout.max_arms_hp,
			"max_legs_hp": loadout.max_legs_hp,
			"mobility": loadout.mobility,
			"armor": loadout.armor,
			"firepower": loadout.firepower,
			"module_ids": loadout.module_ids.duplicate(),
		}
	return {
		"schema_version": SCHEMA_VERSION,
		"active_mech_id": _active_mech_id,
		"mechs": mechs_data,
		"legacy_parts": parts.duplicate(),  # for S6-018 backward compat
	}

func load_snapshot(snap: Dictionary) -> Error:
	var version: int = int(snap.get("schema_version", 1))
	if version == 1:
		# Legacy: just load the 5 parts
		if snap.has("parts"):
			for key in snap["parts"].keys():
				parts[StringName(key)] = StringName(snap["parts"][key])
		return OK
	# v2: roster
	if snap.has("active_mech_id"):
		var aid: StringName = StringName(snap["active_mech_id"])
		if _mechs.has(aid):
			_active_mech_id = aid
	if snap.has("mechs"):
		var mechs_data: Dictionary = snap["mechs"]
		for mech_id in mechs_data:
			var md: Dictionary = mechs_data[mech_id]
			var loadout: MechCombatLoadout = _mechs.get(StringName(mech_id), null)
			if loadout == null:
				# Auto-register a missing mech from save data
				var mid: StringName = StringName(mech_id)
				var dn: String = md.get("display_name", String(mech_id))
				var ct: StringName = StringName(md.get("class_type", "infantry"))
				var mws: int = int(md.get("max_weapon_slots", 3))
				loadout = _register_default_mech(mid, dn, ct, mws, 100, [])
			# Restore state
			if md.has("unlocked"):
				loadout.unlocked = bool(md["unlocked"])
			if md.has("weapon_slots"):
				var ws: Array = md["weapon_slots"]
				for i in range(min(ws.size(), loadout.max_weapon_slots)):
					loadout.weapon_slots[i] = StringName(ws[i])
			if md.has("ammo_slots"):
				var as_: Array = md["ammo_slots"]
				for i in range(min(as_.size(), loadout.max_weapon_slots)):
					loadout.ammo_slots[i] = StringName(as_[i])
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
			if md.has("pilot_id"):
				loadout.pilot_id = StringName(md["pilot_id"])
	if snap.has("legacy_parts"):
		var lp: Dictionary = snap["legacy_parts"]
		for key in lp.keys():
			parts[StringName(key)] = StringName(lp[key])
	return OK