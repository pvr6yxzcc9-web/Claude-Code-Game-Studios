#!/usr/bin/env python3
"""
gen_ch3_assets.py — Generate all Ch3 (Sat-3 蜂巢号 / Hive) art assets (Sprint 8).

Outputs:
  assets/tilesets/ch3/{floor_hive,floor_hive_damaged,wall_hive,wall_hive_damaged}.png (4 tiles, 32x32)
  assets/sprites/enemies/{frostling,glacier,shard_bot,ice_drone,frost_walker,crystal_sentinel}.png → ch3 variants
  assets/sprites/enemies/boss_hive_queen_guardian.png (1 boss, 64x64)
  assets/sprites/npcs/{wanderer_scientist,hive_survivor,surviving_crew,fungal_infected}.png (4 NPCs, 64x64)
  assets/sprites/title/title_ch3.png (1 title bg, 1280x720)
  assets/audio/music/hive_heart.wav (1 BGM, 30s loop)

Palette: deep purple (hive walls) + viscous yellow (hive fluids) + organic shapes.
Follows the same Python synth pattern as gen_ch2_assets.py — uses PIL + wave stdlib.
"""
import os
import struct
import math
import wave
import random
from PIL import Image, ImageDraw, ImageFilter

# === Hive palette ===
HIVE_DARK = (35, 15, 55, 255)         # deep purple wall base
HIVE_MID = (75, 35, 110, 255)          # mid purple
HIVE_LIGHT = (130, 80, 165, 255)       # light purple
HIVE_PULSE = (200, 160, 220, 255)      # pale purple pulse
FLUID_YELLOW = (220, 200, 80, 255)     # viscous yellow fluid
FLUID_AMBER = (180, 140, 50, 255)      # darker amber
ORGANIC_RED = (140, 50, 60, 255)       # organic red (warning)
EGG_WHITE = (230, 220, 200, 255)       # egg/larva white
DARK_VOID = (10, 5, 20, 255)           # near-black background
SPORE_GREEN = (110, 160, 90, 255)      # fungal green

OUT_DIR_TILES = "assets/tilesets/ch3"
OUT_DIR_ENEMIES = "assets/sprites/enemies"
OUT_DIR_BOSSES = "assets/sprites/enemies"
OUT_DIR_NPCS = "assets/sprites/npcs"
OUT_DIR_TITLE = "assets/sprites/title"
OUT_DIR_MUSIC = "assets/audio/music"

# === Tile generation ===

def make_hive_tile(variant: str = "floor", size: int = 32) -> Image.Image:
	img = Image.new("RGBA", (size, size), HIVE_DARK)
	draw = ImageDraw.Draw(img)
	if variant == "floor":
		# Pulsing veins — small curving lines
		for _ in range(8):
			x1 = random.randint(0, size - 1)
			y1 = random.randint(0, size - 1)
			x2 = x1 + random.randint(-4, 4)
			y2 = y1 + random.randint(-4, 4)
			draw.line([(x1, y1), (x2, y2)], fill=HIVE_LIGHT, width=1)
		# Yellow fluid drips
		for _ in range(2):
			x = random.randint(2, size - 3)
			y = random.randint(2, size - 3)
			draw.ellipse([(x - 1, y - 1), (x + 1, y + 1)], fill=FLUID_YELLOW)
	elif variant == "floor_damaged":
		# Cracked floor — darker base + jagged lines
		for _ in range(5):
			x1 = random.randint(0, size - 1)
			y1 = random.randint(0, size - 1)
			x2 = x1 + random.randint(-8, 8)
			y2 = y1 + random.randint(-8, 8)
			draw.line([(x1, y1), (x2, y2)], fill=DARK_VOID, width=2)
		# Exposed yellow fluid
		for _ in range(3):
			x = random.randint(2, size - 3)
			y = random.randint(2, size - 3)
			draw.ellipse([(x - 2, y - 2), (x + 2, y + 2)], fill=FLUID_AMBER)
	elif variant == "wall":
		# Wall — vertical organic grooves
		for x in range(0, size, 6):
			draw.line([(x, 0), (x + random.randint(-2, 2), size)], fill=HIVE_MID, width=2)
		# Yellow veins
		for _ in range(3):
			y = random.randint(0, size - 1)
			x1 = random.randint(0, size // 2)
			x2 = x1 + random.randint(2, 8)
			draw.line([(x1, y), (x2, y)], fill=FLUID_YELLOW, width=1)
	elif variant == "wall_damaged":
		# Wall with cracks + exposed organic red
		draw = ImageDraw.Draw(img)
		for _ in range(6):
			x1 = random.randint(0, size - 1)
			y1 = random.randint(0, size - 1)
			x2 = x1 + random.randint(-6, 6)
			y2 = y1 + random.randint(-6, 6)
			draw.line([(x1, y1), (x2, y2)], fill=DARK_VOID, width=2)
		for _ in range(2):
			x = random.randint(4, size - 4)
			y = random.randint(4, size - 4)
			draw.ellipse([(x - 2, y - 2), (x + 2, y + 2)], fill=ORGANIC_RED)
	# Slight blur for organic feel
	img = img.filter(ImageFilter.GaussianBlur(radius=0.5))
	return img

def generate_tiles() -> None:
	os.makedirs(OUT_DIR_TILES, exist_ok=True)
	for variant in ["floor", "floor_damaged", "wall", "wall_damaged"]:
		img = make_hive_tile(variant)
		img.save(f"{OUT_DIR_TILES}/{variant}_hive.png")
		print(f"  tile: {variant}_hive.png")

# === Enemy sprites (32x32) ===

def make_enemy_sprite(name: str, color_main, color_accent, size: int = 32) -> Image.Image:
	img = Image.new("RGBA", (size, size), DARK_VOID)
	draw = ImageDraw.Draw(img)
	cx, cy = size // 2, size // 2
	if name == "hive_guardian":
		# Standing humanoid-shape: head + body
		draw.ellipse([(cx - 4, 4), (cx + 4, 12)], fill=color_main)  # head
		draw.rectangle([(cx - 5, 12), (cx + 5, 24)], fill=color_main)  # body
		draw.ellipse([(cx - 2, 24), (cx + 2, 30)], fill=color_accent)  # base
	elif name == "hive_cannon":
		# Round with center spike
		draw.ellipse([(4, 8), (size - 4, size - 8)], fill=color_main)
		draw.line([(cx, 4), (cx, 12)], fill=color_accent, width=2)  # spike up
		draw.ellipse([(cx - 3, cy - 3), (cx + 3, cy + 3)], fill=color_accent)
	elif name == "hive_parasite":
		# Worm-like horizontal
		for i in range(5):
			draw.ellipse([(2 + i * 6, cy - 4), (8 + i * 6, cy + 4)], fill=color_main)
		draw.ellipse([(size - 8, cy - 3), (size - 2, cy + 3)], fill=color_accent)  # head
	elif name == "hive_mycelium":
		# Fungal clump with spores
		draw.ellipse([(4, 8), (size - 4, size - 4)], fill=color_main)
		for _ in range(8):
			x = random.randint(6, size - 6)
			y = random.randint(6, size - 6)
			draw.ellipse([(x - 1, y - 1), (x + 1, y + 1)], fill=color_accent)
	elif name == "hive_larva":
		# Egg-shape (vertical oval)
		draw.ellipse([(cx - 6, 6), (cx + 6, size - 4)], fill=color_main)
		draw.ellipse([(cx - 4, 10), (cx + 4, 18)], fill=color_accent)
	elif name == "hive_breeder":
		# Bulk shape with smaller units attached
		draw.ellipse([(4, 8), (size - 4, size - 4)], fill=color_main)
		for off in [(6, 4), (size - 10, 4), (6, size - 10), (size - 10, size - 10)]:
			draw.ellipse([(off[0] - 2, off[1] - 2), (off[0] + 2, off[1] + 2)], fill=color_accent)
	return img

def generate_enemy_sprites() -> None:
	os.makedirs(OUT_DIR_ENEMIES, exist_ok=True)
	enemies = [
		("hive_guardian", HIVE_LIGHT, FLUID_YELLOW),
		("hive_cannon", HIVE_MID, ORGANIC_RED),
		("hive_parasite", HIVE_DARK, FLUID_AMBER),
		("hive_mycelium", HIVE_MID, SPORE_GREEN),
		("hive_larva", EGG_WHITE, FLUID_YELLOW),
		("hive_breeder", HIVE_MID, HIVE_PULSE),
	]
	for name, main, accent in enemies:
		img = make_enemy_sprite(name, main, accent)
		img.save(f"{OUT_DIR_ENEMIES}/ch3_{name}.png")
		print(f"  enemy: ch3_{name}.png")

# === Boss sprite (64x64) ===

def make_boss_sprite(size: int = 64) -> Image.Image:
	img = Image.new("RGBA", (size, size), DARK_VOID)
	draw = ImageDraw.Draw(img)
	cx, cy = size // 2, size // 2
	# Big central hive node
	draw.ellipse([(cx - 16, cy - 16), (cx + 16, cy + 16)], fill=HIVE_MID)
	# Inner glow
	draw.ellipse([(cx - 10, cy - 10), (cx + 10, cy + 10)], fill=HIVE_PULSE)
	# Central eye
	draw.ellipse([(cx - 4, cy - 4), (cx + 4, cy + 4)], fill=ORGANIC_RED)
	# Tendrils (4 of them, 90° apart)
	for angle in [0, 90, 180, 270]:
		r = math.radians(angle)
		for i in range(8):
			t = i / 8.0
			dist = 18 + i * 3
			x = cx + int(math.cos(r) * dist)
			y = cy + int(math.sin(r) * dist)
			draw.ellipse([(x - 2, y - 2), (x + 2, y + 2)], fill=FLUID_AMBER)
	# Outer ring
	draw.ellipse([(cx - 22, cy - 22), (cx + 22, cy + 22)], outline=FLUID_YELLOW, width=2)
	return img

def generate_boss_sprite() -> None:
	os.makedirs(OUT_DIR_BOSSES, exist_ok=True)
	img = make_boss_sprite()
	img.save(f"{OUT_DIR_BOSSES}/boss_hive_queen_guardian.png")
	print(f"  boss: boss_hive_queen_guardian.png")

# === NPC portraits (64x64) ===

def make_npc_portrait(name: str, color_main, color_accent, accessory: str, size: int = 64) -> Image.Image:
	img = Image.new("RGBA", (size, size), DARK_VOID)
	draw = ImageDraw.Draw(img)
	cx, cy = size // 2, size // 2
	# Head
	draw.ellipse([(cx - 12, 8), (cx + 12, 32)], fill=color_main)
	# Body
	draw.rectangle([(cx - 14, 30), (cx + 14, 56)], fill=color_main)
	# Eyes
	draw.ellipse([(cx - 6, 16), (cx - 2, 20)], fill=(255, 255, 255, 255))
	draw.ellipse([(cx + 2, 16), (cx + 6, 20)], fill=(255, 255, 255, 255))
	draw.ellipse([(cx - 5, 17), (cx - 3, 19)], fill=(0, 0, 0, 255))
	draw.ellipse([(cx + 3, 17), (cx + 5, 19)], fill=(0, 0, 0, 255))
	# Accessory
	if accessory == "glasses":
		draw.rectangle([(cx - 8, 14), (cx - 1, 22)], outline=(200, 200, 200, 255), width=1)
		draw.rectangle([(cx + 1, 14), (cx + 8, 22)], outline=(200, 200, 200, 255), width=1)
		draw.line([(cx - 1, 18), (cx + 1, 18)], fill=(200, 200, 200, 255), width=1)
	elif accessory == "hood":
		draw.polygon([(cx - 14, 12), (cx + 14, 12), (cx + 18, 32), (cx - 18, 32)],
			fill=color_accent)
	elif accessory == "scar":
		draw.line([(cx - 2, 20), (cx + 4, 28)], fill=ORGANIC_RED, width=2)
	elif accessory == "mask":
		draw.rectangle([(cx - 8, 18), (cx + 8, 24)], fill=color_accent)
	# Hive-influenced: faint pulse glow
	for r in range(0, 2):
		draw.ellipse([(cx - 16 - r * 2, cy - 16 - r * 2), (cx + 16 + r * 2, cy + 16 + r * 2)],
			outline=FLUID_YELLOW, width=1)
	return img

def generate_npc_portraits() -> None:
	os.makedirs(OUT_DIR_NPCS, exist_ok=True)
	npcs = [
		("wanderer_scientist", HIVE_LIGHT, (80, 100, 140, 255), "glasses"),
		("hive_survivor", HIVE_MID, (60, 50, 80, 255), "hood"),
		("surviving_crew", (140, 120, 100, 255), ORGANIC_RED, "scar"),
		("fungal_infected", (160, 140, 100, 255), SPORE_GREEN, "mask"),
	]
	for name, main, accent, accessory in npcs:
		img = make_npc_portrait(name, main, accent, accessory)
		img.save(f"{OUT_DIR_NPCS}/ch3_{name}.png")
		print(f"  npc: ch3_{name}.png")

# === Title background (1280x720) ===

def make_title_bg(size=(1280, 720)) -> Image.Image:
	img = Image.new("RGBA", size, DARK_VOID)
	draw = ImageDraw.Draw(img)
	# Deep purple gradient (vertical bands of color)
	for y in range(0, size[1], 8):
		t = y / size[1]
		r = int(HIVE_DARK[0] + (HIVE_MID[0] - HIVE_DARK[0]) * t * 0.3)
		g = int(HIVE_DARK[1] + (HIVE_MID[1] - HIVE_DARK[1]) * t * 0.3)
		b = int(HIVE_DARK[2] + (HIVE_MID[2] - HIVE_DARK[2]) * t * 0.3)
		draw.rectangle([(0, y), (size[0], y + 8)], fill=(r, g, b, 255))
	# Organic veins
	for _ in range(40):
		x1 = random.randint(0, size[0])
		y1 = random.randint(0, size[1])
		# Curving vein: 4-6 segments
		points = [(x1, y1)]
		for _ in range(random.randint(3, 5)):
			px = points[-1][0] + random.randint(-80, 80)
			py = points[-1][1] + random.randint(-40, 40)
			points.append((px, py))
		for i in range(len(points) - 1):
			draw.line([points[i], points[i + 1]], fill=HIVE_LIGHT, width=2)
	# Yellow fluid drips
	for _ in range(15):
		x = random.randint(0, size[0])
		y = random.randint(0, size[1])
		draw.ellipse([(x - 4, y - 4), (x + 4, y + 4)], fill=FLUID_YELLOW)
	# Hive nodes (circular pulse points)
	for _ in range(5):
		x = random.randint(100, size[0] - 100)
		y = random.randint(100, size[1] - 100)
		draw.ellipse([(x - 30, y - 30), (x + 30, y + 30)], outline=FLUID_AMBER, width=3)
		draw.ellipse([(x - 20, y - 20), (x + 20, y + 20)], outline=HIVE_PULSE, width=2)
		draw.ellipse([(x - 8, y - 8), (x + 8, y + 8)], fill=ORGANIC_RED)
	# Subtle blur for organic feel
	img = img.filter(ImageFilter.GaussianBlur(radius=1.0))
	return img

def generate_title_bg() -> None:
	os.makedirs(OUT_DIR_TITLE, exist_ok=True)
	img = make_title_bg()
	img.save(f"{OUT_DIR_TITLE}/title_ch3.png")
	print(f"  title: title_ch3.png")

# === BGM (30s loop) ===

def make_hive_heart_bgm(duration_sec: float = 30.0, sample_rate: int = 22050) -> None:
	os.makedirs(OUT_DIR_MUSIC, exist_ok=True)
	n_samples = int(duration_sec * sample_rate)
	# Hive Heart: low-frequency organic drone with pulsing higher tones
	# Base drone: ~55 Hz (deep)
	# Pulse: ~110 Hz every 4 seconds
	# High spore: ~330 Hz random
	files_path = f"{OUT_DIR_MUSIC}/hive_heart.wav"
	with wave.open(files_path, "w") as w:
		w.setnchannels(1)
		w.setsampwidth(2)
		w.setframerate(sample_rate)
		for i in range(n_samples):
			t = i / sample_rate
			# Base drone (55 Hz)
			base = math.sin(2 * math.pi * 55 * t) * 0.3
			# Subtle harmonics
			base += math.sin(2 * math.pi * 110 * t) * 0.15
			# Pulsing heartbeat (every 4 seconds, decaying)
			pulse_phase = (t % 4.0) / 4.0  # 0..1
			pulse_strength = max(0, 1.0 - pulse_phase * 5)  # strong at start, decays
			pulse = math.sin(2 * math.pi * 80 * t) * pulse_strength * 0.4
			# High spore sounds (random, sparse)
			spore = 0
			if random.random() < 0.001:  # ~20 spores per second on average
				spore_freq = 250 + random.random() * 200
				spore = math.sin(2 * math.pi * spore_freq * t) * 0.2
			# Mix and clip
			sample = base + pulse + spore
			sample = max(-1.0, min(1.0, sample))
			# Convert to 16-bit PCM
			pcm = int(sample * 32767)
			w.writeframes(struct.pack("<h", pcm))
	print(f"  bgm: hive_heart.wav ({duration_sec}s)")

# === Main ===

if __name__ == "__main__":
	random.seed(20260616)  # deterministic
	print("Generating Sat-3 (蜂巢号) assets...")
	generate_tiles()
	generate_enemy_sprites()
	generate_boss_sprite()
	generate_npc_portraits()
	generate_title_bg()
	make_hive_heart_bgm()
	print("Done.")