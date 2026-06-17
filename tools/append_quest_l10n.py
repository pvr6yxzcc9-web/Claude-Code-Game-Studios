#!/usr/bin/env python3
"""Append Sprint 13 side-quest localization keys to design/l10n/strings.csv."""
from pathlib import Path

CSV = Path("design/l10n/strings.csv")

# Quest titles (12) + descriptions (12) + board labels + status strings
NEW_KEYS = [
    # Board UI labels
    ("ui.quest_board.title", "QUEST BOARD (Q to open)", "任务板 (按 Q 打开)"),
    ("ui.quest_board.tab_active", "Active", "进行中"),
    ("ui.quest_board.tab_available", "Available", "可接取"),
    ("ui.quest_board.tab_completed", "Completed", "已完成"),
    ("ui.quest_board.sat_header", "── Satellite %d ──", "── %d 号卫星 ──"),
    # Status prefixes
    ("ui.quest_board.status_plot", "[PLOT] ", "[剧情] "),
    ("ui.quest_board.status_done", "[DONE] ", "[完成] "),
    ("ui.quest_board.status_failed", "[FAILED] ", "[失败] "),
    ("ui.quest_board.choice_compassionate", "[choice: compassionate]", "[选择: 仁慈]"),
    ("ui.quest_board.choice_pragmatic", "[choice: pragmatic]", "[选择: 务实]"),
    ("ui.quest_board.choice_ruthless", "[choice: ruthless]", "[选择: 残忍]"),
    # Quest 1
    ("quest.q1.title", "Rescue the Scavenger Leader", "救援劫掠者首领"),
    ("quest.q1.description", "Scavenger leader captured in a collapsed cave.", "劫掠者首领被困在坍塌的洞穴中。"),
    # Quest 2
    ("quest.q2.title", "Ice Hermit's Relic", "冰隐士遗物"),
    ("quest.q2.description", "Hermit guards an ancient artifact.", "隐士守护着一件远古遗物。"),
    # Quest 3
    ("quest.q3.title", "Malfunctioning Drone Ambush", "故障无人机"),
    ("quest.q3.description", "Six salvage drones went autonomous.", "六台打捞无人机失控。"),
    # Quest 4
    ("quest.q4.title", "Hive Survivor's Trust", "蜂巢幸存者的信任"),
    ("quest.q4.description", "A survivor in the lower hive.", "蜂巢下层有一名幸存者。"),
    # Quest 5
    ("quest.q5.title", "Fungal Infection Cure", "真菌感染治愈"),
    ("quest.q5.description", "Scientist needs live fungal spores.", "科学家需要活体真菌孢子。"),
    # Quest 6
    ("quest.q6.title", "Queen's Ambrosia", "蜂后王浆"),
    ("quest.q6.description", "Royal jelly from the dying queen.", "垂死蜂后的王浆。"),
    # Quest 7
    ("quest.q7.title", "Veteran's Arsenal", "老兵军火库"),
    ("quest.q7.description", "Pre-Rift weapons cache discovered.", "发现了战前的武器库。"),
    # Quest 8
    ("quest.q8.title", "AI Fragment Merge", "人工智能残片合并"),
    ("quest.q8.description", "Damaged AI core found.", "找到受损的 AI 核心。"),
    # Quest 9
    ("quest.q9.title", "War Orphan's Home", "战争孤儿归乡"),
    ("quest.q9.description", "A child, alone since the war.", "一个战后就独自一人的孩子。"),
    # Quest 10
    ("quest.q10.title", "Creator's Premonition", "造物者的预示"),
    ("quest.q10.description", "A vision of the Creator in the chamber.", "在密室中看见造物者的幻象。"),
    # Quest 11
    ("quest.q11.title", "Cangqiong's Legacy", "苍穹号遗志"),
    ("quest.q11.description", "Marlow's last will: 苍穹号's fate.", "马洛遗愿：苍穹号的归属。"),
    # Quest 12
    ("quest.q12.title", "???", "???"),
    ("quest.q12.description", "A hidden post-game challenge.", "一个隐藏的通关后挑战。"),
    # Quest 12 lock condition
    ("ui.quest_board.q12_locked", "[Locked: complete all 35 truths + ending A or B]", "[锁定：需集齐 35 真相 + 达成结局 A 或 B]"),
]

# Append (deduplicated)
existing = CSV.read_text(encoding="utf-8")
existing_lines = existing.splitlines()
existing_keys = {line.split(",", 1)[0] for line in existing_lines if "," in line}

appended = 0
for key, en, zh in NEW_KEYS:
    if key in existing_keys:
        continue
    # CSV escape: wrap in quotes if value contains comma
    en_q = f'"{en}"' if "," in en else en
    zh_q = f'"{zh}"' if "," in zh else zh
    existing_lines.append(f"{key},{en_q},{zh_q}")
    appended += 1

CSV.write_text("\n".join(existing_lines) + "\n", encoding="utf-8")
print(f"Appended {appended} new quest l10n keys to {CSV}")
print(f"Total keys: {len(existing_lines) - 1}")  # minus header
