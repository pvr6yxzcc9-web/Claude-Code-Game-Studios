# Sat-3 蜂巢号 Enemy Resources (Sprint 8 Prep)

> **Created**: 2026-06-16
> **Purpose**: Pre-create Sat-3 enemy .tres resources so that Sprint 8 can focus on room design, boss fight, and dialogue instead of resource creation.

## Files

| File | Type | HP | Attack | Accuracy | Weakness | Resistance | Notes |
|------|------|----|----|----|----|----|----|
| `ch3_hive_guardian.tres` | Enemy (守卫) | 180 | 22 | 0.80 | fire | ice | Mid-tier basic enemy |
| `ch3_hive_cannon.tres` | Enemy (炮手) | 120 | 35 | 0.70 | fire | ice | Glass cannon (low HP, high damage) |
| `ch3_hive_parasite.tres` | Enemy (寄生) | 80 | 28 | 0.90 | fire | ice | High accuracy, low HP |
| `ch3_hive_mycelium.tres` | Enemy (菌丝) | 250 | 15 | 0.60 | fire | ice, kinetic | Tank (high HP, low damage) |
| `ch3_hive_larva.tres` | Enemy (幼虫) | 50 | 12 | 0.95 | fire | ice | Swarm enemy (low HP, high accuracy) |
| `ch3_hive_breeder.tres` | Enemy (繁殖体) | 220 | 25 | 0.75 | fire | ice | Spawns larvae (special ability) |
| `boss_hive_queen_guardian.tres` | Boss | 2400 | 35 | 0.85 | fire | ice | Ch9 boss |

## Schema Notes

These .tres use the **existing EnemyData schema** (`src/resource/enemy_data.gd`):
- `id` (StringName)
- `display_name` (String)
- `max_hp` (int, 10-500)
- `attack` (int, 1-100)
- `accuracy` (float, 0.0-1.0)
- `boss` (bool)
- `boss_immune_to_one_shot` (bool)
- `weaknesses` (Array[StringName])
- `resistances` (Array[StringName])

**Important**: The schema does NOT have an `element` field. The "element=hive" mentioned in S8-003 is implicitly encoded via the `weaknesses` and `resistances` arrays (all Sat-3 enemies are weak to fire, resistant to ice). If a future feature needs explicit element tracking, the schema will need to be extended.

## Auto-Loading

These .tres are auto-loaded by `ResourceRegistry` autoload. After the next game launch, these enemy IDs will be available via:
- `ResourceRegistry.get_resource(&"ch3_hive_guardian")`
- `ResourceRegistry.get_resource(&"boss_hive_queen_guardian")`
- etc.

## What This Does NOT Include

The following are **deferred** to Sprint 8 implementation:

- **Sprites** (`ch3_*.png` and `boss_hive_queen_guardian.png`) — the .tres files have no `sprite` field set, so the existing fallback (colored rectangle) will be used
- **Room placements** — which rooms these enemies appear in is part of `data/levels/chapters/chapter3.tres` (not yet written)
- **Boss fight script** — the "regenerate 5% HP per turn" special ability requires a separate script (per S8-005 in the sprint doc)
- **Drops** — the `drops` field is empty in these .tres; the bounty / boss weapon drops are separate (per S8-005)

## Why Element=hive Is Encoded as weakness/resistance

The original sprint-08 doc says "element=hive" for all 6 Sat-3 enemies, suggesting they share a common element type. Since the EnemyData schema doesn't have an `element` field, the most consistent way to represent "all hive enemies are weak to fire, resistant to ice" is to put `&"fire"` in `weaknesses` and `&"ice"` in `resistances` for every Sat-3 enemy.

When the BattleMathLib computes damage (per `party-system.md` §4 F4), it checks:
- If weapon's element is in enemy's `resistances` → damage × 0.5
- If weapon's element is in enemy's `weaknesses` → damage × 2.0
- Otherwise → damage × 1.0

So fire weapons deal 2x damage to all Sat-3 enemies, and ice weapons deal 0.5x. This is consistent with the "hive" theme: fire burns the hive, ice freezes it (which the hive resists).

## Next Steps (Sprint 8)

When Sprint 8 starts, the team will:
1. Generate enemy sprites (S8-004) — assign to the `sprite` field
2. Generate boss sprite (S8-006) — assign to boss
3. Generate tile assets (S8-001) and title background (S8-002)
4. Write room data files (S8-007) — which enemies appear in which rooms
5. Write boss fight script (S8-005) — implement 5% HP regen per turn
6. Write dialogue + fragment files (S8-008 + S8-011)
7. Add hallucination mechanic (S8-013) — visual decoy enemies

The .tres files in this directory are **complete data** and require no further edits for the enemy stats to be correct.
