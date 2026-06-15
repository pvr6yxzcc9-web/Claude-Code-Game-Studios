extends Camera2D

# Camera2D follow player (per camera.md)
# Attached as child of Player (or sibling) — follows target node.

@export var target: Node2D

func _ready() -> void:
    # Auto-target parent if not explicitly set
    if target == null:
        var parent: Node = get_parent()
        if parent is Node2D:
            target = parent
    if target != null:
        # Position camera to view the area around target (center of viewport)
        global_position = target.global_position
        # Enable and make current
        enabled = true
        make_current()
    print("[CameraFollow] ready, target=%s, pos=%s" % [target.name if target else "none", global_position])

func _process(_delta: float) -> void:
    var _sm: Node = get_node_or_null("/root/GameStateMachine")
    if _sm != null and _sm.is_paused():
        return
    if target == null:
        return
    global_position = global_position.lerp(target.global_position, 0.1)
