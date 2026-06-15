# S7-004 Implementation Plan — HUD 3-4 Mech HP Bars + Assignment UI

> **Sprint 7 Story**: S7-004 (1.5 days, godot-gdscript-specialist + ui-programmer)
> **Depends on**: S7-001 (BattleState.party_mechs) + S7-003 (MechLoadout 4 mechs)
> **Goal**: Refactor `src/ui/hud.gd` to display **3-4 mech HP bars** (one per party mech), each with pilot icon, mech name, current/max HP, and active/knocked-out status. Add a click-to-select interaction for combat mech switching.

## Current State (Baseline)

- **File**: `src/ui/hud.gd` (466 lines)
- **Data model**: 1 global `_hp_fill: ColorRect`, 1 player HP bar
- **Bottom-right HP bar**: shows 1 mech's HP
- **No multi-mech UI** — only 1 player's HP is shown

## Target State (After S7-004)

- **3-4 mech HP bars** (one per active mech in the party)
- **Each bar shows**: pilot icon (small portrait), mech name, current/max HP, parts HP (head/chest/arms/legs as 4 small sub-bars)
- **Active mech** highlighted (yellow border)
- **Knocked-out mechs** dimmed (gray)
- **Click-to-select**: clicking a mech bar selects it as the active mech (1/2/3 key alternative)
- **Bottom-right**: weapons panel (current mech's 3-4 weapons, click to select) — already partially exists

## File Changes (Summary)

| File | Lines added | Lines removed | Net |
|------|-------------|---------------|-----|
| `src/ui/hud.gd` | +250 | -80 | +170 |
| `src/ui/party_hud_panel.gd` (NEW) | +200 | 0 | +200 |
| `assets/sprites/hud/pilot_icons/` (3 NEW) | +30 | 0 | +30 |
| `tests/integration/fc62_hud_3mech_test.gd` (NEW) | +80 | 0 | +80 |

**Total**: ~560 lines added, ~80 lines removed. **Net: +480 lines** across 4 files (incl. assets).

---

## Sub-Task Breakdown (Days 1-1.5)

### Day 1 Morning: Multi-Mech HP Bar Layout

**Sub-task 1.1: Create `src/ui/party_hud_panel.gd`** (0.5 day)

A new HUD component that draws 3-4 mech bars. Reusable across battle and exploration.

```gdscript
# src/ui/party_hud_panel.gd
extends Control

# Visual elements (one per mech)
var _mech_bars: Array[Dictionary] = []  # each: {bg, fill, label, pilot_icon, parts_indicators}

# Active mech index (highlights the active bar)
var _active_mech_index: int = 0

# Data source (from BattleState or MechLoadout)
func update_from_battle_state(state: BattleState) -> void
func update_from_mech_loadout(loadout: MechLoadout, active_mech_id: StringName) -> void

# Click handler
signal mech_bar_clicked(mech_index: int)

func _draw_mech_bar(index: int, mech_data: MechData, pilot_id: StringName, is_active: bool, is_knocked_out: bool) -> void
```

**Why a new file**: HUD code is already 466 lines. Adding 3-4 mech bars to the existing file would push it to 700+ lines. Extracting to a new component keeps HUD manageable.

**Sub-task 1.2: Pilot icon assets (3 small portraits)** (0.25 day)

3 pilot icon PNGs (32×32 each) for 漫游者 / 霜尾 / 轰天:
- 漫游者: mech pilot helmet
- 霜尾: snow goggles + scarf
- 轰天: military beret + scars

These are **HUD icons**, not full portraits (which already exist for dialogue). Small enough to fit in a mech bar.

**Sub-task 1.3: Layout positioning** (0.25 day)

Position the 3-4 mech bars in a vertical column on the **left side** of the screen (replacing the current 1-player HP bar position):
- Y=120, height=80, width=200, each bar 80px tall with 4px gap
- Mech 1 (top), Mech 2, Mech 3, Mech 4 (bottom)
- Each bar: pilot icon (left) + mech name + current/max HP text + 4 small parts indicators (right)

### Day 1 Afternoon: Combat Integration

**Sub-task 1.4: Wire to BattleState (S7-001)** (0.25 day)

In `BattleScene`, when combat starts, the HUD subscribes to `BattleState.party_mechs` changes. When the active mech changes (1/2/3 keys or Tab), the HUD updates.

**Sub-task 1.5: Wire to MechLoadout (S7-003)** (0.25 day)

When the player is in exploration mode, the HUD reads `MechLoadout.get_active_mech()` to display the current mech's parts HP.

**Sub-task 1.6: Click-to-select** (0.25 day)

Each mech bar is a `Button` (or `Control` with `mouse_filter` enabled). Clicking emits `mech_bar_clicked(mech_index)`. The BattleScene listens and calls `set_active_mech(mech_id)`.

### Day 1.5: Tests + Polish

**Sub-task 1.7: Tests fc62_hud_3mech_test.gd** (0.25 day)

5 tests:
- 1) HUD shows 3 mech bars (default 3 pilots)
- 2) Active mech bar is highlighted (yellow border)
- 3) Knocked-out mech bar is dimmed (gray)
- 4) Clicking a mech bar emits mech_bar_clicked signal
- 5) HUD updates when active mech changes (via 1/2/3 keys)

**Sub-task 1.8: Visual polish** (0.25 day)

- Active mech: yellow border (already in code, just verify)
- Knocked-out mech: gray, with "X" overlay
- HP bar color: green > 50%, yellow > 25%, red < 25% (already in code, just apply to 4 bars)
- Pilot icon: hover shows pilot name (tooltip)

---

## Code Patterns to Reuse (from existing codebase)

| Pattern | Existing location | Reuse for S7-004 |
|--------|-------------------|------------------|
| HP bar (single) | `hud.gd` `_hp_fill`, `_hp_text` | Same pattern, but for 4 mechs |
| Mech part indicators | `hud.gd` `_mech_labels` (T/L/R 1-letter) | Extend to 4 letters (H/C/A/L) |
| Fragment counter | `hud.gd` `_fragment_count` | Same — display 1 number, not multi-mech |
| Color coding | `hud.gd` HP color (green/yellow/red) | Same — apply to each mech's bar |
| Click handlers | `hud.gd` _on_action_pressed | Reuse the pattern for mech_bar_clicked |

## Risks Specific to S7-004

1. **HUD clutter**: 3-4 mech bars + 4 parts indicators each = 16+ UI elements. Risk of visual clutter.
   - **Mitigation**: Use a compact layout (1 line per mech, 4 sub-bars on the right). 3.5" wide × 0.6" tall per bar.

2. **Performance**: Updating 4 bars every frame could be slow on lower-end devices.
   - **Mitigation**: Only update on state change (subscribe to BattleState signals, not process every frame). Tests in fc62 verify no per-frame updates.

3. **4-mech bar visual confusion**: Players might not understand which bar is the "active" mech. Visual cues (yellow border, larger font, etc.) must be obvious.
   - **Mitigation**: Active mech's bar is **2x taller** than inactive bars. Plus yellow border. Tested with 2-3 users.

4. **Existing HUD elements (state badge, weapon slots, etc.) need to coexist with new mech bars**: The current HUD has 1 HP bar at bottom-right. The new design has 4 mech bars at left. Re-arrangement required.
   - **Mitigation**: Carefully position the new bars without overlapping existing elements. Test in F5.

## Out of Scope (for S7-004 only)

- Mech Bay menu UI (S7-007)
- Combat damage popups (already in battle_scene.gd)
- Pause menu (S6 already)
- Tutorial hints (S6-002 already)

## Acceptance Test (Manual F5 Verification)

1. Start a new game, F5.
2. **Exploration mode**: HUD shows 3 mech bars on the left (Ranger / Frostbite / Bomber). 苍穹号 is hidden (locked).
3. Each bar shows: pilot icon, mech name, HP bar (full = 100/100), 4 parts sub-bars.
4. Press M (Mech Bay menu) — S7-007. Switch active mech to Frostbite.
5. Return to HUD — the active mech bar (Frostbite) has a yellow border; the other 2 bars are dimmed.
6. Enter combat. Encounter a scavenger.
7. **Combat HUD**: Same 3 mech bars, but the active mech's HP bar decreases as the enemy attacks.
8. Damage a mech's head to 0 — the head sub-bar is grayed out, and the mech has -50% accuracy (verified by checking attack hit rate).
9. Click on a different mech bar in the HUD — the active mech changes (1/2/3 key alternative works).
10. Save and reload — the HUD state is preserved (active mech, parts HP).

If all 10 steps work, S7-004 is complete.
