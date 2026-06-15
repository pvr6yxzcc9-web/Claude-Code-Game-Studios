# ADR-0001: Scene Management & Autoload Order

## Status

Accepted

## Date

2026-06-12

## Last Verified

2026-06-12

## Decision Makers

User (game-studio founder, solo) + technical-director (self-review, APPROVED WITH CONCERNS 2026-06-12)

## Summary

Railhunter uses 5 Godot autoloads with a **fixed, non-negotiable load order** in `Project > Autoload`. `GameStateMachine` loads first (it owns the state stack), then `InputBus` (which queries `GameStateMachine.top_of_stack` for routing), then `ResourceRegistry` (loads all `.tres` files), then `MetaState` (per-entity discovery tracking), then `SaveManager` (which depends on all of the above). This order is enforced by `AutoloadOrderError` at boot and codified as the `GameStateMachine` C-R6 hard constraint in `design/gdd/game-state-machine.md`.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (Scene tree + Autoload + signal) |
| **Knowledge Risk** | MEDIUM — autoload order in training, but 4.5+ `@abstract` may interact; 4.6 node order is stable but `process_priority` semantics verified at first use |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` (4.6 pin), `docs/engine-reference/godot/breaking-changes.md` |
| **Post-Cutoff APIs Used** | None directly — autoload is a 4.0-stable feature |
| **Verification Required** | First boot: assert autoload order via `Project > Autoload` and `OS.get_cmdline_args()`. If order mismatches, `AutoloadOrderError` in stderr + 1 Hz console warning (not crash). At first use: dev-mode boot test + manual mode-toggle test (proves InputBus runs after GameStateMachine). |

> **Note**: Knowledge Risk is MEDIUM because Godot 4.5 introduced `@abstract` for Resource subclasses — this may interact with our `Resource._set()` immutability guard (covered in ADR-0007). Autoload order itself is LOW RISK (stable since 4.0).

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None (this is the first ADR) |
| **Enables** | ADR-0002 (Event Architecture — codifies signal patterns across autoloads), ADR-0003 (Save/Load Contract — SaveManager autoload depends on this), every implementation story |
| **Blocks** | Every implementation epic/story (cannot start coding without autoload order) |
| **Ordering Note** | This ADR is the **foundation** — it must be the first ADR accepted. All other ADRs assume this autoload order exists. |

## Context

### Problem Statement

Railhunter has 5 cross-cutting concerns that need to be available globally to every scene and every other system:

1. **State ownership** — who owns "what state is the game in right now?"
2. **Input routing** — who routes player input to the correct scene subscriber?
3. **Resource access** — who holds the loaded `.tres` instances for weapons / ammo / enemies / etc.?
4. **Discovery tracking** — who tracks "what entities has the player discovered?" for the Codex?
5. **Save/Load** — who serializes/deserializes all the above?

These 5 concerns must be **available to every scene** without explicit dependency injection (Godot's recommended pattern for cross-cutting concerns is **autoload**). But Godot processes autoloads in `Project > Autoload` **registration order**, so the order has architectural significance: an autoload that *consumes* another autoload must come *after* it, or it will be holding a null reference.

The order we pick is not just a convention — it is a **hard correctness constraint**. A wrong order causes:
- `InputBus` queries `GameStateMachine.top_of_stack` → null
- `SaveManager` calls `Inventory.get_state_snapshot()` → Inventory is a per-player scene-tree node, not an autoload, so this works either way
- `ResourceRegistry` queries `GameStateMachine` to know which chapter to load → null

These bugs would only manifest **at boot or first scene-transition** — i.e., 30+ minutes of debug time, not a one-line fix.

### Current State

`design/gdd/game-state-machine.md` already declares C-R6: *"autoload 顺序硬约束. `Project > Autoload` 中必须按以下顺序注册: 1. GameStateMachine 2. InputBus 3. ResourceRegistry 4. MetaState 5. SaveManager."*

`player-input.md` E9 (revised) reinforces: *"InputBus autoload MUST be listed after GameStateMachine in `Project > Autoload` so that InputBus's `_process(delta)` runs AFTER any state transition triggered during the same frame."*

The constraint is declared in two GDDs but not codified as a single source of truth. This ADR is that source.

### Constraints

- **Engine**: Godot 4.6 autoload order is the *only* mechanism for cross-cutting autoloads. We cannot use static singletons (we use signals + autoloads, per `technical-preferences.md`).
- **Single-player**: no networking, so order is not affected by host/client asymmetry.
- **Solo dev**: 5 autoloads, not 50. Order is manageable; enforcement is automated.
- **Performance budget**: 16.6ms @ 60 FPS. Autoload `_process` overhead must stay ≤ 0.1ms each.

### Requirements

- **Functional**: 5 autoloads exist with documented load order; each has a single, named public API; consumers reference them via `/root/<Name>`.
- **Reliability**: Wrong load order must be **detectable at boot**, not at first use.
- **Performance**: Each autoload's `_ready()` completes in ≤ 50ms (boot budget = 250ms total).
- **Testability**: Order can be asserted in CI via a Godot test that reads `Project > Autoload` and checks sequence.

## Decision

### Architecture

```
Boot sequence (Godot 4.6):
┌─────────────────────────────────────────────────────────────┐
│  Phase 1: Engine init                                        │
│  Phase 2: Autoloads (in this order):                         │
│    [1] GameStateMachine  (autoload, GDScript)                │
│         └─ Owns: state_stack, top_of_stack                   │
│         └─ Exposes: transition_to / push / pop / snapshot    │
│                                                             │
│    [2] InputBus  (autoload, GDScript)                        │
│         └─ Owns: subscriber list per state, focus context    │
│         └─ Consumes: GameStateMachine.top_of_stack           │
│                                                             │
│    [3] ResourceRegistry  (autoload, GDScript)                │
│         └─ Owns: all loaded .tres instances by id            │
│         └─ Consumes: res://data/**/*.tres (filesystem scan) │
│                                                             │
│    [4] MetaState  (autoload, GDScript)                       │
│         └─ Owns: discovered / unlocked Dictionary            │
│         └─ Consumes: ResourceRegistry.get(id) for ID lookup │
│                                                             │
│    [5] SaveManager  (autoload, GDScript)                     │
│         └─ Owns: save slot mgmt, autosave trigger, version   │
│         └─ Consumes: 10 producer systems' get_state_snapshot │
│  Phase 3: First scene loads                                  │
│  Phase 4: _process begins                                    │
└─────────────────────────────────────────────────────────────┘
```

### Key Interfaces

```gdscript
# Project > Autoload registration (conceptual, not literal code)
# Godot registers these in order:

# [1] GameStateMachine — /root/GameStateMachine
extends Node
const ALLOWED_TRANSITIONS: Dictionary = {...}  # see game-state-machine.md C-R3
var state_stack: Array[StringName] = []
var top_of_stack: StringName = &""

func _ready() -> void:
    state_stack = [&"state_exploration"]
    top_of_stack = state_stack[0]
    print("[GameStateMachine] ready as autoload #1")

# [2] InputBus — /root/InputBus
extends Node
var _subscribers: Dictionary[StringName, Array] = {}

func _ready() -> void:
    assert(get_node_or_null("/root/GameStateMachine") != null,
        "Autoload order error: GameStateMachine must load before InputBus")
    print("[InputBus] ready as autoload #2")

# [3] ResourceRegistry — /root/ResourceRegistry
extends Node
var _registry: Dictionary[StringName, Resource] = {}

func _ready() -> void:
    _load_all_resources()
    print("[ResourceRegistry] ready, ", _registry.size(), " resources loaded")

# [4] MetaState — /root/MetaState
extends Node
var discovered: Dictionary[StringName, bool] = {}

func _ready() -> void:
    assert(get_node_or_null("/root/ResourceRegistry") != null,
        "Autoload order error: ResourceRegistry must load before MetaState")
    print("[MetaState] ready as autoload #4")

# [5] SaveManager — /root/SaveManager
extends Node

func _ready() -> void:
    assert(get_node_or_null("/root/GameStateMachine") != null)
    assert(get_node_or_null("/root/InputBus") != null)
    assert(get_node_or_null("/root/ResourceRegistry") != null)
    assert(get_node_or_null("/root/MetaState") != null)
    print("[SaveManager] ready as autoload #5")
```

### Implementation Guidelines

1. **Registration in Godot editor**:
   - Open `Project > Project Settings > Autoload` tab
   - Add each autoload in the order: GameStateMachine → InputBus → ResourceRegistry → MetaState → SaveManager
   - Verify by reading the autoload list in alphabetical order — they will be sorted, but Godot preserves registration order in `ProjectSettings.get_setting("autoload/...")`

2. **Boot-time order assertion**:
   - Each autoload's `_ready()` must assert that all its upstream autoloads exist via `get_node_or_null("/root/<Name>")`
   - On assertion failure: `push_error("Autoload order error: <Name> must load before <ThisName>")` + `set_process(false)` to halt processing
   - In **release build**: log only, don't crash (devs need to ship even if boot is imperfect)
   - In **dev build**: full assertion + 1 Hz console warning for 10 seconds

3. **Linter check** (CI):
   - A pre-build script reads `project.godot` `[autoload]` section
   - Asserts the order matches: GameStateMachine, InputBus, ResourceRegistry, MetaState, SaveManager
   - On mismatch: `AutoLoadOrderError` + exit code 1

4. **Documentation**:
   - This ADR is referenced by:
     - `design/gdd/game-state-machine.md` C-R6 (cross-doc link)
     - `design/gdd/player-input.md` E9 (cross-doc link)
     - Future ADR-0002 (Event Architecture) — signals cross autoload boundaries
   - All implementation stories MUST reference this ADR by ID

5. **Scene-tree conventions** (not autoload, but related):
   - First scene: `Main.tscn` (autoload path: `/root/Main`)
   - Scene ownership: scenes own their children; they do **not** own autoloads
   - Autoloads own **only** the cross-cutting data they expose
   - `queue_free()` of an autoload = crash (Godot protects this, but dev tools shouldn't try)

6. **Naming conventions**:
   - Autoload names = `PascalCase` (matches Godot convention)
   - File paths: `src/autoload/<name>.gd` (per `technical-preferences.md` GDScript naming)
   - All consumers reference via `/root/<Name>` — never `Engine.get_singleton()` (Godot 4.x deprecated; use NodePath)

7. **No autoload may `_ready()` access `/root/Main`** — autoloads load BEFORE the first scene. Anything scene-dependent must be deferred to `_process_first` (Godot 4.4+ stable) or via signal `tree_entered`.

## Alternatives Considered

### Alternative 1: All autoloads in one file (monolithic)

- **Description**: Combine 5 autoloads into one large `Game.gd` autoload with sub-namespaces
- **Pros**: Single registration point; can't have order wrong; faster `_ready` (no inter-autoload assertions)
- **Cons**: Violates single-responsibility; makes the file 2000+ lines; harder to test in isolation; doesn't match GDD architecture principles
- **Estimated Effort**: -50% setup, +200% maintenance
- **Rejection Reason**: Violates the architecture principle "state is owned, not scattered" — combining all state into one giant object is the worst form of scattered state

### Alternative 2: Use static singletons instead of autoloads

- **Description**: Each system has a `static var instance: Self` set in `_enter_tree` and accessed via `System.instance`
- **Pros**: No autoload registration; no order constraints; faster boot
- **Cons**: Godot 4.x best practice is autoload; static singletons fight the engine; harder to mock in tests; not GDScript-idiomatic
- **Estimated Effort**: -30% setup, +100% technical debt
- **Rejection Reason**: `technical-preferences.md` explicitly says "Use GDScript conventions" and the engine's documented pattern is autoload. Static singletons are an anti-pattern in Godot 4.x

### Alternative 3: Scene-tree composition (no autoloads, find by group)

- **Description**: Each scene adds a "Manager" node; consumers use `get_tree().get_first_node_in_group("input_bus")`
- **Pros**: Fully testable; no order constraints; explicit ownership
- **Cons**: Every scene must remember to add 5 manager nodes; if forgotten, runtime error; ugly to wire up; violates Godot pattern
- **Estimated Effort**: +200% boilerplate, +50% runtime checks
- **Rejection Reason**: Godot 4.6 best practice for cross-cutting concerns is autoload. Group-based lookup is for "find one of N similar things", not "the singleton for X concern"

### Alternative 4: Defer the order to a runtime check, not a linter

- **Description**: No CI linter; rely on `_ready()` asserts
- **Pros**: No external tool; simpler
- **Cons**: Asserts only fire at first run; dev who violates order might miss the assert (headless boot, suppressed error)
- **Estimated Effort**: -100% linter, +30% debug time
- **Rejection Reason**: "Correctness detectable at boot, not at first use" is a stated requirement. Linter is the cleanest enforcement.

## Consequences

### Positive

- **Single source of truth** — this ADR is THE place that defines autoload order; no more "is it game-state-machine.md or player-input.md or somewhere else?"
- **Boot-time detection** — wrong order caught in 250ms, not 30+ minutes of debug
- **Game state owned cleanly** — `GameStateMachine` truly owns state, doesn't have to defend against null autoload references
- **Player input routing correct** — `InputBus` queries state after the state is established
- **Save/Load composable** — SaveManager queries all 10 producer systems via their `get_state_snapshot()` contracts (see ADR-0003)

### Negative

- **Ordering is not editable** — adding a 6th autoload requires this ADR to be updated and re-accepted
- **Linter must be maintained** — if Godot's `project.godot` autoload section format changes, linter needs update
- **Boot assertions are runtime cost** — 5 `_ready()` asserts per autoload = ~25ns total (negligible)
- **Solo dev cognitive load** — must remember the order when creating new systems (mitigated by clear linter output)

### Neutral

- All 5 autoloads are GDScript (per `technical-preferences.md` GDScript convention); no autoload is C# (C# reserved for performance-critical math in `BattleMathLib`)
- `process_priority` is left at default (0) for all 5; if any requires explicit priority, that's a separate ADR
- No autoload is "lazy" (all `_ready()` at boot) — this means the ResourceRegistry's full file scan happens at startup, not on first request. Total scan time: ~50-200ms for ~30 `.tres` files. Acceptable.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Dev adds a new autoload without updating this ADR | Medium | High — breaks the order contract | Linter checks autoload list against this ADR's declared order; CI fails |
| Engine upgrade changes autoload semantics | Low | High | `Engine version pin` ADR (0006) — any engine upgrade re-runs `/architecture-review` to re-validate |
| `process_priority` interaction breaks expected dispatch | Low | Medium | First use site in `InputBus._process()` is tested with mode-toggle (proves order) |
| `ResourceRegistry` scan at boot exceeds 250ms budget | Low | Low | Scan is async after `_ready()` returns; `_process` reports progress if needed |
| Linter breaks on Godot project.godot format change | Low | Low | Linter is updated alongside engine pin ADR |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| Boot time (autoloads) | N/A | ~150ms (5 autoloads + 30 .tres files) | 250ms |
| `_ready()` assert cost | 0 | ~25ns (5 asserts) | <1ms |
| `_process()` overhead per autoload | 0 | ~0.05ms each = 0.25ms total | <1ms |
| Memory per autoload | 0 | ~1-2 MB each (Dictionary + signal tables) | 10MB total |

## Migration Plan

N/A — this is greenfield; no existing systems to migrate. The 5 autoloads are created in this order on first project setup.

**Rollback plan**: If autoload order proves wrong, the fix is:
1. Reorder in `Project > Autoload` (drag-and-drop in editor)
2. Update this ADR with the new order
3. Re-run CI linter to verify
4. Re-run `/architecture-review`

No code changes required (autoload order is config, not code).

## Validation Criteria

- [ ] **First boot test**: `godot --headless --quit-after 1` runs all 5 autoloads in order; `print` statements confirm `[GameStateMachine] ready as autoload #1` through `[SaveManager] ready as autoload #5`
- [ ] **Order assert test**: Manually reorder in `Project > Autoload`; first `_ready()` should emit `AutoloadOrderError` + halt
- [ ] **Linter test**: CI step `python tools/lint_autoload_order.py` exits 0 with the correct order; exits 1 with reordered autoloads
- [ ] **Mode toggle test**: Player presses `A` in BATTLE; mode flips to AUTO; InputBus dispatched correctly (proves autoload order)
- [ ] **SaveManager test**: Save slot 0 with all 5 autoloads in their default state; load slot 0; GameStateMachine, InputBus, ResourceRegistry, MetaState all restored correctly
- [ ] **Resource scan test**: 30 .tres files load in < 200ms (ResourceRegistry `_ready` budget)

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/game-state-machine.md` | Game State Machine | **C-R6**: "Autoload 顺序硬约束" | Codifies the order: GameStateMachine first; defines boot-time assert; linter enforces |
| `design/gdd/game-state-machine.md` | Game State Machine | **C-R4**: "transition_to 是原子的 1 帧事件" | GameStateMachine loads before InputBus so state transitions complete before InputBus `_process` runs in the same frame |
| `design/gdd/player-input.md` | Player Input | **E9** (revised): "InputBus autoload MUST be listed after GameStateMachine" | Codifies the InputBus position at #2; asserts in `_ready()` |
| `design/gdd/save-load.md` | Save/Load | **C-R2**: "Save data = 完整运行时状态快照" | SaveManager loads last; can safely call `get_state_snapshot()` on all upstream autoloads |
| `design/gdd/save-load.md` | Save/Load | **C-R5**: "Load 时校验 + 自愈" | SaveManager has all upstream autoloads in known state when `load_snapshot()` is called |
| `design/gdd/resource-data.md` | Resource/Data | **C-R4**: "不可变 Resource" | ResourceRegistry loads #3; resources are available before any other system tries to read them |

> Foundational — no GDD requirement above is about a *specific feature*; this ADR enables the architecture that makes all 12 MVP GDDs implementable.

## Related

- **Blocks**: every implementation epic/story (all depend on the autoload order)
- **Enables**:
  - ADR-0002 (Event Architecture) — signals cross autoload boundaries
  - ADR-0003 (Save/Load Contract) — SaveManager's snapshot API
  - ADR-0006 (Engine Version Pin) — engine upgrades re-validate this
  - ADR-0007 (Resource Immutability) — Resource._set() override, loaded by ResourceRegistry
- **Cross-doc links** (must be updated when this ADR is accepted):
  - `design/gdd/game-state-machine.md` C-R6 (status reference)
  - `design/gdd/player-input.md` E9 (status reference)
  - `design/gdd/save-load.md` C-R2, C-R5 (status reference)
  - `design/gdd/resource-data.md` C-R4 (status reference)
- **Code locations** (when implemented):
  - `src/autoload/game_state_machine.gd`
  - `src/autoload/input_bus.gd`
  - `src/autoload/resource_registry.gd`
  - `src/autoload/meta_state.gd`
  - `src/autoload/save_manager.gd`
  - `project.godot` `[autoload]` section
  - `tools/lint_autoload_order.py` (CI linter)
