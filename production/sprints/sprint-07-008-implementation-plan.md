# S7-008 Implementation Plan — 苍穹号 Inheritance Scene (Ch13)

> **Sprint 7 Story**: S7-008 (1.5 days, godot-gdscript-specialist + writer)
> **Depends on**: S7-001 (BattleState.party_mechs) + S7-003 (4-mech roster with unlock_cangqiong())
> **Goal**: Implement the **7-beat cutscene** for inheriting the 苍穹号 mech, per `party-system.md` §3.3. The cutscene triggers in Ch13 Room 9 (or via a debug command in Sprint 7 for testing). After the cutscene, 苍穹号 is added to the player's 4-mech roster, the Creator Receiver is integrated, and the player's mech roster is now fully unlocked.

## Current State (Baseline)

- **No cutscene system exists**. There is no dedicated cutscene infrastructure.
- **Existing animations use Tween** (in `battle_scene.gd` damage popup + camera shake) — the pattern is `create_tween()` + `tween_property()` + `tween_callback()`.
- **No 苍穹号 inheritance mechanism** — `MechLoadout._cangqiong_unlocked = false` is the only state.
- **No 苍穹号 mech resource** — the 4 unique weapons (`cangqiong_cannon`, `light_blade`, `signal_jammer`, `creator_receiver`) don't exist yet.

## Target State (After S7-008)

- **CangqiongInheritance** cutscene script (1 new file, 280 lines)
- **7-beat cutscene** plays in Ch13 Room 9 (or via debug command in Sprint 7)
- **苍穹号** is unlocked and added to the player's 4-mech roster
- **Creator Receiver** is integrated (per `party-system.md` §3.6)
- **Final state**: player has 4 mechs (Ranger / Frostbite / Bomber / Cangqiong), 12 weapons (3-4 per mech)
- **Save**: the cangqiong_unlocked flag is persisted

## File Changes (Summary)

| File | Lines added | Lines removed | Net |
|------|-------------|---------------|-------|
| `src/cutscene/cangqiong_inheritance.gd` (NEW) | +280 | 0 | +280 |
| `src/autoload/mech_loadout.gd` (S7-003) | +20 | 0 | +20 |
| `src/autoload/weapon_loadout.gd` (S7-002) | +20 | 0 | +20 |
| `src/resource/weapon_data.gd` | +30 | 0 | +30 |
| `data/weapons/cangqiong_*.tres` (4 NEW) | +60 | 0 | +60 |
| `tests/integration/fc66_cangqiong_inheritance_test.gd` (NEW) | +70 | 0 | +70 |

**Total**: ~480 lines added, 0 removed. **Net: +480 lines** across 6 files.

---

## Sub-Task Breakdown (Days 1-1.5)

### Day 1 Morning: Weapon Data + CangqiongInheritance Skeleton

**Sub-task 1.1: Extend `weapon_data.gd` with 苍穹号-specific fields** (0.25 day)

```gdscript
# src/resource/weapon_data.gd (additions)
class_name WeaponData
extends Resource

# Existing fields...
@export var id: StringName
@export var display_name: String
# ... etc

# NEW: cangqiong-locked weapons
@export var is_cangqiong_unique: bool = false
@export var requires_pilot: StringName = &""  # empty = any pilot
@export var passive_effect: StringName = &""  # e.g., "creator_dialogue", "truth_vision"
```

**Sub-task 1.2: Create 4 苍穹号 weapon .tres files** (0.5 day)

| File | Weapon | Stats | Special |
|------|--------|-------|---------|
| `cangqiong_cannon.tres` | 苍穹炮 | 200-300 damage, long-range | Devastating single-target |
| `cangqiong_light_blade.tres` | 光刃 | 80-120 damage, 1x3 line | Hits all enemies in a row |
| `cangqiong_signal_jammer.tres` | 信号干扰器 | 50-80 damage, AOE | Disables enemy abilities for 2 turns |
| `cangqiong_creator_receiver.tres` | 造物者信号接收器 | 0 damage (utility) | Reveals hidden truths; required for True Ending A |

Each has `is_cangqiong_unique = true` and (for the receiver) `requires_pilot = "ranger"`.

**Sub-task 1.3: Create `src/cutscene/cangqiong_inheritance.gd` skeleton** (0.25 day)

```gdscript
# src/cutscene/cangqiong_inheritance.gd
extends Control

# Visual elements (created in _ready)
var _bg: ColorRect
var _stage: Node2D  # 2D stage where mechs appear
var _label: Label
var _continue_prompt: Label

# State
enum Beat {
    FIND_COCKPIT,       # 1
    SEE_PILOT_BODY,     # 2
    READ_LETTER,        # 3
    PARTY_MOURNS,       # 4
    MECH_POWERON,       # 5
    BOND_TO_RANGER,     # 6
    RECEIVE_MECH,       # 7
    COMPLETE,           # 8 (end state)
}
var _current_beat: int = Beat.FIND_COCKPIT
var _timer: SceneTreeTimer

# Timing (per party-system.md §3.3)
const BEAT_DURATIONS := {
    Beat.FIND_COCKPIT: 4.0,    # "party finds 苍穹号's destroyed cockpit"
    Beat.SEE_PILOT_BODY: 3.0,  # "苍穹号's body is visible, with a final letter"
    Beat.READ_LETTER: 5.0,     # "letter is read (text overlay)"
    Beat.PARTY_MOURNS: 2.0,    # "party mourns briefly"
    Beat.MECH_POWERON: 3.0,    # "苍穹号 mech power-on sequence"
    Beat.BOND_TO_RANGER: 3.0,  # "mech bonds to 漫游者"
    Beat.RECEIVE_MECH: 3.0,    # "party receives 苍穹号"
}
const TOTAL_DURATION := 23.0  # ~23 seconds for full cutscene

signal cutscene_finished

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_preset(Control.PRESET_FULL_RECT)
    _build_ui()
    hide()

func _build_ui() -> void:
    # ... builds the visual stage
    pass

func start() -> void:
    show()
    _current_beat = Beat.FIND_COCKPIT
    _advance_beat()

func _advance_beat() -> void:
    if _current_beat > Beat.RECEIVE_MECH:
        _complete_cutscene()
        return
    # Show beat content
    _show_beat_content(_current_beat)
    # Wait for the beat duration, then advance
    var duration: float = BEAT_DURATIONS[_current_beat]
    _timer = get_tree().create_timer(duration)
    _timer.timeout.connect(_on_beat_complete)

func _on_beat_complete() -> void:
    _current_beat += 1
    _advance_beat()

func _show_beat_content(beat: int) -> void:
    match beat:
        Beat.FIND_COCKPIT:
            _show_find_cockpit()
        Beat.SEE_PILOT_BODY:
            _show_pilot_body()
        # ... etc
```

### Day 1 Afternoon: 7 Beat Implementations

**Sub-task 1.4: Beat 1 — "Find the cockpit"** (0.1 day)

Show a wide shot of a destroyed mech bay. The 苍穹号 mech's cockpit is visible (smoke, broken glass). A soft amber light emanates from inside.

Implementation: a `ColorRect` background with a 苍穹号 sprite (64×64 or larger) in the center. Tween the cockpit to a low opacity (broken/destroyed feel).

```gdscript
func _show_find_cockpit() -> void:
    _label.text = "[Ch13 — The Cockpit]"
    # Display 苍穹号 sprite at center, dimmed
    _cangqiong_sprite.modulate = Color(0.5, 0.5, 0.5, 0.7)  # dim
    _cangqiong_sprite.position = Vector2(640, 400)  # center
```

**Sub-task 1.5: Beat 2 — "See the pilot's body"** (0.1 day)

Camera pans down to reveal 苍穹号's body (a human mech pilot, weathered, deceased). The 4 unique weapons are visible at his sides.

Implementation: a "pilot body" sprite (procedurally generated if no asset) + 4 weapon sprites around it.

**Sub-task 1.6: Beat 3 — "Read the letter"** (0.25 day)

A text overlay fades in, displaying 苍穹号's final letter. The letter is short (4-6 sentences) and tragic.

```gdscript
const FINAL_LETTER := """To whoever finds this,

I was the first to hear the signal. I tried to warn them. They didn't listen.
I followed the signal to Sat-5. I saw what was waiting.
The Creator is not a god. It is a question. And we are the answer it fears.

I am leaving this mech to the one who comes after. The receiver code is yours now.
You will need it. When the time comes, you will need to speak — not fight.

The cycle has run for 50 years. It will run for 50 more, unless someone breaks it.
Be that someone.

— 苍穹号 (Azure Sky)"""
```

**Sub-task 1.7: Beat 4 — "Party mourns"** (0.1 day)

2 seconds of silence. The 3 party members (Frostbite, Bomber, Ranger) are visible in silhouette, heads bowed. No text.

**Sub-task 1.8: Beat 5 — "Mech power-on"** (0.25 day)

The 苍穹号 mech glows golden. A power-on sequence: lights flicker, screens boot, engines hum. The 4 unique weapons float toward the mech and attach to its slots.

```gdscript
func _show_mech_poweron() -> void:
    # 苍穹号 becomes brighter
    var tween: Tween = create_tween()
    tween.tween_property(_cangqiong_sprite, "modulate", Color(2.0, 1.8, 0.5, 1.0), 2.0)
    # 4 weapons fly from corners to mech
    for i in 4:
        var weapon_sprite: Sprite2D = _weapon_sprites[i]
        var tween2: Tween = create_tween()
        tween2.set_parallel(true)
        tween2.tween_property(weapon_sprite, "position", Vector2(640, 400), 1.5).set_delay(0.5 + i * 0.2)
        tween2.tween_property(weapon_sprite, "modulate:a", 0.0, 0.5).set_delay(2.0)
```

**Sub-task 1.9: Beat 6 — "Bond to Ranger"** (0.15 day)

The Creator Receiver code (carried by 漫游者 since Ch1) activates. A beam of light connects 漫游号 (the Ranger's mech) to 苍穹号. The bond is established.

```gdscript
func _show_bond_to_ranger() -> void:
    # Show a beam from 漫游号 to 苍穹号
    _bond_beam.visible = true
    var tween: Tween = create_tween()
    tween.tween_property(_bond_beam, "modulate:a", 1.0, 1.0)
    tween.tween_property(_bond_beam, "modulate:a", 0.0, 1.0)
    # Text: "The bond is established."
    _label.text = "The bond is established."
```

**Sub-task 1.10: Beat 7 — "Receive mech"** (0.15 day)

The cutscene ends with a summary: "苍穹号 is now in your roster." A "Continue" button appears.

### Day 1.5: MechLoadout + WeaponLoadout Updates

**Sub-task 1.11: Hook into `MechLoadout.unlock_cangqiong()`** (0.25 day)

After the cutscene, call:

```gdscript
# In cangqiong_inheritance.gd, in _complete_cutscene
func _complete_cutscene() -> void:
    var loadout: Node = get_node("/root/MechLoadout")
    loadout.unlock_cangqiong()  # adds 苍穹号 to roster, max_weapon_slots = 4
    var weapons: Node = get_node("/root/WeaponLoadout")
    weapons.register_mech(&"cangqiong", 4)  # 4 weapon slots for 苍穹号
    # Equip the 4 default weapons
    for i in 4:
        var weapon_id: StringName = [&"cangqiong_cannon", &"cangqiong_light_blade", &"cangqiong_signal_jammer", &"cangqiong_creator_receiver"][i]
        weapons.equip_weapon_to_mech(&"cangqiong", i, weapon_id)
    _show_continue_prompt()
    cutscene_finished.emit()
```

**Sub-task 1.12: Add a debug command for Sprint 7 testing** (0.1 day)

```gdscript
# In cangqiong_inheritance.gd
func start_debug() -> void:
    # For Sprint 7 testing: triggers the cutscene immediately
    start()
```

The debug command is called from a hidden test trigger (e.g., pressing a key combination in the existing pause menu).

### Day 1.5: Tests + Polish

**Sub-task 1.13: Tests fc66_cangqiong_inheritance_test.gd** (0.5 day)

5 tests:
- 1) Starting the cutscene shows Beat 1
- 2) Advancing through all 7 beats takes ~23 seconds
- 3) After the cutscene, 苍穹号 is in the roster (4 mechs)
- 4) After the cutscene, 苍穹号 has 4 weapons equipped
- 5) Save/Load roundtrip preserves cangqiong_unlocked flag

**Sub-task 1.14: Polish + edge cases** (0.25 day)

- Skip button: player can press SPACE to skip the cutscene (skips to Beat 7 immediately)
- Audio: play a custom BGM for the cutscene (a soft, somber piece)
- Subtitle: all text in the cutscene is localized (EN + ZH)
- Edge case: if the player starts the cutscene while 苍穹号 is already unlocked, show "Already inherited" message and exit immediately

---

## Code Patterns to Reuse (from existing codebase)

| Pattern | Existing location | Reuse for S7-008 |
|--------|-------------------|------------------|
| Tween animations | `battle_scene.gd` `_shake_camera` | Same pattern for mech power-on, beam |
| Localization | `Localization.t(&"key")` | All cutscene text |
| Resource loading | `ResourceRegistry.get_resource()` | 苍穹号 weapons |
| Save producer | `MechLoadout.get_state_snapshot()` | `cangqiong_unlocked` flag in save |

## Risks Specific to S7-008

1. **The 7-beat cutscene is 23 seconds** — long for a JRPG. Risk of player boredom.
   - **Mitigation**: Add the **skip button** (SPACE). Allow player to skip the cutscene entirely.

2. **The "letter" text (Beat 3) is heavy** — 6 sentences of exposition. Risk of player reading fatigue.
   - **Mitigation**: Use a typewriter effect (text appears one character at a time). Allow player to press SPACE to skip the typewriter.

3. **The 4 苍穹号 weapons don't exist yet** — S7-002 will define the WeaponData schema, but the actual .tres for 苍穹号 weapons are new.
   - **Mitigation**: S7-008 creates 4 new .tres for the 苍穹号 weapons. They're not in the existing Ch1/Ch2 weapon roster.

4. **The cutscene triggers in Ch13, but Ch13 doesn't exist yet in the codebase**. Sprint 7's cangqiong_inheritance is essentially "dead code" until Sprint 10 ships Ch13.
   - **Mitigation**: Provide the debug command (`start_debug()`) so the cutscene can be tested in Sprint 7. Sprint 10 will integrate the real trigger in Ch13 Room 9.

5. **The cutscene is single-use** (苍穹号 is inherited once). If the player loads a save from before the cutscene, they should be able to replay it.
   - **Mitigation**: The `cangqiong_unlocked` flag is saved. If the flag is false, the cutscene can be triggered. If true, the trigger is suppressed.

## Out of Scope (for S7-008 only)

- The 4 weapons' detailed stats / sprites (S7-002's per-mech data model handles this)
- The Ch13 actual content (Sprint 10)
- The 4 ending cutscenes (Sprint 10)
- The Creator chamber dialogue (Sprint 10)
- Voice acting

## Acceptance Test (Manual F5 Verification)

1. Start a new game, F5. (苍穹号 is locked.)
2. Press the debug command (S7-008's start_debug, triggered via a key combination).
3. **Verify**: The 7-beat cutscene plays. Each beat has a distinct visual.
4. Watch the full 23-second cutscene. The text in Beat 3 (the letter) is readable.
5. After the cutscene, press SPACE to skip (or wait for it to finish).
6. **Verify**: 苍穹号 is now in the roster. Open the Mech Bay (S7-007) — 4 mechs are visible.
7. Click on 苍穹号. **Verify**: 4 weapon slots are visible (vs 3 for other mechs).
8. Save the game. Quit. Reload.
9. **Verify**: 苍穹号 is still in the roster (save preserves the cangqiong_unlocked flag).
10. Try to trigger the cutscene again. **Verify**: It says "Already inherited" and exits.

If all 10 steps work, S7-008 is complete.
