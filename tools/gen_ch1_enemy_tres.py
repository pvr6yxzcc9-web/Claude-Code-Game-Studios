#!/usr/bin/env python3
"""
gen_ch1_enemy_tres.py — Generate 6 Sat-1 enemy data .tres files (S16-001).

Per design/multi-satellite-arc.md: 6 normal enemies per satellite.
Sat-1 = "The Drift Wreck" — derelict cargo ship, salvage crew gone
feral. Boss is already in data/enemies/boss_marrow_sentinel.tres.

Enemy tiers (per S7-009 BattleMathLib):
  Tier 1 (40-60 HP, 8-12 atk):  early game
  Tier 2 (80-120 HP, 14-20 atk): mid game
  Tier 3 (160-200 HP, 22-30 atk): late game (rare in Sat-1)

Output: data/enemies/ch1_*.tres (6 files)
"""
import os

OUT_DIR = "data/enemies"

# (id, display_name_zh, display_name_en, max_hp, attack, accuracy, weakness, resistance)
ENEMIES = [
    ("ch1_feral_scavenger", "野生打捞者", "Feral Scavenger",
     45, 10, 0.80, "fire", "cold"),
    ("ch1_drone_remnant", "残骸无人机", "Drone Remnant",
     35, 12, 0.90, "emp", "ice"),
    ("ch1_cargo_bot", "货运机器人", "Cargo Bot",
     80, 14, 0.70, "emp", "physical"),
    ("ch1_frozen_crew", "冰冻船员", "Frozen Crew",
     60, 16, 0.75, "fire", "cold"),
    ("ch1_warden_construct", "典狱长傀儡", "Warden Construct",
     120, 20, 0.85, "emp", "physical"),
    ("ch1_hollow_tech", "空壳技师", "Hollow Tech",
     95, 22, 0.90, "fire", "emp"),
]


def make_tres(eid: str, name_zh: str, name_en: str, hp: int, atk: int, acc: float,
              weakness: str, resistance: str) -> str:
    return f"""[gd_resource type="Resource" script_class="EnemyData" load_steps=2 format=3 uid="uid://enemy_{eid}_001"]

[ext_resource type="Script" path="res://src/resource/enemy_data.gd" id="1_enemy"]

[resource]
script = ExtResource("1_enemy")
id = &"{eid}"
display_name = "{name_zh} ({name_en})"
max_hp = {hp}
attack = {atk}
accuracy = {acc:.2f}
boss = false
boss_immune_to_one_shot = true
weaknesses = Array[StringName]([&"{weakness}"])
resistances = Array[StringName]([&"{resistance}"])
"""


def main() -> int:
    os.makedirs(OUT_DIR, exist_ok=True)
    for e in ENEMIES:
        path = os.path.join(OUT_DIR, f"{e[0]}.tres")
        with open(path, "w", encoding="utf-8") as f:
            f.write(make_tres(*e))
        print(f"  wrote {path} (HP={e[3]}, ATK={e[4]})")
    print(f"\nGenerated {len(ENEMIES)} Sat-1 enemy .tres files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
