extends Node

# ParticleFxManager (S6-101) — central spawner for short-lived particle effects.
# All effects are GPUParticles2D nodes with a configured ParticleProcessMaterial;
# they auto-free after their lifetime expires. No texture dependency — we use
# procedural "soft circle" particles drawn via the draw_pass_quads.
#
# Public API:
#   spawn_footstep_dust(pos: Vector2)        # small grey puffs
#   spawn_muzzle_flash(pos: Vector2)        # bright yellow burst
#   spawn_hit_spark(pos: Vector2)            # orange sparks outward
#
# Effects are added to the "Main" scene (level_runtime) so they render in world
# space at the correct z-order. They are removed by emit_one_shot + auto-cleanup
# timer.

const _FOOTSTEP_LIFETIME: float = 0.4
const _MUZZLE_LIFETIME: float = 0.15
const _HIT_LIFETIME: float = 0.3

func _ready() -> void:
	print("[ParticleFx] ready")

# S6-101: footstep dust — small grey puffs near the player's feet.
# Called by player_controller when they move (debounced to every N pixels).
func spawn_footstep_dust(pos: Vector2) -> void:
	var fx: GPUParticles2D = _make_burst(pos, Color(0.7, 0.7, 0.7, 0.5),
		amount: int = 6, lifetime: float = _FOOTSTEP_LIFETIME,
		speed: float = 30.0, direction: Vector2 = Vector2(0, -0.3),
		spread: float = 45.0, scale_min: float = 1.5, scale_max: float = 3.0)
	_attach(fx)

# S6-101: muzzle flash — bright yellow burst at the attack origin.
# Called by battle_scene.on_player_attack().
func spawn_muzzle_flash(pos: Vector2) -> void:
	var fx: GPUParticles2D = _make_burst(pos, Color(1.0, 0.95, 0.5, 1.0),
		amount: int = 12, lifetime: float = _MUZZLE_LIFETIME,
		speed: float = 120.0, direction: Vector2(1, 0),
		spread: float = 25.0, scale_min: float = 3.0, scale_max: float = 6.0)
	_attach(fx)

# S6-101: hit sparks — orange/red sparks outward from the impact point.
# Called by battle_scene._on_enemy_hit() (to be wired).
func spawn_hit_spark(pos: Vector2) -> void:
	var fx: GPUParticles2D = _make_burst(pos, Color(1.0, 0.6, 0.2, 1.0),
		amount: int = 14, lifetime: float = _HIT_LIFETIME,
		speed: float = 180.0, direction: Vector2(0, -1),
		spread: float = 70.0, scale_min: float = 2.0, scale_max: float = 4.0)
	_attach(fx)

# Build a one-shot GPUParticles2D burst.
func _make_burst(pos: Vector2, color: Color, amount: int, lifetime: float,
		speed: float, direction: Vector2, spread: float, scale_min: float, scale_max: float) -> GPUParticles2D:
	var fx: GPUParticles2D = GPUParticles2D.new()
	fx.global_position = pos
	fx.amount = amount
	fx.lifetime = lifetime
	fx.one_shot = true
	fx.explosiveness = 1.0
	fx.local_coords = false
	fx.z_index = 5  # above floor tiles, below UI
	# ParticleProcessMaterial configures the per-particle motion
	var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	mat.direction = direction
	mat.spread = spread
	mat.initial_velocity_min = speed * 0.5
	mat.initial_velocity_max = speed
	mat.gravity = Vector3(0, 80, 0)  # pull down
	mat.scale_min = scale_min
	mat.scale_max = scale_max
	mat.color = color
	mat.damping_min = 50.0
	mat.damping_max = 100.0
	fx.process_material = mat
	# Draw pass: a soft circle (no texture = use default white quad)
	fx.texture = null  # default white rectangle
	# Auto-cleanup after lifetime + 0.1s buffer
	var t: SceneTreeTimer = get_tree().create_timer(lifetime + 0.1)
	t.timeout.connect(func() -> void:
		if is_instance_valid(fx):
			fx.queue_free())
	return fx

func _attach(fx: GPUParticles2D) -> void:
	# Attach to the running scene's root, so particles render in world space
	# and are cleaned up on room change.
	var main: Node = get_tree().get_root().find_child("Main", true, false)
	if main != null:
		main.add_child(fx)
	else:
		# Fallback: add to root if we can't find Main
		get_tree().root.add_child(fx)
	fx.emitting = true
