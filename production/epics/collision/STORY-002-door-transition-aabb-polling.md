# STORY-002: Door transition via AABB polling fallback (4.6 fix)

> **Epic**: collision
> **Layer**: Foundation
> **TR**: TR-COL-003, TR-COL-004, TR-COL-006
> **Status**: Done (verified 2026-06-13)

## Acceptance Criteria

- [x] Doors are `Area2D` triggers at room edges (32x96 rect)
- [x] Doors wrap a `Node2D` for visual rendering
- [x] Door transition fires when player AABB is inside door rect
- [x] Manual polling fallback in `_process` works around 4.6 Area2D `body_entered` reliability issue
- [x] `set_deferred("monitoring", true)` prevents spawn-time false triggers
- [x] Player can traverse all 10 rooms via doors (verified F5: room 0 → 1 → 2 → 3 → 4)

## Implementation

- `src/scene/level_runtime.gd:_spawn_door()` — creates Node2D wrapper + Area2D + CollisionShape + ColorRect visual
- `src/scene/level_runtime.gd:_process()` — manual AABB check, calls `build_room(target_room)` on match
- `door_dir` tracks which direction player came from for spawn position

## Verification Evidence

- F5 log: `POLL: door trigger at (1280.0, 360.0)` → `build_room(N)` runs
- Typed array bug fix: `Array[Area2D]` → `Array[Node2D]` (door_wrapper is Node2D, not Area2D)
- 5 rooms traversed in one F5 session
