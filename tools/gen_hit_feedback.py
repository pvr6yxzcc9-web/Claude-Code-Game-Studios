#!/usr/bin/env python3
"""
gen_hit_feedback.py — Generate 8 hit feedback sprites (S17-003).

Per design/battle-core-loop.md: combat needs visual feedback for
every damage type. Each sprite is shown briefly (0.1-0.3s) at the
impact point via TextureRect popups in battle_scene.gd.

Outputs (in assets/sprites/vfx/):
  hit_damage.png         32x32  — generic damage indicator
  hit_crit.png           32x32  — critical hit (big star + ring)
  hit_heal.png           32x32  — heal sparkles (green +)
  hit_buff.png           32x32  — buff applied (blue up arrow)
  hit_debuff.png         32x32  — debuff applied (purple down arrow)
  hit_block.png          32x32  — block/parry (cyan shield)
  hit_miss.png           32x32  — miss/dodge (grey dash)
  hit_kill.png           32x32  — enemy killed (skull + ring)

Run from project root:
  python tools/gen_hit_feedback.py
"""
import math
import os
from PIL import Image, ImageDraw

OUT_DIR = "assets/sprites/vfx"
SIZE = 32

# Palette
NAVY = (16, 20, 32, 255)
NAVY_DARK = (10, 14, 24, 255)
RED = (220, 50, 50, 255)
RED_BRIGHT = (255, 80, 80, 255)
RED_DARK = (140, 30, 30, 255)
YELLOW = (255, 220, 100, 255)
YELLOW_BRIGHT = (255, 255, 200, 255)
AMBER = (255, 180, 60, 255)
AMBER_DARK = (140, 88, 48, 255)
GREEN = (80, 220, 100, 255)
GREEN_BRIGHT = (180, 255, 180, 255)
GREEN_DARK = (40, 140, 60, 255)
BLUE = (90, 160, 255, 255)
BLUE_BRIGHT = (160, 200, 255, 255)
PURPLE = (180, 100, 220, 255)
PURPLE_DARK = (100, 50, 140, 255)
CYAN = (90, 220, 255, 255)
GRAY = (120, 124, 132, 255)
GRAY_DARK = (60, 64, 72, 255)
WHITE = (240, 240, 240, 255)
WHITE_BRIGHT = (255, 255, 255, 255)


def make_damage() -> Image.Image:
    """Generic damage — red impact star."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = SIZE // 2, SIZE // 2
    # 4-pointed impact star
    arms = [
        (cx, cy - 12, cx, cy + 12),
        (cx - 12, cy, cx + 12, cy),
        (cx - 8, cy - 8, cx + 8, cy + 8),
        (cx - 8, cy + 8, cx + 8, cy - 8),
    ]
    for x1, y1, x2, y2 in arms:
        d.line([(x1, y1), (x2, y2)], fill=RED, width=3)
    # Center red dot
    d.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=RED_BRIGHT)
    return img


def make_crit() -> Image.Image:
    """Critical hit — big 5-point star + outer ring."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = SIZE // 2, SIZE // 2
    # Outer ring
    d.ellipse([cx - 13, cy - 13, cx + 13, cy + 13], outline=YELLOW, width=2)
    # 5-point star
    r_outer, r_inner = 10, 4
    points: list = []
    for i in range(10):
        angle = (math.pi * 2 * i / 10) - math.pi / 2
        r = r_outer if i % 2 == 0 else r_inner
        x = cx + r * math.cos(angle)
        y = cy + r * math.sin(angle)
        points.append((x, y))
    d.polygon(points, fill=YELLOW, outline=AMBER)
    d.ellipse([cx - 2, cy - 2, cx + 2, cy + 2], fill=WHITE_BRIGHT)
    return img


def make_heal() -> Image.Image:
    """Heal — green plus sign + sparkles."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = SIZE // 2, SIZE // 2
    # Plus sign (thick)
    d.rectangle([cx - 2, cy - 11, cx + 2, cy + 11], fill=GREEN)
    d.rectangle([cx - 11, cy - 2, cx + 11, cy + 2], fill=GREEN)
    # Outer glow
    d.ellipse([cx - 12, cy - 12, cx + 12, cy + 12], outline=GREEN_BRIGHT, width=1)
    # Sparkles around
    for x, y in [(6, 6), (22, 8), (8, 22), (24, 24), (16, 4), (4, 16)]:
        d.ellipse([x - 1, y - 1, x + 1, y + 1], fill=GREEN_BRIGHT)
    return img


def make_buff() -> Image.Image:
    """Buff — blue up arrow + ring."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = SIZE // 2, SIZE // 2
    # Up arrow (triangle + rectangle)
    d.polygon([(cx, cy - 11), (cx - 8, cy - 1), (cx + 8, cy - 1)], fill=BLUE)
    d.rectangle([cx - 3, cy - 1, cx + 3, cy + 10], fill=BLUE)
    # Outer ring
    d.ellipse([cx - 13, cy - 13, cx + 13, cy + 13], outline=BLUE_BRIGHT, width=2)
    return img


def make_debuff() -> Image.Image:
    """Debuff — purple down arrow + ring."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = SIZE // 2, SIZE // 2
    # Down arrow
    d.polygon([(cx, cy + 11), (cx - 8, cy + 1), (cx + 8, cy + 1)], fill=PURPLE)
    d.rectangle([cx - 3, cy - 10, cx + 3, cy + 1], fill=PURPLE)
    # Outer ring
    d.ellipse([cx - 13, cy - 13, cx + 13, cy + 13], outline=PURPLE_DARK, width=2)
    return img


def make_block() -> Image.Image:
    """Block/parry — cyan shield."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = SIZE // 2, SIZE // 2
    # Shield shape
    d.polygon([
        (cx - 8, cy - 11), (cx + 8, cy - 11),
        (cx + 8, cy + 2), (cx, cy + 11), (cx - 8, cy + 2),
    ], fill=CYAN, outline=NAVY)
    # Highlight
    d.line([(cx - 5, cy - 7), (cx - 5, cy - 1)], fill=WHITE, width=1)
    return img


def make_miss() -> Image.Image:
    """Miss/dodge — grey dashes."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = SIZE // 2, SIZE // 2
    # 3 horizontal dashes
    for i, dy in enumerate([-5, 0, 5]):
        d.line([(cx - 10, cy + dy), (cx - 2, cy + dy)], fill=GRAY, width=2)
    # Motion blur lines
    for dx in [-3, 0, 3]:
        d.line([(cx + 4, cy - 8 + dx), (cx + 12, cy - 8 + dx)], fill=GRAY_DARK, width=1)
    return img


def make_kill() -> Image.Image:
    """Enemy killed — red X with skull-like crossbones."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = SIZE // 2, SIZE // 2
    # Skull shape (simple oval)
    d.ellipse([cx - 9, cy - 10, cx + 9, cy + 6], fill=WHITE, outline=NAVY_DARK)
    # Eye sockets
    d.ellipse([cx - 6, cy - 6, cx - 2, cy - 2], fill=NAVY_DARK)
    d.ellipse([cx + 2, cy - 6, cx + 6, cy - 2], fill=NAVY_DARK)
    # Teeth (red X overlay)
    d.line([(cx - 4, cy), (cx + 4, cy + 4)], fill=RED, width=2)
    d.line([(cx - 4, cy + 4), (cx + 4, cy)], fill=RED, width=2)
    # Crossbones
    d.line([(cx - 12, cy + 8), (cx - 4, cy + 4)], fill=WHITE, width=2)
    d.line([(cx - 12, cy + 4), (cx - 4, cy + 8)], fill=WHITE, width=2)
    d.line([(cx + 4, cy + 4), (cx + 12, cy + 8)], fill=WHITE, width=2)
    d.line([(cx + 4, cy + 8), (cx + 12, cy + 4)], fill=WHITE, width=2)
    return img


SPRITES = [
    ("hit_damage", make_damage),
    ("hit_crit", make_crit),
    ("hit_heal", make_heal),
    ("hit_buff", make_buff),
    ("hit_debuff", make_debuff),
    ("hit_block", make_block),
    ("hit_miss", make_miss),
    ("hit_kill", make_kill),
]


def main() -> int:
    os.makedirs(OUT_DIR, exist_ok=True)
    for name, fn in SPRITES:
        img = fn()
        path = os.path.join(OUT_DIR, f"{name}.png")
        img.save(path)
        print(f"  wrote {path} ({SIZE}x{SIZE})")
    print(f"\nGenerated {len(SPRITES)} hit feedback sprites")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
