#!/usr/bin/env python3
"""
lint_typed_array_inference.py — CI guard for Godot 4.6 typed array invariance.

Godot 4.x typed arrays are INVARIANT. Assigning a narrower typed array to
a wider typed local variable is a parser error:

  var wider: Array[Node] = some_func_returning_Array[Node2D]  # ERROR

This is the same bug class as `Object.get()` 2-arg (also 4.6 strictness).
The breakable_wall.gd bug was: `var bodies: Array[Node] =
get_overlapping_bodies()` where `get_overlapping_bodies()` returns
`Array[Node2D]`. Both are Node-derived, but typed arrays don't allow
that conversion.

This lint scans for the common pattern:
  var <name>: Array[<TypeX>] = <expr>

…and flags assignments where the LHS type is wider than the RHS function
return type. The heuristic is intentionally narrow (function call RHS
only) because the most common occurrence is `var x: Array[W] =
obj.get_overlapping_bodies()` style — and those are the ones that crash
during F5.

Exits 0 on pass, 1 on violation.

Usage:
  python tools/lint_typed_array_inference.py
"""
import os
import re
import sys

SKIP_DIRS = {".godot", "addons", ".git", "node_modules", ".import", ".claude", "production", "design", "docs", "data"}

# Pattern: var NAME: Array[T] = <expr>
# We capture the LHS type T and the RHS expression.
PATTERN = re.compile(
    r"^\s*var\s+([a-z_][a-zA-Z0-9_]*)\s*:\s*Array\[([A-Z][a-zA-Z0-9_]*)\]\s*=\s*(.+)$"
)

# Functions known to return Array[Node2D] in Godot 4.6. (We only need the
# ones the project actually calls; extending this list as new 4.6 typed
# array methods are discovered is fine.)
RETURNS_ARRAY_NODE2D = {
    "get_overlapping_bodies",
    "get_children",  # returns Array[Node] actually; flagged by Node check below
}

RETURNS_ARRAY_NODE = {
    "get_children",
    "find_children",
}

def check_file(path: str) -> list:
    issues = []
    try:
        with open(path, "r", encoding="utf-8") as f:
            for lineno, line in enumerate(f, 1):
                stripped = line.strip()
                if stripped.startswith("#"):
                    continue
                m = PATTERN.match(line)
                if not m:
                    continue
                name, lhs_type, rhs = m.group(1), m.group(2), m.group(3).strip()
                # Empty literal RHS is fine.
                if rhs in ("[]", ""):
                    continue
                # Check function-call RHS.
                fn_match = re.match(r"^([a-zA-Z_][a-zA-Z0-9_.]*)\s*\(", rhs)
                if not fn_match:
                    continue
                fn_name = fn_match.group(1).split(".")[-1]
                # Heuristic: if LHS is Array[Node] and RHS is a known
                # Array[Node2D] returner, flag it.
                if lhs_type == "Node" and fn_name in RETURNS_ARRAY_NODE2D:
                    issues.append(
                        f"line {lineno}: `var {name}: Array[Node] = {fn_name}()` — "
                        f"`{fn_name}` returns Array[Node2D] in Godot 4.6; typed "
                        f"arrays are invariant. Use untyped `var {name}: Array = ...` "
                        f"or change type to `Array[Node2D]`."
                    )
                elif lhs_type == "Node2D" and fn_name in RETURNS_ARRAY_NODE:
                    # Inverse: LHS narrower, RHS wider. This is the opposite
                    # direction and is also a parser error in 4.6.
                    issues.append(
                        f"line {lineno}: `var {name}: Array[Node2D] = {fn_name}()` — "
                        f"`{fn_name}` returns Array[Node] in Godot 4.6; typed "
                        f"arrays are invariant. Use untyped `var {name}: Array = ...` "
                        f"or change type to `Array[Node]`."
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
        print("=== Typed Array Inference Lint FAILED ===")
        print("Godot 4.6 typed arrays are invariant — assign Array[Node2D] to Array[Node] is a parser error.")
        print()
        for path, issues in problems.items():
            for issue in issues:
                print(f"  {path}: {issue}")
        print(f"\n{len(problems)} file(s) with issues.")
        sys.exit(1)
    else:
        print("=== Typed Array Inference Lint OK ===")
        print(f"No typed-array invariance violations found in {target}/.")
        sys.exit(0)

if __name__ == "__main__":
    main()
