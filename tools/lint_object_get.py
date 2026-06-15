#!/usr/bin/env python3
"""
lint_object_get.py — CI guard for the S5-002/003/004 bug class.

Godot 4.6 has TWO `.get()` signatures:
  - Dictionary.get(key, default=null)  → 2 args OK
  - Object.get(property_name)         → 1 arg ONLY

Mixing these up is a parser error: "Too many arguments for 'get()' call.
Expected at most 1 but received 2." This bug was hidden in S5-002/003/004
because fc31 tests used Resource.new() as fixtures and the GUT headless
test runner was never executed (no Godot binary in dev env). The bug only
surfaced when a user pressed F5 in the editor — a classic
"headless-tests-pass-but-runtime-crashes" gap.

This lint scans all .gd files and flags any 2-arg `.get(...)` call where
the second argument is a non-None literal (heuristic: catch the most
common mistake, `obj.get("key", default)`).

Exits 0 on pass, 1 on violation.

Usage:
  python tools/lint_object_get.py
"""
import os
import re
import sys

SKIP_DIRS = {".godot", "addons", ".git", "node_modules", ".import", ".claude", "production", "design", "docs", "data"}

# Pattern: .get("key", VALUE)  where VALUE is non-null (the bug).
# We accept .get("key", null) because some codebases deliberately use
# the no-value pattern to fetch-then-check. (Still not idiomatic, but
# not the S5-002-class bug.)
PATTERN = re.compile(r'\.get\(\s*"[a-zA-Z_][a-zA-Z0-9_]*"\s*,\s*([a-zA-Z0-9_&\[\]\(\)\.\-]+)\s*\)')

# Common false-positive contexts (where 2-arg .get() is OK on Dictionary).
# We can't statically distinguish Dictionary from Object without type info,
# so we exempt Dictionary-typed identifiers by name (common local names).
DICT_LIKELY = {
    "node", "nodes", "snap", "parsed", "current_tree", "stats", "choice",
    "choices", "r", "ending_node", "bag", "data", "result", "row", "entry",
    "mod", "item", "record", "config", "settings", "props", "args",
    "kwargs", "params", "opts",
}

def check_file(path: str) -> list:
    issues = []
    try:
        with open(path, "r", encoding="utf-8") as f:
            for lineno, line in enumerate(f, 1):
                # Skip comment-only lines.
                stripped = line.strip()
                if stripped.startswith("#"):
                    continue
                # Find all matches on this line.
                for m in PATTERN.finditer(line):
                    # Extract the variable before `.get(`.
                    before = line[:m.start()]
                    # Find the most recent identifier before `.get(`.
                    id_match = re.search(r'([a-zA-Z_][a-zA-Z0-9_]*)\s*$', before)
                    if not id_match:
                        continue
                    var_name = id_match.group(1)
                    # Skip Dictionary-likely names.
                    if var_name in DICT_LIKELY:
                        continue
                    # Skip the safe helper.
                    if var_name == "_prop":
                        continue
                    second_arg = m.group(1).strip()
                    # null is OK (no value pattern).
                    if second_arg == "null":
                        continue
                    issues.append(
                        f"line {lineno}: `{var_name}.get(..., {second_arg})` — "
                        f"in Godot 4.6, `Object.get()` takes 1 arg. Use "
                        f"`{var_name}.get(key) if {var_name}.get(key) != null else {second_arg}` "
                        f"or use a typed Dictionary. (S5-002/003/004 bug class.)"
                    )
    except (IOError, UnicodeDecodeError) as e:
        return [f"cannot read: {e}"]
    return issues

def scan_dir(path: str) -> dict:
    problems = {}
    for entry in os.listdir(path):
        if entry.startswith(".") or entry in SKIP_DIRS:
            continue
        full = os.path.join(path, entry)
        if os.path.isdir(full):
            problems.update(scan_dir(full))
        elif entry.endswith(".gd"):
            issues = check_file(full)
            if issues:
                problems[full] = issues
    return problems

def main():
    target = "src"
    if not os.path.isdir(target):
        print(f"ERROR: {target} directory not found")
        sys.exit(1)
    problems = scan_dir(target)
    if problems:
        print("=== Object.get() 2-arg Lint FAILED ===")
        print("In Godot 4.6, Object.get() takes 1 arg. Use Dictionary if you need defaults.")
        print()
        for path, issues in problems.items():
            for issue in issues:
                print(f"  {path}: {issue}")
        print(f"\n{len(problems)} file(s) with issues.")
        sys.exit(1)
    else:
        print("=== Object.get() 2-arg Lint OK ===")
        print(f"No `Object.get(..., default)` calls found in {target}/.")
        sys.exit(0)

if __name__ == "__main__":
    main()
