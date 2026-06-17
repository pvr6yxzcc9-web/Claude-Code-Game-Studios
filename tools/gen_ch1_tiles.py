#!/usr/bin/env python3
"""
gen_ch1_tiles.py — Generate Sat-1 tile PNGs (S18-001).

Per art-bible + per-room layouts: Sat-1 = "The Drift Wreck" —
abandoned derelict cargo ship, salvage crew, frozen by deep-space cold.

Tile themes:
  floor_derelict.png         — industrial metal floor plates
  floor_derelict_damaged.png  — with cracks and rust
  wall_derelict.png          — riveted metal walls
  wall_derelict_damaged.png   — with holes and bent panels

Outputs (in assets/tilesets/ch1/):
  floor_derelict.png
  floor_derelict_damaged.png
  wall_derelict.png
  wall_derelict_damaged.png

All 32x32 RGBA, matching ch3 hive tile size (S8-007).

Run from project root:
  python tools/gen_ch1_tiles.py
"""
import math
import os
import random
from PIL import Image, ImageDraw

OUT_DIR = "assets/tilesets/ch1"
TILE = 32

# Palette — industrial derelict (navy + rust + metal)
NAVY = (20, 25, 40, 255)
NAVY_DARK = (12, 16, 28, 255)
NAVY_MID = (30, 38, 58, 255)
STEEL = (110, 120, 135, 255)
STEEL_LIGHT = (150, 160, 175, 255)
STEEL_DARK = (70, 78, 92, 255)
RUST = (140, 80, 50, 255)
RUST_DARK = (90, 50, 30, 255)
RUST_BRIGHT = (180, 110, 70, 255)
FROST_WHITE = (220, 235, 250, 255)
WARN_YELLOW = (220, 200, 80, 255)
DARK = (8, 12, 20, 255)


def rivet(d: ImageDraw.Draw, x: int, y: int) -> None:
    """Draw a small metal rivet at (x, y)."""
    d.ellipse([x - 1, y - 1, x + 1, y + 1], fill=STEEL_DARK)
    d.ellipse([x - 1, y - 1, x, y], fill=STEEL_LIGHT)


def crack(d: ImageDraw.Draw, length: int = 8) -> None:
    """Draw a random crack on the tile."""
    x1 = random.randint(2, TILE - 4)
    y1 = random.randint(2, TILE - 4)
    for _ in range(length):
        dx = random.choice([-1, 0, 1])
        dy = random.choice([-1, 0, 1])
        x2 = max(0, min(TILE - 1, x1 + dx))
        y2 = max(0, min(TILE - 1, y1 + dy))
        d.line([(x1, y1), (x2, y2)], fill=DARK, width=1)
        x1, y1 = x2, y2


def rust_stain(d: ImageDraw.Draw, count: int = 3) -> None:
    """Draw rust stains."""
    for _ in range(count):
        cx = random.randint(2, TILE - 4)
        cy = random.randint(2, TILE - 4)
        r = random.randint(2, 4)
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=RUST)
        # Darker edges
        d.ellipse([cx - r, cy - r, cx + r - 1, cy + r - 1], outline=RUST_DARK)


def make_floor_derelict() -> Image.Image:
    """Industrial metal floor plates with 4 panels + corner rivets."""
    img = Image.new("RGBA", (TILE, TILE), STEEL_DARK)
    d = ImageDraw.Draw(img)
    # 2x2 metal plate grid
    for x in [0, 16]:
        for y in [0, 16]:
            d.rectangle([x + 1, y + 1, x + 15, y + 15], fill=STEEL, outline=STEEL_DARK)
            # Plate highlight (top-left)
            d.line([(x + 2, y + 2), (x + 14, y + 2)], fill=STEEL_LIGHT, width=1)
            d.line([(x + 2, y + 2), (x + 2, y + 14)], fill=STEEL_LIGHT, width=1)
            # Plate shadow (bottom-right)
            d.line([(x + 14, y + 2), (x + 14, y + 14)], fill=NAVY_DARK, width=1)
            d.line([(x + 2, y + 14), (x + 14, y + 14)], fill=NAVY_DARK, width=1)
            # Corner rivets
            rivet(d, x + 3, y + 3)
            rivet(d, x + 13, y + 3)
            rivet(d, x + 3, y + 13)
            rivet(d, x + 13, y + 13)
    # Center joint darkening
    d.line([(15, 0), (15, TILE)], fill=NAVY, width=1)
    d.line([(0, 15), (TILE, 15)], fill=NAVY, width=1)
    return img


def make_floor_derelict_damaged() -> Image.Image:
    """Damaged floor — base + cracks + rust stains."""
    img = make_floor_derelict()
    d = ImageDraw.Draw(img)
    # 2-3 cracks
    for _ in range(random.randint(2, 3)):
        crack(d, length=random.randint(5, 10))
    # 1-2 rust stains
    rust_stain(d, count=random.randint(1, 2))
    return img


def make_wall_derelict() -> Image.Image:
    """Riveted metal wall panels."""
    img = Image.new("RGBA", (TILE, TILE), NAVY)
    d = ImageDraw.Draw(img)
    # Vertical panel strips
    for x in [0, 8, 16, 24]:
        d.rectangle([x, 0, x + 7, TILE - 1], fill=STEEL_DARK, outline=NAVY_DARK)
        # Panel highlight (left edge)
        d.line([(x + 1, 0), (x + 1, TILE - 1)], fill=STEEL, width=1)
    # Horizontal joint at midpoint
    d.line([(0, 16), (TILE, 16)], fill=NAVY_DARK, width=1)
    d.line([(0, 17), (TILE, 17)], fill=STEEL_DARK, width=1)
    # Rivets on each panel
    for x in [0, 8, 16, 24]:
        rivet(d, x + 4, 4)
        rivet(d, x + 4, 12)
        rivet(d, x + 4, 20)
        rivet(d, x + 4, 28)
    return img


def make_wall_derelict_damaged() -> Image.Image:
    """Damaged wall — bent panels + holes + warning sign."""
    img = make_wall_derelict()
    d = ImageDraw.Draw(img)
    # 1 large hole (dark)
    hx = random.randint(4, TILE - 8)
    hy = random.randint(4, TILE - 8)
    hr = random.randint(3, 5)
    d.ellipse([hx - hr, hy - hr, hx + hr, hy + hr], fill=DARK)
    # Bent metal (jagged lines)
    for _ in range(3):
        x1 = random.randint(0, TILE - 1)
        y1 = random.randint(0, TILE - 1)
        d.line([(x1, y1), (x1 + random.randint(-4, 4), y1 + random.randint(-4, 4))],
               fill=NAVY_DARK, width=1)
    # Optional warning stripe on one panel
    if random.random() > 0.5:
        d.rectangle([1, 18, 7, 26], fill=WARN_YELLOW)
        d.rectangle([1, 22, 7, 23], fill=NAVY_DARK)  # black stripe
    return img


TILES = [
    ("floor_derelict", make_floor_derelict),
    ("floor_derelict_damaged", make_floor_derelict_damaged),
    ("wall_derelict", make_wall_derelict),
    ("wall_derelict_damaged", make_wall_derelict_damaged),
]


def main() -> int:
    os.makedirs(OUT_DIR, exist_ok=True)
    random.seed(20260617)  # deterministic
    for name, fn in TILES:
        img = fn()
        path = os.path.join(OUT_DIR, f"{name}.png")
        img.save(path, optimize=True)
        print(f"  wrote {path} ({TILE}x{TILE})")
    print(f"\nGenerated {len(TILES)} ch1 tileset PNG files in {OUT_DIR}/")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
