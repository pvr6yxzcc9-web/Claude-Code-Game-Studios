# PartyBattleController (S7-001 First Real Implementation)

> **Status**: First PR of S7-001 (per the `sprint-07-001-implementation-plan.md` plan)
> **Created**: 2026-06-16
> **Purpose**: Minimal-risk first refactor toward 3v1 combat. Does NOT modify the existing 1v1 `battle_scene.gd`.

## What This Is

A **separate controller** that runs in parallel with the existing `battle_scene.gd`. It:
- Loads 3 mechs from the party (currently a hardcoded fallback; will read from `MechLoadout` in Sprint 7 PR 2)
- Provides 1/2/3 keys to switch active mech mid-battle
- Iterates through 3 mechs (1 attack each) before the enemy attacks once
- Manages knock-out state per mech
- Emits signals for UI to listen to (HUD, etc.)

## How It Differs from the Existing 1v1 BattleScene

| Aspect | Existing 1v1 (`battle_scene.gd`) | New 3v1 (`party_battle_controller.gd`) |
|--------|----------------------------------|----------------------------------------|
| Pilots | 1 (Ranger) | 3 (Ranger, Frostbite, Bomber) |
| Action order | 1 player attack → 1 enemy attack | 3 player attacks (1 per mech) → 1 enemy attack |
| Active mech | N/A | Switchable with 1/2/3 keys |
| Mech HP | 1 global _player_hp | Per-mech HP (ranger/frostbite/bomber each have their own) |
| Knock-out | Player death = game over | 1 mech knocked out → others continue; all 3 down = encounter loss |

## How to Use

### Add the controller to main.tscn

1. Open `src/main.tscn` in the Godot editor
2. Add a new node: `Node` with the script `res://src/battle/party_battle_controller.gd`
3. Save the scene

### Test the controller

The controller doesn't auto-trigger yet. To test it, you need to call `debug_start_test_battle()` from somewhere. **Currently, there's no test trigger** — for Sprint 7 PR 1, the controller is dormant until you wire it up.

**Wire-up options for PR 2**:
- Hook into a debug key (e.g., Ctrl+Shift+T) in the existing main scene
- Add to the pause menu as a "Test 3v1 Battle" button
- Add to a debug HUD

## What's Implemented

- ✅ 3-pilot data model (3 default mechs, fallback if MechLoadout not loaded)
- ✅ 1/2/3 key switching (mid-battle)
- ✅ 3-pilot per round economy (1 attack per mech, then enemy attacks)
- ✅ Active mech highlighting via signal
- ✅ Knock-out handling (per-mech HP tracking)
- ✅ Enemy attack on active mech
- ✅ Round counter
- ❌ Not yet integrated with the existing `battle_scene.gd` (1v1 fights)
- ❌ Not yet triggered by `state_battle` transitions
- ❌ No real damage formula (uses 20-30 random — Sprint 7-009 will fix)
- ❌ No HUD (Sprint 7-004)
- ❌ No save/load (Sprint 7-010)
- ❌ No MechLoadout reading (Sprint 7-003 + this file's PR 2)

## Why a Separate File (Not Modifying battle_scene.gd)

Per the S7-001 implementation plan:
- The existing `battle_scene.gd` (352 lines) is **production-tested code** for Ch1/Ch2 1v1 fights
- Modifying it in PR 1 would risk breaking the working game
- A separate controller in PR 1 is **non-breaking** — existing fights still work
- PR 2-4 of S7-001 will integrate the two, replacing 1v1 with 3v1 (with a `legacy_1v1_mode` flag for safety)

## Files

- `src/battle/party_battle_controller.gd` (220 lines, the controller)
- `src/battle/party_battle_controller_README.md` (this file)

## Next Steps (S7-001 PR 2-4)

- **PR 2** (next): Read party mechs from `MechLoadout._mechs` (when S7-003 is committed)
- **PR 3**: Wire `state_battle` to call `start_party_battle()` instead of `battle_scene._enter_battle()`
- **PR 4**: Add `legacy_1v1_mode` flag, integrate HUD (S7-004), auto mode (S7-011), etc.

## Notes for Code Review

- The controller is intentionally **simple** — it does the minimum to demonstrate the 3v1 round loop
- Damage formula is hardcoded 20-30 random — Sprint 7-009 will replace with `BattleMathLib` formulas
- Per-mech data is currently a hardcoded fallback — Sprint 7-003 will provide the real `MechLoadout._mechs` data
- The controller is **not yet triggered by anything** — for testing, you must call `debug_start_test_battle()` from a script or signal

## Acceptance Test (Manual F5 Verification)

1. Add the controller to main.tscn (as described above)
2. F5 in Godot
3. The controller's `_ready` log appears: "[PartyBattleController] ready (S7-001 first PR)"
4. **Verify**: No errors in the console (the controller doesn't conflict with existing 1v1 fights)
5. Walk into an encounter in Ch1 → the existing 1v1 fight starts (NOT 3v1 yet)
6. Defeat the enemy → existing flow continues
7. (Optional) Wire a debug key to call `debug_start_test_battle()` and verify 3v1 works

If step 4 passes (no errors), the controller is safely coexisting with the 1v1 code.
