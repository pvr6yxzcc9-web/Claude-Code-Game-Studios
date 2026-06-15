# S7-007 Implementation Plan — Mech Bay Menu (M Key)

> **Sprint 7 Story**: S7-007 (2 days, ui-programmer)
> **Depends on**: S7-002 (per-mech weapons) + S7-003 (4 mechs) + S7-005 (companion system)
> **Goal**: Build the **Mech Bay menu** — the player's primary party management UI. Opened with **M key** in exploration, save points, and during the player's turn in combat. Shows all owned mechs, current pilot assignments, weapon inventory per mech, and mech part HP. Player can: (1) switch active mech, (2) reassign pilots, (3) move weapons between mechs, (4) view part HP.

## Current State (Baseline)

- **No Mech Bay menu exists**. The existing menus (Pause, Main, Codex, Save) are unrelated.
- **M key** is currently unassigned (or assigned to a non-existent menu).
- **Party state** is split across 3 autoloads (WeaponLoadout, MechLoadout, DialogueManager's companion). The Mech Bay is the **unified view** of these.

## Target State (After S7-007)

- **Mech Bay menu** (M key) opens in:
  - Exploration mode
  - Save points
  - Repair stations
  - During the player's turn in combat (paused state)
- **Menu layout**:
  - Top: 4 mech cards (one per mech). Each card shows: mech portrait, mech name, class, current pilot, parts HP.
  - Middle: 3-4 weapon slots per active mech. Click a slot to see weapon details / swap.
  - Bottom: Pilot roster (3 pilots). Click a pilot to assign to the active mech.
- **Operations** (via commands/events, per `.claude/rules/ui-code.md`):
  - Switch active mech: `MechBayEvents.set_active_mech(mech_id)`
  - Reassign pilot: `MechBayEvents.assign_pilot(mech_id, pilot_id)`
  - Move weapon: `MechBayEvents.move_weapon(from_mech, from_slot, to_mech, to_slot)`
- **Cloud save versioning** is already handled by S7-010 (per the roadmap adjustments).

## File Changes (Summary)

| File | Lines added | Lines removed | Net |
|------|-------------|---------------|-------|
| `src/ui/mech_bay_ui.gd` (NEW) | +400 | 0 | +400 |
| `src/ui/mech_bay_events.gd` (NEW) | +50 | 0 | +50 |
| `src/autoload/mech_loadout.gd` (S7-003) | +30 | 0 | +30 |
| `src/autoload/weapon_loadout.gd` (S7-002) | +30 | 0 | +30 |
| `assets/sprites/mech_bay/bg.png` (NEW) | 0 | 0 | 0 (asset) |
| `tests/integration/fc65_mech_bay_test.gd` (NEW) | +100 | 0 | +100 |

**Total**: ~610 lines added, 0 lines removed. **Net: +610 lines** across 5 files (incl. 1 asset).

---

## Sub-Task Breakdown (Days 1-2)

### Day 1 Morning: Layout Skeleton + Mech Cards

**Sub-task 1.1: Create `src/ui/mech_bay_events.gd`** (0.25 day)

A new autoload that provides **command methods** for the UI to call (per `.claude/rules/ui-code.md` — UI uses commands/events, not direct state mutation):

```gdscript
# src/ui/mech_bay_events.gd
extends Node

signal active_mech_changed(new_mech_id: StringName)
signal pilot_assigned(mech_id: StringName, new_pilot_id: StringName)
signal weapon_moved(from_mech: StringName, from_slot: int, to_mech: StringName, to_slot: int)

func set_active_mech(mech_id: StringName) -> Error:
    # Delegates to MechLoadout
    var loadout: Node = get_node("/root/MechLoadout")
    if mech_id not in loadout._mechs:
        return ERR_INVALID_PARAMETER
    loadout.set_active_mech(mech_id)
    active_mech_changed.emit(mech_id)
    return OK

func assign_pilot(mech_id: StringName, pilot_id: StringName) -> Error:
    # Validates, then updates MechLoadout._mechs[mech_id].pilot_id
    # Validates that the pilot is in the party
    ...
    pilot_assigned.emit(mech_id, pilot_id)
    return OK

func move_weapon(from_mech: StringName, from_slot: int, to_mech: StringName, to_slot: int) -> Error:
    # Validates slot types match (e.g., can move rifle to rifle slot)
    # Then updates WeaponLoadout._mech_loadouts
    ...
    weapon_moved.emit(from_mech, from_slot, to_mech, to_slot)
    return OK
```

**Why events autoload**: Separates UI from data mutation. Testable in isolation. Future-proofs for "remote control" (e.g., AI suggestions).

**Sub-task 1.2: Create `src/ui/mech_bay_ui.gd`** (1 day)

The main UI. Layout (anchored to full rect, modal):

```
┌────────────────────────────────────────────────┐
│ MECH BAY                              [M] Close  │
├────────────────────────────────────────────────┤
│ ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐         │
│ │  R   │  │  F   │  │  B   │  │  ?   │ (locked)│
│ │ranger│  │ frost│  │bomber│  │ cang │         │
│ │400hp │  │ 320hp│  │ 480hp│  │ 800hp│         │
│ │HAC 70│  │HAC 80│  │HAC120│  │HAC200│         │
│ │ 100% │  │ 100% │  │ 100% │  │ 100% │         │
│ └──────┘  └──────┘  └──────┘  └──────┘         │
│ [ACTIVE = ranger]                              │
├────────────────────────────────────────────────┤
│ Active Mech: 漫游者号                          │
│ Weapons:                                      │
│ ┌────┐ ┌────┐ ┌────┐                          │
│ │RIFL│ │KNIF│ │THRW│                          │
│ │    │ │    │ │    │                          │
│ └────┘ └────┘ └────┘                          │
│ [click slot to swap, drag to move]            │
├────────────────────────────────────────────────┤
│ Pilots: 漫游者 ●  霜尾 ○  轰天 ○              │
│ [click to assign active pilot]                │
└────────────────────────────────────────────────┘
```

Implementation pattern (mirroring `pause_menu.gd`):

```gdscript
# src/ui/mech_bay_ui.gd
extends Control

const MENU_WIDTH: float = 960.0
const MENU_HEIGHT: float = 720.0

# Visual elements
var _bg: ColorRect
var _mech_cards: Array[Dictionary] = []  # 4 cards, one per mech
var _weapon_slots: Array[Dictionary] = []  # 3-4 slots for active mech
var _pilot_buttons: Array[Button] = []  # 3 pilot toggle buttons

# Data
var _active_mech_id: StringName = &""

# Signals
signal closed

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_preset(Control.PRESET_FULL_RECT)
    _build_ui()
    var events: Node = get_node("/root/MechBayEvents")
    events.active_mech_changed.connect(_on_active_mech_changed)
    events.pilot_assigned.connect(_on_pilot_assigned)
    events.weapon_moved.connect(_on_weapon_moved)
    hide()
    print("[MechBayUI] ready")

func _build_ui() -> void:
    # ... builds the layout shown above
    pass

func _input(event: InputEvent) -> void:
    if event.is_action_pressed(&"mech_bay_toggle"):
        if visible:
            hide()
            closed.emit()
        else:
            show()
            _refresh()
```

**Localization**: All visible text must use `Localization.t(&"ui.mech_bay.<key>")`. Examples: "MECH BAY", "Active", "Locked", "Click to assign".

### Day 1 Afternoon: Mech Card + Weapon Slot Interactions

**Sub-task 1.3: Mech card click → set active mech** (0.25 day)

Clicking a mech card calls `MechBayEvents.set_active_mech(mech_id)`. The card highlights as "active" (yellow border).

**Sub-task 1.4: Weapon slot click → show weapon details / swap menu** (0.5 day)

Clicking a weapon slot opens a sub-menu:
- "View details" (shows weapon stats, lore)
- "Swap" (opens the player's weapon inventory, player picks a weapon to equip)
- "Move to another mech" (drag-and-drop or click-to-select + click-to-place)

### Day 2 Morning: Pilot Roster + Save/Load

**Sub-task 1.5: Pilot roster buttons** (0.25 day)

3 pilot buttons (one per pilot). Clicking assigns the pilot to the **active mech**. The button highlights if the pilot is currently assigned to the active mech.

**Constraint**: Each pilot can only drive 1 mech at a time. If the player tries to assign Pilot A to Mech X when Pilot A is already driving Mech Y, the system **swaps**: Pilot A goes to Mech X, and Pilot Y (currently driving Mech X) goes to Mech Y. This is the "auto-swap" behavior.

**Sub-task 1.6: Save/Load integration** (0.25 day)

The Mech Bay is **not persisted** as a separate state. The state is composed of:
- `MechLoadout._mechs[mech_id].pilot_id` (S7-003)
- `WeaponLoadout._mech_loadouts[mech_id].weapon_slots` (S7-002)
- `MechLoadout._active_mech_id` (S7-003)

All three are already in the save format (via S7-010). So the Mech Bay **doesn't need its own save state** — it just reads from existing snapshots.

**Sub-task 1.7: M key input handling** (0.1 day)

Add `mech_bay_toggle` action to `project.godot`:
```
mech_bay_toggle={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":77,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
```

(77 is the keycode for M.)

### Day 2 Afternoon: Tests + Polish

**Sub-task 1.8: Tests fc65_mech_bay_test.gd** (0.5 day)

6 tests:
- 1) M key opens the Mech Bay
- 2) Closing the Mech Bay hides the UI
- 3) Clicking a mech card sets the active mech
- 4) Clicking a pilot button assigns the pilot to the active mech
- 5) Moving a weapon between mechs updates both mechs' inventories
- 6) Save/Load roundtrip preserves mech assignments + weapon loadouts

**Sub-task 1.9: Polish** (0.25 day)

- Active mech card: yellow border + "ACTIVE" label
- Locked mech (苍穹号 pre-inheritance): grayed out, "LOCKED" label
- Hover effects on cards / slots / buttons
- Keyboard navigation: Tab cycles focus, Enter selects
- Gamepad support: D-pad to navigate, A to select (per `.claude/rules/ui-code.md`)

---

## Code Patterns to Reuse (from existing codebase)

| Pattern | Existing location | Reuse for S7-007 |
|--------|-------------------|------------------|
| Modal UI | `pause_menu.gd` | Same: full-rect ColorRect + VBoxContainer |
| Localization | `Localization.t(&"ui.<key>")` | Required for all text per UI rules |
| Input handling | `pause_menu.gd` `_input` | Same: M key toggle |
| Events/commands pattern | (new) | New pattern, but follows `.claude/rules/ui-code.md` |
| Save/load producer | `save_manager.gd` | Already in S7-002/003/010 — no new producer needed |

## Risks Specific to S7-007

1. **The UI is large** (3 mechs visible at once, 3-4 weapons, 3 pilots). Risk of clutter.
   - **Mitigation**: Use a clean grid layout. Card-based design. Generous spacing. Per UI rules, "Test all screens at minimum and maximum supported resolutions."

2. **The "auto-swap pilot" behavior** might confuse the player. If Pilot A is swapped from Mech X to Mech Y, and Pilot B was driving Y, the player might not realize B is now on X.
   - **Mitigation**: Show a clear "Pilot A: Mech X → Mech Y. Pilot B: Mech Y → Mech X" message. Animate the swap.

3. **Drag-and-drop for weapon moving** is complex in Godot. The click-to-select + click-to-place alternative is simpler.
   - **Mitigation**: Implement click-to-select first (simpler). Drag-and-drop is a future enhancement.

4. **M key conflict with existing input**: Need to verify M is not already used.
   - **Mitigation**: Check `project.godot` input map. M is currently unassigned.

5. **The Mech Bay is a 4th menu** alongside Pause / Codex / Save. The main menu hierarchy is getting complex.
   - **Mitigation**: From the main menu, add "Mech Bay" as a top-level item. From the pause menu, add "Mech Bay" as a sub-item.

## Out of Scope (for S7-007 only)

- Mech comparison tooltips (S7-022 — Nice-to-Have)
- Pilot ability description tooltips (S7-013 — Should-Have)
- Mech skin / cosmetic selection (deferred)
- Voice acting (deferred)

## Acceptance Test (Manual F5 Verification)

1. Start a new game, F5. Recruit 霜尾 (Ch4 mid).
2. Press **M** — Mech Bay opens. Shows 3 mech cards (ranger / frostbite / bomber), 苍穹号 locked.
3. **Verify**: Active mech is ranger (default).
4. Click the frostbite card. **Verify**: Active mech is now frostbite. The weapons panel shows frostbite's weapons.
5. Click the pilot button for 轰天. **Verify**: 轰天 is assigned to the active mech. The other 2 pilots are unassigned.
6. Move a weapon from ranger's slot 1 to frostbite's slot 2. **Verify**: Both mechs' inventories update.
7. Click the "swap pilot" action (auto-swap). **Verify**: Pilots are swapped. A message shows the swap.
8. Save the game. Quit. Reload. **Verify**: All assignments are preserved.
9. Open the Mech Bay during combat (during the player's turn). **Verify**: The Mech Bay opens, but the game is paused.
10. Close the Mech Bay. **Verify**: Combat resumes.

If all 10 steps work, S7-007 is complete.
