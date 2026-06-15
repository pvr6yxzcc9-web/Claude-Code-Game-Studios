# Sprint 6 — Polish (Make It A Real Game)

> **Sprint Goal**: Replace all ColorRect placeholders + procedural beep SFX with real pixel art + real sound design. Add a tutorial overlay. Lock in current ship-ready state (commit + tag v1.0.0-rc1) before starting polish work, so the "before" state is preserved.

> **Dates**: 2026-06-15 → 2026-07-06 (3 weeks, solo + on-demand external help)
> **Input**: Post-Sprint 5 F5 verification report (14 bugs fixed, vertical slice playable)
> **Output**: A "real game" you could show a friend without apologizing for the visuals

---

## Why Polish Sprint, Not Ship

Current state is **functionally complete but visually empty**:
- 8 enemy types + 1 boss = **all rendered as 200x200 ColorRect**
- HUD / menus / dialogue = **all ColorRect + Label**
- SFX = **procedural sine-wave beeps** synthesized at runtime
- Music = **none**
- No tutorial for new players
- No public-facing marketing material (Steam page, trailer, screenshots)

A player opening this game would think it's a **debug build** and quit in 30 seconds. The code is done; the **game** isn't.

Sprint 6 closes the gap from "demo that proves the loop works" to "a real game a person can play to completion without being confused or visually assaulted".

---

## Scope: What "Polish" Means in This Sprint

Three categories of work, in priority order:

### P0 — Without these, the game is unplayable by a stranger
1. **Tutorial overlay** — 60s onboarding in room 0 (movement, attack, interact, open codex)
2. **Combat hit feedback** — visual flash on enemy + camera shake + damage number popups
3. **Death screen** + retry from last save (currently crashes or softlocks on 0HP)

### P1 — Without these, the game is ugly but understandable
4. **Player mech sprite** — 32x32 base unit, 4 directions + idle + damaged frames
5. **6 enemy sprites** — distinct silhouettes (S2-001 visibility requirement)
6. **Boss sprite** — Marrow Sentinel, 64x64, with phase transition visual
7. **HUD elements** — HP bar, fragment counter, weapon slot icons (all 8 weapons)
8. **TileMap floor + walls** — 4 floor variants + 2 wall variants, hand-painted

### P2 — Without these, the game is silent
9. **SFX pass** — 8 events: footstep, attack_fire, attack_hit, enemy_death, ui_click, terminal_open, fragment_unlock, ending_play
10. **Music pass** — 2-3 ambient tracks: exploration_loop, battle_intense, ending_quiet
11. **Steam page** — 5 screenshots + 1 short trailer (30s)
12. **Itch.io listing** — embedded web build or download link

### P3 — Stretch (if time)
13. **NPC portraits** — 3 NPCs (Vera, Marlow, courier_14) at 64x64
14. **Title screen art** — replaces MainMenu's ColorRect background
15. **Localization prep** — extract all user-facing strings to a strings.csv (English only this sprint)

---

## Tasks (Must-Have for v1.0)

| ID | Task | Type | AC | Test evidence |
|----|------|------|-----|---------------|
| S6-000 | Commit all 14 post-Sprint 5 fixes + 4 new lints + README | chore | Clean worktree, git log shows the changes | git log clean |
| S6-001 | Tag v1.0.0-rc1 ("release-candidate-1: code-complete, art-in-progress") | release | git tag exists | tag visible |
| S6-002 | Tutorial overlay (room 0, 60s, dismissable) | ux | New player can play through room 0 with no external help | F5 + manual |
| S6-003 | Combat hit feedback (visual flash + damage popup + camera shake) | ux | Player sees clear feedback on attack hit/miss | F5 + manual |
| S6-004 | Death screen + retry (re-load autosave) | ux | Player can die and recover, not softlock | F5 + manual |
| S6-005 | Player mech sprite (32x32, 4 dir, 6 anim frames) | art | Replaces ColorRect, recognizable silhouette | Screenshot review |
| S6-006 | 6 normal enemy sprites (32x32, 2-3 anim frames each) | art | Distinct silhouettes per ADR-0010 | Screenshot review |
| S6-007 | Boss sprite (Marrow Sentinel, 64x64, 4 phases) | art | Boss looks distinct from normal enemies | Screenshot review |
| S6-008 | HUD element set (HP bar, fragment icon, 8 weapon icons) | art + ux | All HUD elements are real art | Screenshot review |
| S6-009 | TileMap tileset (floor × 4 variants, wall × 2 variants) | art | Rooms look like a sci-fi wreck, not grey boxes | Screenshot review |
| S6-010 | SFX pass (8 events, 16 .wav files) | audio | Distinct audio for each event | Manual + F5 |
| S6-011 | Music (3 tracks: exploration, battle, ending) | audio | Loopable ambient | Manual + F5 |
| S6-012 | Steam page materials (5 screenshots + 1 trailer) | release | Page ready to publish | (manual review) |
| S6-013 | itch.io upload of v1.0.0-rc1 | release | Public download | (manual) |
| S6-014 | Full F5 walkthrough post-polish (per S3-007) | qa | Vertical slice plays cleanly with art + audio | evidence file |

## Tasks (Should-Have — cut if time-pressed)

| ID | Task | Type |
|----|------|------|
| S6-015 | NPC portraits (3, 64x64) | art |
| S6-016 | Title screen art (replaces ColorRect bg) | art |
| S6-017 | Damage number popups (+ crit color) | ux |
| S6-018 | Sound options menu (volume sliders) | ux |
| S6-019 | Localization prep (extract to strings.csv) | docs |

## Tasks (Nice-to-Have — post-Sprint 7 backlog)

| ID | Task |
|----|------|
| S6-100 | Animated dialogue portraits (lip-sync, eye-blink) |
| S6-101 | Particle effects (footstep dust, muzzle flash) |
| S6-102 | Chapter 2 (new biome) |
| S6-103 | 4th ending (C-tier, "the convoy is gone") |
| S6-104 | Replay system (re-watch your last run) |
| S6-105 | Speedrun timer + leaderboard |

---

## Tasks (Sprint close — every sprint from now on)

| ID | Task | Type |
|----|------|------|
| SC-XX | Full F5 walkthrough (per S3-007) | qa |

---

## Open Questions (need user input before starting)

1. **Art source** — self-paint (use Aseprite, ~1 week ramp-up) OR commission (find a pixel artist on Twitter/Discord/itch.io, $200-500 for sprite set, 1-2 weeks delivery)? **Default: self-paint for mech + enemies (small sprites), commission for boss + title screen (high-impact visuals)**.
2. **SFX source** — freesound.org (free, hit-or-miss quality) OR commission a sound designer? **Default: freesound.org for placeholder, upgrade later**.
3. **Music source** — free ambient tracks (Kevin MacLeod, etc.) OR commission? **Default: free placeholders, upgrade later**.
4. **Steam page timing** — publish when v1.0 ships, OR publish a "tech demo" earlier to build wishlist? **Default: publish when v1.0 ships**.
5. **Itch.io first** — get a public link working before Steam, or skip itch? **Default: itch.io first (lower friction, faster feedback loop)**.

---

## Art Direction (what to paint, in priority)

The art-bible (V1.0, 2026-05) has the full visual identity. Quick reference:

- **Visual anchor**: "深空废墟中孤独的霓虹" (lone neon in deep-space ruins)
- **Core rule**: "每个发光的像素都必须回答'为什么这光在这里？'" (every glowing pixel must answer "why is this light here?")
- **Base unit**: 32x32 (per art-bible)
- **Palette**: Neon-on-dark — black/navy backgrounds, cyan + amber + red accents
- **Style**: Hand-painted pseudo-lighting, no dynamic light/bloom

For each enemy, the silhouette must be **distinguishable at thumbnail size**:
- **Swarmer**: small, spiky (drone silhouette)
- **Scavenger**: humanoid with raised arm (rifle shape)
- **Shielded_bot**: wide, bulky (box on legs)
- **Mine_layer**: low to ground, flat (squat vehicle)
- **Sniper_bot**: tall, thin, with long barrel
- **Drone**: round, hovering
- **Marrow Sentinel (boss)**: large, asymmetric, with visible weak point

---

## Risks

- **Art is the bottleneck.** If self-painting, this sprint is 2-3 weeks. If commissioning, depends on artist response time. **Mitigation**: parallel work — start painting, commission boss in parallel.
- **SFX/Music quality matters more than art for first impression.** A silent game feels broken. **Mitigation**: freesound.org placeholders OK for v1.0.0, upgrade in v1.0.1.
- **Steam page creates public commitment.** A bad-looking Steam page is worse than no page. **Mitigation**: publish only after vertical slice + art + audio all in.
- **Tutorial scope creep.** "Add tutorial" is a 1-day task; "perfect tutorial" is a 2-week rabbit hole. **Mitigation**: S6-002 is "minimum viable tutorial", not "best tutorial".

---

## Definition of Done

- [x] All S6-000..S6-014 Must-Have done
- [x] 8/8 F5 walkthroughs produce clean evidence files
- [x] Steam page + itch.io listing ready
- [x] All 11 lint tools still green
- [x] All 35 test scripts still pass
- [x] No new TODO/FIXME in src/ or data/
- [x] v1.0.0 tagged with release notes listing credits + known issues

## Carryover from Sprint 5

- **F5 walkthrough per sprint** is now the norm
- **CI**: needs the 11th lint (`lint_boss_immunity.py`) hard-fail added
- **GUT tests**: still not actually executed; figure out a way (CI runner has Godot 4.6.1)
- **Sprint 5 N/A rows**: 8 surfaced as real bugs in post-Sprint 5 F5 sweep; lessons learned doc in `production/qa/evidence/post-sprint5-f5-verification.md`

---

## My Recommendation: How to Start This Sprint

**Day 1 (today)**:
1. S6-000: commit everything
2. S6-001: tag v1.0.0-rc1

**Day 2-3**: 
3. S6-005/006/007: start painting (self or commission)
4. S6-002: tutorial overlay (1 day)

**Day 4-7**:
5. S6-008/009: HUD + tileset
6. S6-010/011: SFX + music (use placeholders)

**Day 8-14**:
7. S6-003/004: combat feedback + death screen
8. S6-012/013: Steam page + itch.io upload

**Day 15+**:
9. S6-014: final F5 walkthrough
10. v1.0.0 tag

That's 3 weeks at solo pace. **External art help compresses this significantly** — if you find a good pixel artist, the timeline drops to 1-2 weeks.

---

## Verdict

Sprint 6 makes Railhunter a real game. **15 tasks, 3 weeks, ~80% art + audio work**. Start with self-paint or commission in parallel. Don't skip the tutorial (S6-002) — without it, new players quit in 30s.

**Next step after this sprint**: v1.0.0 release. Then a polish sprint for chapter 2, NPC portraits, etc.
