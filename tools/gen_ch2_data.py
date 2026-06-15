#!/usr/bin/env python3
"""
gen_ch2_data.py — Generate Ch2 resource .tres files (S6-102 full).

Outputs:
  data/enemies/{frostling,glacier,shard_bot,ice_drone,frost_walker,crystal_sentinel}.tres
  data/enemies/boss_ice_warden.tres  (replaces the previous boss_ice_sentinel)
  data/npcs/{frost_engineer,ice_hermit,scavenger_leader,frost_drone}.tres + 4 dialogue trees
  data/fragments/fragment_{who_remains,whats_in_the_crates,what_lurks_below,
                          the_cryo_chamber,what_the_warden_knew,who_was_lyra,
                          the_lost_road}.tres
  data/levels/chapter2.tres  (overwrites with 10 rooms)
"""
import os

ENEMY_DIR = "data/enemies"
NPC_DIR = "data/npcs"
FRAG_DIR = "data/fragments"
LEVEL_DIR = "data/levels"

ENEMY_SCRIPT = "[ext_resource type=\"Script\" path=\"res://src/resource/enemy_data.gd\" id=\"1_enemy\"]"
NPC_SCRIPT = "[ext_resource type=\"Script\" path=\"res://src/resource/npc_data.gd\" id=\"1_npc\"]"
DLG_SCRIPT = "[ext_resource type=\"Script\" path=\"res://src/resource/dialogue_tree.gd\" id=\"1_dlg\"]"
FRAG_SCRIPT = "[ext_resource type=\"Script\" path=\"res://src/resource/story_fragment_data.gd\" id=\"1_frag\"]"
LEVEL_SCRIPT = "[ext_resource type=\"Script\" path=\"res://src/resource/level_data.gd\" id=\"1_level\"]"

# === Enemies ===
# Stats: (id, display_name, max_hp, attack, accuracy, boss?, weak[], resist[])
ENEMIES = [
    ("frostling", "Frostling", 20, 5, 0.85, False, ["burn"], ["basic_cell"]),
    ("glacier", "Glacier", 50, 10, 0.75, False, ["plasma_rounds"], ["basic_cell"]),
    ("shard_bot", "Shard Bot", 35, 14, 0.80, False, ["burn", "rail_rounds"], []),
    ("ice_drone", "Ice Drone", 25, 8, 0.90, False, ["plasma_rounds"], []),
    ("frost_walker", "Frost Walker", 60, 12, 0.70, False, ["burn"], ["basic_cell", "rail_rounds"]),
    ("crystal_sentinel", "Crystal Sentinel", 80, 16, 0.75, False, ["plasma_rounds", "burn"], ["rail_rounds"]),
    ("boss_ice_warden", "Ice Warden", 250, 22, 0.80, True, ["burn", "plasma_rounds"], ["basic_cell"]),
]

# === NPCs + dialogues ===
NPCS = [
    ("frost_engineer", "Frost Engineer Rhea",
        "A salvage engineer in a heavy frost suit, maintaining the cryo-chamber. Speaks slowly, methodically.",
        "dlg_frost_engineer", "lore_keeper", 4,
        "The cryo-chamber must be cold. The family inside must sleep. If you wake them, you kill them. If you let them sleep, they die anyway. There is no good answer. I am the engineer. I keep the cold.",
        [{"label": "Who is in the chamber?", "next": "chamber"}],
        {
            "chamber": "Three of the convoy leadership. Their daughter Lyra. Two medics. The warden knows. Ask her.",
        },
        1, "engineer_chamber"),
    ("ice_hermit", "Old Hermit Vex",
        "A wizened figure in frost-blue robes. Speaks in riddles, sometimes lucid. Lives in the upper corridors.",
        "dlg_ice_hermit", "ambient", 2,
        "I came here to forget. The cold helps. The cold also remembers for you, if you let it. The warden is a liar. The warden is also the only one who can save you. Both can be true.",
        [{"label": "What do you remember?", "next": "memory"}],
        {
            "memory": "The day the convoy stopped. The day the cryo-chamber sealed. The day I stopped counting. That was three years ago, or thirty, or one. Time is a poor guest here.",
        },
        2, "hermit_memory"),
    ("scavenger_leader", "Scavenger Leader Torvin",
        "A pragmatic leader in a bandana and armored vest, runs a small crew of salvagers. Speaks bluntly.",
        "dlg_scavenger_leader", "merchant", 3,
        "I run the crew. We take from the dead and give to the living. The warden is alive, technically. We don't bother her. She bothers us. The crates you want are the ones we don't touch.",
        [{"label": "What's in the crates?", "next": "crates"}],
        {
            "crates": "Family. Three people. One kid. Sleeping until someone figures out how to wake them up. The warden would rather they stay asleep. Forever. Take that as you will.",
        },
        3, "leader_crates"),
    ("frost_drone", "Salvage Drone 7",
        "A maintenance drone with a single glowing eye. Speaks in clipped, machine-like phrases.",
        "dlg_frost_drone", "merchant", 2,
        "Drone. Active. Task: inventory. Result: incomplete. The cryo-chamber inventory does not match the manifest. Three bodies inside, manifest says four. One missing.",
        [{"label": "Who is missing?", "next": "missing"}],
        {
            "missing": "Lyra Marlow. Age 12. Listed as: contained. Actual: uncontained. The warden knows. The warden does not say.",
        },
        0, "drone_missing"),
]

# === Fragments ===
FRAGMENTS = [
    ("fragment_who_remains", "Who Remains",
        "You find a log terminal. The previous engineer recorded: 'Three in cryo. Two medics, one child. Names recorded. Will they wake? Unknown.'"),
    ("fragment_whats_in_the_crates", "What's in the Crates",
        "Salvage drone log: 'Cryo-chamber inventory mismatch. Three bodies contained, manifest says four. Lyra Marlow: missing.'"),
    ("fragment_what_lurks_below", "What Lurks Below",
        "A scratched note in a corridor: 'The warden sealed herself in. Says the lower decks are too cold. Says the cold moves. Don't go down.'"),
    ("fragment_the_cryo_chamber", "The Cryo Chamber",
        "A damaged log near the chamber door: 'Chamber temp -196C. Optimal for indefinite preservation. But the child wakes sometimes. Hears the warden. Hears the warden humming.'"),
    ("fragment_what_the_warden_knew", "What the Warden Knew",
        "A warning, etched into metal: 'The warden knows the convoy isn't coming back. Has known for years. Why does she still keep the cold?'"),
    ("fragment_who_was_lyra", "Who Was Lyra",
        "A child's drawing on a corridor wall. Three stick figures in a box. A sun outside. The word 'home.'"),
    ("fragment_the_lost_road", "The Lost Road",
        "Last log of the convoy's captain: 'If anyone finds this, the road is gone. We were too slow. The cold is faster than us. Stay. Sleep. Forget.'"),
]

def write_enemy(fpath: str, eid: str, display: str, hp: int, atk: int, acc: float,
                boss: bool, weak: list, resist: list) -> None:
    weak_str = ", ".join(f"&\"{w}\"" for w in weak)
    resist_str = ", ".join(f"&\"{r}\"" for r in resist)
    weak_arr = f"Array[StringName]([{weak_str}])" if weak else "Array[StringName]()"
    resist_arr = f"Array[StringName]([{resist_str}])" if resist else "Array[StringName]()"
    content = f"""[gd_resource type="Resource" script_class="EnemyData" load_steps=2 format=3 uid="uid://{eid}_001"]

{ENEMY_SCRIPT}

[resource]
script = ExtResource("1_enemy")
id = &"{eid}"
display_name = "{display}"
max_hp = {hp}
attack = {atk}
accuracy = {acc:.2f}
boss = {str(boss).lower()}
boss_immune_to_one_shot = {str(boss).lower()}
weaknesses = {weak_arr}
resistances = {resist_arr}
"""
    with open(fpath, "w", encoding="utf-8") as f:
        f.write(content)

def write_npc(fpath: str, eid: str, display: str, desc: str, dlg: str, role: str,
              priority: int) -> None:
    role_str = f"&\"{role}\""
    content = f"""[gd_resource type="Resource" script_class="NPCData" load_steps=2 format=3 uid="uid://{eid}_001"]

{NPC_SCRIPT}

[resource]
script = ExtResource("1_npc")
id = &"{eid}"
display_name = "{display}"
faction = &"frozen_reactor"
dialogue_tree_id = &"{dlg}"
location = &"frozen_reactor"
role = {role_str}
inventory_id = &""
description = "{desc}"
priority = {priority}
"""
    with open(fpath, "w", encoding="utf-8") as f:
        f.write(content)

def write_dialogue(fpath: str, eid: str, start: str, lines: dict) -> None:
    lines_str = ""
    for nid, ndata in lines.items():
        text = ndata["text"]
        choices = ndata.get("choices", [])
        choices_str = ""
        if choices:
            choices_list = ", ".join(f'{{"label": "{c["label"]}", "next": "{c["next"]}"}}' for c in choices)
            choices_str = f', "choices": [{choices_list}]'
        lines_str += f'\n&"{nid}": {{"text": "{text}"{choices_str}}},'
    content = f"""[gd_resource type="Resource" script_class="DialogueTree" load_steps=2 format=3 uid="uid://dlg_{eid}_001"]

{DLG_SCRIPT}

[resource]
script = ExtResource("1_dlg")
id = &"dlg_{eid}"
start_node_id = &"{start}"
nodes = {{{lines_str}
}}
"""
    with open(fpath, "w", encoding="utf-8") as f:
        f.write(content)

def write_fragment(fpath: str, eid: str, title: str, text: str) -> None:
    content = f"""[gd_resource type="Resource" script_class="StoryFragmentData" load_steps=2 format=3 uid="uid://{eid}_001"]

{FRAG_SCRIPT}

[resource]
script = ExtResource("1_frag")
id = &"{eid}"
display_name = "{title}"
text = "{text}"
related_fragment_ids = Array[StringName]([])
"""
    with open(fpath, "w", encoding="utf-8") as f:
        f.write(content)

def write_chapter2() -> None:
    rooms = ", ".join(f"&\"c2_r{i}\"" for i in range(1, 11))
    content = f"""[gd_resource type="Resource" script_class="LevelData" load_steps=2 format=3 uid="uid://level_chapter2_001"]

{LEVEL_SCRIPT}

[resource]
script = ExtResource("1_level")
id = &"chapter2_frozen_reactor"
display_name = "Chapter 2 — The Frozen Reactor"
chapter_index = 2
room_ids = Array[StringName]([{rooms}])
boss_id = &"boss_ice_warden"
encounter_rate = 0.4
description = "The abandoned cryo-reactor. The convoy is asleep. The warden keeps them cold. The road is gone. You are the only one who came."
"""
    with open(os.path.join(LEVEL_DIR, "chapter2.tres"), "w", encoding="utf-8") as f:
        f.write(content)

def main():
    os.makedirs(ENEMY_DIR, exist_ok=True)
    os.makedirs(NPC_DIR, exist_ok=True)
    os.makedirs(FRAG_DIR, exist_ok=True)

    # Remove the previous minimal boss
    old_boss = os.path.join(ENEMY_DIR, "boss_ice_sentinel.tres")
    if os.path.exists(old_boss):
        os.remove(old_boss)
        print(f"  removed old {old_boss}")

    # Enemies
    print("=== Enemies ===")
    for eid, display, hp, atk, acc, boss, weak, resist in ENEMIES:
        path = os.path.join(ENEMY_DIR, f"{eid}.tres")
        write_enemy(path, eid, display, hp, atk, acc, boss, weak, resist)
        print(f"  wrote {path}")

    # NPCs (NPCS has 9 fields per tuple: eid, display, desc, dlg, role, priority, initial_text, followup_text, fragment_id)
    print("=== NPCs ===")
    for npc in NPCS:
        eid, display, desc, dlg, role, priority = npc[0], npc[1], npc[2], npc[3], npc[4], npc[5]
        path = os.path.join(NPC_DIR, f"{eid}.tres")
        write_npc(path, eid, display, desc, dlg, role, priority)
        print(f"  wrote {path}")

    # Dialogues
    print("=== Dialogues ===")
    for npc in NPCS:
        eid, dlg, initial, followup = npc[0], npc[3], npc[6], npc[7]
        nodes = {eid: {"text": initial, "choices": [{"label": "Continue", "next": "followup"}]},
                 "followup": {"text": followup, "choices": []}}
        path = os.path.join(NPC_DIR, f"{dlg}.tres")
        write_dialogue(path, dlg.replace("dlg_", ""), eid, nodes)
        print(f"  wrote {path}")

    # Fragments
    print("=== Fragments ===")
    for eid, title, text in FRAGMENTS:
        path = os.path.join(FRAG_DIR, f"{eid}.tres")
        write_fragment(path, eid, title, text)
        print(f"  wrote {path}")

    # Chapter 2 level
    print("=== Chapter 2 level data ===")
    write_chapter2()
    print(f"  wrote {os.path.join(LEVEL_DIR, 'chapter2.tres')}")

    print("\nAll Ch2 .tres data files generated.")

if __name__ == "__main__":
    main()
