# Godot F5 Verification — Manual Run Guide

The game is **feature-complete** at the data + system + UI layers (5 sprints
shipped: S7-S11, plus the polish phase — 65/65 stories, ~11200 LOC, ~310
tests). Final verification requires opening the project in Godot 4.6 and
hitting F5 to confirm the runtime actually loads everything.

Claude Code can't run Godot from this terminal, so this document is the
runbook for the manual F5 check.

---

## Pre-flight (no Godot required)

```bash
# 1. Asset sanity check
python tools/verify_assets.py
# Expected: Total: 42 OK / 0 missing / 0 invalid

# 2. GDScript syntax pass (catches parse errors before Godot opens)
for f in $(find src tests -name "*.gd"); do
    godot --headless --check-only --script "$f" 2>&1 | grep -i error
done
```

If `verify_assets.py` reports anything missing, regenerate first:

```bash
python tools/gen_ch3_assets.py
python tools/gen_ch4_assets.py
python tools/gen_ch5_assets.py
python tools/gen_ch2_assets.py
```

---

## F5 in Godot 4.6

1. **Open Godot 4.6** (download from https://godotengine.org/download if not
   installed — pick `Godot v4.6.x - Standard` for Windows).

2. **Import the project**: Godot → Import → navigate to `C:\Users\suxiu\Desktop\my-game` → select `project.godot` → Import & Open.

3. **Wait for asset import**: First open reimports all PNG/WAV/.tres files.
   For our 42 assets + 30+ `.tres` files, expect ~30-60 s.

4. **Watch for errors** in the Output panel (bottom):
   - ✅ Good: `[Resource] Loaded N .tres files` then quiet.
   - ❌ Bad: `Parse Error: ...` or `Could not find class ...`. Paste the
     first error back to Claude for a fix.

5. **Hit F5** (or click the Play button ▶). The Main scene loads.

---

## What to verify in-game

The game has 5 satellites (S1-S2 from prior session, S3 Hive, S4 Pluto,
S5 Origin) + 4 endings. Full walkthrough is too long for one F5; spot-check
the **critical-path checkpoints** below — each one tests a different system.

### Checkpoint 1 — Title screen loads

- **Look for**: Title screen with chapter select or `NEW GAME` button.
- **Tests**: scene tree loads, autoloads register without error.
- **If broken**: Output panel will show `null instance` or autoload errors.

### Checkpoint 2 — Start a new game (Ch1)

- **Look for**: Spawn into Ch1 frozen-reactor scene; Ranger mech on screen.
- **Tests**: SaveManager initializes; ResourceRegistry loads all `.tres`;
  PlayerController accepts input.
- **If broken**: black screen or immediate crash. Check Output for the
  first error line.

### Checkpoint 3 — Mech Bay menu (S7-007)

- **Action**: Press **M** key in town.
- **Look for**: Modal menu with 4 mech cards (ranger/frostbite/bomber/cangqiong);
  3 pilot buttons (ranger/frostbite/bomber).
- **Tests**: `MechBayEvents` autoload registers; `mech_bay_ui.gd` instantiates.
- **If broken**: nothing happens on M-key, or console says "MechBayEvents missing".

### Checkpoint 4 — 3v1 Battle (S7-001)

- **Action**: Trigger an encounter (touch an enemy on the map).
- **Look for**: 3-pilot party HUD at top, single boss enemy on right, turn-based
  action bar at bottom.
- **Tests**: `PartyBattleController` integrates with `state_battle`;
  `PartyHudOverlay` displays 3 HP bars.
- **If broken**: HUD missing, only 1 pilot shows, or error in `party_battle_controller.gd`.

### Checkpoint 5 — Auto mode toggle (S7-011)

- **Action**: Press the **A** key during battle.
- **Look for**: Each pilot takes their turn automatically. Ranger picks
  highest-damage slot; frostbite targets weakest enemy; bomber picks AOE.
- **Tests**: `AutoModeAI` registers; pilot rotation works; knocked-out pilots skipped.
- **If broken**: only the first pilot acts, then nothing happens.

### Checkpoint 6 — Sat-3 Hive hallucination (S8-013)

- **Action**: Travel to Sat-3 (蜂巢号).
- **Look for**: Some "enemies" shimmer and don't take damage when hit.
- **Tests**: `HallucinationManager.is_decoy()` returns true; `on_attack()`
  returns true (no damage applied).
- **If broken**: every enemy takes normal damage.

### Checkpoint 7 — Sat-4 AI ability (S9-014)

- **Action**: Fight a Sat-4 enemy.
- **Look for**: Enemy occasionally uses an ability (player ability disabled for
  1 turn, aim recalculated, scrap drone summoned).
- **Tests**: `AIEnemyManager.try_trigger_ability()` fires; cooldowns tick.
- **If broken**: enemy never uses abilities or crashes the battle.

### Checkpoint 8 — Bounty Board (S11)

- **Action**: Walk to the bounty board in town.
- **Look for**: 6 bounty entries (1 orange/plot, 5 gray/optional, 1 post-game).
- **Tests**: `BountyManager` registered; `bounty_board_ui.gd` lists bounties.
- **If broken**: empty list or "BountyManager missing" error.

### Checkpoint 9 — Racing Arena (S11)

- **Action**: Visit the racing arena.
- **Look for**: 6 track buttons + 4 mech buttons + bet adjuster.
  Press RACE → top-down race animation with 4 colored mech sprites.
- **Tests**: `RacingManager.calculate_race_time()` runs; `race_animation.gd`
  spawns 4 mechs and animates them.
- **If broken**: bet adjuster doesn't update, or race animation doesn't start.

### Checkpoint 10 — Save / Load

- **Action**: Save game (Esc → Save), quit, reload.
- **Look for**: Active mech + gold + ending state + bounty progress all
  restored exactly.
- **Tests**: `SaveManager.SAVE_VERSION_CURRENT == 2`; v1→v2 migration
  if loading an old save.

---

## Test runner (optional but recommended)

If your machine has Godot on PATH:

```bash
# Headless regression — all 22 test files, ~340 tests
godot --headless --script tests/runners/sprint7_plus_runner.gd
```

Expected: `Passed: ~340 / Failed: 0 / Pending: 0` (some tests use `pending()`
when an autoload is missing in headless mode — that's normal).

---

## Common errors and fixes

| Error | Cause | Fix |
|---|---|---|
| `Class "X" not found` | `class_name` typo or missing `@tool` | Check `src/resource/*.gd` for the class |
| `Could not load resource ...` | `.tres` references missing `.gd` | Open the `.tres` in a text editor, fix the `script_class` |
| `Autoload ... not registered` | `project.godot` missing singleton | Add to `[autoload]` section |
| `null instance on Node "X"` | Node not in the expected scene | Re-add the node via the scene editor |
| `Parser Error: Unexpected` | Indentation or syntax issue | Run `python tools/lint_indent.py` |

For anything not in this table, paste the **first** error from the Output
panel back to Claude — the first error usually points at the root cause.

---

## Verification complete

If all 10 checkpoints pass, the game is **verified-feature-complete** and
ready for store submission. The next step is platform export:

```bash
# Build Windows export (requires export templates installed)
godot --headless --export-release "Windows Desktop" build/railhunter.exe

# Or open Godot → Project → Export → add Windows Desktop preset → Export Project
```

For Steam: see `production/store-submission-checklist.md` (if it exists).
For itch.io: drag `build/railhunter.exe` + the `assets/` folder to butler
or just zip and upload.