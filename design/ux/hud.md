# HUD UX Spec (hud)

> **Status**: Draft v0.1 (2026-06-13)
> **Author**: ux-designer
> **GDD**: design/gdd/hud.md
> **Patterns**: design/ux/interaction-patterns.md

## Overview

The HUD is a persistent overlay visible during exploration and battle. It provides at-a-glance status: HP, mech part status, current weapon/ammo, mode indicator, encounter count, story fragment count, and current state. The HUD is non-interactive (display-only); controls are always available via keyboard. The HUD is rendered as a CanvasLayer with a `Control` root that fills the viewport (anchor 0,0 to 1,1, mouse_filter = 2 = ignore).

## Player Fantasy

The player should feel **informed without being overwhelmed**. The HUD shows what they need, when they need it, and never blocks the action. Pillar: Pillar 1 (Player-Designed Honesty) — every visible value is a truthful representation of game state.

## Detailed Design

### Layout (1280x720 viewport)

```
+-------------------------------------------------------+
| [STATE: EXPLORING]            [FRAGMENTS: 3/12]       |  ← top bar
|                                                       |
|  +----+  +----+  +----+        +-------------------+  |
|  | W1 |  | W2 |  | W3 |        | MODE: [MANUAL]    |  |  ← weapon slots
|  +----+  +----+  +----+        | HP: ████░ 80/100  |  |
|   ↑ active                       +-------------------+  |
|                                                       |
|                (game world renders here)              |
|                                                       |
+-------------------------------------------------------+
```

### Widgets (top to bottom, left to right)

1. **State badge** (top-left): Current `GameStateMachine.top_of_stack` (e.g., "EXPLORING", "IN BATTLE", "PAUSED"). Color: cyan for exploration, red for battle, yellow for menu/paused.
2. **Fragment counter** (top-right): `MetaState.unlocked_story_fragments.size() / total_in_region`. Format: "FRAGMENTS: 3/12".
3. **Weapon slots** (bottom-left, 64x64 each): Three slots. Active slot is highlighted (yellow border, 1.5x scale). Press 1/2/3 to switch.
4. **Mode indicator** (bottom-right): "MANUAL" or "AUTO". Press M to toggle (battle only).
5. **HP bar** (bottom-right, above mode): Total player HP / max. Color: green > 50%, yellow 25-50%, red < 25%.

### States and Transitions

- **EXPLORATION**: Weapon slots visible, mode indicator hidden (mode is battle-only)
- **BATTLE**: Mode indicator visible, weapon slots highlight on press, HP bar pulses on damage
- **MENU/PAUSE**: HUD dimmed (50% opacity), state badge shows "PAUSED"
- **GAME OVER**: HP bar at 0% with red flash; state badge "GAME OVER"

### Interactions with Other Systems

- Reads `GameStateMachine.top_of_stack` for state badge
- Reads `WeaponLoadout.active_slot` + `WeaponLoadout.weapon_slots` for slot highlight
- Reads `MetaState` for fragment count
- Reads `PlayerController.max_hp` + `current_hp` for HP bar
- Reads `BattleCore.mode` for MANUAL/AUTO indicator

## Formulas

- HP bar fill: `fill_ratio = current_hp / max_hp` (clamped [0, 1])
- Weapon slot scale: `1.0` if inactive, `1.5` if active (lerp 0.1s on switch)
- HUD dim: `opacity = 1.0` in play, `0.5` in menu/pause (lerp 0.15s)

## Edge Cases

- **No weapon equipped**: Show "EMPTY" text in slot, no scale highlight
- **Max HP = 0** (game over state): HP bar flashes red at 30% opacity
- **State transitions during animation**: Animate to new layout immediately (no queue)
- **Multiple state badges in stack** (e.g., DIALOGUE pushed on top of EXPLORATION): show `top_of_stack` only

## Dependencies

- `GameStateMachine` (autoload) — state badge
- `WeaponLoadout` (autoload) — weapon slots
- `MetaState` (autoload) — fragment counter
- `PlayerController` (scene) — HP
- `BattleCore` (autoload) — mode indicator

## Tuning Knobs

- HUD opacity in menu: 0.5 (default), range [0.3, 0.7]
- HP bar colors: green/yellow/red thresholds (50%, 25% default)
- Weapon slot scale on active: 1.5x (default), range [1.2x, 2.0x]
- HP bar pulse duration on damage: 0.3s (default), range [0.1s, 0.5s]

## Acceptance Criteria

- [ ] HUD shows state badge, fragment counter, weapon slots, mode indicator, HP bar
- [ ] Active weapon slot is highlighted
- [ ] State badge updates within 1 frame of state change
- [ ] HUD does not block mouse input (`mouse_filter = 2`)
- [ ] HUD dim animates smoothly on state change
- [ ] HUD is keyboard-navigable (no hover-only interactions — per accessibility-requirements.md)
- [ ] Color choices respect colorblind safety per interaction-patterns.md
