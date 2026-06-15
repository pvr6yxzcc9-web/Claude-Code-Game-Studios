#!/usr/bin/env python3
"""
gen_ch2_assets.py — Generate all Ch2 art assets in batch (S6-102 full).

Outputs:
  assets/sprites/enemies/ice_{frostling,glacier,shard_bot,ice_drone,frost_walker,crystal_sentinel}.png  (6 enemies)
  assets/sprites/enemies/boss_ice_warden.png                                              (1 boss)
  assets/sprites/npcs/{frost_engineer,ice_hermit,scavenger_leader,frost_drone}.png          (4 NPCs)
  assets/sprites/title/title_ch2.png                                                     (chapter bg)
  assets/audio/music/frozen_reactor.wav                                                  (1 BGM)
"""
import os
import struct
import math
import wave
import random
from PIL import Image, ImageDraw, ImageFilter

# === Palette (frozen/ice) ===
ICE_DARK = (40, 70, 100, 255)
ICE_MID = (90, 145, 180, 255)
ICE_LIGHT = (160, 210, 235, 255)
ICE_BRIGHT = (220, 240, 255, 255)
FROST = (230, 245, 255, 255)
WHITE = (240, 240, 240, 255)
DARK = (15, 30, 50, 255)
ACCENT_BLUE = (60, 120, 180, 255)
ACCENT_CYAN = (100, 200, 230, 255)
NAVY = (10, 20, 40, 255)
WARN_RED = (200, 60, 60, 255)

ENEMY_DIR = "assets/sprites/enemies"
NPC_DIR = "assets/sprites/npcs"
TITLE_DIR = "assets/sprites/title"
MUSIC_DIR = "assets/audio/music"

def draw_ice_glow(d: ImageDraw.Draw, cx: int, cy: int, r: int) -> None:
    """Draws a soft cyan/ice glow centered at (cx, cy)."""
    for ring in range(r, 0, -2):
        alpha = max(0, 100 - ring * 2)
        d.ellipse([cx - ring, cy - ring, cx + ring, cy + ring],
                  outline=(ACCENT_CYAN[0], ACCENT_CYAN[1], ACCENT_CYAN[2], alpha))

# === Enemies (6) ===
def make_frostling() -> Image.Image:
    """Small ice sprite — fast, weak."""
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Body (small ice block)
    d.rectangle([10, 14, 22, 26], fill=ICE_MID, outline=ICE_LIGHT)
    # Head (round)
    d.ellipse([11, 6, 21, 18], fill=ICE_LIGHT, outline=ICE_BRIGHT)
    # Eyes (icy)
    d.ellipse([13, 11, 15, 13], fill=DARK)
    d.ellipse([17, 11, 19, 13], fill=DARK)
    # Frost spikes
    d.polygon([(16, 2), (18, 6), (14, 6)], fill=ICE_BRIGHT)
    d.polygon([(10, 14), (8, 18), (10, 20)], fill=ICE_BRIGHT)
    d.polygon([(22, 14), (24, 18), (22, 20)], fill=ICE_BRIGHT)
    return img

def make_glacier() -> Image.Image:
    """Medium tanky ice construct."""
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Larger body, armored
    d.rectangle([7, 12, 25, 28], fill=ICE_DARK, outline=ICE_MID)
    # Ice plating lines
    d.line([(7, 18), (25, 18)], fill=ICE_MID, width=1)
    d.line([(7, 23), (25, 23)], fill=ICE_MID, width=1)
    # Head
    d.ellipse([9, 4, 23, 16], fill=ICE_MID, outline=ICE_LIGHT)
    # Visor (cyan glow)
    d.rectangle([12, 8, 20, 12], fill=ACCENT_CYAN)
    d.rectangle([14, 9, 18, 11], fill=ICE_BRIGHT)
    # Frost crystals on shoulders
    d.polygon([(5, 10), (7, 14), (3, 16)], fill=ICE_BRIGHT)
    d.polygon([(27, 10), (25, 14), (29, 16)], fill=ICE_BRIGHT)
    return img

def make_shard_bot() -> Image.Image:
    """Sharp, spiky ice attacker."""
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Body (diamond shape)
    d.polygon([(16, 8), (24, 16), (16, 26), (8, 16)], fill=ICE_MID, outline=ICE_LIGHT)
    # Spikes
    d.polygon([(16, 4), (14, 8), (18, 8)], fill=ICE_BRIGHT)
    d.polygon([(28, 16), (24, 14), (24, 18)], fill=ICE_BRIGHT)
    d.polygon([(16, 28), (14, 26), (18, 26)], fill=ICE_BRIGHT)
    d.polygon([(4, 16), (8, 14), (8, 18)], fill=ICE_BRIGHT)
    # Eye
    d.ellipse([14, 14, 18, 18], fill=DARK)
    d.ellipse([15, 15, 17, 17], fill=ACCENT_CYAN)
    return img

def make_ice_drone() -> Image.Image:
    """Floating ice eye / sensor."""
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Central eye
    d.ellipse([10, 10, 22, 22], fill=ICE_DARK, outline=ICE_LIGHT)
    d.ellipse([13, 13, 19, 19], fill=ACCENT_CYAN)
    d.ellipse([15, 15, 17, 17], fill=ICE_BRIGHT)
    # Frost tendrils (4 directions)
    for dx, dy in [(-4, 0), (4, 0), (0, -4), (0, 4)]:
        x, y = 16 + dx*2, 16 + dy*2
        d.ellipse([x-2, y-2, x+2, y+2], fill=ICE_LIGHT)
    return img

def make_frost_walker() -> Image.Image:
    """Bipedal ice robot with legs."""
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Head
    d.rectangle([11, 4, 21, 12], fill=ICE_MID, outline=ICE_LIGHT)
    d.rectangle([13, 7, 19, 9], fill=ACCENT_CYAN)  # visor
    # Torso
    d.rectangle([10, 13, 22, 22], fill=ICE_DARK, outline=ICE_MID)
    d.line([(10, 18), (22, 18)], fill=ICE_MID, width=1)
    # Arms (raised)
    d.rectangle([5, 13, 9, 21], fill=ICE_DARK, outline=ICE_MID)
    d.rectangle([23, 13, 27, 21], fill=ICE_DARK, outline=ICE_MID)
    # Legs
    d.rectangle([12, 22, 16, 30], fill=ICE_DARK, outline=ICE_MID)
    d.rectangle([16, 22, 20, 30], fill=ICE_DARK, outline=ICE_MID)
    return img

def make_crystal_sentinel() -> Image.Image:
    """Elite ice guardian, sharp crystal form."""
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Hexagonal crystal body
    d.polygon([(16, 4), (26, 10), (26, 22), (16, 28), (6, 22), (6, 10)],
              fill=ICE_MID, outline=ICE_BRIGHT)
    # Inner crystal
    d.polygon([(16, 10), (22, 14), (22, 20), (16, 24), (10, 20), (10, 14)],
              fill=ICE_LIGHT, outline=ICE_BRIGHT)
    # Eye
    d.ellipse([14, 14, 18, 18], fill=DARK)
    d.ellipse([15, 15, 17, 17], fill=ACCENT_CYAN)
    return img

def make_boss_ice_warden() -> Image.Image:
    """Big boss — 64x64."""
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Aura
    draw_ice_glow(d, 32, 32, 28)
    # Body — large ice golem
    d.rectangle([14, 22, 50, 56], fill=ICE_DARK, outline=ICE_LIGHT)
    # Shoulders
    d.rectangle([6, 18, 18, 32], fill=ICE_DARK, outline=ICE_MID)
    d.rectangle([46, 18, 58, 32], fill=ICE_DARK, outline=ICE_MID)
    # Head
    d.rectangle([20, 4, 44, 20], fill=ICE_MID, outline=ICE_BRIGHT)
    # Crown / frost spikes
    d.polygon([(20, 4), (24, 0), (28, 4)], fill=ICE_BRIGHT)
    d.polygon([(32, 0), (36, 4), (40, 0), (44, 4)], fill=ICE_BRIGHT)
    # Visor (eye)
    d.rectangle([24, 10, 40, 14], fill=ACCENT_CYAN)
    d.rectangle([26, 11, 38, 13], fill=ICE_BRIGHT)
    # Chest crystal
    d.polygon([(28, 26), (32, 22), (36, 26), (36, 36), (32, 40), (28, 36)], fill=ICE_LIGHT, outline=ICE_BRIGHT)
    d.ellipse([30, 28, 34, 32], fill=ACCENT_CYAN)
    return img

ENEMIES = {
    "frostling.png": make_frostling,
    "glacier.png": make_glacier,
    "shard_bot.png": make_shard_bot,
    "ice_drone.png": make_ice_drone,
    "frost_walker.png": make_frost_walker,
    "crystal_sentinel.png": make_crystal_sentinel,
    "boss_ice_warden.png": make_boss_ice_warden,
}

# === NPCs (4) ===
def make_frost_engineer() -> Image.Image:
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Body (heavy frost suit)
    d.rectangle([18, 28, 46, 60], fill=ICE_DARK, outline=ICE_LIGHT)
    # Frost patches
    d.line([(20, 38), (44, 38)], fill=ICE_LIGHT, width=1)
    d.line([(20, 48), (44, 48)], fill=ICE_LIGHT, width=1)
    # Head
    d.ellipse([24, 8, 40, 28], fill=(220, 200, 190, 255), outline=(150, 120, 100, 255))
    # Beanie
    d.rectangle([22, 4, 42, 14], fill=(140, 90, 60, 255), outline=(100, 60, 40, 255))
    d.ellipse([30, 0, 34, 6], fill=(180, 130, 90, 255))  # pom
    # Beard
    d.polygon([(24, 22), (40, 22), (38, 30), (26, 30)], fill=(200, 200, 210, 255))
    # Eyes (warm)
    d.ellipse([28, 16, 30, 18], fill=DARK)
    d.ellipse([34, 16, 36, 18], fill=DARK)
    # Tool
    d.rectangle([44, 36, 50, 40], fill=(140, 180, 200, 255), outline=ICE_DARK)
    return img

def make_ice_hermit() -> Image.Image:
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Robe (heavy)
    d.polygon([(18, 26), (46, 26), (52, 60), (12, 60)], fill=(60, 60, 100, 255), outline=(30, 30, 60, 255))
    # Hood
    d.polygon([(16, 12), (32, 2), (48, 12), (44, 30), (20, 30)], fill=(40, 40, 80, 255), outline=(20, 20, 60, 255))
    # Face (mostly shadow)
    d.ellipse([22, 16, 42, 32], fill=(180, 200, 220, 255))
    # Eyes glow (cyan)
    d.ellipse([27, 22, 30, 25], fill=ACCENT_CYAN)
    d.ellipse([35, 22, 38, 25], fill=ACCENT_CYAN)
    # Staff
    d.line([(50, 30), (56, 8)], fill=(80, 80, 100, 255), width=2)
    d.ellipse([54, 6, 58, 10], fill=ACCENT_CYAN)
    return img

def make_scavenger_leader() -> Image.Image:
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Body (armored vest)
    d.rectangle([18, 28, 46, 60], fill=(80, 50, 30, 255), outline=(50, 30, 20, 255))
    # Vest details
    d.rectangle([22, 32, 42, 40], fill=(60, 35, 20, 255), outline=(40, 20, 10, 255))
    d.rectangle([28, 36, 36, 38], fill=(200, 180, 60, 255))  # badge
    # Head
    d.ellipse([24, 8, 40, 28], fill=(220, 180, 150, 255), outline=(150, 120, 100, 255))
    # Bandana
    d.rectangle([24, 14, 40, 20], fill=(180, 40, 40, 255), outline=(120, 20, 20, 255))
    # Eyes (determined)
    d.ellipse([27, 18, 30, 21], fill=DARK)
    d.ellipse([34, 18, 37, 21], fill=DARK)
    # Hat
    d.polygon([(22, 8), (42, 8), (38, 2), (26, 2)], fill=(40, 30, 20, 255), outline=(20, 15, 10, 255))
    return img

def make_frost_drone() -> Image.Image:
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Main body (hex frame)
    d.polygon([(16, 18), (32, 10), (48, 18), (52, 38), (40, 56), (24, 56), (12, 38)],
              fill=ICE_DARK, outline=ICE_LIGHT)
    # Eye (lens)
    d.ellipse([24, 24, 40, 40], fill=NAVY, outline=ACCENT_CYAN)
    d.ellipse([28, 28, 36, 36], fill=ACCENT_CYAN)
    d.ellipse([30, 30, 34, 34], fill=ICE_BRIGHT)
    # 4 hover jets
    for cx, cy in [(20, 56), (32, 60), (44, 56), (14, 42), (50, 42)]:
        d.ellipse([cx-3, cy-3, cx+3, cy+3], fill=ACCENT_CYAN)
    return img

NPCS = {
    "frost_engineer.png": make_frost_engineer,
    "ice_hermit.png": make_ice_hermit,
    "scavenger_leader.png": make_scavenger_leader,
    "frost_drone.png": make_frost_drone,
}

# === Title background (lighter ice version) ===
def make_ch2_title_bg() -> Image.Image:
    W, H = 1280, 720
    img = Image.new("RGBA", (W, H), ICE_DARK)
    d = ImageDraw.Draw(img)
    # Vertical gradient (lighter near horizon)
    for y in range(H):
        t = y / H
        r = int(20 + t * 60)
        g = int(40 + t * 90)
        b = int(70 + t * 130)
        d.line([(0, y), (W, y)], fill=(r, g, b, 255))
    # Stars
    random.seed(7331)
    for _ in range(200):
        x = random.randint(0, W-1)
        y = random.randint(0, H-3)
        roll = random.random()
        if roll < 0.75:
            d.point((x, y), fill=(180, 200, 220, 200))
        elif roll < 0.95:
            d.point((x, y), fill=ICE_BRIGHT)
        else:
            d.point((x, y), fill=ICE_BRIGHT)
            d.point((x-1, y), fill=(200, 220, 240, 180))
            d.point((x+1, y), fill=(200, 220, 240, 180))
    # Distant planet (icy)
    cx, cy, r = 1100, 130, 100
    d.ellipse([cx-r, cy-r, cx+r, cy+r], fill=(20, 30, 50, 255))
    for angle in range(180, 360, 5):
        rad = math.radians(angle)
        x = cx + int(r * math.cos(rad))
        y = cy + int(r * math.sin(rad))
        d.ellipse([x-3, y-3, x+3, y+3], fill=ICE_LIGHT)
    # Derelict satellite silhouette
    dx, dy = 350, 380
    d.rectangle([dx, dy, dx + 450, dy + 32], fill=(5, 5, 12, 255))
    d.rectangle([dx-30, dy+8, dx, dy+24], fill=(5, 5, 12, 255))
    d.rectangle([dx+450, dy+8, dx+480, dy+24], fill=(5, 5, 12, 255))
    d.line([(dx+80, dy), (dx+80, dy-22)], fill=(5, 5, 12, 255), width=2)
    d.line([(dx+220, dy), (dx+220, dy-30)], fill=(5, 5, 12, 255), width=2)
    d.line([(dx+360, dy), (dx+360, dy-18)], fill=(5, 5, 12, 255), width=2)
    # Lit windows (cyan)
    for wx in [dx+60, dx+120, dx+200, dx+280, dx+360, dx+420]:
        d.rectangle([wx, dy+10, wx+5, dy+15], fill=(150, 220, 255, 255))
    # Vignette
    vig = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    vd = ImageDraw.Draw(vig)
    for i in range(50):
        alpha = i * 5
        vd.line([(0, i), (W, i)], fill=(0, 0, 0, alpha))
        vd.line([(0, H-1-i), (W, H-1-i)], fill=(0, 0, 0, alpha))
        vd.line([(i, 0), (i, H)], fill=(0, 0, 0, alpha))
        vd.line([(W-1-i, 0), (W-1-i, H)], fill=(0, 0, 0, alpha))
    return Image.alpha_composite(img, vig.filter(ImageFilter.GaussianBlur(radius=20)))

# === Music (frozen_reactor.wav — slow, cold, 30s loop) ===
def make_frozen_reactor_wav() -> bytes:
    """Slow ambient ice music: low drones + sparse high crystalline tones."""
    SR = 22050
    duration = 30.0
    n = int(SR * duration)
    # Cold base drone (B1 = ~61.7 Hz)
    base = 61.7
    # Major 3rd + 5th
    intervals = [1.0, 1.19, 1.50, 2.0, 2.37, 3.0]
    samples = []
    # Slow random "frost crystal" ping trigger
    random.seed(4242)
    ping_times = [random.uniform(2, 5), random.uniform(7, 11), random.uniform(14, 18), random.uniform(20, 24), random.uniform(26, 29)]
    for i in range(n):
        t = i / SR
        # Slow LFO
        lfo = 0.7 + 0.3 * math.sin(2 * math.pi * 0.07 * t)
        s = 0.0
        for j, ratio in enumerate(intervals[:4]):
            f = base * ratio
            s += 0.08 * math.sin(2 * math.pi * f * t) * (1.0 - j * 0.15)
        # Add a slow LFO-modulated filter sweep
        sweep = math.sin(2 * math.pi * 0.13 * t)
        s = s * (0.6 + 0.4 * (sweep + 1) / 2)
        # Crystal pings (high frequency, short envelope)
        for pt in ping_times:
            dt = t - pt
            if 0 <= dt < 1.5:
                env = math.exp(-dt * 4.0)
                s += 0.18 * env * math.sin(2 * math.pi * 1760 * dt) * math.sin(2 * math.pi * 1320 * dt)
        s *= lfo * 0.4
        samples.append(int(max(-1, min(1, s)) * 32767))
    # WAV header
    data_size = len(samples) * 2
    header = b'RIFF' + struct.pack('<I', 36 + data_size) + b'WAVE'
    header += b'fmt ' + struct.pack('<IHHIIHH', 16, 1, 1, SR, SR * 2, 2, 16)
    header += b'data' + struct.pack('<I', data_size)
    return header + b''.join(struct.pack('<h', s) for s in samples)

def main():
    os.makedirs(ENEMY_DIR, exist_ok=True)
    os.makedirs(NPC_DIR, exist_ok=True)
    os.makedirs(TITLE_DIR, exist_ok=True)
    os.makedirs(MUSIC_DIR, exist_ok=True)

    print("=== Enemies (6 + 1 boss) ===")
    for name, fn in ENEMIES.items():
        img = fn()
        path = os.path.join(ENEMY_DIR, name)
        img.save(path)
        print(f"  wrote {path}")

    print("=== NPCs (4) ===")
    for name, fn in NPCS.items():
        img = fn()
        path = os.path.join(NPC_DIR, name)
        img.save(path)
        print(f"  wrote {path}")

    print("=== Title bg ===")
    bg = make_ch2_title_bg()
    bg_path = os.path.join(TITLE_DIR, "title_ch2.png")
    bg.save(bg_path)
    print(f"  wrote {bg_path}")

    print("=== Music (frozen_reactor.wav) ===")
    wav_bytes = make_frozen_reactor_wav()
    music_path = os.path.join(MUSIC_DIR, "frozen_reactor.wav")
    with open(music_path, "wb") as f:
        f.write(wav_bytes)
    print(f"  wrote {music_path} ({len(wav_bytes)} bytes)")

    print("\nAll Ch2 assets generated.")

if __name__ == "__main__":
    main()
