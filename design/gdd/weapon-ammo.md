# 武器与弹药 (Weapon & Ammo)

> **Status**: Approved
> **Author**: user + systems-designer + gameplay-programmer
> **Review Verdict**: APPROVED (first review 2026-06-12, lean, prototype-validated)
> **Last Updated**: 2026-06-12 (first review)
> **Implements Pillar**: Pillar 3（每次战斗都是 build 试验）—— 武器×弹药 = build 深度的素材；Pillar 1（探索密度）—— 找到新武器是"被看见的回报"的最直接形式

## Summary

武器与弹药系统是 Railhunter build 试验系统的**载体**。它定义 3 武器槽 × 3+ 弹药类型 = 9+ 种 build 组合（per prototype 验证：3×3）、武器 / 弹药的库存管理、装备切换、战利品拾取、丢弃规则。它是 #7 战斗核心的下游消费者（提供 weapon_data / ammo_data 给战斗），是 #15 关卡 / 暗雷的下游触发器（提供战利品投放）。

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `Resource/Data #1`（WeaponData/AmmoData Resource）、`战斗核心 #7`（apply build）、`关卡/迷宫 #15`（pickup）、`暗雷 #16`（drop trigger）· Depended on by: HUD、Codex、存档

## Overview

武器与弹药系统是 Railhunter **build 试验系统的载体**。它定义：

- **3 武器槽**（MVP 默认），玩家同时持有 3 把武器 + 一套**当前弹药**
- **弹药类型**（MVP 3 种：普通 / 电浆 / 跟踪，未来加爆破 / EMP）
- **build = 武器 × 弹药** 的组合（3×3=9 种 MVP；VS 5×4=20 种）
- 武器 / 弹药**库存管理**（拾取 / 丢弃 / 装备 / 切换）
- **战利品拾取流**（战斗中敌人掉落 → 战后弹出 → 玩家选择保留 / 丢弃）

本系统**完全依赖** #1 资源 / 数据（每把武器 / 弹药是 `WeaponData.tres` / `AmmoData.tres`），是 #7 战斗核心的**数据源**，是 #15 关卡 / 暗雷的**投放点**。

玩家**直接接触**这个系统——他们看武器库、切武器、收集弹药、试不同 build。**这是 Pillar 3 唯一的"试错素材池"**。

如果本系统不存在，**build 试验 = 0**——战斗就只是按"当前武器"打，没有 build 深度。

**在 5 层 Feature 中**：本系统是**第一个** Feature 系统（按 dependency sort）。它依赖全部 5 个 Foundation + 1 个 Core（战斗），被 HUD / Codex / 存档 / 关卡 / 暗雷依赖。

## Player Fantasy

玩家**直接接触**这个系统——这是他们**最频繁**互动的系统之一（仅次于战斗本身）。

他们感受到的，是**"我有一把 arsenal，每个 build 都是一个新发现"**：

- **打开武器库**：看到 3 个武器槽 + 12 把未装备的武器（从战利品 / 探索获得），可以拖拽换装
- **战斗中切武器**：按 1/2/3 立即切到对应 slot 的武器 + 立即攻击（per #7 C-R3 / prototype 学习）
- **战斗中切弹药**：按 Q/E 循环弹药，**不消耗回合**（per #7 C-R2），HUD 立即更新伤害预览
- **拾取新武器**：敌人掉落 / 探索宝箱 → 弹出"获得 [新武器名]" + icon 显示 → 玩家选择"装备" / "入背包" / "丢弃"
- **试 build**：激光枪 × 普通弹（高命中低伤）→ 激光枪 × 电浆弹（中命中高伤）→ 激光枪 × 跟踪弹（100% 命中低伤）——**每个 build 都有"啊原来如此"的发现**
- **取舍**：3 个武器槽限制让玩家**必须**取舍——最强的武器 vs 最适合这个敌人的武器 vs 备用防御武器
- **发现新武器**：探索中捡到新武器 → 图鉴更新（per #1 C-R8）→ "X / 24 已发现"百分比上升

这背后的情感是 **Pillar 3（每次战斗都是 build 试验）**——build 深度 = 武器数 × 弹药数 = 9-20 种可能；**Pillar 1（探索密度）**——新武器 = "被看见的回报"的最直接形式（per art-bible "深空废墟中孤独的霓虹"——发光的东西 = 有故事的东西）。

参考游戏：
- **《重装机兵》FC** —— 武器收集 + 战车改造的灵感
- **Into the Breach** —— 武器 build 的清晰度
- **Diablo** —— 武器库的视觉 / 听觉爽点（拾取闪光 + 数字）

> `creative-director` 未咨询（Solo 模式）。

## Detailed Design

### Core Rules

本系统有 **8 条 invariant**。

**C-R1 — 3 个武器槽闭集（MVP）**。`weapon_slots: Array[WeaponData, 3]`（按 slot 0/1/2 顺序）。槽位 0 = 数字键 1，槽位 1 = 数字键 2，槽位 2 = 数字键 3。新增槽位 = 改 GDD + 改 #2 玩家输入（47 actions 中有 3 个 slot），**不是**实现决定。

**C-R2 — 1 套当前弹药 = 全武器共享**。玩家持有 `current_ammo: AmmoData`（一种弹药）+ 各种弹药的 `inventory: Dictionary[AmmoData, int]`。战斗中按 Q/E 循环弹药，**所有**武器都用同一套当前弹药（**不**是 per-weapon ammo）。**理由**：简化 build 试验的心智负担（per prototype）。

**C-R3 — 武器 build 公式 = weapon.base_damage × ammo.damage_mult × ...**（per #7 战斗核心 F1）**。build 的实际伤害**只**取决于"当前武器 + 当前弹药"组合。**禁止**per-weapon 的隐藏 modifier（避免 build 不可解释）。

**C-R4 — 武器 / 弹药都是 Resource（per #1 资源）**。**不**在运行时实例化武器数据。运行时持有的是 `WeaponData` 资源引用 + 槽位 index。`Inventory` 持有 `Array[WeaponData]`（不重复）。

**C-R5 — 拾取流：战后弹出 + 玩家决策**。战斗中 / 探索中**不**直接加进背包——而是 emit `signal weapon_pickup_offered(weapon: WeaponData)`，HUD 弹出"获得 [X]" 弹窗，玩家按 [确认] 装备到空槽 / 替换已装备 / 入背包 / 丢弃。**禁止**自动入背包（per 玩家对"主动决策"的偏好，per game concept）。

**C-R6 — 武器丢弃不可逆**。背包满时玩家可丢弃武器 / 弹药，**一旦丢弃 = 永久消失**（per #1 C-R8 / C-R5）。**不**有"回收站" / 撤销机制——增加战利品的**重量感**。

**C-R7 — 武器升级（VS 阶段，MVP 占位）**。MVP 不实现武器升级。VS 阶段加 `WeaponUpgrade` Resource（per #1 资源）和 `weapon.level: int` 字段。**当前**：所有武器 = level 1。

**C-R8 — 弹药与武器的兼容性由 WeaponData.ammo_slot 决定**。每个 `WeaponData` 声明 `ammo_slot: AmmoData.Type`（per #1 资源），决定可装弹药类型。**例外**：`AmmoData.Type.ANY`（爆破弹）—— 任何武器都可装（per #1 弹药设计）。

### States and Transitions

**武器生命周期**：

```
                    ┌─ 玩家未获得
                    │
[未获得] ──────[战斗/探索拾取]──→ [拾取弹窗] ──玩家决策──→ [背包] ──玩家装备──→ [装备槽]
                                                                          │
                                                                          │ 战斗中按 1/2/3
                                                                          ↓
                                                                       [激活使用] ──丢弃──→ [永久删除]
```

**8 个状态**（武器对象生命周期）：

| 状态 | 用途 | 转换触发 |
|------|------|----------|
| `NOT_OBTAINED` | 玩家未拥有 | 默认初始 |
| `OFFERED` | 拾取弹窗中 | 战斗 / 探索触发 |
| `INVENTORY` | 玩家背包 | 玩家选"入背包" |
| `EQUIPPED_SLOT_0` | 装备槽 0（数字键 1） | 玩家从 OFFERED 选"装备到槽 0"或从 INVENTORY 拖拽 |
| `EQUIPPED_SLOT_1` | 装备槽 1（数字键 2） | 同上 |
| `EQUIPPED_SLOT_2` | 装备槽 2（数字键 3） | 同上 |
| `ACTIVE_IN_BATTLE` | 战斗中激活 | per #7 战斗核心 1/2/3 切换 |
| `DISCARDED` | 永久删除 | 玩家主动丢弃 |

**弹药状态**（更简单——没有"槽"概念）：

```
[未获得] ──[拾取]──→ [库存 inventory: Dict[AmmoData, int]] ──[战斗中 Q/E]──→ [当前 current_ammo]
                                       │
                                       └─[丢弃]──→ [永久删除]
```

**关键约束**：
- 同一把武器**不能**同时在 2 个状态（per C-R1 槽位互斥）
- 切换装备（INVENTORY → EQUIPPED）：如果目标槽已有武器，**原武器弹回 INVENTORY**（per C-R5 玩家决策）
- 战斗中**只**能使用 `ACTIVE_IN_BATTLE` 的武器——INVENTORY 武器不可用

### Interactions with Other Systems

| 系统 | 接口 | 触发 |
|------|------|------|
| **资源 / 数据 #1** | 读 `WeaponData.tres` / `AmmoData.tres` | 初始化 + 每次战斗 |
| **战斗核心 #7** | 提供 `weapon_data: WeaponData` + `ammo_data: AmmoData` 给战斗 | 玩家攻击时 |
| **关卡 / 迷宫 #15** | 触发 `signal weapon_pickup_offered(weapon)` / `signal ammo_pickup_offered(ammo, qty)` | 探索中拾取 |
| **暗雷 #16** | 战斗胜利后 emit `signal battle_ended` → 本系统处理 `rewards.drops[]` | 战斗胜利 |
| **HUD** | 推送 `inventory_state: Dictionary`（每帧更新） + 显示拾取弹窗 | 每帧 |
| **Codex** | 触发 `signal new_weapon_discovered(weapon_id)` | 首次获得 |
| **存档 #21** | 序列化 weapon_slots / inventory / current_ammo | 存档时 |
| **机甲升级 #13** | (MVP 不交互) | VS 阶段 |

## Formulas

### F1. Build Damage (per #7 战斗核心 F1 简化版)

`build_damage_preview = weapon.base_damage × ammo.damage_mult`

| 变量 | 类型 | 范围 | 描述 |
|------|------|------|------|
| `weapon.base_damage` | int | 20–80 | per #1 |
| `ammo.damage_mult` | float | 0.8–1.3 | per #1 |

**Formula expression**: `build_damage_preview = int(weapon.base_damage * ammo.damage_mult)`

**Output Range**: 16 (min: 20×0.8) to 104 (max: 80×1.3)
**Note**: 这是**预期伤害预览**（per #2 玩家输入弹药切换立即更新 HUD 数字），**不**是最终伤害——最终伤害由 #7 F1 加上 crit / weakness / defense。

**Example**: 激光枪（20）× 普通弹（1.0）= 20；激光枪（20）× 电浆弹（1.3）= 26；粒子炮（35）× 跟踪弹（0.8）= 28；粒子炮（35）× 电浆弹（1.3）= 45。

### F2. Build Combination Count (per #1 + Pillar 3)

`total_builds = weapon_count × ammo_count`

| 变量 | 类型 | 范围 | 描述 |
|------|------|------|------|
| `weapon_count` | int | 3 (MVP 槽数) / 5 (VS) | per C-R1 |
| `ammo_count` | int | 3 (MVP) / 4 (VS) | 普通 / 电浆 / 跟踪 (+ 爆破 / EMP) |

**MVP**: 3 × 3 = **9 种 build**
**VS**: 5 × 4 = **20 种 build**

**Output**: 这就是 Pillar 3 "build 深度" 的来源——9-20 种可选组合，玩家在手动模式下需要"试"才能发现最优 build。

### F3. Inventory Capacity

`inventory_slots_used = equipped_count + backpack_count`

| 变量 | 类型 | 范围 | 描述 |
|------|------|------|------|
| `equipped_count` | int | 0–3 | 装备槽数（MVP 固定 3） |
| `backpack_count` | int | 0–20 | 背包上限（MVP 20） |
| `total_capacity` | int | 23 | 总持有数 = 3 + 20 |

**Default**: `backpack_max = 20`。**Edge case**: 玩家获得第 21 把武器 = 强制玩家选"装备" / "丢弃"。

### F4. Pickup Decision Tree

```
function on_pickup_offered(weapon):
    if equipped_count < 3:
        show_prompt("装备 [weapon] 到空槽? [Y/N]")
    elif backpack_count < backpack_max:
        show_prompt("入背包? [Y/N]")
    else:
        show_prompt("背包满！丢弃其他武器 / 丢弃此武器? [List]")
```

**Decision time**: 玩家有 0.5s 决策窗口——超时 = 武器入背包（默认行为，避免误触丢）。

### F5. Ammo Stack (per #1 E8 + #7 E22)

弹药 = 单一类型，**累加堆叠**。`ammo_inventory[ammo_type] += qty`，堆叠上限 = `AmmoData.stack_size = 99`。

**Formula**: `effective_qty = min(ammo_inventory[ammo_type] + qty, 99) - ammo_inventory[ammo_type]`
**Output**: 玩家实际获得 = min(qty, 99 - current)
**Edge case**: 玩家已持 99 普通弹 + 获得 5 普通弹 = 获得 0（per #7 AC-22）。

## Edge Cases

| # | 条件 | 结果 | 原因 |
|---|------|------|------|
| 1 | **3 槽全满 + 背包满 20 + 拾取新武器** | 弹出"必须丢弃一项才能拾取"界面（per F4） | 强制玩家取舍 |
| 2 | **战斗中按 1/2/3 切武器但目标槽是空** | per #2 F2 拒绝反馈（"无武器"），回合**不**消耗 | per #7 AC-6 |
| 3 | **弹药切到玩家没持有的类型**（逻辑错误） | 切换**不**发生，UI 提示"无该弹药" | 防止"持有 0 弹" 的悖论 |
| 4 | **同一种武器重复拾取** | 弹窗显示"已拥有"，玩家选"丢弃" | 防止背包被同种武器占满 |
| 5 | **武器被丢弃但当时装备着** | 武器槽弹回空，玩家进入无武器状态 | 玩家主动取舍 |
| 6 | **存档时武器 ID 在新版 .tres 中找不到**（版本不匹配） | `load_snapshot` 抛 `WeaponNotFoundError` + 弹回 `INVENTORY` 状态 + 日志记录 | 存档兼容（per #3 E8） |
| 7 | **当前弹药数为 0 但 current_ammo 还是该类型**（逻辑错误） | 战斗 #7 仍允许玩家按 1/2/3 攻击（**不**检查弹药量，弹药是"装填模式"） | MVP 弹药**不**消耗——只是"装填哪种弹药"的偏好 |
| 8 | **武器不在可装弹药类型列表中**（per C-R8） | 玩家尝试装 = `signal ammo_incompatible` + 拒绝 + UI 提示"该武器不兼容" | C-R8 兼容性 |
| 9 | **战斗中按 Q/E 切到不兼容当前武器的弹药**（per C-R8） | 切换**不**发生，UI 提示"武器不兼容该弹药" | C-R8 兼容性 + #7 C-R2 |
| 10 | **拾取 0 数量弹药**（drop_rate 边界） | 弹窗**不**出现，silent | E1 弹窗不打扰 |
| 11 | **弹窗 0.5s 超时** | 默认入背包（F4） | 防止误触 |
| 12 | **多武器同帧拾取**（双敌人同时掉 2 把武器） | 串行弹窗（一次只显示 1 把） | 避免同时弹 2 个 UI |

## Dependencies

### 上游依赖（5 个 Foundation + 1 Core）

| 系统 | 接口 | 备注 |
|------|------|------|
| **资源 / 数据 #1** | `WeaponData.tres` / `AmmoData.tres` 资源 | 数据源 |
| **战斗核心 #7** | 读取 weapon_data / ammo_data | 战斗时 build 应用 |
| **关卡 / 迷宫 #15** | 触发 `weapon_pickup_offered` | 探索中拾取 |
| **暗雷 #16** | 触发 `signal battle_ended` → 处理 rewards.drops[] | 战后战利品 |
| **玩家输入 #2** | 订阅 weapon_slot_1/2/3 / cycle_weapons / cycle_ammo actions | input 路由 |

### 下游依赖（5 个系统）

| 系统 | 接口 | 备注 |
|------|------|------|
| **HUD** | 推送 `inventory_state: Dictionary` + 显示拾取弹窗 | UI 状态 |
| **Codex** | 触发 `signal new_weapon_discovered(weapon_id)` | 首次发现 |
| **存档 #21** | 序列化 weapon_slots / inventory / current_ammo | 存档 |
| **机甲升级 #13** | (MVP 不交互) | VS 阶段 |
| **门锁 #17** | 检查玩家是否持有特定武器（per #1 Resource） | 开门条件 |

### 双向约束

| 约束 | 在 #1 中 | 在本 GDD 中 |
|------|----------|-------------|
| 武器 = `WeaponData.tres` | #1 C-R1 闭集 / 9 个 Resource 子类型 | C-R4 武器是 Resource |
| 弹药 = `AmmoData.tres` | 同上 | C-R4 弹药是 Resource |
| 弹药堆叠 99 | #1 Tuning Knobs ammo_stack_size | F5 |
| 1/2/3 切武器 = 立即攻击 | #2 E1 + 玩家输入 C-R4 | C-R2 + C-R3 + per #7 C-R3 |
| Q/E 切弹药不消耗回合 | #2 Formulas 自由行动 | per #7 C-R2 |

## Tuning Knobs

| 参数 | 当前默认值 | 安全范围 | 调高 → | 调低 → | 为什么取这个数 |
|------|------------|----------|---------|---------|----------------|
| `WEAPON_SLOT_COUNT` | 3 | 3 (MVP) / 5 (VS) | 玩家 build 空间大 | 玩家 build 空间小 | 3 = 重装机兵 / classic RPG 经典 |
| `BACKPACK_MAX` | 20 | 10–50 | 玩家囤积倾向 | 玩家频繁取舍 | 20 = 3 槽 + 17 备用 = 约 4-5 章节的战利品 |
| `PICKUP_DECISION_TIMEOUT_S` | 0.5 | 0.0–5.0 | 玩家没时间思考 | 弹窗卡住玩家 | 0.5s = 30 帧 @ 60 FPS 短暂窗口 |
| `PICKUP_DEFAULT_ON_TIMEOUT` | "in_inventory" | "in_inventory" / "discard" | 玩家不用担心漏拾 | 玩家需要立即做决策 | 默认入背包最安全 |
| `AMMO_STACK_SIZE` | 99 | 10–999 | 弹药永不缺 | 弹药紧张 | 99 = "够用上限"（per #1） |
| `TOTAL_WEAPON_TYPES_AVAILABLE` | 12 | 8–20 | build 深度大 | build 深度小 | 12 = 4 章 × 3 把（每章发现 3 把） |
| `TOTAL_AMMO_TYPES_AVAILABLE` | 3 | 3 (MVP) / 4 (VS) | build 深度大 | build 单一 | 3 = MVP 验证足够 |
| `WEAPON_DROP_RATE_BOSS` | 1.0 | 1.0 | — | — | boss 100% 掉（per #7） |
| `WEAPON_DROP_RATE_ELITE` | 0.40 | 0.20–0.60 | 精英=武器库 | 精英没存在感 | 40% = 显著但不滥用 |
| `WEAPON_DROP_RATE_GRUNT` | 0.10 | 0.05–0.20 | 普通怪也掉武器 | 普通怪没奖励 | 10% = 主要奖励是 ammo / credits |
| `AMMO_PICKUP_QTY_GRUNT` | 5 | 1–20 | 弹药过度堆积 | 弹药不够用 | 5 = 约 2-3 场战斗量 |
| `AMMO_PICKUP_QTY_ELITE` | 15 | 5–30 | 弹药过度堆积 | 弹药不够用 | 15 = 约 6-8 场战斗量 |
| `AMMO_PICKUP_QTY_BOSS` | 50 | 20–100 | 弹药无限 | 弹药不够 | 50 = 满满一箱 |

### 跨系统杠杆

| 杠杆 | 影响范围 | 当前值 | 调高 → | 调低 → |
|------|----------|---------|---------|---------|
| `WEAPON_SLOT_COUNT` | Pillar 3 build 深度 | 3 | 玩家可玩 build 多 | 玩家 build 空间紧 |
| `BACKPACK_MAX` | 玩家囤积 vs 抉择 | 20 | 玩家倾向囤积 | 玩家倾向取舍 |
| `WEAPON_DROP_RATE_GRUNT` | 探索回报节奏 | 0.10 | 玩家频繁得新武器（破坏发现感） | 普通怪没存在感 |

## Visual/Audio Requirements

| 事件 | 视觉反馈 | 音频反馈 | 备注 |
|------|----------|----------|------|
| 拾取武器弹窗 | 武器 icon 居中放大 + "获得 [name]" 文字（per art-bible 霓虹发光） | 拾取 chime | per C-R5 |
| 武器入背包 | icon 飞向右上 HUD 武器库 | 短入背包音 | 决策完成后 |
| 武器装备 | HUD 槽位 icon 切换 + 短暂高亮 | 装备音 | 决策完成后 |
| 武器丢弃 | icon 飞出屏幕 + 灰化 | 短丢弃音 | 不可逆 |
| 武器切到空槽 | "无武器" 文字 + HUD 槽位红框 | 拒绝音 | per #2 F2 |
| 弹药切到不兼容 | "武器不兼容该弹药" 文字 | 拒绝音 | per C-R8 E9 |
| 弹药切换 | HUD 弹药 icon 立即切换 + 伤害预览数字变 | 切换音 | 立即生效（per #7 C-R2） |
| 武器库页打开 | 12 把武器 grid + 3 个装备槽高亮 | UI 音 | HUD 渲染 |
| 背包满 | 红字警告 + 闪烁 | 警告音 | F3 |

## UI Requirements

| 信息 | 消费者 | 触发 | 备注 |
|------|--------|------|------|
| 武器库 3 槽状态 | HUD | 每帧 | 槽位 0/1/2 + 装备的武器 icon |
| 当前武器 | HUD | 战斗中按 1/2/3 | 武器 icon + 名称 + 伤害 |
| 当前弹药 | HUD | 战斗中按 Q/E | 弹药 icon + 名称 + mult |
| 弹药数 | HUD | 拾取 / 消耗 | 数字 |
| 拾取弹窗 | HUD | OFFERED 状态 | 武器 icon + "获得 [X]" + 4 个选项按钮 |
| Codex 百分比 | Codex | 首次发现 | "X / 12 已发现" |
| 武器 / 弹药库页 | HUD / 菜单 | 玩家主动打开 | grid 视图 |
| 丢弃确认弹窗 | HUD | 玩家选"丢弃" | "确认丢弃 [X]? 不可恢复" |

**关键约定**：本系统**不直接渲染** UI widget——只**提供** `inventory_state: Dictionary` 给 HUD，HUD 自己渲染。拾取弹窗的 4 按钮布局由 HUD 设计（per #2 玩家输入 GDD UI 协同）。

## Acceptance Criteria

> Solo 模式（`qa-lead` 未咨询），生产前人工 review。

### 武器槽

- **AC-1**：**GIVEN** 玩家装备槽 0=激光枪、槽 1=粒子炮、槽 2=空 **WHEN** 测 weapon_slots **THEN** `weapon_slots = [laser, cannon, null]`。验证：C-R1 槽位。
- **AC-2**：**GIVEN** 玩家槽 2=空 **WHEN** 按 3 攻击 **THEN** per #2 F2 显示"无武器"拒绝反馈，回合不消耗。验证：E2。
- **AC-3**：**GIVEN** 玩家背包满 20 把武器 + 3 槽全装备 **WHEN** 拾取新武器 **THEN** 弹"必须丢弃一项才能拾取"界面，4 选项（丢弃旧 / 丢弃新 / 取消 / 入背包如果换出）。验证：E1 + F3。

### 弹药

- **AC-4**：**GIVEN** 玩家持有普通弹 99 + 拾取 5 普通弹 **WHEN** 测 ammo_inventory **THEN** 普通弹 = 99（堆叠上限），5 进入丢弃。验证：F5 堆叠。
- **AC-5**：**GIVEN** 玩家 current_ammo=普通弹 **WHEN** 按 Q 切弹药 **THEN** current_ammo = 电浆弹（per #7 C-R2 不消耗回合）。验证：弹药切换。
- **AC-6**：**GIVEN** 玩家装备激光枪 + current_ammo=爆破弹（不兼容）**WHEN** 按 Q 试图切到爆破弹 **THEN** 切换不发生，UI 提示"激光枪不兼容爆破弹"。验证：C-R8 E9。

### Build 公式

- **AC-7**：**GIVEN** 玩家装备粒子炮（base 35）+ current_ammo=电浆弹（mult 1.3）**WHEN** 测 build_damage_preview **THEN** = int(35×1.3) = 45。验证：F1 公式。
- **AC-8**：**GIVEN** 玩家装备粒子炮（35）+ 电浆弹（1.3）**WHEN** HUD 显示 build preview **THEN** 显示 45（per #2 弹药切换立即生效）。验证：HUD 实时更新。

### 拾取流

- **AC-9**：**GIVEN** 玩家击杀普通敌人 + drop_rate=0.10 + 武器 drop **WHEN** 战斗胜利 **THEN** 弹窗"获得 [weapon]" + 4 选项，玩家选"装备" → 进对应槽（如果该槽空）or 替换该槽（如果已装备）。验证：C-R5 玩家决策。
- **AC-10**：**GIVEN** 弹窗 0.5s 超时 **WHEN** 测默认行为 **THEN** 武器入背包（如果未满）或弹"必须丢弃"（如果满）。验证：F4 默认行为。
- **AC-11**：**GIVEN** 玩家弹窗选"丢弃" **WHEN** 测武器状态 **THEN** 武器进入 DISCARDED 状态，永久不可恢复。验证：C-R6 不可逆。

### 战斗集成

- **AC-12**：**GIVEN** 玩家按 1 切激光枪（per #7 C-R3）**WHEN** 测战斗 attack **THEN** 激光枪 × current_ammo 组合立即 attack，伤害 = F1 公式。验证：#7 集成。
- **AC-13**：**GIVEN** 玩家战斗中按 Q/E 切弹药 **WHEN** 测回合消耗 **THEN** 弹药切换**不**消耗回合（per #7 C-R2）。验证：弹药切换 free action。

### Codex / 发现

- **AC-14**：**GIVEN** 玩家首次获得粒子炮 **WHEN** 测 Codex **THEN** Codex 显示 13/12 + "新发现！"特效 + 粒子炮解锁完整描述。验证：#1 C-R8 + Codex 集成。

### 存档

- **AC-15**：**GIVEN** 玩家存档时持有 [laser, cannon, missile] + 普通弹 50 + 电浆弹 30 + 跟踪弹 20 **WHEN** 测 save data **THEN** save 包含 `weapon_slots: [laser_id, cannon_id, missile_id]` + `ammo_inventory: {normal: 50, plasma: 30, tracker: 20}` + `current_ammo: tracker`。验证：序列化。

## Open Questions

| 问题 | Owner | 截止 | 决议 |
|------|-------|------|------|
| MVP 是否允许玩家"丢弃已装备的武器"（变空槽）？ | game-designer | 战斗 GDD 阶段 | 当前定：允许（per E5），但 UI 警告"会进入无武器状态" |
| 弹药是否在战斗中"消耗"（每次 attack 用 1 发）？ | systems-designer + game-designer | 战斗 GDD 阶段 | 当前定：**不消耗**——弹药只是"装填模式偏好"，per #7 E7 |
| 武器升级（VS 阶段）是否影响 ammo_slot 兼容性？ | systems-designer | VS 阶段 | 当前定：不影响（升级只改 base_damage / accuracy） |
| 同一武器不同 level 在图鉴中算"1 个"还是"N 个"？ | codex | Codex GDD 阶段 | 当前定：1 个（Codex 关心"有哪些武器"，不关心 level） |
| 是否支持"武器镶嵌宝石"等深度系统？ | systems-designer | VS 阶段 | 当前定：MVP 不支持（保持 build 简单） |
| 拾取弹窗 4 按钮的具体键位？ | ux-designer | 战斗 GDD 阶段 | 当前定：[1] 装备 / [2] 入背包 / [3] 丢弃 / [ESC] 取消 / 0.5s 超时 = 默认入背包 |
| **弹药不消耗 UX 风险**：OQ #2 决定弹药只是"装填模式偏好"（不消耗），但 classic RPG 玩家期待消耗。需要 onboarding 提示：1st terminal log (per Pillar 4) 解释"弹药不会消耗——你可以随时切换 build 试错" | ux-designer + npc-terminal | 实施前 | **待补 onboarding 提示设计**（lean first review Rec #2, 2026-06-12） |
| **拾取弹窗 state interaction 风险**：OQ #6 用 1/2/3 = 装备/入背包/丢弃，但 #7 Battle Core 用 1/2/3 = 立即攻击。拾取弹窗**只**应在 BATTLE_END_VICTORY 或 EXPLORATION 状态出现，**不**在 BATTLE 中。需显式 AC | gameplay-programmer | 实施前 | **待补 AC "no pickup popup in BATTLE state"**（lean first review Rec #3, 2026-06-12） |
