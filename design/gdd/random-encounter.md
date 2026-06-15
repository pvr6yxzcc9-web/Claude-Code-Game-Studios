# 暗雷遇敌 (Random Encounter)

> **Status**: Approved
> **Author**: user + gameplay-programmer
> **Review Verdict**: APPROVED (first review 2026-06-12, lean)
> **Last Updated**: 2026-06-12 (first review)
> **Implements Pillar**: Pillar 1（探索密度）—— 暗雷的惊喜感激励玩家边走边小心；Pillar 3（每次战斗都是 build 试验）—— 暗雷战 = 不可预测 build 试验

## Summary

暗雷遇敌是 Railhunter 探索的"心跳"——玩家在 EXPLORATION 中移动到 ENCOUNTER tile → 触发 BATTLE 状态 → 战斗结束回 EXPLORATION。它定义 ENCOUNTER tile 的触发机制、每个关卡的"敌人分布表"（哪些 tile 触发哪些敌人）、触发冷却、视觉反馈（per #4 相机 FADE_BLACK）、与 #5 碰撞 ENCOUNTER layer 的契约。

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `关卡/迷宫 #15`（ENCOUNTER tile 位置）、`碰撞 #5`（ENCOUNTER layer）、`战斗核心 #7`（BATTLE 转换）、`状态机 #3`（state_changed）、`相机 #4`（FADE_BLACK）· Depended on by: HUD（遇敌计数）

## Overview

暗雷遇敌是 Railhunter 探索的"心跳"——玩家在 EXPLORATION 中移动到 ENCOUNTER tile → 触发 BATTLE 状态 → 战斗结束回 EXPLORATION。它定义 ENCOUNTER tile 的**触发机制**、每个关卡的**敌人分布表**（哪些 tile 触发哪些敌人）、触发冷却、视觉反馈（per #4 相机 FADE_BLACK 0.4s）、与 #5 碰撞 ENCOUNTER layer 的契约。

本系统**整合**了 4 个 Foundation + 1 个 Core + 1 个 Feature（关卡）：

- #15 关卡：声明 ENCOUNTER tile 位置（per 关卡 C-R4 不可见）
- #5 碰撞：ENCOUNTER layer 6 触发信号
- #3 状态机：`transition_to(BATTLE)` 转换
- #7 战斗核心：BATTLE 状态 + 战斗流程
- #4 相机：FADE_BLACK 转场

玩家**直接接触**这个系统——他们**走**的每一步都可能触发战斗。

如果本系统不存在，**没有战斗触发**——战斗核心 #7 永远不会被调用，整个 gameplay 失效。

**在 5 层 Feature 中**：本系统是**第四个** Feature 系统（#11+#12 武器弹药、#15 关卡 之后）。MVP 1 章节（10 房间 + 25 ENCOUNTER tile per #15 F2）。

## Player Fantasy

玩家**直接接触**这个系统——他们**走**的每一步都可能触发战斗。

他们感受到的，是 **Pillar 1 探索密度的"暗雷惊喜"**：

- **每走一步都有"心跳"**：玩家在走廊里走，每步都"可能"是遇敌 tile——**不可见**（per #15 C-R4），所以**每次移动都带悬念**
- **遇敌瞬间**：屏幕 0.4s 淡黑（per #4 相机 FADE_BLACK）→ 战斗场景淡入——这个 transition 给玩家"我刚被打断了"的惊吓感
- **回 EXPLORATION**：战斗胜利后玩家回到同一 tile（per #5 E2）——可以**再走一遍**触发更多战斗（per Pillar 1 "回头探索"）
- **遇敌计数**：HUD 显示"本章遇敌 X / Y"（Y = 章节总遇敌 tile 数）——**完成度量化**激励玩家战斗
- **变种敌人**：章节 1 末段 ENCOUNTER tile 触发**精英敌人**（HP 80-120）而非普通——玩家后期遇敌更刺激

这背后的情感是 **Pillar 1（探索密度）**——每个 tile 都有"被看见的回报"（战斗 + 战利品）；**Pillar 3（build 试验）**——不可预测的敌人 = 玩家必须**总是**有应对 build。

参考游戏：
- **《重装机兵》FC** —— 暗雷遇敌的灵感
- **Chrono Trigger** —— 视觉化遇敌（敌人从场景中"突袭"）的升级版
- **Into the Breach** —— 明示遇敌（每个 tile 都标注）的对照

> `creative-director` 未咨询（Solo 模式）。

## Detailed Design

### Core Rules

本系统有 **6 条 invariant**。

**C-R1 — ENCOUNTER tile 不可见**。tile 是 trigger Area2D（per #5 LAYER_ENCOUNTER），但**不**画任何视觉。玩家**不**预先知道哪些 tile 遇敌。**禁止**"遇敌 tile 视觉化"——破坏"暗雷"的惊喜感（per #15 C-R4）。

**C-R2 — 遇敌 = transition_to(BATTLE) + 传 enemy_data**。玩家进入 ENCOUNTER tile → 立即 emit `signal encounter_triggered(enemy_data: EnemyData)` → 由 EncounterManager 调 `GameStateMachine.transition_to(BATTLE, payload={enemy_data: ...})`（per #3 状态机）。**禁止**绕过状态机直接调战斗。

**C-R3 — 一次性触发 + 玩家离开后 reset**。tile 触发后 `cooldown = true` + `monitoring = false`（per #15 F3）。玩家离开 tile 区域 → `cooldown = false` + `monitoring = true`（玩家可以再走一遍触发）。**禁止**永久禁用（破坏 Pillar 1 "回头探索"）。

**C-R4 — 战斗结束 = 回到同一 tile**。胜利 / 失败 / 逃跑后，玩家位置 = 触发遇敌时的位置（per #5 E2 战斗暂停）。玩家可以"再走一遍"以触发更多战斗。

**C-R5 — ENCOUNTER distribution table per level**。每个章节有 `EncounterTable: Array[{tile_position, enemy_data, weight}]` —— 哪些位置触发哪些敌人 + 权重。**禁止**程序生成（per #15 C-R1）——所有 ENCOUNTER tile + 触发的敌人**手工设计**。

**C-R6 — 同帧 2 个 ENCOUNTER tile 触发 1 次战斗**。如果玩家 1 步内进入 2 个 ENCOUNTER tile 紧邻，**只**触发 1 次战斗（per #5 E7 战斗风暴防护 + ENCOUNTER layer monitoring = false in BATTLE state）。

### States and Transitions

**4 个 ENCOUNTER tile 状态**（tile 私有，不在 #3 全局）：

| 状态 | 用途 | 转换触发 |
|------|------|----------|
| `READY` | 可触发 | 默认初始 / 玩家离开 |
| `COOLDOWN` | 不可触发（玩家仍在 tile 区域） | `area_entered` 触发后 |
| `TRIGGERED` | 已触发战斗，玩家被传送到 BATTLE | 立即从 COOLDOWN 转 |
| `RESETTING` | 战斗结束，玩家位置恢复，开始监测 | 玩家离开 tile 区域 |

**EncounterTable 结构**：

```yaml
chapter_1:
  - tile_pos: Vector2i(5, 5)
    enemy_data: grunt_01
    weight: 0.60
  - tile_pos: Vector2i(10, 10)
    enemy_data: grunt_02
    weight: 0.30
  - tile_pos: Vector2i(15, 5)
    enemy_data: elite_01
    weight: 0.10
```

### Interactions with Other Systems

| 系统 | 接口 | 触发 |
|------|------|------|
| **关卡 #15** | 提供 ENCOUNTER tile 位置 + EncounterTable | 玩家加载章节 |
| **碰撞 #5** | 订阅 `area_entered(ENCOUNTER layer)` | 玩家进入 tile |
| **状态机 #3** | `transition_to(BATTLE, payload={enemy_data})` | 遇敌触发 |
| **战斗核心 #7** | 接收 enemy_data 初始化战斗 | BATTLE 转换完成 |
| **相机 #4** | 监听到 BATTLE 状态 → FADE_BLACK 0.4s | 状态转换 |
| **HUD** | 推送 `encounter_count: int` / `encounter_total: int` | 玩家进入 / 战斗结束 |

## Formulas

### F1. Encounter Density per Room (per #15 F2)

`avg_encounter_tiles_per_room = 2.5`（章节 1 MVP）

| 章节 | 房间 | 总 ENCOUNTER tile | 平均 / 房间 |
|------|------|-------------------|-------------|
| 1（MVP） | 10 | ~25 | 2.5 |
| 2（VS） | 12 | ~36 | 3.0 |
| 3（VS） | 14 | ~50 | 3.5 |

### F2. Enemy Distribution per Encounter

`grunt_ratio = 0.80`, `elite_ratio = 0.18`, `boss_ratio = 0.02`

| 章节 | 普通 (grunt) | 精英 (elite) | boss |
|------|--------------|--------------|------|
| 1 | 22 (88%) | 3 (12%) | 0 |
| 2 | 28 (78%) | 7 (19%) | 1 |
| 3 | 32 (64%) | 16 (32%) | 2 |

**Rationale**: 章节越深入，精英 / boss 比例越高（per Pillar 3 战斗挑战升级）。

### F3. Encounter Frequency per Minute

`encounters_per_minute = (move_speed_tiles_per_sec × 60) × avg_encounter_density`

| 玩家移动速度 | 章节 1 遇敌频率 | 章节 3 遇敌频率 |
|---------------|------------------|------------------|
| 4 tile/s（标准） | 1.0 场 / 25 秒 | 1.0 场 / 17 秒 |
| 8 tile/s（dash 加速） | 1.0 场 / 12 秒 | 1.0 场 / 8 秒 |

**Output Range**: 章节 1 = 25 秒/场战斗，章节 3 = 17 秒/场。**Edge case**: dash 加速让遇敌翻倍——激励玩家"安全慢走"。

### F4. Total Encounter Time per Chapter

`expected_encounter_minutes = encounters_per_chapter × avg_battle_duration_minutes`

| 章节 | 总遇敌数 | 战斗时长（per #7） | 遇敌总时长 |
|------|----------|---------------------|-------------|
| 1 | 25 | 1.0 min | 25 min |
| 2 | 36 | 1.2 min（精英更多） | 43 min |
| 3 | 50 | 1.5 min | 75 min |

**Note**: 加上房间探索时间，符合 #15 F3 章节时长公式。

## Edge Cases

| # | 条件 | 结果 | 原因 |
|---|------|------|------|
| 1 | **玩家 1 帧内进入 2 个 ENCOUNTER tile 紧邻** | 第二次触发被抑制（per #5 E7 + ENCOUNTER monitoring = false in BATTLE） | 战斗风暴防护 |
| 2 | **战斗胜利回到 EXPLORATION，玩家在原 tile 中心** | tile.cooldown = false，玩家可以"再走一遍" | per C-R3 一次性触发 + 离开 reset |
| 3 | **玩家死亡 → TITLE → 新游戏 → 回到同章节同 tile** | tile.cooldown = false（新游戏状态） | 死亡不重置进度（per #3 死亡流） |
| 4 | **同章节遇敌 1000 次 Monte Carlo** | 每个 tile 的触发次数应符合 EncounterTable 权重分布 | 防止 RNG 不公 |
| 5 | **玩家站 ENCOUNTER tile 边缘不动** | 玩家跨入 tile 时触发，不重复触发 | per C-R3 area_entered 单次触发 |
| 6 | **ENCOUNTER tile 在安全房** | 章节 1 ~20% 房间无 ENCOUNTER tile（per #15 F2 SAFE_ROOM_RATIO） | 给玩家喘息 |
| 7 | **dash 进入 ENCOUNTER tile 速度太快** | 触发正常，遇敌 transition 不变 | 速度不影响触发 |
| 8 | **Boss 战遇敌 tile 重复触发** | Boss 房 ENCOUNTER tile = 1（per #15 F2）触发后 monitoring = false | Boss 房 1 次遇敌 |

## Dependencies

### 上游依赖

| 系统 | 接口 | 备注 |
|------|------|------|
| **关卡 #15** | 提供 ENCOUNTER tile 位置 + EncounterTable | 章节加载时 |
| **碰撞 #5** | 订阅 `area_entered(ENCOUNTER layer)` | 玩家进入 |
| **状态机 #3** | `transition_to(BATTLE, payload={enemy_data})` | 触发 |
| **战斗核心 #7** | 接收 enemy_data | BATTLE 初始化 |
| **相机 #4** | FADE_BLACK 0.4s 转场 | 状态转换 |

### 下游依赖

| 系统 | 接口 | 备注 |
|------|------|------|
| **HUD** | 推送 `encounter_count: int` / `encounter_total: int` | 玩家进入 + 战斗结束 |
| **存档 #21** | 序列化 encounter_count | 章节完成度 |

### 双向约束

| 约束 | 在 #15 中 | 在本 GDD 中 |
|------|----------|-------------|
| ENCOUNTER tile 不可见 | #15 C-R4 | C-R1 |
| 一次性触发 + 离开 reset | #15 F3 | C-R3 |
| 战斗回到同 tile | #5 E2 | C-R4 |
| ENCOUNTER distribution table per level | #15 字段（pos + enemy_data） | C-R5 权重 |
| 同帧 2 tile 触发 1 次 | #5 E7 | C-R6 |

## Tuning Knobs

| 参数 | 当前默认值 | 安全范围 | 调高 → | 调低 → | 为什么取这个数 |
|------|------------|----------|---------|---------|----------------|
| `AVG_ENCOUNTER_TILES_PER_ROOM` | 2.5 | 1.5–4.0 | 战斗频繁 | 战斗稀疏 | per #15 F2 |
| `GRUNT_RATIO_CHAPTER_1` | 0.88 | 0.60–0.95 | 普通太多（无聊） | 普通太少（破坏入门体验） | 88% = 章节 1 主要挑战是普通 |
| `ELITE_RATIO_CHAPTER_1` | 0.12 | 0.05–0.30 | 章节 1 太难 | 章节 1 没精英 | 12% = 章节 1 后段 3 个精英 = 玩家备战 |
| `ENCOUNTER_COOLDOWN_RESET_ON_LEAVE` | true | true / false | 玩家"再走一遍" 触发（per Pillar 1 回头探索） | tile 永久禁用 | Pillar 1 鼓励回头 |
| `TILE_RETRIGGER_VISUAL_HINT` | false | true / false | 玩家看到"已触发"提示 | 保持暗雷惊喜 | MVP 不加（per #15 OQ-6） |
| `BOSS_TILE_RETRIGGER` | false | true / false | BOSS 战可重复触发 | — | BOSS 房 1 次触发 |

### 跨系统杠杆

| 杠杆 | 影响范围 | 当前值 | 调高 → | 调低 → |
|------|----------|---------|---------|---------|
| `AVG_ENCOUNTER_TILES_PER_ROOM` | 战斗密度 | 2.5 | 战斗频繁 | 战斗稀疏 |
| `ELITE_RATIO_CHAPTER_1` | 章节难度曲线 | 0.12 | 章节 1 后段太难 | 章节 1 后段没变化 |

## Visual/Audio Requirements

| 事件 | 视觉反馈 | 音频反馈 | 备注 |
|------|----------|----------|------|
| 玩家进入 ENCOUNTER tile | 屏幕 0.4s 淡黑（per #4 相机 FADE_BLACK） | 遇敌音（短促警告） | per C-R2 |
| 战斗回到 EXPLORATION | 屏幕 0.4s 淡黑淡入（per #4 FADE_BLACK 反向） | 战斗结束音 | per C-R4 |
| 战斗胜利 | 玩家机甲特写 1.5s + VICTORY rig | 胜利音乐 | per #4 C-R5 + #7 |
| 战斗失败 | 玩家机甲倾斜 3° + DEFEAT rig | 失败音乐 | per #4 C-R5 + #7 |

## UI Requirements

| 信息 | 消费者 | 触发 | 备注 |
|------|--------|------|------|
| 遇敌计数 "X / Y" | HUD | 玩家进入 / 战斗结束 | 章节完成度 |
| 战利品弹出 | HUD | 战斗胜利 | per #11+#12 |
| 状态徽章 `BATTLE` | HUD | 状态转换 | per #2 UI-2b |

**关键约定**：本系统**不直接渲染**任何 UI widget——只**提供** `encounter_count: int` 和 `encounter_total: int` 给 HUD，HUD 自己渲染。

## Acceptance Criteria

> Solo 模式（`qa-lead` 未咨询），生产前人工 review。

### 基础触发

- **AC-1**：**GIVEN** 玩家在 EXPLORATION 走进 ENCOUNTER tile **WHEN** 测触发 **THEN** 0.4s 淡黑 + `transition_to(BATTLE, payload={enemy_data})` + 战斗初始化。验证：C-R2。
- **AC-2**：**GIVEN** 玩家进入 ENCOUNTER tile **WHEN** 测 tile state **THEN** tile.cooldown = true + tile.monitoring = false。验证：C-R3。
- **AC-3**：**GIVEN** 玩家战斗胜利回到 EXPLORATION + 玩家离开 tile 区域 **WHEN** 测 tile state **THEN** tile.cooldown = false + tile.monitoring = true。验证：C-R3 reset。

### 同帧 2 tile 防护

- **AC-4**：**GIVEN** 玩家 1 帧内进入 2 个 ENCOUNTER tile 紧邻 **WHEN** 测触发 **THEN** 只触发 1 次战斗（per #5 E7 + ENCOUNTER monitoring = false in BATTLE）。验证：C-R6 + #5 E7。

### 战斗返回

- **AC-5**：**GIVEN** 玩家在 tile (5,5) 触发战斗 **WHEN** 战斗结束回 EXPLORATION **THEN** 玩家位置 = (5,5)，房间 = EXPLORING。验证：C-R4。
- **AC-6**：**GIVEN** 玩家战斗失败 → state replace(TITLE) → 新游戏 **WHEN** 测 tile state **THEN** tile.cooldown = false（新游戏状态）。验证：E3。

### 密度与权重

- **AC-7**：**GIVEN** 章节 1 25 ENCOUNTER tile 触发 1000 次 Monte Carlo **WHEN** 测敌人分布 **THEN** grunt ~88%, elite ~12%, boss 0（per F2 表）。验证：RNG 公平。
- **AC-8**：**GIVEN** 玩家章节 1 标准速度走 60 秒 **WHEN** 测遇敌数 **THEN** ~2-3 场战斗（per F3 = 25 秒/场）。验证：F3 频率。

### 视觉 / 集成

- **AC-9**：**GIVEN** 玩家遇敌 **WHEN** 测视觉 **THEN** 屏幕 0.4s 淡黑 + 战斗场景淡入（per #4 FADE_BLACK）。验证：#4 集成。
- **AC-10**：**GIVEN** 玩家遇敌 **WHEN** 测 HUD 遇敌计数 **THEN** 显示 "X+1 / 25"。验证：HUD 推送。
- **AC-11**：**GIVEN** 玩家战斗失败 → BATTLE_END_DEFEAT **WHEN** 测相机 **THEN** DEFEAT rig + 3° roll + 灰度。验证：#4 + #7 集成。

## Open Questions

| 问题 | Owner | 截止 | 决议 |
|------|-------|------|------|
| 是否要"可见遇敌区域"（visually marked area = 100% 遇敌）作为"安全 vs 危险"提示？ | level-designer + art-director | 关卡 GDD 阶段 | 当前定：MVP 全部不可见（保持暗雷），VS 评估"可见"模式 |
| Boss 战遇敌后，玩家死亡回标题 vs 章节 1 末尾？ | game-designer | 战斗 GDD 阶段 | 当前定：回标题（per #7 + #3 死亡流） |
| 章节切换时遇敌计数重置？ | game-designer | 存档 GDD 阶段 | 当前定：每个章节独立计数（章节 1 = 25, 章节 2 = 36...） |
| ENCOUNTER tile 的视觉提示（per 1.5s 红圈闪烁）是否打破"暗雷"核心？ | game-designer | art-bible 阶段 | 当前定：MVP 保持不可见（per C-R1） |
| 玩家多次刷同一 tile（cooldown 反复 reset）是否会被认为是"刷怪"？ | game-designer | 战斗 GDD 阶段 | 当前定：是的，这是**有意的**（per Pillar 1 回头探索 + 自动模式刷图） |
| **C-R3 cooldown reset duration 缺显式值**：C-R3 说"玩家离开 tile 区域 → cooldown = false"，但**不**明确"离开"是 instant 还是 N 秒后。需补：`cooldown_reset_delay_s = 0.2`（tunable, 防 pixel-exploit "leave 1 pixel → re-enter"） | gameplay-programmer | 实施前 | **待补默认值**（lean first review Rec #2, 2026-06-12） |
| **HUD "X / Y" 计数器语义不清**：C-R3 + OQ #5 都明确"刷怪是有意的"，但 HUD 推送的 `encounter_count` 应该是 per-tile-unique（X = 触发了多少**不同** tile）还是 total-triggers（X = 累加触发次数）？当前定：per-tile-unique（X / 25 = 25 个 tile 各触发至少 1 次 = 100%）。需明确"重复触发不计数" | ui-programmer + gameplay-programmer | HUD GDD 阶段 | **待 HUD GDD 决议**（lean first review Rec #5, 2026-06-12） |
