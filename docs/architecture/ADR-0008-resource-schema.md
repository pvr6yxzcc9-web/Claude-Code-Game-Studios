# ADR-0008: Resource Schema (NPCData as 10th Subtype)

## Status

Accepted

## Date

2026-06-12

## Last Verified

2026-06-12

## Decision Makers

User + technical-director (self-review)

## Summary

Railhunter has **10 Resource subtypes** total. The 9th (NPCData) was missing from `resource-data.md` — this ADR adds it as the 10th. NPCData is the data backing the NPC system (`npc-terminal.md` C-R5): `name: String`, `dialog_lines: Array[String]`, `associated_fragment: StoryFragmentData` (optional). The cross-doc fix updates `resource-data.md` C-R3 to mention 10 subtypes (was 9) and updates `npc-terminal.md` C-R5 to reference `NPCData` explicitly. All 10 subtypes share the same pattern (immutability guard per ADR-0007, fields per ADR-0003 snapshot contract).

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (Resource + cross-doc consistency) |
| **Knowledge Risk** | LOW — same Resource pattern as 9 existing subtypes |
| **References Consulted** | `resource-data.md` C-R3, `npc-terminal.md` C-R5, `architecture.md` §4a Resource Subtypes |
| **Post-Cutoff APIs Used** | None — `Resource` + `@export` + `@export_range` are 4.0-stable |
| **Verification Required** | First NPCData `.tres` file: load, read fields, write blocked (per ADR-0007), serialize/deserialize (per ADR-0003) |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0007 (Resource Immutability — NPCData uses the same guard), ADR-0003 (Save Contract — NPCData producer implements contract) |
| **Enables** | NPC/Terminal system (`npc-terminal.md`) implementation; 10th producer in SaveManager |
| **Blocks** | NPC system implementation; possibly NPC-related cross-doc review (per architecture §8 OQ-05) |
| **Ordering Note** | Eighth ADR. After Immutability (0007). Before NPC/Terminal implementation |

## Context

### Problem Statement

`architecture.md` §8 OQ-05 says: *"NPCData Resource subtype definition (per [2b-1]) — High priority, resolved by ADR-RESOURCE-SCHEMA + npc-terminal.md update."*

`resource-data.md` C-R3 currently lists 9 Resource subtypes:
- WeaponData
- AmmoData
- EnemyData
- MechPartData
- ItemData
- EffectData
- TerminalLogData
- StoryFragmentData
- RegionData

But `npc-terminal.md` C-R5 says: *"NPC 节点持有 `npc_data: NPCData`（per #1 资源），包含：name / dialog_lines[] / associated_fragment."*

There's a **cross-doc contradiction**: resource-data.md doesn't list NPCData, but npc-terminal.md references it. This is the kind of bug `/review-all-gdds` would catch. The architecture §8 prioritizes it as a High-priority open question.

This ADR closes the loop:
- Adds NPCData to the official Resource subtype list (10 total)
- Defines the field schema
- Updates `resource-data.md` to mention NPCData
- Updates `npc-terminal.md` to be consistent

### Current State

- `resource-data.md` C-R3: "9 Resource 子类型" (excludes NPCData)
- `npc-terminal.md` C-R5: "NPC 节点持有 `npc_data: NPCData`" (references but doesn't define)
- `architecture.md` §4a: "Resource Subtypes" lists 9 (no NPCData)
- `architecture.md` §8 OQ-05: "NPCData Resource subtype definition" — **High priority**, awaiting this ADR

### Constraints

- **Cross-doc consistency** — this ADR updates 3 documents (this ADR, resource-data.md, npc-terminal.md)
- **MVP scope** — NPCData MVP needs 1 NPC (per `npc-terminal.md` C-R5); schema must support that
- **Pillar 4** — NPCData.associated_fragment is the contract with StoryFragmentData
- **Save/Load** — NPCData doesn't need save (per ADR-0003: NPCData is the *static data*, runtime state is in `npc_terminal` producer)

### Requirements

- **Field schema**: name, dialog_lines, associated_fragment (optional)
- **Immutability**: extends `ImmutableResource` (per ADR-0007)
- **Cross-doc fix**: 3 documents updated to be consistent
- **Optional fields**: associated_fragment may be null (NPC without fragment)
- **dialog_lines array**: minimum 1 line; if 0, show "信号损坏" placeholder (per `npc-terminal.md` E5)
- **Testable**: NPCData + NPC system + Save load round-trip

## Decision

### Architecture

```
NPCData (10th Resource subtype):

  @tool
  class_name NPCData
  extends ImmutableResource

  Fields:
    - id: StringName              (stable ID, per ADR-0003 contract)
    - display_name: String         (shown in dialogue UI)
    - dialog_lines: Array[String]  (≥1 line; each ≤200 chars; ≥10 lines typical)
    - associated_fragment: StoryFragmentData  (optional ref to truth piece)
    - sprite: Texture2D            (optional, for character art)
    - portrait_offset_px: Vector2i (optional, for UI positioning; default (0, 0))

  Constraints (enforced by @export annotations + ImmutableResource):
    - id: required, non-empty
    - display_name: required, non-empty
    - dialog_lines: required, ≥1
    - associated_fragment: optional
    - sprite: optional
    - portrait_offset_px: optional, default (0, 0)

  Producer: NPC/Terminal system
  Consumer: NPCController (in npc-terminal.md C-R5)
  Save: not serialized (NPC data is static; runtime state in npc_terminal producer)
```

### Key Interfaces

```gdscript
# === NPCData Resource subclass ===
# File: src/resource/npc_data.gd
@tool

class_name NPCData
extends ImmutableResource

@export var id: StringName
@export var display_name: String
@export var dialog_lines: Array[String] = []
@export var associated_fragment: StoryFragmentData
@export var sprite: Texture2D
@export var portrait_offset_px: Vector2i = Vector2i(0, 0)

# _init() validation
func _init() -> void:
    super._init()
    # Optional: assert id is non-empty in editor
    if Engine.is_editor_hint() and id == &"":
        push_warning("NPCData %s: id is empty" % resource_path)


# === NPC node using NPCData ===
# File: src/scene/npc_controller.gd
class_name NPCController
extends Area2D

@export var npc_data: NPCData

func _ready() -> void:
    assert(npc_data != null, "NPCController requires npc_data")
    assert(npc_data.dialog_lines.size() > 0, "NPCController %s has 0 dialog lines" % npc_data.id)

func interact(player: Node) -> void:
    # Trigger NPC dialogue
    var payload: Dictionary = {
        "npc_id": npc_data.id,
        "dialog_lines": npc_data.dialog_lines.duplicate(),
        "associated_fragment": null,  # resolved on display
        "sprite": npc_data.sprite,
        "portrait_offset_px": npc_data.portrait_offset_px,
    }
    if npc_data.associated_fragment != null:
        payload["associated_fragment_id"] = String(npc_data.associated_fragment.id)
    
    # Push to NPC/Terminal state
    GameStateMachine.push(TERMINAL, payload)
```

### Implementation Guidelines

#### Why NPCData doesn't have `schema_version` in the file (per ADR-0003)

- NPCData is **static** (`.tres` file)
- It's not serialized in the save file (per ADR-0003 PRODUCER_NAMESPACES, NPCData is not a producer)
- Runtime state of "which NPC logs have been read" lives in the `npc_terminal` producer
- NPCData is just the data file; no version needed (it's a static file like all .tres)

#### Cross-doc fix

| Document | Section | Change |
|----------|---------|--------|
| `resource-data.md` | C-R3 (Resource 子类型列表) | "9 Resource 子类型" → "10 Resource 子类型" + add `NPCData` to the list |
| `resource-data.md` | C-R3 (Resource 子类型数量) | `Total: 9` → `Total: 10` |
| `resource-data.md` | Interaction consumers table | Add `NPC/Terminal` row (consumes NPCData) |
| `npc-terminal.md` | C-R5 (NPC 节点) | "NPC 节点持有 `npc_data: NPCData`（per #1 资源）" — already correct, no change needed (it was already referencing NPCData) |
| `npc-terminal.md` | C-R5 (NPCData 字段) | "name / dialog_lines[] / associated_fragment" → "id / display_name / dialog_lines / associated_fragment / sprite / portrait_offset_px" (per this ADR) |
| `architecture.md` | §4a Resource Subtypes | Add NPCData to the list |

#### NPCData field semantics

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | StringName | Yes | Stable ID; e.g., `&"npc_chapter1_engineer"`. Used by NPC/Terminal system for "already-read" tracking |
| `display_name` | String | Yes | Shown in dialogue UI header. Default: empty string (validator warns) |
| `dialog_lines` | Array[String] | Yes | Each line ≤ 200 chars; typical 10-30 lines. Lines can contain player-readable text including pauses (`...`) and special characters |
| `associated_fragment` | StoryFragmentData | No | Optional ref to truth piece. If null, NPC dialogue doesn't unlock a fragment |
| `sprite` | Texture2D | No | Character portrait shown in dialogue UI. If null, no portrait shown (per art-bible "minimalism" rule) |
| `portrait_offset_px` | Vector2i | No | Default (0, 0). For UI positioning in dialogue screen (rare use case) |

#### Why 6 fields, not 5 or 7

- **id + display_name + dialog_lines + associated_fragment** = the 4 fields explicitly mentioned in `npc-terminal.md` C-R5
- **sprite + portrait_offset_px** = visual presentation, added because we have an art-bible-driven UI to support
- Could be split (e.g., NPCData + NPCVisuals) but for MVP, one class is simpler

#### What's NOT in NPCData

| NOT in NPCData | Why |
|----------------|-----|
| `is_read: bool` | Runtime state; lives in `npc_terminal` producer |
| `position: Vector2` | Scene-level, lives in NPCController |
| `trigger_radius: float` | Scene-level, lives in NPCController |
| `voice_clip: AudioStream` | Could add later; MVP uses text-only dialogue |

#### ID naming convention

- Format: `npc_<chapter>_<role>` or `npc_<role>`
- Examples: `npc_chapter1_engineer`, `npc_archive_keeper`, `npc_lone_survivor`
- Must be unique within the project (per `resource-data.md` C-R7)
- Used by `npc_terminal` producer for "already-read" tracking

#### Validation in editor

When NPCData is created in Godot editor, the script validates:
- `id` is non-empty
- `display_name` is non-empty
- `dialog_lines` has ≥ 1 line
- If `associated_fragment` is set, the fragment's `id` is non-empty

These are warnings, not errors (the `.tres` file can still be saved with empty fields, but the dev will see warnings).

#### NPCData with associated_fragment contract

```yaml
# Example npc_data.tres
[gd_resource type="Resource" script_class="NPCData" format=3]
[ext_resource type="Script" path="res://src/resource/npc_data.gd" id="1_xxx"]
[ext_resource type="Resource" path="res://data/fragments/frag_chapter1_orphanage.tres" id="2_xxx"]

[resource]
script = ExtResource("1_xxx")
id = &"npc_chapter1_archive_keeper"
display_name = "档案保管员"
dialog_lines = Array[String]([
    "你来得正好...",
    "我们等了很久了。",
    "（他指向屏幕）... 那里有真相。",
])
associated_fragment = ExtResource("2_xxx")
sprite = null
portrait_offset_px = Vector2i(0, 0)
```

#### No save serialization (per ADR-0003)

- NPCData is static data
- It is NOT in `SaveManager.PRODUCER_NAMESPACES`
- It is loaded fresh from `.tres` on game start
- Runtime state (which NPC logs have been read) is in the `npc_terminal` producer (separate from NPCData)

#### NPCData in cross-system contracts

| System | Uses NPCData | How |
|--------|---------------|-----|
| NPCController (Scene) | Yes | `@export var npc_data: NPCData` |
| `npc_terminal` producer | No (only uses fragment IDs and dialog_lines) | Reads `npc_data.dialog_lines.duplicate()` at interaction time |
| SaveManager | No | Per ADR-0003 PRODUCER_NAMESPACES — NPCData not a producer |
| Codex | No | NPC logs tracked separately in `npc_terminal` producer |
| HUD | No | NPC dialogue is its own UI, not HUD |

## Alternatives Considered

### Alternative 1: Don't add NPCData (skip NPC for MVP)

- **Description**: Remove the NPC from MVP scope; only have terminals
- **Pros**: One less Resource type; simpler
- **Cons**: Loses "NPC dialog" mechanic; less variety; `npc-terminal.md` OQ-01 still asks "is NPC worth it?"
- **Estimated Effort**: -10% implementation, -20% content richness
- **Rejection Reason**: `npc-terminal.md` C-R5 commits to 1-2 NPCs in MVP. We can't roll that back in this ADR.

### Alternative 2: Add NPCData as a separate file (not Resource)

- **Description**: NPCDialog as a plain GDScript class with `class_name NPCDialog extends RefCounted`
- **Pros**: No Resource overhead
- **Cons**: Can't be edited as `.tres` file; no Inspector integration
- **Estimated Effort**: -20% Resource boilerplate, -100% editor friendliness
- **Rejection Reason**: We want NPCs to be editable in Godot Inspector (per art-bible "data-driven" principle)

### Alternative 3: NPCData inherits from TerminalLogData

- **Description**: Make NPC a special case of terminal (extends TerminalLogData)
- **Pros**: 9 Resource types instead of 10
- **Cons**: NPC has different fields (sprite, portrait_offset) than terminal (audio, fragment). Inheritance is awkward
- **Estimated Effort**: -1 type, +20% field coupling
- **Rejection Reason**: They're different concepts; "is-a" doesn't hold. Composition is better than inheritance.

### Alternative 4: Add NPCData + NPCVisuals as two types

- **Description**: Split into NPCData (logic) + NPCVisuals (sprite, offset)
- **Pros**: Separation of concerns
- **Cons**: 11 Resource types; NPCs need 2 references instead of 1
- **Estimated Effort**: +1 type, +1 reference per NPC
- **Rejection Reason**: For 1-2 NPCs in MVP, one class is simpler. Can split in VS if needed.

## Consequences

### Positive

- **Cross-doc consistency** — `resource-data.md`, `npc-terminal.md`, `architecture.md` all agree on NPCData
- **Closes High-priority OQ** — architecture §8 OQ-05 resolved
- **Schema is uniform** — NPCData follows the same pattern as the 9 other subtypes
- **Immutability** — NPCData extends ImmutableResource (per ADR-0007), so editing is safe
- **Pillar 4 support** — `associated_fragment` field connects NPCs to truth pieces
- **MVP scope satisfied** — 1-2 NPCs in MVP, schema supports that

### Negative

- **3-doc update** — must update `resource-data.md`, `npc-terminal.md`, `architecture.md` (this ADR's migration plan)
- **NPCData is essentially read-only** — but has 6 fields, not just 4; more boilerplate per NPC
- **Sprite field** — adds a small dependency on art-bible asset pipeline (we need a sprite format)

### Neutral

- NPCData is a "data file" like other Resources; not in save/load (per ADR-0003)
- NPC visual presentation is part of NPCData (sprite + offset), not separate
- First NPCData implementation requires a portrait artist or placeholder

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Cross-doc fix not propagated (resource-data.md still says 9 types) | Medium | Medium | This ADR includes explicit migration steps; reviewer verifies |
| First NPCData has 0 dialog_lines (developer forgets) | Medium | Low | `_ready()` asserts `dialog_lines.size() > 0` (per npc-terminal.md E5 fallback) |
| associated_fragment is a missing/broken ref | Low | Low | Same pattern as WeaponData's ammo_slot — null OK, but log warning |
| Sprite import fails | Low | Low | `sprite: Texture2D` is optional; null OK |
| 10th Resource subtype breaks ResourceRegistry scanning | Low | Medium | ResourceRegistry uses `_get_property_list()` not a hardcoded list; new subtype is auto-discovered |
| NPCData ID collision (two NPCs with same id) | Low | High | Linter checks uniqueness in `data/npcs/*.tres`; CI fails |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| ResourceRegistry scan (10 → 11 types) | ~30 files | ~31 files | <200ms total |
| NPCData load time | N/A | <5ms (small Resource) | <10ms |
| Memory per NPCData | N/A | ~1 KB | <5 KB |
| NPC dialogue display latency | N/A | <16ms (text rendering) | <16.6ms |
| associated_fragment resolution | N/A | <1ms (registry lookup) | <5ms |

## Migration Plan

1. **Update `resource-data.md` C-R3** — change "9 Resource 子类型" to "10 Resource 子类型" + add NPCData to the list
2. **Update `resource-data.md` C-R3 (Total count)** — change `Total: 9` to `Total: 10`
3. **Update `resource-data.md` Interaction consumers** — add `NPC/Terminal` row
4. **Update `npc-terminal.md` C-R5** — refine NPCData field list to match this ADR
5. **Update `architecture.md` §4a Resource Subtypes** — add NPCData entry

After this migration, all 3 cross-doc references are consistent.

**Rollback plan**: If a downstream GDD explicitly does NOT want NPCData (e.g., a new design says "no NPCs in MVP"):
1. Revert the migration steps
2. Update `npc-terminal.md` C-R5 to remove NPC reference (use only terminals)
3. Update architecture §8 OQ-05 to "deferred"
4. Mark this ADR as "Superseded by future ADR"

No code changes required (NPCData class doesn't exist yet at this point).

## Validation Criteria

- [ ] **First NPCData test**: create `data/npcs/npc_chapter1_archive_keeper.tres` with 6 fields, load via `ResourceLoader.load()`, assert all fields populated
- [ ] **Immutability test**: `npc.dialog_lines.append("new line")` → `ImmutableResourceError` (per ADR-0007)
- [ ] **Cross-doc consistency test**: `grep -c "10 Resource 子类型" resource-data.md` returns 1
- [ ] **SaveManager test**: load all 11 producer systems (per ADR-0003), NPCData is NOT in PRODUCER_NAMESPACES (correctly)
- [ ] **NPC interaction test**: walk to NPC node, press E, `push(TERMINAL, payload)` triggered with correct dialog_lines
- [ ] **associated_fragment test**: NPC with fragment → unlock on completion (per npc-terminal.md C-R3)
- [ ] **No fragment NPC test**: NPC without fragment → no unlock signal (correctly)

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/npc-terminal.md` | NPC/Terminal | **C-R5**: "NPC 节点持有 `npc_data: NPCData`" | Defines NPCData schema with id, display_name, dialog_lines, associated_fragment, sprite, portrait_offset_px |
| `design/gdd/resource-data.md` | Resource/Data | **C-R3**: "9 Resource 子类型" | Cross-doc fix: change to 10 |
| `architecture.md` §4a | Resource Subtypes | "Resource Subtypes" list | Adds NPCData to the list |
| `architecture.md` §8 OQ-05 | Open Question | "NPCData Resource subtype definition" | **Resolved** by this ADR |

> Resolves 1 cross-doc contradiction + 1 architecture-level OQ.

## Related

- **Depends on**:
  - ADR-0007 (Resource Immutability — NPCData uses the same guard)
  - ADR-0003 (Save Contract — NPCData is NOT in PRODUCER_NAMESPACES, but NPC dialogue runtime state IS in `npc_terminal` producer)
- **Enables**:
  - NPC/Terminal system implementation
  - 10 producer systems in SaveManager (already counted)
- **Cross-doc updates required**:
  - `resource-data.md` C-R3 (9 → 10)
  - `npc-terminal.md` C-R5 (refine field list)
  - `architecture.md` §4a (add NPCData)
- **Code locations** (when implemented):
  - `src/resource/npc_data.gd` (this ADR's schema)
  - `data/npcs/npc_chapter1_archive_keeper.tres` (first NPC)
  - `data/npcs/npc_chapter1_lone_survivor.tres` (second NPC, optional)
  - `src/scene/npc_controller.gd` (NPC node using NPCData)
  - `src/scene/npc_terminal.gd` (NPC/Terminal producer; runtime state)
  - `tests/integration/npc_data_test.gd` (integration test)
  - `tools/lint_npc_id_uniqueness.py` (CI linter)
