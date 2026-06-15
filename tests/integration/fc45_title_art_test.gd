extends GutTest

# FC-45 Title screen art (S6-016)
# Pins that MainMenu now renders the title background art:
#   1) title_bg.png exists at 1280x720
#   2) MainMenu has a TextureRect (not just a ColorRect) as background
#   3) The TextureRect's texture matches the title_bg.png
#   4) Title text "RAILHUNTER" still present
#   5) Menu items still present and focusable

var _main: Node = null
var _menu: Node = null

func before_all() -> void:
	_main = load("res://src/main.tscn").instantiate()
	get_tree().root.add_child(_main)
	await get_tree().process_frame
	await get_tree().process_frame
	_menu = get_tree().get_root().find_child("MainMenu", true, false)

func after_all() -> void:
	if _main != null:
		_main.queue_free()
		_main = null

# 1) Asset presence + dimensions

func test_title_bg_exists() -> void:
	var path: String = "res://assets/sprites/title/title_bg.png"
	assert_true(ResourceLoader.exists(path), "title_bg.png exists")

func test_title_bg_is_1280x720() -> void:
	var path: String = "res://assets/sprites/title/title_bg.png"
	if not ResourceLoader.exists(path):
		pending("title_bg.png missing")
		return
	var tex: Texture2D = load(path)
	assert_eq(tex.get_width(), 1280, "title_bg width is 1280")
	assert_eq(tex.get_height(), 720, "title_bg height is 720")

# 2) MainMenu uses TextureRect

func test_main_menu_has_texture_rect_background() -> void:
	if _menu == null:
		pending("MainMenu not found")
		return
	var has_tex_rect: bool = false
	for child in _menu.get_children():
		if child is TextureRect:
			has_tex_rect = true
			break
	assert_true(has_tex_rect, "MainMenu has a TextureRect child (title bg)")

# 3) TextureRect is the title art

func test_main_menu_texture_rect_uses_title_bg() -> void:
	if _menu == null:
		pending("MainMenu not found")
		return
	for child in _menu.get_children():
		if child is TextureRect and child.texture != null:
			var path: String = child.texture.resource_path
			assert_eq(path, "res://assets/sprites/title/title_bg.png",
				"TextureRect uses title_bg.png (path = %s)" % path)
			return
	pending("no TextureRect with title_bg texture found")

# 4) Title text still present

func test_main_menu_title_label_present() -> void:
	if _menu == null:
		pending("MainMenu not found")
		return
	for child in _menu.get_children():
		if child is Label and String(child.text) == "RAILHUNTER":
			return
	assert_true(false, "MainMenu has 'RAILHUNTER' title label")

# 5) Menu items still focusable

func test_main_menu_has_focusable_items() -> void:
	if _menu == null:
		pending("MainMenu not found")
		return
	assert_gt(_menu._menu_items.size(), 0, "MainMenu has menu items")
	assert_gt(_menu._label_widgets.size(), 0, "MainMenu has label widgets")
