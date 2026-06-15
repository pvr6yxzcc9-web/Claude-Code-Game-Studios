#!/usr/bin/env python3
"""
lint_resource_subclasses.py — CI guard for ADR-0008 closed Resource set.

ADR-0008 declares DATA Resource types as a CLOSED SET of 10 subtypes:
  1. WeaponData
  2. AmmoData
  3. EnemyData
  4. MechPartData
  5. ItemData
  6. EffectData
  7. TerminalLogData
  8. StoryFragmentData
  9. RegionData
  10. NPCData

Adding an 11th DATA Resource requires GDD + ADR update.

ADR-0008 also permits INFRASTRUCTURE Resource classes (base classes, helpers
that aren't gameplay data). These are exempted from the closed set but are
listed explicitly here so any new one is a deliberate decision.

This lint:
  1. Scans src/ for `extends Resource` (or `extends <ResourceName>`) classes.
  2. Verifies each one is in the APPROVED (data) or EXEMPT (infrastructure) list.
  3. Fails on any new Resource subclass not in either list.

Why this is a separate lint from the closed-set rule:
  The closed set is enforced structurally: ADR-0008 lists exactly 10 names,
  and adding an 11th triggers an explicit ADR amendment. This lint catches
  the case where someone forgets the ADR and adds a class anyway — the
  lint will fail and force them to either (a) remove the class, (b) move
  it to EXEMPT if it's infrastructure, or (c) update the ADR + APPROVED
  list if it's a new data Resource.

Exits 0 on pass, 1 on violation.

Usage:
  python tools/lint_resource_subclasses.py
"""
import os
import re
import sys

SKIP_DIRS = {".godot", "addons", ".git", "node_modules", ".import", ".claude", "production", "design", "docs", "data"}

# The 10 closed-set DATA Resource subtypes per ADR-0008.
APPROVED = {
    "WeaponData", "AmmoData", "EnemyData", "MechPartData", "ItemData",
    "EffectData", "TerminalLogData", "StoryFragmentData", "RegionData",
    "NPCData",
}

# INFRASTRUCTURE Resource classes (base classes, helpers — not data).
# Adding a new one here is a deliberate decision and should be justified
# in code with a doc comment explaining why it's infrastructure, not data.
EXEMPT = {
    "ImmutableResource",  # ADR-0007 base class for all 10 data subtypes
    "LevelData",           # chapter/region container (per level-dungeon.md)
    "DialogueTree",        # dialogue node graph (per npc-terminal.md)
}

# A class is a "Resource subclass" iff it does:
#   extends Resource
#   class_name <Foo>
#   extends <ApprovedSubtype>     # uncommon, but valid
# (or both extends Resource + class_name; this is the standard GDScript
#  pattern for a custom Resource).

def check_file(path: str) -> list:
    issues = []
    try:
        with open(path, "r", encoding="utf-8") as f:
            text = f.read()
    except (IOError, UnicodeDecodeError) as e:
        return [f"cannot read: {e}"]
    # Must extend Resource to be a Resource subclass.
    if not re.search(r"^extends\s+Resource\b", text, re.MULTILINE):
        return issues
    # Get class_name.
    m = re.search(r"^class_name\s+([A-Za-z_][A-Za-z0-9_]*)", text, re.MULTILINE)
    if not m:
        issues.append("extends Resource but has no class_name declaration")
        return issues
    name = m.group(1)
    if name in APPROVED:
        return issues
    if name in EXEMPT:
        return issues
    issues.append(
        f"`{name}` extends Resource but is not in the ADR-0008 closed set "
        f"of 10 APPROVED data subtypes ({', '.join(sorted(APPROVED))}) "
        f"nor in the EXEMPT infrastructure list ({', '.join(sorted(EXEMPT))}). "
        f"If this is a new data Resource: (1) update ADR-0008, (2) update "
        f"this lint's APPROVED list, (3) update resource-data.md GDD. "
        f"If this is infrastructure: (1) add to EXEMPT list with a doc "
        f"comment explaining why, (2) update this lint. Otherwise, remove "
        f"the class."
    )
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
        print("=== Resource Subclass Lint FAILED ===")
        for path, issues in problems.items():
            for issue in issues:
                print(f"  {path}: {issue}")
        print(f"\n{len(problems)} file(s) with issues.")
        sys.exit(1)
    else:
        print("=== Resource Subclass Lint OK ===")
        print(f"All `extends Resource` classes are in ADR-0008 closed set "
              f"({len(APPROVED)} data subtypes) or EXEMPT infrastructure list "
              f"({len(EXEMPT)} classes).")
        sys.exit(0)

if __name__ == "__main__":
    main()
