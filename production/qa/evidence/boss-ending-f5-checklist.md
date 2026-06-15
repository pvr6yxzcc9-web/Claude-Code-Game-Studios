# F5 Checklist — Boss Ending UI (S4-009 E2E)

> **Purpose**: Verify the visual transition from "boss defeated" → "ending dialogue
> appears" → "close dialogue returns to exploration" — the one flow fc33 covers
> structurally but no one has actually pressed F5 to watch happen.
>
> **Method**: F5 in Godot editor, follow the steps below, note what you see.
>
> **Expected duration**: 5-10 minutes if you know the controls; 15 min if
> you need to look up keys.

## Setup

1. Open `main.tscn` in Godot 4.6.3 editor
2. Press **F5** (play project)
3. Game launches in `state_exploration` (room 0)
4. The fastest path to room 9 (boss) is to walk through doors. If you
   want a faster path, use the dev menu if present (otherwise just walk
   the 9 rooms — takes about 1-2 minutes at 120 px/s).

## Controls you need

- **WASD** or **arrow keys** — move
- **E** — interact (door / terminal / NPC)
- **1 / 2 / 3** — pick weapon slot in battle
- **Q** — cycle equipped mech part
- **F** — toggle auto-mode (optional; battle will work in manual too)
- **Esc** — pause menu
- **C** — codex
- **Space** — confirm / advance dialogue
- **Tab** — end dialogue early (probably)

## Test 1 — Walk to room 9 (boss room)

1. F5 launches you in room 0
2. Walk right to door → enter room 1
3. Walk right → room 2 → ... → room 9
4. **Observation**: boss encounter triggers when you enter room 9 (or
   step on a specific tile — depends on room layout)

## Test 2 — Defeat the boss

1. Battle scene appears, "BOSS" marker should be visible somewhere
2. Use any weapon + ammo combo (1/2/3 to pick, then 1/2/3 to fire —
   read HUD if confused)
3. Keep attacking. The boss has more HP than regular enemies (look up
   the data file if curious) but takes the same damage range
4. **Observation**: When boss HP hits 0, the battle should NOT return
   to exploration normally. Instead, the ending dialogue should appear.

## Test 3 — Ending dialogue appears

This is the **critical test** — this is what fc33 covers structurally.

1. After boss HP hits 0, the screen should:
   - Hide the battle scene
   - Show the ending dialogue (1 node, with text)
2. The ending text will be one of:
   - **Ending A** (≥6 fragments): revelation — the convoy was family
   - **Ending B** (3-5 fragments): partial — some truth
   - **Ending C** (<3 fragments): default — the convoy is gone

   Which one you get depends on how many fragments you have. The
   base count when you walk in is 4 (from sprint 4's 6 active+spawn)
   so you'll likely get Ending B or A. Boss victory also unlocks 3
   more (S5-005), so by the time you finish the boss, you have
   4+3=7 → **Ending A** for sure (threshold 6).

3. **Observation to record**:
   - Did the ending dialogue actually appear visually? (Y/N)
   - What text did it show? (paste the first sentence)
   - Did the screen freeze the battle scene behind it? (Y/N)
   - Any UI glitches — text overflow, missing background, etc.?

## Test 4 — Close ending, return to exploration

1. Press Space (or whatever "advance/confirm" is) to close the ending
2. **Observation**:
   - Did you return to the boss room in exploration mode? (Y/N)
   - Or did it crash / softlock / show menu instead? (Y/N)
   - Did the HUD show "exploration" state (no PAUSED badge, no BATTLE badge)?
3. Try moving — player should walk freely

## Test 5 — Boss save (optional but recommended)

1. After defeating boss, check if `user://save_<slot>.json` got written
   (open `FileSystem` dock in Godot or check `~/.local/share/godot/app_userdata/railhunter/`)
2. **Observation**: file exists? (Y/N). Reopen game and load — should
   re-enter the boss-defeated state.

## If something breaks

- **Ending doesn't appear at all** — boss flag detection might be wrong
  in `battle_scene.gd:183`. Check the enemy data file to confirm the
  boss has `boss = true`.
- **Ending appears but wrong text** — threshold logic in
  `ending_controller.gd:determine_ending()` might be off.
- **Can't close ending** — `dlg_ending_*.tres` might have no `advance`
  signal or the dialogue manager might not be transitioning out.
- **Game crashes** — share the stack trace from the editor output panel.

## After F5

Write your observations to:
`production/qa/evidence/boss-ending-f5-result-2026-06-14.md`

Use this format:

```markdown
# Boss Ending UI F5 Result — 2026-06-14

## Test 1 (walk to room 9)
- Reached boss room: Y/N
- Time taken: [minutes]
- Encounter triggered: Y/N
- Notes: [anything weird]

## Test 2 (defeat boss)
- Boss appeared: Y/N
- Boss HP visible: Y/N
- Defeated cleanly: Y/N / Notes: [crash / softlock / etc.]

## Test 3 (ending dialogue appears)  ← THE CRITICAL TEST
- Ending appeared: Y/N
- Ending tier: A / B / C
- First sentence: "[paste]"
- Visual issues: [overflow / glitch / none]
- Screen state: [frozen / black / dialogue box / etc.]

## Test 4 (close ending)
- Closed with: [Space / click / etc.]
- Returned to exploration: Y/N
- Player movable: Y/N
- HUD state correct: Y/N

## Test 5 (save) [optional]
- Save file written: Y/N
- Load returns correctly: Y/N

## Overall verdict
PASS / PARTIAL / FAIL

## Bugs found (if any)
1. [description, file:line if known]
2. ...

## Suggested next steps
- [if PASS]: ready to mark S4-009 e2e as F5-verified, update close report
- [if PARTIAL]: list which tests failed, which passed
- [if FAIL]: file as bug, decide ship-or-block
```

That's it. 5-10 minutes of F5 and we close out the only remaining
headless gap in the project.
