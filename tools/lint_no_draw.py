#!/usr/bin/env python3
"""
lint_no_draw.py — S3-006 guard. Prevents regression of S2-001 HiDPI crash.

Background (S2-001):
  Godot 4.6 + Vulkan + Intel Iris + 2x DPI scale crashes in
    func _draw() -> void:
        draw_string(ThemeDB.fallback_font, ...)
  The crash is in the HiDPI path. Solution: use real Label/ColorRect children.

This script scans src/ui/ and src/battle/ for:
  - any `func _draw(` override
  - any `draw_string(ThemeDB.fallback_font` call
  - any other `draw_string(` call (ThemeDB fallback is the documented crash site,
    but other font-less draw_string usages share the same risk)

Exits 0 if clean, 1 if any violation found.

Usage:
  python tools/lint_no_draw.py            # scan src/ui + src/battle
  python tools/lint_no_draw.py src/ui     # scan specific dir
  python tools/lint_no_draw.py --ci       # CI mode (no colors, stricter)
"""
import os
import re
import sys

SKIP_DIRS = {".godot", "addons", ".git", "node_modules", ".import", ".claude",
             "production", "design", "docs", "data", "autoload", "scene",
             "math", "resource", "tests", "prototypes"}
DEFAULT_TARGETS = ["src/ui", "src/battle"]

# Patterns that indicate a HiDPI-prone custom drawing path
PATTERNS = [
    (re.compile(r"^func\s+_draw\s*\("), "func _draw() override (use Label/ColorRect children instead)"),
    (re.compile(r"\bdraw_string\s*\(\s*ThemeDB\s*\.\s*fallback_font\b"), "draw_string(ThemeDB.fallback_font ...) - documented S2-001 HiDPI crash site"),
    (re.compile(r"\bdraw_string\s*\("), "draw_string(...) call (HiDPI risk; prefer Label nodes)"),
    (re.compile(r"\bdraw_char\s*\("), "draw_char(...) call (HiDPI risk; prefer Label nodes)"),
]


def check_file(path: str) -> list:
    issues = []
    try:
        with open(path, "r", encoding="utf-8") as f:
            for lineno, line in enumerate(f, 1):
                # Skip pure comment lines — they document the rule
                stripped = line.lstrip()
                if stripped.startswith("#"):
                    continue
                for pat, msg in PATTERNS:
                    if pat.search(line):
                        issues.append(f"line {lineno}: {msg}")
    except (IOError, UnicodeDecodeError) as e:
        return [f"cannot read: {e}"]
    return issues


def scan_dir(path: str) -> dict:
    problems = {}
    for entry in sorted(os.listdir(path)):
        if entry.startswith("."):
            continue
        full = os.path.join(path, entry)
        if os.path.isdir(full):
            if entry in SKIP_DIRS:
                continue
            problems.update(scan_dir(full))
        elif entry.endswith(".gd"):
            issues = check_file(full)
            if issues:
                problems[full] = issues
    return problems


def main():
    args = sys.argv[1:]
    if "--ci" in args:
        args.remove("--ci")
    if not args:
        args = DEFAULT_TARGETS
    all_problems = {}
    for t in args:
        if os.path.isdir(t):
            all_problems.update(scan_dir(t))
        elif os.path.isfile(t) and t.endswith(".gd"):
            issues = check_file(t)
            if issues:
                all_problems[t] = issues
        else:
            print(f"WARNING: skipping non-existent path: {t}")
    if all_problems:
        print("=== No-Draw Lint FAILED ===")
        print("S2-001 HiDPI crash fix: use real Label/ColorRect children, not custom _draw().")  # ASCII-only by design
        print("Found the following violations:")
        for path, issues in all_problems.items():
            for issue in issues:
                print(f"  {path}: {issue}")
        print(f"\n{len(all_problems)} file(s) with violations.")
        sys.exit(1)
    else:
        print("=== No-Draw Lint OK ===")
        print("No func _draw / draw_string / draw_char found in:")
        for t in args:
            print(f"  - {t}")
        sys.exit(0)


if __name__ == "__main__":
    main()
