#!/usr/bin/env python3
"""
gen_npc_portraits.py — Generate NPC portrait PNGs (S6-015).

Per art-bible: 64x64 pixel-art portraits in dark sci-fi ruin palette.
Each NPC has a distinct silhouette and color so players recognize
them at a glance.

Outputs (in assets/sprites/npcs/):
  vera_merchant.png       (wiry woman, oil-stained fingers, amber+navy)
  marlow_ghost.png        (faded holo-figure, transparent edges, cyan+gray)
  courier_14.png          (helmeted runner, red+gray, antenna)
  salvage_drone_operator.png  (small maintenance drone, yellow+navy)

Run from project root:
  python tools/gen_npc_portraits.py
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
AMBER = (220, 158, 80, 255)
AMBER_DARK = (140, 88, 48, 255)
AMBER_LIGHT = (255, 200, 100, 255)
RED = (220, 50, 50, 255)
RED_DARK = (140, 30, 30, 255)
CYAN = (90, 220, 255, 255)
CYAN_DIM = (50, 140, 180, 255)
WHITE = (240, 240, 240, 255)
SKIN = (200, 160, 130, 255)
SKIN_DARK = (140, 100, 70, 255)
HAIR_BROWN = (100, 70, 50, 255)
HAIR_GRAY = (180, 180, 190, 255)

def make_vera() -> Image.Image:
    """Wiry merchant woman — amber jacket, oil-stained fingers."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Body / jacket (amber)
    d.rectangle([18, 28, 46, 60], fill=AMBER_DARK, outline=AMBER)
    # Jacket details — pockets
    d.rectangle([22, 40, 30, 50], outline=AMBER, width=1)
    d.rectangle([34, 40, 42, 50], outline=AMBER, width=1)
    # Neck
    d.rectangle([28, 24, 36, 28], fill=SKIN)
    # Head (skin tone)
    d.ellipse([24, 8, 40, 28], fill=SKIN, outline=SKIN_DARK)
    # Hair (short brown, swept back)
    d.rectangle([24, 6, 40, 14], fill=HAIR_BROWN)
    d.polygon([(24, 12), (20, 14), (22, 18), (24, 14)], fill=HAIR_BROWN)
    d.polygon([(40, 12), (44, 14), (42, 18), (40, 14)], fill=HAIR_BROWN)
    # Eyes (focused, narrow)
    d.rectangle([28, 16, 30, 18], fill=NAVY)
    d.rectangle([34, 16, 36, 18], fill=NAVY)
    # Mouth (slight smirk)
    d.line([(30, 22), (34, 22)], fill=SKIN_DARK, width=1)
    # Oil stain on left hand
    d.ellipse([18, 50, 24, 56], fill=(40, 30, 20, 255))
    # Tool/weapon at hip (small wrench)
    d.rectangle([44, 44, 50, 48], fill=METAL, outline=GRAY_DARK)
    return img

def make_marlow() -> Image.Image:
    """Marlow the ghost — faded holo-figure, transparent edges."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Faded body (cyan with low alpha for transparency feel)
    body = (40, 80, 110, 180)  # dim cyan
    d.rectangle([20, 28, 44, 58], fill=body, outline=CYAN_DIM)
    d.line([(20, 28), (44, 58)], fill=(80, 140, 170, 100), width=1)
    d.line([(44, 28), (20, 58)], fill=(80, 140, 170, 100), width=1)
    # Faded head
    d.ellipse([24, 8, 40, 28], fill=body, outline=CYAN_DIM)
    # Eyes (no pupils — ghost)
    d.ellipse([28, 16, 30, 18], fill=CYAN)
    d.ellipse([34, 16, 36, 18], fill=CYAN)
    # "Data readout" lines on body
    for y in [32, 36, 40, 44]:
        d.line([(24, y), (32, y)], fill=CYAN, width=1)
    # Antenna
    d.line([(32, 8), (32, 4)], fill=CYAN_DIM, width=1)
    d.ellipse([31, 3, 33, 5], fill=CYAN)
    return img

def make_courier() -> Image.Image:
    """Courier 14 — helmeted runner, red armor, antenna."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Body / red armor
    d.rectangle([18, 28, 46, 60], fill=RED_DARK, outline=RED)
    # Armor chest plate
    d.rectangle([24, 32, 40, 44], fill=GRAY_DARK, outline=RED)
    d.rectangle([28, 36, 36, 40], fill=(40, 50, 60, 255))  # dark slot
    # Helmet (full)
    d.ellipse([20, 4, 44, 28], fill=GRAY_DARK, outline=METAL)
    # Visor (cyan)
    d.rectangle([24, 14, 40, 22], fill=CYAN)
    d.rectangle([26, 16, 38, 20], fill=(140, 240, 255, 200))  # visor highlight
    # Antenna
    d.line([(40, 4), (44, 0)], fill=METAL, width=1)
    d.ellipse([43, -1, 45, 2], fill=RED)
    # "14" insignia
    d.text((29, 50), "14", fill=WHITE)
    return img

def make_drone_op() -> Image.Image:
    """Salvage drone operator — small maintenance drone."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Floating body (rounded rectangle)
    d.rounded_rectangle([16, 22, 48, 50], radius=8, fill=GRAY_DARK, outline=AMBER)
    # Central eye / camera
    d.ellipse([26, 28, 38, 40], fill=NAVY, outline=AMBER_LIGHT)
    d.ellipse([28, 30, 36, 38], fill=(80, 100, 140, 255))  # lens
    d.ellipse([30, 32, 34, 36], fill=(140, 180, 220, 255))  # highlight
    # Hover jets (top + bottom)
    d.ellipse([22, 18, 26, 22], fill=AMBER, outline=AMBER_DARK)
    d.ellipse([38, 18, 42, 22], fill=AMBER, outline=AMBER_DARK)
    d.ellipse([22, 50, 26, 54], fill=AMBER, outline=AMBER_DARK)
    d.ellipse([38, 50, 42, 54], fill=AMBER, outline=AMBER_DARK)
    # Antenna
    d.line([(32, 22), (32, 14)], fill=AMBER_DARK, width=1)
    d.ellipse([31, 12, 33, 14], fill=RED)
    return img

def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    portraits = {
        "vera_merchant.png": make_vera(),
        "marlow_ghost.png": make_marlow(),
        "courier_14.png": make_courier(),
        "salvage_drone_operator.png": make_drone_op(),
    }
    for name, img in portraits.items():
        path = os.path.join(OUT_DIR, name)
        img.save(path)
        print(f"  wrote {path} ({img.size[0]}x{img.size[1]})")
    print(f"\n{len(portraits)} NPC portrait(s) generated.")

if __name__ == "__main__":
    main()
