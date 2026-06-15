#!/usr/bin/env python3
"""
lint_boss_immunity.py — CI guard for ADR-0011 Damage Bounds.

ADR-0011 enforces two invariants on EnemyData boss resources:

  1. `boss = true` resources MUST have `boss_immune_to_one_shot = true`
     (per cross-review [3c-1] — bosses cannot be killed in a single
     attack; preserves Pillar 3 build-trial integrity).

  2. WeaponData `min_damage` and `max_damage` MUST be in [10, 480] (the
     canonical damage range, per cross-review [2b-4]). Combined with
     max ammo_mult (1.5) and max crit_mult (3.0), peak hit = 80 * 1.5 * 3.0
     = 360 + ammo effect bonus ~50 = 410, well under 480.

These bounds are enforced in `BattleMathLib.CalcDamage()` (boss immunity)
and `BattleMathLib.clamp_damage()` (canonical range). This lint catches
violations at the resource layer so balance issues surface in CI rather
than during F5.

Exits 0 on pass, 1 on violation.

Usage:
  python tools/lint_boss_immunity.py
"""
import os
import re
import sys

SKIP_DIRS = {".godot", "addons", ".git", "node_modules", ".import", ".claude", "production", "design", "docs", "data"}

# ADR-0011 canonical damage bounds
MIN_DAMAGE = 10
MAX_DAMAGE = 480

def check_weapon(path: str) -> list:
    """Validate WeaponData: min_damage, max_damage in [10, 480]."""
    issues = []
    try:
        with open(path, "r", encoding="utf-8") as f:
            text = f.read()
    except (IOError, UnicodeDecodeError) as e:
        return [f"cannot read: {e}"]
    # Check that this is a WeaponData .tres
    if 'script_class="WeaponData"' not in text:
        return issues
    # Find min_damage and max_damage lines
    min_m = re.search(r"^\s*min_damage\s*=\s*(\d+)\s*$", text, re.MULTILINE)
    max_m = re.search(r"^\s*max_damage\s*=\s*(\d+)\s*$", text, re.MULTILINE)
    if min_m:
        v = int(min_m.group(1))
        if v < MIN_DAMAGE or v > MAX_DAMAGE:
            issues.append(
                f"min_damage={v} is outside [{MIN_DAMAGE}, {MAX_DAMAGE}] "
                f"(per ADR-0011 canonical range)"
            )
    if max_m:
        v = int(max_m.group(1))
        if v < MIN_DAMAGE or v > MAX_DAMAGE:
            issues.append(
                f"max_damage={v} is outside [{MIN_DAMAGE}, {MAX_DAMAGE}] "
                f"(per ADR-0011 canonical range)"
            )
    if min_m and max_m and int(min_m.group(1)) > int(max_m.group(1)):
        issues.append(
            f"min_damage={min_m.group(1)} > max_damage={max_m.group(1)} (impossible range)"
        )
    return issues

def check_enemy(path: str) -> list:
    """Validate EnemyData: boss=True MUST have boss_immune_to_one_shot=True."""
    issues = []
    try:
        with open(path, "r", encoding="utf-8") as f:
            text = f.read()
    except (IOError, UnicodeDecodeError) as e:
        return [f"cannot read: {e}"]
    if 'script_class="EnemyData"' not in text:
        return issues
    # Find boss = true
    boss_m = re.search(r"^\s*boss\s*=\s*(\w+)\s*$", text, re.MULTILINE)
    if not boss_m or boss_m.group(1) != "true":
        return issues  # not a boss, skip
    # Find boss_immune_to_one_shot
    immune_m = re.search(
        r"^\s*boss_immune_to_one_shot\s*=\s*(\w+)\s*$", text, re.MULTILINE
    )
    if not immune_m:
        issues.append(
            "boss=true but no `boss_immune_to_one_shot` field. Per ADR-0011, "
            "bosses must be immune to one-shot kills (preserves Pillar 3)."
        )
    elif immune_m.group(1) != "true":
        issues.append(
            f"boss=true but boss_immune_to_one_shot={immune_m.group(1)}. "
            f"Per ADR-0011, boss MUST be immune to one-shot kills."
        )
    return issues

def scan_dir(path: str) -> dict:
    problems = {}
    if not os.path.isdir(path):
        return problems
    for entry in os.listdir(path):
        if entry.startswith(".") or entry in SKIP_DIRS:
            continue
        full = os.path.join(path, entry)
        if os.path.isdir(full):
            problems.update(scan_dir(full))
        elif entry.endswith(".tres"):
            issues = check_weapon(full) + check_enemy(full)
            if issues:
                problems[full] = issues
    return problems

def main():
    target = "data"
    if not os.path.isdir(target):
        print(f"ERROR: {target} directory not found")
        sys.exit(1)
    problems = scan_dir(target)
    if problems:
        print("=== Boss Immunity / Damage Bounds Lint FAILED ===")
        print("Per ADR-0011:")
        print("  - boss = true requires boss_immune_to_one_shot = true")
        print("  - weapon min_damage / max_damage in [10, 480]")
        print()
        for path, issues in problems.items():
            for issue in issues:
                print(f"  {path}: {issue}")
        print(f"\n{len(problems)} file(s) with issues.")
        sys.exit(1)
    else:
        print("=== Boss Immunity / Damage Bounds Lint OK ===")
        print(f"All EnemyData and WeaponData .tres in {target}/ comply with ADR-0011.")
        sys.exit(0)

if __name__ == "__main__":
    main()
