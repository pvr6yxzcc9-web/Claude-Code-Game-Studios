# Sat-3 蜂巢号 Level (Sprint 8 Prep)

> **Created**: 2026-06-16
> **Purpose**: Document the chapter3.tres level header + explain why the 10 individual rooms are NOT pre-created yet.

## Files

- `chapter3.tres` — Level data header (10 rooms, boss, encounter rate, description)

## Why No Individual Room .tres Files

The current `LevelData` schema (in `src/resource/level_data.gd`) only contains:
- `id`, `display_name`, `chapter_index`
- `room_ids: Array[StringName]` (just IDs, no content)
- `boss_id`
- `encounter_rate`
- `description`

The **actual room content** (encounter placement, NPC placement, terminal placement, tile layout) is **hardcoded in `src/scene/level_runtime.gd`** (636 lines). This is a known technical debt that the team has accepted in the early game design (per `level-dungeon.md` GDD).

When Sprint 8 actually implements S8-007 (10 rooms, 3 days), the implementation will:
1. Extend `LevelData` schema with per-room content (or use a separate `RoomData` resource)
2. OR add Sat-3's 10 rooms to `level_runtime.gd` (alongside Ch1/Ch2)
3. Then write `chapter3.tres` to reference those rooms

This is **3 days of level designer work** that doesn't benefit from being done in advance. Pre-creating `chapter3.tres` only saves the trivial header (the file above).

## What chapter3.tres Provides

- **chapter_index = 3**: identifies this as the 3rd chapter
- **10 room_ids (c3_r1 to c3_r10)**: room placeholders
- **boss_id = boss_hive_queen_guardian**: the boss enemy ID (created in the previous commit, see `data/enemies/boss_hive_queen_guardian.tres`)
- **encounter_rate = 0.4**: matches Sat-1 (0.5) and Sat-2 (0.4) for consistency
- **description**: thematic flavor text

## What Sprint 8 Will Add

When S8-007 (level design) starts, the team will:
1. Generate Sat-3 tile assets (S8-001: floor_hive, wall_hive, damaged variants)
2. Generate Sat-3 title background (S8-002)
3. Generate 6 enemy sprites (S8-004) + 1 boss sprite (S8-006)
4. Write 10 room .tres files (S8-007) — **this is where the actual room content lives**
5. Write 4 NPC .tres files (S8-008) — for Ch7, Ch8, Ch9 NPCs
6. Write 7 fragment .tres files (S8-011) — Truth 3 "Hive Mind"
7. Write 1 BGM (S8-012) — "蜂巢之心" (Hive Heart)
8. Implement hallucination mechanic (S8-013) — visual decoy enemies

## Level Data Header Validity

The `chapter3.tres` is **valid Godot resource** (uses the LevelData script_class, all required fields populated, correct format). It can be loaded by:
- `ResourceRegistry.get_resource(&"chapter3_hive")` (auto-loads on next game launch)
- `load("res://data/levels/chapter3.tres")` (manual load)

The level_runtime will recognize it as a 10-room chapter with a boss. It won't be **playable** until the room content is added in Sprint 8, but the data is correct.

## Why I Did This Anyway

Even though `chapter3.tres` only saves the trivial header, it:
1. **Establishes the level ID** (`chapter3_hive`) — this ID is referenced by other systems (e.g., Bounty #3 in Sprint 11, boss #6 in post-game)
2. **Sets the boss ID** (`boss_hive_queen_guardian`) — this is referenced by bounty #3
3. **Confirms the resource format works** — the user can verify in Godot that the .tres loads

If the user wants to **play Sat-3 right now**, they'd need to also:
- Generate tile sprites (S8-001)
- Generate enemy sprites (S8-004)
- Add 10 room definitions to `level_runtime.gd`
- Wire up encounter / NPC / fragment .tres

This is the full Sprint 8, which is several days of work. Pre-creating the level header is a small first step.
