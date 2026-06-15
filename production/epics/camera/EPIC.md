# Epic: Camera System

> **Layer**: Foundation
> **GDD**: design/gdd/camera.md (Approved)
> **Architecture Module**: `Camera2D` (Scene) + `CameraFollow` (helper script)
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories camera`

## Overview

Provide room-bounded follow camera for exploration and a separate static camera for the battle screen. During exploration, the camera follows the player with smoothed movement, clamps to room bounds (1280x720 viewport), and snaps to the new room on door transition. During battle, the camera switches to a fixed battle screen position (typically centered on the enemy) and a "BATTLE" badge appears in the HUD. Camera transitions use Godot 4.6 `Camera2D.make_current()` with a brief tween (0.15s) for visual continuity. The camera does NOT own player position or input — it reads `Player.global_position` each frame and lerps toward it. This is a read-only module: no other system should write to camera state.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|------------|
| ADR-0010: TileMap Usage | Camera bounds derived from TileMapLayer room extents; supports 1280x720 and scaled room sizes | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-CAM-001 | Exploration camera follows player with smoothing | ADR-0010 ✅ |
| TR-CAM-002 | Camera clamped to room bounds (no over-scroll) | ADR-0010 ✅ |
| TR-CAM-003 | Camera snaps to new room on door transition | ADR-0010 ✅ |
| TR-CAM-004 | Battle camera is static; switches via `make_current()` | ADR-0010 ✅ |
| TR-CAM-005 | Camera transitions use 0.15s tween (4.6 Camera2D) | ADR-0010 ✅ |
| TR-CAM-006 | Camera is read-only — does not own player position | ADR-0010 ✅ |

## Definition of Done

- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/camera.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories camera` to break this epic into implementable stories.
