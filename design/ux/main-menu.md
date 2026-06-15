# Main Menu UX Spec (main-menu)

> **Status**: Draft v0.1 (2026-06-13)
> **Author**: ux-designer
> **GDD**: design/gdd/game-state-machine.md (state_title)
> **Patterns**: design/ux/interaction-patterns.md

## Overview

The Main Menu is the first screen the player sees on game launch. It provides access to New Game, Load Game (from autosave + manual slots), Settings, and Quit. The menu is shown in `state_title` and is the only state where the player can quit without confirmation. The menu is keyboard-navigable; gamepad navigation is partial (recommended for ship).

## Player Fantasy

The player should feel **invited, not overwhelmed**. The main menu is the threshold into the world — it should be atmospheric (dark background, distant mech hum) and quickly navigable. Pillar: Pillar 3 (Atmosphere over Exposition) — visual tone matches in-game darkness.

## Detailed Design

### Layout (1280x720 viewport)

```
+-------------------------------------------------------+
|                                                       |
|                                                       |
|                  RAILHUNTER                           |
|                  钢轨猎人                              |
|                                                       |
|                                                       |
|                  > NEW GAME        ← default          |
|                    LOAD GAME                         |
|                    SETTINGS                          |
|                    QUIT                              |
|                                                       |
|                                                       |
|   v0.1.0 (build 2026-06-13)         Press ENTER       |
+-------------------------------------------------------+
```

### Menu Items (top to bottom)

1. **NEW GAME** (default focus): Press Enter → push `state_save_load` with action="new" → first room
2. **LOAD GAME**: Press Enter → push `state_save_load` with action="load" → list autosave + 3 manual slots → load
3. **SETTINGS**: Press Enter → push `state_settings` (TBD: deferred to Polish layer; for MVP, no-op or hidden)
4. **QUIT**: Press Enter → `get_tree().quit()`

### Navigation

- **Up/Down arrows / W/S**: Move focus between menu items
- **Enter / Space / E**: Activate focused item
- **Esc**: Quits (no confirmation — title state is the only quit-without-prompt state)
- **Gamepad**: D-pad up/down + A button (partial support per accessibility-requirements.md)

### States and Transitions

- **TITLE → SAVE_LOAD** (action=new): Initialize fresh game state, push state_exploration
- **TITLE → SAVE_LOAD** (action=load): Show save slot list, load selected, push state_exploration
- **TITLE → QUIT**: `get_tree().quit()`
- **TITLE → SETTINGS**: Deferred to Polish layer; for MVP, hide or no-op

### Visual Design

- **Background**: Dark gradient (top: deep blue #0a0e1a, bottom: black) — matches in-game atmosphere
- **Title font**: Large, monospaced or pixel-style; white with subtle red glow
- **Menu items**: 32px monospace; inactive = dim white (#888), focused = bright cyan (#0ff), selected = green flash (0.2s)
- **Footer**: Build version + control hint, 16px dim white

## Formulas

- Menu item focus animation: `scale = 1.0 + 0.1 * sin(time * 4)` for focused item (subtle pulse)
- Title glow: `glow_intensity = 0.5 + 0.3 * sin(time * 2)` (subtle ambient pulse)

## Edge Cases

- **No save files**: "LOAD GAME" item is disabled (dim, no focus)
- **Corrupted save file**: Show "LOAD FAILED" toast; return to title
- **Quit during settings**: Returns to title (settings deferred)
- **Backed out of save load**: Returns to title (pop state_save_load)

## Dependencies

- `GameStateMachine` (autoload) — state_title, push state_save_load
- `SaveManager` (autoload) — list save slots, load autosave/manual
- `PlayerController` (scene) — fresh game init

## Tuning Knobs

- Menu focus animation speed: 4 (default), range [2, 8]
- Title glow frequency: 2 (default), range [1, 4]
- First focus item: NEW GAME (default)
- Show build version: true (default)

## Acceptance Criteria

- [ ] Main menu shows on game launch (state_title)
- [ ] Default focus is on NEW GAME
- [ ] Up/Down navigates between items
- [ ] Enter activates focused item
- [ ] Esc quits without confirmation
- [ ] LOAD GAME is disabled when no save files exist
- [ ] Title is visually striking (font + glow)
- [ ] Background matches in-game atmosphere
- [ ] Keyboard-navigable end-to-end
