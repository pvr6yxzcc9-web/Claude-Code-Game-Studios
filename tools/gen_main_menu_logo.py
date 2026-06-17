#!/usr/bin/env python3
"""
gen_main_menu_logo.py — Generate the main menu Logo (S14-004).

Per art-bible: pixel-art style Logo, dark sci-fi feel.
Size: 800x300, 16:6 aspect ratio for title screen.

Output: assets/sprites/title/logo.png

The Logo is procedurally drawn (no font dependency for the Logo
itself — the title text Label still uses Noto Sans SC from
assets/fonts/). This ensures the Logo is recognizable even if the
project font fails to load.

Run from project root:
  python tools/gen_main_menu_logo.py
"""
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

OUT = "assets/sprites/title/logo.png"
W, H = 800, 300

# Palette (rail / steel / sci-fi)
NAVY_DARK = (8, 12, 24, 255)
NAVY = (16, 24, 48, 255)
STEEL = (140, 160, 180, 255)
STEEL_LIGHT = (200, 220, 240, 255)
AMBER = (255, 180, 60, 255)
AMBER_BRIGHT = (255, 220, 120, 255)
RED = (200, 60, 60, 255)
WHITE = (240, 240, 240, 255)


def draw_rail(d: ImageDraw.ImageDraw, x: int, y: int, length: int = 200) -> None:
    """Draw a horizontal rail segment (twin steel tracks with crossties)."""
    # Top rail
    d.rectangle([x, y, x + length, y + 4], fill=STEEL)
    d.rectangle([x, y + 1, x + length, y + 2], fill=STEEL_LIGHT)
    # Bottom rail
    d.rectangle([x, y + 30, x + length, y + 34], fill=STEEL)
    d.rectangle([x, y + 31, x + length, y + 32], fill=STEEL_LIGHT)
    # Crossties
    for i in range(0, length, 20):
        d.rectangle([x + i, y - 2, x + i + 12, y + 36], fill=(60, 40, 20, 255))


def draw_mech(d: ImageDraw.ImageDraw, cx: int, cy: int, scale: int = 1) -> None:
    """Draw a tiny pixel-art mech silhouette at (cx, cy)."""
    s = scale
    # Body (gray)
    d.rectangle([cx - 12 * s, cy - 6 * s, cx + 12 * s, cy + 10 * s], fill=(80, 90, 100, 255))
    d.rectangle([cx - 12 * s, cy - 6 * s, cx + 12 * s, cy - 4 * s], fill=(120, 130, 140, 255))
    # Cockpit (red glow)
    d.rectangle([cx - 4 * s, cy - 4 * s, cx + 4 * s, cy + 2 * s], fill=RED)
    d.rectangle([cx - 2 * s, cy - 4 * s, cx + 2 * s, cy - 2 * s], fill=AMBER_BRIGHT)
    # Arms
    d.rectangle([cx - 16 * s, cy - 2 * s, cx - 12 * s, cy + 6 * s], fill=(80, 90, 100, 255))
    d.rectangle([cx + 12 * s, cy - 2 * s, cx + 16 * s, cy + 6 * s], fill=(80, 90, 100, 255))
    # Legs
    d.rectangle([cx - 8 * s, cy + 10 * s, cx - 2 * s, cy + 18 * s], fill=(60, 70, 80, 255))
    d.rectangle([cx + 2 * s, cy + 10 * s, cx + 8 * s, cy + 18 * s], fill=(60, 70, 80, 255))
    # Head
    d.rectangle([cx - 4 * s, cy - 12 * s, cx + 4 * s, cy - 6 * s], fill=(100, 110, 120, 255))


def main() -> int:
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # === Background: dark with starfield ===
    d.rectangle([0, 0, W, H], fill=NAVY_DARK)
    # Stars
    import random
    random.seed(20260617)
    for _ in range(60):
        x = random.randint(0, W - 1)
        y = random.randint(0, H // 2)
        size = random.choice([1, 1, 1, 2])
        brightness = random.randint(180, 255)
        d.rectangle([x, y, x + size, y + size], fill=(brightness, brightness, brightness, 200))
    # Horizon glow (subtle)
    for y in range(H // 2, H):
        t = (y - H / 2) / (H / 2)
        a = int(40 * (1 - t))
        d.line([(0, y), (W, y)], fill=(40, 30, 20, a), width=1)

    # === Top decorative rail line ===
    draw_rail(d, 50, 50, length=700)
    # === Bottom decorative rail line ===
    draw_rail(d, 50, 230, length=700)

    # === Title text "RAILHUNTER" — drawn with built-in font fallback ===
    # Use AnonymousPro from project fonts for consistent English text
    font_path = "assets/fonts/AnonymousPro-Regular.ttf"
    if not os.path.exists(font_path):
        for candidate in [
            "C:/Windows/Fonts/consola.ttf",
            "C:/Windows/Fonts/NotoSansSC-Regular.otf",
        ]:
            if os.path.exists(candidate):
                font_path = candidate
                break
    title_font = None
    if os.path.exists(font_path):
        try:
            title_font = ImageFont.truetype(font_path, 64)
        except Exception:
            title_font = None
    subtitle_font = None
    if os.path.exists(font_path):
        try:
            subtitle_font = ImageFont.truetype(font_path, 18)
        except Exception:
            subtitle_font = None

    # Title (centered) — English only; Chinese subtitle is in main_menu.gd Label
    title = "RAILHUNTER"
    tw, th = 600, 60
    tx, ty = (W - tw) // 2, 110
    if title_font:
        bbox = d.textbbox((0, 0), title, font=title_font)
        tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
        tx = (W - tw) // 2
    # Title shadow (red glow)
    d.text((tx + 2, ty + 2), title, fill=(120, 30, 30, 200), font=title_font)
    # Title main
    d.text((tx, ty), title, fill=STEEL_LIGHT, font=title_font)
    # Title highlight (top half brighter)
    d.text((tx, ty - 1), title, fill=WHITE, font=title_font)

    # Subtitle (English only; Chinese is in main_menu.gd Label)
    subtitle = "STEEL RAIL HUNTER"
    sw = 400
    if subtitle_font:
        bbox = d.textbbox((0, 0), subtitle, font=subtitle_font)
        sw = bbox[2] - bbox[0]
    sx = (W - sw) // 2
    sy = 180
    d.text((sx, sy), subtitle, fill=AMBER, font=subtitle_font)

    # Decorative mechs at corners (small silhouettes)
    draw_mech(d, 80, 220, scale=1)
    draw_mech(d, W - 80, 220, scale=1)

    # Slight blur for soft pixel-art feel
    img = img.filter(ImageFilter.GaussianBlur(radius=0.4))
    img.save(OUT, optimize=True)
    print(f"  wrote {OUT} ({W}x{H})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
