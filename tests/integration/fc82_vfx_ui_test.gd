extends GutTest

# VFX + UI sprite library integration test (Sprint 17, fc82) —
# verifies the 26 new sprites from S17-001..003 + ParticleFxManager
# sprite loading (S17-004).

const VFX_SPRITES: Array[String] = [
	"particle_circle", "particle_spark", "particle_star",
	"particle_glow", "particle_dust",
	"hit_damage", "hit_crit", "hit_heal", "hit_buff",
	"hit_debuff", "hit_block", "hit_miss", "hit_kill",
]
const UI_SPRITES: Array[String] = [
	"button_normal", "button_hover", "button_pressed", "button_disabled",
	"panel_bg", "panel_border", "dialog_portrait",
	"scrollbar_track", "scrollbar_handle",
	"slider_track", "slider_handle",
	"checkbox_unchecked", "checkbox_checked",
]
const PFX_PATH: String = "/root/ParticleFxManager"

func _pfx() -> Node: return get_node_or_null(PFX_PATH)

# === VFX sprites (13 total: 5 particles + 8 hit feedback) ===

func test_vfx_particle_sprites_all_5_exist() -> void:
	for name in ["particle_circle", "particle_spark", "particle_star", "particle_glow", "particle_dust"]:
		var path: String = "res://assets/sprites/vfx/%s.png" % name
		assert_true(FileAccess.file_exists(path), "%s.png exists" % name)

func test_vfx_hit_feedback_sprites_all_8_exist() -> void:
	for name in ["hit_damage", "hit_crit", "hit_heal", "hit_buff",
		"hit_debuff", "hit_block", "hit_miss", "hit_kill"]:
		var path: String = "res://assets/sprites/vfx/%s.png" % name
		assert_true(FileAccess.file_exists(path), "%s.png exists" % name)

# === UI element sprites (13 total) ===

func test_ui_sprites_all_13_exist() -> void:
	for name in UI_SPRITES:
		var path: String = "res://assets/sprites/ui/%s.png" % name
		assert_true(FileAccess.file_exists(path), "%s.png exists" % name)

# === ParticleFxManager integration ===

func test_particle_fx_manager_registered() -> void:
	# ParticleFxManager should be in autoload list (S6-101 was added in Sprint 6)
	# S17-004 updated it to load sprites
	var pfx: Node = _pfx()
	# Don't pending() — if missing, this is a real failure
	if pfx == null:
		fail_test("ParticleFxManager autoload missing — was it removed?")
		return
	# Check new S17-004 methods exist
	assert_true(pfx.has_method("spawn_heal_sparkle"), "spawn_heal_sparkle exists (S17-004)")
	assert_true(pfx.has_method("spawn_buff_glow"), "spawn_buff_glow exists (S17-004)")

func test_particle_fx_has_all_original_methods() -> void:
	var pfx: Node = _pfx()
	if pfx == null:
		return
	for method in ["spawn_footstep_dust", "spawn_muzzle_flash", "spawn_hit_spark"]:
		assert_true(pfx.has_method(method), "%s exists" % method)

# === Sprite size sanity (32x32 for VFX, various for UI) ===

func test_vfx_sprites_are_32x32() -> void:
	# Spot check: particle_circle should be 32x32 RGBA
	var path: String = "res://assets/sprites/vfx/particle_circle.png"
	if not FileAccess.file_exists(path):
		return
	var img: Image = Image.load_from_file(path)
	if img == null:
		return
	assert_eq(img.get_width(), 32, "particle_circle width 32")
	assert_eq(img.get_height(), 32, "particle_circle height 32")

func test_ui_button_sprites_are_64x16() -> void:
	for name in ["button_normal", "button_hover", "button_pressed", "button_disabled"]:
		var path: String = "res://assets/sprites/ui/%s.png" % name
		if not FileAccess.file_exists(path):
			continue
		var img: Image = Image.load_from_file(path)
		if img == null:
			continue
		assert_eq(img.get_width(), 64, "%s width 64" % name)
		assert_eq(img.get_height(), 16, "%s height 16" % name)

# === Cumulative check ===

func test_total_s17_assets_at_least_26() -> void:
	var count: int = 0
	for name in VFX_SPRITES:
		if FileAccess.file_exists("res://assets/sprites/vfx/%s.png" % name):
			count += 1
	for name in UI_SPRITES:
		if FileAccess.file_exists("res://assets/sprites/ui/%s.png" % name):
			count += 1
	# 13 VFX + 13 UI = 26
	assert_gte(count, 26, "at least 26 S17 assets present (got %d)" % count)
