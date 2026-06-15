# STORY-001: StaticBody2D walls + CharacterBody2D move_and_slide

> **Epic**: collision
> **Layer**: Foundation
> **TR**: TR-COL-001, TR-COL-002
> **Status**: Done (verified 2026-06-13)

## Acceptance Criteria

- [x] Walls are `StaticBody2D` with `CollisionShape2D` (RectangleShape2D) bounding room
- [x] Player `CharacterBody2D` uses `move_and_slide()` to slide along walls
- [x] Top + bottom walls always present; left/right walls only when no door
- [x] Player cannot pass through walls; slides cleanly

## Implementation

- `src/scene/level_runtime.gd:build_room()` — creates `_walls: StaticBody2D` with 2-4 CollisionShape2D
- `src/scene/player_controller.gd` — `CharacterBody2D extends` with `_physics_process` calling `move_and_slide()`
- `SPEED: float = 120.0` (pixels/sec)

## Verification Evidence

- F5 manual play: player slides along top/bottom walls, cannot pass through
- FC-3 tests pass
