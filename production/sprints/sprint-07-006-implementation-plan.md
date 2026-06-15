# S7-006 Implementation Plan — Town Clinic Revival System

> **Sprint 7 Story**: S7-006 (1.5 days, godot-gdscript-specialist)
> **Depends on**: S7-001 (BattleState.party_mechs) + S7-002 (per-mech loadouts)
> **Goal**: Implement the **town clinic revival system** specified in `party-system.md` §3.8. When a non-main pilot is knocked out in combat, they are auto-sent to the nearest clinic after combat. Revival cost = `max(floor(gold × 0.25), 100)`. Revivals are unlimited. The main character (漫游者) cannot be revived — death = game over.

## Current State (Baseline)

- **No clinic / revival system exists**. There is no `Clinic` or `Hospital` autoload.
- **SaveManager** has 13 producer namespaces (per `PRODUCER_NAMESPACES` in `save_manager.gd`); none for clinic/revival.
- **Combat** (in `BattleScene`) handles enemy victory but doesn't have a "knocked out pilot" state separate from "dead pilot".
- **No "revival" concept** in the codebase.

## Target State (After S7-006)

- **New autoload**: `ClinicManager` (autoload #22) — handles revival state, gold cost calculation, UI
- **New producer namespace** in SaveManager: `clinic` — added to `PRODUCER_NAMESPACES`
- **Knocked-out pilots** tracked per-pilot: a pilot has 3 states (active / knocked out / dead)
- **Auto-send on combat end**: when a non-main pilot is knocked out, they're auto-queued for revival
- **UI**: clinic front desk — "Revive [pilot] for X gold?" prompt
- **Main character exception**: 漫游者 cannot be revived; death = game over

## File Changes (Summary)

| File | Lines added | Lines removed | Net |
|------|-------------|---------------|-------|
| `src/autoload/clinic_manager.gd` (NEW) | +200 | 0 | +200 |
| `src/autoload/save_manager.gd` | +5 | 0 | +5 |
| `src/scene/clinic_ui.gd` (NEW) | +180 | 0 | +180 |
| `src/battle/battle_scene.gd` (S7-001 refactor) | +30 | 0 | +30 |
| `tests/integration/fc64_clinic_revive_test.gd` (NEW) | +90 | 0 | +90 |

**Total**: ~505 lines added, ~0 lines removed. **Net: +505 lines** across 5 files (incl. autoload + UI).

---

## Sub-Task Breakdown (Days 1-1.5)

### Day 1 Morning: ClinicManager Autoload

**Sub-task 1.1: Create `src/autoload/clinic_manager.gd`** (0.5 day)

The core revival logic:

```gdscript
# src/autoload/clinic_manager.gd
extends Node

# Per-pilot state
enum PilotState { ACTIVE, KNOCKED_OUT, DEAD }
var _pilot_states: Dictionary = {}  # pilot_id (StringName) → PilotState

# Pilots queued for revival (set after combat)
var _revival_queue: Array[StringName] = []

# Gold tracking
var _gold: int = 0

# Revival cost formula
const REVIVAL_COST_RATIO: float = 0.25
const REVIVAL_COST_MIN: int = 100

# Signals
signal pilot_revived(pilot_id: StringName, gold_spent: int)
signal pilot_state_changed(pilot_id: StringName, new_state: int)
signal gold_changed(new_amount: int)

func _ready() -> void:
    # Initialize 3 pilots
    _pilot_states[&"ranger"] = PilotState.ACTIVE
    _pilot_states[&"frostbite"] = PilotState.ACTIVE  # even if not yet recruited
    _pilot_states[&"bomber"] = PilotState.ACTIVE

func knock_out_pilot(pilot_id: StringName) -> void:
    # Called by BattleScene when a non-main pilot's mech is reduced to 0 HP
    if pilot_id == &"ranger":
        push_error("ClinicManager: cannot knock out main character (ranger) — that's game over")
        return
    _pilot_states[pilot_id] = PilotState.KNOCKED_OUT
    _revival_queue.append(pilot_id)
    pilot_state_changed.emit(pilot_id, PilotState.KNOCKED_OUT)

func revive_pilot(pilot_id: StringName) -> Error:
    if pilot_id not in _pilot_states:
        return ERR_INVALID_PARAMETER
    if _pilot_states[pilot_id] != PilotState.KNOCKED_OUT:
        return ERR_INVALID_DATA  # can only revive knocked-out pilots
    var cost: int = get_revival_cost()
    if _gold < cost:
        return ERR_DOES_NOT_EXIST  # not enough gold
    _gold -= cost
    _pilot_states[pilot_id] = PilotState.ACTIVE
    _revival_queue.erase(pilot_id)
    pilot_revived.emit(pilot_id, cost)
    gold_changed.emit(_gold)
    pilot_state_changed.emit(pilot_id, PilotState.ACTIVE)
    return OK

func get_revival_cost() -> int:
    return max(int(floor(_gold * REVIVAL_COST_RATIO)), REVIVAL_COST_MIN)

func add_gold(amount: int) -> void:
    _gold += amount
    gold_changed.emit(_gold)

func get_gold() -> int:
    return _gold

func is_knocked_out(pilot_id: StringName) -> bool:
    return _pilot_states.get(pilot_id, PilotState.ACTIVE) == PilotState.KNOCKED_OUT

func get_state_snapshot() -> Dictionary:
    return {
        "pilot_states": _pilot_states.duplicate(),
        "revival_queue": _revival_queue.duplicate(),
        "gold": _gold,
    }

func load_snapshot(snap: Dictionary) -> Error:
    if "pilot_states" in snap:
        _pilot_states = snap["pilot_states"]
    if "revival_queue" in snap:
        _revival_queue = snap["revival_queue"]
    if "gold" in snap:
        _gold = snap["gold"]
    return OK
```

**Sub-task 1.2: Register `ClinicManager` in `project.godot`** (0.1 day)

Add to autoloads (after existing 21 autoloads, before `SaveManager` per autoload order convention):
```
ClinicManager="*res://src/autoload/clinic_manager.gd"
```

**Sub-task 1.3: Add `clinic` to `SaveManager.PRODUCER_NAMESPACES`** (0.05 day)

```gdscript
# In save_manager.gd, add "clinic" to the namespaces list
const PRODUCER_NAMESPACES: Array[StringName] = [
    ...existing 13...
    &"clinic",  # NEW (14th)
]
```

### Day 1 Afternoon: BattleScene Integration

**Sub-task 1.4: Hook into BattleScene (S7-001)** (0.5 day)

When a non-main pilot's mech is reduced to 0 HP (in `BattleState`):

```gdscript
# In battle_scene.gd (S7-001's _on_mech_knocked_out method, NEW)
func _on_mech_knocked_out(pilot_id: StringName) -> void:
    if pilot_id == &"ranger":
        # Main character death = game over
        _game_over()
        return
    var clinic: Node = get_node("/root/ClinicManager")
    clinic.knock_out_pilot(pilot_id)
    # Don't show a "knocked out" popup here — just log it
    print("[BattleScene] pilot %s knocked out, queued for revival" % pilot_id)
```

**When all 3 non-main pilots are knocked out** (per party-system.md §3.8 E11): Game over.

**Sub-task 1.5: After-combat revival queue** (0.25 day)

When combat ends (in `_resolve_battle`), check the revival queue:

```gdscript
# In battle_scene.gd (S7-001's _resolve_battle, NEW)
func _show_revival_prompt() -> void:
    var clinic: Node = get_node("/root/ClinicManager")
    if clinic._revival_queue.is_empty():
        return
    # Show a UI prompt listing the knocked-out pilots and their revival cost
    # Player can choose to revive or skip (the queue persists)
    ...
```

### Day 1.5: UI + Tests

**Sub-task 1.6: Create `src/scene/clinic_ui.gd`** (0.5 day)

The clinic front desk UI. Displayed when the player interacts with a "clinic" object in a town.

```gdscript
# src/scene/clinic_ui.gd
extends Control

# UI elements
var _gold_label: Label
var _pilot_list: VBoxContainer  # 3 rows, one per pilot
var _revive_button: Button

# Data
var _selected_pilot: StringName = &""

func _ready() -> void:
    # Build UI
    ...
    # Subscribe to ClinicManager signals
    var clinic: Node = get_node("/root/ClinicManager")
    clinic.pilot_state_changed.connect(_on_pilot_state_changed)
    clinic.gold_changed.connect(_on_gold_changed)
    _refresh()

func _refresh() -> void:
    var clinic: Node = get_node("/root/ClinicManager")
    _gold_label.text = "Gold: %d" % clinic.get_gold()
    # For each pilot, show: name, state (Active/Knocked Out/Dead), revival cost
    for pilot_id in [&"ranger", &"frostbite", &"bomber"]:
        var state: int = clinic._pilot_states.get(pilot_id, 0)
        var row: Control = _pilot_list.get_node(String(pilot_id))
        row.get_node("Name").text = String(pilot_id)
        row.get_node("State").text = ["Active", "Knocked Out", "Dead"][state]
        if state == 1:  # KNOCKED_OUT
            var cost: int = clinic.get_revival_cost()
            row.get_node("ReviveButton").text = "Revive (%d gold)" % cost
            row.get_node("ReviveButton").disabled = clinic.get_gold() < cost

func _on_revive_pressed(pilot_id: StringName) -> void:
    var clinic: Node = get_node("/root/ClinicManager")
    var err: Error = clinic.revive_pilot(pilot_id)
    if err != OK:
        push_warning("ClinicUI: revive failed (%d)" % err)
    _refresh()
```

**Sub-task 1.7: Tests fc64_clinic_revive_test.gd** (0.5 day)

6 tests:
- 1) Knock out a pilot → state is KNOCKED_OUT
- 2) Revive cost = max(floor(gold × 0.25), 100)
- 3) Revive with insufficient gold fails
- 4) Revive with sufficient gold succeeds, pilot state is ACTIVE
- 5) Cannot knock out ranger (main character)
- 6) Save/Load roundtrip preserves pilot states + gold

---

## Code Patterns to Reuse (from existing codebase)

| Pattern | Existing location | Reuse for S7-006 |
|--------|-------------------|------------------|
| Save producer pattern | `save_manager.gd` `PRODUCER_NAMESPACES` | Add `&"clinic"` |
| Snapshot pattern | Other autoloads `get_state_snapshot` | Same pattern for ClinicManager |
| Signal-based UI | Various | `pilot_state_changed` + `gold_changed` signals |
| Game over pattern | `BattleScene._on_player_died` | Reuse for "all non-main knocked out" |

## Risks Specific to S7-006

1. **All 3 non-main pilots knocked out = game over**: But the player just lost the fight. Is this game over? Or is it "you lost, retry"? Per `party-system.md` §3.8 E11, it's a "you lost" — but is that "you lost the encounter" (retry) or "you lost the game" (game over)?
   - **Decision**: It's "you lost the encounter" — the player retries from the last save (same as current 1v1 loss behavior). The revival system is for the *in-combat* knocked-out state, not for full game loss.
   - **Mitigation**: Document this in the implementation. The revival flow is for **mid-fight** losses, not end-of-fight.

2. **The 25% gold cost might be too punishing** if the player keeps losing. After 4 losses with insufficient gold, the pilot is permanently dead.
   - **Mitigation**: The minimum cost is 100 gold. If the player has < 100 gold, the revival fails. This is a fail-state. Document it. (Per `party-system.md` §3.8 E9.)

3. **The "auto-send to clinic" might surprise the player**: They didn't choose to be revived; the system auto-deducts gold.
   - **Mitigation**: Show a clear "Revival prompt" after combat ends. The player must confirm. If they decline, the pilot stays knocked out (and gold is NOT deducted).

4. **Save format migration**: Old saves don't have `_pilot_states`. The migration must default to all pilots ACTIVE.
   - **Mitigation**: In `load_snapshot`, if `pilot_states` is missing, default to all ACTIVE.

## Out of Scope (for S7-006 only)

- Med-bay in satellites (without towns) — per `party-system.md` §3.8 table, "satellite on-board med-bay" is a deferred variant. For S7-006, only the town clinic is implemented.
- Trust / affinity (different system)
- Voice acting
- 3-character dialogue (deferred)

## Acceptance Test (Manual F5 Verification)

1. Start a new game, F5. Recruit 霜尾 (Ch4 mid).
2. Enter a tough encounter. Let 霜尾's mech reach 0 HP first.
3. **Verify**: 霜尾 is "knocked out" (not killed). The fight continues with 漫游者 + 轰天.
4. Lose the fight (or win). Combat ends.
5. **Verify**: A "Revival prompt" appears: "Revive 霜尾 for X gold? (Y/N)"
6. Press Y. Gold is deducted. 霜尾 is ACTIVE again.
7. Visit a clinic in town. Verify the UI shows: Gold, 3 pilots (with state), revive buttons for knocked-out pilots.
8. Reload from a save. Verify pilot states are preserved.
9. Knock out 霜尾 + 轰天. Try to revive 霜尾 (costs 25% of gold). Try to revive 轰天 (now costs 25% of remaining gold). Verify the cost decreases as gold decreases.
10. Test the main character death: let 漫游者's mech reach 0 HP. **Verify**: Game over screen appears (not a revival prompt).

If all 10 steps work, S7-006 is complete.
