# ADR-0005: Save/Load Upgrade Path

## Status

Accepted

## Date

2026-06-12

## Last Verified

2026-06-12

## Decision Makers

User + technical-director (self-review)

## Summary

SaveManager owns the centralized `upgrade_snapshot(snap: Dictionary, from_version: int, to_version: int) -> Dictionary` function. Each producer's local schema version can drift (handled in `load_snapshot` per ADR-0003), but the **file-level** save version is centrally upgraded by SaveManager via a chain of upgrade functions. Old saves (v0) can be loaded in new code (v1+); the upgrade chain is explicit, tested, and additive (new functions don't break old ones). Codifies the "forward compat" half of `save-load.md` C-R5.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Persistence (Core + Versioning) |
| **Knowledge Risk** | LOW — version-migration is a standard pattern, no engine-specific knowledge |
| **References Consulted** | `save-load.md` C-R5 |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | First upgrade: save v0, upgrade code to v1, load v0 save → upgraded correctly. Test every upgrade path (v0→v1, v1→v2) |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0003 (Save Contract — defines snapshot structure), ADR-0004 (Save I/O — calls upgrade on load) |
| **Enables** | Future version migrations; production bugfixes that need schema changes; new content (chapters) that change save shape |
| **Blocks** | First time we need to change save schema in a way that's not forward-compat |
| **Ordering Note** | Fifth ADR. After Save I/O. Future-versioning may be tested in dev but production migration is a real event |

## Context

### Problem Statement

Saves will outlive code versions. A player on v1.0 saves the game. We release v1.1 with a new field (e.g., "we added a 4th weapon slot"). Player loads v1.1, tries to load v1.0 save → ?

Options:
1. **Crash** — bad UX
2. **Refuse to load** — bad UX (player loses progress)
3. **Auto-upgrade** — best UX, but requires explicit code

`save-load.md` C-R5: *"Load 时校验 + 自愈. Load 流程: 读 JSON → 校验 schema → 如果 `save_version` 不匹配 → 升级路径; 如果某个字段缺失或类型错 → 用默认值填充."*

This ADR specifies the upgrade path mechanism.

### Current State

- `save-load.md` declares the concept but not the implementation
- No upgrade functions exist (greenfield)
- `save_version: 1` is the current version (per architecture §5b SaveManager)

### Constraints

- **MVP scope** — only need to support v0 → v1 → v2 → ... upgrades
- **No downgrades** — if save is v2 and code is v1, refuse to load (not a real scenario in single-player, but document the policy)
- **Backup before upgrade** — keep original save as `.bak` in case upgrade fails
- **Schema changes are infrequent** — every few months, not daily

### Requirements

- **Centralized ownership** — SaveManager owns `upgrade_snapshot`; producers don't know about file versions
- **Additive** — adding a new upgrade function `v1→v2` doesn't require touching `v0→v1`
- **Idempotent** — running upgrade twice produces same result
- **Backup** — original save is backed up before upgrade
- **Logged** — every upgrade is logged with old version, new version, fields changed
- **Testable** — every upgrade function has unit tests with representative old saves

## Decision

### Architecture

```
SaveManager (autoload #5) — upgrade path:

  ┌─ upgrade_snapshot(snap, from_version, to_version) ────────┐
  │                                                            │
  │  1. If from_version == to_version: return snap (no-op)   │
  │                                                            │
  │  2. Backup original:                                       │
  │     user://save_<slot>.json → user://save_<slot>.bak.json  │
  │                                                            │
  │  3. Walk upgrade chain:                                     │
  │     current = snap                                          │
  │     for v in [from_version, from_version+1, ..., to_version-1]:│
  │       upgrade_fn = _get_upgrade(v, v+1)                     │
  │       current = upgrade_fn.call(current)                    │
  │       Log: "Upgraded save from v%d to v%d" % [v, v+1]      │
  │                                                            │
  │  4. Return current                                          │
  │                                                            │
  └────────────────────────────────────────────────────────────┘

  ┌─ _get_upgrade(from, to) → Callable ───────────────────────┐
  │                                                            │
  │  Returns the upgrade function for (from→to) transition.     │
  │  If not found: return null (caller fails)                  │
  │                                                            │
  │  Lookup table (built in _ready):                            │
  │    { (0, 1): _upgrade_v0_to_v1,                            │
  │      (1, 2): _upgrade_v1_to_v2,                            │
  │      ... }                                                  │
  │                                                            │
  └────────────────────────────────────────────────────────────┘

  ┌─ _upgrade_v0_to_v1(snap: Dictionary) -> Dictionary ──────┐
  │                                                            │
  │  (Specific to this upgrade)                                 │
  │  e.g., "Add 4th weapon slot field"                          │
  │    snap["inventory"]["weapon_slots"] = Array([null, null,    │
  │        null, null])  # was 3 slots, now 4                   │
  │  e.g., "Rename field"                                       │
  │    if snap["mech"].has("parts_head_hp"):                    │
  │      snap["mech"]["parts"][&"head"] = {"hp": ...}            │
  │      snap["mech"].erase("parts_head_hp")                     │
  │                                                            │
  │  Return snap                                                │
  │                                                            │
  └────────────────────────────────────────────────────────────┘
```

### Key Interfaces

```gdscript
# === SaveManager — upgrade path ===
# File: src/autoload/save_manager.gd (excerpt)

const SAVE_VERSION_CURRENT: int = 1

# Upgrade functions: maps (from, to) → upgrade callable
var _upgrade_chain: Dictionary = {}

func _ready() -> void:
    # Register upgrade functions
    _upgrade_chain[(0, 1)] = _upgrade_v0_to_v1
    # When we add v2:
    # _upgrade_chain[(1, 2)] = _upgrade_v1_to_v2

# Called by load_from_slot when save_version < SAVE_VERSION_CURRENT
func _upgrade_snapshot(snap: Dictionary, from_version: int, to_version: int) -> Dictionary:
    if from_version == to_version:
        return snap  # no-op
    
    # Backup before upgrading (so a failed upgrade can fall back)
    _backup_current_save()  # user://save_<slot>.json → .bak.json
    
    var current: Dictionary = snap
    var current_version: int = from_version
    
    while current_version < to_version:
        var key: Array = [current_version, current_version + 1]
        if not _upgrade_chain.has(key):
            push_error("SaveManager: no upgrade from v%d to v%d" % [current_version, current_version + 1])
            return current  # partial upgrade — caller should fail the load
        
        var upgrade_fn: Callable = _upgrade_chain[key]
        current = upgrade_fn.call(current)
        current_version += 1
        print("SaveManager: upgraded save from v%d to v%d" % [current_version - 1, current_version])
    
    return current

func _backup_current_save() -> void:
    # Copy current save to .bak (overwriting any existing backup)
    # Note: this is a stub — actual implementation uses DirAccess
    pass

# === Example upgrade: v0 → v1 ===
# (Hypothetical: v1 added a 4th weapon slot)
func _upgrade_v0_to_v1(snap: Dictionary) -> Dictionary:
    # If inventory namespace exists, expand weapon_slots
    if snap.has("inventory") and snap["inventory"] is Dictionary:
        var inv: Dictionary = snap["inventory"]
        if inv.has("weapon_slots") and inv["weapon_slots"] is Array:
            var slots: Array = inv["weapon_slots"]
            if slots.size() < 4:
                # Expand to 4 slots, filling missing with null
                while slots.size() < 4:
                    slots.append(null)
                inv["weapon_slots"] = slots
    
    # Bump producer-local schema version
    if snap.has("inventory") and snap["inventory"].has("schema_version"):
        snap["inventory"]["schema_version"] = 1
    
    return snap

# === Example upgrade: v1 → v2 ===
# (Hypothetical: v2 renamed "mech.parts_head_hp" → "mech.parts.{head}.hp")
func _upgrade_v1_to_v2(snap: Dictionary) -> Dictionary:
    if snap.has("mech") and snap["mech"] is Dictionary:
        var mech: Dictionary = snap["mech"]
        if mech.has("parts_head_hp") and not mech.has("parts"):
            mech["parts"] = {
                &"head": {"hp": mech["parts_head_hp"]},
                &"chest": {"hp": mech.get("parts_chest_hp", 100)},
                &"arms": {"hp": mech.get("parts_arms_hp", 100)},
                &"legs": {"hp": mech.get("parts_legs_hp", 100)},
            }
            mech.erase("parts_head_hp")
            mech.erase("parts_chest_hp")
            mech.erase("parts_arms_hp")
            mech.erase("parts_legs_hp")
    return snap
```

### Implementation Guidelines

#### When to bump save_version

| Change | Bump save_version? | Why |
|--------|---------------------|-----|
| Add new optional field | **No** | Forward-compat handles it (per ADR-0003) |
| Add new required field | **Yes** | Old saves lack the field; need upgrade |
| Rename field | **Yes** | Old saves have the old name; need rename |
| Remove field | **Yes** | Old saves have the field; need to ignore (or upgrade) |
| Change field type | **Yes** | Old saves have wrong type; need conversion |
| Reorder fields | **No** | Dictionary key order is irrelevant |
| Change default value | **No** | New default applies to new saves; old saves still have old value |
| Add new namespace (new producer) | **No** | Producer absent → graceful default (per ADR-0003) |

#### Bump process

1. Increment `SAVE_VERSION_CURRENT` (e.g., 1 → 2)
2. Write the upgrade function `_upgrade_v1_to_v2` and register it in `_ready()`
3. Increment producer-local `schema_version` (only for affected producers)
4. Add a unit test with a v1 sample save → assert upgrade produces correct v2 save
5. Update this ADR's "Upgrade chain" section
6. Re-run `/architecture-review` to ensure all cross-doc references still hold

#### Backup policy

| Policy | Behavior |
|--------|----------|
| Before upgrade | `user://save_<slot>.json` → `user://save_<slot>.bak.json` (overwrite) |
| After successful load | Keep `.bak.json` for 7 days (or until next upgrade) |
| On next upgrade | New `.bak.json` overwrites old |

#### Failure modes

| Failure | Behavior |
|---------|----------|
| No upgrade function for (v, v+1) | Log error, return partial snapshot; caller fails load |
| Upgrade function throws | Catch, log, return original snap; caller fails load |
| Upgrade produces invalid snap (missing required field) | Log error, fail load |
| Disk full during backup | Log warning, continue without backup; user accepts risk |

#### What we DON'T upgrade

- **Producer-local schema** — handled in each producer's `load_snapshot` (per ADR-0003)
- **Forward-compat** (new field added) — handled by `load_snapshot` using `.get(key, default)`
- **Type fixes** within existing fields — handled by `load_snapshot` with type-mismatch warning

The `upgrade_snapshot` is only for **file-level breaking changes** that producers can't handle.

#### When to add a new upgrade function

| Trigger | Add upgrade? |
|--------|--------------|
| New field that producers must know about | Yes (bump save_version) |
| New field that producers treat as optional | No (let `load_snapshot` use default) |
| New namespace (new producer) | No (load_snapshot handles missing namespace) |
| Field rename | Yes (bump save_version) |
| Field removal | Yes (bump save_version, upgrade to "remove and default") |

#### Producer-level vs file-level schema

| Concern | Owner | Example |
|---------|-------|---------|
| Producer-local schema | The producer | "Inventory has its own schema_version" |
| File-level schema (save_version) | SaveManager | "Save v0 has different field names" |
| Engine version | Per ADR-0006 | "Godot 4.6.x is the pin" |

Producer-level and file-level can drift. E.g., save v0 has `inventory.schema_version = 1`, but inventory itself can be at schema 2 (producer evolved). The producer's `load_snapshot` handles producer-level; the file-level `upgrade_snapshot` handles file-level.

#### Why not a generic "schema-migration framework"?

- Could use a library like `godot-schema-migrator` if it existed
- MVP scope: 1-3 upgrade functions over the game's lifetime. Roll-your-own is 30 lines.
- A framework adds dependency and indirection for negligible benefit

## Alternatives Considered

### Alternative 1: Always-rewrite, no version

- **Description**: Don't track save_version; on load, run all producers' `load_snapshot` with `snap.get(key, default)`
- **Pros**: Simple — no upgrade chain
- **Cons**: If a field is **renamed**, old saves still have old name → silently treated as missing → wrong data
- **Estimated Effort**: -50% code, +500% debugging on rename
- **Rejection Reason**: Doesn't handle renames or type changes. Per `save-load.md` C-R5, explicit version is required.

### Alternative 2: Producer-owned upgrade paths

- **Description**: Each producer has its own `_upgrade_v0_to_v1`; SaveManager delegates
- **Pros**: Each producer controls its own evolution
- **Cons**: SaveManager has to know which producer handles which fields; upgrade chain is scattered
- **Estimated Effort**: +20% boilerplate, more files
- **Rejection Reason**: Centralized in SaveManager = single audit point. Producers shouldn't know about file-level versioning.

### Alternative 3: Database-style migrations (e.g., Alembic, Flyway)

- **Description**: Each migration is a forward-only `up` function with a reverse `down` (not used in prod)
- **Pros**: Industry standard, well-tested patterns
- **Cons**: Heavier; the use case is 1-3 migrations over 5+ years, not 100+ over a project's life
- **Estimated Effort**: +200% boilerplate for negligible benefit
- **Rejection Reason**: Overkill for MVP. We can adopt Alembic-style later if migration count explodes.

### Alternative 4: Reject old saves (no upgrade)

- **Description**: If `save_version < SAVE_VERSION_CURRENT`, refuse to load with error
- **Pros**: Simplest — no upgrade functions
- **Cons**: Bad UX — player loses progress on every major update
- **Estimated Effort**: -100% upgrade code, -50% player retention
- **Rejection Reason**: `save-load.md` C-R5 mandates upgrade. We committed to "player's progress is sacred".

## Consequences

### Positive

- **Future-proof** — old saves can be loaded in new code, indefinitely
- **Single source of truth** — SaveManager owns file-level version; producers don't have to know
- **Testable** — every upgrade function is a unit test (old save → upgraded save → load → assert same state)
- **Additive** — adding v1→v2 doesn't require touching v0→v1
- **Backup** — original save is preserved on upgrade failure
- **Logged** — every upgrade is recorded for debugging

### Negative

- **Manual upgrade functions** — every breaking change requires writing 1 function
- **No "downgrade" support** — if save is v2 and code is v1, refuse (acceptable for single-player)
- **Backup storage** — `.bak.json` files accumulate (mitigated by 7-day cleanup)
- **Test maintenance** — every upgrade function has tests; tests accumulate over time

### Neutral

- Per ADR-0003, producer-local schema version is separate from save_version
- Upgrade chain is in code, not config (no migration scripts)
- `upgrade_snapshot` is a method on SaveManager, not a separate file

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Dev forgets to bump save_version on breaking change | High | Medium | Linter checks git diff: if a producer field is renamed, save_version should bump |
| Upgrade function has a bug (e.g., wrong field name) | Medium | High | Unit test with v_old sample save; backup before upgrade |
| Backup fails (disk full) | Low | Medium | Log warning, continue without backup; user accepts risk |
| Upgrade chain grows unbounded over 5 years | Low | Low | Documented as "1-3 migrations per year" in save-load.md |
| File too old to upgrade (e.g., 3 versions behind) | Low | Low | Upgrade chain is forward-only; works for any depth |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| Upgrade time per version | N/A | <1ms (Dict manipulation) | <10ms |
| Total upgrade time (3 versions) | N/A | <3ms | <10ms |
| Backup copy time | N/A | <1ms | <5ms |
| Memory during upgrade | N/A | ~10-50 KB (Dict copy) | <100 KB |

## Migration Plan

N/A — this ADR is the greenfield policy. First upgrade will happen when v1 → v2 in production.

**Rollback plan**: If a v1→v2 upgrade function has a bug and is discovered post-release:
1. Hotfix: fix the upgrade function in a patch release (e.g., v1.0.1)
2. Players who already attempted upgrade: their `.bak.json` is still on disk → manual recovery
3. Add a "diagnostic mode" to log every upgrade result for QA

## Validation Criteria

- [ ] **First upgrade test**: save v0 → upgrade code to v1 → load v0 save → assert upgraded correctly + all producers in correct state
- [ ] **Multi-version upgrade test**: save v0 → upgrade code to v2 (with both v0→v1 and v1→v2 functions) → load v0 save → assert all fields present
- [ ] **Idempotency test**: upgrade v0→v1 twice → assert same result
- [ ] **Backup test**: upgrade creates `.bak.json` matching original save
- [ ] **Missing upgrade function test**: simulate missing `_upgrade_v0_to_v1` → load fails gracefully, no crash
- [ ] **Backup failure test**: simulate disk full during backup → upgrade continues (logs warning), still succeeds
- [ ] **Type-mismatch in upgrade test**: upgrade function has a typo → load fails, error logged

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/save-load.md` | Save/Load | **C-R5**: "Load 时校验 + 自愈" | Defines centralized upgrade_snapshot function |
| `design/gdd/save-load.md` | Save/Load | **C-R5**: "如果 `save_version` 不匹配 → 升级路径" | Specifies chain-of-functions upgrade pattern |
| `design/gdd/save-load.md` | Save/Load | **C-R5**: "如果某个字段缺失或类型错 → 用默认值填充" | Handled by producer `load_snapshot` (per ADR-0003), not upgrade |
| `design/gdd/save-load.md` | Save/Load | **E6**: "Save 写盘过程中崩溃" | Backup before upgrade mitigates this risk |

> Foundational — no single GDD requirement; this ADR codifies the *implementation* of save versioning as declared in `save-load.md` C-R5.

## Related

- **Depends on**:
  - ADR-0003 (Save Contract — defines what we serialize)
  - ADR-0004 (Save I/O — calls upgrade on load)
- **Enables**:
  - Production migrations
  - Hotfixes that change save schema
  - New content (chapters) requiring schema changes
- **Code locations** (when implemented):
  - `src/autoload/save_manager.gd` (this ADR's pseudocode)
  - `tests/unit/save_upgrade_test.gd` (unit tests for every upgrade function)
  - `tools/snapshot_v0.json` (sample v0 save for testing)
