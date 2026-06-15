# 游戏状态机 (Game State Machine)

> **Status**: Approved
> **Author**: user + game-designer + gameplay-programmer + lead-programmer
> **Review Verdict**: APPROVED (first review 2026-06-12, lean)
> **Last Updated**: 2026-06-12 (first review)
> **Implements Pillar**: 全部 4 个 pillar（间接 — 状态清晰是一切玩家体验的前提）

## Summary

游戏状态机是 Railhunter 所有"当前玩家处于什么场景"事实的**单一权威**。它管理一个**显式的状态堆栈**（Title / Exploration / Battle / Menu / Terminal / Codex / Pause），定义合法转换、转换生命周期、暂停语义、autoload 顺序，以及 InputBus 订阅契约。

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None`（地基）· Depended on by: 战斗核心、关卡/迷宫、菜单/暂停、存档/加载、战斗场景切换、HUD 等 7+ 个系统

## Overview

游戏状态机是 Railhunter 所有"当前玩家处于什么场景"事实的**单一权威**。它管理一个**显式的状态堆栈**（Title / Exploration / Battle / Menu / Terminal / Codex / Pause），定义合法转换、转换生命周期、暂停语义、autoload 顺序、InputBus 订阅契约，以及与玩家输入系统（#2）共享的"autoload 必须按此顺序"硬约束。

玩家**永远不会直接接触**这个系统——他们看到的是 HUD 左上角的状态徽章（`EXPLORATION` / `BATTLE` / `PAUSED` 等），听到状态转换的音效，感受到按错的键被礼貌拒绝。这些**全部**通过本系统的"堆栈 + 转换"机制实现。

如果本系统不存在，**所有下游系统（战斗、关卡、菜单、存档、HUD、暂停、场景切换）都得自己维护一份"我现在在什么状态"**——典型的"事实散落"反模式，会导致：暂停时战斗继续跑、菜单打开后玩家还在被敌人打、读档后状态不一致、autosave 触发时玩家正打开 Codex。

**在 5 层 Foundation 中**：本系统是**第 5 层地基**（与 Resource/Data、Player Input、Camera、Collision 并列）。它不依赖任何系统，但被 7+ 个下游系统**Hard 依赖**（详见 Dependencies 段）。

## Player Fantasy

玩家**不会意识到**这个系统的存在——这是它成功的标志。

他们感受到的，是**"我永远知道现在在干嘛"**的清晰感：

- **在探索中按 Tab**：Codex 打开，HUD 状态徽章立刻变 `CODEX`，战斗输入全部被锁，但**不卡顿**
- **战斗中按 Esc**：回合取消，状态徽章保持 `BATTLE`，回到"选目标"阶段
- **战斗中按 Q**（暂停）：战斗状态不变，叠加 `PAUSED` 堆栈，徽章变 `PAUSED`，再次按 Q 弹出
- **读档回到上次**：状态完全一致——如果上次是 BATTLE 第 3 回合玩家回合，读档后精确恢复
- **alt-tab 切出 1 小时再切回**：游戏自动暂停，状态徽章显示 `PAUSED`，不消耗输入、不掉血、不触发战斗
- **关掉 Codex 跳回探索**：无缝衔接，位置、HP、状态全部保持

这背后的情感是 **Pillar 1（探索密度）+ Pillar 2（发现 > 数值）+ Pillar 3（每次战斗都是 build 试验）+ Pillar 4（真相是收集的结果）**的**共同前提**——玩家必须先**永远知道自己在哪**，才能放心去探索 / 试验 / 拼图。状态机是这一切的**隐形骨架**。

参考游戏：**Outer Wilds** —— 玩家在飞船里、空间站上、量子卫星中切换，但从未有"我在哪？"的迷失感。**Into the Breach** —— 战斗中暂停看敌我布局，状态机毫不含糊地处理"暂停 / 取消暂停"。

> `creative-director` 未咨询（Solo 模式）。生产前人工 review。

## Detailed Design

### Core Rules

本系统有 **7 条 invariant**，违反任一条 = 设计审计失败。

**C-R1 — 显式状态枚举，闭集**。游戏有 7 个状态：`TITLE` / `EXPLORATION` / `BATTLE` / `MENU` / `TERMINAL` / `CODEX` / `PAUSE`。状态用 StringName 常量（`&"state_battle"`），不在运行时拼字符串。新增状态 = 改 GDD + 写合法转换表，**不是**实现决定。

**C-R2 — 堆栈语义，不是字典**。状态机是**栈**（LIFO），不是哈希。`push(state)` / `pop()` / `replace(state)` 三种操作。`top_of_stack` 是当前活跃状态。当 `push(PAUSE)` 时，`top_of_stack = PAUSE`，下层状态是 `BATTLE`（暂停的战斗）。`pop()` 后恢复 `BATTLE`。

**C-R3 — 合法转换是 GDD 定义，不是代码定义**。`ALLOWED_TRANSITIONS: Dictionary[StringName, Array[StringName]]` 在本 GDD 表里（见下）。代码**只**用 `transition_to(new_state)`，由状态机校验合法性。非法转换 → 抛 `IllegalTransitionError` + 记录到日志（不崩溃游戏）。

**C-R4 — 转换是原子的 1 帧事件**。`transition_to(new)` 在单帧内完成：
1. 旧状态 `unsubscribe_from_input_bus(bus)`（per 玩家输入 #2 E9 约定）
2. 旧状态 `queue_free()`（除非是 PAUSE——PAUSE 是 overlay，不销毁底层）
3. 新状态 `add_child()` + `subscribe_to_input_bus(bus)`
4. HUD 状态徽章更新（1 帧内）
5. `state_changed` 信号发射

**C-R5 — 暂停语义：`get_tree().paused` + 状态堆栈双管齐下**。
- `get_tree().paused = true`：冻结所有 `_process` / `_physics_process`（动画、计时、AI）
- 状态堆栈 push `PAUSE`：InputBus 不再 dispatch 到下层（Battle 仍订阅，但 InputBus 抑制 dispatch）
- 这**两个机制缺一不可**——只有 `get_tree().paused` 会冻结 input 投递（input handler 不跑），只有状态堆栈会让玩家以为"游戏没暂停"（按 Esc 没反应）

**C-R6 — Autoload 顺序硬约束**。`Project > Autoload` 中必须按以下顺序注册（**这个顺序被 #2 玩家输入 E9 引用**）：
1. `GameStateMachine`（最先）
2. `InputBus`（依赖 GameStateMachine 知道当前状态）
3. 其他 Foundation / Feature autoloads

违反顺序会导致 InputBus 比状态转换早 1 帧 dispatch（玩家按键丢失）。

**C-R7 — 单例 / Autoload 模式，不在代码中找**。`GameStateMachine` 注册在 `Project > Autoload` 为 `GameStateMachine`。所有访问通过 `/root/GameStateMachine`。**没有**静态 `GameStateMachine.instance` 模式（避免和 Godot autoload 双源）。

### States and Transitions

**7 个状态**（按典型出现顺序）：

| 状态 | 用途 | 是否阻塞下层 | 是否订阅 InputBus | 出现频率 |
|------|------|--------------|------------------|---------|
| **TITLE** | 主菜单 | N/A（栈底） | 是 | 启动时 |
| **EXPLORATION** | 地图移动 / 互动 / 遇敌 | N/A（栈底或 push 目标） | 是 | 80% 游戏时间 |
| **BATTLE** | 战斗（替换 EXPLORATION） | 是（`replace` 操作） | 是 | 15% |
| **MENU** | 暂停时的设置 / 存档 | 是（push overlay） | 是 | 偶尔 |
| **TERMINAL** | 阅读 NPC 录音 / 终端 | 是（push overlay） | 是 | 频繁（探索中触发） |
| **CODEX** | 图鉴 | 是（push overlay） | 是 | 偶尔 |
| **PAUSE** | 暂停 | 是（push overlay） | 是 | 频繁 |

**合法转换表**：

| 当前状态 | 目标状态 | 操作 | 触发者 |
|----------|----------|------|--------|
| `TITLE` | `EXPLORATION` | `replace` | 主菜单"开始游戏" |
| `EXPLORATION` | `BATTLE` | `replace` | 暗雷遇敌 |
| `BATTLE` | `EXPLORATION` | `replace` | 战斗胜利 / 逃跑 |
| `EXPLORATION` | `MENU` | `push` | 按 Esc（在主菜单"设置"等二级页面） |
| `EXPLORATION` | `TERMINAL` | `push` | 玩家走近终端并按 E |
| `EXPLORATION` | `CODEX` | `push` | 按 Tab |
| `EXPLORATION` | `PAUSE` | `push` | 按 Esc（在探索中，无菜单时） |
| `BATTLE` | `MENU` | `push` | 按 Q（pause_battle） |
| `BATTLE` | `PAUSE` | **禁止**（BATTLE 自带暂停语义 via Q→MENU） | — |
| `MENU` | *（前状态）* | `pop` | 关闭菜单 |
| `TERMINAL` | `EXPLORATION` | `pop` | 按 Esc |
| `CODEX` | `EXPLORATION` | `pop` | 按 Esc |
| `PAUSE` | *（前状态）* | `pop` | 按 Esc |
| *任何* | `TITLE` | `replace` | 玩家死亡 / 主菜单"回标题" |

**关键约束**：
- `BATTLE` ↔ `EXPLORATION` 是 **`replace`**（不是 push/pop）——战斗是替换场景，不能"叠加"
- `MENU` / `TERMINAL` / `CODEX` / `PAUSE` 都是 **`push` overlay**——底层状态被冻结但不销毁
- 任何 `push` 后只能 `pop` 回**那个底层**状态（不能跨层 pop）

### Interactions with Other Systems

**本系统**管理状态 + 发出信号。**下游**消费信号。

| 下游系统 | 消费方式 | 接口 |
|----------|----------|------|
| **玩家输入 #2** | InputBus 在 dispatch 前查询 `state_machine.top_of_stack` 来路由订阅者 | `GameStateMachine.top_of_stack: StringName` (read-only) |
| **HUD** | 监听 `state_changed(old, new)` 信号 + 状态徽章 widget | `signal state_changed(old: StringName, new: StringName)` |
| **战斗核心 #7** | 触发 `transition_to(BATTLE)` / `transition_to(EXPLORATION)` | `transition_to(state: StringName) -> Error` |
| **关卡 / 迷宫 #15** | 触发 `transition_to(BATTLE)`（遇敌） | 同上 |
| **菜单 / 暂停 #23** | 触发 `push(MENU)` / `push(PAUSE)` / `pop()` | 同上 |
| **存档 / 加载 #21** | 序列化 `state_stack` + `top_of_stack`；读档时 `transition_to(saved_top)` | 读：`GameStateMachine.get_state_snapshot() -> Dictionary`；写：`load_snapshot(snap: Dictionary)` |
| **战斗场景切换 #6** | 监听 `state_changed` 来加载 / 卸载 battle scene | 同 HUD |
| **终端 / Codex 触发** | 触发 `push(TERMINAL)` / `push(CODEX)` | 同上 |
| **聚焦事件** | `NOTIFICATION_WM_WINDOW_FOCUS_OUT` 触发 `push(PAUSE)` | `GameStateMachine` 内置订阅 NOTIFICATION |

**所有权约定**：
- 本系统**唯一拥有**"现在在什么状态"
- 任何下游系统**修改状态 = bug**——所有转换走 `transition_to()`
- InputBus **不**自己判断状态——只问状态机

## Formulas

本系统**不计算复杂数学**——它的"公式"集中在**转换时序**和**输入路由**。

### F1. Transition Latency Budget

`transition_to(new_state)` 的最大完成时间 = 单帧（16.6ms @ 60 FPS）。

| 步骤 | 期望时间 | 上限 |
|------|----------|------|
| 旧状态 `unsubscribe` | 1ms | 3ms |
| 旧状态 `queue_free`（如需） | 0ms（延迟到帧末） | 0ms |
| 新状态 `add_child` + `_ready` | 5ms | 8ms |
| 新状态 `subscribe_to_input_bus` | 1ms | 2ms |
| HUD 状态徽章更新 | 1ms | 2ms |
| `state_changed` 信号 emit + 监听者执行 | 1ms | 1.5ms |
| **总计** | **9ms** | **16.5ms** |

**Output Range**: 9ms (best case) to 16.5ms (帧上限). **Edge case**: 若 16.5ms 帧预算被超过，下游系统的输入 dispatcher 会延迟 1 帧（玩家感觉"卡了一下"）。**Hard rule**: 超过 16.5ms = 必须优化（不接收推迟）。

### F2. State Stack Depth Limit

栈深度 = `state_stack.size()`

| 常量 | 值 | 理由 |
|------|------|------|
| `MAX_STACK_DEPTH` | 3 | PAUSE / CODEX / TERMINAL 都是 overlay，超过 3 层 = 玩家迷失"我在哪" |
| `MIN_STACK_DEPTH` | 1 | 至少有一个状态（栈底） |

**Edge case**: 试图 push 第 4 个状态 → 抛 `StackOverflowError` + 拒绝（不崩溃游戏）。允许的组合：`(EXPLORATION, PAUSE)`、`(EXPLORATION, CODEX)`、`(EXPLORATION, TERMINAL)`、`(BATTLE, MENU)`。**不允许**：`(EXPLORATION, CODEX, MENU)`——CODEX 打开时菜单不能叠加。

### F3. Input Routing (top-of-stack query)

InputBus 在 dispatch 一个 action 前查询：

```gdscript
var top: StringName = GameStateMachine.top_of_stack
match top:
    &"state_battle":     bus.dispatch_to(battle_subscribers, action)
    &"state_pause":      bus.dispatch_to(pause_subscribers, action)
    &"state_menu":       bus.dispatch_to(menu_subscribers, action)
    &"state_terminal":   bus.dispatch_to(terminal_subscribers, action)
    &"state_codex":      bus.dispatch_to(codex_subscribers, action)
    &"state_exploration": bus.dispatch_to(exploration_subscribers, action)
    &"state_title":      bus.dispatch_to(title_subscribers, action)
    _:                    bus.log_unhandled(action, top)
```

| 变量 | 类型 | 范围 | 描述 |
|------|------|------|------|
| `top` | StringName | 7 个有效值 | 栈顶状态的 StringName |
| `subscribers` | Array[Callable] | 0-N | 当前栈顶状态的所有 InputBus 订阅者 |

**Output Range**: O(1) 查询（Dict[StringName, Array] 索引）+ O(N) 派发（N = 当前栈顶的订阅者数，典型 ≤ 5）。**Edge case**: 0 订阅者 = `log_unhandled`，不报错。

### F4. Pause Recovery Cost

从 `PAUSE` 恢复时，需要"重放"被暂停期间积累的所有 input。

| 变量 | 类型 | 范围 | 描述 |
|------|------|------|------|
| `pause_duration_seconds` | float | 0–86400 (24h) | 玩家暂停多久 |
| `input_drops_during_pause` | int | 0–1000 | 暂停期间按下的键数（OS 缓存的） |

**Rule**: 暂停期间的所有 input **全部丢弃**，**不**回放。玩家从 PAUSE 弹出后，按的第一个键是"新的"——这一点已写进 #2 玩家输入 E5（focus loss 处理）作为一致约定。

**Output**: 0 keys replayed, 0 keys dropped silently（都是"丢弃"语义）。**Edge case**: 暂停 24h 后弹出 → 玩家需要重新按键 1 次以"重新进入"输入流。

## Edge Cases

按"使用频率 × 严重度"排序（高 → 低）：

| # | 条件 | 结果 | 原因 |
|---|------|------|------|
| 1 | **非法转换**：EXPLORATION → BATTLE → TERMINAL（直接 push TERMINAL 在 BATTLE 上） | `transition_to(TERMINAL)` 抛 `IllegalTransitionError`（per C-R3），`TERMINAL` 不 push，游戏停在 BATTLE | TERMINAL 是探索专属；战斗中无"终端"概念 |
| 2 | **栈溢出**：在 `(EXPLORATION, PAUSE)` 上 push CODEX = 3 层 OK；再 push MENU = 4 层 | 抛 `StackOverflowError`（per F2），第 4 个 push 拒绝，不修改栈 | 玩家迷失"我在哪"——3 层是上限 |
| 3 | **同状态 push**：玩家在 EXPLORATION 上 push(EXPLORATION) | `transition_to(EXPLORATION)` 抛 `SameStateError`（实际是 no-op 但明确报错方便调试） | 避免静默 no-op 掩盖 bug |
| 4 | **autoload 顺序错误**：GameStateMachine 在 InputBus 之后注册 | 启动时 `AutoloadOrderError` + 警告 + 游戏照常启动（不崩溃）但 InputBus 早 1 帧 dispatch | C-R6 硬约束，错误必须可观测但不阻塞开发 |
| 5 | **状态节点已 free 但仍在栈中**：内存压力下 `queue_free` 异步触发，转换期间旧节点已被回收 | `unsubscribe_from_input_bus` 收到 `null`，InputBus 静默忽略 | Godot Callable 弱引用约定，per #2 E9 |
| 6 | **转换与遇敌在同一帧**：EXPLORATION 移动到遇敌 tile + 玩家同时按 Pause | 遇敌的 `replace(BATTLE)` 先发生（在 Level 的 `_physics_process` 中），pause 转换在下一帧处理（InputBus dispatch 顺序：movement → pause，但遇敌触发早于 input） | 显式优先级：物理遇敌 > input；遇敌总是先于 input 触发 |
| 7 | **死亡时按 Pause**：玩家 HP=0 触发 `replace(TITLE)`，同时按 Pause | `replace(TITLE)` 先发生，pause 转换在 TITLE 上无效（TITLE 不允许 push PAUSE——TITLE 是栈底） | C-R3 合法转换表约束 |
| 8 | **读档时状态不连续**：save 写了 `(EXPLORATION, CODEX)` 但 CODEX 节点 ID 已变 | `load_snapshot` 时 CODEX 节点找不到 → 抛 `SnapshotRestoreError`，回退到 `replace(EXPLORATION)` 单层 | 存档兼容性 — 不让玩家被卡死 |
| 9 | **HUD 状态徽章在转换中途消失**：1 帧的间隙，旧 badge 已 free，新 badge 还没 add | 转换在单帧内完成（per C-R4 原子性），不存在"中途"——但渲染仍可能在不同帧 → 接受最多 1 帧的视觉抖动 | 极致优化需要 double-buffered badge，超出 MVP |
| 10 | **状态节点的 _process 在 paused 期间仍在跑**：动画节点用 `_process` 而非 `_physics_process` | 暂停时 `_process` 仍跑（除非手动检查 `get_tree().paused`） | Godot 默认 `_process` 在 paused 时**不**被冻结——状态机**不**自动 freeze，依赖**节点自己**检查 `get_tree().paused`。这在 E5 玩家输入 E5 中有引用 |
| 11 | **Modded 自定义状态**：玩家 mod 添加第 8 个状态 | `transition_to(&"state_modded_xxx")` 抛 `UnknownStateError` | C-R1 闭集约束 |

## Dependencies

### 上游依赖（Hard）

**无**——本系统是 Foundation 层地基之一，**不**依赖任何其他系统。

### 下游依赖（7+ 个系统）

| 系统 | 方向 | 性质 | 接口（伪代码） | 备注 |
|------|------|------|----------------|------|
| **玩家输入 #2** | 强依赖 | Hard | `GameStateMachine.top_of_stack` (read-only) | InputBus 路由订阅者；C-R6 autoload 顺序硬约束 |
| **HUD** | 强依赖 | Hard | `signal state_changed(old, new)` | 状态徽章更新 |
| **战斗核心 #7** | 强依赖 | Hard | `transition_to(BATTLE / EXPLORATION)` | 战斗进入 / 退出 |
| **关卡 / 迷宫 #15** | 强依赖 | Hard | `transition_to(BATTLE)` | 暗雷遇敌 |
| **菜单 / 暂停 #23** | 强依赖 | Hard | `push(MENU) / push(PAUSE) / pop()` | 菜单 / 暂停触发 |
| **存档 / 加载 #21** | 强依赖 | Hard | `get_state_snapshot() / load_snapshot(snap)` | 序列化 + 恢复状态堆栈 |
| **战斗场景切换 #6** | 强依赖 | Hard | `signal state_changed` | 加载 / 卸载 battle scene |
| **终端 / NPC 触发** | 强依赖 | Hard | `push(TERMINAL) / push(CODEX)` | 玩家靠近互动 |
| **聚焦事件** | 强依赖 | Hard | (内置) `NOTIFICATION_WM_WINDOW_FOCUS_*` | 自动 pause / unpause |

**总计 9 个下游系统**，全部 **Hard 依赖**（本系统是它们**唯一可信的"现在在哪"事实源**）。

### 关键双向约束（与玩家输入 #2 共享）

| 约束 | 在 #2 GDD 中的位置 | 在本 GDD 中的位置 |
|------|----------------------|-------------------|
| Autoload 顺序（GameStateMachine 先，InputBus 后） | #2 E9 | 本系统 **C-R6** |
| 状态订阅 API 契约（`subscribe_to_input_bus` / `unsubscribe_from_input_bus`） | #2 E9 | 本系统 **C-R4** |
| Pause 期间 input 全部丢弃 | #2 E5 | 本系统 **F4** |

**约定**：本 GDD 与 #2 GDD **必须保持一致**。任何对 autoload 顺序、订阅 API、Pause 语义的修改，**双向** GDD 都要更新（这是 design-docs.md 的硬规则）。

### 依赖方向图

```
                ┌─ 玩家输入 #2  ←──┐
                ├─ HUD           ←──┤
                ├─ 战斗核心 #7   ←──┤
                ├─ 关卡 #15      ←──┤
                ├─ 菜单 #23      ←──┤  (9 个下游系统)
                ├─ 存档 #21      ←──┤
                ├─ 战斗场景 #6   ←──┤
                ├─ 终端/NPC     ←──┤
游戏状态机 #3 ──┤               │
                └─ 聚焦事件     ←──┘
```

## Tuning Knobs

> 本节列**状态机**特有的可调值。其他"通用"常量（FPS、动画时长）属于游戏项目级配置，不在本 GDD。

| 参数 | 当前默认值 | 安全范围 | 调高 → | 调低 → | 为什么取这个数 |
|------|------------|----------|---------|---------|----------------|
| `MAX_STACK_DEPTH` | 3 | 2-4 | 玩家迷失"我在哪"；modal 复杂度爆炸 | 没法叠加 pause+codex | 3 是 PAUSE/CODEX/TERMINAL 都允许的最小值 |
| `MIN_STACK_DEPTH` | 1 | 1（不可调） | — | 0 = 没有状态，游戏无意义 | 至少 1 个活跃状态 |
| `TRANSITION_LATENCY_BUDGET_MS` | 16.5 | 8.3-33 | 帧率掉到 30 | 玩家感觉"瞬切" | 单帧 = 16.6ms @ 60 FPS |
| `STATE_CHANGE_LOG_VERBOSITY` | "WARN" | "OFF" / "ERROR" / "WARN" / "INFO" / "DEBUG" | 日志爆炸 | 调试时缺信息 | 默认 WARN 级别记录所有非法转换 |
| `PAUSE_RECOVERY_INPUT_DROPS` | true | true / false | — | 暂停时按键被回放（感觉"卡了一下"） | 丢弃更直觉——玩家不期待暂停期间按键被记住 |
| `FOCUS_LOSS_AUTO_PAUSE` | true | true / false | — | alt-tab 不自动暂停 | 行为可关但默认开（FPS 玩家偏好） |
| `ALLOW_MODDED_STATES` | false | true / false | 模组支持 / 调试灵活 | 闭集保护消失 | MVP 闭集，VS 阶段重评 |
| `HUD_BADGE_TRANSITION_FADE_MS` | 0 | 0-200 | 状态徽章淡入淡出（更柔和） | 瞬切（更锐利） | MVP 瞬切，0ms = 最锐利的反馈 |

### 跨系统杠杆

| 杠杆 | 影响范围 | 当前值 | 调高 → | 调低 → |
|------|----------|---------|---------|---------|
| `MAX_STACK_DEPTH` | 整体 modal 复杂度 | 3 | 模态叠加更灵活 / 但玩家迷失 | 模态更严 / 但 UX 限制多 |
| `FOCUS_LOSS_AUTO_PAUSE` | 玩家中途被打断的体验 | true | 玩家被打断时游戏不暂停 | 自动暂停友好 |
| `STATE_CHANGE_LOG_VERBOSITY` | 调试 / 玩家支持 | "WARN" | 性能日志开销 | 调试时缺关键事件 |

## Visual/Audio Requirements

> Foundation / Infrastructure 层，**没有自己的视觉 / 音频元素**——所有视觉 / 音频反馈由下游系统（主要是 HUD、Audio、玩家输入）承载。

| 事件 | 视觉反馈 | 音频反馈 | 承载者 |
|------|----------|----------|--------|
| 状态转换（任意 → 任意） | HUD 状态徽章更新 | `state_transition.wav`（per #2 GDD F2） | HUD + Audio |
| Push overlay（→ PAUSE / CODEX / TERMINAL） | 屏幕 50% 透明遮罩 + 0.15s 淡入 | `overlay_open.wav` | HUD |
| Pop overlay（PAUSE → EXPLORATION） | 屏幕遮罩 0.15s 淡出 | `overlay_close.wav` | HUD |
| 非法转换 | **无视觉反馈**（避免玩家知道"我刚做了非法事"） | 日志记录（无音频） | Logger |
| 栈溢出 | 红字 HUD 警告（debug build only） | `error_chime.wav`（debug only） | Debug overlay |

> 详见 `design/art/art-bible.md` 的"深空废墟中孤独的霓虹"调色板 + `design/gdd/player-input.md` 的 F2 音频时长。

## UI Requirements

> Foundation 层，**没有自己独立的 UI 屏幕**——所有 UI 由下游系统（HUD、Menu、Codex）承载。本系统**仅**为这些下游系统提供"我现在在什么状态"的数据。

| 信息 | 消费者 | 触发 | 频率 |
|------|--------|------|------|
| `top_of_stack: StringName` | HUD 状态徽章、玩家输入路由、战斗核心 | 任何 `transition_to` | 实时 |
| `state_stack: Array[StringName]`（完整栈） | 存档 / 加载 | save/load | 触发时 |
| `state_changed(old, new)` 信号 | HUD、战斗场景切换 | `transition_to` 后立即 | 每转换 1 次 |
| `get_state_snapshot() -> Dictionary` | 存档 | save | 触发时 |

**关键约定**：本系统**不**直接渲染任何 widget——只**提供数据**给 HUD 渲染。HUD 通过订阅 `state_changed` 信号 + 查询 `top_of_stack` 来决定显示什么。

## Acceptance Criteria

> 每条都是 Given-When-Then 格式。**Solo 模式**（`qa-lead` 未咨询），生产前人工 review。

### 基础状态操作

- **AC-1**：**GIVEN** 游戏处于 `EXPLORATION` **WHEN** 调用 `transition_to(BATTLE)` **THEN** 在 16.5ms 内完成，HUD 状态徽章更新为 `BATTLE`，InputBus 不再 dispatch 给 Exploration 订阅者，Battle 订阅者开始接收。验证：转换原子性 + 单帧。
- **AC-2**：**GIVEN** 游戏处于 `EXPLORATION` **WHEN** 调用 `push(PAUSE)` **THEN** 栈变为 `[EXPLORATION, PAUSE]`，HUD 徽章变 `PAUSED`，`get_tree().paused = true`，玩家按 Esc 后栈弹出回 `[EXPLORATION]`。验证：push/pop 语义。
- **AC-3**：**GIVEN** 游戏处于 `(EXPLORATION, CODEX)`（2 层）**WHEN** 调用 `push(MENU)` **THEN** 抛 `StackOverflowError`，栈保持 2 层不变。验证：F2 上限。

### 合法 / 非法转换

- **AC-4**：**GIVEN** 游戏处于 `EXPLORATION` **WHEN** 调用 `transition_to(TERMINAL)`（直接 replace，非 push） **THEN** 抛 `IllegalTransitionError`，游戏仍处于 `EXPLORATION`，日志记录 `WARN: Illegal transition EXPLORATION -> TERMINAL`。验证：C-R3 合法转换表。
- **AC-5**：**GIVEN** 游戏处于 `BATTLE` **WHEN** 调用 `push(PAUSE)` **THEN** 抛 `IllegalTransitionError`（BATTLE 自带暂停 via MENU），栈不变。验证：合法转换表禁止 BATTLE→PAUSE。
- **AC-6**：**GIVEN** 游戏处于 `EXPLORATION` **WHEN** 调用 `transition_to(EXPLORATION)` **THEN** 抛 `SameStateError`，栈不变。验证：避免 no-op 掩盖 bug。

### Autoload 顺序

- **AC-7**：**GIVEN** `Project > Autoload` 中 `InputBus` 排在 `GameStateMachine` 之前 **WHEN** 启动游戏 **THEN** 启动日志显示 `AutoloadOrderError: InputBus must be after GameStateMachine`，游戏仍启动但 console 每秒 warning 一次。验证：C-R6 硬约束 + 错误可观测。
- **AC-8**：**GIVEN** 正确 autoload 顺序 **WHEN** 玩家在 EXPLORATION 中按 Esc 然后按 E（触发终端） **THEN** Esc 推 PAUSE，E 推 TERMINAL——两次 input 都正确 dispatch 到对应栈顶的订阅者。验证：autoload 顺序正确时 input 路由正确。

### Pause 语义

- **AC-9**：**GIVEN** 玩家在 BATTLE 第 3 回合 **WHEN** 按 Q（pause_battle） **THEN** 栈变为 `[BATTLE, MENU]`，`get_tree().paused = true`，战斗动画冻结但 Battle 节点仍在树中（订阅保持）。再次按 Q 弹出 MENU，战斗从第 3 回合继续。验证：F4 暂停语义。
- **AC-10**：**GIVEN** 玩家暂停 5 秒 **WHEN** 弹出 pause **THEN** 暂停期间按的所有键全部丢弃，弹出后第一次按键是"新"输入。验证：F4 暂停期间 input 丢弃。

### 状态机自愈

- **AC-11**：**GIVEN** 游戏崩溃前栈为 `(EXPLORATION, CODEX)` **WHEN** 读档恢复 **THEN** 加载器调用 `load_snapshot(snap)`，如果 CODEX 节点 ID 找不到 → 抛 `SnapshotRestoreError` + 自动回退 `replace(EXPLORATION)` + 日志记录。玩家可继续游戏。验证：存档兼容性自愈。
- **AC-12**：**GIVEN** 玩家在 EXPLORATION 中 `queue_free` 被强制触发（极端内存压力） **WHEN** 旧 EXPLORATION 节点已被回收但还在栈中 **THEN** 下次 `transition_to` 时 InputBus 静默忽略 null Callable（per #2 E9 weak ref），不抛错。验证：弱引用安全。

### 转换时序

- **AC-13**：**GIVEN** `EXPLORATION → BATTLE` **WHEN** 测时序 **THEN** 总耗时 ≤ 16.5ms（per F1）。验证：帧预算合规。
- **AC-14**：**GIVEN** 玩家在 EXPLORATION 中移动到遇敌 tile **WHEN** 同一帧玩家按 Pause **THEN** 遇敌的 `replace(BATTLE)` 先发生，pause 转换在 BATTLE 上非法（per E7 死亡/遇敌同帧），最终栈为 `[BATTLE]` 不含 PAUSE。验证：遇敌优先级 > input。

### HUD 状态徽章（与 #2 玩家输入 UI-2b 协同）

- **AC-15**：**GIVEN** 玩家打开 Codex 5 秒 **WHEN** 查询 HUD 状态徽章的 `visible` 属性 **THEN** 始终为 `true`（per #2 UI-2 / UI-2b）。验证：状态徽章在 overlay 期间仍可见。

## Open Questions

| 问题 | Owner | 截止 | 决议 |
|------|-------|------|------|
| 状态转换是否需要 "transition_class" 概念（瞬切 / 淡入淡出 / 滑入）以支持章节切换等"剧情级"转换？ | game-designer + narrative-director | VS 阶段 | MVP 全部瞬切，VS 评估是否加 transition_class |
| 死亡流：`replace(TITLE)` 还是 `push(DEATH_OVERLAY)` + pop 回 EXPLORATION？ | game-designer | 战斗 GDD 阶段 | 当前定：`replace(TITLE)`，死亡 = 强制回标题（不"复活"以保持严肃） |
| 状态机的 `signal state_changed` 是否要 emit 整个新栈，还是只 emit `top_of_stack`？ | gameplay-programmer | 实现阶段 | 当前定：emit `(old_top, new_top)`，需要完整栈的监听者自己查询 `state_stack`（避免信号载荷过重） |
| Modding 钩子：是否暴露 `register_state(name, scene_path)` API 允许 mod 加状态？ | lead-programmer | VS 阶段 | 当前定：MVP 闭集（`ALLOW_MODDED_STATES=false`），VS 评估 |
| 网络/协作场景：双人 / 多人游戏时状态机是 per-player 还是全局？ | technical-director | 超出 MVP 范围 | 当前定：N/A（单玩家游戏，per game concept） |
