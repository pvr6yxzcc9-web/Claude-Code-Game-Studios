#!/usr/bin/env python3
"""
lint_action_count.py — CI guard for ADR-0009 input action count.

ADR-0009 specifies the InputMap is a closed set: 47 actions in original spec,
52 after S5-008 backfill (battle_attack_slot1/2/3, codex, mech_cycle).

The YAML (design/registry/input-bindings.yaml) is the source-of-truth per
ADR-0009 — it declares the FULL 52-action target. The runtime artifact
(project.godot [input] section) is the dev-in-progress subset.

This lint enforces two contracts:
  1. HARD FAIL: project.godot has actions that are NOT in YAML (orphans).
     The reverse is OK during dev — actions get added to project.godot
     incrementally, and sync_input_bindings.py also catches orphans.
  2. WARNING: project.godot is missing N actions from YAML. This is
     expected during dev — it means the dev hasn't filled in all bindings
     yet. Becomes a ship-blocker if 0 actions are missing (i.e., parity
     reached). Output: info message, exit 0.

This is separate from sync_input_bindings.py: that lint checks naming
consistency (does every project.godot action exist in YAML?). This lint
checks the inverse — does every YAML action exist in project.godot? — and
also enforces the EXPECTED_TOTAL count on the YAML side itself (catches
YAML being out of sync with ADR-0009's closed-set spec).

Exits 0 on pass, 1 on hard-fail violation.

Usage:
  python tools/lint_action_count.py
"""
import os
import re
import sys

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
YAML_PATH = os.path.join(PROJECT_ROOT, "design", "registry", "input-bindings.yaml")
PROJECT_GODOT = os.path.join(PROJECT_ROOT, "project.godot")

# The expected total per ADR-0009 + S5-008 backfill.
# This is the "closed set" rule — adding an action requires updating
# this constant AND the YAML + player-input.md GDD.
EXPECTED_TOTAL = 52

def parse_yaml_actions(path: str) -> set:
    actions = set()
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            if line.startswith((" ", "\t", "#", "\n", "\r")):
                continue
            m = re.match(r"^([a-z_][a-z0-9_]*):\s*$", line)
            if m:
                actions.add(m.group(1))
    return actions

def parse_project_godot_actions(path: str) -> set:
    actions = set()
    in_input = False
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            stripped = line.strip()
            if stripped.startswith("["):
                in_input = (stripped == "[input]")
                continue
            if not in_input:
                continue
            m = re.match(r"^([a-z_][a-z0-9_]*)=" r"\{?", line)
            if m:
                actions.add(m.group(1))
    return actions

def main():
    if not os.path.exists(YAML_PATH):
        print(f"ERROR: YAML not found at {YAML_PATH}")
        sys.exit(1)
    if not os.path.exists(PROJECT_GODOT):
        print(f"ERROR: project.godot not found at {PROJECT_GODOT}")
        sys.exit(1)

    yaml_actions = parse_yaml_actions(YAML_PATH)
    godot_actions = parse_project_godot_actions(PROJECT_GODOT)

    print(f"YAML actions:   {len(yaml_actions)}")
    print(f"project.godot:  {len(godot_actions)}")
    print(f"EXPECTED total: {EXPECTED_TOTAL} (ADR-0009 + S5-008 backfill)")

    errors = []
    warnings = []

    # Hard rule 1: YAML must declare exactly EXPECTED_TOTAL actions.
    # If YAML has more or fewer, ADR-0009 is out of sync with this lint.
    if len(yaml_actions) != EXPECTED_TOTAL:
        errors.append(
            f"YAML count {len(yaml_actions)} != EXPECTED {EXPECTED_TOTAL}. "
            f"If you added an action, update EXPECTED_TOTAL in this lint "
            f"+ input-bindings.yaml SUMMARY + player-input.md GDD."
        )

    # Hard rule 2: project.godot must not have orphan actions (in project
    # but not in YAML). Catches the dev-side error of adding an action
    # that was never declared in the source-of-truth.
    orphans = godot_actions - yaml_actions
    for orphan in sorted(orphans):
        errors.append(
            f"project.godot action `{orphan}` is not declared in {YAML_PATH}. "
            f"Add to YAML or remove from project.godot."
        )

    # Soft rule: project.godot may be a subset of YAML during dev.
    # We WARN (not fail) on missing-from-project actions.
    missing = yaml_actions - godot_actions
    if missing:
        warnings.append(
            f"project.godot is missing {len(missing)} actions declared in YAML. "
            f"This is OK during dev (incremental binding fill-in). To reach "
            f"ship-readiness, sync project.godot to declare all 52 actions. "
            f"Sample missing: {sorted(missing)[:5]}{'...' if len(missing) > 5 else ''}"
        )

    if errors:
        print("\n=== Action Count Lint FAILED ===")
        for e in errors:
            print(f"  - {e}")
        for w in warnings:
            print(f"  WARN: {w}")
        sys.exit(1)
    else:
        print("\n=== Action Count Lint OK ===")
        print(f"YAML count matches ADR-0009 closed set ({EXPECTED_TOTAL}).")
        print(f"No orphan actions in project.godot.")
        for w in warnings:
            print(f"  WARN: {w}")
        sys.exit(0)

if __name__ == "__main__":
    main()
