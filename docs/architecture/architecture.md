# Railhunter — Master Architecture

## Document Status

- **Version**: 1.0
- **Last Updated**: 2026-06-12
- **Engine**: Godot 4.6 (GDScript + C#)
- **GDDs Covered**: 12 MVP GDDs (Foundation 5 + Core 1 + Feature 4 + Presentation 2)
- **ADRs Referenced**: 0 (none yet — this doc is the blueprint that motivates ADRs)
- **TR Coverage**: 155 technical requirements extracted from 12 GDDs, registered at `docs/architecture/tr-registry.yaml`
- **Review Mode**: solo (per `production/review-mode.txt`)
- **Director Sign-Off**: APPROVED WITH CONCERNS (lean self-review 2026-06-12 — see §10)
- **Lead Programmer Feasibility**: SKIPPED — solo mode (see §10)

---

## 1. Architecture Principles

These 5 principles govern all technical decisions for Railhunter. They are derived from the game concept, all 12 GDDs, and the engine's strengths.

1. **Foundation-first dependency order** — Foundation → Core → Feature → Presentation → Polish. No upward dependencies. A Feature system may depend on Core; a Core system may depend on Foundation; a Foundation system depends on nothing in the game layer.
2. **Data-driven, never hardcoded** — All gameplay values (weapons, enemies, ammo, mech parts, items, effects, terminal logs, story fragments, regions) are `Resource` `.tres` files owned by the Resource/Data system. Code reads from resources; code never contains literal balance values.
3. **State is owned, not scattered** — Game state lives in named autoloads (`GameStateMachine`, `InputBus`, `MetaState`, `ResourceRegistry`, `SaveManager`). Each piece of state has exactly one owner. Reading = query the owner; writing = call the owner's API.
4. **Signals at the module boundary, methods within** — Cross-module communication uses Godot signals. Within a module, direct method calls are fine. Never call across language boundaries directly — use signals.
5. **Prototype before polish** — Every Core and Feature system was prototype-validated before its GDD was written (Battle Core + Weapon/Ammo specifically). The architecture preserves this: any system with prototype-validated mechanics gets the implementation language split (C# math + GDScript orchestration) to keep iteration fast.

---

## 2. Engine Knowledge Gap Summary

**Engine**: Godot 4.6 — **HIGH RISK** (post-LLM-cutoff; LLM training covers ~4.3 only)
**Verified against**: `docs/engine-reference/godot/` (pinned 2026-02-12)

### 2a. HIGH RISK Domains (flagged throughout this doc, ADRs will reference engine docs at use sites)

| Domain | Post-Cutoff Change | Our Touch | Mitigation |
|---|---|---|---|
| **Core** | `FileAccess.store_*` return `bool` (was `void`) in 4.4 | `SaveManager` async write path | Verify `FileAccess.open_write()` + `store_string()` return handling |
| **Input** | Dual-focus system (4.6) — mouse/touch separate from keyboard/gamepad | HUD, Menu, Codex, Pause UI | Test both focus paths; `grab_focus()` only affects keyboard/gamepad |
| **Input** | SDL3 gamepad backend (4.5) — device hot-swap behavior | Player Input bindings (47 actions) | Verify device hot-swap re-resolves bindings; no assumption of stable device ID |
| **TileMap** | `TileMapLayer` replaces `TileMap` (4.3+, in training but verify) | Level/Dungeon room geometry | Use `TileMapLayer`, never `TileMap` |
| **UI** | Dual-focus + FoldableContainer (4.5) + Recursive Control | HUD, Codex, Menu | Use `FoldableContainer` for collapsible sections |
| **Resource** | `duplicate_deep()` (4.5) | Resource immutability guard | Use `duplicate_deep()` for any nested resource copies (none expected in MVP) |
| **GDScript** | `@abstract` decorator (4.5), variadic args (4.5) | Abstract base classes for Resource subtypes | Use `@abstract` for `ResourceData` base if we add one |
| **Accessibility** | AccessKit screen reader (4.5) | TBD — not in MVP scope | Defer to VS phase |

### 2b. 6 HIGH-Risk Technical Requirements (extracted from 155 TRs)

| TR ID | Domain | Requirement | Resolution |
|---|---|---|---|
| TR-resource-data-003 | Resource | Runtime immutability of loaded Resource via `_set()` guard | ADR-XXXX (linter) — defer to Technical Setup ADR work |
| TR-resource-data-005 | Resource | Cross-language field access from C# via `Resource.Get("field").AsInt32()` | **Documented in resource-data.md §"跨语言访问"** — no ADR needed |
| TR-resource-data-014 | Resource | `TypedArray[EffectData]` in `@export` fields | **Documented in resource-data.md** — Godot 4.6 native |
| TR-resource-data-015 | BuildTool | Engine version pin 4.6.x at startup | **ADR-ENGINE-VERSION** — proposed ADR in §8 |
| TR-player-input-008 | Input | SDL3 gamepad device hot-swap | **ADR-INPUT-BINDING** — proposed ADR in §8 |
| TR-level-dungeon-001 | Engine | `TileMapLayer` for room geometry | **Documented in level-dungeon.md** — Godot 4.6 API |

---

## 3. System Layer Map

Strict 5-layer model (per user decision 2026-06-12 + `systems-index.md`).

```
┌─────────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER                                         │  ← HUD only (MVP)
├─────────────────────────────────────────────────────────────┤
│  FEATURE LAYER                                              │  ← Weapon&Ammo, Level,
│                                                            │     Random Encounter, NPC/Terminal
├─────────────────────────────────────────────────────────────┤
│  CORE LAYER                                                 │  ← Player Input, Camera, Collision,
│                                                            │     Battle Core Loop
├─────────────────────────────────────────────────────────────┤
│  FOUNDATION LAYER                                           │  ← Resource/Data, GameStateMachine,
│                                                            │     SaveManager (promoted from
│                                                            │     Presentation, 2026-06-12 decision)
├─────────────────────────────────────────────────────────────┤
│  PLATFORM LAYER (Godot 4.6 2D runtime)                      │  ← Engine APIs, OS, FileAccess
└─────────────────────────────────────────────────────────────┘
```

### 3a. Foundation Layer (autoloads + Foundation GDDs)

| Module | Type | Language | Owns | Touches HIGH RISK? |
|---|---|---|---|---|
| `GameStateMachine` | autoload | GDScript | State stack, transition logic | No |
| `InputBus` | autoload | GDScript | Input action dispatch, top-of-stack routing | **YES (dual-focus 4.6, SDL3 gamepad)** |
| `MetaState` | autoload | GDScript | `discovered` + `unlocked` dictionaries | No |
| `ResourceRegistry` | autoload | GDScript | All `.tres` instances, ID lookup, ID uniqueness validation | No |
| `SaveManager` | autoload (promoted from Presentation, 2026-06-12) | GDScript | Save/load orchestration, save version, autosave triggers | **YES (FileAccess 4.4)** |
| Resource subtypes (`WeaponData`, etc.) | Resource `.tres` | GDScript | Static data; immutable at runtime | **YES (immutability guard, `@abstract` 4.5)** |

### 3b. Core Layer

| Module | Type | Language | Owns |
|---|---|---|---|
| `PlayerController` | Scene (`Player.tscn`) | GDScript | Player position, movement, mech 4-part HP, weapon slot focus, ammo slot focus |
| `Camera2D` | Scene | GDScript | Camera position, follow logic, room bounds |
| `CollisionManager` | autoload | GDScript | Tile-based collision query API |
| `BattleCore` | autoload (C# math + GDScript orchestration) | **C# + GDScript** | Turn order, manual/auto mode switch, damage calc, victory/defeat detection |
| `BattleMathLib` (C#) | static class | C# | `CalcDamage(weapon, ammo, target) -> int`, `CalcCrit(weapon, rng) -> int`, `MinDamageRule(d) -> int` |

**Battle Core split** (per user decision 2026-06-12):
- **C#** = math (pure functions, deterministic, testable, no Node dependencies)
- **GDScript** = orchestration (state machine, AI decision tree, signal emission)
- Boundary: C# exposes `static` methods; GDScript calls them via `BattleMathLib.CalcDamage(...)`. Signals emitted by GDScript, not C#.

### 3c. Feature Layer

| Module | Type | Language | Owns |
|---|---|---|---|
| `Inventory` | autoload (or in `Player` scene) | GDScript | weapon slots, ammo inventory, item stacks |
| `WeaponLoadout` | autoload | GDScript | current weapon + ammo selection, slot switching |
| `TileMapLayer` room scenes | Scene (`.tscn`) | GDScript | Room geometry, encounter tile placement, hidden rooms, terminal placement, NPC placement |
| `EncounterManager` | autoload | GDScript | Encounter tile trigger, encounter table per room, `replace(EXPLORATION→BATTLE)` call |
| `TerminalPlayer` | Scene | GDScript | Audio log playback, fragment unlock, push(TERMINAL) state |
| `NPCController` | Scene | GDScript | NPC dialogue, fragment grant |

### 3d. Presentation Layer

| Module | Type | Language | Owns |
|---|---|---|---|
| `HUD` | Scene (CanvasLayer) | GDScript | HP bars, weapon/ammo display, mode indicator (MANUAL/AUTO), encounter count, fragment count, state badge |
| `Codex` | Scene (push CODEX) | GDScript | Weapon/enemy/region bestiary |
| `Menu` | Scene (push MENU) | GDScript | Settings, save slots (MVP: 1 autosave + 3 manual) |
| `TerminalUI` | Scene (push TERMINAL) | GDScript | Transcript display, audio playback controls |
| `DamageNumbers` | Scene (CanvasLayer overlay) | GDScript | Floating damage numbers, crit indicator, weak-point indicator |

---

## 4. Module Ownership Map

For each module: **Owns** (sole responsibility) · **Exposes** (public API) · **Consumes** (reads) · **Engine APIs used** (with version + risk).

### 4a. Foundation Layer

#### `GameStateMachine` (autoload, GDScript)

- **Owns**: `state_stack: Array[StringName]`, `top_of_stack: StringName`, `ALLOWED_TRANSITIONS` table
- **Exposes**: `transition_to(state) -> Error`, `push(state) -> Error`, `pop() -> Error`, `get_state_snapshot() -> Dictionary`, `load_snapshot(snap: Dictionary)`, signal `state_changed(old, new)`
- **Consumes**: `InputBus.top_of_stack` (read-only) for routing
- **Engine APIs**: `Node.tree_entered`, `Node.tree_exited`, `get_tree().paused` — all 4.0+, **LOW RISK**

#### `InputBus` (autoload, GDScript)

- **Owns**: subscriber list per state, current input focus context
- **Exposes**: `subscribe(state, callable)`, `unsubscribe(state, callable)`, `dispatch(action)`, `is_action_just_pressed(action)`, `is_action_pressed(action)`, `get_vector(...)`
- **Consumes**: `GameStateMachine.top_of_stack`
- **Engine APIs**: `Input.is_action_*`, `Input.get_vector` — all 4.0+, **LOW RISK** for basic API
- **HIGH RISK**: **dual-focus 4.6** — `Input.is_action_just_pressed` covers both mouse/touch and keyboard/gamepad, but visual focus (HUD highlighting) is now separate. `grab_focus()` only affects keyboard/gamepad. Our input map is 47 actions (see `design/registry/input-bindings.yaml`); visual focus for HUD must be tested with both input methods.

#### `MetaState` (autoload, GDScript)

- **Owns**: `discovered: Dictionary[StringName, bool]`, `unlocked: Dictionary[StringName, bool]`
- **Exposes**: `mark_discovered(id)`, `mark_unlocked(id)`, `is_discovered(id) -> bool`, `is_unlocked(id) -> bool`, `serialize() -> Dictionary`, `deserialize(snap)`, signal `entity_discovered(id)`
- **Consumes**: Resource references (for ID lookup)
- **Engine APIs**: `Dictionary[StringName, bool]` typed dict (4.4+) — **LOW RISK**

#### `ResourceRegistry` (autoload, GDScript)

- **Owns**: All loaded `.tres` instances indexed by `id: StringName`
- **Exposes**: `get(id: StringName) -> Resource`, `get_all_of_type(type: StringName) -> Array`, `load_all() -> Error` (called on boot)
- **Consumes**: `res://data/**/*.tres` (file system scan)
- **Engine APIs**: `ResourceLoader.load(path)`, `DirAccess.get_files_at()`, `Resource.get_local_scene()` — all 4.0+, **LOW RISK**

#### `SaveManager` (autoload, GDScript — promoted from Presentation 2026-06-12)

- **Owns**: Save slot management, save version, autosave trigger logic, async write queue
- **Exposes**: `save_to_slot(slot: int) -> Error`, `load_from_slot(slot: int) -> Error`, `get_autosave() -> Error`, `restore_last_save() -> Error`, `serialize_all() -> Dictionary` (calls all 10 producer systems' `get_state_snapshot()`), signal `save_completed(slot)`, `save_failed(error)`, `load_completed`, `load_failed`
- **Consumes**: 10 systems' `get_state_snapshot() / load_snapshot(snap)` contracts (Resource/Data, GameStateMachine, Inventory, WeaponLoadout, BattleCore, Level, EncounterManager, NPC/Terminal, PlayerController, HUD settings)
- **Engine APIs**: `FileAccess.open_write()`, `FileAccess.open_read()`, `FileAccess.store_string()` returns `bool` (4.4) — **HIGH RISK**: must check return value, treat `false` as save error → emit `save_failed`. `FileAccess.flush()` — **LOW RISK**. `JSON.stringify()` / `JSON.parse_string()` — **LOW RISK**

#### Resource Subtypes (`.tres` files, GDScript `class_name`)

- **Owns**: Static gameplay data
- **Exposes**: `@export` fields (read-only at runtime — immutability guard in `_set()`)
- **Consumes**: Other Resource references (WeaponData → AmmoData.Type, etc.)
- **Engine APIs**: `Resource` base class, `@export`, `@export_range`, `@export_group` — **LOW RISK**
- **HIGH RISK**: **Immutability guard** — `Resource._set()` override in each subclass throws `ImmutableResourceError` on any write. Verify against 4.6 `Resource._set()` signature (4.5+ `@abstract` may interact — needs verification at first use site).

### 4b. Core Layer

#### `PlayerController` (Scene, GDScript)

- **Owns**: `position: Vector2`, `mech_parts: Dictionary[PartType, int]` (4-part HP), `current_weapon_slot: int`, `current_ammo: StringName`
- **Exposes**: `move(direction)`, `take_damage(part: PartType, amount: int)`, `heal(part, amount)`, `set_weapon_slot(idx)`, `set_ammo(id)`, signal `hp_changed(part, new_hp)`, `weapon_switched(new_slot)`, `ammo_switched(new_id)`
- **Consumes**: `InputBus` (movement input), `Inventory` (weapon data), `WeaponLoadout` (current selection)
- **Engine APIs**: `CharacterBody2D`, `move_and_slide()`, `get_tree().paused` — **LOW RISK** (2D physics unchanged in 4.6)

#### `Camera2D` (Scene, GDScript)

- **Owns**: Camera position, follow target, room bounds (when entering new room)
- **Exposes**: `set_room_bounds(rect: Rect2)`, `set_follow_target(node: Node2D)`
- **Consumes**: `PlayerController.position` (follow)
- **Engine APIs**: `Camera2D.position_smoothing_enabled`, `Camera2D.limit_*` — **LOW RISK**

#### `CollisionManager` (autoload, GDScript)

- **Owns**: Collision query API
- **Exposes**: `tile_at(pos: Vector2) -> int`, `is_walkable(pos: Vector2) -> bool`, `get_overlapping_bodies(area) -> Array`
- **Consumes**: `TileMapLayer.get_cell_tile_data()` — **LOW RISK** (TileMapLayer in training)
- **Engine APIs**: `TileMapLayer` (replaces deprecated `TileMap` since 4.3), `PhysicsShapeQueryParameters2D` — **LOW RISK**

#### `BattleCore` (autoload, GDScript orchestration + C# math)

- **Owns**: Battle state (turn order, current actor, mode = MANUAL/AUTO), battle enemies
- **Exposes**: `start_battle(enemies: Array[BattleEnemy])`, `end_battle(victory: bool)`, `switch_mode()`, signal `battle_started`, `battle_ended`, `mode_switched`, `turn_started(actor)`, `turn_ended(actor)`, `damage_dealt(target, amount, is_crit)`
- **Consumes**: `PlayerController`, `Inventory`, `WeaponLoadout`, `ResourceRegistry` (enemy data)
- **Engine APIs**: State machine pattern, signal-heavy — **LOW RISK**

#### `BattleMathLib` (C# static class)

- **Owns**: Pure math (no state)
- **Exposes**: `static int CalcDamage(WeaponData weapon, AmmoData ammo, EnemyData target, bool is_crit)`, `static int ApplyMinDamageRule(int raw)`, `static bool RollHit(float accuracy, int seed)`, `static int RollCrit(float crit_chance, int seed)`
- **Consumes**: Resource data via `weapon.Get("min_damage").AsInt32()` pattern (per resource-data.md cross-language access section)
- **Engine APIs**: None (pure C# math)
- **Engine version check**: C# `.Get().AsInt32()` — verify at first use site. 4.6 `Resource.Get` should return `Variant` (4.4 change)

### 4c. Feature Layer (abbreviated — see individual GDDs for detail)

- **`Inventory`** — owns weapon slots + ammo counts + item stacks. Exposes `add_weapon(weapon)`, `add_ammo(id, qty)`, `use_item(id)`. Consumes `ResourceRegistry`. **LOW RISK**.
- **`WeaponLoadout`** — owns current weapon + ammo. Exposes `set_weapon(idx)`, `set_ammo(id)`. **LOW RISK**.
- **Room scenes (`*.tscn`)** — `TileMapLayer` geometry, encounter tile markers, terminal placements, NPC placements. **TileMapLayer API** (4.3+) — **MEDIUM RISK** (in training but verify scene tile rotation, 4.6).
- **`EncounterManager`** — owns encounter tables per room. Exposes `check_encounter(pos) -> bool`. Calls `GameStateMachine.transition_to(BATTLE)`. **LOW RISK**.
- **`TerminalPlayer`** — owns audio log playback state. Calls `GameStateMachine.push(TERMINAL)`. **LOW RISK**.
- **`NPCController`** — owns NPC dialogue state. **LOW RISK**.

### 4d. Presentation Layer (abbreviated)

- **`HUD`** — CanvasLayer. Subscribes to `state_changed`, `hp_changed`, `weapon_switched`, `ammo_switched`, `mode_switched`, `entity_discovered`. **MEDIUM RISK** (dual-focus 4.6).
- **`Codex` / `Menu` / `TerminalUI`** — push overlays. **MEDIUM RISK** (dual-focus).
- **`DamageNumbers`** — overlay that listens to `damage_dealt` signal. **LOW RISK**.

---

## 5. Data Flow

### 5a. Frame Update Path (Exploration)

```
┌──────────────────────────────────────────────────────────────────────┐
│  Input → State query → Player update → Camera follow → Render         │
└──────────────────────────────────────────────────────────────────────┘

1. _physics_process(delta):
2.   GameStateMachine.top_of_stack  (read-only)
3.   if top == &"state_exploration":
4.     InputBus.dispatch_to(exploration_subscribers, "move_*")
5.     PlayerController.move(direction)  → CharacterBody2D.move_and_slide()
6.     Camera2D.update_follow(player.position)
7.   EncounterManager.check_encounter(player.position)  (if new tile)
8.   if encounter: GameStateMachine.transition_to(BATTLE)
9.   _process(delta):
10.    HUD.update_all_displays()  (reads Player + WeaponLoadout + MetaState)
11.    Renderer renders frame
```

### 5b. Event/Signal Path (cross-module decoupling)

| Signal | Emitter | Listener | Use case |
|---|---|---|---|
| `state_changed(old, new)` | GameStateMachine | HUD, EncounterManager, BattleSceneSwitch | State badge, load/unload scenes |
| `entity_discovered(id)` | MetaState | Codex, HUD (popup), StoryMap | New resource unlocked → "新发现！" |
| `hp_changed(part, hp)` | PlayerController | HUD, BattleCore (mode-priority AI) | HP bar update, AI decides defend |
| `weapon_switched(slot)` | PlayerController | HUD, BattleCore | Weapon display update |
| `damage_dealt(target, amt, is_crit)` | BattleCore | DamageNumbers, HUD | Visual feedback |
| `save_completed(slot)` | SaveManager | HUD (toast) | "已自动保存" |
| `save_failed(error)` | SaveManager | HUD (red text) | "保存失败" |
| `load_completed` | SaveManager | GameStateMachine (transition) | Resume from save |

### 5c. Save/Load Path

```
SAVE:
  SaveManager.save_to_slot(slot):
    1. snap = {}
    2. snap["save_version"] = SAVE_VERSION_CURRENT
    3. snap["saved_at_unix"] = Time.get_unix_time_from_system()
    4. snap.merge(GameStateMachine.get_state_snapshot())       # state_stack
    5. snap.merge(PlayerController.get_state_snapshot())       # pos, mech_parts, current_weapon
    6. snap.merge(Inventory.get_state_snapshot())              # weapon_slots, ammo_inventory
    7. snap.merge(WeaponLoadout.get_state_snapshot())          # current_ammo
    8. snap.merge(BattleCore.get_state_snapshot())             # if in battle (else empty)
    9. snap.merge(LevelManager.get_state_snapshot())           # current_room_id, player_pos
   10. snap.merge(EncounterManager.get_state_snapshot())        # encounter_count
   11. snap.merge(NPCTerminal.get_state_snapshot())            # unlocked_fragments, read_logs
   12. snap.merge(MetaState.serialize())                       # discovered_ids, unlocked_ids
   13. snap.merge(HUD.get_settings_snapshot())                  # font_size, show_damage_numbers
   14. json = JSON.stringify(snap, "  ")
   15. file = FileAccess.open_write("user://save_N.json")
   16. if not file.store_string(json):  # 4.4 returns bool
   17.   save_failed.emit(IO_ERROR)
   18.   return ERR_FILE_CANT_WRITE
   19. file.flush()  # 4.4 returns Error
   20. save_completed.emit(slot)

LOAD:
  SaveManager.load_from_slot(slot):
    1. if not FileAccess.file_exists("user://save_N.json"):
    2.   return ERR_FILE_NOT_FOUND  (silent → TITLE)
    3. file = FileAccess.open_read("user://save_N.json")
    4. json = file.get_as_text()
    5. snap = JSON.parse_string(json)
    6. if snap == null:  (parse failure)
    7.   load_failed.emit(CORRUPT)
    8.   return ERR_PARSE_ERROR
    9. if snap["save_version"] != SAVE_VERSION_CURRENT:
   10.   snap = upgrade_path(snap)  (per ADR-SAVE-UPGRADE)
   11. validate_snapshot(snap)  (per ADR-SAVE-CONTRACT)
   12. # Push loading screen overlay
   13. GameStateMachine.load_snapshot(snap["state_stack"])
   14. PlayerController.load_snapshot(snap["player"])
   15. ... (10 systems)
   16. GameStateMachine.transition_to(snap["top_of_stack"])
   17. load_completed.emit()
```

### 5d. Initialisation Order (Autoloads)

**Per game-state-machine.md C-R6 — autoload order is a hard constraint** (re-verified):

```
Project > Autoload (in this order):
  1. GameStateMachine     ← loads first, defines state semantics
  2. InputBus             ← depends on GameStateMachine.top_of_stack
  3. ResourceRegistry     ← loads all .tres on boot
  4. MetaState            ← reads ResourceRegistry for known IDs
  5. SaveManager          ← depends on all 10 producer systems (lazy-init OK)
```

Resource sub-types (10 `.tres` types) are loaded by `ResourceRegistry.load_all()` on boot. They are NOT autoloads — they are loaded as needed via `ResourceRegistry.get(id)`.

---

## 6. API Boundaries

### 6a. Save/Load Contract (per cross-review [2a-1] Rec)

**Every state-owning system MUST implement**:
```gdscript
# GDScript signature
func get_state_snapshot() -> Dictionary:
    """Returns a Dictionary containing all state this system owns.
    Must be deterministic — same state → same snapshot."""
    pass

func load_snapshot(snap: Dictionary) -> void:
    """Restores state from snapshot. Missing fields → default values.
    Type mismatches → log warning, use default. Never crash."""
    pass
```

**10 systems implementing this contract** (per save-load.md):
- `GameStateMachine` (state_stack)
- `PlayerController` (pos, mech_parts, current_weapon)
- `Inventory` (weapon_slots, ammo_inventory)
- `WeaponLoadout` (current_ammo)
- `BattleCore` (battle_state — empty if not in battle)
- `LevelManager` (current_room_id, player_pos)
- `EncounterManager` (encounter_count)
- `NPCTerminal` (unlocked_fragments, read_logs)
- `MetaState` (discovered_ids, unlocked_ids)
- `HUD` (settings)

This contract is **added in OQ** of each producer GDD (per save-load.md Rec #3) and will be codified in **ADR-SAVE-CONTRACT** during Technical Setup.

### 6b. Cross-Language Boundary (GDScript ↔ C#)

**Per resource-data.md §"跨语言访问"**:

- C# never redefines Resource subclasses — uses `ResourceLoader.Load<Resource>(path)` + `.Get("field_name").AsInt32()` pattern
- GDScript calls C# static methods via `BattleMathLib.CalcDamage(weapon, ammo, target, false)`
- Signals emitted by GDScript, not C# (C# math is pure)
- **No direct C# → GDScript instance method calls** — use signals at the boundary

### 6c. InputBus Contract (per game-state-machine.md C-R4 + player-input.md E9)

- Every state-owning scene subscribes in `_ready()` and unsubscribes in `_exit_tree()`
- `subscribe(state: StringName, callable: Callable)` adds to subscriber list
- `unsubscribe(state: StringName, callable: Callable)` removes (weak ref for safety)
- `dispatch(action: StringName)` queries `GameStateMachine.top_of_stack` and calls that state's subscribers

---

## 7. ADR Audit (existing ADRs)

**0 ADRs exist** in `docs/architecture/`. This section is the *gap analysis* — what ADRs are needed to support this architecture.

### 7a. Required ADRs (full list — see §8 for priority)

| ADR | Title | Covers | Layer |
|---|---|---|---|
| **ADR-SAVE-IO** | Async save write path (FileAccess 4.4) | Save/Load C-R6 | Foundation |
| **ADR-SAVE-UPGRADE** | Centralized `upgrade_path()` ownership | Save/Load C-R5 | Foundation |
| **ADR-SAVE-CONTRACT** | `get_state_snapshot() / load_snapshot(snap)` contract | Save/Load Rec #3 | Foundation |
| **ADR-RESOURCE-SCHEMA** | NPCData as 10th Resource subtype | Cross-review [2b-1] | Foundation |
| **ADR-DAMAGE-BOUNDS** | Canonical damage range 10-480, `boss_immune_to_one_shot` | Cross-review [2b-4][3c-1] | Core |
| **ADR-SCENE-MANAGEMENT** | Scene autoload order, transition lifecycle | GameStateMachine C-R4-C-R6 | Foundation |
| **ADR-EVENT-ARCHITECTURE** | Signal-based module decoupling, naming convention | All modules | Foundation |
| **ADR-INPUT-BINDING** | 47-action InputMap source-of-truth + SDL3 device hot-swap (4.5+) | Player Input + TR-player-input-008 | Core |
| **ADR-ENGINE-VERSION** | Engine pin policy 4.6.x + upgrade process | TR-resource-data-015 | Foundation |
| **ADR-RESOURCE-IMMUTABILITY** | `_set()` guard pattern for Resource subtypes | TR-resource-data-003 | Foundation |
| **ADR-TILEMAP-USAGE** | `TileMapLayer` only — never `TileMap` (deprecated 4.3) | TR-level-dungeon-001 | Core |

**11 total ADRs** needed. Priority order: §8.

---

## 8. Required ADRs (Priority Order)

### Must have before any coding starts (Foundation)

1. **`/architecture-decision "Scene Management & Autoload Order"` → ADR-SCENE-MANAGEMENT**
   - Defines Project > Autoload order (per §5d)
   - Codifies GameStateMachine C-R6 hard constraint
   - **Unblocks**: every other system (autoloads are the foundation)

2. **`/architecture-decision "Event Architecture (Signal vs Direct Call)"` → ADR-EVENT-ARCHITECTURE**
   - Defines cross-module signal naming convention
   - Documents when to use signal vs method call vs shared state
   - Codifies principle #4 (signals at boundary, methods within)
   - **Unblocks**: HUD, EncounterManager, BattleCore (all signal-heavy)

3. **`/architecture-decision "Save/Load Contract"` → ADR-SAVE-CONTRACT**
   - Codifies `get_state_snapshot() / load_snapshot(snap)` for 10 systems
   - **Unblocks**: SaveManager + all 10 producer systems

4. **`/architecture-decision "Save/Load I/O (Async Write Path)"` → ADR-SAVE-IO**
   - FileAccess 4.4 `store_string()` return value handling
   - Async write queue + error path
   - **Unblocks**: SaveManager implementation

5. **`/architecture-decision "Save/Load Upgrade Path" → ADR-SAVE-UPGRADE**
   - Centralized `upgrade_path(v_old → v_new)` ownership (SaveManager)
   - Version migration policy
   - **Unblocks**: SaveManager (after ADR-SAVE-CONTRACT)

6. **`/architecture-decision "Engine Version Pin" → ADR-ENGINE-VERSION**
   - 4.6.x pin policy
   - Upgrade process: any engine upgrade PR must re-run `/architecture-review` to re-validate
   - **Unblocks**: Build/CI setup

7. **`/architecture-decision "Resource Immutability Guard" → ADR-RESOURCE-IMMUTABILITY**
   - `_set()` override pattern for Resource subtypes
   - Verification against 4.6 `Resource._set()` signature (HIGH RISK — needs godot-specialist at use site)
   - **Unblocks**: Resource data layer

8. **`/architecture-decision "Resource Schema (NPCData subtype)" → ADR-RESOURCE-SCHEMA**
   - Adds NPCData as 10th Resource subtype (per cross-review [2b-1])
   - Cross-doc fix: `#npc-terminal.md` ↔ `#resource-data.md`
   - **Unblocks**: NPC/Terminal system implementation

### Must have before Core layer is built

9. **`/architecture-decision "Input Binding Strategy"` → ADR-INPUT-BINDING**
   - 47-action InputMap source-of-truth at `design/registry/input-bindings.yaml`
   - SDL3 device hot-swap behavior (4.5+ HIGH RISK per TR-player-input-008)
   - **Unblocks**: Player Input + all input consumers (HUD, BattleCore, etc.)

10. **`/architecture-decision "TileMap Usage" → ADR-TILEMAP-USAGE**
    - `TileMapLayer` only — `TileMap` deprecated since 4.3
    - Scene tile rotation API (4.6 new)
    - **Unblocks**: Level/Dungeon implementation

11. **`/architecture-decision "Damage Bounds" → ADR-DAMAGE-BOUNDS**
    - Canonical damage range 10-480 (per cross-review [2b-4])
    - `boss_immune_to_one_shot` flag (per cross-review [3c-1] Pillar 3 bypass fix)
    - **Unblocks**: BattleCore + Damage Calc GDDs

### Should have before relevant Feature system is built

- ADR-DAMAGE-CALC (defer to Damage Calc GDD phase)
- ADR-ENEMY-AI (defer to Enemy AI GDD phase)
- ADR-PARTY (N/A — single-player)

### Can defer to implementation

- Specific shader techniques (no 3D, no water)
- Per-asset visual specs (defer to /asset-spec)
- Audio mix details (defer to Audio GDD)

---

## 9. Architecture Principles (Recap)

1. Foundation-first dependency order
2. Data-driven, never hardcoded
3. State is owned, not scattered
4. Signals at the module boundary, methods within
5. Prototype before polish

These are also codified in the control manifest (`docs/architecture/control-manifest.md`, generated by `/create-control-manifest` after ADRs are accepted).

---

## 10. Director Sign-Off

**Technical Director (TD-ARCHITECTURE gate)**: **APPROVED WITH CONCERNS** (lean self-review 2026-06-12). 
Rationale: all 4 TD-ARCHITECTURE gate criteria met (completeness, layered decomposition, data flow + autoload order documented, all 6 HIGH RISK domains flagged with mitigation). One open CONCERN: cross-system runtime dependency chain verification deferred to implementation phase.

**Lead Programmer Feasibility (LP-FEASIBILITY gate)**: **SKIPPED — solo mode**. Per skill definition: "solo → skip. Note: 'LP-FEASIBILITY skipped — Solo mode.'"

**Self-review notes (this is a lean-mode self-review)**:
- ✅ All 12 MVP GDDs have a home in the layer map
- ✅ All 155 TRs are covered (either by an existing pattern or by an ADR in §8)
- ✅ 4 cross-GDD BLOCKERs are addressed by ADRs (NPCData → ADR-RESOURCE-SCHEMA, ammo consumption → ADR-SAVE-CONTRACT, HUD AC-18 hardcode → ADR-DAMAGE-BOUNDS cross-cut, auto-mode Pillar 3 bypass → ADR-DAMAGE-BOUNDS)
- ✅ 6 HIGH-risk TRs are flagged with engine version verification
- ✅ Save/Load promoted to Foundation (per user decision 2026-06-12)
- ✅ Battle Core split (C# math + GDScript orchestration) per user decision 2026-06-12
- ✅ Strict 5-layer model maintained
- ⚠️ **CONCERN — DEPENDENCIES NOT FULLY VERIFIED**: BattleCore ← Weapon&Ammo ← BattleMathLib ← Inventory ← SaveManager dependency chain. All chains documented in §3-4 but cross-system runtime verification deferred to implementation. Resolution: First implementation PR must include end-to-end smoke test exercising the chain.

---

## 11. Open Questions

| ID | Summary | Priority | Resolution Path |
|----|---------|----------|-----------------|
| QQ-01 | BattleCore AI decision tree algorithm (manual/auto dual-mode priority) | High | Battle Core Loop GDD (already Approved) + ADR-DAMAGE-BOUNDS (auto-mode Pillar 3 fix) |
| QQ-02 | Resource immutability verification against 4.6 `_set()` signature | High | First Resource subclass implementation + godot-specialist review |
| QQ-03 | 47-action InputMap device hot-swap behavior (SDL3 4.5+) | Medium | First gamepad connection in dev + ADR-INPUT-BINDING |
| QQ-04 | 2 cross-doc loops (encounter count, fragment count) | Medium | Re-review loop GDDs in Pre-Production |
| QQ-05 | NPCData Resource subtype definition (per [2b-1]) | High | ADR-RESOURCE-SCHEMA + npc-terminal.md update |

---

## 12. Traceability Summary

| Metric | Count |
|---|---|
| GDDs covered | 12 (5 Foundation + 1 Core + 4 Feature + 2 Presentation) |
| Technical Requirements | 155 (across 14 domains) |
| HIGH-risk TRs | 6 (flagged in §2a) |
| Existing ADRs | 0 |
| Required ADRs (must have) | 11 (§8) |
| Cross-GDD BLOCKERs | 4 (all addressed by ADRs) |
| Open Questions | 5 |

**Coverage**: 100% of GDD requirements have an architectural home. No GDD requirement is architecturally orphaned.
