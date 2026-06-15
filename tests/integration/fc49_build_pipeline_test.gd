extends GutTest

# FC-49 Build pipeline (S6-020)
# Pins that the build infrastructure is in place:
#   1) tools/build.sh exists
#   2) export_presets.cfg exists
#   3) export_presets.cfg defines 4 presets
#   4) The preset names match what build.sh expects
#   5) project.godot references autoloads (mono build still works)
#   6) Localization.t() exists (renamed from tr() to avoid Object.tr shadowing)
#   7) production/build/README.md exists

func test_build_script_exists() -> void:
	assert_true(FileAccess.file_exists("res://tools/build.sh"),
		"tools/build.sh exists")

func test_export_presets_exists() -> void:
	assert_true(FileAccess.file_exists("res://export_presets.cfg"),
		"export_presets.cfg exists")

func test_export_presets_has_4_presets() -> void:
	var f: FileAccess = FileAccess.open("res://export_presets.cfg", FileAccess.READ)
	if f == null:
		pending("cannot read export_presets.cfg")
		return
	var content: String = f.get_as_text()
	f.close()
	# Count [preset.N] sections
	var count: int = 0
	for line in content.split("\n"):
		if line.begins_with("[preset."):
			count += 1
	assert_eq(count, 4, "export_presets.cfg has 4 presets (Linux/Win release+debug)")

func test_preset_names_match_build_sh() -> void:
	# build.sh looks for: "Linux/X11", "Linux/X11 (Debug)", "Windows Desktop", "Windows Desktop (Debug)"
	var f: FileAccess = FileAccess.open("res://export_presets.cfg", FileAccess.READ)
	if f == null:
		pending("cannot read export_presets.cfg")
		return
	var content: String = f.get_as_text()
	f.close()
	for name in ["Linux/X11", "Linux/X11 (Debug)", "Windows Desktop", "Windows Desktop (Debug)"]:
		assert_true(content.contains("name=\"" + name + "\""),
			"preset named '%s' present" % name)

func test_project_uses_mono() -> void:
	# project.godot must have [dotnet] section for the mono build to work
	var f: FileAccess = FileAccess.open("res://project.godot", FileAccess.READ)
	if f == null:
		pending("cannot read project.godot")
		return
	var content: String = f.get_as_text()
	f.close()
	assert_true(content.contains("[dotnet]"), "project.godot has [dotnet] section")
	assert_true(content.contains("project/assembly_name"), "project.godot has assembly_name")

func test_localization_t_method_exists() -> void:
	# After the rename from tr() to t() to avoid Object.tr collision
	var loc: Node = get_node_or_null("/root/Localization")
	if loc == null:
		pending("Localization not in scene tree")
		return
	assert_true(loc.has_method("t"), "Localization has .t() method (renamed from .tr() to avoid Object.tr shadow)")
	assert_false(loc.has_method("tr") and not loc.get_script().get_script_method_list().any(
		func(m): return m.name == "tr"),
		"Localization does not define a tr() method that would shadow Object.tr()")

func test_build_readme_exists() -> void:
	assert_true(FileAccess.file_exists("res://production/build/README.md"),
		"production/build/README.md exists")

func test_build_script_references_correct_preset_paths() -> void:
	var f: FileAccess = FileAccess.open("res://tools/build.sh", FileAccess.READ)
	if f == null:
		pending("cannot read build.sh")
		return
	var content: String = f.get_as_text()
	f.close()
	# Sanity: script checks for godot, export_presets.cfg, and runs --export-release
	assert_true(content.contains("godot"), "build.sh references godot")
	assert_true(content.contains("export_presets.cfg"), "build.sh checks for export_presets.cfg")
	assert_true(content.contains("export-release"), "build.sh uses --export-release flag")
