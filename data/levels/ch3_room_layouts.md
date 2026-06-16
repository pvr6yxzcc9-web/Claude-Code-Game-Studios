# Sat-3 蜂巢号 — 10 Room Layout Design

> **Created**: 2026-06-16
> **Purpose**: Pre-design the 10 Sat-3 rooms (Ch7-Ch9) so that Sprint 8 S8-007 (the 3-day level designer task) can focus on **implementation** rather than **design decisions**.

## How to Read This Document

Each room has:
- **Room ID**: `c3_r1` to `c3_r10`
- **Chapter**: Which of Ch7/Ch8/Ch9 the room belongs to
- **Visual**: Description of the room's appearance (organic matter, walls, lighting)
- **Enemies**: Which enemy IDs spawn (from the 6 we created + hallucination decoys)
- **NPCs**: Which NPC ID is in this room (if any)
- **Terminals**: Which terminal log ID is in this room (if any)
- **Exits**: Which rooms connect to this one
- **Lore**: What's the story significance of this room
- **Density audit per game-concept.md Pillar 1**: "Every room must have a payoff"

## Hallucination Mechanic Integration

Per Sprint 8 S8-013, Sat-3 rooms have **1-2 hallucination decoys** (visual only, no damage). These are **in addition to** the regular enemies. The decoy IDs are `decoy_hive_a` / `decoy_hive_b` (separate from the 6 real enemies). They spawn at specific positions and have a different visual (translucent purple).

The 10-room design accounts for this. Each room that has enemies lists 1-2 decoys as part of its "encounter budget."

---

## Chapter 7 (Ch7) — First 3 Rooms

### Room 1: `c3_r1` — The Air Lock

| Attribute | Value |
|-----------|-------|
| **Chapter** | Ch7 (entrance) |
| **Visual** | A standard air lock, but the walls are coated in **translucent purple mycelium**. The door at the far end is sealed with hive matter. Dim amber light. |
| **Enemies** | 2 × ch3_hive_larva (the weakest enemy) + 1 hallucination decoy |
| **NPCs** | None |
| **Terminals** | 1 × log_sat3_arrival — "The ship is no longer responding. The walls are breathing. I can hear something in the vents." |
| **Exits** | Right → c3_r2 |
| **Lore** | The player's first view of Sat-3. Establishes the alien hive aesthetic. The terminal log is the first hint that the original crew is in trouble. |
| **Density audit** | 2 enemies (low difficulty) + 1 decoy (visual) + 1 terminal (story) + 1 exit. **Payoff: the player gets a feel for the hive and learns the crew is missing.** |

### Room 2: `c3_r2` — The Breathing Hall

| Attribute | Value |
|-----------|-------|
| **Chapter** | Ch7 |
| **Visual** | A larger room (16x12 tiles) with **walls that visibly pulse** (animated texture). Pools of viscous yellow liquid on the floor. |
| **Enemies** | 3 × ch3_hive_larva (swarm) + 2 × ch3_hive_parasite (high accuracy) + 2 hallucination decoys |
| **NPCs** | None |
| **Terminals** | 1 × log_sat3_hive_growth — "The organism grows when we're near. It learns. The walls know our names." |
| **Exits** | Left → c3_r1, Right → c3_r3 |
| **Lore** | The hive is **aware**. The terminal log is the first hint that the hive is intelligent. |
| **Density audit** | 5 enemies (medium difficulty) + 2 decoys + 1 terminal + 2 exits. **Payoff: combat difficulty ramps up; the player learns the hive is sentient.** |

### Room 3: `c3_r3` — The Drift Engineer's Quarters (NPC)

| Attribute | Value |
|-----------|-------|
| **Chapter** | Ch7 (end) |
| **Visual** | A small personal quarters, now overgrown. A workbench in the center, half-consumed by the hive. An NPC is slumped against the wall. |
| **Enemies** | 1 × ch3_hive_parasite (lurking) + 1 hallucination decoy |
| **NPCs** | 1 × ch3_drift_engineer (drift engineer who survived alone) |
| **Terminals** | 1 × log_sat3_engineer_final — "I tried to radio Sat-1. They didn't answer. I tried to escape. The door sealed itself. I think the ship is keeping me." |
| **Exits** | Left → c3_r2, Down → c3_r4 (Ch8) |
| **Lore** | The first NPC encountered. He can speak in fragments (he's been partially merged with the hive for 3 years). He gives the player **fragment 1 of Truth 3** ("The hive is the Creator's mind"). |
| **Density audit** | 1 enemy (low) + 1 decoy + 1 NPC (story) + 1 terminal (story) + 1 fragment (Truth 3 part 1) + 2 exits. **Payoff: high — fragment unlocks + NPC is memorable.** |

---

## Chapter 8 (Ch8) — Middle 3 Rooms

### Room 4: `c3_r4` — The Biomass Chamber

| Attribute | Value |
|-----------|-------|
| **Chapter** | Ch8 |
| **Visual** | A large chamber where the hive has **completely consumed** the original machinery. The walls are now 70% organic matter, with veins and pulsing nodes. |
| **Enemies** | 2 × ch3_hive_guardian + 1 × ch3_hive_mycelium (tank) + 1 hallucination decoy |
| **NPCs** | None |
| **Terminals** | 1 × log_sat3_biomass — "Sat-3 was a research station. We were studying the organism. Then it started studying us." |
| **Exits** | Up → c3_r3, Right → c3_r5 |
| **Lore** | The hive's "biomass" is the medium through which the Creator thinks. The terminal log hints at the Creator's presence. |
| **Density audit** | 3 enemies (high difficulty) + 1 decoy + 1 terminal + 2 exits. **Payoff: combat challenge + lore drop about the Creator.** |

### Room 5: `c3_r5` — The Frozen Fragment (NPC)

| Attribute | Value |
|-----------|-------|
| **Chapter** | Ch8 |
| **Visual** | A frozen chamber. The temperature has dropped (the hive's mycelium is **dead** here, killed by cold). At the center, a figure encased in ice — **Frostbite's mother**, partially merged with a frozen hive fragment. |
| **Enemies** | 1 × ch3_hive_parasite (lurking) + 1 hallucination decoy (the mother, also appears as a decoy until examined) |
| **NPCs** | 1 × ch3_frostbite_mother (NPC, partially biological) |
| **Terminals** | 1 × log_sat3_frozen_research — "Dr. Chen's experiment went wrong. The frozen organism merged with her. She's still alive. She can still speak." |
| **Exits** | Left → c3_r4, Down → c3_r6 |
| **Lore** | The **emotional climax** of Sat-3's story. Frostbite meets his mother. She can speak in broken phrases. She gives him a "mother's keepsake" item (boosts Frostbite's stats). **Fragment 2 of Truth 3** ("I am a neuron in the Creator's mind"). |
| **Density audit** | 1 enemy (low) + 1 decoy + 1 NPC (high emotional weight) + 1 terminal + 1 item + 1 fragment. **Payoff: very high — emotional + mechanical.** |

### Room 6: `c3_r6` — The Breeder's Lair

| Attribute | Value |
|-----------|-------|
| **Chapter** | Ch8 (end) |
| **Visual** | A nest-like chamber. The floor is covered in egg sacs (visually distinct from regular mycelium). The ceiling drips with viscous yellow. |
| **Enemies** | 1 × ch3_hive_breeder (boss-like mini-boss) + 3 × ch3_hive_larva (spawned by breeder) + 1 hallucination decoy |
| **NPCs** | None |
| **Terminals** | 1 × log_sat3_breeder_lair — "The breeders create more of themselves. We've killed three. There are always more. I think the queen is in the deep chamber. The one we cannot reach." |
| **Exits** | Up → c3_r5, Right → c3_r7 (Ch9) |
| **Lore** | The breeder is a mini-boss. Killing it gives a small reward (e.g., 蜂巢之心 unique weapon). The terminal hints at the queen. |
| **Density audit** | 4 enemies (boss + adds) + 1 decoy + 1 terminal + 1 weapon drop + 2 exits. **Payoff: boss fight + weapon reward.** |

---

## Chapter 9 (Ch9) — Last 3 Rooms + Boss

### Room 7: `c3_r7` — The Echoing Corridor

| Attribute | Value |
|-----------|-------|
| **Chapter** | Ch9 |
| **Visual** | A long corridor. The walls are made of **mirrored hive matter** — the player can see their own reflection. The reflections are **slightly off** (the hive mimics the player imperfectly). |
| **Enemies** | 2 × ch3_hive_guardian + 2 × ch3_hive_parasite + 4 hallucination decoys (the most decoys in the game — plays on the "are these real?" theme) |
| **NPCs** | None |
| **Terminals** | 1 × log_sat3_echo — "The reflections are wrong. They smile when I don't. They wait when I move. I think they're the hive, watching me through the walls." |
| **Exits** | Left → c3_r6, Right → c3_r8 |
| **Lore** | The mirrors establish that the hive can perceive the player. This is the **psychic** dimension of the mystery (per `multi-satellite-arc.md` §3.3). |
| **Density audit** | 4 enemies + **4 decoys** (heaviest hallucination in the game) + 1 terminal + 2 exits. **Payoff: paranoia, "which one is real?" tension.** |

### Room 8: `c3_r8` — The Pre-Chamber

| Attribute | Value |
|-----------|-------|
| **Chapter** | Ch9 |
| **Visual** | A circular chamber at the base of a **descending staircase**. The staircase leads down (off-screen) to the queen's chamber. The chamber itself is empty except for a single pulsing light. |
| **Enemies** | 1 × ch3_hive_cannon (sniper guarding the staircase) + 1 hallucination decoy |
| **NPCs** | None |
| **Terminals** | 1 × log_sat3_pre_chamber — "We're not alone. There's something below. It's been calling us. I don't think it's hostile. I think it's lonely." |
| **Exits** | Left → c3_r7, Down → c3_r9 (boss) |
| **Lore** | The pre-chamber. The player is **about to face the boss**. The terminal hints at the Creator (the lonely being). **Fragment 3 of Truth 3** ("The signal is the Creator's dream — not a warning, but a lullaby"). |
| **Density audit** | 1 enemy (sniper) + 1 decoy + 1 terminal + 1 fragment + 1 exit (down). **Payoff: emotional + lore setup for boss.** |

### Room 9: `c3_r9` — The Queen's Chamber (Boss)

| Attribute | Value |
|-----------|-------|
| **Chapter** | Ch9 (boss room) |
| **Visual** | A vast circular chamber. At the center, a **massive pulsing mass** — the queen is half-biological, half-organic-mech. Viscous yellow fluids ooze from her. The walls are 100% hive. The ceiling is impossibly high (or non-Euclidean). |
| **Enemies** | 1 × **boss_hive_queen_guardian** (boss, 2400 HP, regenerates 5% per turn) |
| **NPCs** | None (the queen is the only entity here) |
| **Terminals** | None (the queen is the "terminal" — she speaks through fragment pickups) |
| **Exits** | Up → c3_r8 (after boss kill) |
| **Lore** | The **boss fight**. The queen is the Creator's local representative. Killing her reveals **Fragment 4-7 of Truth 3** (the rest of the "hive mind" truth). She also drops the unique weapon 蜂巢之心. |
| **Density audit** | 1 boss (high difficulty) + 4 fragments (Truth 3 complete) + 1 weapon + 1 exit. **Payoff: climactic boss + Truth 3 completion + unique weapon.** |

---

## Room Layout Summary

| Room | Chapter | Enemies | Decoys | NPCs | Terminals | Fragments | Difficulty |
|------|---------|---------|--------|------|-----------|-----------|------------|
| c3_r1 | Ch7 | 2 | 1 | 0 | 1 | 0 | Low |
| c3_r2 | Ch7 | 5 | 2 | 0 | 1 | 0 | Medium |
| c3_r3 | Ch7 | 1 | 1 | 1 | 1 | 1 | Low |
| c3_r4 | Ch8 | 3 | 1 | 0 | 1 | 0 | High |
| c3_r5 | Ch8 | 1 | 1 | 1 | 1 | 1 | Low (emotional) |
| c3_r6 | Ch8 | 1 + 3 adds | 1 | 0 | 1 | 0 | Boss (mini) |
| c3_r7 | Ch9 | 4 | 4 | 0 | 1 | 0 | High (paranoia) |
| c3_r8 | Ch9 | 1 | 1 | 0 | 1 | 1 | Low (setup) |
| c3_r9 | Ch9 | 1 (boss) | 0 | 0 | 0 | 4 | Boss (climax) |
| c3_r10 | (reserved) | — | — | — | — | — | — |

**Note**: I numbered rooms 1-9 in the design but the `chapter3.tres` has `c3_r1` to `c3_r10` (10 rooms). I'll add a `c3_r10` for symmetry — likely a quiet room after the boss (recovery area, save point).

### Room 10: `c3_r10` — The Recovery Chamber (Reserved)

| Attribute | Value |
|-----------|-------|
| **Chapter** | Ch9 (post-boss) |
| **Visual** | A small, calm chamber. The hive matter is **dormant** here (the queen's death deactivated the local hive). A single save point. |
| **Enemies** | None (post-boss rest area) |
| **NPCs** | None |
| **Terminals** | 1 × log_sat3_aftermath — "If you're reading this, the queen is dead. The hive is silent. The door to the surface is open. You can leave. But you might want to stay. The view from the observation deck is beautiful." |
| **Exits** | Up → c3_r9 (boss room) |
| **Lore** | A quiet, reflective space. The player can save, rest, and reflect on the boss fight. The terminal hints at leaving Sat-3 (transition to Sat-4). |
| **Density audit** | 1 save point + 1 terminal + 1 exit. **Payoff: closure + transition to next satellite.** |

---

## What This Document Does NOT Cover

The following are **deferred** to Sprint 8 implementation:

- **Per-room tile layouts** (which specific tiles, where walls/doors are)
- **Encounter tile exact positions** (the procedurally-placed encounter tiles)
- **Hidden paths / secret rooms** (S8-020 — deferred to Nice-to-Have)
- **Boss fight special ability script** (5% HP regen per turn) — needs a separate script
- **NPC dialogue trees** (S8-008) — the 4 NPC IDs are listed, but their actual dialogue text is in NPC .tres files (separate from this layout)

This document provides the **design intent** for each room. Sprint 8's level designer uses this as a reference to implement the rooms in `level_runtime.gd` (or in a new `RoomData` resource, depending on the schema extension).

## How Sprint 8 S8-007 Will Use This Document

The level designer will:
1. Read this document for the **design intent** of each room
2. Extend `level_runtime.gd`'s `build_room` function with a `room_index → (enemy IDs, NPC ID, terminal ID, fragment ID, exits)` mapping
3. The data is keyed by `c3_r1` to `c3_r10`
4. Implementation is straightforward — the design is the spec

The level designer can also **adjust** the design (e.g., add a hidden room, change enemy placement) — this document is a starting point, not a constraint.
