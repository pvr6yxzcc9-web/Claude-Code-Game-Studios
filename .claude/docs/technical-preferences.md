# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.6
- **Language**: GDScript (gameplay/UI scripting), C# (performance-critical systems), C++ via GDExtension (native only)
- **Rendering**: Godot 4.6 2D renderer (Forward+ for any 3D test scenes)
- **Physics**: Godot 4.6 2D physics (Jolt is the default 3D physics in 4.6; not used in this project)

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: PC (Steam, Epic, itch.io)
- **Input Methods**: Keyboard/Mouse (primary), Gamepad (optional)
- **Primary Input**: Keyboard/Mouse
- **Gamepad Support**: Partial (recommended; not blocking for ship)
- **Touch Support**: None
- **Platform Notes**: Single-window desktop game. UI must be fully navigable with keyboard. Optional gamepad navigation support for menu/UI screens. No hover-only interactions.

## Naming Conventions

Mixed-language project (GDScript + C#). Use GDScript conventions for `.gd` files and C# conventions for `.cs` files. The boundary is per-file — do not mix languages within a single file. When in doubt about which language a new system should use, ask the user and record the decision below.

**GDScript (.gd files):**
- Classes: PascalCase (e.g., `PlayerController`)
- Variables/functions: snake_case (e.g., `move_speed`)
- Signals: snake_case past tense (e.g., `health_changed`)
- Files: snake_case matching class (e.g., `player_controller.gd`)
- Scenes: PascalCase matching root node (e.g., `PlayerController.tscn`)
- Constants: UPPER_SNAKE_CASE (e.g., `MAX_HEALTH`)

**C# (.cs files):**
- Classes: PascalCase (`PlayerController`) — must also be `partial`
- Public properties/fields: PascalCase (`MoveSpeed`, `JumpVelocity`)
- Private fields: `_camelCase` (`_currentHealth`, `_isGrounded`)
- Methods: PascalCase (`TakeDamage()`, `GetCurrentHealth()`)
- Signal delegates: PascalCase + `EventHandler` suffix (`HealthChangedEventHandler`)
- Files: PascalCase matching class (`PlayerController.cs`)
- Scenes: PascalCase matching root node (`PlayerController.tscn`)
- Constants: PascalCase (`MaxHealth`, `DefaultMoveSpeed`)

**Language assignment rule for this project:**
- Use **GDScript** by default for: gameplay scripts, UI scripts, scene controllers, prototype code
- Use **C#** for: performance-critical systems (combat math, procedural generation, large data sets), and where stronger IDE tooling (Rider/VS) helps
- Use **GDExtension (C++)** for: only when a bottleneck cannot be solved in C#

## Performance Budgets

- **Target Framerate**: 60 FPS
- **Frame Budget**: 16.6 ms
- **Draw Calls**: ~200 per scene (well under Godot 2D's practical limit)
- **Memory Ceiling**: 500 MB (desktop target is comfortable; do not exceed 1 GB)

## Testing

- **Framework**: GUT (Godot Unit Test) for GDScript; NUnit for C#
- **Minimum Coverage**: 70% for combat math, weapon/ammo formulas, build/equipment systems
- **Required Tests**:
  - Balance formulas (damage, crit, ammo effects)
  - Combat systems (turn order, status effects, manual/auto mode logic)
  - Map/encounter generation (if any)
  - Save/load integrity

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- [None configured yet — add as architectural decisions are made]

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here. Do NOT add speculatively. -->
- GUT (Godot Unit Test, https://github.com/bitwes/Gut) — testing framework for GDScript

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]

## Engine Specialists

<!-- Written by /setup-engine when engine is configured. -->
<!-- Read by /code-review, /architecture-decision, /architecture-review, and team skills -->
<!-- to know which specialist to spawn for engine-specific validation. -->

- **Primary**: godot-specialist
- **GDScript Specialist**: godot-gdscript-specialist (.gd files — gameplay/UI scripts)
- **C# Specialist**: godot-csharp-specialist (.cs files — performance-critical systems)
- **Shader Specialist**: godot-shader-specialist (.gdshader files, VisualShader resources)
- **UI Specialist**: godot-specialist (no dedicated UI specialist — primary covers all UI)
- **Additional Specialists**: godot-gdextension-specialist (GDExtension / native C++ bindings only)
- **Routing Notes**: Invoke primary for cross-language architecture decisions and which systems belong in which language. Invoke GDScript specialist for .gd files. Invoke C# specialist for .cs files and .csproj management. Prefer signals over direct cross-language method calls at the boundary.

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->
<!-- If a row says [TO BE CONFIGURED], fall back to Primary for that file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.gd files) | godot-gdscript-specialist |
| Game code (.cs files) | godot-csharp-specialist |
| Cross-language boundary decisions | godot-specialist |
| Shader / material files (.gdshader, VisualShader) | godot-shader-specialist |
| UI / screen files (Control nodes, CanvasLayer) | godot-specialist |
| Scene / prefab / level files (.tscn, .tres) | godot-specialist |
| Project config (.csproj, NuGet) | godot-csharp-specialist |
| Native extension / plugin files (.gdextension, C++) | godot-gdextension-specialist |
| General architecture review | godot-specialist |
