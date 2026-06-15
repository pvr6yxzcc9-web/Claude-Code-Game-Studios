# Review Log — 碰撞检测 (Collision)

> Source: `design/gdd/collision.md`
> Review mode: solo (per `production/review-mode.txt`)
> Analyst depth: lean (per `--depth lean`)

---

## Review — 2026-06-12 (first review) — Verdict: APPROVED

**Scope signal:** M
**Specialists consulted:** None (lean mode, per user direction)
**Analyst:** main session
**Blocking items:** 0 | **Recommended:** 7 | **Nice-to-have:** 4

### Summary

First review of the Collision GDD (313 lines, 8 required sections + Visual/Audio + UI bonus sections). 6 invariants, 4 formulas, 12 edge cases, 10 tuning knobs, 16 acceptance criteria. All cross-doc bidirectional constraints to `resource-data.md` / `game-state-machine.md` / `player-input.md` (all Approved 2026-06-12) verified. GDD is structurally clean — no blockers. **The cleanest Foundation-layer GDD yet**: 6 invariants (one less than typical, no fluff), 8×8 collision matrix exhaustive, 12 edge cases thorough, 16 ACs highest count of any Foundation GDD. AC-15 (linter detects `CollisionMatrixMismatch`) is exemplary — startup-time correctness check, not runtime crash.

**Prior verdict resolved:** N/A (first review)

### Key decisions reaffirmed
- **Lean mode accepted** — no specialist agents spawned. Cross-doc consistency to 3 already-Approved GDDs is sufficient inline. Godot 4.6 API flag (`continuous_cd`) tracked as Rec #1 (verify at implementation time).
- **6 invariants** (vs typical 7) is the right count — each is directly enforceable (layer count, matrix-in-GDD, signal routing, friendly fire, shape choice, autoload). No fluff invariants.
- **8×8 collision matrix is exhaustive and correct** — all 64 cells specified with explicit "❌ (C-R4)" annotations where the rule comes from an invariant. This is the right discipline.
- **State-collision-profile mechanism** (atomic toggle on transition) is the correct atom for game state transitions. Solves the BATTLE-cleanup / ENCOUNTER-disabling problem cleanly.
- **Signal-routed events (C-R3)** with named signals + weak ref is correct for Area2D nodes that may be freed during state transitions. Direct Area2D signal subscription would be a memory-safety hazard.
- **CCD (Edge case #10, AC-14)** correctly addresses tunneling at high bullet speeds. The 5000 px/s test condition is precise.
- **AOE damage stacking (Edge case #5)** is correctly deferred to battle-core-loop.md but needs a "Worst Case Stacking" note (Rec #4).
- **AC-15 (linter detects `CollisionMatrixMismatch`)** is the same pattern as `game-state-machine.md`'s autoload order check — startup-time correctness, not runtime crash. Exemplary.

### Recommended (non-blocking) follow-ups
1. **Rec #1** (Godot 4.6 `continuous_cd` API): verify against `docs/engine-reference/godot/breaking-changes.md` — 4.5+ introduced changes to swept collision for 2D bodies. Implementation-time check.
2. **Rec #2** (BATTLE → ENCOUNTER signal race): add AC-12b "no `player_entered_encounter_tile` during BATTLE transition (per state-collision-profile atomicity)." **Appended to Open Questions for tracking.**
3. **Rec #3** ("撞墙摇头" animation ownership): clarify the cross-system handoff — CollisionManager emits `body_entered_wall` → Player CharacterBody2D subscribes → triggers `mech_head_shake` animation.
4. **Rec #4** (AOE damage stacking worst case): add a note in F2: "if N AOE areas overlap, total damage = N × damage_per_tick. Battle GDD must budget for N=2-3 reasonable, N≥4 unreasonable."
5. **Rec #5** (Linter check dev ergonomics): add a `collision_linter_severity` knob — log in dev, fail-fast in release.
6. **Rec #6** (Knob dedup): `INTERACTABLE_AREA_RADIUS_PX` is dead config (= `INTERACT_RADIUS_PX`); remove. **Appended to Open Questions for tracking.**
7. **Rec #7** (Cross-doc API verification in `/review-all-gdds`): verify 6 named signals against downstream GDDs.

### Nice-to-have
- 2D ASCII diagram of 8 layers with brief use-case icons (wall, mech, enemy, bullet, terminal, encounter, fire).
- AC-13 (60 enemies + 200 bullets) is a great "stress test" pattern — replicate in battle-core-loop.md.
- Consider a "collision budget" concept for Vertical Slice: total active Area2D nodes per scene.
- `continuous_cd` boolean per bullet resource is nice data-driven choice — could mention in Resource/Data cross-doc.

### Manual checks deferred
- `level-dungeon.md` cross-check on `register_layer_profile(level_id, ...)` API — verify in `/review-all-gdds`.
- `random-encounter.md` cross-check on `player_entered_encounter_tile` handler — verify in `/review-all-gdds`.
- `battle-core-loop.md` cross-check on `bullet_hit` + `damage_area_tick` handlers — verify in `/review-all-gdds`.
- `npc-terminal.md` cross-check on `player_near_terminal` handler — verify in `/review-all-gadss`.
- Godot 4.6 `continuous_cd` post-cutoff behavior — verify at implementation time.

### Post-Approval
- Status in `systems-index.md`: Approved (line 27 updated). **Foundation layer 5/5 complete.**
- GDD frontmatter: updated to `Status: Approved` + `Review Verdict: APPROVED (first review 2026-06-12, lean)`
- Open Questions: Rec #2 (BATTLE transition ENCOUNTER signal race) + Rec #6 (knob dedup) appended for tracking
- Tracking: **5/12 MVP GDDs approved** (Resource/Data, Player Input, Game State Machine, Camera, Collision). 7 remaining GDDs in pipeline.
- Next pipeline step: Phase 1f — `/design-review battle-core-loop.md` (Core layer — highest risk system, prototype-validated).
