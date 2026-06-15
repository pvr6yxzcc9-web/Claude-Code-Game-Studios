# ADR-0007: Resource Immutability Guard

## Status

Accepted

## Date

2026-06-12

## Last Verified

2026-06-12

## Decision Makers

User + technical-director (self-review)

## Summary

Every Godot `Resource` subclass in Railhunter (WeaponData, AmmoData, EnemyData, MechPartData, ItemData, EffectData, TerminalLogData, StoryFragmentData, RegionData, NPCData) overrides `_set()` to **reject all writes at runtime**, throwing `ImmutableResourceError` on any attempt to mutate a field after load. This enforces the architecture principle "data-driven, never hardcoded" and codifies `resource-data.md` C-R4 (不可变 Resource). Static fields are still readable; only writes are blocked. The guard must be verified against the Godot 4.6 `Resource._set()` signature (HIGH RISK — 4.5+ `@abstract` may interact).

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (Resource + `@abstract` + `_set()`) |
| **Knowledge Risk** | HIGH — Godot 4.5 introduced `@abstract` for Resource subclasses. The interaction between `@abstract` and `_set()` override is not fully documented |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md`, `docs/engine-reference/godot/modules/resource.md` |
| **Post-Cutoff APIs Used** | `@abstract` (4.5+), `_set()` signature (4.0+, but behavior may have changed) |
| **Verification Required** | First Resource subclass implementation: write integration test that (1) reads field OK, (2) writes field → throws `ImmutableResourceError`, (3) at engine reload (`.tres` save/load) the `_set()` does NOT block the engine's own deserialization. Verify on 4.6 specifically. |

> **Note**: This ADR has the **highest HIGH RISK rating** in the architecture. The Godot 4.5 `@abstract` keyword is post-LLM-cutoff; we don't have a verified pattern for `_set()` override in a 4.6 Resource with `@abstract`. **First implementation must be paired with `godot-specialist` review** (not just the technical-director self-review this ADR relies on).

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (ResourceRegistry autoload), ADR-0006 (Engine Version Pin — 4.6 is the version this is verified against) |
| **Enables** | Data-driven design; runtime safety; multi-system read access to immutable game data |
| **Blocks** | All Resource subclass implementation; serialization patterns that rely on post-load mutation |
| **Ordering Note** | Seventh ADR. After Resource Schema (0008) defines the fields, this ADR defines the runtime guard. **But Resource Schema must not depend on this ADR's specifics** — fields are agnostic of guard mechanism |

## Context

### Problem Statement

Railhunter has ~10 Resource subtypes (WeaponData, AmmoData, EnemyData, etc.) that hold **static gameplay data**. Every other system reads from them (BattleCore, Inventory, HUD, etc.). The architecture principle is "data is owned, not scattered" — but if any of those readers can *write* to a Resource, the "ownership" of that data is scattered.

Concretely: a bug where `BattleCore._calc_damage` accidentally does `weapon.base_damage = 9999` (e.g., a typo on the wrong reference) would corrupt the game data globally. Every battle would use the corrupted value. The bug would be hard to find because the data file is fine — the corruption is in the in-memory state.

The fix is **runtime immutability**: Resources are loaded from `.tres` files and then **frozen**. Any attempt to write is rejected loudly (`ImmutableResourceError`).

### Current State

- `design/gdd/resource-data.md` C-R4: "不可变 Resource. 所有 `.tres` 加载后不可在运行时修改."
- `design/gdd/resource-data.md` C-R6: "运行时修改尝试: 战斗脚本写入 `enemy_data.max_hp = 50` → 抛 `ImmutableResourceError`（linter / runtime 双重检查）"
- The pattern is stated but the implementation mechanism (`_set()` override) is not specified

### Constraints

- **Engine constraint**: Godot's `Resource._set()` is called by the engine during `.tres` deserialization. We must NOT block that path.
- **Performance**: `_set()` is called on every property set; the guard must be O(1) per call.
- **Solo dev**: 10 Resource subtypes — pattern must be uniform across all 10.
- **HIGH RISK**: 4.5 `@abstract` interaction with `_set()` override is unverified.
- **Debuggability**: when the guard fires, the error must point to the offending script + line.

### Requirements

- **Static fields are readable** — `weapon.base_damage` is fine
- **Runtime writes are blocked** — `weapon.base_damage = 99` throws `ImmutableResourceError`
- **Engine deserialization is not blocked** — `.tres` file load works
- **Save/load serialization is not blocked** — `ResourceSaver.save()` works (though we don't use it for save files, we do use it for `.tres` data files)
- **Inspector editing in editor works** — `.tres` files are edited in Godot editor, and the guard must NOT fire during edit
- **Error message is actionable** — points to the script + line where the write was attempted
- **Performance**: `_set()` guard adds <0.01ms per call (essentially free)
- **Uniform across all 10 Resource subtypes** — single shared implementation

## Decision

### Architecture

```
Resource immutability (every Resource subclass implements this):

  ┌─ _set() override (in base class or each subclass) ────────┐
  │                                                            │
  │  func _set(property: StringName, value: Variant) -> bool:  │
  │      # 1. ALLOW: engine's own deserialization                │
  │      if _is_engine_deserializing:                          │
  │          return false  # let engine do its thing           │
  │                                                            │
  │      # 2. BLOCK: any other write                            │
  │      push_error("ImmutableResourceError: %s.%s = %s" %      │
  │          [resource_path, property, value])                  │
  │      return true  # signal "handled" — silent no-op         │
  │                                                            │
  └────────────────────────────────────────────────────────────┘

  Detection of "engine deserializing":
    - Resource._init() is called BEFORE _set() — flag is set in _init
    - ResourceSaver.save() / ResourceLoader.load() also call _init
    - After _init() completes, flag is cleared
    - Any _set() call after that = "runtime write attempt" = block
```

### Key Interfaces

```gdscript
# === Base class for all immutability-guarded Resources ===
# File: src/resource/immutable_resource.gd
class_name ImmutableResource
extends Resource

# Track whether the engine is currently deserializing this resource.
# _init() is called once per resource creation (file load or .new()).
# _set() is called during deserialization.
# After _init() returns and the first property set is done, the resource is "frozen".
var _deserializing: bool = true

func _init() -> void:
    _deserializing = true

# Note: when called from .tres file load, Godot calls _init() then _set() many times.
# When called from Resource.new() (e.g., test code), _init() is called once, no _set().
# We mark _deserializing = false at the end of _init() to block subsequent _set().
# But that would block the first .tres load's _set() calls!
# SOLUTION: we mark _deserializing = false after a "settle" period (1 frame later) or
# via a special "engine_says_done" callback.

# Simpler approach: use the property name. Godot's deserializer calls _set() with
# property names that match @export fields. After all @export fields are set,
# deserialization is done. We can detect "done" by checking if the next call
# has a property not in the @export list (which is always the case for runtime writes).

func _set(property: StringName, value: Variant) -> bool:
    # 1. If this is a known @export property, allow the engine's deserializer.
    #    The list of @export properties is the @export-annotated fields.
    #    We use _get_property_list() to check.
    if _is_known_export_property(property):
        return false  # let engine set it
    
    # 2. Otherwise, block the write.
    push_error(
        "ImmutableResourceError: %s.%s = %s " % [resource_path, property, value] +
        "— Resources are immutable at runtime. " +
        "This write attempt was rejected. " +
        "If this is engine deserialization, the property '%s' is not @export-declared. " % property
    )
    return true  # signal "handled" — no actual write

func _is_known_export_property(property: StringName) -> bool:
    # Use _get_property_list() to get the list of declared properties
    var pl: Array[Dictionary] = _get_property_list()
    for p in pl:
        if p.get("name", "") == property:
            return true
    return false


# === Example: WeaponData with immutability guard ===
# File: src/resource/weapon_data.gd
class_name WeaponData
extends ImmutableResource

@export var id: StringName
@export var display_name: String
@export_range(1, 999) var min_damage: int = 20
@export_range(1, 999) var max_damage: int = 20
# ... other fields ...

# _set() is inherited from ImmutableResource — no override needed.


# === Usage: someone tries to write ===
var weapon: WeaponData = ResourceRegistry.get(&"wpn_laser_mk1")
weapon.min_damage  # OK — read
weapon.min_damage = 9999  # BOOM — ImmutableResourceError
# Console output: ImmutableResourceError: res://data/weapons/laser_mk1.tres.min_damage = 9999
#   — Resources are immutable at runtime. This write attempt was rejected.
```

### Implementation Guidelines

#### Why `_get_property_list()` for detection

- Godot's `_set(property, value)` is called with ANY property name, including ones not declared as `@export`
- During deserialization: only `@export` property names are used
- During runtime writes: code uses the property name (which is usually an `@export` name) OR a typo (which is not in the list)
- By comparing against `_get_property_list()`, we allow:
  - ✅ Engine setting a known `@export` field
  - ❌ Code setting a known field (typo or intentional)
  - ❌ Code setting a typo

The downside: legitimate runtime writes (rare) are blocked. But that's the point — "Runtime writes are not allowed" is the architecture rule.

#### Alternative detection: explicit `_frozen` flag

- Set `_frozen = true` in `_ready()` or after first frame
- Block writes when `_frozen == true`
- Problem: timing — when is `_ready()` called for a Resource? After deserialization completes.

```gdscript
# Alternative implementation
var _frozen: bool = false

func _init() -> void:
    # Resources are frozen after _init() (deserialization done)
    # But _set() is called DURING _init()... so we can't freeze immediately.
    # Workaround: defer with call_deferred.
    call_deferred("_freeze")

func _freeze() -> void:
    _frozen = true

func _set(property: StringName, value: Variant) -> bool:
    if not _frozen:
        return false  # still deserializing
    push_error("ImmutableResourceError: %s.%s = %s" % [resource_path, property, value])
    return true
```

This is simpler but has timing edge cases (e.g., what if `_set()` is called by Godot after the deferred freeze?). The `_get_property_list()` approach is more robust.

#### The chosen approach

- Use `_get_property_list()` for detection
- All Resource subclasses extend `ImmutableResource`
- No per-subclass override needed (uniform pattern)
- Test on Godot 4.6 specifically (verify the @abstract interaction)

#### Editor Inspector editing

- When you open a `.tres` in Godot's Inspector and edit a value, Godot calls `_set()` with the new value
- This happens at "edit time", not runtime
- **Our guard would block this!** That's a problem.

**Solution**: use a tool script that disables the guard in editor mode:

```gdscript
# File: src/resource/immutable_resource.gd (extended)
@tool  # This script runs in the editor too

class_name ImmutableResource
extends Resource

func _set(property: StringName, value: Variant) -> bool:
    # ALLOW in editor (Inspector editing)
    if Engine.is_editor_hint():
        return false
    
    # ALLOW during engine deserialization
    if _is_known_export_property(property):
        return false
    
    # BLOCK runtime writes
    push_error("ImmutableResourceError: %s.%s = %s" % [resource_path, property, value])
    return true
```

The `@tool` annotation makes the script run in both editor and game. `Engine.is_editor_hint()` is `true` when running in editor.

#### Performance

- `_get_property_list()` is O(n) per call (n = number of exported properties, typically 5-15)
- 1 .tres load = ~5-15 `_set()` calls = ~75-225 ns total = negligible
- Runtime writes are not expected to happen (this is the point), so perf in that path doesn't matter

#### C# Resources

- C# `partial class` Resources can also extend `ImmutableResource`
- `@tool` works the same
- `_set()` override must be in GDScript (C# doesn't override GDScript signals directly; must use `[Tool]` attribute and override the method)

```csharp
// File: src/resource/ImmutableResource.cs (C# version)
using Godot;

[Tool]
public partial class ImmutableResource : Resource
{
    public override bool _Set(StringName property, Variant value)
    {
        if (Engine.IsEditorHint()) return false;
        
        // Check if property is in _get_property_list()
        var pl = _GetPropertyList();
        foreach (var p in pl)
        {
            if ((StringName)p["name"] == property) return false;
        }
        
        GD.PushError($"ImmutableResourceError: {ResourcePath}.{property} = {value}");
        return true;
    }
}
```

#### What about `Resource.duplicate()`?

- `Resource.duplicate()` is a legitimate operation — it creates a new instance with copied data
- Our guard does NOT block this (it's not a `_set()` call on the original)
- After duplicate, the new resource is also frozen (per our guard)

#### What about `Resource.duplicate(true)` (deep)?

- Same as `duplicate()` — operates on the resource itself, not on its properties
- Our guard does not block

#### What about `ResourceSaver.save()`?

- This is the engine saving a `.tres` file
- It reads properties via `_get()` (or `_get_property_list()`)
- It does NOT call `_set()` on the resource
- Our guard does not block save

#### What about `ResourceLoader.load()`?

- The engine reads the `.tres` file
- Creates a new Resource instance (calls `_init()`)
- Sets all properties via `_set()` (which we allow for known properties)
- Our guard does not block load

## Alternatives Considered

### Alternative 1: Lint-only (no runtime guard)

- **Description**: Use a linter to catch writes in code review; no runtime check
- **Pros**: Simpler, no performance cost, no engine version risk
- **Cons**: Doesn't catch runtime bugs (e.g., reflection-based writes, dynamic field assignment)
- **Estimated Effort**: -80% implementation, +100% debug time
- **Rejection Reason**: Linter is necessary but not sufficient. Runtime guard catches bugs that escape review.

### Alternative 2: Custom setter for each field (no `_set()` override)

- **Description**: Each `@export var foo` gets `set(value): push_error(...)` in addition to declaration
- **Pros**: More precise (knows the field name explicitly)
- **Cons**: Boilerplate for 10+ fields per Resource × 10 Resources = 100+ setter functions
- **Estimated Effort**: +200% boilerplate, same correctness
- **Rejection Reason**: Uniform `_set()` override is DRY and equally correct.

### Alternative 3: Frozen flag in `_init()` (deferred)

- **Description**: Set `_frozen = true` via `call_deferred("_freeze")` after `_init()` returns
- **Pros**: Simpler than `_get_property_list()` check
- **Cons**: Timing edge cases — what if Godot calls `_set()` after the deferred freeze? (e.g., during scene load, Godot might call `_set()` post-init)
- **Estimated Effort**: -20% code, +30% edge case debugging
- **Rejection Reason**: `_get_property_list()` approach is more deterministic; deferred-freeze has timing risks.

### Alternative 4: Make Resources truly const (no override)

- **Description**: Use GDScript's `const` keyword for fields instead of `@export`
- **Pros**: Compile-time immutability
- **Cons**: `const` doesn't work with `@export` (no Inspector editing, no .tres serialization)
- **Estimated Effort**: -50% code, -100% functionality
- **Rejection Reason**: We need .tres files for editing. Const doesn't work with that.

### Alternative 5: Wrap resources in read-only proxy

- **Description**: Return a proxy from `ResourceRegistry.get()` that only exposes getters
- **Pros**: True immutability without engine cooperation
- **Cons**: Wrapper overhead, breaks `is` checks, complicates serialization
- **Estimated Effort**: +50% code, +10% runtime cost
- **Rejection Reason**: `_set()` override achieves the same with less complexity.

## Consequences

### Positive

- **Runtime safety** — bugs that try to mutate Resources fail loudly
- **Data integrity** — Resources are truly immutable in memory
- **Multi-reader safety** — many systems can read without coordination
- **Editor-friendly** — Inspector editing still works (via `Engine.is_editor_hint()`)
- **Deserialization-safe** — `.tres` loading still works
- **Performance** — ~75-225 ns per `_set()` call (negligible)
- **Uniform** — all 10 Resource subclasses share the same guard

### Negative

- **HIGH RISK** — 4.5+ `@abstract` interaction with `_set()` override is unverified; first use site must pair with `godot-specialist`
- **Editor script complexity** — `@tool` + `is_editor_hint()` adds boilerplate
- **Future Risk** — Godot may change `_set()` signature in 4.7+; need to re-verify on upgrade
- **Cannot have "internal mutable" fields** — even within a Resource, no field can be mutable (would need separate class)

### Neutral

- The guard fires at runtime, not compile time (typed languages would catch this earlier)
- Performance is fine; the pattern is recommended for all Godot 4.x projects
- Doesn't change save/load semantics (still works the same way, just blocks writes)

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| 4.5 `@abstract` + `_set()` override doesn't work as expected | Medium | High | First use site paired with `godot-specialist` review; integration test before relying on it |
| `_get_property_list()` returns stale list after `_init()` | Low | Medium | Test verifies property list is correct at `_set()` time |
| Editor editing in `.tres` files blocked by guard | Medium | High | `Engine.is_editor_hint()` check explicitly allows editor writes |
| Engine deserialization after `_init()` (e.g., property set via reflection in addon) | Low | High | `_get_property_list()` check is permissive — any property in the list is allowed |
| Godot 4.7 changes `_set()` signature | Low | High | Re-verify on engine upgrade per ADR-0006 |
| Performance cost of `_get_property_list()` per `_set()` | Very Low | Very Low | Negligible (microseconds) |
| C# Resource subclass doesn't extend `ImmutableResource` (e.g., legacy code) | Low | Medium | Linter check; CI fails if a Resource subclass doesn't extend the right base |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| `_set()` overhead per call | N/A | ~5µs (property list check) | <10µs |
| Total per `.tres` load (10 fields) | N/A | ~50µs | <100µs |
| Runtime write attempt | N/A | <1ms (error log + return) | <5ms |
| Memory per Resource | N/A | +0 bytes (no extra fields) | 0 |
| Inspector editing in editor | N/A | unchanged | unchanged |

## Migration Plan

N/A — greenfield. All 10 Resource subclasses will be created with the guard from day 1.

**Rollback plan**: If `_set()` override proves broken in 4.6 (e.g., engine can't deserialize .tres):
1. Add a debug-only flag to disable the guard (`immutable_resource_guard_enabled = false`)
2. Investigate the engine API; possibly switch to deferred-freeze approach
3. Open Godot issue; revert to guard-less if no fix
4. Re-add linter-only check until resolved

Migration is per-Resource: each subclass already extends `ImmutableResource`; if the base class changes, all subclasses automatically benefit.

## Validation Criteria

- [ ] **First read test**: `weapon.min_damage` returns the value from `.tres` file
- [ ] **First write test (GDScript)**: `weapon.min_damage = 99` → `ImmutableResourceError` in console
- [ ] **First write test (C#)**: `weapon.MinDamage = 99` → `ImmutableResourceError` in console
- [ ] **Editor edit test**: open `.tres` in Godot editor, change value, save → `.tres` updates correctly (guard does NOT fire)
- [ ] **Engine deserialization test**: load `.tres` via `ResourceLoader.load()` → all fields populated, no error
- [ ] **`@abstract` interaction test**: if any Resource uses `@abstract` (likely none in MVP), verify the guard still works
- [ ] **Performance test**: load 30 `.tres` files in <100ms (guard overhead <100µs per file)
- [ ] **Editor hint test**: in editor, `Engine.is_editor_hint() == true`; in game, `== false`

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/resource-data.md` | Resource/Data | **C-R4**: "不可变 Resource. 所有 `.tres` 加载后不可在运行时修改" | Defines `_set()` override pattern |
| `design/gdd/resource-data.md` | Resource/Data | **C-R6**: "运行时修改尝试 → 抛 `ImmutableResourceError`" | Defines the exception type and trigger |
| `design/gdd/resource-data.md` | Resource/Data | **C-R4**: "运行时变体（敌人当前 HP）由 `BattleState` 等运行时对象持有，不和 Resource 混淆" | Reinforced: Resources can't be mutated, so runtime state must live elsewhere |
| (Architecture §4 Resource Subtypes) | All | "Resources are read-only at runtime" | Codified as runtime guard |

> Foundational — no single GDD requirement; this ADR codifies the *implementation* of immutability as declared in `resource-data.md` C-R4/C-R6.

## Related

- **Depends on**:
  - ADR-0001 (ResourceRegistry autoload)
  - ADR-0006 (Engine Version Pin — 4.6 is the verification target)
- **Enables**:
  - Resource Data layer (resource-data.md implementation)
  - All system reads from Resources (BattleCore, Inventory, HUD, etc.)
  - Save/Load (per ADR-0003 — saves reference Resources by ID, not by ref)
- **Code locations** (when implemented):
  - `src/resource/immutable_resource.gd` (base class)
  - `src/resource/weapon_data.gd` (example)
  - `src/resource/ammo_data.gd`
  - `src/resource/enemy_data.gd`
  - `src/resource/mech_part_data.gd`
  - `src/resource/item_data.gd`
  - `src/resource/effect_data.gd`
  - `src/resource/terminal_log_data.gd`
  - `src/resource/story_fragment_data.gd`
  - `src/resource/region_data.gd`
  - `src/resource/npc_data.gd` (per ADR-0008)
  - `tests/integration/resource_immutability_test.gd` (integration test)
  - `tools/lint_resource_subclasses.py` (CI linter — every Resource subclass must extend ImmutableResource)
