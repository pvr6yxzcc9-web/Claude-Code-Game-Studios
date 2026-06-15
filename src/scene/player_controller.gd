extends CharacterBody2D
class_name PlayerController

# PlayerController — per player-input.md + level-dungeon.md
# Top-down 2D player movement on a TileMapLayer-based room.

const SPEED: float = 120.0  # pixels/sec

var facing: Vector2i = Vector2i.DOWN
var last_footstep_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
    print("[PlayerController] ready")

func _physics_process(_delta: float) -> void:
    var _sm: Node = get_node_or_null("/root/GameStateMachine")
    if _sm != null and _sm.is_paused():
        return
    var input: Vector2 = Vector2(
        Input.get_axis("move_left", "move_right"),
        Input.get_axis("move_up", "move_down")
    )
    if input.length() > 0:
        input = input.normalized()
        velocity = input * SPEED
        if abs(input.y) > abs(input.x):
            facing = Vector2i.UP if input.y < 0 else Vector2i.DOWN
        else:
            facing = Vector2i.LEFT if input.x < 0 else Vector2i.RIGHT
    else:
        velocity = Vector2.ZERO
    move_and_slide()
