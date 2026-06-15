# ADR-0004: Save/Load I/O (Async Write Path)

## Status

Accepted

## Date

2026-06-12

## Last Verified

2026-06-12

## Decision Makers

User + technical-director (self-review)

## Summary

SaveManager writes to `user://save_<slot>.json` via Godot 4.4+ `FileAccess.store_string()` (which returns `bool` — must check) on a **dedicated async write thread** using `WorkerThreadPool.add_task()`. Reads are synchronous (load is rare; load happens on TITLE screen so blocking is OK). This avoids main-thread stalls, handles `false` return values correctly (treat as `save_failed` signal), and gives us a clean error path. Codifies `save-load.md` C-R6 and C-R7.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Persistence (FileAccess + threading) |
| **Knowledge Risk** | MEDIUM — `WorkerThreadPool` is 4.0+, but `FileAccess` thread-safety and the `store_string` return type are 4.4+ changes |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md` |
| **Post-Cutoff APIs Used** | `FileAccess.store_string()` returns `bool` (4.4 change — pre-4.4 returned `void`); `WorkerThreadPool.add_task()` (4.0+, stable) |
| **Verification Required** | First save: assert file written within 30ms. Disk full simulation: `store_string` returns `false` → emit `save_failed`. Threaded write: assert main thread never blocks > 2ms during save |

> **Note**: Knowledge Risk is MEDIUM because Godot 4.5 changed the SDL3 gamepad backend which also restructured how `FileAccess` integrates with OS file handles. Must verify at first use site that our write pattern works on 4.6 specifically.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (SaveManager autoload), ADR-0003 (Save Contract — defines what we serialize) |
| **Enables** | Save/Load implementation; autosave triggers (per save-load.md F1) |
| **Blocks** | First save/load implementation PR; autosave on chapter/room/victory |
| **Ordering Note** | Fourth ADR. After Save Contract, before Save Upgrade |

## Context

### Problem Statement

Saving the game involves:
1. Calling 10 producer systems' `get_state_snapshot()` (ADR-0003)
2. Composing into a Dictionary
3. `JSON.stringify()` to text
4. `FileAccess.open_write(path)` + `store_string(json)` + `flush()` + close
5. Error handling (disk full, permission denied, file locked)

The naive approach (synchronous, on main thread) has problems:
- **Frame stall**: JSON encode + file write can take 10-30ms → frame drops to 33 FPS
- **Crash on disk full**: if `FileAccess.store_string` fails (returns `false` in 4.4+), the naive code doesn't check → silent data loss
- **Concurrent writes**: if autosave triggers while a manual save is in progress → file corruption

The fix is:
- Async write (off main thread)
- Check `store_string` return value
- Serialize write requests through a queue

### Current State

`save-load.md` C-R6: *"Save 不阻塞主循环. SaveManager 在 `_process` 中**异步**写盘."*
`save-load.md` C-R7: *"Save 失败不丢数据. 如果 FileAccess 写入失败 → `SaveError` 信号 + HUD 提示."*

Both C-Rules are stated but not specified at the I/O level. This ADR specifies *how*.

### Constraints

- **Single-player only** — no need for cross-network sync
- **MVP scope** — no cloud save, no encryption, no async I/O on multiple slots simultaneously
- **Godot 4.6 FileAccess** — `store_string` returns `bool` (4.4+ change), `flush()` is 4.0-stable
- **Worker thread safety** — Godot 4.6 `WorkerThreadPool` is safe for I/O but **not** for any Godot Object access
- **Crash safety** — if app crashes mid-write, save is corrupt (acceptable; ADR-0005 covers upgrade)

### Requirements

- **Non-blocking**: main thread stall during save ≤ 2ms
- **Reliable**: `false` return from `store_string` is detected and treated as `save_failed` signal
- **Atomic**: a save either completes fully or doesn't (no partial files)
- **Bounded queue**: at most 1 pending save at a time (skip newer if older pending)
- **Crash-safe**: corrupt save → graceful fail to TITLE (per save-load.md E2)

## Decision

### Architecture

```
SaveManager (autoload #5):

  ┌─ _process(delta) ─────────────────────────────────────────┐
  │                                                            │
  │  1. Check autosave triggers (chapter / room / victory)     │
  │     If triggered: _enqueue_save(autosave_slot)             │
  │                                                            │
  │  2. Check pending save state                                │
  │     - PENDING → check WorkerThreadPool.is_task_completed() │
  │       If completed: process result                          │
  │     - IDLE → nothing to do                                   │
  │                                                            │
  └────────────────────────────────────────────────────────────┘

  ┌─ _enqueue_save(slot) ────────────────────────────────────┐
  │                                                            │
  │  1. If slot is currently PENDING:                           │
  │     Log "skipping newer save, old still in flight"          │
  │     Return (the older save will complete first)              │
  │                                                            │
  │  2. Call serialize_all() (synchronous — 10 producers)      │
  │     Time budget: 5ms                                        │
  │                                                            │
  │  3. Convert to JSON (synchronous — 1ms)                     │
  │                                                            │
  │  4. Submit to WorkerThreadPool.add_task():                  │
  │     Task: _write_to_disk(slot, json)                        │
  │                                                            │
  └────────────────────────────────────────────────────────────┘

  ┌─ Worker thread: _write_to_disk(slot, json) ─────────────┐
  │                                                            │
  │  1. file = FileAccess.open_write("user://save_<slot>.json") │
  │     If file == null: emit save_failed, return                │
  │                                                            │
  │  2. ok = file.store_string(json)                             │
  │     If ok == false: emit save_failed, file.close, return    │
  │                                                            │
  │  3. file.flush()                                             │
  │                                                            │
  │  4. file.close()                                             │
  │                                                            │
  │  5. Set _pending_result = { slot, OK, timestamp }           │
  │                                                            │
  └────────────────────────────────────────────────────────────┘

  ┌─ _process (next frame) — process result ──────────────────┐
  │                                                            │
  │  If _pending_result is set:                                │
  │    if OK: emit save_completed(slot)                         │
  │    if not OK: emit save_failed(slot, error)                 │
  │    Clear _pending_result                                    │
  │                                                            │
  └────────────────────────────────────────────────────────────┘

  ┌─ Load (synchronous, on main thread) ──────────────────────┐
  │                                                            │
  │  1. file = FileAccess.open_read(path)                        │
  │     If file == null: return ERR_FILE_NOT_FOUND              │
  │                                                            │
  │  2. json = file.get_as_text()                              │
  │     file.close()                                            │
  │                                                            │
  │  3. snap = JSON.parse_string(json)                          │
  │     If parse fails: return ERR_PARSE_ERROR                  │
  │                                                            │
  │  4. Validate schema (per ADR-0003 + ADR-0005)              │
  │                                                            │
  │  5. restore_all(snap) (synchronous — calls 10 producers)   │
  │                                                            │
  │  6. Return OK                                                │
  │                                                            │
  └────────────────────────────────────────────────────────────┘
```

### Key Interfaces

```gdscript
# === SaveManager (autoload #5) — write path ===
# File: src/autoload/save_manager.gd
class_name SaveManager
extends Node

const SAVE_VERSION_CURRENT: int = 1
const SLOT_AUTOSAVE: int = -1  # sentinel for autosave
const MANUAL_SLOT_COUNT: int = 3  # slots 0-2

var _pending_slot: int = -2  # -2 = idle, -1 = autosave, 0-2 = manual
var _pending_thread: WorkerThreadPool.TaskID = -1
var _pending_result: Dictionary = {}

func _ready() -> void:
    set_process(true)

func _process(_delta: float) -> void:
    if _pending_thread == -1:
        return  # idle
    
    if not WorkerThreadPool.is_task_completed(_pending_thread):
        return  # still running, check next frame
    
    # Task completed — process result
    if _pending_result.get("ok", false):
        save_completed.emit(_pending_slot)
    else:
        save_failed.emit(_pending_slot, _pending_result.get("error", "unknown"))
    
    _pending_slot = -2
    _pending_thread = -1
    _pending_result = {}

# Public: trigger a save (autosave or manual)
func save_to_slot(slot: int) -> Error:
    if _pending_slot != -2:
        push_warning("SaveManager: save already in flight for slot %d, skipping" % _pending_slot)
        return ERR_BUSY
    
    # Synchronous part (main thread, ≤ 6ms total)
    var save_dict: Dictionary = serialize_all()
    var json: String = JSON.stringify(save_dict, "  ")
    
    # Hand off to worker thread
    _pending_slot = slot
    _pending_result = {}  # clear any stale result
    _pending_thread = WorkerThreadPool.add_task(_write_to_disk.bind(slot, json), true)
    # `true` = high priority (realtime-ish)
    
    return OK

# Worker thread function (Godot 4.6 WorkerThreadPool)
func _write_to_disk(slot: int, json: String) -> void:
    var path: String = _slot_to_path(slot)
    var file: FileAccess = FileAccess.open_write(path)
    
    if file == null:
        # FileAccess error (permission, etc.)
        var err: Error = FileAccess.get_open_error()
        call_deferred("_set_write_result", slot, false, "FileAccess.open_write failed: %s" % err)
        return
    
    # CRITICAL: store_string returns bool in 4.4+ — MUST check
    var ok: bool = file.store_string(json)
    if not ok:
        call_deferred("_set_write_result", slot, false, "store_string returned false (disk full?)")
        file.close()
        return
    
    file.flush()
    file.close()
    
    call_deferred("_set_write_result", slot, true, "")

# Deferred setter (thread-safe: called on main thread)
func _set_write_result(slot: int, ok: bool, error: String) -> void:
    _pending_result = {"slot": slot, "ok": ok, "error": error}

# Public: trigger load (synchronous, on main thread)
func load_from_slot(slot: int) -> Error:
    var path: String = _slot_to_path(slot)
    
    if not FileAccess.file_exists(path):
        return ERR_FILE_NOT_FOUND
    
    var file: FileAccess = FileAccess.open_read(path)
    if file == null:
        push_error("SaveManager: open_read failed: %s" % FileAccess.get_open_error())
        return ERR_FILE_CANT_OPEN
    
    var json: String = file.get_as_text()
    file.close()
    
    var parsed: Variant = JSON.parse_string(json)
    if parsed == null:
        push_error("SaveManager: JSON parse failed")
        return ERR_PARSE_ERROR
    
    if not parsed is Dictionary:
        push_error("SaveManager: save is not a Dictionary")
        return ERR_INVALID_DATA
    
    var snap: Dictionary = parsed
    
    # Schema version check (per ADR-0005)
    var save_version: int = snap.get("save_version", 0)
    if save_version > SAVE_VERSION_CURRENT:
        push_error("SaveManager: save too new (v%d > v%d)" % [save_version, SAVE_VERSION_CURRENT])
        return ERR_INVALID_DATA
    if save_version < SAVE_VERSION_CURRENT:
        # Run upgrade path (per ADR-0005)
        snap = _upgrade_snapshot(snap, save_version, SAVE_VERSION_CURRENT)
    
    # Restore all producers
    var err: Error = restore_all(snap)
    if err != OK:
        push_error("SaveManager: restore_all returned %s" % err)
        return err
    
    load_completed.emit(slot)
    return OK

# Public: autosave (special slot)
func get_autosave() -> Error:
    return load_from_slot(SLOT_AUTOSAVE)

# Slot to file path
func _slot_to_path(slot: int) -> String:
    if slot == SLOT_AUTOSAVE:
        return "user://save_autosave.json"
    return "user://save_%d.json" % slot

# Public signals
signal save_completed(slot: int)
signal save_failed(slot: int, error: String)
signal load_completed(slot: int)
signal load_failed(slot: int, error: String)
```

### Implementation Guidelines

#### Thread safety

| Operation | Thread | Safe? | Notes |
|-----------|--------|-------|-------|
| `serialize_all()` (call 10 producers) | Main | ✅ | Godot Object access is main-thread only |
| `JSON.stringify()` | Main | ✅ | Pure function, no Godot Object access |
| `WorkerThreadPool.add_task(_write_to_disk)` | Main | ✅ | Just queues the call |
| `_write_to_disk` (FileAccess operations) | **Worker** | ✅ | FileAccess is thread-safe in 4.6 |
| `call_deferred("_set_write_result", ...)` | **Worker** | ✅ | `call_deferred` is thread-safe |
| `_pending_result = {...}` | Main (via deferred) | ✅ | Always on main thread |
| `save_completed.emit(...)` | Main (via `_process`) | ✅ | Signal emit is main-thread only |
| Restore (load) | **Main** | ✅ | Synchronous, no threading |

#### Why `call_deferred` and not direct assignment?

- `_write_to_disk` runs on worker thread
- `_pending_result` is a Godot Dictionary — assigning to it from worker is **unsafe** (no memory barrier)
- `call_deferred` queues the assignment to happen on main thread, on the next frame
- This guarantees `_process` sees the result after it's set

#### Why skip if pending?

- If player triggers save while another is in flight, **the older one wins** (avoids two writers competing for the same file)
- MVP scope: no save queue (later VS could add a queue)
- This is documented as a known limitation; UI feedback is "Save in progress, please wait"

#### What about autosave during manual save?

- Same logic: the second save is dropped
- The player can see "Save in progress" toast

#### What about crash mid-write?

- Mid-write file is corrupt (JSON parse fails on load)
- `load_from_slot` returns `ERR_PARSE_ERROR` + logs error
- Per `save-load.md` E2 + E6: graceful fail to TITLE new game
- Crash safety is the cost of the async pattern; mitigated by autosave (always have a recent good save)

#### File path

| Slot | Path | Notes |
|------|------|-------|
| -1 (autosave) | `user://save_autosave.json` | Always overwritten |
| 0 | `user://save_0.json` | Manual slot 0 |
| 1 | `user://save_1.json` | Manual slot 1 |
| 2 | `user://save_2.json` | Manual slot 2 |

`user://` resolves to OS-specific app data dir:
- Linux: `~/.local/share/godot/app_userdata/Railhunter/`
- macOS: `~/Library/Application Support/Godot/app_userdata/Railhunter/`
- Windows: `%APPDATA%/Godot/app_userdata/Railhunter/`

#### Why not use a 3rd-party save library?

- godot-save-shader, gd-save, etc. exist but add dependency
- Godot 4.6 FileAccess is simple enough (~30 lines) that a wrapper isn't justified
- Custom code = full control over versioning (ADR-0005)

#### Performance budget (per save-load.md F3)

| Operation | Time | Notes |
|-----------|------|-------|
| `serialize_all()` | 5ms | 10 producers × 0.5ms |
| `JSON.stringify()` | 1ms | ~1-2 KB |
| `add_task` (queueing) | <0.1ms | Just a queue insert |
| `_write_to_disk` (worker) | 5-10ms | FileAccess + flush |
| `_process` (result handling) | <0.5ms | Signal emit |
| **Total** | **~15ms** | <16.6ms frame budget (per save-load.md) |

## Alternatives Considered

### Alternative 1: Synchronous write on main thread

- **Description**: `save_to_slot` blocks the main thread until disk write completes
- **Pros**: Simpler — no thread, no `call_deferred`, no result queue
- **Cons**: 10-30ms frame stall on save → visible hitch, especially on slow disks
- **Estimated Effort**: -80% complexity, +10ms per save
- **Rejection Reason**: Visible hitch breaks the 60 FPS contract (per `technical-preferences.md`). Players notice stutters during gameplay.

### Alternative 2: Full async (read + write on worker thread)

- **Description**: Reads also on worker thread
- **Pros**: All I/O off main thread
- **Cons**: Load happens on TITLE screen, where blocking is fine. Adds complexity for zero benefit.
- **Estimated Effort**: +50% complexity, 0 benefit
- **Rejection Reason**: Premature optimization. Title screen load is naturally async to user.

### Alternative 3: Use a save game addon (e.g., `godot-game-save`)

- **Description**: Third-party save addon
- **Pros**: Mature, well-tested
- **Cons**: Dependency; custom versioning; doesn't support per-producer namespaces
- **Estimated Effort**: -50% initial, +30% debugging (don't fully own the code)
- **Rejection Reason**: ADRs need full control over versioning (per ADR-0005). A third-party addon would be a black box.

### Alternative 4: Batch all saves (write every 30s if dirty)

- **Description**: Accumulate changes; flush every 30s
- **Pros**: Fewer disk writes (better SSD lifetime)
- **Cons**: If crash within 30s, lose 30s of progress
- **Estimated Effort**: -50% writes, +30s potential data loss
- **Rejection Reason**: `save-load.md` C-R3 mandates autosave at safe points (chapter/room/victory). 30s batching is incompatible with that policy.

## Consequences

### Positive

- **No main-thread stall** — save is async, game continues at 60 FPS during save
- **Reliable error detection** — `store_string` return value is checked; `save_failed` is emitted on disk full
- **Crash-safe** — corrupt save → graceful fail to TITLE; autosave is always recent
- **Deterministic** — save → load → same state (after ADR-0003 contract)
- **Debuggable** — JSON file is human-readable; `cat user://save_autosave.json | jq`

### Negative

- **One-save-in-flight policy** — concurrent saves are dropped (acceptable for MVP)
- **Async complexity** — `call_deferred` + worker thread + main thread coordination is harder to debug
- **Worker thread context** — Godot signals and `Node` access from worker thread = crash (mitigated by careful rules)
- **Save window** — during the 10-15ms save, a frame could be lost (acceptable, it's not a render frame)

### Neutral

- `WorkerThreadPool` is shared with other Godot internals; our task is small (10ms) so contention is negligible
- Save file size is JSON, not binary; bigger but more debuggable
- No file rotation or backup (MVP scope)

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| `FileAccess` thread-safety issue on 4.6 (4.5 SDL3 backend change) | Low | High | First use site integration test; verify on Windows + macOS + Linux |
| `call_deferred` from worker → main missed (e.g., main thread blocked) | Low | Medium | Defensive: also check `WorkerThreadPool.is_task_completed` directly in `_process` |
| Disk full mid-save | Medium | Medium | `store_string` returns `false` → emit `save_failed`; player retries |
| File lock by antivirus (Windows) | Medium | Low | One retry after 100ms; if still fails, `save_failed` |
| Multiple manual saves in quick succession (player rage-saves) | Low | Low | One-save-in-flight policy drops the second; UI feedback |
| Save file corruption by user manual edit | Low | Low | JSON parse error → graceful fail to TITLE (per save-load.md E2) |
| Worker thread pool exhaustion (other systems) | Low | Low | Godot 4.6 `WorkerThreadPool` has unbounded task queue by default |
| `user://` path not writable (permission) | Low | High | First boot integration test asserts file write succeeds |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| Main thread stall during save | 10-30ms (sync) | <2ms | <2ms |
| Save file size | N/A | 1-2 KB | <5 KB |
| Disk I/O time | N/A | 5-10ms | <16.6ms |
| Autosave frequency | N/A | per chapter/room/victory (per save-load.md F1) | ~30/session |
| Memory during save (Dict composition) | N/A | ~10-20 KB | <50 KB |

## Migration Plan

N/A — greenfield. First save happens after this ADR is implemented.

**Rollback plan**: If async write proves unstable (e.g., thread-safety bug in 4.6):
1. Fall back to synchronous write (Alternative 1) with frame-budget safeguards
2. Log a "frame stall" warning on save for QA
3. Open a Godot 4.6 issue / upgrade to fix thread-safety
4. Update this ADR with the regression

Migration is just: replace `_write_to_disk` worker with synchronous write. Single function change.

## Validation Criteria

- [ ] **First save test**: complete a play session, trigger autosave, assert `user://save_autosave.json` exists, has 11 top-level keys
- [ ] **Manual save test**: F5 → save to slot 0 → file appears
- [ ] **Load test**: load slot 0 → state restored correctly
- [ ] **Main thread test**: instrument `_process` with timestamp; assert no frame stalls > 2ms during save
- [ ] **Disk full test**: simulate by making `user://` read-only → `save_to_slot` → `save_failed` signal fires within 30ms
- [ ] **Worker thread test**: confirm `_write_to_disk` runs on a non-main thread (e.g., `OS.get_thread_caller_id() != OS.get_main_thread_id()`)
- [ ] **Crash test**: kill app mid-save → restart → `load_from_slot` returns `ERR_PARSE_ERROR` → graceful TITLE fallback
- [ ] **Concurrent save test**: trigger 5 manual saves in 100ms → first wins, others logged as skipped

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/save-load.md` | Save/Load | **C-R6**: "Save 不阻塞主循环" | Defines async write via `WorkerThreadPool.add_task` |
| `design/gdd/save-load.md` | Save/Load | **C-R7**: "Save 失败不丢数据" | Checks `store_string` return value; emits `save_failed` |
| `design/gdd/save-load.md` | Save/Load | **C-R3**: "Autosave 在 safe points 触发" | Implemented as `_enqueue_save` calls in `_process` |
| `design/gdd/save-load.md` | Save/Load | **F3**: "save_time_ms ~10ms (async)" | Validated against this budget |
| `design/gdd/save-load.md` | Save/Load | **C-R4**: "Save 文件格式 = JSON" | Mandated in this ADR |

> Foundational — no single GDD requirement; this ADR codifies the *implementation* of save/load as defined in `save-load.md`.

## Related

- **Depends on**:
  - ADR-0001 (SaveManager autoload position)
  - ADR-0003 (Save Contract — what we serialize)
- **Enables**:
  - ADR-0005 (Save Upgrade — operates on snapshot Dict after load)
  - First save/load implementation PR
  - Autosave triggers
- **Code locations** (when implemented):
  - `src/autoload/save_manager.gd` (this ADR's pseudocode)
  - `tests/integration/save_io_test.gd` (integration tests)
  - `tools/simulate_disk_full.sh` (dev tool for testing error path)
