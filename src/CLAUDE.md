# src/

**Engine**: Godot 4.6
**Language**: GDScript (gameplay/UI) + C# (performance-critical)
**Layer**: Implementation code (post-architecture, post-GDDs)

## Directory Layout

```
src/
  autoload/          # 5 autoloads (per ADR-0001)
    game_state_machine.gd
    input_bus.gd
    resource_registry.gd
    meta_state.gd
    save_manager.gd
  resource/          # 10 Resource subtypes (per ADR-0008)
    immutable_resource.gd
    weapon_data.gd
    ammo_data.gd
    enemy_data.gd
    mech_part_data.gd
    item_data.gd
    effect_data.gd
    terminal_log_data.gd
    story_fragment_data.gd
    region_data.gd
    npc_data.gd
  scene/             # Scene-tree nodes
    player_controller.gd
    encounter_tile.gd
    door.gd
    terminal.gd
    npc_controller.gd
  math/              # C# static math
    battle_math_lib.cs
  ui/                # HUD and UI scenes
    hud.tscn
    hud.gd
    ...
  main.tscn          # First scene
```

## Coding Standards (per technical-preferences.md)

- **GDScript files**: snake_case matching class, PascalCase class names
- **C# files**: PascalCase matching class, classes must be `partial`
- **GDScript signals**: snake_case past tense (`state_changed`, `damage_dealt`)
- **Constants**: UPPER_SNAKE_CASE (.gd) / PascalCase (.cs)
- **Comments**: doc comments on public APIs only

## Cross-References

- Architecture: `docs/architecture/architecture.md`
- ADRs: `docs/architecture/ADR-*.md`
- Control manifest: `docs/architecture/control-manifest.md`
- GDDs: `design/gdd/*.md`
- Tests: `tests/`
