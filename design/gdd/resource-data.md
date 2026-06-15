# 资源 / 数据系统 (Resource / Data System)

> **Status**: Approved
> **Author**: user + game-designer + lead-programmer
> **Review Verdict**: APPROVED (post-revision 2026-06-12, lean re-review 2026-06-12, lean re-review #2 2026-06-12 post-8-GDDs confirmation)
> **Last Updated**: 2026-06-12 (lean re-review #2)
> **Implements Pillar**: Pillar 2 (发现 > 数值) + Pillar 3 (每次战斗都是 build 试验) + Pillar 4 (真相是收集的结果)

## Summary

Resource / Data 系统是 Railhunter 所有"可发现、可装备、可战斗、可阅读"事实的**单一数据来源**。它把武器、弹药、敌人、机甲部位、道具、状态效果、终端日志、剧情碎片、地区定义成 Godot 自定义 `Resource` 类型（`.tres` 文件），让所有下游系统（战斗、build、HUD、图鉴、存档、剧情、NPC）从同一个地方读取，禁止硬编码数值。

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None`（地基） · Depended on by: 战斗核心、武器弹药、敌人 AI、机甲升级、道具、关卡、门锁、图鉴、HUD、存档、NPC / 终端日志、剧情图谱、地区（**13 个系统** — 2026-06-12 修订新增 3 个 Pillar 4 依赖）

## Overview

资源 / 数据系统是 Railhunter 所有可发现、可装备、可战斗、可阅读事实的**单一权威数据源**。它用 Godot 4.6 的 `Resource` 子类机制把武器、弹药、敌人、机甲部位、道具、状态效果、终端日志、剧情碎片、地区定义为可序列化的 `.tres` 文件，让战斗、build、HUD、图鉴、存档、NPC、剧情图谱、关卡等 **13 个下游系统**从同一个地方读取，禁止硬编码数值。

玩家**永远不会直接接触**这个系统——他们看到的是"武器库里多了把激光枪""敌人图鉴亮了 1/12""这把武器能装电浆弹"。这些"被看见的回报"全部由本系统提供。

如果本系统不存在，**所有数值都会散落在代码里**：调一个敌人 HP 要去 5 个文件改 5 处，调一个弹药加成要重新编译，玩家的 build 试验将永远被困在"开发者的魔数"上。

## Player Fantasy

玩家**不会意识到**这个系统的存在——这是它成功的标志。

他们感受到的，是**"我解锁了一个新东西"**的清晰时刻：

- **在武器库页**，看到一把新武器静静躺在网格里，名称、伤害、特殊效果一目了然，旁白写着"退役研究员的实验品，第 2 章获得"
- **在敌人图鉴**，击败一个变种后看到它的弱点、掉落物、首次发现日期，以及一段简短的描述"卫星研究部的安保单位，退役后开始自行巡逻"
- **在战斗中**，按下 1/2/3 切武器时，HUD 上数字立刻跳到新武器的伤害——**反馈是"立即生效"**
- **在 build 试验中**，换一把武器 + 换一种弹药，看伤害从 20 跳到 65（基础激光 × 普通弹 → 导弹 × 电浆弹 = 50 × 1.3）——**玩家会觉得"我发现了这个组合"**
- **在终端日志墙**，捡起一卷 30 秒的录音，听见"我们已经切断了和外界的联系……"，然后看见剧情图谱多亮了一个节点

这背后的情感是 **Pillar 2 (发现 > 数值) + Pillar 4 (真相是收集的结果)**：玩家最满足的时刻来自"发现新东西"和"拼出真相"。本系统为这两个时刻提供"立即、清晰、有回报"的体验——所有数值、所有文本、所有剧情碎片都在同一个地方，加载是即时的，没有"调一个数字要重启游戏"的延迟。

参考游戏：**极乐迪斯科** 的思维内阁（disc 文本的丰富度）+ **Into the Breach**（数据 = 战斗反馈的清晰度）。**修正 2026-06-12 早期版本说法**：本系统对玩家**不是完全无形的**——战斗中每次伤害数字都是数据层的输出。准确的说法是**"玩家不需要理解数据系统"**——他们不读 GDD、不写 `.tres`、不看 Inspector，但他们**感受到的每一次发现**都来自这一层。

> `creative-director` 未咨询（Solo 模式）。生产前需人工审核。

## Detailed Design

### Core Rules

1. **类型即文件**：每种 Resource 子类对应一种 `.tres` 模板。武器 = `WeaponData.tres` 实例，弹药 = `AmmoData.tres` 实例，敌人 = `EnemyData.tres` 实例，依此类推。
2. **唯一权威源**：战斗中读敌人 HP 只走 `EnemyData.max_hp`，不许在战斗脚本里写 `enemy.hp = 30` 这种字面量。
3. **不可变 Resource**：所有 `.tres` 加载后不可在运行时修改。运行时变体（敌人当前 HP）由 `BattleState` 等运行时对象持有，**不和 Resource 混淆**。
4. **必填字段校验**：每个 Resource 子类在 `_init()` 末尾对关键字段做 `assert()`，完整清单见下方"Schema Invariants"小节。编辑器中 Inspector 红字提示。
5. **引用而非复制**：武器槽位持有的是 `WeaponData` 资源引用（`@export Resource`），不是深度复制。这保证"调一处，所有引用同步"。
6. **跨语言兼容**：所有 Resource 子类用 GDScript 写，C# 通过 `ResourceLoader.Load<Resource>()` 拿到基类引用，字段访问用 `weapon.Get("min_damage").AsInt32()` 字符串路径（**C# 不依赖具体 GDScript 类型**）。详见"跨语言访问"小节。
7. **图鉴 ID 唯一 + 强制前缀**：每个 Resource 都有 `id: StringName` 字段，作为图鉴 / 存档的稳定 key。不许用 `display_name` 当 ID（玩家改语言后存档就废了）。**强制前缀规则**（在 `_init()` 中断言）：
   - `WeaponData.id` 必须以 `wpn_` 开头
   - `AmmoData.id` 必须以 `ammo_` 开头
   - `EnemyData.id` 必须以 `enm_` 开头
   - `MechPartData.id` 必须以 `part_` 开头
   - `ItemData.id` 必须以 `itm_` 开头
   - `EffectData.id` 必须以 `eff_` 开头
   - `TerminalLogData.id` 必须以 `log_` 开头
   - `StoryFragmentData.id` 必须以 `frag_` 开头
   - `RegionData.id` 必须以 `reg_` 开头
   - 跨类型 ID 重复 = `DuplicateIDError`（加载时由 `ResourceRegistry` 检测）
8. **首次发现 = 触发信号**：运行时有一个 `Discovery.register(entity_id)` API，任何系统获得 Resource 引用后**必须**调用它，触发图鉴更新 + 剧情碎片点亮。`Discovery` 状态由 `MetaState` autoload 持有（见"Runtime State Location"小节）。
9. **Proto 字段保留**：所有 Resource 都有 `proto_notes: String` 字段，记录 prototype 阶段观察到的 tuning 注释。**这是开发者注释，不进 build**——VS 阶段再决定是否迁移到 `design/notes/` 工具链。Editor 中用 `@export_group("Developer Notes (not exposed to player)")` 视觉分组。

### Schema Invariants（加载时断言）

每个 Resource 子类在 `_init()` 中必须检查的不变量：

| 字段 | 不变量 | 错误类型 |
|------|--------|----------|
| 任意 `id: StringName` | 非空 + 前缀正确 | `InvalidIDError` / `InvalidPrefixError` |
| `WeaponData.min_damage` | 1 ≤ min ≤ 200 | `OutOfRangeError` |
| `WeaponData.max_damage` | min ≤ max ≤ 200 | `OutOfRangeError` |
| `WeaponData.accuracy` | 0.05 ≤ accuracy ≤ 1.0 | `OutOfRangeError` |
| `WeaponData.crit_chance` | 0.0 ≤ crit_chance ≤ 1.0 | `OutOfRangeError` |
| `WeaponData.crit_multiplier` | 1.0 ≤ crit_multiplier ≤ 3.0 | `OutOfRangeError` |
| `AmmoData.damage_mult` | 0.5 ≤ damage_mult ≤ 2.0 | `OutOfRangeError` |
| `AmmoData.stack_size` | 1 ≤ stack_size ≤ 999 | `OutOfRangeError` |
| `EnemyData.max_hp` | 10 ≤ max_hp ≤ 500 | `OutOfRangeError` |
| `EnemyData.attack` | 1 ≤ attack ≤ 100 | `OutOfRangeError` |
| `EnemyData.accuracy` | 0.05 ≤ accuracy ≤ 1.0 | `OutOfRangeError` |
| `MechPartData.max_hp` | 50 ≤ max_hp ≤ 500 | `OutOfRangeError` |
| `ItemData.stack_size` | 1 ≤ stack_size ≤ 999 | `OutOfRangeError` |
| `DropEntry.drop_rate` | 0.0 ≤ drop_rate ≤ 1.0 | `OutOfRangeError` |
| `DropEntry.qty` | 1 ≤ qty ≤ 99 | `OutOfRangeError` |
| `EffectData.duration_turns` | duration_turns ≥ 0 | `OutOfRangeError` |
| `EffectData.target_stat` (STAT_MOD) | 必须是非空 `StringName` 且在封闭枚举内 | `InvalidEffectError` |
| `MechPartData.upgrade_path` | 长度 ≤ 1（MVP），无自引用 | `InvalidUpgradePathError` |
| 任意 `Array[*]` | 无 null 元素（assert in _init） | `NullArrayElementError` |
| 任意 `EffectData?` (nullable) | null ≡ "无效果"（两种空状态等价） | (no error) |

### Resource 子类型与字段

#### WeaponData

```gdscript
class_name WeaponData extends Resource
@export var id: StringName                            # 必须以 "wpn_" 开头
@export var display_name: String
@export var icon: Texture2D
@export_range(1, 200) var min_damage: int = 20        # 生产上限 200 (Tight range, 2026-06-12 修订)
@export_range(1, 200) var max_damage: int = 20
@export_range(0.05, 1.0) var accuracy: float = 0.9
@export var default_ammo: AmmoData.Type               # 默认 / 推荐弹药 (原 ammo_slot, 2026-06-12 重命名)
@export var compatible_ammo_types: Array[AmmoData.Type] = []  # 空数组 = 全部类型可用
@export var range: WeaponData.Range                   # NEAR / MID / FAR
@export_range(0.0, 1.0) var crit_chance: float = 0.05
@export_range(1.0, 3.0) var crit_multiplier: float = 2.0
@export var special_effects: Array[EffectData] = []   # 空数组 = 无特殊效果
@export_multiline var flavor_text: String = ""       # codex 显示 (Player-facing)
@export_multiline var discovery_log: String = ""     # 首次发现时弹出的文本
@export_group("Developer Notes (not exposed to player)")
@export_multiline var proto_notes: String = ""
```

#### AmmoData

```gdscript
class_name AmmoData extends Resource
@export var id: StringName                            # 必须以 "ammo_" 开头
@export var display_name: String
@export_range(0.5, 2.0) var damage_mult: float = 1.0  # 生产上限 2.0 (Tight range, 2026-06-12 修订)
@export var effect: EffectData = null                 # null = 无附加效果
@export_range(1, 999) var stack_size: int = 99
@export_multiline var flavor_text: String = ""
@export_group("Developer Notes (not exposed to player)")
@export_multiline var proto_notes: String = ""
```

#### EnemyData

```gdscript
class_name EnemyData extends Resource
@export var id: StringName                            # 必须以 "enm_" 开头
@export var display_name: String
@export var sprite: Texture2D
@export var sprite_palette: String                   # 已知有效值见 art-bible.md
@export_range(10, 500) var max_hp: int = 40
@export_range(1, 100) var attack: int = 25
@export_range(0.05, 1.0) var accuracy: float = 0.85
@export var drops: Array[DropEntry] = []              # 空数组 = 无掉落
@export var weaknesses: Array[AmmoData.Type] = []     # 空数组 = 无弱点
@export var resistances: Array[AmmoData.Type] = []    # 空数组 = 无抗性
@export_multiline var flavor_text: String = ""
@export_multiline var discovery_log: String = ""
@export_group("Developer Notes (not exposed to player)")
@export_multiline var proto_notes: String = ""
```

#### MechPartData

```gdscript
class_name MechPartData extends Resource
@export var id: StringName                            # 必须以 "part_" 开头
@export var part_type: MechPartData.Type              # HEAD / CHEST / ARM / LEG
@export var display_name: String
@export var icon: Texture2D                           # 升级 UI 显示 (2026-06-12 补充)
@export_range(50, 500) var max_hp: int = 100
@export var upgrade_path: Array[MechPartData] = []    # MVP: 长度 ≤ 1, 线性链
@export_multiline var flavor_text: String = ""
@export_multiline var discovery_log: String = ""
@export_group("Developer Notes (not exposed to player)")
@export_multiline var proto_notes: String = ""
```

#### ItemData

```gdscript
class_name ItemData extends Resource
@export var id: StringName                            # 必须以 "itm_" 开头
@export var display_name: String
@export var category: ItemData.Category               # REPAIR / CONSUMABLE / KEY / QUEST
@export var icon: Texture2D
@export_range(1, 999) var stack_size: int = 99
@export var effect: EffectData = null                 # null = 无效果
@export var is_key_item: bool = false
@export_multiline var flavor_text: String = ""
@export_multiline var discovery_log: String = ""
@export_group("Developer Notes (not exposed to player)")
@export_multiline var proto_notes: String = ""
```

#### EffectData

```gdscript
class_name EffectData extends Resource
@export var id: StringName                            # 必须以 "eff_" 开头
@export var display_name: String
@export var type: EffectData.Type                     # DAMAGE_OVER_TIME / STAT_MOD / INSTANT
@export var target_stat: EffectData.Stat = NONE       # STAT_MOD 时必填 (2026-06-12 补充)
@export var damage_type: AmmoData.Type = NORMAL       # DAMAGE_OVER_TIME 时必填 (2026-06-12 补充)
@export var magnitude: float = 0.0
@export_range(0, 99) var duration_turns: int = 0      # 0 = 即时
@export var target: EffectData.Target                 # SELF / ENEMY / AREA
@export_group("Developer Notes (not exposed to player)")
@export_multiline var proto_notes: String = ""
```

**EffectData.Stat 封闭枚举**：`NONE` / `CRIT_CHANCE` / `ACCURACY` / `DAMAGE_MULT` / `DAMAGE_TAKEN` / `MOVE_SPEED` —— 战斗核心读取时若遇到未列出的 stat 名 = `InvalidEffectError`。

#### DropEntry（补充声明 — 之前未在类型目录中）

```gdscript
class_name DropEntry extends Resource
@export_range(0.0, 1.0) var drop_rate: float = 0.8
@export_range(1, 99) var qty: int = 1
@export var item: ItemData                            # 必填, null = InvalidDropError
```

#### TerminalLogData（新增 — Pillar 4 支撑）

```gdscript
class_name TerminalLogData extends Resource
@export var id: StringName                            # 必须以 "log_" 开头
@export var display_name: String                     # 简短标题 (例: "通讯中断记录 - 第 17 天")
@export var region_id: StringName                     # 引用 RegionData.id (定位)
@export var audio_clip: AudioStream                   # 玩家播放的录音
@export_range(1, 600) var duration_seconds: int = 30
@export var transcript: String                        # 文本版 (无障碍 + 存档)
@export var unlocks_fragments: Array[StoryFragmentData] = []  # 听完会点亮哪些剧情碎片
@export var prerequisite_logs: Array[TerminalLogData] = []    # 听这个 log 之前要听哪些
@export_multiline var flavor_text: String = ""
@export_group("Developer Notes (not exposed to player)")
@export_multiline var proto_notes: String = ""
```

**契约**：`audio_clip` 必填（nullable = 设计错误）；`prerequisite_logs` 用于"Pillar 4 真相拼图"的解锁顺序。

#### StoryFragmentData（新增 — Pillar 4 支撑）

```gdscript
class_name StoryFragmentData extends Resource
@export var id: StringName                            # 必须以 "frag_" 开头
@export var display_name: String                     # 碎片标题 (例: "反应堆真相")
@export var body_text: String                        # 剧情图谱上显示的文本 (1-2 段)
@export var unlock_sources: Array[StringName] = []   # 哪些 log/事件/敌人会触发此碎片
@export var chapter: int = 1                          # 所属章节
@export_multiline var flavor_text: String = ""
@export_group("Developer Notes (not exposed to player)")
@export_multiline var proto_notes: String = ""
```

**契约**：`body_text` 必填且 ≥ 50 字符（assert）；`unlock_sources` 引用其他 Resource 的 ID（运行时由 Discovery 服务验证）。

#### RegionData（新增 — 图鉴 / 探索支撑）

```gdscript
class_name RegionData extends Resource
@export var id: StringName                            # 必须以 "reg_" 开头
@export var display_name: String                     # 地区名 (例: "卫星表层 - 前哨基地")
@export var chapter: int = 1
@export var background: Texture2D                    # 图鉴页背景
@export var ambient_sound: AudioStream               # 进入地区时的氛围音
@export_multiline var flavor_text: String = ""       # 图鉴中地区描述
@export_multiline var discovery_log: String = ""     # 首次进入地区时弹出的文本
@export_group("Developer Notes (not exposed to player)")
@export_multiline var proto_notes: String = ""
```

**契约**：`background` 必填（null → placeholder texture + 启动时 warning log）。

### States and Transitions

本系统**没有运行时状态**——它只是数据。运行时状态由下游系统（`BattleState`、`SaveData`、`MetaState`）持有。但有两个"伪状态"是 Resource 的**外部属性**——它们**不**存在 Resource 上，存在 `MetaState` autoload 中。

**Runtime State Location**：

| 状态 | 存储位置 | 接口 | 持久化 |
|------|----------|------|--------|
| `discovered: Dictionary[StringName, bool]` | `MetaState` autoload（in-memory） | `MetaState.is_discovered(id)`, `MetaState.mark_discovered(id)` | 通过 `Save.serialize_meta()` 序列化到 `discovered_ids: PackedStringArray` |
| `unlocked: Dictionary[StringName, bool]` | `MetaState` autoload（in-memory） | `MetaState.is_unlocked(id)`, `MetaState.mark_unlocked(id)` | 通过 `Save.serialize_meta()` 序列化到 `unlocked_ids: PackedStringArray` |
| 当前 HP / 弹药数 / 武器槽 | `BattleState` / `InventoryState` | (per-system) | 通过 `Save.serialize_state()` |
| 战斗中临时状态效果 | `BattleState.active_effects` | (per-system) | 不持久化（战斗重置） |

**重要约定**：Resource 本身**绝不**持有 `discovered` 或 `unlocked` 字段（即使命名为 `var discovered: bool`）。这两个状态的所有权在 `MetaState`，不与 Resource 混淆（符合 Core Rule #3 不可变性）。下游系统**必须**通过 `MetaState.mark_*()` 修改状态，**不能**直接改 Resource。

| 属性 | 状态转换 | 触发 API | 监听方 |
|------|----------|----------|--------|
| `discovered` | UNDISCOVERED → DISCOVERED | 任何系统 `MetaState.mark_discovered(entity_id)` | Codex (更新 %)、HUD (弹出 "新发现！")、Story Map (点亮碎片) |
| `unlocked` | LOCKED → UNLOCKED | 战利品掉落 `Inventory.add_*`、商店购买 `Shop.buy()`、剧情给予 `Quest.grant()` | 武器库 / 道具栏 / 图鉴 (从灰色 → 彩色) |

### Interactions with Other Systems

| 下游系统 | 流向 | 接口（伪代码） |
|----------|------|----------------|
| **战斗核心** | Resource → Battle | `Battle.spawn_enemy(enemy_data: EnemyData) -> BattleEnemy` |
| **战斗核心** | Resource → Battle | `Battle.calc_damage(weapon: WeaponData, ammo: AmmoData, target: EnemyData) -> int` |
| **武器弹药** | Resource → Inventory | `Inventory.add_weapon(weapon: WeaponData) -> bool` |
| **武器弹药** | Resource → Combat | `Weapon.load_ammo(weapon: WeaponData, ammo: AmmoData)` |
| **敌人 AI** | Resource → AI | `EnemyAI.choose_action(self: EnemyData, battle: Battle) -> Action` |
| **机甲升级** | Resource → Mech | `Mech.install_part(slot: Slot, part: MechPartData)` |
| **道具** | Resource → Inventory | `Inventory.add_item(item: ItemData, qty: int)` |
| **图鉴** | Resource → Codex | `Codex.register_discovery(entity_id: StringName)` |
| **HUD** | Resource → Display | `HUD.show_weapon_stats(weapon: WeaponData)` |
| **存档** | Resource → Save | `Save.serialize(owned_ids: Array[StringName])` |
| **门锁** | Resource → Door | `Door.check_unlock(requirement: WeaponData or AmmoData or ItemData)` |
| **NPC / 终端日志** | Resource → Narrative | `TerminalLog.play(log: TerminalLogData)` / `StoryFragment.unlock(frag: StoryFragmentData)` |
| **剧情图谱** | Resource → Story Map | `StoryMapNode.reveal(fragment_id: StringName)` |
| **关卡 / 地区** | Resource → Level | `Level.load_region(region: RegionData)` / `Level.get_ambient_sound(region: RegionData)` |

**所有权约定**：
- 本系统**只拥有**"游戏世界的事实是什么"（武器有哪些、敌人 HP 多少）
- 下游系统**各自拥有**"事实现在处于什么状态"（玩家持有几把、敌人现在掉多少血）
- 任何下游系统**写入 Resource** = bug。所有写入必须经过运行时状态对象。

> **跨语言访问**（C# / GDScript）— 完整契约 (2026-06-12 补充):
>
> C# 不重定义 `WeaponData` / `EnemyData` 等类。C# 读取字段的统一模式：
>
> | GDScript 字段类型 | C# 访问模式 |
> |------------------|------------|
> | `int`, `float`, `bool`, `String`, `StringName` | `weapon.Get("min_damage").AsInt32()` / `.AsSingle()` / `.AsBool()` / `.AsString()` / `.AsStringName()` |
> | `Texture2D`, `AudioStream` | `weapon.Get("icon").As<Texture2D>()` |
> | `Array[EffectData]` (typed array) | `var arr = weapon.Get("special_effects").AsGodotArray(); foreach (var elem in arr) { var eff = elem.As<Resource>(); ... }` |
> | `Array[AmmoData.Type]` (typed enum array) | `var arr = weapon.Get("compatible_ammo_types").AsGodotArray(); foreach (var elem in arr) { var t = (AmmoData.Type)(int)elem; ... }` |
> | `Array[MechPartData]` | 同 `Array[EffectData]`，但 `As<Resource>()` 后强转 `MechPartData` (via `Resource.As<>()` 若已注册) |
> | `EffectData = null` (nullable) | `weapon.Get("default_effect")` → `Variant` of type `Nil` 表示 null；用 `.VariantType == Variant.Type.Nil` 检查 |
>
> **错误路径**：`ResourceLoader.Load<Resource>(path)` 在文件不存在时返回 `null`（Godot 4.6 行为）。C# 调用方**必须**在每次 `Load` 后做 null 检查，否则 `.Get("...")` 会抛 `NullReferenceException`。详细错误处理见 AC-9b。
>
> **未来扩展**：若 C# 必须重写 Resource 子类（例如为了 IDE 强类型），必须显式 `partial class : Resource` 跨语言继承并在 `docs/architecture/` 中创建 ADR 记录（与 GDScript 父类共存，字段类型必须一致）。当前**不**做此扩展。

> `specialist agents` 未咨询（Solo 模式）。生产前建议人工 review 字段完整性。

## Formulas

本系统**定义**了字段的有效输入空间（什么 `.tres` 是合法的）和**最低计算规则**（最小伤害、命中下限）。更复杂的战斗 / 伤害 / 敌人 AI / 机甲升级公式在它们各自的 GDD 中定义。

### damage_ceiling_analysis（**2026-06-12 新增** — 紧范围设计的依据）

紧范围设计的核心目标：**让"build 进度"在战斗中可观察**。`final_damage = weapon_damage × ammo_mult × crit_mult`，代入紧范围边界：

| 场景 | min_damage | ammo_mult | crit | final_damage |
|------|------------|-----------|------|--------------|
| **默认 build**（laser × normal） | 20 | 1.0 | ×1 | 20 |
| **优化 build**（missile × plasma） | 50 | 1.3 | ×1 | 65 |
| **最大 build**（missile × plasma + crit） | 50 | 1.3 | ×3.0 | 195 |
| **理论上限**（满值 × 满值 × 满值） | 200 | 2.0 | ×3.0 | **1200** |
| **理论下限**（最小值 × 最小值 × 最小值） | 1 | 0.5 | ×1.0 | 0.5 → **强制 1（最小伤害规则）** |

**BOSS HP 上限** = 500（普通敌人 30–50 / 精英 80–120 / BOSS 200+）。最大 build (195) 击杀 BOSS (500) = 3 击，**符合"3–5 回合击杀"** 节奏。**强制最小伤害规则**：任何成功命中至少造成 1 伤害（避免 `0.5 → int 0` 的退化）。

### weapon_damage_range

`WeaponData.min_damage .. max_damage` 之间的随机整数。

| 字段 | 类型 | **生产范围** | prototype 默认 | 生产预期 |
|------|------|--------------|----------------|----------|
| `min_damage` | int | **1–200** | 20（laser）/ 35（cannon）/ 50（missile） | 20–80 |
| `max_damage` | int | **1–200** | 同上（原型 min == max） | min–min × 1.2 |

**说明**：生产范围**收紧到 1–200**（原 1–999 太宽，与 500 HP BOSS 上限碰撞导致 1-shot kill）。原型阶段把 min==max 以简化平衡测试。生产应引入随机浮动（让玩家有"幸运一击"的爽点）。**注意：浮动超过 ×1.2 会破坏 build 可预测性**（玩家需要能预判伤害来设计战术）。

### ammo_damage_multiplier

| 字段 | 类型 | **生产范围** | prototype 默认 | 备注 |
|------|------|--------------|----------------|------|
| `damage_mult` | float | **0.5–2.0** | 1.0（normal）/ 1.3（plasma）/ 0.8（tracker） | 与 weapon_damage **相乘**，不替代 |

### enemy_hp

| 字段 | 类型 | **生产范围** | prototype 默认 | **生产推荐** | 备注 |
|------|------|--------------|----------------|--------------|------|
| `max_hp` | int | **10–500** | 200（**太硬，玩家反馈**） | **30–50（普通）**、80–120（精英）、200–500（BOSS） | 决定战斗长度 |

**原型经验教训（必须传达给战斗 GDD）**：
- 玩家反映"敌人有点难打"的根本原因是 `max_hp = 200` × 武器伤害 20–50 = 4–10 回合才能击杀 → **战斗拖太长**。
- 生产默认值：普通敌人 30–50 HP（2–3 回合击杀，默认 build）— 让玩家"打完有奖励"的爽点保留。
- BOSS 例外：HP 可达 200–500 但需要"分部位"或"召唤小怪"等机制来扩展战斗长度，避免单纯堆血量。

### enemy_attack

| 字段 | 类型 | **生产范围** | prototype 默认 | 备注 |
|------|------|--------------|----------------|------|
| `attack` | int | 1–100 | 25 | 玩家 HP 200 ÷ 25 = 8 击倒，可接受 |

### hit_chance

`weapon.accuracy` 决定命中的概率。`randf() <= accuracy` → 命中。

| 字段 | 类型 | **生产范围** | prototype 默认 | 备注 |
|------|------|--------------|----------------|------|
| `accuracy` | float | **0.05–1.0** | 0.9（laser）/ 0.7（cannon）/ 0.5（missile） | 武器越强越不准的权衡；下限 0.05 避免 0% 命中武器 |

### crit_chance

| 字段 | 类型 | **生产范围** | prototype 默认 | 备注 |
|------|------|--------------|----------------|------|
| `crit_chance` | float | 0.0–1.0 | 0.05 | 标准 RPG 5% |
| `crit_multiplier` | float | **1.0–3.0** | 2.0 | 暴击 = 伤害 × 2 |

### mech_part_hp

| 字段 | 类型 | **生产范围** | prototype 默认 | 备注 |
|------|------|--------------|----------------|------|
| `max_hp` | int | 50–500 | 100 | 4 部位各 100 → 总 400 ≈ 玩家能扛 16 次普通攻击 |

### drop_chance

`DropEntry.drop_rate` 决定掉落概率。每次敌人死亡 = 一次独立的 `randf() <= drop_rate`。

| 字段 | 类型 | **生产范围** | 备注 |
|------|------|--------------|------|
| `drop_rate` | float | 0.0–1.0 | 0.8 = 80% 掉，普通小怪默认 |
| `qty` | int | 1–99 | 单次掉落的数量 |
| `item` | ItemData ref | — | 引用，不可空 |

### minimum_damage_rule（**新增** — 战斗核心 GDD 必须实施）

**任何成功命中至少造成 1 伤害**。当 `weapon_damage × ammo_mult × crit_mult < 1.0` 时向下取整若为 0，则强制设为 1。理由：避免 "0-damage hit" 的退化状态破坏 Pillar 2 (发现 > 数值) — 玩家无法区分"几乎成功"与"完全失败"。

### 派生公式的输入（不是本系统定义，但本系统**提供输入**）

| 公式 | 在哪个 GDD 定义 | 本系统提供的输入 |
|------|------------------|------------------|
| `final_damage = weapon_damage × ammo_mult × crit_mult` | 战斗核心 / 伤害计算 | weapon_damage, ammo_mult, crit_chance, crit_multiplier |
| `effective_hp = enemy.hp - sum(damage_taken)` | 战斗核心 | enemy.max_hp |
| `can_unlock = (player.has(requirement) && not_already_unlocked)` | 门锁 | weapon / ammo / item 资源引用 |
| `discovery_complete = discovered_count / total_count` | 图鉴 | 全部 id 列表 |
| `ai_decision = argmax(strategy_score(weapon, ammo, enemy))` | 敌人 AI / 自动模式 | weapon / ammo / enemy 全字段 |

## Edge Cases

按"使用频率 × 严重度"排序（高 → 低）：

| # | 条件 | 结果 | 原因 |
|---|------|------|------|
| 1 | **资源缺失**：战斗触发时 `EnemyData.tres` 文件不存在 | `Battle.spawn_enemy()` 抛 `MissingResourceError` 并 fallback 到占位敌人（"未知机甲"，完整字段定义见 AC-11），战斗可继续但日志报警 | 不让一个缺失文件让游戏崩溃；占位敌人保证战斗不会卡死 |
| 2 | **必填字段为空** / **ID 缺少前缀**：`.tres` 没填 `id`、`display_name`，或 `id` 不带 `wpn_` / `enm_` 等前缀 | 加载时 `assert()` 失败（见 Schema Invariants 表），编辑器红字、运行时 `MetaState.mark_discovered()` 抛 `InvalidIDError` / `InvalidPrefixError` 并跳过 | 早失败、明确错误位置；ID 前缀防止跨类型 ID 撞车 |
| 3 | **数值越界**（参见 Schema Invariants 表的所有 18 条） | 加载时 `assert()` 抛 `OutOfRangeError`，列越界字段 + 实际值 + 允许范围 | 配置错误必须早发现；避免运行时的退化状态（0-damage hit、0% accuracy 武器） |
| 4 | **循环引用**：武器 A 引用武器 B，武器 B 引用武器 A | 加载时由 `ResourceRegistry` 检测环，抛 `CircularReferenceError`。MVP 唯一允许的循环来源是 `MechPartData.upgrade_path`，但被限制为长度 ≤ 1 + 无自引用 | Resource 引用图必须是 DAG（除 upgrade_path 线性链） |
| 5 | **ID 冲突**：两个 `.tres` 用了相同的 `id`（跨类型或同类型） | 加载时由 `ResourceRegistry` 抛 `DuplicateIDError`，列冲突的文件路径 | 存档 / 图鉴依赖 ID 唯一性；前缀规则让同类型冲突几乎不可能，跨类型仍可能 |
| 6 | **运行时修改尝试**：战斗脚本写入 `enemy_data.max_hp = 50` | 抛 `ImmutableResourceError`（runtime exception）；**linter warning 由 ADR-XXXX 的 GDScript script tool plugin 实现（待办）** | 强制所有权：运行时状态必须走 BattleState |
| 7 | **proto 字段含敏感信息**：`proto_notes` 写了"调试用：玩家无敌" | **不阻止**——这是开发者注释，不会暴露给玩家（`@export_group("Developer Notes (not exposed to player)")` 视觉分组） | proto_notes 是给开发者的，不参与游戏逻辑 |
| 8 | **drop_rate 全部为 0**（敌人不掉落） | 战斗胜利仍然显示"胜利" + 0 战利品。**图鉴发现** 仍触发（玩家遇到这个敌人就算"发现"） | 击败仍是奖励——发现 + 经验值（或未来加入） |
| 9 | **MechPartData 升级链不连通**：A 没有 `next_part` 引用 | 升级按钮变灰，hover 显示"无法升级"；不抛错 | 升级是可选玩法，缺失升级链 = 部位不能升级，不是 bug |
| 10 | **跨语言调用失败**：C# `Load<WeaponData>()` 拿到 `null`（文件不存在） | 调用方**必须**在每次 `Load` 后做 null 检查；`.Get("...")` 在 null 上会抛 `NullReferenceException` | 见 AC-9b 的强制 null 检查 AC |
| 11 | **堆叠上限达到后获得更多**：玩家持有 99 普通弹（`stack_size=99`），战斗再获得 5 个 | 玩家获得 0 个，**剩余 5 个进入"lost loot" 流程**（写到 `BattleState.lost_loot[item_id] += qty`），战斗结束 UI 显示"+5 修理包（丢失：背包已满）"。**不静默丢弃** | 玩家必须有反馈；不静默丢战利品 |
| 12 | **命中计算产生 0 伤害**：`weapon_damage × ammo_mult × crit_mult < 1.0` | **强制最小伤害规则**：向下取整若为 0，强制设为 1 | 见 `minimum_damage_rule`；避免 "0-damage hit" 退化状态 |
| 13 | **EffectData.target_stat 不在封闭枚举内**：designer 写了 `target_stat = "ARMOR_PIERCING"` | 加载时 `assert()` 抛 `InvalidEffectError`，战斗核心遇到未列出的 stat = 跳过此效果 + log warning | 防止 typo 导致静默失败 |
| 14 | **RegionData.background 为 null**：地区未指定图鉴背景图 | 启动时扫描所有 RegionData，发现 null → 加载 placeholder texture `res://ui/placeholder_region.png` + 写一行 warning log | 视觉降级，不崩溃 |

## Dependencies

### 上游依赖（Hard）

**无**——本系统是 Foundation 层地基，不依赖任何其他系统。

### 下游依赖（13 个系统）

| 系统 | 方向 | 性质 | 接口（伪代码） | 备注 |
|------|------|------|----------------|------|
| **战斗核心循环** | 强依赖 | Hard | `Battle.spawn_enemy(enemy_data)` / `Battle.calc_damage(weapon, ammo, target)` | 战斗无数据 = 无战斗 |
| **武器弹药** | 强依赖 | Hard | `Inventory.add_weapon(weapon)` / `Weapon.load_ammo(weapon, ammo)` | 武器 / 弹药资源定义 |
| **敌人 AI** | 强依赖 | Hard | `EnemyAI.choose_action(enemy_data, battle)` | AI 读取敌人属性 + 武器 / 弹药来选最优解 |
| **机甲升级** | 强依赖 | Hard | `Mech.install_part(slot, part_data)` | 部位升级链数据 |
| **道具** | 强依赖 | Hard | `Inventory.add_item(item, qty)` | 道具 / 消耗品定义 |
| **关卡 / 迷宫** | 弱依赖 | Soft | `Level.get_encounter_table(level_id)` / `Level.load_region(region: RegionData)` | 关卡定义"哪个地图区域触发哪个敌人组"——可选地直接引用 `EnemyData.tres` |
| **图鉴** | 强依赖 | Hard | `Codex.register_discovery(id)` | 图鉴 100% 进度 = 已发现 / 总数；RegionData 驱动"地区图鉴"分页 |
| **HUD** | 强依赖 | Hard | `HUD.show_weapon_stats(weapon)` | 武器 / 弹药 / 部位状态显示 |
| **存档 / 加载** | 强依赖 | Hard | `Save.serialize(owned_ids)` / `Save.serialize_meta()` | 存档只存 ID 引用，运行时 re-load `.tres`；MetaState (discovered/unlocked) 通过 `serialize_meta()` 持久化 |
| **门锁** | 强依赖 | Hard | `Door.check_unlock(requirement)` | 门锁 = 检查玩家是否持有特定资源 |
| **NPC / 终端日志** | 强依赖 | Hard | `TerminalLog.play(log: TerminalLogData)` | 终端日志是 Pillar 4 的核心载体；日志播放会触发 `StoryFragment.unlock()` |
| **剧情图谱** | 强依赖 | Hard | `StoryMapNode.reveal(fragment_id: StringName)` | 剧情图谱读取 `StoryFragmentData.body_text` 显示已解锁的真相 |
| **地区 (Level/Region data)** | 强依赖 | Hard | `Level.load_region(region: RegionData)` | 地区数据驱动关卡加载 + 氛围音 + 探索密度审计 |

**总计 13 个下游系统**，全部 **Hard 依赖**（除了关卡 / 迷宫的 Soft 依赖——关卡可以内嵌敌人 ID 字符串而不是直接引用 `.tres`，灵活度更高）。**新增 3 个依赖**（NPC / 终端日志、剧情图谱、地区）来自本次 Pillar 4 修订。

**依赖方向图**：

```
                    ┌─ 战斗核心 ←──┐
                    ├─ 武器弹药  ←──┤
                    ├─ 敌人 AI  ←──┤
                    ├─ 机甲升级  ←──┤
                    ├─ 道具      ←──┤
资源 / 数据系统 ────┤              │
                    ├─ 图鉴      ←──┤  (10 个下游系统)
                    ├─ HUD       ←──┤
                    ├─ 存档      ←──┤
                    ├─ 门锁      ←──┤
                    └─ 关卡 / 迷宫 (Soft)
```

**约定**：
- 本系统**单向向下游提供数据**，不反向调用下游方法
- 下游系统**单向读取资源**，不修改资源
- **运行时状态的所有权** = 下游系统各自持有，本系统不参与
- **依赖图变更** = 改本 GDD + 通知所有 10 个下游系统的 GDD（更新 `Cross-References` 表）

## Tuning Knobs

> 本节只列**平衡类**可调字段（伤害、HP、概率、堆叠）。开关类（`is_key_item`、`stackable`）不列——它们是定义字段，不是平衡字段。

### WeaponData（武器）

| 参数 | 当前 proto 默认 | **生产安全范围** | 调高 → | 调低 → | 为什么取这个数 |
|------|----------------|----------------|---------|---------|----------------|
| `min_damage` | 20（laser）/ 35（cannon）/ 50（missile） | **15–80** | 一击必杀 / 战斗过快 / 失去 build 深度 | 战斗拖长 / 玩家觉得"打不动" | Proto 三档差异 15–20，让 build 切换有明显手感 |
| `max_damage` | == min（无浮动） | **min–min × 1.2** | 不可预测，玩家设计战术难 | （不建议调低到 0） | Proto 简化，生产应改为 min–min × 1.1–1.2 引入"幸运一击" |
| `accuracy` | 0.9 / 0.7 / 0.5 | **0.4–1.0** | 命中无悬念，武器选择不再有意义 | 玩家觉得"老打不中" | "高伤低命中"是 RPG 经典权衡（"导弹"原型验证可用）；下限 0.05 避免 0% 命中 |
| `crit_chance` | 0.05 | **0.0–0.2** | 暴击主导输出，build 变成"堆暴击" | 暴击感觉不到 | 标准 RPG 5%；>15% 会破坏 build 多样性 |
| `crit_multiplier` | 2.0 | **1.5–3.0** | 暴击一击必杀 | 暴击等于没暴击 | ×2 是行业标准，玩家有明确预期 |

### AmmoData（弹药）

| 参数 | 当前 proto 默认 | **生产安全范围** | 调高 → | 调低 → | 为什么取这个数 |
|------|----------------|----------------|---------|---------|----------------|
| `damage_mult` | 1.0 / 1.3 / 0.8 | **0.5–2.0** | 一种弹药主导 build | 弹药切换没意义 | Proto 三档差距 0.3，玩家能"感觉到"换弹 ≠ 摆设 |
| `stack_size` | 99 | **10–999** | 弹药永远不缺 / 失去紧张感 | 玩家频繁缺弹药 / 累 | 99 是单格"够用但有上限"的心理锚点 |

### EnemyData（敌人）

| 参数 | 当前 proto 默认 | **生产推荐** | 调高 → | 调低 → | 为什么取这个数 |
|------|----------------|--------------|---------|---------|----------------|
| `max_hp` | 200（**太硬，玩家反馈**） | **30–50（普通）** / 80–120（精英） / 200–500（BOSS） | 战斗拖长 4–10 回合 | 一击必杀 / 失去挑战 | **Proto 教训**：200 玩家说"太硬"；30–50 给出 2–3 回合击杀的"胜利感" |
| `attack` | 25 | **10–50** | 玩家 4 击倒 | 玩家 20 击倒 / 无威胁 | 200 玩家 HP ÷ 25 = 8 击倒，可接受。BOSS 调到 40–50 让玩家"认真打" |
| `accuracy` | 0.85 | **0.5–1.0** | 玩家没法回避 | 玩家无威胁 | 0.85 = 85% 命中，留 15% 走位 / 防御空间 |
| `drop_rate` | 0.8（普通） | **0.0–1.0** | 玩家感觉"必掉" | 玩家觉得"刷不到" | 80% 是"几乎必掉但仍有悬念"的心理锚点 |

### MechPartData（机甲部位）

| 参数 | 当前 proto 默认 | **生产安全范围** | 调高 → | 调低 → | 为什么取这个数 |
|------|----------------|----------------|---------|---------|----------------|
| `max_hp` | 100 | **50–500** | 总 HP 400 玩家无敌 | 部位一击破坏 / 战斗过脆 | 4 部位各 100 = 总 400 = 16 次普通攻击，符合"能扛但会死" |
| `upgrade_path.length` | 1（默认） | **0–1（MVP）** | 升级链太长 / 失去 RPG 紧凑感 | 无升级 / 减少 build 深度 | MVP 默认 1 段升级（线性链）；tree semantics 推迟到 VS 阶段 |

### ItemData（道具）

| 参数 | 当前 proto 默认 | **生产安全范围** | 调高 → | 调低 → | 为什么取这个数 |
|------|----------------|----------------|---------|---------|----------------|
| `stack_size` | 99 | **1–999** | 背包永不爆 / 失去紧张感 | 频繁满背包 | 99 = 心理"够用上限" |
| `effect.magnitude` | （未定义） | 视道具定 | 道具过强 → 战斗无脑用药 | 道具太弱 → 玩家不用 | 平衡要等具体道具 GDD |

### 跨系统杠杆

| 杠杆 | 影响范围 | 当前值 | 调高 → | 调低 → |
|------|----------|---------|---------|---------|
| `WeaponData.accuracy 梯度` | 战斗策略深度 | laser 0.9 / cannon 0.7 / missile 0.5 | 武器选择无差异 | 武器选择无差异 |
| `AmmoData.damage_mult 梯度` | 弹药切换手感 | 1.0 / 1.3 / 0.8 | 弹药选择主导战斗 | 弹药切换无意义 |
| `EnemyData.max_hp 区间` | 战斗节奏 | 30–50（普通） | 战斗拖长 | 战斗过快 |
| `MechPartData.max_hp 总和 / 单体` | 生存 vs 部位感 | 100/部位 | 部位感消失 | 部位一击破坏 |

## Acceptance Criteria

> 每条都是 Given-When-Then 格式，所有 AC 均含确定性 seed / 输入 / 输出，QA 测试员**不读 GDD body**即可判断通过 / 失败。**2026-06-12 修订**：原 AC 集有 8 处可测性问题（类型不匹配、确定性缺失、统计区间过紧、AC 缺失），本次全部修正并新增 3 条 AC 覆盖关键不变式。

### 数据加载与完整性

- **AC-1（修订）**：**GIVEN** 一个合法 `EnemyData.tres`（id=`"enm_grunt_01"`, max_hp=40, attack=25, accuracy=0.85, drops=[]）**WHEN** 战斗系统调用 `Battle.spawn_enemy(enemy_data: EnemyData)` **THEN** 资源 0 警告 0 错误加载成功，战斗照常开始，且 `BattleEnemy.underlying_data is enemy_data`（引用相等，非深拷贝）。
- **AC-2（修订）**：**GIVEN** 一个 `.tres` 文件 `id` 字段为空（`StringName("")`） **WHEN** 编辑器打开该文件 **THEN** (a) Inspector 在 `id` 字段显示红色错误标记 [ADVISORY — 需编辑器截图证据]，AND (b) `ResourceLoader.load(path)` 抛 `InvalidIDError` 且错误信息含 `id` 字段名 [BLOCKING — 单元测试], AND (c) `Battle.start()` 检测到 enemy_data 加载失败时拒绝进入战斗状态 [BLOCKING — 集成测试]。
- **AC-2a（新增）**：**GIVEN** 一个 `WeaponData.tres` 的 `id = "laser_mk1"`（缺少 `wpn_` 前缀）**WHEN** `ResourceLoader.load(path)` 被调用 **THEN** 抛 `InvalidPrefixError` 且错误信息含期望前缀 `"wpn_"`。
- **AC-2b（新增）**：**GIVEN** 两个 `.tres` 文件 `res://data/weapons/wpn_laser_mk1.tres` 和 `res://data/unlockables/wpn_laser_mk1.tres` 都使用 `id = &'wpn_laser_mk1'` **WHEN** `ResourceRegistry.load_all()` 扫描两者 **THEN** 抛 `DuplicateIDError` 且错误信息含**两个**文件路径，AND 第二个文件从注册表拒绝，AND 第一个文件仍可通过其路径正常加载。

### 不可变性 / 所有权

- **AC-3（修订）**：**GIVEN** 一场战斗进入第 3 回合 **WHEN** 战斗脚本执行 `enemy_data.max_hp = 50`（任何 `@export` 字段写入）**THEN** runtime 抛 `ImmutableResourceError` 且该写入**不**生效，战斗继续基于原始 `EnemyData.tres` 的 `max_hp` 值。**linter 警告（设计时检查）** 由 ADR-XXXX 中的 GDScript script tool plugin 实现，**目前不在 CI 范围**——AC-3 仅测试 runtime 部分。
- **AC-4（修订）**：**GIVEN** 玩家拥有 3 把武器（A、B、C，引用相等保留）+ 当前装备 B **WHEN** 玩家切换到 A **THEN** (a) `active_weapon is A_data` 引用相等（不是深拷贝）, AND (b) `active_weapon.min_damage` 返回 A 的 `min_damage`（不是 B 的）。**HUD 渲染的视觉响应**由 HUD GDD 测试——本 AC 只测 Resource 层的引用语义。

### 公式与平衡

- **AC-5（修订）**：**GIVEN** 一把粒子炮 `WeaponData(min_damage=35, max_damage=35, accuracy=0.7, crit_chance=0.0)` + 电浆弹 `AmmoData(damage_mult=1.3)` + 敌人 `EnemyData(max_hp=40, resistances=[])`，RNG seed = `0xDEADBEEF`，第一次 `randf()` 返回 `0.5`（命中），第二次返回 `0.5`（未暴击，因 `crit_chance=0.0`）**WHEN** 玩家攻击 1 次 **THEN** `final_damage = int(35 × 1.3 × 1.0) = 45`，敌人 HP 变成 `max(0, 40-45) = 0`，战斗胜利。
- **AC-5a（新增 — 验证最小伤害规则）**：**GIVEN** 武器 `min_damage=1, max_damage=1, crit_chance=0.0` + 弹药 `damage_mult=0.5`（floor 边界）**WHEN** 攻击命中 **THEN** `final_damage = max(1, int(1 × 0.5 × 1.0)) = 1`（强制最小伤害规则生效，避免 0 伤害）。
- **AC-5b（新增 — 验证 build 跳跃）**：**GIVEN** 玩家用 laser (20) × normal (1.0) 攻击 40 HP 敌人，切换到 missile (50) × plasma (1.3) 攻击同敌人（重置 HP=40）**WHEN** 两次攻击后 **THEN** 第一次伤害 = 20, 第二次伤害 = 65, 第二次击杀。验证 "20 → 65" 的 build 跳跃 = 3.25×。
- **AC-6（修订 — 标记为 INTEGRATION）**：**GIVEN** 一个普通敌人 `max_hp = 30`, `attack = 25`, `accuracy = 0.85`, 玩家 `max_hp = 200`, `accuracy = 1.0`, player always defends **WHEN** 战斗模拟器运行 8 个敌人回合（每次敌人攻击，player 防御，伤害 = max(1, 25 - defense_reduction)）**THEN** 玩家 HP 减少总和 = 8 × 伤害。**[INTEGRATION 测试]** 路由到 `tests/integration/combat_loop/enemy_kill_time_test.gd`。**Resource GDD 不拥有"player always defends"或"defense_reduction"** —— 这些是 Battle Core 的契约。

### 战利品

- **AC-7（修订 — 统计区间修正）**：**GIVEN** 一个普通敌人 `drop_rate = 0.8`, 掉落物 `item = repair_kit, qty = 1`，RNG = `RandomNumberGenerator` 实例（per-trial seed = 0xDEADBEEF + trial_index），**WHEN** 10000 个独立 trial `rng.randf() <= 0.8` **THEN** 观察到的命中数在 [7800, 8200] 之间（95% CI for binomial(10000, 0.8), half-width ≈ 0.98%）。**N=1000 不再使用**：原 ±2% 在 N=1000 下置信区间是 ±2.48%，会假阳 5% 的时间。
- **AC-7a（新增 — 边界）**：**GIVEN** `drop_rate = 0.0`, 1000 trials **THEN** 命中数 = 0。**GIVEN** `drop_rate = 1.0`, 1000 trials **THEN** 命中数 = 1000。
- **AC-7b（新增 — qty 语义）**：**GIVEN** `drop_rate = 0.5, qty = 99`, 1000 trials **THEN** 总掉落数量在 [48500, 51500]（验证 `qty` 是 multiplier，不被 cap）。
- **AC-8（修订 — 丢弃流定义）**：**GIVEN** 玩家持有 99 普通弹（`AmmoData.stack_size = 99`，cap = per-ammo-type），**WHEN** 战斗胜利获得 5 个普通弹 **THEN** (a) 玩家 `Inventory.normal_ammo` 仍 = 99, AND (b) `BattleState.lost_loot[&"ammo_normal"]` 增 += 5, AND (c) 战斗结束 UI 显示 "+5 普通弹（丢失：背包已满）"。**不静默丢弃**。

### 跨语言与图鉴

- **AC-9（修订 — 拆分）**：
  - **AC-9a**：**GIVEN** `res://data/weapons/wpn_laser_mk1.tres` 存在且 `min_damage = 20` **WHEN** C# 调用 `var weapon = ResourceLoader.Load<Resource>(path)` 然后 `weapon.Get("min_damage").AsInt32()` **THEN** 返回 20，且 `weapon.Get("display_name").AsString()` 返回 "激光枪 Mk1"。
  - **AC-9b**：**GIVEN** 路径 `res://data/weapons/missing.tres` 不存在 **WHEN** C# 调用 `ResourceLoader.Load<Resource>(path)` **THEN** 返回 `null`，AND 调用方 `if (weapon == null) { /* handle */ }` 必须存在否则运行时会抛 `NullReferenceException`（测试：`Load` 后不检查 null 触发 NPE）。
  - **AC-9c**：**GIVEN** `WeaponData` 加载后含 `special_effects: Array[EffectData] = [eff_burn]` **WHEN** C# 读取 `var arr = weapon.Get("special_effects").AsGodotArray(); foreach (var v in arr) { var eff = v.As<Resource>(); /* 访问 eff 字段 */ }` **THEN** `arr.Count == 1` 且 `eff.AsStringName() == &'eff_burn'`。
- **AC-10（修订 — 限定 Resource 边界）**：**GIVEN** 玩家从未遇到 `enm_grunt_01`（`MetaState.is_discovered(&'enm_grunt_01') == false`）**WHEN** 任意下游系统调用 `MetaState.mark_discovered(&'enm_grunt_01')` **THEN** (a) `MetaState.is_discovered(&'enm_grunt_01') == true`, AND (b) `entity_discovered` 信号被 emit 一次，payload = `{id: &'enm_grunt_01'}`, AND (c) `MetaState.serialize()` 的 `discovered_ids` 包含 `'enm_grunt_01'`。**Codex UI 的 "12/13 → 13/13" 跳变和 "新发现！" popup 由 Codex GDD 测试**——本 AC 只测 `MetaState` 行为。

### 错误处理

- **AC-11（修订 — fallback 完整化）**：**GIVEN** 路径 `res://data/enemies/enemmy_01.tres` 不存在（注意拼写错误）**WHEN** `Battle.spawn_enemy(load('res://data/enemies/enemmy_01.tres'))` 被调用 **THEN** 返回的 `BattleEnemy` 包装一个 fallback `EnemyData`，完整字段：
  - `id == &'enm_unknown'`
  - `display_name == "未知机甲"`
  - `max_hp == 30`, `attack == 20`, `accuracy == 0.85`
  - `drops == []`, `weaknesses == []`, `resistances == []`
  - `sprite == null`（renderer 用 placeholder texture）
  - `flavor_text == "数据损坏的未知敌人"`
  AND 系统 log 一行 `MissingResourceError: enemmy_01.tres`，AND 战斗用 fallback enemy 继续 3 个回合不抛 unhandled exception。

### 视觉资源（新增 — 2026-06-12）

- **AC-12（新增 — 视觉资源非空）**：**GIVEN** 启动时扫描 `res://data/weapons/*.tres` 和 `res://data/enemies/*.tres` **WHEN** 加载完成 **THEN** (a) 所有 `WeaponData.icon != null` AND 所有 `EnemyData.sprite != null`，否则 log warning (含 weapon/enemy 的 `id`)，AND (b) 武器库 / 战斗渲染遇到 null icon/sprite 时使用 `res://ui/placeholder_icon.png` 或 `res://ui/placeholder_enemy.png`，不显示空白方块。
- **AC-13（新增 — 文本字段长度）**：**GIVEN** 所有 `StoryFragmentData.body_text` 和 `TerminalLogData.transcript` **WHEN** 加载 **THEN** 每个 `body_text` ≥ 50 字符 AND 每个 `transcript` ≥ 20 字符（assert in `_init()`），否则 `InvalidContentError`。
- **AC-14（新增 — save/load round-trip — release blocker）**：**GIVEN** 一个 save 文件包含 `owned_weapon_ids = ['wpn_laser_mk1', 'wpn_plasma_rifle']` AND 两个对应 `.tres` 文件存在 **WHEN** `Save.load(path)` 被调用 **THEN** (a) `PlayerState.weapons` 含 2 个 `WeaponData` 引用, AND (b) `weapons[0].id == &'wpn_laser_mk1'` AND `weapons[0].min_damage == 20`, AND (c) `weapons[1].id == &'wpn_plasma_rifle'` AND `weapons[1].min_damage == 50`。**变体 AC-14b**：save 含 `id = 'wpn_removed'` 但 `.tres` 已删除 **WHEN** `Save.load(path)` **THEN** 抛 `MissingResourceError` 含 ID, AND load 中止（不部分状态），AND 旧 save 不被覆盖。

### 引擎版本

- **AC-15（新增 — 引擎版本 pin）**：**GIVEN** 项目构建于 Godot 4.6.x **WHEN** 游戏启动 **THEN** 启动 log 含 `engine_version: 4.6.x`，AND CI 在检测到 4.6 之前的版本时 warn（不 fail，因为可能有合理理由）。**Resource immutability guard `_set()` 依赖 4.6 行为**——若未来 Godot 升级到 4.7+ 且 `_set()` 语义变化，本 AC 必须在升级前重新验证。

> **Visual / Audio / UI 备注**：本系统是 Foundation / Infrastructure 层，**没有**自己的视觉 / 音频 / UI 元素。
> 视觉（武器 sprite / 敌人 sprite / 道具 icon）由具体的 `.tres` 实例决定，**遵循** `design/art/art-bible.md` 的"深空废墟中孤独的霓虹"原则。
> UI 元素（武器库页、图鉴页、HUD）由**下游 GDD**（HUD / Menu / Codex）承载。
> 本 GDD 不重复定义，遵循"地基不持有视觉 / UI"的架构原则。

## Open Questions

> 2026-06-12 修订：以下问题中 3 条已在本次 review 中解决（标 ✅ 关闭），3 条新增（来自 review 反馈），剩余 2 条保留到下一个决策点。

| 问题 | Owner | 截止 | 状态 | 决议 |
|------|-------|------|------|------|
| ~~`id` 字段是否需要 `namespace` 前缀？~~ | lead-programmer | 第一次 30+ 资源时 | ✅ **关闭** | **强制前缀**（已在 Core Rule #7 实施）。每个 Resource 子类有专属前缀；`@export` 字段不变，但 `_init()` 断言前缀。 |
| ~~是否引入三维 build 矩阵？~~ | game-designer | VS 阶段 | ✅ **关闭（MVP）** | MVP 用二维（weapon × ammo），三维推迟到 VS 阶段评估 |
| ~~`proto_notes` 是开发者注释还是 build 工具读取？~~ | lead-programmer | 第一次 `data/*.tres` 创建前 | ✅ **关闭** | **开发者注释，不进 build**。`@export_group("Developer Notes (not exposed to player)")` 视觉分组。VS 阶段再评估是否迁移到 `design/notes/` 工具链。 |
| **（新增）Resource immutability linter ADR 范围** | lead-programmer + godot-specialist | 第一次 5+ Resource 子类时 | 🟡 **待定** | GDScript script tool plugin 实现 `enemy_data.max_hp = 50` 的设计时警告。**不在本 GDD 范围**——创建 ADR-XXXX 跟踪。 |
| **（新增）Pillar 4 内容创作范围** | narrative-director + game-designer | NPC/Terminal GDD 编写时 | 🟡 **待定** | 本 GDD 提供 `TerminalLogData` / `StoryFragmentData` / `RegionData` schema，**不**定义具体剧情内容。M1 章节需 5-10 段 log + 2-3 个真相碎片（待 NPC GDD 决定）。 |
| **（新增）DefenseData / 伤害路由在 Resource 层还是 Damage Calc 层？** | lead-programmer + systems-designer | Damage Calc GDD 编写时 | 🟡 **待定** | 当前定：**Resource 层不持有防御字段**（避免数据层泄漏战斗逻辑），DefenseData 推迟到 Damage Calc GDD。本 GDD 的 `EnemyData` / `MechPartData` 提供输入变量（`max_hp` / `attack`），路由规则在 Damage Calc 中定义。 |
| 敌人图鉴的"弱点 / 抗性"是否要随玩家发现进度逐步揭示？| game-designer + ux-designer | Codex GDD 时 | 🟡 待定 | 当前倾向：默认完全显示（玩家有工具感），不在发现进度里 reveal |
| C# 是否需要重写 Resource 子类以获得更强类型？| lead-programmer + godot-csharp-specialist | 第一次 C# 调用 Resource 时 | 🟡 待定 | 当前定：C# 用 `Resource` 基类 + 字符串字段访问，**不**重写类。VS 阶段重评。 |
| **AC-2 Inspector 红字证据** [ADVISORY]：AC-2(a) 标记为 [ADVISORY — 需编辑器截图证据]。第一次创建 WeaponData.tres 时，需截图空 id Inspector 错误标记，存到 `production/qa/evidence/resource-data-ac2-screenshot.png` | qa-tester | 第一次 WeaponData.tres 创作时 | **待补证据**（lean re-review #2 Rec #1, 2026-06-12） |
| **AC-15 引擎升级 4.7+ 重新验证**：AC-15 提到"若未来 Godot 升级到 4.7+ 且 `_set()` 语义变化，本 AC 必须在升级前重新验证"。需在 ADR / 升级流程加规则：任何 engine upgrade PR 必须 run `/architecture-review` 重新验证 #1 Resource immutability guards | devops-engineer + lead-programmer | 第一次 4.7+ 升级 PR 时 | **待补流程规则**（lean re-review #2 Rec #2, 2026-06-12） |
