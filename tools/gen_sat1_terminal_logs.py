#!/usr/bin/env python3
"""
gen_sat1_terminal_logs.py — Generate 4 Sat-1 terminal logs (S16-002b).

Required by ch1_r2/r4/r5/r9 room layouts. Each log is a short
piece of Sat-1 lore that connects to the Marrow's 12-year mystery.

Output: data/fragments/log_sat1_*.tres (4 files)
"""
import os

OUT_DIR = "data/fragments"

LOGS = [
    {
        "id": "log_sat1_manifest_v1",
        "title": "MANIFEST VERSION 1",
        "body": "Forty-two crew. No cargo description. The convoy didn't want to know what they were carrying. The manifest says nothing because the cargo is everything. If you're reading this, the convoy has been gone longer than twelve years. We are the cargo. The cargo is us. Decide what that means to you.",
        "author": "Manifest vault, draft 1",
    },
    {
        "id": "log_sat1_manifest_v2",
        "title": "MANIFEST VERSION 2",
        "body": "We were carrying forty-two crew. We were carrying the Marrow's last hope. The cold is not the weather. The cold is what's in the hold. The seals cracked at year three. The cold got in. The cold got us. We are the cargo. We are the warning. The convoy knows.",
        "author": "Manifest vault, draft 2",
    },
    {
        "id": "log_sat1_manifest_v3",
        "title": "MANIFEST VERSION 3 — FINAL",
        "body": "Three drafts. Same answer. Forty-two crew. No cargo. The convoy didn't fail us. We failed the convoy. We were carrying something worse than ourselves. Something that wanted out. We are the cargo. We are the container. We are the warning. Marlow knows. Marlow is gone. The inheritance is here. Find the first mate on Sat-2. Tell him the Marrow is ready.",
        "author": "Manifest vault, final",
    },
    {
        "id": "log_sat1_marlow_note",
        "title": "MARLOW'S DEPARTURE NOTE",
        "body": "If you're reading this, you're the one I sent. Twenty years on this ship and the cargo bay is the only thing that's changed — and it hasn't changed. It's just older. The inheritance is 苍穹号 — a ship I found on the upper decks. Pre-Rift. Intact. The captain doesn't know. The convoy doesn't know. I know. You know now. The inheritance is yours if you can get out of here alive. Find me on Sat-2. I'll know the manifest is real. — Marlow",
        "author": "First Mate Marlow",
    },
]


def make_tres(log: dict) -> str:
    return f"""[gd_resource type="Resource" script_class="TerminalLogData" load_steps=2 format=3 uid="uid://{log['id']}_001"]

[ext_resource type="Script" path="res://src/resource/terminal_log_data.gd" id="1_log"]

[resource]
script = ExtResource("1_log")
id = &"{log['id']}"
title = "{log['title']}"
body = "{log['body']}"
author = "{log['author']}"
"""


def main() -> int:
    os.makedirs(OUT_DIR, exist_ok=True)
    for log in LOGS:
        path = os.path.join(OUT_DIR, f"{log['id']}.tres")
        with open(path, "w", encoding="utf-8") as f:
            f.write(make_tres(log))
        print(f"  wrote {path}")
    print(f"\nGenerated {len(LOGS)} Sat-1 terminal logs")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
