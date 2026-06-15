# Systems Index: Railhunter（钢轨猎人）

> **Status**: Draft
> **Created**: 2026-06-12
> **Last Updated**: 2026-06-12
> **Source Concept**: design/gdd/game-concept.md
> **Review Mode**: Solo (CD-SYSTEMS and TD-SYSTEM-BOUNDARY gates skipped)

---

## Overview

Railhunter needs **25 systems** to deliver its 3-5 hour experience of "discover → fight → collect → piece together truth" inside a high-density 2D pixel sci-fi satellite. The system set is intentionally minimal for a 1-3 month solo project: it covers the four game pillars (exploration density, discovery-over-numbers, every-fight-is-a-build-test, truth-as-collection) without sprawling into open-world, multiplayer, or any system the concept anti-pillars explicitly forbid.

The architecture follows a five-layer dependency model: **Foundation → Core → Feature → Presentation → Polish**. MVP design and build starts with the 5 Foundation systems, then the combat Core, then the Feature systems that produce the player's experience, and finally Presentation and Polish wrap the game. **No GDDs exist yet** — every system is "Not Started" in the tracker below.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | 玩家输入 (Player Input) | Core | MVP | Approved | `design/gdd/player-input.md` | — |
| 2 | 游戏状态机 (Game State Machine) | Core | MVP | Approved | `design/gdd/game-state-machine.md` | — |
| 3 | 资源 / 数据系统 (Resource/Data) | Core | MVP | Approved | `design/gdd/resource-data.md` | — |
| 4 | 相机系统 (Camera) | Core | MVP | Approved | `design/gdd/camera.md` | — |
| 5 | 碰撞检测 (Collision) | Core | MVP | Approved | `design/gdd/collision.md` | — |
| 6 | 战斗场景切换 (Battle Scene Switch) | Core | Vertical Slice | Not Started | — | Game State, Battle Core |
| 7 | 战斗核心循环 (Battle Core Loop) | Gameplay | MVP | Approved | `design/gdd/battle-core-loop.md` | State, Data, Input, Collision |
| 8 | 伤害计算 (Damage Calc) | Gameplay | Vertical Slice | Not Started | — | Battle Core, Weapon, Ammo, Mech |
| 9 | 状态效果 (Status Effects) | Gameplay | Alpha | Not Started | — | Battle Core, Damage Calc |
| 10 | 敌人 AI (Enemy AI) | Gameplay | Vertical Slice | Not Started | — | Battle Core, Data |
| 11 | 武器系统 (Weapon System) | Gameplay | MVP | Approved | `design/gdd/weapon-ammo.md` (combined GDD) | Data, Ammo |
| 12 | 弹药系统 (Ammo System) | Gameplay | MVP | Approved | `design/gdd/weapon-ammo.md` (combined GDD) | Data |
| 13 | 机甲升级 (Mech Upgrade) | Progression | Vertical Slice | Not Started | — | Data, Battle Core |
| 14 | 道具系统 (Items) | Economy | Vertical Slice | Not Started | — | Data, HUD |
| 15 | 关卡 / 迷宫 (Level/Dungeon) | Gameplay | MVP | Approved | `design/gdd/level-dungeon.md` | Input, Camera, Collision |
| 16 | 暗雷遇敌 (Random Encounter) | Gameplay | MVP | Approved | `design/gdd/random-encounter.md` | Level, Battle Scene Switch |
| 17 | 门 / 锁系统 (Doors/Locks) | Gameplay | Vertical Slice | Not Started | — | Level, Weapon or Ammo or NPC |
| 18 | NPC / 终端日志 (NPC/Terminal) | Narrative | MVP | Approved | `design/gdd/npc-terminal.md` | Level, Story Map |
| 19 | 剧情图谱 (Story Map) | Narrative | Vertical Slice | Not Started | — | NPC |
| 20 | 图鉴系统 (Codex) | Progression | Vertical Slice | Not Started | — | Weapon, Enemy AI, Level |
| 21 | 存档 / 加载 (Save/Load) | Persistence | MVP | Approved | `design/gdd/save-load.md` | State, all Feature systems |
| 22 | HUD | UI | MVP | Approved | `design/gdd/hud.md` | Battle Core, Mech, Weapon, Input |
| 23 | 菜单 / 暂停 (Menu/Pause) | UI | Vertical Slice | Not Started | — | State, Save, Codex |
| 24 | 小地图 (Minimap) | UI | Vertical Slice | Not Started | — | Level, Input |
| 25 | Polish（音频 / 设置 / 教学 / 成就 / 本地化） | Meta | Full Vision | Not Started | — | All Presentation and Feature |

> **Note**: Items 11 and 12 (Weapon and Ammo) will be authored as a single combined GDD "Weapon & Ammo System" because they are tightly coupled. Item 25 covers multiple "polish" sub-systems that ship together at the end.

---

## Categories

| Category | Description | Systems in this Project |
|----------|-------------|-------------------------|
| **Core** | Foundation systems everything depends on | Player Input, Game State, Resource/Data, Camera, Collision |
| **Gameplay** | The systems that make the game fun | Battle Core, Damage, Status Effects, Enemy AI, Weapon, Ammo, Level, Encounter, Doors |
| **Progression** | How the player grows over time | Mech Upgrade, Codex |
| **Economy** | Resource creation and consumption | Items |
| **Persistence** | Save state and continuity | Save/Load |
| **UI** | Player-facing information displays | HUD, Menu/Pause, Minimap |
| **Narrative** | Story and dialogue delivery | NPC/Terminal, Story Map |
| **Meta** | Systems outside the core game loop | Audio, Settings, Tutorial, Achievements, Localization |

---

## Priority Tiers

| Tier | Definition | Target Milestone | Design Urgency |
|------|------------|------------------|----------------|
| **MVP** | Required for the core loop to function. Without these, you can't test "is this fun?" | First playable prototype (5-7 weeks) | Design FIRST |
| **Vertical Slice** | Required for one complete, polished area. Demonstrates the full experience. | Vertical slice (1-2 months) | Design SECOND |
| **Alpha** | All features present in rough form. Complete mechanical scope, placeholder content OK. | Alpha (2-3 months) | Design THIRD |
| **Full Vision** | Polish, edge cases, nice-to-haves, and content-complete features. | Beta / Release | Design as needed |

---

## Dependency Map

### Foundation Layer (no dependencies)

1. **资源 / 数据系统 (Resource/Data)** — Defines the schema for weapons, enemies, items, ammo, mech parts. Every other system reads from this. **Design first.**
2. **玩家输入 (Player Input)** — Keyboard/mouse + gamepad input mapping. Foundation for movement, battle menus, mode switching, pause.
3. **游戏状态机 (Game State)** — Title → Exploration → Battle → Menu. Every system switches states through this.
4. **相机系统 (Camera)** — Fixed-area and follow camera for exploration; separate camera for battle screen.
5. **碰撞检测 (Collision)** — Player vs walls, bullets vs enemies, player vs doors, player vs encounter tiles.

### Core Layer (depends on foundation)

6. **战斗核心循环 (Battle Core Loop)** — Turn order, manual mode (player chooses action), auto mode (AI takes over), mode switch mid-battle. **Must be prototype-validated before any Feature system depends on it.**

### Feature Layer (depends on core)

7. **武器与弹药 (Weapon & Ammo)** — Weapon slots, ammo types (normal/plasma/track/blast), weapon×ammo combinations produce different effects. **Combined GDD.**
8. **伤害计算 (Damage Calc)** — Weapon × ammo × mech part × weakness → final damage. Includes crit.
9. **状态效果 (Status Effects)** — Burn / poison / slow / EMP. Lasts N turns, has visual indicator.
10. **敌人 AI (Enemy AI)** — Manual-mode AI = simple decision tree (attack / skill / item / defend). Auto-mode AI = "optimal strategy" version of the same logic.
11. **机甲升级 (Mech Upgrade)** — 4 parts (head/chest/arms/legs), each with HP and upgrade path. Auto-mode AI prioritizes damaged parts.
12. **道具系统 (Items)** — Repair kits, consumables, key items. Used in battle or exploration.
13. **关卡 / 迷宫 (Level/Dungeon)** — Tile-based, encounter tiles, hidden rooms, environmental storytelling. **Scope: 1 chapter for MVP, 3 for full.**
14. **暗雷遇敌 (Random Encounter)** — Triggered by walking on encounter tiles. Battle scene switch + return.
15. **门 / 锁系统 (Doors/Locks)** — Normal doors (always open), locked doors (need specific weapon/ammo/item), story doors (open after NPC fragments).
16. **NPC / 终端日志 (NPC/Terminal Logs)** — Audio logs, terminal entries, optional 1-on-1 NPCs. Each produces a story fragment.
17. **剧情图谱 (Story Map)** — Visual map of story fragments; nodes light up as fragments are collected. Shows completion %.
18. **图鉴 (Codex)** — Weapon / enemy / region bestiary. Each entry has stats, lore, completion %.
19. **战斗场景切换 (Battle Scene Switch)** — Visual transition between exploration map and battle screen, with state preserved.

### Presentation Layer (depends on features)

20. **HUD** — HP bar, mech part status, current weapon + ammo, mode indicator (MANUAL/AUTO), enemy HP, encounter count, item hotbar.
21. **存档 / 加载 (Save/Load)** — Stores: position, weapons, ammo, mech upgrades, codex progress, story fragments, settings. **Auto-save at safe points only.**
22. **菜单 / 暂停 (Menu/Pause)** — Title screen, pause overlay, chapter summary screen.
23. **小地图 (Minimap)** — Shows player position and explored area. Does NOT show complete map (preserves exploration feel).

### Polish Layer (depends on everything)

24. **Polish (Audio / Settings / Tutorial / Achievements / Localization)** — BGM, SFX, settings menu, onboarding tutorial, completion %, text externalization for future localization.

---

## Recommended Design Order

Combining dependency sort and priority tiers. **Design these GDDs in this order.** Each GDD should be completed and reviewed via `/design-review` before starting the next.

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| 1 | 资源 / 数据 (Resource/Data) | MVP | Foundation | game-designer + lead-programmer | M |
| 2 | 玩家输入 (Player Input) | MVP | Foundation | gameplay-programmer | S |
| 3 | 游戏状态机 (Game State) | MVP | Foundation | gameplay-programmer + lead-programmer | S |
| 4 | 相机 (Camera) | MVP | Foundation | gameplay-programmer | S |
| 5 | 碰撞 (Collision) | MVP | Foundation | gameplay-programmer | S |
| 6 | **战斗核心循环 (Battle Core Loop)** | MVP | Core | gameplay-programmer + ai-programmer | **L** (validate via `/prototype` first) |
| 7 | 武器与弹药 (Weapon & Ammo) | MVP | Feature | systems-designer + gameplay-programmer | M |
| 8 | 关卡 / 迷宫 (Level/Dungeon) | MVP | Feature | level-designer + gameplay-programmer | **L** (single chapter for MVP) |
| 9 | 暗雷遇敌 (Encounter) | MVP | Feature | gameplay-programmer | S |
| 10 | NPC / 终端日志 (NPC/Terminal) | MVP | Feature | narrative-director + writer | S |
| 11 | HUD | MVP | Presentation | ui-programmer + ux-designer | M |
| 12 | 存档 / 加载 (Save/Load) | MVP | Presentation | gameplay-programmer | M |
| 13 | 战斗场景切换 (Battle Scene Switch) | Vertical Slice | Feature | ui-programmer + gameplay-programmer | S |
| 14 | 伤害计算 (Damage Calc) | Vertical Slice | Gameplay | systems-designer | M |
| 15 | 敌人 AI (Enemy AI) | Vertical Slice | Gameplay | ai-programmer | M |
| 16 | 机甲升级 (Mech Upgrade) | Vertical Slice | Progression | systems-designer + gameplay-programmer | M |
| 17 | 道具系统 (Items) | Vertical Slice | Economy | systems-designer | S |
| 18 | 门 / 锁 (Doors/Locks) | Vertical Slice | Feature | level-designer + gameplay-programmer | S |
| 19 | 剧情图谱 (Story Map) | Vertical Slice | Narrative | narrative-director + ui-programmer | M |
| 20 | 图鉴 (Codex) | Vertical Slice | Progression | systems-designer + ui-programmer | M |
| 21 | 菜单 / 暂停 (Menu/Pause) | Vertical Slice | UI | ui-programmer + ux-designer | M |
| 22 | 小地图 (Minimap) | Vertical Slice | UI | ui-programmer | S |
| 23 | 状态效果 (Status Effects) | Alpha | Gameplay | systems-designer + gameplay-programmer | M |
| 24 | 完整剧情线（章节 2-3） | Alpha | Narrative | narrative-director + writer | L |
| 25 | 完整图鉴（章节 2-3） | Alpha | Progression | systems-designer | M |
| 26 | 隐藏结局 | Alpha | Narrative | narrative-director | S |
| 27 | 教学 (Tutorial) | Full Vision | Meta | ux-designer + writer | S |
| 28 | 音频 (Audio) | Full Vision | Meta | audio-director + sound-designer | M |
| 29 | 设置 (Settings) | Full Vision | Meta | ui-programmer | S |
| 30 | 成就 (Achievements) | Full Vision | Meta | systems-designer | S |
| 31 | 本地化钩子 (Localization) | Full Vision | Meta | localization-lead | S |

[Effort: S = 1 session, M = 2-3 sessions, L = 4+ sessions. A "session" = one focused design conversation producing a complete GDD.]

---

## Circular Dependencies

Three minor bidirectional relationships were found and resolved by GDD structure rather than architecture:

- **关卡 (15) ↔ 暗雷 (16)**: Levels define where encounter tiles are placed; encounter system defines the trigger mechanic. **Resolution**: Level GDD includes the "encounter distribution table" as a subsection; Encounter GDD defines only the trigger mechanism and outcome.

- **武器 (11) ↔ 弹药 (12)**: Weapons slot ammo; ammo only exists in context of weapons. **Resolution**: Combined as a single "Weapon & Ammo System" GDD.

- **NPC (18) ↔ 剧情图谱 (19)**: NPCs produce story fragments; story map shows NPC collection status. **Resolution**: NPC GDD defines the "fragment output interface"; Story Map GDD consumes that interface. No direct coupling.

No hard circular dependencies that would block design or implementation.

---

## High-Risk Systems

Systems requiring prototype validation or extra design attention, regardless of priority tier:

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| **战斗核心循环 (Battle Core Loop)** | Design + Technical | The manual/auto dual-mode is the game's heart. If the rhythm is wrong, nothing else matters. Unproven pattern. | **Validate via `/prototype 暗雷回合制战斗` BEFORE writing GDD.** Failure here means pivoting. |
| **武器与弹药 (Weapon & Ammo)** | Design | Too many combinations = overwhelming build math. Too few = shallow. Balance window is narrow. | Prototype 3 weapons × 3 ammo = 9 combinations first. Re-balance before expanding. |
| **关卡 / 迷宫 (Level/Dungeon)** | Design + Scope | "Every room has a payoff" is the densest design promise in the concept. Easy to ship empty-feeling rooms. | "Density audit" workflow: every room must answer "what does the player find here?" before sign-off. |
| **NPC / 终端日志 (NPC/Terminal)** | Scope | Writing is hard for a first-time developer. Risk of over-promising on narrative depth. | Cap at 1-2 fragments for MVP. Add more only after prototype validates the collection loop. |
| **存档 / 加载 (Save/Load)** | Technical | Save data must include ALL state. Schema creep = corruption. | Define the save schema in the Resource/Data GDD, not the Save GDD. |
| **Polish (Audio + Settings + etc.)** | Scope | "Polish later" is the #1 cause of unfinished games. | Define the MINIMUM polish in MVP. BGM + 1 BGM per game state is enough. |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 25 (collapsed from 35 during enumeration) |
| Design docs started | 3 / 25 |
| Design docs reviewed | 1 / 3 |
| Design docs approved | 1 / 3 (Resource/Data: Approved 2026-06-12 post-revision) |
| MVP systems designed | 3 / 12 (Resource/Data Approved; Player Input revision complete pending re-review; Game State Machine Designed pending review) |
| Vertical Slice systems designed | 0 / 10 |
| Alpha systems designed | 0 / 4 |
| Full Vision systems designed | 0 / 5 |

> **Note on counting**: Some systems are split across multiple priorities (e.g., Weapon & Ammo is one GDD but is required for both MVP and Vertical Slice). The tier counts above reflect GDD authoring waves, not strict GDD-to-tier mapping.

> **2026-06-12 update**: Game State Machine GDD written (366 lines, 8 sections, 0 placeholders, 15 ACs). 3/12 MVP GDDs now authored.

> **Note on Player Input dependency layer**: Per systems-index.md the original Layer classification marked Player Input as "Core" (the older 3-layer model). The newer 5-layer model (Foundation → Core → Feature → Presentation → Polish) classifies Player Input as **Foundation**. This is a labeling inconsistency in the systems-index table — Player Input is functionally a Foundation-layer system. The GDD itself uses the 5-layer model and treats it as Foundation. (No change to systems-index.md Category column needed; both labels are acceptable as long as GDDs are consistent within themselves.)

> **2026-06-12 update**: 资源 / 数据系统 (Resource/Data) GDD written — 8 sections + Visual/Audio/UI redirect note + Open Questions. First MVP GDD complete.
> **2026-06-12 update (revision)**: Resource/Data GDD revised after /design-review. 3 blocking issues addressed: (1) damage/HP range tightened to prevent 1-shot kills + fantasy example fixed to "laser 20 → missile×plasma 65", (2) all 11 ACs rewritten with deterministic seeds and 3 new ACs added (ID uniqueness, save/load, visual asset), (3) Pillar 4 substrate added (TerminalLogData, StoryFragmentData, RegionData) — 9 resource subtypes, 13 downstream systems, 15+ acceptance criteria. Verdict: NEEDS REVISION → revised, pending re-review approval.
> **2026-06-12 update (Player Input)**: 玩家输入 (Player Input) GDD authored in-session. 12 sections: Overview + Player Fantasy + Detailed Design (7 invariants, 47-action closed set, 6 states, 9 consumers) + Formulas (latency, refused feedback, dash) + 8 Edge Cases + Dependencies (3 upstream engine APIs, 9 downstream consumers with stable contract) + Tuning Knobs (47-action summary + 8 timing constants + 3 focus knobs) + Visual/Audio (8 cues) + Game Feel (5 rules) + UI (6 rules) + Cross-References + 12 ACs + 3 Open Questions. **Status: In Design — pending /design-review.**

---

## Next Steps

- [ ] Review and approve this systems enumeration
- [ ] **Validate Battle Core Loop via `/prototype 暗雷回合制战斗`** (manual + auto dual-mode) — the highest-risk system
- [ ] Design MVP-tier systems first (use `/design-system [system-name]`)
  - Recommended first GDD: 资源 / 数据 (Resource/Data) — schema defines everything downstream
  - Recommended second GDD: 战斗核心循环 (Battle Core Loop) — informed by prototype
- [ ] Run `/design-review` on each completed GDD
- [ ] Run `/gate-check pre-production` when all MVP systems are designed
- [ ] Validate the highest-risk systems with `/vertical-slice` before committing to Production

---

## Recommended First Three GDDs (In Order)

1. **资源 / 数据系统 (Resource/Data)** — M effort — game-designer + lead-programmer
   - Defines weapon, ammo, enemy, item, mech-part schemas. **Every other system reads from this.**
2. **战斗核心循环 (Battle Core Loop)** — L effort — gameplay-programmer + ai-programmer
   - **Validate via `/prototype 暗雷回合制战斗` first.** If prototype PROCEEDS, write GDD informed by learnings.
3. **武器与弹药 (Weapon & Ammo)** — M effort — systems-designer + gameplay-programmer
   - Coupled to Battle Core; cannot design before Battle Core.

> The **first action after this index is approved** is to run `/prototype 暗雷回合制战斗` to validate the battle loop. **Do not write Battle Core GDD until prototype PROCEEDS.** Skipping this step risks writing detailed GDDs for a system that turns out not to be fun.
