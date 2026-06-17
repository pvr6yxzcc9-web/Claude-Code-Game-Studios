extends Node

# ParticleFxManager (S6-101 + S17-004) — central spawner for short-lived particle effects.
# All effects are GPUParticles2D nodes with a configured ParticleProcessMaterial;
# they auto-free after their lifetime expires. S17-004 loads 5 sprite textures
# (particle_circle, particle_spark, particle_star, particle_glow, particle_dust)
# from assets/sprites/vfx/ and uses them as the per-particle texture.
#
# Public API:
#   spawn_footstep_dust(pos: Vector2)        # small dust puffs
#   spawn_muzzle_flash(pos: Vector2)        # bright yellow burst
#   spawn_hit_spark(pos: Vector2)            # orange sparks outward
#   spawn_heal_sparkle(pos: Vector2)         # green sparkles (S17-004 new)
#   spawn_buff_glow(pos: Vector2)            # blue up-arrow glow (S17-004 new)
#
# Effects are added to the "Main" scene (level_runtime) so they render in world
# space at the correct z-order. They are removed by emit_one_shot + auto-cleanup
# timer.

const _FOOTSTEP_LIFETIME: float = 0.4
const _MUZZLE_LIFETIME: float = 0.15
const _HIT_LIFETIME: float = 0.3
const _HEAL_LIFETIME: float = 0.5
const _BUFF_LIFETIME: float = 0.4

# S17-004: sprite cache
var _sprite_circle: Texture2D = null
var _sprite_spark: Texture2D = null
var _sprite_star: Texture2D = null
var _sprite_glow: Texture2D = null
var _sprite_dust: Texture2D = null

func _ready() -> void:
	_load_sprites()
	print("[ParticleFx] ready (%d sprites loaded)" % _count_loaded())

func _load_sprites() -> void:
	# Per S17-004: load 5 procedural particle sprites
	_sprite_circle = _safe_load("res://assets/sprites/vfx/particle_circle.png")
	_sprite_spark = _safe_load("res://assets/sprites/vfx/particle_spark.png")
	_sprite_star = _safe_load("res://assets/sprites/vfx/particle_star.png")
	_sprite_glow = _safe_load("res://assets/sprites/vfx/particle_glow.png")
	_sprite_dust = _safe_load("res://assets/sprites/vfx/particle_dust.png")

func _safe_load(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

func _count_loaded() -> int:
	var n: int = 0
	if _sprite_circle != null: n += 1
	if _sprite_spark != null: n += 1
	if _sprite_star != null: n += 1
	if _sprite_glow != null: n += 1
	if _sprite_dust != null: n += 1
	return n

# S6-101: footstep dust — small dust puffs near the player's feet.
# S17-004: uses particle_dust sprite (was plain color).
# Called by player_controller when they move (debounced to every N pixels).
func spawn_footstep_dust(pos: Vector2) -> void:
	var fx: GPUParticles2D = _make_burst(pos, Color(0.7, 0.7, 0.7, 0.8),
		amount: int = 6, lifetime: float = _FOOTSTEP_LIFETIME,
		speed: float = 30.0, direction: Vector2 = Vector2(0, -0.3),
		spread: float = 45.0, scale_min: float = 1.5, scale_max: float = 3.0,
		sprite: Texture2D = _sprite_dust)
	_attach(fx)

# S6-101: muzzle flash — bright yellow burst at the attack origin.
# S17-004: uses particle_glow sprite.
# Called by battle_scene.on_player_attack().
func spawn_muzzle_flash(pos: Vector2) -> void:
	var fx: GPUParticles2D = _make_burst(pos, Color(1.0, 0.95, 0.5, 1.0),
		amount: int = 12, lifetime: float = _MUZZLE_LIFETIME,
		speed: float = 120.0, direction: Vector2(1, 0),
		spread: float = 25.0, scale_min: float = 3.0, scale_max: float = 6.0,
		sprite: Texture2D = _sprite_glow)
	_attach(fx)

# S6-101: hit sparks — orange/red sparks outward from the impact point.
# S17-004: uses particle_spark sprite.
# Called by battle_scene._on_enemy_hit() (to be wired).
func spawn_hit_spark(pos: Vector2) -> void:
	var fx: GPUParticles2D = _make_burst(pos, Color(1.0, 0.6, 0.2, 1.0),
		amount: int = 14, lifetime: float = _HIT_LIFETIME,
		speed: float = 180.0, direction: Vector2(0, -1),
		spread: float = 70.0, scale_min: float = 2.0, scale_max: float = 4.0,
		sprite: Texture2D = _sprite_spark)
	_attach(fx)

# S17-004: heal sparkles — green particles rising upward.
# Called when a pilot is revived at the clinic.
func spawn_heal_sparkle(pos: Vector2) -> void:
	var fx: GPUParticles2D = _make_burst(pos, Color(0.3, 1.0, 0.5, 1.0),
		amount: int = 10, lifetime: float = _HEAL_LIFETIME,
		speed: float = 60.0, direction: Vector2(0, -1),
		spread: float = 30.0, scale_min: float = 2.0, scale_max: float = 4.0,
		sprite: Texture2D = _sprite_glow)
	_attach(fx)

# S17-004: buff glow — blue particles around the buffed target.
# Called when a buff (damage up, defense up) is applied.
func spawn_buff_glow(pos: Vector2) -> void:
	var fx: GPUParticles2D = _make_burst(pos, Color(0.4, 0.7, 1.0, 1.0),
		amount: int = 12, lifetime: float = _BUFF_LIFETIME,
		speed: float = 50.0, direction: Vector2(0, -0.5),
		spread: float = 60.0, scale_min: float = 2.5, scale_max: float = 5.0,
		sprite: Texture2D = _sprite_glow)
	_attach(fx)

# Build a one-shot GPUParticles2D burst.
# S17-004: accepts a sprite parameter; if non-null, sets fx.texture.
func _make_burst(pos: Vector2, color: Color, amount: int, lifetime: float,
		speed: float, direction: Vector2, spread: float, scale_min: float, scale_max: float,
		sprite: Texture2D = null) -> GPUParticles2D:
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
	# S17-004: use the procedural sprite if available, else default white
	if sprite != null:
		fx.texture = sprite
	else:
		fx.texture = null
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
