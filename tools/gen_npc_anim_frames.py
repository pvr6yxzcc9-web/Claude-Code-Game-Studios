#!/usr/bin/env python3
"""
gen_npc_anim_frames.py — Generate dialogue animation frames (S6-100).

For each NPC portrait, create 3 additional frames:
  *_mouth_open.png       — mouth open (for lip-sync during dialogue)
  *_eyes_blink.png       — eyes closed (rare blink)
  *_mouth_open_blink.png  — combined (used briefly)

Saves in assets/sprites/npcs/ alongside the existing base portraits.

Run from project root:
  python tools/gen_npc_anim_frames.py
"""
import os
from PIL import Image, ImageDraw

OUT_DIR = "assets/sprites/npcs"

# Mirror the palette from gen_npc_portraits.py
SKIN = (200, 160, 130, 255)
SKIN_DARK = (140, 100, 70, 255)
HAIR_BROWN = (100, 70, 50, 255)
HAIR_GRAY = (180, 180, 190, 255)
METAL = (140, 152, 168, 255)
AMBER = (220, 158, 80, 255)
AMBER_DARK = (140, 88, 48, 255)
AMBER_LIGHT = (255, 200, 100, 255)
RED = (220, 50, 50, 255)
RED_DARK = (140, 30, 30, 255)
CYAN = (90, 220, 255, 255)
CYAN_DIM = (50, 140, 180, 255)
WHITE = (240, 240, 240, 255)
GRAY_DARK = (40, 44, 52, 255)
NAVY = (16, 20, 32, 255)

def _modify_vera(img: Image.Image, mode: str) -> Image.Image:
    """Modify Vera's mouth/eyes. mode in {'open', 'blink', 'open_blink'}."""
    out = img.copy()
    d = ImageDraw.Draw(out)
    # Mouth position: (30, 22) to (34, 22), 1px line
    # Open mouth: ellipse 30,21 → 34,23 (filled darker)
    if mode in ("open", "open_blink"):
        d.line([(30, 22), (34, 22)], fill=NAVY)  # erase old line
        d.ellipse([29, 20, 35, 24], fill=SKIN_DARK, outline=NAVY)
    if mode in ("blink", "open_blink"):
        # Eyes at (28, 16) and (34, 16) — close them
        d.rectangle([28, 16, 30, 18], fill=NAVY)  # erase old
        d.rectangle([34, 16, 36, 18], fill=NAVY)
        # Closed eyes: short line
        d.line([(28, 17), (30, 17)], fill=SKIN_DARK)
        d.line([(34, 17), (36, 17)], fill=SKIN_DARK)
    return out

def _modify_marlow(img: Image.Image, mode: str) -> Image.Image:
    """Marlow is a hologram (low alpha). Mouth/eyes dim."""
    out = img.copy()
    d = ImageDraw.Draw(out)
    if mode in ("open", "open_blink"):
        # Mouth at (28, 16) and (34, 16) - dim cyan
        d.ellipse([29, 21, 35, 25], fill=(20, 40, 55, 180), outline=CYAN_DIM)
    if mode in ("blink", "open_blink"):
        # Eyes (cyan dots) - dim them
        d.ellipse([28, 16, 30, 18], fill=NAVY)
        d.ellipse([34, 16, 36, 18], fill=NAVY)
    return out

def _modify_courier(img: Image.Image, mode: str) -> Image.Image:
    """Courier 14 - helmeted. Mouth hidden behind helmet grille (no lip sync visible).
    Just blink the visor highlight (a brief dim)."""
    out = img.copy()
    d = ImageDraw.Draw(out)
    if mode in ("blink", "open_blink"):
        # Visor area: 24,14 → 40,22 — dim it briefly
        d.rectangle([24, 14, 40, 22], fill=(40, 60, 80, 200))  # dim cyan overlay
    return out

def _modify_drone(img: Image.Image, mode: str) -> Image.Image:
    """Drone operator - floating eye/lens. "Blink" = lens color shift."""
    out = img.copy()
    d = ImageDraw.Draw(out)
    if mode in ("open", "open_blink"):
        # Lens center (30, 34) - expand highlight to "talk" state
        d.ellipse([28, 32, 36, 40], fill=(140, 180, 220, 255))  # bigger lens
    if mode in ("blink", "open_blink"):
        # Eye lens dim
        d.ellipse([28, 32, 36, 40], fill=(60, 80, 100, 200))
    return out

MODIFIERS = {
    "vera_merchant.png": _modify_vera,
    "marlow_ghost.png": _modify_marlow,
    "courier_14.png": _modify_courier,
    "salvage_drone_operator.png": _modify_drone,
}

def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for base_name, modifier in MODIFIERS.items():
        src_path = os.path.join(OUT_DIR, base_name)
        if not os.path.exists(src_path):
            print(f"  SKIP {base_name} (not found)")
            continue
        img = Image.open(src_path).convert("RGBA")
        for mode, suffix in [("open", "_mouth_open.png"),
                            ("blink", "_eyes_blink.png"),
                            ("open_blink", "_mouth_open_blink.png")]:
            out = modifier(img, mode)
            out_path = os.path.join(OUT_DIR, base_name.replace(".png", suffix))
            out.save(out_path)
            print(f"  wrote {out_path}")
    print("\nAll NPC animation frames generated.")

if __name__ == "__main__":
    main()
