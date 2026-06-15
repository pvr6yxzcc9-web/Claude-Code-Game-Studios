# 相机系统 (Camera)

> **Status**: Approved
> **Author**: user + game-designer + gameplay-programmer + technical-artist
> **Review Verdict**: APPROVED (first review 2026-06-12, lean)
> **Last Updated**: 2026-06-12 (first review)
> **Implements Pillar**: Pillar 1（探索密度——相机帮助玩家"看见"隐藏要素）+ Pillar 3（每次战斗都是 build 试验——战斗相机让玩家清晰判断敌我位置）

## Summary

相机系统管理 Railhunter 所有"玩家看世界的方式"。它定义 6 个相机机位（探索跟随 / 战斗固定 / 终端特写 / Codex 特写 / 胜利 / 失败）、5 个机位切换效应（瞬切 / 淡黑 / 拉远 / 推进 / 闪白）、屏幕震动（hit-stop 配合）、震动预算、视野限制（暗角 mask），以及与游戏状态机 #3 共享的状态→机位映射。

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `GameStateMachine #3` · Depended on by: 战斗核心 #7、关卡/迷宫 #15、HUD、终端 / Codex

## Overview

相机系统是 Railhunter 所有"玩家看世界的方式"的**单一权威**。它定义 6 个相机机位（探索跟随 / 战斗固定俯瞰 / 终端特写 / Codex 特写 / 胜利机位 / 失败机位）、5 个机位切换效应（瞬切 / 淡黑 / 拉远推进 / 闪白）、屏幕震动（命中反馈、boss 战冲击）、视野限制（暗角 mask — 探索中未照明区域看不清），以及与游戏状态机 #3 共享的"状态 → 默认机位"映射表。

玩家**直接接触**这个系统——他们看到的所有画面都由本系统决定。但**不直接控制**——玩家不能自由旋转相机（密特罗德 Dread 的侧视锁定 + 偶尔拉近推远的"剧照"风格）。

如果本系统不存在，**画面在不同场景之间会"跳"得突兀**——遇敌时画面从走廊突然切到战斗没有过渡、终端特写没有拉近感、命中反馈只有数字没有震动——这是**廉价感**的来源。

**在 5 层 Foundation 中**：本系统是**第 4 层**（与 Resource/Data、Player Input、GameStateMachine、Collision 并列）。它**只**依赖 #3 游戏状态机（决定当前机位），被 #7 战斗、#15 关卡、HUD、终端/Codex 触发。

## Player Fantasy

玩家**感受到**的，是"我看到的世界**总是为此刻服务的**"——不同场景相机机位**显著不同**，让玩家**视觉上立即知道**"我现在应该看什么"。

- **探索中**：相机侧视跟随机甲，视野**有死区**（玩家不一定要每帧都精确对准），暗角 mask 让远处看不清（**鼓励**走近去看）——**"我是考古学家在搜索"**
- **遇敌瞬间**：相机**淡黑**0.4s，战斗场景淡入，**没有"切场"感**——**"无缝转场"**
- **战斗中**：相机**固定俯瞰**战棋盘，**不跟随任何角色**——敌我位置一目了然——**"我是战术指挥官"**
- **命中时**：屏幕短暂**震动**（hit-stop 配合），镜头强调"重"——**"机甲对战有重量"**
- **触发终端**：相机**拉近**到终端屏幕的特写机位（0.6s 推进），玩家视线聚焦到终端 UI——**"现在是听故事的时候"**
- **打开 Codex**：相机**拉远**到全图俯瞰（暗示"全局视角"），Codex 浮在屏幕中央——**"我看到的是收藏的全貌"**
- **胜利后**：相机**推进**到玩家机甲特写，胜利音乐起——**"这是我赢的"**
- **失败后**：相机**倾斜**（3-5° roll）+ 暗角加重，灰度降低——**"我输了"**

这背后的情感是 **Pillar 1（探索密度）**——相机暗角 / 视野限制**激励**玩家探索未照明区域；**Pillar 3（build 试验）**——战斗固定俯瞰让玩家清楚看到 build 效果（哪种弹药击中哪个部位）。

参考游戏：
- **Into the Breach** —— 战斗固定机位的典范
- **Outer Wilds** —— 探索跟随相机的"亲密感"
- **极乐迪斯科** —— 终端 / 日志的"剧照"特写
- **密特罗德 Dread** —— 命中震动的"重量感"

> `creative-director` 未咨询（Solo 模式）。

## Detailed Design

### Core Rules

本系统有 **7 条 invariant**。

**C-R1 — 6 个机位闭集**。`RIG_EXPLORATION_FOLLOW` / `RIG_BATTLE_OVERHEAD` / `RIG_TERMINAL_CLOSEUP` / `RIG_CODEX_WIDE` / `RIG_VICTORY` / `RIG_DEFEAT`。每个机位是一个 `CameraRig` 资源（位置、缩放、跟随目标、限制区域）。新增机位 = 改 GDD + 加资源，**不是**实现决定。

**C-R2 — 单 active rig，一次只能一个**。`current_rig: CameraRig` 是当前激活的机位。其他 5 个机位的节点保留在树中但 `enabled = false`。**避免**多个 Camera 同时激活导致画面叠加（Godot 4.6 的 Camera2D 默认行为是 last-enabled wins，但本系统显式管理避免歧义）。

**C-R3 — GameStateMachine 决定默认机位**。状态机 #3 发出 `state_changed(old, new)` 信号，相机系统查 `STATE_TO_RIG_MAP` 表设置默认机位。**禁止**下游系统直接 `set_rig(X)` 绕过状态机——除非触发胜利 / 失败机位（per C-R5）。

**C-R4 — 5 个机位切换效应**。从 A 切到 B 时，根据 `(A, B)` 对查 `RIG_TRANSITION_MAP` 表决定切换效应：
- `INSTANT`（瞬切，0ms）—— 同类机位（EXPLORATION ↔ BATTLE 内的"过场"）使用
- `FADE_BLACK`（淡黑 0.4s）—— 遇敌、终端、Codex 进/出
- `ZOOM`（缩放 0.6s）—— 终端推进、Codex 拉远
- `FLASH_WHITE`（闪白 0.2s）—— 重大剧情时刻（首遇 boss / 真相揭晓）
- `SHAKE_AND_FADE`（shake + 淡黑 0.6s）—— 战斗失败

**C-R5 — 胜利 / 失败机位由战斗触发**。战斗系统 #7 在 `battle_ended(result)` 信号里指定 `result == "victory"` → `set_rig(RIG_VICTORY)`，`result == "defeat"` → `set_rig(RIG_DEFEAT)`。这两个机位**不**走 `STATE_TO_RIG_MAP`（状态没变，但机位变了）。**特殊豁免**：C-R3 默认机位规则的例外，由战斗系统显式 set。

**C-R6 — 屏幕震动预算**。震动持续时间和幅度有上限，避免长时间震动导致玩家不适。
- 命中震动：0.10s，幅度 4px
- 玩家受击震动：0.15s，幅度 6px
- boss 战重击：0.25s，幅度 10px
- **总和上限**：连续 2 秒内震动累积幅度 ≤ 30px（防止叠加过强）

**C-R7 — 相机不渲染 UI**。所有 UI（HUD、菜单、Codex）位于独立 CanvasLayer（rendering layer 10），不受相机 transform 影响。**例外**：shake 期间，CanvasLayer 也跟着 shake 0.5x 幅度（避免 UI 静止 = 画面撕裂感）。

### States and Transitions

**6 个机位**：

| 机位 ID | 用途 | 跟随目标 | 默认缩放 | 限制区域 |
|---------|------|----------|----------|----------|
| `RIG_EXPLORATION_FOLLOW` | 探索中 | 玩家机甲 | 1.0× | 关卡边界（无） |
| `RIG_BATTLE_OVERHEAD` | 战斗中 | 无（固定） | 1.2× | 战场矩形 |
| `RIG_TERMINAL_CLOSEUP` | 终端 / 日志 | 终端节点 | 2.0× | 终端屏幕矩形 |
| `RIG_CODEX_WIDE` | Codex | 无（俯瞰全图） | 0.6× | 全场景 |
| `RIG_VICTORY` | 战斗胜利 | 玩家机甲 | 1.5× | 玩家周围 200px |
| `RIG_DEFEAT` | 战斗失败 | 玩家机甲 | 0.8× + 3° roll | 玩家周围 200px |

**STATE_TO_RIG_MAP**（由 #3 状态变化触发）：

| 状态 (#3) | 默认机位 |
|----------|----------|
| `TITLE` | `RIG_CODEX_WIDE`（暗藏"全图"主题） |
| `EXPLORATION` | `RIG_EXPLORATION_FOLLOW` |
| `BATTLE` | `RIG_BATTLE_OVERHEAD` |
| `TERMINAL` | `RIG_TERMINAL_CLOSEUP` |
| `CODEX` | `RIG_CODEX_WIDE` |
| `MENU` | **保持**前状态机位（菜单是 overlay，不切换） |
| `PAUSE` | **保持**前状态机位 |

**RIG_TRANSITION_MAP**（机位间切换效应）：

| From → To | 效应 | 持续时间 |
|-----------|------|----------|
| EXPLORATION_FOLLOW → BATTLE_OVERHEAD | FADE_BLACK | 0.4s |
| BATTLE_OVERHEAD → EXPLORATION_FOLLOW | FADE_BLACK | 0.4s |
| EXPLORATION_FOLLOW → TERMINAL_CLOSEUP | ZOOM | 0.6s |
| TERMINAL_CLOSEUP → EXPLORATION_FOLLOW | ZOOM（反向） | 0.6s |
| EXPLORATION_FOLLOW → CODEX_WIDE | ZOOM（拉远） | 0.6s |
| CODEX_WIDE → EXPLORATION_FOLLOW | ZOOM（推进） | 0.6s |
| BATTLE_OVERHEAD → VICTORY | ZOOM（推进到机甲） | 0.6s + 0.3s hold |
| BATTLE_OVERHEAD → DEFEAT | SHAKE_AND_FADE | 0.6s + 3° roll |
| VICTORY / DEFEAT → EXPLORATION_FOLLOW | FADE_BLACK | 0.4s |
| 任何 → 任何（剧情） | FLASH_WHITE | 0.2s |

**机位切换的 C-R3 例外**：战斗系统可在 `BATTLE` 状态中**临时**切到 VICTORY / DEFEAT 机位（per C-R5），状态没变但机位变了。

### Interactions with Other Systems

| 下游系统 | 接口 | 触发 |
|----------|------|------|
| **游戏状态机 #3** | 监听 `state_changed` 信号 + 查询 `STATE_TO_RIG_MAP` | 状态转换 |
| **战斗核心 #7** | `set_rig(RIG_VICTORY / DEFEAT)` + `request_shake(intensity, duration)` | 战斗结束 / 命中 |
| **关卡 / 迷宫 #15** | 设置 `RIG_EXPLORATION_FOLLOW` 的 `follow_target` 为玩家机甲 | 玩家进入区域 |
| **终端 / NPC 触发** | `set_rig(RIG_TERMINAL_CLOSEUP)` + `set_closeup_target(terminal_node)` | 玩家靠近终端 |
| **Codex** | `set_rig(RIG_CODEX_WIDE)` | 玩家按 Tab |
| **HUD** | (无) — UI 在独立 CanvasLayer | — |

**所有权约定**：
- 本系统**唯一拥有**"玩家看哪里"
- 战斗系统**唯一例外**：可设置 VICTORY / DEFEAT 机位（C-R5）
- HUD **不**通过相机——独立 CanvasLayer

## Formulas

### F1. Screen Shake Intensity

`shake_magnitude_px` = 屏幕震动像素位移（最大）。

| 触发类型 | 持续 (ms) | 幅度 (px) | 备注 |
|----------|-----------|----------|------|
| 普通命中 | 100 | 4 | 攻击命中 |
| 玩家受击 | 150 | 6 | 玩家被打 |
| Boss 重击 | 250 | 10 | BOSS 战关键打击 |
| 玩家死亡 | 600 | 12 | DEFEAT 机的复合 shake |

**累加上限**：连续 2 秒窗口内累积幅度 ≤ 30px（per C-R6）。超出 = 削减最近一次震动强度。

### F2. Camera Follow Smoothing (Exploration)

`follow_lerp_factor` = 相机跟随玩家的"滞后"系数。

| 变量 | 类型 | 范围 | 描述 |
|------|------|------|------|
| `lerp_factor` | float | 0.0–1.0 | 0 = 完全不跟，1 = 立即跟（无滞后） |
| `deadzone_px` | float | 0–200 | 玩家在此半径内移动不触发相机移动 |

**Default**：`lerp_factor = 0.10`（滞后 1 帧的 1/10）+ `deadzone_px = 24`（32x32 像素基础单位内不跟）。**Edge case**：lerp_factor = 1.0 = 相机永远贴边（不好玩），lerp_factor = 0.0 = 相机不动（不能探索）。

### F3. Zoom Tween Curve

切换到 `ZOOM` 效应时使用 Easing。

```
zoom_progress = clamp(t / duration, 0.0, 1.0)
zoom_scale = start_scale + (target_scale - start_scale) * ease_out_cubic(zoom_progress)
```

| 变量 | 类型 | 范围 | 描述 |
|------|------|------|------|
| `start_scale` | float | 0.5–2.0 | 起始缩放 |
| `target_scale` | float | 0.5–2.0 | 目标缩放 |
| `duration` | float | 0.3–1.0 (s) | 推进 / 拉远时长 |
| `easing` | String | "linear" / "ease_out_cubic" / "ease_in_out_sine" | 缓动函数 |

**Default**：`duration = 0.6s` + `easing = "ease_in_out_sine"`（前段慢、中间快、末段慢——电影感）。

### F4. Deadzone (Exploration Follow)

玩家在 `deadzone_px` 半径内的移动**不**触发相机移动；超出后才平滑跟随。

```
camera_target_x = player_x ± deadzone_px (whichever the player is closer to)
camera_target_y = player_y ± deadzone_px
camera_pos = lerp(camera_pos, camera_target, lerp_factor)
```

**Edge case**：死区太大 = 玩家走到屏幕边缘才能看到更多（失去探索感）。死区太小 = 相机晃动严重。**Default**：24px（= 32x32 基础单位内）。

### F5. FOV / Zoom Limits

| 缩放值 | 含义 | 何时使用 |
|--------|------|----------|
| 0.6× | 拉远 | Codex 全图 |
| 1.0× | 默认 | 探索 |
| 1.2× | 略拉近 | 战斗 |
| 1.5× | 中度特写 | 胜利机位 |
| 2.0× | 高度特写 | 终端 |

**Range**: 0.5× (最大限度拉远) to 3.0× (最大限度推进). **Edge case**: >2.0× 在 32x32 像素艺术下开始糊（NEAREST 滤镜），所以**默认上限 2.0×**。

## Edge Cases

| # | 条件 | 结果 | 原因 |
|---|------|------|------|
| 1 | **相机目标节点被 free**：玩家机甲被销毁（如死亡流） | `RIG_DEFEAT` 触发，最后一帧记录机甲位置，机位锁定在该位置 + 跟随目标 = `null` | DEFEAT 是不动的"凝固"画面 |
| 2 | **窗口 resize**：1280×800 → 1920×1080 | 所有机位**按比例重算** `Camera2D.zoom` + 视口中心点；当前机位不变 | Godot Camera2D 视口自适应，但 zoom 需要重算以保持视觉一致 |
| 3 | **shake + zoom 同时触发**：命中震动 + 进入终端的 zoom 推进 | shake **优先**完成，zoom 在 shake 结束后开始（per C-R6 累加规则 + 简化时序） | 多个 effect 叠加需要优先级；shake 是"瞬时"反馈，zoom 是"持续"过渡 |
| 4 | **玩家在 1 帧内触发多次状态转换**（不可能但理论上）：脚本调用 `transition_to(BATTLE)` 紧接着 `transition_to(EXPLORATION)` | 第二次 `transition_to` 在第一次完成后**立即**生效；累计 2 个 transition 状态 = 3 个机位切换（EXPLORATION → BATTLE → EXPLORATION），每个都走自己的效应 | 状态机 #3 的合法转换规则 + 相机的 transition map 都通过 |
| 5 | **boss 战用 RIG_BATTLE_OVERHEAD 但战场太大**：boss 战场超出默认机位限制区域 | 相机**自动拉远**到 fit 整个战场（最大 0.8×），玩家和 boss 都进入视口 | 不能让玩家看不到任何战斗单位 |
| 6 | **暂停时进入终端**：玩家在 BATTLE 中按 Q（暂停），然后触发终端（非法，但攻击 UI bug 可能） | 双状态 = 双机位冲突 → 状态机 #3 拒绝 TERMINAL 转换（per #3 合法转换表） | 上游问题，不在本系统处理 |
| 7 | **暗角 mask 渲染开销**：8 个 mask 节点 + 4 个 Light2D 节点 → 帧率掉到 50 FPS | 暗角 mask **必须**预渲染为单个 Sprite + Shader（不是多个 Light2D）；2D 像素游戏不应用 Light2D（贵） | 性能边界在 #1 资源 / Data 和 art-bible 中处理 |
| 8 | **玩家快速 zoom in + zoom out 抖动**：连续开关 Codex 3 次/秒 | 相机在切换中间状态时**不**接受新 transition（"切换锁定"，每 transition 0.6s 内不接受新请求） | 避免 zoom 抖动感 |
| 9 | **CODEX_WIDE 机位 0.6× 让 UI 看着太小**：Codex 字体在 0.6× 缩放下变小 | Codex UI 在独立 CanvasLayer，**不受相机 zoom 影响**（per C-R7 独立 UI 规则） | 已规避 |
| 10 | **过小的窗口（< 800×600）**：UI 占满屏幕，没空间给相机视口 | 触发低分辨率警告 + 缩放锁定 0.8×（不再拉远） | MVP 最低 1280×800 |

## Dependencies

### 上游依赖

| 系统 | 方向 | 接口 | 备注 |
|------|------|------|------|
| **游戏状态机 #3** | 强依赖 | 监听 `state_changed` + 查询 `STATE_TO_RIG_MAP` | 默认机位规则的来源 |

### 下游依赖（5+ 个系统）

| 系统 | 方向 | 性质 | 接口 |
|------|------|------|------|
| **战斗核心 #7** | 强依赖 | Hard | `set_rig(VICTORY / DEFEAT)` + `request_shake(intensity, duration)` |
| **关卡 / 迷宫 #15** | 强依赖 | Hard | 设置 `RIG_EXPLORATION_FOLLOW.follow_target` = 玩家机甲 |
| **终端 / NPC 触发** | 强依赖 | Hard | `set_rig(TERMINAL_CLOSEUP)` + `set_closeup_target(node)` |
| **Codex** | 强依赖 | Hard | `set_rig(CODEX_WIDE)` |
| **HUD** | (无) | — | UI 在 CanvasLayer，不受相机影响 |
| **战斗场景切换 #6** | 弱依赖 | Soft | 监听相机 rig 变化来加载 / 卸载场景 |

### 双向约束（与 #3 状态机共享）

| 约束 | 在 #3 中的位置 | 在本系统中的位置 |
|------|----------------|------------------|
| `state_changed → 默认机位` | #3 信号定义 | 本系统 C-R3 + STATE_TO_RIG_MAP |
| `VICTORY / DEFEAT 机位例外` | #3 信号 payload 决定 | 本系统 C-R5 |
| `MENU / PAUSE 保持前机位` | #3 合法转换表 | 本系统 STATE_TO_RIG_MAP |

## Tuning Knobs

| 参数 | 当前默认值 | 安全范围 | 调高 → | 调低 → | 为什么取这个数 |
|------|------------|----------|---------|---------|----------------|
| `EXPLORATION_LERP_FACTOR` | 0.10 | 0.05–0.30 | 相机反应过灵敏（头晕） | 相机反应过慢（脱离感） | 0.10 = 滞后 1 帧的 1/10，丝滑 |
| `EXPLORATION_DEADZONE_PX` | 24 | 8–80 | 玩家撞屏幕边才看到更多 | 相机持续晃动 | 24 = 32x32 基础单位内 |
| `SHAKE_DEFAULT_DURATION_MS` | 100 | 50–300 | 玩家感觉"过激" | 没反馈 | 100ms = 6 帧 @ 60 FPS = 短促 |
| `SHAKE_DEFAULT_MAGNITUDE_PX` | 4 | 2–12 | 画面太抖 | 没反馈 | 4px = 32x32 像素单位的 1/8，肉眼可见但不晕 |
| `SHAKE_ACCUMULATION_BUDGET_PX` | 30 | 10–60 | 累加过强玩家不适 | 累加上限太低导致反馈被吞 | 30 = 普通震动 7-8 次的累积 |
| `BATTLE_OVERHEAD_ZOOM` | 1.2 | 1.0–1.5 | 战斗画面拥挤 | 看不清敌我 | 1.2 = 略拉近但仍能看到全战场 |
| `CODEX_WIDE_ZOOM` | 0.6 | 0.4–0.8 | 玩家看不清 Codex 内容 | 全图感消失 | 0.6 = 拉远到能看见大区域 |
| `TERMINAL_CLOSEUP_ZOOM` | 2.0 | 1.5–2.5 | 32x32 像素糊 | 看不清终端文字 | 2.0 = NEAREST 滤镜安全上限 |
| `TRANSITION_DURATION_FADE_BLACK_MS` | 400 | 200–800 | 转场太长（玩家烦躁） | 转场突兀 | 400ms = 24 帧，肉眼感知"淡" |
| `TRANSITION_DURATION_ZOOM_MS` | 600 | 300–1200 | 拉远太长 | 没电影感 | 600ms = 36 帧，足够"剧场感" |
| `TRANSITION_LOCK_DURATION_MS` | 600 | 300–1200 | 玩家快速开关 Codex 受限 | 抖动 | 与 zoom 同步 |
| `VICTORY_HOLD_DURATION_MS` | 300 | 0–1000 | 庆祝过长 | 没庆祝 | 300ms = 短暂 hold 让玩家享受胜利 |
| `DEFEAT_ROLL_DEGREES` | 3 | 0–10 | 失败画面太倾斜（晕） | 没失败感 | 3° = 微妙但可感知 |

### 跨系统杠杆

| 杠杆 | 影响范围 | 当前值 | 调高 → | 调低 → |
|------|----------|---------|---------|---------|
| `SHAKE_DEFAULT_MAGNITUDE_PX` | 所有命中反馈的"重量感" | 4 | 战斗感觉更"重" | 战斗感觉"轻飘" |
| `BATTLE_OVERHEAD_ZOOM` | 战斗可读性 | 1.2 | 玩家看清 build 细节 | 玩家看清战略布局 |

## Visual/Audio Requirements

| 事件 | 视觉反馈 | 音频反馈 | 备注 |
|------|----------|----------|------|
| 命中震动 | 屏幕 4px shake / 100ms | 命中音（由战斗系统触发） | per C-R6 |
| 玩家受击 | 屏幕 6px shake / 150ms | 受伤音 | per C-R6 |
| 状态转换（淡黑） | 屏幕 0.4s 渐变到黑 | 转换音（短低音） | per RIG_TRANSITION_MAP |
| 状态转换（拉近 / 推远） | zoom 0.6s 缓动 | 静音（避免刺耳） | per RIG_TRANSITION_MAP |
| 闪白（重大剧情） | 屏幕 0.2s 渐变到白 | 低频 bell | per RIG_TRANSITION_MAP |
| 暗角 mask（探索中） | Sprite + Shader 预渲染 | 静音 | 不使用 Light2D（性能） |
| DEFEAT roll | 3° 倾斜 + 灰度降低 | 失败音 | 倾斜是 DEFEAT 专属 |

> 详见 `design/art/art-bible.md` 的色彩 + 动画原则。

## UI Requirements

| 信息 | 消费者 | 触发 | 备注 |
|------|--------|------|------|
| 当前 rig 名称（debug only） | debug overlay | `set_rig()` | dev build only |
| 屏幕震动累加量（debug only） | debug overlay | shake 触发 | dev build only |
| 当前 zoom 值 | HUD 不需要 | — | HUD 在独立 CanvasLayer |
| DEFEAT roll 角度 | HUD 不需要 | — | HUD 在独立 CanvasLayer |

**关键约定**：本系统的所有 UI 反馈**仅在 debug build 可见**。release build 的 UI 完全不显示相机信息（玩家不需要"知道"当前是哪个机位——他们**看到**）。

## Acceptance Criteria

> Solo 模式（`qa-lead` 未咨询），生产前人工 review。

### 机位切换

- **AC-1**：**GIVEN** 玩家在 EXPLORATION 探索 **WHEN** 走到遇敌 tile 触发 BATTLE **THEN** 相机在 0.4s 内淡黑 + 切到 `RIG_BATTLE_OVERHEAD`（1.2× zoom），期间帧率不掉到 50 FPS 以下。验证：FADE_BLACK 效应 + 性能。
- **AC-2**：**GIVEN** 玩家在 BATTLE 战斗结束（胜利） **WHEN** 战斗系统 #7 发出 `battle_ended("victory")` **THEN** 相机在 0.6s 内 zoom 推进到 `RIG_VICTORY`（1.5× 玩家机甲特写）+ 0.3s hold。验证：胜利机位规则（C-R5 例外）。
- **AC-3**：**GIVEN** 玩家按 Tab 打开 Codex **WHEN** 状态机 #3 转换到 CODEX **THEN** 相机在 0.6s 内 zoom 拉远到 `RIG_CODEX_WIDE`（0.6×）。验证：状态→机位映射。

### 跟随与死区

- **AC-4**：**GIVEN** 玩家在 EXPLORATION 中向 +X 方向移动 50px **WHEN** 测相机位置 **THEN** 玩家始终在屏幕视口中央，相机以 0.10 lerp_factor 滞后跟随。验证：F2 跟随。
- **AC-5**：**GIVEN** 玩家在 deadzone (24px) 内移动 **WHEN** 测相机位置 **THEN** 相机位置不变。验证：F4 死区。
- **AC-6**：**GIVEN** 玩家向 +X 方向走到屏幕右边缘 5px 之内 **WHEN** 测相机位置 **THEN** 玩家位置被锁定在屏幕右边缘以内 5px，相机不超出关卡边界。验证：边界限制。

### 屏幕震动

- **AC-7**：**GIVEN** 玩家攻击命中 **WHEN** 测相机震动 **THEN** 屏幕在 100ms 内 ±4px 震动 1 次，结束后回归原位。验证：F1 命中震动。
- **AC-8**：**GIVEN** 玩家连续受击 8 次（每 0.25s 一次） **WHEN** 测累积震动 **THEN** 累加上限不超过 30px（per C-R6），最后一次震动被削减。验证：累加规则。
- **AC-9**：**GIVEN** 玩家死亡触发 DEFEAT 机位 **WHEN** 测相机状态 **THEN** 相机 roll 3° + 0.6s 12px shake + 灰度降低。验证：DEFEAT 复合效果。

### 渲染与性能

- **AC-10**：**GIVEN** 默认 1280×800 窗口 **WHEN** 持续 60 秒 **THEN** 帧率 ≥ 58 FPS（10 帧累计测试）。验证：性能预算（per technical-preferences 16.6ms 帧预算）。
- **AC-11**：**GIVEN** 探索中场景有 8 个 Light2D 节点 + 4 个 mask 节点（错误实现） **WHEN** 帧率检测 **THEN** 帧率掉到 30 FPS。**Fix**：用 Sprite + Shader 替代后帧率回到 60 FPS。验证：暗角 mask 性能规则。
- **AC-12**：**GIVEN** 玩家 resize 窗口到 1920×1080 **WHEN** 测相机 zoom **THEN** 相机 zoom 按比例重算，画面比例保持。验证：resize 处理。

### UI 独立性

- **AC-13**：**GIVEN** 玩家在 `RIG_CODEX_WIDE`（0.6× zoom） **WHEN** 查询 HUD 状态徽章的字号 **THEN** 字号不变（独立 CanvasLayer 规则）。验证：UI 不受相机影响（C-R7）。
- **AC-14**：**GIVEN** 玩家触发命中震动 **WHEN** 观察 HUD 元素位置 **THEN** HUD 元素以 0.5× 幅度跟着 shake（避免画面撕裂感）。验证：C-R7 异常规则。

### 切换锁定

- **AC-15**：**GIVEN** 玩家快速开关 Codex 3 次/秒 **WHEN** 测相机响应 **THEN** 第二次开关在第一次 transition 完成后才接受（0.6s 切换锁定），无 zoom 抖动。验证：TRANSITION_LOCK。

## Open Questions

| 问题 | Owner | 截止 | 决议 |
|------|-------|------|------|
| `RIG_VICTORY` 是否要等战斗音乐结束才 `replace(EXPLORATION)`，还是固定 0.3s hold + 立即退出？ | audio-director + game-designer | 战斗 GDD 阶段 | 当前定：固定 0.3s hold（不动听音乐） |
| 暗角 mask 应该是美术资源（PNG + Shader）还是程序化（用 viewport + polygon）？ | art-director + technical-artist | VS 阶段 | 当前定：PNG + Shader（性能可控） |
| `RIG_CODEX_WIDE` 是否要"全场景"显示（包括 UI 之外的内容）？ | ux-designer | Codex GDD 阶段 | 当前定：相机显示游戏世界（Codex UI 独立 CanvasLayer） |
| boss 战专用机位（`RIG_BOSS_INTRO`）是否单独加？ | game-designer + technical-artist | 战斗 GDD 阶段 | 当前定：MVP 复用 `RIG_BATTLE_OVERHEAD` + 自动拉远，VS 评估是否加 boss 专属 |
| shake 累加的实现：是计时窗口（2s 滑窗）还是次数（5 次后强制停）？ | gameplay-programmer | 实现阶段 | 当前定：2s 滑窗（更平滑） |
| **TITLE 状态 → `RIG_CODEX_WIDE` 的语义意图**：是 TITLE = 主菜单（那应该单独 `RIG_TITLE_MENU`）还是 TITLE = 卫星俯瞰 fade-in（那 RIG_CODEX_WIDE 应该改名 `RIG_WIDE_VIEW`）？ | user + game-designer | 实施前 | **待裁决**（lean first review Rec #1, 2026-06-12） |
