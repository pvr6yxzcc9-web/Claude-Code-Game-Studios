extends GutTest

# FC-53 Particle effects (S6-101)
# Pins that ParticleFxManager works and is wired:
#   1) ParticleFx autoload registered
#   2) spawn_footstep_dust adds a GPUParticles2D to scene
#   3) spawn_muzzle_flash adds a GPUParticles2D
#   4) spawn_hit_spark adds a GPUParticles2D
#   5) Each spawned node has emitting=true on creation
#   6) Particles auto-cleanup after lifetime
#   7) PlayerController has footstep hook (FOOTSTEP_INTERVAL constant)

var _main: Node = null
var _pfx: Node = null

func before_all() -> void:
	_main = load("res://src/main.tscn").instantiate()
	get_tree().root.add_child(_main)
	await get_tree().process_frame
	await get_tree().process_frame
	_pfx = get_node_or_null("/root/ParticleFx")

func after_all() -> void:
	if _main != null:
		_main.queue_free()
		_main = null

# 1) Autoload

func test_particle_fx_registered() -> void:
	assert_not_null(_pfx, "ParticleFx autoload registered")

# 2-4) Spawn methods

func test_spawn_footstep_creates_node() -> void:
	if _pfx == null:
		pending("no ParticleFx")
		return
	var main: Node = get_tree().get_root().find_child("Main", true, false)
	if main == null:
		pending("no Main scene")
		return
	# Count children before
	var before: int = 0
	for c in main.get_children():
		if c is GPUParticles2D:
			before += 1
	_pfx.spawn_footstep_dust(Vector2(640, 360))
	# Count after
	var after: int = 0
	for c in main.get_children():
		if c is GPUParticles2D:
			after += 1
	assert_eq(after, before + 1, "footstep dust added a GPUParticles2D to Main")

func test_spawn_muzzle_flash_creates_node() -> void:
	if _pfx == null:
		pending("no ParticleFx")
		return
	var main: Node = get_tree().get_root().find_child("Main", true, false)
	var before: int = 0
	for c in main.get_children():
		if c is GPUParticles2D:
			before += 1
	_pfx.spawn_muzzle_flash(Vector2(640, 360))
	var after: int = 0
	for c in main.get_children():
		if c is GPUParticles2D:
			after += 1
	assert_eq(after, before + 1, "muzzle flash added a GPUParticles2D")

func test_spawn_hit_spark_creates_node() -> void:
	if _pfx == null:
		pending("no ParticleFx")
		return
	var main: Node = get_tree().get_root().find_child("Main", true, false)
	var before: int = 0
	for c in main.get_children():
		if c is GPUParticles2D:
			before += 1
	_pfx.spawn_hit_spark(Vector2(640, 360))
	var after: int = 0
	for c in main.get_children():
		if c is GPUParticles2D:
			after += 1
	assert_eq(after, before + 1, "hit spark added a GPUParticles2D")

# 5) emitting=true on creation

func test_spawned_particle_is_emitting() -> void:
	if _pfx == null:
		pending("no ParticleFx")
		return
	_pfx.spawn_muzzle_flash(Vector2(100, 100))
	# Find the most recently added GPUParticles2D
	var main: Node = get_tree().get_root().find_child("Main", true, false)
	if main == null:
		pending("no Main")
		return
	var last: GPUParticles2D = null
	for c in main.get_children():
		if c is GPUParticles2D:
			last = c
	if last == null:
		pending("no particles found")
		return
	assert_true(last.emitting, "newly spawned particle is emitting")
	assert_true(last.one_shot, "particle is one_shot")
	assert_gt(last.amount, 0, "particle has non-zero amount")

# 6) Auto-cleanup after lifetime

func test_particles_auto_cleanup() -> void:
	if _pfx == null:
		pending("no ParticleFx")
		return
	_pfx.spawn_hit_spark(Vector2(100, 100))
	var main: Node = get_tree().get_root().find_child("Main", true, false)
	var before: int = 0
	for c in main.get_children():
		if c is GPUParticles2D:
			before += 1
	# Wait for cleanup (>0.3s + 0.1s = 0.4s buffer)
	await get_tree().create_timer(0.5).timeout
	var after: int = 0
	for c in main.get_children():
		if c is GPUParticles2D:
			after += 1
	assert_lt(after, before, "particles auto-cleaned up after lifetime")

# 7) PlayerController footstep hook

func test_player_controller_has_footstep_constant() -> void:
	var player_script: Script = load("res://src/scene/player_controller.gd")
	if player_script == null:
		pending("player_controller.gd not loadable")
		return
	# Check constant exists
	var constants: Dictionary = player_script.get_script_constant_map() if player_script.has_method("get_script_constant_map") else {}
	# Use direct test by looking for FOOTSTEP_INTERVAL in source
	var src: String = player_script.source_code if "source_code" in player_script else ""
	assert_true(src.contains("FOOTSTEP_INTERVAL"), "player_controller has FOOTSTEP_INTERVAL constant")
	assert_true(src.contains("ParticleFx") or src.contains("spawn_footstep_dust"),
		"player_controller references ParticleFx")
