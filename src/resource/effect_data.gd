@tool
class_name EffectData
extends ImmutableResource

# EffectData (per resource-data.md + ADR-0008)
# Describes a status effect applied to a combatant (e.g., poison, stun, +crit).

@export var id: StringName
@export var display_name: String
@export var icon: Texture2D
@export var duration_turns: int = 1
@export var stat_modifiers: Dictionary = {}  # {"attack": 0.15, "accuracy": -0.1}
@export var damage_per_turn: int = 0
@export var on_apply_signal: String = ""  # optional signal hook
@export var on_remove_signal: String = ""
@export var on_tick_signal: String = ""
