# Interaction Pattern Library (interaction-patterns)

> **Scope**: Railhunter MVP — reusable interaction patterns for all UI/HUD/screen implementations
> **Audience**: UI programmers + ux designers + programmers implementing GDDs
> **Status**: Active — v1.0, 2026-06-12
> **Reference**: per `architecture.md` §3e, `design/gdd/player-input.md`, `design/gdd/hud.md`

## Purpose

This document is the **canonical pattern catalog** for Railhunter interactions. When implementing a new screen, menu, or HUD widget, find the pattern below and use it. **Don't invent new patterns** unless the existing one doesn't fit — that signals a missing pattern, which should be added to this doc (not invented ad-hoc).

Patterns are organized by **interaction context** (where the pattern applies).

---

## 1. Movement Patterns

### 1.1 Four-Direction Movement (Keyboard)

**When**: Exploration (per `#15 Level/Dungeon`)

| Aspect | Spec |
|--------|------|
| Keys | WASD or Arrow keys (both work, configurable in `input-bindings.yaml`) |
| Action names | `move_up`, `move_down`, `move_left`, `move_right` (per ADR-0009) |
| Diagonals | Allowed (Input.get_vector handles) |
| Acceleration | None (instant start, instant stop) — pixel-art games don't want acceleration |
| Dead zone | 24 px (per `#4 Camera` F4) |
| Reference | `player-input.md` C-R1, `#4 Camera` AC-4 |

```gdscript
# Pseudocode
func _process(_delta):
    if not is_paused():
        var dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
        velocity = dir * MOVE_SPEED
        move_and_slide()
```

### 1.2 Dash (Keyboard)

**When**: Exploration, with cooldowns

| Aspect | Spec |
|--------|------|
| Key | Shift (modifier) |
| Action | `dash` (with movement direction) |
| Duration | 8 active frames (per player-input.md F3) |
| I-frames | 6 frames during dash |
| Cooldown | 600 ms |
| Visual | Brief white trail sprite |
| Reference | `player-input.md` F3 + `#7 Battle Core` F3 |

### 1.3 Gamepad Movement (Partial)

**When**: Gamepad connected (per `technical-preferences.md` "Gamepad Support: Partial")

| Aspect | Spec |
|--------|------|
| Input | Left stick or D-pad (both work) |
| Dead zone | 0.20 (per ADR-0009 + control-manifest) |
| Reference | `input-bindings.yaml` + `player-input.md` UI-4 |

---

## 2. Combat Patterns

### 2.1 1/2/3 Weapon Switch (with Immediate Attack)

**When**: BATTLE state, manual mode, PLAYER_INPUT phase

| Aspect | Spec |
|--------|------|
| Keys | `1`, `2`, `3` (or D-pad L/R) |
| Action | Selects weapon slot AND attacks immediately (no spacebar confirmation) |
| Reason | Per prototype learning (per `prototypes/暗雷回合制战斗-concept/README.md` "1/2/3 选武器 + 立即攻击") |
| Visual | Weapon slot pulse, damage number flies |
| Reference | `#7 Battle Core` C-R3, `player-input.md` AC-4/5 |

```gdscript
# Pseudocode — Press 1/2/3:
func _on_weapon_slot_pressed(slot: int):
    weapon_loadout.set_slot(slot)
    if current_mode == "manual" and turn_phase == "PLAYER_INPUT":
        perform_player_action()  # immediately attack
```

### 2.2 Q/E Ammo Cycle (Free Action)

**When**: BATTLE state, anytime (does NOT consume turn)

| Aspect | Spec |
|--------|------|
| Keys | `Q` (cycle down) / `E` (cycle up) |
| Action | Cycles current ammo (no turn consumption) |
| Visual | HUD ammo icon updates immediately, build damage preview updates |
| Reference | `#7 Battle Core` C-R2, `player-input.md` AC-3 |

### 2.3 D Defend (50% Reduction)

**When**: BATTLE state, manual mode, PLAYER_INPUT phase

| Aspect | Spec |
|--------|------|
| Key | `D` |
| Action | Sets `defending = true` for next enemy attack (consumes turn) |
| Effect | Damage × 0.5 once, then `defending = false` |
| Visual | Mech turns blue 0.2s |
| Reference | `prototype battle_prototype.gd` lines 141-148, `#7 Battle Core` C-R8 |

### 2.4 A Mode Toggle (Mid-Battle)

**When**: BATTLE state, anytime (does NOT consume turn)

| Aspect | Spec |
|--------|------|
| Key | `A` |
| Action | Toggle MANUAL ↔ AUTO |
| Visual | Mode badge pulse 0.15s (per `#2 G-F2`) |
| Auto AI priority | HP ≤ 30% → use repair_kit; lethal attack → defend; else highest final_damage + weakness match (per `#7 C-R5`) |
| Reference | `#7 Battle Core` C-R4 + C-R5 |

### 2.5 ESC Cancel (Combat, NOT Exit)

**When**: BATTLE state

| Aspect | Spec |
|--------|------|
| Key | `Esc` |
| Action | Cancel current target selection (NOT exit battle) |
| Reason | Per `player-input.md` Blk #1 fix — prevent accidental exit |
| Visual | Brief "ESC = cancel target" hint |
| Reference | `player-input.md` AC-25 |

---

## 3. Menu Patterns

### 3.1 Stack-Based Modal (Push/Pop)

**When**: Opening any modal overlay (Menu, Codex, Terminal, Pause)

| Aspect | Spec |
|--------|------|
| Action | `GameStateMachine.push(STATE, payload)` |
| Stack | Lower states are FROZEN (not destroyed) — per `#3 C-R2` |
| Exit | `pop()` returns to top of stack (per `#3 C-R4`) |
| Visual | 0.4s fade-black (per `#4` FADE_BLACK), 0.6s zoom on terminals (per `#4` ZOOM) |
| Reference | `#3 Game State Machine` C-R2/C-R4 |

```gdscript
# Pseudocode
func open_menu():
    GameStateMachine.push(MENU)
    get_tree().paused = true  # only for PAUSE state

func close_menu():
    GameStateMachine.pop()
```

### 3.2 Focus Chain (Keyboard)

**When**: Any menu with interactive elements

| Aspect | Spec |
|--------|------|
| Initial focus | First focusable element receives focus immediately (per `#2 UI-1`) |
| Visible focus | Pulse animation (default), outline, or glow (configurable per `#2 G3`) |
| Navigation | D-pad/arrow keys (per `#2 G-F5`) |
| D-pad wrap | Last element → first element (per `#2 AC-25`) |
| Reference | `player-input.md` UI-1, AC-24, AC-25 |

### 3.3 "Press E to Interact" Hint

**When**: Player within 32px of INTERACTABLE object (door, terminal, NPC, pickup)

| Aspect | Spec |
|--------|------|
| Trigger | `entity_near_interactable` signal from `#5` Collision |
| Visual | Hint label near player mech (not at fixed position, per `#5` F3) |
| Minimum display | 200 ms (anti-flicker, per `#5` F4) |
| Multiple interactables | Show nearest one only |
| Reference | `#5 Collision` F3 + F4, `#2` UI requirements |

### 3.4 Pause Overlay (Q in BATTLE, Esc in EXPLORATION)

**When**: Pressing pause key in any state

| Aspect | Spec |
|--------|------|
| Action | `GameStateMachine.push(PAUSE)` (per `#3` legal transitions) |
| Effect | `get_tree().paused = true` (freezes `_process`/`_physics_process`) |
| Visual | Screen dim 50% + 0.15s fade-in + pause icon (per `#4`) |
| Underlying state | Frozen but not destroyed |
| Unpause | `pop()` returns to prior state |
| Reference | `#3 C-R2`, `#3 C-R5` |

---

## 4. State Badge Patterns

### 4.1 Always-Visible State Badge

**When**: Always (per `#2 UI-2b` and ADR-0009)

| Aspect | Spec |
|--------|------|
| Position | Top-left of HUD, fixed (per `hud.md` C-R3) |
| Content | State name (e.g., `EXPLORATION`, `BATTLE`, `MENU`) |
| Companion | In BATTLE, MANUAL/AUTO sub-indicator adjacent |
| Visibility | **Never hidden** — even during fullscreen overlays |
| Reference | `player-input.md` UI-2b, AC-4, AC-19 |

### 4.2 Mode Badge (MANUAL/AUTO) Adjacent to State

**When**: BATTLE state only

| Aspect | Spec |
|--------|------|
| Position | Top-left, adjacent to state badge |
| Content | `MANUAL` (orange) or `AUTO` (cyan) |
| Animation | Scale-pulse 0.15s on toggle (per `#2 G-F2`) |
| Visual cue | Color + text (per colorblind safety) |
| Reference | `hud.md` Visual/Audio table |

### 4.3 Phase Indicator (PLAYER_INPUT / ENEMY_INPUT)

**When**: BATTLE state

| Aspect | Spec |
|--------|------|
| Position | Bottom of screen (per `hud.md`) |
| Content | `PLAYER_INPUT` / `ENEMY_INPUT` / `ENEMY_ACTION` etc. |
| Audio | Distinct sound per phase |
| Reference | `hud.md` UI-1 |

---

## 5. Notification Patterns

### 5.1 Toast Notifications (1.5s)

**When**: Autosave, manual save, save success/failure

| Aspect | Spec |
|--------|------|
| Position | Top-right of HUD |
| Duration | 1500 ms |
| Type | Success (green) / Failure (red) |
| Reference | `hud.md` Visual/Audio, `save-load.md` UI Requirements |

```gdscript
# Pseudocode
func show_toast(message: String, is_error: bool = false):
    var toast = ToastLabel.instantiate()
    toast.text = message
    toast.modulate = Color.RED if is_error else Color.GREEN
    $ToastContainer.add_child(toast)
    await get_tree().create_timer(1.5).timeout
    toast.queue_free()
```

### 5.2 Floating Damage Numbers (0.5s)

**When**: Hit lands

| Aspect | Spec |
|--------|------|
| Position | Above target (start) → 50 px up over 0.5s (per `hud.md` F2) |
| Opacity | 1.0 → 0 over 0.5s |
| Color | Normal (white) / Crit (yellow) / Weakness (red) / Defense (cyan) |
| Reference | `hud.md` F2 + Visual/Audio table |

### 5.3 Pickup Prompt (4 options)

**When**: Encounter loot dropped, pickup entered

| Aspect | Spec |
|--------|------|
| Position | Center screen |
| Content | 4 options: "Equip" / "Inventory" / "Discard" / "Cancel" |
| Default | `[1] Equip` if slot empty, else `[2] Inventory` |
| Timeout | 0.5s (default behavior on timeout: Inventory) |
| Reference | `#11+#12 Weapon & Ammo` F4 |

---

## 6. Boss / Special Patterns

### 6.1 Boss One-Shot Immunity Feedback

**When**: Boss with `boss_immune_to_one_shot=true` survives a high-damage hit

| Aspect | Spec |
|--------|------|
| Visual | Damage number 199 (clamped) + 1 HP boss bar + "BOSS SURVIVED" text |
| Audio | Boss takes a hit sound (NOT boss defeat sound) |
| Reference | ADR-0011 + AC-16 (battle-core-loop.md) |

### 6.2 Encounter Trigger (0.4s Fade)

**When**: Player walks onto ENCOUNTER tile

| Aspect | Spec |
|--------|------|
| Sequence | 0.4s fade to black + battle scene fade in (per `#4` FADE_BLACK) |
| Audio | "Encounter" warning chirp (short) |
| Reference | `#16 Random Encounter` AC-1 |

### 6.3 Chapter End (Chapter Summary Screen)

**When**: Player completes a chapter

| Aspect | Spec |
|--------|------|
| Content | Completion % (rooms + rewards + fragments) + weapon library + progress |
| Duration | Manual dismiss (player presses confirm) |
| Reference | `#15 Level/Dungeon` UI Requirements, `#17 HUD` C-R8 |

---

## 7. Camera Patterns (per `#4 Camera`)

### 7.1 Exploration Follow

| Aspect | Spec |
|--------|------|
| Follow target | Player mech (per `camera.md` RIG_EXPLORATION_FOLLOW) |
| Lerp factor | 0.10 (per F2) |
| Dead zone | 24 px (per F4) |

### 7.2 Battle Fixed Overhead

| Aspect | Spec |
|--------|------|
| Position | Fixed (no follow) |
| Zoom | 1.2× (slight zoom-in for clarity) |
| Reference | `camera.md` RIG_BATTLE_OVERHEAD |

### 7.3 Shake on Hit

| Aspect | Spec |
|--------|------|
| Trigger | Hit landed (any damage) |
| Duration | 100-150 ms (per F1) |
| Magnitude | 4-12 px (per F1) |
| UI follow | UI shakes at 0.5× magnitude (per `camera.md` C-R2) |
| Reference | `camera.md` C-R2 + F1 |

---

## 8. Input Anti-Patterns (NEVER do these)

| Anti-pattern | Why wrong | Correct alternative |
|--------------|-----------|---------------------|
| 1/2/3 + "press SPACE to confirm" | Per prototype learning: unnecessary friction | 1/2/3 = select + attack (no spacebar) |
| Hold Esc to exit BATTLE | Per `player-input.md` Blk #1 fix: prevents accidental exit | Esc = cancel target (not exit) |
| Q/E as primary ammo (not modifier) | Q/E is in pause/keybind cluster; per Blk #1 fix: Q = pause_battle | Cycle ammo via gamepad or modifier+Q |
| Mouse-only menu navigation | Per `player-input.md` AC-24 | D-pad/arrow keys + A/Enter for all |
| Click target < 32×32 px | No precision mouse | All interactive elements ≥ 32×32 px |
| Simultaneous 2-key combo required | Motor accessibility | No combos (modifiers OK) |
| Audio-only critical cue | Deaf players miss it | Every sound has visual equivalent |
| Color-only status indication | Colorblind players miss it | Color + text or shape |
| No "no weapon in slot" feedback | Confusing silent failure | Always show refused feedback (per `#2 F2`) |
| Forced timed input | Motor + cognitive | No timed inputs in MVP (hold-to-skip is OK with visual progress) |

---

## 9. Cross-References

| Pattern | Reference ADR/GDD |
|---------|-------------------|
| Autoload order | ADR-0001 Scene Management |
| Signal naming | ADR-0002 Event Architecture |
| Save/load contract | ADR-0003 Save Contract + ADR-0004 Save I/O + ADR-0005 Save Upgrade |
| Engine version | ADR-0006 Engine Version Pin |
| Resource immutability | ADR-0007 Resource Immutability |
| 47 actions | ADR-0009 Input Binding |
| TileMap vs TileMapLayer | ADR-0010 TileMap Usage |
| Damage bounds | ADR-0011 Damage Bounds |
| HUD elements | `hud.md` |
| State transitions | `#3 Game State Machine` |
| Camera rigs | `#4 Camera` |
| Encounter flow | `#16 Random Encounter` |
| NPC dialogue | `#18 NPC/Terminal` |
| Save/load | `#21 Save/Load` |
| Combat math | `#7 Battle Core Loop` |

---

## 10. How to Use This Catalog

1. **Before designing a new screen/UI**: search this doc for similar patterns. Reuse the pattern, don't reinvent.
2. **If a new pattern emerges** (e.g., new screen type, new interaction): add it to this doc with full spec + reference to GDD/ADR. Don't invent ad-hoc in code.
3. **If existing pattern doesn't fit**: document the gap in the GDD's Open Questions; don't silently fork.
4. **Cross-cutting patterns** (named signals, payload schemas): defined in ADR-0002 + per-system GDDs. Reuse those exactly.

## Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-06-12 | Initial pattern library (8 categories, 25+ patterns) |
