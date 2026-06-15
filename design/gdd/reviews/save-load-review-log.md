# Review Log — Save / Load

> Source: `design/gdd/save-load.md`
> Review mode: solo (per `production/review-mode.txt`)
> Analyst depth: lean (per `--depth lean`)
> **Prototype-validated:** no (SaveLoad is Presentation layer; IO patterns will be validated during Technical Setup via ADRs)

---

## Review — 2026-06-12 (first review) — Verdict: APPROVED

**Scope signal:** M-L
**Specialists consulted:** None (lean mode, per user direction)
**Analyst:** main session
**Blocking items:** 0 | **Recommended:** 6 | **Nice-to-have:** 8
**ADRs recommended (non-blocking):** 2 (ADR-SAVE-IO + ADR-SAVE-UPGRADE) — to be authored during Technical Setup

### Summary

First review of the SaveLoad GDD (370 lines, 8 required sections + Visual/Audio + UI redirect + 跨章节保留 ACs bonus = 12 sections). 7 invariants, 4 formulas, 12 edge cases, 8 tuning knobs, 18 acceptance criteria. Schema v1.0 included as concrete JSON example. SaveLoad is the **second largest cross-doc consumer** in the project (10 upstream systems, vs HUD's 8). The 7 invariants cleanly define the contract: 1 autosave + 3 manual (C-R1), complete snapshot (C-R2), safe-points only (C-R3), JSON debug-friendly (C-R4), validate + heal + upgrade (C-R5), async non-blocking (C-R6), error-survive (C-R7). 12 edge cases (E1-E12) cover version migration, corruption, IO failure, race conditions, crash safety, manual delete — exemplary. 18 ACs cover all critical paths. Cross-doc consistency to 9 Approved GDDs (3 Foundation + 1 Core + 4 Feature + 1 Presentation) verified. **8th GDD in a row with cross-doc bidirectional constraints table — project standard fully established.**

**Prior verdict resolved:** N/A (first review)

### Key decisions reaffirmed
- **Lean mode accepted** — no specialist agents spawned. SaveLoad is Presentation layer; IO validation comes from ADRs (SAVE-IO + SAVE-UPGRADE) during Technical Setup, not from `/design-review`.
- **C-R1 1 autosave + 3 manual slots** is the right minimum. MVP doesn't need a slot list UI (per OQ-1). VS 评估 "autosave 滚动".
- **C-R2 完整运行时状态快照** is non-negotiable. SaveManager calls all systems `get_state_snapshot() -> Dictionary`. Partial save = restore corruption.
- **C-R3 Autosave 在 safe points** is the correct safety principle. Battle in-progress save = 帧撕裂 / 状态错乱.
- **C-R4 JSON 格式 + user://save_N.json** is Godot 4.6-native and debug-friendly. Binary 不可读 = 调试噩梦.
- **C-R5 校验 + 自愈 + 升级路径** 三层防御 is industry standard. SaveCorruptError silent fallback + save_version 升级 = 长期可玩性.
- **C-R6 async 写盘** + **C-R7 错误不丢数据** is correctness-first. FileAccess failure → HUD 红字 + 内存状态保留 = 玩家不丢进度.
- **F1 autosave 触发 3 类** (章节/房间/战斗) covers all "玩家进度" points without redundancy.
- **F2 1KB save size 估算** is concrete and implementable. Per-field breakdown allows calibration.
- **F3 10ms + F4 32ms** 估算具体. Async/sync 分别处理 within frame budget.
- **E1 save_version upgrade** + **E2 silent fallback** + **E6 crash safety** 三层 IO 错误处理.
- **E8 Resource 引用 .tres 找不到 → null 字段 + HUD 提示** is consistent with #1 Resource C-R7 (ID 唯一性).
- **18 ACs** is appropriate for M-L scope. AC-17 跨章节保留 + AC-18 Pillar 4 不丢 是关键的玩家保障.
- **Schema v1.0 JSON 示例** with 9 fields is concrete and implementable. Variable naming consistent with GDD language.
- **8th GDD in a row** with cross-doc bidirectional constraints table. Project standard fully established.

### Recommended (non-blocking) follow-ups
1. **Rec #1** (C-R6 async write needs implementation path): F3 says "async" but no concrete path. Recommend ADR `ADR-SAVE-IO` covering: FileAccess mode (open_write), write queue, _process drain, error handling, 0.5s loading fade triggers. **Deferred — to be authored in Technical Setup.**
2. **Rec #2** (C-R5 upgrade path needs ownership decision): OQ-2 "simple `upgrade(v0 → v1)` function" is ambiguous. Recommend: SaveManager owns upgrade_path() centrally, not per-system. Add ADR `ADR-SAVE-UPGRADE` (or fold into ADR-SAVE-IO). **Deferred — to be authored in Technical Setup.**
3. **Rec #3** (10 systems need snapshot/restore contract): C-R2 requires every system implements `get_state_snapshot() / load_snapshot(snap)`. The 10 systems' GDDs don't all explicitly call out this contract. Add: "SaveLoad contract: every system MUST implement `get_state_snapshot() -> Dictionary` and `load_snapshot(snap: Dictionary) -> void`" in #3 / #7 / #11+#12 / #15 / #16 / #18 GDDs. **Appended to Open Questions for tracking.**
4. **Rec #4** (AC-17 跨章节保留 schema 缺 `chapter_history`): Schema v1.0 only stores `chapter_id` (current), no history. AC-17 "章节 1 完成 + 章节 2 入口 save" implies multi-chapter. MVP scope = chapter 1 only (per systems-index), so AC-17 should clarify "single-chapter snapshot, future chapters append to schema". **Appended to Open Questions for tracking.**
5. **Rec #5** (C-R5 Resource 引用 .tres 找不到 → null 字段): E8 + #1 Resource C-R7 consistent, but SaveLoad should add explicit `find_resource_by_id(id: StringName) -> Resource` contract from #1. Currently E8 assumes #1 provides it. **Appended to Open Questions for tracking.**
6. **Rec #6** (F1 autosave count vs #15/#16 实际数字): F1 says "~30 次" (10 房间 + ~25 战斗胜利), but exact numbers depend on #15 chapter size + #16 encounter density. Recommend: replace "~30" with formula reference (#15 room count × #16 encounter-per-room). **Appended to Open Questions for tracking.**

### Nice-to-have
- 7 invariants 完整覆盖 Save/Load 的所有 design space (slots, snapshot, triggers, format, validation, async, error).
- C-R1 1 autosave + 3 manual is the minimum viable complexity.
- C-R4 JSON + user:// 是 Godot 4.6-native 模式.
- C-R5 三层防御 (校验/自愈/升级) 是 industry standard.
- C-R6 async + C-R7 error-survive 是 correctness-first pattern.
- F1 3 类触发 覆盖"玩家进度"点，不冗余.
- F2 1KB 估算 精细 + 逐字段分解 — 实施可校准.
- F3 10ms + F4 32ms 估算 具体 + 帧预算内.
- E1 + E2 + E6 三层 IO 错误处理 (升级 / 损坏自愈 / crash safety).
- E8 Resource 引用 .tres 找不到 → null 字段 — 与 #1 + HUD 双向一致.
- E10 + E11 + E12 覆盖所有 Resource + IO + 玩家操作 failure modes.
- 18 ACs 全面 (autosave / schema / manual / load / 性能 / 错误 / 跨章节).
- Schema v1.0 JSON 示例 9 字段 全部覆盖 7 invariants.

### Manual checks deferred
- 10 systems' `get_state_snapshot() / load_snapshot(snap)` 接口契约 cross-doc 验证 — verify in `/review-all-gdds`
- Cross-chapter schema evolution (VS 阶段) — defer until VS authoring
- Cloud save (Steam Cloud) — Release 阶段 per OQ-3
- ADR-SAVE-IO + ADR-SAVE-UPGRADE authoring — Technical Setup phase (Phase 3b)
- Save file encryption (anti-cheat) — Release 阶段 per OQ-5
- Mech-upgrade.md GDD (#13) referenced but VS scope — not blocking

### Post-Approval
- Status in `systems-index.md`: Approved (line 43 updated, SaveLoad). **12/12 MVP GDDs approved. 100% complete!**
- GDD frontmatter: updated to `Status: Approved` + `Review Verdict: APPROVED (first review 2026-06-12, lean)`
- Open Questions: Rec #3 (snapshot/restore contract), #4 (chapter_history), #5 (find_resource_by_id), #6 (F1 autosave count) appended for tracking. Rec #1, #2 (ADRs) deferred to Technical Setup.
- Tracking: **12/12 MVP GDDs approved**. 0 remaining GDDs in pipeline. MVP design phase COMPLETE.
- Next pipeline step: Phase 2a — `/review-all-gdds` (cross-GDD consistency report). 2 ADRs (SAVE-IO + SAVE-UPGRADE) flagged for Technical Setup.
- **MILESTONE: All MVP GDDs approved. Pipeline ready for cross-GDD review and gate-check advancement to Technical Setup.**
