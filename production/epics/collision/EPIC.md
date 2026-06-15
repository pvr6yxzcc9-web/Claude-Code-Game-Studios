# Epic: Collision Detection

> **Layer**: Foundation
> **GDD**: design/gdd/collision.md (Approved)
> **Architecture Module**: `CollisionManager` (autoload) + `StaticBody2D` walls + `Area2D` triggers
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories collision`

## Overview

Provide the collision layer that gates player movement and triggers gameplay events. Walls are `StaticBody2D` with `CollisionShape2D` rectangles forming the room boundary; the player `CharacterBody2D` uses `move_and_slide()` to slide along walls. Doors and encounter tiles are `Area2D` triggers that emit signals when the player enters their shape. Currently, `level_runtime.gd` uses a manual AABB polling fallback in `_process` (verified 2026-06-13) because Godot 4.6 Area2D `body_entered` was unreliable in some configurations; this may be replaced with proper signal handlers once the engine version is patched. The `CollisionManager` autoload provides a query API for any system that needs to ask "is there a wall here?" or "what's at (x, y)?" without instantiating its own physics queries.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|------------|
| ADR-0010: TileMap Usage | Walls + doors + encounter tiles use StaticBody2D / Area2D with TileMapLayer-derived bounds | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-COL-001 | Player `CharacterBody2D` uses `move_and_slide()` for wall sliding | ADR-0010 ✅ |
| TR-COL-002 | Walls are `StaticBody2D` with `CollisionShape2D` rectangles | ADR-0010 ✅ |
| TR-COL-003 | Doors are `Area2D` triggers at room edges | ADR-0010 ✅ |
| TR-COL-004 | Encounter tiles are `Area2D` triggers on room floor | ADR-0010 ✅ |
| TR-COL-005 | `CollisionManager` autoload provides query API | ADR-0010 ✅ |
| TR-COL-006 | Door transition fires on player AABB inside door rect (manual polling fallback in 4.6) | ADR-0010 ✅ |

## Definition of Done

- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/collision.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories collision` to break this epic into implementable stories.
