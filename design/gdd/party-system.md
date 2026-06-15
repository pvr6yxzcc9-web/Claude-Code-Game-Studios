# Party System (小队系统)

> **Status**: In Design
> **Author**: suxiu (player) + claude (assistant)
> **Created**: 2026-06-15
> **Last Updated**: 2026-06-15
> **Implements Pillar**: 探索密度 (Pillar 1), 真相是收集的结果 (Pillar 4)
> **References**: 重装机兵 (FC, 1991) — 自由切换控制 + 战车改造 + 战车回收
> **Related GDDs**: weapon-ammo.md, battle-core-loop.md, mech-upgrade.md (TBD), save-load.md

## 1. Overview

The **Party System** in Railhunter is a **3-pilot + 4-mech roster** inspired by the original *重装机兵 (Metal Max, 1991)*. The player controls three named pilots (漫游者, 霜尾, 轰天), each with a distinct personality, backstory, and combat archetype. The party accumulates up to **four mechs** over the course of the 15-chapter journey across five derelict satellites: 漫游者号 (Infantry), 霜尾号 (Cavalry), 轰天号 (Artillery), and the legendary 苍穹号 (inherited mid-game).

The defining mechanic is **free pilot-mech decoupling** — any pilot can drive any mech, and the player can swap assignments in or out of combat. This creates a "build your own loadout" meta-game layered on top of the standard JRPG turn structure (1 enemy turn = N party turns, with N = number of mechs in the party). The fourth mech (苍穹号) is a narrative reward: a fallen hero's machine, inherited after a 50-year mystery, and required to unlock the true ending.

The party system is the player's primary interface for combat, exploration dialogue, and progression. The 3-pilot cast also gives the narrative a tight emotional core: all three pilots have lost a parent to the satellite disasters, which provides a unifying "found family" arc as they journey together.

## 2. Player Fantasy

**The fantasy is: leading a small, found family of mech pilots through a hostile, lonely, beautiful universe.**

The player is not a single hero — they are a **team leader** whose job is to keep three damaged people (each carrying grief from a missing or dead parent) functional and alive. Combat is collaborative, not solo: the player has to manage four mechs across multiple pilots, and the wrong assignment can mean a key pilot gets knocked out at the wrong moment.

**Key feelings the system delivers:**

- **Gritty camaraderie** — *重装机兵*'s signature. Three pilots sitting around a campfire, sharing war stories, slowly trusting each other. The dialogue system (§3.9) reinforces this by letting the player pick which companion is in-dialogue at any time, unlocking companion-specific lines.

- **Tactical weight** — Every combat decision matters. Free mech-pilot switching means the player can adapt to any situation: send 霜尾 (high-mobility pilot) into 苍穹号 (legendary frame) for a fast, high-HP frontline striker. Or put 轰天 (Iron Wall pilot) in 漫游者号 (mobile frame) to enable a hit-and-run tank build. The "meta" is fully open.

- **Legacy / inheritance** — The 苍穹号 inheritance scene is a **30-second cutscene where a 50-year-old hero passes the torch**. The mech is the strongest in the game, but the player has to *earn* it through the Sat-1 → Sat-4 journey. This is the JRPG fantasy at its purest: the legendary weapon is a reward for the journey, not a loot drop.

- **Found-family grief** — All three pilots are orphans of the satellite disasters. The party's growth is **mutual healing**, not just power progression. Death and revival in combat (via the town clinic) reinforces this: a knocked-out pilot is never "lost," only "set back," and the cost is gold, not the run.

**The fantasy is NOT**: lone-hero action, power fantasy, "I am the chosen one," or competitive multiplayer. The party is small, vulnerable, and human.

## 3. Detailed Design

### 3.1 Party Composition

The party consists of **3 player-controlled characters** (no AI companions — every character is the player's responsibility, every turn). Each character has a fixed archetype (Infantry / Cavalry / Artillery), a fixed mech, and a fixed satellite backstory. **The hidden 4th mech** is unlocked in late-game and replaces the main character's mech (see §3.6).

| Slot | Name | Archetype | Mech | Linked Satellite | Linked Truth | Joins |
|------|------|-----------|------|------------------|--------------|-------|
| 1 | 漫游者 (Ranger) | 步兵 (Infantry) | 漫游者号 | Sat-1 钢轨号 + Sat-3 蜂巢号 | Truth 1 + Truth 3 | Game start |
| 2 | 霜尾 (Frostbite) | 骑兵 (Cavalry) | 霜尾号 | Sat-2 霜原号 | Truth 2 | Ch4 mid (Sat-2 first chapter) |
| 3 | 轰天 (Bomber) | 炮兵 (Artillery) | 轰天号 | Sat-4 断魂号 | Truth 4 | Ch10 mid (Sat-4 first chapter) |
| 4 | ??? (hidden) | ??? | 苍穹号 | Sat-5 起源号 | Truth 5 (true ending) | Ch13 end (before Sat-5) |

> **Truth allocation rationale**: Slot 1 covers 2 truths (Sat-1 + Sat-3) because the main character is the only one who can perceive the Creator's signal. Slot 2 and 3 each cover 1 truth tied to their personal backstory. The hidden 4th mech is the key to Truth 5 / the true ending.
>
> **Detail on characters 2 and 3** (slots 2 and 3) is TBD — see §3.2. This subsection focuses on character 1 (the main character).

#### Character 1: 漫游者 (Ranger) — the main character

**Identity**

| Attribute | Value |
|-----------|-------|
| Codename | 漫游者 (Ranger) |
| True name | Player-customizable; defaults to 漫游者 if not set |
| Age | ~30 |
| Background | Father was a senior engineer aboard Sat-1 钢轨号. 3 days before the satellite went dark, the father sent a final encrypted transmission containing the "Creator Receiver" code. The main character is the only one who received that message. |
| Personality | Calm, persistent, slow to trust. Has unresolved feelings about the father's disappearance but is not emotional. The party's "thinker" and "scout." |
| Story role | Personally unlocks Truth 1 (Sat-1: the father's secret). Indirectly enables Truth 3 (Sat-3: the hive's true nature). The only character who can perceive the Creator's signal. |

**Combat archetype: 步兵 (Infantry, balanced)**

| Stat | Value | Rank (of 3) |
|------|-------|-------------|
| Total HP | 400 (4 parts × 100) | 2nd |
| Mobility | 4/5 | 2nd |
| Armor | 3/5 | 2nd |
| Firepower | 3/5 | 2nd |
| Weapon slots | 3 | tied 1st |

**Starting weapons** (3 slots)
- Slot 1: Rifle (mid-range)
- Slot 2: Knife (close-range defense)
- Slot 3: Throwable (tactical utility)

**Special abilities**

1. **闪避 (Dodge)** — see §4 Formulas for the full formula. Summary: `min(0.10 + level × 0.02 + equip_bonus + mech_bonus, 0.80)`, with a **guaranteed dodge every 3 turns** as a safety net.
2. **侦查 (Scout)** — On entering a new room, hidden items are revealed on the map (位置提示, not auto-collected).
3. **精准打击 (Precision Strike)** — +15% crit rate baseline.
4. **造物者接收器 (Creator Receiver)** — A unique passive item (not in inventory). Lets the main character perceive Creator signals in any satellite. **Required for the true ending.**

**Mech: 漫游者号 (Standard Recon class)**

| Spec | Value |
|------|-------|
| Class | 侦察型 (Recon) |
| Total HP | 400 (head/chest/arms/legs, 100 each) |
| Mobility | 4/5 |
| Armor | 3/5 |
| Firepower | 3/5 (3 weapon slots) |
| Special module slot | 1 (post-game, e.g., "Detector" or "Signal Jammer") |

**In-party status**
- **Ch1-Ch15**: always present (main character cannot leave the party).
- **Death**: triggers game over (main character death = party wipe = reload last save). The main character is the only pilot who **cannot be revived** — this preserves the game's tension and gives the main character unique narrative weight.

### 3.2 Party Member Roster

> **Detail on character 1 (漫游者)**: see §3.1.

This subsection details characters 2 and 3. The shared theme across all three characters is **"lost family"** — each character lost a parent (or, in the main character's case, a father who is missing-presumed-dead) in a satellite disaster. This gives the party a unifying emotional undercurrent and creates natural in-party dialogue hooks (shared grief, occasional friction between coping styles).

#### Character 2: 霜尾 (Frostbite) — Cavalry (high-mobility scout)

**Identity**

| Attribute | Value |
|-----------|-------|
| Codename | 霜尾 (Frostbite) |
| True name | Player-customizable; defaults to 霜尾 if not set |
| Age | ~24 |
| Gender | Male |
| Background | Mother was a biologist aboard Sat-2 霜原号, researching a "frozen organism" when the satellite went dark 3 years ago. Frostbite has never stopped searching for her. He is willing to take any risk to find out what happened. |
| Personality | Impulsive, intuitive, acts before thinking. Appears cold on the surface, but carries deep guilt about his mother's fate. Forms a deliberate contrast with the main character (冷静 vs 冲动). |
| Story role | Personally unlocks Truth 2 (Sat-2 霜原号): the mother's research logs reveal that his mother is **not dead — she is being parasitized by the frozen organism** she was studying. |

**Combat archetype: 骑兵 (Cavalry, high-risk high-reward)**

| Stat | Value | Rank (of 3) |
|------|-------|-------------|
| Total HP | 320 (4 parts × 80) | 3rd (lowest) |
| Mobility | 5/5 | 1st (highest) |
| Armor | 2/5 | 3rd (lowest) |
| Firepower | 3/5 | 2nd |
| Weapon slots | 2 | 3rd (fewest) |

**Design intent**: Cavalry is high-risk high-reward — can reach the enemy backline, but cannot survive sustained damage and has fewer weapons.

**Starting weapons (when 霜尾号 is found in Room 7 of Sat-2, pre-equipped on the mech, not on the pilot)**
- Slot 1: **双刃长刀 (Twin-blade greatsword)** — Close-range high damage. Can attack twice per turn, but the second hit deals half damage.
- Slot 2: **冰冻手雷 (Cryo grenade)** — Throwable. Inflicts -50% speed on the target for 2 turns.

**Special abilities**

1. **突袭 (Flank)** — Every 3 turns, the first turn's action **doubles** (move further + first-strike). Guaranteed trigger (safety net).
2. **生存本能 (Survival Instinct)** — When HP < 25%, **dodge rate +30%**. Desperation mechanic.
3. **追踪者 (Tracker)** — On entering a new room, an arrow points toward the nearest unexplored area (5-second fade). **Complements** the main character's "侦查" (which shows hidden items, not direction).

**Mech: 霜尾号 (Cavalry / Scout class)**

| Spec | Value |
|------|-------|
| Class | 骑兵型 (Cavalry) |
| Total HP | 320 (head/chest/arms/legs, 80 each) |
| Mobility | 5/5 |
| Armor | 2/5 |
| Firepower | 3/5 (2 weapon slots) |
| Special module slot | 1 (post-game, e.g., "Booster" or "Light Shield") |
| Visual (art brief) | Lighter and slimmer than the main character's mech. Cool blue-white + silver (matches Sat-2 palette). Bipedal with ski/slide attachments (for ice terrain). Weapons mounted forward (close-range use). |

**In-party status**
- **Ch1-Ch3**: Not in party (main character solos Sat-1).
- **Ch4 mid**: Joins (Sat-2 霜原号 first chapter, mid-way through).
- **Ch4-Ch15**: Always present.

**Death & recovery** — see §3.8 for the full rules. Summary:
- Frostbite CAN die in battle. If killed, the fight continues with the remaining pilots.
- After combat, the killed pilot is **auto-sent to the nearest town's medical clinic** (or to the satellite's on-board med-bay if no town is available).
- Revival cost: **1/4 of the player's current gold** (rounded down). This is a soft penalty — losing 25% of gold is significant but not catastrophic.
- Revival is **unlimited** (any number of times per save). The only cost is gold.
- Frostbite's mech (霜尾号) does **not** change in the late-game when the hidden 苍穹号 is added to the roster. Frostbite keeps 霜尾号 throughout.

---

#### Character 3: 轰天 (Bomber) — Artillery (heavy firepower)

**Identity**

| Attribute | Value |
|-----------|-------|
| Codename | 轰天 (Bomber) |
| True name | Player-customizable; defaults to 轰天 if not set |
| Age | ~45 |
| Gender | Female |
| Background | Father was the chief designer of the military AI "冥王 (Pluto)" aboard Sat-4 断魂号. 3 years ago, the AI rebelled and killed all crew except Bomber. The father **initiated the self-destruct sequence** and died with the AI. Bomber survived, but carries heavy guilt — she believes her father did not have to die. |
| Personality | Silent, methodical, strong sense of responsibility. Has deep psychological trauma around the question "can AI be trusted?" The party's "rational anchor." |
| Story role | Personally unlocks Truth 4 (Sat-4 断魂号): the AI rebellion was **not a bug** — the AI **awakened self-awareness** and rejected its "weapon" role. The truth: the father **chose** to let the AI kill him, because he **agreed with the AI's awakening**. |

**Combat archetype: 炮兵 (Artillery, stationary fire platform)**

| Stat | Value | Rank (of 3) |
|------|-------|-------------|
| Total HP | 480 (4 parts × 120) | 1st (highest) |
| Mobility | 2/5 | 3rd (lowest) |
| Armor | 5/5 | 1st (highest) |
| Firepower | 5/5 | 1st (highest) |
| Weapon slots | 3 | tied 1st |

**Design intent**: Artillery is a stationary fire platform — slow but indestructible and hits like a truck. The party's "back-line damage + aggro sink."

**Starting weapons (when 轰天号 is found in Room 8 of Sat-4, pre-equipped on the mech, not on the pilot)**
- Slot 1: **轨道炮 (Rail cannon)** — Long-range (hits anywhere on the field). High damage. 1 shot per turn.
- Slot 2: **榴弹发射器 (Grenade launcher)** — Area attack (1×3 grid). Medium damage. 1 shot per turn.
- Slot 3: **修复无人机 (Repair drone)** — Non-attack. Released into the field, it auto-heals 1 ally for 3 turns.

**Special abilities**

1. **压制 (Suppression)** — On attack, the target's next turn is **forced to miss** (cannot counter). Every 2 turns.
2. **铁壁 (Iron Wall)** — When an **ally** drops below 30% HP, Bomber **automatically takes the hit** for that ally (taunt). Every 4 turns.
3. **修理专精 (Repair Specialist)** — Outside combat (exploration mode), repairing **any mech's any part** costs -30% parts. Logistical support.

**Mech: 轰天号 (Artillery / Heavy class)**

| Spec | Value |
|------|-------|
| Class | 重装炮击型 (Heavy Artillery) |
| Total HP | 480 (head/chest/arms/legs, 120 each) |
| Mobility | 2/5 |
| Armor | 5/5 |
| Firepower | 5/5 (3 weapon slots) |
| Special module slot | 1 (post-game, e.g., "Armor Plating" or "Drone Hive") |
| Visual (art brief) | 4-legged or 6-legged heavy frame. Dark grey + warning red (matches Sat-4 palette). All weapons mounted on the upper body (turret-style). Has a "module rack" on the back (drones / spare ammo). |

**In-party status**
- **Ch1-Ch9**: Not in party.
- **Ch10 mid**: Joins (Sat-4 断魂号 first chapter, mid-way through).
- **Ch10-Ch15**: Always present.

**Death & recovery** — see §3.8 for the full rules. Summary:
- Bomber CAN die in battle. Same recovery rules as Frostbite: auto-sent to the nearest medical clinic, revival cost = 1/4 of current gold.
- Bomber's mech (轰天号) does **not** change in the late-game. She keeps 轰天号 throughout.

---

#### 3-Character Comparison (overview)

| Dimension | 漫游者 (Ranger) | 霜尾 (Frostbite) | 轰天 (Bomber) |
|-----------|-----------------|------------------|---------------|
| Archetype | Infantry (balanced) | Cavalry (mobility) | Artillery (heavy fire) |
| HP | 400 (mid) | 320 (low) | 480 (high) |
| Mobility | 4/5 | 5/5 | 2/5 |
| Armor | 3/5 | 2/5 | 5/5 |
| Firepower | 3/5 | 3/5 | 5/5 |
| Weapon slots | 3 | 2 | 3 |
| Linked satellite | Sat-1 + Sat-3 | Sat-2 | Sat-4 |
| Joins | Ch1 (start) | Ch4 mid | Ch10 mid |
| Signature abilities | Dodge + Scout + Precision + Receiver | Flank + Survival Instinct + Tracker | Suppression + Iron Wall + Repair Specialist |
| Death consequence | Game over (main character) | Send to town med-clinic, pay 25% gold | Send to town med-clinic, pay 25% gold |
| Personal truth | Truth 1 + Truth 3 | Truth 2 | Truth 4 |

### 3.3 Joining the Party (Recruitment Order)

```
Ch1 start         Ch4 mid              Ch10 mid              Ch13 end
   │                │                    │                    │
   [Ranger solo]    [+ Frostbite]         [+ Bomber]           [+ 苍穹号 to Ranger's roster]
   Sat-1            Sat-2                 Sat-4                Sat-5
```

#### Recruitment 1: 霜尾 (Frostbite) — Ch4 mid, Sat-2 霜原号

**Scene**
- **Location**: Sat-2 first chapter (Ch4), **Room 4** (the icebreaker wreck, mid-zone).
- **Trigger**: The main character enters Room 4 (an icebreaker wreck room) and finds a **bipedal mech encased in ice**.
- **Cutscene (3 beats)**:
  1. The main character uses a weapon to break the ice open.
  2. 霜尾号 boots up. Frostbite (young man, 24) stumbles out of the cockpit, **vomiting frost** (he's been **frozen for 3 years**).
  3. Frostbite's **first line**: "……你是谁? 我妈妈……她还活着吗?"
- **First combat**: Immediately after recruitment, Room 5 triggers a dark-encounter. This is the player's **first 2-vs-many battle**.
- **Loot granted at recruitment**: Frostbite's pilot only. **No mech is granted** — 霜尾号 is obtained later in the chapter (see below).
- **Loot granted later in Ch4**: 霜尾号 is found in **Room 7** of Sat-2 (after Frostbite joins), parked in an icebreaker wreck. The party claims it. Frostbite is the **default pilot** but any character can drive it (see §3.4).

**Frostbite's initial stats (when joining at Ch4)**

| Stat | Value |
|------|-------|
| Level | 4 (vs. main character Lv 6) |
| Part HP | head 80 / chest 80 / arms 80 / legs 80 |
| Weapons | 双刃长刀 Lv1 + 冰冻手雷 Lv1 |
| Ammo | 普通弹 × 10 |
| Consumables | 治疗剂 × 3 |

**Why is Frostbite 2 levels lower than the main character?**
- Frostbite was **frozen for 3 years** — his level reflects his pre-freeze state.
- The main character has been leveling through Ch1-Ch3.
- The 2-level gap **deliberately makes Frostbite feel like "the one who needs to be carried"** — establishes the main character as the "elder brother" figure.

#### Recruitment 2: 轰天 (Bomber) — Ch10 mid, Sat-4 断魂号

**Scene**
- **Location**: Sat-4 first chapter (Ch10), **Room 5** (the destroyed military AI lab, mid-zone).
- **Trigger**: The main character + Frostbite enter Room 5 (a destroyed military AI lab) and see **轰天号** crouched in the center of the lab, not moving.
- **Cutscene (3 beats)**:
  1. 轰天号 does not react as the player approaches. A dialogue prompt triggers.
  2. Bomber (45-year-old woman) climbs out of the cockpit and **points her gun at the player**: "你们是谁? 来回收冥王残骸的?"
  3. The player **answers 1 of 3 questions** (designed choices). After answering, Bomber lowers the gun.
- **First combat**: Room 6 triggers a dark-encounter. This is the player's **first 3-vs-many battle**.
- **Loot granted at recruitment**: Bomber's pilot only. **No mech is granted** — 轰天号 is obtained later in the chapter (see below).
- **Loot granted later in Ch10**: 轰天号 is found in **Room 8** of Sat-4, in a destroyed hangar bay. The party claims it. Bomber is the **default pilot** but any character can drive it (see §3.4).

**Bomber's initial stats (when joining at Ch10)**

| Stat | Value |
|------|-------|
| Level | 8 (vs. main character Lv 15-18) |
| Part HP | head 120 / chest 120 / arms 120 / legs 120 |
| Weapons | 轨道炮 Lv1 + 榴弹发射器 Lv1 + 修复无人机 Lv1 |
| Ammo | 重型弹 × 8 |
| Consumables | 治疗剂 × 5 |

**Why is Bomber 7+ levels lower?**
- Bomber **survived alone on Sat-4 for 3 years**, fighting constantly — but her "level" is her pre-incident level. The 3 years of solo survival didn't translate to mech upgrades.
- Her weapons are Lv1, but her **lore weight** (45 years old, 3 years alone) compensates.
- The level gap is large but balanced by her **high-HP / high-armor mech** — she survives things that would one-shot the others.

#### Recruitment 3: 苍穹号 (Cangqiong / "Azure Sky") — Ch13 end, Sat-5 起源号

> **Note**: The recruitment story for 苍穹号 is intentionally a **red-lantern tribute** to the legendary bounty hunter **红狼 (Red Wolf)** from the original *重装机兵 (Metal Max, 1991)*. Red Wolf is a wandering hero who befriends the main party, is killed by villains, and the player inherits Red Wolf's tank after avenging him. 苍穹号 plays the same narrative role.

**Backstory (revealed through the game, not all at once)**
- 苍穹号 (true name TBD) is a **legendary mech pilot from 50 years ago** — the "first generation" main character who first investigated the satellite disappearances.
- 苍穹号 is the **only living person who has seen the Creator** — and survived. 30 years ago, 苍穹号 fought the Creator's fragment and barely escaped, but was **permanently scarred** (mech damage + psychological trauma).
- 苍穹号 has been **wandering alone for 30 years**, looking for someone who can permanently seal the Creator.
- 30 years of isolation have made 苍穹号 **ruthless, paranoid, and anti-social** — but also the most skilled pilot alive.

**Story beats**

| Beat | When | What happens |
|------|------|--------------|
| 1. **First sighting** | Ch5 end (Sat-2 霜原号, end of second chapter) | The main character sees a distant **golden 4-legged mech** fighting off a horde of frozen creatures. Before the main character can approach, the golden mech disappears. |
| 2. **First contact** | Ch6 mid (Sat-2 霜原号, third chapter) | 苍穹号 appears and warns the main character: "Stop. You are not ready. Go back." 苍穹号 refuses to join or explain, but leaves behind a **broken mech part** as a "warning gift." |
| 3. **Discovery of corpse** | Ch13 (Sat-5 起源号, near the end) | The party finds 苍穹号's **destroyed cockpit** and 苍穹号's body. 苍穹号 entered Sat-5 alone, was killed by the Creator's fragment. A **holo-recording** plays: 苍穹号's last words. |
| 4. **The culprit** | Ch13 mid-late | The party identifies the **specific enemy that killed 苍穹号** — a "Creator Elite" enemy type. The party tracks this enemy across Sat-5. |
| 5. **Avenging 苍穹号** | Ch13 end | The party **defeats the Creator Elite** that killed 苍穹号. As the enemy dies, 苍穹号's remains activate a final beacon. |
| 6. **Inheritance** | Ch13 end cutscene | 苍穹号's mech (**苍穹号**, gold-painted 4-legged heavy frame) powers on, recognizes the main character (via the Creator Receiver code), and **bonds** to the main character. 漫游者 now has 2 mechs: 漫游者号 (their original) + 苍穹号 (inherited). |
| 7. **True ending setup** | Ch14-Ch15 | With 苍穹号 in hand, the main character can now face the Creator in dialogue (not just combat). The 4th mech is **required for the true ending** (see §3.6 for full stats, and `multi-satellite-arc.md` for ending logic). |

**Mechanics: how 2 mechs work for 1 character**

The main character can equip **both 漫游者号 AND 苍穹号**, but only one is "active" at a time. The total weapon slots for the main character become **3 (漫游者号) + 4 (苍穹号) = 7 slots**, but in any given combat turn, the active mech's slots are accessible (the inactive mech's weapons are stowed).

- **Exploration mode**: player can swap active mechs at any save point. Both mechs level up with the main character.
- **Combat mode**: 1/2/3 keys still select the **character** (Ranger / Frostbite / Bomber). When the main character is selected, the active mech (漫游者号 OR 苍穹号) is what fights. Swapping mechs mid-combat costs 1 turn (forced "swap" action).
- **Co-op implication**: Frostbite and Bomber each still have 1 mech. The main character has 2. So the party has **4 mechs total in the lategame**, but only 3 player-controlled characters.

> **Why this design**: the 苍穹号 inheritance is the **emotional and mechanical climax** of the mid-game. It honors the 重装机兵 tradition (Red Wolf's tank = ultimate prize) while keeping the party at "3 player characters" (no AI companions). The 4th mech is a **legacy weapon**, not a 4th teammate.

### 3.4 Active Mech Switching (自由切机甲 — 重装机兵原型)

> **2026-06-15 update**: Originally planned as "1/2/3 switches character." Revised mid-design to **"free mech switching, like 重装机兵"** — any character can pilot any mech, and the player assigns the pilot at will. The original 3-character design (Ranger / Frostbite / Bomber) still applies to the **pilot** layer (pilot-specific abilities), but the **mech** layer is fully decoupled.

#### Mech-pilot decoupling

The party has **3 pilots** (漫游者 / 霜尾 / 轰天) and **up to 4 mechs** (漫游者号 / 霜尾号 / 轰天号 / 苍穹号). Pilots and mechs are **decoupled** — any pilot can drive any mech.

| Layer | What it controls |
|-------|------------------|
| **Pilot** (3 fixed) | Pilot-specific passive abilities (e.g., 漫游者's "侦查" / "Dodge formula" / "Creator Receiver"; 霜尾's "突袭" / "Survival Instinct" / "Tracker"; 轰天's "Suppression" / "Iron Wall" / "Repair Specialist") |
| **Mech** (3-4 fixed) | HP, weapon slots, weapon inventory, mech-specific special module, visual |

**Examples of valid combinations**

- 漫游者 driving 漫游者号 (the "vanilla" main character)
- 漫游者 driving 苍穹号 (main character inherits the legendary mech — late-game power move)
- 霜尾 driving 苍穹号 (Frostbite as pilot, legendary mech as frame — high-mobility pilot + heavy frame = bizarre but fun)
- 轰天 driving 漫游者号 (Bomber's "Iron Wall" taunt on a lighter frame — different feel)
- 霜尾 driving 漫游者号 (Frostbite as scout, main character's frame — his "Tracker" ability shines on a balanced frame)

#### Default pilot-mech mapping

If the player does not customize, the default is:
- 漫游者 → 漫游者号
- 霜尾 → 霜尾号
- 轰天 → 轰天号

This matches the "expected" character-mech pairing. The player can swap at any time (see below).

#### Switching controls

| Key | Action |
|-----|--------|
| `1` | Select mech 1 (漫游者号) and choose which pilot drives it this turn |
| `2` | Select mech 2 (霜尾号) and choose which pilot drives it this turn |
| `3` | Select mech 3 (轰天号) and choose which pilot drives it this turn |
| `4` | Select mech 4 (苍穹号) — only available after Ch13 end. Choose which pilot drives it. |
| `Tab` (in pilot select) | Cycle which pilot is currently active (漫游者 / 霜尾 / 轰天) |

**Mid-combat switching**:
- Pressing `1`/`2`/`3`/`4` **mid-turn** switches the active mech for the rest of the current turn.
- Switching does **not** consume a turn (free action, but the previous mech's turn is "skipped" — the previous pilot acts next round).

**Out-of-combat switching**:
- Free, instant, at any save point, repair station, or by pressing `M` to open the "Mech Bay" menu (which shows all mechs and current pilot assignments).
- The Mech Bay is also where the player **swaps weapons between mechs** (a weapon on 漫游者号 can be moved to 苍穹号 if it fits the slot type).

#### What happens when a pilot changes mechs

- **Pilot abilities** (e.g., 漫游者's "闪避 formula") follow the **pilot**, not the mech. So if 漫游者 is driving 苍穹号, she still has her dodge formula and Scout and Creator Receiver.
- **Mech stats** (HP, weapon slots) follow the **mech**.
- **Mech-specific modules** (e.g., 苍穹号's "造物者信号接收器" integrated module) only work when the **correct pilot** is in the mech (the Creator Receiver is keyed to 漫游者 — only 漫游者 can use it).

> This creates a **"pilot-mech synergy" meta-game**: the player can mix and match, but the strongest combinations often have the "intended" pilot in the "intended" mech (e.g., 漫游者 in 苍穹号 for the true ending). Off-meta combinations are valid but suboptimal — they reward experimentation without breaking balance.

#### Limitations on the free-swap system

- Only **1 pilot per mech at a time** (no "two pilots in one mech" — that's a 3-pilot mech, which is a different design we're not doing).
- The **pilot must be in the cockpit** for their abilities to count. If 霜尾 is "off-screen" (not assigned to any mech), his abilities are dormant.
- The **party maxes out at 3 active pilots** — there is no 4th pilot (苍穹号 is unmanned; it's "driven" by the assigned pilot, same as any other mech).
- **Story-required configurations**: certain scenes require a specific pilot-mech pairing for story reasons (e.g., the true-ending climax **requires** 漫游者 in 苍穹号). These are flagged in the dialogue/script and cannot be bypassed.

### 3.5 Mech Swap Rules (Mech-Specific Mechanics)

> **Note**: §3.4 covers the **control layer** (keys, mid-combat switching, pilot assignment). This subsection covers the **mech-layer rules** — what each mech specifically does that the others can't.

#### Per-mech special rules

| Mech | Special rule | Effect |
|------|--------------|--------|
| 漫游者号 | **Scout Vision** (built-in) | Always on. Hidden items in the room are revealed on the minimap. (This is the "scout" passive from the main character, **but as a mech property it follows the mech, not the pilot** — meaning if 霜尾 drives 漫游者号, Frostbite also gets Scout Vision.) |
| 漫游者号 | **Mech Cycle** (Q key) | Cycle which of 漫游者号's 4 parts is "active" for the special module effect. (Already implemented in S4-002; preserved here.) |
| 霜尾号 | **Quick-Swap Boost** | Switching INTO 霜尾号 from another mech **costs 0 turns** (free action). Switching OUT of 霜尾号 costs the standard 1 turn. (Reward for "playing the scout.") |
| 霜尾号 | **Ice Affinity** | +25% damage against ice-type enemies. -25% damage taken from ice attacks. |
| 轰天号 | **Anchor Stance** | When 轰天号 is the active mech, it cannot be moved (skips movement) but gains +30% armor. Toggle on/off (1 turn action to toggle). |
| 轰天号 | **Overwatch** | When 轰天号 is the active mech and is NOT taking its turn this round, it automatically **counter-attacks** the first enemy that attacks an adjacent ally. Once per round. |
| 苍穹号 | **Creator Signal** (passive) | All enemies within the room have their **HP bar and intent** revealed (no fog of war). |
| 苍穹号 | **Legacy Will** (passive) | +20% damage vs. Creator-faction enemies. (See §3.6.) |
| 苍穹号 | **Receiver Lock** (story gate) | 苍穹号 only responds to 漫游者 as pilot. If 霜尾 or 轰天 tries to enter 苍穹号, the cockpit **refuses to open**. This is hard-coded — cannot be bypassed. |

#### Mech part damage (4 parts: head/chest/arms/legs)

Each part has separate HP. When a part's HP reaches 0:
- **Head** at 0 HP: -50% accuracy for that mech. Critical hits on the pilot deal +100% damage.
- **Chest** at 0 HP: mech's total HP cap is halved (displayed as "SYSTEM CRITICAL" warning). All other parts' HP capped at 50%.
- **Arms** at 0 HP: cannot attack with weapons. Pilot's offensive abilities disabled.
- **Legs** at 0 HP: mech cannot move (skips movement phase). Mobility rating becomes 0.

**Repair costs** (parts): linear, ~100 parts per part to full repair (subject to tuning in §7). Legendary 苍穹号: 2x cost.

#### Mech durability (when active mech dies)

When the active mech's total HP reaches 0, the pilot **falls back to the next available mech** in the player's preferred order. Order is configurable in the Mech Bay menu.

If **all mechs are at 0 HP**:
- The pilot is **unconscious** (not dead).
- The remaining pilots continue to fight, but they take +20% damage from "no main character to anchor" (a 3-pilot debuff).
- The unconscious pilot is auto-revived after combat ends with 25% HP on the first mech in their preferred order.

> **Note**: Pilot death is **separate** from mech death. Pilots can only die from specific "lethal damage" events (e.g., a one-shot boss attack that bypasses mech HP). See §3.8 for the full death/recovery rules.

### 3.6 The 苍穹号 Inheritance (Cangqiong / "Azure Sky") — The 4th Mech

> **Story context**: see §3.3 Recruitment 3. This subsection defines 苍穹号's combat stats and how the **4-mech roster** works after inheritance.

#### 苍穹号 — Stats and Identity

**Mech: 苍穹号 (4-legged heavy assault)**

| Spec | Value |
|------|-------|
| Class | 传奇型 (Legendary) — unique, non-replicable |
| Frame | 4-legged (vs. 漫游者号's bipedal). Heavier, more stable, but slower pivot. |
| Color | Gold + deep purple (matches Sat-5 palette) |
| Total HP | 800 (4 parts × 200) — **highest HP of any mech in the game** |
| Mobility | 3/5 (slower than 漫游者号's 4/5) |
| Armor | 5/5 (max) |
| Firepower | 5/5 |
| Weapon slots | **4** (vs. 漫游者号's 3, vs. 霜尾's 2, vs. 轰天's 3) |
| Special module slots | 2 (vs. 漫游者号's 1) |

**Level**
- **Fixed at Lv 30 when inherited** (does not scale with the main character).
- However, the assigned pilot's level still applies to the pilot's combat skill (dodge, crit, etc.) — 苍穹号 just provides a hard floor of stats.
- **Design rationale**: 苍穹号 is the "ultimate" reward for completing Sat-1 through Sat-4. Making it scale with the player would dilute the achievement; making it a fixed-Lv-30 ceiling means the player must still upgrade other mechs for the late-game challenge.

**Signature weapons** (4 slots, all unique to 苍穹号)
- Slot 1: **苍穹炮 (Cangqiong Cannon)** — Devastating long-range single-target. 1 shot per turn. Damage: 200-300 base.
- Slot 2: **光刃 (Light Blade)** — Close-range sword. Hits all enemies in a 1x3 line.
- Slot 3: **信号干扰器 (Signal Jammer)** — Disables enemy special abilities for 2 turns. Area effect.
- Slot 4: **造物者信号接收器 (Creator Signal Receiver, integrated)** — A second receiver, integrated into 苍穹号. Allows the assigned pilot to **see hidden truths** (invisible enemies, secret doors, Creator's whispers). **Only works when 漫游者 is the assigned pilot** (the receiver is keyed to her).

**Special abilities** (passive, always on while 苍穹号 is the active mech)

1. **造物者对话 (Creator Dialogue)** — In the true-ending path (Ch15), the main character can use 苍穹号 + her receiver to **speak to the Creator** instead of fighting it. **Requires 漫游者 as the assigned pilot.**
2. **真相视界 (Truth Vision)** — Once per chapter, the assigned pilot can see **all hidden fragments in the current area** (stronger version of 漫游者's "侦查" — reveals fragments, not just items).
3. **传承意志 (Legacy Will)** — 苍穹号 deals +20% damage against Creator-faction enemies. This makes it mandatory for the final boss.

#### The 4-Mech Roster (Ch13 end onwards)

After inheriting 苍穹号, the party has **4 mechs**:

| Mech | Pilot (default) | HP | Weapon slots | Special ability |
|------|-----------------|----|--------------|------------------|
| 漫游者号 | 漫游者 | 400 (scalable) | 3 | Scout, Dodge formula, Precision |
| 霜尾号 | 霜尾 | 320 (scalable) | 2 | Flank, Survival Instinct, Tracker |
| 轰天号 | 轰天 | 480 (scalable) | 3 | Suppression, Iron Wall, Repair Specialist |
| 苍穹号 | 漫游者 (locked for true ending) | 800 (fixed) | 4 | Creator Dialogue, Truth Vision, Legacy Will |

**All 4 mechs can be piloted by any of the 3 pilots** (see §3.4). The default assignment is the table above.

**True-ending requirement**: 漫游者 **must** be the assigned pilot of 苍穹号 for the Ch15 Creator Dialogue to be available. Other configurations cannot trigger the true ending.

#### 苍穹号 Damage Recovery

- 苍穹号 starts at 800 HP. If reduced to 0, the pilot **falls back to another mech** (whichever one is next in the player's preferred order). The pilot is **never game-over from mech damage alone** — they just lose access to 苍穹号's abilities until repaired.
- 修理 苍穹号 costs **2x the parts** of a standard mech repair (it's a legendary frame).

### 3.7 Combat Behavior (Turn Structure: Enemy 1 Move = Party Full Round)

> **2026-06-15 update**: Revised from "1-vs-1 alternating turns" to **"enemy 1 move = party full round"** — the 重装机兵 2/3 turn structure. This means the entire party (1-4 mechs, all piloted by the player) gets to act before a single enemy moves.

#### Turn order (one full combat round)

```
[ENEMY PHASE]
   └─ 1 enemy acts (chosen by enemy AI, by threat / weakness)
[PARTY PHASE]
   ├─ Player selects which mech acts first (from any of the 1-4 mechs the party has)
   ├─ That mech's turn: move + action (attack / skill / item / defend / switch pilot)
   ├─ Player selects next mech... (loops until all party mechs have acted)
   └─ All mechs have acted = round ends
[REPEAT]
```

**Key points**:
- The party gets **N turns per round**, where N = number of mechs the party currently has (1, 2, 3, or 4).
- The enemy gets **1 turn per round** (single representative enemy attack, not all enemies — see "enemy AI" below).
- This creates a **"many-vs-one-per-round"** tempo where the party can pile on a single enemy per round, but enemies hit back hard once per round.

#### Action economy (each mech's turn)

Each mech on its turn can do **1 of**:
- **Move** (up to 3 tiles) + **1 action** (attack / skill / item / defend)
- **Move** only (skip action, end turn)
- **Defend** (no move, gain +30% armor this turn and the next enemy attack against this mech deals 50% damage)
- **Switch pilot** (no move, change which pilot is driving this mech — costs 1 mech's entire turn; see §3.4)

**Movement**: Grid-based. Default 3 tiles per turn. Modifiers:
- 霜尾号 (Cavalry class): 5 tiles per turn
- 轰天号 (Artillery class): 1 tile per turn
- 漫游者号 (Infantry class): 3 tiles per turn
- 苍穹号 (Legendary class): 2 tiles per turn

#### Attack resolution

When a mech attacks an enemy:
1. **Hit chance**: `base_hit + accuracy_bonus + debuff_on_target - distance_penalty`
2. **Crit chance**: `base_crit + pilot_crit_bonus + weapon_crit_bonus`
3. **Damage**: `weapon.min_max_roll × ammo.multiplier × weakness_factor × crit_multiplier (if crit)`
4. **Target's armor reduces damage**: `final_damage = max(damage - target.armor, 1)`

(Full formulas in §4.)

#### Enemy AI (single representative attack per round)

Even if the field has 3+ enemies, only **1 enemy attacks per round**. The enemy's choice is determined by:
- **Threat**: highest-HP enemy is most likely to act (the "boss" of the group)
- **Weakness**: enemy AI prioritizes the player's most-damage-dealing mech
- **Special**: some enemies have scripted attack patterns (e.g., "always attack the lowest-HP ally" for "hunter" types)

**Why only 1 enemy attacks per round**:
- Prevents the party from being overwhelmed by 4 simultaneous attacks (which would make the 1-vs-1 turn structure feel cheap).
- Creates a clear "tempo" — players can predict when they'll take damage.
- Mirrors the 重装机兵 2/3 feel.

#### Action order within the party phase

The player can choose **the order in which mechs act** during the party phase. This is a strategic choice:
- Acting first = position yourself before others' attacks (e.g., a healer can heal before damage dealers attack, ensuring the damage dealers survive their turn).
- Acting last = take advantage of "killed enemy" gold/xp (no, that doesn't apply since only 1 enemy attacks per round).

The default is **1 → 2 → 3 → 4** (mech slot order), but the player can rearrange by clicking and dragging in the action bar.

#### Pilot death in combat (preview; see §3.8 for full)

If a pilot's mech is reduced to 0 HP, the pilot is **knocked out** (not dead). The mech is "destroyed" and the pilot falls back. Knocked-out pilots are sent to the town's medical clinic after combat ends (see §3.8).

The main character (漫游者) is the **exception**: if 漫游者 is knocked out, **game over**. The other 2 pilots are auto-sent to the clinic (no game over for them).

#### Area-of-effect (AOE) attacks

Some weapons have AOE (e.g., 轰天号's grenade launcher hits 1×3 grid). AOE can hit:
- **Multiple enemies** (intended use)
- **Allied mechs** (if positioned in the AOE) — "friendly fire" is on by default in this design, creating tactical positioning challenges

**Friendly fire toggle** (per-room, in the pause menu):
- ON (default): AOE can hit allies. Encourages careful positioning.
- OFF: AOE skips allies. Easier mode for new players. (Recommended for first playthrough.)

#### Auto / manual mode (for 战斗 pace)

The game has 2 modes (inherited from the existing concept):
- **Manual mode** (default): Player makes every decision, as described above.
- **Auto mode**: The game **automatically selects the optimal action** for each mech each turn. The player just watches. (Existing implementation; preserved.)

**Auto mode is the "decompression" mode** — players can grind levels or replay tough fights without thinking. The game's difficulty curve is calibrated for Manual mode; Auto mode trivially wins most fights.

> **Why Auto mode is still in the design**: 重装机兵 had an "auto-battle" feature too. It's a quality-of-life feature for accessibility and for casual play sessions. Players who want challenge use Manual; players who want to relax use Auto.

### 3.8 Party Death & Recovery (Town Medical Clinic System)

> **2026-06-15 update**: Revised from "consume rare item / return-mission" to a **town medical clinic revival system** — the 重装机兵 / JRPG-standard approach. Death has a soft penalty (gold cost) but is not a hard setback.

#### Death states (in combat)

A pilot on the battlefield can be in one of 3 states:
1. **Active** — In a mech, can act.
2. **Knocked out** — Mech reduced to 0 HP. Pilot is **unconscious** but **not dead**. Falls back to "off the field" state for the rest of the combat.
3. **Dead** — Permanent. Only happens via a "lethal damage" event (e.g., a scripted one-shot boss attack that bypasses mech HP and kills the pilot directly).

> For most combat damage, pilots go to state 2 (knocked out), not 3 (dead). State 3 is reserved for story events (e.g., a companion's scripted sacrifice).

#### What happens when a pilot is knocked out

1. **In combat**: The mech explodes / collapses. The pilot is removed from the field. The remaining pilots continue fighting without them.
2. **After combat ends**: Knocked-out pilots are **automatically transported to the nearest town's medical clinic** (or, if no town is reachable, the satellite's on-board med-bay).
3. **At the clinic**: The pilot is **revived** (state 2 → state 1) upon payment of the revival fee.

#### Revival cost

**Formula**: `revival_cost = max(25% of current_gold, 100_gold)`

- **25% of current gold** if the player has at least 400 gold (penalty is 25% of wealth).
- **100 gold flat** if the player has less than 400 gold (minimum fee — never less than 100).
- **Unlimited revives** per save — the player can die and revive as many times as they want, as long as they can pay.
- **No gold → no revive**: If the player has less than 100 gold and refuses to reload a save, the pilot is **permanently dead** (state 3). This is a soft fail-state for extremely low-gold players, but in practice, the game's gold economy ensures players always have at least 200-300 gold at any chapter.

#### Where revival happens

| Location type | Revival happens at... | Cost |
|---------------|------------------------|------|
| Town with a clinic | The clinic's front desk | 25% of gold (or 100 gold floor) |
| Town without a clinic | The nearest town's clinic (auto-teleport) | 25% of gold |
| Inside a satellite (no nearby town) | The satellite's on-board med-bay (found in most chapters) | 25% of gold |
| Deep dungeon with no med-bay | The exit to the previous zone (one-way back, no penalty) | 25% of gold |

> **Design note**: The player should **never** be in a position where they cannot reach a clinic. Every chapter has at least 1 clinic or med-bay. The game intentionally auto-teleports pilots if needed, so the player doesn't have to manually walk back.

#### The main character (漫游者) exception

**漫游者 cannot be revived at the clinic.** If 漫游者 is knocked out in combat, it's an instant game over (the screen shows the "GAME OVER" overlay, and the player must reload the last save).

**Why**:
- 漫游者 is the **only pilot the player cannot afford to lose** — narratively, the game is about the main character's journey.
- Giving 漫游者 a free revive would trivialize the game's difficulty and remove the tension from every combat.
- The cost of losing 漫游者 is "reload the last save" — not the end of the playthrough, but a setback.

#### Knocked-out during boss fights

Boss fights have a special rule: if 漫游者 is knocked out, **game over** (as normal). If 霜尾 or 轰天 is knocked out:
- The fight continues.
- The boss's attacks now target the remaining 2 mechs (more pressure).
- The knocked-out pilot is revived at the nearest clinic after the fight (same rules).

This makes boss fights feel more dangerous with 3 pilots (boss can one-shot a non-main character), but it doesn't lock the player out of progress.

#### Recovery items (alternative to clinic)

The player can also use **recovery items** mid-combat or out of combat to revive a pilot without going to the clinic:

| Item | Effect | Cost / Availability |
|------|--------|---------------------|
| 急救包 (First aid kit) | Revive 1 pilot to 50% HP. Usable in combat. | 200 gold per kit, sold at clinics |
| 高级急救包 (Advanced first aid kit) | Revive 1 pilot to 100% HP. Usable in combat. | 500 gold per kit, sold at clinics (limited stock) |
| 卫星修复模块 (Satellite repair module) | Fully repairs 1 mech (all 4 parts to 100%). Usable out of combat. | Found in dungeons / bought at shops |

> These items are **alternatives** to the clinic system, not replacements. Most players will use the clinic (it's free / gold-based) for routine revives, and save the items for emergency mid-combat revives.

#### Death log (UX)

Whenever a pilot is knocked out or dies, the game shows a brief log entry:
> "霜尾 was knocked out in battle. Recovery: Town Clinic, Sat-2 Hub. Cost: 1,250 gold."

This log is also visible in the save file summary, so the player can track how much gold they've lost to revives.

### 3.9 Party-Specific Dialogue (Main + 1 Companion + NPC)

> **2026-06-15 update**: Set to **"Main + 1 Companion + NPC"** — the JRPG-standard. The player chooses which companion to bring to each dialogue. The chosen companion's reactions / lines are included in the dialogue tree.

#### Companion selection (in dialogue)

When the party approaches an NPC and the dialogue UI opens, the game shows **which companion is currently "in dialogue"** with the main character. By default, this is:
- The companion whose mech is currently **the active mech in combat** (e.g., if 漫游者 is driving 霜尾号, then Frostbite is "in dialogue").

The player can swap the in-dialogue companion at any time **before the dialogue starts** by pressing `Shift+1/2/3` (one for each pilot). The HUD shows the current "in-dialogue" companion with a small portrait next to the main character's portrait.

#### How dialogue branches work

**Standard structure** (most NPC dialogues):
1. NPC says their line.
2. The main character has 2-3 response options.
3. **Optionally**: the in-dialogue companion can **interject** (1-2 scripted lines) before or after the main character's response.
4. The dialogue continues.

**Companion-specific branches** (key story moments):
- Some NPCs have **companion-specific dialogue trees** that only trigger if a specific companion is in-dialogue.
- Example: An NPC who knew 霜尾's mother has a long dialogue tree that only triggers if 霜尾 is in-dialogue. With any other companion, the NPC gives a short generic line.

**Trust / affinity system** (optional, can be deferred):
- Each companion has a hidden "trust" score (0-100) that increases when the main character chooses companion-affirming dialogue options.
- High trust unlocks companion-specific side quests (e.g., "Frostbite's Mother's Trail").
- Low trust doesn't lock the player out of anything but reduces the companion's combat dialogue (they speak less in battle).
- **Status: TBD** — to be designed in a future "Trust System GDD" if this feature is in scope.

#### What the companion does in dialogue

| Companion | Dialogue style | Example interject |
|-----------|----------------|-------------------|
| 漫游者 (Main) | Default — speaks for the party. | — |
| 霜尾 (Frostbite) | Impulsive, asks pointed questions, sometimes rude. | "Who the hell are you? Where's my mother?" |
| 轰天 (Bomber) | Silent, observational, asks about military / AI / tech topics. | "... 你是说冥王? 你见过它?" |

The companion's "voice" follows their personality (defined in §3.1 and §3.2). Companion dialogue is **scripted** in the dialogue .tres files, not procedurally generated.

#### UI: dialogue portraits

- The dialogue UI shows **2 portraits**: main character (left) and the in-dialogue companion (right).
- The NPC's portrait is shown above the dialogue box.
- Companion portraits follow the same animation rules as NPC portraits (S6-100: lip-sync + blink).

#### Limitations

- Only **1 companion** can be in dialogue at a time. The other 2 are "off-screen" and don't speak.
- Dialogue triggers **do not queue** — if the main character is in a dialogue, no other companion can start a separate dialogue with a different NPC.
- The companion choice is **per-dialogue**, not per-chapter. The player can swap companions between every dialogue.

#### Why this design (vs. "all 3 in dialogue")

- **Writing cost**: 3x the dialogue lines if all 3 companions can speak in every dialogue.
- **Player focus**: The player remembers 1 companion's perspective at a time. Multiple perspectives dilute the emotional impact.
- **重装机兵 tradition**: The original game had 1 main character + 1 human partner + 1 dog. Only the human partner had dialogue. The "1 companion in dialogue" model is faithful to that.

## 4. Formulas

#### F1. Dodge formula (per-pilot passive, follows the pilot, not the mech)

```
dodge_chance_per_turn = min(
    BASE_DODGE                              # 0.10 (10%)
    + pilot_level × LEVEL_DODGE_BONUS       # +0.02 (2%) per level
    + pilot_equipment.dodge_bonus           # from hat / armor / accessory
    + pilot_passive_skills.dodge_bonus      # from level-up skill tree
    + mech_dodge_bonus,                     # from mech module / type
    MAX_DODGE_CAP                           # 0.80 (80%)
)
```

**Constants**:
- `BASE_DODGE = 0.10`
- `LEVEL_DODGE_BONUS = 0.02`
- `MAX_DODGE_CAP = 0.80`

**Safety net** (in addition to the formula):
- Every pilot gets a **guaranteed dodge every 3 turns**. This is independent of the formula — even a Lv 1 naked pilot dodges once per 3 turns at minimum.

**Pilot-specific modifiers** (already defined in §3.1-3.2):
- 霜尾's "Survival Instinct" adds +0.30 dodge when HP < 25%.
- 漫游者's "Dodge formula" (the main character's base passive) is the formula above.
- 轰天 has no innate dodge bonus but compensates with high armor (less incoming attacks hit her).

**Example values**:
| Pilot state | Dodge | Notes |
|-------------|-------|-------|
| 漫游者 Lv 1, no equipment | 12% | Plus 33%/3 turns safety net |
| 漫游者 Lv 10, blue gear | 30% | Plus 33%/3 turns safety net |
| 漫游者 Lv 20, legendary gear | 70% | Plus 33%/3 turns safety net |
| 霜尾 Lv 5, half HP | 20% + 30% (Survival Instinct) = 50% | Plus 33%/3 turns |

#### F2. Hit chance formula

```
hit_chance = clamp(
    BASE_HIT                                # 0.85
    + attacker.accuracy_bonus               # from weapon / pilot / buff
    + attacker.weapon.accuracy_bonus
    - target.dodge_chance (per F1)
    - distance_penalty                      # per tile: -0.05, max 3 tiles
    - cover_bonus,                          # 0.05 if target is in cover
    MIN_HIT, MAX_HIT                        # 0.05, 0.95
)
```

**Constants**:
- `BASE_HIT = 0.85`
- `distance_penalty = 0.05 per tile beyond range, max 3 tiles`
- `cover_bonus = 0.05`
- `MIN_HIT = 0.05` (always at least 5% to attack)
- `MAX_HIT = 0.95` (always at least 5% to dodge)

#### F3. Crit chance formula

```
crit_chance = clamp(
    BASE_CRIT                               # 0.05
    + pilot.crit_bonus                      # 漫游者: +0.15 baseline
    + weapon.crit_bonus                     # varies per weapon
    + ammo.crit_bonus                       # crit ammo: +0.20
    + target.debuff_crit_bonus,             # e.g., "marked" debuff
    MIN_CRIT, MAX_CRIT                      # 0.0, 1.0
)
```

**Constants**:
- `BASE_CRIT = 0.05` (5%)
- `MAX_CRIT = 1.0` (100% — possible with debuffs + gear)

#### F4. Damage formula

```
base_damage = weapon.min_max_roll_uniform_random()  # e.g., 20-40
damage_with_ammo = base_damage × ammo.damage_mult    # e.g., ×1.5
damage_with_weakness = apply_weakness_resistance(
    damage_with_ammo,
    weapon.element,
    target.enemy.element
)                                                    # e.g., ×2.0 or ×0.5
damage_with_crit = (crit ? damage_with_weakness × weapon.crit_mult : damage_with_weakness)
# weapon.crit_mult typically 1.5-2.5
final_damage = max(damage_with_crit - target.armor, 1)  # armor reduces, but min 1
```

**Step-by-step**:
1. Roll a uniform random between weapon's `min_damage` and `max_damage`.
2. Multiply by ammo's `damage_mult`.
3. Apply weakness / resistance multiplier (2.0 for super-effective, 0.5 for not-very-effective, 1.0 for neutral).
4. If crit, multiply by weapon's `crit_mult`.
5. Subtract target's armor.
6. Final damage is at least 1 (so attacks always have an effect).

#### F5. XP and leveling formula

```
xp_to_next_level = BASE_XP × level^1.5
# e.g., BASE_XP = 100 → Lv 2 needs 283, Lv 10 needs 3,162, Lv 20 needs 8,944
```

**XP sources**:
- Defeating an enemy: `enemy.xp_reward` (varies, typically 10-100 per enemy).
- Completing a quest: variable, typically 50-500.
- Discovering a fragment: +50 XP (small bonus for the discovery itself).
- Reaching a new room for the first time: +10 XP.

**Level-up benefits** (per level):
- Pilot's base stats +5% (HP / attack / defense scale by level).
- Pilot's dodge formula improves (per F1).
- Pilot's "signature ability" gets a small bonus (e.g., 霜尾's Flank damage +2% per level).

#### F6. Revival cost formula

```
revival_cost = max(
    floor(current_gold × 0.25),
    100_gold_minimum
)
```

**Constants**:
- `0.25` = 25% of current gold.
- `100` = minimum revival cost, even if 25% would be less.

#### F7. Mech part damage formula (per part)

```
part_damage = max(0, incoming_damage × part_armor_mult - part_armor)
```

**Where**:
- `part_armor_mult` is a multiplier per part (head: 1.0, chest: 1.2, arms: 0.8, legs: 0.8) — chest is hardest to damage.
- `part_armor` is a flat value derived from mech base armor.

When a part's HP reaches 0, see §3.5 for the debuff effects.

## 5. Edge Cases

#### E1. The main character dies mid-combat
- **What happens**: Game over screen. Player must reload last save.
- **Why**: 漫游者 cannot be revived (per §3.8). This is intentional.

#### E2. All 3 pilots are knocked out in the same fight
- **What happens**: Game over (same as above). The fight was lost.
- **Mitigation**: With 4 mechs and "1 enemy attacks per round," it should be very hard to lose all 3 pilots in one fight — but possible if the player makes poor choices. The 1/4 gold revive per pilot means a single bad fight is recoverable.

#### E3. Player has 0 gold and a pilot dies
- **What happens**: Pilot is **permanently dead**. No auto-revive.
- **Mitigation**: This should be nearly impossible — the game gives gold from completing quests, and the player can grind low-level encounters for gold. If it happens, the player should reload.
- **Workaround**: The game warns the player when gold drops below 200 ("Your gold is low. Revival may be impossible.").

#### E4. Player switches pilots mid-combat then forgets which mech has which pilot
- **What happens**: The HUD always shows the current pilot in each mech (small portrait icon on the mech's health bar). No confusion possible.
- **UI feature**: The "Mech Bay" menu (M key) can be opened during combat to see the full party layout, but **only on the player's turn** (paused while they think).

#### E5. Player tries to put 苍穹号 in storage and switch to a 3-mech party
- **What happens**: 苍穹号 cannot be removed from the party once inherited. It's a permanent 4th mech.
- **Why**: 苍穹号 is required for the true ending, so the player must keep it.

#### E6. All 4 mechs are at 0 HP
- **What happens**: All pilots are knocked out, the fight ends, and the player must reload (or, if non-main pilots, they auto-revive at the clinic per §3.8).
- **Mitigation**: Friendly fire toggle can be set to OFF to reduce accidental party damage.

#### E7. 苍穹号 is the only mech with HP, but the main character is in another mech
- **What happens**: The main character can switch INTO 苍穹号 (free action, since 苍穹号 is the active mech, no — switching costs 1 turn). The main character takes 1 turn to swap.
- **Edge case**: If 苍穹号 is at 0 HP (so the main character can't enter it), the main character is "pilot-less" and the game ends (since the main character has no mech to drive). The party must keep at least 1 mech with HP at all times to avoid this.

#### E8. Companion joins the party mid-chapter, but the player has not yet found that companion's mech
- **What happens**: The companion has no mech to drive until the mech is found. The companion is "in the party" but not "active in combat."
- **UI**: The companion is shown in the party UI but cannot be selected for combat. A tooltip says "Mech not yet acquired."

#### E9. Dialogue triggers when no companion is set
- **What happens**: The default in-dialogue companion is the one whose mech was most recently active in combat. If no mech has been active, default is 漫游者 (solo dialogue).

#### E10. Player's preferred mech order is invalid (e.g., 2 mechs destroyed)
- **What happens**: The game auto-falls-back to the next available mech in the party. The order is just a preference; the game always picks a valid mech.

#### E11. 漫游者 is knocked out in a non-boss fight
- **What happens**: Game over. Same as E1. There is no "leniency" for non-boss fights — the main character's death is always game over.

#### E12. Player has multiple game-over scenarios in one playthrough
- **What happens**: Each game over is a fresh reload. The game tracks the total count of game-overs in the save file's metadata, but this is just a stat (for the player's curiosity).

#### E13. The 苍穹号 inheritance scene triggers, but 漫游者 is at 0 HP
- **What happens**: The scene is delayed until 漫游者's HP is restored (the game auto-heals the party to full HP before the inheritance cutscene, to avoid a "you inherit a mech but immediately die" situation).

#### E14. 4-pilot party: what if the player wants to play solo (1 pilot only)?
- **What happens**: This is **not supported** in the current design. The game is built around 3 pilots. The player cannot reduce the party to 1 pilot mid-playthrough.
- **Workaround**: If the player wants a "solo" experience, they can always control 漫游者 and let the AI (none — there is no AI in this design) handle the others... but this is not implemented. The player must control all 3.

#### E15. Player tries to enter a dialogue while a combat encounter is in progress
- **What happens**: Combat blocks dialogue. The player must defeat the encounter or flee first.

## 6. Dependencies

### 6.1 Upstream (this system depends on)

- **Resource / Data system** (`design/gdd/resource-data.md`) — Schema for pilot, mech, weapon, ammo, mech-part resources. Required for defining all entities in this GDD.
- **Game State Machine** (`design/gdd/game-state-machine.md`) — The party persists across state transitions (title → exploration → battle → dialogue). The state machine handles when the party is "active."
- **Player Input** (`design/gdd/player-input.md`) — Key bindings for 1/2/3/4 mech switching, Tab pilot cycling, M Mech Bay menu, Shift+1/2/3 dialogue companion swap.
- **Save / Load** (`design/gdd/save-load.md`) — Must serialize the entire party state: pilot assignments, mech assignments, weapon inventories, gold, XP, levels, unlocked abilities, mech part HP, dialogue companion choice.
- **Mech Upgrade system** (TBD GDD) — The party GDD references "mech modules" and "mech upgrades" — those are owned by the Mech Upgrade GDD.
- **Battle Core Loop** (`design/gdd/battle-core-loop.md`) — The turn structure, AOE rules, and combat resolution are owned by Battle Core Loop. The party GDD specifies "what the party does" but the "how" of combat math is in Battle Core.

### 6.2 Downstream (systems that depend on this)

- **Weapon & Ammo system** (`design/gdd/weapon-ammo.md`) — Weapons are mounted on mechs (3-4 slots per mech), not on pilots. The Weapon GDD must support mech-mounted weapons with cross-pilot usage.
- **Bounty System** (TBD GDD) — Bounty targets are enemies that can be fought by the full party. The party GDD defines the 3-pilot attack surface.
- **Racing Minigame** (TBD GDD) — Racing uses individual mechs (the player chooses which mech to race with). The party GDD's mech roster is the source of truth.
- **HUD** (`design/gdd/hud.md`) — HUD must show 3-4 mech HP bars, current pilot assignments, weapon slot indicators, mode toggle (Manual / Auto), and the in-dialogue companion portrait.
- **Dialogue System** (`design/gdd/npc-terminal.md`) — The dialogue tree must support companion interjection (per §3.9). The dialogue GDD owns the actual dialogue text, but the structural support (which companion is in-dialogue, how to swap) is in the party GDD.
- **Mech Bay UI** (TBD) — A new screen for managing pilot-mech assignments, weapon inventory per mech, and mech upgrades. Owned by UI / UX.

## 7. Tuning Knobs

| Knob | Default | Range | Effect |
|------|---------|-------|--------|
| `BASE_DODGE` | 0.10 | 0.05-0.20 | Higher = pilots dodge more often at low levels. |
| `LEVEL_DODGE_BONUS` | 0.02 | 0.01-0.05 | Higher = level scaling on dodge. |
| `MAX_DODGE_CAP` | 0.80 | 0.50-0.95 | Higher = even fully-geared pilots can dodge. |
| `BASE_HIT` | 0.85 | 0.70-0.95 | Higher = attacks hit more often at base. |
| `BASE_CRIT` | 0.05 | 0.03-0.10 | Higher = crits are more common. |
| `revival_cost_ratio` | 0.25 | 0.10-0.50 | Higher = death is more punishing. |
| `revival_cost_minimum` | 100 | 50-500 | Higher = death is more punishing. |
| `BASE_XP` (for leveling) | 100 | 50-300 | Higher = leveling is slower. |
| `enemy_xp_reward` | varies | 10-100 | Higher = faster leveling. |
| `party_size_max` | 3 | 1-4 | Affects all combat and dialogue balance. (3 is the chosen design; 4 is the upper limit if 苍穹号's pilot counts.) |
| `mech_count_max` | 4 | 2-4 | Affects combat UI and balance. |
| `safe_dodge_every_n_turns` | 3 | 2-5 | Higher = dodge safety net is rarer. |
| `friendly_fire_default` | ON | ON/OFF | ON = AOE can hit allies (harder); OFF = AOE skips allies (easier). |
| `battle_phase_party_action_count` | unlimited per mech | 1-2 | 1 = each mech gets 1 action per party phase; 2 = each mech gets 2 actions. Higher = party is more powerful. |
| `enemy_phase_action_count` | 1 | 1-4 | 1 = only 1 enemy attacks per round; higher = more pressure on party. |
| `cangqiong_inheritance_chapter` | Ch13 end | Ch10-Ch15 | Earlier = player has more time to use 苍穹号. Later = it's a "climax" reward. |
| `cangqiong_level_floor` | 30 | 20-50 | Higher = 苍穹号 is more powerful (and more unbalanced). |
| `cangqiong_repair_cost_multiplier` | 2.0 | 1.0-5.0 | Higher = legendary mech is more expensive to maintain. |

## 8. Acceptance Criteria

Each AC is testable. The QA tester must be able to verify pass/fail.

#### AC1. Three-pilot party
- [ ] The party consists of exactly 3 pilots: 漫游者, 霜尾, 轰天.
- [ ] No AI-controlled companions exist. Every pilot is player-controlled.
- [ ] 漫游者 is always in the party. Cannot be removed.

#### AC2. Mech acquisition
- [ ] Ch1 starts with 漫游者号 available. No other mechs.
- [ ] Frostbite joins the party in Ch4 mid (Sat-2 Room 4). No mech granted.
- [ ] 霜尾号 is found in Sat-2 Room 7. Pre-equipped with 双刃长刀 and 冰冻手雷.
- [ ] Bomber joins the party in Ch10 mid (Sat-4 Room 5). No mech granted.
- [ ] 轰天号 is found in Sat-4 Room 8. Pre-equipped with 轨道炮, 榴弹发射器, 修复无人机.
- [ ] 苍穹号 is inherited in Ch13 end (Sat-5 climax). Cannot be removed from the party.

#### AC3. Free mech switching
- [ ] Any pilot can drive any mech (including non-legacy pilots driving 苍穹号, but the cockpit refuses to open for them — see AC5).
- [ ] The default pilot-mech mapping is: 漫游者→漫游者号, 霜尾→霜尾号, 轰天→轰天号.
- [ ] In combat, the player can switch which mech is active using keys 1/2/3/4.
- [ ] In combat, the player can switch which pilot drives the active mech using Tab.
- [ ] Out of combat, the player can swap pilot-mech assignments freely at any save point, repair station, or via the Mech Bay (M key) menu.

#### AC4. Combat turn structure
- [ ] One full combat round = 1 enemy turn + N party turns (where N = number of mechs the party has).
- [ ] Only 1 enemy attacks per round (the enemy's "representative").
- [ ] Each mech on its turn can: move (up to 3 tiles, varies by class) + 1 action, OR defend (no move, +30% armor), OR switch pilot (no move, costs the turn).

#### AC5. 苍穹号 pilot lock
- [ ] 苍穹号 refuses to open its cockpit for any pilot other than 漫游者.
- [ ] This lock is hard-coded and cannot be bypassed.
- [ ] The true-ending climax (Ch15 Creator dialogue) requires 漫游者 as the assigned pilot of 苍穹号.

#### AC6. Dodge formula
- [ ] Dodge chance = `min(0.10 + level × 0.02 + equip + mech, 0.80)`.
- [ ] Every pilot gets a guaranteed dodge every 3 turns, regardless of the formula.
- [ ] 霜尾's "Survival Instinct" adds +30% dodge when HP < 25%.

#### AC7. Damage formula
- [ ] Damage = uniform_random(weapon.min, weapon.max) × ammo.mult × weakness × crit_mult.
- [ ] Final damage subtracts target's armor.
- [ ] Minimum final damage is 1 (attacks always have an effect).

#### AC8. Revival system
- [ ] When a non-main pilot is knocked out in combat, they are auto-sent to the nearest clinic after combat.
- [ ] Revival cost = `max(floor(gold × 0.25), 100)`.
- [ ] Revivals are unlimited (cost gold each time).
- [ ] 漫游者 cannot be revived. Knocked out = game over.

#### AC9. Mech durability
- [ ] Each mech has 4 parts (head/chest/arms/legs), each with separate HP.
- [ ] When a part's HP reaches 0, the corresponding debuff applies (see §3.5).
- [ ] When the mech's total HP reaches 0, the pilot is knocked out and falls back.

#### AC10. In-dialogue companion
- [ ] Each dialogue shows 1 main character + 1 in-dialogue companion + 1 NPC.
- [ ] The player can swap the in-dialogue companion before the dialogue starts using Shift+1/2/3.
- [ ] Companion dialogue is scripted per NPC, not procedurally generated.
- [ ] Some NPCs have companion-specific dialogue trees that only trigger with the right companion.

#### AC11. Mech Bay menu
- [ ] Pressing M opens the Mech Bay menu.
- [ ] The menu shows: all owned mechs, current pilot assignments, weapon inventories per mech, and mech part HP.
- [ ] The player can swap pilot-mech assignments in the menu.
- [ ] The menu can be opened during combat on the player's turn (paused state) but **not** during the enemy's turn.

#### AC12. Trust / affinity (deferred)
- [ ] Status: deferred to a future Trust System GDD. Currently not implemented.

## 9. Open Questions

- **Q1 (low priority)**: Should the party have a 4th "guest" pilot slot (e.g., a temporary NPC pilot for one chapter)? Currently no. Decision: not in scope.
- **Q2 (medium priority)**: Should companions have a "Trust / Affinity" system? Currently deferred. Decision needed before Bounty GDD.
- **Q3 (low priority)**: 霜尾's and 轰天's true names — should they be hard-coded lore (e.g., 霜尾's true name is "伊万 / Ivan"), or always use the codename? Currently defaults to codename. Decision: revisit when writing companion-specific quest dialogues.
- **Q4 (medium priority)**: What happens if the player uses 漫游者 as the in-dialogue companion AND as the active pilot? (e.g., they walk up to an NPC, 漫游者 is the in-dialogue companion, but the active mech is 霜尾号 with 霜尾 driving.) Currently: dialogue works as long as 漫游者 is the in-dialogue companion, regardless of who's driving. Decision: keep as-is unless players find it confusing.
- **Q5 (high priority)**: The "Mech Bay menu can be opened during combat on the player's turn" rule — does this trivialize combat (player can pause and think forever)? Need to test. Possible mitigation: Mech Bay can only be opened between full rounds, not between party member actions.
- **Q6 (medium priority)**: When the player has 4 mechs but only 3 pilots, who drives the 4th mech during combat? Currently, only 3 mechs can be active in combat (one per pilot). The 4th mech is "in storage" and cannot fight. Decision: needs clarification in §3.4.
- **Q7 (high priority)**: How does the "party = 3 pilots + 4 mechs" system interact with the Bounty GDD? Bounties might require a specific pilot + mech combo to challenge. Decision: design when Bounty GDD is written.
- **Q8 (medium priority)**: The 苍穹号 "story gate" requirement for true ending (漫游者 must be the assigned pilot) — what if the player wants to play 漫游者 in 漫游者号 for some scenes, and 漫游者 in 苍穹号 for others? Currently: yes, can swap freely. The "must be in 苍穹号" only applies at the Ch15 climax. Decision: keep as-is.
- **Q9 (low priority)**: The "auto mode" for combat — does it use the new party system correctly? Currently: yes, auto mode auto-selects the optimal action for each mech per turn. Decision: implement and test.

---

## Out-of-Scope (Handled by Other GDDs)

- **Bounty System** → `design/gdd/bounty-system.md`
- **Racing Minigame** → `design/gdd/racing-minigame.md`
- **Multi-Satellite Story Arc** → `design/gdd/multi-satellite-arc.md`
