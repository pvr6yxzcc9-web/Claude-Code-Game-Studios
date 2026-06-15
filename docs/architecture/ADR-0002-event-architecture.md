# ADR-0002: Event Architecture (Signal vs Direct Call vs Shared State)

## Status

Accepted

## Date

2026-06-12

## Last Verified

2026-06-12

## Decision Makers

User + technical-director (self-review, APPROVED WITH CONCERNS 2026-06-12)

## Summary

Railhunter uses **Godot signals as the only cross-module communication mechanism** at module boundaries. Direct method calls are reserved for **within a single module's internals**, and shared state (e.g. global dictionaries, autoload-held variables) is used **only** for data the system explicitly owns per the "state is owned, not scattered" architecture principle. Signal naming follows a strict `<past_tense>_<subject>` pattern with payload always a single Dictionary. This codifies architecture principle #4 ("Signals at the module boundary, methods within") and unblocks every signal-heavy system (HUD, EncounterManager, BattleCore, SaveManager).

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (Scripting + signals) |
| **Knowledge Risk** | LOW — signals in training, 4.6 changes are additive (typed payload validation, `await` semantics stable) |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` (4.6 pin) |
| **Post-Cutoff APIs Used** | None — signals are 4.0-stable |
| **Verification Required** | First use site: 1 publisher + 1 subscriber + 1 disconnect. Verify signal stays connected after both `_ready` and after `queue_free` of subscriber. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (Scene Management — autoload order establishes signal publish/consume order) |
| **Enables** | Every signal-heavy system: HUD, EncounterManager, BattleCore, SaveManager, MetaState, ResourceRegistry |
| **Blocks** | All implementation epics involving module-to-module communication |
| **Ordering Note** | Must be second ADR. Establishes the rules other ADRs (especially Save/Load) rely on. |

## Context

### Problem Statement

Railhunter has ~50 cross-module events per second during gameplay (input dispatch every frame, HP changes on hit, mode toggle on A press, encounter trigger on tile entry, etc.). We have three possible communication mechanisms:

1. **Direct method call**: `BattleCore.some_method()`
2. **Signal**: `BattleCore.some_signal.connect(listener.method)`
3. **Shared state**: Read `GameStateMachine.state_stack` from anywhere

Each has different consequences:
- **Direct call**: fast, but creates tight coupling. If BattleCore's API changes, all callers break.
- **Signal**: loose coupling, but if 50+ signals exist, naming becomes chaos and connections leak.
- **Shared state**: simplest, but violates "state is owned" — multiple systems writing the same Dictionary = bugs.

The architecture principle #4 ("Signals at the module boundary, methods within") needs codification as a *concrete rule*, not a guideline. Otherwise, devs default to "whatever's easiest" and we end up with a mix that no one can navigate.

### Current State

- `design/gdd/game-state-machine.md` already declares: `signal state_changed(old: StringName, new: StringName)` on the state machine.
- `design/gdd/player-input.md` declares: `signal action_pressed / action_released / action_held` on the InputBus.
- `design/gdd/battle-core-loop.md` declares: `signal battle_ended / mode_switched / turn_started / turn_ended / damage_dealt` on BattleCore.
- `design/gdd/save-load.md` declares: `signal save_completed / save_failed / load_completed / load_failed` on SaveManager.

So signals are already the *de facto* pattern, but no ADR defines:
- Naming convention (camelCase? snake_case? subject-first?)
- Payload type (Dictionary? Typed? Untyped Variant?)
- Disconnect responsibility (who disconnects when?)
- "What NOT to do" rules (no shared state, no direct cross-module calls)

### Constraints

- **GDScript + C# boundary**: signals crossing the language boundary are awkward (C# uses `EventHandler` delegates, GDScript uses `signal` keyword). The ADR must define a uniform pattern.
- **Solo dev**: low ceremony needed — naming convention should be simple, not a 50-page style guide.
- **Performance**: signal dispatch must add < 0.1ms per event. Godot's signal dispatch is fast (per-test ~5µs for 1 connection).
- **Memory**: signal connections are weak-ref-safe in 4.6 (per ADR-0001 E5 / player-input E9); subscriber `queue_free` won't crash.

### Requirements

- **Naming**: every cross-module signal follows a single, easily greppable pattern
- **Payload**: every signal carries a Dictionary (not 3+ args) for forward-compat
- **Disconnect**: subscribers disconnect on `_exit_tree()` automatically; publishers never manually disconnect
- **Cross-language**: C# ↔ GDScript signals use uniform pattern (use `EventHandler` delegate in C#)
- **No leakage**: signal connections from a freed subscriber must silently break (no crash, no error)
- **Testable**: every signal must have at least one integration test

## Decision

### Architecture

```
Communication rules:

WITHIN a module (e.g., inside BattleCore):
  → Direct method calls (BattleCore._start_player_turn())
  → Internal signals (private to file)

ACROSS modules (e.g., BattleCore → HUD):
  → Godot signal (cross-module) — REQUIRED
  → Signal naming: <past_tense>_<subject> snake_case
  → Payload: ALWAYS a single Dictionary
  → Publisher: defines signal, emits, never disconnects
  → Subscriber: connects in _ready, auto-disconnects in _exit_tree

SHARED STATE:
  → ONLY for data the module explicitly owns (per Module Ownership Map)
  → Read: any module may READ another module's owned state
  → Write: ONLY the owning module may WRITE
  → Exception: SaveManager (snapshot/restore is its job — it READS to snapshot, WRITES to restore)

NEVER:
  → Direct cross-module method calls
  → Static singletons (use autoloads + signals)
  → "God variables" (a single Dictionary shared everywhere)
```

### Key Interfaces

```gdscript
# === GDScript signal declaration pattern (publisher) ===
# File: src/autoload/game_state_machine.gd
class_name GameStateMachine
extends Node

# Signal: <past_tense>_<subject>(<typed_payload: Dictionary>)
signal state_changed(payload: Dictionary)
# Payload schema (documented in this file's header):
#   {old: StringName, new: StringName}

# Alternative: explicit typed parameters (preferred for stable contracts)
signal state_changed_explicit(old: StringName, new: StringName)
# (Use Dictionary when fields may grow over time; use typed when contract is stable.)


# === GDScript signal emit (publisher) ===
func transition_to(new_state: StringName) -> Error:
    var old_state: StringName = state_stack[-1]
    state_stack[-1] = new_state
    # Emit with Dictionary payload:
    state_changed.emit({"old": old_state, "new": new_state})
    return OK


# === GDScript signal connect (subscriber) ===
# File: src/ui/hud.gd
class_name HUD
extends CanvasLayer

func _ready() -> void:
    var gsm: GameStateMachine = get_node("/root/GameStateMachine")
    gsm.state_changed.connect(_on_state_changed)
    # Auto-disconnects when HUD _exit_tree (Godot 4.6 signal weak ref)

func _on_state_changed(payload: Dictionary) -> void:
    var old_state: StringName = payload.get("old", &"")
    var new_state: StringName = payload.get("new", &"")
    # Update HUD state badge...


# === C# signal declaration pattern (publisher) ===
// File: src/autoload/battle_core_bridge.cs
namespace Railhunter.Battle;

[GlobalClass]
public partial class BattleCoreBridge : Node
{
    [Signal]
    public delegate void DamageDealtEventHandler(Godot.Collections.Dictionary payload);

    public void EmitDamageDealt(string targetId, int amount, bool isCrit)
    {
        var payload = new Godot.Collections.Dictionary
        {
            { "target_id", targetId },
            { "amount", amount },
            { "is_crit", isCrit }
        };
        EmitSignal(SignalName.DamageDealt, payload);
    }
}


// === C# signal connect (subscriber) ===
// File: src/ui/hud_damage_numbers.cs
public partial class DamageNumbers : CanvasLayer
{
    public override void _Ready()
    {
        var battle = GetNode<BattleCoreBridge>("/root/BattleCoreBridge");
        battle.DamageDealt += OnDamageDealt;
    }

    private void OnDamageDealt(Godot.Collections.Dictionary payload)
    {
        var amount = (int)payload["amount"];
        var isCrit = (bool)payload["is_crit"];
        // Show floating damage number...
    }
}
```

### Implementation Guidelines

#### Naming convention

| Pattern | Example | Why |
|---------|---------|-----|
| `<past_tense>_<subject>` | `state_changed`, `damage_dealt`, `battle_ended` | Past-tense makes it a *fact* not a *command* |
| Always snake_case | `weapon_slot_1_pressed` not `WeaponSlot1Pressed` | Matches GDScript convention (per `technical-preferences.md`) |
| Never include "signal" / "event" in name | `damage_dealt` not `damage_dealt_event` | Redundant — `connect()` makes it a signal |
| Subject in singular | `weapon_switched` not `weapons_switched` | One event = one occurrence |

#### Payload rules

- **Default: single Dictionary** — even for 1-arg signals, use Dictionary for forward-compat
  - Allows adding fields without breaking subscribers
  - Allows optional fields (subscribers can `.get(key, default)`)
- **Optional: typed parameters** — when the contract is truly stable (e.g., `state_changed(old, new)`)
- **NEVER: more than 4 parameters** — readability limit

#### Connection rules

| Rule | Reason |
|------|--------|
| Subscribers connect in `_ready()` | Standard Godot pattern |
| Subscribers **never** manually disconnect | Godot 4.6 weak-ref-safe — `queue_free()` of subscriber auto-disconnects |
| Publishers **never** hold references to subscribers | Avoids memory leaks |
| Use `Callable` not String for `connect()` | String method names are typo-prone |

#### Module boundary (where signals are required)

| From → To | Communication | Example |
|-----------|---------------|---------|
| Autoload → Scene | **Signal** (required) | `GameStateMachine.state_changed` → `HUD._on_state_changed` |
| Scene → Autoload | **Direct call** OR signal depending on direction | `PlayerController` calls `GameStateMachine.transition_to()` (a public method) |
| Scene → Scene | **NEVER direct** — must go through an autoload | `Encounter` → `Battle` via `GameStateMachine.transition_to(BATTLE, payload)` |
| Autoload → Autoload | **Signal** for events, **direct call** for queries | `BattleCore` reads `GameStateMachine.top_of_stack` (query) but emits `battle_ended` (event) |
| C# ↔ GDScript | **Signal with Dictionary payload** (uniform) | `BattleCoreBridge.DamageDealt(Dictionary)` |

#### Shared state rules

| State | Owner | Readers | Writers |
|-------|-------|---------|---------|
| `state_stack` | `GameStateMachine` | Everyone (read-only) | `GameStateMachine` only |
| `top_of_stack` | `GameStateMachine` | Everyone (read-only) | `GameStateMachine` only |
| `discovered` | `MetaState` | HUD, Codex | `MetaState` only (via `mark_discovered()`) |
| `_registry` (loaded resources) | `ResourceRegistry` | Everyone (read-only via `get()`) | `ResourceRegistry` only |
| Player HP, ammo, weapons | `PlayerController` (Scene) | HUD (read-only) | `PlayerController` only |
| Battle state (turn, actors) | `BattleCore` (autoload) | HUD, Camera | `BattleCore` only |

**Rule**: any state that multiple modules read = the owning module is the **single writer**. Other modules must not write even for "convenience".

#### Anti-patterns (NEVER do this)

| Anti-pattern | Why it's wrong | Correct alternative |
|--------------|----------------|---------------------|
| `BattleCore.some_method()` called from HUD | Tight coupling; HUD now depends on BattleCore's API | HUD listens to `BattleCore.damage_dealt` signal |
| `globals.player_hp = 50` from anywhere | "God variable" — no owner, no contract | `PlayerController.take_damage(part, amount)` then HUD reads `_player_hp` |
| `OS.alert("error")` from any module | Side effect, not signal | Emit `error_occurred(payload)` signal; UI layer shows alert |
| `get_tree().get_first_node_in_group("battle")` from anywhere | Group lookup is for "find one of N" not "the singleton" | Use autoload: `BattleCore.do_thing()` |

## Alternatives Considered

### Alternative 1: EventBus pattern (Godot 4.x addons like EventBus)

- **Description**: Use a third-party EventBus addon; modules publish/subscribe to a global channel
- **Pros**: No need to declare signals on every publisher; loose typing
- **Cons**: Loses type safety; loses discoverability (`grep "signal " <file>` is the first tool devs use); add-on dependency
- **Estimated Effort**: -10% initial, +50% debugging time
- **Rejection Reason**: Godot 4.x signals are first-class and the engine's idiom. Third-party EventBus is a workaround for languages without signals.

### Alternative 2: Direct method calls everywhere (no signals)

- **Description**: Modules call each other's methods directly
- **Pros**: Faster (no signal dispatch overhead), simpler (no connection management)
- **Cons**: Tight coupling; one change breaks all callers; subscriber auto-disconnect on `queue_free` not possible
- **Estimated Effort**: -5% initial, +200% refactoring cost later
- **Rejection Reason**: Violates architecture principle #4. Loses the "subscriber auto-disconnect" win that Godot 4.6 gives for free.

### Alternative 3: Shared Dictionary globals (the "God Dictionary" anti-pattern)

- **Description**: One `globals.gd` autoload with a giant `Dictionary`; everyone reads/writes
- **Pros**: Trivial to use
- **Cons**: No ownership, no contracts, no type safety, no signal-driven reactivity
- **Estimated Effort**: -30% initial, infinite maintenance
- **Rejection Reason**: Architecture principle #1 is "state is owned, not scattered". This is the worst form of scattered state.

### Alternative 4: Hybrid (signals for events, direct calls for queries, shared state for "true" globals)

- **Description**: This ADR is what we picked — but explicitly enumerated
- **Pros**: Best of all worlds; rules are clear
- **Cons**: More rules to learn than "just signals"
- **Estimated Effort**: Same as chosen
- **Rejection Reason**: This IS the chosen approach. Listed for completeness.

## Consequences

### Positive

- **Loose coupling** — publishers don't know who consumes their events
- **Auto-cleanup** — Godot 4.6 signal weak refs mean `queue_free` of subscriber = silent disconnect
- **Discoverability** — `grep "signal " src/` finds every cross-module event
- **Cross-language safe** — C# `EventHandler` delegates interoperate with GDScript signals via `[Signal]` attribute
- **Type-safe where it matters** — Dictionary for forward-compat, typed args for stable contracts
- **Testable** — every signal has at least one integration test asserting the connection works

### Negative

- **Slower than direct call** — signal dispatch is ~5µs/connection. With 10 connections, ~50µs per event. Acceptable but not free.
- **"Where is this signal connected?"** — must use `connect()` callsite grep (not declaration)
- **Dictionary payload loses type safety** — typos in key names (`"dmg"` vs `"damage"`) caught only at runtime
- **Cannot subscribe to private internals** — signals are by definition public
- **Solo dev must remember the rules** — mitigated by control manifest (per architecture §9)

### Neutral

- 4-arg Dictionary limit is a soft convention (de facto enforced by linting or review)
- C# subscriber code is slightly more verbose than GDScript (delegate boilerplate)
- New signals require updating this ADR's "Naming convention" list (low ceremony)

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Dev uses direct call instead of signal | High | Medium | Control manifest forbids it; code review catches |
| Dictionary key typo (`"dmg"` vs `"damage"`) | Medium | Low | Unit tests assert payload keys; linting later |
| Signal not disconnected (memory leak in long sessions) | Low | Low | Godot 4.6 weak refs auto-disconnect on `queue_free` |
| C# ↔ GDScript signal type mismatch | Low | Medium | At first use site, verify payload type via integration test |
| Too many signals (50+) → discovery hard | Medium | Low | Naming convention + code organization + docs |
| Payload schema drift (one module adds field, others break) | Medium | Low | Subscribers use `.get(key, default)` for forward-compat |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| Signal dispatch latency | N/A | ~5µs per connection | <0.1ms total per event |
| Memory per connection | N/A | ~50 bytes (Callable + ref) | <100KB total at 200 signals |
| `_ready` connection cost | N/A | ~2ms (50 connections) | <10ms boot |
| Cross-language (C#↔GDScript) signal latency | N/A | ~10µs (Variant marshaling) | <0.5ms per event |

## Migration Plan

N/A — greenfield. All 5 autoloads and downstream systems will follow this convention from day 1.

**Rollback plan**: If signals prove wrong (unlikely), the fix is:
1. Add direct-call method as a fallback (the publisher exposes both)
2. Update this ADR with the new rule
3. Re-run CI linter to catch regressions
4. Re-run `/architecture-review`

No code changes required (signals coexist with direct calls; just remove the direct-call paths later).

## Validation Criteria

- [ ] **First signal test**: `GameStateMachine.state_changed` connect + emit + assert subscriber receives correct payload
- [ ] **Auto-disconnect test**: subscriber `_exit_tree()`; subsequent emit does not crash; signal connection silently removed
- [ ] **Cross-language test**: GDScript signal → C# delegate fires correctly with Dictionary payload
- [ ] **Naming test**: lint script greps `src/` for `signal ` lines, asserts all match `<past_tense>_<subject>` pattern
- [ ] **Payload schema test**: each signal's payload Dictionary is unit-tested for required keys
- [ ] **Performance test**: 100 signal emits per frame × 10 subscribers = 1000 dispatches/frame < 5ms

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/game-state-machine.md` | Game State Machine | `signal state_changed(old, new)` declared | Codifies signal naming + payload rules |
| `design/gdd/player-input.md` | Player Input | `signal action_pressed / action_released / action_held` on InputBus | Codifies signal-as-boundary pattern |
| `design/gdd/battle-core-loop.md` | Battle Core Loop | `signal battle_ended / mode_switched / turn_started / turn_ended / damage_dealt` | Codifies cross-module signal pattern |
| `design/gdd/save-load.md` | Save/Load | `signal save_completed / save_failed / load_completed / load_failed` | Codifies error signaling pattern |
| `design/gdd/collision.md` | Collision | `signal entity_near_interactable / bullet_hit / damage_area_tick / player_entered_encounter_tile` | Codifies physics-event signal pattern |
| (Architecture Principle #4) | All | "Signals at the module boundary, methods within" | Codifies as concrete rules |

> Foundational — no single GDD requirement; this ADR codifies the *pattern* used by 8+ GDDs.

## Related

- **Depends on**: ADR-0001 (autoload order)
- **Enables**:
  - ADR-0003 (Save/Load Contract) — uses signals for save lifecycle events
  - ADR-0009 (Input Binding) — uses signals for input events
  - All implementation stories involving cross-module communication
- **Code locations** (when implemented):
  - All `src/autoload/*.gd` files
  - All `src/ui/*.gd` files (HUD, Codex, Menu)
  - All `src/scene/**/*.gd` files (PlayerController, BattleCoreBridge, etc.)
  - `tools/lint_signal_naming.py` (CI linter for `<past_tense>_<subject>` pattern)
