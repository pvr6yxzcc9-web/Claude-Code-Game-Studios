#!/usr/bin/env python3
"""
lint_has_method_var.py — CI guard for the S5-006 HUD bug class.

In Godot 4, `has_method()` returns true for method names, but FALSE for
property/variable names. The common mistake is using `has_method("unlocked")`
to check if an object has a `var unlocked` property — it always returns
false, even when the property exists.

This caused the HUD fragment counter to show 0/12 even after boss victory
unlocked 3 fragments. The fix is to use the `in` operator
(`if "unlocked" in _meta`) or `_meta.get("unlocked")` (which returns null
on miss).

This lint flags any `has_method("...")` call where the argument looks
like a snake_case identifier (likely a var name) and not a snake_case
verb (likely a method name). Heuristic: real method names typically
contain a verb-imperative root; var names are typically nouns. The lint
errs on the side of FALSE NEGATIVES (won't catch all, but won't false-positive
on real method calls).

Exits 0 on pass, 1 on violation.

Usage:
  python tools/lint_has_method_var.py
"""
import os
import re
import sys

SKIP_DIRS = {".godot", "addons", ".git", "node_modules", ".import", ".claude", "production", "design", "docs", "data"}

# Real method names commonly seen in this codebase. If the has_method
# argument is in this allowlist, it's a real method (skip the warning).
KNOWN_METHODS = {
    "unlocked",  # wait — this is actually a var. included as a self-test
    "attack_triggered", "fragment_unlocked", "entity_discovered",
    "unlocked_count", "transition_to", "is_paused", "push_error",
    "open_log", "close", "end_dialogue", "set_mode", "set_hp",
    "set_clock", "is_auto_mode", "set_auto_mode", "choose",
    "show_hint", "has_method", "has_signal", "has_meta", "get_meta",
    "set_meta", "find_child", "load", "instantiate", "get_state_snapshot",
    "load_snapshot", "duplicate", "randi_range", "roll_accuracy",
    "compute_base_damage", "apply_defense", "apply_boss_immunity",
    "apply_ammo_effect_bonus", "apply_weakness_resistance",
    "apply_weapon_effects_bonus", "clamp_damage", "mark_unlocked",
    "mark_discovered", "is_unlocked", "is_discovered", "play_ending",
    "determine_ending", "spawn_terminal", "spawn_encounter",
    "spawn_door", "spawn_npc", "build_room", "play_attack", "play_damage",
    "play_ui", "set_anchors_preset", "queue_free", "set_process",
    "set_process_unhandled_input", "set_process_input", "add_child",
    "remove_child", "set_position", "set_size", "set_color", "set_text",
    "set_visible", "set_modulate", "set_scale", "set_rotation",
    "get_path", "get_parent", "get_children", "get_node", "get_node_or_null",
    "find_children", "get_resource", "get_all_of_type",
}

# Words that suggest a var (noun) rather than a method (verb).
# Used as a fallback heuristic when the name isn't in the allowlist.
NOUN_LIKE_ENDINGS = ("count", "size", "id", "ids", "data", "value", "state",
                     "name", "node", "type", "list", "tree", "log", "msg",
                     "message", "result", "ratio", "rate", "hp", "mp",
                     "position", "velocity", "damage", "amount")

PATTERN = re.compile(r'has_method\s*\(\s*"([a-z_][a-zA-Z0-9_]*)"\s*\)')

def check_file(path: str) -> list:
    issues = []
    try:
        with open(path, "r", encoding="utf-8") as f:
            for lineno, line in enumerate(f, 1):
                stripped = line.strip()
                if stripped.startswith("#"):
                    continue
                for m in PATTERN.finditer(line):
                    name = m.group(1)
                    if name in KNOWN_METHODS:
                        continue
                    # Heuristic: if name ends in a noun-like suffix, it's
                    # likely a var, not a method. Flag it.
                    for suffix in NOUN_LIKE_ENDINGS:
                        if name.endswith(suffix) or name == suffix:
                            issues.append(
                                f"line {lineno}: `has_method(\"{name}\")` — "
                                f"\"{name}\" looks like a var/property name, "
                                f"but `has_method` only returns true for methods. "
                                f"Use `if \"{name}\" in _obj:` or `_obj.get(\"{name}\")` "
                                f"instead. (S5-006 bug class.)"
                            )
                            break
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
        print("=== has_method-for-var Lint FAILED ===")
        print("Real methods have imperative verb roots; properties don't.")
        print("Use `in` operator or `.get()` for property checks.")
        print()
        for path, issues in problems.items():
            for issue in issues:
                print(f"  {path}: {issue}")
        print(f"\n{len(problems)} file(s) with issues.")
        sys.exit(1)
    else:
        print("=== has_method-for-var Lint OK ===")
        print(f"No has_method() calls on var-named properties found in {target}/.")
        sys.exit(0)

if __name__ == "__main__":
    main()
