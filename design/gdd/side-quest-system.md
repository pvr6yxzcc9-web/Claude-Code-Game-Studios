# Side Quest System

> **Status**: In Design (Sprint 13)
> **Author**: suxiu (player) + claude (assistant)
> **Last Updated**: 2026-06-17
> **Implements Pillar**: Player choice has consequences, every NPC has a story

## 1. Overview

The Side Quest System adds **12 dialogue-driven side quests** to Railhunter (3 per satellite × 4 satellites, skipping Sat-1 prologue). Each quest has a 3-choice dialogue structure — **compassionate / pragmatic / ruthless** — that drives truth_count, grants gold/XP rewards, and can unlock optional mech parts.

Side quests run **parallel to the existing Bounty system** (Sprint 11). Bounties are boss-fight side content with Special Tool rewards. Side quests are **narrative side content** with dialogue, choice, and truth impact. Both systems coexist; a player can engage with neither, one, or both.

The 12th quest is **hidden post-game content** — locked until the player reaches ≥35 truths AND completes ending A or B.

**Why this matters:** The 4 endings are currently determined mostly by story progress (5 satellites) and 苍穹号 ownership. Side quests add a **third axis** — *how* the player resolved the 12 moral choices — making each ending feel like a personal verdict, not a checklist.

## 2. Player Fantasy

**"Every choice matters. Every NPC has a story worth hearing."**

The player should feel that the world is **dense with people who need help** — and that the way they help (or don't) shapes who they become. A completionist who picks "compassionate" everywhere is fundamentally different from a pragmatist who picks the middle path, and both are different from a ruthless player who maximizes gold. The truth_count reflects this in the ending they reach.

**Reference touchstones:** Disco Elysium's dialogue trees (every line is a choice), Pyre's three-option outcomes with different rewards, Kentucky Route Zero's "Acts" that change based on your interactions.

## 3. Detailed Rules

### 3.1 Quest State Machine

```
   AVAILABLE ─accept→ ACTIVE ─complete_quest(choice)→ COMPLETED
       │            │           │
       │            │           └──→ (gold + XP + optional part + fragment) all applied once
       │            │
       │            ├──abandon→ ABANDONED (non-plot only; resets to AVAILABLE on next visit)
       │            │
       │            └──fail→ ACTIVE (retry; increments attempt_count)
       │
       └──hidden + conditions_not_met→ ??? (LOCKED; doesn't appear in board)
```

- `AVAILABLE` — quest giver NPC will offer this quest when talked to
- `ACTIVE` — player accepted, must turn in to complete
- `COMPLETED` — terminal state, choice applied, rewards granted
- `ABANDONED` — non-plot quests only; can be re-accepted
- `LOCKED` — internal state for `is_hidden=true` quests with unmet conditions

### 3.2 Three-Choice Outcome Model

Every quest dialogue tree has exactly **3 ending nodes**, each representing a thematic choice:

| Choice | Truth modifier | Gold | XP | Mech part | Tone |
|---|---|---|---|---|---|
| **Compassionate** | +1 | Low (300-500) | Standard | None | Help, heal, spare, give |
| **Pragmatic** | 0 | Medium (600-1000) | Standard | None | Trade, bargain, split, split the difference |
| **Ruthless** | -1 | High (1000-2000) | Standard | Sometimes (1 quest per satellite) | Kill, steal, exploit, betray |

The truth modifier is **per-choice**, stored in the dialogue tree's terminal node as `unlock_fragment_id` (e.g., `&"quest_q1_truth_compassionate"`). On `dialogue_ended`, `QuestManager.complete_quest(id, choice_idx)` is called with the last choice the player made.

### 3.3 Truth Integration

When a quest completes:
1. `MetaState.mark_unlocked(&"quest_q{N}_truth_{choice}")` is called (idempotent).
2. `EndingController.update_state(MetaState.unlocked_count(), cangqiong_unlocked)` is called by external code to refresh.
3. The fragment ID follows the pattern `quest_q{N}_truth_{compassionate|pragmatic|ruthless}` for easy debugging and quest restoration.

This means **completing all 12 quests on "compassionate" grants +12 truths** (in addition to the 35 from satellite completion = 47 total). On "ruthless" it grants -12 truths (capped at 0; effective range 23-47).

### 3.4 NPC Quest Handoff

Each quest-giver NPC has **3 dialogue trees**:
- `dialogue_tree_id` — initial dialogue offering the quest (used when status is `AVAILABLE`)
- `quest_complete_dialogue_id` — turn-in dialogue (used when status is `ACTIVE`)
- `quest_done_dialogue_id` — post-completion dialogue (used when status is `COMPLETED`)

When the player initiates dialogue, `DialogueManager` looks up the quest for this NPC (from `gives_quest_ids: Array[StringName]`) and picks the right tree based on quest state. First AVAILABLE/ACTIVE quest wins (priority order: ACTIVE > AVAILABLE > post-COMPLETED).

### 3.5 Prerequisite Chains

Some quests depend on others. `prerequisite_quest_ids: Array[StringName]` lists quests that must be `COMPLETED` (or in their compassionate outcome) before this one is offered. Used for narrative sequencing (e.g., "you must save the doctor before the hermit will trust you").

## 4. Formulas

### 4.1 Reward Calculation

Per-quest base rewards (tunable per-quest in `QuestData`):

```gdscript
# In QuestManager._apply_rewards(quest_id, choice_idx)
var base_gold: int = quest.gold_reward[choice_idx]  # 300/800/1500 typical
var base_xp: int = quest.xp_reward[choice_idx]  # 200/400/600 typical
var mech_part: StringName = quest.mech_part_reward[choice_idx]  # "" for non-ruthless
```

- **Compassionate gold** = base × 0.4 (rounded to 50)
- **Pragmatic gold** = base × 1.0
- **Ruthless gold** = base × 1.5 (rounded to 100)
- **XP** is constant per choice (not multiplied)
- **Mech parts** drop on the ruthless path of 1 quest per satellite (3 of 12 quests drop parts: q3 Sat-2, q6 Sat-3, q8 Sat-4)

### 4.2 Truth Count Aggregation

```gdscript
# In EndingController (existing):
func refresh_truth_count() -> void:
    var count: int = 0
    for id in MetaState.unlocked:
        if MetaState.unlocked[id]:
            count += 1
    _truths_unlocked = count
```

Truth count is **derived** from `MetaState.unlocked` (existing pattern). Quest unlocks follow the same path as fragment unlocks, so no separate counting needed.

### 4.3 Hidden Quest Unlock

```gdscript
# In QuestManager.accept_quest(id):
if quest.is_hidden:
    if MetaState.unlocked_count() < 35:
        return ERR_UNAVAILABLE
    if EndingController.get_reached_ending() not in ["A", "B"]:
        return ERR_UNAVAILABLE
```

## 5. Edge Cases

| Case | Behavior |
|---|---|
| Quest abandoned mid-turn-in dialogue | Truth delta does NOT apply; choice_idx only recorded on `dialogue_ended`; `complete_quest` re-checks state and rejects if not ACTIVE |
| Save loaded with `ACTIVE` quest but NPC no longer exists | Quest state preserved; player can still access via QuestBoardUI; dialogue blocked if NPC missing (graceful fallback to "NPC unavailable" message) |
| Save loaded with `ACTIVE` quest whose dialogue_tree_id was removed | Quest state preserved; turn-in dialogue falls back to a generic "I can help you" tree from a different NPC in the same satellite |
| Two quests with the same `giver_npc_id` | First ACTIVE wins; if none ACTIVE, first AVAILABLE wins; if none, post-COMPLETED |
| `prerequisite_quest_ids` out of order | `accept_quest` checks all prereqs; rejects with `ERR_PREREQUISITE_NOT_MET` if any is not COMPLETED |
| Hidden quest q12: MetaState.unlocked_count() < 35 | `accept_quest` returns `ERR_UNAVAILABLE`; doesn't appear in board |
| Rapid Q-key presses | `_unhandled_input` debounce 0.2s between toggles |
| `truth_count_modifier` of 0 (pragmatic) | `complete_quest` still fires, gold + XP + part still granted, fragment NOT unlocked (no truth delta) |
| Quest dialogue tree has no `unlock_fragment_id` on ending | Warning logged; quest still completes, but no truth impact |
| Player accepts a quest, then saves + quits, then loads and the prerequisite was changed | Quest state restored; if prereq is now invalid, quest becomes `ABANDONED` on load (with warning) |

## 6. Dependencies

**Upstream (must exist before this system works):**
- `MetaState` (Sprint 1) — truth fragment storage via `mark_unlocked`
- `ResourceRegistry` (Sprint 1) — `.tres` loading
- `DialogueTree` resource (Sprint 2) — dialogue schema with `unlock_fragment_id` per node
- `DialogueManager` (Sprint 2) — `dialogue_ended` signal, tree resolution
- `ClinicManager` (Sprint 7) — `add_gold` for quest gold rewards
- `BattleMathLib.ComputeXPToNextLevel` (Sprint 7) — XP curve
- `MechLoadout` (Sprint 7) — `unlock_part` for mech part rewards
- `BountyManager` (Sprint 11) — parallel pattern, copy/adapt for QuestManager
- `SaveManager` (Sprint 7) — `PRODUCER_NAMESPACES` for save/load
- `EndingController` (Sprint 10) — `update_state`, `get_reached_ending`

**Downstream (depends on this system):**
- `fc78` integration test (this sprint)
- Future: post-game content expansions (Sprint 14+)

**Parallel (no dependency):**
- `BountyManager` — side content, different reward structure
- `RacingManager` — side content, gold sink

## 7. Tuning Knobs

Per-quest in `data/quests/q{N}_*.tres` (3 outcomes × 12 quests = **36 reward triples**):

| Knob | Default range | Effect |
|---|---|---|
| `gold_reward[0]` (compassionate) | 300-500 | Low gold, high truth |
| `gold_reward[1]` (pragmatic) | 600-1000 | Medium gold, no truth |
| `gold_reward[2]` (ruthless) | 1000-2000 | High gold, -1 truth, sometimes part |
| `xp_reward` (per quest, constant) | 200-600 | Standard XP per completion |
| `mech_part_reward[2]` (ruthless) | "" or part_id | None for most, 1 of 3 satellites drops part |
| `truth_count_modifier` (per ending node) | -1, 0, +1 | Drives ending accessibility |

**Per-quest tuning philosophy:** The 3 Sat-2 quests (early game) have low rewards (300-1000g). Sat-3 mid-game quests have medium (500-1500g). Sat-4 late-game have high (1000-2000g). Sat-5 endgame have highest (1500-3000g). This progression matches expected player level + gold inflation.

## 8. Acceptance Criteria

The system is **Done** when:

1. **All 12 quests load** from `data/quests/*.tres` via `ResourceRegistry` (fc78 test #1, #2)
2. **All 12 quests registered** in `QuestManager.ALL_QUESTS` (fc78 test #3)
3. **Satellite distribution correct**: exactly 3 per Sat-2/3/4/5 (fc78 test #4)
4. **State machine works**: accept → ACTIVE, complete → COMPLETED + rewards, abandon → ABANDONED, fail → ACTIVE (fc78 tests #5-9)
5. **Truth integration works**: completing a quest with `+1` modifier increments `MetaState.unlocked_count()` (fc78 test #10)
6. **Mech parts drop** on the 3 ruthless outcomes (fc78 test #11)
7. **Prerequisites block acceptance** (fc78 test #12)
8. **Save/load roundtrip** preserves all 12 quest states (fc78 test #13)
9. **Existing v1/v2 saves still load** after adding `quest_manager` namespace (fc78 test #14)
10. **NPC dialogue tree swaps** based on quest state: AVAILABLE → initial, ACTIVE → turn-in, COMPLETED → post (fc78 tests #15, #16)
11. **Choice recorded on `dialogue_ended`** not `choice_made` (fc78 test #17)
12. **Hidden q12 locked** until ≥35 truths + ending A or B (fc78 test #18)
13. **QuestBoardUI** shows all 12 quests grouped by satellite with color coding
14. **Q key** opens QuestBoardUI from exploration state; ESC closes
15. **Localization** for all 12 quest titles + descriptions in en + zh (S13-011)

## 9. Open Questions

- **Q1: Should the hidden q12 quest be reachable via a different NPC, or a new post-game NPC?** Plan: add a new post-game NPC `postgame_courier` in Sat-5.
- **Q2: Should the dialogue tree resolution cache pick the tree at dialogue start, or re-evaluate on each node entry?** Plan: cache at start (simpler, no race conditions).
- **Q3: How should the player discover hidden quests?** Plan: a small "??? " entry in QuestBoardUI with a "Locked" badge when conditions are unmet.
- **Q4: Should `truth_count_modifier` of 0 still unlock a fragment for tracking purposes?** Plan: no — pragmatic path is a "no truth change" outcome by design.

## 10. Implementation Order

Per `production/sprints/sprint-13-side-quest.md`:

1. **S13-001** — this GDD ✓
2. **S13-002** — `QuestData` resource + 12 stub `.tres`
3. **S13-003** — `QuestManager` autoload (state machine only)
4. **S13-004** — Save v2 namespace
5. **S13-005** — Dialogue-reward wiring
6. **S13-006** — Reward application
7. **S13-007** — `QuestBoardUI`
8. **S13-008** — NPCData extension
9. **S13-009** — Dialogue tree resolution
10. **S13-010** — 12 dialogue tree `.tres` files
11. **S13-011** — Localization
12. **S13-012** — fc78 tests + summary

Each story ships independently behind a `_quests_enabled: bool = false` flag in `QuestManager._ready()`. Story 5 flips the flag. All commits are revertable without breaking the build.

## 11. Change Log

| Date | Author | Change |
|---|---|---|
| 2026-06-17 | claude | Initial GDD created (S13-001) |
