# S7-001 Implementation Plan — BattleScene 1v1 → 3v1

> **Sprint 7 Story**: S7-001 (3 days, godot-gdscript-specialist)
> **Depends on**: None (S7-001 is the foundation; everything else builds on it)
> **Goal**: Extend `src/battle/battle_scene.gd` from a **1v1 single-mech fight** to a **3v1 multi-pilot party fight** (party of 3 pilots vs 1 enemy), with free pilot-mech switching (1/2/3 keys), mid-combat mech swap (Tab), and the **3-pilot per round** action economy specified in `party-system.md` §3.7.

## Current State (Baseline)

- **File**: `src/battle/battle_scene.gd` (352 lines)
- **Data model**: 1 enemy (`_enemy`), 1 player HP (`_player_hp`), 1 attack slot
- **Combat loop**: 1 player attack per player round, 1 enemy attack per enemy round (1v1 alternating)
- **No pilot switching**, no mech switching
- **2 autoloads** involved: `GameStateMachine` (state transitions), `ResourceRegistry` (enemy lookup)

## Target State (After S7-001)

- **Data model**: 1 enemy + **N mechs (party mechs)**, each with their own pilot, HP, and weapon slots
- **Combat loop**: **1 enemy turn per round, then N party mechs each get 1 turn** (per `party-system.md` §3.7)
- **Mid-combat pilot switch** (1/2/3 keys) — switches which **mech** is active for the next action
- **Mid-combat mech switch** (Tab key) — changes the **pilot** of the active mech
- **Mech visual** rendered for each party mech (3 TextureRects)
- **HP bars** for each party mech (per mech, not per pilot)

## File Changes (Summary)

| File | Lines added | Lines removed | Net |
|------|-------------|---------------|-----|
| `src/battle/battle_scene.gd` | +450 | -120 | +330 |
| `src/battle/party_turn_manager.gd` (NEW) | +150 | 0 | +150 |
| `src/battle/party_hud.gd` (NEW) | +200 | 0 | +200 |
| `data/schemas/battle_state.gd` (NEW) | +80 | 0 | +80 |
| `tests/integration/fc59_battle_3v1_test.gd` (NEW) | +120 | 0 | +120 |

**Total**: ~880 lines added, ~120 lines removed. **Net: +760 lines** across 5 files.

---

## Sub-Task Breakdown (Days 1-3)

### Day 1: Data Model + Party State

**Sub-task 1.1: Create `data/schemas/battle_state.gd`** (0.5 day)

A new resource type that holds the entire party state during combat:

```gdscript
# data/schemas/battle_state.gd
class_name BattleState
extends Resource

# Party mechs in combat order (left to right in HUD)
var party_mechs: Array[Dictionary] = []  # each: {mech_id, pilot_id, current_hp, max_hp, parts_hp, weapons, is_active}
var active_mech_index: int = 0  # which party mech is "selected" for the next action
var enemy_id: StringName = &""
var enemy_hp: int = 0
var enemy_max_hp: int = 0
var round_number: int = 0
var phase: StringName = &"player"  # or "enemy"
var mechs_acted_this_round: Array[int] = []  # indices of mechs that have already acted
```

**Why a new file**: Centralizes the combat state. Easier to test. Decouples from `BattleScene`'s UI.

**Sub-task 1.2: Refactor `battle_scene.gd` to use `BattleState`** (0.5 day)

Replace `_enemy`, `_player_hp`, `_pending_enemy_id` with a single `_state: BattleState` field. Methods that read/write state go through `_state`.

**Backward compat**: Add a `legacy_1v1_mode: bool = false` flag. When true, the BattleScene uses the old 1v1 logic (so existing encounters in Ch1-Ch6 still work). When false, the new 3v1 logic activates. Default: false (new 3v1 mode is on by default for new content).

**Sub-task 1.3: Wire `PartyManager` autoload into `BattleScene`** (Sprint 7's other story, S7-001 depends on it)

`PartyManager` is a new autoload that holds the party's state across all gameplay modes (exploration + battle). `BattleScene` queries `PartyManager.party` at the start of each fight to populate `_state.party_mechs`.

**Note**: `PartyManager` is a separate story (S7-008 or so). For S7-001, hard-code a 3-mech party for testing.

### Day 2: Combat Loop + Mech Visual

**Sub-task 2.1: Implement the 3-pilot action economy** (1 day)

The new combat loop:

```gdscript
func _process_combat_round() -> void:
    # Enemy phase
    _state.phase = &"enemy"
    _enemy_act()  # 1 enemy attack
    if _check_party_wipe():
        return  # game over or revive

    # Player phase
    _state.phase = &"player"
    _state.mechs_acted_this_round = []
    _state.round_number += 1

    # Player selects mechs one at a time (1/2/3 keys to select, E to act, or auto-mode)
    while _state.mechs_acted_this_round.size() < _state.party_mechs.size():
        # Wait for player input
        var action: StringName = await _wait_for_player_action()
        if action == &"act":
            _mech_act(_state.active_mech_index)
            _state.mechs_acted_this_round.append(_state.active_mech_index)
        elif action == &"switch_pilot":
            _switch_active_pilot()  # Tab key
        elif action == &"switch_mech":
            _switch_active_mech()  # 1/2/3 keys

    # Round ends, loop
    _process_combat_round()
```

**Key change**: Each round, the player gets **N turns** (N = number of party mechs), not 1 turn. The enemy gets 1 turn per round. This is the "many vs one" economy from `party-system.md` §3.7.

**Sub-task 2.2: Pilot switch mid-combat (1/2/3 keys)** (0.5 day)

When the player presses 1, 2, or 3 in combat (during the player phase), `_state.active_mech_index` changes. The HUD highlights the selected mech. Subsequent actions (E to act) use the new active mech.

**Sub-task 2.3: Pilot swap mid-combat (Tab key)** (0.5 day)

When the player presses Tab, the **pilot** of the active mech changes (e.g., swap 漫游者 out of 漫游者号, swap 霜尾 in). The mech's HP, weapons, and special abilities change accordingly.

**Implementation**: `_state.party_mechs[active_mech_index].pilot_id` changes. The HUD updates.

### Day 3: HUD + Tests

**Sub-task 3.1: Create `src/battle/party_hud.gd`** (1 day)

A new HUD layer showing:
- 3 mech portraits (left to right) — each shows the mech's sprite + pilot's icon + current/max HP
- Active mech highlighted (yellow border)
- Knocked-out mechs dimmed
- Bottom-right: weapons panel (current mech's 3-4 weapons, click to select)
- Top-right: round counter + enemy HP

**Sub-task 3.2: Tests fc59_battle_3v1_test.gd** (0.5 day)

8 tests covering the new combat loop:
- 1) Battle state initializes with 3 mechs
- 2) 1/2/3 keys switch active mech
- 3) Tab swaps pilot
- 4) Each mech gets 1 turn per round
- 5) Enemy attacks 1 mech per round
- 6) Knocked-out mechs don't get turns
- 7) All mechs knocked out → battle loss
- 8) Boss fight works in 3v1 mode

---

## Code Patterns to Reuse (from existing codebase)

| Pattern | Existing location | Reuse for S7-001 |
|--------|-------------------|------------------|
| Enemy resource lookup | `ResourceRegistry.get_resource(enemy_id)` | Same — works for new enemies |
| Damage calculation | `BattleMathLib.compute_base_damage(...)` | Same — already 1-pilot |
| HP bar rendering | `hud.gd` `_hp_fill` | Reuse the pattern for 3 mechs |
| Texture modulation (hit flash) | `battle_scene.gd` `_flash_enemy()` | Reuse for 3 mechs |
| Camera shake | `battle_scene.gd` `_shake_camera()` | Same |

## Risks Specific to S7-001

1. **Backward compatibility with existing 1v1 encounters**: The `legacy_1v1_mode` flag handles this. Default is 3v1, but old Ch1-Ch6 encounters can be set to `legacy_1v1_mode = true` to use the old code path.
2. **Save/load roundtrip**: The new `BattleState` must be serializable. Use the same pattern as the existing `_pending_enemy_id` (a simple value, not an object).
3. **Auto mode compatibility**: Auto mode (Sprint 7's S7-011) needs to work in 3v1 mode. Defer to S7-011 — S7-001 just adds the 3v1 data model, not the Auto AI.

## Out of Scope (for S7-001 only)

- Pilot ability execution (S7-001 only sets up the framework; the abilities fire in subsequent stories)
- Boss phase transitions (separate story in Sprint 8-10)
- AOE / friendly fire logic (separate story in S7-014 / S11-008)
- Special abilities (e.g., 霜尾's Flank, 轰天's Iron Wall) — Sprint 7's S7-011 territory
- Dialogue companion swap (S7-005)
- Mech Bay menu (S7-007)

## Acceptance Test (Manual F5 Verification)

1. Start a new game, F5.
2. Reach Ch1 Room 3 (first encounter).
3. Trigger the encounter → battle starts.
4. **Verify**: 3 mech portraits appear in the HUD (Ranger, Frostbite, Bomber). The player sees 3 mechs even though only 1 is currently in the party (the others are placeholders).
5. Press 1, 2, 3 — the active mech highlight changes.
6. Press Tab — the pilot of the active mech changes.
7. Press E (or 1/2/3 then E) — the active mech attacks.
8. **Verify**: After all 3 mechs have acted, the round ends, and the enemy attacks 1 mech.
9. Repeat for 2-3 rounds.
10. Defeat the enemy → victory screen.

If all 10 steps work without crash, S7-001 is complete.
