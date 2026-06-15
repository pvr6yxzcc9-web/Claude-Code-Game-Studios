# ADR-0010: TileMap Usage (TileMapLayer + 4.6 Scene Tile Rotation)

## Status

Accepted

## Date

2026-06-12

## Last Verified

2026-06-12

## Decision Makers

User + técnico-director (self-review)

## Summary

Railhunter uses Godot 4.3+ `TileMapLayer` (NOT the deprecated `TileMap` since 4.3) for all tile-based geometry. Each room is one `TileMapLayer` node. Encounter tiles, terminals, NPCs, and doors are placed as **scene nodes** (not tiles) so they can have scripts, signals, and interactive logic. Godot 4.6's new **scene tile rotation API** is used for doors and locked tiles that need to be rotated 90°/180°/270° at edit time. Codifies `level-dungeon.md` C-R1 + C-R2 + C-R6, and addresses the MEDIUM RISK domain flagged in `architecture.md` §2.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Rendering (TileMap) |
| **Knowledge Risk** | MEDIUM — `TileMapLayer` is in training (replaced `TileMap` in 4.3); 4.6 scene tile rotation API is post-LLM-cutoff |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md`, `docs/engine-reference/godot/modules/tilemap.md` |
| **Post-Cutoff APIs Used** | `TileMapLayer` rotation API (4.6+); `TileData.set_scene_rotation_degrees()` (if exists in 4.6; verify) |
| **Verification Required** | First room scene: load, verify TileMapLayer renders; place an encounter tile as scene node; rotate a door 90°; verify collision shapes match rotation. |

> **Note**: Per `architecture.md` §2 / §4c MEDIUM RISK flag: "TileMapLayer in training but verify scene tile rotation, 4.6". First implementation must pair with `godot-specialist` review.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0005 (Collision system — `TileMapLayer.get_cell_tile_data()` is the collision query API), ADR-0001 (autoload — CollisionManager uses TileMapLayer) |
| **Enables** | Level/Dungeon system implementation; encounter tile placement; door placement |
| **Blocks** | First level scene; encounter system; door/lock system |
| **Ordering Note** | Tenth ADR. After Input Binding (0009). Before Level/Dungeon implementation |

## Context

### Problem Statement

Railhunter is a 2D pixel game with tile-based level geometry. We have 3 places tile data appears:
1. **Static geometry** (walls, floors, decoration) — in TileMap
2. **Encounter tiles** (per `level-dungeon.md` C-R4) — invisible trigger; not visible in TileMap
3. **Doors / Locked tiles** (per `level-dungeon.md` C-R5) — interactive; can be rotated 90°/180°/270°
4. **Terminals / NPCs** (per `level-dungeon.md` F1) — interactive scene nodes

Pre-4.3, Godot had `TileMap` (single node, integrated with physics). Since 4.3, `TileMap` is deprecated in favor of `TileMapLayer` (one node per layer, more flexible). In 4.6, the scene tile rotation API was added for rotating scene-node tiles.

The choice: use `TileMapLayer` (4.3+ idiom) and leverage 4.6's scene tile rotation for doors.

### Current State

- `level-dungeon.md` C-R1: "地图 = `TileMap` 节点 + 32x32 像素基础单位" — **outdated, must update to `TileMapLayer`**
- `level-dungeon.md` C-R2: "每个房间 = 1 个 TileMap 屏幕" — applies to TileMapLayer
- `level-dungeon.md` C-R4: "ENCOUNTER tile = 不可见 trigger" — encounter tiles are scene nodes, not tiles
- `level-dungeon.md` C-R6: "隐藏区域 = 视觉提示 + 不在主路" — hidden tiles are scene nodes
- `architecture.md` §2: "TileMapLayer in training but verify scene tile rotation, 4.6" — MEDIUM RISK
- `architecture.md` §4c: "Room scenes (`*.tscn`) — `TileMapLayer` geometry, encounter tile markers, terminal placements, NPC placements. **TileMapLayer API** (4.3+) — **MEDIUM RISK** (in training but verify scene tile rotation, 4.6)."

So the **direction is clear** (use TileMapLayer), but the **specification of scene-vs-tile decisions** is not yet written.

### Constraints

- **MEDIUM RISK** — 4.6 scene tile rotation API is post-cutoff
- **Godot 4.6** is the pin (per ADR-0006)
- **One chapter MVP** — 10 rooms in chapter 1 (per `level-dungeon.md` C-R1)
- **32x32 pixel base** — per art-bible
- **Solo dev** — uniform pattern, easy to extend

### Requirements

- **TileMapLayer only** — `TileMap` (pre-4.3) is forbidden
- **Scene nodes for interactive elements** — encounters, terminals, NPCs, doors as scene nodes (not tiles)
- **Tiles only for static geometry** — walls, floors, decoration
- **Door rotation** — 4.6 scene tile rotation API for 90°/180°/270° door placement
- **Collision via `TileMapLayer.get_cell_tile_data()`** — per ADR-0005
- **Performance**: 10 rooms loaded simultaneously, frame rate ≥ 60 FPS (per `level-dungeon.md` AC-17)
- **Texture format**: 32x32 PNG sprites, NEAREST filter, no compression (pixel-perfect)

## Decision

### Architecture

```
Room scene (e.g., res://scenes/rooms/chapter1_c1_room1.tscn):

  Root
  ├── RoomController (Node, controls room-level logic)
  │    ├── @export var room_id: StringName
  │    ├── @export var chapter_id: StringName
  │    ├── @export var encounter_table: Resource  (EncounterTable.tres)
  │    └── signals: room_entered, room_exited
  │
  ├── TileMapLayer (the static geometry)
  │    ├── TileSet: res://data/tilesets/main_tileset.tres
  │    ├── Renders: walls, floors, decoration
  │    ├── Physics: per-tile collision shapes (configured in TileSet)
  │    └── NO script (logic is in scene nodes)
  │
  ├── EncounterTile1 (Area2D, scene node)
  │    ├── Position: (5, 5) (placed in editor)
  │    ├── CollisionShape2D: 32x32 rectangle
  │    ├── Layer: LAYER_ENCOUNTER (per ADR-0005)
  │    └── Script: encounter_tile.gd
  │         └── Emits encounter_triggered(enemy_data) when player enters
  │
  ├── EncounterTile2 (Area2D, ... same as above)
  │    └── ...
  │
  ├── Door1 (StaticBody2D, scene node with rotation)
  │    ├── Position: (10, 5) (placed in editor)
  │    ├── Rotation: 90° (set in editor, applies 4.6 scene tile rotation)
  │    ├── CollisionShape2D: matches rotation
  │    ├── @export var door_data: DoorData
  │    └── Script: door.gd
  │
  ├── Terminal1 (Area2D, scene node)
  │    ├── Position: (15, 10)
  │    ├── CollisionShape2D: 32x32
  │    ├── Layer: LAYER_INTERACTABLE
  │    ├── @export var terminal_log: TerminalLogData
  │    └── Script: terminal.gd
  │
  └── NPC1 (Area2D, scene node)
       ├── Position: (20, 5)
       ├── CollisionShape2D: 32x32
       ├── Layer: LAYER_INTERACTABLE
       ├── @export var npc_data: NPCData
       └── Script: npc_controller.gd
```

### Key Interfaces

```gdscript
# === TileMapLayer setup (editor-driven, no script) ===
# In Godot editor:
# 1. Add TileMapLayer node
# 2. Set TileSet = res://data/tilesets/main_tileset.tres
# 3. Configure physics layers (per ADR-0005):
#    - Layer 0 (LAYER_WORLD): physics_layer = 0
#    - Set collision shapes for wall tiles
# 4. Place wall/floor/decor tiles in editor
# 5. NO script attached (logic is in scene nodes)


# === EncounterTile (scene node, NOT a tile) ===
# File: src/scene/encounter_tile.gd
class_name EncounterTile
extends Area2D

@export var enemy_data: EnemyData
@export var encounter_table: EncounterTable  # optional, for table-based enemies

func _ready() -> void:
    collision_layer = CollisionManager.LAYER_ENCOUNTER
    collision_mask = CollisionManager.LAYER_PLAYER  # detect player only
    body_entered.connect(_on_body_entered)
    # Per ADR-0005: monitoring toggled off in BATTLE state

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player") and enemy_data != null:
        var payload: Dictionary = {
            "encounter_tile_id": name,
            "enemy_data": enemy_data,
        }
        encounter_triggered.emit(payload)
        EncounterManager.handle_encounter_trigger(payload)


signal encounter_triggered(payload: Dictionary)


# === Door (scene node with rotation, per 4.6 API) ===
# File: src/scene/door.gd
class_name Door
extends StaticBody2D

enum DoorType { NORMAL, WEAPON_LOCKED, AMMO_LOCKED, ITEM_LOCKED, STORY_LOCKED }

@export var door_type: DoorType = DoorType.NORMAL
@export var required_weapon: WeaponData
@export var required_ammo: StringName
@export var required_item: ItemData
@export var required_fragment_count: int = 0  # for STORY_LOCKED

func _ready() -> void:
    collision_layer = CollisionManager.LAYER_WORLD
    collision_mask = CollisionManager.LAYER_PLAYER
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
    if not body.is_in_group("player"):
        return
    if _can_unlock():
        # Open animation
        $AnimationPlayer.play("door_open")
        # Disable collision
        collision_layer = 0
    else:
        # Show refusal hint
        show_refusal_hint()


func _can_unlock() -> bool:
    match door_type:
        DoorType.NORMAL:
            return true
        DoorType.WEAPON_LOCKED:
            return required_weapon != null and Inventory.has_weapon(required_weapon)
        DoorType.AMMO_LOCKED:
            return required_ammo != &"" and Inventory.ammo_count(required_ammo) > 0
        DoorType.ITEM_LOCKED:
            return required_item != null and Inventory.has_item(required_item)
        DoorType.STORY_LOCKED:
            return MetaState.unlocked_count() >= required_fragment_count
    return false


# === TileSet (res://data/tilesets/main_tileset.tres) ===
# In editor:
# - Add TileSet resource
# - Import tilesheet (32x32 PNG)
# - Define collision shapes for wall tiles (per ADR-0005 layer 0)
# - No scene tiles defined here (interactive elements are scene nodes, not tiles)


# === Collision query (per ADR-0005) ===
# In CollisionManager.gd:
func tile_at(pos: Vector2i) -> int:
    var tilemap: TileMapLayer = _get_current_room_tilemap()
    if tilemap == null:
        return -1
    return tilemap.get_cell_source_id(pos)

func is_walkable(pos: Vector2i) -> bool:
    var tilemap: TileMapLayer = _get_current_room_tilemap()
    if tilemap == null:
        return false
    var tile_data: TileData = tilemap.get_cell_tile_data(pos)
    if tile_data == null:
        return true  # empty tile = walkable
    return tile_data.get_collision_polygons_count(0) == 0
```

### Implementation Guidelines

#### Why encounter tiles are scene nodes, not tiles

- **Logic**: EncounterTile has a script that emits a signal
- **Editor-friendly**: Scene nodes are visible in the editor's Scene tree; tiles are not
- **Debug**: Easier to attach debugger to a specific encounter tile
- **Performance**: A scene node has 0 perf overhead vs a tile (both are positioned in 2D)
- **Trade-off**: Slightly larger scene file (one node per encounter tile vs a tile reference). For 25 encounter tiles per chapter, this is negligible.

#### Why doors are scene nodes (not tiles) with rotation

- Doors have logic (locked/unlocked)
- Doors have 4 rotations (N/E/S/W) — the 4.6 scene tile rotation API supports this
- Tiles with rotation: in pre-4.6, you'd need 4 separate tile variants (one per rotation); 4.6 makes this clean
- 4.6 scene tile rotation: `TileMapLayer` supports placing a `PackedScene` (scene file) as a tile; the scene can be rotated via the editor's rotation handle

#### 4.6 scene tile rotation API (HIGH RISK)

Per `architecture.md` §2 MEDIUM RISK flag, the 4.6 scene tile rotation API needs verification.

**Suspected API** (per Godot 4.6 docs):
```gdscript
# File: src/scene/door.gd (extension)
@export var door_scene: PackedScene  # the door PackedScene to instance

func place_in_tile(tilemap: TileMapLayer, pos: Vector2i, rotation_deg: int) -> void:
    # 4.6 API: instantiate scene as tile, apply rotation
    # (verify exact API at first use site)
    pass
```

**Fallback if API is awkward**: doors remain scene nodes (not tiles), placed at room positions in editor. The 4.6 scene tile rotation is a nice-to-have, not a must-have.

#### What is in the TileSet (per ADR-0005 collision layer 0)

- **Walls**: tiles with collision shapes (full 32x32 rectangle)
- **Floor**: tiles with no collision (walkable)
- **Decoration**: tiles with no collision (visual only)
- **Hidden wall**: tile with collision but different visual (for hidden areas)
- **Door tile (visual only)**: tile that visually looks like a door but the actual door is a scene node (per above)

#### What is NOT in the TileSet

- Interactive elements (per above)
- Multi-tile structures (per `level-dungeon.md` C-R6, hidden areas are scene nodes, not tile structures)
- Light sources (per `camera.md` §4, we don't use dynamic lights; visual atmosphere via pre-rendered shaders)

#### 32x32 pixel base

- All tiles are 32x32 pixels
- Tilesheet is a 32-pixel-aligned PNG
- Camera2D zoom in 32-pixel multiples (per `camera.md` Visual rules)
- Player/Enemy character sprites are 32x32 base

#### Texture format

- 32x32 PNG per tile
- NEAREST filter (no anti-aliasing — pixel art)
- No compression (pixel-perfect)
- Atlas packing: multiple tiles per PNG (e.g., 16x16 grid = 256 tiles per atlas)
- Import settings: `texture_filter = TextureFilter.TEXTURE_FILTER_NEAREST`

#### Performance

- 10 rooms loaded simultaneously = 10 `TileMapLayer` nodes
- Each room: 25x15 tiles = 375 tiles per room
- Total: ~3750 tiles visible at once (max)
- Godot 4.6 TileMapLayer is optimized for this (culling, batching)
- Frame rate ≥ 60 FPS (per `level-dungeon.md` AC-17)

#### Per-room `room_id` convention

- Format: `<chapter>_<room_short_name>`
- Example: `chapter1_c1_room5` (chapter 1, room 5)
- Per `level-dungeon.md` C-R7: room_id is StringName, used for save/load

## Alternatives Considered

### Alternative 1: Use deprecated `TileMap` (pre-4.3)

- **Description**: Use the old `TileMap` node (single, integrated)
- **Pros**: Simpler; one node
- **Cons**: Deprecated in 4.3; future versions may remove
- **Estimated Effort**: -20% initial, +rewrite cost on 4.7+
- **Rejection Reason**: Godot 4.6 is our pin; using deprecated API is a future risk

### Alternative 2: Encounter tiles as actual tiles (not scene nodes)

- **Description**: Encounter tiles are tile IDs in TileMap; CollisionManager checks tile_id to determine encounter
- **Pros**: Fewer scene nodes
- **Cons**: Logic in script is awkward; can't easily attach signals; harder to debug
- **Estimated Effort**: -5% scene size, +30% logic complexity
- **Rejection Reason**: Scene nodes are more idiomatic for logic-bearing elements

### Alternative 3: Single global TileMapLayer (not per-room)

- **Description**: One TileMapLayer for the whole game; rooms are "zones" within it
- **Pros**: Fewer nodes; one big tile map
- **Cons**: Memory: all rooms loaded simultaneously; culling harder
- **Estimated Effort**: -10% node count, +memory overhead
- **Rejection Reason**: `level-dungeon.md` C-R2 mandates "每个房间 = 1 个 TileMap 屏幕"

### Alternative 4: One TileMapLayer per `room_part` (wall layer, decoration layer, etc.)

- **Description**: Each room has 3 TileMapLayers: walls, decoration, doors
- **Pros**: Z-order control; pixel-perfect layering
- **Cons**: 30 TileMapLayer nodes per chapter; culling harder
- **Estimated Effort**: +200% nodes, +10% perf overhead
- **Rejection Reason**: Single TileMapLayer is sufficient for MVP; can split in VS

## Consequences

### Positive

- **Forward-compatible** — using `TileMapLayer` (4.3+) means future Godot versions are supported
- **Logic separation** — interactive elements (encounters, doors, terminals, NPCs) are scene nodes; static geometry is TileMapLayer
- **Editor-friendly** — devs can place encounter tiles in editor and see them in the scene tree
- **Performance** — Godot 4.6 TileMapLayer is optimized for 32x32 pixel games
- **Rotation** — 4.6 scene tile rotation for doors
- **Collision query** — `TileMapLayer.get_cell_tile_data()` is the canonical API

### Negative

- **MEDIUM RISK** — 4.6 scene tile rotation API is post-cutoff; first use site must verify
- **Per-room TileMapLayer** — 10 rooms = 10 nodes; not a perf issue but more nodes
- **Y-shape door** — doors need 4 scene nodes or 4 PackedScene variants per room (one per rotation)
- **Tile collision configuration** — per-tile collision shapes in TileSet editor; tedious for 100+ tile types

### Neutral

- TileMapLayer is the engine's idiom; devs familiar with Godot 4.3+ will recognize
- 32x32 base is art-bible convention; not changeable
- NPC/Terminal data is NPCData/TerminalLogData; room just references them

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| 4.6 scene tile rotation API is awkward or doesn't exist | Low | Medium | Doors remain scene nodes (not tiles) — fallback is in place |
| `TileMapLayer` culling bug with 10 simultaneous rooms | Low | High | Per `level-dungeon.md` AC-17, 60 FPS test asserts |
| Tile collision shapes don't match rotation | Low | Medium | First use site verification; per-tile collision check |
| Texture import settings (NEAREST filter) wrong | Low | Low | `tools/lint_texture_settings.py` CI check |
| Encounter tile positioned on top of wall (unreachable) | Medium | Low | Linter checks spawn positions against `is_walkable()` at edit time |
| Tilesheet changes break save data | N/A | N/A | Save data doesn't reference tile IDs (only room_id + encounter_data) |
| Memory: 10 rooms × 375 tiles × 32x32 = 4.7 MB spritesheet | Low | Low | Godot texture atlas = single 4.7 MB texture (acceptable on 500MB budget) |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| Memory per tilesheet (32x32 atlas) | N/A | ~5 MB (atlas) | <50 MB |
| Frame time per room (10 rooms loaded) | N/A | ~2-4ms (cull + batch) | <16.6ms |
| `get_cell_tile_data()` query | N/A | <0.5ms (per query) | <1ms |
| Encounter tile check (player walked) | N/A | <1ms | <5ms |
| Door rotation (editor-time) | N/A | <10ms (per door) | <50ms |
| Room scene load | N/A | ~50ms (10 rooms) | <200ms |

## Migration Plan

1. **Update `level-dungeon.md` C-R1** — change "地图 = `TileMap` 节点" to "地图 = `TileMapLayer` 节点"
2. **Create `main_tileset.tres`** — TileSet resource with wall/floor/decor tiles
3. **Define 4.6 scene tile rotation usage** — first implementation verifies API
4. **Create first room scene** — `chapter1_c1_room1.tscn` with 1 TileMapLayer + 2-3 encounter tiles + 1 door + 1 terminal + (optional) 1 NPC

**Rollback plan**: If 4.6 scene tile rotation API is broken:
1. Doors remain scene nodes (not tiles) — already in fallback
2. Per-door rotation via `rotation_degrees` property in editor
3. Collision shape rotated manually
4. Linter checks rotation consistency

Migration is per-room; not blocking.

## Validation Criteria

- [ ] **First room test**: load `chapter1_c1_room1.tscn` in Godot 4.6, all 5 TileMapLayer tiles render correctly
- [ ] **TileSet test**: 32x32 tiles, NEAREST filter, wall tiles have collision
- [ ] **Encounter tile test**: place 3 encounter tiles, walk player into each, signal fires correctly
- [ ] **Door rotation test**: place door with rotation 0°/90°/180°/270°, collision shape matches rotation
- [ ] **4.6 scene tile API test**: if API exists, use it; if not, fall back to scene-node approach
- [ ] **Performance test**: 10 rooms loaded = 60 FPS sustained (per `level-dungeon.md` AC-17)
- [ ] **Collision query test**: `CollisionManager.is_walkable(pos)` returns correct for wall vs floor
- [ ] **Editor lint test**: CI asserts every room has TileMapLayer + correct scene-node structure

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/level-dungeon.md` | Level/Dungeon | **C-R1**: "地图 = TileMap 节点" | Updated to TileMapLayer; codifies 4.6 API |
| `design/gdd/level-dungeon.md` | Level/Dungeon | **C-R2**: "每个房间 = 1 个 TileMap 屏幕" | One TileMapLayer per room |
| `design/gdd/level-dungeon.md` | Level/Dungeon | **C-R4**: "ENCOUNTER tile = 不可见 trigger" | EncounterTile is scene node, not tile |
| `design/gdd/level-dungeon.md` | Level/Dungeon | **C-R6**: "隐藏区域 = 视觉提示 + 不在主路" | Hidden areas as scene nodes (HiddenDoor with conditional visibility) |
| `architecture.md` §2 | TileMap | "MEDIUM RISK: TileMapLayer in training but verify scene tile rotation, 4.6" | Codified with fallback strategy |
| `architecture.md` §4c | Room scenes | "TileMapLayer geometry, encounter tile markers, terminal placements, NPC placements" | Codifies scene structure |

> Foundational — this ADR codifies the *implementation* of the level system as declared in `level-dungeon.md` C-R1/C-R2/C-R4/C-R6.

## Related

- **Depends on**:
  - ADR-0001 (autoload — CollisionManager autoload)
  - ADR-0005 (Collision system — TileMapLayer.get_cell_tile_data)
- **Enables**:
  - Level/Dungeon system implementation
  - Encounter system (#16) implementation
  - Door/Lock system (#17) implementation
- **Code locations** (when implemented):
  - `data/tilesets/main_tileset.tres` (TileSet resource)
  - `scenes/rooms/chapter1_c1_room1.tscn` (first room)
  - `scenes/rooms/chapter1_c1_room{2-10}.tscn` (other rooms)
  - `src/scene/encounter_tile.gd` (EncounterTile scene node)
  - `src/scene/door.gd` (Door scene node with rotation)
  - `src/scene/terminal.gd` (Terminal scene node)
  - `src/scene/npc_controller.gd` (NPC scene node, per ADR-0008)
  - `src/autoload/collision_manager.gd` (TileMapLayer query API)
  - `tools/lint_room_scene_structure.py` (CI linter)
