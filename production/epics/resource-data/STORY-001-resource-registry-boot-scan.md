# STORY-001: ResourceRegistry autoload scans .tres on boot

> **Epic**: resource-data
> **Layer**: Foundation
> **TR**: TR-RES-001
> **Status**: Done (verified 2026-06-13 — `ResourceRegistry` autoload loads 14 resources at boot per F5 output)

## Acceptance Criteria

- [x] `ResourceRegistry` is autoload #3, loads after `GameStateMachine` and `InputBus`
- [x] On `_ready()`, recursively scans `res://data/**/*.tres` and indexes each by `id: StringName`
- [x] `get(id: StringName) -> Resource` returns the resource or null + `push_error`
- [x] Boot output shows `ResourceRegistry ready, N resources loaded`
- [x] Verified: F5 boot shows `14 resources loaded`

## Implementation

- `src/autoload/resource_registry.gd` — autoload, uses `ResourceLoader.load(path)` + `DirAccess.get_files_at()`
- `get_resource(id)` is the public API (renamed from `get` to avoid collision with Resource built-in)
- 14 fixture + data .tres files in `res://data/`

## Verification Evidence

- F5 boot log: `[ResourceRegistry] ready, 14 resources loaded`
- FC-1 smoke test passes 7/7
