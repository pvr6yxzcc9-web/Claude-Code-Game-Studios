# Railhunter (钢轨猎人)

> **Status (2026-06-14)**: Vertical slice ship-ready. Boss fight winnable, ending UI works, full F5 walkthrough passes.

A turn-based 2D pixel-art sci-fi RPG built in **Godot 4.6** (C# + GDScript hybrid).
You pilot a mech through the wreckage of a convoy, fighting scavengers, discovering fragments of what happened, and choosing what to remember.

> **Engine**: Godot 4.6.3 stable.mono
> **Language**: GDScript (gameplay/UI) + C# reserved for performance-critical paths
> **Test framework**: GUT (Godot Unit Test) + 11 Python lint tools
> **Save format**: JSON in `user://save_<slot>.json`
> **Platform**: PC (Steam, Epic, itch.io)

---

## How to Run

### From Godot Editor
1. Open the project in Godot 4.6.3+
2. Make sure the GUT plugin is enabled (Project > Project Settings > Plugins)
3. Press **F5** to play

### From CLI (headless)
```bash
# Export release build (requires Godot export templates + export_presets.cfg)
./tools/build.sh linux        # build/railhunter.x86_64
./tools/build.sh windows      # build/railhunter.exe
./tools/build.sh debug linux  # build/railhunter-debug.x86_64
```

### From CLI (tests)
```bash
# All CI lints (10 hard-fail + 1 backlog)
for f in tools/lint_*.py tools/sync_*.py; do python "$f"; done

# GUT unit tests
godot --headless --script tests/runners/gut_runner.gd
```

---

## What Works (Vertical Slice Scope)

| Feature | Status | Source |
|---------|--------|--------|
| 10-room chapter 1 (room 0-9, 9 doors) | ✅ | `src/scene/level_runtime.gd` |
| Turn-based combat (manual + auto modes) | ✅ | `src/battle/battle_scene.gd` |
| 1 boss fight (Marrow Sentinel, 200HP, balanced for 100HP player) | ✅ | `data/enemies/boss_marrow_sentinel.tres` |
| Weapon / Ammo build system (8 weapons, 5 ammo) | ✅ | `data/weapons/`, `data/ammo/` |
| Mech parts (2 arms) | ✅ | `data/mech/`, `src/autoload/mech_loadout.gd` |
| Story fragments (7 total: 4 auto + 3 boss-victory) | ✅ | `data/fragments/` |
| 3 endings (A=revelation, B=partial, C=default) | ✅ | `data/npcs/dlg_ending_*.tres` |
| Save / Load (autosave 60s + manual 3 slots) | ✅ | `src/autoload/save_manager.gd` |
| Pause menu, Codex, HUD, dialogue UI | ✅ | `src/ui/` |
| Breakable wall (hidden area in room 4) | ✅ | `src/scene/breakable_wall.gd` |
| 3 NPCs + 3 dialogue trees | ✅ | `data/npcs/`, `data/dialogue_trees/` |

## What's a Placeholder (Art / Audio)

| Item | Current | TODO |
|------|---------|------|
| All visuals | ColorRect placeholders | Pixel art pass |
| SFX | Procedural sine-wave beeps | Real sound design |
| Music | None | OST |
| Boss sprite | 200x200 ColorRect | Pixel art |

---

## Architecture Quick Reference

- **5 autoloads** (ADR-0001): `GameStateMachine → InputBus → ResourceRegistry → MetaState → SaveManager`
- **10 Resource subtypes** (ADR-0008): WeaponData, AmmoData, EnemyData, MechPartData, ItemData, EffectData, TerminalLogData, StoryFragmentData, RegionData, NPCData
- **52 input actions** (ADR-0009 + S5-008): closed set, YAML is source-of-truth
- **BattleMathLib** (`src/math/`): pure GDScript static utility for damage math (canonical range [10, 480] per ADR-0011)
- **State machine** has 8 states: title, exploration, battle, menu, terminal, codex, dialogue, pause

See `docs/architecture/architecture.md` for the full architecture document and
`docs/architecture/ADR-*.md` for the 11 architecture decision records.

## Project Structure

```
src/
  autoload/      5 autoloads (game_state_machine, input_bus, ...)
  resource/      10 Resource subtypes (weapon_data, ammo_data, ...)
  scene/         Scene-tree nodes (player, terminal, door, breakable_wall, ...)
  ui/            UI scenes (hud, main_menu, pause_menu, codex_ui, ...)
  math/          BattleMathLib (pure functions)
data/
  weapons/       8 WeaponData .tres
  ammo/          5 AmmoData .tres
  enemies/       7 EnemyData .tres (1 boss + 6 normal)
  fragments/     7 StoryFragmentData .tres
  npcs/          3 NPCData + dialogue trees
  mech/          2 MechPartData .tres
tests/
  integration/   35 GUT test scripts (fc1-fc36)
  unit/          GDScript unit tests
tools/
  lint_*.py      11 Python lint tools (CI hard-fail)
  build.sh       Release export pipeline
  check_uid.py   .gd/.uid pair verification
docs/
  architecture/  ADRs + master architecture doc + traceability
  engine-reference/  Godot 4.6 API snapshots
production/
  sprints/       Sprint plans + close reports (sprint-01 through sprint-05)
  qa/evidence/   F5 verification logs
  epics/         Foundation + Core epics
```

---

## Recent Work (Sprint 5 + post-sprint F5 verification)

Sprint 5 produced a 9/9 Must-Have pass. A subsequent **full F5 walkthrough** by
the user revealed 14 real runtime bugs that the GUT test suite + static lints
did not catch. All 14 are now fixed. **4 new lints** prevent regression of 4
of the 14 bug classes.

See `production/qa/evidence/post-sprint5-f5-verification.md` for the full bug
list, lessons learned, and the 5 F5 sessions that surfaced them.

### Bugs caught by F5 (14 total)
- `Object.get()` 2-arg parser error (4.6 strictness)
- Typed array invariance on Area2D results
- Exploration-mode attack not emitted
- Terminal UI not transitioning to state_terminal
- Dead UI affordance ("ESC to close" with no handler)
- Boss encounter always spawning Scavenger (not boss)
- Duplicate `var bs` declaration
- Boss attack 35 = impossible difficulty
- fc25 test 2-arg `.get()` parser error
- fc8 test undefined `_level_runtime`
- FSM rejects `state_battle → state_dialogue` (blocking boss endings)
- Ending dialogue auto-ends with 0 choices (0 frames visible)
- 0-choice dialogue has no close handler
- HUD `has_method()` checks var (always false, label never updates)

### Lints added
1. `lint_object_get.py` — `Object.get()` 2-arg catch
2. `lint_typed_array_inference.py` — typed array invariance
3. `lint_has_method_var.py` — `has_method()` for var-named properties
4. `lint_boss_immunity.py` — ADR-0011 boss immunity + damage bounds

---

## Next Steps (Sprint 6 candidates)

- **Pixel art pass** — replace ColorRect placeholders with real sprites
- **Real SFX + music** — replace procedural beeps
- **Full F5 sweep per sprint** (added to sprint close template)
- **Balance check** via `/balance-check` skill after any combat change
- **Build end-to-end** on CI runner (Godot 4.6.1 + export templates)
- **Steam page + marketing trailer**
- **Tutorial overlay** for first-time players
- **Chapter 2** (new biome, more enemies, more endings)

---

## License

MIT. See `LICENSE`.
