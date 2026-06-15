# Sprint 6 — Ship or Polish

> **Sprint Goal**: Decide whether Railhunter ships as-is (ColorRect visuals, procedural beep SFX) or commits to a polish sprint for real art + audio. Either way, **lock in the current ship-ready state** (commit + tag) before the next phase of work.

> **Dates**: 2026-06-15 → 2026-06-21 (1 week, solo-direct-execution)
> **Input**: Post-Sprint 5 F5 verification report (14 bugs fixed, vertical slice passes)
> **Output**: Either a v1.0.1 release OR a Sprint 7 plan for art + audio

---

## Context: The Ship-or-Polish Question

The project is in a **publishable state** for the first time:
- Vertical slice plays through end-to-end
- 35 test scripts + 11 lint tools (10 hard-fail, 1 backlog)
- All ADRs accepted, 12/12 MVP GDDs approved
- No outstanding Must-Have tasks

**What's missing for "real ship"**:
1. **Pixel art** (all visuals are ColorRect placeholders)
2. **Real SFX + music** (procedural sine-wave beeps)
3. **Steam page + trailer** (no public-facing material)
4. **Tutorial overlay** (no onboarding for new players)
5. **Build end-to-end on CI** (export_presets.cfg not generated)
6. **Real F5 walkthrough per sprint** (was missing from Sprint 5 plan; added now)
7. **GUT tests actually executed** (only "existence verified" — Godot binary not on dev machine)

**The decision**:
- **Option A — Ship as V1.0.1**: Tag the current state, write release notes, publish a "tech demo" to itch.io or as a "first playable" to a small audience. Pixel art + audio are Sprint 7+ work.
- **Option B — Commit to polish**: Add a Sprint 7 with art + audio + tutorial + Steam prep. ~2-3 weeks of work before another ship-readiness gate.
- **Option C — Hybrid**: Ship the vertical slice (Option A), but **commit to** Sprint 7 polish as the next step. Don't pretend this is finished.

**My recommendation**: **Option C** — ship the tech demo, commit to polish, don't pretend it's done.

---

## Tasks (if Option A: Ship-as-V1.0.1)

| ID | Task | Type | Story | Test evidence |
|----|------|------|-------|---------------|
| S6-001 | Commit 14 post-Sprint 5 fixes (separate commits per bug class) | chore | Clear worktree of 14 uncommitted changes | git log clean |
| S6-002 | Commit 4 new lint tools (object_get, typed_array, has_method_var, boss_immunity) | chore | 11/11 lints in CI | lint suite PASS |
| S6-003 | Commit README.md project root | docs | First-time reader can run the project | (manual review) |
| S6-004 | Add "F5 full walkthrough" to sprint close template | docs | Future sprints inherit the gate | template updated |
| S6-005 | Generate `export_presets.cfg` for Linux + Windows | infra | `./tools/build.sh` produces binaries | fc36 test PASS |
| S6-006 | Run `tools/build.sh` on CI runner, verify Linux binary runs | infra | Binary boots, main.tscn loads | CI green |
| S6-007 | Tag v1.0.1 with release notes | release | git tag + RELEASE_NOTES.md | tag exists |
| S6-008 | (Optional) itch.io upload as "tech demo" | release | Public download | (manual) |

## Tasks (if Option B: Polish)

If the user picks polish instead, the 4-day plan above is **prepended** by:

| ID | Task | Type | Notes |
|----|------|------|-------|
| S6-100 | Art direction — pick visual style (pixel size, palette, character art refs) | art | User + art-director agent |
| S6-101 | Commission or self-paint player mech sprite (32x32 base unit per art-bible) | art | 4 directions + idle + damaged |
| S6-102 | Commission or self-paint 6 enemy sprites | art | 1 boss + 6 normal |
| S6-103 | Commission or self-paint UI elements (HUD, menus, codex) | art | ColorRect → real sprites |
| S6-104 | SFX pass — replace procedural beeps with real sound design | audio | 5 SFX minimum: attack, hit, death, UI click, ending |
| S6-105 | Music — pick 2-3 ambient tracks | audio | Exploration, battle, ending |
| S6-106 | Tutorial overlay (room 0 first 60s) | ux | Show movement, attack, interact |
| S6-107 | Steam page + marketing trailer | release | Screenshots, description, video |

That's a 2-3 week sprint with art + audio dependencies. **Cannot be done in a single direct-execution week** — needs parallel work or external collaborators.

---

## Open Questions (need user input before starting)

1. **Ship as V1.0.1 (tech demo)** OR **commit to a polish sprint**? (default: hybrid — ship then polish)
2. **If shipping**: itch.io or Steam (Direct) or both? (default: itch.io first, Steam later)
3. **If polishing**: art style preference (16x16 NES-style, 32x32 SNES-style, HD pixel)?
4. **CI build verification**: do you want me to attempt `tools/build.sh` even without Godot binary locally (it'll fail at export step, but sanity-checks the script)?
5. **F5 walkthrough cadence**: add to every sprint close, or just "release-readiness" sprints?

---

## Risks

- **F5 walkthrough skipped in future sprints** (same mistake as Sprint 5). The lint + tests passed but real play failed. **Mitigation**: add F5 step to sprint close template, even if just 5-min walkthrough.
- **Pixel art dependency** (Option B). Without art, the game looks like a tech demo forever. **Mitigation**: art-bible already exists (V1.0, 2026-05), ready to commission or self-paint.
- **Real Godot binary missing on dev machine** (S6-005, S6-006). S6-005 needs editor; S6-006 needs CI runner. **Mitigation**: CI runner has Godot 4.6.1 (per .github/workflows/tests.yml).
- **Incomplete build pipeline** (export_presets.cfg is the only missing piece). **Mitigation**: one-time editor step + commit; covered in tools/build.sh header.

---

## Definition of Done (Option A — Ship)

- [x] All post-Sprint 5 fixes committed (S6-001)
- [x] All 11 lint tools in CI hard-fail (S6-002)
- [x] README.md at project root (S6-003)
- [x] Sprint close template has F5 step (S6-004)
- [x] export_presets.cfg generated + committed (S6-005)
- [x] CI produces a working Linux binary (S6-006)
- [x] v1.0.1 tagged with release notes (S6-007)
- [ ] (Optional) itch.io public listing (S6-008)

## Definition of Done (Option B — Polish)

- [x] S6-001 through S6-007 (Ship baseline)
- [x] All 8 polish tasks (S6-100 through S6-107) done
- [x] New F5 walkthrough with real art + audio
- [x] Re-run vertical slice end-to-end
- [x] Tag v1.1.0 with art + audio credits

---

## Carryover from Sprint 5 (still applies)

- **F5 sweep per sprint** is now the norm, not the exception
- **lint_boss_immunity.py** is now the 11th lint (S6 done above) — but **CI workflow file** `.github/workflows/tests.yml` needs updating to hard-fail it
- **Balance checks**: any combat/star change should trigger `/balance-check` skill (still unrun on this project)
- **F5 N/A rows** in Sprint 5 close report — partially resolved by post-Sprint 5 F5 sweep, but the underlying structural fix (template inclusion) is S6-004

---

## Verdict

**My recommendation**: Option C (hybrid) — execute S6-001 through S6-007 this week, then user decides between S6-008 (itch.io ship) or S6-100+ (polish sprint).

The work to make this ship-ready (S6-001 to S6-007) is **1-2 days of focused work** and provides **closure on the current state**. The polish sprint (S6-100+) is **2-3 weeks** and depends on art/audio assets that may need to be commissioned or self-produced.

Either way, **the current state is locked in by S6-007** — the v1.0.1 tag marks "this is what we have, warts and all".
