# ADR-0003: Save/Load Contract

## Status

Accepted

## Date

2026-06-12

## Last Verified

2026-06-12

## Decision Makers

User + technical-director (self-review, APPROVED WITH CONCERNS 2026-06-12)

## Summary

Every system that holds runtime state in Railhunter exposes a uniform `get_state_snapshot() -> Dictionary` and `load_snapshot(snap: Dictionary) -> Error` contract. SaveManager (autoload) calls all 10 producer systems' `get_state_snapshot()` to compose the save file, and calls all 10 `load_snapshot()` to restore. This contract is **mandatory** for any system that holds state; the only allowed alternative is a stateless module (no save needed). Codifies `design/gdd/save-load.md` C-R2 and enables ADR-0004 (Save I/O) and ADR-0005 (Save Upgrade).

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Persistence (Core + Variant + FileAccess) |
| **Knowledge Risk** | LOW — `Dictionary` and `Variant` are 4.0-stable; `FileAccess` is stable |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` (4.6 pin), `save-load.md` C-R2 |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | First save/load cycle: 10 producers all return valid Dictionary, SaveManager composes, file is 1-2 KB JSON, load restores all state correctly |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Scene Management — SaveManager autoload must exist), ADR-0002 (Event Architecture — save/load lifecycle uses signals) |
| **Enables** | ADR-0004 (Save I/O — uses this contract), ADR-0005 (Save Upgrade — version migration operates on snapshot Dict) |
| **Blocks** | Save/Load implementation, all 10 producer systems' persistence |
| **Ordering Note** | Must be third ADR. Establishes the interface; ADR-0004 and 0005 then specify *how* the contract is fulfilled |

## Context

### Problem Statement

`design/gdd/save-load.md` C-R2 mandates: *"Save data = 完整运行时状态快照"*. The SaveManager must serialize **all** runtime state, which lives in **10+ systems**. Without a uniform contract, the SaveManager ends up with 10 special-case code paths, one per system:

```gdscript
# ANTI-PATTERN (what we want to avoid):
func serialize_all() -> Dictionary:
    var save: Dictionary = {}
    save["state_stack"] = game_state_machine.get_state_stack()
    save["mech_hp"] = player_controller.get_mech_hp()  # different API
    save["weapon_slots"] = inventory.get_weapon_slots()  # different API
    save["ammo"] = inventory.get_ammo_inventory()        # different API
    # ... 10 more special cases ...
    return save
```

This is:
- **Brittle**: any new system requires editing SaveManager
- **Inconsistent**: each system invents its own serialization format
- **Hard to test**: 10 paths × 10 systems = 100 tests
- **Hard to extend**: new fields = 10 SaveManager edits + 10 tests

The fix is a **uniform contract**:
```gdscript
# PATTERN (this ADR):
func serialize_all() -> Dictionary:
    var save: Dictionary = {}
    save["save_version"] = SAVE_VERSION_CURRENT  # owned by SaveManager
    save["saved_at_unix"] = Time.get_unix_time_from_system()  # owned by SaveManager
    for producer in _producers:
        save[producer.get_save_namespace()] = producer.get_state_snapshot()
    return save
```

### Current State

`save-load.md` already declares (in plain text):
- `get_state_snapshot() -> Dictionary` for each producer
- `load_snapshot(snap: Dictionary) -> Error` for each producer
- SaveManager calls all 10 producer systems

But the **shape of the contract** is not specified:
- What is the Dictionary's key schema?
- What is the contract on missing fields (forward compat)?
- What is the contract on extra fields (backward compat)?
- What is the contract on error (SaveManager keeps going or aborts?)

This ADR specifies all of the above.

### Constraints

- **10 producer systems** each own different state (see architecture §4 Module Ownership Map)
- **MVP scope** — must work in 8h dev + 1h test cycle
- **C# boundary** — `BattleMathLib` is stateless (no save needed); but if it ever gains state, contract applies
- **Performance** — save must complete in ≤ 32ms (per save-load F4)
- **Forward compat** — old save (v0) must be loadable in new code (v1); handled by ADR-0005

### Requirements

- **Uniform interface**: all 10 producers expose `get_state_snapshot() -> Dictionary` and `load_snapshot(snap: Dictionary) -> Error`
- **Namespace isolation**: each producer's Dictionary is namespaced by `system_name` (e.g., `"mech"`, `"inventory"`) to prevent key collisions
- **Schema versioned**: every snapshot has a `schema_version: int` field; missing fields default; extra fields ignored
- **Error-resilient**: missing field → use default, not error; type mismatch → log + skip, not crash
- **Type-stable** for stable fields (e.g., `state_stack: Array[StringName]` never becomes `Array[String]`)
- **Forward-compat**: adding a field to a producer is non-breaking
- **Backward-compat**: removing a field requires ADR-0005 upgrade path
- **Testable**: every producer has unit tests for get/load round-trip

## Decision

### Architecture

```
Save/Load contract (uniform across all 10 producers):

Every producer exposes:
  get_state_snapshot() -> Dictionary
  load_snapshot(snap: Dictionary) -> Error

SaveManager (autoload #5) composes the full save:
  ┌─────────────────────────────────────────────────┐
  │ Save file: user://save_<slot>.json                │
  │ {                                                │
  │   "save_version": 1,                             │  ← SaveManager owned
  │   "saved_at_unix": 1700000000,                   │  ← SaveManager owned
  │   "chapter_id": "chapter_1",                     │  ← Level producer
  │   "mech": { ... },                               │  ← Mech producer
  │   "inventory": { ... },                          │  ← Inventory producer
  │   "weapon_loadout": { ... },                     │  ← WeaponLoadout producer
  │   "battle_core": { ... },                        │  ← BattleCore producer
  │   "level": { ... },                              │  ← Level producer
  │   "encounters": { ... },                         │  ← EncounterManager producer
  │   "npc_terminal": { ... },                       │  ← NPC/Terminal producer
  │   "meta_state": { ... },                         │  ← MetaState producer
  │   "player_controller": { ... },                  │  ← PlayerController producer
  │   "hud_settings": { ... },                       │  ← HUD producer
  │ }                                                │
  └─────────────────────────────────────────────────┘
```

### Key Interfaces

```gdscript
# === Producer interface (every stateful system implements this) ===
class_name SaveableState
extends RefCounted  # or Node, depending on system

# Returns a Dictionary containing all serializable state.
# MUST be deterministic (same state = same Dictionary).
# MUST NOT include references (only IDs and primitive values).
# MUST NOT include transient state (e.g., current animation frame).
@warning_ignore("unused_signal")
func get_state_snapshot() -> Dictionary:
    return {}

# Restores state from a Dictionary.
# MUST handle missing fields by using defaults (forward compat).
# MUST log warnings on type mismatches (not crash).
# MUST validate via @return Error (OK if all applied, FAILED if some rejected).
func load_snapshot(snap: Dictionary) -> Error:
    return OK


# === SaveManager (autoload #5) — composes the save ===
# File: src/autoload/save_manager.gd
class_name SaveManager
extends Node

# The 10 producer systems in dependency order.
# Order matters: producers with no deps first.
const PRODUCER_NAMESPACES: Array[StringName] = [
    &"game_state_machine",      # autoload #1, no deps
    &"input_bus",                # autoload #2, deps on #1
    &"resource_registry",        # autoload #3, no deps (resource map)
    &"meta_state",               # autoload #4, deps on #3
    &"inventory",                # Feature, deps on #3
    &"weapon_loadout",           # Feature, deps on #3, #5
    &"mech",                     # Feature, deps on #10
    &"level",                    # Feature, deps on #3
    &"encounters",               # Feature, deps on #7
    &"npc_terminal",             # Feature, deps on #3
    &"player_controller",        # Scene, deps on #5, #6, #7
    &"battle_core",              # autoload (Core), deps on #5, #6, #7
    &"hud_settings",             # Scene (Presentation), deps on all
]

func serialize_all() -> Dictionary:
    var save: Dictionary = {
        "save_version": SAVE_VERSION_CURRENT,
        "saved_at_unix": Time.get_unix_time_from_system(),
    }
    for ns in PRODUCER_NAMESPACES:
        var producer: Node = get_node_or_null("/root/%s" % _pascal_to_title(ns))
        if producer == null:
            push_warning("SaveManager: producer %s not found, skipping" % ns)
            continue
        if not producer.has_method("get_state_snapshot"):
            push_warning("SaveManager: %s has no get_state_snapshot, skipping" % ns)
            continue
        save[ns] = producer.get_state_snapshot()
    return save

func restore_all(snap: Dictionary) -> Error:
    var first_error: Error = OK
    for ns in PRODUCER_NAMESPACES:
        if not snap.has(ns):
            push_warning("SaveManager: snapshot missing %s, using default" % ns)
            continue  # missing field is OK (forward compat)
        var producer: Node = get_node_or_null("/root/%s" % _pascal_to_title(ns))
        if producer == null or not producer.has_method("load_snapshot"):
            continue  # not loaded yet, skip
        var sub_snap: Dictionary = snap[ns]
        var err: Error = producer.load_snapshot(sub_snap)
        if err != OK:
            push_warning("SaveManager: %s.load_snapshot returned %s" % [ns, err])
            if first_error == OK:
                first_error = err
    return first_error


# === Example producer: Inventory ===
# File: src/scene/inventory.gd
class_name Inventory
extends Node

var weapon_slots: Array[WeaponData] = [null, null, null]
var ammo_inventory: Dictionary[StringName, int] = {}
var current_ammo: StringName = &""

func get_state_snapshot() -> Dictionary:
    # Serialize weapon IDs (NOT references) — refs are resolved on load
    var slot_ids: Array = []
    for slot in weapon_slots:
        if slot == null:
            slot_ids.append(null)
        else:
            slot_ids.append(String(slot.id))  # StringName.id is String
    
    return {
        "schema_version": 1,  # producer-local schema version
        "weapon_slots": slot_ids,
        "ammo_inventory": ammo_inventory.duplicate(),
        "current_ammo": String(current_ammo),
    }

func load_snapshot(snap: Dictionary) -> Error:
    if not snap is Dictionary:
        push_error("Inventory.load_snapshot: snap is not a Dictionary")
        return ERR_INVALID_DATA
    
    # Schema version check (producer-local — different from save-level)
    var schema: int = snap.get("schema_version", 1)
    if schema > 1:
        push_warning("Inventory.load_snapshot: schema %d newer than code's %d" % [schema, 1])
    
    # weapon_slots (required field — if missing, ERROR)
    if not snap.has("weapon_slots"):
        push_error("Inventory.load_snapshot: missing weapon_slots")
        return ERR_INVALID_DATA
    var slot_ids: Array = snap["weapon_slots"]
    weapon_slots = [null, null, null]
    for i in slot_ids.size():
        var id: String = slot_ids[i]
        if id == "" or id == null:
            weapon_slots[i] = null
        else:
            var weapon: WeaponData = _registry.get(&"weapon_%s" % id)
            if weapon == null:
                push_warning("Inventory: weapon %s not found, slot %d empty" % [id, i])
                weapon_slots[i] = null
            else:
                weapon_slots[i] = weapon
    
    # ammo_inventory (optional — if missing, use empty dict)
    ammo_inventory.clear()
    if snap.has("ammo_inventory"):
        var raw: Dictionary = snap["ammo_inventory"]
        for key in raw.keys():
            ammo_inventory[StringName(key)] = int(raw[key])
    
    # current_ammo (optional — if missing, use &"")
    if snap.has("current_ammo"):
        current_ammo = StringName(snap["current_ammo"])
    
    return OK
```

### Implementation Guidelines

#### Namespace isolation

- Each producer's Dictionary is namespaced by `system_name` (singular system name in snake_case)
- Top-level keys: `save_version`, `saved_at_unix`, then producer namespaces
- Producer-internal keys: snake_case, namespaced (e.g., `mech.parts_head_hp`, not `mech.head_hp`)

#### Schema versioning

| Concept | Scope | Example |
|---------|-------|---------|
| **Save version** | File-level (SaveManager owns) | `save_version: 1` |
| **Producer schema version** | Producer-local (each producer owns) | `inventory.schema_version: 1` |
| **Both incremented** | On breaking change | bump save_version AND producer schema_version |

#### Forward compat (new code reads old save)

- Missing field → use default value
- Extra field → ignore
- Type mismatch → log warning, skip field
- **Never crash** on partial save

#### Backward compat (old code reads new save)

- SaveManager checks `save_version` against `SAVE_VERSION_CURRENT`
- If newer: use upgrade path (ADR-0005) OR fail with "Save too new" error
- If older: use upgrade path
- If equal: load directly

#### Error handling

| Error | Producer action | SaveManager action |
|-------|-----------------|---------------------|
| Missing field | Use default | Log warning, continue |
| Type mismatch | Log warning, skip field | Log warning, continue |
| Missing namespace (entire producer absent) | n/a | Log warning, continue with default |
| Schema version > code's version | Log warning, **still attempt load** | Continue |
| Schema version < code's version | Run producer's `upgrade_local()` (if defined) | Run upgrade path (ADR-0005) |
| Producer not loaded yet (e.g., ResourceRegistry in error) | n/a | Log warning, skip |

#### Determinism

- `get_state_snapshot()` must be **deterministic**: same state → same Dictionary (byte-for-byte, ignoring key order)
- This enables save file diffing for debugging
- Avoid using `Time.get_*()` or random values in snapshot
- Resource references → serialize IDs only (not ref counts, not load paths)

#### IDs vs references

- Snapshot contains **only IDs and primitive values** (int, float, String, StringName, bool, Array, Dictionary)
- No Node references, no Resource references, no Callable references
- On load: producer resolves IDs via `ResourceRegistry.get(id)` (handles missing ID gracefully per C-R8 of resource-data.md)

#### What NOT to serialize

| Don't serialize | Reason |
|-----------------|--------|
| Node paths | Paths change between sessions |
| Callable references | Cannot be serialized |
| Animation frame counters | Transient, can be reconstructed |
| Camera position | Reconstructed by `set_room_bounds` on scene load |
| Current input focus | Reconstructed when state restored |
| Random seed | Save is meant to be reproducible; don't preserve random |
| `_process` timers (e.g., shake duration) | Transient, restart on load |
| `is_processing` flags | Engine-managed, re-set on `_ready` |

## Alternatives Considered

### Alternative 1: Per-system JSON schemas with custom (de)serializers

- **Description**: Each system has a JSON schema (`.json` file) and a hand-written (de)serializer
- **Pros**: Explicit schema; can validate; clear contract
- **Cons**: 10 schemas to maintain; 10 hand-written parsers; versioning is a nightmare
- **Estimated Effort**: +30% initial, +100% maintenance
- **Rejection Reason**: GDScript `Dictionary` is the engine's natural serialization format. Hand-rolled JSON schemas add ceremony without value.

### Alternative 2: One giant "save" object (no per-system namespaces)

- **Description**: All state in one flat Dictionary, no namespaces
- **Pros**: Easier to inspect
- **Cons**: Key collisions ("hp" in mech, "hp" in battle_core, "hp" in hud_settings), no ownership clarity
- **Estimated Effort**: -10% initial, +200% bug time
- **Rejection Reason**: Namespaces = ownership = the architecture principle "state is owned". Without namespaces, ownership is implicit and breaks.

### Alternative 3: Binary serialization (e.g., pickle, marshal)

- **Description**: Use Godot's `ResourceSaver.save()` for binary save files
- **Pros**: Smaller files, faster
- **Cons**: Not human-readable, hard to debug, version diffing impossible
- **Estimated Effort**: -5% size, +200% debug time
- **Rejection Reason**: Debug-friendliness (JSON) wins for solo dev. Per save-load.md MVP, JSON is mandated.

### Alternative 4: ECS-style component serialization

- **Description**: Save each component (Position, HP, etc.) separately; reassemble on load
- **Pros**: Fine-grained save (only changed components)
- **Cons**: ECS architecture not used; complexity not justified
- **Estimated Effort**: +500% for unknown benefit
- **Rejection Reason**: Railhunter is not ECS. This would require rewriting every system.

## Consequences

### Positive

- **Uniform contract** — SaveManager is a simple loop, not 10 special cases
- **Easy to add new stateful systems** — implement the 2 methods, add to PRODUCER_NAMESPACES
- **Forward-compat by default** — adding fields is non-breaking
- **Backward-compat via upgrade path** — ADR-0005
- **Testable** — every producer's round-trip (save → load → compare) is one unit test
- **Debuggable** — JSON file is human-readable; you can `cat user://save_0.json | jq`

### Negative

- **Dictionary has no type safety** — typos in key names caught at runtime, not compile time
- **Schema drift** — if a producer silently renames a field, the snapshot changes (caught by tests)
- **Per-system schema_version** — every producer must manage its own version
- **Save size is larger than binary** — but MVP target is 1-2 KB, acceptable
- **Linter required** — to catch `get_state_snapshot` not implemented on new systems

### Neutral

- Producer-local schema version is "versioned twice" (file + producer). Mitigation: only increment file version when producer schema breaks.
- SaveManager composes order is independent of restore order. The restore order is also fixed (see §4 — but restoration can be parallelized in VS).
- New types added to a producer (e.g., adding `Vector2` fields) need 1 round of compatibility testing but no schema bump.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| New producer system forgets to implement contract | High | Medium | Linter greps `/root/*` nodes for `get_state_snapshot` method; CI fails |
| Dictionary key typo | High | Low | Unit tests assert payload keys |
| Schema version drift between producer and SaveManager | Medium | Medium | SaveManager's `save_version` bump triggers `/architecture-review` |
| Resource ID resolution fails on load (e.g., weapon removed from registry) | Medium | Low | Producer handles missing ID gracefully (null slot + warning) |
| Save file corruption (manual edit, disk error) | Low | High | SaveManager validates JSON; corruption → graceful fail to TITLE (per save-load.md E2) |
| Snapshot size grows unbounded (e.g., audio buffer cached) | Low | Medium | Snapshot review in `/architecture-review` flags large fields; producer must store IDs only |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| `serialize_all()` time | N/A | ~5ms (10 producers × 0.5ms) | <10ms |
| `restore_all()` time | N/A | ~10ms (with resource ID resolution) | <20ms |
| Save file size | N/A | ~1-2 KB (per save-load F2) | <5 KB |
| Memory per snapshot | N/A | ~10-20 KB (Dict overhead) | <50 KB |
| JSON encode/decode | N/A | ~2-3ms | <5ms |

## Migration Plan

N/A — greenfield. All 10 producers will implement the contract from day 1.

**Rollback plan**: If the contract proves unworkable:
1. Identify the failing case (specific producer)
2. Update the contract (add namespace, add field, etc.)
3. Re-run all producer unit tests
4. Update this ADR

No migration required (no existing saves to convert).

## Validation Criteria

- [ ] **First save test**: complete a play session, save slot 0, inspect `user://save_0.json` — has all 11 top-level keys
- [ ] **Round-trip test**: save → load → save → compare two save files → identical
- [ ] **Forward compat test**: load a v0 snapshot in v1 code → all fields default gracefully, no crash
- [ ] **Backward compat test**: load a v2 snapshot in v1 code → "Save too new" error, no crash
- [ ] **Missing field test**: manually delete a field from a save file → load → producer uses default, logs warning
- [ ] **Type mismatch test**: manually change a field's type → load → producer logs warning, skips field
- [ ] **Missing resource ID test**: save with weapon A, remove weapon A from registry, load → slot empty, warning logged
- [ ] **Performance test**: serialize_all + restore_all round-trip < 32ms (per save-load F4)

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/save-load.md` | Save/Load | **C-R2**: "Save data = 完整运行时状态快照" | Defines uniform contract for all 10 producers |
| `design/gdd/save-load.md` | Save/Load | **C-R5**: "Load 时校验 + 自愈" | Defines forward-compat (missing field = default) and type-mismatch (warn + skip) |
| `design/gdd/game-state-machine.md` | Game State Machine | `get_state_snapshot() / load_snapshot(snap)` | Producer contract applies to autoload |
| `design/gdd/player-input.md` | Player Input | (no save — settings are hard-coded) | Excluded from PRODUCER_NAMESPACES |
| `design/gdd/resource-data.md` | Resource/Data | (stateless — Resource instances are immutable) | Excluded from PRODUCER_NAMESPACES |
| `design/gdd/collision.md` | Collision | (transient state, excluded per "What NOT to serialize") | Excluded from PRODUCER_NAMESPACES |
| (All 12 GDDs) | All | "system exposes its state" | Contract applied uniformly |

> Foundational — no single GDD requirement; this ADR codifies the *pattern* used by 10+ producer systems.

## Related

- **Depends on**:
  - ADR-0001 (Scene Management — SaveManager autoload)
  - ADR-0002 (Event Architecture — save/load lifecycle signals)
- **Enables**:
  - ADR-0004 (Save I/O — uses this contract to define file format)
  - ADR-0005 (Save Upgrade — operates on snapshot Dict)
- **Code locations** (when implemented):
  - `src/autoload/save_manager.gd` (composes)
  - `src/scene/inventory.gd` (producer example)
  - `src/scene/weapon_loadout.gd` (producer)
  - `src/scene/player_controller.gd` (producer)
  - `src/scene/level.gd` (producer)
  - `src/scene/encounter_manager.gd` (producer)
  - `src/scene/npc_terminal.gd` (producer)
  - `src/scene/hud.gd` (producer — hud_settings only)
  - `src/autoload/game_state_machine.gd` (producer)
  - `src/autoload/input_bus.gd` (producer)
  - `src/autoload/resource_registry.gd` (producer)
  - `src/autoload/meta_state.gd` (producer)
  - `tools/lint_save_contract.py` (CI linter — asserts all producers implement contract)
