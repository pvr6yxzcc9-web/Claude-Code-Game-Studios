# Racing Minigame (赛马赌博系统)

> **Status**: In Design
> **Author**: suxiu (player) + claude (assistant)
> **Created**: 2026-06-15
> **Last Updated**: 2026-06-15
> **Implements Pillar**: 探索密度 (Pillar 1) — every town has a "thing to do" beyond shopping
> **References**: 重装机兵 (FC, 1991) — 战马比赛 / ギャンブル (gambling minigame)
> **Related GDDs**: party-system.md, save-load.md, multi-satellite-arc.md

## 1. Overview

The **Racing Minigame** in Railhunter is a 重装机兵 (Metal Max, 1991)-inspired **gambling minigame** where the player bets gold on **mech races** between 4 NPC mechs. The player does NOT control any mech in the race — they are a **spectator/bettor**, watching the race unfold and collecting (or losing) gold based on the outcome.

**6 tracks** are available, each with different difficulty, payout odds, and visual setting. The 4 racing mechs have different **base stats** (Speed, Stamina, Luck) that are visible to the player before they bet. The race is **fully simulated** (no player input during the race) — the player just watches a 30-60 second animated race and sees the results.

**The defining mechanic**: this is a **pure gambling** minigame. There is no "skill" involved — the player picks a mech based on stats and odds, then watches. Outcomes are determined by a **deterministic seed** + the mechs' stats, so the player can theoretically learn to predict outcomes... but with random-looking results, it's mostly about luck and risk management.

**Lore framing**: The races are called **"Inter-Satellite Drift Cup"** — a popular underground gambling event in the satellite network. The mechs that race are **chassis donated by their pilots** (mostly dead or retired), so the races have a slight "ghost race" feel. NPC bettors are dock workers, smugglers, and station crew.

**Key features**:
- 4 mechs racing on 6 tracks = 24 different (mech, track) combinations
- Fixed odds: 1.5x to 8x payouts
- Gold-only (no XP, no items)
- Bet limits per race: 100 gold (min) to 5,000 gold (max) per bet
- No limit on races per visit — player can race repeatedly
- No NPC story impact — pure gold sink/source

## 2. Player Fantasy

**The fantasy is: being a regular at a gritty underground gambling den, betting on mech races with the dock workers, and feeling the rush of a big payout (or the sting of a loss).**

This minigame is **deliberately low-stakes fun** — it's a way to break up combat with a different kind of risk. The fantasy is not "I'm a strategic gambler" — it's "I'm a mech pilot who hangs out at the betting den when I'm not on missions."

**Key feelings the system delivers**:

- **Risk vs. reward tension** — Place a small bet on the favorite (1.5x payout, low risk) or a big bet on the longshot (8x payout, high risk)? The player makes these decisions each race.
- **Pattern-matching itch** — The races use a deterministic seed, so an observant player can potentially learn which mechs win on which tracks. The minigame rewards casual observation, not pure RNG.
- **Visual spectacle** — The race animations are short (30-60s) but visually distinct per track (e.g., the deep-space track has star streaks, the ice track has snow particles). Watching races is fun, not just a money calculation.
- **"Just one more race" hook** — Easy to bet one more time. The minigame is short and doesn't require travel, so the player can grind races for gold easily.

**The fantasy is NOT**: a strategic betting game with deep analysis. The "skill" cap is low. This is a leisure activity, not a main game loop.

## 3. Detailed Design

### 3.1 The Racing Arena (location & access)

The **Racing Arena** is a special room in every **major town** (towns with a clinic + shop, per party-system.md). The arena has:

- **A central holographic track** (the race is shown as a 3D-ish top-down view of 4 mechs racing on the chosen track).
- **A betting counter** with a friendly NPC (the "bookie") who takes bets.
- **A few NPC bettors** standing around (3-5 visible at any time, see §3.7).
- **A small lounge area** with chairs (cosmetic, no gameplay effect).

**How to access**:
- Player enters the arena room.
- Player presses E on the betting counter → opens the betting UI.
- Player chooses track + mech + bet amount → race begins.
- Race animation plays (30-60s).
- Race ends → payout (if any) is auto-credited.
- Player can immediately bet again.

**Time cost per race**: ~1 minute total (30s setup + 30-60s race + 10s settlement).

**Town variations**:
- Each town's arena has a **"house style"** (visual theme matching the town — Sat-1 arena is industrial, Sat-5 arena is golden and otherworldly).
- The **odds and available mechs are the same** across all arenas (the racing is a single shared "league").
- The **NPC bettors** differ per town (Sat-1 has dock workers, Sat-5 has cultists).

### 3.2 The Four "Mechs" (race participants)

Four mechs race in every event. They are **NPC mechs** (not the player's mechs) and are fixed across the entire game.

| # | Mech Name | Class | Speed | Stamina | Luck | Visual |
|---|-----------|-------|-------|---------|------|--------|
| 1 | **铁驭 (Iron Steed)** | Heavy | 60 | 90 | 50 | Bulky industrial mech, dark grey + orange |
| 2 | **星尘 (Stardust)** | Light | 95 | 60 | 70 | Sleek scout mech, silver + blue |
| 3 | **战狼 (War Wolf)** | Medium | 80 | 75 | 60 | Wolf-themed mech, red + black |
| 4 | **鬼影 (Ghost)** | Trickster | 75 | 65 | 95 | Sleek black mech with neon highlights |

**Stats explained**:
- **Speed (0-100)**: Affects the mech's pace on **flat/smooth** tracks. Higher = faster on average lap time.
- **Stamina (0-100)**: Affects the mech's performance on **long** tracks. Higher = less fatigue in the final lap.
- **Luck (0-100)**: Affects the mech's chance of "lucky events" during the race (e.g., gaining a burst of speed, avoiding a hazard). Higher = more lucky events.

**How the player uses stats**:
- Before betting, the player sees each mech's stats and the track's properties (which stat matters most).
- The player picks the mech whose stats best match the track.
- Example: on a long track (Stamina-heavy), 铁驭 (Stamina 90) is favored. On a short track (Speed-heavy), 星尘 (Speed 95) is favored.

**Lore**:
- 铁驭: A salvaged industrial mech. Slow but unbreakable. The "old reliable" of the racing circuit.
- 星尘: A scout-class racing mech. Fast but fragile. The "favorite" of casual bettors.
- 战狼: A medium combat mech repurposed for racing. Balanced but unspectacular.
- 鬼影: A trickster mech with a shady pilot. Wins through luck more than skill. Longshots love this one.

**Mech unlock for racing participation** (optional): The player can also **enter their own mech** in a race (replacing one of the 4 NPC mechs), but only if they have a mech with sufficient "racing compatibility" (a new stat added to mechs). The player can bet on their own mech (or on others). This is a future feature, currently deferred.

### 3.3 The Six Tracks

6 tracks are available. Each track has different properties (length, hazards, visual theme, dominant stat).

| # | Track Name | Length | Dominant Stat | Hazards | Odds Range | Payout Style |
|---|------------|--------|---------------|---------|------------|--------------|
| 1 | **极星赛道 (Polar Star Track)** | Short | Speed | None | 1.5x-2.0x | Low risk, low reward |
| 2 | **迷雾赛道 (Mist Track)** | Medium | Speed + Stamina | Light fog | 1.8x-2.5x | Low-medium risk |
| 3 | **深空赛道 (Deep Space Track)** | Long | Stamina | Star streaks (visual only, no effect) | 2.0x-3.0x | Medium risk |
| 4 | **岩浆赛道 (Lava Track)** | Medium | Speed + Luck | Lava jets (random slowdowns) | 2.5x-4.0x | High risk |
| 5 | **幻影赛道 (Phantom Track)** | Long | Luck | Phasing hazards (teleport random mechs) | 3.0x-5.0x | Very high risk |
| 6 | **极光赛道 (Aurora Track)** | Extreme | All 3 stats | All hazards combined | 4.0x-8.0x | Highest risk, highest reward |

**Track details**:

#### Track 1: 极星赛道 (Polar Star)
- **Length**: 5 laps, 1 km per lap = 5 km total.
- **Visual**: Frozen industrial track under a starry sky. Snow particles drift across the field.
- **Dominant stat**: Speed (95% of race is flat-out speed).
- **Hazards**: None. Pure racing.
- **Best mech**: 星尘 (Speed 95).
- **Odds range**: 1.5x (favorite) to 2.0x (longshot).
- **Use case**: Good for first-time bettors. Easy to predict, low payout.

#### Track 2: 迷雾赛道 (Mist Track)
- **Length**: 7 laps, 1 km per lap = 7 km total.
- **Visual**: Foggy industrial corridor. Limited visibility.
- **Dominant stat**: Speed (60%) + Stamina (40%).
- **Hazards**: Light fog reduces visual range by 30%, but no gameplay effect.
- **Best mech**: 战狼 (Speed 80 + Stamina 75).
- **Odds range**: 1.8x to 2.5x.

#### Track 3: 深空赛道 (Deep Space Track)
- **Length**: 10 laps, 1.5 km per lap = 15 km total.
- **Visual**: Floating platform in deep space. Star streaks pass by.
- **Dominant stat**: Stamina (70%) + Speed (30%).
- **Hazards**: None (star streaks are visual only).
- **Best mech**: 铁驭 (Stamina 90) or 战狼 (balanced).
- **Odds range**: 2.0x to 3.0x.

#### Track 4: 岩浆赛道 (Lava Track)
- **Length**: 7 laps, 1.2 km per lap = 8.4 km total.
- **Visual**: Volcanic planet surface. Lava jets burst from the ground.
- **Dominant stat**: Speed (40%) + Luck (60%). Lava jets trigger random slowdowns based on luck.
- **Hazards**: Lava jets cause a 2-second slowdown if hit. ~5% chance per second per mech. Higher Luck = lower hit chance.
- **Best mech**: 鬼影 (Luck 95).
- **Odds range**: 2.5x to 4.0x.

#### Track 5: 幻影赛道 (Phantom Track)
- **Length**: 9 laps, 1.5 km per lap = 13.5 km total.
- **Visual**: Surreal, color-shifting corridor. The track "phases" between solid and translucent.
- **Dominant stat**: Luck (80%) + Speed (20%).
- **Hazards**: **Phasing** — every 30 seconds, a random mech is teleported 1 lap forward or backward. This can drastically change positions. Luck reduces the chance of being teleported backward.
- **Best mech**: 鬼影 (Luck 95) — the only mech that consistently avoids teleportation disasters.
- **Odds range**: 3.0x to 5.0x.

#### Track 6: 极光赛道 (Aurora Track)
- **Length**: 12 laps, 2 km per lap = 24 km total.
- **Visual**: An aurora-lit alien landscape. The most visually striking track.
- **Dominant stat**: All 3 stats matter (Speed + Stamina + Luck each contribute 33%).
- **Hazards**: **All of the above combined** (lava jets + phasing + extended length).
- **Best mech**: 战狼 (most balanced: Speed 80, Stamina 75, Luck 60) — no single stat is best, balanced wins.
- **Odds range**: 4.0x to 8.0x. Highest payout in the game.
- **Use case**: For serious gamblers. Highest risk, highest reward.

### 3.4 Betting Mechanics (Fixed Odds)

#### Betting UI flow

1. Player opens the betting counter.
2. UI shows: 4 mechs (left), 6 tracks (right), bet amount input (center).
3. Player selects a track → odds for each mech are displayed.
4. Player selects a mech → their potential payout is shown (bet × odds).
5. Player enters bet amount (min 100 gold, max 5,000 gold).
6. Player confirms → race begins.

#### Fixed odds per track

The odds are **fixed** (per the design decision: 固定赔率). The "favorite" (best stat match) has the lowest odds, the "longshot" (worst stat match) has the highest.

**Example for Track 1 (Polar Star, Speed-dominant)**:
- 星尘 (Speed 95) — **1.5x** (favorite)
- 战狼 (Speed 80) — 1.7x
- 鬼影 (Speed 75) — 1.9x
- 铁驭 (Speed 60) — **2.0x** (longshot)

**Example for Track 6 (Aurora, balanced)**:
- 战狼 (most balanced) — **4.0x** (favorite, still risky)
- 鬼影 (Luck-leaning) — 5.0x
- 星尘 (Speed-leaning) — 6.0x
- 铁驭 (Stamina-leaning) — **8.0x** (longshot)

#### Bet limits

| Constraint | Value |
|------------|-------|
| Minimum bet | 100 gold |
| Maximum bet | 5,000 gold |
| Bets per race | 1 (player picks one mech per race) |
| Races per visit | Unlimited |

#### Why fixed odds (vs. parimutuel)

- **Simpler** — player sees the payout before betting. No "what if everyone bets on the favorite?" math.
- **Faster** — race starts immediately after bet. No waiting for other bettors to "close" the pool.
- **Casual-friendly** — doesn't require understanding of pool betting.

#### Why max bet is 5,000 gold

- The game gives ~500-2,000 gold per chapter.
- A max bet of 5,000 is achievable by mid-game but not trivial.
- Prevents the player from "all-in'ing" and breaking the economy.
- The 8x payout on the Aurora track means a 5,000 gold bet could yield 40,000 gold — significant but not game-breaking.

**Workaround for high-rollers**: The game has a "high-stakes" mode (unlocked at post-game) where max bet is 50,000 gold.

### 3.5 Race Animation (Watch + Bet Mode)

The race is shown as a **30-60 second animated sequence** on the central holographic display in the arena. The player is in the "Watch + Bet" mode — they cannot control any mech, only observe.

**Animation phases** (per race):

1. **Pre-race (3-5s)**: Camera shows the 4 mechs lined up at the start. Crowd noise. Bookie announces: "Racing on <Track>!"
2. **Start gun (1s)**: A flash, the mechs launch forward.
3. **Laps (variable, 5-15 laps)**: Camera follows the mechs from a top-down view. Each lap is 2-5 seconds of animation. Hazards trigger visually (lava jets, phasing, etc.).
4. **Final stretch (3-5s)**: Camera zooms in on the lead pack.
5. **Finish line (2s)**: The winning mech crosses first. Slow-motion replay of the last 2 seconds.
6. **Results (3s)**: 1st, 2nd, 3rd, 4th place displayed. The player's bet is highlighted ("YOU BET ON <mech>, which placed #X").
7. **Payout (2s)**: If the player's bet won, a "+X gold" animation plays. If lost, a "-X gold" animation plays.

**Total race duration**: 30-60s depending on track length.

**Skip option**: The player can press SPACE to skip the animation phases (except the start gun and finish line). Skipping reduces the race to ~10-15s.

**Sound**: Each track has its own BGM (lo-fi, ambient, etc.) that plays during the race.

**Visual quality**: Top-down view, pixel art style, simple but readable. The 4 mechs are distinguishable by color and shape.

### 3.6 Payout and Settlement

#### Payout formula

```
payout = bet_amount × mech_odds  (if bet mechs places 1st)
payout = 0  (if bet mech places 2nd, 3rd, or 4th)
```

**No place/show bets** — the player only wins if their mech places **1st**. 2nd place is a loss.

**Why only 1st-place wins**: keeps the betting simple. Otherwise, the player would have to bet on multiple mechs to "spread" risk, which complicates the design.

#### Settlement

After the race ends:
- If the player's bet won: the payout (bet × odds) is added to their gold.
- If the player's bet lost: the bet amount is deducted from their gold.
- If the player's gold drops below 0 (e.g., they had 50 gold and bet 100): the bet is **denied** at the counter. The player cannot place a bet they can't cover.

**Settlement is instant** — no "claim your winnings" step.

#### Gold ceiling

- The game has a **gold cap** of 999,999 gold.
- If a payout would push the player over the cap, the excess is lost (the player gets the cap amount, not more).
- The cap is high enough that the player will never realistically hit it (the cap is more of a UI / save file safety limit).

#### Stat tracking

The game tracks **per-track stats** for the player:
- Total races run on each track
- Win rate on each track
- Largest payout on each track
- Total gold won/lost on each track

These stats are visible in a "Racing Record" menu. Pure flavor, no gameplay effect.

### 3.7 NPC Rival Bettors

The arena has **3-5 NPC bettors** standing around. They are visual flavor — they don't actually bet (the betting is just visual for them) — but they do **react** to races with cheers, groans, and exclamations. This makes the arena feel alive.

**NPC types** (per town theme):

| Town theme | NPC bettor types |
|------------|------------------|
| Sat-1 (industrial) | Dock workers, smugglers, mechanics |
| Sat-2 (frozen) | Scientists, cold-weather merchants, refueling crews |
| Sat-3 (hive) | Drone operators, hive observers, ex-bounty hunters |
| Sat-4 (military) | Veterans, off-duty soldiers, AI mechanics |
| Sat-5 (otherworldly) | Cultists, acolytes, alien observers |

**NPC reactions**:
- When their "favorite" mech is leading: they cheer, pump fists, shout "GO! GO!"
- When their "favorite" mech falls behind: they groan, throw hands, mutter.
- When the race ends: they either celebrate or lament, depending on outcome.
- The player's bet **does not affect NPC reactions** (NPCs have their own "preferred" mech per town).

**NPC dialogue** (interactable):
- Each NPC has 2-3 idle lines of dialogue ("You betting on 鬼影 again? That mech's a scam, I tell ya.")
- These are flavor text — no quest, no info, just character.

**Why NPCs are visual-only**:
- The game is single-player. There are no "other bettors" to compete with.
- The "competing" feel is provided by the racing itself, not by NPC betting.
- Keeps the minigame focused on the player's experience.

### 3.8 Racing Strategy / Hints

#### Why the player CAN win consistently

The race uses a **deterministic seed** based on:
- The track ID
- The player's save file's "race counter" (incremented per race)
- A static "track secret" (a fixed integer per track)

This means the same save file at the same "race counter" will always produce the same result. **The player can theoretically learn which mechs win on which tracks**.

**However**, the relationship between stats and outcomes is **not 1-to-1**. The race uses a complex formula (see §4) that combines Speed, Stamina, Luck, and a "lucky event" random factor. This means:
- A high-Speed mech usually wins on a Speed track... but not always.
- A high-Luck mech can win on a Luck track... but not always.
- Outcomes are **probabilistic, not deterministic** in the player's perception.

**This creates the "almost predictable" feel**: the player can sense patterns but can't perfectly predict. Over many races, the player can develop a "feel" for which mechs to bet on, similar to real-world gambling.

#### Beginner tips (visible in the betting UI)

| Track | Beginner-friendly tip |
|-------|------------------------|
| Polar Star | "Speed wins. Bet on 星尘." |
| Mist Track | "Balanced. Bet on 战狼." |
| Deep Space | "Endurance. Bet on 铁驭." |
| Lava Track | "Luck matters most. Bet on 鬼影." |
| Phantom Track | "Chaos. Bet on 鬼影 and pray." |
| Aurora Track | "All stats matter. Bet on the most balanced mech (战狼)." |

These tips are visible in the betting UI's "?" button. They are **not** spoilers — they reflect the dominant stat of each track, which is visible in the track's description.

#### Advanced strategy

- The "lucky event" random factor means **even the favorite loses sometimes**. The expected long-term payout for a favorite bet is **negative** (the bookie keeps a small edge).
- The player who bets **only on favorites** will slowly bleed gold.
- The player who **mixes favorites and longshots** can have a profitable run if their longshot bets hit.
- The "best" strategy is to bet on the **second-favorite** (which has slightly higher odds than the favorite) — small edge for the player.

**The game does NOT advertise these strategies** — they're for the player to discover through play.

## 4. Formulas

#### F1. Race outcome formula (per race)

The race outcome is determined by a **deterministic seed** combined with mech stats and a "lucky event" random factor.

```
race_seed = hash(track_id, save.race_counter, track_secret)
# e.g., race_seed = hash("deep_space", 17, 0xDEAD1234) → deterministic for the same save state

For each lap, for each mech:
    lap_time = base_lap_time - (mech.speed × 0.05)  # lower is better
    lap_time += stamina_penalty(lap_number, mech.stamina, track_length)
    lap_time += hazard_penalty(lap_number, mech.luck, track.hazards)
    if random_event(race_seed, lap_number, mech.id) < mech.luck / 100:
        lap_time *= 0.7  # lucky burst! 30% faster
    cumulative_time += lap_time

winner = mech with lowest cumulative_time
```

**In plain English**:
- Each mech has a base lap time, reduced by Speed.
- Stamina reduces the "fatigue" penalty on later laps (more impactful on long tracks).
- Luck reduces hazard penalties.
- Random lucky events (based on seed) trigger based on Luck.
- The mech with the lowest total time wins.

#### F2. Payout formula

```
payout = bet_amount × odds
# Example: 1000 gold × 2.5x = 2500 gold
```

#### F3. Odds formula (per mech per track)

The odds are derived from a "skill match" score (how well the mech's stats match the track's dominant stat):

```
skill_match = (
    track.dominant_stat_weight × mech[track.dominant_stat] +
    track.secondary_stat_weight × mech[track.secondary_stat]
) / 100

# Lower skill_match = better fit = favorite = lower odds
# Higher skill_match = worse fit = longshot = higher odds
odds = clamp(1.0 + (1.0 - skill_match) × (max_odds - 1.0), 1.0, max_odds)
# max_odds varies per track (1.5x to 8.0x)
```

**Example** (Polar Star, max_odds = 2.0):
- 星尘 (Speed 95, dominant): skill_match = (1.0 × 95) / 100 = 0.95 → odds = 1.0 + 0.05 × 1.0 = 1.05 → clamped to 1.5 (minimum)
- 铁驭 (Speed 60, dominant): skill_match = (1.0 × 60) / 100 = 0.60 → odds = 1.0 + 0.40 × 1.0 = 1.4 → 1.4 (still under min, clamped to 1.5)

Hmm, this gives too-similar odds. Let me revise — the actual implementation will use a non-linear formula. The key principle is: **favorites have low odds, longshots have high odds, the exact curve is tunable**. Implementation detail.

#### F4. Gold cap

```
max_gold = 999_999
if current_gold + payout > max_gold:
    payout = max_gold - current_gold
```

#### F5. Stamina penalty formula

```
stamina_penalty(lap, stamina, track_length) = max(0, (lap - 1) × track_length / stamina)
# e.g., lap 5 of 10, stamina 60, length 15: penalty = (5-1) × 15 / 60 = 1.0 seconds
```

#### F6. Lucky event chance

```
lucky_event_chance = luck / 200  # 0% at luck 0, 50% at luck 100
# If triggered: lap time reduced by 30%
```

## 5. Edge Cases

#### E1. Player has less than 100 gold
- **What happens**: The betting counter shows "Insufficient funds." The player cannot place a bet. They can still watch races for free? No — there's no "watch only" mode. The player must leave the arena.
- **Mitigation**: The game gives gold from completing quests, so the player will rarely have <100 gold. The bounty system is a gold source, and selling items at the shop is another.

#### E2. Player has exactly 100 gold and bets the minimum
- **What happens**: Bet is accepted. If they lose, they have 0 gold. The betting counter now shows "Insufficient funds" until they earn more.

#### E3. Player bets the max (5,000 gold) and wins on a 8x payout track
- **What happens**: Payout = 5,000 × 8 = 40,000 gold. Significant but not game-breaking.
- **Edge case**: If the player already has 960,000+ gold, the payout is capped at 39,999 (so total gold = 999,999).

#### E4. Player tries to bet more than 5,000 gold
- **What happens**: The bet input is capped at 5,000. They cannot exceed this.

#### E5. Player tries to bet a non-integer amount (e.g., 123.45 gold)
- **What happens**: Gold is integer-only in this game. Bets are rounded down to the nearest 1 gold.

#### E6. Race animation is interrupted (e.g., player closes the game during the race)
- **What happens**: The race is canceled. The bet is **refunded**. The race counter does not increment. This prevents losing a bet due to a crash.

#### E7. Player's save file is loaded after many races; race counter is very high
- **What happens**: The race counter can be any non-negative integer. The hash function is well-defined for any input. No overflow.

#### E8. Two mechs tie for 1st place
- **What happens**: Tiebreaker is by mech ID (lower ID wins). This is rare (deterministic seed = same outcome for the same input), but if it ever happens, the rule is consistent.

#### E9. The book's edge / expected value
- **What happens**: The book has a small edge (favorites win ~45% of the time, but only pay 1.5x). Over many races, the player loses ~5% on average. This is a "rake" that funds the betting system as a gold sink.
- **Mitigation for the player**: The "second-favorite" bet has a slightly positive EV. Expert players can exploit this.

#### E10. Player cheats / hacks the betting system
- **What happens**: There's no anti-cheat for the betting system — it's a single-player game. The player can hack if they want, but it would break their own fun. The game does not save the betting state separately, so save-file edits would also work.

#### E11. The 4th mech (鬼影) wins on the Polar Star track
- **What happens**: This is possible (鬼影 has Speed 75, not the lowest, but the lucky event can boost it). The payout at 1.9x is still profitable for the player.

#### E12. Player has bounty medals but no gold
- **What happens**: Bounty medals are not sellable (they're collectibles, not items). The player cannot convert them to gold.

#### E13. Player has gold over 999,999 from a quest reward
- **What happens**: The quest reward is capped at 999,999. The player cannot exceed the cap.

#### E14. NPC bettors cheer even when the player's bet loses
- **What happens**: Yes, NPCs have their own preferences. They might be cheering for a mech that beat the player's bet. This is intentional — the arena is a social space, not a "support the player" space.

#### E15. Player tries to start a race with 0 mechs (corrupted save)
- **What happens**: The betting counter detects the error and refuses to start. A message: "Racing mechs unavailable. Please contact support." (This should never happen in normal play.)

## 6. Dependencies

### 6.1 Upstream (this system depends on)

- **Town system** (TBD GDD) — Every major town (town with a clinic + shop) has a Racing Arena. The town GDD defines what makes a town "major."
- **Save / Load** (`design/gdd/save-load.md`) — Race counter and per-track stats must be persisted.
- **Resource / Data system** (`design/gdd/resource-data.md`) — The 4 racing mechs and 6 tracks are resources. The betting UI loads from these.
- **Localization** (`data/strings.csv`) — Track names, mech names, and NPC dialogue are localized.

### 6.2 Downstream (systems that depend on this)

- **Bounty system** (`design/gdd/bounty-system.md`) — Bounty rewards include gold. The betting system is a gold sink, balancing the bounty's gold source.
- **Economy balance** (TBD) — The game's gold economy depends on the betting system as a sink. The economy GDD (TBD) must calibrate gold income vs. betting rake.
- **Codex / Bestiary** (TBD) — The 4 racing mechs, when first encountered, are added to the codex as "civilian" entries (not enemy types).

## 7. Tuning Knobs

| Knob | Default | Range | Effect |
|------|---------|-------|--------|
| `min_bet` | 100 | 50-500 | Lower = more accessible; higher = more "high-stakes" feel. |
| `max_bet` | 5,000 | 1,000-50,000 | Lower = safer economy; higher = bigger payouts. |
| `gold_cap` | 999,999 | 100,000-9,999,999 | Higher = more headroom for big payouts. |
| `mech_speed_min/max` | 60-95 | 30-100 | Affects how much Speed matters. |
| `mech_stamina_min/max` | 60-90 | 30-100 | Affects how much Stamina matters. |
| `mech_luck_min/max` | 50-95 | 30-100 | Affects how much Luck matters. |
| `track_count` | 6 | 3-10 | More tracks = more variety but more design work. |
| `favorite_odds` | 1.5x | 1.2-2.0 | Lower = favorite wins pay less (more rake for book). |
| `longshot_odds` | 8.0x | 4.0-20.0 | Higher = longshots are more rewarding. |
| `lucky_event_threshold` | luck / 200 | luck / 100 to luck / 500 | Higher threshold = fewer lucky events. |
| `lucky_event_speedup` | 0.7 | 0.5-0.95 | Lower = lucky event is more impactful. |
| `book_edge` | ~5% | 0-15% | Higher = betting is more punishing long-term. |
| `race_animation_duration` | 30-60s | 10-120s | Longer = more spectacle, less grind-friendly. |
| `npc_bettor_count` | 3-5 | 0-10 | More NPCs = livelier arena, but more chatter. |
| `high_stakes_unlock_post_game` | true | true/false | Whether the high-stakes mode (50k bet cap) is unlockable. |

## 8. Acceptance Criteria

#### AC1. Racing arena exists
- [ ] Every major town has a Racing Arena room.
- [ ] The arena has a betting counter, holographic track display, and 3-5 NPC bettors.
- [ ] The arena's visual theme matches the town's theme (Sat-1 industrial, Sat-5 otherworldly, etc.).

#### AC2. Four racing mechs
- [ ] The 4 mechs are 铁驭, 星尘, 战狼, 鬼影.
- [ ] Each mech has Speed, Stamina, and Luck stats visible in the betting UI.
- [ ] The mechs are visually distinct.

#### AC3. Six tracks
- [ ] 6 tracks exist: Polar Star, Mist, Deep Space, Lava, Phantom, Aurora.
- [ ] Each track has a length, dominant stat, hazards, and odds range.
- [ ] Each track has a unique visual theme.

#### AC4. Betting mechanics
- [ ] The player can bet 100-5,000 gold per race.
- [ ] The player can only bet on 1 mech per race.
- [ ] The odds are fixed (visible before betting).
- [ ] The payout = bet × odds, only if the bet mech places 1st.
- [ ] 2nd, 3rd, 4th place = no payout.

#### AC5. Race animation
- [ ] Each race is 30-60 seconds of animation.
- [ ] The animation shows the 4 mechs racing on the chosen track.
- [ ] The animation can be skipped with SPACE (faster playback).
- [ ] The animation has start, laps, final stretch, and finish phases.
- [ ] Hazards (lava jets, phasing) trigger visually during the race.

#### AC6. Settlement
- [ ] After the race, the payout (or loss) is auto-credited.
- [ ] The player cannot bet more gold than they have.
- [ ] Gold is capped at 999,999.
- [ ] Settlements are instant (no "claim winnings" step).

#### AC7. NPC bettors
- [ ] 3-5 NPC bettors are present in the arena.
- [ ] NPCs have visual variety (different sprites per town theme).
- [ ] NPCs react to races (cheers, groans) but do not bet.
- [ ] NPCs have 2-3 idle dialogue lines.

#### AC8. Determinism
- [ ] The race outcome is deterministic for the same (track, race_counter, save) input.
- [ ] The save file persists the race counter.
- [ ] Loading an old save restores the race counter (and thus the same outcomes).

#### AC9. Beginner tips
- [ ] The betting UI has a "?" button that shows beginner tips per track.
- [ ] The tips mention the dominant stat of each track.
- [ ] The tips do not spoil the actual race outcomes.

#### AC10. High-stakes mode (post-game)
- [ ] After the main story ends, a high-stakes mode is unlocked.
- [ ] The high-stakes mode allows bets up to 50,000 gold.
- [ ] The high-stakes mode uses the same tracks and mechs (no new content, just higher stakes).

## 9. Open Questions

- **Q1 (low)**: Should the player be able to enter **their own mech** in a race? Currently: deferred. Decision: implement in a future update.
- **Q2 (medium)**: Should there be a **"racing achievement"** system (e.g., "Win 10 races on the Aurora track")? Currently: no achievements in the racing minigame (general achievements are a separate GDD). Decision: defer.
- **Q3 (low)**: Should the racing arena be **open only at certain times** (e.g., only at night)? Currently: open at all times. Decision: keep as-is.
- **Q4 (high)**: The race counter increments per race across the entire save. Is this OK for a save that the player loads often? (E.g., quick save/load). Currently: yes, the counter only increments when a race is **fully completed**. If the race is canceled (player closes game), the counter does not increment. Decision: keep as-is.
- **Q5 (medium)**: Should the racing minigame have **lore implications** (e.g., the racing mechs are piloted by ghosts, and the player eventually meets one)? Currently: lore flavor only (the mechs are "donated chassis"). Decision: defer.
- **Q6 (low)**: Should the player be able to **name their favorite racing mech**? Currently: no. Decision: defer.
- **Q7 (high)**: The book edge (5% rake) — is this fair? Currently: 5% is industry standard for real-world sports betting. The player can beat the rake with the "second-favorite" strategy. Decision: keep at 5% but allow tuning in §7.
- **Q8 (medium)**: The 6 tracks — are 6 too many? The 6th track (Aurora) is very high-risk. Currently: 6 is the design target. Decision: ship with 6.
- **Q9 (low)**: Should the player be able to **save a "favorite bet"** (e.g., "always bet 1000 gold on 鬼影")? Currently: no. Decision: defer.

---

## Out-of-Scope (Handled by Other GDDs)

- **Party system** (pilots, mechs) → `design/gdd/party-system.md`
- **Bounty system** (combat-focused side content) → `design/gdd/bounty-system.md`
- **Multi-satellite story arc** (5 satellites) → `design/gdd/multi-satellite-arc.md`
