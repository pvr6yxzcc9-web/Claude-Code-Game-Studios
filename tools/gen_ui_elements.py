#!/usr/bin/env python3
"""
gen_ui_elements.py — Generate 12 UI element sprites (S17-002).

Per .claude/rules/ui-code.md: UI must use sprite-based visual
language, not raw ColorRect/Label. These 12 sprites cover the
core UI vocabulary for menus, dialogs, HUD.

Outputs (in assets/sprites/ui/):
  button_normal.png      64x16  — default button
  button_hover.png       64x16  — hover state
  button_pressed.png     64x16  — pressed state
  button_disabled.png    64x16  — disabled state
  panel_bg.png          256x128 — semi-transparent dialog panel
  panel_border.png      256x128 — 4-edge frame for panels
  dialog_portrait.png    64x64  — portrait frame (around NPC face)
  scrollbar_track.png    8x64   — vertical scrollbar track
  scrollbar_handle.png   8x24   — scrollbar handle
  slider_track.png      96x8   — horizontal slider track
  slider_handle.png     12x12  — slider handle
  checkbox_unchecked.png 16x16 — empty checkbox
  checkbox_checked.png   16x16 — checked checkbox

Run from project root:
  python tools/gen_ui_elements.py
"""
import os
from PIL import Image, ImageDraw

OUT_DIR = "assets/sprites/ui"

# UI palette
NAVY = (16, 20, 32, 255)
NAVY_DARK = (10, 14, 24, 255)
NAVY_MID = (24, 30, 48, 255)
STEEL = (140, 152, 168, 255)
STEEL_LIGHT = (200, 220, 240, 255)
AMBER = (255, 200, 100, 255)
AMBER_DARK = (140, 88, 48, 255)
CYAN = (90, 220, 255, 255)
CYAN_DIM = (50, 140, 180, 255)
RED = (200, 60, 60, 255)
GRAY_DARK = (40, 44, 52, 255)
GRAY_MID = (80, 84, 92, 255)
GRAY = (120, 124, 132, 255)
WHITE = (240, 240, 240, 255)
WHITE_BRIGHT = (255, 255, 255, 255)


def make_button_normal() -> Image.Image:
    """Default button — dark navy bg, amber border, no fill."""
    img = Image.new("RGBA", (64, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 63, 15], fill=NAVY_MID, outline=AMBER_DARK)
    d.rectangle([0, 0, 63, 1], fill=AMBER)  # top highlight
    d.rectangle([0, 14, 63, 15], fill=NAVY_DARK)  # bottom shadow
    return img


def make_button_hover() -> Image.Image:
    """Hover state — brighter bg, glowing amber border."""
    img = Image.new("RGBA", (64, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 63, 15], fill=NAVY, outline=AMBER)
    d.rectangle([0, 0, 63, 1], fill=AMBER_BRIGHT) if False else d.rectangle([0, 0, 63, 2], fill=(255, 230, 150, 255))
    d.rectangle([0, 14, 63, 15], fill=NAVY_DARK)
    return img


def make_button_pressed() -> Image.Image:
    """Pressed state — darker bg, inset shadow."""
    img = Image.new("RGBA", (64, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 63, 15], fill=NAVY_DARK, outline=AMBER_DARK)
    d.rectangle([0, 0, 63, 1], fill=NAVY_DARK)  # top shadow (pressed)
    d.rectangle([0, 14, 63, 15], fill=AMBER_DARK)  # bottom highlight
    return img


def make_button_disabled() -> Image.Image:
    """Disabled state — grayed out."""
    img = Image.new("RGBA", (64, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 63, 15], fill=GRAY_DARK, outline=GRAY_MID)
    d.rectangle([0, 0, 63, 1], fill=GRAY_MID)
    d.rectangle([0, 14, 63, 15], fill=GRAY_DARK)
    return img


def make_panel_bg() -> Image.Image:
    """Dialog panel — semi-transparent dark fill."""
    img = Image.new("RGBA", (256, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 255, 127], fill=(10, 14, 24, 220))  # 86% alpha
    return img


def make_panel_border() -> Image.Image:
    """Panel border — 4-edge frame, no fill."""
    img = Image.new("RGBA", (256, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Top + bottom horizontal edges
    d.line([(0, 0), (255, 0)], fill=AMBER, width=2)
    d.line([(0, 127), (255, 127)], fill=AMBER, width=2)
    # Left + right vertical edges
    d.line([(0, 0), (0, 127)], fill=AMBER, width=2)
    d.line([(255, 0), (255, 127)], fill=AMBER, width=2)
    # Inner darker line (double border)
    d.line([(2, 2), (253, 2)], fill=AMBER_DARK, width=1)
    d.line([(2, 125), (253, 125)], fill=AMBER_DARK, width=1)
    return img


def make_dialog_portrait() -> Image.Image:
    """Dialog portrait frame — 64x64 with amber border around portrait."""
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Outer dark square
    d.rectangle([0, 0, 63, 63], fill=NAVY_DARK)
    # Inner cutout (where portrait goes)
    d.rectangle([2, 2, 61, 61], fill=(0, 0, 0, 0))  # transparent
    # Amber frame
    d.rectangle([0, 0, 63, 63], outline=AMBER, width=2)
    # Corner brackets
    for x, y in [(0, 0), (62, 0), (0, 62), (62, 62)]:
        d.line([(x - 2, y), (x + 4, y)], fill=AMBER, width=2)
        d.line([(x, y - 2), (x, y + 4)], fill=AMBER, width=2)
    # Name plate (bottom 12px)
    d.rectangle([0, 52, 63, 63], fill=(10, 14, 24, 200))
    d.rectangle([0, 52, 63, 53], fill=AMBER)
    return img


def make_scrollbar_track() -> Image.Image:
    """Vertical scrollbar track — 8x64."""
    img = Image.new("RGBA", (8, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 7, 63], fill=NAVY_DARK, outline=AMBER_DARK)
    d.rectangle([3, 0, 4, 63], fill=NAVY)  # center groove
    return img


def make_scrollbar_handle() -> Image.Image:
    """Scrollbar handle — 8x24."""
    img = Image.new("RGBA", (8, 24), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 7, 23], fill=AMBER, outline=AMBER_DARK)
    # 3 grip lines
    for y in [7, 11, 15]:
        d.line([(2, y), (5, y)], fill=AMBER_DARK, width=1)
    return img


def make_slider_track() -> Image.Image:
    """Horizontal slider track — 96x8."""
    img = Image.new("RGBA", (96, 8), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 95, 7], fill=NAVY_DARK, outline=AMBER_DARK)
    d.rectangle([0, 3, 95, 4], fill=NAVY)  # center groove
    return img


def make_slider_handle() -> Image.Image:
    """Slider handle — 12x12."""
    img = Image.new("RGBA", (12, 12), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 11, 11], fill=AMBER, outline=AMBER_DARK)
    d.rectangle([2, 2, 9, 9], fill=AMBER_BRIGHT) if False else d.rectangle([2, 2, 9, 9], fill=(255, 230, 150, 255))
    return img


def make_checkbox_unchecked() -> Image.Image:
    """Empty checkbox — 16x16."""
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 15, 15], fill=NAVY_DARK, outline=AMBER)
    d.rectangle([1, 1, 14, 14], fill=NAVY)
    return img


def make_checkbox_checked() -> Image.Image:
    """Checked checkbox — 16x16 with cyan check."""
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 15, 15], fill=NAVY_DARK, outline=AMBER)
    d.rectangle([1, 1, 14, 14], fill=NAVY)
    # Check mark (cyan V)
    d.line([(3, 8), (6, 11), (13, 4)], fill=CYAN, width=2)
    return img


SPRITES = [
    ("button_normal", make_button_normal),
    ("button_hover", make_button_hover),
    ("button_pressed", make_button_pressed),
    ("button_disabled", make_button_disabled),
    ("panel_bg", make_panel_bg),
    ("panel_border", make_panel_border),
    ("dialog_portrait", make_dialog_portrait),
    ("scrollbar_track", make_scrollbar_track),
    ("scrollbar_handle", make_scrollbar_handle),
    ("slider_track", make_slider_track),
    ("slider_handle", make_slider_handle),
    ("checkbox_unchecked", make_checkbox_unchecked),
    ("checkbox_checked", make_checkbox_checked),
]


def main() -> int:
    os.makedirs(OUT_DIR, exist_ok=True)
    for name, fn in SPRITES:
        img = fn()
        path = os.path.join(OUT_DIR, f"{name}.png")
        img.save(path)
        print(f"  wrote {path} {img.size}")
    print(f"\nGenerated {len(SPRITES)} UI element sprites")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
