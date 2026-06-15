# 碰撞检测 (Collision)

> **Status**: Approved
> **Author**: user + gameplay-programmer + lead-programmer
> **Review Verdict**: APPROVED (first review 2026-06-12, lean)
> **Last Updated**: 2026-06-12 (first review)
> **Implements Pillar**: Pillar 1（探索密度——玩家能"感觉到"墙 / 门 / 隐藏要素的边界）+ Pillar 3（build 试验——命中检测的精度决定 build 是否有意义）

## Summary

碰撞系统是 Railhunter 所有"两个物体在物理上接触 / 重叠 / 触发"的**单一权威**。它定义 8 个物理层（WORLD / PLAYER / ENEMY / BULLET_PLAYER / BULLET_ENEMY / INTERACTABLE / ENCOUNTER / DAMAGE_AREA）、5 个碰撞矩阵规则、信号化的"实体进入 / 离开区域"事件，以及与游戏状态机 #3 共享的"BATTLE 状态忽略 WORLD 层碰撞"等状态相关规则。

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `Resource/Data #1`（layer mask 定义） · Depended on by: 玩家输入 #2、关卡/迷宫 #15、暗雷遇敌 #16、战斗核心 #7、门锁 #17、道具 #14

## Overview

碰撞系统是 Railhunter 所有"两个物体在物理上接触 / 重叠 / 触发"的**单一权威**。它定义 8 个物理层（WORLD / PLAYER / ENEMY / BULLET_PLAYER / BULLET_ENEMY / INTERACTABLE / ENCOUNTER / DAMAGE_AREA）、5 个碰撞矩阵规则、信号化的"实体进入 / 离开区域"事件（`area_entered` / `area_exited`）、命中过滤（friendly fire off）、以及与游戏状态机 #3 共享的"BATTLE 状态忽略 WORLD 层碰撞"等状态相关规则。

玩家**直接接触**这个系统——他们感受到的所有"机甲撞墙、子弹命中、走到遇敌 tile"**全部**由本系统处理。但**不直接控制**——玩家不会调碰撞参数（这是开发者 / 关卡设计者的事）。

如果本系统不存在，**游戏会立刻"漏水"**：机甲穿墙、子弹穿敌人、遇敌 tile 无效、门永远打不开、道具拾不起。

**在 5 层 Foundation 中**：本系统是**第 5 个**（也是最后一个）地基。它**只**依赖 #1 资源 / 数据（layer mask 定义），被战斗 #7、关卡 #15、暗雷 #16、门锁 #17、道具 #14、玩家输入 #2 触发（用于判断"附近有可互动物体"以决定是否显示提示）。

## Player Fantasy

玩家**感受到**的，是"游戏世界**有边界**"——他们不会穿墙、子弹不会穿敌人、走近门会"哔"一声、走到遇敌 tile 一定触发战斗。这**全是**本系统的功劳。

- **机甲撞墙**：硬碰硬——机甲有微小"撞墙摇头"动画（0.2s），玩家立刻知道"这堵墙不可过"
- **走近可互动物体**：UI 弹出"按 E 互动"提示，**只在玩家离物体 ≤ 32px 时显示**——靠本系统的 `area_entered` 触发
- **走到遇敌 tile**：玩家机甲方块"踩"上遇敌 tile（隐形的）→ 立即触发 BATTLE 状态——per systems-index #16 暗雷遇敌
- **战斗中子弹命中**：粒子炮粒子 vs 敌人碰撞体 → 伤害数字弹出 + 命中震动（per相机 #4 配合）
- **伤害区**：敌人 AOE 技能在地上画个红圈 → 玩家踩上去 = 受伤 → 玩家走出红圈 = 停止受伤

这背后的情感是 **Pillar 1（探索密度）**——玩家能"感觉到"关卡边界 = 知道"哪里有内容、哪里没有"；**Pillar 3（build 试验）**——子弹 vs 敌人碰撞的精度 = build 是否能"打中"的保证（如果子弹穿敌人 = build 失效 = 玩家挫败）。

参考游戏：
- **密特罗德 Dread** —— 子弹 vs 敌人的"硬碰硬"反馈（命中粒子 + 屏幕震动）
- **Into the Breach** —— 完美的 grid-based 命中检测（玩家精确知道"我打中了"）
- **Outer Wilds** —— 玩家走入太空即死（伤害区的极端案例）

> `creative-director` 未咨询（Solo 模式）。

## Detailed Design

### Core Rules

本系统有 **6 条 invariant**。

**C-R1 — 8 个物理层，闭集**。`LAYER_WORLD` / `LAYER_PLAYER` / `LAYER_ENEMY` / `LAYER_BULLET_PLAYER` / `LAYER_BULLET_ENEMY` / `LAYER_INTERACTABLE` / `LAYER_ENCOUNTER` / `LAYER_DAMAGE_AREA`。每层 1-bit mask（最多 32 层）。**禁止**新层（除非 game design 改）。所有 Area2D / CollisionShape2D / CharacterBody2D 都必须**显式**声明自己的 layer + collision_mask（per C-R2）。

**C-R2 — 碰撞矩阵是 GDD 定义，不是代码散落**。`COLLISION_MATRIX: Dictionary[Layer, Dictionary[Layer, bool]]` 在本 GDD 表里（见下）。代码**只**用 `set_collision_mask_value(layer, true/false)`，不"猜测"哪些层应该碰撞。

**C-R3 — 信号化 area 事件，订阅者模式**。Area2D 的 `area_entered` / `area_exited` / `body_entered` / `body_exited` 信号在 CollisionManager autoload 中**集中订阅并转发**为命名信号（`signal entity_entered_interactable(entity: Node2D)`），下游系统订阅命名信号而不是直接监听 Area2D。**理由**：Area2D 节点可能在状态转换时被 free，订阅者用命名信号 + weak ref 可避免崩溃。

**C-R4 — 命中过滤 = 友军伤害关闭**。`BULLET_PLAYER` 不会命中 `PLAYER`（自己）；`BULLET_ENEMY` 不会命中 `ENEMY`（自己）。**但**：AOE 技能可能例外（per Game Designer 在战斗中显式 override）。MVP 不做 AOE 友军过滤——AOE 算"全层命中"。

**C-R5 — 碰撞体形状优先矩形**。所有碰撞体用 `RectangleShape2D`（不用 `CircleShape2D` / `CapsuleShape2D`）。32x32 像素基础单位 → 矩形最自然，性能最好（Godot 4.6 broadphase 对矩形最优化）。**例外**：敌人 AOE 用 `CircleShape2D`（视觉上"圆形伤害区"）。

**C-R6 — CollisionManager autoload，单一权威**。所有碰撞事件通过 `/root/CollisionManager` 路由。它维护 `Dictionary[StringName, Array[Node2D]]` 跟踪"哪些实体在哪些区域"。**禁止**其他系统直接调 `Area2D.get_overlapping_bodies()` 之类的查询——必须经过 CollisionManager。

### States and Transitions

**8 个物理层**（bit 0-7，layer_mask = 1 << idx）：

| idx | Layer | 用途 | 典型节点 |
|-----|-------|------|----------|
| 0 | `LAYER_WORLD` | 静态墙 / 地板 / 不可通过 | TileMap, StaticBody2D |
| 1 | `LAYER_PLAYER` | 玩家机甲 | CharacterBody2D |
| 2 | `LAYER_ENEMY` | 敌人（战斗 + 关卡） | CharacterBody2D (战斗) / Area2D (暗雷) |
| 3 | `LAYER_BULLET_PLAYER` | 玩家发射的子弹 / 光束 | Area2D |
| 4 | `LAYER_BULLET_ENEMY` | 敌人发射的子弹 / AOE | Area2D |
| 5 | `LAYER_INTERACTABLE` | 终端 / NPC / 道具 / 门 | Area2D (trigger) |
| 6 | `LAYER_ENCOUNTER` | 暗雷遇敌 tile | Area2D (trigger) |
| 7 | `LAYER_DAMAGE_AREA` | 持续伤害区（敌人 AOE / 地形陷阱） | Area2D (overlap) |

**碰撞矩阵**（`COLLISION_MATRIX`）：

| From \ To | WORLD | PLAYER | ENEMY | BULLET_P | BULLET_E | INTERACT | ENCOUNTER | DAMAGE |
|-----------|-------|--------|-------|----------|----------|----------|-----------|--------|
| **WORLD** | – | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **PLAYER** | ✅ | – | ❌ | ❌ | ❌ | ❌ (用 enter/exit) | ✅ trigger | ✅ overlap |
| **ENEMY** | ✅ | ✅ | – | ❌ | ❌ | ❌ | ❌ | ❌ |
| **BULLET_PLAYER** | ✅ | ❌ (C-R4) | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **BULLET_ENEMY** | ✅ | ✅ | ❌ (C-R4) | ❌ | ❌ | ❌ | ❌ | ❌ |
| **INTERACTABLE** | ❌ | ❌ (用 enter/exit) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **ENCOUNTER** | ❌ | ✅ trigger | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **DAMAGE_AREA** | ❌ | ✅ overlap | ✅ overlap | ❌ | ❌ | ❌ | ❌ | ❌ |

**Legend**: ✅ = collide/detect, ❌ = no detect, trigger = `area_entered` 触发一次, overlap = 持续 overlap 期间每帧检测。

**状态相关规则**（与 #3 GameStateMachine 共享）：

| 状态 (#3) | 激活层 | 禁用层 | 备注 |
|----------|--------|--------|------|
| `EXPLORATION` | WORLD / PLAYER / INTERACTABLE / ENCOUNTER / DAMAGE_AREA | BULLET_PLAYER / BULLET_ENEMY / ENEMY（战斗） | 玩家在地图，敌人不在 |
| `BATTLE` | PLAYER / ENEMY / BULLET_PLAYER / BULLET_ENEMY / DAMAGE_AREA | WORLD（战斗场地无墙）/ INTERACTABLE / ENCOUNTER | 战斗场地是封闭矩形，墙壁由战斗系统内部处理 |
| `TERMINAL` / `CODEX` / `MENU` / `PAUSE` | 保持前状态（per #3 规则） | — | UI overlay 不影响物理 |
| `TITLE` | 无（标题画面无物理） | 全部 | 静态画面 |

**实现层**（per state）：
- 状态机 #3 转换时，CollisionManager 调用 `state_collision_profile[old_state].apply_disable()` + `state_collision_profile[new_state].apply_enable()`，按上表 toggle 各 layer / mask
- 例：`transition_to(BATTLE)` → 启用 ENEMY/BULLET_PLAYER/BULLET_ENEMY/DAMAGE_AREA；禁用 WORLD/INTERACTABLE/ENCOUNTER

### Interactions with Other Systems

| 下游系统 | 接口 | 触发 |
|----------|------|------|
| **玩家输入 #2** | 订阅 `signal entity_near_interactable(entity: Node2D, in_range: bool)` | 玩家进入 / 离开 INTERACTABLE 区域 |
| **关卡 / 迷宫 #15** | 在关卡加载时 `register_layer_profile(level_id, world_mask, encounter_mask)` | 关卡进入 |
| **暗雷遇敌 #16** | 订阅 `signal player_entered_encounter_tile(tile_id)` | 玩家踩 ENCOUNTER |
| **战斗核心 #7** | 订阅 `signal bullet_hit(body, bullet)` | 子弹命中敌人 |
| **战斗核心 #7** | 订阅 `signal damage_area_tick(entity, area, damage)` | 玩家 / 敌人在 DAMAGE_AREA 内 |
| **门锁 #17** | 订阅 `signal entity_near_interactable(door, true)` | 玩家走近门 |
| **道具 #14** | 订阅 `signal player_entered_pickup(pickup, qty)` | 玩家踩 INTERACTABLE 道具 |
| **终端 / NPC 触发** | 订阅 `signal player_near_terminal(terminal)` | 玩家走近终端 |
| **HUD** | (无直接消费) | 玩家靠近的可互动物体由 #2 玩家输入决定显示 |
| **游戏状态机 #3** | `apply_collision_profile(state: StringName)` | 状态转换 |

**所有权约定**：
- 本系统**唯一拥有**"哪些物体物理上接触"
- 任何下游系统**改碰撞 mask = bug**——所有 layer toggle 由 CollisionManager 在状态转换时统一做
- **"可互动物体提示"显示**：本系统**只**告诉 #2 玩家输入"有什么进入 / 离开了 INTERACTABLE 范围"，**不**自己渲染提示（per #2 玩家输入负责）

## Formulas

本系统**不计算复杂数学**——主要是离散判定 + 信号路由。

### F1. Collision Detection Latency

碰撞检测 = O(N) 遍历 + O(1) 矩形 AABB 测试。Godot 4.6 PhysicsServer 用 BVH broadphase，平均查询时间 < 0.1ms（典型 50 个 entity）。

| 步骤 | 期望时间 | 上限 |
|------|----------|------|
| `Area2D.area_entered` 触发 | 0.05ms | 0.2ms |
| CollisionManager 路由到命名信号 | 0.01ms | 0.05ms |
| 订阅者处理（如战斗命中） | 0.5ms | 2.0ms |
| **总计（单事件）** | **0.56ms** | **2.25ms** |

**Output Range**: < 1ms 最佳, 2.25ms 上限. **Edge case**: 1 帧内 100+ 命中 = 6-8ms 累计 = 接近帧预算——是战斗 BOSS 战的极限，per 性能预算测试。

### F2. Damage Area Tick Rate

DAMAGE_AREA 内的实体**每 N 帧**受到一次伤害（per `damage_tick_interval`）。

| 变量 | 类型 | 范围 | 描述 |
|------|------|------|------|
| `damage_tick_interval` | float | 0.1–2.0 (s) | 多久 tick 一次 |
| `damage_per_tick` | int | 1–100 | 每次 tick 多少伤害 |
| `entity_in_area` | bool | true/false | 当前是否在区域内 |

**Rule**: 每 `damage_tick_interval` 秒，CollisionManager 给所有 overlap 实体 emit `damage_area_tick(entity, area, damage_per_tick)`。订阅者（如战斗 #7）应用伤害。

**Default**: `damage_tick_interval = 0.5s`, `damage_per_tick = 5` (玩家在红圈每秒 10 伤害)。**Edge case**: 玩家在帧末 +0.001s 进入红圈 = 下次 tick 在 0.499s 后 = "0.5s 一次" 仍然成立（per first-tick-on-entry rule）。

### F3. Encounter Tile Detection

ENCOUNTER tile 是 trigger area（不是 overlap）—— `area_entered` 触发一次后立即 disable 直到玩家离开再 enable。

```
if player_in_encounter_tile and not tile.cooldown:
    trigger_battle(tile_id)
    tile.cooldown = true
    tile.set_deferred("monitoring", false)
```

**Edge case**: 玩家在 1 帧内连续踩 2 个 encounter tile = 触发 2 次战斗 = bug。**Fix**: `transition_to(BATTLE)` 后整个 ENCOUNTER 层 monitoring = false（per C-R6 状态转换时 toggle）。

### F4. Interactable Proximity

玩家进入 INTERACTABLE 区域时，#2 玩家输入显示"按 E 互动"提示。

| 变量 | 类型 | 范围 | 描述 |
|------|------|------|------|
| `interact_radius_px` | float | 16–64 | 触发提示的距离 |
| `min_prompt_display_ms` | int | 100–500 | 提示最小显示时间（避免闪烁） |

**Default**: `interact_radius_px = 32` (1 个 tile), `min_prompt_display_ms = 200`。**Edge case**: 玩家在 1 帧内进入 2 个 INTERACTABLE = 显示最近的那个（per distance check），切换有 200ms 抑制（防抖动）。

## Edge Cases

| # | 条件 | 结果 | 原因 |
|---|------|------|------|
| 1 | **子弹 vs 多个敌人同时命中**：爆炸型 AOE 一次性命中 3 个敌人 | CollisionManager 在 1 帧内 emit 3 个 `bullet_hit` 事件（每个敌人一次），战斗系统顺序处理 | AOE 默认友军过滤关闭（per C-R4） |
| 2 | **战斗结束后 BULLET_PLAYER 残留**：玩家退出 BATTLE 时有未命中目标的飞行中子弹 | 状态转换时 `state_collision_profile[EXPLORATION].apply_disable()` 禁用 BULLET_PLAYER 层；残留子弹节点 `queue_free` | 防止子弹从战斗场地飞出到探索地图 |
| 3 | **敌人在墙体里出生**：关卡设计错误，敌人 spawn 位置被墙占用 | 战斗初始化时检测：如果敌人矩形与 WORLD 重叠 → 抛 `InvalidSpawnPositionError` + 关卡加载失败 | fail-fast 优于运行时错位 |
| 4 | **玩家卡在墙里**：物理求解失败，玩家被推到非合法位置 | Godot 4.6 CharacterBody2D `safe_margin` 处理；如失败，玩家位置 = 上一个 valid position | 不让玩家永久卡死 |
| 5 | **DAMAGE_AREA 与 BULLET 重叠**：AOE 区里又有 AOE | 双重伤害 = `damage_area_tick` 每 tick 一次，叠加 = 每 tick 受 2 次伤害 | MVP 不去重，由战斗系统决定（per #7 战斗 GDD） |
| 6 | **INTERACTABLE 在 1 帧内 enter + exit**：玩家高速移动穿过小区域 | `min_prompt_display_ms = 200ms` 抑制抖动，提示不会闪烁 | F4 防抖 |
| 7 | **ENCOUNTER tile 在 BATTLE 状态被触发**：state toggle 时序错误 | 状态转换时 ENCOUNTER monitoring = false（per F3），战斗中玩家不可触发新战斗 | 状态转换是原子的 |
| 8 | **碰撞事件在节点 free 之后触发**：子弹命中目标后目标已 free | CollisionManager 检查 `is_instance_valid(target)` 后再 emit，null target 静默忽略 | weak ref 约定 |
| 9 | **碰撞矩阵错误配置**：开发者把 BULLET_PLAYER mask 设为对 PLAYER 命中 | Linter 检查 `COLLISION_MATRIX` vs `actual_masks` 不一致，启动失败 | C-R2 矩阵是 GDD 定义 |
| 10 | **极高速移动的子弹（tunneling）**：1 帧内子弹移动 100px，可能"跳过"小目标 | 启用 Godot 4.6 `continuous_cd` (Continuous Collision Detection)，子弹视为 swept shape | Godot 4.6 内置支持 |
| 11 | **PhysicsServer 卡顿**：物理 tick 延迟到 1 帧后 | 1 帧碰撞事件延迟 = 玩家感觉"撞墙晚了" | Godot 4.6 physics tick = 60Hz 锁定，理论不卡 |
| 12 | **modded 玩家加新层**：超过 8 层 | C-R1 闭集，硬拒绝 + 错误日志 | 防止 mask 越界 |

## Dependencies

### 上游依赖

| 系统 | 方向 | 接口 | 备注 |
|------|------|------|------|
| **资源 / 数据 #1** | 强依赖 | `COLLISION_MATRIX` 注册为 Resource | layer mask 定义在 .tres |

### 下游依赖（8 个系统）

| 系统 | 方向 | 性质 | 接口 |
|------|------|------|------|
| **游戏状态机 #3** | 强依赖 | Hard | `apply_collision_profile(state: StringName)` 双向 |
| **玩家输入 #2** | 强依赖 | Hard | `signal entity_near_interactable` |
| **关卡 / 迷宫 #15** | 强依赖 | Hard | `register_layer_profile(level_id, ...)` |
| **暗雷遇敌 #16** | 强依赖 | Hard | `signal player_entered_encounter_tile` |
| **战斗核心 #7** | 强依赖 | Hard | `signal bullet_hit` + `signal damage_area_tick` |
| **门锁 #17** | 强依赖 | Hard | `signal entity_near_interactable(door, true)` |
| **道具 #14** | 强依赖 | Hard | `signal player_entered_pickup` |
| **终端 / NPC** | 强依赖 | Hard | `signal player_near_terminal` |
| **HUD** | (无) | — | 提示显示由 #2 玩家输入负责 |

### 双向约束（与 #3 状态机共享）

| 约束 | 在 #3 中的位置 | 在本系统中 |
|------|----------------|-------------|
| `state_changed → apply_collision_profile` | #3 信号定义 | 本系统 state_collision_profile 表 + C-R6 状态相关规则 |
| `BATTLE 禁用 WORLD` | #3 C-R4 原子转换 | 本系统 F3 / 状态相关规则表 |

## Tuning Knobs

| 参数 | 当前默认值 | 安全范围 | 调高 → | 调低 → | 为什么取这个数 |
|------|------------|----------|---------|---------|----------------|
| `PHYSICS_TICK_HZ` | 60 | 60 (固定) | — | — | 锁帧 60Hz |
| `CCD_ENABLED` | true | true / false | — | 高低速混合场景会漏命中 | 防 tunneling（E10） |
| `DAMAGE_TICK_INTERVAL_S` | 0.5 | 0.1–2.0 | 玩家持续掉血 = 紧迫感 | 伤害延迟 | 0.5s = 1/2 秒感知阈值 |
| `INTERACT_RADIUS_PX` | 32 | 16–64 | 玩家"靠近"就提示（破坏走近意图） | 玩家需精确站位 | 32 = 1 个 tile 单位 |
| `MIN_PROMPT_DISPLAY_MS` | 200 | 100–500 | 提示闪烁 | 提示不消失 | 200ms = 12 帧 @ 60 FPS，足够视觉稳定 |
| `SAFE_MARGIN_PX` | 4 | 1–16 | 玩家被推出更远 | 卡墙风险 | 4px = 1/8 tile，足够余量 |
| `BULLET_MAX_LIFETIME_S` | 3.0 | 1.0–10.0 | 飞行时间长（卡性能） | 子弹过早消失 | 3s = 命中距离 30+ tile |
| `PLAYER_COLLIDER_SIZE_PX` | 24×24 | 16×16–32×32 | 视觉机甲大但碰撞小 = 看着像穿墙 | 卡墙 | 24×24 = 32×32 像素机甲留 4px 视觉余量 |
| `ENEMY_COLLIDER_SIZE_PX` | 24×24 | 16×16–32×32 | 视觉大碰撞小 | 拥挤 | 同上 |
| `INTERACTABLE_AREA_RADIUS_PX` | 32 | 16–64 | 提示过早 | 提示过晚 | = INTERACT_RADIUS_PX |

### 跨系统杠杆

| 杠杆 | 影响范围 | 当前值 | 调高 → | 调低 → |
|------|----------|---------|---------|---------|
| `DAMAGE_TICK_INTERVAL_S` | AOE / 陷阱的"压迫感" | 0.5 | 紧迫 | 宽松 |
| `INTERACT_RADIUS_PX` | 探索中"发现可互动物体"的灵敏度 | 32 | 灵敏 | 严格 |

## Visual/Audio Requirements

| 事件 | 视觉反馈 | 音频反馈 | 备注 |
|------|----------|----------|------|
| 玩家撞墙 | 机甲 0.2s 摇头动画（per art-bible "重装机兵撞墙反馈"） | 短促 thud | WORLD 碰撞 |
| 子弹命中敌人 | 命中粒子（per art-bible）+ 相机 4px shake（per相机 #4 F1） | 命中音（由战斗触发） | `bullet_hit` 信号 |
| 玩家进入 INTERACTABLE | "按 E 互动" 提示（per #2 玩家输入） | 短提示音 | `entity_near_interactable` |
| 玩家进入 DAMAGE_AREA | 红圈闪烁 + 0.1s 红屏 vignette | 受伤音 | `damage_area_tick` |
| 玩家踩 ENCOUNTER tile | 屏幕 0.4s 淡黑（per相机 #4 RIG_TRANSITION_MAP） | 转换音 | 触发战斗 |
| 战斗子弹残留飞出 | 状态转换时 `queue_free`（无视觉） | 静音 | per E2 |

## UI Requirements

| 信息 | 消费者 | 触发 | 备注 |
|------|--------|------|------|
| "按 E 互动" 提示 | #2 玩家输入 | `entity_near_interactable` | UI 在 CanvasLayer 不受相机影响 |
| 当前区域 layer profile（debug only） | debug overlay | `apply_collision_profile` | dev build only |
| 碰撞事件计数器（debug only） | debug overlay | emit 时 | dev build only |

## Acceptance Criteria

> Solo 模式（`qa-lead` 未咨询），生产前人工 review。

### 基础碰撞

- **AC-1**：**GIVEN** 玩家在 EXPLORATION 撞向墙 **WHEN** 移动输入 **THEN** 玩家在墙前 4px 停下（per `SAFE_MARGIN_PX`），不穿墙。验证：WORLD 碰撞。
- **AC-2**：**GIVEN** 玩家在 EXPLORATION 走向 INTERACTABLE 物体（门）**WHEN** 距离 ≤ 32px **THEN** "按 E 互动" 提示出现。验证：INTERACT 触发。
- **AC-3**：**GIVEN** 玩家离开 INTERACTABLE 物体 **WHEN** 距离 > 32px **THEN** 提示消失，但保留至少 200ms（防抖）。验证：F4 防抖。

### 战斗命中

- **AC-4**：**GIVEN** 玩家在 BATTLE 发射子弹 **WHEN** 子弹与敌人碰撞 **THEN** `bullet_hit(bullet, enemy)` 信号 emit 1 次，敌人 HP 减少，子弹节点 free。验证：基本命中。
- **AC-5**：**GIVEN** 玩家子弹接近自己（自己发射的）**WHEN** 测命中 **THEN** 子弹**不**命中玩家（C-R4 友军过滤）。验证：友军伤害关闭。
- **AC-6**：**GIVEN** 敌人 AOE 红圈 + 玩家进入 **WHEN** 测 **THEN** 每 0.5s `damage_area_tick` emit 1 次，玩家 HP 减少 5。验证：F2 tick 规则。

### 暗雷遇敌

- **AC-7**：**GIVEN** 玩家走到 ENCOUNTER tile **WHEN** `area_entered` 触发 **THEN** `transition_to(BATTLE)` + tile.cooldown = true + tile.monitoring = false。验证：F3 一次性触发。
- **AC-8**：**GIVEN** 玩家 BATTLE 中 ENCOUNTER tile **WHEN** 状态机 toggle layer **THEN** 战斗中玩家不可再触发新 ENCOUNTER。验证：状态切换正确性。
- **AC-9**：**GIVEN** 玩家战斗胜利回到 EXPLORATION **WHEN** 测 ENCOUNTER tile **THEN** tile.monitoring = true（重新可触发）。验证：状态退出时还原。

### 状态切换

- **AC-10**：**GIVEN** 玩家在 EXPLORATION **WHEN** 状态机 `transition_to(BATTLE)` **THEN** 0.05ms 内 `apply_collision_profile(BATTLE)` 完成：ENEMY/BULLET_PLAYER/BULLET_ENEMY/DAMAGE_AREA 启用，WORLD/INTERACTABLE/ENCOUNTER 禁用。验证：状态相关规则。
- **AC-11**：**GIVEN** 玩家在 BATTLE 战斗结束 **WHEN** 状态机 `replace(EXPLORATION)` **THEN** 反向 toggle：WORLD/INTERACTABLE/ENCOUNTER 启用，ENEMY/BULLET_PLAYER/BULLET_ENEMY/DAMAGE_AREA 禁用。验证：状态退出。
- **AC-12**：**GIVEN** 玩家在 BATTLE 残留 BULLET_PLAYER 节点 **WHEN** 状态退出 **THEN** 残留子弹 `queue_free` 防止飞出。验证：E2 清理。

### 性能

- **AC-13**：**GIVEN** 60 个 enemy + 200 个 BULLET_PLAYER 同时在 BATTLE 战场 **WHEN** 帧率测试 **THEN** 帧率 ≥ 55 FPS（10 帧累计）。验证：性能预算。
- **AC-14**：**GIVEN** 极高速子弹（5000 px/s）vs 24×24 敌人 **WHEN** 测命中 **THEN** CCD 启用时 100% 命中（无 tunneling），关闭时 ≤ 95%。验证：E10 CCD 行为。

### 错误处理

- **AC-15**：**GIVEN** 开发者把 BULLET_PLAYER collision_mask 错误设为对 PLAYER 命中 **WHEN** 启动游戏 **THEN** Linter 抛 `CollisionMatrixMismatch` + 启动失败。验证：E9 配置校验。
- **AC-16**：**GIVEN** 子弹命中目标后目标已 `queue_free` **WHEN** 测 **THEN** CollisionManager 静默忽略 null target，无 crash。验证：E8 weak ref 安全。

## Open Questions

| 问题 | Owner | 截止 | 决议 |
|------|-------|------|------|
| 是否需要"穿透"子弹（贯穿多个敌人）？这会改变 C-R4 / C-R5 | gameplay-programmer + systems-designer | 战斗 GDD 阶段 | MVP 默认不穿透，VS 评估 |
| DAMAGE_AREA 是即时伤害还是持续 tick？ | systems-designer | 战斗 GDD 阶段 | 当前定：持续 tick（0.5s） |
| 子弹 vs BOSS 战的"霸体"机制（无视命中震动）由谁处理？ | game-designer | 战斗 GDD 阶段 | 当前定：本系统**只**emit `bullet_hit`，霸体逻辑由战斗 #7 处理 |
| ENCOUNTER tile 是否要"已触发"标记，防止玩家反复踩同 tile 反复战斗 | game-designer + level-designer | 关卡 GDD 阶段 | 当前定：tile 触发后 `cooldown = true` 直到玩家离开再回来（per F3） |
| AOE 友军过滤（MVP 关闭）何时开启？ | systems-designer | VS 阶段 | MVP 关闭（per C-R4），VS 评估是否加同阵营过滤 |
| **BATTLE 状态转换期间 ENCOUNTER 信号 race**：当前 F3 fix 说"transition_to(BATTLE) 后整个 ENCOUNTER 层 monitoring = false"，但 AC-7 只验证 cooldown 逻辑，没验证"转换期间不 emit `player_entered_encounter_tile`" | gameplay-programmer | 实施前 | **待补 AC-12b**（lean first review Rec #2, 2026-06-12） |
| **`INTERACTABLE_AREA_RADIUS_PX` 重复 knob**：tuning knobs 表中 232 行 `INTERACT_RADIUS_PX` 和 238 行 `INTERACTABLE_AREA_RADIUS_PX` 范围完全相同 (16-64) 且后者注明"= INTERACT_RADIUS_PX"，是死 config | gameplay-programmer | 实施前 | **待合并/删除**（lean first review Rec #6, 2026-06-12） |
