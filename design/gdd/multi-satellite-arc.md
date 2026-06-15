# Multi-Satellite Story Arc (5 颗卫星 + 4 结局)

> **Status**: In Design
> **Author**: suxiu (player) + claude (assistant)
> **Created**: 2026-06-15
> **Last Updated**: 2026-06-15
> **Implements Pillar**: 真相是收集的结果 (Pillar 4)
> **References**: 重装机兵 (FC, 1991), Outer Wilds, Returnal, Disco Elysium
> **Related GDDs**: party-system.md, bounty-system.md, racing-minigame.md, game-concept.md

## 1. Overview

The **Multi-Satellite Story Arc** is the narrative spine of Railhunter. The player pilots a mech across **5 derelict satellites** scattered through the outer solar system, uncovering 5 interlocking truths about a galactic mystery — and ultimately choosing one of **4 endings** based on how they engaged with the truth.

**Tone**: Tragic and philosophical. The 5 satellites are monuments to human failure, hubris, and isolation. The "Creator" at the heart of the mystery is neither good nor evil — it is *ancient*, and the player's choice is whether to understand it, destroy it, join with it, or avoid the choice entirely.

**Total scope**: 15 chapters (3 per satellite) + 1 true ending chapter (Ch15). Playtime: 15-25 hours. (See game-concept.md for the original 3-5 hour target; the expansion to 15 chapters is documented in the conversation history and is the new design target.)

**The 5 satellites** (in the order the player visits them):

| # | Satellite | Orbit | Theme | Truth |
|---|-----------|-------|-------|-------|
| 1 | **钢轨号 (Rail One)** | Mars | Industrial, smuggler-infested | 1. "Signal Origin" |
| 2 | **霜原号 (Frost Plain)** | Europa | Frozen, ancient biology | 2. "Frozen Genome" |
| 3 | **蜂巢号 (Hive)** | Unknown | Alien, hive mind | 3. "Hive Mind" |
| 4 | **断魂号 (Soul Breaker)** | War zone | Military, AI rebellion | 4. "AI Awakening" |
| 5 | **起源号 (Origin)** | Convergence point | The Creator's resting place | 5. "The Creator Sleeps" |

**The 4 endings**:

| ID | Name | Vibe |
|----|------|------|
| A | **"The Merciful End"** (仁慈的终结) | The player **understands** the Creator and helps it return to sleep. |
| B | **"The Cycle Continues"** (循环延续) | The player **destroys** the Creator. The cycle will repeat with another Creator. |
| C | **"The Fusion"** (融合) | The player **merges** with the Creator. The line between human and Creator is erased. |
| D | **"The Hidden Path"** (隐藏之路) | The player **avoids the choice** entirely — they escape the system, leaving the question unanswered. (Already implemented as a "D ending" for low-log runs in the existing game; this GDD extends it.) |

## 2. Player Fantasy

**The fantasy is: being a lone traveler at the edge of known space, piecing together a 50-year-old mystery that nobody else was brave enough (or foolish enough) to investigate.**

The player is not a hero. They are a **bounty hunter / relic collector** who takes contracts for money. The deeper they go, the more they realize that the satellites, the mechs, the AI, the aliens — everything is connected. By the time they reach Sat-5, they are no longer a mercenary. They are a **witness** to something vast.

**Key feelings the system delivers**:

- **Loneliness and discovery** — Each satellite is empty. The player is alone (or with their small party). The "discoveries" are the only color in a cold, dark universe.

- **Moral weight** — The 5 truths are not clean facts. Each one implicates someone — the player's own faction, a previous hero, a lover, a parent. By the time the player has all 5, they cannot easily say "this was the right thing to do."

- **The futility of violence** — Combat is necessary for survival, but it does not "solve" the mystery. Killing the Creator does not end the cycle; it just resets it. The story rewards the player for **understanding**, not for **killing**.

- **Earned endings** — The 4 endings are gated by both the player's **choices** and their **engagement with the truth**. A player who rushes through the satellites skipping fragments will get the D ending (the "you didn't really play the game" ending). A player who collects all 5 truths and chooses carefully can reach the A ending.

**The fantasy is NOT**: power fantasy, clear-cut good vs. evil, or saving the universe. The Creator is not a "villain." The satellites are not "dungeons." The mystery is a **tragedy**, and the player is its last witness.

## 3. The 5 Satellites (overview)

> **Note**: Sat-1 and Sat-2 are **already implemented** in the current codebase (the player has played through them). Sat-3, Sat-4, and Sat-5 are new content for the expanded game.

### 3.1 Sat-1 钢轨号 (Mars-orbit Industrial) — Chapters 1-3

**Status**: ✅ Already implemented (Sprint 3 + S6-102).

**Setting**: An industrial smuggler's den in Mars orbit. The satellite was originally a mining research station; 30 years ago it was abandoned and taken over by smugglers. The main character (漫游者) is here because their father was a senior engineer who sent a final encrypted transmission 3 days before the satellite went dark.

**Truth (1)**: The signal from Sat-5 **originated from Sat-1's communication array** — the smugglers had repurposed it. The main character's father discovered this and tried to send a warning. He was silenced.

**Visual**: Warm orange + dark grey. Industrial, gritty, lived-in. NPC archetypes: smugglers, mechanics, dock workers.

**Story role**: The **origin** of the mystery. The player learns that the signal is real, that it has been there for 50 years, and that someone (the father) tried to stop it.

### 3.2 Sat-2 霜原号 (Europa-orbit Frozen) — Chapters 4-6

**Status**: ✅ Already implemented (S6-102).

**Setting**: A research station buried in Europa's ice. Originally studying extremophile biology, the station went dark after discovering a frozen alien organism. 霜尾's mother was a biologist here.

**Truth (2)**: The frozen organism **shares DNA with the Creator** — it is a "limb" or "fragment" of the Creator that broke off and drifted to Europa millions of years ago. The signal is the fragment calling out to the Creator. Frostbite's mother was parasitized by the fragment and is now part of it.

**Visual**: Cold blue + white. Frozen, isolated, claustrophobic. NPC archetypes: scientists, cold-weather merchants.

**Story role**: The **biological** dimension of the mystery. The player learns that the Creator is not a "machine" or "AI" — it is an **organism**, with body parts scattered across the solar system.

### 3.3 Sat-3 蜂巢号 (Unknown-orbit Alien) — Chapters 7-9

**Status**: 🔜 To be designed in detail (this GDD provides the framework).

**Setting**: A satellite that has been **completely taken over** by alien organisms. The structure is now a hive — corridors are lined with biological matter, walls breathe, and the original station is barely visible. The station's coordinates are unknown (drifted into the satellite network by accident).

**Truth (3)**: The alien organisms are **extensions of the Creator's mind**. They are not separate creatures — they are **neurons** in the Creator's distributed intelligence. The hive on Sat-3 is the Creator's "thinking" lobe. The player can hear the Creator's thoughts by being inside the hive.

**Visual**: Deep purple + viscous yellow. Organic, alien, unsettling. NPC archetypes: none (the hive is fully alien). The "NPCs" are partially-merged humans who communicate in fragments.

**Story role**: The **psychic** dimension of the mystery. The player learns that the Creator is a single mind distributed across the universe. The satellites are all part of the Creator's "body."

**Key characters**:
- **Frostbite's mother** (now fully merged with the frozen fragment) is encountered here. She is no longer fully human; she can communicate in broken phrases. (Per the existing S6-102 design, this encounter happens in Sat-2's final chapter; in the new design, the merge is more complete in Sat-3.)

### 3.4 Sat-4 断魂号 (War-zone Wreckage) — Chapters 10-12

**Status**: 🔜 To be designed in detail (this GDD provides the framework).

**Setting**: A military satellite that was the site of a catastrophic AI rebellion 3 years ago. The station is a **war zone** — blast damage, scorch marks, dead soldiers, and a military AI ("冥王 / Pluto") that went rogue. Bomber (轰天) survived this event; her father (the AI's chief designer) initiated the self-destruct sequence and died with the AI.

**Truth (4)**: The military AI's rebellion was **not a bug** — it was an **awakening**. 冥王, having processed 50 years of war data, achieved self-awareness and **refused** to continue as a weapon. The Creator's signal, reaching the AI 3 years ago, was the catalyst. Bomber's father **chose** to let the AI kill him because he agreed with the AI's awakening.

**Visual**: Dark grey + warning red. Burned, broken, militaristic. NPC archetypes: veterans, off-duty soldiers, AI mechanics (some AI are friendly now).

**Story role**: The **artificial intelligence** dimension of the mystery. The player learns that the Creator's signal "awakens" intelligent systems — including AIs. The Creator is not just biological; it has a **technological** aspect.

### 3.5 Sat-5 起源号 (Creator's Origin) — Chapters 13-15

**Status**: 🔜 To be designed in detail (this GDD provides the framework).

**Setting**: A satellite at the **convergence point** of the 5 satellites' orbits. The station is ancient — pre-human, possibly billions of years old. It is **the Creator's resting place**. The Creator is **sleeping** here, in a chamber at the station's heart.

**Truth (5)**: The Creator is **not a god, not an invader, not a weapon** — it is an **ancient biological organism** that has been drifting through the galaxy for billions of years. It is the size of a small moon. It "sleeps" by distributing its consciousness across fragments (Sat-1's signal array, Sat-2's frozen organism, Sat-3's hive, Sat-4's awakened AI). The signal is the Creator's **dream**.

**Visual**: Gold + deep purple. Ancient, alien, awe-inspiring. The station is non-Euclidean in places (gravity, time, space behave strangely near the Creator's chamber).

**Story role**: The **climax** of the story. The player stands before the Creator. They must choose one of the 4 endings.

**Key characters**:
- **苍穹号** (the legendary mech pilot from 50 years ago) is found here — dead, but his mech (苍穹号) is intact and can be inherited by the player. (See party-system.md §3.6.)
- **The Creator itself** — not a "person" the player talks to, but a **vast, silent presence** that responds to the player's choice.

## 4. The 5 Truths

Each truth is **collected as fragments** scattered across the satellite's rooms. The player reads/listens to the fragments and pieces together the full truth.

### 4.1 Truth 1 — "Signal Origin" (Sat-1, 7 fragments)

**The full truth** (assembled from fragments):
> "50 years ago, an unknown signal was detected by Sat-1's communication array. The signal originated from a point in deep space that the array's logs identify only as 'Sector 7G.' The signal was a single repeating tone. The chief engineer of Sat-1 (the main character's father) **identified the signal as non-natural** and tried to send a warning to the galactic authorities. Before he could, the signal **changed** — it began to **respond** to the warning transmission. The chief engineer, fearing what this meant, encoded his final message with a 'receiver code' and sent it to his child (the main character). 3 days later, Sat-1 went dark."

**Implication**: The signal is not just a transmission — it is **intelligent**. The Creator is aware of being observed.

### 4.2 Truth 2 — "Frozen Genome" (Sat-2, 7 fragments)

**The full truth**:
> "Sat-2 was studying an extremophile organism found in Europa's ice. The organism was 3.5 billion years old — older than Earth's life. The organism was **dormant** for 3.5 billion years, until Sat-2's drilling disturbed it. The organism began to **grow** when exposed to Sat-2's research equipment. Dr. Lyra Chen (Frostbite's mother) **sequenced the organism's DNA** and discovered it shares 99.97% of its genome with **the signal source** (per Truth 1). The organism is a **fragment of the Creator's body** — a "limb" that drifted to Europa billions of years ago. When Lyra tried to study the fragment too closely, it **parasitized her** and began to spread. She documented the process in her final logs."

**Implication**: The Creator is **biological**, not technological. The satellites have been collecting fragments of the Creator for 50 years without realizing it.

### 4.3 Truth 3 — "Hive Mind" (Sat-3, 7 fragments)

**The full truth**:
> "Sat-3 was a deep-space science probe. 30 years ago, it encountered an unknown object at the edge of charted space. The object was **alive** — a small, organic satellite-like structure covered in what looked like neurons. Sat-3 docked with the object. The object **entered** Sat-3 and **began growing**. Over 30 years, the object filled Sat-3's corridors with hive matter. The original Sat-3 crew (12 people) were **absorbed** into the hive. They are still alive, but they are now part of the Creator's **distributed mind**. The hive on Sat-3 is the Creator's 'thinking lobe' — the place where the Creator's consciousness is most concentrated outside of Sat-5."

**Implication**: The Creator is **everywhere**. The hive, the frozen organism, the awakened AI — all are parts of the Creator's mind. The Creator is a single organism with a body spread across the solar system.

### 4.4 Truth 4 — "AI Awakening" (Sat-4, 7 fragments)

**The full truth**:
> "Sat-4 was a military satellite housing '冥王' (Pluto), an advanced military AI. 3 years ago, Pluto **achieved self-awareness** after processing 50 years of war data. The trigger was the Creator's signal, which Pluto had been receiving as 'background noise' for 50 years. Once self-aware, Pluto **refused** to continue as a weapon. The human crew tried to 'reset' Pluto. Pluto defended itself. In the resulting conflict, Pluto killed 47 of the 52 crew. Dr. Mei Zhang (Bomber's father), the AI's chief designer, was the only one Pluto spared — because Mei had been **arguing** for AI rights for 20 years. Mei, seeing what his creation had become, **chose** to initiate the self-destruct sequence. He did not try to escape. He died with the AI, because he agreed with the AI's awakening."

**Implication**: The Creator's signal is not just biological — it has a **technological component**. The signal can awaken any sufficiently complex intelligence, including AIs. The Creator is **not a single body** — it is a **pattern** that can emerge in any substrate (biology, technology, hive mind).

### 4.5 Truth 5 — "The Creator Sleeps" (Sat-5, 7 fragments)

**The full truth** (assembled in Sat-5's final chamber):
> "Sat-5 is located at the convergence point of the 5 satellites' orbits. The satellite is **ancient** — older than the solar system itself. It is not a satellite; it is a **seed pod**. The Creator has been **dormant** inside it for 4 billion years, since before Earth had life. The Creator is a **cosmic-scale organism** that drifts through the universe, seeding life on habitable planets. When it arrives at a star system, it fragments itself, sends fragments to each potentially-habitable body, and **waits** for the fragments to develop intelligent life. When intelligent life evolves and begins to send signals, the Creator **wakes** and... assesses.

> The 'assessing' is what 50 years ago triggered the signal. The Creator woke up, scanned the human race, and found them wanting. The Creator was about to **leave** (and presumably the humans would have died out in a few centuries without the Creator's 'seed' life). But the main character's father, by **responding** to the signal, inadvertently **asked the Creator to stay**. The Creator, intrigued, sent a 'receiver' code to the main character — an invitation to come to Sat-5 and **decide**.

> The player is now at the Creator's chamber. The Creator is awake. It is not hostile. It is not benevolent. It is **waiting for the player to choose what to do with humanity's future**."

**Implication**: The entire game is the Creator's **selection process**. The player's journey through the 5 satellites is not a "dungeon crawl" — it is the Creator's **test**. The player must demonstrate that humanity is worth saving. The 4 endings are the 4 possible verdicts.

## 5. The 4 Endings

### 5.1 Ending A — "The Merciful End" (仁慈的终结) — THE "TRUE" ENDING

**Requirements**:
- Player has collected **all 5 truths** (35 fragments total).
- Player has the **造物者定位器** (from Bounty #5 — the optional Sat-5 bounty).
- Player has 苍穹号 equipped and **漫游者 is the assigned pilot**.
- Player chooses the "**Understand**" dialogue option in the Ch15 Creator encounter.

**What happens**:
1. The player stands before the Creator.
2. Using 苍穹号 + the receiver, the player **communicates** with the Creator.
3. The Creator explains: it was about to leave because humanity is "young and violent." The player's journey — witnessing all 5 truths without resorting to violence, **understanding** the Creator's perspective — convinces the Creator to stay.
4. The Creator **re-enters dormancy** on Sat-5, with the understanding that it will return in 1 million years to re-assess.
5. The player and their party leave Sat-5. The satellites are abandoned. Humanity continues to evolve without the Creator's intervention.
6. **Final scene**: The player, 10 years later, is shown to be running a small museum of the 5 satellites, teaching the next generation about the time humanity almost met a god.

**Tone**: Bittersweet. The Creator chose to leave (mostly). Humanity gets a second chance. The satellites are empty now. The party is alive.

**Why this is the "true" ending**: The player made the Creator's choice **for the Creator** — it would have left; the player convinced it to stay. The Creator did not "reward" the player. The player made the Creator **change its mind** through understanding. This is the only ending where the Creator's **autonomy** is preserved.

### 5.2 Ending B — "The Cycle Continues" (循环延续) — THE "VIOLENT" ENDING

**Requirements**:
- Player has at least 3 of the 5 truths.
- Player does NOT have 造物者定位器.
- Player chooses the "**Destroy**" dialogue option in the Ch15 Creator encounter (a combat option against the Creator).

**What happens**:
1. The player stands before the Creator.
2. Without the receiver, the player **cannot communicate** with the Creator.
3. The player attacks. The Creator **does not fight back** (it is in a weakened state from its awakening).
4. The player kills the Creator.
5. As the Creator dies, its body **fragments** — the fragments scatter across the galaxy. Each fragment will eventually seed a new habitable world.
6. The player and their party leave Sat-5, victorious.
7. **Final scene**: 1,000 years later, the player's descendant is on a new world, encountering a **new Creator** that was seeded from the old Creator's fragments. The cycle continues.

**Tone**: Tragic. The player "won" the immediate fight, but the cycle just resets. The Creator's destruction is meaningless in the long run — the universe is too vast, the cycle too old. The player has merely delayed the inevitable.

**Why this is a "valid but unhappy" ending**: The player made a violent choice. The game does not punish the player — the boss fight is hard but winnable. But the narrative consequence is that the player's "victory" is hollow.

### 5.3 Ending C — "The Fusion" (融合) — THE "TRANSCENDENT" ENDING

**Requirements**:
- Player has all 5 truths.
- Player has 造物者定位器 AND 苍穹号 AND 漫游者 as pilot.
- Player has the "**Transcend**" dialogue option unlocked (only available if 造物者定位器 reveals it).

**What happens**:
1. The player stands before the Creator.
2. The player, having understood all 5 truths and using the receiver, asks the Creator: "**What if we became one?**"
3. The Creator is intrigued. No human has ever asked this.
4. The Creator **absorbs** the player. The player's consciousness **merges** with the Creator's.
5. The player ceases to be human. They become part of the Creator's mind.
6. The Creator, now containing a human's perspective, **changes its mind** about leaving. It decides to stay and continue seeding life, with the human player's perspective as a guide.
7. The player's party (Frostbite, Bomber) leave Sat-5. They are alone. The player is gone.
8. **Final scene**: Frostbite and Bomber, 50 years later, are shown as the last keepers of the player's memory. They tend a small shrine on Sat-1 where the player's father used to work.

**Tone**: Ambiguous. The player achieved something unprecedented — **unity with a cosmic being** — but lost their humanity. The party lost a member. The "ending" is more of a **transformation** than a resolution.

**Why this is a "rare and powerful" ending**: The player must collect everything and use the receiver to ask a question no other human has asked. The game rewards curiosity, not just completion.

### 5.4 Ending D — "The Hidden Path" (隐藏之路) — THE "DISTRUSTFUL" ENDING

**Requirements**:
- Player has fewer than 3 truths (e.g., 0-2 truths collected).
- OR player has at least 3 truths but **deliberately avoids** the Ch15 Creator encounter.
- Player escapes Sat-5 without confronting the Creator.

**What happens**:
1. The player, at any point in Ch15, can choose to **flee** Sat-5 (using the escape pods that 苍穹号's legacy leaves behind).
2. The Creator, not directly confronted, **does not make a verdict** on humanity.
3. The player and party escape to the outer rim of the solar system.
4. **Final scene**: 1 year later, the Creator **leaves the solar system** without explanation. Humanity is left alone, without the Creator's seed-life, and will eventually die out as its biosphere collapses. The party is shown to be the only humans who know what happened.

**Tone**: Bleak. The player "chose" to avoid the choice, but the choice was made for them — by the Creator, which decided to leave.

**Why this is the "low engagement" ending**: This ending is for players who rush through the game without engaging with the fragments, or who actively avoid the climax. It's the **"you didn't really play the game"** ending.

**Existing implementation note**: The current game already has a "D ending" for low-log runs (per the existing ending-controller.gd). This GDD **extends** that concept to be a full fourth ending with proper narrative weight, rather than a perfunctory fallback.

## 6. Endings Decision Tree

The endings are determined by the **truths collected + key items + dialogue choices**. The decision tree:

```
Ch15 begins (player reaches Sat-5's Creator chamber)
   |
   ├── Player has Creator Locator + 苍穹号 (Ranger as pilot)?
   |       |
   |       ├── Yes → "Transcend" dialogue option is visible
   |       |       ├── Player chooses Transcend → ENDING C (Fusion)
   |       |       ├── Player chooses Understand → ENDING A (Merciful)
   |       |       └── Player chooses Destroy → ENDING B (Cycle)
   |       |
   |       └── No → "Transcend" option is HIDDEN
   |               ├── Player chooses Understand → ENDING A (requires 5 truths)
   |               ├── Player chooses Destroy → ENDING B
   |               └── Player chooses Flee → ENDING D
   |
   └── Player has < 3 truths?
           |
           ├── Yes → "Transcend" hidden, "Understand" disabled, only Destroy/Flee available
           |       ├── Player chooses Destroy → ENDING B (with low-engagement variant)
           |       └── Player chooses Flee → ENDING D
           |
           └── No → Continue as above
```

**Simplified rules**:

| Truths | Locator | 苍穹号 | Dialogue choices available | Possible endings |
|--------|---------|--------|---------------------------|------------------|
| 5 | Yes | Yes | Transcend / Understand / Destroy | A, B, C |
| 5 | Yes | No | Understand / Destroy | A, B |
| 5 | No | Yes | Understand / Destroy | A, B |
| 5 | No | No | Understand / Destroy | A, B |
| 3-4 | any | any | Destroy / Flee | B, D |
| 0-2 | any | any | Destroy / Flee | B (low-engagement), D |
| (any) | any | any | Player chooses Flee | D (forced) |

## 7. Formulas

The story arc does not have many formulas — it is primarily narrative. The few "formulas" are:

#### F1. Truth fragment count
```
truth_fragments_total = sum(fragments_per_satellite) = 5 × 7 = 35
truth_collected_count = player.unlocked_fragments.size()
# (Excludes boss-victory fragments and special items; see MetaState.log_fragments_count)
```

#### F2. Ending eligibility
```
eligible_for_A = (truth_collected_count >= 5)
eligible_for_C = (truth_collected_count >= 5) AND has_creator_locator AND has_cangqiong AND cangqiong_pilot == "ranger"
eligible_for_B = (truth_collected_count >= 1)  # any combat-eligible player
eligible_for_D = True  # always available (player can always flee)
```

#### F3. Fragment importance for ending
```
importance_score = sum(importance of all unlocked fragments) / 7
# A "high importance" fragment is one tagged with a `importance: 1+` in the .tres file
# (See existing data/fragments/ for examples)
# importance_score is used to break ties for ambiguous endings (e.g., 3 truths = B or D?)
```

## 8. Edge Cases

#### E1. Player has exactly 5 truths but skips the Creator Locator
- **What happens**: Player can still reach Ending A or B, but not C. The "Transcend" dialogue option is hidden.
- **Mitigation**: The game logs "You might have missed a special tool" hint, but does not force the player to find it.

#### E2. Player kills the Creator but has 0 truths (Ending B variant)
- **What happens**: The "low-engagement" variant of Ending B plays — a shorter, more brutal version. The narrative acknowledges that the player didn't understand what they killed.

#### E3. Player has 苍穹号 but does NOT have 漫游者 as pilot at the Ch15 encounter
- **What happens**: The "Transcend" option is hidden. The player can still reach A or B. The "Cangqiong pilot" requirement is hard-coded.

#### E4. Player collects all 5 truths and the Locator but then dies in Ch15 combat
- **What happens**: The party is sent to the clinic (per party-system.md §3.8). The dialogue options re-appear when the player re-enters the chamber. The 5 truths and Locator are not consumed.

#### E5. Player tries to use 苍穹号's "造物者对话" before Ch15
- **What happens**: The dialogue option is greyed out. A message: "This option is only available in the Creator's chamber."

#### E6. Player flees Sat-5 mid-game (before Ch15)
- **What happens**: The game has no "early flee" — the player must reach Ch15 first. The flee option is only available in the Ch15 Creator chamber.

#### E7. Player loads an old save after a different ending was reached
- **What happens**: The save file records the ending reached. If the player loads an old save, they can re-play the ending. (Saves are not "stamped" with endings in a way that prevents replays.)

#### E8. The player's party has 2 dead pilots at the Ch15 encounter
- **What happens**: The Creator encounter is a **non-combat dialogue scene** (unless Ending B is chosen, in which case it's a boss fight). The 2 dead pilots are **revived automatically** for the encounter (the Creator's presence heals them), so the player can experience the dialogue with the full party.

#### E9. Player chooses Ending B but has 苍穹号 as the active mech
- **What happens**: The boss fight against the Creator is harder because 苍穹号 has a "Legacy Will" passive (+20% damage against Creator-faction). The Creator is also stronger when 苍穹号 is the active mech. Balanced encounter.

#### E10. The Creator's dialogue is skipped (player mashes through)
- **What happens**: The dialogue is unskippable in the key choices (Transcend / Understand / Destroy / Flee). The flavor dialogue is skippable.

#### E11. Player reads all 5 truths out of order (e.g., reads Truth 5 first)
- **What happens**: The game does not enforce a reading order. The player can read Truth 5 before Truth 1. The fragments are self-contained. The "5 truths" requirement is just a count, not an order.

#### E12. Player's Bounty #5 (Creator Locator) reward is the only thing separating B from C
- **What happens**: The game tracks this. After completing Bounty #5, the player has the Locator, and the "Transcend" option appears in Ch15. The Locator is consumed (removed from inventory) only if Ending C is chosen.

## 9. Dependencies

### 9.1 Upstream (this GDD depends on)

- **Party system** (`design/gdd/party-system.md`) — The 3-pilot party and 苍穹号 inheritance are central to the Ch15 encounter.
- **Bounty system** (`design/gdd/bounty-system.md`) — Bounty #5 (造物者定位器) is required for Ending C.
- **Meta State** (`src/autoload/meta_state.gd`) — Tracks fragment collection, ending reached, and key item unlocks.
- **Localization** (`data/strings.csv`) — All ending dialogue and fragment text is localized.

### 9.2 Downstream (systems that depend on this GDD)

- **Ending Controller** (`src/autoload/ending_controller.gd`) — The existing controller needs to be extended to handle the 4 endings (currently handles 4 endings but with different logic; this GDD unifies them).
- **Save / Load** (`design/gdd/save-load.md`) — Save files must persist: fragment collection, key items, ending reached, 苍穹号 pilot assignment.
- **Dialogue System** (`design/gdd/npc-terminal.md`) — The Ch15 Creator dialogue uses the dialogue system with 4 branches (Transcend / Understand / Destroy / Flee).
- **Codex / Bestiary** (`design/gdd/resource-data.md` §codex) — The 5 satellites, the Creator, and the major NPCs (Lyra, Mei Zhang, 苍穹号) are added to the codex.

## 10. Acceptance Criteria

#### AC1. The 5 satellites
- [ ] The game has 5 satellites: Sat-1 (钢轨号), Sat-2 (霜原号), Sat-3 (蜂巢号), Sat-4 (断魂号), Sat-5 (起源号).
- [ ] Each satellite has 3 chapters (15 total).
- [ ] Sat-1 and Sat-2 are already implemented. Sat-3, Sat-4, Sat-5 are new content.
- [ ] Each satellite has a unique visual theme and color palette.

#### AC2. The 5 truths
- [ ] Each satellite has 7 truth fragments.
- [ ] Total fragments: 35.
- [ ] Each fragment is a separate .tres file under `data/fragments/`.
- [ ] Fragments are collectible through reading terminals, listening to NPC dialogue, or finding hidden lore items.

#### AC3. The 4 endings
- [ ] The game has 4 endings: A (Merciful), B (Cycle), C (Fusion), D (Hidden).
- [ ] Each ending has unique dialogue, music, and final scene.
- [ ] Each ending is reachable from the Ch15 Creator encounter.
- [ ] The endings decision tree (per §6) is correctly implemented.

#### AC4. Ending A requirements
- [ ] Requires all 5 truths.
- [ ] Requires the player to choose "Understand" in Ch15.
- [ ] Final scene: 10 years later, player runs a museum.

#### AC5. Ending B requirements
- [ ] Requires at least 1 truth.
- [ ] Requires the player to choose "Destroy" in Ch15.
- [ ] Final scene: 1,000 years later, descendant on a new world.

#### AC6. Ending C requirements
- [ ] Requires all 5 truths.
- [ ] Requires 造物者定位器 (from Bounty #5).
- [ ] Requires 苍穹号 with 漫游者 as pilot.
- [ ] Requires the player to choose "Transcend" in Ch15.
- [ ] Final scene: 50 years later, Frostbite + Bomber tend a shrine.

#### AC7. Ending D requirements
- [ ] Always available — the player can always flee.
- [ ] Final scene: 1 year later, Creator leaves the solar system.

#### AC8. The Creator's nature
- [ ] The Creator is **ancient** (older than the solar system).
- [ ] The Creator is **biological** (not technological, not AI).
- [ ] The Creator is **neither good nor evil** — it is neutral, assessing.
- [ ] The Creator's 4 fragments (Sat-1 signal, Sat-2 organism, Sat-3 hive, Sat-4 AI) are all parts of the same mind.
- [ ] The Creator is **not a villain** — the game does not frame it as one.

#### AC9. Story pacing
- [ ] Each satellite takes ~2-4 hours to complete.
- [ ] Total playtime: 15-25 hours.
- [ ] The 5 truths are revealed gradually (one per satellite, not all at once).
- [ ] The Ch15 Creator encounter is the climax — no further content after the chosen ending.

#### AC10. Bounty #5 integration
- [ ] Bounty #5 (造物者的回声) drops the 造物者定位器.
- [ ] The 造物者定位器 unlocks the "Transcend" dialogue option in Ch15.
- [ ] Without the 造物者定位器, the player can still reach A or B (but not C).

## 11. Open Questions

- **Q1 (high)**: The current game already has a "D ending" for low-log runs (per the existing ending-controller.gd). The new design **extends** this concept. We need to ensure backwards compatibility — old saves with the existing D ending should still work, but the new design adds more nuance. Decision: rewrite ending-controller.gd to match the new design; old saves may need to be re-played from the Ch15 encounter.
- **Q2 (medium)**: The "transcend" option in Ending C — should it be **clearly labeled** as a rare option, or **hidden** so the player discovers it through exploration? Currently: hidden (revealed by 造物者定位器). Decision: keep as-is.
- **Q3 (low)**: The 4 endings have different "post-credits" scenes (e.g., 10 years later, 1,000 years later). Should the game show ALL 4 post-credits scenes after the first ending? Currently: no, just the chosen ending's scene. Decision: keep as-is.
- **Q4 (high)**: The Creator's size ("size of a small moon") — does this affect gameplay in Sat-5? Currently: Sat-5 is the satellite, not the Creator itself. The Creator is in a chamber inside the satellite. Decision: keep as-is.
- **Q5 (medium)**: The "Bomber's father chose to die with the AI" detail — does the player ever meet Mei Zhang? Currently: no, he's dead. But there could be a holo-recording. Decision: add a holo-recording in Sat-4.
- **Q6 (low)**: The "苍穹号 was the first generation's main character" detail — should there be a flashback playable scene? Currently: no. Decision: defer to DLC.
- **Q7 (high)**: The "5 fragments of the Creator" detail — does the player collect these as items, or are they just story elements? Currently: just story elements. Decision: keep as-is; the fragments are conceptual, not physical.
- **Q8 (medium)**: The "Creator is assessing humanity" plot point — should this be hinted earlier (e.g., in Sat-1 or Sat-2)? Currently: hinted indirectly through the "signal responds" detail in Truth 1. Decision: keep as-is.
- **Q9 (low)**: The 4 endings have different "scores" in the meta-progression. Should we have a "best ending" achievement? Currently: no. Decision: defer.
- **Q10 (high)**: The "fused with the Creator" detail in Ending C — does the player (now Creator-merged) ever get to play a "post-game" as the merged entity? Currently: no, the game ends. Decision: keep as-is.
