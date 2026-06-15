# Accessibility Requirements (AccessibilityRequirements)

> **Scope**: Railhunter MVP (1 chapter, ~30-45 min playthrough)
> **Platform**: PC (Steam, Epic, itch.io) — per `technical-preferences.md`
> **Audience**: Solo developer + accessibility-conscious players
> **Status**: Active — v1.0, 2026-06-12
> **Reference**: per `architecture.md` §3e, `.claude/docs/technical-preferences.md`, `design/gdd/player-input.md` (cross-doc)

## Purpose

Railhunter commits to **minimum-viable accessibility** for its 3-5 hour experience. The goal is: any player who can read text and click with keyboard or gamepad can complete the game. Full WCAG-AA / XBox Accessibility Guidelines conformance is **out of scope for MVP** but the foundations laid here make that conformance achievable in future.

## 1. Supported Input Methods (per technical-preferences.md)

| Method | Support | Notes |
|--------|---------|-------|
| Keyboard | **Primary (required)** | All gameplay, menus, terminals. WASD movement, Tab navigation, Space/Enter confirm. |
| Mouse | **Primary (required)** | All menus + click-to-interact. Right-click cancels. |
| Gamepad | **Secondary (partial)** | Movement + battle menu only (per ADR-0009). Code-bound actions (terminals, codex search) have keyboard fallback hints. |
| Touch | **Not supported** | Per technical-preferences.md ("Touch Support: None"). |
| Eye tracker / Switch / Voice | **Not supported** | Out of scope for MVP. |
| Remappable bindings | **Not in MVP** | Per player-input.md C-R7. Hard-coded 47 actions. OQ-1 deferred. |

## 2. Visual Accessibility

### 2.1 Color and Contrast

| Requirement | Spec | Source |
|-------------|------|--------|
| Text contrast on HUD | WCAG AA (4.5:1) for body text, AAA (7:1) for damage numbers and HP numbers | Accessibility baseline |
| Damage numbers | Always include a shape/position cue, not color alone (per `#2 F2 refused feedback`) | player-input.md E10 |
| HP bars | Color + length + position | art-bible + hud.md |
| State badge | Text + color (per `#2 UI-2b`) | player-input.md |
| Boss one-shot immunity | Color + animation + position — three independent signals | damage-bounds |
| Colorblind safety | Status colors: red/green must be paired with shape OR label | art-bible accessibility |
| Dark mode | None (per art-bible "deep space" theme is always dark) | n/a |
| Light mode | None | n/a |
| High contrast mode | **Not in MVP** — deferred to Polish | accessibility OQ |

### 2.2 Text

| Requirement | Spec | Source |
|-------------|------|--------|
| Minimum font size | 14 px (HUD body) / 18 px (HP + damage) / 24 px (state badge) | art-bible HUD |
| Font | art-bible HUD font (per control-manifest Global Rules) | art-bible |
| Scalable text | 1.0× / 1.25× / 1.5× scale options (HUD `font_size` setting) | hud.md |
| Language | 中文 (simplified) only for MVP. Localizable hooks deferred. | technical-preferences.md |
| Reading order | Terminal text auto-scrolls; player can press SPACE to advance | npc-terminal.md |
| Dyslexia-friendly font | **Not in MVP** | accessibility OQ |

### 2.3 Visual Effects

| Requirement | Spec | Source |
|-------------|------|--------|
| Screen shake | Has 0.5× UI-shake follow (so UI doesn't dissociate from screen) | camera.md AC-16 |
| Hit-stop | 80-100 ms freeze frame on impact (per player-input.md + camera.md) | impact moments |
| Particle effects | Paired with shape cues, not color alone | art-bible |
| Flash effects | ≤ 2 per second to avoid photosensitive triggers (per WCAG 2.3.1) | accessibility baseline |
| Camera shake | Toggleable in Settings (**deferred to Polish**) | accessibility OQ |

### 2.4 Visual Mode

| Requirement | Spec | Source |
|-------------|------|--------|
| Windowed | 1280×800 minimum, 4K supported | technical-preferences.md |
| Fullscreen | Supported (Godot default) | n/a |
| Borderless windowed | Supported (Godot default) | n/a |
| UI scaling | 1.0× / 1.25× / 1.5× (HUD `font_size` setting) | hud.md |
| Aspect ratio | 16:10 native, supports 16:9 / 21:9 | technical-preferences.md |

## 3. Audio Accessibility

| Requirement | Spec | Source |
|-------------|------|--------|
| Subtitles/captions | All terminal logs display text (per `#18 NPC/终端` C-R3). Voice optional. | npc-terminal.md |
| Important sound cues | Always paired with visual cue (per `#2` G-F4 "acknowledgment is universal") | player-input.md |
| Music volume slider | **Deferred to Polish** | accessibility OQ |
| SFX volume slider | **Deferred to Polish** | accessibility OQ |
| Mono audio output | **Not in MVP** | accessibility OQ |
| Hearing-aid compatibility (HAC) | **Not in MVP** | accessibility OQ |
| Visual-only gameplay (no audio) | **Not supported** — some cues are audio-only (boss one-shot warning chirp) | accessibility OQ |
| Vibration alternative | **Not in MVP** | accessibility OQ |

## 4. Motor Accessibility

| Requirement | Spec | Source |
|-------------|------|--------|
| All gameplay | Reachable with keyboard only (WASD + 1/2/3 + Q/E + D + A) | player-input.md |
| All menus | Reachable with keyboard (arrow + Enter + Esc) | player-input.md |
| No timed inputs | **All actions are NOT timed** — except the 1.5s hold-to-skip for terminal (G-F5) | player-input.md |
| Hold-to-confirm | `pause_battle` (0.5s hold-to-confirm) — has a visual progress indicator | player-input.md Blk #1 |
| Combo inputs | **No simultaneous 2-key combos required** | player-input.md E6 |
| Click target size | HUD buttons ≥ 32×32 px (1 tile unit) | hud.md |
| Drag-and-drop | **Not required** — weapon equip uses 1/2/3 (per player-input.md) | player-input.md |
| Cursor precision | All interactive elements have 32×32 px hitbox — no "precise click" required | n/a |
| Auto-attack (accessibility) | **Auto-mode already provides this** — player can switch to AUTO (per #7 C-R5) | battle-core-loop.md |
| Pause-anywhere | Pause available from any state (per #3 C-R2) | game-state-machine.md |
| Remappable bindings | **Not in MVP** | player-input.md OQ-1 |
| Controller remap | **Not in MVP** | player-input.md OQ-1 |

## 5. Cognitive Accessibility

| Requirement | Spec | Source |
|-------------|------|--------|
| Tutorial | **Minimal in MVP** (3 GDDs deferred tutorial to Polish) | art-bible |
| Hint system | "No weapon in slot 2" refused feedback (per #2) | player-input.md |
| Save-anywhere | Autosave at safe points (per #21) | save-load.md |
| Difficulty modes | Boss one-shot immunity is opt-out per boss (default on) — designer can flag tutorial bosses | damage-bounds ADR-0011 |
| Undo | Not in MVP (RPG doesn't have undo) | n/a |
| Slow mode | Not in MVP (combat is turn-based; no time pressure except auto-mode) | n/a |
| Pause/slow | Already supported (per #3 Pause overlay) | game-state-machine.md |
| Color-coding | Always paired with text or shape | art-bible |
| Reading level | Chinese level 4 (general adult). Per game concept: dense like 极乐迪斯科. | game-concept.md |
| Information density | HUD per hud.md C-R1 — 14 elements, each with position rationale | hud.md |
| Tooltips | Terminal + Codex entries have explanatory text | hud.md |

## 6. Assistive Technology Compatibility

| Requirement | Spec | Source |
|-------------|------|--------|
| Screen reader (Windows Narrator, macOS VoiceOver) | **Not in MVP** | accessibility OQ |
| High-contrast mode | **Not in MVP** | accessibility OQ |
| Switch control | **Not in MVP** | accessibility OQ |
| Eye tracking | **Not in MVP** | accessibility OQ |
| Voice control | **Not in MVP** | accessibility OQ |
| Closed captions for cutscenes | **Not in MVP** (no cutscenes) | n/a |

## 7. Save / Load Accessibility

| Requirement | Spec | Source |
|-------------|------|--------|
| Manual save | F5 (3 slots) | save-load.md |
| Autosave | Per chapter/room/victory (per #21 F1) | save-load.md |
| Quick load | F9 | save-load.md |
| Save on death | No (death = back to title per #3) | game-state-machine.md |
| Save file corruption | Graceful TITLE fallback (per #21 E2) | save-load.md |
| Backup save | `.bak.json` per upgrade (per ADR-0005) | save-load.md |

## 8. Game-Specific Accessibility Patterns

### 8.1 Dual-Mode Combat (per #7 C-R4) — Already an accessibility win

The manual/auto dual-mode (per #7 C-R5) is **itself an accessibility feature**:
- **Manual mode**: full control, requires no time pressure
- **Auto mode**: AI takes over, no decisions needed
- **Toggle anytime**: A key, no menu diving
- This means motor-impaired or cognitively-impaired players can choose their own difficulty

### 8.2 Weapon/Build System (per #11+#12) — Per-build feedback

- Build damage preview HUD (per #11+#12 AC-7) shows expected damage
- "No weapon in slot 2" refused feedback (per #2 F2) — no silent failures
- Boss one-shot immunity (per ADR-0011) — never lose to a single hit

### 8.3 Information Design

- State badge is always visible (per #2 UI-2b)
- HUD elements in fixed positions (no spatial disorientation)
- Codex percentages: weapon X / 12 已发现 (concrete progress)
- Encounter count: X / 25 (visible chapter progress)

## 9. Compliance Status

| Standard | MVP Status | Notes |
|----------|-----------|-------|
| WCAG 2.1 AA | **Partial** | Text contrast, color-not-only, captions for terminal logs, pause-anytime |
| WCAG 2.1 AAA | **Not MVP** | Body text contrast only, not all rules |
| XAG (XBox Accessibility Guidelines) | **Not MVP** | Out of scope |
| CVAA (21st Century Communications and Video Accessibility Act) | **N/A** | Single-player, no video |

## 10. Open Questions

| OQ | Summary | Priority | Resolution Path |
|----|---------|----------|-----------------|
| OQ-1 | Should MVP include basic remapping for left-handed players? | Low | Defer to Polish; if playtest shows demand, add to Settings. |
| OQ-2 | Should we add a "no flashing" mode for photosensitive players? | Low | WCAG 2.3.1 already caps flashing at ≤ 2/s; defer to Polish. |
| OQ-3 | Should we add screen reader support? | Low | Out of scope for MVP; deferred. |
| OQ-4 | Should we add save file backup to a known location (e.g., Documents) for players with locked user:// access? | Low | Godot's user:// resolution is OS-specific; not blocking. |
| OQ-5 | Should auto-mode respect player pause (currently it doesn't — battle is its own pause state)? | Medium | Defer to battle polish; manual-mode players don't care. |

## 11. Validation Criteria

- [ ] **All HUD text is WCAG AA contrast** (verified via automated linter)
- [ ] **All status colors are paired with text or shape** (e.g., boss warning = red + ⚠ icon)
- [ ] **Damage numbers and HP numbers are AAA contrast** (visually distinguished)
- [ ] **Game can be completed with keyboard only** (no mouse required for gameplay)
- [ ] **Game can be completed with one hand on keyboard** (WASD + 1/2/3 + Q/E + D + A all on left hand)
- [ ] **No critical cue is audio-only** (every sound has a visual equivalent)
- [ ] **Subtitles/captions are available for all terminal logs** (text always shown)
- [ ] **Auto-mode works correctly** (boss one-shot immunity, weapon selection, ammo switching)
- [ ] **Pause works from any state** (per #3 Pause overlay)
- [ ] **Save/load corruption doesn't crash** (graceful TITLE fallback)
- [ ] **Window resize doesn't break UI** (per hud.md C-R1 resize handling)

## Related Documents

- `design/gdd/player-input.md` — input bindings + 47 actions
- `design/gdд/ hud.md` — HUD layout + elements
- `design/gdd/camera.md` — camera + screen shake
- `design/gdd/save-load.md` — save/load + autosave
- `.claude/docs/technical-preferences.md` — input methods, platform
- `docs/architecture/control-manifest.md` — naming conventions
- `docs/architecture/ADR-0009-input-binding.md` — 47-action closed set

## Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-06-12 | Initial MVP accessibility requirements |
