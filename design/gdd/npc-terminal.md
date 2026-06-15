# NPC / 终端日志 (NPC / Terminal Logs)

> **Status**: Approved
> **Author**: user + narrative-director + writer
> **Review Verdict**: APPROVED (first review 2026-06-12, lean)
> **Last Updated**: 2026-06-12 (first review)
> **Implements Pillar**: Pillar 4（真相是收集的结果）—— 终端 / NPC 录音是真相碎片的载体；Pillar 2（发现 > 数值）—— 真相碎片是"我发现了这个"

## Summary

NPC / 终端日志系统是 Railhunter **Pillar 4（真相是收集的结果）的核心**。它定义 1-2 段终端日志（MVP：每章节 5-8 段录音 / 日志）、NPC 类型（可选 MVP）、真相碎片（StoryFragment）的产出接口、与剧情图谱 #19 的契约（仅 MVP 阶段声明契约，#19 VS 阶段实现）。

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `关卡 #15`（NPC / 终端位置）、`资源 #1`（TerminalLogData / StoryFragmentData Resource）、`状态机 #3`（push TERMINAL state）· Depended on by: 剧情图谱 #19（VS）、Codex #20（VS）

## Overview

NPC / 终端日志系统是 Railhunter **Pillar 4（真相是收集的结果）的核心载体**。它定义：

- **终端日志**（Terminal Log）—— 散布在关卡各处的音频 / 文本记录，per #1 `TerminalLogData` Resource
- **NPC 类型**（MVP 可选）—— 1-2 个 NPC 提供对话片段
- **真相碎片**（Story Fragment）—— 通过日志 / NPC 触发产出，per #1 `StoryFragmentData`
- **产出接口契约**（per systems-index 循环依赖解决方案）：本系统**只**定义"产生碎片"接口，**不**直接驱动剧情图谱（#19 是 VS 阶段）

本系统**整合**了 #15 关卡（NPC / 终端位置）、#1 资源（TerminalLogData + StoryFragmentData）、#3 状态机（push TERMINAL state）、#4 相机（TERMINAL_CLOSEUP rig）、#5 碰撞（INTERACTABLE layer）。

玩家**直接接触**这个系统——他们读到"真相碎片"。

如果本系统不存在，**Pillar 4 直接失效**——没有"真相的载体"，剧情只是 NPC 长对话（违反 Pillar 4 测试）。

**在 5 层 Feature 中**：本系统是**第四个** Feature 系统（#11+#12、#15、#16 之后）。MVP 每章节 5-8 个终端日志 + 1-2 个 NPC。

## Player Fantasy

玩家**直接接触**这个系统——他们**听到 / 读到**这些碎片。

他们感受到的，是 **Pillar 4（真相是收集的结果）** 的具体兑现——"我拼出了真相的一部分"：

- **找到终端**：玩家在关卡中走近 INTERACTABLE 终端 → 相机拉近（per #4 TERMINAL_CLOSEUP）→ 屏幕显示日志内容（音频 / 文本）
- **听录音**：音频自动播放（约 30-60s） + 文本逐字显示 → 玩家可按 ESC 跳过 / 滚轮滚动
- **获得真相碎片**：日志末尾 emit `signal story_fragment_unlocked(fragment: StoryFragmentData)` → 玩家脑中"多了一块拼图"
- **NPC 对话**（MVP 可选 1-2 个）：玩家走近 NPC → 短对话（per art-bible "极乐迪斯科"风格的密实对话）→ 同样产出碎片
- **可重读**：玩家可重新打开任何已读终端（不消耗资源）——per Codex "已读条目可重看"原则
- **不显示"已读"视觉提示**：MVP 简化（玩家自己记得）

这背后的情感是 **Pillar 4（真相是收集的结果）**——剧情不是被告知的，是被拼出来的。**Pillar 2（发现 > 数值）**——找到终端 = 拼图 +1，比"看见伤害数字 +5"更爽。

参考游戏：
- **Outer Wilds** —— 录音是真相碎片的典范
- **极乐迪斯科** —— 密实对话 / 思想内阁
- **System Shock** —— 终端日志的环境叙事

> `creative-director` 未咨询（Solo 模式）。

## Detailed Design

### Core Rules

本系统有 **5 条 invariant**。

**C-R1 — 每个终端 = 1 段 `TerminalLogData` 资源**。终端节点持有 `terminal_log: TerminalLogData`（per #1 资源），包含：title / body_text / audio_clip（可选）/ associated_fragment（可选 StoryFragmentData）。**禁止**运行时拼字符串。

**C-R2 — 终端触发 = push(TERMINAL) state**。玩家走近终端 → `GameStateMachine.push(TERMINAL, payload={log_id: ...})`（per #3 状态机）。底层 EXPLORATION 冻结但不销毁（per #3 C-R2 push 语义）。**禁止**绕过状态机。

**C-R3 — 真相碎片产出接口 = emit signal**。本系统**只**emit `signal story_fragment_unlocked(fragment: StoryFragmentData)`，**不**直接驱动剧情图谱 UI（#19 VS 阶段消费该信号）。per systems-index "NPC (18) ↔ 剧情图谱 (19)" 循环依赖解决方案：定义产出接口，不直接耦合。

**C-R4 — 每个日志可重读但只产出 1 次碎片**。玩家第二次打开同一终端 = 显示内容但**不**再 emit `story_fragment_unlocked`（防止重复触发）。**禁止**重复解锁（破坏"碎片唯一"原则）。

**C-R5 — NPC（可选 MVP 1-2 个）= 类似终端**。NPC 节点持有 `npc_data: NPCData`（per #1 资源），包含：name / dialog_lines[] / associated_fragment。玩家走近 NPC → push(TERMINAL) + 显示 dialog。**MVP 范围**：1-2 个 NPC（per game concept "首次做开发者，写作风险"）。

### States and Transitions

**5 个终端 / NPC 状态**：

| 状态 | 用途 | 转换触发 |
|------|------|----------|
| `UNREAD` | 玩家未读 | 默认初始 |
| `READ` | 玩家已读 | 玩家第一次读完 / 听完 |
| `REPLAYING` | 玩家在重读 | 玩家打开已 READ 终端 |
| `SKIPPING` | 玩家按 ESC 跳过 | 录音播放中按 ESC |
| `COMPLETED` | 玩家完成（含 unlock 碎片） | unlock 后立即进入 |

**碎片生命周期**（per C-R4 + per #19 集成）：

```
[NOT_UNLOCKED] → emit story_fragment_unlocked → [UNLOCKED] → 永久不可变
                                                                       ↓
                                                              玩家在剧情图谱中看到节点亮起（per #19）
```

### Interactions with Other Systems

| 系统 | 接口 | 触发 |
|------|------|------|
| **关卡 #15** | 提供 Terminal / NPC 节点位置 | 章节加载 |
| **资源 #1** | 读 `TerminalLogData` / `StoryFragmentData` / `NPCData` | 节点初始化 + 玩家互动 |
| **状态机 #3** | `push(TERMINAL, payload={log_id})` | 玩家走近 |
| **相机 #4** | 监听到 TERMINAL state → RIG_TERMINAL_CLOSEUP | 状态转换 |
| **碰撞 #5** | INTERACTABLE layer 提示 #2 玩家输入 | 玩家走近 |
| **玩家输入 #2** | 订阅 `interact` action | 玩家按 E |
| **剧情图谱 #19（VS）** | 消费 `story_fragment_unlocked` 信号 | unlock 时 |
| **Codex #20（VS）** | 消费 `terminal_log_read` 信号 | 玩家读完 |
| **存档 #21** | 序列化 `unlocked_fragments: Array[StringName]` | 存档时 |

## Formulas

### F1. Terminal Log Density per Chapter (per #15 F1)

`terminal_logs_per_chapter = 5-8` (MVP)

| 章节 | 终端日志数 | NPC 数 | 真相碎片数 |
|------|------------|--------|-------------|
| 1（MVP） | 6 | 1 | 4 (1 NPC + 3 terminals, 其中 2 terminals 共用 1 碎片) |
| 2（VS） | 8 | 2 | 6 |
| 3（VS） | 10 | 2 | 8 |

**Rationale**: 终端 = "Pillar 1 B 型密度"回报（per #15 C-R3），每章节 B 型回报 5-8 个 = 5-8 终端。

### F2. Read Time Estimate

`avg_read_time_seconds = body_text_chars / reading_speed_wpm × 60 / 5 + audio_duration_s`

| 变量 | 类型 | 范围 | 描述 |
|------|------|------|------|
| `body_text_chars` | int | 100-1000 | 日志正文字数 |
| `reading_speed_wpm` | int | 200-400 | 玩家阅读速度（中文 200-400 字 / 分钟） |
| `audio_duration_s` | float | 30-90 | 录音时长（per art-bible 密实对话） |

**Default**: 中文 200 字 + 60s 音频 = 60s（音频主导阅读）。**MVP 范围**: 30-90s / 终端。

### F3. Total Narrative Time per Chapter

`total_narrative_minutes = sum(terminal_logs) × avg_read_time_seconds / 60`

**Output**: 章节 1 = 6 终端 × 60s = 6 分钟叙事时间。**Acceptance**: 玩家在 6 分钟内获得 4 个真相碎片 = 1.5 分钟 / 碎片（per Pillar 4 "收集驱动叙事"）。

### F4. Story Fragment Uniqueness (per C-R4)

`unique_fragments_unlocked ≤ total_terminals + total_npcs`（每终端 / NPC 最多 1 个碎片）

**Output Range**: 4-8 碎片 / 章节（MVP 4）。**Edge case**: 玩家读所有终端 = 全部碎片 unlock = 剧情图谱 100% 章节完成。

## Edge Cases

| # | 条件 | 结果 | 原因 |
|---|------|------|------|
| 1 | **玩家第二次读同一终端** | 显示内容但不 emit fragment（per C-R4） | 防止重复 unlock |
| 2 | **音频文件丢失**（.ogg 不存在） | 静默播放 + 仅显示文本 + 日志记录 | E10 资源缺失自愈 |
| 3 | **关联的 StoryFragmentData 引用找不到** | 终端正常运行（不抛错），仅记录 `FragmentMissingError` 到日志 | 不让玩家卡死 |
| 4 | **玩家在 TERMINAL state 中按 ESC 跳过音频** | 立即关闭终端，emit fragment（如未 unlock） | F2 skip = 玩家主动决策 |
| 5 | **NPC 对话线 0 条**（开发者忘记填） | 终端显示"信号损坏"占位文字 | 资源缺失自愈 |
| 6 | **终端在 BATTLE 状态被访问**（不合法的状态转换） | 状态机 #3 拒绝 push(TERMINAL) from BATTLE，silent | 状态合法性（per #3 合法转换表） |
| 7 | **玩家快速来回进出同一终端** | 1 次 unlock + 多次 read display | C-R4 一次性 unlock |
| 8 | **音频播放 0.5s 时玩家死亡** | 音频停止 + 玩家死亡流（per #3 死亡流） | 状态机接管 |
| 9 | **多语言 / 本地化**：MVP 不实现本地化，body_text 是中文硬编码 | VS 阶段评估本地化钩子 | per Polish #25 |

## Dependencies

### 上游依赖

| 系统 | 接口 | 备注 |
|------|------|------|
| **关卡 #15** | 提供 Terminal / NPC 节点位置 | 章节加载 |
| **资源 #1** | 读 `TerminalLogData` / `StoryFragmentData` / `NPCData` | 资源 |
| **状态机 #3** | `push(TERMINAL, payload={log_id})` | 状态转换 |
| **相机 #4** | RIG_TERMINAL_CLOSEUP | 视觉转场 |
| **碰撞 #5** | INTERACTABLE layer 提示 | 玩家走近 |
| **玩家输入 #2** | 订阅 `interact` action | 玩家按 E |

### 下游依赖（VS 阶段消费本系统信号）

| 系统 | 接口 | 备注 |
|------|------|------|
| **剧情图谱 #19** | 消费 `story_fragment_unlocked` | VS 阶段实现 |
| **Codex #20** | 消费 `terminal_log_read` | VS 阶段实现 |
| **存档 #21** | 序列化 `unlocked_fragments: Array[StringName]` | MVP 实现 |

### 双向约束

| 约束 | 在 #15 中 | 在本 GDD 中 |
|------|----------|-------------|
| 终端 = B 型密度回报 | #15 C-R3 | 本系统 F1 |
| INTERACTABLE layer 提示 | #5 F4 | 本系统 C-R2 + #2 玩家输入 |
| 终端可重读 | n/a | C-R4 |
| 碎片唯一 | n/a | C-R4 + F4 |

## Tuning Knobs

| 参数 | 当前默认值 | 安全范围 | 调高 → | 调低 → | 为什么取这个数 |
|------|------------|----------|---------|---------|----------------|
| `TERMINAL_LOGS_PER_CHAPTER` | 6 | 4-10 | 玩家疲劳 | Pillar 4 收集感弱 | 6 = 章节 1 B 型回报数（per #15 F1） |
| `NPCS_PER_CHAPTER` | 1 | 0-3 | 写作风险（first-time developer） | 没 NPC | 1 = MVP 最小，VS 评估 |
| `AVG_BODY_TEXT_CHARS` | 200 | 100-500 | 玩家疲劳 | 信息不足 | 200 = 60s 音频 + 200 字文本 |
| `AUDIO_DURATION_S` | 60 | 30-90 | 玩家疲劳 | 信息不足 | 60s = 1 分钟 = 玩家注意力上限 |
| `UNLOCK_ON_FULL_READ` | true | true / false | 完整阅读才 unlock | 跳过也 unlock | 鼓励完整阅读 |
| `ENABLE_LOCALIZATION` | false | true / false | 需本地化钩子 | MVP 不实现 | MVP 单语言（中文） |

### 跨系统杠杆

| 杠杆 | 影响范围 | 当前值 | 调高 → | 调低 → |
|------|----------|---------|---------|---------|
| `TERMINAL_LOGS_PER_CHAPTER` | Pillar 4 收集密度 | 6 | 玩家疲劳 | Pillar 4 失效 |
| `AVG_BODY_TEXT_CHARS` | 叙事节奏 | 200 | 慢节奏 | 快节奏 |

## Visual/Audio Requirements

| 事件 | 视觉反馈 | 音频反馈 | 备注 |
|------|----------|----------|------|
| 玩家走近终端 | "按 E 互动" 提示（per #2） + INTERACTABLE 高亮 | 短促提示音 | per C-R2 |
| 终端打开 | 相机拉近（per #4 RIG_TERMINAL_CLOSEUP） | 终端激活音 | per C-R2 |
| 录音播放 | 文字逐字显示 + 进度条 | 日志音频 | per F2 |
| 录音结束 | "已听完" + "获得真相碎片" 弹窗 | 短"解锁"音 | per C-R3 |
| ESC 跳过 | 立即关闭终端 | 音频停止 | per E4 |
| 玩家重读 | 直接显示内容（不重 unlock） | 无特殊音 | per C-R4 |

## UI Requirements

| 信息 | 消费者 | 触发 | 备注 |
|------|--------|------|------|
| 终端内容（text + audio progress） | HUD | push(TERMINAL) | 文本框 |
| 真相碎片解锁弹窗 | HUD | emit story_fragment_unlocked | "获得真相碎片 [X]" |
| 进度条 | HUD | 录音播放 | 0-100% |
| ESC 跳过提示 | HUD | 录音播放中 | "按 ESC 跳过" |
| 剧情图谱节点亮起 | 剧情图谱 #19 | fragment unlock | VS 阶段 |

## Acceptance Criteria

> Solo 模式（`qa-lead` 未咨询），生产前人工 review。

### 基础触发

- **AC-1**：**GIVEN** 玩家走近 INTERACTABLE 终端 **WHEN** 测 **THEN** "按 E 互动" 提示显示（per #2 + #5 F4）。验证：基础触发。
- **AC-2**：**GIVEN** 玩家按 E 互动 **WHEN** 测 **THEN** `push(TERMINAL, payload={log_id})` + 相机拉近（per #4 RIG_TERMINAL_CLOSEUP）。验证：C-R2 + #4 集成。

### 终端播放

- **AC-3**：**GIVEN** 终端 push 完成 **WHEN** 测 **THEN** 录音自动播放 + 文字逐字显示 + 进度条 0-100%。验证：F2 read time。
- **AC-4**：**GIVEN** 录音播放中 **WHEN** 玩家按 ESC **WHEN** 测 **THEN** 音频立即停止 + 终端关闭 + 弹出真相碎片（如未 unlock）。验证：E4 skip。

### 真相碎片

- **AC-5**：**GIVEN** 玩家第一次读终端 + 关联 StoryFragmentData **WHEN** 录音结束 **THEN** emit `story_fragment_unlocked(fragment)` + HUD 弹窗"获得真相碎片 [X]"。验证：C-R3。
- **AC-6**：**GIVEN** 玩家第二次读同一终端 **WHEN** 测 **THEN** 显示内容但**不**再 emit fragment。验证：C-R4。
- **AC-7**：**GIVEN** 章节 1 玩家读完所有 6 终端 + 1 NPC **WHEN** 测 unlocked_fragments **WHEN** 测 **THEN** 4 个碎片全部 unlock（per F1 表）。验证：F4 碎片唯一。

### NPC

- **AC-8**：**GIVEN** 玩家走近 NPC + 按 E 互动 **WHEN** 测 **WHEN** 测 **THEN** push(TERMINAL) + 显示 NPC dialog lines + 结束 emit fragment（如有关联）。验证：C-R5 NPC。
- **AC-9**：**GIVEN** NPC dialog_lines 0 条（开发者忘记填）**WHEN** 测 **THEN** 显示"信号损坏"占位文字 + 不 crash。验证：E5 资源自愈。

### 资源错误

- **AC-10**：**GIVEN** 终端音频文件丢失 **WHEN** 测 **WHEN** 测 **THEN** 静默播放 + 仅显示文本 + 日志记录。验证：E2 资源缺失自愈。
- **AC-11**：**GIVEN** 终端关联的 StoryFragmentData 引用找不到 **WHEN** 测 **WHEN** 测 **THEN** 终端正常运行（不抛错），仅日志记录 FragmentMissingError。验证：E3 资源自愈。

### 状态合法性

- **AC-12**：**GIVEN** 玩家在 BATTLE 状态尝试打开终端 **WHEN** 测 **WHEN** 测 **THEN** 状态机 #3 拒绝 push(TERMINAL) from BATTLE，silent（per #3 合法转换表）。验证：E6 状态合法性。
- **AC-13**：**GIVEN** 玩家在 TERMINAL state 中死亡 **WHEN** 测 **WHEN** 测 **THEN** 音频停止 + 状态机接管死亡流。验证：E8 死亡流。

### 存档

- **AC-14**：**GIVEN** 玩家章节 1 读 3 终端（unlock 2 碎片）+ 1 NPC（unlock 1 碎片）存档 **WHEN** 测 save data **WHEN** 测 **THEN** 包含 `unlocked_fragments: [frag_1, frag_2, frag_3]`。验证：序列化。

## Open Questions

| 问题 | Owner | 截止 | 决议 |
|------|-------|------|------|
| MVP 1-2 个 NPC 是否值得做？写作对 first-time developer 有风险 | narrative-director | narrative GDD 阶段 | 当前定：MVP 1 个 NPC（最简，验证"对话触发"机制），VS 评估增加 |
| 录音是 .ogg 音频还是 TTS（per Godot 4.6 内置）？ | audio-director + technical-artist | audio GDD 阶段 | 当前定：.ogg 预录音（可控质量），MVP 1 NPC 用预录 |
| 真相碎片是否区分"主线" / "支线"（影响剧情图谱节点大小 / 颜色）？ | narrative-director | 剧情图谱 GDD 阶段 | 当前定：MVP 不区分（平等），VS 评估 |
| 玩家是否能"分享"终端到其他玩家（截图 / 复制文本）？ | ux-designer | VS 阶段 | MVP 不实现 |
| 终端是否应该有"完成度提示"（"3/6 已读"）？ | ux-designer + codex | Codex GDD 阶段 | 当前定：MVP 简化，玩家自己记得 |
| **NPCData 需加到 #1 Resource schema**：C-R5 引用 `npc_data: NPCData`，但 #1 Resource 9 subtypes 无 NPCData（无 wpn/ammo/enm/part/itm/eff/log/frag/reg 之外）。需选一：(a) 加 NPCData 为 #1 10th subtype (推荐, 与其他 Resource 一致), OR (b) NPC 复用 TerminalLogData + `npc_flag: bool` 扩展。Cross-doc reconciliation 需在 `/review-all-gdds` 验证 | lead-programmer + game-designer | `/review-all-gdds` 时 | **待 cross-doc 决议**（lean first review Rec #1, 2026-06-12） |
| **"2 terminals 共用 1 碎片" 缺 C-R**：F1 章节 1 写"2 terminals 共用 1 碎片"，但 5 条 invariant 未提"shared fragment"概念。需 C-R6: (a) "Multiple terminals 可共享同一 fragment (触发任一即 unlock)", OR (b) "每 fragment 唯一对应 1 terminal/NPC (1:1 strict)"。当前定 (a) 更符合 Pillar 4 收集感 | narrative-director | 实施前 | **待补 C-R**（lean first review Rec #2, 2026-06-12） |
| **C-R4 unlock race condition 缺显式 AC**：C-R4 + E7 说"1 unlock per fragment"，但未给"重复触发的同一 frame" race condition 的 AC。需补 AC-7b: "GIVEN 玩家读终端 + fragment 已在 MetaState.unlocked WHEN 测 THEN unlocked_fragments 不增 (no double-count)" | gameplay-programmer | 实施前 | **待补 AC**（lean first review Rec #3, 2026-06-12） |
| **E8 audio stop 责任划分不清**：E8 说"音频停止 + 玩家死亡流"，但哪一方负责 stop audio？`GameStateMachine` 还是 `AudioManager`？需明确: AudioManager.stop_all() 由 #3 死亡流 transition 调用，不由 NPC GDD 触发。需 ADR | lead-programmer + audio-director | 实施前 | **待补 ADR 责任划分**（lean first review Rec #6, 2026-06-12） |
