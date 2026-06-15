# S7-005 Implementation Plan — Dialogue Companion In-Dialogue Swap

> **Sprint 7 Story**: S7-005 (1.5 days, godot-gdscript-specialist)
> **Depends on**: None (parallel to S7-001) — but S7-001's party data is the data source
> **Goal**: Extend `src/autoload/dialogue_manager.gd` to support **1 main character + 1 in-dialogue companion + 1 NPC** model (per `party-system.md` §3.9). Player can swap the in-dialogue companion before the dialogue starts using `Shift+1/2/3`. Some NPCs have companion-specific dialogue trees.

## Current State (Baseline)

- **File**: `src/autoload/dialogue_manager.gd` (126 lines)
- **Data model**: 1 `current_npc`, 1 `current_tree`, 1 `current_node_id` — no concept of "in-dialogue companion"
- **API**: `start_dialogue(npc)`, `choose(choice_index)` — no companion parameter
- **No Shift+1/2/3 handler** — only E to start, 1-9 to choose

## Target State (After S7-005)

- **Data model**: `current_npc`, `current_tree`, `current_node_id`, **`in_dialogue_companion_id`** (the pilot who is "in dialogue" with the main character)
- **API**: `start_dialogue(npc, companion_id = "")` — optional companion
- **Shift+1/2/3 handler**: Before dialogue starts, player can press Shift+1/2/3 to set the in-dialogue companion
- **Companion-specific dialogue trees**: Some NPCs have a different `current_tree` depending on which companion is in-dialogue (e.g., a scientist who knew 霜尾's mother has a long dialogue only with 霜尾)
- **Default companion**: If the player doesn't Shift+1/2/3 before pressing E, default is the **active mech's pilot** (per S7-001's data)

## File Changes (Summary)

| File | Lines added | Lines removed | Net |
|------|-------------|---------------|-------|
| `src/autoload/dialogue_manager.gd` | +80 | -10 | +70 |
| `src/resource/dialogue_tree.gd` | +50 | 0 | +50 |
| `src/ui/dialogue_ui.gd` | +60 | -20 | +40 |
| `tests/integration/fc63_dialogue_companion_test.gd` | +90 | 0 | +90 |

**Total**: ~280 lines added, ~30 lines removed. **Net: +250 lines** across 4 files.

---

## Sub-Task Breakdown (Days 1-1.5)

### Day 1 Morning: Data Model + API

**Sub-task 1.1: Extend `DialogueManager` with companion field** (0.25 day)

Add a new field and update the API:

```gdscript
# In dialogue_manager.gd (after refactor)
var in_dialogue_companion_id: StringName = &""  # &"ranger" / &"frostbite" / &"bomber" / &""

func start_dialogue(npc: Resource, companion_id: StringName = &"") -> Error:
    current_npc = npc
    in_dialogue_companion_id = companion_id
    # Pick the dialogue tree based on the companion
    var tree: Resource = _pick_dialogue_tree(npc, companion_id)
    return start_dialogue_with_tree(tree, npc)

func _pick_dialogue_tree(npc: Resource, companion_id: StringName) -> Resource:
    # Check if NPC has a companion-specific tree
    if companion_id != &"" and "companion_trees" in npc:
        var trees: Dictionary = npc.get("companion_trees")
        if trees.has(companion_id):
            return trees[companion_id]
    # Default: use npc's main tree
    return npc.get("dialogue_tree")
```

**Sub-task 1.2: Update `dialogue_tree.gd` resource** (0.25 day)

Add a field for "companion-specific lines":

```gdscript
# In dialogue_tree.gd
class_name DialogueTree
extends Resource

# Existing fields
var nodes: Dictionary = {}  # node_id → DialogueNode

# NEW: companion-specific line overrides
# e.g., a node_id can have a different text if 霜尾 is in-dialogue
var companion_overrides: Dictionary = {}  # {node_id: {companion_id: text}}

func get_node_text(node_id: StringName, companion_id: StringName = &"") -> String:
    if companion_id != &"" and node_id in companion_overrides:
        var overrides: Dictionary = companion_overrides[node_id]
        if companion_id in overrides:
            return overrides[companion_id]
    if node_id in nodes:
        return nodes[node_id].text
    return ""
```

### Day 1 Afternoon: UI + Input

**Sub-task 1.3: Update `dialogue_ui.gd` to show companion portrait** (0.5 day)

The existing `dialogue_ui.gd` shows the main character + NPC portraits. Add a third portrait (the in-dialogue companion) between them.

The companion portrait uses the **NPC portrait asset** that already exists (S6-015). E.g., 霜尾's portrait is the same one used when 霜尾 is an NPC in the world.

**Sub-task 1.4: Handle Shift+1/2/3 input** (0.25 day)

In `dialogue_manager.gd._on_action_pressed`:

```gdscript
func _on_action_pressed(action: StringName) -> void:
    if not is_active:
        return
    if action == &"dialogue_companion_1":
        in_dialogue_companion_id = &"ranger"
    elif action == &"dialogue_companion_2":
        in_dialogue_companion_id = &"frostbite"
    elif action == &"dialogue_companion_3":
        in_dialogue_companion_id = &"bomber"
    # ... rest of existing logic
```

**Input map**: Add 3 new actions to `project.godot`:
- `dialogue_companion_1` = Shift+1
- `dialogue_companion_2` = Shift+2
- `dialogue_companion_3` = Shift+3

### Day 1.5: Tests + Polish

**Sub-task 1.5: Tests fc63_dialogue_companion_test.gd** (0.5 day)

8 tests:
- 1) Default companion is empty (no companion)
- 2) Shift+1 sets companion to ranger
- 3) Shift+2 sets companion to frostbite
- 4) Shift+3 sets companion to bomber
- 5) Companion-specific tree is loaded when companion is set
- 6) Default tree is loaded when no companion is set
- 7) companion_overrides change the text of a node based on companion
- 8) Dialogue UI shows 3 portraits (main + companion + NPC)

**Sub-task 1.6: Polish + edge cases** (0.25 day)

- If the chosen companion is not in the player's party (e.g., Shift+1 when 霜尾 is not yet recruited), fall back to no companion.
- If the companion's tree doesn't exist, fall back to the default tree.
- Visual: highlight the active companion portrait in the UI.

---

## Code Patterns to Reuse (from existing codebase)

| Pattern | Existing location | Reuse for S7-005 |
|--------|-------------------|------------------|
| Dialogue tree node | `dialogue_tree.gd` `nodes: Dictionary` | Extend, don't replace |
| Portrait display | `dialogue_ui.gd` (existing) | Add 1 more portrait slot |
| Input handling | `dialogue_manager.gd` `_on_action_pressed` | Extend with 3 new actions |
| NPC data lookup | `ResourceRegistry.get_resource(npc_id)` | Same — works for new NPCs |

## Risks Specific to S7-005

1. **Backwards compat with existing NPCs**: Existing NPCs (Vera, Marlow, courier) don't have `companion_trees` field. The new code must handle this gracefully (use default tree).
   - **Mitigation**: Use the `in` operator to check before reading. Fall back to default tree.

2. **Shift+1/2/3 conflicts with existing input**: Existing input map has `Shift+1/2/3` for ... let me check. The current input map uses 1/2/3 for weapon selection. Shift+1/2/3 is free.
   - **Mitigation**: Verify in tests. If conflict, use a different key (e.g., F1/F2/F3).

3. **NPC portrait asset reuse**: The companion portrait uses the existing NPC portrait (e.g., 霜尾's portrait = 霜尾's NPC portrait in the world). This is fine if the portrait is generic enough.
   - **Mitigation**: If the portrait looks weird in dialogue (e.g., it's a full-body shot, not a headshot), create a separate "dialogue portrait" asset. For S7-005, reuse the existing.

4. **The "main character portrait" is currently not displayed** (NPC portrait is on the left, dialogue box on the right). Adding the main character + companion portraits might require UI rework.
   - **Mitigation**: Layout the 3 portraits in a row at the top of the dialogue UI. Each portrait is 64×64.

## Out of Scope (for S7-005 only)

- Companion-specific quest flags (S7-013 — Should-Have)
- Trust / affinity system (deferred per GDD §3.9 OQ2)
- Voice acting for companions (deferred)
- 3-character dialogue (all 3 companions + NPC at once) — not in current design

## Acceptance Test (Manual F5 Verification)

1. Start a new game, F5. Recruit 霜尾 (Ch4 mid).
2. Approach an NPC (e.g., Vera in Ch1 Room 0). Before pressing E, press **Shift+2** (select 霜尾 as the in-dialogue companion).
3. Press E. Dialogue starts. The dialogue UI shows 3 portraits: main character (left), 霜尾 (middle), Vera (right).
4. The dialogue text is 霜尾's specific lines (if the NPC has companion-specific trees; otherwise, default).
5. Press **Shift+1** (switch to 漫游者 as the in-dialogue companion).
6. The dialogue UI updates to show 漫游者's portrait (middle).
7. The dialogue text updates if the companion override applies.
8. End the dialogue. The in-dialogue companion resets to default (the active mech's pilot).
9. Save and reload. The in-dialogue companion state is preserved.
10. Open the same NPC's dialogue again without pressing Shift — the default companion (active mech's pilot) is used.

If all 10 steps work, S7-005 is complete.
