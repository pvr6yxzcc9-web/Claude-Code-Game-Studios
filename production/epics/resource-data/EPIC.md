# Epic: Resource / Data System

> **Layer**: Foundation
> **GDD**: design/gdd/resource-data.md (Approved)
> **Architecture Module**: `ResourceRegistry` (autoload) + 10 Resource subtypes (`.tres` instances)
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories resource-data`

## Overview

Define the data layer that every other system reads from. `ResourceRegistry` is a Foundation autoload that scans `res://data/**/*.tres` at boot, indexes every Resource by its `id: StringName`, and exposes `get(id) -> Resource` / `get_all_of_type(type) -> Array` to all consumers. Ten Resource subtypes (WeaponData, AmmoData, EnemyData, MechPartData, ItemData, EffectData, TerminalLogData, StoryFragmentData, RegionData, NPCData) provide a single, immutable, data-driven schema for all gameplay content. Every balance value, weapon stat, enemy ability, and NPC line lives in a `.tres` file — never hardcoded in scripts. All Resource instances are **immutable at runtime** (enforced by `ImmutableResource._set()`) to prevent accidental in-memory mutation that would break save/load round-trips.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|------------|
| ADR-0007: Resource Immutability | `_set()` override blocks all writes after resource load; runtime mutation forbidden | LOW |
| ADR-0008: Resource Schema (NPCData) | 10th Resource subtype (NPCData) added in same pass; same `ImmutableResource` base | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-RES-001 | `ResourceRegistry` autoload scans `res://data/` recursively and indexes by `id` | ADR-0007 ✅ |
| TR-RES-002 | 10 Resource subtypes, all extending `ImmutableResource` | ADR-0007, ADR-0008 ✅ |
| TR-RES-003 | Immutability: runtime writes raise error and are dropped | ADR-0007 ✅ |
| TR-RES-004 | All gameplay values (damage, HP, crit) live in `.tres`, not scripts | ADR-0007 ✅ |
| TR-RES-005 | `get(id)` returns null on miss + push_error (no silent failure) | ADR-0007 ✅ |
| TR-RES-006 | `NPCData` exposes dialogue tree + fragment output interface | ADR-0008 ✅ |

## Definition of Done

- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/resource-data.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories resource-data` to break this epic into implementable stories.
