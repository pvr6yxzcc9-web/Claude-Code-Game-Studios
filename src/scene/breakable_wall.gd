extends StaticBody2D
class_name BreakableWall

# BreakableWall (S4-008)
# A wall segment that the player destroys by pressing 1/2/3 while in
# proximity. Used to hide secret areas. Reduces hp by 1 per attack
# (no weapon-damage scaling — kept simple for MVP). When hp hits 0,
# the wall is freed, revealing what's behind it (handled by caller).

signal wall_broken(wall: Node)

@export var max_hp: int = 3
var current_hp: int = 3
var _visual: ColorRect
var _proximity_area: Area2D

func _ready() -> void:
	current_hp = max_hp
	_visual = ColorRect.new()
	_visual.color = Color(0.4, 0.3, 0.2, 1)
	_visual.size = Vector2(100, 320)
	add_child(_visual)
	# Collision for player to bump into
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(100, 320)
	shape.shape = rect
	add_child(shape)
	# Proximity sensor: detects player within ~120px of the wall
	_proximity_area = Area2D.new()
	add_child(_proximity_area)
	var prox_shape: CollisionShape2D = CollisionShape2D.new()
	var prox_rect: RectangleShape2D = RectangleShape2D.new()
	prox_rect.size = Vector2(220, 440)  # 120px wider than the wall on each side
	prox_shape.shape = prox_rect
	_proximity_area.add_child(prox_shape)
	# Subscribe to attack signals from WeaponLoadout (via InputBus)
	var loadout: Node = get_node_or_null("/root/WeaponLoadout")
	if loadout != null and loadout.has_signal("attack_triggered"):
		loadout.attack_triggered.connect(_on_attack_triggered)

func _on_attack_triggered(_slot: int) -> void:
	if current_hp <= 0:
		return
	# Only count the attack if a PlayerController body is within proximity.
	# Note: Godot 4.6 `Area2D.get_overlapping_bodies()` returns `Array[Node2D]`
	# (narrow), not `Array[Node]`. Typed arrays are invariant — assigning
	# Array[Node2D] to Array[Node] is a parser error even though Node2D
	# extends Node. Untyped local works around this; runtime check
	# `b is PlayerController` gives the same safety.
	var bodies: Array = _proximity_area.get_overlapping_bodies()
	for b in bodies:
		if b is PlayerController:
			_take_hit()
			return

func _take_hit() -> void:
	current_hp -= 1
	# Visual feedback: darken as hp drops
	var t: float = float(current_hp) / float(max_hp)
	_visual.color = Color(0.4 * t, 0.3 * t, 0.2 * t, 1.0)
	if current_hp <= 0:
		_break()

func _break() -> void:
	wall_broken.emit(self)
	queue_free()

# Public API: how many hits remain (for HUD / progress)
func get_remaining_hp() -> int:
	return current_hp
