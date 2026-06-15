#!/usr/bin/env python3
"""
gen_player_mech.py — Generate 32x32 player mech sprite (4 directions).

Per art-bible V1.0 (2026-06-12):
- Base unit: 32x32 pixels
- Palette: dark navy background, neon orange/amber for mech (warm foreground)
- Hand-painted pseudo-lighting: 1 main light + 1 ambient
- Visual identity: "lone neon in deep-space ruins"

Output: 4 PNGs (down/up/left/right) at 32x32 with alpha.

Run from project root:
  python tools/gen_player_mech.py
"""
import os
from PIL import Image

OUT_DIR = "assets/sprites/player"
SIZE = 32

# Art-bible palette (per design/art/art-bible.md)
DARK_NAVY = (16, 20, 32, 0)        # transparent
ARMOR_DARK = (60, 38, 22, 255)      # deep amber shadow
ARMOR_MID = (140, 88, 48, 255)     # amber mid
ARMOR_LIGHT = (220, 158, 80, 255)   # amber highlight
ARMOR_HOT = (255, 200, 100, 255)   # hot amber
METAL_DARK = (32, 36, 48, 255)     # gunmetal shadow
METAL_MID = (72, 78, 92, 255)      # gunmetal
METAL_LIGHT = (140, 152, 168, 255) # gunmetal highlight
ACCENT = (255, 90, 30, 255)        # neon orange accent (eyes, lights)
ENERGY = (90, 220, 255, 255)       # cyan energy glow
WINDOW = (180, 240, 255, 200)      # cyan cockpit window

def make_mech_down() -> Image.Image:
    """Front-facing mech (down direction in top-down 2D)."""
    img = Image.new("RGBA", (SIZE, SIZE), DARK_NAVY)
    px = img.load()

    # Silhouette (top-down 2D — head is top, feet bottom)
    # Head/shoulder mass (rows 4-11)
    head_silhouette = [
        # x:  10 11 12 13 14 15 16 17 18 19 20 21
        (4,  [0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0]),
        (5,  [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0]),
        (6,  [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0]),
        (7,  [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0]),
        (8,  [0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0]),
    ]
    # ... etc
    return _render_with_palette(img, px, "down")

def _render_with_palette(img, px, direction):
    # Stub — replaced by real rendering below
    return img

# === Real implementation: build each direction from a "skeleton" of named zones ===
# Each direction defines a list of (y, x_start, x_end, fill_color, optional accent)

def draw_rect(px, y, x0, x1, color):
    for x in range(x0, x1 + 1):
        if 0 <= x < SIZE and 0 <= y < SIZE:
            px[x, y] = color

def make_down() -> Image.Image:
    """Top-down 2D — player viewed from above facing down (south)."""
    img = Image.new("RGBA", (SIZE, SIZE), DARK_NAVY)
    px = img.load()

    # Outline: dark amber (back/armor base)
    # Cockpit window (cyan, glowing)
    # Head (12-19, 12-19) at top
    # Shoulders (12-15, 8-23) wide
    # Torso (16-22, 10-21) center
    # Arms (16-22, 7-9 + 22-24) side
    # Legs (23-27, 11-14 + 17-20) bottom
    # Feet (28-30, 10-15 + 16-21) bottom

    # === Head (rows 4-7, center 12-19) ===
    draw_rect(px, 4, 13, 18, ARMOR_DARK)   # head outline top
    draw_rect(px, 5, 12, 19, ARMOR_MID)    # head body
    draw_rect(px, 6, 12, 19, ARMOR_MID)
    # Cockpit window (cyan glow at front)
    draw_rect(px, 5, 14, 17, WINDOW)
    draw_rect(px, 6, 14, 17, WINDOW)
    # Eye lights (neon orange) at top corners
    px[13, 5] = ACCENT
    px[18, 5] = ACCENT

    # === Shoulders (rows 8-11, wider) ===
    draw_rect(px, 8, 9, 22, ARMOR_DARK)   # shoulder outline
    draw_rect(px, 9, 8, 23, ARMOR_MID)
    draw_rect(px, 10, 8, 23, ARMOR_LIGHT)
    draw_rect(px, 11, 9, 22, ARMOR_MID)
    # Energy core (cyan glow at chest top)
    draw_rect(px, 10, 14, 17, ENERGY)
    draw_rect(px, 10, 15, 16, WINDOW)

    # === Torso (rows 12-18) ===
    draw_rect(px, 12, 10, 21, ARMOR_DARK)
    draw_rect(px, 13, 10, 21, ARMOR_MID)
    draw_rect(px, 14, 10, 21, ARMOR_LIGHT)
    draw_rect(px, 15, 10, 21, ARMOR_LIGHT)
    draw_rect(px, 16, 10, 21, ARMOR_MID)
    draw_rect(px, 17, 10, 21, ARMOR_DARK)
    # Chest detail line
    draw_rect(px, 14, 15, 16, METAL_DARK)
    draw_rect(px, 15, 15, 16, METAL_DARK)
    # Left/right armor plates
    draw_rect(px, 13, 11, 12, METAL_MID)
    draw_rect(px, 14, 11, 12, METAL_MID)
    draw_rect(px, 13, 19, 20, METAL_MID)
    draw_rect(px, 14, 19, 20, METAL_MID)

    # === Arms (rows 13-20, sides) ===
    # Left arm (weapon side)
    draw_rect(px, 13, 6, 9, ARMOR_DARK)
    draw_rect(px, 14, 6, 9, ARMOR_MID)
    draw_rect(px, 15, 6, 9, ARMOR_LIGHT)
    draw_rect(px, 16, 6, 9, ARMOR_MID)
    draw_rect(px, 17, 6, 9, ARMOR_DARK)
    # Right arm
    draw_rect(px, 13, 22, 25, ARMOR_DARK)
    draw_rect(px, 14, 22, 25, ARMOR_MID)
    draw_rect(px, 15, 22, 25, ARMOR_LIGHT)
    draw_rect(px, 16, 22, 25, ARMOR_MID)
    draw_rect(px, 17, 22, 25, ARMOR_DARK)
    # Weapon (left arm — blaster barrel)
    draw_rect(px, 18, 4, 6, METAL_DARK)
    draw_rect(px, 19, 4, 6, METAL_LIGHT)
    draw_rect(px, 20, 4, 6, METAL_MID)
    draw_rect(px, 21, 4, 6, METAL_DARK)
    # Muzzle flash tip (energy)
    px[4, 22] = ENERGY
    px[6, 22] = ENERGY
    px[5, 23] = WINDOW

    # === Legs (rows 19-26) ===
    # Left leg
    draw_rect(px, 19, 11, 14, ARMOR_DARK)
    draw_rect(px, 20, 11, 14, ARMOR_MID)
    draw_rect(px, 21, 11, 14, ARMOR_LIGHT)
    draw_rect(px, 22, 11, 14, ARMOR_MID)
    draw_rect(px, 23, 11, 14, ARMOR_DARK)
    # Right leg
    draw_rect(px, 19, 17, 20, ARMOR_DARK)
    draw_rect(px, 20, 17, 20, ARMOR_MID)
    draw_rect(px, 21, 17, 20, ARMOR_LIGHT)
    draw_rect(px, 22, 17, 20, ARMOR_MID)
    draw_rect(px, 23, 17, 20, ARMOR_DARK)
    # Knee joints (metal)
    draw_rect(px, 21, 12, 14, METAL_DARK)
    draw_rect(px, 21, 17, 20, METAL_DARK)
    # Hip joint
    draw_rect(px, 18, 13, 18, METAL_DARK)

    # === Feet (rows 24-27) ===
    # Left foot
    draw_rect(px, 24, 10, 15, ARMOR_MID)
    draw_rect(px, 25, 10, 15, ARMOR_LIGHT)
    draw_rect(px, 26, 10, 15, ARMOR_DARK)
    # Right foot
    draw_rect(px, 24, 16, 21, ARMOR_MID)
    draw_rect(px, 25, 16, 21, ARMOR_LIGHT)
    draw_rect(px, 26, 16, 21, ARMOR_DARK)

    # Edge highlights (light from upper-left per art-bible)
    for y in range(4, 26):
        x = 9
        if 0 <= x < SIZE and px[x, y] != DARK_NAVY and px[x-1 if x > 0 else 0, y] == DARK_NAVY:
            px[x, y] = ARMOR_HOT
    for y in range(4, 18):
        x = 22
        if 0 <= x < SIZE and px[x, y] != DARK_NAVY and px[x+1 if x < SIZE-1 else 0, y] == DARK_NAVY:
            px[x, y] = ARMOR_DARK

    return img

def make_up() -> Image.Image:
    """Player viewed from above facing up (north) — back of mech visible."""
    img = Image.new("RGBA", (SIZE, SIZE), DARK_NAVY)
    px = img.load()

    # Back of head (rows 4-7) — no cockpit window
    draw_rect(px, 4, 13, 18, ARMOR_DARK)
    draw_rect(px, 5, 12, 19, ARMOR_MID)
    draw_rect(px, 6, 12, 19, ARMOR_MID)
    draw_rect(px, 7, 12, 19, ARMOR_DARK)
    # Antenna/spine
    px[15, 3] = METAL_MID
    px[16, 3] = METAL_MID
    px[15, 2] = METAL_LIGHT
    px[16, 2] = METAL_LIGHT
    # Rear vents
    draw_rect(px, 5, 14, 17, METAL_DARK)
    draw_rect(px, 6, 14, 17, METAL_DARK)

    # Shoulders
    draw_rect(px, 8, 9, 22, ARMOR_DARK)
    draw_rect(px, 9, 8, 23, ARMOR_MID)
    draw_rect(px, 10, 8, 23, ARMOR_LIGHT)
    draw_rect(px, 11, 9, 22, ARMOR_MID)
    # Backpack / reactor
    draw_rect(px, 10, 13, 18, METAL_DARK)
    draw_rect(px, 11, 13, 18, METAL_DARK)
    draw_rect(px, 12, 13, 18, ARMOR_DARK)

    # Torso back
    draw_rect(px, 12, 10, 21, ARMOR_DARK)
    draw_rect(px, 13, 10, 21, ARMOR_MID)
    draw_rect(px, 14, 10, 21, ARMOR_LIGHT)
    draw_rect(px, 15, 10, 21, ARMOR_LIGHT)
    draw_rect(px, 16, 10, 21, ARMOR_MID)
    draw_rect(px, 17, 10, 21, ARMOR_DARK)
    # Back spine detail
    draw_rect(px, 14, 15, 16, METAL_DARK)
    draw_rect(px, 15, 15, 16, METAL_DARK)

    # Arms
    draw_rect(px, 13, 6, 9, ARMOR_DARK)
    draw_rect(px, 14, 6, 9, ARMOR_MID)
    draw_rect(px, 15, 6, 9, ARMOR_LIGHT)
    draw_rect(px, 16, 6, 9, ARMOR_MID)
    draw_rect(px, 17, 6, 9, ARMOR_DARK)
    draw_rect(px, 13, 22, 25, ARMOR_DARK)
    draw_rect(px, 14, 22, 25, ARMOR_MID)
    draw_rect(px, 15, 22, 25, ARMOR_LIGHT)
    draw_rect(px, 16, 22, 25, ARMOR_MID)
    draw_rect(px, 17, 22, 25, ARMOR_DARK)

    # Legs (same as down)
    draw_rect(px, 19, 11, 14, ARMOR_DARK)
    draw_rect(px, 20, 11, 14, ARMOR_MID)
    draw_rect(px, 21, 11, 14, ARMOR_LIGHT)
    draw_rect(px, 22, 11, 14, ARMOR_MID)
    draw_rect(px, 23, 11, 14, ARMOR_DARK)
    draw_rect(px, 19, 17, 20, ARMOR_DARK)
    draw_rect(px, 20, 17, 20, ARMOR_MID)
    draw_rect(px, 21, 17, 20, ARMOR_LIGHT)
    draw_rect(px, 22, 17, 20, ARMOR_MID)
    draw_rect(px, 23, 17, 20, ARMOR_DARK)
    draw_rect(px, 21, 12, 14, METAL_DARK)
    draw_rect(px, 21, 17, 20, METAL_DARK)
    draw_rect(px, 18, 13, 18, METAL_DARK)

    # Feet
    draw_rect(px, 24, 10, 15, ARMOR_MID)
    draw_rect(px, 25, 10, 15, ARMOR_LIGHT)
    draw_rect(px, 26, 10, 15, ARMOR_DARK)
    draw_rect(px, 24, 16, 21, ARMOR_MID)
    draw_rect(px, 25, 16, 21, ARMOR_LIGHT)
    draw_rect(px, 26, 16, 21, ARMOR_DARK)

    return img

def make_left() -> Image.Image:
    """Player viewed from above facing left (west)."""
    img = Image.new("RGBA", (SIZE, SIZE), DARK_NAVY)
    px = img.load()

    # Head (left side, no window — facing left)
    draw_rect(px, 4, 14, 19, ARMOR_DARK)
    draw_rect(px, 5, 13, 19, ARMOR_MID)
    draw_rect(px, 6, 13, 19, ARMOR_MID)
    draw_rect(px, 7, 13, 19, ARMOR_DARK)
    # Side eye glow (left direction)
    px[13, 5] = ACCENT
    px[13, 6] = ACCENT

    # Shoulders (asymmetric — narrower on left since facing that way)
    draw_rect(px, 8, 11, 22, ARMOR_DARK)
    draw_rect(px, 9, 10, 22, ARMOR_MID)
    draw_rect(px, 10, 10, 22, ARMOR_LIGHT)
    draw_rect(px, 11, 11, 22, ARMOR_MID)
    # Energy core (cyan)
    draw_rect(px, 10, 14, 18, ENERGY)

    # Torso (offset slightly left since facing that way)
    draw_rect(px, 12, 11, 22, ARMOR_DARK)
    draw_rect(px, 13, 10, 22, ARMOR_MID)
    draw_rect(px, 14, 10, 22, ARMOR_LIGHT)
    draw_rect(px, 15, 10, 22, ARMOR_LIGHT)
    draw_rect(px, 16, 10, 22, ARMOR_MID)
    draw_rect(px, 17, 11, 22, ARMOR_DARK)

    # Both arms (visible since side view, but weapon in front)
    # Front arm (left, holding weapon — extended forward)
    draw_rect(px, 14, 7, 11, ARMOR_DARK)
    draw_rect(px, 15, 7, 11, ARMOR_MID)
    draw_rect(px, 16, 7, 11, ARMOR_LIGHT)
    draw_rect(px, 17, 7, 11, ARMOR_MID)
    draw_rect(px, 18, 7, 11, ARMOR_DARK)
    # Back arm (right, behind body)
    draw_rect(px, 14, 19, 22, ARMOR_DARK)
    draw_rect(px, 15, 19, 22, ARMOR_MID)
    draw_rect(px, 16, 19, 22, ARMOR_LIGHT)
    draw_rect(px, 17, 19, 22, ARMOR_MID)
    draw_rect(px, 18, 19, 22, ARMOR_DARK)

    # Weapon barrel (extended forward, left)
    draw_rect(px, 18, 3, 8, METAL_DARK)
    draw_rect(px, 19, 3, 8, METAL_LIGHT)
    draw_rect(px, 20, 3, 8, METAL_MID)
    draw_rect(px, 21, 3, 8, METAL_DARK)
    # Muzzle
    px[3, 22] = ENERGY
    px[2, 22] = WINDOW
    px[3, 21] = ACCENT

    # Legs
    draw_rect(px, 19, 12, 15, ARMOR_DARK)
    draw_rect(px, 20, 12, 15, ARMOR_MID)
    draw_rect(px, 21, 12, 15, ARMOR_LIGHT)
    draw_rect(px, 22, 12, 15, ARMOR_MID)
    draw_rect(px, 23, 12, 15, ARMOR_DARK)
    draw_rect(px, 19, 17, 21, ARMOR_DARK)
    draw_rect(px, 20, 17, 21, ARMOR_MID)
    draw_rect(px, 21, 17, 21, ARMOR_LIGHT)
    draw_rect(px, 22, 17, 21, ARMOR_MID)
    draw_rect(px, 23, 17, 21, ARMOR_DARK)

    # Feet
    draw_rect(px, 24, 11, 16, ARMOR_MID)
    draw_rect(px, 25, 11, 16, ARMOR_LIGHT)
    draw_rect(px, 26, 11, 16, ARMOR_DARK)
    draw_rect(px, 24, 16, 21, ARMOR_MID)
    draw_rect(px, 25, 16, 21, ARMOR_LIGHT)
    draw_rect(px, 26, 16, 21, ARMOR_DARK)
    return img

def make_right() -> Image.Image:
    """Player viewed from above facing right (east) — mirror of left."""
    img = Image.new("RGBA", (SIZE, SIZE), DARK_NAVY)
    px = img.load()

    # Head (right side)
    draw_rect(px, 4, 12, 17, ARMOR_DARK)
    draw_rect(px, 5, 12, 18, ARMOR_MID)
    draw_rect(px, 6, 12, 18, ARMOR_MID)
    draw_rect(px, 7, 12, 17, ARMOR_DARK)
    # Side eye glow (right direction)
    px[18, 5] = ACCENT
    px[18, 6] = ACCENT

    # Shoulders
    draw_rect(px, 8, 9, 20, ARMOR_DARK)
    draw_rect(px, 9, 9, 21, ARMOR_MID)
    draw_rect(px, 10, 9, 21, ARMOR_LIGHT)
    draw_rect(px, 11, 9, 20, ARMOR_MID)
    draw_rect(px, 10, 13, 19, ENERGY)

    # Torso
    draw_rect(px, 12, 9, 20, ARMOR_DARK)
    draw_rect(px, 13, 9, 21, ARMOR_MID)
    draw_rect(px, 14, 9, 21, ARMOR_LIGHT)
    draw_rect(px, 15, 9, 21, ARMOR_LIGHT)
    draw_rect(px, 16, 9, 21, ARMOR_MID)
    draw_rect(px, 17, 9, 20, ARMOR_DARK)

    # Arms — back arm holding weapon extended forward (right)
    draw_rect(px, 14, 20, 24, ARMOR_DARK)
    draw_rect(px, 15, 20, 24, ARMOR_MID)
    draw_rect(px, 16, 20, 24, ARMOR_LIGHT)
    draw_rect(px, 17, 20, 24, ARMOR_MID)
    draw_rect(px, 18, 20, 24, ARMOR_DARK)
    # Front arm (left, behind body)
    draw_rect(px, 14, 9, 12, ARMOR_DARK)
    draw_rect(px, 15, 9, 12, ARMOR_MID)
    draw_rect(px, 16, 9, 12, ARMOR_LIGHT)
    draw_rect(px, 17, 9, 12, ARMOR_MID)
    draw_rect(px, 18, 9, 12, ARMOR_DARK)

    # Weapon barrel (right)
    draw_rect(px, 18, 23, 28, METAL_DARK)
    draw_rect(px, 19, 23, 28, METAL_LIGHT)
    draw_rect(px, 20, 23, 28, METAL_MID)
    draw_rect(px, 21, 23, 28, METAL_DARK)
    px[28, 22] = ENERGY
    px[29, 22] = WINDOW
    px[28, 21] = ACCENT

    # Legs
    draw_rect(px, 19, 10, 13, ARMOR_DARK)
    draw_rect(px, 20, 10, 13, ARMOR_MID)
    draw_rect(px, 21, 10, 13, ARMOR_LIGHT)
    draw_rect(px, 22, 10, 13, ARMOR_MID)
    draw_rect(px, 23, 10, 13, ARMOR_DARK)
    draw_rect(px, 19, 16, 19, ARMOR_DARK)
    draw_rect(px, 20, 16, 19, ARMOR_MID)
    draw_rect(px, 21, 16, 19, ARMOR_LIGHT)
    draw_rect(px, 22, 16, 19, ARMOR_MID)
    draw_rect(px, 23, 16, 19, ARMOR_DARK)

    # Feet
    draw_rect(px, 24, 9, 14, ARMOR_MID)
    draw_rect(px, 25, 9, 14, ARMOR_LIGHT)
    draw_rect(px, 26, 9, 14, ARMOR_DARK)
    draw_rect(px, 24, 15, 20, ARMOR_MID)
    draw_rect(px, 25, 15, 20, ARMOR_LIGHT)
    draw_rect(px, 26, 15, 20, ARMOR_DARK)
    return img

def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    directions = {
        "down": make_down(),
        "up": make_up(),
        "left": make_left(),
        "right": make_right(),
    }
    for name, img in directions.items():
        path = os.path.join(OUT_DIR, f"mech_{name}.png")
        img.save(path)
        print(f"  wrote {path} ({img.size[0]}x{img.size[1]})")
    print(f"\n{len(directions)} sprite(s) generated.")

if __name__ == "__main__":
    main()
