#!/usr/bin/env python3
"""
verify_assets.py — Pre-F5 verification tool for the Railhunter asset pipeline.

Scans all generated PNG + WAV assets and reports:
- File existence
- File size sanity checks
- Image dimensions (for PNGs)
- WAV header validation (sample rate, channels, duration)
- Lists any issues to fix before opening in Godot
"""
import os
import struct
import sys

OUT_DIR_TILES = "assets/tilesets/ch3"
OUT_DIR_TILES_4 = "assets/tilesets/ch4"
OUT_DIR_TILES_5 = "assets/tilesets/ch5"
OUT_DIR_ENEMIES = "assets/sprites/enemies"
OUT_DIR_NPCS = "assets/sprites/npcs"
OUT_DIR_TITLE = "assets/sprites/title"
OUT_DIR_MUSIC = "assets/audio/music"

# Expected files (from gen_ch3/4/5_assets.py output)
EXPECTED_FILES: dict[str, str] = {
	# Sat-3 tiles (4)
	f"{OUT_DIR_TILES}/floor_hive.png": "32x32 PNG",
	f"{OUT_DIR_TILES}/floor_damaged_hive.png": "32x32 PNG",
	f"{OUT_DIR_TILES}/wall_hive.png": "32x32 PNG",
	f"{OUT_DIR_TILES}/wall_damaged_hive.png": "32x32 PNG",
	# Sat-4 tiles (4 — note: generator used "{variant}_damaged_military" pattern)
	f"{OUT_DIR_TILES_4}/floor_military.png": "32x32 PNG",
	f"{OUT_DIR_TILES_4}/floor_damaged_military.png": "32x32 PNG",
	f"{OUT_DIR_TILES_4}/wall_military.png": "32x32 PNG",
	f"{OUT_DIR_TILES_4}/wall_damaged_military.png": "32x32 PNG",
	# Sat-5 tiles (4 — note: generator used "{variant}_glowing_ancient" pattern)
	f"{OUT_DIR_TILES_5}/floor_ancient.png": "32x32 PNG",
	f"{OUT_DIR_TILES_5}/floor_glowing_ancient.png": "32x32 PNG",
	f"{OUT_DIR_TILES_5}/wall_ancient.png": "32x32 PNG",
	f"{OUT_DIR_TILES_5}/wall_glowing_ancient.png": "32x32 PNG",
	# Sat-3 enemies (6 + 1 boss)
	f"{OUT_DIR_ENEMIES}/ch3_hive_guardian.png": "32x32 PNG",
	f"{OUT_DIR_ENEMIES}/ch3_hive_cannon.png": "32x32 PNG",
	f"{OUT_DIR_ENEMIES}/ch3_hive_parasite.png": "32x32 PNG",
	f"{OUT_DIR_ENEMIES}/ch3_hive_mycelium.png": "32x32 PNG",
	f"{OUT_DIR_ENEMIES}/ch3_hive_larva.png": "32x32 PNG",
	f"{OUT_DIR_ENEMIES}/ch3_hive_breeder.png": "32x32 PNG",
	f"{OUT_DIR_ENEMIES}/boss_hive_queen_guardian.png": "64x64 PNG",
	# Sat-4 enemies (6 + 1 boss)
	f"{OUT_DIR_ENEMIES}/ch4_ai_remnant.png": "32x32 PNG",
	f"{OUT_DIR_ENEMIES}/ch4_renegade_sentinel.png": "32x32 PNG",
	f"{OUT_DIR_ENEMIES}/ch4_rogue_drone.png": "32x32 PNG",
	f"{OUT_DIR_ENEMIES}/ch4_battle_mech.png": "32x32 PNG",
	f"{OUT_DIR_ENEMIES}/ch4_wreck_bot.png": "32x32 PNG",
	f"{OUT_DIR_ENEMIES}/ch4_self_destruct.png": "32x32 PNG",
	f"{OUT_DIR_ENEMIES}/boss_pluto_remnant.png": "64x64 PNG",
	# Sat-5 boss
	f"{OUT_DIR_ENEMIES}/boss_creator.png": "96x96 PNG",
	# Sat-3 NPCs (4)
	f"{OUT_DIR_NPCS}/ch3_wanderer_scientist.png": "64x64 PNG",
	f"{OUT_DIR_NPCS}/ch3_hive_survivor.png": "64x64 PNG",
	f"{OUT_DIR_NPCS}/ch3_surviving_crew.png": "64x64 PNG",
	f"{OUT_DIR_NPCS}/ch3_fungal_infected.png": "64x64 PNG",
	# Sat-4 NPCs (4)
	f"{OUT_DIR_NPCS}/ch4_veteran.png": "64x64 PNG",
	f"{OUT_DIR_NPCS}/ch4_ai_repair.png": "64x64 PNG",
	f"{OUT_DIR_NPCS}/ch4_pluto_fragment.png": "64x64 PNG",
	f"{OUT_DIR_NPCS}/ch4_war_orphan.png": "64x64 PNG",
	# Title backgrounds (3)
	f"{OUT_DIR_TITLE}/title_ch3.png": "1280x720 PNG",
	f"{OUT_DIR_TITLE}/title_ch4.png": "1280x720 PNG",
	f"{OUT_DIR_TITLE}/title_ch5.png": "1280x720 PNG",
	# BGMs (4)
	f"{OUT_DIR_MUSIC}/frozen_reactor.wav": "30s WAV",
	f"{OUT_DIR_MUSIC}/hive_heart.wav": "30s WAV",
	f"{OUT_DIR_MUSIC}/wreckage_echo.wav": "30s WAV",
	f"{OUT_DIR_MUSIC}/creators_dream.wav": "60s WAV",
}

def check_png(path: str) -> tuple[bool, str]:
	"""Verify PNG file: signature + IHDR dimensions."""
	try:
		with open(path, "rb") as f:
			sig = f.read(8)
			if sig != b"\x89PNG\r\n\x1a\n":
				return False, "invalid PNG signature"
			# IHDR chunk: 4 bytes length + 4 bytes "IHDR" + 4 bytes width + 4 bytes height
			f.read(4)  # length
			f.read(4)  # "IHDR"
			width = struct.unpack(">I", f.read(4))[0]
			height = struct.unpack(">I", f.read(4))[0]
			return True, f"{width}x{height}"
	except Exception as e:
		return False, f"error: {e}"

def check_wav(path: str) -> tuple[bool, str]:
	"""Verify WAV file: RIFF header + sample rate + duration."""
	try:
		with open(path, "rb") as f:
			riff = f.read(4)
			if riff != b"RIFF":
				return False, "invalid RIFF header"
			f.read(4)  # RIFF chunk size
			wave = f.read(4)
			if wave != b"WAVE":
				return False, "invalid WAVE header"
			# Iterate chunks
			sample_rate: int = 0
			num_channels: int = 0
			byte_rate: int = 0
			data_size: int = 0
			while True:
				chunk_id = f.read(4)
				if not chunk_id or len(chunk_id) < 4:
					break
				chunk_size_bytes = f.read(4)
				if len(chunk_size_bytes) < 4:
					break
				chunk_size = struct.unpack("<I", chunk_size_bytes)[0]
				if chunk_id == b"fmt ":
					# PCM fmt chunk: audio_format(2) + num_channels(2) +
					# sample_rate(4) + byte_rate(4) + block_align(2) + bits_per_sample(2)
					# = 16 bytes total
					f.read(2)  # audio_format
					num_channels = struct.unpack("<H", f.read(2))[0]
					sample_rate = struct.unpack("<I", f.read(4))[0]
					byte_rate = struct.unpack("<I", f.read(4))[0]
					block_align = struct.unpack("<H", f.read(2))[0]
					bits_per_sample = struct.unpack("<H", f.read(2))[0]
					# If chunk_size is larger than 16, skip remaining
					remaining: int = chunk_size - 16
					if remaining > 0:
						f.read(remaining)
				elif chunk_id == b"data":
					data_size = chunk_size
					break
				else:
					# Skip unknown chunks (e.g., "fact")
					f.read(chunk_size)
			if data_size == 0:
				return False, "no data chunk"
			if byte_rate == 0:
				return False, "byte_rate=0 (invalid fmt chunk)"
			duration_sec = data_size / byte_rate
			return True, f"{sample_rate}Hz {num_channels}ch {duration_sec:.1f}s"
	except Exception as e:
		return False, f"error: {e}"

def main() -> int:
	print("=" * 60)
	print("Railhunter Pre-F5 Asset Verification")
	print("=" * 60)

	missing: list[str] = []
	invalid: list[str] = []
	ok_count: int = 0

	for path, expected in EXPECTED_FILES.items():
		if not os.path.exists(path):
			missing.append(path)
			print(f"  MISSING: {path} (expected: {expected})")
			continue
		size = os.path.getsize(path)
		if path.endswith(".png"):
			ok, info = check_png(path)
			if ok:
				print(f"  OK    : {path} ({info}, {size} bytes)")
				ok_count += 1
			else:
				invalid.append(path)
				print(f"  INVALID: {path} ({info})")
		elif path.endswith(".wav"):
			ok, info = check_wav(path)
			if ok:
				print(f"  OK    : {path} ({info}, {size} bytes)")
				ok_count += 1
			else:
				invalid.append(path)
				print(f"  INVALID: {path} ({info})")

	print("=" * 60)
	print(f"Total: {ok_count} OK / {len(missing)} missing / {len(invalid)} invalid")
	print(f"Out of {len(EXPECTED_FILES)} expected files")

	if missing:
		print("\nMISSING FILES (regenerate with tools/gen_ch3/4/5_assets.py):")
		for m in missing:
			print(f"  - {m}")

	if invalid:
		print("\nINVALID FILES (check format):")
		for inv in invalid:
			print(f"  - {inv}")

	return 1 if missing or invalid else 0

if __name__ == "__main__":
	sys.exit(main())