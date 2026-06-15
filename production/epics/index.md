# Epics Index

Last Updated: 2026-06-13
Engine: Godot 4.6
Total Epics: 5 (Foundation) + 0 (Core) = 5

## Foundation Layer

| Epic | System | GDD | Architecture Module | Stories | Status |
|------|--------|-----|---------------------|---------|--------|
| [resource-data](resource-data/EPIC.md) | 资源/数据 (Resource/Data) | design/gdd/resource-data.md | ResourceRegistry + 10 Resource subtypes | Not yet created | Ready |
| [player-input](player-input/EPIC.md) | 玩家输入 (Player Input) | design/gdd/player-input.md | InputBus | Not yet created | Ready |
| [game-state-machine](game-state-machine/EPIC.md) | 游戏状态机 (Game State) | design/gdd/game-state-machine.md | GameStateMachine | Not yet created | Ready |
| [camera](camera/EPIC.md) | 相机 (Camera) | design/gdd/camera.md | Camera2D + CameraFollow | Not yet created | Ready |
| [collision](collision/EPIC.md) | 碰撞 (Collision) | design/gdd/collision.md | CollisionManager | Not yet created | Ready |

## Core Layer

| Epic | System | GDD | Architecture Module | Stories | Status |
|------|--------|-----|---------------------|---------|--------|
| [battle-core-loop](battle-core-loop/EPIC.md) | 战斗核心循环 (Battle Core Loop) | design/gdd/battle-core-loop.md | BattleCore (C# math + GDScript orchestration) | Not yet created | Ready |

## Feature Layer

| Epic | System | GDD | Architecture Module | Stories | Status |
|------|--------|-----|---------------------|---------|--------|
| (not yet created) | Weapon & Ammo | design/gdd/weapon-ammo.md | WeaponLoadout, Inventory | — | — |
| (not yet created) | Level / Dungeon | design/gdd/level-dungeon.md | LevelRuntime | — | — |
| (not yet created) | Random Encounter | design/gdd/random-encounter.md | EncounterManager | — | — |
| (not yet created) | NPC / Terminal | design/gdd/npc-terminal.md | NPCController, TerminalPlayer | — | — |

## Presentation Layer

| Epic | System | GDD | Architecture Module | Stories | Status |
|------|--------|-----|---------------------|---------|--------|
| (not yet created) | HUD | design/gdd/hud.md | HUD scene | — | — |
| (not yet created) | Save/Load | design/gdd/save-load.md | SaveManager | — | — |
| (not yet created) | Menu/Pause | (not yet designed) | Menu scene | — | — |
| (not yet created) | Codex | (not yet designed) | Codex scene | — | — |
| (not yet created) | Minimap | (not yet designed) | Minimap scene | — | — |

## Polish Layer

| Epic | System | GDD | Architecture Module | Stories | Status |
|------|--------|-----|---------------------|---------|--------|
| (not yet created) | Audio, Settings, Tutorial, Achievements, Localization | (not yet designed) | TBD | — | — |

## Recommended Next Step

Run `/create-stories [epic-slug]` for each Foundation epic:
```
/create-stories resource-data
/create-stories player-input
/create-stories game-state-machine
/create-stories camera
/create-stories collision
```

Then `/create-epics layer: core` to scaffold the Battle Core Loop epic.

Then `/sprint-plan new` to create the first sprint plan.
