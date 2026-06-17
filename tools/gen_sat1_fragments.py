#!/usr/bin/env python3
"""
gen_sat1_fragments.py — Generate 7 Sat-1 truth fragments (S15-004).

Per multi-satellite-arc.md: 7 fragments per satellite × 5 satellites
= 35 total. Sat-1 (prologue) covers the Marrow derelict arc.

Themes:
  1. Captain's log — first sign of trouble
  2. Cargo manifest — the lie
  3. Crew count — 42 vs. expected
  4. The cold — what really happened
  5. The seals — what cracked
  6. Marlow's departure — why he left
  7. The inheritance — 苍穹号

Output: data/fragments/fragment_ch1_{1..7}.tres

Run from project root:
  python tools/gen_sat1_fragments.py
"""
import os

OUT_DIR = "data/fragments"

FRAGMENTS = [
    {
        "id": "fragment_ch1_1",
        "title": "Captain's Log, Day 0",
        "body": "Convoy departed at 0400. Forty-two crew aboard. Manifest shows generic salvage. Cold storage active. The cargo hold is sealed. As it should be. As it always has been.",
        "author": "Captain D. Vance",
        "importance": 1,
    },
    {
        "id": "fragment_ch1_2",
        "title": "The Empty Manifest",
        "body": "The manifest says: nothing. Three pages of nothing. Forty-two crew listed as 'salvage specialists.' No cargo description. No cargo weight. The manifest is a lie. The convoy knew.",
        "author": "First Mate Marlow",
        "importance": 2,
    },
    {
        "id": "fragment_ch1_3",
        "title": "Forty-Two",
        "body": "Forty-two of us. That's what the captain said. That's what the manifest says. But I counted. There are forty-three people on this ship. The forty-third doesn't speak. The forty-third doesn't eat. The forty-third is in the hold.",
        "author": "Eng. R. Kowalski",
        "importance": 2,
    },
    {
        "id": "fragment_ch1_4",
        "title": "The Cold",
        "body": "The cold isn't the weather. The cold is what's in the hold. The seals cracked at year three. The cold got in. The cold got us. We are the cargo. We are the warning. We are what's preserved.",
        "author": "Cryo-Tech L. Park",
        "importance": 3,
    },
    {
        "id": "fragment_ch1_5",
        "title": "The Seals",
        "body": "Year five. The seals cracked from inside. We welded them. Year eight. The seals cracked again. We welded them again. Year twelve. The seals cracked a third time. We stopped welding. Whatever's in the hold, it's not waiting anymore.",
        "author": "Captain D. Vance",
        "importance": 3,
    },
    {
        "id": "fragment_ch1_6",
        "title": "Marlow's Departure",
        "body": "I left because I knew. Twenty years I kept the secret. The cargo is the crew. The crew is the cargo. The inheritance is the answer. Find me on Sat-2. I'll know the manifest is real.",
        "author": "First Mate Marlow (departure note)",
        "importance": 4,
    },
    {
        "id": "fragment_ch1_7",
        "title": "The Inheritance",
        "body": "苍穹号 — a pre-Rift vessel, intact, on the upper decks. Marlow found it. Marlow left instructions. The inheritance is yours if you can get out of here alive. Welcome to the cold.",
        "author": "First Mate Marlow (final transmission)",
        "importance": 5,
    },
]


def make_tres(frag: dict) -> str:
    return f"""[gd_resource type="Resource" script_class="StoryFragmentData" load_steps=2 format=3 uid="uid://fragment_{frag['id']}"]

[ext_resource type="Script" path="res://src/resource/story_fragment_data.gd" id="1_frag"]

[resource]
script = ExtResource("1_frag")
id = &"{frag['id']}"
title = "{frag['title']}"
body = "{frag['body']}"
author = "{frag['author']}"
importance = {frag['importance']}
unlock_fragment_id = &"{frag['id']}"
"""


def main() -> int:
    os.makedirs(OUT_DIR, exist_ok=True)
    for frag in FRAGMENTS:
        path = os.path.join(OUT_DIR, f"{frag['id']}.tres")
        with open(path, "w", encoding="utf-8") as f:
            f.write(make_tres(frag))
        print(f"  wrote {path}")
    print(f"\nGenerated {len(FRAGMENTS)} Sat-1 truth fragments")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
