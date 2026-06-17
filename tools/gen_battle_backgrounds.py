#!/usr/bin/env python3
"""
gen_battle_backgrounds.py — Generate 5 battle background PNGs (S14-002).

Per art-bible: 1280x720 dark sci-fi backgrounds, one per satellite.
Each conveys the atmosphere of that location without distracting
from the foreground battle UI (mech sprite + HP bars).

Outputs (in assets/sprites/battle/):
  bg_sat1.png  (frozen reactor — ice blue, dim machinery silhouettes)
  bg_sat2.png  (alien ruins — purple, broken arches)
  bg_sat3.png  (hive — sickly green, organic tendrils)
  bg_sat4.png  (warzone — red+gray, destroyed bunkers)
  bg_sat5.png  (origin — black + gold, the Creator's chamber)

Run from project root:
  python tools/gen_battle_backgrounds.py
"""
import math
import os
import random
from PIL import Image, ImageDraw, ImageFilter

OUT_DIR = "assets/sprites/battle"
W, H = 1280, 720

# Per-satellite palettes
PALETTES = {
    1: {  # Frozen reactor — ice blue
        "sky_top": (10, 18, 32, 255),
        "sky_bot": (40, 80, 120, 255),
        "mid": (60, 110, 150, 255),
        "fg": (80, 140, 180, 255),
        "accent": (180, 220, 255, 255),
        "name": "frozen_reactor",
    },
    2: {  # Alien ruins — purple
        "sky_top": (15, 8, 28, 255),
        "sky_bot": (50, 30, 80, 255),
        "mid": (90, 50, 130, 255),
        "fg": (130, 70, 170, 255),
        "accent": (200, 150, 255, 255),
        "name": "alien_ruins",
    },
    3: {  # Hive — sickly green
        "sky_top": (8, 16, 10, 255),
        "sky_bot": (30, 80, 40, 255),
        "mid": (50, 130, 60, 255),
        "fg": (80, 180, 80, 255),
        "accent": (180, 255, 140, 255),
        "name": "hive",
    },
    4: {  # Warzone — red+gray
        "sky_top": (20, 8, 8, 255),
        "sky_bot": (80, 30, 20, 255),
        "mid": (130, 60, 40, 255),
        "fg": (180, 90, 70, 255),
        "accent": (255, 180, 100, 255),
        "name": "warzone",
    },
    5: {  # Origin — black + gold
        "sky_top": (4, 4, 8, 255),
        "sky_bot": (20, 14, 8, 255),
        "mid": (60, 40, 20, 255),
        "fg": (160, 110, 40, 255),
        "accent": (255, 200, 80, 255),
        "name": "origin",
    },
}


def vertical_gradient(img: Image.Image, top: tuple, bot: tuple) -> None:
    """Fill a vertical gradient from top to bottom."""
    px = img.load()
    for y in range(H):
        t = y / (H - 1)
        r = int(top[0] * (1 - t) + bot[0] * t)
        g = int(top[1] * (1 - t) + bot[1] * t)
        b = int(top[2] * (1 - t) + bot[2] * t)
        for x in range(W):
            px[x, y] = (r, g, b, 255)


def draw_stars(d: ImageDraw.ImageDraw, count: int, palette: dict) -> None:
    """Draw small stars in the upper sky."""
    for _ in range(count):
        x = random.randint(0, W - 1)
        y = random.randint(0, H // 3)
        size = random.choice([1, 1, 1, 2])
        brightness = random.randint(180, 255)
        d.rectangle([x, y, x + size, y + size], fill=(brightness, brightness, brightness, 200))


def make_bg_sat1(d: ImageDraw.ImageDraw, img: Image.Image) -> None:
    """Sat-1: frozen reactor — ice pillars, dim machinery."""
    pal = PALETTES[1]
    vertical_gradient(img, pal["sky_top"], pal["sky_bot"])
    draw_stars(d, 30, pal)
    # Frozen pillars (left + right foreground)
    for x_base in [80, 200, 320, 1000, 1140, 1240]:
        h = random.randint(180, 320)
        w = random.randint(40, 80)
        d.rectangle([x_base, H - h, x_base + w, H], fill=pal["mid"], outline=pal["fg"])
        # Ice cracks
        for _ in range(4):
            cx = random.randint(x_base, x_base + w)
            cy = random.randint(H - h, H)
            d.line([(cx, cy), (cx + random.randint(-10, 10), cy + random.randint(10, 30))], fill=pal["accent"], width=1)
    # Ground (snow)
    d.rectangle([0, H - 60, W, H], fill=(200, 220, 240, 255))
    # Machinery silhouettes
    for x in [400, 600, 800]:
        d.rectangle([x, H - 200, x + 80, H - 60], fill=pal["fg"], outline=pal["accent"])
        d.rectangle([x + 20, H - 230, x + 60, H - 200], fill=pal["accent"])


def make_bg_sat2(d: ImageDraw.ImageDraw, img: Image.Image) -> None:
    """Sat-2: alien ruins — broken arches, purple glow."""
    pal = PALETTES[2]
    vertical_gradient(img, pal["sky_top"], pal["sky_bot"])
    draw_stars(d, 50, pal)
    # Distant arches (multiple layers for depth)
    for layer_idx, scale in enumerate([0.3, 0.6, 1.0]):
        for x_base in range(int(-100 * scale), W + 100, int(200 * scale)):
            h = int(180 * scale) + random.randint(-20, 40)
            w = int(120 * scale) + random.randint(-10, 20)
            y_top = H - h - 50
            color = pal["mid"] if layer_idx < 1 else (pal["fg"] if layer_idx < 2 else pal["mid"])
            # Arched top
            d.pieslice([x_base, y_top, x_base + w, y_top + w], 180, 360, fill=color, outline=pal["fg"])
            d.rectangle([x_base, y_top + w // 2, x_base + w, H - 50], fill=color, outline=pal["fg"])
            # Inner glow
            d.pieslice([x_base + 8, y_top + 8, x_base + w - 8, y_top + w - 8], 180, 360, fill=pal["sky_bot"])
    # Foreground ground
    d.rectangle([0, H - 40, W, H], fill=(20, 12, 30, 255))
    # Glow at center
    for r in range(60, 0, -10):
        alpha = int(100 * (60 - r) / 60)
        d.ellipse([640 - r * 2, H - 80 - r, 640 + r * 2, H - 80 + r], fill=(200, 150, 255, alpha))


def make_bg_sat3(d: ImageDraw.ImageDraw, img: Image.Image) -> None:
    """Sat-3: hive — organic tendrils, dripping walls."""
    pal = PALETTES[3]
    vertical_gradient(img, pal["sky_top"], pal["sky_bot"])
    # No stars (underground hive)
    # Organic walls (left + right)
    for x in [0, W - 60]:
        for y in range(0, H, 6):
            wave = int(15 * math.sin(y * 0.04 + (x * 0.01)))
            d.line([(x + wave, y), (x + wave + 30, y)], fill=pal["mid"], width=4)
            d.line([(x + wave, y), (x + wave + 15, y + 3)], fill=pal["fg"], width=2)
    # Tendrils hanging from top
    for i in range(20):
        x = random.randint(50, W - 50)
        h = random.randint(40, 200)
        w = random.randint(3, 8)
        for y in range(0, h, 4):
            curve = int(8 * math.sin(y * 0.08))
            d.rectangle([x + curve, y, x + curve + w, y + 4], fill=pal["fg"])
        # Drip
        d.ellipse([x + curve - 1, h - 4, x + curve + w + 1, h + 4], fill=pal["accent"])
    # Ground (organic mass)
    for y in range(H - 80, H, 4):
        wave = int(10 * math.sin(y * 0.06))
        d.line([(0, y), (W, y)], fill=pal["mid"], width=4)
    # Pustules on ground
    for _ in range(15):
        x = random.randint(20, W - 20)
        y = random.randint(H - 60, H - 10)
        r = random.randint(2, 5)
        d.ellipse([x - r, y - r, x + r, y + r], fill=pal["accent"])


def make_bg_sat4(d: ImageDraw.ImageDraw, img: Image.Image) -> None:
    """Sat-4: warzone — destroyed bunkers, fire, smoke."""
    pal = PALETTES[4]
    vertical_gradient(img, pal["sky_top"], pal["sky_bot"])
    # Smoke clouds
    for _ in range(8):
        cx = random.randint(0, W)
        cy = random.randint(0, H // 2)
        r = random.randint(60, 120)
        d.ellipse([cx - r, cy - r // 2, cx + r, cy + r // 2], fill=(60, 30, 25, 100))
    # Destroyed bunkers
    for x in [50, 250, 450, 850, 1050, 1200]:
        h = random.randint(80, 160)
        w = random.randint(100, 180)
        d.rectangle([x, H - h, x + w, H - 30], fill=pal["fg"], outline=pal["accent"])
        # Damage
        for _ in range(5):
            dx = random.randint(x, x + w)
            dy = random.randint(H - h, H - 30)
            d.rectangle([dx, dy, dx + random.randint(5, 15), dy + random.randint(5, 15)], fill=(20, 8, 8, 255))
        # Top destroyed (jagged)
        d.polygon([(x, H - h), (x + w // 4, H - h - 20), (x + w // 2, H - h + 10),
                   (x + 3 * w // 4, H - h - 15), (x + w, H - h)], fill=pal["sky_bot"], outline=pal["fg"])
    # Ground (rubble)
    d.rectangle([0, H - 30, W, H], fill=(60, 30, 20, 255))
    for _ in range(40):
        x = random.randint(0, W)
        y = random.randint(H - 30, H)
        r = random.randint(2, 6)
        d.ellipse([x - r, y - r, x + r, y + r], fill=(40, 20, 15, 255))
    # Distant fires
    for x in [200, 500, 900]:
        for r in range(20, 0, -3):
            alpha = int(150 * r / 20)
            d.ellipse([x - r, H - 150 - r, x + r, H - 150 + r], fill=(255, 150, 50, alpha))


def make_bg_sat5(d: ImageDraw.ImageDraw, img: Image.Image) -> None:
    """Sat-5: origin — the Creator's chamber, golden + black, geometric."""
    pal = PALETTES[5]
    vertical_gradient(img, pal["sky_top"], pal["sky_bot"])
    draw_stars(d, 80, pal)
    # Massive geometric pillars (left + right, with perspective)
    for x_base, h, w in [(50, 600, 100), (W - 150, 600, 100)]:
        # Trapezoid (wider at bottom)
        d.polygon([(x_base, H - h), (x_base + w, H - h),
                   (x_base + w + 30, H), (x_base - 30, H)], fill=pal["mid"], outline=pal["fg"])
        # Gold inlay
        d.line([(x_base + 10, H - h + 30), (x_base + w - 10, H - h + 30)], fill=pal["accent"], width=2)
        d.line([(x_base + 10, H - h + 60), (x_base + w - 10, H - h + 60)], fill=pal["accent"], width=2)
        d.line([(x_base + 10, H - h + 90), (x_base + w - 10, H - h + 90)], fill=pal["accent"], width=2)
    # Central arch (Creator's door)
    d.pieslice([W // 2 - 200, H - 600, W // 2 + 200, H - 200], 180, 360, fill=pal["mid"], outline=pal["fg"])
    d.pieslice([W // 2 - 180, H - 590, W // 2 + 180, H - 210], 180, 360, fill=pal["sky_top"])
    # Gold glyphs on the door
    for i, y in enumerate([H - 500, H - 400, H - 300]):
        d.line([(W // 2 - 60, y), (W // 2 - 30, y - 10), (W // 2, y), (W // 2 + 30, y - 10), (W // 2 + 60, y)], fill=pal["accent"], width=2)
    # Floor (black marble with gold veins)
    d.rectangle([0, H - 50, W, H], fill=(8, 6, 4, 255))
    for _ in range(20):
        x1 = random.randint(0, W)
        y1 = random.randint(H - 50, H)
        x2 = x1 + random.randint(-30, 30)
        y2 = y1 + random.randint(-10, 10)
        d.line([(x1, y1), (x2, y2)], fill=pal["fg"], width=1)


GENERATORS = {
    1: make_bg_sat1,
    2: make_bg_sat2,
    3: make_bg_sat3,
    4: make_bg_sat4,
    5: make_bg_sat5,
}


def main() -> int:
    os.makedirs(OUT_DIR, exist_ok=True)
    random.seed(20260617)  # deterministic
    for sat in range(1, 6):
        img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
        d = ImageDraw.Draw(img)
        GENERATORS[sat](d, img)
        # Slight blur to soften pixel art
        img = img.filter(ImageFilter.GaussianBlur(radius=0.5))
        path = os.path.join(OUT_DIR, f"bg_sat{sat}.png")
        img.save(path, optimize=True)
        print(f"  wrote {path} ({W}x{H})")
    print(f"\nGenerated {len(GENERATORS)} battle backgrounds in {OUT_DIR}/")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
