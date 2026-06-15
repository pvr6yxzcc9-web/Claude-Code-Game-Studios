#!/usr/bin/env python3
"""
gen_title_art.py — Generate title screen background (S6-016).

1280x720 atmospheric title screen for Railhunter.
Layers (back to front):
  1. Deep navy gradient sky
  2. Nebula clouds (low-opacity purple/cyan)
  3. Starfield (200 stars with size + brightness variation)
  4. Distant planet/dwarf silhouette (top-right, partial)
  5. Horizon line (the derelict satellite's outline)
  6. Derelict silhouette (mech-shaped debris in midground)
  7. Atmosphere haze at the bottom
  8. Vignette (darken corners)

Output: assets/sprites/title/title_bg.png (1280x720)

Run from project root:
  python tools/gen_title_art.py
"""
import os
import math
import random
from PIL import Image, ImageDraw, ImageFilter

OUT_DIR = "assets/sprites/title"
W, H = 1280, 720

# Palette
NAVY_DEEP = (4, 6, 12, 255)
NAVY = (10, 14, 24, 255)
NAVY_LIGHT = (20, 30, 50, 255)
NEBULA_PURPLE = (60, 30, 80, 255)
NEBULA_CYAN = (30, 80, 100, 255)
NEBULA_AMBER = (100, 60, 30, 255)
STAR_BRIGHT = (240, 240, 255, 255)
STAR_DIM = (120, 130, 160, 255)
PLANET_SHADOW = (15, 12, 20, 255)
PLANET_RIM = (50, 35, 60, 255)
HORIZON_DARK = (4, 4, 8, 255)
DERELICT = (2, 2, 4, 255)
DERELICT_RIM = (60, 70, 90, 80)  # partial alpha for backlight
HAZE = (20, 25, 40, 60)
VIGNETTE = (0, 0, 0, 200)

def make_sky() -> Image.Image:
    """Vertical gradient sky from very dark navy at top to slightly less dark at horizon."""
    img = Image.new("RGBA", (W, H), NAVY_DEEP)
    d = ImageDraw.Draw(img)
    for y in range(H):
        # Linear gradient: navy_deep at top, navy_light near horizon
        t = y / H
        r = int(4 + t * 16)
        g = int(6 + t * 24)
        b = int(12 + t * 38)
        d.line([(0, y), (W, y)], fill=(r, g, b, 255))
    return img

def make_nebula(base: Image.Image) -> Image.Image:
    """Add 2-3 soft nebula clouds using radial gradients."""
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    random.seed(42)
    clouds = [
        # (cx, cy, radius, color)
        (300, 200, 250, NEBULA_PURPLE),
        (900, 350, 320, NEBULA_CYAN),
        (640, 100, 200, NEBULA_AMBER),
    ]
    for cx, cy, radius, color in clouds:
        # Draw concentric circles with decreasing alpha
        for r in range(radius, 0, -8):
            alpha = int(60 * (1 - r / radius))  # peak at center
            d.ellipse(
                [cx - r, cy - r, cx + r, cy + r],
                fill=(color[0], color[1], color[2], alpha)
            )
    # Blur the nebula layer for soft edges
    layer = layer.filter(ImageFilter.GaussianBlur(radius=40))
    return Image.alpha_composite(base, layer)

def make_starfield(base: Image.Image) -> Image.Image:
    """Scatter 200+ stars with size + brightness variation."""
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    random.seed(1337)
    for _ in range(280):
        x = random.randint(0, W - 1)
        y = random.randint(0, H - 2)  # avoid last row
        # Size: 80% dim 1px, 15% bright 1px, 5% cross-shaped 2px
        roll = random.random()
        if roll < 0.80:
            d.point((x, y), fill=STAR_DIM)
        elif roll < 0.95:
            d.point((x, y), fill=STAR_BRIGHT)
        else:
            # Cross-shaped highlight
            d.point((x, y), fill=STAR_BRIGHT)
            d.point((x - 1, y), fill=(180, 190, 220, 180))
            d.point((x + 1, y), fill=(180, 190, 220, 180))
            d.point((x, y - 1), fill=(180, 190, 220, 180))
            d.point((x, y + 1), fill=(180, 190, 220, 180))
    return Image.alpha_composite(base, layer)

def make_planet(base: Image.Image) -> Image.Image:
    """Top-right dwarf planet (partial, half off-screen)."""
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    cx, cy, r = 1180, 80, 130
    # Solid body
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=PLANET_SHADOW)
    # Rim light (crescent on the lower-left side, like sunlight from below)
    for angle in range(180, 360, 5):
        rad = math.radians(angle)
        x = cx + int(r * math.cos(rad))
        y = cy + int(r * math.sin(rad))
        d.ellipse([x - 3, y - 3, x + 3, y + 3], fill=PLANET_RIM)
    # Soft blur
    layer = layer.filter(ImageFilter.GaussianBlur(radius=1))
    return Image.alpha_composite(base, layer)

def make_horizon_and_derelict(base: Image.Image) -> Image.Image:
    """Lower 1/3: a dark horizon line + a derelict satellite silhouette in midground."""
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    horizon_y = 510
    # Horizon: gradual darkening from y=510 to y=720
    for y in range(horizon_y, H):
        t = (y - horizon_y) / (H - horizon_y)
        # Subtle: keep mostly transparent at top, fully dark at bottom
        alpha = int(80 + 175 * (t ** 2))
        d.line([(0, y), (W, y)], fill=(0, 0, 0, alpha))
    # Derelict silhouette: long horizontal body + small protrusions
    # Position: center-left, around y=440-510
    dx, dy = 400, 440
    # Main body (long horizontal capsule)
    d.rectangle([dx, dy, dx + 380, dy + 30], fill=DERELICT)
    # Front prong (left)
    d.polygon([(dx - 40, dy + 8), (dx, dy + 4), (dx, dy + 26), (dx - 40, dy + 22)], fill=DERELICT)
    # Back prong (right)
    d.polygon([(dx + 380, dy + 4), (dx + 420, dy + 8), (dx + 420, dy + 22), (dx + 380, dy + 26)], fill=DERELICT)
    # Antennae / detail
    d.line([(dx + 60, dy), (dx + 60, dy - 18)], fill=DERELICT, width=2)
    d.line([(dx + 180, dy), (dx + 180, dy - 25)], fill=DERELICT, width=2)
    d.line([(dx + 300, dy), (dx + 300, dy - 14)], fill=DERELICT, width=2)
    # Windows (lit amber dots)
    for wx in [dx + 50, dx + 100, dx + 200, dx + 250, dx + 320]:
        d.rectangle([wx, dy + 10, wx + 4, dy + 14], fill=(180, 120, 60, 255))
    # Backlight rim (right edge of derelict, facing planet)
    d.line([(dx + 420, dy + 8), (dx + 420, dy + 22)], fill=DERELICT_RIM, width=1)
    return Image.alpha_composite(base, layer)

def make_haze_and_vignette(base: Image.Image) -> Image.Image:
    """Bottom atmospheric haze + corner vignette."""
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    # Haze: vertical gradient in lower 200px
    for y in range(520, H):
        t = (y - 520) / 200
        alpha = int(40 * (1 - t) + 100 * t)
        d.line([(0, y), (W, y)], fill=(20, 25, 40, alpha))
    layer = layer.filter(ImageFilter.GaussianBlur(radius=8))
    base = Image.alpha_composite(base, layer)
    # Vignette: dark corners
    vig = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(vig)
    for i in range(40):
        alpha = int(i * 5)
        # Top edge
        d.line([(0, i), (W, i)], fill=(0, 0, 0, alpha))
        # Bottom edge
        d.line([(0, H - 1 - i), (W, H - 1 - i)], fill=(0, 0, 0, alpha))
        # Left edge
        d.line([(i, 0), (i, H)], fill=(0, 0, 0, alpha))
        # Right edge
        d.line([(W - 1 - i, 0), (W - 1 - i, H)], fill=(0, 0, 0, alpha))
    vig = vig.filter(ImageFilter.GaussianBlur(radius=30))
    return Image.alpha_composite(base, vig)

def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    print("  building title screen layers...")
    sky = make_sky()
    print("    sky gradient OK")
    with_nebula = make_nebula(sky)
    print("    nebula OK")
    with_stars = make_starfield(with_nebula)
    print("    starfield OK")
    with_planet = make_planet(with_stars)
    print("    planet OK")
    with_derelict = make_horizon_and_derelict(with_planet)
    print("    derelict OK")
    final = make_haze_and_vignette(with_derelict)
    print("    haze + vignette OK")
    path = os.path.join(OUT_DIR, "title_bg.png")
    final.save(path)
    size_kb = os.path.getsize(path) / 1024
    print(f"\n  wrote {path} ({size_kb:.1f} KB, {W}x{H})")

if __name__ == "__main__":
    main()
