#!/usr/bin/env python3
"""Generate 12 quest dialogue tree .tres files for S13-010.

Each quest has ONE tree (dlg_q{N}_quest) containing:
- start node (offer)
- 3 mid-choice nodes (compassionate / pragmatic / ruthless)
- 3 ending nodes (each with unlock_fragment_id matching the choice)

The offer / turnin / done swap in S13-009 uses 3 separate trees by NPC:
- dlg_q{N}_offer (the offer dialogue when status=AVAILABLE)
- dlg_q{N}_turnin (the turn-in dialogue when status=ACTIVE)
- dlg_q{N}_done (the thanks dialogue when status=COMPLETED)

For simplicity, we generate the same tree content for all 3 names —
the content is quest-specific and the structure stays the same.

Pattern per quest: start → 3 choices → 3 endings.
The endings carry unlock_fragment_id matching truth_count_modifier:
  compassionate → &"quest_q{N}_truth_compassionate"  (truth_delta=+1)
  pragmatic     → (no fragment; truth_delta=0)
  ruthless      → &"quest_q{N}_truth_ruthless"        (truth_delta=-1)
"""
from pathlib import Path

OUT = Path("data/dialogue")
OUT.mkdir(parents=True, exist_ok=True)

# (id_short, title_en, sat, offer_text, comp_text, prag_text, ruth_text)
QUESTS = [
    ("q1", "Rescue the Scavenger Leader", 2,
     "The leader's been stuck in that collapsed cave for three days. The captor is wounded but desperate. We have to do something.",
     "We sneak in at night. Rescue the leader, leave the captor alive. (Compassionate)",
     "We offer the captor 500 gold. He releases the leader and we all walk away. (Pragmatic)",
     "We storm the cave. Kill the captor, take the leader, take his stash. (Ruthless)"),
    ("q2", "Ice Hermit's Relic", 2,
     "The hermit guards a pre-Rift artifact. She says it belonged to her family. The Black Market pays 3000 gold for one.",
     "We sit with her. Hear the story. Leave the artifact where it is. (Compassionate)",
     "We offer her 1500 gold. Half of market value, but she keeps it. (Pragmatic)",
     "We steal it at night. Sell to the Black Market. The hermit never knows. (Ruthless)"),
    ("q3", "Malfunctioning Drone Ambush", 2,
     "Six salvage drones went autonomous last week. They've been harassing caravans. The military wants them, the engineers want them, I want them off my route.",
     "We reprogram them. They become allies. (Compassionate)",
     "We sell the route to the engineers, they take the drones for parts, we take 30% of the salvage. (Pragmatic)",
     "We scrap them for parts ourselves. 4 weapons, 2 power cores. The military can go hang. (Ruthless)"),
    ("q4", "Hive Survivor's Trust", 3,
     "A survivor in the lower hive. Won't talk to anyone. Says the queen's getting ready to hatch. The commander wants intel.",
     "We share our rations. Listen to her story. She tells us where the queen's chamber is. (Compassionate)",
     "We trade: 200 gold for full intel. She takes it. (Pragmatic)",
     "We drag her to the commander. She tells him everything. 500 gold bounty. (Ruthless)"),
    ("q5", "Fungal Infection Cure", 3,
     "The scientist needs live fungal spores for a cure. The spores are also a potent bioweapon. The hive is full of them.",
     "We collect the spores. Give them to the scientist. She starts working on the cure. (Compassionate)",
     "We collect two batches. Give one to the scientist, sell the other. (Pragmatic)",
     "We collect the spores. Sell them all to the highest bidder. No cure this year. (Ruthless)"),
    ("q6", "Queen's Ambrosia", 3,
     "Royal jelly from the queen. Worth 5000 gold on the black market. The faction wants it for the cure. The queen is dying.",
     "We deliver it to the faction. They fund the cure. (Compassionate)",
     "We sell half to the faction, half to the black market. Everyone gets something. (Pragmatic)",
     "We sell it all. The queen dies. The cure is delayed another year. (Ruthless)"),
    ("q7", "Veteran's Arsenal", 4,
     "Pre-Rift weapons cache. The veteran says it's his unit's memorial. The commander wants it for the arsenal.",
     "We leave it as a memorial. The veteran tells us about the war. (Compassionate)",
     "We split: take 3 weapons, leave 3. The veteran takes the rest to the commander. (Pragmatic)",
     "We take it all. The veteran protests. We pay him 200 gold to walk away. (Ruthless)"),
    ("q8", "AI Fragment Merge", 4,
     "Damaged AI core. The repair tech says it can be healed. The military wants it for weapons. The crew wants it scrapped.",
     "We heal it. It becomes a useful ally in the final push. (Compassionate)",
     "We repurpose it. It runs the base comms. We keep it for ourselves. (Pragmatic)",
     "We scrap it. The parts are worth 2000 gold. The tech is upset. (Ruthless)"),
    ("q9", "War Orphan's Home", 4,
     "A child, alone since the war. The orphanage is gone. The shelter is full. The adoption list is long.",
     "We take her in. One more seat in the mech bay. (Compassionate)",
     "We sponsor her. 500 gold a month to the shelter. We visit when we can. (Pragmatic)",
     "We leave her at the shelter. It's not our war. (Ruthless)"),
    ("q10", "Creator's Premonition", 5,
     "A vision. The Creator, in the chamber, says: 'You will be the last.' The party is shaken. The ending feels near.",
     "We study it. Document everything. The truth is more important than the ending. (Compassionate)",
     "We share it with the party. They all carry the weight. (Pragmatic)",
     "We ignore it. The Creator is just another enemy. We focus on what's next. (Ruthless)"),
    ("q11", "Cangqiong's Legacy", 5,
     "苍穹号 — the ship — is yours now. Marlow's last will says: pass it to the next pilot. Or keep it. Or destroy it. Your call.",
     "We pass 苍穹号 to the next pilot. The cycle continues. (Compassionate)",
     "We keep 苍穹号. We earned it. The next pilot can wait. (Pragmatic)",
     "We destroy 苍穹号. The cycle ends here. No more inheritors. (Ruthless)"),
    ("q12", "??? (Post-Game)", 5,
     "The post-game courier stands at the edge of the chamber. They have one more truth. Are you ready?",
     "We listen. The final truth is gentle. (Compassionate)",
     "We listen. The final truth is honest. (Pragmatic)",
     "We refuse. Some truths are too heavy. (Ruthless)"),
]

# Choice names for fragment id
CHOICE_NAMES = ["compassionate", "pragmatic", "ruthless"]


def make_quest_trees(qid_short: str, title: str, sat: int,
                     offer_text: str, comp_text: str, prag_text: str, ruth_text: str):
    """Generate 3 .tres files: offer, turnin, done (all with same structure)."""
    qid = f"{qid_short}_hive_survivor_trust" if qid_short == "q4" else f"{qid_short}_quest"  # noqa
    # Use simple naming: dlg_q{N}_{offer|turnin|done}
    qid_base = qid_short  # e.g., "q1"

    # Build nodes dict: start, mid, comp_end, prag_end, ruth_end, bye
    nodes = {
        f"&\"{qid_base}_start\"": {
            "text": f'"{title}\\n\\n{offer_text}"',
            "choices": [
                {"label": f'"[1] {comp_text.replace(chr(34), chr(92)+chr(34))}"', "next": f"&\"{qid_base}_comp_end\""},
                {"label": f'"[2] {prag_text.replace(chr(34), chr(92)+chr(34))}"', "next": f"&\"{qid_base}_prag_end\""},
                {"label": f'"[3] {ruth_text.replace(chr(34), chr(92)+chr(34))}"', "next": f"&\"{qid_base}_ruth_end\""},
            ],
        },
        f"&\"{qid_base}_comp_end\"": {
            "text": '"You chose compassion. The NPC accepts your decision. Quest complete. (truth +1)"',
            "unlock_fragment_id": f"&\"quest_{qid_base}_truth_compassionate\"",
            "choices": [],
        },
        f"&\"{qid_base}_prag_end\"": {
            "text": '"You chose pragmatism. The NPC accepts your decision. Quest complete. (truth 0)"',
            "choices": [],
        },
        f"&\"{qid_base}_ruth_end\"": {
            "text": '"You chose ruthlessness. The NPC accepts your decision. Quest complete. (truth -1)"',
            "unlock_fragment_id": f"&\"quest_{qid_base}_truth_ruthless\"",
            "choices": [],
        },
    }
    # Build the nodes block (Godot Dict format)
    nodes_lines = []
    for key, val in nodes.items():
        nodes_lines.append(f"{key}: {{")
        for k, v in val.items():
            if k == "text":
                # v is already wrapped in quotes
                nodes_lines.append(f'"{k}": {v},')
            elif k == "unlock_fragment_id":
                nodes_lines.append(f'"{k}": {v},')
            elif k == "choices":
                if v:
                    nodes_lines.append(f'"{k}": [')
                    for choice in v:
                        nodes_lines.append("{" + ", ".join(f'"{ck}": {cv}' for ck, cv in choice.items()) + "},")
                    nodes_lines.append("]")
                else:
                    nodes_lines.append(f'"{k}": []')
        nodes_lines.append("},")
    nodes_block = "\n".join(nodes_lines)

    # Generate 3 files (offer/turnin/done) with same content for now
    files = []
    for suffix in ["offer", "turnin", "done"]:
        dlg_id = f"dlg_{qid_base}_{suffix}"
        content = f"""[gd_resource type="Resource" script_class="DialogueTree" load_steps=2 format=3 uid="uid://{dlg_id}"]

[ext_resource type="Script" path="res://src/resource/dialogue_tree.gd" id="1_dlg"]

[resource]
script = ExtResource("1_dlg")
id = &"{dlg_id}"
start_node_id = &"{qid_base}_start"
nodes = {{
{nodes_block}
}}
"""
        out = OUT / f"{dlg_id}.tres"
        out.write_text(content, encoding="utf-8")
        files.append(out)
    return files


for q in QUESTS:
    files = make_quest_trees(*q)
    for f in files:
        print(f"  wrote {f.name}")

print(f"\nGenerated {len(QUESTS) * 3} dialogue tree .tres files in {OUT}/")
