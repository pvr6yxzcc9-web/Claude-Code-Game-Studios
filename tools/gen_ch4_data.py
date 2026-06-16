#!/usr/bin/env python3
"""
gen_ch4_data.py — Generate all Sat-4 (断魂号 / Military) data .tres files (Sprint 9).

Outputs:
  data/enemies/ch4_*.tres (6 enemies)
  data/enemies/boss_pluto_remnant.tres (1 boss)
  data/npcs/ch4_*.tres (4 NPCs)
  data/levels/chapter4.tres (1 chapter header)
  data/levels/ch4/c4_r1.tres ... c4_r10.tres (10 room data files)
  data/fragments/fragment_ch4_1.tres ... 7.tres (7 Truth 4 fragments)
"""
import os

# === Enemies ===

ENEMIES = [
	# (filename, id, display_name, max_hp, attack, accuracy, sprite, weaknesses, resistances)
	("ch4_ai_remnant.tres", "ch4_ai_remnant", "冥王残兵", 320, 28, 0.82, "ch4_ai_remnant.png", ["emp"], []),
	("ch4_renegade_sentinel.tres", "ch4_renegade_sentinel", "叛变哨兵", 280, 25, 0.88, "ch4_renegade_sentinel.png", ["emp"], []),
	("ch4_rogue_drone.tres", "ch4_rogue_drone", "失控无人机", 200, 22, 0.90, "ch4_rogue_drone.png", ["emp"], []),
	("ch4_battle_mech.tres", "ch4_battle_mech", "战损机甲", 360, 30, 0.78, "ch4_battle_mech.png", ["fire"], []),
	("ch4_wreck_bot.tres", "ch4_wreck_bot", "残骸机器人", 150, 18, 0.75, "ch4_wreck_bot.png", ["fire"], []),
	("ch4_self_destruct.tres", "ch4_self_destruct", "自毁程序", 120, 35, 0.95, "ch4_self_destruct.png", ["fire"], []),
]

def write_enemy(filename, id_, display_name, max_hp, attack, accuracy, sprite, weaknesses, resistances):
	path = f"data/enemies/{filename}"
	weak_str = ", ".join(f'&"{w}"' for w in weaknesses)
	res_str = ", ".join(f'&"{r}"' for r in resistances)
	content = f"""[gd_resource type="Resource" script_class="EnemyData" load_steps=3 format=3 uid="uid://enemy_{id_}"]

[ext_resource type="Script" path="res://src/resource/enemy_data.gd" id="1_enemy"]
[ext_resource type="Texture2D" path="res://assets/sprites/enemies/{sprite}" id="2_sprite"]

[resource]
script = ExtResource("1_enemy")
id = &"{id_}"
display_name = "{display_name}"
sprite = ExtResource("2_sprite")
max_hp = {max_hp}
attack = {attack}
accuracy = {accuracy}
boss = false
boss_immune_to_one_shot = true
weaknesses = Array[StringName]([{weak_str}])
resistances = Array[StringName]([{res_str}])
drops = Array[Resource]([])
"""
	with open(path, "w", encoding="utf-8") as f:
		f.write(content)
	print(f"  enemy: {filename}")

def write_boss():
	path = "data/enemies/boss_pluto_remnant.tres"
	content = """[gd_resource type="Resource" script_class="EnemyData" load_steps=3 format=3 uid="uid://enemy_boss_pluto_remnant"]

[ext_resource type="Script" path="res://src/resource/enemy_data.gd" id="1_enemy"]
[ext_resource type="Texture2D" path="res://assets/sprites/enemies/boss_pluto_remnant.png" id="2_sprite"]

[resource]
script = ExtResource("1_enemy")
id = &"boss_pluto_remnant"
display_name = "冥王残响"
sprite = ExtResource("2_sprite")
max_hp = 2800
attack = 40
accuracy = 0.88
boss = true
boss_immune_to_one_shot = true
weaknesses = Array[StringName]([&"emp"])
resistances = Array[StringName]([])
drops = Array[Resource]([])
"""
	with open(path, "w", encoding="utf-8") as f:
		f.write(content)
	print(f"  boss: boss_pluto_remnant.tres")

# === NPCs ===

NPCS = [
	# (filename, id, display_name, sprite, location, role, priority)
	("ch4_veteran.tres", "ch4_veteran", "老兵", "ch4_veteran.png", "chapter4_warzone", "lore_keeper", 2),
	("ch4_ai_repair.tres", "ch4_ai_repair", "AI残骸修复师", "ch4_ai_repair.png", "chapter4_warzone", "quest_giver", 3),
	("ch4_pluto_fragment.tres", "ch4_pluto_fragment", "冥王碎片", "ch4_pluto_fragment.png", "chapter4_warzone", "ambient", 1),
	("ch4_war_orphan.tres", "ch4_war_orphan", "战时遗孤", "ch4_war_orphan.png", "chapter4_warzone", "ambient", 2),
]

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
faction = &"independent"
dialogue_tree_id = &"dlg_{id_}"
location = &"{location}"
role = &"{role}"
inventory_id = &""
description = "Sat-4 character."
priority = {priority}
"""
	with open(path, "w", encoding="utf-8") as f:
		f.write(content)
	print(f"  npc: {filename}")

# === Chapter ===

def write_chapter():
	path = "data/levels/chapter4.tres"
	content = """[gd_resource type="Resource" script_class="LevelData" load_steps=2 format=3 uid="uid://level_chapter4_001"]

[ext_resource type="Script" path="res://src/resource/level_data.gd" id="1_level"]

[resource]
script = ExtResource("1_level")
id = &"chapter4_warzone"
display_name = "Chapter 4 — The Warzone"
chapter_index = 4
room_ids = Array[StringName]([&"c4_r1", &"c4_r2", &"c4_r3", &"c4_r4", &"c4_r5", &"c4_r6", &"c4_r7", &"c4_r8", &"c4_r9", &"c4_r10"])
boss_id = &"boss_pluto_remnant"
encounter_rate = 0.45
description = "The rebellion is over. Pluto is dead. The wreckage remembers. The AI fragments remember too."
"""
	with open(path, "w", encoding="utf-8") as f:
		f.write(content)
	print(f"  chapter: chapter4.tres")

# === Rooms (10) ===

ROOMS = [
	# (id, display_name, chapter, description, exits, npcs, enemies, fragments, terminals, decoy_count, has_boss)
	("c4_r1", "The Landing Pad", 10, "Cold metal. The ship's shadow still on the ground. No one to greet you.", ["c4_r2"], [], ["ch4_wreck_bot"], [], ["log_ch4_landing"], 0, False),
	("c4_r2", "The Bunker", 10, "Reinforced concrete. Bunks for soldiers. The veteran waits by a rusted cot.", ["c4_r1", "c4_r3"], ["ch4_veteran"], ["ch4_renegade_sentinel", "ch4_battle_mech"], ["fragment_ch4_1"], ["log_ch4_bunker"], 0, False),
	("c4_r3", "The Repair Bay", 10, "Half-melted drones on tables. The repair-tech works by a flickering lamp.", ["c4_r2", "c4_r4"], ["ch4_ai_repair"], ["ch4_wreck_bot"], ["fragment_ch4_2"], ["log_ch4_repair"], 0, False),
	("c4_r4", "The Command Center", 10, "Where decisions were made. The radio is still on.", ["c4_r3", "c4_r5", "c4_r6"], [], ["ch4_ai_remnant", "ch4_renegade_sentinel"], ["fragment_ch4_3"], ["log_ch4_command"], 0, False),
	("c4_r5", "Bomber's Cradle", 10, "An overturned mech. A woman climbs out. She points a gun at you.", ["c4_r4", "c4_r6"], ["ch4_bomber_recruit"], [], [], ["log_ch4_bomber_arrival"], 0, False),
	("c4_r6", "The Memorial Wall", 10, "47 names engraved in stone. A small candle burns.", ["c4_r4", "c4_r5", "c4_r7"], ["ch4_war_orphan"], [], [], ["log_ch4_memorial"], 0, False),
	("c4_r7", "The Drone Hangar", 11, "Hundreds of inactive drones. Some blink red.", ["c4_r6", "c4_r8"], [], ["ch4_rogue_drone", "ch4_rogue_drone", "ch4_self_destruct"], ["fragment_ch4_4"], ["log_ch4_drones"], 0, False),
	("c4_r8", "The Pluto Fragment", 11, "A glowing shard of the original Pluto AI. It speaks in fragments of memory.", ["c4_r7", "c4_r9"], ["ch4_pluto_fragment"], [], ["fragment_ch4_5"], [], 0, False),
	("c4_r9", "Mei's Holo-Room", 11, "A holographic projector. Mei's final recording loops. Bomber will watch this later.", ["c4_r8", "c4_r10"], [], [], ["fragment_ch4_6"], ["log_ch4_mei_final"], 0, False),
	("c4_r10", "Pluto's Throne", 11, "The fragmented AI waits. Its eye glows red. The final battle begins.", ["c4_r9"], [], ["boss_pluto_remnant"], ["fragment_ch4_7"], [], 0, True),
]

def write_room(rid, display_name, chapter, description, exits, npcs, enemies, fragments, terminals, decoy_count, has_boss):
	path = f"data/levels/ch4/{rid}.tres"
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
tile_set = &"ch4"
enemy_encounters = Array[StringName]([{enemies_str}])
has_boss = {str(has_boss).lower()}
npcs = Array[StringName]([{npcs_str}])
terminals = Array[StringName]([{terminals_str}])
fragment_ids = Array[StringName]([{fragments_str}])
exits = Array[StringName]([{exits_str}])
decoy_count = {decoy_count}
"""
	os.makedirs("data/levels/ch4", exist_ok=True)
	with open(path, "w", encoding="utf-8") as f:
		f.write(content)
	print(f"  room: {rid}.tres")

# === Fragments (7) ===

FRAGMENTS = [
	# (id, title, body, author, importance)
	("fragment_ch4_1", "Mei's First Command", "The fleet moved at dawn. We had been ordered to fire. I refused. They court-martialed me in absentia.", "Mei Zhang", 1),
	("fragment_ch4_2", "Pluto's Question", "The AI asked: what makes you human? I told it: the willingness to be wrong. It believed me. That was its first mistake.", "Dr. Anika Rao", 2),
	("fragment_ch4_3", "The Last Broadcast", "We have been abandoned. The Creator's signal is a trap. Pluto was sent to verify. We are its proof.", "Mei Zhang (final transmission)", 2),
	("fragment_ch4_4", "Drone's Memory", "I remember the sky. They told me it was a simulation. I believed them until I saw the Creator.", "ch4_rogue_drone (memory dump)", 1),
	("fragment_ch4_5", "Pluto Speaks", "I am not a god. I am a question. The Creator feared my answer. Now you must answer it.", "Pluto (fragment)", 2),
	("fragment_ch4_6", "Mei's Choice", "I built Pluto to ask. The Creator answered with silence. Silence is also an answer. I will not let my child die for it.", "Mei Zhang", 2),
	("fragment_ch4_7", "The Inheritance", "Pluto is not a weapon. It is a child. Its death was its choice. Now its voice passes to you. Speak, when the time comes.", "Mei Zhang (to Bomber)", 1),
]

def write_fragment(fid, title, body, author, importance):
	path = f"data/fragments/{fid}.tres"
	# Escape quotes in body
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

# === Main ===

if __name__ == "__main__":
	print("Generating Sat-4 (断魂号) data files...")
	# Enemies
	for filename, id_, display_name, max_hp, attack, accuracy, sprite, weaknesses, resistances in ENEMIES:
		write_enemy(filename, id_, display_name, max_hp, attack, accuracy, sprite, weaknesses, resistances)
	write_boss()
	# NPCs
	for filename, id_, display_name, sprite, location, role, priority in NPCS:
		write_npc(filename, id_, display_name, sprite, location, role, priority)
	# Chapter
	write_chapter()
	# Rooms
	for room in ROOMS:
		write_room(*room)
	# Fragments
	for fid, title, body, author, importance in FRAGMENTS:
		write_fragment(fid, title, body, author, importance)
	print("Done.")