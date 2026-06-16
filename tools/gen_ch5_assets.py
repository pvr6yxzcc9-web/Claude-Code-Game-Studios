#!/usr/bin/env python3
"""
gen_ch5_assets.py — Generate all Ch5 (Sat-5 起源号 / Creator's Origin) art assets (Sprint 10).

Outputs:
  assets/tilesets/ch5/{floor_ancient,floor_ancient_glowing,wall_ancient,wall_ancient_glowing}.png (4 tiles)
  assets/sprites/enemies/boss_creator.png (96x96)
  assets/sprites/title/title_ch5.png (1280x720)
  assets/audio/music/creators_dream.wav (60s loop)

Palette: gold + deep purple + cosmic ambient + alien geometric patterns.
"""
import os
import struct
import math
import wave
import random
from PIL import Image, ImageDraw, ImageFilter

# === Cosmic palette ===
ANCIENT_GOLD = (200, 170, 90, 255)
ANCIENT_GOLD_BRIGHT = (240, 220, 140, 255)
ANCIENT_PURPLE_DEEP = (50, 30, 80, 255)
ANCIENT_PURPLE = (90, 60, 130, 255)
GLOW_WHITE = (240, 235, 220, 255)
COSMIC_BLACK = (15, 10, 30, 255)
STAR_YELLOW = (255, 240, 200, 255)
RUNE_BLUE = (80, 130, 220, 255)

OUT_DIR_TILES = "assets/tilesets/ch5"
OUT_DIR_BOSSES = "assets/sprites/enemies"
OUT_DIR_TITLE = "assets/sprites/title"
OUT_DIR_MUSIC = "assets/audio/music"

# === Tile generation ===

def make_ancient_tile(variant: str = "floor", size: int = 32) -> Image.Image:
	img = Image.new("RGBA", (size, size), ANCIENT_PURPLE_DEEP)
	draw = ImageDraw.Draw(img)
	if variant == "floor":
		# Geometric patterns (diamond shapes)
		for y in range(0, size, 8):
			for x in range(0, size, 8):
				draw.polygon([(x + 4, y), (x + 8, y + 4), (x + 4, y + 8), (x, y + 4)], outline=ANCIENT_GOLD, width=1)
	elif variant == "floor_glowing":
		# Glowing runes
		for y in range(0, size, 12):
			for x in range(0, size, 12):
				draw.ellipse([(x + 4, y + 4), (x + 8, y + 8)], fill=RUNE_BLUE)
				# Glow halo
				draw.ellipse([(x + 2, y + 2), (x + 10, y + 10)], outline=RUNE_BLUE, width=1)
	elif variant == "wall":
		# Tall gold-inlaid wall
		for x in range(0, size, 4):
			draw.line([(x, 0), (x, size)], fill=ANCIENT_GOLD, width=1)
		# Geometric ornament
		for y in range(0, size, 8):
			draw.line([(0, y), (size, y + 2)], fill=ANCIENT_GOLD_BRIGHT, width=1)
	elif variant == "wall_glowing":
		# Glowing wall runes
		for y in range(0, size, 8):
			for x in range(0, size, 4):
				draw.ellipse([(x, y + 2), (x + 2, y + 6)], fill=RUNE_BLUE)
	img = img.filter(ImageFilter.GaussianBlur(radius=0.5))
	return img

def generate_tiles() -> None:
	os.makedirs(OUT_DIR_TILES, exist_ok=True)
	for variant in ["floor", "floor_glowing", "wall", "wall_glowing"]:
		img = make_ancient_tile(variant)
		img.save(f"{OUT_DIR_TILES}/{variant}_ancient.png")
		print(f"  tile: {variant}_ancient.png")

# === Boss sprite (96x96) ===

def make_creator_boss(size: int = 96) -> Image.Image:
	img = Image.new("RGBA", (size, size), COSMIC_BLACK)
	draw = ImageDraw.Draw(img)
	cx, cy = size // 2, size // 2
	# Outer ring (gold)
	draw.ellipse([(cx - 44, cy - 44), (cx + 44, cy + 44)], outline=ANCIENT_GOLD, width=3)
	# Inner glow (purple)
	draw.ellipse([(cx - 36, cy - 36), (cx + 36, cy + 36)], fill=ANCIENT_PURPLE_DEEP)
	# Geometric pattern (radial lines)
	for angle in range(0, 360, 30):
		r = math.radians(angle)
		x1 = cx + int(math.cos(r) * 25)
		y1 = cy + int(math.sin(r) * 25)
		x2 = cx + int(math.cos(r) * 38)
		y2 = cy + int(math.sin(r) * 38)
		draw.line([(x1, y1), (x2, y2)], fill=ANCIENT_GOLD, width=1)
	# Central eye
	draw.ellipse([(cx - 16, cy - 16), (cx + 16, cy + 16)], fill=ANCIENT_PURPLE)
	draw.ellipse([(cx - 10, cy - 10), (cx + 10, cy + 10)], fill=ANCIENT_GOLD_BRIGHT)
	draw.ellipse([(cx - 4, cy - 4), (cx + 4, cy + 4)], fill=GLOW_WHITE)
	# Outer stars
	for _ in range(20):
		x = random.randint(0, size)
		y = random.randint(0, size)
		if (x - cx) ** 2 + (y - cy) ** 2 > 44 ** 2:  # outside ring
			draw.ellipse([(x - 1, y - 1), (x + 1, y + 1)], fill=STAR_YELLOW)
	return img

def generate_boss_sprite() -> None:
	os.makedirs(OUT_DIR_BOSSES, exist_ok=True)
	img = make_creator_boss()
	img.save(f"{OUT_DIR_BOSSES}/boss_creator.png")
	print(f"  boss: boss_creator.png")

# === Title background (1280x720) ===

def make_title_bg(size=(1280, 720)) -> Image.Image:
	img = Image.new("RGBA", size, COSMIC_BLACK)
	draw = ImageDraw.Draw(img)
	# Deep purple radial gradient
	for y in range(0, size[1], 8):
		t = y / size[1]
		r = int(ANCIENT_PURPLE_DEEP[0] + (COSMIC_BLACK[0] - ANCIENT_PURPLE_DEEP[0]) * t)
		g = int(ANCIENT_PURPLE_DEEP[1] + (COSMIC_BLACK[1] - ANCIENT_PURPLE_DEEP[1]) * t)
		b = int(ANCIENT_PURPLE_DEEP[2] + (COSMIC_BLACK[2] - ANCIENT_PURPLE_DEEP[2]) * t)
		draw.rectangle([(0, y), (size[0], y + 8)], fill=(r, g, b, 255))
	# Stars (random small dots)
	for _ in range(200):
		x = random.randint(0, size[0])
		y = random.randint(0, size[1])
		brightness = random.randint(150, 255)
		draw.ellipse([(x - 1, y - 1), (x + 1, y + 1)], fill=(brightness, brightness, brightness, 255))
	# Gold geometric lines (sparse)
	for _ in range(15):
		x1 = random.randint(0, size[0])
		y1 = random.randint(0, size[1])
		x2 = x1 + random.randint(-100, 100)
		y2 = y1 + random.randint(-100, 100)
		draw.line([(x1, y1), (x2, y2)], fill=ANCIENT_GOLD, width=1)
	# Central golden glow
	for r in [80, 60, 40]:
		draw.ellipse([(size[0] // 2 - r, size[1] // 2 - r), (size[0] // 2 + r, size[1] // 2 + r)],
			outline=ANCIENT_GOLD, width=1)
	img = img.filter(ImageFilter.GaussianBlur(radius=1.0))
	return img

def generate_title_bg() -> None:
	os.makedirs(OUT_DIR_TITLE, exist_ok=True)
	img = make_title_bg()
	img.save(f"{OUT_DIR_TITLE}/title_ch5.png")
	print(f"  title: title_ch5.png")

# === BGM (60s loop — cosmic ambient) ===

def make_creators_dream_bgm(duration_sec: float = 60.0, sample_rate: int = 22050) -> None:
	os.makedirs(OUT_DIR_MUSIC, exist_ok=True)
	n_samples = int(duration_sec * sample_rate)
	path = f"{OUT_DIR_MUSIC}/creators_dream.wav"
	with wave.open(path, "w") as w:
		w.setnchannels(1)
		w.setsampwidth(2)
		w.setframerate(sample_rate)
		for i in range(n_samples):
			t = i / sample_rate
			# Deep low drone (~40 Hz)
			drone = math.sin(2 * math.pi * 40 * t) * 0.3
			# Slow LFO modulation (~0.1 Hz) for breathing effect
			lfo = math.sin(2 * math.pi * 0.1 * t) * 0.1
			drone = drone * (1 + lfo)
			# Mid-range harmonic shimmer
			shimmer = math.sin(2 * math.pi * 200 * t) * 0.1 + math.sin(2 * math.pi * 400 * t) * 0.05
			# Sparse voice-like tones (chord arpeggios)
			voice = 0
			if random.random() < 0.005:
				voice_freq = 300 + random.random() * 400
				voice = math.sin(2 * math.pi * voice_freq * t) * 0.2
			sample = drone + shimmer + voice
			sample = max(-1.0, min(1.0, sample))
			pcm = int(sample * 32767)
			w.writeframes(struct.pack("<h", pcm))
	print(f"  bgm: creators_dream.wav ({duration_sec}s)")

if __name__ == "__main__":
	random.seed(20260616)
	print("Generating Sat-5 (起源号) assets...")
	generate_tiles()
	generate_boss_sprite()
	generate_title_bg()
	make_creators_dream_bgm()
	print("Done.")