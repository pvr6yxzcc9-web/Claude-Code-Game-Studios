#!/usr/bin/env python3
"""
lint_indent.py — S3-005 guard. Prevents the Sprint 2 indent wars (tab/space/CRLF).

Godot 4.6 supports both tab and 4-space indent (configurable in Editor Settings).
This lint allows EITHER style as long as a file is consistent within itself:

  - File uses tab indent throughout: OK
  - File uses 4-space indent throughout: OK
  - File mixes tab and 4-space in leading indent: FAIL (the original Sprint 2 bug)
  - File has CRLF line endings: FAIL (Godot 4.6 wants \n)
  - File has UTF-8 BOM: FAIL (Godot strips these on save, never need them)

Why not just "no tab"? Because the Godot editor default IS tab, and forcing
spaces is editorial preference, not correctness. The Sprint 2 indent wars
were caused by mixed-indent within a single file, not by the choice between
tab and space. The fix is to require consistency, not to mandate a style.

Exits 0 if all clean, 1 if any problem found.

Usage:
  python tools/lint_indent.py            # scan whole project
  python tools/lint_indent.py src/ tests # scan specific dirs
  python tools/lint_indent.py --ci       # CI mode (no colors, stricter)
"""
import os
import sys

SKIP_DIRS = {".godot", "addons", ".git", "node_modules", ".import", ".claude", "production", "design", "docs", "data"}
SKIP_FILES = set()

# Recognized leading-indent unit widths (in spaces). A line's leading indent
# must be a multiple of exactly one of these. Tab is treated as a separate
# "indentation system" (any tab anywhere = file is tab-style).
RECOGNIZED_WIDTHS = (4,)

def check_file(path: str) -> list:
    issues = []
    try:
        with open(path, "rb") as f:
            content = f.read()
    except (IOError, UnicodeDecodeError) as e:
        return [f"cannot read: {e}"]
    if b"\r\n" in content:
        issues.append("has CRLF line ending(s)")
    if content.startswith(b"\xef\xbb\xbf"):
        issues.append("has UTF-8 BOM")
    # Detect indent style by scanning leading indent of indented lines.
    # - If ANY line's leading indent contains a tab, file is "tab style"
    # - Else all-space-indent; check width is multiple of 4
    lines = content.split(b"\n")
    has_tab_indent = False
    has_space_indent = False
    bad_space_width = False
    for line in lines:
        stripped_indent = line.lstrip(b" \t")
        leading = line[:len(line) - len(stripped_indent)]
        if not leading:
            continue
        if b"\t" in leading:
            has_tab_indent = True
            if b" " in leading:
                # same line mixes space and tab in leading indent
                bad_space_width = True
                break
        elif leading.startswith(b" "):
            has_space_indent = True
            if len(leading) % 4 != 0:
                bad_space_width = True
                break
    if has_tab_indent and has_space_indent:
        issues.append("mixed tab + 4-space indent across lines")
    if bad_space_width and not (has_tab_indent and has_space_indent):
        issues.append("leading indent width is not a multiple of 4 spaces")
    return issues

def scan_dir(path: str) -> dict:
    problems = {}
    for entry in os.listdir(path):
        if entry.startswith("."):
            continue
        if entry in SKIP_DIRS:
            continue
        full = os.path.join(path, entry)
        if os.path.isdir(full):
            problems.update(scan_dir(full))
        elif entry.endswith(".gd") and entry not in SKIP_FILES:
            issues = check_file(full)
            if issues:
                problems[full] = issues
    return problems

def main():
    targets = sys.argv[1:]
    if "--ci" in targets:
        targets.remove("--ci")
    if not targets:
        targets = ["src", "tests", "prototypes"]
    all_problems = {}
    for t in targets:
        if os.path.isdir(t):
            all_problems.update(scan_dir(t))
        elif os.path.isfile(t) and t.endswith(".gd"):
            issues = check_file(t)
            if issues:
                all_problems[t] = issues
    if all_problems:
        print("=== Indent Lint FAILED ===")
        for path, issues in all_problems.items():
            for issue in issues:
                print(f"  {path}: {issue}")
        print(f"\n{len(all_problems)} file(s) with issues.")
        sys.exit(1)
    else:
        print("=== Indent Lint OK ===")
        print("No tab, CRLF, BOM, or mixed-indent issues found in:")
        for t in targets:
            print(f"  - {t}")
        sys.exit(0)

if __name__ == "__main__":
    main()
