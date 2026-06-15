#!/usr/bin/env python3
"""
gen_ch2_terminals.py — Create Ch2 terminal log .tres files (S6-102).

These are stored as TerminalLogData resources in data/fragments/log_*.tres.
Each terminal body_entered triggers a fragment unlock via TerminalController.

5 Ch2 terminals total:
  c2_terminal_who_remains      -> fragment_who_remains
  c2_terminal_crates           -> fragment_whats_in_the_crates
  c2_terminal_lurks            -> fragment_what_lurks_below
  c2_terminal_cryo_chamber     -> fragment_the_cryo_chamber  (hidden, behind breakable wall)
  c2_terminal_warden_knew      -> fragment_what_the_warden_knew
"""
import os

OUT_DIR = "data/fragments"
TERMINAL_SCRIPT = "[ext_resource type=\"Script\" path=\"res://src/resource/terminal_log_data.gd\" id=\"1_log\"]"

# Map terminal log_id -> (title, body, author, fragment_id, date)
TERMINALS = [
    ("log_who_remains",
     "CONVOY LOG // STATION 3",
     "Three in cryo. Two medics, one child. Names recorded. Will they wake? Unknown. The cold is good. The cold is forever.",
     "Eng. K. Voss",
     "Year 0",
     "fragment_who_remains"),
    ("log_whats_in_the_crates",
     "DRONE INVENTORY // STATION 7",
     "Cryo-chamber inventory: mismatch. Manifest says 4 occupants. Actual: 3 occupants. Lyra Marlow, age 12: listed CONTAINED, actual UNCONTAINED.",
     "Salvage Drone 7",
     "Year 1",
     "fragment_whats_in_the_crates"),
    ("log_what_lurks_below",
     "SCRATCHED NOTE // CORRIDOR 12",
     "The warden sealed herself in. Says the lower decks are too cold. Says the cold moves. Don't go down.",
     "Salvage Crew 4",
     "Year 2",
     "fragment_what_lurks_below"),
    ("log_the_cryo_chamber",
     "DAMAGED LOG // CHAMBER DOORWAY",
     "Chamber temp: -196C. Optimal for indefinite preservation. But the child wakes sometimes. Hears the warden. Hears the warden humming.",
     "Salvage Archive",
     "Year 3",
     "fragment_the_cryo_chamber"),
    ("log_what_the_warden_knew",
     "ETCHED WARNING // STATION 9",
     "The warden knows the convoy isn't coming back. Has known for years. Why does she still keep the cold? Who is she keeping cold for, if no one is coming?",
     "Unknown",
     "Year 4",
     "fragment_what_the_warden_knew"),
]

def write_terminal(fpath: str, log_id: str, title: str, body: str, author: str, date: str, frag_id: str) -> None:
    content = f"""[gd_resource type="Resource" script_class="TerminalLogData" load_steps=2 format=3 uid="uid://{log_id}_001"]

{TERMINAL_SCRIPT}

[resource]
script = ExtResource("1_log")
id = &"{log_id}"
title = "{title}"
body = "{body}"
author = "{author}"
date_in_world = "{date}"
unlock_fragment_id = &"{frag_id}"
importance = 3
"""
    with open(fpath, "w", encoding="utf-8") as f:
        f.write(content)

def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for log_id, title, body, author, date, frag_id in TERMINALS:
        path = os.path.join(OUT_DIR, f"{log_id}.tres")
        write_terminal(path, log_id, title, body, author, date, frag_id)
        print(f"  wrote {path}")
    print(f"\n{len(TERMINALS)} Ch2 terminal log(s) generated.")

if __name__ == "__main__":
    main()
