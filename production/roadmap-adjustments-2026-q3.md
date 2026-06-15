# Roadmap Adjustments — 2026 Q3

> **Status**: Active
> **Created**: 2026-06-15
> **Last Updated**: 2026-06-15
> **Owner**: suxiu (solo dev + Claude as on-demand help)
> **Purpose**: Honest reflection on the 5-sprint plan. The original `roadmap-2026-q3.md` made optimistic estimates. This document identifies the over-capacity / under-estimated areas and proposes concrete adjustments.

---

## 1. Why This Document Exists

The original `roadmap-2026-q3.md` was authored in 1 session alongside the 4 GDDs and 5 sprint task lists. The estimates are **optimistic** — they assume best-case execution, no bugs, no rework, and the user has 45 hours/week to commit.

This document:
1. Identifies the **3 critical over-capacity / under-estimation issues**
2. Proposes **concrete adjustments** to fix them
3. Suggests **realistic total timeline** (likely 22-26 weeks, not 18)
4. Recommends a **risk-mitigation strategy** for the user

The user should read this before starting Sprint 7.

---

## 2. Critical Issue 1: Sprint 7 is Over-Capacity

**Original estimate**: Sprint 7 has 12 Must-Have stories, totaling **20.5 days** of work, with **16.8 days** of capacity (3 weeks × 80% utilization). This is a **3.7-day over-capacity**.

**The problem**: I described Sprint 7 as "at capacity" in the original sprint-07 doc, but **it's actually over-capacity**. The risk of slipping is high.

**Why this is especially bad**: Sprint 7 is the **foundation** for everything else. If Sprint 7 slips by 1 week, Sprint 8 cannot start (it needs the party system). A cascading delay across all 5 sprints.

**Proposed Adjustment (3 options)**:

| Option | Approach | Trade-off |
|--------|----------|-----------|
| **A: Extend Sprint 7 to 4 weeks** | Add 1 more week of capacity (16.8 → 22.4 days). All 12 stories fit. | Pushes the total timeline to 19 weeks (~5 months). |
| **B: Cut 4 stories from Sprint 7** | Move S7-013 (pilot-specific dialogue), S7-014 (combo tutorials), S7-015 (XP UI), S7-016 (in-combat Mech Bay) to a later sprint. Saves ~2 days. | Sprint 7 is still over-capacity by ~1.5 days. Some features deferred. |
| **C: Hire external help** | Bring in a 2nd programmer (via Fiverr / Upwork / a friend) for the L stories (S7-001, S7-002). Cost: $500-2000. | Fastest. But adds cost + coordination overhead. |

**Recommendation**: **Option A** (extend Sprint 7 to 4 weeks). It's the safest — no risk of feature loss, no extra cost, just more time. Total timeline becomes 19 weeks (~5 months), which is still reasonable.

---

## 3. Critical Issue 2: Sprints 10 + 11 Are Dangerously Tight

**Original estimates**:
- Sprint 10: 19 Must-Have stories, **~21 days** estimated, **22.4 days** capacity (4 weeks × 80%). Buffer: 1.4 days.
- Sprint 11: 20 Must-Have stories, **~17 days** estimated, **16.8 days** capacity. Buffer: 0.2 days.

**The problem**: Both sprints are **at the edge of capacity**. A single 1-day slip in a critical story (e.g., S10-013 Creator chamber, S11-007 Bounty #2 plot-required) cascades.

**Why this is especially bad**:
- Sprint 10 is the **climax** — quality bar is highest. Rushing it produces a bad ending sequence.
- Sprint 11 contains **Bounty #2**, which is plot-required for Sat-2 → Sat-3 transition. If Bounty #2 slips, the game is broken past Sat-2.

**Proposed Adjustment**:

| Sprint | Original | Adjusted | Reason |
|--------|----------|----------|--------|
| Sprint 10 | 4 weeks (22.4 days capacity) | **5 weeks (28 days capacity)** | Add 1 more week for sprint 10's climax work. Pushes total to 20 weeks. |
| Sprint 11 | 3 weeks (16.8 days capacity) | **4 weeks (22.4 days capacity)** | Add 1 more week for sprint 11's bounty + racing. Pushes total to 21 weeks. |

**Recommendation**: Extend both Sprints 10 and 11 by 1 week each. Total timeline: 21 weeks (~5.5 months).

---

## 4. Critical Issue 3: Missing "Integration + Bug Fix" Time

**The problem**: My sprint task lists have:
- Wave 1-4: implementation
- Wave 5: tests + verification (1-2 days)
- **NO "integration + bug fix" buffer**

In real game development, **20-30% of sprint time is spent fixing integration bugs** (not just unit tests, but actual playtest issues found via F5). My estimates didn't account for this.

**Example scenarios**:
- After Sprint 8 ships, the user F5s the full Ch7-9 playthrough and finds a soft-lock in Ch9 Room 7. Takes 1-2 days to fix.
- After Sprint 10 ships, the user F5s the 4 endings and finds that Ending C's "Transcend" option doesn't show correctly. Takes 1 day to fix.
- After Sprint 11 ships, the user F5s Bounty #2 and finds that failing it doesn't trigger the Sat-2 → Sat-3 transition correctly. Takes 2 days to fix.

**Proposed Adjustment**: Add a **dedicated "Integration + Bug Fix" week** at the end of each major content sprint (Sprint 8, 9, 10, 11). The week is reserved for F5 + bug fixing, not for new features.

| Sprint | Original | Adjusted (with Integration Week) |
|--------|----------|-----------------------------------|
| Sprint 8 | 3 weeks (16.8 days) | 3 weeks + 1 week integration = 4 weeks (~22.4 days) |
| Sprint 9 | 3 weeks (16.8 days) | 3 weeks + 1 week integration = 4 weeks (~22.4 days) |
| Sprint 10 | 4 weeks (22.4 days) | 4 weeks + 1 week integration = 5 weeks (~28 days) |
| Sprint 11 | 3 weeks (16.8 days) | 3 weeks + 1 week integration = 4 weeks (~22.4 days) |

**Cumulative Effect**: Total timeline = 5 weeks (S7) + 4 weeks (S8) + 4 weeks (S9) + 5 weeks (S10) + 4 weeks (S11) = **22 weeks (~5.5 months)**.

---

## 5. Revised Total Timeline

| Sprint | Original | Revised | Reason |
|--------|----------|---------|--------|
| Sprint 7 | 3 weeks | **4 weeks** | Over-capacity; foundation work |
| Sprint 8 | 3 weeks | **4 weeks** | + 1 week integration/bug fix |
| Sprint 9 | 3 weeks | **4 weeks** | + 1 week integration/bug fix |
| Sprint 10 | 4 weeks | **5 weeks** | + 1 week integration/bug fix; climax work |
| Sprint 11 | 3 weeks | **4 weeks** | + 1 week integration/bug fix |
| **Total** | **18 weeks** | **22 weeks** | **+4 weeks (22% increase)** |

**Total elapsed**: 2026-06-15 → **2026-11-15** (~5.5 months, vs the original 4.5 months).

---

## 6. Other Adjustments (Minor)

### 6.1 Single-Specialist Bottleneck

**Issue**: My estimates assume 1 godot-gdscript-specialist can do the L stories (3 days each) on their own. In reality, large refactors benefit from **2 specialists** (one to plan, one to review).

**Adjustment**: For L stories (S7-001, S7-002, S10-004, S10-013, S11-007), consider:
- **Pair programming** with a friend / Fiverr contractor for 1-2 days
- Cost: ~$200-500 per pair session
- Benefit: catches bugs earlier, reduces rework

**Recommendation**: Budget $1000-2000 total for external help on the 5 L stories. This is optional but recommended.

### 6.2 Bilingual Content (EN + ZH)

**Issue**: I haven't planned for **ZH localization** of the new content (Sat-3, 4, 5 NPC dialogue, fragment text, ending scenes). The original `strings.csv` has EN + ZH, but new content must be added in both.

**Adjustment**: Add ~1-2 hours per content sprint for ZH translation. This is small but easy to forget.

**Recommendation**: When writing Sprint 8's content, the writer adds ZH translations to `data/strings.csv` in the same commit. Same for Sprint 9, 10, 11.

### 6.3 Save Format Compatibility Across Sprints

**Issue**: Each sprint adds new state (party state, bounty state, racing state, ending state). If save formats are added in different sprints, the migration gets complex.

**Adjustment**: **Sprint 7 (the foundation)** should establish the **save format versioning scheme** that all subsequent sprints build on. The save file should have a `version` field; on load, migrations upgrade old saves to new versions.

**Recommendation**: Add a **save versioning sub-task to S7-010** (which already exists, but add versioning to it).

### 6.4 User Burnout Risk

**Issue**: 22 weeks × 45 hours/week = 990 hours of solo dev work. This is **a lot**. Burnout is real.

**Adjustment**: The user should plan for **1-2 weeks off** during the 22-week period. Possibly at:
- End of Sprint 9 (after Sat-4) — natural break point
- End of Sprint 11 (after bounty + racing) — before post-launch

**Recommendation**: Build in 1-2 rest weeks. Total timeline becomes **23-24 weeks (~6 months)**.

---

## 7. Revised Sprint Plan Summary

| Sprint | Weeks | Stories | New Tests | Notes |
|--------|-------|---------|-----------|-------|
| Sprint 7 | 4 | 12 | 8 | Extended from 3 weeks (foundation work) |
| Sprint 8 | 4 | 14 | 6 | + 1 week integration/bug fix |
| Sprint 9 | 4 | 15 | 6 | + 1 week integration/bug fix |
| Sprint 10 | 5 | 19 | 6 | + 1 week integration/bug fix; climax |
| Sprint 11 | 4 | 20 | 8 | + 1 week integration/bug fix |
| (rest weeks) | 1-2 | 0 | 0 | User burnout prevention |
| **Total** | **22-24 weeks (~6 months)** | **80 stories** | **34 tests** | |

**Test count progression**: 532 → 540 → 546 → 552 → 558 → 564 (same as before — tests don't change).

**At end of Sprint 11**: 564 tests pass, 5 satellites complete, 4 endings reachable, all 6 bounties and 6 tracks playable.

---

## 8. Risks I Now Realize (After Writing This Document)

1. **5.5 months of solo work is a long time** — life events (job change, family, illness) can derail. The user should plan for **slippage** of 2-4 weeks.
2. **The "shared boss template" assumption in Sprint 11 is unvalidated** — it might not work as cleanly as I described. If the 6 bounties take 1 day each (not 0.5), Sprint 11 slips.
3. **The 5-phase Creator fight (Sprint 10)** is the **single most complex** story in the project. It might take 4 days, not 3. If so, Sprint 10 slips.
4. **The 4 endings' emotional weight** depends on the user's writing quality. If the user is a slow writer, Sprint 10's "4 ending scenes" (1 day each) could take 2 days each. If so, Sprint 10 slips.
5. **The 5,000-HP Creator fight** might be too hard or too easy. The user will need to **playtest extensively** and adjust.

**Mitigation**: All 5 of these risks are addressed by the **"Integration + Bug Fix" weeks** added in §4. The integration weeks give the user time to playtest, find issues, and adjust.

---

## 9. What To Do Now

1. **Read this document** end-to-end (you're here).
2. **Decide on the adjustments**:
   - Do you accept the 22-24 week timeline? (vs 18 weeks)
   - Do you accept the 1-2 rest weeks?
   - Do you want to budget $1000-2000 for external help?
3. **Update `roadmap-2026-q3.md`** with the revised numbers (or note that this adjustments doc supersedes it).
4. **Start Sprint 7** with the revised 4-week scope.

The original `roadmap-2026-q3.md` should be **kept as a record** of the original optimistic plan. This adjustments doc is the **realistic** plan going forward.

---

## 10. Open Questions (need user input)

- **OQ1**: Do you accept the 22-24 week timeline? (vs 18 weeks original)
- **OQ2**: Do you want to budget for external help? ($1000-2000 for L stories)
- **OQ3**: When do you want the 1-2 rest weeks? (Sprint 9 end, Sprint 11 end, or elsewhere?)
- **OQ4**: Do you want to keep the original 18-week timeline and just accept the over-capacity risk? (Sprint 7 slips, cascading delay)
- **OQ5**: Should the user commit to **F5 verification at the end of each sprint** (mandatory, not optional)? Currently: yes, per sprint definitions of done. But in practice, F5 is the first thing skipped under time pressure.

---

*Adjustments complete. The realistic timeline is 22-24 weeks (~6 months), not 18 weeks. The user should plan accordingly.*
