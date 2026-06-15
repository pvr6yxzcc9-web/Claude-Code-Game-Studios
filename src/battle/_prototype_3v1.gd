extends Control
# 3v1 战斗原型 (Sprint 7-001 MVP)
#
# 这是 **最小可运行原型** - 不替代现有 BattleScene。
# 当 state_battle 激活时,这个原型**叠加**显示一个 3v1 战斗框:
# - 1 个敌人 (右侧)
# - 3 个玩家机甲 (左侧, 垂直堆叠)
# - 按 1/2/3 切换 active mech
# - 按 空格 攻击 (active mech 攻击敌人)
# - 敌人每回合攻击 1 次 (active mech)
# - 所有 3 个机甲被打败 = 战斗失败
#
# **这是演示** - 真正的 S7-001 还需要:
# - Pilot-mech 切换 (Tab)
# - 武器 / 弹药系统
# - Pilot 特殊能力
# - 城镇医馆复活 (S7-006)
# - 完整 HUD (S7-004)
# - 真实敌人 .tres 资源
#
# 这个原型**只**验证 3 角色 vs 1 敌人的基本战斗循环。

# === 数据模型 ===

# 3 个玩家机甲 (简化版 - 没有武器槽, 没有 part HP, 只有总 HP)
var party_mechs: Array = [
    {
        "id": "ranger",
        "name": "漫游者",
        "max_hp": 400,
        "hp": 400,
        "is_active": true,  # 默认第一个是 active
    },
    {
        "id": "frostbite",
        "name": "霜尾",
        "max_hp": 320,
        "hp": 320,
        "is_active": false,
    },
    {
        "id": "bomber",
        "name": "轰天",
        "max_hp": 480,
        "hp": 480,
        "is_active": false,
    },
]

var active_mech_index: int = 0  # 当前是 party_mechs 哪个

# 1 个敌人 (简化版)
var enemy: Dictionary = {
    "name": "测试敌人 (Scavenger)",
    "max_hp": 200,
    "hp": 200,
    "attack": 15,
}

# 战斗状态
var in_combat: bool = false
var player_phase: bool = true  # true = 玩家回合, false = 敌人回合
var round_number: int = 0
var mechs_acted_this_round: Array = []  # 已经行动过的 mech index

# === UI 节点 (在 _ready 中创建) ===

var _bg: ColorRect
var _title: Label
var _enemy_label: Label
var _enemy_hp_label: Label
var _mech_labels: Array = []  # 3 个 mech label
var _mech_hp_labels: Array = []
var _mech_active_borders: Array = []  # 3 个边框 (active 的亮黄)
var _status_label: Label
var _help_label: Label

# === 生命周期 ===

func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    z_index = 100  # 在现有 BattleScene 之上
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build_ui()
    hide()
    # 监听 state_battle
    var sm: Node = get_node_or_null("/root/GameStateMachine")
    if sm != null:
        sm.state_changed.connect(_on_state_changed)
    print("[3v1 Prototype] ready. Press T in any state to start a test battle.")

func _build_ui() -> void:
    # 背景
    _bg = ColorRect.new()
    _bg.color = Color(0.0, 0.0, 0.0, 0.85)
    _bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(_bg)
    # 标题
    _title = Label.new()
    _title.text = "3v1 BATTLE PROTOTYPE (Sprint 7-001 MVP)"
    _title.position = Vector2(40, 20)
    _title.add_theme_font_size_override("font_size", 24)
    _title.add_theme_color_override("font_color", Color.YELLOW)
    add_child(_title)
    # 敌人 (右上)
    _enemy_label = Label.new()
    _enemy_label.position = Vector2(900, 100)
    _enemy_label.add_theme_font_size_override("font_size", 20)
    _enemy_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
    add_child(_enemy_label)
    _enemy_hp_label = Label.new()
    _enemy_hp_label.position = Vector2(900, 130)
    _enemy_hp_label.add_theme_font_size_override("font_size", 18)
    add_child(_enemy_hp_label)
    # 3 个玩家机甲 (左中, 垂直堆叠)
    for i in 3:
        var y: float = 200.0 + i * 100.0
        var mech_label: Label = Label.new()
        mech_label.position = Vector2(80, y)
        mech_label.add_theme_font_size_override("font_size", 20)
        add_child(mech_label)
        _mech_labels.append(mech_label)
        var hp_label: Label = Label.new()
        hp_label.position = Vector2(80, y + 30)
        hp_label.add_theme_font_size_override("font_size", 16)
        add_child(hp_label)
        _mech_hp_labels.append(hp_label)
        # Active 边框 (隐藏, 激活时显示)
        var border: ColorRect = ColorRect.new()
        border.color = Color(1.0, 0.9, 0.2, 0.5)
        border.position = Vector2(60, y - 10)
        border.size = Vector2(400, 60)
        border.visible = false
        add_child(border)
        _mech_active_borders.append(border)
    # 状态 + 帮助
    _status_label = Label.new()
    _status_label.position = Vector2(40, 540)
    _status_label.add_theme_font_size_override("font_size", 18)
    _status_label.add_theme_color_override("font_color", Color.WHITE)
    add_child(_status_label)
    _help_label = Label.new()
    _help_label.position = Vector2(40, 600)
    _help_label.add_theme_font_size_override("font_size", 14)
    _help_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
    _help_label.text = "[1/2/3] 切换 active mech | [SPACE] active mech 攻击 | [T] 启动测试战斗 | [ESC] 退出"
    add_child(_help_label)

# === 状态监听 ===

func _on_state_changed(_old: StringName, new: StringName) -> void:
    # 监听 state_battle: 在原 BattleScene 显示的同时, 我们的原型也显示 (叠加)
    if new == &"state_battle":
        # 不在这里启动战斗 (现有的 _enter_battle 会做)
        # 只显示 UI 框架
        show()
        _refresh()
    elif _old == &"state_battle":
        hide()
        _reset_combat()

# === 输入 ===

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_T:
                # 启动测试战斗 (无需触发 state_battle)
                _start_test_combat()
            KEY_1:
                if in_combat:
                    _set_active_mech(0)
            KEY_2:
                if in_combat:
                    _set_active_mech(1)
            KEY_3:
                if in_combat:
                    _set_active_mech(2)
            KEY_SPACE:
                if in_combat and player_phase:
                    _active_mech_attack()
            KEY_ESCAPE:
                if in_combat:
                    _end_combat()

# === 战斗流程 ===

func _start_test_combat() -> void:
    print("[3v1 Prototype] Starting test combat")
    in_combat = true
    player_phase = true
    round_number = 1
    mechs_acted_this_round = []
    # 重置 HP
    party_mechs[0]["hp"] = party_mechs[0]["max_hp"]
    party_mechs[1]["hp"] = party_mechs[1]["max_hp"]
    party_mechs[2]["hp"] = party_mechs[2]["max_hp"]
    enemy["hp"] = enemy["max_hp"]
    _set_active_mech(0)
    show()
    _refresh()

func _set_active_mech(index: int) -> void:
    if index < 0 or index >= party_mechs.size():
        return
    if party_mechs[index]["hp"] <= 0:
        _status_label.text = "机甲 %s 已被击败! 切换失败" % party_mechs[index]["name"]
        return
    for i in 3:
        party_mechs[i]["is_active"] = (i == index)
    active_mech_index = index
    _status_label.text = "Active mech: %s" % party_mechs[index]["name"]
    _refresh()

func _active_mech_attack() -> void:
    if not in_combat or not player_phase:
        return
    var mech: Dictionary = party_mechs[active_mech_index]
    if mech["hp"] <= 0:
        _status_label.text = "%s 已倒下, 不能攻击" % mech["name"]
        return
    # 简化: 固定伤害 20-30
    var damage: int = randi_range(20, 30)
    enemy["hp"] = max(0, enemy["hp"] - damage)
    print("[3v1 Prototype] %s attacks enemy for %d damage" % [mech["name"], damage])
    _status_label.text = "%s 攻击! 造成 %d 伤害" % [mech["name"], damage]
    mechs_acted_this_round.append(active_mech_index)
    _refresh()
    if enemy["hp"] <= 0:
        _victory()
        return
    # 检查是否所有 mech 都行动了 → 敌人回合
    if mechs_acted_this_round.size() >= 3 or _all_living_mechs_acted():
        _enemy_turn()

func _all_living_mechs_acted() -> bool:
    for i in 3:
        if party_mechs[i]["hp"] > 0 and i not in mechs_acted_this_round:
            return false
    return true

func _enemy_turn() -> void:
    player_phase = false
    _status_label.text = "敌人回合..."
    _refresh()
    await get_tree().create_timer(1.0).timeout
    # 敌人攻击 active mech (如果有 HP)
    if party_mechs[active_mech_index]["hp"] > 0:
        var target: Dictionary = party_mechs[active_mech_index]
        target["hp"] = max(0, target["hp"] - enemy["attack"])
        print("[3v1 Prototype] Enemy attacks %s for %d damage" % [target["name"], enemy["attack"]])
        _status_label.text = "敌人攻击 %s! 造成 %d 伤害" % [target["name"], enemy["attack"]]
        if target["hp"] <= 0:
            _status_label.text = "%s 被打倒了!" % target["name"]
            # 切换到下一个活着的 mech
            var next_alive: int = -1
            for i in 3:
                if party_mechs[i]["hp"] > 0:
                    next_alive = i
                    break
            if next_alive == -1:
                _defeat()
                return
            _set_active_mech(next_alive)
    else:
        # Active mech 已倒下, 攻击下一个
        for i in 3:
            if party_mechs[i]["hp"] > 0:
                _set_active_mech(i)
                var target: Dictionary = party_mechs[i]
                target["hp"] = max(0, target["hp"] - enemy["attack"])
                _status_label.text = "敌人攻击 %s! 造成 %d 伤害" % [target["name"], enemy["attack"]]
                if target["hp"] <= 0:
                    _status_label.text = "%s 被打倒了!" % target["name"]
                break
    # 玩家回合
    await get_tree().create_timer(0.5).timeout
    round_number += 1
    mechs_acted_this_round = []
    player_phase = true
    _status_label.text = "Round %d: 玩家回合" % round_number
    _refresh()

func _victory() -> void:
    _status_label.text = "胜利! 敌人被击败"
    print("[3v1 Prototype] VICTORY")
    in_combat = false
    _refresh()

func _defeat() -> void:
    _status_label.text = "失败! 所有机甲被击败 (漫游者 Game Over)"
    print("[3v1 Prototype] DEFEAT")
    in_combat = false
    _refresh()

func _end_combat() -> void:
    in_combat = false
    _reset_combat()
    _status_label.text = "测试战斗已退出"

func _reset_combat() -> void:
    in_combat = false
    player_phase = true
    mechs_acted_this_round = []
    for i in 3:
        party_mechs[i]["hp"] = party_mechs[i]["max_hp"]
        party_mechs[i]["is_active"] = (i == 0)
    active_mech_index = 0
    enemy["hp"] = enemy["max_hp"]

# === UI 刷新 ===

func _refresh() -> void:
    # 敌人
    _enemy_label.text = "%s" % enemy["name"]
    _enemy_hp_label.text = "HP: %d / %d" % [enemy["hp"], enemy["max_hp"]]
    # 3 个机甲
    for i in 3:
        var m: Dictionary = party_mechs[i]
        _mech_labels[i].text = "%d. %s%s" % [i + 1, m["name"], " [ACTIVE]" if m["is_active"] else ""]
        _mech_hp_labels[i].text = "  HP: %d / %d%s" % [m["hp"], m["max_hp"], " [DOWN]" if m["hp"] <= 0 else ""]
        _mech_active_borders[i].visible = m["is_active"]
