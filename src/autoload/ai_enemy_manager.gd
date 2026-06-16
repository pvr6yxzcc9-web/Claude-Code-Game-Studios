extends Node

# AIEnemyManager (S9-014) — AI enemy combat mechanic for Sat-4 断魂号.
# Per sprint-09-sat4-military.md
# AI mechs have additional combat abilities triggered by their `ai_abilities` field.
# Examples:
#   叛变哨兵: disable_player_ability_1_turn (locks one player ability for 1 turn)
#   冥王残兵: force_recalculate_aim (reroll all player attacks this turn)
#   失控无人机: summon_scrap_drone (every 3 turns, summon 1 weak ally)

signal ai_ability_triggered(enemy_id: StringName, ability: StringName, target_id: StringName)
signal ai_ability_resolved(enemy_id: StringName, ability: StringName)

# Per-enemy ability definitions (registered at _ready)
# Format: enemy_id → [{ability: StringName, chance_per_turn: float, params: Dict}]
var _abilities: Dictionary = {}

# Cooldowns (turns remaining until ability can re-trigger)
var _cooldowns: Dictionary = {}

# Locked player abilities (ability_id → turns_remaining)
var _locked_abilities: Dictionary = {}

func _ready() -> void:
	# Register AI enemy abilities (S9-014 + S9-003)
	_register_default_abilities()
	print("[AIEnemyManager] ready — AI abilities registered")

func _register_default_abilities() -> void:
	# 叛变哨兵 (renegade_sentinel): disable_player_ability_1_turn
	_abilities[&"ch4_renegade_sentinel"] = [
		{"ability": &"disable_player_ability_1_turn", "chance": 0.30, "cooldown": 3, "params": {}},
	]
	# 冥王残兵 (ai_remnant): force_recalculate_aim
	_abilities[&"ch4_ai_remnant"] = [
		{"ability": &"force_recalculate_aim", "chance": 0.25, "cooldown": 4, "params": {}},
	]
	# 失控无人机 (rogue_drone): summon_scrap_drone
	_abilities[&"ch4_rogue_drone"] = [
		{"ability": &"summon_scrap_drone", "chance": 1.0, "cooldown": 3, "params": {"ally_id": &"ch4_wreck_bot"}},
	]
	# Boss 冥王残响: disable_2_player_abilities_1_turn (S9-016 phase 2 ability)
	_abilities[&"boss_pluto_remnant"] = [
		{"ability": &"disable_2_player_abilities_1_turn", "chance": 0.40, "cooldown": 3, "params": {}},
	]

# === API ===

# Called at start of enemy's turn. Returns true if an ability triggered.
func try_trigger_ability(enemy_id: StringName, target_id: StringName = &"") -> bool:
	if not _abilities.has(enemy_id):
		return false
	var ability_list: Array = _abilities[enemy_id]
	for ability_data in ability_list:
		var ability: StringName = ability_data["ability"]
		# Check cooldown
		var cd_key: String = String(enemy_id) + "_" + String(ability)
		if _cooldowns.has(cd_key) and int(_cooldowns[cd_key]) > 0:
			continue
		# Roll
		var chance: float = ability_data["chance"]
		if randf() > chance:
			continue
		# Trigger
		ai_ability_triggered.emit(enemy_id, ability, target_id)
		_resolve_ability(enemy_id, ability, target_id, ability_data)
		# Set cooldown
		_cooldowns[cd_key] = ability_data["cooldown"]
		return true
	return false

func _resolve_ability(enemy_id: StringName, ability: StringName, target_id: StringName, ability_data: Dictionary) -> void:
	match String(ability):
		"disable_player_ability_1_turn":
			# Lock 1 random player ability for 1 turn
			var abilities: Array[StringName] = [&"q", &"w", &"e", &"r", &"t", &"y"]
			var locked: StringName = abilities[randi() % abilities.size()]
			_locked_abilities[locked] = 1
			print("[AIEnemyManager] %s disabled player ability %s for 1 turn" % [enemy_id, locked])
		"force_recalculate_aim":
			# Triggered visual: enemy glows red for 1 turn
			print("[AIEnemyManager] %s forces aim recalculation this turn" % enemy_id)
		"summon_scrap_drone":
			var ally_id: StringName = StringName(ability_data["params"].get("ally_id", &""))
			print("[AIEnemyManager] %s summons %s" % [enemy_id, ally_id])
		"disable_2_player_abilities_1_turn":
			var abilities: Array[StringName] = [&"q", &"w", &"e", &"r", &"t", &"y"]
			abilities.shuffle()
			for i in 2:
				_locked_abilities[abilities[i]] = 1
			print("[AIEnemyManager] %s disabled 2 player abilities for 1 turn" % enemy_id)
	ai_ability_resolved.emit(enemy_id, ability)

# Check if a player ability is locked
func is_ability_locked(ability: StringName) -> bool:
	return _locked_abilities.get(ability, 0) > 0

# Decrement cooldowns (called at start of each turn)
func tick_turn() -> void:
	# Decrement ability cooldowns
	for key in _cooldowns:
		_cooldowns[key] = max(0, int(_cooldowns[key]) - 1)
	# Decrement lock timers
	for key in _locked_abilities:
		_locked_abilities[key] = max(0, int(_locked_abilities[key]) - 1)
		if int(_locked_abilities[key]) == 0:
			_locked_abilities.erase(key)

# Get all currently locked abilities (for UI display)
func get_locked_abilities() -> Array:
	var out: Array = []
	for key in _locked_abilities:
		if int(_locked_abilities[key]) > 0:
			out.append(StringName(key))
	return out

# Register a custom ability (for testing or extension)
func register_ability(enemy_id: StringName, ability: StringName, chance: float, cooldown: int, params: Dictionary = {}) -> void:
	if not _abilities.has(enemy_id):
		_abilities[enemy_id] = []
	var existing: Array = _abilities[enemy_id]
	existing.append({"ability": ability, "chance": chance, "cooldown": cooldown, "params": params})
	_abilities[enemy_id] = existing

# Reset state (new combat / new game)
func reset() -> void:
	_cooldowns.clear()
	_locked_abilities.clear()