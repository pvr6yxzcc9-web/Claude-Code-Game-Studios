extends SceneTree

# Tab vs space diagnostic — scans all .gd files in project, reports indent issues.
# Run with: godot --headless --script tools/lint_indent.gd

const SOURCE_DIRS := ["src", "tests", "prototypes"]
const SKIP_DIRS := [".godot", "addons"]

func _init() -> void:
    print("=== Indent Diagnostic ===\n")
    var problems: int = 0
    for dir in SOURCE_DIRS:
        problems += _scan_dir(dir)
    print("\n=== Summary ===")
    if problems == 0:
        print("OK - no indent issues found.")
    else:
        print("FAIL - %d problem(s) found." % problems)
    quit(problems)

func _scan_dir(path: String) -> int:
    var count: int = 0
    var d := DirAccess.open(path)
    if d == null:
        return 0
    d.list_dir_begin()
    var entry: String = d.get_next()
    while entry != "":
        if entry.begins_with("."):
            entry = d.get_next()
            continue
        var full: String = path + "/" + entry
        if d.current_is_dir():
            var skip := false
            for s in SKIP_DIRS:
                if full.contains(s):
                    skip = true
                    break
            if not skip:
                count += _scan_dir(full)
        elif entry.ends_with(".gd"):
            count += _check_file(full)
        entry = d.get_next()
    d.list_dir_end()
    return count

func _check_file(path: String) -> int:
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null:
        return 0
    var content := f.get_as_text()
    f.close()
    var lines := content.split("\n")
    var has_tab := false
    var mixed_indent := false
    for i in lines.size():
        var line: String = lines[i]
        # Check for tabs
        if "\t" in line:
            has_tab = true
        # Check for mixed indent (both leading spaces and tabs on same line)
        if line.length() > 0 and (line[0] == " " or line[0] == "\t"):
            var leading := ""
            for c in line:
                if c == " " or c == "\t":
                    leading += c
                else:
                    break
            if " " in leading and "\t" in leading:
                mixed_indent = true
    if has_tab:
        print("[TAB] %s" % path)
        return 1
    if mixed_indent:
        print("[MIXED] %s" % path)
        return 1
    return 0
