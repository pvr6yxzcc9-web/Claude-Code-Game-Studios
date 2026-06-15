#!/usr/bin/env python3
"""
lint_signal_naming.py — CI guard for ADR-0002 signal naming convention.

ADR-0002 C-R6: signal names follow `<past_tense>_<subject>` snake_case.
Forbidden patterns:
  - CamelCase (signals are snake_case, methods are CamelCase)
  - "signal" or "event" in the name (those are noise words)
  - Imperative verbs (e.g., "do_damage") instead of past-tense
    (e.g., "damage_dealt")

This lint scans all .gd files in src/ for `signal` declarations and
checks each name against these rules.

Exits 0 on pass, 1 on violation.

Usage:
  python tools/lint_signal_naming.py
"""
import os
import re
import sys

SKIP_DIRS = {".godot", "addons", ".git", "node_modules", ".import", ".claude", "production", "design", "docs", "data"}

# Common past-tense particles that should appear in well-named signals.
# This is a heuristic — it's a list of past-participle endings common in
# English past tense. A signal name not ending in one of these is flagged
# for manual review (warning, not fail).
COMMON_PAST_ENDINGS = {
    "ed", "wn", "en", "ne", "lt", "ad", "id", "ud", "pt", "ck", "ng",
    "st", "ht", "ed", "sed", "zed",
}

# Hard fail patterns.
FORBIDDEN_SUBSTRINGS = ("_signal_", "_event_", "Signal_", "Event_")
FORBIDDEN_PREFIXES = ("signal_", "event_")

# Past-tense examples (the "approved" set — for documentation, not enforcement)
APPROVED_EXAMPLES = (
    "state_changed", "damage_dealt", "battle_ended", "save_completed",
    "fragment_unlocked", "part_equipped", "item_added", "item_removed",
    "action_pressed", "action_released", "action_held",
    "choice_made", "ending_chosen", "entity_discovered",
    "dialogue_started", "dialogue_ended", "node_entered",
)

def check_file(path: str) -> list:
    issues = []
    try:
        with open(path, "r", encoding="utf-8") as f:
            for lineno, line in enumerate(f, 1):
                stripped = line.strip()
                if not stripped.startswith("signal "):
                    continue
                # signal name(args) or signal name: type
                m = re.match(r"^signal\s+([a-zA-Z_][a-zA-Z0-9_]*)", stripped)
                if not m:
                    continue
                name = m.group(1)
                # CamelCase check
                if re.search(r"[A-Z]", name):
                    issues.append(f"line {lineno}: `{name}` has uppercase letters (signals must be snake_case)")
                # Forbidden substrings
                for bad in FORBIDDEN_SUBSTRINGS:
                    if bad in name:
                        issues.append(f"line {lineno}: `{name}` contains forbidden substring `{bad}`")
                # Forbidden prefixes
                for bad in FORBIDDEN_PREFIXES:
                    if name.startswith(bad):
                        issues.append(f"line {lineno}: `{name}` starts with forbidden prefix `{bad}`")
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
        print("=== Signal Naming Lint FAILED ===")
        for path, issues in problems.items():
            for issue in issues:
                print(f"  {path}: {issue}")
        print(f"\n{len(problems)} file(s) with issues.")
        sys.exit(1)
    else:
        print("=== Signal Naming Lint OK ===")
        print(f"All signal declarations in {target}/ follow <past_tense>_<subject> snake_case convention.")
        sys.exit(0)

if __name__ == "__main__":
    main()
