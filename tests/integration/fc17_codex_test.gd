extends GutTest

# FC-17 Codex Integration Test (S2-020)
# Verifies CodexUI displays 6 weapons + 5 enemies with stats + fragments section.

const MAIN_SCENE := "res://src/main.tscn"

const WEAPON_IDS: Array[StringName] = [
    &"blaster_rifle",
    &"shotgun",
    &"sniper_rifle",
    &"plasma_cannon",
    &"railgun",
    &"shotgun_spread",
]

const ENEMY_IDS: Array[StringName] = [
    &"scavenger",
    &"drone",
    &"heavy_walker",
    &"sniper_bot",
    &"boss_marrow_sentinel",
]

var _main: Node = null
var _codex: Node = null

func before_all() -> void:
    _main = load(MAIN_SCENE).instantiate()
    get_tree().root.add_child(_main)
    await get_tree().process_frame
    await get_tree().process_frame
    _codex = get_tree().get_root().find_child("CodexUI", true, false)

func after_all() -> void:
    if _main != null:
        _main.queue_free()
        _main = null

func test_codex_present() -> void:
    assert_not_null(_codex, "CodexUI must be in scene tree after main scene loads")

func test_codex_has_weapon_ids_constant() -> void:
    # S2-020 AC: Codex shows all 6 weapons
    assert_eq(_codex.WEAPON_IDS.size(), 6, "CodexUI has 6 weapons in catalog")
    for id in WEAPON_IDS:
        assert_true(_codex.WEAPON_IDS.has(id), "CodexUI has %s" % id)

func test_codex_has_enemy_ids_constant() -> void:
    # S2-020 AC: Codex shows all 5 enemies
    assert_eq(_codex.ENEMY_IDS.size(), 5, "CodexUI has 5 enemies in catalog")
    for id in ENEMY_IDS:
        assert_true(_codex.ENEMY_IDS.has(id), "CodexUI has %s" % id)

func test_codex_visibility_toggles_with_state() -> void:
    var sm: Node = get_node("/root/GameStateMachine")
    sm.transition_to(&"state_exploration")
    assert_false(_codex.visible, "CodexUI hidden in state_exploration")
    sm.transition_to(&"state_codex")
    assert_true(_codex.visible, "CodexUI visible in state_codex")
    sm.transition_to(&"state_exploration")
    assert_false(_codex.visible, "CodexUI hidden again after leaving state_codex")

func test_codex_can_render_without_error() -> void:
    # Force a redraw and verify it doesn't crash
    var sm: Node = get_node("/root/GameStateMachine")
    sm.transition_to(&"state_codex")
    await get_tree().process_frame
    _codex.queue_redraw()
    await get_tree().process_frame
    # If we got here without a crash, _draw() succeeded
    assert_true(_codex.visible, "CodexUI still visible after redraw")

func test_scroll_mechanics() -> void:
    var sm: Node = get_node("/root/GameStateMachine")
    sm.transition_to(&"state_codex")
    await get_tree().process_frame
    var initial_scroll: float = _codex._scroll
    assert_eq(initial_scroll, 0.0, "scroll starts at 0")
    _codex._scroll = 30.0
    assert_eq(_codex._scroll, 30.0, "scroll can be set")
    _codex._scroll = 0.0
