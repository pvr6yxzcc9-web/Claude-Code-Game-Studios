#!/usr/bin/env python3
"""
lint_npc_id_uniqueness.py — CI guard for ADR-0008 NPC id uniqueness.

ADR-0008 requires every NPCData has a unique `id: StringName` field.
If two NPCs share an id, the dialogue/encounter system can't tell them
apart and the player will get the wrong dialogue (this was a real risk
flagged in the Sprint 4 cross-review when adding 3 new NPCs in S4-006).

This lint:
  1. Scans all NPCData .tres files in data/npcs/ (Sprint 4 standard).
  2. Extracts the id field from each.
  3. Fails on any duplicate id.

Why scan .tres not .gd:
  NPCData is a Resource (ADR-0008 closed set), instances live as .tres
  files, and the id is set per-instance in the editor. Scanning .gd
  would only find the class definition, not the data.

Why not extend to all Resource types:
  Currently only NPCs are at risk for collision (multiple instances
  of the same subtype). Weapons, ammo, enemies, etc. have one instance
  per id and collisions are caught by the entity registry's
  load_resource validation (which would be a future lint).

Exits 0 on pass, 1 on violation.

Usage:
  python tools/lint_npc_id_uniqueness.py
"""
import os
import re
import sys
from collections import Counter

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(PROJECT_ROOT, "data", "npcs")

# A NPCData .tres file looks like:
#   [gd_resource type="NPCData" ...]
#   ...
#   id = &"marlow_ghost"
#   display_name = "..."
# ...
# The id field is what we check.

ID_RE = re.compile(r'^\s*id\s*=\s*&?"([^"&]+)"', re.MULTILINE)
RESOURCE_TYPE_RE = re.compile(r'type="(NPCData|Resource)"')

def main():
    if not os.path.isdir(DATA_DIR):
        print(f"ERROR: {DATA_DIR} directory not found")
        sys.exit(1)

    id_to_files = {}
    for entry in os.listdir(DATA_DIR):
        if not entry.endswith(".tres"):
            continue
        path = os.path.join(DATA_DIR, entry)
        with open(path, "r", encoding="utf-8") as f:
            text = f.read()
        # Skip non-NPCData resources.
        if not RESOURCE_TYPE_RE.search(text):
            continue
        m = ID_RE.search(text)
        if not m:
            print(f"  WARN: {entry} has no id field (skipping)")
            continue
        npc_id = m.group(1)
        id_to_files.setdefault(npc_id, []).append(entry)

    if not id_to_files:
        print(f"=== NPC ID Uniqueness Lint OK ===")
        print(f"No NPCData .tres files found in {DATA_DIR} (nothing to check).")
        sys.exit(0)

    errors = []
    counts = Counter(npc_id for npc_id in id_to_files)
    for npc_id, count in counts.items():
        if count > 1:
            files = id_to_files[npc_id]
            errors.append(
                f"duplicate NPC id `{npc_id}` in {count} files: {', '.join(files)}"
            )

    if errors:
        print("=== NPC ID Uniqueness Lint FAILED ===")
        for e in errors:
            print(f"  - {e}")
        sys.exit(1)
    else:
        print("=== NPC ID Uniqueness Lint OK ===")
        print(f"All {len(id_to_files)} NPCData .tres files have unique ids.")
        sys.exit(0)

if __name__ == "__main__":
    main()
