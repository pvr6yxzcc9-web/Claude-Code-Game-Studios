# Review Log — NPC / 终端日志 (NPC / Terminal Logs)

> Source: `design/gdd/npc-terminal.md`
> Review mode: solo (per `production/review-mode.txt`)
> Analyst depth: lean (per `--depth lean`)
> **Prototype-validated:** no (Pillar 4 narrative content is hand-authored; no prototype for "terminal log → story fragment" loop)

---

## Review — 2026-06-12 (first review) — Verdict: APPROVED

**Scope signal:** S
**Specialists consulted:** None (lean mode, per user direction)
**Analyst:** main session
**Blocking items:** 0 | **Recommended:** 6 | **Nice-to-have:** 8

### Summary

First review of the NPC/Terminal GDD (272 lines, 8 required sections + Visual/Audio + UI + Dependencies bonus sections). 5 invariants, 4 formulas, 9 edge cases, 6 tuning knobs, 14 acceptance criteria. Carries **Pillar 4 (真相是收集的结果)** through the terminal log mechanic + story fragment signal. The 5-state terminal lifecycle is exemplary. C-R3 "emit signal, not direct coupling" is the canonical solution to the systems-index circular dependency warning (NPC #18 ↔ Story Map #19). Cross-doc bidirectional constraints to all 4 Foundation GDDs + #15 Level-Dungeon (Approved 2026-06-12) verified clean. **The 6th GDD in a row with a bidirectional cross-doc constraints table — project standard fully established.**

**Prior verdict resolved:** N/A (first review)

### Key decisions reaffirmed
- **Lean mode accepted** — no specialist agents spawned. The GDD is small (S scope) and the Pillar 4 narrative is hand-authored content (not prototype-validated).
- **5 invariants cleanly define the contract**: 1 log = 1 resource (C-R1), push(TERMINAL) routing (C-R2), emit signal pattern (C-R3), 1-unlock (C-R4), NPC optional (C-R5).
- **C-R3 "emit signal, not direct coupling"** is the canonical solution to the systems-index circular dependency warning (NPC #18 ↔ Story Map #19). The Story Map GDD will be authored in VS phase and can consume this signal.
- **5-state terminal lifecycle (UNREAD/READ/REPLAYING/SKIPPING/COMPLETED)** is clean. REPLAYING + COMPLETED distinction is important (allows re-viewing without re-unlocking).
- **F1 chapter 1 fragment distribution** = "1 NPC + 3 terminals, 其中 2 terminals 共用 1 碎片" = 4 fragments from 7 sources. The "shared fragment" concept is a strong design tool but needs formalization (Rec #2).
- **C-R4 "1 unlock per fragment"** is correct but needs explicit race-condition handling (Rec #3).
- **F2 read time estimate with 中文 200-400 字/分钟** is localization-aware and thoughtful.
- **14 ACs** is appropriate for S scope. AC-12 (TERMINAL from BATTLE rejected) is exemplary state-legality validation. AC-9/10/11 (resource self-healing) are essential defensive testing.
- **MVP 1 NPC is the right scoping** (per game concept "first-time developer, writing risk"). NPCData not in #1 Resource 9 subtypes — needs cross-doc reconciliation (Rec #1).
- **6th GDD in a row** with bidirectional cross-doc constraints table. Project standard fully established.
- **All 5 Open Questions have `当前定` resolutions** — no orphaned design questions.

### Recommended (non-blocking) follow-ups
1. **Rec #1** (NPCData is referenced in C-R5 but not declared in #1 Resource schema): #1 Resource 9 subtypes = WeaponData / AmmoData / EnemyData / MechPartData / ItemData / EffectData / DropEntry / TerminalLogData / StoryFragmentData / RegionData. **NPCData is NOT in this list.** The GDD says `npc_data: NPCData` exists. Either: (a) NPCData needs to be added to #1 Resource schema (10th subtype), OR (b) NPCs are stored as a `TerminalLogData` with `npc_flag: bool` extension. **Recommended: add NPCData as 10th subtype in #1 Resource**. **Flag to #1 Resource Open Questions for `/review-all-gdds` reconciliation. Appended here for tracking.**
2. **Rec #2** (F1 "2 terminals 共用 1 碎片" is a new concept not declared as a C-R): Recommend: add C-R6 "Fragment 共享规则 — 多个 terminal 可共享同一 fragment (e.g., 1 碎片 = 2 个 terminal 都触发时 unlock)" OR "每 fragment 唯一对应 1 terminal/NPC (1:1 strict)". **Appended to Open Questions for tracking.**
3. **Rec #3** (C-R4 "1 unlock" + E7 race condition): Recommend: "unlock = `MetaState.unlocked_fragments.contains(fragment.id) == false`" check (already implicit via #1 MetaState). Add explicit AC: "AC-7b: GIVEN player reads terminal + fragment already in MetaState.unlocked WHEN 测 THEN NO new fragment in unlocked_fragments (no double-count)." **Appended to Open Questions for tracking.**
4. **Rec #4** (E9 多语言 MVP 不实现 — needs codepath safety): Recommend: `LocalizationKey: StringName` field (empty = "no localization planned, use body_text") to make future migration easy. **Deferred to VS phase (no MVP block).**
5. **Rec #5** (5 states 缺 "interrupted" / "replay_completed"): Low priority. **Deferred to architecture phase.**
6. **Rec #6** (E8 录音 0.5s 死亡 — audio stop responsibility): E8 says "音频停止 + 玩家死亡流". Which system stops audio? `GameStateMachine` or `AudioManager`? Recommend: explicit "AudioManager.stop_all()" called by #3 死亡流 transition, not by NPC GDD. **Appended to Open Questions for tracking.**

### Nice-to-have
- 5-state terminal lifecycle is exemplary. Replicate in `hud.md` for any UI state.
- C-R3's "emit signal, not direct coupling" pattern is the canonical solution for circular dependencies. Promote to `docs/architecture/patterns.md` as the "interface-decoupling" pattern.
- 6th GDD in a row with cross-doc bidirectional constraints table — project standard fully established.
- C-R4 "1 unlock per fragment" + C-R2 "禁止绕过状态机" are both critical architectural invariants. Promote to ADR collection.
- F1 "1 NPC + 3 terminals + 2 shared → 4 fragments" demonstrates careful Pillar 4 pacing. The "shared fragment" mechanic is a strong design tool — would be a great design pillar addition: "Some fragments require multiple logs to unlock".
- AC-12 (TERMINAL from BATTLE rejected) is a great state-legality AC. Replicate in all push-based state transitions.
- E6 silent rejection (not error popup) is a thoughtful UX choice — player is in BATTLE so any modal would be jarring.
- F2 read time estimate with 中文 200-400 字/分钟 is a thoughtful localization-aware formula. Replicate for any text-content system.

### Manual checks deferred
- #21 save-load cross-check on `unlocked_fragments: Array[StringName]` serialization — verify in `/review-all-gdds` (Phase 1l)
- #19 story-map (VS) cross-check on `story_fragment_unlocked` signal consumption — defer until VS authoring
- #20 codex (VS) cross-check on `terminal_log_read` signal consumption — defer until VS authoring
- #1 Resource Rec #1 cross-doc reconciliation (NPCData as 10th subtype) — verify in `/review-all-gdds`

### Post-Approval
- Status in `systems-index.md`: Approved (line 40 updated, NPC/Terminal). **Feature layer 4/4 complete (Weapon+Ammo + Level/Dungeon + Random Encounter + NPC/Terminal = 4 GDDs in 4 layers).** Foundation 5/5 + Core 1/1 = 6. Feature 4/4 = 4. Total = 10.
- GDD frontmatter: updated to `Status: Approved` + `Review Verdict: APPROVED (first review 2026-06-12, lean)`
- Open Questions: Rec #1 (NPCData cross-doc), #2 (shared fragment C-R6), #3 (unlock race AC-7b), #6 (audio stop responsibility) appended for tracking. Rec #4, #5 deferred.
- Tracking: **10/12 MVP GDDs approved**. 2 remaining GDDs in pipeline (2 Presentation HUD + SaveLoad).
- Next pipeline step: Phase 1k — `/design-review hud.md` (Presentation layer, M scope, all Feature consumers converge here).
