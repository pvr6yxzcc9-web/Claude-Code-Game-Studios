# STORY-002: ImmutableResource blocks runtime writes

> **Epic**: resource-data
> **Layer**: Foundation
> **TR**: TR-RES-002, TR-RES-003
> **Status**: Done (verified 2026-06-13 — `_set()` override raises error on writes)

## Acceptance Criteria

- [x] `ImmutableResource` base class overrides `_set()` to block all property writes after load
- [x] All 10 Resource subtypes extend `ImmutableResource`
- [x] Runtime attempts to set a property raise error (and are dropped)
- [x] Initial loads (via `ResourceLoader.load`) work normally

## Implementation

- `src/resource/immutable_resource.gd` — base class with `_set()` override
- 10 subtypes: `weapon_data.gd`, `ammo_data.gd`, `enemy_data.gd`, `mech_part_data.gd`, `item_data.gd`, `effect_data.gd`, `terminal_log_data.gd`, `story_fragment_data.gd`, `region_data.gd`, `npc_data.gd`

## Verification Evidence

- ADR-0007 specifies the immutability pattern
- F5 boot succeeds; no error in console
- Save/load round-trip preserves resource state
