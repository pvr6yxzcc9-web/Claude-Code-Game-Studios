#!/usr/bin/env python3
"""
gen_ch1_rooms.py — Generate 10 Sat-1 room .tres files (S16-002).

Per level-dungeon.md: each satellite has 10 rooms. Rooms form a
connected graph via `exits`. Sat-1 = "The Drift Wreck" — derelict
cargo ship layout.

Layout (linear with side branches):
  c1_r1  → c1_r2  → c1_r3  → c1_r4  → c1_r5
                ↓                                ↓
              c1_r6  → c1_r7  → c1_r8  → c1_r9
                                                 ↓
                                              c1_r10 (boss: marrow_sentinel)

Themes:
  r1:  The Air Lock            — entry, tutorial
  r2:  Corridor of Lost Crew   — lore, 1 fragment
  r3:  Engineering Bay          — engineer NPC, repair
  r4:  Frozen Cargo Hold        — 2 enemies, fragment, cryo-tech
  r5:  Reactor Access            — lore
  r6:  Drone Hangar             — 2 drone enemies
  r7:  Manifest Vault           — lore, 1 fragment
  r8:  The Warden's Sanctum      — warden_construct boss-minion
  r9:  Marlow's Last Quarters   — first mate NPC, 1 fragment
  r10: The Inheritance Chamber  — boss arena (marrow_sentinel)

Output: data/levels/ch1/c1_r1..c1_r10.tres (10 files)
"""
import os

OUT_DIR = "data/levels/ch1"

# (room_id, display_name, description, enemies, npcs, terminals, fragments, exits, has_boss, decoy)
ROOMS = [
    # r1: tutorial entry
    ("c1_r1", "The Air Lock",
     "Standard air lock. The outer door is frozen shut. Frost on every surface. A single dim light flickers above the control panel.",
     [],  # no enemies (tutorial)
     ["ch1_derelict_captain"],
     [],
     [],
     ["c1_r2"], False, 0),

    # r2: corridor with lore terminal + 1 weak enemy
    ("c1_r2", "Corridor of the Lost Crew",
     "A long corridor. The walls are lined with emergency suits, all empty. The cold has preserved them. One suit is missing its helmet.",
     ["ch1_feral_scavenger"],
     [],
     ["log_sat1_manifest_v1"],
     ["fragment_ch1_1"],
     ["c1_r1", "c1_r3"], False, 0),

    # r3: engineering bay (engineer NPC + cargo bot)
    ("c1_r3", "Engineering Bay",
     "Workbenches covered in half-finished repairs. A welding torch still burns blue. The engineer has made this her home for twelve years.",
     ["ch1_cargo_bot"],
     ["ch1_salvage_engineer"],
     [],
     [],
     ["c1_r2", "c1_r4", "c1_r6"], False, 0),

    # r4: frozen cargo hold (lvl-up enemy, fragment, cryo-tech NPC)
    ("c1_r4", "Frozen Cargo Hold",
     "The cargo bay. The seals are cracked — welded twice, they say. The cold has preserved forty-two bodies in cryo-sleep. Some are still breathing.",
     ["ch1_frozen_crew", "ch1_drone_remnant"],
     ["ch1_frozen_cargo_tech"],
     ["log_sat1_manifest_v2"],
     ["fragment_ch1_3", "fragment_ch1_4"],
     ["c1_r3", "c1_r5"], False, 0),

    # r5: reactor access (medium enemy, fragment)
    ("c1_r5", "Reactor Access",
     "Catwalks over the reactor pit. The reactor is dark — been dark for years. But something keeps the cold. Something keeps the seals.",
     ["ch1_warden_construct"],
     [],
     ["log_sat1_manifest_v3"],
     ["fragment_ch1_2"],
     ["c1_r4", "c1_r7"], False, 0),

    # r6: drone hangar (drone enemies)
    ("c1_r6", "Drone Hangar",
     "Six bays for salvage drones. Two are open. The drones are autonomous now — they don't need crews to hunt.",
     ["ch1_drone_remnant", "ch1_drone_remnant"],
     [],
     [],
     [],
     ["c1_r3"], False, 0),

    # r7: manifest vault (lore + fragment, hollow_tech enemy)
    ("c1_r7", "The Manifest Vault",
     "The captain's safe. The manifest is here. Three pages of nothing. The truth is in the nothing. The nothing is the crew.",
     ["ch1_hollow_tech"],
     [],
     [],
     ["fragment_ch1_5"],
     ["c1_r5", "c1_r8"], False, 0),

    # r8: warden's sanctum (tough enemy)
    ("c1_r8", "The Warden's Sanctum",
     "The security golem hasn't moved in twelve years. It moves now. The cargo is awake. The cargo has been awake for years.",
     ["ch1_warden_construct", "ch1_hollow_tech"],
     [],
     [],
     [],
     ["c1_r7", "c1_r9"], False, 0),

    # r9: Marlow's last quarters (first mate NPC + fragment + tough enemy)
    ("c1_r9", "Marlow's Last Quarters",
     "Marlow's bunk. The pillow still has the shape of his head. He left in a hurry. He left for Sat-2. He left instructions.",
     ["ch1_frozen_crew"],
     ["ch1_marlow_first_mate"],
     ["log_sat1_marlow_note"],
     ["fragment_ch1_6", "fragment_ch1_7"],
     ["c1_r8", "c1_r10"], False, 0),

    # r10: boss arena (marrow_sentinel)
    ("c1_r10", "The Inheritance Chamber",
     "The deepest room. 苍穹号 is here. The pre-Rift vessel, intact. Waiting. The Marrow Sentinel stands at its door. The Sentinel was Marlow's first ship. The Sentinel remembers.",
     ["boss_marrow_sentinel"],
     [],
     [],
     [],
     ["c1_r9"], True, 0),  # has_boss=True
]


def make_tres(room_id: str, display_name: str, description: str,
             enemies: list, npcs: list, terminals: list, fragments: list,
             exits: list, has_boss: bool, decoy_count: int) -> str:
    """Generate a RoomData .tres file matching the ch3 schema."""
    def array_str(items: list, type_name: str = "StringName") -> str:
        if not items:
            return f"Array[{type_name}]([])"
        return "Array[" + type_name + "]([" + ", ".join(f"&\"{x}\"" for x in items) + "])"

    return f"""[gd_resource type="Resource" script_class="RoomData" load_steps=2 format=3 uid="uid://room_{room_id}"]

[ext_resource type="Script" path="res://src/resource/room_data.gd" id="1_room"]

[resource]
script = ExtResource("1_room")
id = &"{room_id}"
display_name = "{display_name}"
chapter = 1
description = "{description}"
tile_set = &"ch1"
enemy_encounters = {array_str(enemies)}
has_boss = {str(has_boss).lower()}
npcs = {array_str(npcs)}
terminals = {array_str(terminals)}
fragment_ids = {array_str(fragments)}
exits = {array_str(exits)}
decoy_count = {decoy_count}
"""


def main() -> int:
    os.makedirs(OUT_DIR, exist_ok=True)
    for r in ROOMS:
        path = os.path.join(OUT_DIR, f"{r[0]}.tres")
        with open(path, "w", encoding="utf-8") as f:
            f.write(make_tres(*r))
        print(f"  wrote {path} (enemies={len(r[4])}, npcs={len(r[5])}, boss={r[8]})")
    print(f"\nGenerated {len(ROOMS)} Sat-1 room .tres files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
