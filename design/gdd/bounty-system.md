# Bounty System (赏金首系统)

> **Status**: In Design
> **Author**: suxiu (player) + claude (assistant)
> **Created**: 2026-06-15
> **Last Updated**: 2026-06-15
> **Implements Pillar**: 探索密度 (Pillar 1), 装备驱动 build 试验 (Pillar 3)
> **References**: 重装机兵 (FC, 1991) — 赏金首公告板 + 赏金奖励 (金币 + 武器 + 奖牌)
> **Related GDDs**: party-system.md, weapon-ammo.md, multi-satellite-arc.md, save-load.md

## 1. Overview

The **Bounty System** in Railhunter is a classic 重装机兵 (Metal Max)-inspired optional challenge system with **6 bounties total**: **1 plot-required bounty** (Ch5 end, required to progress past Sat-2) and **5 optional bounties** (one per satellite, Sat-1 through Sat-5). Bounties are tough, single-enemy boss fights that the player accepts from a Bounty Board in town, then hunts down in a designated "boss arena" within the satellite.

The defining mechanic: bounties are **strictly optional** (except for the 1 plot-required one), but the rewards — unique weapons, special tools, gold, and the **Bounty Medal** collectible — are worth pursuing. The 5 optional bounties also drop **"Special Tools"** — single-use items that unlock alternate paths or shortcuts elsewhere in the game. Players who skip all optional bounties can still complete the game, but they'll find some puzzles / shortcuts / secrets are harder or impossible without the special tools.

The 1 plot-required bounty (Ch5 end) is integrated into the main storyline: a former crew member of Sat-2 has gone rogue, and the party must defeat them to reach Sat-3. This bounty is not "optional" — failing it means game over. But unlike a normal main-story boss, the player has to **accept the bounty at the board first** (a narrative beat, not a menu choice) before they can fight. This makes the bounty feel like a "contract" the party takes on, not just a story trigger.

**Total bounties in the game: 6 (1 plot + 5 optional)**
**Bounty medals collectible: 6 (1 per bounty)**
**Bounty special tools: 5 (1 per optional bounty)**

## 2. Player Fantasy

**The fantasy is: being a mercenary with a reputation, taking dangerous contracts for big payouts, and being known as "the mech pilot who finished the job."**

Bounties in Railhunter are the player's **out-of-main-story reason to fight**. The main story is about uncovering the truth of the satellites; bounties are about **being a professional, taking jobs for money, and earning a name**. Even the 1 plot-required bounty has this flavor: the party isn't "destined heroes" — they're "the pilots who took the contract."

**Key feelings the system delivers:**

- **Reputation and reward** — Bounty medals are visible collectibles. The player can see "Bounty Medals: 3 / 6" in the menu. Each medal is a tangible "I beat that thing" trophy.

- **Risk-reward tension** — Optional bounties are genuinely hard. The player has to decide: am I strong enough? Do I want to spend resources on a tough fight for a unique reward? Some players will skip them; others will grind until they can win.

- **Tactical planning** — Before a bounty, the player reviews the boss's known weaknesses (displayed on the board), adjusts their mech loadout, swaps weapons, and pre-buffs at the clinic. This is the "build your team for the fight" JRPG moment.

- **Single-boss focus** — Bounty fights are 1 boss vs the party. No trash mobs, no adds. Just the boss. This is purer combat than the main story, where the player often has 3-5 random encounters per chapter.

**The fantasy is NOT**: grinding for levels, doing repetitive tasks, or doing "fetch quests." Bounties are *bosses*, not errands. Each is a memorable set-piece.

## 3. Detailed Design

### 3.1 Bounty Roster (6 total)

| # | Bounty Name | Satellite | Type | Required? | Min. Level | Reward Summary |
|---|-------------|-----------|------|-----------|------------|-----------------|
| 1 | **隐藏的猎手 (The Hidden Hunter)** | Sat-1 钢轨号 | Optional | No | 5 | 5,000 gold + 1 unique weapon + 1 special tool (冰封探测器) + medal |
| 2 | **叛徒的遗产 (The Traitor's Legacy)** | Sat-2 霜原号 | **PLOT** | **Yes (Ch5 end)** | 12 | 8,000 gold + 1 unique weapon + 1 unique mech part + medal |
| 3 | **蜂后守卫 (Hive Queen's Guard)** | Sat-3 蜂巢号 | Optional | No | 18 | 12,000 gold + 1 unique weapon + 1 special tool (蜂巢扫描器) + medal |
| 4 | **AI 残响 (AI Remnant)** | Sat-4 断魂号 | Optional | No | 25 | 18,000 gold + 1 unique weapon + 1 special tool (军用干扰器) + medal |
| 5 | **造物者的回声 (The Creator's Echo)** | Sat-5 起源号 | Optional | No | 35 | 30,000 gold + 1 unique weapon + 1 special tool (造物者定位器) + medal |
| 6 | **??? (Hidden Bounty)** | Sat-5 起源号 (post-game) | Optional | No | 40 | 50,000 gold + 苍穹号强化部件 + 1 unique weapon + medal |

**Bounty #6 is a post-game "true boss" bounty** — unlocked only after completing the main story (any ending). It's the hardest fight in the game and rewards a 苍穹号-specific upgrade part.

> **Bounty #2 detail (the plot-required one)**: This is the only bounty that is NOT optional. Failing it = the Sat-2 story arc does not progress = game over (with the message "You cannot continue without completing this contract."). All other bounties can be skipped without blocking progression.

### 3.2 Bounty Board (公告板) UX

The **Bounty Board** is a town-only object (found in every town with a clinic, per §3.8 of party-system.md). The board shows:

- **Available bounties** (the player's current satellite region; later satellites' bounties show as "???")
- **Accepted bounties** (the player has accepted, not yet completed)
- **Completed bounties** (grayed out, with the medal icon)

**Reading a bounty on the board**:

| Field | Content |
|-------|---------|
| **Title** | The bounty name (e.g., "蜂后守卫") |
| **Target portrait** | The boss's face / silhouette |
| **Location** | "Sat-3 蜂巢号 — Room 7" |
| **Threat level** | "DANGEROUS" / "DEADLY" / "EXTREME" |
| **Reward summary** | "12,000 gold + 1 unique weapon + ??? (Special Tool)" |
| **Known weaknesses** | "Vulnerable to: ice damage. Resistant to: poison." |
| **Recommended level** | "Lv 18+" |
| **Status** | "AVAILABLE" / "ACCEPTED" / "COMPLETED" |

**Accepting a bounty**:
- Player presses "E" or clicks "ACCEPT" on the board.
- The bounty is added to the player's active quest list.
- The player can now go to the bounty location (in the current satellite, in a specific room) and trigger the fight.
- The board UI shows "ACCEPTED" for the bounty.

**Completing a bounty**:
- After defeating the boss, the reward is auto-credited (gold) and added to inventory (weapon / tool).
- The bounty shows as "COMPLETED" on the board.
- The player can read the bounty entry but cannot re-accept it.

**Bounty board limitations**:
- The board **only shows bounties for the player's current satellite**. Bounties for future satellites are hidden as "???" until the player reaches that satellite.
- Bounty #6 (post-game hidden) does not appear on any in-game board. It's triggered by a special event after the main story ends.
- The board is in **towns**, not in satellites. To accept a bounty, the player must be in a town (not while exploring a satellite).

### 3.3 Plot-Required Bounty — "叛徒的遗产 (The Traitor's Legacy)" (Ch5 end)

**This is the only bounty that is required to progress the main story.**

**Setup**
- **Sat-2 霜原号, Ch5 end** (third chapter of Sat-2, immediately before the party would leave for Sat-3).
- The party encounters a distress signal from a **former Sat-2 crew member** — Dr. Lyra Chen (陈丽拉), the chief xenobiologist who worked with 霜尾's mother.
- Lyra has **gone rogue**: she was experimenting with the frozen organism that 霜尾's mother was parasitized by, and she now wants to **weaponize** the organism to "save" the satellites from human overreach.
- The party arrives at Lyra's hidden lab (Room 9 of Sat-2, the deepest room). Lyra confronts them, and **the only way forward is to defeat her in combat**.

**How it works as a "bounty"** (the narrative framing):
1. **Before the fight**: A cutscene shows the party receiving a **bounty contract** from the Sat-2 surviving crew (a "wanted: Dr. Lyra Chen, alive or dead" notice). This is the same UX as accepting a normal bounty — but the player has no choice to decline (the cutscene auto-accepts).
2. **The fight**: Lyra fights with a **parasite-augmented mech** (her own custom frame, **not a standard enemy mech**). The fight is harder than a normal boss because Lyra is **plot-critical**.
3. **After the fight**: Lyra is defeated (not killed — she's a story character). She surrenders and gives the party a piece of crucial information: **the signal from Sat-5**. This unlocks the path to Sat-3.

**Bounty #2 mechanics**
- **Recommended level**: 12+ (party average, since this is Ch5 end, the party is around Lv 12-14).
- **Boss HP**: 1,500 HP (about 3x a normal boss for this chapter).
- **Boss special abilities**:
  - **Parasite Swarm** (every 3 turns): Summons 3 weak parasites that act in subsequent rounds. The party must choose: kill the parasites (lose 1-2 turns) or ignore them and tank the damage.
  - **Frost Aura** (passive): All attacks against Lyra deal 25% less damage from non-ice weapons. (Hint: bring ice weapons.)
  - **Phase 2 at 50% HP**: Lyra heals 200 HP and goes berserk (attack +50%, accuracy +20%). Visual: her mech glows red.
- **Reward**:
  - 8,000 gold (auto-credited)
  - **Chen Family Rifle** (陈家步枪): a unique weapon with high ice damage and a passive that boosts the wielder's crit rate by +10%. Lore: the rifle belonged to 霜尾's mother; Lyra kept it as a "souvenir."
  - **Lyra's Datachit** (丽拉的数据芯片): a unique mech part (head) that gives +15% XP gain and a special dialogue option with the AI in Sat-4.
  - 1 **Bounty Medal** (collectible)

**Why this bounty is required**:
- The party needs Lyra's Datachit to access the Sat-2 → Sat-3 jump point. Without it, the jump point is "encrypted" and won't activate.
- This is a soft requirement: the party could in theory ignore Lyra and try to brute-force the jump point, but the jump point is hard-coded to require the Datachit. The "no choice to decline" framing makes this feel like a story beat, not a forced quest.

**What happens if the party wipes**:
- Game over (same as any story boss). Reload the last save.
- The plot bounty is **not** a soft fail — it's a hard checkpoint.

### 3.4 Optional Bounties (5 — one per satellite, plus 1 hidden post-game)

All 5 optional bounties follow the same template:
- **Acceptable at any town** in the relevant satellite.
- **Fight location**: a specific room in the satellite (the "bounty arena").
- **Failing the fight**: no game over. The party is sent to the nearest clinic (per party-system.md §3.8). The bounty is **not** removed from the board; the player can try again.
- **Skipping the bounty entirely**: allowed. The game continues without the reward.

| # | Bounty | Sat | Recommended Lv | Special Tool Dropped |
|---|--------|-----|----------------|----------------------|
| 1 | 隐藏的猎手 | Sat-1 | 5 | 冰封探测器 (Ice Detector) |
| 3 | 蜂后守卫 | Sat-3 | 18 | 蜂巢扫描器 (Hive Scanner) |
| 4 | AI 残响 | Sat-4 | 25 | 军用干扰器 (Military Jammer) |
| 5 | 造物者的回声 | Sat-5 | 35 | 造物者定位器 (Creator Locator) |
| 6 | ??? (post-game) | Sat-5 | 40 | 苍穹号强化部件 |

**Per-bounty brief** (compact version; full mechanics to be designed in implementation phase):

#### Bounty #1 — 隐藏的猎手 (Sat-1, Lv 5)
- **Target**: A 隐藏 in Sat-1's industrial district. Has been hunting scavengers for months.
- **Fight arena**: Sat-1 Room 5 (a hidden mech bay).
- **Special mechanic**: The boss **invisibles** every 2 turns. The party must use 雷达 or 声波 attack to reveal it.
- **Special tool**: **冰封探测器** — reveals hidden enemies in any chapter (consumable, 3 uses per tool). This is one of the most "QoL-impactful" tools, useful in Ch1-3 especially.
- **Why optional but recommended**: The hidden hunter boss is one of the few enemies in Sat-1 that drops a **unique weapon** (the Frostbite Knife, +30% ice damage). The tool is also a major help in Ch1-3.

#### Bounty #3 — 蜂后守卫 (Sat-3, Lv 18)
- **Target**: A 蜂巢守卫 — half-mech, half-biological creature. Guards the hive's deepest chamber.
- **Fight arena**: Sat-3 Room 8.
- **Special mechanic**: The boss **regenerates 5% HP per turn** (must be killed quickly). Weakness: fire damage (double).
- **Special tool**: **蜂巢扫描器** — reveals hidden paths in any chapter (3 uses). Unlocks 2 hidden rooms in Ch7-9.

#### Bounty #4 — AI 残响 (Sat-4, Lv 25)
- **Target**: A **remnant of the 冥王 AI** that the player's party did not fully destroy in the main story boss fight. It survived, fragmented, and is haunting the satellite.
- **Fight arena**: Sat-4 Room 7.
- **Special mechanic**: The boss **disables one of the party's abilities per turn** (chosen randomly). Weakness: EMP damage (2x).
- **Special tool**: **军用干扰器** — disables one enemy attack per turn in any combat (consumable, 1 use per tool). A "panic button" for tough fights.

#### Bounty #5 — 造物者的回声 (Sat-5, Lv 35)
- **Target**: A **Creator Echo** — a fragment of the Creator that survived the Ch15 climax. Wants to return to the Creator.
- **Fight arena**: Sat-5 Room 10 (the deepest room).
- **Special mechanic**: The boss **mirrors the party's last 3 actions** (uses the same attacks the party used last turn, but stronger). Weakness: 苍穹号 (the player's legendary mech deals +50% damage to this boss specifically).
- **Special tool**: **造物者定位器** — in the true ending's Ch15, allows the player to see **all hidden Creator dialogue options** (not just the default 3). Critical for finding the best true-ending path.

#### Bounty #6 — Hidden Post-Game Bounty (Sat-5, Lv 40)
- **Unlocks**: After completing the main story (any ending), an NPC in the post-game town offers this bounty.
- **Target**: A **"What-If" Boss** — a fusion of all 5 main-story bosses. Has multiple phases.
- **Fight arena**: A new "Dream Arena" room unlocked in Sat-5.
- **Special mechanic**: Phase 1 = Sat-1 boss attack pattern, Phase 2 = Sat-2 boss, etc. Phase 5 = all 5 at once. The hardest fight in the game.
- **Special tool**: **苍穹号强化部件** — a unique upgrade part for 苍穹号. Adds +1 weapon slot (5 total) and +200 max HP.

### 3.5 Bounty Boss Design Rules

Every bounty boss follows these design rules (enforced during implementation):

#### Rule B1. Single enemy
- The bounty arena has **exactly 1 boss enemy**. No adds, no trash mobs.
- Exception: some bosses **summon adds during the fight** (e.g., Lyra's parasite swarm). These are part of the boss's kit, not separate enemies.

#### Rule B2. Difficulty above chapter average
- Bounty boss HP = **2.5x to 3x** a normal chapter boss's HP at the same level.
- Bounty boss damage = **1.5x to 2x** normal boss damage.
- Bounty boss has **at least 1 special mechanic** that the chapter's normal enemies do not have.
- Bounty boss has **at least 1 weakness** that the party can exploit (displayed on the board).

#### Rule B3. Pre-fight setup
- Before the fight, the player can:
  - **Equip different mechs** (in the Mech Bay, if accessible from the fight arena).
  - **Swap weapons** between mechs.
  - **Use consumables** (healing, buffs).
  - **Read the boss's full stats** on a "Intel" screen (HP, attack, weaknesses, special abilities).
- The fight does NOT start until the player presses "BEGIN FIGHT."

#### Rule B4. No escape
- Once the fight starts, **the player cannot flee**. They must win or lose.
- This is different from normal random encounters (which can be fled from).
- The party is locked in the arena for the duration of the fight.

#### Rule B5. Loss = clinic, not game over (except plot bounty)
- Losing a non-plot bounty: party is sent to the nearest clinic (per party-system.md §3.8). The bounty is **not** completed. The player can re-attempt.
- Losing the plot bounty (Bounty #2): game over.

#### Rule B6. No "cheese" strategies
- Bounty bosses are designed to **resist common cheese strategies**:
  - **Defend-spam**: Most bounty bosses have an "anti-defend" mechanic (e.g., Lyra's parasite ignores defense).
  - **Dodge-stacking**: Most bounty bosses have at least one **guaranteed hit** attack that bypasses the dodge formula.
  - **Overlevel cheese**: Bounty bosses scale with the player's level (see F2 in §4), so outleveling them doesn't trivialize the fight.

#### Rule B7. Reward proportional to difficulty
- Each bounty boss's reward is calibrated to its difficulty (see F3 in §4).
- The **Special Tool** reward is always **unique** — no other way to obtain it in the game.

### 3.6 Special Tool Drops (Optional Bounties' Unique Rewards)

The 5 optional bounties each drop a **Special Tool** — a consumable item that provides a unique utility in any chapter. These tools are designed to **make subsequent content easier or more accessible** without being required.

| Tool | Effect | Uses | Best used in... |
|------|--------|------|-----------------|
| 冰封探测器 (Ice Detector) | Reveals hidden enemies on the map. | 3 per tool | Anywhere; especially useful in Ch1-3 |
| 蜂巢扫描器 (Hive Scanner) | Reveals hidden paths and rooms on the map. | 3 per tool | Ch7-9 (Sat-3) |
| 军用干扰器 (Military Jammer) | Disables one enemy attack per turn in combat. | 1 per tool | Boss fights (any) |
| 造物者定位器 (Creator Locator) | In the Ch15 climax, reveals all hidden Creator dialogue options. | 1 per tool | Ch15 only (true ending) |
| 苍穹号强化部件 (Cangqiong Upgrade) | A permanent upgrade for 苍穹号. Adds +1 weapon slot and +200 max HP. | Permanent (1 use) | Equip on 苍穹号 in the post-game |

**Design intent**:
- Each tool is **optional** — the game can be completed without any of them.
- Each tool is **useful but not overpowered** — they reduce friction but don't trivialize content.
- The **Creator Locator** is the most strategically important — it unlocks the **best** true ending, not just any true ending. Players who skip Bounty #5 will have fewer dialogue options in the climax.

**Lore justification** (why these tools exist):
- **冰封探测器**: Salvaged from a Sat-1 recon drone that was designed to detect ice-based lifeforms. Now repurposed for general use.
- **蜂巢扫描器**: A piece of the hive's own nervous system, harvested by the bounty boss's previous victims.
- **军用干扰器**: Sat-4's standard military counter-measures tech, recovered from a destroyed weapons cache.
- **造物者定位器**: A "lost" piece of the Creator, paradoxically recovered from the boss. The boss is the only place this can be found.
- **苍穹号强化部件**: A piece of 苍穹号's original upgrade kit, which 苍穹号 never got to install. The party finishes the job.

### 3.7 Bounty Boss Mechanics (Differences from Normal Bosses)

Bounty bosses are mechanically distinct from the main-story bosses in these ways:

| Dimension | Main-story boss | Bounty boss |
|-----------|-----------------|-------------|
| HP pool | ~1 chapter's worth of damage to kill | 2.5-3x that |
| Damage | Standard for the chapter | 1.5-2x standard |
| Number of mechanics | 1-2 | **3-4** (more complex patterns) |
| Recommended level | "In-level" | **Slightly above** the player's current level |
| Pre-fight preparation | None (random encounter or scripted) | Full Mech Bay access, consumable use, intel screen |
| Escape allowed? | Yes (random) or No (scripted) | **No** |
| Failure consequence | Game over (scripted) or clinic (random) | **Clinic** (not game over, except Bounty #2) |
| Reward | Story progress | Gold + unique weapon + special tool + medal |
| Repeatable? | No (one-shot story beat) | **Yes** — losing allows re-attempt; winning marks complete (medal earned) |

**Special combat rules for bounty arenas**:
- **No mid-fight Mech Bay access**: Once the fight starts, the player cannot open the Mech Bay. They must commit to their pre-fight setup.
- **Pause is allowed** (the player can pause the game to think, but cannot change party composition).
- **No consumable use from inventory mid-fight** (consumables must be equipped to a mech's slot before the fight). Exception: 军用干扰器 (a bounty drop) can be used mid-fight because it was pre-equipped.

### 3.8 Bounty Acceptance & Tracking

#### Acceptance flow

1. Player enters a town with a Bounty Board (every town in the current satellite region has one).
2. Player interacts with the board (E key or click).
3. The board UI opens, showing all available bounties (per §3.2).
4. Player selects a bounty → sees the bounty details (target, location, reward, weaknesses).
5. Player clicks "ACCEPT" → bounty is added to active quests.
6. The board closes.

#### Active bounty tracking

Once accepted, the bounty is visible:
- **On the HUD minimap**: the bounty arena is marked with a skull icon (similar to how side-quest markers work).
- **In the Quest menu**: under "BOUNTIES" tab, the accepted bounty shows progress (e.g., "HIDDEN HUNTER — In progress — Sat-1 Room 5").
- **In the world**: when the player is near the bounty arena, the game shows a prompt: "This is the HIDDEN HUNTER's lair. Begin fight? (Y / N)".

#### Bounty completion flow

1. Player approaches the bounty arena.
2. Game prompt: "Begin fight?" (default: No, requires explicit Y).
3. If Yes → the player enters a "Pre-fight Setup" screen (full Mech Bay access, consumable use, intel screen).
4. After setup, player presses "BEGIN FIGHT" → fight starts.
5. Win → reward auto-credited. Bounty marked complete.
6. Lose → sent to clinic. Bounty remains "ACCEPTED" (can re-attempt).

#### Bounty abandonment

- The player can **abandon** a bounty by going back to the Bounty Board and clicking "ABANDON."
- Abandoned bounties can be **re-accepted** later (re-accepting is free, no penalty).
- Abandoned bounties are NOT marked "completed" — they remain "AVAILABLE" on the board.

#### Multi-bounty

- The player can have **multiple bounties active at once** (one per satellite region, max 5 active at any time).
- Each bounty has its own arena and progress. The player can do them in any order.
- The plot bounty (Bounty #2) is auto-accepted and cannot be abandoned.

### 3.9 Bounty Failure / Repeat

#### Failure consequences (per bounty type)

| Bounty | Failure result |
|--------|----------------|
| Optional bounty | Party sent to nearest clinic. Revival cost = 25% of gold (per party-system.md §3.8). The bounty remains "ACCEPTED" — player can re-attempt. |
| Plot bounty (Bounty #2) | **Game over.** Reload last save. |

#### Repeat fights

- The player can re-attempt any optional bounty **as many times as desired** (each attempt is a full bounty fight).
- Each attempt costs:
  - No direct cost (no entry fee), but if the player wipes, they lose 25% gold.
  - The boss **respawns** fully healed after each attempt.
- The reward is **only granted once** (on the first successful clear). Subsequent clears give no reward (the boss has no more loot).

#### Strategy for retry

- After a failed attempt, the player can:
  - Re-equip mechs / swap weapons based on what they learned.
  - Use different consumables.
  - Try a different pilot-mech assignment.
  - Grind for levels (in the same satellite's encounters).
- The intel screen (visible in pre-fight setup) **updates with hints** after a failed attempt: "The boss's Frost Aura reduces non-ice damage by 25%. Bring ice weapons." This is a soft "training wheels" feature for first-time bounty players.

#### The "Fool's Bounty" rule

- A bounty can be failed up to **5 times** in a row. After 5 consecutive failures, the **6th attempt grants the player a "Fool's Bounty" buff**:
  - +25% damage to the boss
  - +10% dodge
  - The boss's HP is reduced by 20%
- This is a **safety valve** for players who are stuck — it ensures the game can always be completed, even if the player can't beat a tough bounty.
- The Fool's Bounty buff is **not** applied to the plot bounty (Bounty #2) — failing that is a real fail-state.

## 4. Formulas

#### F1. Bounty boss HP formula
```
bounty_boss_HP = chapter_normal_boss_HP × BOUNTY_HP_MULTIPLIER
# BOUNTY_HP_MULTIPLIER = 2.5 to 3.0 (varies per bounty)
```

**Example**: If a Sat-3 normal boss has 500 HP, a Sat-3 bounty boss has 500 × 2.7 = 1,350 HP.

#### F2. Bounty boss level scaling
```
bounty_boss_level = max(
    recommended_level,
    max(party_pilots.level) - 3   # slightly below max party level
)
```
- The boss is always at least the **recommended level**.
- If the player is overleveled, the boss is **3 levels below** the max party level (so overleveling helps but doesn't trivialize).
- If the player is underleveled, the boss is at the recommended level (so underleveled players face a hard fight).

#### F3. Bounty reward formula
```
gold_reward = base_gold × (1 + (bounty_number - 1) × 0.5)
# Bounty 1: 5000, Bounty 2: 8000, Bounty 3: 12000, Bounty 4: 18000, Bounty 5: 30000, Bounty 6: 50000
```

#### F4. Fool's Bounty eligibility
```
consecutive_failures = tracked_per_bounty
if consecutive_failures >= 5:
    apply_fools_bounty_buff()
```

#### F5. Bounty "fog" (intel screen)
```
intel_hints_visible = 1 + consecutive_failures
# First attempt: 1 hint
# Second attempt: 2 hints
# ...
# Fifth attempt: 5 hints (all of them)
```

## 5. Edge Cases

#### E1. Player accepts bounty but never visits the arena
- **What happens**: Bounty remains "ACCEPTED" indefinitely. No penalty. The player can complete it whenever they want.
- **No deadline** — bounties are not time-limited.

#### E2. Player fails 5 times, gets Fool's Bounty buff, then succeeds
- **What happens**: The buff is consumed on success. The player gets the normal reward (no extra bonus). The counter resets to 0.

#### E3. Player accepts the same bounty twice (e.g., from two different towns in the same satellite)
- **What happens**: The board UI detects duplicates and shows "Already accepted" — the player cannot accept a second instance of the same bounty.
- **Implementation**: Bounties are tracked by `bounty_id`, not by board instance.

#### E4. Player's party is too low-level for the bounty's recommended level
- **What happens**: The bounty is still accessible. The player can attempt it (and likely fail). The boss is at the recommended level regardless of the player's level (per F2).
- **No level-gating** — the player can always try.

#### E5. Player abandons Bounty #2 (the plot one)
- **What happens**: Cannot be abandoned. The "ABANDON" button is greyed out / hidden.
- **Why**: Plot bounty is required for story progression.

#### E6. Player is in the middle of a bounty fight and the game crashes
- **What happens**: On reload, the player is at the last save point (before the bounty arena). The bounty remains "ACCEPTED" but the in-progress fight is lost. No penalty (the fight didn't complete).

#### E7. Player has a companion knocked out (in party-system §3.8 terms) and wants to attempt a bounty
- **What happens**: The bounty arena requires the full party (3 pilots). If a pilot is knocked out (in the clinic), the player must revive them first.
- **Workaround**: The bounty board in town shows "Companion at clinic: <name>. Revival cost: <amount>." The player can pay and revive before attempting the bounty.

#### E8. Player tries to use 苍穹号 for a bounty (Sat-5 bounties)
- **What happens**: 苍穹号 is the strongest mech in the game. The bounty is **balanced** for it (the boss has +20% HP and damage to compensate). The bounty is still hard, just not impossible.

#### E9. Player has 0 gold and fails a bounty
- **What happens**: The 25% gold revival cost is clamped to a minimum of 100 gold (per party-system.md §3.8 / F6). If the player has less than 100 gold, the revival fails and the player must reload. The bounty is still on the board (re-attempt possible).

#### E10. Bounty #6 (post-game) is not visible on any board
- **What happens**: It's hidden until the main story ends. Once the main story ends, an NPC in the **post-game town** tells the player about Bounty #6, and the bounty becomes available.

#### E11. Player accepts Bounty #2 (plot) before reaching its minimum level
- **What happens**: The plot bounty is **auto-accepted** at Ch5 end regardless of level. If the party is underleveled (e.g., the player skipped content), the boss will be very hard. The Fool's Bounty rule does NOT apply to plot bounties — underleveled players can still game-over here.

#### E12. Player defeats the bounty boss, but the special tool reward is duplicated
- **What happens**: The reward is **unique per bounty**. If the player has the tool already, they receive a **gold refund** (50% of the bounty's gold reward) instead. No duplication.

#### E13. The "pre-fight setup" screen allows consumable use, but the player uses up all their healing items before the fight
- **What happens**: This is allowed (and intentional). The player can pre-buff at their own risk. The fight starts with the player's current consumable state.

#### E14. Player tries to enter the bounty arena with all 4 pilots at 0 HP
- **What happens**: The arena refuses to start. A message: "All pilots are unable to fight. Visit a clinic first."

#### E15. Player accepts a bounty, then leaves the satellite
- **What happens**: The bounty is **paused** (no failure, no progress). When the player returns to that satellite, the bounty is still active.

## 6. Dependencies

### 6.1 Upstream (this system depends on)

- **Party system** (`design/gdd/party-system.md`) — Bounty fights use the full party (3 pilots + 4 mechs). The party GDD defines combat, mech-pilot decoupling, and revival rules.
- **Weapon & Ammo system** (`design/gdd/weapon-ammo.md`) — Bounty rewards include unique weapons. The Weapon GDD must support one-of-a-kind weapons with custom stats.
- **Resource / Data system** (`design/gdd/resource-data.md`) — Bounty bosses, rewards, special tools, and medals are all resources.
- **Save / Load** (`design/gdd/save-load.md`) — Bounty state (accepted, completed, failed-counter) must be persisted.
- **HUD** (`design/gdd/hud.md`) — HUD shows bounty markers on the minimap, active bounty list, and post-fight reward summary.
- **Quest / Tracking system** (TBD) — The Quest menu has a "BOUNTIES" tab. The quest system GDD (TBD) owns the menu structure.

### 6.2 Downstream (systems that depend on this)

- **Multi-Satellite Story Arc** (`design/gdd/multi-satellite-arc.md`) — The plot bounty (Bounty #2) is integrated into the Sat-2 → Sat-3 story transition. The arc GDD must reference this.
- **True Ending system** (`design/gdd/multi-satellite-arc.md` §Ending) — Bounty #5's reward (造物者定位器) is required for the **best** true ending. The arc GDD defines the exact ending logic.
- **Codex / Bestiary** (`design/gdd/resource-data.md` §codex) — Each bounty boss, when first encountered, is added to the codex with their full stats and lore.
- **Post-game content** — Bounty #6 is a post-game fight. The post-game content design (TBD) must reference this bounty.

## 7. Tuning Knobs

| Knob | Default | Range | Effect |
|------|---------|-------|--------|
| `BOUNTY_HP_MULTIPLIER` | 2.5-3.0 | 1.5-5.0 | Higher = bounty bosses have more HP. |
| `BOUNTY_DAMAGE_MULTIPLIER` | 1.5-2.0 | 1.0-3.0 | Higher = bounty bosses deal more damage. |
| `FoolsBountyThreshold` | 5 | 3-10 | How many failures before the safety buff applies. |
| `FoolsBountyDamageBonus` | 0.25 | 0.0-0.50 | Damage bonus when Fool's Bounty is active. |
| `FoolsBountyHPReduction` | 0.20 | 0.0-0.50 | HP reduction when Fool's Bounty is active. |
| `recommendedLevelOffset` | 0 (matches chapter level) | -5 to +5 | Lower = bounties are accessible earlier. |
| `special_tool_uses` | varies (1-3) | 1-10 | How many uses each special tool has. |
| `intel_hints_per_failure` | 1 | 0-3 | How many hints added per failed attempt. |
| `gold_per_bounty_index` | 5000, 8000, 12000, 18000, 30000, 50000 | any | Reward scaling. |
| `bounty_count_per_satellite` | 1 | 0-3 | How many optional bounties per satellite. |
| `plot_bounty_required` | true (Bounty #2) | true/false | Whether the plot bounty is required for story progression. |

## 8. Acceptance Criteria

#### AC1. Bounty count
- [ ] The game has exactly 6 bounties (1 plot + 5 optional + 1 post-game hidden).
- [ ] The plot bounty is Bounty #2 (Sat-2, "叛徒的遗产").
- [ ] 5 optional bounties exist, one per satellite (Sat-1 through Sat-5).
- [ ] Bounty #6 is a post-game hidden bounty, unlocked after the main story ends.

#### AC2. Bounty board UX
- [ ] Every town with a clinic has a Bounty Board.
- [ ] The board shows available bounties, accepted bounties, and completed bounties.
- [ ] The board displays threat level, recommended level, weaknesses, and reward summary.
- [ ] The board only shows bounties for the player's current satellite.

#### AC3. Bounty acceptance
- [ ] The player can accept a bounty from the board.
- [ ] The accepted bounty is added to the Quest menu's "BOUNTIES" tab.
- [ ] The bounty arena is marked on the minimap with a skull icon.
- [ ] The player can abandon a non-plot bounty (which marks it AVAILABLE again).
- [ ] The plot bounty (Bounty #2) cannot be abandoned.

#### AC4. Bounty fights
- [ ] The pre-fight setup screen allows the player to access the Mech Bay, swap weapons, and use consumables.
- [ ] Once the fight starts, the player cannot access the Mech Bay.
- [ ] Each bounty fight is a 1-vs-many battle (1 boss vs the player's party).
- [ ] The party cannot flee a bounty fight.

#### AC5. Bounty rewards
- [ ] Each successful bounty grants: gold, 1 unique weapon, 1 special tool (optional bounties only), 1 Bounty Medal.
- [ ] The reward is auto-credited to the player after the fight.
- [ ] Special tools are unique — the player cannot have duplicates.
- [ ] Bounty Medals are visible in the player's collectible list.

#### AC6. Bounty failure (optional bounties)
- [ ] Failing an optional bounty sends the party to the nearest clinic.
- [ ] The revival cost is 25% of gold (or 100 gold minimum).
- [ ] The bounty remains ACCEPTED; the player can re-attempt.
- [ ] The intel screen on re-attempt shows additional hints (1 hint per previous failure).

#### AC7. Fool's Bounty safety valve
- [ ] After 5 consecutive failures, the next attempt grants the Fool's Bounty buff.
- [ ] The buff applies +25% damage, +10% dodge, and -20% boss HP.
- [ ] The buff does not apply to the plot bounty (Bounty #2).

#### AC8. Plot bounty (Bounty #2)
- [ ] Bounty #2 is auto-accepted at Ch5 end (no menu choice).
- [ ] Failing Bounty #2 is a game over (no clinic revival).
- [ ] Winning Bounty #2 grants the Chen Family Rifle and Lyra's Datachit.
- [ ] The Datachit unlocks the Sat-2 → Sat-3 jump point.

#### AC9. Bounty special tools
- [ ] 5 special tools exist, one per optional bounty.
- [ ] Each tool has a unique effect (per §3.6).
- [ ] The 造物者定位器 (from Bounty #5) is required for the best true ending.
- [ ] Special tools are not duplicated if the player already has one.

#### AC10. Post-game bounty (Bounty #6)
- [ ] Bounty #6 does not appear on any in-game board during the main story.
- [ ] After the main story ends, an NPC tells the player about Bounty #6.
- [ ] Bounty #6's reward (苍穹号强化部件) is a permanent upgrade for 苍穹号.
- [ ] Bounty #6 has 5 phases, mirroring the 5 main-story bosses.

## 9. Open Questions

- **Q1 (medium)**: Should the Bounty Board be in **every town**, or only the **chapter's "main" town**? Currently: every town. Decision: simplify to main town only? (Less UI work.)
- **Q2 (low)**: Should bounty bosses have **lore entries in the codex**? Currently: yes (added to codex on first encounter). Decision: keep as-is.
- **Q3 (high)**: The plot bounty (Bounty #2) is in Ch5 end, but the player's party is only 2 pilots (漫游者 + 霜尾) at that point. Is that a fair fight? Currently: 2 pilots vs the boss. Need to balance the boss's damage for 2-pilot scaling. Decision: rebalance in implementation.
- **Q4 (medium)**: Should there be a **bounty "rank" system** (e.g., E-rank, D-rank, C-rank, etc., like in a typical bounty-hunter anime)? Currently: no, just by chapter level. Decision: defer to a future update.
- **Q5 (low)**: The Bounty Medal — is it a **stat-tracked collectible** (visible in the menu) or a **physical in-game item**? Currently: stat-tracked. Decision: keep as stat-tracked.
- **Q6 (high)**: The "造物者定位器" — the GDD says it's required for the **best** true ending, but the multi-satellite-arc GDD hasn't been written yet. The exact true-ending logic is TBD. Decision: define when arc GDD is written.
- **Q7 (medium)**: Should the player be able to **preview a bounty boss** (e.g., fight a "weak" version in the arena before the real fight)? Currently: no. Decision: keep as-is.
- **Q8 (low)**: When the player has 0 gold and the revival would fail, can the player **sell items** to get enough gold for revival? Currently: not specified. Decision: yes, allow item-selling at the clinic.

---

## Out-of-Scope (Handled by Other GDDs)

- **Party system** (pilots, mechs, combat) → `design/gdd/party-system.md`
- **Racing minigame** (gambling) → `design/gdd/racing-minigame.md`
- **Multi-satellite story arc** (5 satellites) → `design/gdd/multi-satellite-arc.md`
