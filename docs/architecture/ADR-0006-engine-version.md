# ADR-0006: Engine Version Pin (Godot 4.6.x)

## Status

Accepted

## Date

2026-06-12

## Last Verified

2026-06-12

## Decision Makers

User + technical-director (self-review)

## Summary

Railhunter pins to **Godot 4.6.x** (latest stable as of January 2026). Any engine upgrade requires (1) a fresh `/architecture-review` pass, (2) an `ADR-ENGINE-VERSION` bump + migration notes, (3) integration tests run on all 5 reference platforms (Windows, macOS, Linux, ideally Steam Deck). Minor version upgrades (4.6.0 → 4.6.1) are auto-approved; major/minor upgrades (4.6 → 4.7) require a full review. This codifies the engine version policy already in `CLAUDE.md` and `technical-preferences.md`.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 (latest stable) |
| **Domain** | Core (engine selection + upgrade policy) |
| **Knowledge Risk** | HIGH — 4.6 is post-LLM-cutoff (May 2025). LLM does not fully know 4.6 APIs |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md`, `docs/engine-reference/godot/modules/*.md` |
| **Post-Cutoff APIs Used** | Many — see architecture §2 (6 HIGH RISK domains flagged) |
| **Verification Required** | All HIGH RISK APIs verified at first use site. Re-verified on engine upgrade. |

> **Note**: Knowledge Risk is HIGH because the LLM training data predates Godot 4.4. The 4.5+ changes (SDL3 backend, `@abstract`, Jolt physics default) and 4.6 changes (D3D12 default on Windows, glow rework, IK restored) are not in training. **Every API call must be verified against `docs/engine-reference/godot/` before use.**

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None (this is the engine selection ADR — informs all others) |
| **Enables** | All other ADRs (they all reference Godot 4.6 APIs) |
| **Blocks** | Any implementation that uses Godot APIs (i.e., everything) |
| **Ordering Note** | Sixth ADR but referenced by ADR-0001, 0002, 0003, etc. Effectively the root ADR for engine compatibility |

## Context

### Problem Statement

Godot 4.x has had 4 minor versions (4.0, 4.1, 4.2, 4.3, 4.4, 4.5, 4.6) and patch versions in 18 months. Each minor version can introduce:
- API changes (renames, signatures)
- New defaults (e.g., 4.6: Jolt default, D3D12 default on Windows)
- Deprecated APIs
- Behavior changes (e.g., 4.5: SDL3 gamepad backend)

If Railhunter silently uses a Godot 4.4 API, then upgrades to 4.6:
- Build might fail (deprecated API removed)
- Game might crash (signature change)
- Game might silently misbehave (e.g., D3D12 vs OpenGL rendering)

The fix is a **version pin + upgrade policy**: pin to a specific version, with a strict process for upgrading.

### Current State

- `CLAUDE.md` declares: `Engine: Godot 4.6`
- `technical-preferences.md` declares: `Engine: Godot 4.6`
- `docs/engine-reference/godot/VERSION.md` declares: `Godot 4.6 / January 2026 / HIGH RISK version`
- Architecture §2 (Engine Knowledge Gap Summary) lists 6 HIGH RISK domains
- But no ADR defines the **upgrade policy**: when to bump, what to verify, what process to follow

### Constraints

- **Solo dev** — must be able to do this in 1-2 hours, not 1 day
- **Single-player** — no engine multiplayer upgrade to coordinate
- **MVP scope** — only need to support 4.6 → 4.7 → 4.8, not 5.0
- **Existing 4.6 project** — not greenfield migration

### Requirements

- **Pinned to 4.6.x** — `project.godot` uses 4.6.x features
- **Auto-approve patch upgrades** (4.6.0 → 4.6.1) — no ADR bump, just verify CI passes
- **Manual approve minor upgrades** (4.6 → 4.7) — ADR bump, full review, integration tests
- **Manual approve major upgrades** (4.x → 5.x) — ADR bump, full review, possible rewrite
- **HIGH RISK APIs flagged** — every ADR that uses a post-cutoff API must mark it
- **Re-validation on upgrade** — `/architecture-review` must pass on the new version

## Decision

### Architecture

```
Engine version policy:

Version pin (project.godot):
  config/features=PackedStringArray("4.6", "Forward Plus")
  # No specific patch version pin (Godot doesn't support that)

CI / build matrix:
  - Godot 4.6.1-stable (latest patch) on Windows + macOS + Linux
  - Optional: Steam Deck (Linux ARM64) — verify later

Upgrade policy:

  Patch (4.6.0 → 4.6.1):
    - Auto-approve
    - Verify CI passes
    - No ADR bump
    - Re-run /architecture-review (1-2 hours)
    - Update docs/engine-reference/godot/VERSION.md

  Minor (4.6 → 4.7):
    - Manual approve
    - Bump SAVE_VERSION_CURRENT? (no — engine change, not data change)
    - Bump ADR-ENGINE-VERSION to "v2" with migration notes
    - Re-run /architecture-review
    - All HIGH RISK APIs in all ADRs re-verify at first use site
    - Full integration test pass on all platforms

  Major (4.x → 5.x):
    - Major refactor
    - Bump ADR-ENGINE-VERSION to "vN"
    - Re-run /architecture-review
    - Likely rewrite some systems (e.g., C# GDExtension may change)
    - Not in MVP scope (Godot 5.0 doesn't exist yet as of 2026-01)
```

### Key Interfaces

```gdscript
# === Engine version assertion ===
# File: src/autoload/engine_version_checker.gd
class_name EngineVersionChecker
extends Node

const REQUIRED_VERSION: String = "4.6"

func _ready() -> void:
    var actual: String = Engine.get_version_info().get("string", "unknown")
    var actual_major_minor: String = "%s.%s" % [
        Engine.get_version_info().get("major", 0),
        Engine.get_version_info().get("minor", 0),
    ]
    
    if actual_major_minor != REQUIRED_VERSION:
        push_error("Railhunter requires Godot %s, found %s" % [REQUIRED_VERSION, actual])
        get_tree().quit(1)
    
    # Patch version is allowed to differ
    print("[EngineVersionChecker] Godot %s OK" % actual)


# === project.godot entry (informational, not enforced by Godot) ===
# config/features=PackedStringArray("4.6", "Forward Plus")
# config/name="Railhunter"
# config/description="..."
# 
# This tells Godot "use 4.6 features" — if you open in 4.5, you get a warning


# === Engine upgrade PR template ===
# File: .github/PULL_REQUEST_TEMPLATE/engine-upgrade.md
# 
# ## Engine Upgrade: X.Y → A.B
# 
# ### Engine changes reviewed
# - [ ] breaking-changes.md reviewed for new APIs
# - [ ] All HIGH RISK APIs re-verified at first use site
# - [ ] docs/engine-reference/godot/VERSION.md updated
# 
# ### ADRs affected
# - [ ] /architecture-review re-run
# - [ ] All ADRs that flag HIGH RISK APIs reviewed
# 
# ### Tests
# - [ ] All unit tests pass
# - [ ] All integration tests pass
# - [ ] Manual smoke test on all 5 reference platforms
# 
# ### Rollback plan
# - [ ] git revert <this-PR-sha>
# - [ ] engine-version pin restored
# - [ ] CI matrix re-runs on previous version
```

### Implementation Guidelines

#### Where to pin the version

- `project.godot`: `config/features=PackedStringArray("4.6", "Forward Plus")` — informational
- `src/autoload/engine_version_checker.gd`: runtime assertion (per code above)
- `docs/engine-reference/godot/VERSION.md`: human-readable doc (already exists)
- `.github/workflows/build.yml`: CI matrix (the actual enforcement)

#### What goes in the CI build matrix

```yaml
# .github/workflows/build.yml (excerpt)
jobs:
  test:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
        godot_version: ["4.6.1-stable"]  # current pin
    steps:
      - uses: chickensoft-games/setup-godot@v2
        with:
          version: ${{ matrix.godot_version }}
      - run: godot --headless --check-only  # import + parse check
      - run: godot --headless --script tests/runner.gd  # run tests
```

#### When to use a different Godot version

| Scenario | Decision |
|----------|----------|
| Patch upgrade available (4.6.0 → 4.6.1) | Auto-apply, re-run CI |
| Minor upgrade available (4.6 → 4.7) | Manual decision: read 4.7 release notes, decide if benefits outweigh risk |
| Major upgrade (4.x → 5.x) | Defer; only consider if Godot 5 ships in 2026-2027 |
| Stuck on old version (e.g., 4.5) | Backport security fixes only; no upgrades for new features |

#### How to update docs/engine-reference/godot/

1. WebSearch: `"Godot 4.6.2 release notes"`, `"Godot 4.6 migration guide"`, etc.
2. Read official migration guide (linked from `breaking-changes.md`)
3. Add new entries to `docs/engine-reference/godot/breaking-changes.md`
4. Add new APIs to relevant `modules/*.md` files
5. Mark HIGH RISK APIs that are post-cutoff

#### HIGH RISK API flagging

Every ADR that uses a Godot 4.4+ API must:
1. Mark the API as "HIGH RISK" in the "Engine Compatibility" section
2. Reference `docs/engine-reference/godot/breaking-changes.md`
3. Note "Post-Cutoff APIs Used" with specific APIs
4. Specify "Verification Required" with concrete test behavior

The architecture §2 already flags 6 HIGH RISK domains:
1. **Jolt physics** (4.6 default; new API in 4.5+)
2. **D3D12 on Windows** (4.6 default; potential driver issues)
3. **SDL3 gamepad backend** (4.5; affects hot-swap behavior)
4. **`@abstract` for Resource** (4.5; affects Resource._set() override)
5. **Glow rework** (4.6; rendering changes)
6. **IK restored** (4.6; affects animation)

#### Upgrade process checklist (minor version)

1. **Read release notes** — what changed?
2. **Run `/architecture-review`** with new engine version
3. **For each HIGH RISK API**:
   - Find first use site
   - Write integration test
   - Verify behavior matches expected
4. **Update `docs/engine-reference/godot/VERSION.md`** with new version + risk assessment
5. **Update CI matrix** to new version
6. **Run full CI** on all 5 reference platforms
7. **Manual smoke test** — play 30 min on each platform
8. **Bump this ADR** to "v2" with migration notes
9. **Update `CLAUDE.md`** with new version
10. **Tag release** as "engine-upgrade-X.Y"

#### Why 4.6.x not 4.6.0 specifically

- Godot's `config/features` only specifies major.minor, not patch
- Patch upgrades are auto-approved and require no ADR bump
- 4.6.0, 4.6.1, 4.6.2 are all "4.6" — they fix bugs but don't change APIs

#### Compatibility matrix

| Godot | Status | Notes |
|-------|--------|-------|
| 4.5 | ❌ Not supported | Pre-pinned baseline |
| 4.6.0 | ✅ Supported | Current pin (Jan 2026) |
| 4.6.1 | ✅ Supported | Auto-apply when available |
| 4.7 | ❌ Not yet | Requires ADR bump |
| 5.x | ❌ Not yet | Future consideration |

## Alternatives Considered

### Alternative 1: Always latest Godot (no pin)

- **Description**: Use `master` branch of Godot, get all new features immediately
- **Pros**: New features as they ship
- **Cons**: Unstable; breaking changes mid-development
- **Estimated Effort**: -50% setup, +300% debugging
- **Rejection Reason**: Solo dev cannot afford instability. Pin to stable.

### Alternative 2: Pin to 4.5 (older stable)

- **Description**: Use 4.5 (slightly older) for stability
- **Pros**: More mature, more LLM knowledge
- **Cons**: Missing 4.6 features (Jolt default, D3D12 default)
- **Estimated Effort**: Same
- **Rejection Reason**: 4.6 is current stable. 4.5 would force backporting fixes.

### Alternative 3: Pin to LTS (long-term-support) release

- **Description**: Wait for Godot to declare a version LTS
- **Pros**: Stability commitment
- **Cons**: Godot doesn't have an LTS program (as of 2026-01); can't predict when they will
- **Estimated Effort**: Same
- **Rejection Reason**: No LTS exists. Pin to latest stable.

### Alternative 4: Use both 4.6 and 4.5 (compatibility matrix)

- **Description**: Support both versions
- **Pros**: Smoother upgrade path
- **Cons**: Double testing burden; #ifdef hell
- **Estimated Effort**: +100% testing, -50% feature velocity
- **Rejection Reason**: Solo dev can't afford double testing. Pin to one.

## Consequences

### Positive

- **Stable** — no surprise breaking changes mid-development
- **Documented** — engine compatibility is a first-class concern in every ADR
- **Testable** — `/architecture-review` re-validates on every upgrade
- **Solo-friendly** — solo dev can manage with clear policy

### Negative

- **Slow to adopt new features** — must wait for full review on minor upgrade
- **HIGH RISK APIs require discipline** — every use site needs verification
- **Solo dev bottleneck** — solo dev is the only one who can approve upgrade
- **Documentation burden** — must keep `docs/engine-reference/godot/` up to date

### Neutral

- Godot 4.6 is current as of 2026-01; future versions (4.7+) not considered
- Godot 5.0 not expected before 2027-2028 (conservative estimate)
- We don't track Godot's "beta" releases; only stable

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Godot releases 4.7 with breaking changes that affect us | Medium | High | Per upgrade checklist: read release notes, decide, run review |
| 4.6.x patch breaks our project (regression) | Low | Medium | CI runs on every commit; smoke test before release |
| 4.6 feature we depend on is removed in 4.7 | Low | High | Pin to 4.6; if removed, we can pin indefinitely or rewrite |
| Godot project becomes unmaintained | Very Low | High | Switch engines (out of MVP scope; not relevant 2026-2028) |
| 4.7 has security fix we miss | Low | Low | Quarterly review of 4.7 release notes; manual decision |
| LLM training data stays stale | High (over time) | Medium | Continue updating `docs/engine-reference/godot/` on every upgrade |
| Engine upgrade breaks save format | Low | High | Save format is engine-agnostic (JSON, no Godot-specific binary); ADR-0005 covers data version |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| Engine startup time | 4.6 baseline | 4.6.1 baseline (faster boot in 4.6.1) | <5s |
| Memory overhead | 4.6 baseline | 4.6.1 baseline | <500MB |
| Compile time | 4.6 baseline | 4.6.1 baseline | <30s |
| Engine version check (boot) | N/A | <1ms | <10ms |

## Migration Plan

N/A — this is the initial pin. Migration to a new version follows the upgrade checklist in the Implementation Guidelines.

**Rollback plan**: If a 4.6.x patch breaks us:
1. Revert `project.godot` to previous patch version (if committed) OR
2. Reinstall Godot at previous patch version (CI re-runs with previous version)
3. No code changes required (patch is supposed to be backwards-compatible)

If a 4.6 → 4.7 upgrade breaks us:
1. Stay on 4.6 indefinitely (we own the pin, not Godot)
2. Open an issue with Godot to fix the regression
3. Re-attempt upgrade in next minor release

## Validation Criteria

- [ ] **First build test**: project opens in Godot 4.6.1 without warnings
- [ ] **First import test**: `godot --headless --import` succeeds
- [ ] **First run test**: `godot --headless --quit-after 5` exits 0
- [ ] **Version check test**: `engine_version_checker._ready()` logs "Godot 4.6 OK"
- [ ] **Wrong version test**: simulate Godot 4.5 → `EngineVersionChecker` push_error + `quit(1)`
- [ ] **CI matrix test**: build passes on Windows + macOS + Linux
- [ ] **Smoke test**: 30-min playtest on each platform, no crashes
- [ ] **HIGH RISK API test**: each of the 6 HIGH RISK domains has at least one integration test

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `CLAUDE.md` | Project | "Engine: Godot 4.6" | Codifies version pin + upgrade policy |
| `.claude/docs/technical-preferences.md` | Project | "Engine: Godot 4.6 / HIGH RISK version" | Codifies HIGH RISK domains and verification policy |
| `docs/engine-reference/godot/VERSION.md` | Engine | "HIGH RISK version (4.4-4.6 post-cutoff)" | Codifies post-cutoff API verification policy |
| (Architecture §2) | All | "Engine Knowledge Gap Summary" | Codifies 6 HIGH RISK domains |
| (All ADRs) | All | "Engine Compatibility" table | Defines the schema: Engine / Domain / Risk / Verification |

> Foundational — this ADR codifies the *policy* for engine compatibility that all other ADRs reference.

## Related

- **Referenced by**:
  - ADR-0001 (autoload order assumes Godot 4.6 Project > Autoload)
  - ADR-0002 (signals assume Godot 4.6 signal semantics)
  - ADR-0003 (Dictionary / Variant / FileAccess assume 4.6)
  - ADR-0004 (WorkerThreadPool + FileAccess.store_string return bool — 4.4+ change)
  - ADR-0007 (Resource._set() — needs 4.6 verification due to @abstract)
  - ADR-0009 (Input binding — SDL3 gamepad backend is 4.5+)
  - ADR-0010 (TileMapLayer — replaces deprecated TileMap since 4.3)
- **Depends on**: None (root ADR)
- **Code locations** (when implemented):
  - `src/autoload/engine_version_checker.gd` (runtime assertion)
  - `project.godot` (config/features)
  - `.github/workflows/build.yml` (CI matrix)
  - `docs/engine-reference/godot/VERSION.md` (human-readable)
  - `.github/PULL_REQUEST_TEMPLATE/engine-upgrade.md` (PR template)
