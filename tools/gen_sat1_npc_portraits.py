#!/usr/bin/env python3
"""
gen_sat1_npc_portraits.py — Generate 4 Sat-1 NPC portraits (S15-001).

Per art-bible: 64x64 pixel-art portraits, dark sci-fi ruin palette.
Sat-1 = "The Drift Wreck" — abandoned derelict cargo ship, salvage
crew, frozen by the cold of deep space.

NPCs:
  derelict_captain     — captain of the Marrow, weathered leader
  salvage_engineer     — grease-stained mechanic, goggles
  frozen_cargo_tech    — cryo-vest tech, blue-tinged skin from cold
  marlow_first_mate    — Marlow's right hand, grizzled veteran

Outputs (in assets/sprites/npcs/):
  ch1_derelict_captain.png + 3 anim frames (12 PNG total)
  ch1_salvage_engineer.png + 3 anim frames
  ch1_frozen_cargo_tech.png + 3 anim frames
  ch1_marlow_first_mate.png + 3 anim frames

Total: 4 base + 12 anim = 16 PNG

Run from project root:
  python tools/gen_sat1_npc_portraits.py
"""
import os
from PIL import Image, ImageDraw

OUT_DIR = "assets/sprites/npcs"
SIZE = 64

# Palette
NAVY = (16, 20, 32, 255)
NAVY_DARK = (10, 14, 24, 255)
NAVY_MID = (24, 30, 48, 255)
GRAY = (60, 64, 72, 255)
GRAY_DARK = (40, 44, 52, 255)
GRAY_MID = (80, 84, 92, 255)
METAL = (140, 152, 168, 255)
METAL_DARK = (90, 100, 116, 255)
AMBER = (220, 158, 80, 255)
AMBER_DARK = (140, 88, 48, 255)
AMBER_LIGHT = (255, 200, 100, 255)
RED = (220, 50, 50, 255)
RED_DARK = (140, 30, 30, 255)
RED_BRIGHT = (255, 80, 80, 255)
CYAN = (90, 220, 255, 255)
CYAN_DIM = (50, 140, 180, 255)
CYAN_ICE = (180, 230, 255, 255)
WHITE = (240, 240, 240, 255)
WHITE_BRIGHT = (255, 255, 255, 255)
SKIN = (200, 160, 130, 255)
SKIN_DARK = (140, 100, 70, 255)
SKIN_BLUE = (170, 170, 200, 255)  # frozen
SKIN_ASH = (180, 165, 150, 255)   # weathered
HAIR_BROWN = (100, 70, 50, 255)
HAIR_GRAY = (180, 180, 190, 255)
HAIR_BLACK = (40, 30, 30, 255)
BROWN = (110, 70, 40, 255)


def make_derelict_captain() -> Image.Image:
    """Weathered captain of the Marrow — dark uniform, gray hair, scar."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Body (navy uniform with gold trim)
    d.rectangle([16, 28, 48, 60], fill=NAVY_DARK, outline=NAVY)
    d.rectangle([16, 32, 48, 36], fill=AMBER_DARK)  # gold trim
    d.rectangle([16, 50, 48, 54], fill=AMBER_DARK)
    # Rank insignia (gold bars on shoulder)
    d.rectangle([20, 30, 26, 38], fill=AMBER_LIGHT)
    d.rectangle([38, 30, 44, 38], fill=AMBER_LIGHT)
    # Head (weathered skin)
    d.rectangle([22, 12, 42, 30], fill=SKIN_ASH, outline=SKIN_DARK)
    # Gray hair (short, balding)
    d.rectangle([22, 10, 42, 16], fill=HAIR_GRAY)
    d.rectangle([20, 14, 24, 18], fill=HAIR_GRAY)
    d.rectangle([40, 14, 44, 18], fill=HAIR_GRAY)
    # Eyes (tired, navy)
    d.rectangle([26, 19, 30, 22], fill=NAVY)
    d.rectangle([34, 19, 38, 22], fill=NAVY)
    # Eye whites (subtle)
    d.rectangle([26, 19, 27, 21], fill=WHITE)
    d.rectangle([34, 19, 35, 21], fill=WHITE)
    # Scar (left cheek)
    d.line([(24, 23), (28, 27)], fill=RED_BRIGHT, width=1)
    # Stubble
    d.rectangle([26, 26, 38, 28], fill=HAIR_GRAY)
    # Mouth (firm line)
    d.line([(28, 25), (36, 25)], fill=NAVY_DARK, width=1)
    return img


def make_salvage_engineer() -> Image.Image:
    """Grease-stained mechanic — yellow hardhat, goggles, beard."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Body (gray jumpsuit, oil stains)
    d.rectangle([16, 28, 48, 60], fill=GRAY_DARK, outline=GRAY)
    d.rectangle([18, 38, 24, 44], fill=NAVY_DARK)  # oil stain
    d.rectangle([40, 48, 46, 54], fill=NAVY_DARK)  # another stain
    # Tool belt
    d.rectangle([16, 52, 48, 56], fill=BROWN)
    d.rectangle([20, 53, 24, 55], fill=METAL)
    d.rectangle([30, 53, 34, 55], fill=METAL)
    d.rectangle([40, 53, 44, 55], fill=AMBER)
    # Hardhat (yellow)
    d.rectangle([20, 8, 44, 18], fill=AMBER, outline=AMBER_DARK)
    d.rectangle([18, 16, 46, 18], fill=AMBER_DARK)  # brim
    # Hardhat detail (stripe)
    d.rectangle([20, 14, 44, 16], fill=AMBER_LIGHT)
    # Lamp on hat
    d.rectangle([30, 10, 34, 14], fill=AMBER_LIGHT, outline=AMBER_DARK)
    # Face (below brim)
    d.rectangle([22, 18, 42, 30], fill=SKIN, outline=SKIN_DARK)
    # Goggles (round)
    d.ellipse([24, 19, 32, 25], fill=NAVY_DARK, outline=GRAY)
    d.ellipse([32, 19, 40, 25], fill=NAVY_DARK, outline=GRAY)
    # Goggle lens highlights
    d.ellipse([26, 20, 28, 22], fill=CYAN_ICE)
    d.ellipse([34, 20, 36, 22], fill=CYAN_ICE)
    # Goggle strap
    d.line([(24, 22), (18, 25)], fill=GRAY, width=1)
    d.line([(40, 22), (46, 25)], fill=GRAY, width=1)
    # Beard (full, brown)
    d.rectangle([24, 26, 40, 32], fill=HAIR_BROWN)
    d.line([(28, 28), (28, 32)], fill=HAIR_BROWN, width=1)
    d.line([(36, 28), (36, 32)], fill=HAIR_BROWN, width=1)
    # Mouth (hidden by beard)
    return img


def make_frozen_cargo_tech() -> Image.Image:
    """Cryo-vest tech — blue-tinged skin from cold, frost on clothes, hooded."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Body (blue cryo-vest)
    d.rectangle([16, 28, 48, 60], fill=NAVY_MID, outline=CYAN_DIM)
    d.rectangle([16, 32, 48, 36], fill=CYAN_ICE)  # frost trim
    # Frost crystals on body
    for x, y in [(22, 38), (38, 42), (30, 50), (40, 54)]:
        d.ellipse([x, y, x + 2, y + 2], fill=WHITE_BRIGHT)
    # Hood
    d.polygon([(16, 14), (32, 6), (48, 14), (48, 30), (16, 30)], fill=NAVY_DARK, outline=CYAN_DIM)
    # Frost on hood edge
    d.line([(18, 16), (46, 16)], fill=WHITE_BRIGHT, width=1)
    # Face (frozen blue)
    d.rectangle([22, 18, 42, 30], fill=SKIN_BLUE, outline=SKIN_DARK)
    # Eyes (icy, pale)
    d.rectangle([26, 21, 30, 24], fill=CYAN_ICE)
    d.rectangle([34, 21, 38, 24], fill=CYAN_ICE)
    d.rectangle([27, 22, 28, 23], fill=WHITE_BRIGHT)
    d.rectangle([35, 22, 36, 23], fill=WHITE_BRIGHT)
    # Frost on eyebrows
    d.line([(25, 20), (30, 20)], fill=WHITE_BRIGHT, width=1)
    d.line([(34, 20), (39, 20)], fill=WHITE_BRIGHT, width=1)
    # Mouth (slightly blue lips)
    d.line([(28, 26), (36, 26)], fill=NAVY_DARK, width=1)
    # Breath (small white puff)
    d.ellipse([30, 32, 34, 34], fill=(200, 220, 240, 100))
    return img


def make_marlow_first_mate() -> Image.Image:
    """Marlow's right hand — grizzled veteran, eyepatch, scar, weathered."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Body (dark coat with red collar)
    d.rectangle([16, 28, 48, 60], fill=NAVY_DARK, outline=NAVY)
    d.rectangle([16, 28, 22, 60], fill=RED_DARK)  # red side panel
    d.rectangle([42, 28, 48, 60], fill=RED_DARK)
    # Belt (gold buckle)
    d.rectangle([16, 48, 48, 52], fill=NAVY)
    d.rectangle([28, 48, 36, 52], fill=AMBER_LIGHT)
    # Head (weathered, square jaw)
    d.rectangle([22, 12, 42, 30], fill=SKIN, outline=SKIN_DARK)
    # Hair (black, slicked back)
    d.rectangle([22, 10, 42, 14], fill=HAIR_BLACK)
    # Eyepatch (left eye)
    d.rectangle([22, 18, 30, 22], fill=NAVY_DARK)
    d.line([(22, 18), (30, 22)], fill=NAVY, width=1)
    d.line([(22, 22), (30, 18)], fill=NAVY, width=1)
    # Right eye (visible, sharp)
    d.rectangle([34, 19, 38, 22], fill=NAVY)
    d.rectangle([34, 19, 35, 21], fill=WHITE)
    # Scar (right side of face)
    d.line([(40, 18), (42, 26)], fill=RED_BRIGHT, width=1)
    # Stubble
    d.rectangle([28, 26, 36, 30], fill=HAIR_BROWN)
    # Mouth (firm)
    d.line([(28, 25), (36, 25)], fill=NAVY_DARK, width=1)
    # Jaw (defined)
    d.line([(24, 28), (40, 28)], fill=SKIN_DARK, width=1)
    return img


# === Animation frame modifiers ===

def make_mouth_open(base: Image.Image) -> Image.Image:
    """Open mouth: small dark ellipse in the mouth area."""
    out = base.copy()
    d = ImageDraw.Draw(out)
    # Erase the mouth line (most are at y=25)
    d.rectangle([27, 24, 37, 27], fill=SKIN if "salvage" not in str(base.tobytes()) else BROWN)
    # Draw open mouth
    d.ellipse([28, 24, 36, 28], fill=NAVY_DARK)
    d.ellipse([29, 25, 35, 27], fill=(60, 20, 20, 255))
    return out


def make_eyes_blink(base: Image.Image) -> Image.Image:
    """Closed eyes: horizontal lines instead of eye shapes."""
    out = base.copy()
    d = ImageDraw.Draw(out)
    # Close the eyes (small lines at y=20-22)
    d.line([(25, 21), (31, 21)], fill=NAVY_DARK, width=1)
    d.line([(33, 21), (39, 21)], fill=NAVY_DARK, width=1)
    return out


def make_mouth_open_blink(base: Image.Image) -> Image.Image:
    """Both: open mouth + closed eyes."""
    out = make_eyes_blink(base)
    d = ImageDraw.Draw(out)
    d.ellipse([28, 24, 36, 28], fill=NAVY_DARK)
    d.ellipse([29, 25, 35, 27], fill=(60, 20, 20, 255))
    return out


NPCS = [
    ("ch1_derelict_captain", make_derelict_captain),
    ("ch1_salvage_engineer", make_salvage_engineer),
    ("ch1_frozen_cargo_tech", make_frozen_cargo_tech),
    ("ch1_marlow_first_mate", make_marlow_first_mate),
]


def main() -> int:
    os.makedirs(OUT_DIR, exist_ok=True)
    for name, fn in NPCS:
        base = fn()
        base_path = os.path.join(OUT_DIR, f"{name}.png")
        base.save(base_path)
        print(f"  wrote {base_path}")
        # Animation frames
        for frame_fn, suffix in [
            (make_mouth_open, "_mouth_open.png"),
            (make_eyes_blink, "_eyes_blink.png"),
            (make_mouth_open_blink, "_mouth_open_blink.png"),
        ]:
            frame = frame_fn(base)
            frame_path = os.path.join(OUT_DIR, f"{name}{suffix}")
            frame.save(frame_path)
            print(f"  wrote {frame_path}")
    print(f"\nGenerated {len(NPCS) * 4} Sat-1 NPC PNG files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
