# Test Infrastructure

**Engine**: Godot 4.6
**Test Framework**: GUT (Godot Unit Test) for GDScript, NUnit for C# (GDExtension)
**CI**: `.github/workflows/tests.yml`
**Setup date**: 2026-06-12

## Directory Layout

```
tests/
  unit/           # Isolated unit tests (formulas, state machines, logic)
  integration/    # Cross-system and save/load tests
  smoke/          # Critical path test list for /smoke-check gate
  evidencia/       # Screenshot logs and manual test sign-off records
  runners/        # Test runner scripts (entry point for CI)
  helpers/        # Shared test utilities (factory functions, mock-clock DI)
  README.md       # This file
```

## Running Tests

### Locally (developer machine)

```bash
# Run all GDScript unit tests via GUT (Godot CLI)
godot --headless --script tests/runners/gut_runner.gd

# Run all GDScript integration tests
godot --headless --script tests/runners/gut_integration_runner.gd

# Run all C# unit tests via NUnit (dotnet test)
dotnet test tests/unit-cs/

# Run all C# integration tests
dotnet test tests/integration-cs/

# Run smoke test list (critical paths only, ~15 min)
godot --headless --script tests/runners/smoke_runner.gd
```

### In CI

CI runs on every push to main (see `.github/workflows/tests.yml`):
1. Setup Godot 4.6.1 + dotnet
2. Run GUT tests
3. Run NUnit tests
4. Run smoke tests
5. Run static checks (linters from control-manifest)

## Test Naming

- **Files**: `[system]_[feature]_test.[ext]`
- **Functions**: `test_[scenario]_[expected]`
- **Examples**:
  - `tests/unit/combat/damage_bounds_test.gd` → `test_boss_one_shot_immunity_returns_one_hp()`
  - `tests/unit-cs/math/battle_math_lib_test.cs` → `TestCalcDamage_MinDamageRule_ReturnsTen()`
  - `tests/integration/save/load_roundtrip_test.gd` → `test_save_then_load_preserves_inventory()`

## Story Type → Test Evidence

| Story Type | Required Evidence | Location |
|---|---|---|
| Logic | Automated unit test — must pass | `tests/unit/[system]/` (GDScript) or `tests/unit-cs/[system]/` (C#) |
| Integration | Integration test OR playtest doc | `tests/integration/[system]/` (GDScript) or `tests/integration-cs/[system]/` (C#) |
| Visual/Feel | Screenshot + lead sign-off | `production/qa/evidencia/` |
| UI | Manual walkthrough OR interaction test | `production/qa/evidencia/` |
| Config/Data | Smoke check pass | `tests/smoke/` |

## Mock Clock / DI

Per `design/gdd/player-input.md` AC-9/10/15/20/21 (and ADR-0003 contract), InputBus exposes a settable `clock: Callable` field for test-time mock clocks. Tests inject a deterministic clock; production wires it to `Time.get_ticks_msec`.

Usage:
```gdscript
var fake_clock := func() -> float: return 1000.0
input_bus.set_clock(fake_clock)
# ... run test ...
```

## Coverage Targets

Per `technical-preferences.md`:

- **Combat math** (damage formula, crit, weakness): 70% minimum, target 90%
- **Weapon/ammo formulas** (build combinations): 70% minimum
- **Save/Load integrity** (round-trip): 100% (every producer tested)
- **State transitions** (4 phases, mode switch, encounter flow): 70% minimum

## Linter Integration (from control-manifest)

The following CI linters (defined in control-manifest § ADR rules) are run as part of the test pipeline:

- `tools/lint_autoload_order.py` — autoload order (ADR-0001)
- `tools/lint_action_count.py` — 47-action closed set (ADR-0009)
- `tools/lint_signal_naming.py` — `<past_tense>_<subject>` pattern (ADR-0002)
- `tools/lint_resource_subclasses.py` — every Resource extends `ImmutableResource` (ADR-0007)
- `tools/lint_npc_id_uniqueness.py` — NPCData ID uniqueness (ADR-0008)
- `tools/lint_boss_immunity.py` — every `boss=true` has `boss_immune_to_one_shot=true` (ADR-0011)
- `tools/sync_input_bindings.py` — generate `project.godot [input]` from YAML (ADR-0009)
- `tools/strip_debug_actions.py` — release build strips 4 Debug actions (ADR-0009)

A linter failure = CI failure = story not mergeable.

## Adding a New Test

1. Choose the right location:
   - Logic test → `tests/unit/[system]/[system]_[feature]_test.gd` (or `.cs`)
   - Integration test → `tests/integration/[system]/`
   - Smoke test → `tests/smoke/[system]_smoke_test.gd`
2. Follow the naming convention above
3. Add a doc comment explaining what the test asserts
4. Run tests locally before pushing
5. Reference the GDD section / ADR that mandates the behavior

## When Tests Fail

1. **Read the failure message** — GUT and NUnit both have good error messages
2. **Check if the test is asserting the contract** — if it's a behavior test, the implementation may be wrong
3. **Check if the test is stale** — the GDD may have been updated without the test
4. **Don't disable tests to make CI green** — fix the underlying issue
5. **If the test is wrong** — fix the test, document why
6. **If the implementation is wrong** — file a bug, fix it

## Test Framework Documentation

- GUT: https://github.com/bitwes/Gut
- NUnit: https://docs.nunit.org/
- Godot 4.6 test runner: see `tests/runners/gut_runner.gd`
