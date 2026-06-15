# Control Manifest

> **Engine**: Godot 4.6
> **Last Updated**: 2026-06-12
> **Manifest Version**: 2026-06-12
> **ADRs Covered**: ADR-0001, ADR-0002, ADR-0003, ADR-0004, ADR-0005, ADR-0006, ADR-0007, ADR-0008, ADR-0009, ADR-0010, ADR-0011
> **Status**: Active — regenerate with `/create-control-manifest update` when ADRs change

`Manifest Version` is the date this manifest was generated. Story files embed
this date when created. `/story-readiness` compares a story's embedded version
to this field to detect stories written against stale rules. Always matches
`Last Updated` — they are the same date, serving different consumers.

This manifest is a programmer's quick-reference extracted from all Accepted ADRs,
technical preferences, and engine reference docs. For the reasoning behind each
rule, see the referenced ADR.

> **TD-MANIFEST gate**: SKIPPED — Solo mode (per `production/review-mode.txt`).

---

## Foundation Layer Rules

*Applies to: scene management, event architecture, save/load, engine initialisation*

### Required Patterns

- **Autoload registration order is fixed**: in `Project > Autoload` register in this order — `GameStateMachine` → `InputBus` → `ResourceRegistry` → `MetaState` → `SaveManager`. **Never reorder.** Each autoload's `_ready()` must assert all upstream autoloads exist via `get_node_or_null("/root/<Name>")`. — source: ADR-0001
- **Boot-time autoload-order error must NOT crash release build**: in dev, assertion pushes error + halts processing; in release, log only. — source: ADR-0001
- **CI linter must validate autoload order**: a pre-build script reads `project.godot [autoload]` and asserts sequence; on mismatch, exit code 1. — source: ADR-0001
- **All cross-module communication is via Godot signal**: signals only at module boundaries; direct method calls only within a single module's internals. — source: ADR-0002
- **Signal naming convention**: `<past_tense>_<subject>` snake_case. Examples: `state_changed`, `damage_dealt`, `battle_ended`, `save_completed`. Never include "signal" or "event" in the name. — source: ADR-0002
- **Signal payload is always a single Dictionary** (even for 1-arg signals): use Dictionary for forward-compat; use typed args only when contract is truly stable. — source: ADR-0002
- **Subscribers connect in `_ready()` and never manually disconnect**: Godot 4.6 signal weak refs auto-disconnect on subscriber `queue_free()`. — source: ADR-0002
- **Cross-language signals use uniform pattern**: C# `EventHandler` delegates with `Godot.Collections.Dictionary` payload. — source: ADR-0002
- **No "God Dictionary" shared globals**: each module's state is owned and exposed via signals or public methods only. — source: ADR-0002
- **No direct cross-module method calls**: use autoload + signal pattern. — source: ADR-0002
- **Stateful systems implement uniform `get_state_snapshot() / load_snapshot(snap)` contract**: SaveManager composes all producer snapshots into one file. — source: ADR-0003
- **Snapshot Dictionary is namespaced by system_name**: top-level keys are `save_version`, `saved_at_unix`, then per-system namespaces (`mech`, `inventory`, `weapon_loadout`, etc.). — source: ADR-0003
- **Snapshot contains only IDs and primitive values** (int, float, String, StringName, bool, Array, Dictionary): no Node paths, no Callable references. — source: ADR-0003
- **Forward-compat rules**: missing field → use default; type mismatch → log warning + skip; missing namespace → log warning + use default. Never crash on partial save. — source: ADR-0003
- **Save file format is JSON** (`user://save_<slot>.json`): not binary (debug-friendly). — source: ADR-0004
- **SaveManager writes async via `WorkerThreadPool.add_task()`**: main thread stall ≤ 2ms. Reads are synchronous (TITLE-screen). — source: ADR-0004
- **Always check `FileAccess.store_string()` return value**: returns `bool` in 4.4+. On `false`, emit `save_failed` and do NOT advance state. — source: ADR-0004
- **One-save-in-flight policy**: newer saves triggered while older is pending are dropped (logged). — source: ADR-0004
- **Save upgrade chain is centralized in SaveManager**: each `(from_version, to_version)` pair has a single upgrade function. Additive: adding a new function doesn't touch old ones. — source: ADR-0005
- **Backup before upgrade**: `user://save_<slot>.json` → `user://save_<slot>.bak.json` before any upgrade run. — source: ADR-0005
- **Engine version pinned to Godot 4.6.x**: patch upgrades (4.6.0 → 4.6.1) auto-approve; minor (4.6 → 4.7) require ADR bump + full review. — source: ADR-0006
- **Engine upgrade process**: read release notes → re-run `/architecture-review` → re-verify all HIGH RISK APIs at first use site → update `docs/engine-reference/godot/VERSION.md` → update CI matrix. — source: ADR-0006
- **Resource subclasses override `_set()` to enforce immutability**: allow engine deserialization (via `_is_known_export_property()` check), block runtime writes. — source: ADR-0007
- **Resource subclasses extend `ImmutableResource`** (GDScript base class) or `ImmutableResource` (C# via `[Tool]` attribute). — source: ADR-0007
- **Immutability guard must allow editor editing**: `Engine.is_editor_hint() == true` → return false (allow editor writes). — source: ADR-0007
- **All Resource fields are `@export`**: set at `.tres` edit time, immutable at runtime. — source: ADR-0007
- **Resource types are closed set**: 10 subtypes (WeaponData, AmmoData, EnemyData, MechPartData, ItemData, EffectData, TerminalLogData, StoryFragmentData, RegionData, NPCData). Adding an 11th requires GDD + ADR update. — source: ADR-0008
- **NPCData field schema**: `id: StringName`, `display_name: String`, `dialog_lines: Array[String]`, `associated_fragment: StoryFragmentData` (optional), `sprite: Texture2D` (optional), `portrait_offset_px: Vector2i` (default 0,0). — source: ADR-0008
- **Resource IDs are StringName + namespaced**: format `wpn_`, `enm_`, `itm_`, `frag_`, `npc_` etc. — source: ADR-0008 (per resource-data.md C-R7)
- **47-action InputMap is closed set**: any new action requires GDD + binding registry update. — source: ADR-0009
- **Input bindings YAML is canonical**: `design/registry/input-bindings.yaml` is the source of truth; `project.godot [input]` is generated artifact (via `tools/sync_input_bindings.py`). — source: ADR-0009
- **All action names are StringName**, not strings. — source: ADR-0009
- **Modifier keys use Godot 4.4+ `InputEventKey` fields**: `shift_pressed: true` (not "Shift" string in modifiers list). — source: ADR-0009
- **Debug actions stripped from release build**: 47 in dev → 43 in release (4 Debug actions removed). — source: ADR-0009

### Forbidden Approaches

- **Never reorder the 5 autoloads** — order is a hard correctness constraint. — source: ADR-0001
- **Never use direct cross-module method calls** — use signals at boundary. — source: ADR-0002
- **Never use static singletons** — use autoloads + signals. — source: ADR-0002
- **Never use "God Dictionary" globals** (one shared Dictionary). — source: ADR-0002
- **Never use the deprecated `TileMap` node** (pre-4.3) — use `TileMapLayer` (4.3+). — source: ADR-0010
- **Never write to Resources at runtime** — `_set()` override throws `ImmutableResourceError`. — source: ADR-0007
- **Never put a Node reference, Callable, or non-primitive in a save snapshot** — only IDs and primitive values. — source: ADR-0003
- **Never bypass the SaveManager to write a save file** — all writes go through `save_to_slot`. — source: ADR-0004
- **Never call `FileAccess.store_string()` without checking the bool return value** (4.4+). — source: ADR-0004
- **Never modify the engine version without re-running `/architecture-review`**. — source: ADR-0006
- **Never add a 48th input action** without GDD + binding registry update. — source: ADR-0009
- **Never hardcode bindings in `project.godot` directly** — must go through YAML. — source: ADR-0009
- **Never use the pre-4.3 `TileMap` class** — `TileMapLayer` only. — source: ADR-0010
- **Never place encounter tiles as actual TileMap tiles** — must be scene nodes. — source: ADR-0010

### Performance Guardrails

- **Autoload `_ready()` cost**: 5 autoloads + 30 `.tres` files ≤ 250ms total boot. — source: ADR-0001
- **Signal dispatch latency**: < 0.1ms per event. — source: ADR-0002
- **`_ready()` connection cost**: < 10ms total (50 connections). — source: ADR-0002
- **SaveManager `serialize_all()` time**: < 10ms (10 producers × 0.5ms). — source: ADR-0003
- **SaveManager `restore_all()` time**: < 20ms (10 producers × 2ms). — source: ADR-0003
- **Main thread stall during save**: < 2ms (async write via `WorkerThreadPool`). — source: ADR-0004
- **Save file size**: 1-2 KB per save (5 KB max). — source: ADR-0004
- **SaveManager load time**: < 32ms (covered by loading screen). — source: ADR-0004
- **Engine version check at boot**: < 1ms. — source: ADR-0006
- **Resource `_set()` overhead**: < 10µs per call. — source: ADR-0007
- **InputBus `InputMap.get_actions()` at boot**: < 10ms (47 actions). — source: ADR-0009
- **Per-frame input poll**: < 1ms total (47 actions polled). — source: ADR-0009

### Engine API Constraints (Godot 4.6)

- **HIGH RISK**: `@abstract` (4.5+) interaction with `Resource._set()` override. Verify at first use site. — source: ADR-0007
- **HIGH RISK**: SDL3 gamepad backend (4.5+). Hot-swap behavior may differ from pre-4.5. Verify at first use. — source: ADR-0009
- **MEDIUM RISK**: 4.6 dual-focus model (action dispatch ≠ visual focus). Both must work together. — source: ADR-0009
- **MEDIUM RISK**: 4.6 scene tile rotation API. Fallback: doors remain scene nodes (not tiles). — source: ADR-0010
- **MEDIUM RISK**: C# `Resource.Get().AsInt32()` pattern. Verify at first use. — source: ADR-0011
- **LOW RISK**: `WorkerThreadPool.add_task()` (4.0+ stable). — source: ADR-0004
- **LOW RISK**: `Dictionary` + `Variant` (4.0+ stable). — source: ADR-0003

---

## Core Layer Rules

*Applies to: core gameplay loop, main player systems, physics, collision, combat math*

### Required Patterns

- **BattleMathLib is the single source of truth for damage math** (C# static class). — source: ADR-0011
- **`CalcDamage()` 6-step formula**: (1) read fields via `Resource.Get().AsInt32()`; (2) compute raw; (3) apply MIN damage rule (max 10); (4) apply MAX damage cap (min 480); (5) apply boss one-shot immunity if applicable; (6) return. — source: ADR-0011
- **Damage canonical bounds**: MIN = 10, MAX = 480. Both enforced in `BattleMathLib.CalcDamage`. — source: ADR-0011
- **Boss one-shot immunity**: `EnemyData.boss_immune_to_one_shot: bool` (default true). When true and damage ≥ current_hp, damage = `current_hp - 1`. — source: ADR-0011
- **`BattleCore` orchestrates, `BattleMathLib` calculates**: GDScript orchestrator calls C# static method. — source: ADR-0011
- **TileMapLayer is the only tile node**: rooms have one TileMapLayer per room scene. — source: ADR-0010
- **Encounter tiles are scene nodes, not tiles**: `Area2D` with `LAYER_ENCOUNTER` (per ADR-0005 collision layer 6). — source: ADR-0010
- **Doors are scene nodes with rotation**: `StaticBody2D` + 4.6 scene tile rotation API. — source: ADR-0010
- **Collision query via `TileMapLayer.get_cell_tile_data()`**: CollisionManager owns this API. — source: ADR-0010

### Forbidden Approaches

- **Never compute damage outside `BattleMathLib.CalcDamage`**: single source of truth. — source: ADR-0011
- **Never apply damage bounds in BattleCore** (or anywhere else): the bound enforcement is centralized. — source: ADR-0011
- **Never allow a 200-HP boss to be one-shot by max 480 damage**: `boss_immune_to_one_shot=true` enforces this. Designer can opt out (tutorial boss) but default is true. — source: ADR-0011
- **Never use pre-4.3 `TileMap` node in core code**: `TileMapLayer` only. — source: ADR-0010
- **Never put encounter logic in a tile**: it's a scene node with signals. — source: ADR-0010
- **Never use `force_dispatch_pending()` (doesn't exist)**: use autoload order instead. — source: (from game-state-machine.md, referenced by ADR-0001)

### Performance Guardrails

- **`CalcDamage` latency**: < 50µs per call (5µs + 10µs cross-language). — source: ADR-0011
- **TileMapLayer memory**: 10 rooms × 375 tiles = ~5 MB atlas. — source: ADR-0010
- **Per-room frame time**: < 4ms (cull + batch). — source: ADR-0010
- **`TileMapLayer.get_cell_tile_data()` query**: < 1ms per call. — source: ADR-0010

### Engine API Constraints

- **MEDIUM RISK**: C# `Resource.Get().AsInt32()` pattern is post-cutoff. Verify at first use. — source: ADR-0011
- **MEDIUM RISK**: 4.6 scene tile rotation API. — source: ADR-0010
- **MEDIUM RISK**: C# GDExtension boundary. — source: ADR-0011

---

## Feature Layer Rules

*Applies to: secondary mechanics, AI systems, secondary features*

### Required Patterns

- **47 input actions are closed set** (per ADR-0009). — source: ADR-0009
- **Producer systems implement get/load_snapshot** (per ADR-0003). — source: ADR-0003
- **Resources are immutable at runtime** (per ADR-0007). — source: ADR-0007
- **Encounter tables are per-chapter EncounterTable resources**: weight distribution + enemy_data refs. — source: (from random-encounter.md, referenced by ADR-0001)

### Forbidden Approaches

- **Never mutate Resources at runtime** (per ADR-0007). — source: ADR-0007
- **Never add input actions without updating GDD + binding registry** (per ADR-0009). — source: ADR-0009
- **Never bypass the save/load contract** (per ADR-0003). — source: ADR-0003

### Performance Guardrails

- **Per-frame input poll**: < 1ms total (47 actions). — source: ADR-0009
- **Producer `get_state_snapshot()`**: < 0.5ms per producer. — source: ADR-0003
- **Producer `load_snapshot()`**: < 2ms per producer (with Resource ID resolution). — source: ADR-0003

---

## Presentation Layer Rules

*Applies to: rendering, audio, UI, VFX, shaders, animations*

### Required Patterns

- **32x32 pixel base unit** (per art-bible). — source: (from camera.md + art-bible)
- **NEAREST filter on all textures**: pixel art, no anti-aliasing. — source: (from camera.md)
- **No compression on spritesheet**: pixel-perfect. — source: (from camera.md)

### Forbidden Approaches

- **No `force_dispatch_pending()` (doesn't exist in any Godot version)**: use autoload order. — source: (from game-state-machine.md, referenced by ADR-0001)
- **No anti-aliasing on pixel art textures**: NEAREST only. — source: (from art-bible)

### Performance Guardrails

- **Per-frame rendering**: ≤ 16.6ms (60 FPS target). — source: technical-preferences
- **Draw calls**: ≤ 200 per scene. — source: technical-preferences
- **Memory ceiling**: ≤ 500MB. — source: technical-preferences

---

## Global Rules (All Layers)

### Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Classes | PascalCase (per `technical-preferences.md` GDScript) | `PlayerController` |
| Variables / functions | snake_case | `move_speed` |
| Signals | snake_case past tense | `health_changed` |
| Files (.gd) | snake_case matching class | `player_controller.gd` |
| Files (.cs) | PascalCase matching class | `PlayerController.cs` |
| Constants | UPPER_SNAKE_CASE (.gd) / PascalCase (.cs) | `MAX_HEALTH` |
| Autoloads | PascalCase | `GameStateMachine` |
| Resource paths | `res://data/<type>s/<id>.tres` | `res://data/weapons/wpn_laser_mk1.tres` |
| Action names | StringName snake_case | `attack_primary` |
| Enum values | PascalCase | `DoorType.WEAPON_LOCKED` |

### Performance Budgets

| Target | Value | Source |
|--------|-------|--------|
| Framerate | 60 FPS | technical-preferences.md |
| Frame budget | 16.6 ms | technical-preferences.md |
| Draw calls per scene | ~200 | technical-preferences.md |
| Memory ceiling | 500 MB (hard cap 1 GB) | technical-preferences.md |
| Save file size | 1-2 KB (max 5 KB) | ADR-0004 |

### Approved Libraries / Addons

- **GUT (Godot Unit Test)** — testing framework for GDScript. — source: technical-preferences.md
- **NUnit** — testing framework for C# (GDExtension). — source: technical-preferences.md

### Forbidden APIs (Godot 4.6)

These APIs are deprecated or unverified for Godot 4.6:

- **`TileMap` node** — deprecated since 4.3, use `TileMapLayer` instead. — source: ADR-0010
- **`force_dispatch_pending()`** — does not exist in any Godot version. — source: ADR-0001 (referenced from game-state-machine.md)
- **Static singletons** — anti-pattern in Godot 4.x. Use autoloads. — source: ADR-0001
- **Group-based singleton lookup** (`get_tree().get_first_node_in_group`) — for "find one of N" not "the singleton". — source: ADR-0002

### Cross-Cutting Constraints

- **Engine**: Godot 4.6.x (pinned, see ADR-0006). Patch upgrades auto-approve; minor upgrades require ADR bump.
- **Solo mode**: LP-FEASIBILITY and TD-MANIFEST gates skipped (per `production/review-mode.txt`).
- **All Resource fields must be `@export`**: set at `.tres` edit, never mutated at runtime.
- **All autoloads use PascalCase names**: `/root/GameStateMachine`, `/root/InputBus`, etc.
- **All cross-language signals use Dictionary payload**: GDScript signals + C# `EventHandler`.
- **Linter is the enforcer**: every rule above must have a corresponding CI linter check (or be checked at first use site).
- **Documentation in code**: doc comments on public APIs; section comments in complex logic.

---

## ADR Source Index

| ADR | Title | Rules derived |
|-----|-------|---------------|
| ADR-0001 | Scene Management & Autoload Order | 6 Required, 2 Forbidden, 2 Performance, 0 Engine |
| ADR-0002 | Event Architecture (Signal vs Direct Call) | 5 Required, 4 Forbidden, 3 Performance, 0 Engine |
| ADR-0003 | Save/Load Contract | 7 Required, 2 Forbidden, 3 Performance, 0 Engine |
| ADR-0004 | Save/Load I/O (Async Write Path) | 4 Required, 2 Forbidden, 4 Performance, 0 Engine |
| ADR-0005 | Save/Load Upgrade Path | 2 Required, 0 Forbidden, 0 Performance, 0 Engine |
| ADR-0006 | Engine Version Pin (Godot 4.6.x) | 2 Required, 1 Forbidden, 1 Performance, 0 Engine |
| ADR-0007 | Resource Immutability Guard | 4 Required, 1 Forbidden, 1 Performance, 1 Engine (HIGH RISK) |
| ADR-0008 | Resource Schema (NPCData as 10th Subtype) | 3 Required, 0 Forbidden, 0 Performance, 0 Engine |
| ADR-0009 | Input Binding Strategy | 5 Required, 3 Forbidden, 2 Performance, 1 Engine (HIGH RISK) |
| ADR-0010 | TileMap Usage | 4 Required, 2 Forbidden, 2 Performance, 1 Engine (MEDIUM RISK) |
| ADR-0011 | Damage Bounds | 4 Required, 4 Forbidden, 1 Performance, 1 Engine (MEDIUM RISK) |
| **Total** | **11 ADRs** | **46 Required, 21 Forbidden, 19 Performance, 4 Engine Risk** |

---

## Manifest Maintenance

- **When to regenerate**: after any ADR is accepted, revised, or superseded.
- **Command**: `/create-control-manifest update` (per skill argument-hint).
- **What changes**: rules derived from changed/added/superseded ADRs are added/removed/updated.
- **Story impact**: stories embedding an older `Manifest Version` are flagged by `/story-readiness` as stale.
- **CI integration**: the linters referenced in this manifest (autoload order, action count, etc.) are the executable form of these rules.

---

*End of Control Manifest v2026-06-12.*
