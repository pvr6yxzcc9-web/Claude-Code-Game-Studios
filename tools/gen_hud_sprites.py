#!/usr/bin/env python3
"""
gen_hud_sprites.py — Generate HUD element sprites (S6-008).

Outputs:
  assets/sprites/hud/
    hp_bar_bg.png       200x18 (dark red bg)
    hp_bar_fill.png     200x18 (bright red/green gradient frame)
    hp_bar_frame.png    200x18 (border)
    fragment_icon.png   16x16 (cyan diamond)
    mech_part_torso.png 16x16
    mech_part_legs.png  16x16
    mech_part_left_arm.png 16x16
    mech_part_right_arm.png 16x16
    weapons/
      blaster_rifle.png  48x24 (rifle silhouette)
      railgun.png       48x24
      plasma_cannon.png 48x24
      sniper_rifle.png  48x24
      shotgun.png       48x24
      shotgun_spread.png 48x24
      mine_layer.png    48x24
      arc_emitter.png   48x24

Run from project root:
  python tools/gen_hud_sprites.py
"""
import os
from PIL import Image, ImageDraw

OUT_DIR = "assets/sprites/hud"
WEAPON_DIR = "assets/sprites/hud/weapons"

# Palette (consistent with art-bible)
DARK = (16, 20, 32, 255)
DARK_NAVY = (16, 20, 32, 0)
AMBER = (220, 158, 80, 255)
AMBER_LIGHT = (255, 200, 100, 255)
AMBER_DARK = (140, 88, 48, 255)
CYAN = (90, 220, 255, 255)
RED = (220, 50, 50, 255)
GREEN = (80, 220, 100, 255)
GRAY = (100, 100, 100, 255)
GRAY_DARK = (50, 50, 50, 255)
WHITE = (240, 240, 240, 255)

# ============================================================
# HP Bar (200x18)
# ============================================================

def make_hp_bar_bg() -> Image.Image:
    """HP bar background — dark red rectangle with subtle gradient."""
    img = Image.new("RGBA", (200, 18), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Dark red bg
    draw.rectangle([0, 0, 199, 17], fill=(60, 10, 10, 255))
    # Inner border shadow
    draw.rectangle([1, 1, 198, 16], outline=(20, 0, 0, 255))
    return img

def make_hp_bar_fill() -> Image.Image:
    """HP bar fill — green→yellow→red horizontal gradient, used as a fill texture."""
    img = Image.new("RGBA", (200, 18), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # 3-zone gradient: green (left) → amber (mid) → red (right)
    for x in range(200):
        pct = x / 199.0
        if pct < 0.5:
            # Green to amber
            t = pct / 0.5
            r = int(80 + (220 - 80) * t)
            g = int(220 - (220 - 158) * t)
            b = int(100 - (100 - 80) * t)
        else:
            # Amber to red
            t = (pct - 0.5) / 0.5
            r = int(220 + (220 - 220) * t)  # stays 220
            g = int(158 - (158 - 50) * t)
            b = int(80 - (80 - 50) * t)
        draw.line([(x, 0), (x, 17)], fill=(r, g, b, 255))
    return img

def make_hp_bar_frame() -> Image.Image:
    """HP bar frame — bright border around the bar."""
    img = Image.new("RGBA", (200, 18), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Outer border
    draw.rectangle([0, 0, 199, 17], outline=AMBER_LIGHT, width=1)
    # Corner accents
    for cx, cy in [(0, 0), (199, 0), (0, 17), (199, 17)]:
        draw.ellipse([cx - 1, cy - 1, cx + 1, cy + 1], fill=AMBER)
    # Center divider (notch)
    draw.line([(100, 0), (100, 17)], fill=AMBER, width=1)
    return img

# ============================================================
# Fragment Icon (16x16) — cyan diamond
# ============================================================

def make_fragment_icon() -> Image.Image:
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Diamond outline
    pts = [(8, 1), (15, 8), (8, 15), (1, 8)]
    draw.polygon(pts, outline=CYAN)
    # Inner glow (lighter center)
    inner = [(8, 4), (12, 8), (8, 12), (4, 8)]
    draw.polygon(inner, fill=(140, 240, 255, 180))
    # Core
    draw.ellipse([6, 6, 10, 10], fill=WHITE)
    return img

# ============================================================
# Mech part badges (16x16)
# ============================================================

def make_mech_part_torso() -> Image.Image:
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Shield-like torso
    draw.rectangle([3, 4, 12, 13], fill=AMBER_DARK, outline=AMBER_LIGHT)
    draw.rectangle([5, 6, 10, 8], fill=CYAN)  # core
    return img

def make_mech_part_legs() -> Image.Image:
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Two pillars
    draw.rectangle([4, 3, 6, 13], fill=AMBER_DARK, outline=AMBER_LIGHT)
    draw.rectangle([9, 3, 11, 13], fill=AMBER_DARK, outline=AMBER_LIGHT)
    # Joint bar
    draw.rectangle([3, 7, 12, 8], fill=AMBER)
    return img

def make_mech_part_arm(part_id: str) -> Image.Image:
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Arm silhouette (vertical limb)
    if part_id == "left_arm":
        # Left arm: bent at elbow, hand on left
        draw.rectangle([7, 3, 9, 9], fill=AMBER_DARK)  # upper
        draw.rectangle([4, 9, 9, 11], fill=AMBER)  # forearm
        draw.ellipse([2, 9, 5, 13], fill=AMBER_LIGHT)  # hand
    else:
        # Right arm: mirror
        draw.rectangle([7, 3, 9, 9], fill=AMBER_DARK)
        draw.rectangle([7, 9, 12, 11], fill=AMBER)
        draw.ellipse([11, 9, 14, 13], fill=AMBER_LIGHT)
    return img

# ============================================================
# Weapon icons (48x24) — distinct silhouettes per weapon
# ============================================================

def make_weapon(weapon_id: str) -> Image.Image:
    """Generate a 48x24 weapon icon based on the weapon's id."""
    img = Image.new("RGBA", (48, 24), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Common: dark border background slot
    draw.rectangle([0, 0, 47, 23], fill=(20, 25, 35, 255), outline=GRAY_DARK)

    if weapon_id == "blaster_rifle":
        # Standard rifle: stock + barrel
        draw.rectangle([6, 9, 18, 15], fill=AMBER_DARK)  # stock
        draw.rectangle([18, 10, 36, 14], fill=GRAY)  # barrel
        draw.ellipse([35, 9, 41, 15], fill=AMBER_LIGHT)  # muzzle
        # Sight
        draw.rectangle([20, 6, 24, 10], fill=GRAY_DARK)
    elif weapon_id == "railgun":
        # Long railgun: extra long barrel
        draw.rectangle([4, 9, 14, 15], fill=AMBER_DARK)  # stock
        draw.rectangle([14, 11, 40, 13], fill=CYAN)  # rail (cyan glow)
        draw.ellipse([39, 9, 45, 15], fill=WHITE)  # muzzle flash
    elif weapon_id == "plasma_cannon":
        # Bulky cannon
        draw.rectangle([4, 7, 24, 17], fill=AMBER_DARK)
        draw.rectangle([24, 8, 38, 16], fill=GRAY)
        draw.ellipse([36, 6, 44, 18], fill=(140, 90, 220, 255))  # plasma
        draw.ellipse([39, 9, 42, 15], fill=WHITE)
    elif weapon_id == "sniper_rifle":
        # Sniper: very long thin barrel
        draw.rectangle([4, 9, 16, 15], fill=AMBER_DARK)
        draw.rectangle([16, 11, 44, 13], fill=GRAY)
        # Scope
        draw.rectangle([20, 6, 26, 12], fill=GRAY_DARK)
        draw.ellipse([21, 7, 25, 11], fill=CYAN)  # scope lens
    elif weapon_id == "shotgun":
        # Shotgun: thick stock + wide barrel
        draw.rectangle([4, 8, 18, 16], fill=AMBER_DARK)  # stock
        draw.rectangle([18, 9, 38, 15], fill=GRAY)  # barrel
        draw.rectangle([18, 11, 38, 13], fill=GRAY_DARK)  # inner barrel line
        draw.ellipse([36, 8, 42, 16], fill=AMBER_LIGHT)
    elif weapon_id == "shotgun_spread":
        # Spread shotgun: wider, with spread indicator
        draw.rectangle([4, 8, 16, 16], fill=AMBER_DARK)
        draw.rectangle([16, 9, 32, 15], fill=GRAY)
        # Spread pattern (3 dots)
        for dx, dy in [(36, 9), (38, 12), (36, 15)]:
            draw.ellipse([dx - 1, dy - 1, dx + 1, dy + 1], fill=AMBER_LIGHT)
    elif weapon_id == "mine_layer":
        # Mine layer: short stock with launcher and mine icon
        draw.rectangle([4, 9, 16, 15], fill=AMBER_DARK)
        draw.rectangle([16, 10, 28, 14], fill=GRAY)  # launcher
        # Mine icon at end
        draw.ellipse([32, 8, 40, 16], fill=RED)
        draw.ellipse([34, 10, 38, 14], fill=(255, 200, 100, 255))  # mine spike
    elif weapon_id == "arc_emitter":
        # Arc emitter: stock with electrical coils
        draw.rectangle([4, 9, 18, 15], fill=AMBER_DARK)
        draw.rectangle([18, 10, 30, 14], fill=GRAY)
        # Coils (cyan zigzag)
        for i in range(3):
            cx = 32 + i * 4
            draw.line([(cx, 9), (cx + 2, 12), (cx, 15)], fill=CYAN, width=1)
    else:
        # Fallback: question mark
        draw.text((20, 4), "?", fill=AMBER_LIGHT)

    return img

def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    os.makedirs(WEAPON_DIR, exist_ok=True)

    # HUD core
    huds = {
        "hp_bar_bg.png": make_hp_bar_bg(),
        "hp_bar_fill.png": make_hp_bar_fill(),
        "hp_bar_frame.png": make_hp_bar_frame(),
        "fragment_icon.png": make_fragment_icon(),
        "mech_part_torso.png": make_mech_part_torso(),
        "mech_part_legs.png": make_mech_part_legs(),
        "mech_part_left_arm.png": make_mech_part_arm("left_arm"),
        "mech_part_right_arm.png": make_mech_part_arm("right_arm"),
    }
    for name, img in huds.items():
        path = os.path.join(OUT_DIR, name)
        img.save(path)
        print(f"  wrote {path} ({img.size[0]}x{img.size[1]})")

    # Weapons
    weapon_ids = [
        "blaster_rifle", "railgun", "plasma_cannon", "sniper_rifle",
        "shotgun", "shotgun_spread", "mine_layer", "arc_emitter",
    ]
    for wid in weapon_ids:
        img = make_weapon(wid)
        path = os.path.join(WEAPON_DIR, f"{wid}.png")
        img.save(path)
        print(f"  wrote {path} ({img.size[0]}x{img.size[1]})")

    print(f"\n{len(huds) + len(weapon_ids)} HUD sprite(s) generated.")

if __name__ == "__main__":
    main()
