# Review Log — 关卡 / 迷宫 (Level / Dungeon)

> Source: `design/gdd/level-dungeon.md`
> Review mode: solo (per `production/review-mode.txt`)
> Analyst depth: lean (per `--depth lean`)
> **Prototype-validated:** no (Level layout is hand-crafted; gameplay not prototype-validated)

---

## Review — 2026-06-12 (first review) — Verdict: APPROVED

**Scope signal:** L (the only L-tier MVP GDD)
**Specialists consulted:** None (lean mode, per user direction)
**Analyst:** main session
**Blocking items:** 0 | **Recommended:** 7 | **Nice-to-have:** 7

### Summary

First review of the Level/Dungeon GDD (357 lines, 8 required sections + Visual/Audio + UI + Dependencies bonus sections). 8 invariants, 5 formulas, 10 edge cases, 9 tuning knobs, 20 acceptance criteria. Carries **Pillar 1 (探索密度)** and **Pillar 2 (发现 > 数值)** — the structural backbone of the MVP experience. The 5-type density template (A/B/C/D/E per C-R3) is a Pillar-driven design heuristic that should become a project standard. F4 玩家类型发现率 prediction + F5 reward_density 量化测试 together provide a **measurable definition of "done"** for Pillar 1. 8-state room lifecycle is exemplary — local state machine complementing global #3. Cross-doc bidirectional constraints to all 4 Foundation GDDs + #7 Battle Core (all Approved 2026-06-12) verified clean. **The 4th GDD in a row with a bidirectional cross-doc constraints table (project standard).**

**Prior verdict resolved:** N/A (first review, not prototype-validated — Level layout is hand-crafted, gameplay validated via #7 battle-core prototype)

### Key decisions reaffirmed
- **Lean mode accepted** — no specialist agents spawned. Cross-doc consistency to 6 already-Approved GDDs is sufficient inline. Hand-crafted-only is a Pillar 1 commitment, not a prototype-validated gameplay mechanic.
- **MVP = 1 chapter (卫星表层, 10 rooms) + 16 rewards = reward_density 1.6 (F5 "good" range)** is the right Pillar 1 calibration. 1.5-2.0 is the target band — 1.6 sits at the upper-mid.
- **C-R3 5-type density template (A weapons / B terminals / C items / D hidden / E story)** is the right Pillar 1 design heuristic. Should be promoted to `design/gdd/game-pillars.md` as a design tool.
- **C-R4 "遇敌 tile = 不可见 trigger"** preserves "暗雷" surprise (per Pillar 2). OQ #6 玩家从战斗回来时**不**提示"已遇敌" reaffirms this.
- **C-R5 4 lock types (NORMAL/WEAPON_LOCKED/AMMO_LOCKED/ITEM_LOCKED/STORY_LOCKED)** cleanly maps to #1 Resource subtypes. AMMO_LOCKED consumption semantics need #17 doors-locks to clarify (Rec #4 → OQ).
- **C-R6 隐藏区域 = 2 入口 (可破坏墙 / 不可见门)** is the right balance — too easy = no discovery; too hard = 玩家 frustration. 20% 隐藏房间比例 (HIDDEN_ROOM_RATIO) is a calibrated Pillar 2 兑现.
- **F3 chapter minutes formula** = `sum(rooms) × (avg_room_minutes + avg_battle_minutes × encounter_count_per_room)`. MVP chapter 1 = ~41 min ✓ (within game concept 30-45 min/章节).
- **F4 玩家类型发现率** (Explorer 100% / Achiever 80-100% / Casual 30-60% / Speedrun 0-20%) is a thoughtful playtest prediction. Target ≥ 60% average for chapter 1 (per Pillar 2 验证).
- **F5 reward_density ratio量化测试** (good: 1.5-2.0) is gold standard. Add to `/architecture-review` as a Pillar 1 validation metric.
- **8 room states (LOCKED/ENTERED/EXPLORING/COMBAT/RETURNING/COMPLETED/CLEARED/HIDDEN)** is a LOCAL state machine (room-level) complementing global #3. Exemplary pattern for any sub-system with its own lifecycle.
- **20 ACs is the highest count in the project** (tied with #7 battle-core-loop) — appropriate for the only L-scope MVP GDD. AC-3 Pillar 1 测试 + AC-12 章节完成度 are Pillar-tracking ACs that should be in every Feature GDD.
- **C-R1 "禁止程序生成"** is a Pillar 1 commitment that needs ADR backing (Rec #3 → Architecture phase).

### Recommended (non-blocking) follow-ups
1. **Rec #1** (E7 ENCOUNTER double-trigger suppression — explicit AC): Add **AC-14b**: "GIVEN 玩家在 BATTLE 状态 + 物理引擎仍报告 ENCOUNTER tile overlap WHEN 测 THEN 该次 trigger 被 `MonitoringToggle` 静默丢弃。" E7 mentions "ENCOUNTER monitoring = false in BATTLE state" but no AC validates it. **Appended to Open Questions for tracking.**
2. **Rec #2** (F3 chapter minutes formula caveat): F3 is linear — non-linear encounter clustering effects (e.g., back-to-back encounters) are NOT captured. Add caveat to F3. Deferred to Architecture phase (no implementation block).
3. **Rec #3** (C-R1 hand-crafted-only needs ADR): "禁止程序生成" is a Pillar 1 commitment. Recommend ADR: "ADR-LEVEL-HANDCRAFTED — All level layouts hand-authored. No procedural generation. Reason: density is Pillar 1." Deferred to Architecture phase.
4. **Rec #4** (AMMO_LOCKED consumption semantics): C-R5 says "持爆破弹 ≥ 5 发" but is the ammo consumed on unlock? Recommend: AMMO_LOCKED = check ownership only (per #11/#12 ammo not consumed, see C-R8). Flag to #17 doors-locks GDD when authored. **Appended to Open Questions for cross-doc tracking.**
5. **Rec #5** (C-R6 隐藏区域缺 "HIDDEN → EXPLORING" transition): Once discovered, hidden room becomes normal. Add explicit transition: "HIDDEN → EXPLORING (when first discovered)". **Appended to Open Questions for tracking.**
6. **Rec #6** (8 room states缺 `HIDDEN_DISCOVERED` intermediate state): If hidden room is discovered but player leaves, next entry should still show as "visited" on minimap. Add `HIDDEN_DISCOVERED` intermediate state. **Appended to Open Questions for tracking.**
7. **Rec #7** (Chapter 1 weapon count vs #11 weapon-ammo TOTAL_WEAPON_TYPES_AVAILABLE = 12): F1 lists chapter 1 = 1 weapon drop. Weapon-ammo tuning knob says total = 12 weapons, implying 4×3 chapter structure. 3 chapters × 1+1+2 = 4 weapons. **Possible inconsistency: 4 ≠ 12.** Cross-doc reconciliation needed in `/review-all-gdds`. **Appended to Open Questions for tracking.**

### Nice-to-have
- "Pillar 1 测试" 5-type density template (A/B/C/D/E) is exemplary. Replicate in `random-encounter.md` and `npc-terminal.md`.
- F4 玩家类型发现率 is a thoughtful playtest prediction. Replicate for any "optional discovery" system.
- F5 reward_density ratio is gold standard. Add to `/architecture-review` as a Pillar 1 validation metric.
- 8-state room state machine (LEVEL-LEVEL) is exemplary. Replicate for any sub-system with its own lifecycle (e.g., Mech upgrade state, Codex entry state).
- AC-3 "Pillar 1 测试" AC is critical — kind of Pillar-tracking AC every Feature GDD should have.
- "Pillar 1 测试" 5-type template is essentially a **design heuristic** — should be promoted to `design/gdd/game-pillars.md` as a design tool.
- C-R8 "visited = 黑色（保留探索感）" is a great explicit non-feature. Don't show un-explored minimap tiles.

### Manual checks deferred
- #16 random-encounter cross-check on ENCOUNTER tile trigger API — verify in `/review-all-gdds`
- #18 npc-terminal cross-check on Terminal node push(TERMINAL) state interaction — verify in `/review-all-gdds`
- #21 save-load cross-check on current_room_id + player_pos serialization — verify in `/review-all-gdds`
- #24 minimap cross-check on visited_tiles array schema — verify in `/review-all-gdds` once authored
- #17 doors-locks cross-check on Door node 4 lock types + AMMO consumption — verify in `/review-all-gdds` once authored
- Rec #7 cross-doc reconciliation with #11 weapon-ammo TOTAL_WEAPON_TYPES_AVAILABLE = 12 — verify in `/review-all-gdds`

### Post-Approval
- Status in `systems-index.md`: Approved (line 37 updated, Level/Dungeon). **Feature layer 3/4 complete (Weapon+Ammo combined + Level/Dungeon).**
- GDD frontmatter: updated to `Status: Approved` + `Review Verdict: APPROVED (first review 2026-06-12, lean)`
- Open Questions: Rec #1, #4, #5, #6, #7 appended for tracking. Rec #2, #3 deferred to Architecture phase.
- Tracking: **8/12 MVP GDDs approved** (Foundation 5 + Core 1 + Feature Weapon/Ammo + Level/Dungeon 2). 4 remaining GDDs in pipeline (2 Feature + 2 Presentation).
- Next pipeline step: Phase 1i — `/design-review random-encounter.md` (Feature layer, encounter tile trigger + battle scene switch, S scope).
