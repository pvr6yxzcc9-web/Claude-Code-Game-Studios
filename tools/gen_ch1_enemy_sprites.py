#!/usr/bin/env python3
"""
gen_ch1_enemy_sprites.py — Generate 6 Sat-1 enemy sprites (S16-003).

Per art-bible: 32x32 pixel-art enemies in dark sci-fi ruin palette.
Sat-1 = "The Drift Wreck" — derelict cargo ship, salvage crew gone
feral/mad, frozen by deep-space cold.

Enemies (6 normal + 1 boss already in enemies/):
  ch1_feral_scavenger     — ex-crew gone mad, rusty knife
  ch1_drone_remnant        — autonomous salvage drone
  ch1_cargo_bot            — repurposed loading bot
  ch1_frozen_crew          — ex-crew preserved by cold
  ch1_warden_construct     — security golem
  ch1_hollow_tech          — ex-tech with broken cybernetic

Output: assets/sprites/enemies/{id}.png (6 files)

Run from project root:
  python tools/gen_ch1_enemy_sprites.py
"""
import os
from PIL import Image, ImageDraw

OUT_DIR = "assets/sprites/enemies"
SIZE = 32

# Palette
NAVY = (16, 20, 32, 255)
NAVY_DARK = (10, 14, 24, 255)
GRAY = (60, 64, 72, 255)
GRAY_DARK = (40, 44, 52, 255)
GRAY_MID = (80, 84, 92, 255)
METAL = (140, 152, 168, 255)
METAL_DARK = (90, 100, 116, 255)
RUST = (140, 70, 40, 255)
RUST_DARK = (90, 40, 20, 255)
AMBER = (220, 158, 80, 255)
AMBER_DARK = (140, 88, 48, 255)
RED = (220, 50, 50, 255)
RED_DARK = (140, 30, 30, 255)
CYAN = (90, 220, 255, 255)
CYAN_DIM = (50, 140, 180, 255)
CYAN_ICE = (180, 230, 255, 255)
WHITE = (240, 240, 240, 255)
SKIN = (200, 160, 130, 255)
SKIN_DARK = (140, 100, 70, 255)
SKIN_BLUE = (170, 170, 200, 255)
SKIN_PALE = (180, 200, 200, 255)
HAIR_BROWN = (100, 70, 50, 255)
HAIR_GRAY = (180, 180, 190, 255)


def make_feral_scavenger() -> Image.Image:
    """Ex-crew gone mad, rusty knife."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Body (tattered vest)
    d.rectangle([10, 14, 22, 28], fill=GRAY_DARK, outline=GRAY)
    d.rectangle([10, 14, 22, 16], fill=AMBER_DARK)  # vest strap
    # Head (mad eyes, unkempt)
    d.rectangle([11, 6, 21, 14], fill=SKIN, outline=SKIN_DARK)
    d.rectangle([11, 4, 21, 8], fill=HAIR_BROWN)  # hair
    # Mad eyes (red, wild)
    d.rectangle([13, 9, 15, 11], fill=RED)
    d.rectangle([17, 9, 19, 11], fill=RED)
    d.rectangle([13, 9, 14, 10], fill=RED_DARK)
    d.rectangle([17, 9, 18, 10], fill=RED_DARK)
    # Open mouth (scream)
    d.rectangle([14, 12, 18, 14], fill=NAVY_DARK)
    # Rusty knife in right hand
    d.polygon([(24, 16), (28, 8), (30, 10), (26, 18)], fill=RUST, outline=RUST_DARK)
    # Left arm
    d.rectangle([6, 14, 10, 22], fill=SKIN)
    # Legs
    d.rectangle([12, 28, 16, 32], fill=GRAY_DARK)
    d.rectangle([17, 28, 21, 32], fill=GRAY_DARK)
    return img


def make_drone_remnant() -> Image.Image:
    """Autonomous salvage drone — 4 rotors, single red eye."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Body (gray, square)
    d.rectangle([10, 10, 22, 22], fill=GRAY, outline=GRAY_DARK)
    d.rectangle([10, 10, 22, 12], fill=METAL)
    # 4 rotor arms
    d.rectangle([6, 12, 10, 14], fill=METAL)
    d.rectangle([22, 12, 26, 14], fill=METAL)
    d.rectangle([6, 20, 10, 22], fill=METAL)
    d.rectangle([22, 20, 26, 22], fill=METAL)
    # Rotors (spinning)
    for cx, cy in [(8, 13), (24, 13), (8, 21), (24, 21)]:
        d.ellipse([cx - 2, cy - 2, cx + 2, cy + 2], fill=GRAY_DARK, outline=GRAY)
    # Center eye (red scanner)
    d.ellipse([14, 14, 18, 18], fill=RED, outline=AMBER)
    d.ellipse([15, 15, 17, 17], fill=AMBER)
    # Antenna
    d.line([(16, 10), (16, 4)], fill=GRAY_DARK, width=1)
    d.ellipse([15, 2, 17, 4], fill=RED)
    return img


def make_cargo_bot() -> Image.Image:
    """Repurposed loading bot — boxy, claw arms."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Body (orange industrial)
    d.rectangle([8, 10, 24, 26], fill=AMBER_DARK, outline=RUST_DARK)
    d.rectangle([10, 12, 22, 24], fill=AMBER)
    # Cargo plate on chest
    d.rectangle([12, 14, 20, 20], fill=RUST, outline=RUST_DARK)
    d.rectangle([14, 16, 18, 18], fill=AMBER_LIGHT) if False else d.rectangle([14, 16, 18, 18], fill=WHITE) if False else None
    # Eyes (cyan, boxy)
    d.rectangle([10, 12, 12, 14], fill=CYAN)
    d.rectangle([20, 12, 22, 14], fill=CYAN)
    # Claw arms
    d.rectangle([4, 14, 8, 20], fill=GRAY)
    d.polygon([(2, 18), (4, 14), (4, 20)], fill=GRAY_DARK)  # claw
    d.rectangle([24, 14, 28, 20], fill=GRAY)
    d.polygon([(30, 18), (28, 14), (28, 20)], fill=GRAY_DARK)  # claw
    # Treads (bottom)
    d.rectangle([8, 26, 24, 28], fill=GRAY_DARK)
    for x in range(10, 24, 3):
        d.rectangle([x, 26, x + 1, 28], fill=GRAY_MID)
    return img


def make_frozen_crew() -> Image.Image:
    """Ex-crew preserved by cold — blue skin, frost on body."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Body (cryo-vest)
    d.rectangle([10, 14, 22, 28], fill=NAVY_DARK, outline=CYAN_DIM)
    d.rectangle([10, 14, 22, 16], fill=CYAN_DIM)
    # Frost crystals on body
    for x, y in [(12, 18), (18, 22), (14, 25), (20, 19)]:
        d.ellipse([x, y, x + 2, y + 2], fill=WHITE)
    # Head (blue, frozen)
    d.rectangle([11, 6, 21, 14], fill=SKIN_BLUE, outline=CYAN_DIM)
    # Frost on head
    d.rectangle([11, 4, 21, 7], fill=WHITE)
    d.line([(12, 6), (20, 6)], fill=WHITE, width=1)
    # Eyes (icy, dead)
    d.rectangle([13, 9, 15, 11], fill=CYAN_ICE)
    d.rectangle([17, 9, 19, 11], fill=CYAN_ICE)
    # Frost breath
    d.ellipse([14, 14, 18, 17], fill=(200, 220, 240, 150))
    # Arms (raised, frozen)
    d.rectangle([6, 12, 10, 20], fill=SKIN_BLUE)
    d.rectangle([22, 12, 26, 20], fill=SKIN_BLUE)
    # Legs
    d.rectangle([12, 28, 16, 32], fill=NAVY)
    d.rectangle([17, 28, 21, 32], fill=NAVY)
    return img


def make_warden_construct() -> Image.Image:
    """Security golem — heavy armor, glowing eye."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Body (heavy gray armor)
    d.rectangle([8, 10, 24, 26], fill=GRAY_DARK, outline=NAVY_DARK)
    d.rectangle([8, 10, 24, 12], fill=NAVY)  # shoulder plate
    d.rectangle([10, 12, 22, 24], fill=GRAY)
    # Chest plate with warning stripe
    d.rectangle([12, 16, 20, 22], fill=AMBER_DARK)
    d.line([(12, 18), (20, 18)], fill=AMBER, width=1)
    d.line([(12, 20), (20, 20)], fill=AMBER, width=1)
    # Head (helmeted, single eye)
    d.rectangle([11, 4, 21, 10], fill=GRAY_DARK, outline=NAVY_DARK)
    d.ellipse([14, 6, 18, 8], fill=RED)  # single red eye
    d.ellipse([15, 6, 17, 7], fill=AMBER)
    # Arms (armored, gun)
    d.rectangle([4, 12, 8, 22], fill=GRAY_DARK)
    d.rectangle([24, 12, 28, 22], fill=GRAY_DARK)
    # Right arm cannon
    d.rectangle([26, 16, 30, 18], fill=NAVY_DARK)
    d.rectangle([28, 14, 30, 20], fill=NAVY)
    d.ellipse([30, 16, 32, 18], fill=RED)
    # Legs
    d.rectangle([10, 26, 14, 32], fill=GRAY_DARK)
    d.rectangle([18, 26, 22, 32], fill=GRAY_DARK)
    return img


def make_hollow_tech() -> Image.Image:
    """Ex-tech with broken cybernetic — half human, half machine."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Body (left side human, right side machine)
    d.rectangle([10, 14, 22, 28], fill=NAVY_DARK, outline=NAVY)
    d.rectangle([10, 14, 16, 28], fill=SKIN_PALE)  # left: human flesh
    d.rectangle([16, 14, 22, 28], fill=GRAY)  # right: metal
    # Visible cybernetics (screws, plates)
    d.rectangle([16, 16, 22, 18], fill=METAL)
    d.rectangle([18, 20, 22, 22], fill=METAL_DARK)
    # Head (half human, half skull-plate)
    d.rectangle([11, 6, 21, 14], fill=SKIN_PALE, outline=SKIN_DARK)
    d.rectangle([16, 6, 21, 14], fill=GRAY)  # right half: skull plate
    d.line([(16, 6), (16, 14)], fill=NAVY, width=1)
    # Left eye (red, organic)
    d.rectangle([13, 9, 15, 11], fill=RED)
    # Right eye (cyan, robotic)
    d.rectangle([17, 9, 19, 11], fill=CYAN)
    # Mouth (half smile, half grimace)
    d.line([(13, 12), (19, 12)], fill=NAVY_DARK, width=1)
    # Arms
    d.rectangle([6, 14, 10, 22], fill=SKIN_PALE)  # human
    d.rectangle([22, 14, 26, 22], fill=GRAY)  # metal
    # Legs
    d.rectangle([12, 28, 16, 32], fill=SKIN_PALE)
    d.rectangle([17, 28, 21, 32], fill=GRAY)
    return img


ENEMIES = [
    ("ch1_feral_scavenger", make_feral_scavenger),
    ("ch1_drone_remnant", make_drone_remnant),
    ("ch1_cargo_bot", make_cargo_bot),
    ("ch1_frozen_crew", make_frozen_crew),
    ("ch1_warden_construct", make_warden_construct),
    ("ch1_hollow_tech", make_hollow_tech),
]


def main() -> int:
    os.makedirs(OUT_DIR, exist_ok=True)
    for name, fn in ENEMIES:
        img = fn()
        path = os.path.join(OUT_DIR, f"{name}.png")
        img.save(path)
        print(f"  wrote {path} ({SIZE}x{SIZE})")
    print(f"\nGenerated {len(ENEMIES)} Sat-1 enemy sprites")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
