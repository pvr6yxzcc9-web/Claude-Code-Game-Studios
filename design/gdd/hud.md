# HUD

> **Status**: Approved
> **Author**: user + ui-programmer + ux-designer + art-director
> **Review Verdict**: APPROVED (first review 2026-06-12, lean)
> **Last Updated**: 2026-06-12 (first review)
> **Implements Pillar**: Pillar 1（探索密度）—— HUD 始终可见，玩家随时知道"我在哪 / 我有多少 / 我在干嘛"

## Summary

HUD 是 Railhunter **所有玩家可见信息**的容器。它定义：HP 条、机甲部位状态、当前武器 / 弹药、模式徽章（MANUAL / AUTO）、敌人 HP、回合阶段、遇敌计数、战利品、状态徽章（per #2 玩家输入 UI-2b）、拾取弹窗、伤害数字、章节结算屏。HUD 在**独立 CanvasLayer**（rendering layer 10）——不受相机变换影响。

> **Quick reference** — Layer: `Presentation` · Priority: `MVP` · Key deps: 几乎所有 Foundation + Feature（消费它们的 `state: Dictionary`）· Depended on by: 菜单 / 暂停 #23（独立 GDD）、Codex #20

## Overview

HUD 是 Railhunter **所有玩家可见信息**的容器。它定义 14 个 HUD 元素：HP 条、机甲 4 部位状态、当前武器 / 弹药、模式徽章（MANUAL / AUTO）、敌人 HP、回合阶段、遇敌计数、伤害数字、战利品、状态徽章（per #2 玩家输入 UI-2b）、拾取弹窗、章节结算屏、终端内容框、真相碎片解锁。

HUD 在**独立 CanvasLayer**（rendering layer 10）—— 不受相机变换影响（per #4 C-R7 独立 UI 规则 + #2 玩家输入 C-R7）。**例外**：shake 期间 CanvasLayer 以 0.5x 幅度跟着 shake（避免画面撕裂感，per #4 C-R7 + #2 AC-14）。

本系统**几乎消费**所有 Foundation + Feature 系统的 `state: Dictionary`：
- #3 状态机 → 状态徽章
- #7 战斗核心 → battle_state（HP、模式、回合、伤害）
- #15 关卡 → 房间名 / 遇敌计数
- #11+#12 武器弹药 → 武器 / 弹药显示
- #18 NPC / 终端 → 终端内容
- 等等

玩家**直接接触**这个系统——**永远在屏幕上看它**。

如果本系统不存在，**玩家什么都看不到**——所有状态变化都是"无视觉反馈的内部状态"。

**在 5 层 Presentation 中**：本系统是**第一个** Presentation 系统（按 dependency sort），依赖几乎所有 Feature 系统。

## Player Fantasy

玩家**永远在看 HUD**——这是他们"游戏状态"的**唯一**视觉来源。

他们感受到的，是 **"我永远知道现在在干嘛"** 的清晰感（per #2 玩家输入 modal transparency 承诺）：

- **HP 条**（左下 / 或顶部）：玩家 4 部位机甲 HP 实时变化
- **状态徽章**（左上）：`EXPLORATION` / `BATTLE` / `TERMINAL` / `PAUSED` + BATTLE 时 MANUAL/AUTO 子指示器
- **武器 / 弹药**（右下）：3 个武器槽 + 当前弹药 + build 伤害预览
- **敌人 HP**（战斗时，顶部）：当前敌人 HP + 弱点提示
- **回合阶段**（战斗时，底部）：`PLAYER_INPUT` / `ENEMY_INPUT` 等
- **遇敌计数**（顶部小字）："本章 X / 25"
- **伤害数字**：命中 / 受击时的飘字
- **战利品**：战斗胜利时弹出
- **拾取弹窗**：获得新武器 / 弹药时
- **终端内容框**：读终端 / NPC 时
- **真相碎片解锁**：读终端后弹出
- **章节结算屏**：章节完成时
- **模式徽章**：BATTLE 时 MANUAL ↔ AUTO 切换

这背后的情感是 **Pillar 1（探索密度）**——HUD 始终可见，玩家随时知道状态；**Pillar 2（发现 > 数值）**——新武器拾取、真相碎片解锁都是 HUD 弹窗给"我发现了"的反馈。

参考游戏：
- **Into the Breach** —— 极简 HUD 的典范
- **Outer Wilds** —— 信息密度高但不杂乱
- **极乐迪斯科** —— 文字密度高 + 视觉简洁

> `creative-director` 未咨询（Solo 模式）。

## Detailed Design

### Core Rules

本系统有 **7 条 invariant**。

**C-R1 — HUD 在独立 CanvasLayer**。所有 HUD 元素位于 `CanvasLayer` 节点，`layer = 10`（高于游戏世界但低于系统 modal）。不受相机 transform / zoom 影响（per #4 C-R7 独立 UI 规则）。

**C-R2 — shake 期间 CanvasLayer 跟 0.5x 幅度 shake**。相机 shake 时（命中 / 受击 / DEFEAT），HUD 元素以 0.5x 幅度跟着 shake（避免画面撕裂感，per #2 AC-14）。**禁止** HUD 静止 = 玩家感觉"画面和 UI 分离"。

**C-R3 — 状态徽章 = 永远可见**。per #2 UI-2b 状态徽章（包括 BATTLE + MANUAL/AUTO 子指示器）**任何** fullscreen overlay 期间都**不**被隐藏（per #2 AC-19）。在 EXPLORATION / BATTLE / TERMINAL / CODEX / PAUSE 全部状态都可见。

**C-R4 — HUD 元素按 Pillar 1 优先级排**。**永远可见**（按重要度）:
1. 状态徽章（左上，per C-R3）
2. 模式徽章（仅 BATTLE，左上邻接状态徽章）
3. HP 条 + 4 部位（小，左下）
4. 武器槽（右下）
5. 当前弹药（右下邻接武器）
6. 敌人 HP（战斗时，顶部）
7. 回合阶段（战斗时，底部）

**按需可见**：
- 遇敌计数（顶部小字）
- 伤害数字（飘字 0.5s）
- 战利品弹出（胜利时）
- 拾取弹窗（拾取时）
- 终端内容框（push TERMINAL 时）
- 真相碎片解锁（解锁时）
- 章节结算屏（章节完成时）
- "按 E 互动" 提示（per #2 + #5 F4）

**C-R5 — HUD 不持有游戏状态**。HUD **只**消费 `state: Dictionary` 数据，**不**写。所有数据所有权归对应系统（#7 战斗持 battle_state，#11+#12 武器弹药持 weapon_slots，#3 状态机持 state_stack）。**禁止** HUD 修改任何游戏状态。

**C-R6 — HUD 帧率恒定 60 FPS**。HUD 渲染**不**超过 1ms / 帧（per performance budget 16.6ms）。包括飘字动画、图标切换、状态徽章更新。

**C-R7 — HUD 字体 = art-bible 字体**。per art-bible "深空废墟中孤独的霓虹"调色 + 字体约定。**禁止**用默认系统字体（破坏视觉一致性）。

### States and Transitions

**14 个 HUD 元素**：

| 元素 | 位置 | 可见条件 | 数据源 |
|------|------|----------|--------|
| 状态徽章 | 左上 (24, 24) | 永远（per C-R3） | #3 状态机 |
| 模式徽章 | 邻接状态徽章 | 仅 BATTLE | #2 玩家输入 |
| 玩家 HP 条 | 左下 (24, 600) | 永远 | #7 战斗 + #13 机甲 |
| 机甲 4 部位状态 | HP 条下方 | 永远 | #13 机甲 |
| 武器槽 0/1/2 | 右下 (1100, 600) | 永远 | #11+#12 武器弹药 |
| 当前武器 / 弹药 | 武器槽上方 | 永远 | #11+#12 武器弹药 |
| 敌人 HP | 顶部 (200, 80) | BATTLE 期间 | #7 战斗 |
| 敌人 4 部位 | 敌人 HP 下方 | BOSS 期间 | #13 机甲 |
| 回合阶段 | 底部 (500, 700) | BATTLE 期间 | #7 战斗 |
| 遇敌计数 | 顶部 (24, 80) | EXPLORATION | #16 暗雷 |
| 伤害数字 | 飘字 | 命中时 | #7 战斗 |
| 战利品弹出 | 屏幕中央 | 战斗胜利 | #7 战斗 + #11+#12 武器弹药 |
| 拾取弹窗 | 屏幕中央 | 拾取时 | #11+#12 武器弹药 |
| 终端内容框 | 屏幕中央 | TERMINAL state | #18 NPC/终端 |
| 真相碎片解锁 | 屏幕中央 | unlock 时 | #18 NPC/终端 |
| 章节结算屏 | 全屏 | 章节完成 | #3 状态机 + #15 关卡 |
| "按 E 互动" | 玩家机甲附近 | INTERACTABLE 进入 | #2 玩家输入 + #5 F4 |

### Interactions with Other Systems

| 系统 | 接口 | 触发 |
|------|------|------|
| **状态机 #3** | 订阅 `state_changed` → 更新状态徽章 | 状态转换 |
| **战斗核心 #7** | 推送 `battle_state: Dictionary` | 每帧 |
| **武器弹药 #11+#12** | 推送 `inventory_state: Dictionary` | 每帧 + 拾取时 |
| **关卡 #15** | 推送 `room_info: Dictionary` | 进入房间 |
| **暗雷 #16** | 推送 `encounter_count: int` | 战斗结束 |
| **NPC/终端 #18** | 推送 `terminal_state: Dictionary` | push(TERMINAL) |
| **玩家输入 #2** | 推送 `mode: StringName` + interactable 提示 | 模式切换 + 玩家走近 |
| **碰撞 #5** | INTERACTABLE 提示（per #2 + #5 F4） | 玩家走近 |
| **存档 #21** | 序列化 HUD 状态 | 存档 |

## Formulas

### F1. HUD Render Performance

`hud_render_time_ms = 14_elements × render_cost_each`

| 元素 | 期望渲染时间 | 上限 |
|------|---------------|------|
| 状态徽章 | 0.05ms | 0.1ms |
| HP 条 + 4 部位 | 0.15ms | 0.3ms |
| 武器槽 + 弹药 | 0.2ms | 0.4ms |
| 敌人 HP + 部位（BOSS） | 0.2ms | 0.4ms |
| 回合阶段 | 0.05ms | 0.1ms |
| 遇敌计数 | 0.05ms | 0.1ms |
| 伤害数字（飘字） | 0.1ms | 0.2ms |
| 战利品弹出 | 0.1ms | 0.2ms |
| 拾取弹窗 | 0.1ms | 0.2ms |
| 终端内容框 | 0.3ms | 0.5ms |
| 真相碎片解锁 | 0.1ms | 0.2ms |
| 章节结算屏 | 0.3ms | 0.5ms |
| "按 E 互动" | 0.05ms | 0.1ms |
| Shake offset | 0.1ms | 0.2ms |
| **总计** | **1.95ms** | **3.5ms** |

**Output Range**: 2-4ms 总渲染。**Edge case**: 多个弹窗同帧 = 接近 5ms 上限，但仍在 16.6ms 帧预算内。

### F2. Damage Number Float

```
damage_number.position = start_pos + Vector2(0, -50) * ease_out_quad(t / 0.5s)
damage_number.opacity = 1.0 - (t / 0.5s)
```

| 变量 | 类型 | 范围 | 描述 |
|------|------|------|------|
| `start_pos` | Vector2 | 屏幕坐标 | 伤害发生的位置 |
| `t` | float | 0-0.5 | 飘字时间 |
| `easing` | String | "ease_out_quad" | 缓动函数 |

**Default**: 飘字 0.5s + 向上 50px + 渐变消失。

### F3. HP Bar Smooth Lerp

`hp_bar.fill_amount = lerp(hp_bar.fill_amount, target_hp_pct, 0.20)`

**Default**: 0.20 lerp factor（per #2 玩家输入 F2 跟随常数），HP 变化丝滑不抖。

### F4. Weapon Slot Pulse on Active

```gdscript
if weapon_slot_idx == active_slot:
    weapon_slot_ui.scale = 1.0 + 0.10 * sin(time * 8.0)  # 8 Hz pulse
else:
    weapon_slot_ui.scale = 1.0
```

**Output**: 当前激活武器槽轻微脉动 0.5Hz（视觉提示）。

## Edge Cases

| # | 条件 | 结果 | 原因 |
|---|------|------|------|
| 1 | **窗口 resize 1280×800 → 1920×1080** | HUD 元素按比例重定位（per #4 AC-12 协同） | resize 处理 |
| 2 | **shake + 弹窗同帧** | shake 影响弹窗（per C-R2），弹窗位置仍正确 | 不冲突 |
| 3 | **战利品 + 拾取弹窗同帧**（双敌人同帧掉落） | 战利品先弹，拾取弹窗后弹（per #11+#12 E12 串行） | 避免 UI 叠加 |
| 4 | **状态徽章被多 overlay 叠加**（CODEX + PAUSE） | 显示**最顶层**的 overlay（PAUSE 优先） | 玩家"知道在哪" |
| 5 | **终端内容框超长**（> 1000 字） | 自动分页 + 玩家按 SPACE 下一页 | 文本溢出处理 |
| 6 | **真相碎片 unlock + Codex 更新同帧** | unlock 弹窗 + Codex 节点亮起**同时**显示 | per #18 C-R3 + #19 |
| 7 | **BOSS 4 部位 + 普通敌人** | BOSS 显示 4 部位，普通敌人**只**显示总 HP（不显示部位） | UI 简洁 |
| 8 | **HP 变化极快**（BOSS 重击 50 伤害） | HP 条按 0.20 lerp 平滑过渡（per F3），不抖 | F3 lerp |
| 9 | **章节结算屏 + 状态徽章** | 章节结算屏全屏，状态徽章**隐藏**（结算屏是"宣告完成"，模态比状态重要） | C-R3 永远可见**有例外**：结算屏期间 |
| 10 | **伤害数字 0**（防御减伤后为 0） | 显示 "0" 文字但**不**飘字 | 0 伤害视觉噪音 |

## Dependencies

### 上游依赖（几乎所有系统）

| 系统 | 接口 | 备注 |
|------|------|------|
| **状态机 #3** | 状态徽章 | state_changed |
| **战斗核心 #7** | battle_state | 每帧 |
| **武器弹药 #11+#12** | inventory_state | 每帧 + 拾取 |
| **关卡 #15** | room_info | 进入房间 |
| **暗雷 #16** | encounter_count | 战斗结束 |
| **NPC/终端 #18** | terminal_state | push(TERMINAL) |
| **玩家输入 #2** | mode + interactable 提示 | 模式切换 + 走近 |
| **碰撞 #5** | INTERACTABLE 提示 | 走近 |

### 下游依赖

| 系统 | 接口 | 备注 |
|------|------|------|
| **菜单 / 暂停 #23** | 菜单 UI 独立于 HUD | 独立 GDD |
| **Codex #20** | 独立 UI 浮层 | VS 阶段 |
| **存档 #21** | HUD 状态序列化 | 存档 |

## Tuning Knobs

| 参数 | 当前默认值 | 安全范围 | 调高 → | 调低 → | 为什么取这个数 |
|------|------------|----------|---------|---------|----------------|
| `HUD_CANVAS_LAYER` | 10 | 5-20 | 高于系统 modal | 低于系统 modal | layer 10 = 高于游戏但低于 modal |
| `HUD_SHAKE_FACTOR` | 0.5 | 0.0-1.0 | UI 完全跟 shake（视觉撕裂感） | UI 静止（画面撕裂感） | 0.5 = 平衡 |
| `HP_BAR_LERP_FACTOR` | 0.20 | 0.05-0.50 | HP 变化过快（晕） | HP 变化过慢（拖泥带水） | 0.20 = 丝滑 |
| `DAMAGE_FLOAT_DURATION_S` | 0.5 | 0.3-1.0 | 飘字过长 | 飘字过短 | 0.5s = 30 帧 |
| `DAMAGE_FLOAT_DISTANCE_PX` | 50 | 20-100 | 飘字过高 | 飘字过近 | 50 = 1.5 个 tile |
| `WEAPON_SLOT_PULSE_HZ` | 0.5 | 0.0-2.0 | 脉动过频 | 不脉动 | 0.5 Hz = 微妙 |
| `STATE_BADGE_TRANSITION_FADE_MS` | 0 | 0-200 | 状态徽章淡入淡出 | 瞬切 | per #2 UI-2b 修订，MVP 瞬切 |
| `BOSS_PART_VISIBILITY` | true | true / false | BOSS 显示 4 部位 | 普通敌人也显示 | BOSS 专用 |

### 跨系统杠杆

| 杠杆 | 影响范围 | 当前值 | 调高 → | 调低 → |
|------|----------|---------|---------|---------|
| `HP_BAR_LERP_FACTOR` | HP 视觉反馈 | 0.20 | 玩家感觉数字抖 | 玩家感觉"反应慢" |
| `DAMAGE_FLOAT_DURATION_S` | 命中反馈 | 0.5 | 飘字慢 | 飘字快 |

## Visual/Audio Requirements

| 元素 | 视觉 | 音频 | 备注 |
|------|------|------|------|
| 状态徽章 | 顶部左上，文字 | 状态转换音（per #2） | per C-R3 |
| HP 条 | 底部，红色 | — | per F3 lerp |
| 机甲 4 部位 | 4 小条，per art-bible | 部位损坏时特殊音 | per #13 |
| 武器槽 | 右下，3 个方格 | 切换时装备音 | per F4 脉动 |
| 弹药 | 右下邻接武器 | 切换音 | per #11+#12 |
| 状态徽章 MANUAL/AUTO | 邻接状态徽章 | 模式切换音 | per #2 G-F2 |
| 敌人 HP | 顶部，红色 + 弱点提示 | — | per #7 |
| 回合阶段 | 底部 | 你的回合 / 敌人回合音 | per #7 |
| 伤害数字 | 飘字 0.5s，per 颜色区分（暴击 = 黄 / 弱点 = 红） | 命中音 | per F2 |
| 战利品 | 屏幕中央 icon | 战利品音 | per #7 |
| 拾取弹窗 | 屏幕中央 | 拾取音 | per #11+#12 |
| 终端内容 | 屏幕中央文本框 + 进度条 | 日志音频 | per #18 |
| 真相碎片解锁 | 屏幕中央 | 解锁音 | per #18 |
| 章节结算 | 全屏 + 完成度 + 武器库 | 章节完成音 | per #15 |
| "按 E 互动" | 玩家机甲附近 | 提示音 | per #2 + #5 |

## UI Requirements

> 本系统**就是** UI Requirements——所有 UI 由本系统实现。

14 个 HUD 元素 + 它们的 layout / 字体 / 颜色全部在本系统中定义（per art-bible）。

**关键原则**：
- 字体：art-bible HUD 字体
- 颜色：art-bible "深空废墟中孤独的霓虹"调色
- 动画：状态徽章 / HP / 弹药切换均有 0.10-0.20s 缓动
- 可访问性：所有文字都有图标 backup（per technical-preferences.md）

## Acceptance Criteria

> Solo 模式（`qa-lead` 未咨询），生产前人工 review。

### 基础渲染

- **AC-1**：**GIVEN** 玩家启动游戏 **WHEN** 测 HUD 渲染 **THEN** 状态徽章 / HP 条 / 武器槽 / 弹药显示，**永远可见**（per C-R3）。验证：基础可见性。
- **AC-2**：**GIVEN** 玩家在 BATTLE **WHEN** 测 HUD **THEN** + 状态徽章变 `BATTLE` + MANUAL/AUTO 邻接 + 敌人 HP + 回合阶段。验证：战斗 HUD 完整。
- **AC-3**：**GIVEN** 玩家在 EXPLORATION **WHEN** 测 HUD **THEN** 状态徽章 `EXPLORATION` + 无敌人 HP / 回合阶段 + 遇敌计数显示。验证：探索 HUD 简洁。

### 状态徽章（per #2 玩家输入 UI-2b）

- **AC-4**：**GIVEN** 玩家打开 Codex **WHEN** 测状态徽章 **THEN** 仍显示 `EXPLORATION`（不被遮挡，per #2 AC-19）。验证：永远可见。
- **AC-5**：**GIVEN** 玩家在 EXPLORATION → BATTLE → 战斗结束 **WHEN** 测状态徽章 **THEN** 变化顺序 `EXPLORATION → BATTLE → EXPLORATION`，每帧更新。验证：状态同步。

### HP / 部位

- **AC-6**：**GIVEN** 玩家受击 30 伤害 **WHEN** 测 HP 条 **THEN** 0.20 lerp 平滑过渡到 170/200，不抖。验证：F3 lerp。
- **AC-7**：**GIVEN** BOSS 战 **WHEN** 测 HUD **THEN** 敌人 4 部位状态显示。验证：BOSS 部位。
- **AC-8**：**GIVEN** 普通敌人战 **WHEN** 测 HUD **THEN** 敌人 4 部位**不**显示，只总 HP。验证：普通敌人简化。

### 武器 / 弹药

- **AC-9**：**GIVEN** 玩家按 1/2/3 切武器 **WHEN** 测 HUD **THEN** 当前武器槽高亮 + 脉动（per F4）+ 装备的武器 icon 切换。验证：武器切换视觉。
- **AC-10**：**GIVEN** 玩家按 Q/E 切弹药 **WHEN** 测 HUD **THEN** 弹药 icon 立即切换 + 伤害预览数字变（per #2 AC-9 / per #11+#12 AC-8）。验证：弹药切换立即。

### 战斗反馈

- **AC-11**：**GIVEN** 玩家粒子炮命中敌人 68 伤害 **WHEN** 测 HUD **THEN** 飘字 "68" 向上 50px 0.5s 渐变消失。验证：F2 飘字。
- **AC-12**：**GIVEN** 玩家防御 + 敌人攻击 25 **WHEN** 测 HUD **THEN** 飘字 "12" + "DEFENDED" 文字。验证：防御反馈。
- **AC-13**：**GIVEN** 玩家命中 0 伤害（防御减伤 100%）**WHEN** 测 HUD **THEN** **不**显示飘字（避免视觉噪音，per E10）。验证：0 伤害处理。

### 战斗结束

- **AC-14**：**GIVEN** 战斗胜利 **WHEN** 测 HUD **THEN** 战利品弹窗显示（icon + 数量）。验证：#7 集成。
- **AC-15**：**GIVEN** 战斗失败 **WHEN** 测 HUD **THEN** 状态徽章变 `PAUSED` 然后 replace(TITLE)。验证：#3 + #7 集成。

### Shake + Resize

- **AC-16**：**GIVEN** 玩家受击 shake 6px **WHEN** 测 HUD 元素 **THEN** HUD 元素以 3px shake 跟（per C-R2 0.5x）。验证：#4 + C-R2 集成。
- **AC-17**：**GIVEN** 玩家 resize 1280×800 → 1920×1080 **WHEN** 测 HUD **THEN** 元素按比例重定位。验证：resize。

### 章节结算

- **AC-18**：**GIVEN** 玩家完成章节 1 全部 10 房间 **WHEN** 测 HUD **THEN** 章节结算屏全屏 + 显示完成度（X/10 房间 + Y/16 回报 + Z/4 真相碎片）。验证：#15 + #18 集成。

### 性能

- **AC-19**：**GIVEN** HUD 全部 14 元素 + shake 渲染 **WHEN** 帧率测试 **THEN** 总渲染时间 ≤ 4ms（per F1）。验证：性能预算。
- **AC-20**：**GIVEN** 战利品 + 拾取弹窗 + 真相碎片 3 弹窗同帧 **WHEN** 测渲染 **THEN** 总时间 ≤ 5ms（仍在 16.6ms 帧预算内）。验证：多弹窗不卡。

## Open Questions

| 问题 | Owner | 截止 | 决议 |
|------|-------|------|------|
| 状态徽章 / 模式徽章 / 敌人 HP / 回合阶段同帧时是否有 z-order 冲突？ | ui-programmer | 实现阶段 | 当前定：z-order = 状态 > 模式 > 敌人 HP > 回合 |
| HUD 在章节结算屏期间**完全隐藏**vs 留状态徽章？ | ux-designer | 章节 GDD 阶段 | 当前定：完全隐藏（per E9 结算屏是模态） |
| 拾取弹窗 4 按钮的 UI 布局？ | ux-designer | 战斗 GDD 阶段 | 当前定：HUD 设计时决定，per #11+#12 4 选项 |
| HUD 字体 = art-bible 字体，但 4 种字重（regular/bold/light/italic）如何分配？ | art-director + ux-designer | art-bible 阶段 | MVP 简化为 2 字重（regular + bold） |
| HUD 在不同窗口尺寸（800×600）下自动重布局？ | ui-programmer | 实现阶段 | 当前定：1280×800 起步，更小窗口 warn + 缩放 |
| **HUD "X / Y" 遇敌计数语义需 commit to per-tile-unique**：#16 random-encounter Rec #5 标记此决议属于 HUD GDD。当前定：HUD 推送 `encounter_count: int` = 触发了多少**不同** tile (per-tile-unique)，**不**累加重触发。需补 C-R 或 F 说明 | gameplay-programmer + ui-programmer | 实施前 | **待补 C-R/F**（lean first review Rec #1, 2026-06-12） |
| **AC-18 章节结算 "Z/4 真相碎片" 硬编码 risk**：#18 npc-terminal F1 说"4 fragments from 6 terminals + 1 NPC with 2 shared"（Rec #2 待 #18 决议）。若 1:1 strict 则 count 不同。HUD 应防御性使用 `unlocked_fragments.size()` 而非 hardcoded "4"。需补 AC-18b: "GIVEN 章节 1 玩家读 3 terminals (1 shared) + 1 NPC WHEN 测 unlocked_fragments = 3" | ui-programmer | 实施前 | **待补 AC-18b**（lean first review Rec #3, 2026-06-12） |
| **HUD save/load 缺 AC**：本 GDD 与 #21 存档接口只 1 行 ("HUD 状态序列化 存档")，无 AC 验证。需补 AC-21: "GIVEN 玩家章节 1 末尾存档 + 重新载入 WHEN 测 HUD THEN 14 元素 = 保存时状态 (HP / weapon slots / encounter count / fragment count) 重现" | gameplay-programmer | 实施前 | **待补 AC-21**（lean first review Rec #4, 2026-06-12） |
| **C-R3 "永远可见" 缺完整 exception 列表**：E9 列出"章节结算屏期间隐藏" 1 个 exception。其他潜在 exception：cutscenes, save/load modal, quit dialog。需枚举: "Always visible EXCEPT during: (1) chapter summary, (2) cutscenes, (3) save/load modal, (4) quit dialog" | ux-designer | 实施前 | **待补 exception 列表**（lean first review Rec #6, 2026-06-12） |
