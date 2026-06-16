# Sat-3 Truth 3 Fragments (Sprint 8 Prep)

> **Created**: 2026-06-16
> **Purpose**: Pre-create the 7 Truth 3 ("Hive Mind") story fragments for Sat-3. Sprint 8 S8-011 (1.5-day writer task) can focus on **dialogue polish** rather than fragment content creation.

## Files

7 fragments in `data/fragments/fragment_hive_*.tres`:

| Fragment | Title | Lore Layer | Unlock Condition |
|----------|-------|------------|------------------|
| `fragment_hive_1.tres` | 蜂巢是活的 (The Hive is Alive) | 4 | read_log_sat3_engineer_final |
| `fragment_hive_2.tres` | 我是神经元 (I am a Neuron) | 5 | spoke_to_frostbite_mother |
| `fragment_hive_3.tres` | 造物者的梦 (The Creator's Dream) | 6 | read_log_sat3_pre_chamber |
| `fragment_hive_4.tres` | 蜂后的低语 (The Queen's Whisper) | 7 | defeated_boss_hive_queen_guardian |
| `fragment_hive_5.tres` | 镜中的笑 (The Smile in the Mirror) | 6 | visited_c3_r7 |
| `fragment_hive_6.tres` | 繁殖的意义 (The Purpose of Breeding) | 7 | defeated_breeder_miniboss |
| `fragment_hive_7.tres` | 信号是摇篮曲 (The Signal is a Lullaby) | 8 | defeated_boss_hive_queen_guardian_2 |

## Story Arc (per `multi-satellite-arc.md` §4.3)

The 7 fragments collectively tell **Truth 3: The Hive Mind**:
- The alien organisms on Sat-3 are **extensions of the Creator's mind**
- They are not separate creatures — they are **neurons** in the Creator's distributed intelligence
- The hive on Sat-3 is the Creator's "thinking lobe"
- The player can hear the Creator's thoughts by being inside the hive

## Fragment Difficulty Curve (lore_layer)

The `lore_layer` field ranges from 1 (surface) to 10 (deepest truth). The 7 Sat-3 fragments range from 4-8, which fits Truth 3's place in the 5-Truth arc (mid-game truth, not the deepest).

| Truth | Lore Layer Range |
|-------|------------------|
| Truth 1 (Sat-1, Signal Origin) | 1-3 |
| **Truth 3 (Sat-3, Hive Mind)** | **4-8** |
| Truth 5 (Sat-5, Creator Sleeps) | 9-10 |

## Unlock Conditions (cross-reference)

The `unlock_condition` field uses the existing schema (StringName). The current conditions reference:
- `read_log_sat3_engineer_final` → Sat-3 c3_r3 terminal (drift engineer's log)
- `spoke_to_frostbite_mother` → NPC interaction in Sat-3 c3_r5
- `read_log_sat3_pre_chamber` → Sat-3 c3_r8 terminal (pre-chamber)
- `defeated_boss_hive_queen_guardian` → Boss kill in Sat-3 c3_r9
- `visited_c3_r7` → Visited Sat-3 c3_r7 (echoing corridor with mirrors)
- `defeated_breeder_miniboss` → Killed breeder in Sat-3 c3_r6
- `defeated_boss_hive_queen_guardian_2` → Defeated boss a second time (post-boss, harder variant? or just ensure collection?)

> **Note**: Some unlock conditions reference events that don't exist in the current codebase (e.g., "defeated_breeder_miniboss"). These are **forward-looking** — Sprint 8 will define these unlock events when the boss/miniboss fights are implemented.

## Related Fragment IDs

Each fragment has `related_fragment_ids` pointing to fragments that share lore context. The 7 Sat-3 fragments form a connected graph:

```
1 (alive)
├── 2 (neuron) ─── 3 (Creator's dream) ─── 5 (mirror smile) ─── 7 (lullaby)
├── 4 (queen's whisper) ─── 6 (breeding purpose) ─── 7 (lullaby)
```

`fragment_hive_7` is the **synthesis fragment** — it references all 4 prior fragments (1, 4, 5, 6) and the "lullaby" theme. Collecting all 7 unlocks the deepest layer of Truth 3.

## Lore Theme: Tragic + Philosophical

Per the user's design choice (per the 2026-06-15 conversation), the tone is **tragic + philosophical**. The 7 fragments:
- Show the hive as **intelligent but not malevolent** (per the multi-satellite-arc.md setting)
- Reveal that the **Creator is the lonely being** (not an invader)
- The signal is a **lullaby** (not a warning)
- Humanity is **part of the Creator's dream**

This is the same emotional register as Truth 5 (the deepest truth) but approached from the **biological/organic** angle rather than the **technological** angle (Truth 4) or the **cosmic** angle (Truth 5).

## How Sprint 8 S8-011 Will Use These Fragments

The writer/designer will:
1. Read these 7 fragments as the **canonical content**
2. Add **fragment 2 unlock UI** (after speaking to Frostbite's mother, the fragment appears in the Codex)
3. Add **lore_layer visualization** in the Codex (deeper fragments have a different visual treatment)
4. Add **ZH translations** to `data/strings.csv` (currently only EN)
5. Add **icon assignments** to each fragment (current .tres don't have an `icon` set)

If the writer wants to **adjust** the fragment text (e.g., add more detail, change wording), they can edit these .tres files directly. The IDs and unlock conditions are stable; only the text is editable.

## Auto-Loading

These .tres are auto-loaded by `ResourceRegistry` autoload. After the next game launch, the 7 fragment IDs will be available via:
- `ResourceRegistry.get_resource(&"fragment_hive_1")`
- `ResourceRegistry.get_resource(&"fragment_hive_2")`
- etc.

## Why the Unlock Conditions Reference Future Events

Some unlock conditions reference events that don't exist yet (e.g., "defeated_breeder_miniboss"). This is intentional:
- The **fragment content is stable** (the text is the canonical Truth 3)
- The **unlock mechanism** is implemented later (Sprint 8 S8-007/008/011)
- The condition names are **placeholders** — Sprint 8 will create the actual event triggers

If the user wants to **change** the unlock conditions before Sprint 8, they can edit the .tres files directly. The text is the most important thing; the conditions are flexible.
