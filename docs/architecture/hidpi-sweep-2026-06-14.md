# HiDPI Sweep — 2026-06-14

> **Purpose**: Audit SaveUI / TerminalUI / CodexUI / BattleScene overlay for the
> S2-001 class of bug (Godot 4.6 + Vulkan + Intel Iris + 2x DPI scale crash in
> `func _draw` + `draw_string(ThemeDB.fallback_font, ...)`).
> **Method**: 1) `tools/lint_no_draw.py` (already wired in CI) for the strict
> detection, 2) manual read of each file to spot related risks (hardcoded
> geometry that drifts from panel position, FULL_RECT darken overlays).

## Lint result

```
$ python tools/lint_no_draw.py
=== No-Draw Lint OK ===
No func _draw / draw_string / draw_char found in:
  - src/ui
  - src/battle
```

All 4 target files plus all other UI files pass.

## Per-file findings

| File | `_draw`? | Fragile geometry? | Risk | Verdict |
|------|----------|--------------------|------|---------|
| `src/ui/save_ui.gd` | No | Fixed in fc21 (PANEL_X/Y/W/H constants); `_refresh()` uses them | None | PASS (S3-010 carryover shipped) |
| `src/ui/terminal_ui.gd` | No | **Yes** — body text uses `y_offset = 80` (absolute), while title uses `_bg.position + Vector2(20, 40)` (relative). If `_bg.position` changes, body labels drift. Same pattern that caused the S3-010 SaveUI highlight bug. | Low (no current visual bug) | PASS now, but flag for follow-up |
| `src/ui/codex_ui.gd` | No | **Yes** — scroll indicator math hardcodes `600.0` (panel height) twice (`_scroll_indicator.size.y = bar_h` and `position.y` calc). If `rect_h` changes, scrollbar drifts. | Low | PASS now, but flag for follow-up |
| `src/battle/battle_scene.gd` | No | **No** — overlay is `Color(0, 0, 0, 0.75)` + FULL_RECT, which is a *known-good* pattern (intentional full-screen dim during battle). `extends Control` not CanvasLayer so it renders as part of the main canvas. | None | PASS |

## Follow-up backlog (do NOT bundle into this task)

| Item | Reason | Priority |
|------|--------|----------|
| TerminalUI: refactor `y_offset` to relative (`var y_offset: float = _bg.position.y + 80`) and rename to make absolute-vs-relative intent explicit | Prevent future bug same as S3-010 (hardcoded geometry drifts from panel position) | Low — no current visual bug, but a regression waiting to happen |
| CodexUI: extract `PANEL_H` const, use it in scroll indicator math | Same pattern as above | Low — no current visual bug |
| (informational) BattleScene: add a comment in the file warning future contributors not to "improve" the FULL_RECT darken overlay with a `_draw` override — it's a *feature* (intentional dim), not a workaround | Defensive comment, zero code change | Trivial |

## Why this is the structural fix (not just a one-time sweep)

The S3-006 lint guard (`tools/lint_no_draw.py`) is the durable protection: every
future PR that introduces a `func _draw` or `draw_string` in `src/ui/` or
`src/battle/` will fail CI before it lands. This sweep's job is to confirm
the guard covers the current code, and to surface the *related* fragile
geometry patterns that the lint can't catch (because they're not `_draw`
violations, they're absolute-vs-relative geometry mistakes).

The S3-006 guard + this sweep = two layers of defense:

1. **Lint layer (CI-enforced)**: blocks `_draw` / `draw_string` reintroduction
2. **Geometry layer (code review)**: catches hardcoded numbers that don't
   track with their parent panel's position

For (2), the right next step is NOT another lint script (would generate noise
on legitimate absolute numbers like screen center `Vector2(640, 360)`); it's a
*code review checklist item* that says "if you add a UI element with a
hardcoded position, justify why it's not relative to its parent."

## F5 verification (still required by S3-007 process)

This sweep did NOT include live F5 verification at HiDPI 2x scale (the project
runs at native 1x in the developer's environment). The lint pass is strong
evidence the code is correct, but the S2-001 lesson stands: **lint passing is
not F5 passing**. The full HiDPI 2x F5 check is deferred until the project
has a second machine or VM capable of triggering the Intel Iris driver
behavior.

Until then, this sweep + the lint guard = best-effort protection. The
remaining latent risk is acknowledged in the carryover table.
