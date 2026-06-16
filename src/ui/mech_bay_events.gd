extends Node

# MechBayEvents (S7-007) — command/event bus for the Mech Bay UI.
# Per .claude/rules/ui-code.md: UI never directly modifies game state.
# UI calls these methods; they validate and delegate to MechLoadout /
# WeaponLoadout, then emit signals so the UI can refresh.
#
# Registered as autoload (after MechLoadout, before WeaponLoadout in the
# autoload order convention — but order matters less for events than for
# data dependencies since we resolve at call-time).

signal active_mech_changed(new_mech_id: StringName)
signal pilot_assigned(mech_id: StringName, pilot_id: StringName, previous_pilot_id: StringName)
signal weapon_moved(from_mech: StringName, from_slot: int, to_mech: StringName, to_slot: int)
signal mech_bay_opened()
signal mech_bay_closed()

const DEFAULT_PILOTS: Array[StringName] = [&"ranger", &"frostbite", &"bomber"]

func _ready() -> void:
	print("[MechBayEvents] ready")

# Switch the active mech. Validates the mech exists and is unlocked.
func set_active_mech(mech_id: StringName) -> Error:
	var loadout: Node = get_node("/root/MechLoadout")
	if loadout == null:
		push_error("MechBayEvents: MechLoadout missing")
		return ERR_DOES_NOT_EXIST
	if not loadout._mechs.has(mech_id):
		return ERR_INVALID_PARAMETER
	if not loadout.is_unlocked(mech_id):
		return ERR_UNAVAILABLE
	loadout.set_active_mech(mech_id)
	active_mech_changed.emit(mech_id)
	return OK

# Assign a pilot to a mech. If the pilot is already on another mech, the
# previous pilot of THIS mech gets bumped to that other mech (auto-swap).
func assign_pilot(mech_id: StringName, pilot_id: StringName) -> Error:
	var loadout: Node = get_node("/root/MechLoadout")
	if loadout == null:
		return ERR_DOES_NOT_EXIST
	var mech: Resource = loadout.get_mech(mech_id)
	if mech == null:
		return ERR_INVALID_PARAMETER
	if not mech.unlocked:
		return ERR_UNAVAILABLE
	# Validate the pilot is in the party roster
	var pilot_in_roster: bool = false
	for p in DEFAULT_PILOTS:
		if p == pilot_id:
			pilot_in_roster = true
			break
	if not pilot_in_roster:
		push_warning("MechBayEvents: pilot %s not in roster" % pilot_id)
		return ERR_INVALID_PARAMETER
	# Find the mech that currently has this pilot (if any)
	var previous_mech_id: StringName = &""
	var previous_pilot_id: StringName = StringName(mech.get("pilot_id"))
	for other_mech_id in loadout._mechs:
		var other: Resource = loadout._mechs[other_mech_id]
		if StringName(other.get("pilot_id")) == pilot_id and other_mech_id != mech_id:
			previous_mech_id = other_mech_id
			break
	# Auto-swap: previous pilot of THIS mech goes to the OTHER mech
	if previous_mech_id != &"":
		var prev_other: Resource = loadout._mechs[previous_mech_id]
		prev_other.set("pilot_id", String(previous_pilot_id))
	# Set the new pilot on the target mech
	mech.set("pilot_id", String(pilot_id))
	pilot_assigned.emit(mech_id, pilot_id, previous_pilot_id)
	if previous_mech_id != &"":
		# Emit a second signal for the swap (so UI can show "A: X → Y, B: Y → X")
		pilot_assigned.emit(previous_mech_id, previous_pilot_id, pilot_id)
	return OK

# Move a weapon from one mech's slot to another mech's slot.
func move_weapon(from_mech: StringName, from_slot: int, to_mech: StringName, to_slot: int) -> Error:
	var wl: Node = get_node("/root/WeaponLoadout")
	if wl == null:
		return ERR_DOES_NOT_EXIST
	var from_loadout: Resource = wl.get_mech_loadout(from_mech)
	var to_loadout: Resource = wl.get_mech_loadout(to_mech)
	if from_loadout == null or to_loadout == null:
		return ERR_INVALID_PARAMETER
	if from_slot < 0 or from_slot >= from_loadout.max_weapon_slots:
		return ERR_INVALID_PARAMETER
	if to_slot < 0 or to_slot >= to_loadout.max_weapon_slots:
		return ERR_INVALID_PARAMETER
	# Swap weapons between the two slots
	var from_weapon: StringName = StringName(from_loadout.weapon_slots[from_slot])
	var to_weapon: StringName = StringName(to_loadout.weapon_slots[to_slot])
	from_loadout.weapon_slots[from_slot] = to_weapon
	to_loadout.weapon_slots[to_slot] = from_weapon
	weapon_moved.emit(from_mech, from_slot, to_mech, to_slot)
	return OK

# Open / close signals (UI emits these for telemetry, not strictly needed
# since the UI handles its own visibility).
func notify_opened() -> void:
	mech_bay_opened.emit()

func notify_closed() -> void:
	mech_bay_closed.emit()