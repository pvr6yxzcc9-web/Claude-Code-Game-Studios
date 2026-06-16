#!/usr/bin/env python3
"""
gen_ch5_data.py — Generate all Sat-5 (起源号) data .tres files (Sprint 10).
"""
import os

BOSS = {
	"id": "boss_creator",
	"display_name": "造物者本体",
	"hp": 5000,
	"attack": 50,
	"accuracy": 0.90,
	"sprite": "boss_creator.png",
	"phases": 5,
	"weaknesses": ["creator_signal"],
	"resistances": [],
}

CHAPTER = {
	"id": "chapter5_origin",
	"display_name": "Chapter 5 — The Origin",
	"chapter_index": 5,
	"room_ids": ["c5_r1", "c5_r2", "c5_r3", "c5_r4", "c5_r5", "c5_r6", "c5_r7", "c5_r8", "c5_r9", "c5_r10"],
	"boss_id": "boss_creator",
	"encounter_rate": 0.30,
	"description": "The Creator's origin. The cycle began here. The cycle ends here.",
}

ROOMS = [
	("c5_r1", "The Antechamber", 13, "Gold inlaid walls. The air hums.", ["c5_r2"], [], [], [], ["log_ch5_arrival"], 0, False),
	("c5_r2", "The Memory Vault", 13, "Holographic records of the Creator's experiments.", ["c5_r1", "c5_r3"], [], [], ["fragment_ch5_1"], ["log_ch5_memory"], 0, False),
	("c5_r3", "The Empty Throne", 13, "A throne. No one sits. The dust is perfect.", ["c5_r2", "c5_r4"], [], [], ["fragment_ch5_2"], [], 0, False),
	("c5_r4", "The Mural", 13, "A wall shows the 5 satellites. They pulse.", ["c5_r3", "c5_r5"], [], [], ["fragment_ch5_3"], ["log_ch5_mural"], 0, False),
	("c5_r5", "The Resting Place", 13, "A mech cockpit. Damaged. Inside, a body.", ["c5_r4", "c5_r6"], ["ch5_cangqiong_deceased"], [], ["fragment_ch5_4"], [], 0, False),
	("c5_r6", "The Echo Hall", 13, "Your voices return to you. Older. Tired.", ["c5_r5", "c5_r7", "c5_r8"], [], [], [], [], 0, False),
	("c5_r7", "The Mirror Room", 13, "You see yourself. Older. Without you.", ["c5_r6", "c5_r8"], ["ch5_ranger_father"], [], ["fragment_ch5_5"], [], 0, False),
	("c5_r8", "The Garden of Frozen Mothers", 13, "Frostbite's mother, half-human, half-fragment.", ["c5_r6", "c5_r7", "c5_r9"], ["ch5_frostbite_mother", "ch5_bomber_father"], [], ["fragment_ch5_6"], [], 0, False),
	("c5_r9", "The Creator's Door", 13, "A door. Behind it, the answer.", ["c5_r8", "c5_r10"], [], [], ["fragment_ch5_7"], [], 0, False),
	("c5_r10", "The Creator's Chamber", 13, "Vast. Golden. Silent. The Creator waits.", ["c5_r9"], [], ["boss_creator"], [], [], 0, True),
]

FRAGMENTS = [
	("fragment_ch5_1", "The First Question", "The Creator asked itself: am I alone? It built 5 satellites to hear its own echo.", "Unknown", 1),
	("fragment_ch5_2", "The Answer (Cycle 1)", "In the first cycle, the satellites answered: we are you.", "Creator Log 1", 2),
	("fragment_ch5_3", "The Answer (Cycle 2)", "In the second cycle, the satellites answered: we are not you.", "Creator Log 2", 2),
	("fragment_ch5_4", "苍穹号's Last Letter", "I heard the signal. I know the answer. It is not destruction. It is speech.", "苍穹号", 2),
	("fragment_ch5_5", "The Wanderer's Warning", "Do not seek the answer by force. The answer is not a weapon.", "Wanderer", 1),
	("fragment_ch5_6", "Mei's Final Truth", "Pluto was a child. Its death was a choice. I honor it by living.", "Mei Zhang", 1),
	("fragment_ch5_7", "The Inheritance", "You carry our voices. Speak, when the time comes.", "All Truths", 2),
]

NPCS = [
	("ch5_cangqiong_deceased.tres", "ch5_cangqiong_deceased", "苍穹号 (遗骸)", "ch5_cangqiong_deceased.png", "chapter5_origin", "lore_keeper", 3),
	("ch5_ranger_father.tres", "ch5_ranger_father", "漫游者之父 (幽灵)", "ch5_ranger_father.png", "chapter5_origin", "ambient", 2),
	("ch5_frostbite_mother.tres", "ch5_frostbite_mother", "霜尾之母", "ch5_frostbite_mother.png", "chapter5_origin", "ambient", 2),
	("ch5_bomber_father.tres", "ch5_bomber_father", "轰天之父 (幽灵)", "ch5_bomber_father.png", "chapter5_origin", "ambient", 2),
]

def write_boss():
	path = "data/enemies/boss_creator.tres"
	weak_str = ", ".join(f'&"{w}"' for w in BOSS["weaknesses"])
	res_str = ", ".join(f'&"{r}"' for r in BOSS["resistances"])
	content = f"""[gd_resource type="Resource" script_class="EnemyData" load_steps=3 format=3 uid="uid://enemy_boss_creator"]

[ext_resource type="Script" path="res://src/resource/enemy_data.gd" id="1_enemy"]
[ext_resource type="Texture2D" path="res://assets/sprites/enemies/{BOSS['sprite']}" id="2_sprite"]

[resource]
script = ExtResource("1_enemy")
id = &"{BOSS['id']}"
display_name = "{BOSS['display_name']}"
sprite = ExtResource("2_sprite")
max_hp = {BOSS['hp']}
attack = {BOSS['attack']}
accuracy = {BOSS['accuracy']}
boss = true
boss_immune_to_one_shot = true
weaknesses = Array[StringName]([{weak_str}])
resistances = Array[StringName]([{res_str}])
drops = Array[Resource]([])
"""
	os.makedirs("data/enemies", exist_ok=True)
	with open(path, "w", encoding="utf-8") as f:
		f.write(content)
	print(f"  boss: boss_creator.tres")

def write_chapter():
	path = "data/levels/chapter5.tres"
	rooms_str = ", ".join(f'&"{r}"' for r in CHAPTER["room_ids"])
	content = f"""[gd_resource type="Resource" script_class="LevelData" load_steps=2 format=3 uid="uid://level_chapter5_001"]

[ext_resource type="Script" path="res://src/resource/level_data.gd" id="1_level"]

[resource]
script = ExtResource("1_level")
id = &"{CHAPTER['id']}"
display_name = "{CHAPTER['display_name']}"
chapter_index = {CHAPTER['chapter_index']}
room_ids = Array[StringName]([{rooms_str}])
boss_id = &"{CHAPTER['boss_id']}"
encounter_rate = {CHAPTER['encounter_rate']}
description = "{CHAPTER['description']}"
"""
	with open(path, "w", encoding="utf-8") as f:
		f.write(content)
	print(f"  chapter: chapter5.tres")

def write_room(rid, display_name, chapter, description, exits, npcs, enemies, fragments, terminals, decoy_count, has_boss):
	path = f"data/levels/ch5/{rid}.tres"
	exits_str = ", ".join(f'&"{e}"' for e in exits)
	npcs_str = ", ".join(f'&"{n}"' for n in npcs)
	enemies_str = ", ".join(f'&"{e}"' for e in enemies)
	fragments_str = ", ".join(f'&"{f}"' for f in fragments)
	terminals_str = ", ".join(f'&"{t}"' for t in terminals)
	content = f"""[gd_resource type="Resource" script_class="RoomData" load_steps=2 format=3 uid="uid://room_{rid}"]

[ext_resource type="Script" path="res://src/resource/room_data.gd" id="1_room"]

[resource]
script = ExtResource("1_room")
id = &"{rid}"
display_name = "{display_name}"
chapter = {chapter}
description = "{description}"
tile_set = &"ch5"
enemy_encounters = Array[StringName]([{enemies_str}])
has_boss = {str(has_boss).lower()}
npcs = Array[StringName]([{npcs_str}])
terminals = Array[StringName]([{terminals_str}])
fragment_ids = Array[StringName]([{fragments_str}])
exits = Array[StringName]([{exits_str}])
decoy_count = {decoy_count}
"""
	os.makedirs("data/levels/ch5", exist_ok=True)
	with open(path, "w", encoding="utf-8") as f:
		f.write(content)
	print(f"  room: {rid}.tres")

def write_fragment(fid, title, body, author, importance):
	path = f"data/fragments/{fid}.tres"
	body_esc = body.replace('"', '\\"')
	content = f"""[gd_resource type="Resource" script_class="StoryFragmentData" load_steps=2 format=3 uid="uid://fragment_{fid}"]

[ext_resource type="Script" path="res://src/resource/story_fragment_data.gd" id="1_frag"]

[resource]
script = ExtResource("1_frag")
id = &"{fid}"
title = "{title}"
body = "{body_esc}"
author = "{author}"
importance = {importance}
unlock_fragment_id = &"{fid}"
"""
	with open(path, "w", encoding="utf-8") as f:
		f.write(content)
	print(f"  fragment: {fid}.tres")

def write_npc(filename, id_, display_name, sprite, location, role, priority):
	path = f"data/npcs/{filename}"
	content = f"""[gd_resource type="Resource" script_class="NPCData" load_steps=3 format=3 uid="uid://npc_{id_}"]

[ext_resource type="Script" path="res://src/resource/npc_data.gd" id="1_npc"]
[ext_resource type="Texture2D" path="res://assets/sprites/npcs/{sprite}" id="2_portrait"]

[resource]
script = ExtResource("1_npc")
id = &"{id_}"
display_name = "{display_name}"
portrait = ExtResource("2_portrait")
faction = &"creator"
dialogue_tree_id = &"dlg_{id_}"
location = &"{location}"
role = &"{role}"
inventory_id = &""
description = "Sat-5 character."
priority = {priority}
"""
	with open(path, "w", encoding="utf-8") as f:
		f.write(content)
	print(f"  npc: {filename}")

if __name__ == "__main__":
	print("Generating Sat-5 (起源号) data files...")
	write_boss()
	write_chapter()
	for room in ROOMS:
		write_room(*room)
	for fid, title, body, author, importance in FRAGMENTS:
		write_fragment(fid, title, body, author, importance)
	for filename, id_, display_name, sprite, location, role, priority in NPCS:
		write_npc(filename, id_, display_name, sprite, location, role, priority)
	print("Done.")