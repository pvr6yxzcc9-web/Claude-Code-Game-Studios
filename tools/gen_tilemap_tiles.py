#!/usr/bin/env python3
"""
gen_tilemap_tiles.py — Generate TileMap tilesets (S6-009).

Per art-bible V1.0:
- Dark sci-fi ruin theme
- Floor: dark navy with subtle hex panel pattern
- Walls: heavy industrial gray with red emergency-light strips

Outputs (in assets/tilesets/):
  floor_main.png         256x256 (4 panels of 64x64, but exported as single tile)
  floor_damaged.png      256x256 (broken panels, exposed wires)
  floor_clean.png        256x256 (pristine)
  floor_warning.png      256x256 (yellow hazard strips)
  wall_industrial.png    256x256 (heavy wall, dark with bolts)
  wall_damaged.png       256x256 (breached wall, sparks)

Each PNG is 64x64 pixel-art tile designed to be tileable. Generated as
Texture2D in Godot. level_runtime.gd uses Sprite2D instances placed in
a grid (we don't need full TileMap infrastructure for ship).

Run from project root:
  python tools/gen_tilemap_tiles.py
"""
import os
from PIL import Image, ImageDraw

OUT_DIR = "assets/tilesets"
TILE = 64  # base unit (matches art-bible)

# Palette
NAVY = (16, 20, 32, 255)
NAVY_DARK = (10, 14, 24, 255)
NAVY_MID = (24, 30, 48, 255)
GRAY = (60, 64, 72, 255)
GRAY_DARK = (40, 44, 52, 255)
GRAY_MID = (80, 84, 92, 255)
METAL = (140, 152, 168, 255)
AMBER = (220, 158, 80, 255)
AMBER_LIGHT = (255, 200, 100, 255)
RED = (220, 50, 50, 255)
YELLOW = (220, 200, 80, 255)
DARK = (10, 14, 24, 255)
WIRE = (140, 80, 60, 255)

def hex_panel_pattern(draw: ImageDraw, base_color: tuple, accent: tuple) -> None:
    """Draw a hex-panel floor pattern across a 64x64 tile."""
    draw.rectangle([0, 0, TILE - 1, TILE - 1], fill=base_color)
    # Hex pattern via 4 horizontal stripes + diagonal lines
    for y in [16, 32, 48]:
        draw.line([(0, y), (TILE, y)], fill=accent, width=1)
    for x in [16, 32, 48]:
        draw.line([(x, 0), (x, TILE)], fill=accent, width=1)
    # Corner bolts
    for cx, cy in [(4, 4), (TILE - 5, 4), (4, TILE - 5), (TILE - 5, TILE - 5)]:
        draw.ellipse([cx - 1, cy - 1, cx + 1, cy + 1], fill=accent)
    # Center accent
    draw.ellipse([TILE // 2 - 2, TILE // 2 - 2, TILE // 2 + 2, TILE // 2 + 2], fill=accent)

def make_floor_main() -> Image.Image:
    img = Image.new("RGBA", (TILE, TILE), NAVY)
    draw = ImageDraw.Draw(img)
    hex_panel_pattern(draw, NAVY_MID, GRAY)
    return img

def make_floor_damaged() -> Image.Image:
    img = Image.new("RGBA", (TILE, TILE), NAVY_DARK)
    draw = ImageDraw.Draw(img)
    hex_panel_pattern(draw, NAVY_DARK, GRAY_DARK)
    # Damage: crack + exposed wire
    draw.line([(10, 10), (30, 30), (45, 35)], fill=GRAY_MID, width=1)
    draw.line([(30, 30), (50, 50)], fill=WIRE, width=1)
    draw.ellipse([28, 28, 35, 35], fill=(60, 30, 20, 255))  # scorch
    return img

def make_floor_clean() -> Image.Image:
    img = Image.new("RGBA", (TILE, TILE), NAVY)
    draw = ImageDraw.Draw(img)
    hex_panel_pattern(draw, NAVY_MID, METAL)
    # Brighter (cleaner) version with subtle glow
    draw.ellipse([TILE // 2 - 4, TILE // 2 - 4, TILE // 2 + 4, TILE // 2 + 4], fill=(120, 200, 255, 180))
    return img

def make_floor_warning() -> Image.Image:
    img = Image.new("RGBA", (TILE, TILE), NAVY_DARK)
    draw = ImageDraw.Draw(img)
    hex_panel_pattern(draw, NAVY_DARK, YELLOW)
    # Yellow hazard stripes at edges
    for i in range(0, TILE, 8):
        draw.polygon([(i, 0), (i + 4, 0), (i + 8, 4), (i + 4, 4)], fill=YELLOW)
    for i in range(0, TILE, 8):
        draw.polygon([(i, TILE - 4), (i + 4, TILE - 4), (i + 8, TILE), (i + 4, TILE)], fill=YELLOW)
    return img

def make_wall_industrial() -> Image.Image:
    img = Image.new("RGBA", (TILE, TILE), GRAY_DARK)
    draw = ImageDraw.Draw(img)
    # Heavy wall texture
    draw.rectangle([0, 0, TILE - 1, TILE - 1], fill=GRAY_DARK)
    # Bolts at corners
    for cx, cy in [(6, 6), (TILE - 7, 6), (6, TILE - 7), (TILE - 7, TILE - 7)]:
        draw.ellipse([cx - 2, cy - 2, cx + 2, cy + 2], fill=GRAY_MID)
        draw.ellipse([cx - 1, cy - 1, cx + 1, cy + 1], fill=METAL)
    # Center panel
    draw.rectangle([12, 12, TILE - 13, TILE - 13], outline=GRAY, width=1)
    draw.rectangle([20, 20, TILE - 21, TILE - 21], outline=GRAY, width=1)
    # Red emergency light strip at top
    draw.rectangle([4, 0, TILE - 5, 2], fill=RED)
    return img

def make_wall_damaged() -> Image.Image:
    img = Image.new("RGBA", (TILE, TILE), GRAY_DARK)
    draw = ImageDraw.Draw(img)
    make_wall_industrial()  # start with industrial as base
    # Re-draw with damage on top
    # Big breach
    draw.polygon([(20, 15), (40, 15), (45, 35), (35, 50), (15, 45)], fill=DARK)
    # Sparks at breach edges
    for sx, sy in [(22, 18), (40, 18), (35, 48), (18, 44)]:
        draw.line([(sx, sy), (sx + 4, sy + 4)], fill=AMBER_LIGHT, width=1)
    # Exposed rebar
    draw.line([(25, 10), (28, 18)], fill=GRAY_MID, width=1)
    draw.line([(38, 8), (42, 16)], fill=GRAY_MID, width=1)
    return img

def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    tiles = {
        "floor_main.png": make_floor_main(),
        "floor_damaged.png": make_floor_damaged(),
        "floor_clean.png": make_floor_clean(),
        "floor_warning.png": make_floor_warning(),
        "wall_industrial.png": make_wall_industrial(),
        "wall_damaged.png": make_wall_damaged(),
    }
    for name, img in tiles.items():
        path = os.path.join(OUT_DIR, name)
        img.save(path)
        print(f"  wrote {path} ({img.size[0]}x{img.size[1]})")
    print(f"\n{len(tiles)} tile(s) generated.")

if __name__ == "__main__":
    main()
