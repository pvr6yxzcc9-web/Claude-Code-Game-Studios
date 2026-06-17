#!/usr/bin/env python3
"""Generate 12 stub QuestData .tres files for Sprint 13 (S13-002).

Each stub has all required fields; content is placeholder until S13-010
(dialogue trees) and S13-011 (localization) fill in real values.

Output: data/quests/q1..q12_*.tres
"""
from pathlib import Path

OUT = Path("data/quests")
OUT.mkdir(parents=True, exist_ok=True)

# (id, title_zh, title_en, description_zh, description_en, satellite,
#  giver_npc_id, dialogue_tree_id, prereq_quests, turn_in_npc_id,
#  quest_complete_dialogue_id, quest_done_dialogue_id, is_hidden, is_plot_required)
QUESTS = [
    (
        "q1_rescue_scavenger_leader",
        "救援劫掠者首领",
        "Rescue the Scavenger Leader",
        "Scavenger leader captured in a collapsed cave. Three paths: sneak rescue, ransom, or kill captor.",
        "Scavenger leader captured in a collapsed cave. Three paths: sneak rescue, ransom trade, or kill captor.",
        2,
        "npc_ch2_scavenger_leader",
        "dlg_q1_offer",
        [],
        "npc_ch2_scavenger_leader",
        "dlg_q1_turnin",
        "dlg_q1_done",
        False, False,
    ),
    (
        "q2_ice_hermit_relic",
        "冰隐士遗物",
        "Ice Hermit's Relic",
        "Hermit guards ancient artifact. Three paths: befriend, steal, or trade.",
        "Hermit guards ancient artifact. Three paths: befriend, steal, or trade.",
        2,
        "npc_ch2_ice_hermit",
        "dlg_q2_offer",
        [],
        "npc_ch2_ice_hermit",
        "dlg_q2_turnin",
        "dlg_q2_done",
        False, False,
    ),
    (
        "q3_drone_ambush",
        "故障无人机",
        "Malfunctioning Drone Ambush",
        "Drones gone rogue. Three paths: reprogram, scrap for parts, or sell to military.",
        "Malfunctioning drones. Three paths: reprogram, scrap for parts, or sell to military.",
        2,
        "npc_ch2_drone_operator",
        "dlg_q3_offer",
        [],
        "npc_ch2_drone_operator",
        "dlg_q3_turnin",
        "dlg_q3_done",
        False, False,
    ),
    (
        "q4_hive_survivor_trust",
        "蜂巢幸存者的信任",
        "Hive Survivor's Trust",
        "Lone survivor in the hive. Three paths: trust and help, interrogate, or leave to fate.",
        "Lone survivor in the hive. Three paths: trust and help, interrogate, or leave to fate.",
        3,
        "npc_ch3_hive_survivor",
        "dlg_q4_offer",
        [],
        "npc_ch3_hive_survivor",
        "dlg_q4_turnin",
        "dlg_q4_done",
        False, False,
    ),
    (
        "q5_fungal_infection_cure",
        "真菌感染治愈",
        "Fungal Infection Cure",
        "Scientist needs spores for cure. Three paths: cure her, harvest for sale, or use on enemy.",
        "Scientist needs spores for cure. Three paths: cure her, harvest for sale, or use on enemy.",
        3,
        "npc_ch3_wanderer_scientist",
        "dlg_q5_offer",
        [],
        "npc_ch3_wanderer_scientist",
        "dlg_q5_turnin",
        "dlg_q5_done",
        False, False,
    ),
    (
        "q6_queen_ambrosia",
        "蜂后王浆",
        "Queen's Ambrosia",
        "Royal jelly sample. Three paths: deliver to faction, sell to black market, or destroy it.",
        "Royal jelly sample. Three paths: deliver to faction, sell to black market, or destroy it.",
        3,
        "npc_ch3_surviving_crew",
        "dlg_q6_offer",
        [],
        "npc_ch3_surviving_crew",
        "dlg_q6_turnin",
        "dlg_q6_done",
        False, False,
    ),
    (
        "q7_veteran_arsenal",
        "老兵军火库",
        "Veteran's Arsenal",
        "Weapons cache discovered. Three paths: return to faction, keep, or sell.",
        "Weapons cache discovered. Three paths: return to faction, keep, or sell.",
        4,
        "npc_ch4_veteran",
        "dlg_q7_offer",
        [],
        "npc_ch4_veteran",
        "dlg_q7_turnin",
        "dlg_q7_done",
        False, False,
    ),
    (
        "q8_ai_fragment_merge",
        "人工智能残片合并",
        "AI Fragment Merge",
        "Damaged AI core. Three paths: heal it, repurpose, or scrap.",
        "Damaged AI core. Three paths: heal it, repurpose, or scrap.",
        4,
        "npc_ch4_ai_repair",
        "dlg_q8_offer",
        [],
        "npc_ch4_ai_repair",
        "dlg_q8_turnin",
        "dlg_q8_done",
        False, False,
    ),
    (
        "q9_war_orphan_home",
        "战争孤儿归乡",
        "War Orphan's Home",
        "Orphaned child. Three paths: adopt, sponsor, or leave.",
        "Orphaned child. Three paths: adopt, sponsor, or leave.",
        4,
        "npc_ch4_war_orphan",
        "dlg_q9_offer",
        [],
        "npc_ch4_war_orphan",
        "dlg_q9_turnin",
        "dlg_q9_done",
        False, False,
    ),
    (
        "q10_creator_premonition",
        "造物者的预示",
        "Creator's Premonition",
        "Vision of a Creator. Three paths: study it, ignore, or share with party.",
        "Vision of a Creator. Three paths: study it, ignore, or share with party.",
        5,
        "npc_ch5_pluto_fragment",
        "dlg_q10_offer",
        [],
        "npc_ch5_pluto_fragment",
        "dlg_q10_turnin",
        "dlg_q10_done",
        False, False,
    ),
    (
        "q11_cangqiong_legacy",
        "苍穹号遗志",
        "Cangqiong's Legacy",
        "Final choice involving 苍穹号. Three paths: pass to next pilot, keep, or destroy.",
        "Final choice involving 苍穹号. Three paths: pass to next pilot, keep, or destroy.",
        5,
        "npc_ch5_marlow_ghost",
        "dlg_q11_offer",
        [],
        "npc_ch5_marlow_ghost",
        "dlg_q11_turnin",
        "dlg_q11_done",
        False, True,  # PLOT — cannot be abandoned
    ),
    (
        "q12_hidden_postgame",
        "???",
        "???",
        "A hidden post-game challenge. Requires ≥35 truths and ending A or B.",
        "A hidden post-game challenge. Requires ≥35 truths and ending A or B.",
        5,
        "npc_ch5_postgame_courier",
        "dlg_q12_offer",
        ["q11_cangqiong_legacy"],
        "npc_ch5_postgame_courier",
        "dlg_q12_turnin",
        "dlg_q12_done",
        True, False,  # HIDDEN
    ),
]


def make_tres(quest):
    (qid, title_zh, title_en, desc_zh, desc_en, sat, giver, dlg_offer,
     prereqs, turn_in_npc, dlg_turnin, dlg_done, is_hidden, is_plot) = quest

    prereq_str = ", ".join(f'&"{p}"' for p in prereqs) if prereqs else ""
    # gold/xp/part/truth per choice (idx 0=compassionate, 1=pragmatic, 2=ruthless)
    # Progression: low sat → high sat, low choice → high choice
    base_gold = 300 + (sat - 2) * 250  # 300, 550, 800, 1050
    gold_rewards = [
        int(base_gold * 0.4 / 50) * 50,  # compassionate: round to 50
        base_gold,  # pragmatic
        int(base_gold * 1.5 / 100) * 100,  # ruthless: round to 100
    ]
    base_xp = 200 + (sat - 2) * 100  # 200, 300, 400, 500
    xp_rewards = [base_xp, base_xp, base_xp]  # constant per quest
    # Mech parts drop on ruthless of q3 (Sat-2), q6 (Sat-3), q8 (Sat-4)
    part_id = ""
    if qid in ("q3_drone_ambush", "q6_queen_ambrosia", "q8_ai_fragment_merge"):
        part_id = f"mech_part_{qid}_reward"
    part_rewards = ["", "", f"&\"{part_id}\"" if part_id else ""]
    truth_mods = [1, 0, -1]

    return f"""[gd_resource type="Resource" script_class="QuestData" load_steps=2 format=3 uid="uid://quest_{qid}"]

[ext_resource type="Script" path="res://src/resource/quest_data.gd" id="1_quest"]

[resource]
script = ExtResource("1_quest")
id = &"{qid}"
title_zh = "{title_zh}"
title_en = "{title_en}"
description_zh = "{desc_zh}"
description_en = "{desc_en}"
satellite = {sat}
giver_npc_id = &"{giver}"
dialogue_tree_id = &"{dlg_offer}"
prerequisite_quest_ids = [{prereq_str}]
turn_in_npc_id = &"{turn_in_npc}"
quest_complete_dialogue_id = &"{dlg_turnin}"
quest_done_dialogue_id = &"{dlg_done}"
gold_reward = [{gold_rewards[0]}, {gold_rewards[1]}, {gold_rewards[2]}]
xp_reward = [{xp_rewards[0]}, {xp_rewards[1]}, {xp_rewards[2]}]
mech_part_reward = [{part_rewards[0]}, {part_rewards[1]}, {part_rewards[2]}]
truth_count_modifier = [{truth_mods[0]}, {truth_mods[1]}, {truth_mods[2]}]
is_repeatable = false
is_hidden = {str(is_hidden).lower()}
is_plot_required = {str(is_plot).lower()}
"""


for q in QUESTS:
    out_path = OUT / f"{q[0]}.tres"
    out_path.write_text(make_tres(q), encoding="utf-8")
    print(f"  wrote {out_path}")

print(f"\nGenerated {len(QUESTS)} quest stub .tres files in {OUT}/")
