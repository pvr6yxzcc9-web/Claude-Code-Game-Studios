# Player Input GDD — Revision Plan (2026-06-12)

> **Verdict**: MAJOR REVISION NEEDED (5 specialists + 1 creative-director, full mode)
> **Target**: design/gdd/player-input.md + design/registry/input-bindings.yaml + design/registry/entities.yaml
> **Status**: Plan written, revisions DEFERRED to fresh session (context at ~85% — editing 12 sections × 557 lines of GDD plus two registry files in this session would risk a half-edited GDD).
> **Post-revision step**: `/clear` → resume revisions → `/design-review design/gdd/player-input.md` (re-review) in a new session.

---

## 4 BLOCKING ISSUES (must fix)

### Blk #1 — Modal transparency not delivered
**User-approved design decisions**:
- Add a persistent state badge top-left of HUD: `EXPLORATION` / `BATTLE` / `MENU` / `TERMINAL` / `CODEX` / `PAUSED`. Visual + textual (not icon-only). The MANUAL/AUTO sub-indicator sits adjacent to it during Battle.
- Convert F2 silent rejection to **visible refusal-with-hint** for cross-state keys: `TAB opens codex — only in Exploration` (0.5s hint with cross-reference).
- Unify Esc semantics: `Esc` = `cancel_target` in Battle (always), `Q` = `pause_battle` (separate key, away from the combat cluster). Update GDD Section G1 table + input-bindings.yaml.

**Edits required**:
- player-input.md Section B (Player Fantasy §3) — strengthen modal transparency language.
- player-input.md Section C (C-R6) — clarify focus routing for the new state badge.
- player-input.md Section C (Input refused feedback) — add 3rd category: "bound-elsewhere" hint.
- player-input.md Section C (States table) — add "State badge" row to the per-state column.
- player-input.md Section H (UI Requirements UI-2 → UI-7) — specify the persistent state badge.
- player-input.md Section H (Visual/Audio) — add an "input_refused_cross_state" audio cue (or reuse input_refused; designer may decide).
- input-bindings.yaml `cancel_target` — confirm Esc binding.
- input-bindings.yaml `pause_battle` — change keyboard binding from Esc to Q, gamepad from GAMEPAD_BUTTON_START to GAMEPAD_BUTTON_BACK (with hold-to-confirm 0.5s).

### Blk #2 — Acceptance criteria coupled to implementation, not contract
**Edits required**:
- Rewrite AC-1..AC-12 as **contract assertions** (player experience + observable state, not API name/count).
- Add 13 missing ACs:
  - **AC-13**: closed-set policy (adding a 48th action causes linter to fail with `TOO_MANY_ACTIONS`).
  - **AC-14**: action-name identity (project.godot ⊆ input-bindings.yaml).
  - **AC-15**: AC-3 split into 3 sub-assertions (action_pressed fires exactly once on press transition; action_released fires exactly once on release; action_held fires every frame with strictly increasing duration).
  - **AC-16**: F1 internal 500µs trigger (median input_to_handler_us ≤ 200µs, p99 ≤ 500µs).
  - **AC-17**: E2 atomic transition (key pressed on transition frame reaches new state within 1 frame).
  - **AC-18**: E6 modifier key invariant (Shift+W produces only move_up, no sprint).
  - **AC-19**: UI-2 mode indicator always visible (visible==true during all fullscreen overlays).
  - **AC-20**: G-F5 hold-to-skip threshold (1.5s ± 0.05s triggers skip).
  - **AC-21**: action_held monotonicity (5 held frames produce strictly increasing durations ending at ~83ms).
  - **AC-22**: debug-stripping (release build has 43 actions, dev build has 47).
  - **AC-23**: F2 audio cue plays for 100ms ± 8ms.
  - **AC-24**: no-mouse-only-menu (every interactive Control has focus_mode != FOCUS_NONE).
  - **AC-25**: focus_wrap behavior (D-pad on last element wraps to first).
- Test evidence location block: split GUT (`.gd`) vs NUnit (`.cs`); defer to ADR-0006 but document convention.
- Mock-clock dependency-injection point in InputBus (referenced in AC-9, AC-10, AC-15, AC-20, AC-21).

### Blk #3 — Godot 4.6 API surface mis-described
**Edits required**:
- Remove all references to `force_dispatch_pending()` (does not exist in any Godot version). Replace E2 with: "Verify scene-tree ordering — InputBus autoload must be listed after GameStateMachine in `Project > Autoload` to ensure InputBus `_process` runs after state transitions."
- Document `action_held` as **custom per-action timer** in InputBus: `Dictionary[StringName, float] _press_start_times`. On `action_pressed`, set `_press_start_times[action] = Time.get_ticks_msec() / 1000.0`. In `_process`, iterate the dictionary, compute `duration`, emit signal, clean up on `action_released`. Add to C-R3.
- Fix `flee_battle` binding: change YAML from `modifiers: [ESC]` to `shift_pressed: true` (Godot 4.4+ `InputEventKey` field). Same for `menu_tab_prev` (Shift+Tab) and `quit_to_title` (Ctrl+Q).
- Rewrite G-F2 (Game Feel rule): "Input is handled in `_unhandled_input` for one-shot events that should yield to GUI focus, and in `_process` / `_physics_process` for continuous-state polling. The InputBus wraps both paths into a single signal interface." Update C-R6 accordingly.
- Add verification note to OQ-2 (controller rumble): "Verify `Input.start_joy_vibration()` signature in Godot 4.6 source — the SDL3 migration in 4.5 may have changed parameter order."
- Plumb `analog_deadzone: 0.20` in input-bindings.yaml: change from top-level documentation-only field to per-action field attached to GAMEPAD_AXIS bindings (move_up/down/left/right). Add a loader note: "InputBus `_ready()` calls `InputMap.action_set_deadzone(&"move_up", 0.20)` etc."

### Blk #4 — Gamepad coverage is incoherent
**User-approved design decisions**:
- Add D-pad LEFT/RIGHT for weapon slots 1/3 on gamepad.
- Add shoulder buttons for ammo cycle (RIGHT_SHOULDER for `cycle_ammo`).
- Add Select+Start (hold) for `toggle_mode` on gamepad (alternative to current GAMEPAD_BUTTON_BACK which is also minimap).

**Edits required**:
- Replace "Yes (full)" in States table with the honest per-action coverage matrix.
- Update input-bindings.yaml gamepad bindings for the 4 above actions.
- Add a "Gamepad coverage" sub-section to G1 (Tuning Knobs) that explicitly maps user-approved scope: "Movement + battle menu only. Code-bound but UI-true coverage for weapon slots 1/2/3 + ammo cycle + mode toggle." Honest partial where partial is the actual scope.

---

## 6 IMPORTANT REVISIONS (deferable, but fix in same pass)

### Rec #5 — Latency budget framing
**Edits required**:
- F1: clarify 16.5ms is the **hard ceiling** (frame budget). Add a 33ms **target** for perceived responsiveness (perception threshold, 2 frames). Document the difference.
- Add AC-16 (F1 internal 500µs trigger — listed above as part of Blk #2).

### Rec #6 — Action-count production/staging split
**Edits required**:
- Document the split: **47 actions in dev build, 43 actions in release** (debug-stripped).
- Document the `pause` / `pause_battle` deduplication: same physical binding (was Esc; after Blk #1 fix, both are unique keys — but document the design rule: "Two actions on the same physical key are forbidden by C-R5 unless they route to different state-level handlers; the only exception is `pause` and `pause_battle` in their current shared-binding form, which is BANNED per Blk #1 fix").
- Update AC-1 to verify the 47/43 split, not just "exactly 47."
- Update entities.yaml: add `input_action_count_release: 43` constant.

### Rec #7 — E2 race + autoload order + subscription lifetime
**Edits required**:
- C-R3 — Add: "The InputBus autoload MUST be listed after the GameStateMachine autoload in `Project > Autoload` to ensure InputBus `_process` runs after state transitions."
- C-R4 — Replace `_enter_tree`/`_exit_tree` subscription with: "Each state exposes `subscribe_to_input_bus(bus: InputBus)` and `unsubscribe_from_input_bus(bus: InputBus)`. The GameStateMachine calls these in its `transition_to(new_state)` method, after the new state is added to the tree and before the old state is removed."
- Add E9 (new edge case): "Subscription during state pooling — if a state is removed via `queue_free()` and a new instance is instantiated, the InputBus's signal holds weak references to Callable targets, so the old connections silently break. The GameStateMachine's `transition_to` is the single point of subscription, preventing double-connection or stale-connection bugs."

### Rec #8 — Refusal fatigue escalation
**Edits required**:
- Add F4 (new formula): `t_escalation = clamp(refusal_count_session[action] * 0.10, 0.0, 0.50)` and a state machine for escalation levels:
  - Level 0 (1st-2nd identical refusal): 0.3s hint + 100ms audio (current behavior).
  - Level 1 (3rd): 0.5s longer hint, no audio.
  - Level 2 (4th-5th): 0.3s hint, subtle 0.1x opacity.
  - Level 3 (6+): subtle visual flicker only, no audio, no text.
- Add a per-session counter in InputBus: `Dictionary[StringName, int] _refusal_count_session`.
- AC-9: assert that the 4th identical refusal within 60s suppresses the audio cue.

### Rec #10 — Held-vs-pressed policy on state transitions
**User-approved design decision**: held-preserved (new state must acknowledge held keys for one frame).
**Edits required**:
- Add E9 (renumber from above; merge into a single E9 on transition policy):
  - "Held keys: preserved. If the player holds `move_right` and an encounter triggers on the same frame, the Battle state receives `move_right was held` for one frame (then released if the player released during the transition). Battle state may use this for an emergency-mech-pivot animation or simply ignore it. Implementation: the InputBus, on detecting a state transition, snapshots the `is_action_pressed` set, replays it to the new state as `_process`'s first action, and clears the snapshot."
  - "Pressed keys (just-pressed-this-frame): preserved per current behavior. The InputBus dispatches the press to the new state on the same frame."
  - "Symmetric rule: every input the player thought they gave at frame N-1 is honored at frame N."

---

## NICE-TO-HAVE (4 items, low priority, defer to Polish phase)

- Gamepad indicator: bump 12x12px to 24x24px with "GAMEPAD" label for the first 5s of any gamepad-active session, fade to icon-only.
- Hold-to-skip discoverability: add a circular progress ring around the cursor during the 1.5s hold.
- Mouse-leaves-window: `Input.warp_mouse()` to window center on `WM_WINDOW_FOCUS_IN`. 1-line code change.
- `bindings_version: int` home: define as a const on `InputBus.gd` (`const BINDINGS_SCHEMA_VERSION: int = 1`).

---

## FILES TO MODIFY (in order)

1. `design/gdd/player-input.md` — primary edits (~12 sections touched)
2. `design/registry/input-bindings.yaml` — Blk #1 (Esc/Q split), Blk #3 (modifiers → shift_pressed), Blk #4 (gamepad D-pad/shoulder), Rec #6 (debug-strip note)
3. `design/registry/entities.yaml` — Rec #6 (add `input_action_count_release: 43` constant)
4. `design/gdd/systems-index.md` — update status: In Design → In Review (after revisions)

---

## POST-REVISION STEPS

1. Update `production/session-state/active.md` — Task #26-#34 all complete; Phase 8 status = "Revised, pending re-review"
2. Run `/clear`
3. Resume in fresh session: complete the actual edits per this plan
4. Run `/design-review design/gdd/player-input.md` (re-review)
5. If APPROVED: update systems-index + review-log, advance to Phase 9 (Game State Machine)
