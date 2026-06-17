#!/usr/bin/env python3
"""
gen_quest_giver_portraits.py — Generate 4 quest-giver NPC portraits for S13-013.

Per art-bible: 64x64 pixel-art portraits, distinct silhouettes + colors.

Outputs (in assets/sprites/npcs/):
  ch2_scavenger_leader.png  (scarred scavenger, red+gray, mech shoulder)
  ch2_ice_hermit.png        (hooded hermit, cyan+white, ice crystals)
  ch2_drone_operator.png    (goggled engineer, yellow+navy, antenna)
  ch5_postgame_courier.png  (post-game messenger, purple+silver, halo)

Run from project root:
  python tools/gen_quest_giver_portraits.py
"""
import os
from PIL import Image, ImageDraw

OUT_DIR = "assets/sprites/npcs"
SIZE = 64

# Reuse palette from gen_npc_portraits.py
NAVY = (16, 20, 32, 255)
NAVY_DARK = (10, 14, 24, 255)
NAVY_MID = (24, 30, 48, 255)
GRAY = (60, 64, 72, 255)
GRAY_DARK = (40, 44, 52, 255)
GRAY_MID = (80, 84, 92, 255)
METAL = (140, 152, 168, 255)
AMBER = (220, 158, 80, 255)
AMBER_DARK = (140, 88, 48, 255)
YELLOW = (240, 200, 60, 255)
YELLOW_DARK = (160, 130, 30, 255)
RED = (220, 50, 50, 255)
RED_DARK = (140, 30, 30, 255)
RED_BRIGHT = (255, 80, 80, 255)
CYAN = (90, 220, 255, 255)
CYAN_DIM = (50, 140, 180, 255)
WHITE = (240, 240, 240, 255)
WHITE_BRIGHT = (255, 255, 255, 255)
SKIN = (200, 160, 130, 255)
SKIN_DARK = (140, 100, 70, 255)
HAIR_BROWN = (100, 70, 50, 255)
HAIR_GRAY = (180, 180, 190, 255)
PURPLE = (140, 80, 200, 255)
PURPLE_DARK = (80, 40, 130, 255)
SILVER = (200, 210, 220, 255)


def make_scavenger_leader() -> Image.Image:
    """Scarred scavenger — red+gray, mech shoulder pad, bandaged face."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Mech shoulder pad (right)
    d.rectangle([42, 26, 60, 50], fill=GRAY_DARK, outline=GRAY)
    d.rectangle([44, 28, 50, 36], fill=RED_DARK)
    # Body / vest (red)
    d.rectangle([18, 30, 42, 60], fill=RED_DARK, outline=RED)
    d.rectangle([20, 32, 28, 44], fill=GRAY_DARK)  # pocket
    # Head (skin)
    d.rectangle([22, 14, 38, 30], fill=SKIN, outline=SKIN_DARK)
    # Bandage over left eye (white)
    d.rectangle([22, 18, 30, 22], fill=WHITE, outline=GRAY_MID)
    # Right eye (visible, dark)
    d.rectangle([33, 19, 36, 21], fill=NAVY_DARK)
    # Scar (red line)
    d.line([30, 24, 36, 26], fill=RED_BRIGHT, width=1)
    # Hair (brown, short)
    d.rectangle([22, 12, 38, 16], fill=HAIR_BROWN)
    return img


def make_ice_hermit() -> Image.Image:
    """Hooded hermit — cyan+white, ice crystals on hood, long beard."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Hood (cyan-gray)
    d.polygon([(16, 12), (32, 4), (48, 12), (50, 40), (14, 40)], fill=CYAN_DIM, outline=CYAN)
    # Ice crystals on hood (white)
    for x, y in [(20, 14), (28, 8), (40, 12), (44, 18)]:
        d.polygon([(x, y), (x-1, y+2), (x+1, y+2)], fill=WHITE)
    # Face in shadow (dark blue)
    d.rectangle([24, 24, 40, 36], fill=NAVY_DARK)
    # Eyes (glowing white)
    d.rectangle([27, 28, 30, 30], fill=WHITE_BRIGHT)
    d.rectangle([34, 28, 37, 30], fill=WHITE_BRIGHT)
    # Long beard (white)
    d.polygon([(26, 36), (32, 56), (38, 36)], fill=WHITE, outline=GRAY_MID)
    # Body (dark blue)
    d.rectangle([16, 40, 48, 62], fill=NAVY_DARK, outline=NAVY_MID)
    return img


def make_drone_operator() -> Image.Image:
    """Goggled engineer — yellow+navy, antenna on head, tool belt."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Antenna (yellow)
    d.line([(32, 4), (32, 12)], fill=YELLOW, width=1)
    d.ellipse([30, 2, 34, 6], fill=RED)
    # Head (skin)
    d.rectangle([22, 12, 42, 30], fill=SKIN, outline=SKIN_DARK)
    # Goggles (yellow, large)
    d.rectangle([22, 18, 42, 24], fill=YELLOW, outline=YELLOW_DARK)
    d.rectangle([26, 19, 32, 22], fill=NAVY_DARK)  # left lens
    d.rectangle([34, 19, 40, 22], fill=NAVY_DARK)  # right lens
    # Goggle strap
    d.line([(22, 21), (18, 23)], fill=GRAY_DARK, width=1)
    d.line([(42, 21), (46, 23)], fill=GRAY_DARK, width=1)
    # Mouth (small line)
    d.line([(28, 27), (36, 27)], fill=SKIN_DARK, width=1)
    # Body (navy jumpsuit)
    d.rectangle([18, 30, 46, 60], fill=NAVY_MID, outline=NAVY_DARK)
    # Yellow stripes (engineer uniform)
    d.rectangle([20, 36, 44, 38], fill=YELLOW)
    d.rectangle([20, 50, 44, 52], fill=YELLOW)
    # Tool belt
    d.rectangle([20, 54, 44, 58], fill=GRAY_DARK)
    d.rectangle([24, 55, 28, 57], fill=METAL)
    d.rectangle([32, 55, 36, 57], fill=METAL)
    return img


def make_postgame_courier() -> Image.Image:
    """Post-game messenger — purple+silver, halo, ethereal."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Halo (silver, behind head)
    d.ellipse([18, 6, 46, 18], outline=SILVER, width=2)
    # Head (silver, ethereal)
    d.rectangle([22, 14, 42, 32], fill=SILVER, outline=PURPLE_DARK)
    # Eyes (glowing purple)
    d.rectangle([26, 20, 30, 23], fill=PURPLE)
    d.rectangle([34, 20, 38, 23], fill=PURPLE)
    # Body (purple robe)
    d.polygon([(16, 32), (32, 28), (48, 32), (52, 62), (12, 62)], fill=PURPLE, outline=PURPLE_DARK)
    # Silver trim on robe
    d.line([(20, 40), (44, 40)], fill=SILVER, width=1)
    d.line([(18, 50), (46, 50)], fill=SILVER, width=1)
    # Ethereal particles (small purple dots floating)
    for x, y in [(8, 22), (56, 30), (10, 50), (54, 56)]:
        d.ellipse([x-1, y-1, x+1, y+1], fill=PURPLE)
    return img


PORTRAITS = [
    ("ch2_scavenger_leader", make_scavenger_leader),
    ("ch2_ice_hermit", make_ice_hermit),
    ("ch2_drone_operator", make_drone_operator),
    ("ch5_postgame_courier", make_postgame_courier),
]


def main() -> int:
    os.makedirs(OUT_DIR, exist_ok=True)
    for name, fn in PORTRAITS:
        img = fn()
        path = os.path.join(OUT_DIR, f"{name}.png")
        img.save(path)
        print(f"  wrote {path} ({img.size[0]}x{img.size[1]})")
    print(f"\nGenerated {len(PORTRAITS)} quest-giver portraits in {OUT_DIR}/")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
