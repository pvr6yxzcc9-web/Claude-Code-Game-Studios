# Pause Menu UX Spec (pause-menu)

> **Status**: Draft v0.1 (2026-06-13)
> **Author**: ux-designer
> **GDD**: design/gdd/game-state-machine.md (state_menu), design/gdd/save-load.md
> **Patterns**: design/ux/interaction-patterns.md

## Overview

The Pause Menu appears when the player presses Esc during exploration or battle. It pauses the game world (`get_tree().paused = true`), shows a translucent overlay, and provides access to Resume, Save, Load, Settings, and Quit to Title. Pause is reachable from any state except state_title and state_game_over.

## Player Fantasy

The player should feel **in control without losing momentum**. The pause menu is brief — most players hit Esc to check something, then resume. It should be fast to navigate and never lose progress. Pillar: Pillar 1 (Player-Designed Honesty) — what you see is what's saved.

## Detailed Design

### Layout (1280x720 viewport)

```
+-------------------------------------------------------+
|                                                       |
|                  (game world dimmed)                  |
|                                                       |
|                                                       |
|                  > RESUME          ← default          |
|                    SAVE                                |
|                    LOAD                                |
|                    SETTINGS (TBD)                      |
|                    QUIT TO TITLE                       |
|                                                       |
|                                                       |
+-------------------------------------------------------+
```

### Menu Items (top to bottom)

1. **RESUME** (default focus): Press Enter → pop state_menu, `get_tree().paused = false`
2. **SAVE**: Press Enter → `SaveManager.save_to_slot(N)` for N in 1..3 → toast "SAVED TO SLOT N" → return to pause
3. **LOAD**: Press Enter → show save slot list → load selected → pop state_menu
4. **SETTINGS**: TBD (deferred to Polish layer); for MVP, no-op or hidden
5. **QUIT TO TITLE**: Press Enter → confirm dialog "QUIT TO TITLE? UNSAVED PROGRESS WILL BE LOST" → if yes, transition_to state_title

### Navigation

- **Up/Down arrows / W/S**: Move focus
- **Enter / Space / E**: Activate focused item
- **Esc**: Resume (closes pause)
- **Gamepad**: D-pad up/down + A button (partial support)

### Visual Design

- **Overlay**: Black 60% opacity over game world
- **Menu items**: 32px monospace; inactive = dim white, focused = bright cyan, selected = green flash
- **Confirm dialog** (for QUIT TO TITLE): Modal with 2 buttons (YES / NO), default focus on NO

### State Transitions

- **EXPLORATION → MENU (push)**: `get_tree().paused = true`, push state_menu
- **MENU → EXPLORATION (pop)**: `get_tree().paused = false`, pop state_menu
- **MENU → SAVE_LOAD (push)**: For SAVE/LOAD action
- **MENU → TITLE (transition)**: For QUIT TO TITLE; resets pause state
- **BATTLE → MENU (push)**: Same as exploration; battle scene can be paused

## Formulas

- Overlay fade-in: `opacity = 0.0 → 0.6` over 0.15s on pause
- Overlay fade-out: `opacity = 0.6 → 0.0` over 0.15s on resume
- Game world pause: `get_tree().paused = true/false` (binary, no transition)

## Edge Cases

- **Pause during save/load**: Cannot — save/load is itself a state that blocks input
- **Pause during cutscene/dialogue**: Should be allowed but is rare (deferred to Feature layer)
- **Quit to title during battle**: Confirm dialog; if yes, defeat player (set HP to 0) before transitioning
- **Save slot full / write error**: Toast "SAVE FAILED"; return to pause
- **Load from corrupted save**: Toast "LOAD FAILED"; return to pause

## Dependencies

- `GameStateMachine` (autoload) — push/pop state_menu, transition_to state_title
- `SaveManager` (autoload) — save_to_slot, load_from_slot
- `PlayerController` (scene) — HP reset on quit-to-title-during-battle

## Tuning Knobs

- Overlay opacity: 0.6 (default), range [0.4, 0.8]
- Overlay fade duration: 0.15s (default), range [0.1s, 0.3s]
- Confirm dialog default focus: NO (safety)
- Toast duration: 2.0s (default), range [1.0s, 3.0s]

## Acceptance Criteria

- [ ] Esc pauses game in any non-title state
- [ ] Pause overlay dims game world
- [ ] Default focus is on RESUME
- [ ] Up/Down navigates between items
- [ ] Enter activates focused item
- [ ] Esc resumes
- [ ] SAVE writes to manual slot 1-3
- [ ] LOAD lists available save slots
- [ ] QUIT TO TITLE shows confirm dialog
- [ ] Game world actually pauses (`get_tree().paused = true`)
- [ ] Toasts appear and auto-dismiss
