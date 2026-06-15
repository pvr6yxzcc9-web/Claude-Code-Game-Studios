extends GutTest

# FC-36 Build export script (S5-009)
# Pins:
#   1) tools/build.sh exists and is executable
#   2) Script syntax-checks (bash -n) without errors
#   3) Script accepts --help without error
#   4) Script rejects unknown arguments with exit code 5
#   5) Script reports missing godot when GODOT_BIN is not in PATH
#   6) Script reports missing export_presets when godot is available
#      but presets file does not exist
#   7) exit codes map correctly to documented values (1=godot, 3=presets,
#      4=export-fail, 5=arg-err)

const BUILD_SH := "res://tools/build.sh"
const EXPECTED_HELP_LINE := "USAGE:"

func _run_bash(args: Array) -> Array:
    # Returns [stdout, exit_code]. Uses bash via OS.execute if available,
    # else returns empty (test best-effort on Windows / no bash).
    var script_path: String = ProjectSettings.globalize_path(BUILD_SH)
    var output: Array = []
    var cmd: String = "bash %s %s 2>&1; echo EXIT_CODE:$?" % [script_path, " ".join(args)]
    # OS.execute is not available in GUT headless. Use OS.read
    # fallback. If we can't run bash, skip the test with pending().
    var pipe_path: String = OS.get_environment("TEMP") + "/build_test_output.txt"
    var redirect_cmd: String = "%s > %s 2>&1; echo EXIT_CODE:$? >> %s" % [cmd, pipe_path, pipe_path]
    var rc: int = OS.execute("bash", ["-c", redirect_cmd])
    if rc != 0:
        return ["<OS.execute not available>", -1]
    var f: FileAccess = FileAccess.open(pipe_path, FileAccess.READ)
    if f == null:
        return ["<cannot read pipe>", -1]
    var content: String = f.get_as_text()
    f.close()
    # Extract exit code
    var exit_code: int = -1
    var lines: PackedStringArray = content.split("\n")
    for line in lines:
        if line.begins_with("EXIT_CODE:"):
            exit_code = int(line.substr(10))
            break
    return [content, exit_code]

func test_build_sh_exists() -> void:
    var path: String = ProjectSettings.globalize_path(BUILD_SH)
    assert_true(FileAccess.file_exists(path), "tools/build.sh exists")

func test_build_sh_syntax_valid() -> void:
    var path: String = ProjectSettings.globalize_path(BUILD_SH)
    var rc: int = OS.execute("bash", ["-n", path])
    assert_eq(rc, 0, "bash -n syntax check passes (no script errors)")

func test_build_sh_help_works() -> void:
    var result: Array = _run_bash(["--help"])
    var content: String = result[0]
    var exit_code: int = result[1]
    if exit_code == -1:
        pending("OS.execute unavailable; cannot run shell test")
        return
    assert_eq(exit_code, 0, "--help exits 0")
    assert_true(content.contains(EXPECTED_HELP_LINE), "--help output contains USAGE")

func test_build_sh_rejects_unknown_arg() -> void:
    var result: Array = _run_bash(["bogus"])
    var exit_code: int = result[1]
    if exit_code == -1:
        pending("OS.execute unavailable")
        return
    assert_eq(exit_code, 5, "unknown arg exits 5")

func test_build_sh_errors_when_godot_missing() -> void:
    # Run with PATH cleared and GODOT_BIN pointing at non-existent
    # binary. Should exit 1 (godot not found).
    var path: String = ProjectSettings.globalize_path(BUILD_SH)
    var cmd: String = "PATH=/usr/bin:/bin GODOT_BIN=/nonexistent/godot bash %s 2>&1; echo EXIT_CODE:$?" % path
    var pipe_path: String = OS.get_environment("TEMP") + "/build_test_missing.txt"
    var redirect_cmd: String = "%s > %s 2>&1; echo EXIT_CODE:$? >> %s" % [cmd, pipe_path, pipe_path]
    var rc: int = OS.execute("bash", ["-c", redirect_cmd])
    if rc != 0:
        pending("OS.execute unavailable")
        return
    var f: FileAccess = FileAccess.open(pipe_path, FileAccess.READ)
    if f == null:
        pending("cannot read pipe")
        return
    var content: String = f.get_as_text()
    f.close()
    var exit_code: int = -1
    for line in content.split("\n"):
        if line.begins_with("EXIT_CODE:"):
            exit_code = int(line.substr(10))
            break
    assert_eq(exit_code, 1, "godot not found -> exit 1")
    assert_true(content.contains("godot binary"), "error message mentions godot binary")

func test_build_sh_errors_when_export_presets_missing() -> void:
    # Simulate godot available but export_presets.cfg missing.
    # Use GODOT_BIN=echo to satisfy the binary check; export_presets
    # check should fire next.
    var path: String = ProjectSettings.globalize_path(BUILD_SH)
    # Move export_presets.cfg out of the way (if it exists)
    var cwd: String = ProjectSettings.globalize_path("res://")
    var backup: String = cwd + "/export_presets.cfg.test_backup"
    var had_presets: bool = false
    if FileAccess.file_exists(cwd + "/export_presets.cfg"):
        DirAccess.rename_absolute(cwd + "/export_presets.cfg", backup)
        had_presets = true
    var cmd: String = "GODOT_BIN=echo bash %s 2>&1; echo EXIT_CODE:$?" % path
    var pipe_path: String = OS.get_environment("TEMP") + "/build_test_presets.txt"
    var redirect_cmd: String = "%s > %s 2>&1; echo EXIT_CODE:$? >> %s" % [cmd, pipe_path, pipe_path]
    var rc: int = OS.execute("bash", ["-c", redirect_cmd])
    if rc != 0:
        if had_presets:
            DirAccess.rename_absolute(backup, cwd + "/export_presets.cfg")
        pending("OS.execute unavailable")
        return
    var f: FileAccess = FileAccess.open(pipe_path, FileAccess.READ)
    if f == null:
        if had_presets:
            DirAccess.rename_absolute(backup, cwd + "/export_presets.cfg")
        pending("cannot read pipe")
        return
    var content: String = f.get_as_text()
    f.close()
    var exit_code: int = -1
    for line in content.split("\n"):
        if line.begins_with("EXIT_CODE:"):
            exit_code = int(line.substr(10))
            break
    # Restore export_presets.cfg
    if had_presets:
        DirAccess.rename_absolute(backup, cwd + "/export_presets.cfg")
    assert_eq(exit_code, 3, "export_presets missing -> exit 3")
    assert_true(content.contains("export_presets.cfg"), "error message mentions export_presets.cfg")
