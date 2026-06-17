#!/usr/bin/env python3
"""Add quest fields to existing NPC .tres files (S13-008).

Maps each quest to its quest-giver NPC and appends 3 fields:
  gives_quest_ids
  quest_complete_dialogue_id
  quest_done_dialogue_id

Existing NPCs updated:
  ch3_hive_survivor     -> q4
  ch3_wanderer_scientist -> q5
  ch3_surviving_crew    -> q6
  ch4_veteran           -> q7
  ch4_ai_repair         -> q8
  ch4_war_orphan        -> q9
  ch4_pluto_fragment    -> q10
  ch5_cangqiong_deceased -> q11 (marlow_ghost)

Sat-2 quest givers (scavenger_leader, ice_hermit, drone_operator) and
ch5_postgame_courier don't exist as .tres files yet — quest .tres still
references them but no NPC update is needed.
"""
import re
from pathlib import Path

# (npc_file_basename, quest_id, dlg_complete_id, dlg_done_id)
NPC_QUEST_BINDINGS = [
    ("ch3_hive_survivor", "q4_hive_survivor_trust", "dlg_q4_turnin", "dlg_q4_done"),
    ("ch3_wanderer_scientist", "q5_fungal_infection_cure", "dlg_q5_turnin", "dlg_q5_done"),
    ("ch3_surviving_crew", "q6_queen_ambrosia", "dlg_q6_turnin", "dlg_q6_done"),
    ("ch4_veteran", "q7_veteran_arsenal", "dlg_q7_turnin", "dlg_q7_done"),
    ("ch4_ai_repair", "q8_ai_fragment_merge", "dlg_q8_turnin", "dlg_q8_done"),
    ("ch4_war_orphan", "q9_war_orphan_home", "dlg_q9_turnin", "dlg_q9_done"),
    ("ch4_pluto_fragment", "q10_creator_premonition", "dlg_q10_turnin", "dlg_q10_done"),
    # q11 cangqiong_legacy: closest existing NPC is ch5_cangqiong_deceased
    ("ch5_cangqiong_deceased", "q11_cangqiong_legacy", "dlg_q11_turnin", "dlg_q11_done"),
]

NPC_DIR = Path("data/npcs")

for basename, qid, dlg_complete, dlg_done in NPC_QUEST_BINDINGS:
    path = NPC_DIR / f"{basename}.tres"
    if not path.exists():
        print(f"  SKIP: {path} (missing)")
        continue
    text = path.read_text(encoding="utf-8")
    # Remove any existing quest fields (idempotent re-run)
    text = re.sub(r"^gives_quest_ids = .*\n", "", text, flags=re.MULTILINE)
    text = re.sub(r"^quest_complete_dialogue_id = .*\n", "", text, flags=re.MULTILINE)
    text = re.sub(r"^quest_done_dialogue_id = .*\n", "", text, flags=re.MULTILINE)
    # Append the 3 fields
    addition = (
        f"gives_quest_ids = [&\"{qid}\"]\n"
        f"quest_complete_dialogue_id = &\"{dlg_complete}\"\n"
        f"quest_done_dialogue_id = &\"{dlg_done}\"\n"
    )
    # Add before the priority line if present, else append at end
    if re.search(r"^priority = ", text, flags=re.MULTILINE):
        text = re.sub(r"^(priority = .*)$", addition + r"\1", text, count=1, flags=re.MULTILINE)
    else:
        text = text.rstrip() + "\n" + addition
    path.write_text(text, encoding="utf-8")
    print(f"  updated {path.name} -> {qid}")

print(f"\nUpdated {len(NPC_QUEST_BINDINGS)} NPC files")
