#!/usr/bin/env python3
"""
lint_autoload_order.py — S5-008 guard. Enforces ADR-0001 autoload order.

Per ADR-0001, the 5 core autoloads MUST load in this order:
  1. GameStateMachine (owns the state stack)
  2. InputBus (queries GameStateMachine.top_of_stack)
  3. ResourceRegistry (loads all .tres files)
  4. MetaState (per-entity discovery tracking)
  5. SaveManager (depends on all of the above)

The remaining autoloads (WeaponLoadout, Inventory, MechLoadout,
TerminalController, DialogueManager, ResourceIntegrity, SFXPlayer,
EndingController) can be in any order AFTER SaveManager.

Exits 0 if order is valid, 1 if any violation.

Usage:
  python tools/lint_autoload_order.py
  python tools/lint_autoload_order.py --ci
"""
import os
import re
import sys

# The 5 autoloads whose relative order is fixed by ADR-0001
REQUIRED_ORDER: list[str] = [
    "GameStateMachine",
    "InputBus",
    "ResourceRegistry",
    "MetaState",
    "SaveManager",
]


def read_autoload_order(project_godot: str) -> list[str]:
    """Parse the [autoload] section of project.godot and return autoload
    names in declaration order (excluding comments and blank lines)."""
    if not os.path.isfile(project_godot):
        print(f"ERROR: {project_godot} not found")
        sys.exit(1)
    order: list[str] = []
    in_autoload = False
    with open(project_godot, "r", encoding="utf-8") as f:
        for line in f:
            stripped = line.strip()
            if stripped == "[autoload]":
                in_autoload = True
                continue
            if in_autoload:
                if stripped.startswith("["):
                    # Next section starts
                    break
                if not stripped or stripped.startswith(";"):
                    continue
                # Parse "Name=\"*res://...\""
                m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*)="', stripped)
                if m:
                    order.append(m.group(1))
    return order


def lint(order: list[str]) -> list[str]:
    issues: list[str] = []
    if not order:
        return ["no autoloads found in project.godot [autoload] section"]
    # Check 1: GameStateMachine must be first
    if order[0] != "GameStateMachine":
        issues.append(
            f"GameStateMachine must be FIRST autoload (ADR-0001), got: {order[0]}"
        )
    # Check 2: the 5 required autoloads appear in the correct relative order
    positions: list[tuple[str, int]] = []
    for name in REQUIRED_ORDER:
        if name in order:
            positions.append((name, order.index(name)))
    # If any of the 5 are missing, that's a separate ADR violation
    missing = [n for n in REQUIRED_ORDER if n not in order]
    if missing:
        issues.append(f"missing required autoloads: {missing}")
    # Check ordering: positions should be strictly increasing
    for i in range(len(positions) - 1):
        n1, p1 = positions[i]
        n2, p2 = positions[i + 1]
        if p1 >= p2:
            issues.append(
                f"order violation: {n1} (pos {p1}) must come before {n2} (pos {p2})"
            )
    return issues


def main() -> int:
    args = sys.argv[1:]
    ci_mode = "--ci" in args
    args = [a for a in args if a != "--ci"]
    project_godot = args[0] if args else "project.godot"
    order = read_autoload_order(project_godot)
    issues = lint(order)
    if issues:
        print("=== Autoload Order Lint FAILED ===")
        print("Per ADR-0001, autoloads must load in this order:")
        for n in REQUIRED_ORDER:
            print(f"  {n}")
        print("\nCurrent order in project.godot:")
        for i, n in enumerate(order):
            marker = " <-- VIOLATION" if any(n in s for s in issues) else ""
            print(f"  {i}: {n}{marker}")
        print("\nIssues:")
        for issue in issues:
            print(f"  - {issue}")
        return 1
    else:
        print("=== Autoload Order Lint OK ===")
        print(f"All {len(REQUIRED_ORDER)} required autoloads in correct order. Total: {len(order)} autoloads.")
        return 0


if __name__ == "__main__":
    sys.exit(main())
