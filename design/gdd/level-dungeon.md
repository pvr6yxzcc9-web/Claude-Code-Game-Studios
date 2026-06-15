# 关卡 / 迷宫 (Level / Dungeon)

> **Status**: Approved
> **Author**: user + level-designer + world-builder + gameplay-programmer
> **Review Verdict**: APPROVED (first review 2026-06-12, lean)
> **Last Updated**: 2026-06-12 (first review)
> **Implements Pillar**: Pillar 1（探索密度）—— 每一个房间都有"被看见的回报"；Pillar 2（发现 > 数值）—— 隐藏区域 = 玩家"发现"的最高形式

## Summary

关卡 / 迷宫系统是 Railhunter **Pillar 1（探索密度）的舞台**。它定义 1 个完整章节（MVP：卫星表层）的地图：8-12 个 tile-based 房间、隐藏区域、遇敌 tile、终端 / NPC / 道具 / 门的空间分布，以及"每个房间都有回报"的密度设计规则。它是 #5 碰撞 + #16 暗雷 + #17 门锁 + #14 道具 + #18 NPC 的空间容器。

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `碰撞 #5`（player vs walls）、`暗雷 #16`（encounter tiles）、`门锁 #17`（doors）、`NPC/Terminal #18`（NPCs）、`相机 #4`（follow camera）· Depended on by: HUD、Codex、存档

## Overview

关卡 / 迷宫系统是 Railhunter **Pillar 1（探索密度）的舞台**。它定义 1 个完整章节（MVP：卫星表层 / 前哨基地走廊）的地图——8-12 个 tile-based 房间、隐藏区域、遇敌 tile、终端 / NPC / 道具 / 门的空间分布，以及"每个房间都有回报"的密度设计规则。

本系统**承载** 5 个 Foundation + 1 个 Core + 1 个 Feature 的下游消费者：
- #5 碰撞：玩家 vs 墙（WORLD 层）
- #16 暗雷：玩家踩 ENCOUNTER tile 触发 BATTLE
- #17 门锁：玩家走近门 + 用特定武器 / 弹药 / 道具解锁
- #14 道具：玩家踩 INTERACTABLE 拾取
- #18 终端 / NPC：玩家走近读终端日志
- #4 相机：EXPLORATION_FOLLOW 跟随玩家

玩家**直接接触**这个系统——他们**走**的每一步都是关卡设计的结果。

如果本系统不存在，**Pillar 1 直接消失**——没有"密度"可言；没有"发现"可言；每个房间都"没什么特别的"。

**在 5 层 Feature 中**：本系统是**第二个** Feature 系统（#11+#12 武器弹药是第一个）。MVP 单章节（卫星表层，8-12 房间）；VS 加到 3 章节（30-50 房间）。

## Player Fantasy

玩家**直接接触**这个系统——这是他们 80% 的游戏时间。

他们感受到的，是 **Pillar 1（探索密度）** 的具体兑现——"我永远期待下一个房间":

- **进入新房间**：HUD 短暂显示房间名（如"卫星表层 - C-7 走廊"），**总能看到新东西**（隐藏终端 / 隐藏道具 / 隐藏门 / 隐藏 NPC 录音 / 隐藏区域）
- **探索不寻常路径**：玩家不一定要走"主路"——侧路、死路、可破坏墙、隐藏开关**都可能有回报**（per Pillar 1 测试："这违反 Pillar 1"）
- **遇敌**：玩家走到 ENCOUNTER tile → 触发战斗（per #16 暗雷）→ 战后回到同一 tile → 玩家可以"再走一遍"以触发更多战斗
- **门 / 锁**：玩家走近锁着的门 → UI 提示"需要 [X]" → 玩家回来时有了 X → 解锁新区域
- **终端**：玩家靠近终端 → 拉近相机（per #4 TERMINAL_CLOSEUP）→ 读 NPC 录音 / 日志 → 关闭后状态回 EXPLORATION
- **退出关卡**：完成章节最后一房间 → 章节结算屏 → 状态机 transition_to(CHAPTER_X+1)（per #3）

这背后的情感是 **Pillar 1（探索密度）**——密度 = 每个房间都有回报；**Pillar 2（发现 > 数值）**——隐藏区域 = 玩家"发现"的高峰；**Pillar 4（真相是收集的结果）**——终端 / NPC 录音散布在关卡各处。

参考游戏：
- **《重装机兵》FC** —— 暗雷遇敌 + 战车改造 + 迷宫探索的灵感
- **Outer Wilds** —— 高密度探索 + 隐藏区域的典范
- **密特罗德 Dread** —— 隐藏区域 + 100% 完成度
- **极乐迪斯科** —— 环境叙事 + 终端日志

> `creative-director` 未咨询（Solo 模式）。

## Detailed Design

### Core Rules

本系统有 **8 条 invariant**。

**C-R1 — 1 个章节（MVP），手工 tile-based 地图**。MVP = 1 个章节（卫星表层），VS = 3 章节。地图 = `TileMapLayer` 节点 + 32x32 像素基础单位（per ADR-0010，**`TileMap` 节点自 4.3 起 deprecated，禁止使用**）。**禁止**程序生成（per game concept："**最小化**程序生成"——程序生成破坏密度）。所有房间**手工设计**。

**C-R2 — 每个房间 = 1 个 TileMapLayer 屏幕**。每个房间大致 25×15 tile（800×480 像素）= 一个屏幕可见。**禁止**超过 1 屏幕的房间（MVP）——避免玩家迷失方向。房间之间用 `Door` / `TransitionZone` 连接（per ADR-0010，Doors 是带旋转的 scene node，不是 tile）。

**C-R3 — Pillar 1 测试：每个房间必须有"被看见的回报"**。每个房间至少有 1 个回报（按以下 5 种密度模板之一）：
- **A 型 - 新武器 / 新弹药**（最稀有，1 章 1-2 个）
- **B 型 - 终端 / NPC 日志**（最常用，1 章 5-8 个——叙事主线）
- **C 型 - 道具**（弹药 / 修复包 / 钥匙，1 章 3-5 个）
- **D 型 - 隐藏区域 / 隐藏门**（"探索奖励"，1 章 1-3 个）
- **E 型 - 章节线索**（终端 / NPC 提及下章 / boss / 真相碎片，1 章 2-4 个）

**禁止**"空房间"——只有"通道"的房间**也**必须有回报（哪怕是 E 型线索或 B 型"小日志"）。

**C-R4 — 遇敌 tile = 不可见 trigger**。每个房间有 N 个 ENCOUNTER tile（per #16 暗雷），玩家踩到触发 BATTLE。tile 是**不可见**的（不画），玩家**不**预先知道哪些 tile 遇敌。**禁止**"遇敌 tile 视觉化"——破坏"暗雷"的惊喜感。

**C-R5 — 锁着的门需要特定资源**。门有 4 种锁类型（per #17 门锁）：
- **NORMAL**：永远打开
- **WEAPON_LOCKED**：需要持有特定 weapon（如粒子炮）
- **AMMO_LOCKED**：需要持有特定 ammo（如爆破弹 ≥ 5 发）
- **ITEM_LOCKED**：需要持有特定 key item
- **STORY_LOCKED**：需要收集特定 NPC 录音 / 真相碎片（per Pillar 4）

**C-R6 — 隐藏区域 = 视觉提示 + 不在主路**。每个 D 型隐藏区域有 2 个入口之一：
- **可破坏墙**：玩家用特定武器攻击（N 次）破坏
- **不可见门**：玩家靠近时显示"按 E 互动"提示

**C-R7 — 房间命名 + 完成度**。每个房间有 `id: StringName` + `display_name: String` + `is_completed: bool`。`is_completed = true` 当玩家离开该房间 = 玩家"已发现"。

**C-R8 — 小地图支持**。每个 TileMapLayer 节点在玩家"已发现"区域标记 visited = true（per #24 小地图）。玩家**未**发现 = 黑色（per game concept "保留探索感"）。

### States and Transitions

**8 个房间状态**：

| 状态 | 用途 | 转换触发 |
|------|------|----------|
| `LOCKED` | 房间被锁（门关闭） | 默认初始（被门锁系统控制） |
| `ENTERED` | 玩家进入 | `transition_to(EXPLORATION)` + 房间在 player 位置 |
| `EXPLORING` | 玩家在该房间活动 | 默认 |
| `COMBAT` | 玩家在该房间触发战斗 | #16 暗雷遇敌 → transition_to(BATTLE) |
| `RETURNING` | 玩家从战斗回来 | `transition_to(EXPLORATION)` + 房间不变 |
| `COMPLETED` | 玩家离开该房间 | 玩家走出 `Door` / `TransitionZone` |
| `CLEARED` | 所有 encounter tile 已触发 + 所有 reward 已拾取 | 显式 set（关卡设计者） |
| `HIDDEN` | 房间被锁 + 玩家未触发解锁条件 | 默认初始（被门锁系统控制） |

**章节进度**：

```
[CHAPTER_LOCKED] → [CHAPTER_INTRO] → [CHAPTER_ACTIVE] → [CHAPTER_COMPLETE]
                                                  ↓
                                     (next chapter or end)
```

### Interactions with Other Systems

| 系统 | 接口 | 触发 |
|------|------|------|
| **碰撞 #5** | TileMapLayer 提供 `WORLD` 层碰撞（per ADR-0010 + ADR-0005） | 玩家移动 |
| **暗雷 #16** | 玩家踩 ENCOUNTER tile → transition_to(BATTLE) | 暗雷遇敌 |
| **门锁 #17** | `Door` 节点 + 4 种锁类型 | 玩家靠近门 |
| **道具 #14** | `Pickup` 节点 + INTERACTABLE layer | 玩家走近 |
| **终端 / NPC #18** | `Terminal` 节点 + push(TERMINAL) state | 玩家走近 |
| **相机 #4** | `RIG_EXPLORATION_FOLLOW` | 玩家移动 |
| **玩家输入 #2** | 订阅 `move_up/down/left/right` + `interact` + `dash` | 玩家操作 |
| **状态机 #3** | `transition_to(EXPLORATION)` | 进入关卡 |
| **HUD** | 推送 `room_info: Dictionary`（房间名 / 完成度） | 玩家进入 |
| **小地图 #24** | 推送 `visited_tiles: Array[Vector2i]` | 玩家移动 |
| **存档 #21** | 序列化 `current_room_id` + 玩家位置 | 存档 |

## Formulas

### F1. Room Count per Chapter (Pillar 1 测试)

`min_rooms_per_chapter = 8` (MVP), `max_rooms_per_chapter = 12` (MVP)

| 章节 | 房间数（MVP） | 房间数（VS） | 回报数（5 种模板） |
|------|--------------|--------------|---------------------|
| 1 卫星表层 | 10 | 10 | A:1 + B:6 + C:4 + D:2 + E:3 = 16 |
| 2 卫星中层（VS） | — | 12 | A:1 + B:7 + C:5 + D:3 + E:4 = 20 |
| 3 卫星核心（VS） | — | 14 | A:2 + B:8 + C:5 + D:4 + E:5 = 24 |

**Output**: MVP 总计 10 房间 + 16 回报 = 1.6 回报 / 房间密度（per Pillar 1 远超"1 回报 / 房间"基准）。

### F2. Encounter Tile Density

`encounter_tiles_per_room` = 房间内的暗雷 tile 数。

| 房间类型 | 遇敌 tile 数 | 备注 |
|----------|--------------|------|
| 通道 / 走廊 | 1–2 | 低密度，激励玩家走过 |
| 普通房间 | 2–3 | 中密度 |
| 战斗房（per #16 暗雷） | 4–6 | 高密度，boss 战前置 |
| boss 房 | 1（仅 boss） | 一次性 |

**Default**: 平均每房间 2.5 个遇敌 tile。

**Edge case**: 遇敌 tile 0 个的房间 = "安全区"（per art-bible "密特罗德风格"安全房——给玩家喘息空间）—— 占总房间数 20%。

### F3. Chapter Completion Time Estimate

`expected_chapter_minutes = sum(rooms) × (avg_room_minutes + avg_battle_minutes × encounter_count_per_room)`

| 变量 | 类型 | 范围 | 描述 |
|------|------|------|------|
| `avg_room_minutes` | float | 1–3 | 平均每个非战斗房间时间 |
| `avg_battle_minutes` | float | 0.5–2 | 平均每个战斗时间（per #7） |
| `encounter_count_per_room` | float | 0–6 | per F2 |

**MVP 章节 1 (10 房间)**:
- 8 探索房间 × 2 分钟 = 16 分钟
- 25 遇敌 (2.5 × 10) × 1 分钟 = 25 分钟
- 总: ~41 分钟
- per game concept "MVP: 1 个章节 30-45 分钟" ✓

### F4. Hidden Room Discovery Rate (Pillar 2)

`player_discovery_rate = hidden_rooms_found / total_hidden_rooms_in_chapter`

| 玩家类型 | 发现率（per playtest） |
|----------|----------------------|
| Explorer (per Bartle) | 100% |
| Achiever | 80-100% |
| Casual | 30-60% |
| Speedrun | 0-20% |

**Target**: 章节 1 完成后平均发现率 ≥ 60%（MVP 目标）— 验证玩家"愿意探索"。

### F5. Reward Density Ratio (Pillar 1 量化测试)

`reward_density = total_rewards / total_rooms`

| 数值 | 评价 |
|------|------|
| < 1.0 | 不足（违反 Pillar 1） |
| 1.0-1.5 | 合格 |
| 1.5-2.0 | 良好（**MVP 目标 1.6**） |
| > 2.5 | 过于密集（破坏玩家"探索"的满足感） |

**Output Range**: MVP = 1.6 (10 房间 / 16 回报)
**Edge case**: < 1.0 = 必须增加回报或减少房间。

## Edge Cases

| # | 条件 | 结果 | 原因 |
|---|------|------|------|
| 1 | **玩家卡墙 / 卡角**：物理失败，玩家位置无效 | 玩家位置 = 上一个 valid position (per #5 E4) | 不让玩家永久卡死 |
| 2 | **战斗回到房间时玩家已不在原 tile**：遇敌时玩家在 (5,5)，战斗后回到 (5,5) | 仍然回到 (5,5)，即使战斗期间房间有敌人移动 / 道具消失 | 战斗 = 暂停，不改变地图状态 |
| 3 | **门解锁但玩家没回头探索**：玩家用粒子炮开锁门 → 门打开但玩家继续往前走 | 门保持"开"状态，下次玩家路过时门开 | 永久解锁（per #17） |
| 4 | **boss 房玩家死了**：玩家 HP = 0 → state replace(TITLE) | 玩家从 TITLE → 新游戏 → 重新打 boss（per #7 AC-17 + #3 死亡流） | 死亡 = 重来 |
| 5 | **章节切换时玩家在 EXPLORATION 边缘**：玩家刚走出章节 1 最后房间 → 章节 2 自动进入 | 章节切换走 #3 transition_to(CHAPTER_X+1)，新章节第一房间为 spawn 房间 | 平滑切换 |
| 6 | **隐藏门未被玩家触发**：玩家错过 D 型隐藏区域 | 房间不计入"完成度"百分比（per Codex 1-1 mapping） | 鼓励回头 |
| 7 | **同房间 2 个 ENCOUNTER tile 紧邻**：玩家 1 步触发 2 次战斗 | 第二次触发在第一次 `replace(BATTLE)` 后**被抑制**（per #5 E8 + 状态机 toggle ENCOUNTER layer） | 防止战斗风暴 |
| 8 | **房间被破坏（vs 章节 3 可破坏地形）**：玩家爆破弹炸墙 | MVP 不实现；VS 评估 | MVP 范围外 |
| 9 | **章节 1 完成后玩家还在章节 1**：存档读档回到章节 1 末尾房间 | 章节 1 末尾房间 = "exit" 房间，玩家下次进 = 章节 2 入口 | 流畅跨章节 |
| 10 | **NPC 录音 / 终端内容损坏** | 占位 "信号损坏" + 不阻塞玩家 | 资源缺失自愈 |

## Dependencies

### 上游依赖

| 系统 | 接口 | 备注 |
|------|------|------|
| **碰撞 #5** | TileMapLayer 物理碰撞（per ADR-0010） | 玩家 vs 墙 |
| **相机 #4** | `RIG_EXPLORATION_FOLLOW` 跟随 | 玩家移动 |
| **玩家输入 #2** | 订阅 move / interact / dash actions | 玩家操作 |
| **状态机 #3** | `transition_to(EXPLORATION)` | 进入关卡 |

### 下游依赖

| 系统 | 接口 | 备注 |
|------|------|------|
| **暗雷 #16** | 玩家踩 ENCOUNTER tile → BATTLE | 在本 GDD 中**声明** ENCOUNTER tile 位置，per #16 实现触发 |
| **门锁 #17** | `Door` 节点（4 种锁类型） | 房间之间的连接 |
| **道具 #14** | `Pickup` 节点（INTERACTABLE layer） | 散落道具 |
| **终端 / NPC #18** | `Terminal` 节点（push TERMINAL state） | 散布终端 |
| **HUD** | 推送 room_info | 房间名 / 完成度 |
| **小地图 #24** | 推送 visited_tiles | 玩家移动时 |
| **存档 #21** | 序列化 current_room_id + player_pos | 存档 |
| **Codex** | 推送 room_completion | 章节完成度 |

### 双向约束

| 约束 | 在 #5 碰撞中 | 在本 GDD 中 |
|------|-------------|-------------|
| TileMapLayer 物理 | #5 C-R5 矩形碰撞优先 | C-R1 TileMapLayer + 32x32（per ADR-0010） |
| 玩家撞墙反馈 | #5 Visual 摇头动画 | 本系统 E1 |
| ENCOUNTER tile 不可见 | #5 Layer 6 触发 | C-R4 不可见 |
| 门锁 4 类型 | #17 (本 GDD 引用 #17) | C-R5 4 类型 |

## Tuning Knobs

| 参数 | 当前默认值 | 安全范围 | 调高 → | 调低 → | 为什么取这个数 |
|------|------------|----------|---------|---------|----------------|
| `TILE_SIZE_PX` | 32 | 16 / 32 / 64 | 美术粒度细 | 美术粒度粗 | 32 = art-bible 像素基础单位 |
| `MIN_ROOMS_PER_CHAPTER` | 8 | 6-10 | 章节小 / 完成快 | 章节大 / 完成慢 | 8 = Pillar 1 密度下限 |
| `MAX_ROOMS_PER_CHAPTER` | 12 | 10-15 | 章节大 / Pillar 1 难 | 章节小 / Pillar 1 易 | 12 = MVP 上限 |
| `AVG_ENCOUNTER_TILES_PER_ROOM` | 2.5 | 1.5-4.0 | 战斗密集 | 战斗稀疏 | 2.5 = 平衡"鼓励探索"+"有挑战" |
| `SAFE_ROOM_RATIO` | 0.20 | 0.10-0.30 | 玩家喘气多 | 玩家喘气少 | 20% = "密特罗德风格"安全房 |
| `HIDDEN_ROOM_RATIO` | 0.20 | 0.10-0.30 | 隐藏过多（找不到） | 隐藏过少 | 20% = 1/5 房间有隐藏 |
| `CHAPTER_1_TARGET_MINUTES` | 40 | 30-50 | 章节太长 | 章节太短 | per game concept MVP 30-45 分钟 |
| `REWARD_DENSITY_TARGET` | 1.6 | 1.0-2.5 | 过于密集 | 不足（Pillar 1 fail） | 1.6 = "良好"范围中段 |
| `BOSS_FIGHT_ENCOUNTER_COUNT` | 1 | 1 | — | — | boss 房 1 次遇敌（per F2） |

### 跨系统杠杆

| 杠杆 | 影响范围 | 当前值 | 调高 → | 调低 → |
|------|----------|---------|---------|---------|
| `AVG_ENCOUNTER_TILES_PER_ROOM` | 战斗密度 / 玩家疲劳度 | 2.5 | 战斗频繁 | 战斗稀疏 |
| `REWARD_DENSITY_TARGET` | Pillar 1 兑现度 | 1.6 | 玩家被奖励淹没 | 玩家觉得"没什么回报" |
| `SAFE_ROOM_RATIO` | 玩家疲劳恢复 | 0.20 | 玩家不累 | 玩家累 |

## Visual/Audio Requirements

| 事件 | 视觉反馈 | 音频反馈 | 备注 |
|------|----------|----------|------|
| 进入新房间 | 房间名短暂显示（1.5s 淡入 0.5s 淡出） | 进入音 | per C-R7 |
| 遇敌（ENCOUNTER tile） | 屏幕 0.4s 淡黑 + 战斗场景淡入（per #4 FADE_BLACK） | 遇敌音 | per #16 暗雷 |
| 门解锁 | 门动画（滑开 / 淡出） | 解锁音 | per #17 |
| 隐藏门触发 | 隐藏门视觉化（之前不可见）+ "发现隐藏区域" 弹窗 | 发现音 | per C-R6 |
| 终端触发 | 相机拉近 + 终端 UI 显示 | 终端音 | per #4 TERMINAL_CLOSEUP |
| 章节完成 | 章节结算屏（per #3 transition_to CHAPTER_X+1） | 章节完成音 | per #3 |

## UI Requirements

| 信息 | 消费者 | 触发 | 备注 |
|------|--------|------|------|
| 房间名 | HUD | 玩家进入 | 1.5s 短暂显示 |
| 房间完成度（%探索） | HUD / Codex | 玩家离开 | per F4 探索百分比 |
| "按 E 互动" 提示 | #2 玩家输入 | INTERACTABLE 进入 | per #5 F4 |
| 小地图 | HUD | 玩家移动 | per #24 |
| "发现隐藏区域" 弹窗 | HUD | 隐藏门触发 | per C-R6 |
| 章节结算屏 | HUD | 章节完成 | 完成度 + 武器库 + 剧情进度 |

**关键约定**：本系统**不直接渲染**任何 UI widget——只**提供** `room_info: Dictionary` 给 HUD，HUD 自己渲染。

## Acceptance Criteria

> Solo 模式（`qa-lead` 未咨询），生产前人工 review。每条都是 Given-When-Then 格式。

### 关卡基础

- **AC-1**：**GIVEN** 玩家进入章节 1 第一房间 **WHEN** 测 room_state **THEN** 房间 = EXPLORING，HUD 显示房间名"卫星表层 - C-1 入口"。验证：C-R7 房间命名。
- **AC-2**：**GIVEN** 玩家在房间中移动到 ENCOUNTER tile **WHEN** 测触发 **THEN** `transition_to(BATTLE)` + 房间 state = COMBAT（per #16 暗雷 + #3 状态机）。验证：F2 遇敌。

### Pillar 1 测试（最关键）

- **AC-3**：**GIVEN** 章节 1 完成（10 房间）**WHEN** 测 Pillar 1 测试 **THEN** reward_density = total_rewards / 10 ≥ 1.5（per F5 MVP 目标 1.6）。验证：Pillar 1 兑现。
- **AC-4**：**GIVEN** 玩家通关章节 1 **WHEN** 测完成度统计 **THEN** 16 个回报（per F1 表）= 1 A + 6 B + 4 C + 2 D + 3 E。验证：C-R3 5 种密度模板。
- **AC-5**：**GIVEN** 玩家章节 1 末尾房间完成 **WHEN** 测章节进度 **THEN** 触发 `transition_to(CHAPTER_X+1)` 或游戏结束（per #3）。验证：E5 章节切换。

### 隐藏区域

- **AC-6**：**GIVEN** 玩家靠近可破坏墙 + 持有粒子炮（爆破弹 ≥ 5）**WHEN** 按互动 **WHEN** 测 **THEN** 墙 5 次攻击后破坏 + 隐藏区域出现 + "发现隐藏区域" 弹窗。验证：C-R6 + #17 门锁。
- **AC-7**：**GIVEN** 玩家进入隐藏区域 **WHEN** 测 room_state **THEN** 隐藏区域从 LOCKED → EXPLORING，房间 id 注册为新发现。验证：隐藏区域独立房间。

### 锁门

- **AC-8**：**GIVEN** 玩家走近 WEAPON_LOCKED 门 **WHEN** 测 **THEN** UI 提示"需要 [粒子炮]"，玩家没持粒子炮 = 门不开。验证：C-R5 4 种锁。
- **AC-9**：**GIVEN** 玩家有粒子炮 + 走近 WEAPON_LOCKED 门 **WHEN** 按互动 **WHEN** 测 **THEN** 门动画打开 + 玩家可以进入新房间。验证：解锁成功。

### 房间命名 + 完成度

- **AC-10**：**GIVEN** 玩家进入每个新房间 **WHEN** 测 room_state **THEN** 房间名短暂显示（1.5s 淡入 + 0.5s 淡出） + room.is_completed = false。验证：C-R7 命名。
- **AC-11**：**GIVEN** 玩家走出房间（通过 Door）**WHEN** 测 room_state **THEN** 离开的房间 is_completed = true（已发现）。验证：C-R7 完成。
- **AC-12**：**GIVEN** 玩家章节 1 完成 5 房间 + 5 房间未完成 **WHEN** 测 Codex 章节 1 完成度 **WHEN** 测 **THEN** 显示 5/10 (50%) 探索 + 5/16 回报 (31%)。验证：完成度量化。

### 遇敌密度

- **AC-13**：**GIVEN** 章节 1 10 房间 + avg 2.5 encounter tile/room **WHEN** 测总 encounter 数 **WHEN** 测 **THEN** ~25 个 ENCOUNTER tile。验证：F2 密度。
- **AC-14**：**GIVEN** 玩家 1 步触发 2 个 ENCOUNTER tile 紧邻 **WHEN** 测 **WHEN** 测 **THEN** 第二次触发被抑制（per #5 E8 + ENCOUNTER monitoring = false in BATTLE state）。验证：E7 战斗风暴防护。

### 章节时长

- **AC-15**：**GIVEN** 玩家首次通关章节 1 **WHEN** 测时长 **WHEN** 测 **THEN** ~40 分钟（per F3 公式），符合 game concept "30-45 分钟/章节"。验证：MVP 时长。
- **AC-16**：**GIVEN** 玩家章节 1 安全房（无 encounter tile）比例 **WHEN** 测 **WHEN** 测 **THEN** ~20% 房间 = 安全房（2/10）。验证：F2 safe_room_ratio。

### 性能

- **AC-17**：**GIVEN** 10 房间全部加载到内存 **WHEN** 帧率测试 **THEN** 帧率 ≥ 58 FPS。验证：性能预算。
- **AC-18**：**GIVEN** 玩家从战斗回到原房间 **WHEN** 测位置 **WHEN** 测 **THEN** 玩家仍在遇敌 tile（5,5），房间状态 EXPLORING。验证：E2 战斗暂停。

### 存档

- **AC-19**：**GIVEN** 玩家章节 1 房间 5 存档 **WHEN** 测 save data **WHEN** 测 **THEN** 包含 `current_room_id: "C-1-room-5"` + `player_pos: Vector2i(5, 5)` + `visited_rooms: [C-1-room-1..5]`。验证：序列化。
- **AC-20**：**GIVEN** 玩家读档回到章节 1 房间 5 **WHEN** 测 room_state **WHEN** 测 **THEN** 房间 = EXPLORING（不是 LOCKED），所有 encounter tile cooldown reset。验证：读档自愈。

## Open Questions

| 问题 | Owner | 截止 | 决议 |
|------|-------|------|------|
| 章节 1 应该有 1 个 boss 还是多个？ | game-designer | 战斗 GDD 阶段 | 当前定：1 个 boss（章节末尾），保持 MVP 紧凑 |
| 隐藏区域是否在 Codex 中独立显示？ | codex | Codex GDD 阶段 | 当前定：是（per #1 C-R8 首次发现） |
| 安全房是否完全无战斗？玩家在安全房能否手动触发战斗？ | game-designer | 战斗 GDD 阶段 | 当前定：完全无遇敌 tile（玩家不能触发），但 NPC / 终端仍可互动 |
| 章节切换是否保留章节 1 的某些状态（如武器 / 弹药）？ | systems-designer | 存档 GDD 阶段 | 当前定：是（玩家全 inventory + weapon_slots 都跨章节保留） |
| 章节 1 是否需要"小 boss"（章节中段非最终 boss）？ | game-designer | 战斗 GDD 阶段 | 当前定：MVP 不加（避免设计蔓延），VS 评估 |
| 玩家从战斗回来时是否应该"知道这个 tile 已遇敌"（视觉提示）？ | art-director + ux-designer | art-bible 阶段 | 当前定：MVP 不加（保持"暗雷"惊喜感） |
| **ENCOUNTER double-trigger 缺显式 AC**：E7 说"ENCOUNTER monitoring = false in BATTLE state"抑制第二次触发，但无 AC 验证。需补 AC-14b："GIVEN 玩家在 BATTLE 状态 + 物理引擎仍报告 ENCOUNTER tile overlap WHEN 测 THEN 该次 trigger 被 `MonitoringToggle` 静默丢弃" | gameplay-programmer | 实施前 | **待补 AC**（lean first review Rec #1, 2026-06-12） |
| **AMMO_LOCKED 门锁 consumption 语义**：C-R5 说"持爆破弹 ≥ 5 发"但**不**明确"开锁时是否消耗"。需明确：AMMO_LOCKED = check ownership only（per #11/#12 C-R8 弹药不消耗）。等 #17 doors-locks GDD 落实 | doors-locks designer | #17 撰写时 | **待 #17 决议**（lean first review Rec #4, 2026-06-12） |
| **C-R6 缺 HIDDEN → EXPLORING 转换**：隐藏区域被发现后应转为正常 EXPLORING。需显式状态转换："HIDDEN → EXPLORING (when first discovered)" | gameplay-programmer | 实施前 | **待补状态转换**（lean first review Rec #5, 2026-06-12） |
| **8 room states 缺 HIDDEN_DISCOVERED 中间态**：玩家发现隐藏区后离开，下次进入时 minimap 应仍标记 visited。需补 HIDDEN_DISCOVERED 状态 | gameplay-programmer | 实施前 | **待补状态**（lean first review Rec #6, 2026-06-12） |
| **章节武器数 vs #11 weapon-ammo TOTAL_WEAPON_TYPES_AVAILABLE = 12 不一致**：F1 章节 1 = 1 weapon drop；3 章节 × 不等数 = 4 武器总数 ≠ 12。Cross-doc reconciliation 需在 `/review-all-gdds` 验证 | systems-designer + game-designer | `/review-all-gdds` 时 | **待 cross-doc 验证**（lean first review Rec #7, 2026-06-12） |
