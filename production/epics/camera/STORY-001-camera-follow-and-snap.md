# STORY-001: Camera follows player + snaps to new room on door

> **Epic**: camera
> **Layer**: Foundation
> **TR**: TR-CAM-001, TR-CAM-002, TR-CAM-003
> **Status**: Done (verified 2026-06-13)

## Acceptance Criteria

- [x] `Camera2D` is child of `Player` in `main.tscn` (positioned at offset (0,0))
- [x] Camera follows `Player.global_position` each frame
- [x] Camera bounds clamp to room (1280x720 viewport)
- [x] On door transition, `LevelRuntime.build_room()` repositions player; camera follows automatically
- [x] F5 boot: `[CameraFollow] ready, target=Player, pos=(200.0, 360.0)`

## Implementation

- `src/ui/camera_follow.gd` — camera follow script (currently minimal; position = player position)
- Camera is child of Player, so inherits transform; no explicit tween yet
- Future: add 0.15s tween for door transitions (deferred — not blocking)

## Verification Evidence

- F5 boot output confirms camera ready
- Manual play: camera follows player through door transitions
