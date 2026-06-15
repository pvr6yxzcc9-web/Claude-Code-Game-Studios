# Entity Inventory

> **Status**: Draft v0.1 (2026-06-13)
> **Author**: lead-programmer (lightweight version)
> **Purpose**: Track all game-world content IDs that exist as `.tres` resources
> **Source of truth**: `res://data/**/*.tres` + `design/registry/entities.yaml`

This is a lightweight inventory of all in-game entities (weapons, ammo, enemies, mech parts, NPCs, fragments, levels). The canonical cross-system facts are in `design/registry/entities.yaml`. This file's purpose is to list the **physical content that exists right now** so QA and asset teams know what to test against.

## Weapons (3)

| ID | File | Type | Notes |
|---|---|---|---|
| `blaster_rifle` | `data/weapons/blaster_rifle.tres` | Ranged | Default loadout (slot 0) |
| `shotgun` | `data/weapons/shotgun.tres` | Ranged spread | |
| `sniper_rifle` | `data/weapons/sniper_rifle.tres` | Ranged high-damage | |

## Ammo (3)

| ID | File | Type | Effect |
|---|---|---|---|
| `basic_cell` | `data/ammo/basic_cell.tres` | Standard | 1.0x damage mult |
| `acid_round` | `data/ammo/acid_round.tres` | Damage over time | Applies poison |
| `emp_charge` | `data/ammo/emp_charge.tres` | Disable | Stuns enemies |

## Enemies (2)

| ID | File | Boss | Notes |
|---|---|---|---|
| `scavenger` | `data/enemies/scavenger.tres` | No | Default battle enemy |
| `boss_marrow_sentinel` | `data/enemies/boss_marrow_sentinel.tres` | Yes (immune to one-shot) | Room 9 boss |

## Mech Parts (1)

| ID | File | Slot | Notes |
|---|---|---|---|
| `starter_torso` | `data/mech/starter_torso.tres` | Torso | Default mech part (1/5) |

## NPCs (2)

| ID | File | Type | Notes |
|---|---|---|---|
| `vera_merchant` | `data/npcs/vera_merchant.tres` | Merchant | First NPC |
| `dlg_vera_greeting` | `data/npcs/dlg_vera_greeting.tres` | Dialogue line | Vera's first dialogue |

## Story Fragments (2)

| ID | File | Type |
|---|---|---|
| `log_scrapyard_intro` | `data/fragments/log_scrapyard_intro.tres` | Terminal log |
| `fragment_who_we_were` | `data/fragments/fragment_who_we_were.tres` | Story fragment |

## Levels (1)

| ID | File | Rooms | Notes |
|---|---|---|---|
| `chapter1` | `data/levels/chapter1.tres` | 10 | First chapter (Scrapyard) |

## Total: 14 resources registered

(Confirmed via F5 boot: `[ResourceRegistry] ready, 14 resources loaded`)

## Gaps to Fill (Sprint 1 Should-Have)

- **Weapons**: Currently 3. Need at least 6 for variety. Add: `plasma_cannon`, `railgun`, `flamethrower`.
- **Ammo**: Currently 3. Need 6+. Add: `plasma_cell`, `incendiary_round`, `cryo_round`.
- **Enemies**: Currently 2. Need 6+ for encounter variety. Add: `drone_scout`, `heavy_walker`, `sniper_bot`.
- **Bosses**: Only 1. Need 1 more per chapter (3 total for chapter 1).
- **Mech parts**: Only 1 of 5 slots filled. Add: starter head, arms, legs.
- **NPCs**: Only Vera. Add 2-3 more (informant, repair tech, hidden contact).
- **Fragments**: Only 2. Need 12 per chapter for full story map.
- **Levels**: Only chapter 1. Need chapters 2 and 3 (full game).

## Test Coverage

- All 14 resources are loaded by `ResourceRegistry` at boot
- `get_resource(id)` returns the resource for each of the 14 IDs
- FC-1..FC-11 tests cover resource lookup, immutability, and gameplay integration
