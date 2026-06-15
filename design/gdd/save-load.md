# 存档 / 加载 (Save / Load)

> **Status**: Approved
> **Author**: user + gameplay-programmer + lead-programmer
> **Review Verdict**: APPROVED (first review 2026-06-12, lean)
> **Last Updated**: 2026-06-12 (first review)
> **Implements Pillar**: Pillar 1（探索密度）—— 玩家不会因为失败丢失探索进度；Pillar 4（真相是收集的结果）—— 真相碎片永久保存

## Summary

存档 / 加载是 Railhunter **所有玩家进度**的持久化层。它定义 save data schema（位置 / 武器 / 弹药 / 状态栈 / 真相碎片 / 章节完成度）、autosave 触发器、save 损坏自愈、版本兼容性、读档时和 #3 状态机的契约。

> **Quick reference** — Layer: `Presentation` · Priority: `MVP` · Key deps: `#3 状态机`（state_stack snapshot）+ 全部 Feature 系统（inventory / story / encounter_count / etc.）· Depended on by: HUD（autosave 提示）、菜单 / 暂停 #23（VS 阶段菜单的 save/load 选项）

## Overview

存档 / 加载是 Railhunter **所有玩家进度**的持久化层。它定义：

- **Save data schema**（v1.0）：位置、武器槽、弹药库存、当前弹药、机甲 4 部位 HP、状态栈、真相碎片、章节完成度、遇敌计数、HUD 设置
- **Autosave 触发器**：进入新章节、进入新房间、战斗胜利
- **手动存档**：F5 快捷键 + 菜单（VS 阶段）
- **读档流程**：load_snapshot() + 校验 + 损坏自愈
- **版本兼容**：save_version 字段 + Resource 引用升级路径

本系统**整合**了**几乎所有其他系统**——它序列化所有 Feature 层的运行时状态：

- #3 状态机 → state_stack
- #11+#12 武器弹药 → weapon_slots + ammo_inventory + current_ammo
- #7 战斗核心 → battle_state（如在战斗中保存）
- #15 关卡 → current_room_id + player_pos
- #16 暗雷 → encounter_count
- #18 NPC/终端 → unlocked_fragments + read_logs
- #13 机甲 → parts[].current_hp
- #4 相机 → 相机状态
- HUD → settings (字体大小等)

玩家**直接接触**（autosave 提示、读档界面）但**不直接控制**（MVP 没有 save 文件管理 UI）——per #21 OQ-1。

如果本系统不存在，**所有进度都是 volatile**——重启 / 崩溃 / 切换 = 一切归零。

**在 5 层 Presentation 中**：本系统是**第二个** Presentation 系统（HUD 之后）。MVP 单 autosave slot + 3 个 manual slots（per #21 OQ-1）。

## Player Fantasy

玩家**间接接触**这个系统——他们"知道"它在工作（autosave 提示）但**不**需要操心。

他们感受到的，是 **"我永远不会丢失进度"** 的安全感：

- **进入新章节**：右上角短暂显示"已自动保存"提示 + autosave 音（per art-bible）
- **进入新房间**：同上
- **战斗胜利**：同上
- **重启游戏**：玩家看到最近一次 save 的画面（章节、房间、状态）——无缝继续
- **崩溃 / 断电**：下次启动 = 加载最近 autosave（不丢超过 1 章节的进度）
- **手动存档**（MVP 限定 F5）：玩家按 F5 触发 manual save + 看到"已保存到 [slot X]" 提示
- **读档**（MVP 通过 TITLE 屏幕 → 加载 last autosave）：玩家从 TITLE 选"继续游戏" = 加载最近 autosave

这背后的情感是 **Pillar 4（真相是收集的结果）**——真相碎片永久保存，玩家**不会**因为重启丢失 3 小时的剧情进度；**Pillar 1（探索密度）**——章节完成度永久保存，激励"回头探索"。

参考游戏：
- **Outer Wilds** —— 自动保存 15 分钟（per #21 F1 我们的 10 分钟）
- **极乐迪斯科** —— 手动 save 多 slots
- **Into the Breach** —— 循环 save（每回合）

> `creative-director` 未咨询（Solo 模式）。

## Detailed Design

### Core Rules

本系统有 **7 条 invariant**。

**C-R1 — 单 autosave slot + 多 manual slots**。MVP 1 autosave slot（自动覆盖）+ 3 manual slots（F5 → 选择 slot 0/1/2）。**禁止**无限 slots（增加 UX 复杂度）。

**C-R2 — Save data = 完整运行时状态快照**。SaveManager 调所有系统 `get_state_snapshot() -> Dictionary`，合并到 root save object。**禁止**只保存部分状态（破坏"恢复完整"原则）。

**C-R3 — Autosave 在 safe points 触发**。Safe points = 进入新章节 / 进入新房间 / 战斗胜利。**禁止**战斗中保存（per game concept "auto-save at safe points only"）。

**C-R4 — Save 文件格式 = JSON（user://save_N.json）**。**不**用 binary（debug 友好）。**不**用加密（MVP 不需要防作弊）。版本字段 = `save_version: int`（per OQ-1，未来兼容）。

**C-R5 — Load 时校验 + 自愈**。Load 流程：读 JSON → 校验 schema → 如果 `save_version` 不匹配 → 升级路径（per OQ-1）；如果某个字段缺失或类型错 → 用默认值填充（**不** crash）；如果文件不存在 → silent no-op（玩家从 TITLE 开始新游戏）。

**C-R6 — Save 不阻塞主循环**。SaveManager 在 `_process` 中**异步**写盘（用 `FileAccess.open()` + `flush()`，**不** await）。写入完成前玩家可继续游戏。**禁止**同步写盘卡顿。

**C-R7 — Save 失败不丢数据**。如果 FileAccess 写入失败（磁盘满 / 权限错） → `SaveError` 信号 + HUD 提示"保存失败" + 当前内存状态保留。**禁止**默默吞错。

### Save Data Schema (v1.0)

```json
{
  "save_version": 1,
  "saved_at_unix": 1700000000,
  "chapter_id": "chapter_1",
  "room_id": "C-1-room-5",
  "player_pos": {"x": 5, "y": 5},
  "state_stack": ["EXPLORATION"],
  "mech": {
    "parts": {
      "HEAD": {"current_hp": 100, "max_hp": 100},
      "CHEST": {"current_hp": 100, "max_hp": 100},
      "ARMS": {"current_hp": 100, "max_hp": 100},
      "LEGS": {"current_hp": 100, "max_hp": 100}
    }
  },
  "weapon_slots": [
    {"id": "wpn_laser_mk1", "level": 1},
    {"id": "wpn_cannon_mk1", "level": 1},
    null
  ],
  "ammo_inventory": {
    "ammo_normal": 50,
    "ammo_plasma": 30,
    "ammo_tracker": 20
  },
  "current_ammo": "ammo_plasma",
  "encounter_count_chapter_1": 12,
  "unlocked_fragments": ["frag_1", "frag_2", "frag_3"],
  "read_logs": ["log_1", "log_2"],
  "hud_settings": {
    "font_size": "medium",
    "show_damage_numbers": true
  }
}
```

### States and Transitions

**4 个 Save 状态**：

| 状态 | 用途 | 转换触发 |
|------|------|----------|
| `IDLE` | 无 save / load 操作 | 默认 |
| `SAVING` | 写盘中（async） | autosave / manual save 触发 |
| `LOADING` | 读盘中 | TITLE → "继续游戏" / F9 |
| `ERROR` | 写盘失败 | FileAccess 错误 |

### Interactions with Other Systems

| 系统 | 接口 | 备注 |
|------|------|------|
| **状态机 #3** | `get_state_snapshot() / load_snapshot(snap)` | state_stack |
| **战斗核心 #7** | `get_battle_state_snapshot() / restore_battle_state(snap)` | battle 期间不存 |
| **武器弹药 #11+#12** | `get_inventory_snapshot() / restore_inventory(snap)` | weapon_slots + ammo |
| **关卡 #15** | `get_room_snapshot() / restore_room(snap)` | room_id + pos |
| **暗雷 #16** | `get_encounter_count() / restore_count(snap)` | encounter_count |
| **NPC/终端 #18** | `get_fragments_snapshot() / restore_fragments(snap)` | unlocked_fragments + read_logs |
| **机甲 #13** | `get_mech_snapshot() / restore_mech(snap)` | parts HP |
| **HUD** | `get_hud_settings() / restore_hud_settings(snap)` | 字体 + 显示设置 |
| **玩家输入 #2** | (无) | 输入设置不存（硬编码 MVP） |
| **相机 #4** | (MVP 不存) | 相机状态可重新计算 |

## Formulas

### F1. Autosave Frequency

`autosave_triggers = ["enter_new_chapter", "enter_new_room", "battle_victory"]`

| 触发 | 频率 | 玩家失去的最大进度 |
|------|------|---------------------|
| 进入新章节 | 每章节 1 次 | 1 章节 |
| 进入新房间 | 每房间 1 次 | 1 房间 (章节内) |
| 战斗胜利 | 每场战斗 1 次 | 1 场战斗 |

**Output Range**: 章节 1 = ~30 次 autosave（10 房间 + ~25 战斗胜利 + 章节 1 完成）。**Edge case**: 玩家在房间内反复遇敌 + 战斗胜利 = 频繁 autosave（可接受，性能 OK，per C-R6 async）。

### F2. Save File Size Estimate

`save_size_bytes = sum of all snapshot fields`

| 字段 | 字节 |
|------|------|
| state_stack (1-3 states) | 50 |
| mech parts (4 × 2 int) | 100 |
| weapon_slots (3 × 30 chars) | 100 |
| ammo_inventory (3 × 30 chars) | 100 |
| unlocked_fragments (~4 ids) | 200 |
| read_logs (~6 ids) | 300 |
| encounter_count + room_id + pos | 100 |
| HUD settings | 50 |
| **Total** | **~1000 bytes / save** |

**Output Range**: 1-2 KB / save。**Edge case**: 50+ 个真相碎片 = 2-3 KB（仍 < 5 KB）。

### F3. Save Time Estimate

`save_time_ms = json_encode + file_write`

| 操作 | 时间 |
|------|------|
| JSON encode | 2ms |
| File write (1-2 KB) | 5ms |
| Flush | 3ms |
| **Total** | **~10ms (async, 不阻塞主循环)** |

**Output Range**: 10-15ms 总时间。**Edge case**: 大存档（未来 VS 50+ 真相碎片）= 30-50ms（仍在 16.6ms 帧预算内，async）。

### F4. Load Time Estimate

`load_time_ms = json_decode + state_restore + UI_rebuild`

| 操作 | 时间 |
|------|------|
| JSON decode | 2ms |
| state_restore (逐系统) | 20ms (10 系统 × 2ms) |
| UI rebuild (HUD) | 10ms |
| **Total** | **~32ms (sync, 在加载界面)** |

**Output Range**: 30-50ms。**Edge case**: 加载界面有 0.5s 淡黑 / 进度条掩盖延迟。

## Edge Cases

| # | 条件 | 结果 | 原因 |
|---|------|------|------|
| 1 | **save_version 不匹配**（v1 → v2 升级） | upgrade_path(snap) → 缺失字段填默认值 + 升级武器 ID（旧 → 新） | per C-R5 兼容 |
| 2 | **save 文件损坏**（JSON 解析失败） | `SaveCorruptError` + silent 回退到 TITLE 新游戏 + 不 crash | per C-R5 自愈 |
| 3 | **磁盘满 / 权限错** | `SaveError` 信号 + HUD 提示"保存失败" + 内存状态保留 | per C-R7 |
| 4 | **战斗中按 F5**（违反 C-R3） | 拒绝保存 + UI 提示"战斗中无法保存"，F5 在战斗中 disabled | per C-R3 safe points |
| 5 | **F5 + F9 同帧** | 串行执行（不并行） | 避免 IO 冲突 |
| 6 | **Save 写盘过程中崩溃** | 下次启动读存档 = JSON 不完整 = C-R5 损坏自愈 → 退到 autosave（如果存在） | crash safety |
| 7 | **多 slot 互相覆盖** | manual slot 0/1/2 各自独立，但 autosave 始终覆盖 slot "autosave" | per C-R1 |
| 8 | **Save 引用 .tres 找不到**（per #1 Resource） | 武器槽 = null 字段 + HUD 提示"丢失武器 [X]"（per #15 E10） | per C-R5 自愈 |
| 9 | **玩家在 save loading 中** | loading 界面有 0.5s 淡黑 + 进度条，玩家不操作 | per F4 load time |
| 10 | **Save 包含 .tres 但 .tres 升级** | Resource 引用通过 id 匹配（per #1 资源 ID 唯一性），找不到 = null 字段 | per #1 C-R7 |
| 11 | **autosave 频繁触发**（玩家在章节 1 反复遇敌 + 战斗胜利） | 每次 10ms async，性能 OK | per C-R6 |
| 12 | **Save 文件被玩家手动删除** | silent 回退到 TITLE 新游戏 | per C-R5 |

## Dependencies

### 上游依赖（10 个系统）

| 系统 | 接口 | 备注 |
|------|------|------|
| **状态机 #3** | `get_state_snapshot() / load_snapshot(snap)` | state_stack |
| **战斗核心 #7** | battle_state 序列化 | 战斗不存 |
| **武器弹药 #11+#12** | inventory_snapshot | weapon_slots + ammo |
| **关卡 #15** | room_snapshot | room_id + pos |
| **暗雷 #16** | encounter_count | 章节进度 |
| **NPC/终端 #18** | fragments + read_logs | 真相碎片 |
| **机甲 #13** | parts HP | 4 部位 |
| **HUD** | hud_settings | 字体等 |
| **玩家输入 #2** | (无 — 硬编码) | 设置不存 |
| **相机 #4** | (MVP 不存) | 重新计算 |

### 下游依赖

| 系统 | 接口 | 备注 |
|------|------|------|
| **菜单 / 暂停 #23（VS）** | save/load UI 集成 | VS 阶段 |
| **HUD** | 推送 "已自动保存" / "保存失败" 提示 | MVP |

### 双向约束

| 约束 | 在 #3 中 | 在本 GDD 中 |
|------|----------|-------------|
| save_version + 升级路径 | #3 E11 (autoload order) | C-R4 + C-R5 兼容 |
| 状态栈 = 序列化 | #3 F1 state_stack | 本系统 state_stack 字段 |
| Save 触发不打断 | #3 C-R4 atomic transition | C-R6 async write |

## Tuning Knobs

| 参数 | 当前默认值 | 安全范围 | 调高 → | 调低 → | 为什么取这个数 |
|------|------------|----------|---------|---------|----------------|
| `AUTOSAVE_ON_NEW_CHAPTER` | true | true / false | 章节间必保存 | 玩家自由 | 章节切换 = 高价值存档点 |
| `AUTOSAVE_ON_NEW_ROOM` | true | true / false | 频繁 autosave | 房间进度丢失 | 房间切换 = 玩家进度 |
| `AUTOSAVE_ON_BATTLE_VICTORY` | true | true / false | 频繁 autosave | 战斗后丢失进度 | 战斗胜利 = 战利品已获得 |
| `MANUAL_SLOT_COUNT` | 3 | 1-10 | 玩家选 slot 自由 | 没选 | 3 = 简单 + 够用 |
| `SAVE_FILE_FORMAT` | "json" | "json" / "binary" | debug 友好 | 不可读 | JSON 优先（MVP debug） |
| `SAVE_VERSION_CURRENT` | 1 | int | 未来版本 | — | v1.0 启动 |
| `LOADING_FADE_DURATION_MS` | 500 | 0-2000 | 加载界面太长 | 加载界面太短 | 500ms = 掩盖 F4 32ms + 视觉稳定 |
| `SAVE_HUD_TOAST_DURATION_MS` | 1500 | 500-3000 | 提示太长 | 提示太短 | 1.5s = 玩家足够注意到 |

### 跨系统杠杆

| 杠杆 | 影响范围 | 当前值 | 调高 → | 调低 → |
|------|----------|---------|---------|---------|
| `AUTOSAVE_ON_NEW_ROOM` | 玩家安全感 vs IO 频率 | true | 频繁 IO | 房间进度丢失 |
| `LOADING_FADE_DURATION_MS` | 加载体验 | 500 | 加载界面长 | 加载界面短 |

## Visual/Audio Requirements

| 事件 | 视觉 | 音频 | 备注 |
|------|------|------|------|
| Autosave 成功 | HUD 右上 toast "已自动保存" 1.5s | 短"保存"音 | per F1 |
| Manual save 成功 | HUD 提示"已保存到 [slot X]" 1.5s | "保存"音 | per F1 |
| Save 失败 | HUD 红字"保存失败" | 警告音 | per C-R7 |
| Loading | 全屏淡黑 0.5s + 进度条 | 加载音 | per F4 |
| Load 成功 | 屏幕淡黑 0.5s + 进入 save 时画面 | "加载"音 | per C-R5 |
| Load 失败（损坏） | TITLE 屏幕 + 不 crash | 无特殊音 | per E2 |

## Acceptance Criteria

> Solo 模式（`qa-lead` 未咨询），生产前人工 review。

### Autosave

- **AC-1**：**GIVEN** 玩家进入新章节 **WHEN** 测 autosave **THEN** 文件写入 + HUD toast 显示"已自动保存"。验证：F1 autosave 触发。
- **AC-2**：**GIVEN** 玩家进入新房间 **WHEN** 测 autosave **WHEN** 测 **THEN** 同 AC-1。验证：F1。
- **AC-3**：**GIVEN** 战斗胜利 **WHEN** 测 autosave **WHEN** 测 **THEN** 同 AC-1。验证：F1。

### Save Schema

- **AC-4**：**GIVEN** 玩家 save **WHEN** 测 save JSON **THEN** 包含全部 9 字段（per C-R2 schema）。验证：完整快照。
- **AC-5**：**GIVEN** 玩家章节 1 房间 5 战斗胜利 **WHEN** 测 save **THEN** 包含 `chapter_id: "chapter_1"` + `room_id: "C-1-room-5"` + `player_pos: {x, y}` + `encounter_count_chapter_1: 12` + `unlocked_fragments: [3 个]`。验证：序列化。

### Manual Save

- **AC-6**：**GIVEN** 玩家按 F5 + 在 EXPLORATION **WHEN** 测 **THEN** HUD 提示"已保存到 slot 0" 1.5s + slot 0 文件写入。验证：manual save。
- **AC-7**：**GIVEN** 玩家按 F5 + 在 BATTLE **WHEN** 测 **THEN** UI 提示"战斗中无法保存" + F5 拒绝。验证：E4 safe points。
- **AC-8**：**GIVEN** 玩家按 F5 + 选 slot 0/1/2 **WHEN** 测 **THEN** 各自独立文件 + 不互相覆盖。验证：E7 multi-slot。

### Load

- **AC-9**：**GIVEN** 玩家从 TITLE 选"继续游戏" **WHEN** 测 **THEN** 加载最近 autosave + 全屏淡黑 0.5s + 进入 save 时画面。验证：C-R5 + F4。
- **AC-10**：**GIVEN** save 文件损坏 **WHEN** load **THEN** silent 回退到 TITLE + 不 crash。验证：E2 损坏自愈。
- **AC-11**：**GIVEN** save_version 不匹配（v0 → v1）**WHEN** load **THEN** upgrade_path 升级 + 缺失字段填默认值。验证：E1 兼容。
- **AC-12**：**GIVEN** save 引用 .tres 找不到（武器已被删）**WHEN** load **THEN** 武器槽 = null + HUD 提示"丢失武器 [X]"。验证：E8 资源自愈。

### 性能

- **AC-13**：**GIVEN** 玩家 autosave 触发 30 次（章节 1）**WHEN** 测 **THEN** 每次 10ms async，**不**掉帧。验证：F3 + C-R6。
- **AC-14**：**GIVEN** 玩家 load 触发 **WHEN** 测 **THEN** 32ms sync（被 loading 界面掩盖）。验证：F4。

### 错误处理

- **AC-15**：**GIVEN** 磁盘满 **WHEN** save **THEN** `SaveError` 信号 + HUD 红字"保存失败" + 内存状态保留。验证：E3 + C-R7。
- **AC-16**：**GIVEN** Save 写盘过程中崩溃（模拟）**WHEN** 启动游戏 **THEN** 损坏自愈退到 autosave（如果存在）否则 TITLE 新游戏。验证：E6 crash safety。

### 跨章节保留

- **AC-17**：**GIVEN** 玩家章节 1 完成 + 章节 2 入口 save **WHEN** 测 save **THEN** 玩家 inventory / weapon_slots / 真相等跨章节保留。验证：跨章节持久化。
- **AC-18**：**GIVEN** 玩家解锁 4 个真相碎片 + save **WHEN** load **THEN** 4 碎片全部恢复。验证：Pillar 4 不丢。

## Open Questions

| 问题 | Owner | 截止 | 决议 |
|------|-------|------|------|
| MVP 是否要 Save/Load 列表 UI（slot 0/1/2 显示时间戳）？ | ux-designer | 菜单 GDD 阶段 | 当前定：MVP **不**实现（autosave + F5 manual + TITLE 继续游戏足够，per C-R1） |
| save_version 升级路径如何管理？ | lead-programmer | 架构 GDD 阶段 | 当前定：v1.0 启动 + 简单 `upgrade(v0 → v1)` 函数（字段映射） |
| 是否支持云存档（Steam Cloud）？ | release-manager | Release 阶段 | 当前定：MVP 本地 user://，VS 评估云存档 |
| 多存档槽位是否要"自动"（autosave 保留 3 个最近章节）？ | systems-designer | VS 阶段 | 当前定：MVP 单 autosave 槽 + 3 manual 槽，VS 评估"autosave 滚动" |
| Save 文件是否需要加密（防作弊）？ | security-engineer | Release 阶段 | MVP 不加密（debug 友好） |
| **10 systems 需补 snapshot/restore 接口契约**：C-R2 要求每个系统实现 `get_state_snapshot() -> Dictionary` + `load_snapshot(snap: Dictionary) -> void`，但 #3 / #7 / #11+#12 / #15 / #16 / #18 GDD 未显式 call out 此契约。需在每系统 GDD 补接口契约段："SaveLoad contract: 必须实现 `get_state_snapshot() -> Dictionary` + `load_snapshot(snap: Dictionary) -> void`，SaveManager 在 C-R6 async write 时调用前者，C-R5 load 时调用后者" | lead-programmer + gameplay-programmer | 实施前 | **待 cross-doc 补契约**（lean first review Rec #3, 2026-06-12） |
| **AC-17 跨章节保留 schema 缺 `chapter_history`**：Schema v1.0 只存 `chapter_id` (current)，无 history。AC-17 "章节 1 完成 + 章节 2 入口 save" 隐含多章节。MVP scope = chapter 1 only (per systems-index)，需补 AC-17 决议: "单章节 snapshot，未来章节 append to schema (v1.1+)" | gameplay-programmer | VS 阶段 | **待 AC-17 决议**（lean first review Rec #4, 2026-06-12） |
| **C-R5 Resource 引用 .tres 找不到 缺 #1 接口契约**：E8 + #1 Resource C-R7 (ID 唯一性) 一致，但 SaveLoad 应显式依赖 #1 提供 `find_resource_by_id(id: StringName) -> Resource` 接口。当前 E8 隐含 #1 必须提供但未在 #1 GDD 写明。需在 #1 补 SaveLoad-specific 接口契约 | lead-programmer | 实施前 | **待 cross-doc 补 #1 接口**（lean first review Rec #5, 2026-06-12） |
| **F1 autosave count 缺与 #15/#16 实际数字对齐**：F1 写"~30 次" (10 房间 + ~25 战斗胜利)，但具体数字依赖 #15 章节 size + #16 encounter density。建议替换为 formula reference: `autosave_per_chapter = #15 rooms_per_chapter + sum(#16 encounters_per_room) + 1 (chapter_complete)`。需在 OQ 补决议公式 | systems-designer | 实施前 | **待 F1 公式对齐**（lean first review Rec #6, 2026-06-12） |
