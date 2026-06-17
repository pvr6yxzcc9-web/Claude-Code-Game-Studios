#!/usr/bin/env python3
"""
gen_boss_animation_frames.py — Generate boss animation frames (S19-001).

Per art-bible: bosses need 4-6 animation frames for combat
weight. Each boss gets: idle (1-2 frames), attack (2 frames:
windup + strike), hit (1 frame), death (1 frame).

For each of 5 bosses, generate 5 frames (4 effective states):
  {boss}_idle.png          — base (copy of base, maybe minor sway)
  {boss}_attack_windup.png — raised arms / energy gathering
  {boss}_attack_strike.png — full attack pose
  {boss}_hit.png           — flash white + recoil
  {boss}_death.png         — collapse / fade

Output: assets/sprites/enemies/{boss}_{frame}.png (25 files)

Approach: copy the base sprite + apply state-specific modifications
via PIL. Cheaper than re-drawing from scratch.

Run from project root:
  python tools/gen_boss_animation_frames.py
"""
import os
import shutil
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

OUT_DIR = "assets/sprites/enemies"

# Boss base sprites + their satellite color themes
BOSSES = [
    ("boss_marrow_sentinel", 64, (200, 60, 60), "Sat-1 derelict crew"),
    ("boss_ice_warden", 64, (90, 220, 255), "Sat-2 ice warden"),
    ("boss_hive_queen_guardian", 64, (220, 200, 80), "Sat-3 hive guardian"),
    ("boss_pluto_remnant", 64, (220, 50, 50), "Sat-4 warzone remnant"),
    ("boss_creator", 96, (255, 200, 80), "Sat-5 origin creator"),
]


def make_idle(base: Image.Image) -> Image.Image:
    """Idle — base sprite (no modification)."""
    return base.copy()


def make_idle2(base: Image.Image) -> Image.Image:
    """Idle frame 2 — subtle sway (slight horizontal shift, no other changes).

    Skipping for now to keep frame count to 5 per boss.
    """
    return base.copy()


def make_attack_windup(base: Image.Image) -> Image.Image:
    """Attack windup — boss glows brighter, slight color shift toward white."""
    out = base.copy()
    # Brighten by 20%
    out = ImageEnhance.Brightness(out).enhance(1.2)
    # Slight color overlay (additive)
    overlay = Image.new("RGBA", out.size, (255, 255, 255, 30))
    out = Image.alpha_composite(out, overlay)
    return out


def make_attack_strike(base: Image.Image) -> Image.Image:
    """Attack strike — full bright flash + impact lines."""
    out = base.copy()
    # Bright flash
    overlay = Image.new("RGBA", out.size, (255, 255, 255, 80))
    out = Image.alpha_composite(out, overlay)
    # Add radial impact lines at center
    d = ImageDraw.Draw(out)
    cx, cy = out.size[0] // 2, out.size[1] // 2
    for angle in range(0, 360, 30):
        import math
        rad = math.radians(angle)
        x1 = cx + int(math.cos(rad) * (out.size[0] // 2 - 4))
        y1 = cy + int(math.sin(rad) * (out.size[1] // 2 - 4))
        x2 = cx + int(math.cos(rad) * (out.size[0] // 2))
        y2 = cy + int(math.sin(rad) * (out.size[1] // 2))
        d.line([(x1, y1), (x2, y2)], fill=(255, 255, 255, 200), width=2)
    return out


def make_hit(base: Image.Image) -> Image.Image:
    """Hit — boss flashes red/white, slight downward shift (recoil)."""
    out = base.copy()
    # Flash red overlay
    overlay = Image.new("RGBA", out.size, (255, 100, 100, 100))
    out = Image.alpha_composite(out, overlay)
    # Recoil: shift down 2px
    shifted = Image.new("RGBA", out.size, (0, 0, 0, 0))
    shifted.paste(out, (0, 2))
    return shifted


def make_death(base: Image.Image) -> Image.Image:
    """Death — boss faded + tilted + lowered opacity."""
    out = base.copy()
    # Desaturate
    out = ImageEnhance.Color(out).enhance(0.2)
    # Reduce opacity
    alpha = out.split()[3]
    alpha = Image.eval(alpha, lambda x: int(x * 0.5))
    out.putalpha(alpha)
    # Tilt 15° (rotate)
    out = out.rotate(15, resample=Image.BICUBIC, expand=False)
    return out


def main() -> int:
    os.makedirs(OUT_DIR, exist_ok=True)
    for boss_id, size, color, description in BOSSES:
        base_path = os.path.join(OUT_DIR, f"{boss_id}.png")
        if not os.path.exists(base_path):
            print(f"  SKIP {boss_id} (no base sprite at {base_path})")
            continue
        base = Image.open(base_path).convert("RGBA")
        # Validate size
        if base.size != (size, size):
            print(f"  WARN {boss_id} base size {base.size} != expected ({size}, {size})")
        # Generate 5 frames per boss
        frames = [
            ("idle", make_idle(base)),
            ("attack_windup", make_attack_windup(base)),
            ("attack_strike", make_attack_strike(base)),
            ("hit", make_hit(base)),
            ("death", make_death(base)),
        ]
        for frame_name, img in frames:
            out_path = os.path.join(OUT_DIR, f"{boss_id}_{frame_name}.png")
            img.save(out_path)
            print(f"  wrote {out_path} ({img.size[0]}x{img.size[1]})")
    total = len(BOSSES) * 5
    print(f"\nGenerated {total} boss animation frames ({len(BOSSES)} bosses × 5 frames)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
