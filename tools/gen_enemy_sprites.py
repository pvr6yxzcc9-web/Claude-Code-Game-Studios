#!/usr/bin/env python3
"""
gen_enemy_sprites.py — Generate 32x32 enemy sprites (6 normal + 1 boss).

Per art-bible V1.0 (2026-06-12):
- Base unit: 32x32 pixels
- Each enemy must have distinct silhouette at thumbnail size
- Dark background, neon accents
- Visual identity: "lone neon in deep-space ruins"

Distinct silhouettes (per ADR-0010 + level-dungeon.md):
  - swarmer: small, spiky (drone silhouette)
  - scavenger: humanoid with raised arm (rifle shape)
  - shielded_bot: wide, bulky (box on legs)
  - mine_layer: low to ground, flat (squat vehicle)
  - sniper_bot: tall, thin, with long barrel
  - drone: round, hovering (no legs)
  - heavy_walker: tall, bulky humanoid
  - boss (Marrow Sentinel): large, asymmetric, glowing weak point

Run from project root:
  python tools/gen_enemy_sprites.py
"""
import os
from PIL import Image

OUT_DIR = "assets/sprites/enemies"
SIZE = 32

# Enemy-specific palettes (each enemy has a distinct accent color)
PALETTES = {
    "swarmer": {
        "body_dark": (40, 30, 50, 255),
        "body_mid": (90, 60, 110, 255),
        "body_light": (140, 90, 160, 255),
        "accent": (200, 80, 220, 255),  # purple
        "eye": (255, 100, 220, 255),
    },
    "scavenger": {
        "body_dark": (50, 35, 20, 255),
        "body_mid": (110, 75, 40, 255),
        "body_light": (170, 120, 70, 255),
        "accent": (255, 130, 50, 255),  # orange
        "eye": (255, 200, 100, 255),
    },
    "shielded_bot": {
        "body_dark": (30, 45, 70, 255),
        "body_mid": (70, 100, 150, 255),
        "body_light": (120, 160, 200, 255),
        "accent": (90, 220, 255, 255),  # cyan shield
        "eye": (255, 255, 100, 255),
    },
    "mine_layer": {
        "body_dark": (50, 30, 30, 255),
        "body_mid": (100, 60, 60, 255),
        "body_light": (160, 100, 100, 255),
        "accent": (255, 60, 60, 255),  # red
        "eye": (255, 150, 50, 255),
    },
    "sniper_bot": {
        "body_dark": (25, 35, 45, 255),
        "body_mid": (60, 80, 100, 255),
        "body_light": (110, 140, 170, 255),
        "accent": (200, 220, 255, 255),  # pale blue
        "eye": (255, 50, 50, 255),  # red eye = sniper
    },
    "drone": {
        "body_dark": (45, 20, 60, 255),
        "body_mid": (90, 50, 120, 255),
        "body_light": (140, 100, 170, 255),
        "accent": (255, 100, 200, 255),  # pink
        "eye": (255, 255, 100, 255),
    },
    "heavy_walker": {
        "body_dark": (60, 40, 20, 255),
        "body_mid": (120, 80, 40, 255),
        "body_light": (180, 130, 70, 255),
        "accent": (255, 200, 50, 255),  # yellow
        "eye": (255, 50, 50, 255),  # red eye
    },
    "boss_marrow_sentinel": {
        "body_dark": (60, 30, 30, 255),
        "body_mid": (140, 50, 50, 255),
        "body_light": (200, 90, 80, 255),
        "accent": (255, 50, 30, 255),  # bright red
        "eye": (255, 255, 100, 255),  # yellow weak point
    },
}

def make_swarmer() -> Image.Image:
    """Small, spiky drone — fast, low HP, melee."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    px = img.load()
    p = PALETTES["swarmer"]
    # Spiky hexagonal body (12-20, 12-20)
    spike_runs = [
        # (y, x_start, x_end, color)
        (10, 15, 16, p["body_dark"]),
        (11, 13, 18, p["body_mid"]),
        (12, 12, 19, p["body_light"]),
        (13, 11, 20, p["body_mid"]),
        (14, 11, 20, p["body_light"]),
        (15, 11, 20, p["body_mid"]),
        (16, 12, 19, p["body_mid"]),
        (17, 13, 18, p["body_dark"]),
        (18, 15, 16, p["body_dark"]),
    ]
    for y, x0, x1, c in spike_runs:
        for x in range(x0, x1 + 1):
            px[x, y] = c
    # Side spikes
    for y in [12, 13, 14]:
        for x in [10, 21]:
            if 0 <= x < SIZE:
                px[x, y] = p["body_mid"]
    for y in [15, 16]:
        for x in [9, 22]:
            if 0 <= x < SIZE:
                px[x, y] = p["body_dark"]
    # Eye (center)
    px[15, 14] = p["eye"]
    px[16, 14] = p["eye"]
    px[15, 15] = p["accent"]
    px[16, 15] = p["accent"]
    return img

def make_scavenger() -> Image.Image:
    """Humanoid with raised rifle arm — ranged, low armor."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    px = img.load()
    p = PALETTES["scavenger"]
    # Head (rows 4-7, x 14-17)
    for y in [4, 5, 6, 7]:
        for x in [14, 15, 16, 17]:
            px[x, y] = p["body_dark"] if y in [4, 7] else p["body_mid"]
    px[15, 5] = p["eye"]
    px[16, 5] = p["eye"]
    # Torso (rows 8-15)
    for y in range(8, 16):
        for x in [13, 14, 15, 16, 17, 18]:
            if y in [8, 15]:
                px[x, y] = p["body_dark"]
            elif y in [9, 14]:
                px[x, y] = p["body_mid"]
            else:
                px[x, y] = p["body_light"]
    # Belt (accent line)
    for x in [13, 14, 15, 16, 17, 18]:
        px[x, 12] = p["accent"]
    # Left arm (rifle) — raised up
    for y in [6, 7, 8, 9]:
        for x in [11, 12]:
            px[x, y] = p["body_mid"]
    # Rifle barrel
    for y in [5, 6]:
        for x in [9, 10, 11]:
            px[x, y] = p["body_dark"]
    px[9, 4] = p["accent"]
    # Right arm
    for y in [9, 10, 11, 12, 13]:
        for x in [19, 20]:
            px[x, y] = p["body_mid"]
    # Legs
    for y in [16, 17, 18, 19]:
        for x in [13, 14]:
            px[x, y] = p["body_dark"] if y in [16, 19] else p["body_mid"]
        for x in [17, 18]:
            px[x, y] = p["body_dark"] if y in [16, 19] else p["body_mid"]
    # Boots
    for y in [20, 21]:
        for x in [12, 13, 14, 15]:
            px[x, y] = p["body_dark"]
        for x in [16, 17, 18, 19]:
            px[x, y] = p["body_dark"]
    return img

def make_shielded_bot() -> Image.Image:
    """Wide, bulky box on legs — high armor, slow, ranged projectiles."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    px = img.load()
    p = PALETTES["shielded_bot"]
    # Wide armored body (rows 6-18, x 6-25)
    for y in range(6, 19):
        for x in range(6, 26):
            if y in [6, 18]:
                px[x, y] = p["body_dark"]
            elif y in [7, 17]:
                px[x, y] = p["body_mid"]
            else:
                px[x, y] = p["body_light"]
    # Energy shield front (rows 9-15, x 4-7)
    for y in range(9, 16):
        for x in [4, 5]:
            px[x, y] = p["accent"]
    px[4, 12] = (255, 255, 255, 200)  # glow center
    # Head/eye slit (rows 9-10, x 14-17)
    for y in [9, 10]:
        for x in [14, 15, 16, 17]:
            px[x, y] = p["body_dark"]
    px[15, 9] = p["eye"]
    px[16, 9] = p["eye"]
    # Two stubby legs (rows 19-26, x 9-13 + 18-22)
    for y in range(19, 27):
        for x in [9, 10, 11, 12, 13]:
            if y in [19, 26]:
                px[x, y] = p["body_dark"]
            else:
                px[x, y] = p["body_mid"]
        for x in [18, 19, 20, 21, 22]:
            if y in [19, 26]:
                px[x, y] = p["body_dark"]
            else:
                px[x, y] = p["body_mid"]
    return img

def make_mine_layer() -> Image.Image:
    """Low, flat, squat vehicle with mine droppers."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    px = img.load()
    p = PALETTES["mine_layer"]
    # Wide flat body (rows 14-22, x 4-27)
    for y in range(14, 23):
        for x in range(4, 28):
            if y in [14, 22]:
                px[x, y] = p["body_dark"]
            elif y in [15, 21]:
                px[x, y] = p["body_mid"]
            else:
                px[x, y] = p["body_light"]
    # Treads (rows 23-26, x 4-27) - bumpy
    for y in [23, 24, 25, 26]:
        for x in range(4, 28):
            if (x + y) % 2 == 0:
                px[x, y] = p["body_dark"]
    # Mine droppers (top, 3x3 each at corners)
    for cx, cy in [(8, 11), (15, 10), (22, 11)]:
        for y in range(cy - 1, cy + 2):
            for x in range(cx - 1, cx + 2):
                if 0 <= x < SIZE and 0 <= y < SIZE:
                    px[x, y] = p["accent"]
    # Eye
    px[15, 17] = p["eye"]
    px[16, 17] = p["eye"]
    return img

def make_sniper_bot() -> Image.Image:
    """Tall, thin, with long barrel — long range, low HP."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    px = img.load()
    p = PALETTES["sniper_bot"]
    # Tall thin body (rows 5-25, x 13-18)
    for y in range(5, 26):
        for x in [13, 14, 15, 16, 17, 18]:
            if y in [5, 25]:
                px[x, y] = p["body_dark"]
            elif y in [6, 24]:
                px[x, y] = p["body_mid"]
            else:
                px[x, y] = p["body_light"]
    # Head (rows 5-9, x 14-17)
    for y in [5, 6, 7, 8, 9]:
        for x in [14, 15, 16, 17]:
            if y in [5, 9]:
                px[x, y] = p["body_dark"]
            else:
                px[x, y] = p["body_mid"]
    px[15, 7] = p["eye"]
    px[16, 7] = p["eye"]
    # Long barrel (rows 12-15, x 3-12)
    for y in [12, 13, 14, 15]:
        for x in range(3, 13):
            if y in [12, 15]:
                px[x, y] = p["body_dark"]
            else:
                px[x, y] = p["body_mid"]
    # Scope (rows 9-11, x 9-12)
    for y in [9, 10, 11]:
        for x in [9, 10, 11, 12]:
            px[x, y] = p["body_dark"]
    # Tripod legs (rows 25-30, x 11, 15, 19)
    for y in range(25, 31):
        for x in [11, 15, 19]:
            px[x, y] = p["body_dark"]
    return img

def make_drone() -> Image.Image:
    """Round hovering drone, no legs."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    px = img.load()
    p = PALETTES["drone"]
    # Round body (rows 8-20, x 9-22)
    for y in range(8, 21):
        for x in range(9, 23):
            # Make it round by skipping corner pixels
            if y in [8, 20] and x in [9, 22]:
                continue
            if y in [9, 19] and x in [9, 10, 21, 22]:
                continue
            if y in [8, 9, 19, 20]:
                px[x, y] = p["body_dark"]
            elif y in [10, 18]:
                px[x, y] = p["body_mid"]
            else:
                px[x, y] = p["body_light"]
    # Single eye (center)
    px[14, 13] = p["eye"]
    px[15, 13] = p["eye"]
    px[16, 13] = p["eye"]
    px[17, 13] = p["eye"]
    px[14, 14] = p["accent"]
    px[15, 14] = p["accent"]
    px[16, 14] = p["accent"]
    px[17, 14] = p["accent"]
    # Antenna (top)
    for y in [5, 6, 7]:
        px[15, y] = p["body_mid"]
    px[15, 4] = p["accent"]
    # Bottom thruster glow
    for y in [21, 22, 23]:
        for x in [12, 13, 14, 15, 16, 17, 18, 19]:
            if y == 21 and (x - 12) % 2 == 0:
                px[x, y] = p["accent"]
            elif y == 22:
                px[x, y] = p["accent"]
    return img

def make_heavy_walker() -> Image.Image:
    """Tall bulky humanoid — high HP, slow, melee."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    px = img.load()
    p = PALETTES["heavy_walker"]
    # Head (rows 3-6, x 13-18)
    for y in [3, 4, 5, 6]:
        for x in [13, 14, 15, 16, 17, 18]:
            if y in [3, 6]:
                px[x, y] = p["body_dark"]
            else:
                px[x, y] = p["body_mid"]
    px[15, 4] = p["eye"]
    px[16, 4] = p["eye"]
    # Massive shoulders (rows 7-11, x 8-23)
    for y in range(7, 12):
        for x in range(8, 24):
            if y in [7, 11]:
                px[x, y] = p["body_dark"]
            elif y in [8, 10]:
                px[x, y] = p["body_mid"]
            else:
                px[x, y] = p["body_light"]
    # Torso (rows 12-20, x 11-20)
    for y in range(12, 21):
        for x in [11, 12, 13, 14, 15, 16, 17, 18, 19, 20]:
            if y in [12, 20]:
                px[x, y] = p["body_dark"]
            elif y in [13, 19]:
                px[x, y] = p["body_mid"]
            else:
                px[x, y] = p["body_light"]
    # Arms (rows 12-22, x 7-10 + 21-24) - thick
    for y in range(12, 23):
        for x in [7, 8, 9, 10]:
            if y in [12, 22]:
                px[x, y] = p["body_dark"]
            else:
                px[x, y] = p["body_mid"]
        for x in [21, 22, 23, 24]:
            if y in [12, 22]:
                px[x, y] = p["body_dark"]
            else:
                px[x, y] = p["body_mid"]
    # Legs (rows 21-30, x 12-14 + 17-19)
    for y in range(21, 31):
        for x in [12, 13, 14]:
            if y in [21, 30]:
                px[x, y] = p["body_dark"]
            else:
                px[x, y] = p["body_mid"]
        for x in [17, 18, 19]:
            if y in [21, 30]:
                px[x, y] = p["body_dark"]
            else:
                px[x, y] = p["body_mid"]
    return img

def make_boss_marrow_sentinel() -> Image.Image:
    """Marrow Sentinel — large, asymmetric, glowing weak point. 64x64 boss size."""
    boss_size = 64
    img = Image.new("RGBA", (boss_size, boss_size), (0, 0, 0, 0))
    px = img.load()
    p = PALETTES["boss_marrow_sentinel"]
    # Asymmetric bulk: wider on left (where the cannon arm is)
    # Main body (rows 12-50, x 16-48)
    for y in range(12, 51):
        for x in range(16, 49):
            # Asymmetric: damage/tattered on right side
            if x > 42 and y % 3 == 0 and (x + y) % 5 == 0:
                continue  # missing chunks (battle damage aesthetic)
            if y in [12, 50] or x in [16, 48]:
                px[x, y] = p["body_dark"]
            elif y in [13, 49] or x in [17, 47]:
                px[x, y] = p["body_mid"]
            else:
                px[x, y] = p["body_light"]
    # Massive shoulder (top, x 20-44, y 6-13)
    for y in range(6, 14):
        for x in range(20, 45):
            if y in [6, 13] or x in [20, 44]:
                px[x, y] = p["body_dark"]
            else:
                px[x, y] = p["body_mid"]
    # Head (rows 4-9, x 26-37) - small relative to body
    for y in [4, 5, 6, 7, 8, 9]:
        for x in [26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37]:
            if y in [4, 9]:
                px[x, y] = p["body_dark"]
            else:
                px[x, y] = p["body_mid"]
    # Glowing weak point (chest, rows 22-32, x 28-36)
    for y in range(22, 33):
        for x in range(28, 37):
            px[x, y] = p["eye"]
    # Inner glow (rows 25-30, x 30-34)
    for y in range(25, 31):
        for x in range(30, 35):
            px[x, y] = p["accent"]
    # Big cannon arm (left, x 6-19, y 20-44)
    for y in range(20, 45):
        for x in range(6, 20):
            if x < 8:
                if y in [28, 29, 30, 31]:  # barrel
                    px[x, y] = p["body_dark"]
                else:
                    continue  # empty space (arm extends out)
            elif y in [20, 44]:
                px[x, y] = p["body_dark"]
            else:
                px[x, y] = p["body_mid"]
    # Cannon barrel tip (rows 27-32, x 0-7)
    for y in [27, 28, 29, 30, 31, 32]:
        for x in [3, 4, 5, 6, 7]:
            px[x, y] = p["body_dark"]
    # Muzzle (rows 28-30, x 0-3)
    for y in [28, 29, 30]:
        for x in [0, 1, 2, 3]:
            px[x, y] = p["accent"]
    # Legs (rows 50-62, x 22-28 + 35-41)
    for y in range(50, 63):
        for x in [22, 23, 24, 25, 26, 27, 28]:
            if y in [50, 62]:
                px[x, y] = p["body_dark"]
            else:
                px[x, y] = p["body_mid"]
        for x in [35, 36, 37, 38, 39, 40, 41]:
            if y in [50, 62]:
                px[x, y] = p["body_dark"]
            else:
                px[x, y] = p["body_mid"]
    return img

def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    generators = [
        ("swarmer", make_swarmer),
        ("scavenger", make_scavenger),
        ("shielded_bot", make_shielded_bot),
        ("mine_layer", make_mine_layer),
        ("sniper_bot", make_sniper_bot),
        ("drone", make_drone),
        ("heavy_walker", make_heavy_walker),
    ]
    for name, gen in generators:
        img = gen()
        path = os.path.join(OUT_DIR, f"{name}.png")
        img.save(path)
        print(f"  wrote {path} ({img.size[0]}x{img.size[1]})")
    # Boss is 64x64
    boss = make_boss_marrow_sentinel()
    boss_path = os.path.join(OUT_DIR, "boss_marrow_sentinel.png")
    boss.save(boss_path)
    print(f"  wrote {boss_path} ({boss.size[0]}x{boss.size[1]})")
    print(f"\n{len(generators) + 1} sprite(s) generated.")

if __name__ == "__main__":
    main()
