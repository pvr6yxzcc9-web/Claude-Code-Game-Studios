# 战斗核心循环 (Battle Core Loop)

> **Status**: Approved
> **Author**: user + game-designer + gameplay-programmer + ai-programmer
> **Review Verdict**: APPROVED (first review 2026-06-12, lean, prototype-validated)
> **Last Updated**: 2026-06-12 (first review)
> **Implements Pillar**: Pillar 3（每次战斗都是 build 试验）—— 双模式 + 武器×弹药 build 是核心；Pillar 2（发现 > 数值）—— 战斗爽点不是"看见数字变大"而是"build 验证"

## Summary

战斗核心循环是 Railhunter **gameplay 的心脏**——管理 BATTLE 状态中的回合推进、手动/自动双模式切换、武器×弹药 build 试验、防御、敌人 AI 决策、战斗结束 → 战利品/经验/剧情的产出。它**整合**了 5 个 Foundation 系统（Resource/Data、Player Input、Game State Machine、Camera、Collision）的输入，输出"战斗有回报"的玩家体验。

> **Quick reference** — Layer: `Core` · Priority: `MVP` · Key deps: `Resource/Data #1`（武器/弹药/敌人 Resource）、`Player Input #2`（input actions）、`Game State Machine #3`（state transition）、`Camera #4`（VICTORY/DEFEAT rig）、`Collision #5`（bullet hit detection）· Depended on by: 武器弹药 #11/#12、伤害计算 #8、敌人 AI #10、机甲升级 #13、关卡 #15、暗雷 #16

## Overview

战斗核心循环是 Railhunter **gameplay 的心脏**。它管理 BATTLE 状态中的：回合推进（玩家回合 → 玩家行动 → 敌人回合 → 敌人行动 → 循环）、手动/自动双模式切换、武器×弹药 build 试验、防御、敌人 AI 决策、战斗结束 → 战利品/经验/剧情产出、以及战斗结束回到 EXPLORATION 状态。

本系统**整合**了 5 个 Foundation 系统（Resource/Data 提供武器/弹药/敌人 Resource、Player Input 提供 input actions、Game State Machine 提供 BATTLE 状态切换、Camera 提供 VICTORY/DEFEAT 机位、Collision 提供 bullet hit detection），输出"每次战斗都是一次 build 试验"的玩家体验。

**这是所有 prototype 学习**的归宿：手动/自动双模式已验证 PARTIALLY CONFIRMED（prototype 玩家反馈"1/2/3 选武器立即攻击比先选+确认更顺手"已采纳为本系统 C-R3；"敌人 HP 200 太硬"已转化为本系统生产推荐"30-50 HP 普通敌人"）。

如果本系统不存在，**游戏没有 gameplay**——探索 + 收集 + 剧情都在，但核心的"战斗回报"循环完全不存在。

**在 5 层 Core 中**：本系统是**唯一**的 Core 层系统（按 systems-index 排序，Core 层只有 1 个）。它依赖全部 5 个 Foundation，被 6 个 Feature 系统依赖。

## Player Fantasy

玩家**直接接触**这个系统——他们每个回合都在和它互动。

他们感受到的，是**"战斗从不卡顿 + 战术深度可自选"**：

- **战斗开局**：状态从 EXPLORATION 切到 BATTLE（per 相机 #4 FADE_BLACK 0.4s），HUD 切到战斗布局（HP 条 / 武器 / 弹药 / 模式），状态徽章显示 `BATTLE + MANUAL`
- **手动模式**（默认 / 战术）：玩家**逐回合决策**——按 1/2/3 选武器**立即攻击**（per prototype 学习，C-R3）；按 Q/E 切弹药（不消耗回合）；按 D 防御（减伤 50% 下次受击）；按 A 切自动模式。**核心爽点**：build 试验的策略深度
- **自动模式**（可一键切换 / 默认开）：AI 接管——按"最优策略"选最高伤害武器 + 最佳弹药，必要时防御或用道具。**核心爽点**：**减压**——可以在休息时挂机刷图，不影响日常生活
- **模式切换设计**：A 键**战斗中任何时刻**切换（不打断当前回合），不需要确认
- **回合节奏**：玩家回合 → 玩家行动（瞬时响应）→ 敌人回合（0.5s 延迟 per prototype）→ 敌人行动 → 玩家回合
- **命中反馈**：伤害数字弹出 + 命中粒子 + 相机 4px shake + 命中音（per #4 相机 + art-bible）——build"打中了"的爽点
- **弹药切换反馈**：HUD 立即更新弹药类型 + 伤害预览——"立即生效"（per prototype 玩家反馈"反馈立即生效"）
- **战斗胜利**：相机 zoom 推进到玩家机甲特写（per #4 VICTORY rig），胜利音乐起，战利品弹出
- **战斗失败**：相机 roll 3° + shake + 灰度（per #4 DEFEAT rig），状态机 replace(TITLE)

这背后的情感是 **Pillar 3（每次战斗都是 build 试验）**——手动模式下玩家主动 build 试验，自动模式下玩家被减压和刷级解放；**Pillar 2（发现 > 数值）**——战斗爽点不是"看见伤害数字变大"，而是"build 验证（这个弹药对这种敌人有效！）"。

参考游戏：
- **《重装机兵》FC** —— 暗雷遇敌 + 武器切换 + 回合制的核心灵感
- **Into the Breach** —— 自动模式 + 完美 hit feedback 的典范
- **Outer Wilds** —— 战斗不应是 grind（与 Pillar 4 真相收集一致）

> `creative-director` 未咨询（Solo 模式）。

## Detailed Design

### Core Rules

本系统有 **8 条 invariant**。

**C-R1 — 回合结构固定：4 阶段**。`PHASE_PLAYER_INPUT` → `PHASE_PLAYER_ACTION` → `PHASE_ENEMY_INPUT` → `PHASE_ENEMY_ACTION` → 循环。**禁止**新阶段（除非 game design 改）。每阶段在单帧内转换。

**C-R2 — 玩家回合 1 行动 = 1 回合**。玩家在 PHASE_PLAYER_INPUT 选 1 个 action（attack / defend / item / skill / flee）后立即进入 PHASE_PLAYER_ACTION 并消耗本回合。**例外**：弹药切换不消耗回合（per prototype）——`Q/E` 是 free action。

**C-R3 — 1/2/3 选武器 = 立即攻击（无确认步骤）**。这是 prototype 验证后采纳的关键 UX——按 1/2/3 = 选武器 + 立即执行 attack action。**禁止**"先选武器 + 再按空格确认"的两步流程（per prototype 玩家反馈"改成手动攻击的时候 1,2,3 按键直接就用各自武器攻击了吧，不要再按空格了"）。

**C-R4 — A 键模式切换不打断回合**。战斗中任何时刻按 A 立即切换 manual ↔ auto。**不**清空当前回合、**不**重置行动队列、**不**回滚敌人决策。如果切换瞬间玩家已选 action 但未执行，**继续执行**玩家的选择（不归 AI 接管）。

**C-R5 — 自动模式 AI = "最优策略"**。AI 按以下优先级决策：
1. 若玩家 HP ≤ 30%：使用 repair_kit（如果有）
2. 若敌人即将击杀玩家（敌人攻击 > 玩家 HP）：defend
3. 否则：选最高 final_damage = weapon.base_damage × ammo.damage_mult 的组合
4. 弱点匹配：若某个 ammo 在敌人 `weaknesses` 列表中，优先级 +1

**C-R6 — 战斗结束 = 状态机 transition_to(EXPLORATION)**。胜利或失败都通过 `transition_to(EXPLORATION)`（不是 replace TITLE——失败流是状态机 #3 的责任，不在本系统）。本系统**只**emit `signal battle_ended(result: StringName, rewards: Dictionary)`。

**C-R7 — 战利品由独立 DropTable 处理**。本系统**不**直接给玩家物品。战斗胜利后 emit `signal battle_ended` + `rewards: Dictionary` (包含 `xp: int`, `credits: int`, `drops: Array[ItemData]`)。HUD 显示战利品 + 玩家按确认键入背包。

**C-R8 — 防御是"减伤 50%"的 1 次性 buff**。玩家按 D 防御 = 标记 `player_defending = true`，下次敌人攻击伤害 × 0.5。**单次消耗**——下次受击后 `player_defending = false`。可以连续多回合防御（每回合重新 mark）。

### States and Transitions

**8 个战斗内部状态**（本系统私有，不在 #3 全局状态机）：

| 状态 | 用途 | 进入条件 | 退出条件 |
|------|------|----------|----------|
| `INIT` | 战斗初始化（加载敌人、生成玩家回合） | BATTLE 状态被进入 | 立即 → PLAYER_INPUT |
| `PLAYER_INPUT` | 等待玩家 / AI 决策 | 初始化后 / 敌人行动后 | 玩家 / AI 选 action → PLAYER_ACTION |
| `PLAYER_ACTION` | 执行玩家 action（攻击 / 防御 / 物品） | PLAYER_INPUT 退出 | action 完成 → ENEMY_INPUT |
| `ENEMY_INPUT` | 敌人 AI 决策（0.5s 延迟 per prototype） | PLAYER_ACTION 完成 | 敌人 AI 决策完 → ENEMY_ACTION |
| `ENEMY_ACTION` | 执行敌人 action | ENEMY_INPUT 完成 | 敌人行动完 → check_battle_end |
| `BATTLE_END_VICTORY` | 胜利机位 + 战利品显示 | 敌人 HP ≤ 0 | 玩家确认 → emit battle_ended |
| `BATTLE_END_DEFEAT` | 失败机位 + 死亡流 | 玩家 HP ≤ 0 | 玩家确认 → emit battle_ended |
| `BATTLE_END_FLED` | 逃跑成功 | 玩家选 flee 且成功 | 玩家确认 → emit battle_ended |

**回合结构**：

```
        ┌─────────────────────────────────────┐
        ↓                                     │
[INIT] → [PLAYER_INPUT] → [PLAYER_ACTION] → [ENEMY_INPUT] → [ENEMY_ACTION]
                       │                                              │
                       └──────[check_battle_end]─────────────────────┘
                                      ↓
                          [BATTLE_END_VICTORY / DEFEAT / FLED]
                                      ↓
                          emit battle_ended → 状态机 #3 transition_to(EXPLORATION)
```

**关键约束**：
- 1 回合 = 1 次 PLAYER_INPUT + 1 次 PLAYER_ACTION + 1 次 ENEMY_INPUT + 1 次 ENEMY_ACTION
- 任何阶段被打断（pause / 状态转换）必须能恢复
- 自动 / 手动模式共享同一状态机——只有"谁选 action"不同

### Interactions with Other Systems

| 系统 | 接口 | 触发 |
|------|------|------|
| **资源 / 数据 #1** | 读 `WeaponData.tres` / `AmmoData.tres` / `EnemyData.tres` | 初始化 + 每次行动 |
| **玩家输入 #2** | 订阅 `action_pressed(attack / defend / cycle_weapons / cycle_ammo / flee / use_item / toggle_mode)` | 玩家决策 |
| **游戏状态机 #3** | `transition_to(BATTLE)`（外部触发）+ `transition_to(EXPLORATION)`（战斗结束） | 进出 BATTLE |
| **相机 #4** | `set_rig(RIG_VICTORY / DEFEAT)`（per C-R5 例外）+ `request_shake` | 战斗结束 / 命中 |
| **碰撞 #5** | 订阅 `signal bullet_hit(bullet, enemy)` | 子弹命中（但本系统不直接处理——伤害由 #8 伤害计算） |
| **武器弹药 #11/#12** | 调用 `Inventory.get_equipped_weapon()` / `cycle_ammo()` | 玩家切武器 / 切弹药 |
| **伤害计算 #8** | 调用 `DamageCalc.compute(weapon, ammo, target, attacker_is_player)` | 每次 attack action |
| **敌人 AI #10** | 委托 `EnemyAI.choose_action(self_enemy_data, battle_state)` | ENEMY_INPUT 阶段 |
| **机甲升级 #13** | 读 `Mech.parts[head/chest/arms/legs].current_hp` | 玩家 HP 受击时 |
| **HUD** | 推送 `battle_state: Dictionary`（每帧更新） | 每帧 |
| **关卡 #15 / 暗雷 #16** | 触发 `transition_to(BATTLE)` + 传 enemy_data | 遇敌 |

**所有权约定**：
- 本系统**唯一拥有**"战斗中现在是什么 phase"
- 玩家 HP 改动：本系统**写**（受击时）但**不**读（HP 由 #13 机甲持有，本系统读机甲的 HP）
- 敌人 HP 改动：本系统**写**
- 战利品：本系统**只 emit rewards**，**不**直接修改玩家背包

## Formulas

### F1. Final Damage (per #1 资源 + 武器弹药 #11/#12)

`final_damage = base_damage × ammo_mult × crit_mult × weakness_mult × defense_mult`

| 变量 | 类型 | 范围 | 描述 |
|------|------|------|------|
| `base_damage` | int | 20–80 | `WeaponData.base_damage`（per #1） |
| `ammo_mult` | float | 0.8–1.3 | `AmmoData.damage_mult`（per #1） |
| `crit_mult` | float | 1.0 / 2.0 | 默认 1.0，命中暴击时 = `WeaponData.crit_multiplier` |
| `weakness_mult` | float | 1.0 / 1.5 / 0.5 | 默认 1.0；若 ammo 在 enemy.weaknesses = 1.5；若 ammo 在 enemy.resistances = 0.5 |
| `defense_mult` | float | 1.0 / 0.5 | 默认 1.0；若 target 处于 `defending` 状态 = 0.5 |

**Formula expression**: `final_damage = int(base_damage * ammo_mult * crit_mult * weakness_mult * defense_mult)`

**Output Range (after canonical clamps per ADR-0011)**: 10 (enforced min — `BattleMathLib.ApplyMinDamageRule`) to 480 (enforced max — `BattleMathLib.MAX_DAMAGE` constant)
- **Raw computed**: 8 (min: 20×0.8×1.0×0.5×1.0 = 8) to 312 (max: 80×1.3×2.0×1.5×1.0 = 312)
- **After clamps**: 10 to 480 (per ADR-0011)
- **After boss one-shot immunity** (per ADR-0011): boss damage is capped to `current_hp - 1` when `boss_immune_to_one_shot=true` (default)
**Edge case**: 最小伤害 = 10 (clamped from natural min 8) — 普通攻击不会"擦伤"，保证战斗有进展
**Example**: 粒子炮（35）× 电浆弹（1.3）× 无暴击（1.0）× 弱点（1.5）× 无防御（1.0）= int(35 × 1.3 × 1.0 × 1.5 × 1.0) = **68** (within bounds, no clamp)

### F2. Hit Chance (per #1 资源 + #2 玩家输入 E6)

`hit = randf() <= weapon.accuracy`

| 变量 | 类型 | 范围 | 描述 |
|------|------|------|------|
| `accuracy` | float | 0.0–1.0 | `WeaponData.accuracy`（per #1） |

**Output Range**: 50% (导弹) to 90% (激光枪) default; tracker 弹 100% 命中（per #1 enemy.resistances ignored against tracker）
**Edge case**: `accuracy = 0` = 永不命中（debug 用）

### F3. Auto-Mode AI Decision (per C-R5)

```
function auto_ai_decide(player, enemies, inventory):
    if player.hp_pct <= 0.30 and inventory.has("repair_kit"):
        return use_item("repair_kit")
    if enemies.predicted_damage_to_player() >= player.hp:
        return defend
    best = max(combinations, key=lambda c: predicted_damage(c, enemies[0]))
    return best.attack_action
```

| 变量 | 类型 | 范围 | 描述 |
|------|------|------|------|
| `player.hp_pct` | float | 0.0–1.0 | 玩家 HP 百分比 |
| `predicted_damage_to_player` | function | — | 敌人下次攻击预测 |
| `best.attack_action` | Action | — | 最高 expected_damage 的 attack |

**Output Range**: AI 决策耗时 ≤ 50ms（per 性能预算）
**Edge case**: AI 不可达的 action 不被选（如 `flee_battle` 在 boss 战被禁用）

### F4. Battle Duration Estimate (per F1 + enemy HP)

`turns_to_kill_enemy = ceil(enemy.max_hp / expected_damage_per_turn)`

| 变量 | 类型 | 范围 | 描述 |
|------|------|------|------|
| `enemy.max_hp` | int | 30–200 | per #1 生产推荐（per prototype 教训：不是 200） |
| `expected_damage_per_turn` | float | 8–200 | 用玩家最优 build 算的预期伤害 |

**Default enemy HP range**（per prototype + #1 生产推荐）：
- 普通敌人：30–50 HP → 玩家 3–5 回合击杀（生产目标）
- 精英敌人：80–120 HP → 6–10 回合
- BOSS：200+ HP → 15+ 回合（需要多 phases / 召唤小怪，不只是堆血量）

**Output Range**: 3 (普通, optimal build) to 20+ (BOSS, suboptimal build)
**Edge case**: 玩家用最弱 build vs BOSS = 永远打不过 = 应该逃跑 / 撤退

### F5. Reward Calculation (per C-R7)

`rewards = {xp, credits, drops}`

| 变量 | 类型 | 范围 | 描述 |
|------|------|------|------|
| `xp` | int | 10–500 | 普通 30, 精英 100, BOSS 300 |
| `credits` | int | 5–200 | 普通 20, 精英 80, BOSS 200 |
| `drops` | Array[ItemData] | 0–3 | 从 `EnemyData.drops` 表 + 概率 roll |

**Formula**: 每个 drop 独立 `randf() <= drop_rate`。
**Output Range**: 普通敌人 80% 掉 1 件；BOSS 100% 掉 1 件 + 50% 第二件。
**Edge case**: 背包满 → drop 进入"丢弃"流（per #1 E8）

## Edge Cases

| # | 条件 | 结果 | 原因 |
|---|------|------|------|
| 1 | **1/2/3 按键时处于 ENEMY_INPUT 阶段**：玩家提前按了 | 1/2/3 绑定的 action 被 InputBus 抑制（InputBus 只在 PLAYER_INPUT 阶段路由战斗 action） | per #2 C-R6 焦点路由；战利品按确认时按 1/2/3 不该触发攻击 |
| 2 | **玩家按 A 切自动的瞬间，敌人正在行动**：敌人动画 / 伤害数字已发出 | A 切自动不影响**当前帧**已发出的敌人 action，玩家下一个 PLAYER_INPUT 时 AI 接管 | C-R4 模式切换不打断回合 |
| 3 | **战斗中玩家死亡前最后时刻按 A**：HP ≤ 0 的同一帧按 A | 切自动**不**阻止死亡（HP 已经到 0），玩家看到 DEFEAT 机位 | AI 不能复活玩家 |
| 4 | **自动模式 AI 选 action 后，玩家立即按 1/2/3**：切回手动 + 1/2/3 攻击 | 玩家的 1/2/3 覆盖 AI 决策，**只**在本 PLAYER_INPUT 阶段（下一个阶段仍按手动算） | C-R4 模式切换不打断回合，但玩家可"立刻反悔" |
| 5 | **敌人被打死，玩家回合仍然进行**：玩家选了 action，但敌人 HP 在 PLAYER_ACTION 阶段归零 | action 仍然执行（伤害溢出），然后跳到 BATTLE_END_VICTORY（跳过 ENEMY_INPUT / ENEMY_ACTION） | 战斗早期结束 |
| 6 | **逃跑成功，但玩家没意识到**：flee 选了，50% 概率成功，敌人回合继续 | 显示"逃跑成功！"提示 + BATTLE_END_FLED | 玩家必须能区分"成功" vs "失败" |
| 7 | **逃跑失败，玩家被敌人打死**：flee 失败后敌人攻击 | 玩家 HP 0 → BATTLE_END_DEFEAT | 逃跑有风险 |
| 8 | **战利品满了 99 个弹药，再得 5 个** | per #1 E8 堆叠上限 → 后 5 个进丢弃 | 不让玩家卡死 |
| 9 | **boss 战不可 flee**：`EnemyData.boss == true` | `flee_battle` action 被本系统 disable，UI 显示"无法逃跑" | boss 必须被打 |
| 10 | **mode-toggle 在 PLAYER_ACTION 阶段被按**：动画 / 伤害数字在播 | mode 切换**立即**生效，下一帧的 UI 显示新模式 | C-R4 不打断，但 UI 状态可立即变 |
| 11 | **玩家按 ESC 在 BATTLE 中**（per #2 修订后）| ESC 取消目标（per #2 玩家输入 C-R4）+ 不退出战斗 | 战斗中按 ESC 不退出 = 不能误退 |
| 12 | **defend 后被多个 AOE 同时命中**：3 个 AOE tick 同帧 | `defending = false` 在**第一次**命中后消耗，后续命中按正常伤害 | 单次减伤 |
| 13 | **AI 在自动模式下选择"flee"** | AI **不**选 flee（per F3 优先级——只考虑 attack / defend / use_item） | 自动模式不该让玩家"被 AI 拉走" |

## Dependencies

### 上游依赖（5 个 Foundation）

| 系统 | 接口 | 备注 |
|------|------|------|
| **资源 / 数据 #1** | `WeaponData.tres` / `AmmoData.tres` / `EnemyData.tres` / `ItemData.tres` | 数据源 |
| **玩家输入 #2** | 订阅 input actions（attack_primary/secondary, defend, cycle_weapons, cycle_ammo, flee, use_item, toggle_mode） | input 路由 |
| **游戏状态机 #3** | `transition_to(BATTLE / EXPLORATION)` | 状态切换 |
| **相机 #4** | `set_rig(VICTORY/DEFEAT)` + `request_shake` | 战斗视觉 |
| **碰撞 #5** | 订阅 `bullet_hit` 信号（per 战斗子弹命中） | 命中检测 |

### 下游依赖（6+ 个系统）

| 系统 | 接口 | 备注 |
|------|------|------|
| **武器弹药 #11/#12** | 调用 `Inventory.get_equipped_weapon()` / `cycle_ammo()` | 装备 / 弹药 |
| **伤害计算 #8** | 调用 `DamageCalc.compute(weapon, ammo, target, attacker_is_player)` | 伤害公式 |
| **敌人 AI #10** | 委托 `EnemyAI.choose_action(enemy_data, battle_state)` | 敌人决策 |
| **机甲升级 #13** | 读 `Mech.parts[].current_hp` + 写（受击时） | 部位 HP |
| **HUD** | 推送 `battle_state: Dictionary` | UI 状态 |
| **关卡 #15 / 暗雷 #16** | 触发 `transition_to(BATTLE)` + 传 enemy_data | 遇敌 |
| **存档 #21** | 序列化 battle_state（per #3 状态机 snapshot） | 读档 |

### 双向约束

| 约束 | 在 #2 中 | 在本 GDD 中 |
|------|----------|-------------|
| 1/2/3 = 立即攻击 | #2 玩家输入 E1 (Blk #1 修订) | C-R3 |
| ESC 战斗中 = 取消目标（不退出） | #2 C-R4 / Blk #1 | E11 |
| A 键 = 切模式不打断 | #2 Game Feel G-F2 | C-R4 |
| Q/E 弹药切换不消耗回合 | #2 Formulas 自由行动 | C-R2 例外 |
| 防御 50% 减伤 | #2 G-F4 + 0.5s hold | C-R8 |
| VICTORY/DEFEAT 机位 | #4 相机 C-R5 | 本系统胜利 / 失败 emit |

## Tuning Knobs

| 参数 | 当前默认值 | 安全范围 | 调高 → | 调低 → | 为什么取这个数 |
|------|------------|----------|---------|---------|----------------|
| `ENEMY_HP_GRUNT_MIN` | 30 | 20–50 | 战斗拖长 | 一击必杀 | per prototype 教训：200 太硬 |
| `ENEMY_HP_GRUNT_MAX` | 50 | 30–80 | 战斗拖长 | 一击必杀 | 30-50 = 3-5 回合击杀 |
| `ENEMY_HP_ELITE_MIN` | 80 | 60–120 | 战斗拖长 | 普通 = 精英 | 80-120 = 6-10 回合 |
| `ENEMY_HP_BOSS_MIN` | 200 | 150–300 | BOSS 战拖 1 小时 | BOSS 战 5 分钟 | 200+ 需要多 phases |
| `ENEMY_ATTACK_GRUNT_DEFAULT` | 25 | 15–50 | 玩家 4 击倒 | 玩家 20 击倒 | 200 ÷ 25 = 8 击倒 |
| `DEFEND_DAMAGE_MULT` | 0.5 | 0.25–0.75 | 防御几乎免伤 | 防御没用 | 50% = 经典 RPG |
| `FLEE_SUCCESS_RATE` | 0.5 | 0.0–1.0 | 逃跑太容易（破坏战斗） | 逃跑太难（挫败感） | 50% = 经典 RPG |
| `BOSS_CAN_FLEE` | false | true / false | boss 战可逃（破坏体验） | — | boss 必须打 |
| `AUTO_AI_HP_DEFEND_THRESHOLD` | 0.30 | 0.10–0.50 | AI 太保守 | AI 太浪 | 30% HP = 警戒线 |
| `AUTO_AI_DECISION_TIME_MS` | 50 | 10–200 | AI 决策慢（玩家等） | AI 决策快（看不出在思考） | 50ms = 3 帧 @ 60 FPS |
| `REWARD_XP_GRUNT` | 30 | 10–100 | 升级太快 | 升级太慢 | 30 XP = 普通怪基础奖励 |
| `REWARD_XP_ELITE` | 100 | 50–300 | 升级太快 | 升级太慢 | 100 = 3x 普通 |
| `REWARD_XP_BOSS` | 300 | 200–1000 | — | — | 300 = 10x 普通 |
| `REWARD_CREDITS_GRUNT` | 20 | 5–100 | 金钱膨胀 | 金钱太紧 | 20 = 早期可买 1 件 repair |
| `DROP_RATE_GRUNT` | 0.80 | 0.50–1.0 | 玩家觉得"必掉" | 玩家觉得"刷不到" | 80% = 几乎必掉 |
| `DROP_RATE_ELITE` | 1.0 | 0.80–1.0 | — | — | 100% = 精英必掉 |
| `DROP_RATE_BOSS` | 1.0 | 1.0 | — | — | boss 100% 掉 |

### 跨系统杠杆

| 杠杆 | 影响范围 | 当前值 | 调高 → | 调低 → |
|------|----------|---------|---------|---------|
| `ENEMY_HP_GRUNT_MAX` | 战斗节奏（玩家多久能打 1 场） | 50 | 战斗拖长 | 战斗过快 |
| `FLEE_SUCCESS_RATE` | 玩家对"打不过就跑"的信心 | 0.5 | 玩家少尝试 build | 玩家被战斗压死 |
| `AUTO_AI_HP_DEFEND_THRESHOLD` | 自动模式的"求生本能" | 0.30 | AI 偏保守 | AI 偏激进 |

## Visual/Audio Requirements

| 事件 | 视觉反馈 | 音频反馈 | 备注 |
|------|----------|----------|------|
| 战斗开始（状态转换） | 屏幕 0.4s 淡黑（per #4 相机 FADE_BLACK） | 战斗开始音 | 遇敌 tile 触发 |
| 玩家回合开始 | 状态徽章闪烁（手动/自动） | "你的回合" 提示音 | 区分玩家 / 敌人 |
| 玩家攻击命中 | 伤害数字弹出 + 命中粒子（per art-bible）+ 相机 4px shake / 100ms | 命中音（不同武器不同音） | per #4 F1 |
| 玩家攻击未命中 | "MISS" 文字 | 未命中音 | 视觉化失败 |
| 玩家防御 | 玩家机甲变蓝色 0.2s | 防御音 | 视觉 buff 提示 |
| 玩家防御受击 | 0.5x 伤害数字 + "DEFENDED" 文字 | 防御命中音 | 区别普通命中 |
| 弹药切换 | HUD 弹药图标立即切换 + 伤害预览数字变 | 短切换音 | 立即生效（per C-R2） |
| 模式切换（A 键） | 模式徽章 0.15s scale-pulse | 模式切换音 | per #2 G-F2 |
| 敌人攻击命中玩家 | 玩家机甲 0.1s 红色 + 屏幕 6px shake | 受伤音 | per #4 F1 |
| 敌人攻击未命中 | 玩家机甲闪避动画 | 闪避音 | 视觉化成功 |
| 自动 AI 决策 | 玩家机甲"思考"姿态 0.3s | 思考音 | 让玩家知道"AI 在工作" |
| 战斗胜利 | 相机 zoom 推进 VICTORY rig + 1.5x | 胜利音乐 | per #4 C-R5 |
| 战斗失败 | 相机 roll 3° + DEFEAT rig + 灰度 | 失败音乐 | per #4 C-R5 |
| 战利品弹出 | 物品 icon 飞向玩家 + 数字 | 战利品音 | per art-bible |

> 详见 `design/art/art-bible.md` 的"深空废墟中孤独的霓虹"调色 + 粒子原则。

## UI Requirements

| 信息 | 消费者 | 触发 | 备注 |
|------|--------|------|------|
| 玩家 HP（current / max） | HUD | 每帧 | 红色条 + 数字 |
| 玩家机甲部位 HP（4 个） | HUD | 每帧 | 4 个小条 |
| 玩家当前武器 | HUD | `cycle_weapons` / 战斗开始 | 武器 icon + 名称 |
| 玩家当前弹药 | HUD | `cycle_ammo` / 战斗开始 | 弹药 icon + 名称 |
| 玩家弹药数 | HUD | `use_ammo` / 战利品拾取 | 数字 |
| 模式徽章（MANUAL / AUTO） | HUD | 模式切换 | per #2 UI-2 |
| 敌人 HP（current / max） | HUD | 敌人受击 | 红色条 + 数字 |
| 敌人部位 HP（4 个，BOSS 才显示） | HUD | BOSS 战 | 4 个小条 |
| 回合阶段（PLAYER_INPUT / ENEMY_INPUT） | HUD | 阶段变化 | 文字（per #2 UI-2b state badge） |
| 伤害数字 | HUD | 命中 | 飘字 0.5s |
| 战利品弹出 | HUD | 战斗胜利 | 物品 icon + 数量 |
| BATTLE 状态徽章 | HUD | 状态转换 | `BATTLE` 文字 + MANUAL/AUTO 子指示器 |

**关键约定**：本系统**不直接渲染**任何 UI widget——只**提供** `battle_state: Dictionary` 给 HUD，HUD 自己渲染。

## Acceptance Criteria

> Solo 模式（`qa-lead` 未咨询），生产前人工 review。每条都是 Given-When-Then 格式。

### 回合基础

- **AC-1**：**GIVEN** 玩家在 BATTLE 状态 **WHEN** 测战斗 phase **THEN** 顺序为 INIT → PLAYER_INPUT → PLAYER_ACTION → ENEMY_INPUT → ENEMY_ACTION → 循环，1 回合 = 4 phase。验证：C-R1。
- **AC-2**：**GIVEN** 玩家处于 PLAYER_INPUT **WHEN** 选 attack action **THEN** 进入 PLAYER_ACTION 完成 attack 后立即进入 ENEMY_INPUT。验证：4 phase 顺序。
- **AC-3**：**GIVEN** 玩家处于 PLAYER_INPUT **WHEN** 按 Q 切弹药 **THEN** 弹药切换但**不**消耗回合（仍在 PLAYER_INPUT）。验证：C-R2 例外。

### 1/2/3 立即攻击（per prototype 学习）

- **AC-4**：**GIVEN** 玩家处于 PLAYER_INPUT + 装备 weapon_slot_1 武器 **WHEN** 按 1 **THEN** 武器立即切到 slot_1 + 立即执行 attack action。验证：C-R3。
- **AC-5**：**GIVEN** 玩家处于 PLAYER_INPUT **WHEN** 按 2 **THEN** 切到 slot_2 + 立即 attack，**不需要**按空格确认。验证：1/2/3 = 选 + 攻击（per prototype 玩家反馈）。
- **AC-6**：**GIVEN** 玩家处于 PLAYER_INPUT **WHEN** 按 1/2/3 但**没有**装备该 slot 的武器 **THEN** 显示"无武器"提示（per #2 F2 拒绝反馈），回合**不**消耗。验证：边界 + per #2 input refused。

### 模式切换

- **AC-7**：**GIVEN** 玩家处于 manual 模式 + 玩家回合 **WHEN** 按 A **THEN** 模式切到 auto，下一 PLAYER_INPUT 由 AI 决策。验证：C-R4 + C-R5。
- **AC-8**：**GIVEN** 玩家处于 auto 模式 + 玩家回合 **WHEN** 按 A **THEN** 模式切到 manual，AI **不**已选 action（因为还没到决策点），玩家继续。验证：模式切换不打断。
- **AC-9**：**GIVEN** 玩家处于 auto 模式 + AI 正在决策（≤ 50ms 思考）**WHEN** 玩家按 1/2/3 **THEN** 玩家 1/2/3 覆盖 AI 决策，立即执行 attack。验证：玩家随时夺回控制。
- **AC-10**：**GIVEN** 玩家处于 auto 模式 + 玩家 HP ≤ 30% **WHEN** AI 决策 **THEN** AI 优先用 repair_kit（per C-R5 优先级 1）。验证：AI 求生本能。
- **AC-11**：**GIVEN** 玩家处于 auto 模式 + 玩家 HP = 100% + 多个武器 **WHEN** AI 决策 **THEN** AI 选最高 final_damage 武器 + 弹药组合。验证：C-R5 优先级 3。
- **AC-12**：**GIVEN** 玩家处于 auto 模式 vs 弱点敌人 **WHEN** AI 决策 **THEN** AI 优先弱点匹配的弹药（weakness_mult 1.5x）。验证：C-R5 优先级 4。

### 伤害公式

- **AC-13**：**GIVEN** 玩家粒子炮（damage 35）+ 电浆弹（mult 1.3）+ 普通敌人 HP 40 + 弱点 1.5x **WHEN** 攻击 **THEN** final_damage = int(35 × 1.3 × 1.5) = 68，敌人 HP = max(0, 40-68) = 0 → 胜利。验证：F1 公式。
- **AC-14**：**GIVEN** 普通敌人 HP 30 + 玩家 HP 200 + 敌人 attack 25 **WHEN** 玩家不动，敌人攻击 8 次 **THEN** 玩家 HP = 0 → 失败。验证：8 击倒（per prototype）。
- **AC-15**：**GIVEN** 玩家防御 + 敌人攻击 25 **WHEN** 测伤害 **THEN** 实际伤害 = int(25 × 0.5) = 12，defending = false。验证：C-R8 单次减伤。

### 战斗结束

- **AC-16**：**GIVEN** 玩家击杀最后一个敌人 **WHEN** 测 phase 转换 **THEN** PLAYER_ACTION 完成后**跳** ENEMY_INPUT/ACTION 直接到 BATTLE_END_VICTORY + 相机切 VICTORY rig。验证：E5 早期结束。
- **AC-17**：**GIVEN** 玩家 HP = 0 **WHEN** 测 phase **THEN** 立即进 BATTLE_END_DEFEAT + 相机切 DEFEAT rig + 状态机 replace(TITLE)。验证：C-R6。
- **AC-18**：**GIVEN** boss 战 + 玩家按 flee **WHEN** 测 **THEN** flee action 被 disable，UI 显示"无法逃跑"，消耗一回合但无事发生。验证：E9。
- **AC-19**：**GIVEN** 普通敌人战 + 玩家按 flee + randf() ≤ 0.5 **WHEN** 测 **THEN** 逃跑成功 → BATTLE_END_FLED + 状态机 transition_to(EXPLORATION)。验证：Flee。
- **AC-20**：**GIVEN** 普通敌人战 + 玩家按 flee + randf() > 0.5 **WHEN** 测 **THEN** 逃跑失败 → 敌人回合继续。验证：Flee 风险。

### 战利品

- **AC-21**：**GIVEN** 普通敌人 80% drop rate + repair_kit 1 个 **WHEN** 战斗胜利 1000 次 Monte Carlo **THEN** 掉落率 0.78-0.82 之间（per #1 AC-7）。验证：RNG 公平。
- **AC-22**：**GIVEN** 玩家背包已满 99 ammo **WHEN** 战斗胜利再得 5 ammo **THEN** 0 进入背包，5 进入丢弃（per #1 E8）。验证：堆叠上限。
- **AC-23**：**GIVEN** 战斗胜利 **WHEN** 测 emit signals **THEN** emit `battle_ended("victory", rewards)` + `rewards` 包含 `xp`, `credits`, `drops[]`。验证：C-R7 战利品 emit。

### 状态与边界

- **AC-24**：**GIVEN** 玩家在 ENEMY_INPUT 阶段按 1/2/3 **WHEN** 测 input 路由 **THEN** input 被 InputBus 抑制（per #2 C-R6 焦点路由），不触发 attack。验证：E1。
- **AC-25**：**GIVEN** 玩家在 BATTLE **WHEN** 按 ESC **WHEN** 测 **THEN** ESC 取消目标（per #2），**不**退出战斗。验证：E11。
- **AC-26**：**GIVEN** 玩家按 D 防御 + 3 个 AOE 同帧命中 **WHEN** 测伤害 **THEN** 第一次 0.5x，后续 1.0x。验证：E12 单次减伤。

### 性能

- **AC-27**：**GIVEN** 战斗 BOSS 战 + 60 敌人 + 200 子弹 **WHEN** 帧率测试 10 秒 **THEN** 帧率 ≥ 55 FPS。验证：性能预算。
- **AC-28**：**GIVEN** AI 决策中 **WHEN** 测 AI 决策时间 **THEN** ≤ 50ms（per F3）。验证：AI 不卡顿。

## Open Questions

| 问题 | Owner | 截止 | 决议 |
|------|-------|------|------|
| 战斗中是否可以"中断"敌人回合（玩家反击）？ | game-designer | 战斗 GDD 阶段 | 当前定：MVP 不可中断（per C-R1 固定 4 phase） |
| 多敌人战斗（≥2 敌人）的"目标选择" UX？ | ux-designer + game-designer | 战斗 GDD 阶段 | 当前定：MVP 1v1（per prototype） |
| BOSS 战"多 phases"具体怎么设计？ | game-designer | 战斗 GDD 阶段 | 当前定：MVP 单 phase BOSS（血量 200-300），VS 加 phases |
| 战利品是否区分"已发现但未持有"和"新发现"？ | game-designer + codex | Codex GDD 阶段 | 当前定：弹窗显示"新发现"特效（per #1 C-R8） |
| 玩家死亡时是否允许"用 repair_kit 自救"？ | systems-designer | 战斗 GDD 阶段 | 当前定：HP = 0 立即失败（不允许自救，per C-R3） |
| 自动模式 AI 是否应该"预读"玩家操作习惯？ | ai-programmer | VS 阶段 | 当前定：MVP 用规则 AI，VS 评估是否加 ML |
| **多敌人战斗的 F 公式占位**：当前 F1/F2/F5 都是单目标，OQ #2 把多敌人推到 VS 但没预留公式 | systems-designer + game-designer | VS 阶段 | **待补 F1b 多敌人 spread damage 公式或显式标记"VS placeholder"**（lean first review Rec #1, 2026-06-12） |
| **BOSS 50% HP 行为变化（防 trash 感）**：MVP 单 phase BOSS 200-300 HP = 8-15 回合拖沓战，建议在 BOSS HP < 50% 时增加新攻击模式 + 新 AOE（threshold-based behavior change） | game-designer | 战斗实施前 | **待评估是否纳入 MVP**（lean first review Rec #3, 2026-06-12） |
