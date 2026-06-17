#!/usr/bin/env python3
"""
gen_vfx_sprites.py — Generate 5 VFX particle sprites (S17-001).

Per art-bible: soft pixel-art particles, 32x32 RGBA with transparent
background. Used by ParticleFxManager for visual feedback.

Outputs (in assets/sprites/vfx/):
  particle_circle.png     — soft white circle (footstep dust, generic)
  particle_spark.png      — angular spark (hit impact)
  particle_star.png       — 5-point star (crit, special)
  particle_glow.png       — soft glow (muzzle flash, heal)
  particle_dust.png       — small irregular dust (footstep)

Run from project root:
  python tools/gen_vfx_sprites.py
"""
import math
import os
from PIL import Image, ImageDraw

OUT_DIR = "assets/sprites/vfx"
SIZE = 32


def make_circle() -> Image.Image:
    """Soft white circle — generic particle, footstep dust."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = SIZE // 2, SIZE // 2
    for r in range(SIZE // 2, 0, -1):
        # Fade alpha from edge to center
        t = r / (SIZE // 2)
        a = int(255 * (1 - t) ** 1.5)  # quadratic falloff
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 255, 255, a))
    return img


def make_spark() -> Image.Image:
    """Angular spark — 4-pointed star, used for hit impacts."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = SIZE // 2, SIZE // 2
    # 4-pointed star (cross + diagonals)
    arms = [
        (cx, cy - 14, cx, cy + 14),  # vertical
        (cx - 14, cy, cx + 14, cy),  # horizontal
        (cx - 10, cy - 10, cx + 10, cy + 10),  # diagonal \
        (cx - 10, cy + 10, cx + 10, cy - 10),  # diagonal /
    ]
    for x1, y1, x2, y2 in arms:
        d.line([(x1, y1), (x2, y2)], fill=(255, 220, 100, 255), width=2)
    # Center bright dot
    d.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=(255, 255, 200, 255))
    return img


def make_star() -> Image.Image:
    """5-pointed star — for crits and special moments."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = SIZE // 2, SIZE // 2 + 2
    r_outer = 13
    r_inner = 5
    points: list = []
    for i in range(10):
        angle = (math.pi * 2 * i / 10) - math.pi / 2
        r = r_outer if i % 2 == 0 else r_inner
        x = cx + r * math.cos(angle)
        y = cy + r * math.sin(angle)
        points.append((x, y))
    d.polygon(points, fill=(255, 230, 100, 255), outline=(255, 255, 200, 255))
    # Inner highlight
    d.ellipse([cx - 2, cy - 2, cx + 2, cy + 2], fill=(255, 255, 255, 255))
    return img


def make_glow() -> Image.Image:
    """Soft radial glow — for muzzle flash, heal sparkles."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = SIZE // 2, SIZE // 2
    # Multi-layer glow (concentric circles, fading)
    for i, r in enumerate([14, 11, 8, 5, 3]):
        a = int(255 * (r / 14) ** 1.2)
        color = (255, 200, 80, a) if i % 2 == 0 else (255, 255, 150, a)
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color)
    return img


def make_dust() -> Image.Image:
    """Small irregular dust — for footstep and ambient particles."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = SIZE // 2, SIZE // 2
    # Cluster of small irregular dots
    import random
    random.seed(20260617)
    for _ in range(8):
        ox = random.randint(-8, 8)
        oy = random.randint(-8, 8)
        r = random.randint(1, 3)
        a = random.randint(100, 200)
        d.ellipse([cx + ox - r, cy + oy - r, cx + ox + r, cy + oy + r],
                  fill=(200, 190, 170, a))
    return img


SPRITES = [
    ("particle_circle", make_circle),
    ("particle_spark", make_spark),
    ("particle_star", make_star),
    ("particle_glow", make_glow),
    ("particle_dust", make_dust),
]


def main() -> int:
    os.makedirs(OUT_DIR, exist_ok=True)
    for name, fn in SPRITES:
        img = fn()
        path = os.path.join(OUT_DIR, f"{name}.png")
        img.save(path)
        print(f"  wrote {path} ({SIZE}x{SIZE})")
    print(f"\nGenerated {len(SPRITES)} VFX particle sprites")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
