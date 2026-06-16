# Tools — Pipeline, Asset Generation, Verification

This directory contains all build-time tooling for Railhunter. Pipeline tools
are invoked once per content drop or once per commit. Asset generators write
deterministic seeded outputs so regenerating produces identical bytes.

## Quick Start

```bash
# Pre-commit asset sanity check (fast, <1s)
python tools/verify_assets.py

# Full GUT regression (requires Godot in PATH)
godot --headless --script tests/runners/sprint7_plus_runner.gd
```

## Verification Tools

### `verify_assets.py` — pre-F5 asset sanity check

Scans 42 expected asset files (PNG + WAV) and validates:

- **PNG**: signature + IHDR dimensions match the expected spec
- **WAV**: RIFF/WAVE header, PCM `fmt ` chunk (16 bytes), sample rate (22050 Hz),
  channel count (mono), and data-chunk duration (30 s or 60 s BGMs)

Exit codes: `0` if all 42 pass, `1` if any are missing or invalid. Designed
to run as a pre-commit gate so broken assets don't reach Godot.

Expected asset count: **42** (38 PNG + 4 WAV).

## Asset Generators (Python)

All generators write deterministic outputs (PIL + wave stdlib only — no
third-party deps). Regenerate after editing `.tres` data, sprite specs, or
BGM parameters.

### Sprite / Tile / Portrait Generators

| Script | Output | Notes |
|---|---|---|
| `gen_ch3_assets.py` | Sat-3 tiles + enemies + NPCs + title BG | 4 tiles + 6 enemies + 1 boss + 4 NPCs + 1 title |
| `gen_ch4_assets.py` | Sat-4 tiles + enemies + NPCs + title BG | 4 tiles + 6 enemies + 1 boss + 4 NPCs + 1 title |
| `gen_ch5_assets.py` | Sat-5 tiles + boss + title BG | 4 tiles + 1 boss + 1 title |
| `gen_ch2_assets.py` | Sat-2 (Ch2) tiles + enemies + NPCs | 4 tiles + 6 enemies + 1 boss + 4 NPCs + 1 title + 4 portraits |
| `gen_tilemap_tiles.py` | Base tilesets | 32×32 PNG, palette-aware |
| `gen_enemy_sprites.py` | Enemy sprite variants | 32×32 PNG, indexed palette |
| `gen_npc_portraits.py` | NPC headshots | 64×64 PNG |
| `gen_player_mech.py` | Player mech (4 dirs) | 32×32 PNG sprite frames |
| `gen_hud_sprites.py` | HUD elements | 16×16 + 32×32 icons |
| `gen_title_art.py` | Title screen backgrounds | 1280×720 PNG (procedural composition) |
| `gen_npc_anim_frames.py` | Mouth-open / eye-blink variants | For lip-sync (S6-100) |

### Audio Generators

| Script | Output | Notes |
|---|---|---|
| `gen_music.py` | 4 BGMs (frozen_reactor, hive_heart, wreckage_echo, creators_dream) | 22050 Hz mono PCM, 30 s / 60 s loops |
| `gen_sfx.py` | SFX sample bank | Short procedural cues for combat / UI |

### Data Generators (`.tres`)

| Script | Output | Notes |
|---|---|---|
| `gen_ch3_data.py` | Sat-3 enemies / NPCs / rooms / fragments / chapter header | 30+ `.tres` |
| `gen_ch4_data.py` | Sat-4 `.tres` data | 30+ files |
| `gen_ch5_data.py` | Sat-5 `.tres` data | 30+ files |
| `gen_ch2_terminals.py` | Ch2 terminal data | For narrative interaction system |
| `generate_tr_yaml.py` | Translation YAML for Godot's tr() system | Syncs `design/l10n/strings.csv` |

## Linters

Lint tools enforce project coding standards. Each runs in <2 s and exits
non-zero on any violation.

| Script | Purpose |
|---|---|
| `lint_action_count.py` | Verify no single `_input` handler exceeds the action budget |
| `lint_autoload_order.py` | Validate autoload singleton registration order in project.godot |
| `lint_boss_immunity.py` | Boss immunity fields declared consistently |
| `lint_has_method_var.py` | Catch typos in `has_method()` / `has_signal()` calls |
| `lint_indent.py` | Tabs-only indentation in GDScript |
| `lint_no_draw.py` | No `_draw()` overrides outside HUD modules |
| `lint_npc_id_uniqueness.py` | NPC IDs are unique across the project |
| `lint_object_get.py` | Use `get_node_or_null()` instead of `get_node()` |
| `lint_resource_subclasses.py` | All custom Resources have `@tool` and `class_name` |
| `lint_signal_naming.py` | Signals follow `past_tense` snake_case |
| `lint_typed_array_inference.py` | `Array[X]` over `Array` for typed collections |

Run all linters: `for l in tools/lint_*.py; do python "$l"; done`

## Other Tools

| Script | Purpose |
|---|---|
| `build.sh` | Godot export preset invoker (Linux / macOS) |
| `parse_trs.py` | Inspect Godot `.tscn` files (debug aid) |
| `sync_input_bindings.py` | Validate InputMap matches `design/inputs.json` |

## Adding a New Generator

1. Write `<system>_assets.py` and `<system>_data.py` following the existing
   pattern: deterministic seed, file path constants, one function per asset.
2. Add the asset filenames to `tools/verify_assets.py::EXPECTED_FILES`.
3. Run `python tools/verify_assets.py` — must report `Total: N OK / 0 missing / 0 invalid`.
4. Commit the generator + the assets together.