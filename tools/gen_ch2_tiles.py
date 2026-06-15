#!/usr/bin/env python3
"""
gen_ch2_tiles.py — Generate ice-themed tile PNGs (S6-102).

Chapter 2 visual identity: cold blue/cyan tiles (vs Ch1 navy/orange).
Same tile grid as Ch1 (20x12 floor + wall strips), different palette.

Outputs (in assets/tilesets/ch2/):
  floor_ice.png         64x64 light blue with hex panel pattern
  floor_ice_damaged.png 64x64 darker with cracks
  wall_ice.png          64x64 cold blue with bolts
  wall_ice_damaged.png  64x64 with frost chips

Run from project root:
  python tools/gen_ch2_tiles.py
"""
import os
from PIL import Image, ImageDraw

OUT_DIR = "assets/tilesets/ch2"
TILE = 64

# Ice palette (cold blue/cyan)
ICE_LIGHT = (180, 215, 235, 255)
ICE_MID = (140, 185, 215, 255)
ICE_DARK = (90, 145, 180, 255)
ICE_SHADOW = (60, 100, 140, 255)
FROST_WHITE = (230, 245, 255, 255)
DARK = (20, 40, 60, 255)
METAL = (140, 180, 200, 255)
CRACK_COLOR = (50, 80, 110, 255)

def hex_panel(d: ImageDraw.Draw, base: tuple, accent: tuple) -> None:
    d.rectangle([0, 0, TILE - 1, TILE - 1], fill=base)
    for y in [16, 32, 48]:
        d.line([(0, y), (TILE, y)], fill=accent, width=1)
    for x in [16, 32, 48]:
        d.line([(x, 0), (x, TILE)], fill=accent, width=1)
    for cx, cy in [(4, 4), (TILE - 5, 4), (4, TILE - 5), (TILE - 5, TILE - 5)]:
        d.ellipse([cx - 1, cy - 1, cx + 1, cy + 1], fill=accent)

def make_floor_ice() -> Image.Image:
    img = Image.new("RGBA", (TILE, TILE), ICE_MID)
    d = ImageDraw.Draw(img)
    hex_panel(d, ICE_MID, ICE_DARK)
    # Add a subtle "frost" highlight in the center
    d.ellipse([TILE // 2 - 6, TILE // 2 - 6, TILE // 2 + 6, TILE // 2 + 6],
              fill=(255, 255, 255, 60))
    return img

def make_floor_ice_damaged() -> Image.Image:
    img = make_floor_ice()
    d = ImageDraw.Draw(img)
    # Frost cracks
    d.line([(8, 6), (20, 18), (28, 30), (40, 42)], fill=CRACK_COLOR, width=1)
    d.line([(35, 50), (45, 55), (55, 58)], fill=CRACK_COLOR, width=1)
    return img

def make_wall_ice() -> Image.Image:
    img = Image.new("RGBA", (TILE, TILE), ICE_SHADOW)
    d = ImageDraw.Draw(img)
    # Bolts at corners (silver/cyan)
    for cx, cy in [(6, 6), (TILE - 7, 6), (6, TILE - 7), (TILE - 7, TILE - 7)]:
        d.ellipse([cx - 2, cy - 2, cx + 2, cy + 2], fill=METAL, outline=ICE_DARK)
        d.ellipse([cx - 1, cy - 1, cx + 1, cy + 1], fill=ICE_LIGHT)
    # Center panel with frost pattern
    d.rectangle([12, 12, TILE - 13, TILE - 13], outline=ICE_DARK, width=1)
    d.line([(16, 16), (TILE - 17, 16)], fill=FROST_WHITE, width=1)
    d.line([(16, TILE - 17), (TILE - 17, TILE - 17)], fill=ICE_DARK, width=1)
    # Frost crystal at top
    d.rectangle([4, 0, TILE - 5, 2], fill=FROST_WHITE)
    return img

def make_wall_ice_damaged() -> Image.Image:
    img = make_wall_ice()
    d = ImageDraw.Draw(img)
    # Frost damage
    d.polygon([(20, 15), (40, 15), (45, 35), (35, 50), (15, 45)], fill=DARK)
    d.line([(25, 10), (28, 18)], fill=METAL, width=1)
    d.line([(38, 8), (42, 16)], fill=METAL, width=1)
    return img

def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    tiles = {
        "floor_ice.png": make_floor_ice(),
        "floor_ice_damaged.png": make_floor_ice_damaged(),
        "wall_ice.png": make_wall_ice(),
        "wall_ice_damaged.png": make_wall_ice_damaged(),
    }
    for name, img in tiles.items():
        path = os.path.join(OUT_DIR, name)
        img.save(path)
        print(f"  wrote {path}")
    print(f"\n{len(tiles)} Ch2 tile(s) generated.")

if __name__ == "__main__":
    main()
