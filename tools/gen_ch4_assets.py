#!/usr/bin/env python3
"""
gen_ch4_assets.py — Generate all Ch4 (Sat-4 断魂号 / Military) art assets (Sprint 9).

Outputs:
  assets/tilesets/ch4/{floor_military,floor_military_damaged,wall_military,wall_military_damaged}.png (4 tiles, 32x32)
  assets/sprites/enemies/ch4_{ai_remnant,renegade_sentinel,rogue_drone,battle_mech,wreck_bot,self_destruct}.png (6 enemies, 32x32)
  assets/sprites/enemies/boss_pluto_remnant.png (1 boss, 64x64)
  assets/sprites/npcs/ch4_{veteran,ai_repair,pluto_fragment,war_orphan}.png (4 NPCs, 64x64)
  assets/sprites/title/title_ch4.png (1 title bg, 1280x720)
  assets/audio/music/wreckage_echo.wav (1 BGM, 30s loop)

Palette: dark grey (military) + warning red (danger) + blast marks + scorched metal.
"""
import os
import struct
import math
import wave
import random
from PIL import Image, ImageDraw, ImageFilter

# === Military palette ===
MIL_DARK = (40, 45, 50, 255)        # dark grey wall base
MIL_MID = (75, 80, 85, 255)         # mid grey
MIL_LIGHT = (130, 135, 140, 255)    # light grey
WARN_RED = (200, 50, 40, 255)       # warning red
DARK_RED = (130, 30, 25, 255)       # dark warning red
METAL_HIGHLIGHT = (200, 205, 210, 255)  # metallic highlight
EXPLOSION_YELLOW = (240, 180, 60, 255)  # explosion glow
SMOKE_GREY = (90, 95, 100, 255)     # smoke
INSIGNIA_WHITE = (220, 220, 220, 255)   # military insignia
DARK_VOID = (10, 10, 15, 255)       # near-black
RUST_ORANGE = (180, 100, 50, 255)   # rust

OUT_DIR_TILES = "assets/tilesets/ch4"
OUT_DIR_ENEMIES = "assets/sprites/enemies"
OUT_DIR_BOSSES = "assets/sprites/enemies"
OUT_DIR_NPCS = "assets/sprites/npcs"
OUT_DIR_TITLE = "assets/sprites/title"
OUT_DIR_MUSIC = "assets/audio/music"

# === Tile generation ===

def make_military_tile(variant: str = "floor", size: int = 32) -> Image.Image:
	img = Image.new("RGBA", (size, size), MIL_DARK)
	draw = ImageDraw.Draw(img)
	if variant == "floor":
		# Metal panel grid
		for x in range(0, size, 8):
			draw.line([(x, 0), (x, size)], fill=MIL_MID, width=1)
		for y in range(0, size, 8):
			draw.line([(0, y), (size, y)], fill=MIL_MID, width=1)
		# Random bolt
		for _ in range(2):
			x = random.randint(2, size - 3)
			y = random.randint(2, size - 3)
			draw.ellipse([(x - 1, y - 1), (x + 1, y + 1)], fill=INSIGNIA_WHITE)
	elif variant == "floor_damaged":
		# Heavy blast damage + scorch
		for _ in range(5):
			x1 = random.randint(0, size - 1)
			y1 = random.randint(0, size - 1)
			draw.ellipse([(x1 - 2, y1 - 2), (x1 + 2, y1 + 2)], fill=DARK_VOID)
		for _ in range(3):
			x = random.randint(2, size - 3)
			y = random.randint(2, size - 3)
			draw.ellipse([(x - 3, y - 3), (x + 3, y + 3)], fill=WARN_RED)
	elif variant == "wall":
		# Reinforced wall (vertical + horizontal beams)
		for x in [0, size // 2, size - 2]:
			draw.rectangle([(x, 0), (x + 1, size)], fill=MIL_MID)
		for y in [0, size - 4]:
			draw.rectangle([(0, y), (size, y + 1)], fill=MIL_LIGHT)
		# Warning stripe (diagonal)
		for i in range(0, size, 4):
			draw.line([(i, size - 8), (i + 4, size - 4)], fill=WARN_RED, width=1)
	elif variant == "wall_damaged":
		# Wall with craters + exposed interior
		for _ in range(4):
			x1 = random.randint(0, size - 1)
			y1 = random.randint(0, size - 1)
			x2 = x1 + random.randint(-6, 6)
			y2 = y1 + random.randint(-6, 6)
			draw.line([(x1, y1), (x2, y2)], fill=DARK_VOID, width=2)
		for _ in range(2):
			x = random.randint(4, size - 4)
			y = random.randint(4, size - 4)
			draw.ellipse([(x - 2, y - 2), (x + 2, y + 2)], fill=EXPLOSION_YELLOW)
	img = img.filter(ImageFilter.GaussianBlur(radius=0.5))
	return img

def generate_tiles() -> None:
	os.makedirs(OUT_DIR_TILES, exist_ok=True)
	for variant in ["floor", "floor_damaged", "wall", "wall_damaged"]:
		img = make_military_tile(variant)
		img.save(f"{OUT_DIR_TILES}/{variant}_military.png")
		print(f"  tile: {variant}_military.png")

# === Enemy sprites (32x32) ===

def make_enemy_sprite(name: str, color_main, color_accent, size: int = 32) -> Image.Image:
	img = Image.new("RGBA", (size, size), DARK_VOID)
	draw = ImageDraw.Draw(img)
	cx, cy = size // 2, size // 2
	if name == "ai_remnant":
		# Angular mech with red glow
		draw.polygon([(cx - 8, 8), (cx + 8, 8), (cx + 10, 24), (cx - 10, 24)], fill=color_main)
		draw.rectangle([(cx - 3, 14), (cx + 3, 18)], fill=color_accent)
	elif name == "renegade_sentinel":
		# Tall sentry tower
		draw.rectangle([(cx - 4, 6), (cx + 4, size - 4)], fill=color_main)
		draw.ellipse([(cx - 3, 8), (cx + 3, 12)], fill=color_accent)
	elif name == "rogue_drone":
		# Quad-copter drone
		for off in [(6, 6), (size - 6, 6), (6, size - 6), (size - 6, size - 6)]:
			draw.ellipse([(off[0] - 3, off[1] - 3), (off[0] + 3, off[1] + 3)], fill=color_main)
		draw.rectangle([(cx - 4, cy - 4), (cx + 4, cy + 4)], fill=color_accent)
	elif name == "battle_mech":
		# Bulky human-survivor mech
		draw.rectangle([(cx - 8, 8), (cx + 8, size - 4)], fill=color_main)
		draw.ellipse([(cx - 4, 10), (cx + 4, 16)], fill=color_accent)
	elif name == "wreck_bot":
		# Broken bot
		draw.rectangle([(4, 12), (size - 4, size - 4)], fill=color_main)
		draw.ellipse([(cx - 3, 14), (cx + 3, 18)], fill=color_accent)
		# Broken part
		draw.line([(8, 8), (size - 8, 8)], fill=color_main, width=2)
	elif name == "self_destruct":
		# Bomb-shape
		draw.ellipse([(cx - 7, 8), (cx + 7, size - 4)], fill=color_main)
		draw.line([(cx, 4), (cx, 8)], fill=color_accent, width=2)  # fuse
	return img

def generate_enemy_sprites() -> None:
	os.makedirs(OUT_DIR_ENEMIES, exist_ok=True)
	enemies = [
		("ai_remnant", MIL_LIGHT, WARN_RED),
		("renegade_sentinel", MIL_MID, DARK_RED),
		("rogue_drone", MIL_LIGHT, EXPLOSION_YELLOW),
		("battle_mech", MIL_MID, RUST_ORANGE),
		("wreck_bot", MIL_DARK, SMOKE_GREY),
		("self_destruct", WARN_RED, EXPLOSION_YELLOW),
	]
	for name, main, accent in enemies:
		img = make_enemy_sprite(name, main, accent)
		img.save(f"{OUT_DIR_ENEMIES}/ch4_{name}.png")
		print(f"  enemy: ch4_{name}.png")

# === Boss sprite (64x64) ===

def make_boss_sprite(size: int = 64) -> Image.Image:
	img = Image.new("RGBA", (size, size), DARK_VOID)
	draw = ImageDraw.Draw(img)
	cx, cy = size // 2, size // 2
	# Fragmented large mech
	draw.polygon([(cx - 22, cy - 10), (cx + 22, cy - 10), (cx + 18, cy + 18), (cx - 18, cy + 18)],
		fill=MIL_LIGHT)
	# Fragmented pieces around it
	for _ in range(8):
		x = cx + random.randint(-25, 25)
		y = cy + random.randint(-25, 25)
		size_frag = random.randint(3, 6)
		draw.rectangle([(x, y), (x + size_frag, y + size_frag)], fill=MIL_MID)
	# Central red eye
	draw.ellipse([(cx - 6, cy - 6), (cx + 6, cy + 6)], fill=WARN_RED)
	draw.ellipse([(cx - 3, cy - 3), (cx + 3, cy + 3)], fill=EXPLOSION_YELLOW)
	# Sparks
	for _ in range(5):
		x = cx + random.randint(-25, 25)
		y = cy + random.randint(-25, 25)
		draw.ellipse([(x - 1, y - 1), (x + 1, y + 1)], fill=EXPLOSION_YELLOW)
	return img

def generate_boss_sprite() -> None:
	os.makedirs(OUT_DIR_BOSSES, exist_ok=True)
	img = make_boss_sprite()
	img.save(f"{OUT_DIR_BOSSES}/boss_pluto_remnant.png")
	print(f"  boss: boss_pluto_remnant.png")

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
	if accessory == "uniform":
		# Military uniform collar
		draw.polygon([(cx - 8, 30), (cx + 8, 30), (cx + 12, 38), (cx - 12, 38)], fill=color_accent)
	elif accessory == "toolbelt":
		# Tech belt
		draw.rectangle([(cx - 10, 40), (cx + 10, 44)], fill=color_accent)
	elif accessory == "glow":
		# Red glow (Pluto fragment)
		draw.ellipse([(cx - 8, 14), (cx + 8, 22)], fill=color_accent)
	elif accessory == "child":
		# Smaller head, no body (child)
		draw.rectangle([(cx - 8, 36), (cx + 8, 56)], fill=color_accent)
	return img

def generate_npc_portraits() -> None:
	os.makedirs(OUT_DIR_NPCS, exist_ok=True)
	npcs = [
		("veteran", (120, 110, 100, 255), MIL_DARK, "uniform"),
		("ai_repair", (130, 130, 130, 255), METAL_HIGHLIGHT, "toolbelt"),
		("pluto_fragment", (180, 100, 90, 255), WARN_RED, "glow"),
		("war_orphan", (200, 180, 160, 255), MIL_MID, "child"),
	]
	for name, main, accent, accessory in npcs:
		img = make_npc_portrait(name, main, accent, accessory)
		img.save(f"{OUT_DIR_NPCS}/ch4_{name}.png")
		print(f"  npc: ch4_{name}.png")

# === Title background (1280x720) ===

def make_title_bg(size=(1280, 720)) -> Image.Image:
	img = Image.new("RGBA", size, DARK_VOID)
	draw = ImageDraw.Draw(img)
	# Grey vertical gradient
	for y in range(0, size[1], 8):
		t = y / size[1]
		r = int(MIL_DARK[0] + (MIL_MID[0] - MIL_DARK[0]) * t * 0.3)
		g = int(MIL_DARK[1] + (MIL_MID[1] - MIL_DARK[1]) * t * 0.3)
		b = int(MIL_DARK[2] + (MIL_MID[2] - MIL_DARK[2]) * t * 0.3)
		draw.rectangle([(0, y), (size[0], y + 8)], fill=(r, g, b, 255))
	# Blast marks (scattered)
	for _ in range(30):
		x = random.randint(0, size[0])
		y = random.randint(0, size[1])
		r = random.randint(5, 25)
		draw.ellipse([(x - r, y - r), (x + r, y + r)], outline=SMOKE_GREY, width=2)
	# Warning stripes
	for _ in range(15):
		x = random.randint(0, size[0])
		y = random.randint(0, size[1])
		draw.line([(x, y), (x + 30, y)], fill=WARN_RED, width=2)
	# Military insignia (5-pointed star, faded)
	for _ in range(3):
		x = random.randint(100, size[0] - 100)
		y = random.randint(100, size[1] - 100)
		points = []
		for i in range(10):
			angle = math.radians(-90 + i * 36)
			r = 20 if i % 2 == 0 else 10
			points.append((x + math.cos(angle) * r, y + math.sin(angle) * r))
		draw.polygon(points, outline=INSIGNIA_WHITE, width=2)
	img = img.filter(ImageFilter.GaussianBlur(radius=1.0))
	return img

def generate_title_bg() -> None:
	os.makedirs(OUT_DIR_TITLE, exist_ok=True)
	img = make_title_bg()
	img.save(f"{OUT_DIR_TITLE}/title_ch4.png")
	print(f"  title: title_ch4.png")

# === BGM (30s loop) — military march with distortion ===

def make_wreckage_echo_bgm(duration_sec: float = 30.0, sample_rate: int = 22050) -> None:
	os.makedirs(OUT_DIR_MUSIC, exist_ok=True)
	n_samples = int(duration_sec * sample_rate)
	path = f"{OUT_DIR_MUSIC}/wreckage_echo.wav"
	with wave.open(path, "w") as w:
		w.setnchannels(1)
		w.setsampwidth(2)
		w.setframerate(sample_rate)
		for i in range(n_samples):
			t = i / sample_rate
			# Military march bass drum (kick on every beat)
			beat_t = t % 0.5  # 120 BPM
			beat_envelope = max(0, 1.0 - beat_t * 6)  # fast decay
			beat = math.sin(2 * math.pi * 60 * t) * beat_envelope * 0.4
			# Brass-like mid range (square-ish via harmonics)
			brass = 0
			for harmonic in range(1, 5):
				brass += math.sin(2 * math.pi * 110 * harmonic * t) * 0.08 / harmonic
			# Distortion (clipping) on brass
			brass = math.tanh(brass * 3) * 0.15
			# Hollow resonance
			resonance = math.sin(2 * math.pi * 220 * t) * 0.1
			# Distant gunfire (sparse, high-frequency burst)
			gunfire = 0
			if random.random() < 0.0008:
				gunfire_freq = 800 + random.random() * 400
				gunfire = math.sin(2 * math.pi * gunfire_freq * t) * 0.3
			sample = beat + brass + resonance + gunfire
			sample = max(-1.0, min(1.0, sample))
			pcm = int(sample * 32767)
			w.writeframes(struct.pack("<h", pcm))
	print(f"  bgm: wreckage_echo.wav ({duration_sec}s)")

if __name__ == "__main__":
	random.seed(20260616)
	print("Generating Sat-4 (断魂号) assets...")
	generate_tiles()
	generate_enemy_sprites()
	generate_boss_sprite()
	generate_npc_portraits()
	generate_title_bg()
	make_wreckage_echo_bgm()
	print("Done.")