# STORY-002: BattleScene stub: enter, attack, resolve, return

> **Epic**: battle-core-loop
> **Layer**: Core
> **TR**: TR-BAT-001, TR-BAT-006, TR-BAT-007
> **Status**: Done (verified 2026-06-13)

## Acceptance Criteria

- [x] `BattleScene` is a `Node` child of `Main` in `main.tscn`
- [x] Listens to `GameStateMachine.state_changed` signal
- [x] On `state_battle`: spawn enemy from `ResourceRegistry` (default: `scavenger`), set `in_battle = true`
- [x] On `1/2/3` pressed: `WeaponLoadout.trigger_attack(slot)` → `BattleScene.on_player_attack(slot)` → damage calc
- [x] Enemy counter-attack if accuracy roll passes
- [x] On victory: emit `battle_resolved(true, dmg, taken)` → `state_exploration`
- [x] On defeat: emit `battle_resolved(false, dmg, taken)` → `SaveManager.get_autosave()` → `state_exploration`
- [x] Esc in battle flees → `state_exploration`

## Implementation

- `src/battle/battle_scene.gd` — listens to state machine, owns enemy state
- `src/autoload/weapon_loadout.gd:trigger_attack()` — emits `attack_triggered` signal
- `src/math/battle_math_lib.gd:compute_base_damage()` — pure damage math

## Verification Evidence

- F5 boot: `[BattleScene] ready (stub)`
- Manual: trigger encounter (red diamond) → state_battle → 1/2/3 attacks → enemy HP decreases
- FC-1..FC-11 cover battle stub
