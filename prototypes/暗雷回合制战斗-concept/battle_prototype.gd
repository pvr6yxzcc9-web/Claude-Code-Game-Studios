extends Node2D

# PROTOTYPE - NOT FOR PRODUCTION（非生产代码）
# 假设：手动 / 自动双模式 + 弹药切换 在回合制战斗中是否好玩？
# 日期：2026-06-12
# 路径：Engine（Godot 4.6 + GDScript）
# 范围：1v1 战斗，3 武器 × 3 弹药，手动 + 自动模式，回合间弹药切换
# 砍掉：探索、NPC、图鉴、存档、多敌人、菜单、音效、教学

# === 数据定义 ===

# 3 武器 × 3 弹药 = 9 种组合
# 每种武器有基础伤害 + 命中率
# 每种弹药修改伤害并可能附加效果

const WEAPONS = {
    "laser":  {"name": "激光枪",   "base_damage": 20, "accuracy": 0.9, "range": "long"},
    "cannon": {"name": "粒子炮",   "base_damage": 35, "accuracy": 0.7, "range": "mid"},
    "missile":{"name": "导弹发射器", "base_damage": 50, "accuracy": 0.5, "range": "long"},
}

const AMMO = {
    "normal":  {"name": "普通弹",   "damage_mult": 1.0, "effect": "none"},
    "plasma":  {"name": "电浆弹",   "damage_mult": 1.3, "effect": "burn"},
    "tracker": {"name": "跟踪弹",   "damage_mult": 0.8, "effect": "ignore_evasion"},
}

# === STATE ===

var current_mode = "manual"  # "manual" or "auto"
var player_weapon = "laser"
var player_ammo = "normal"
var turn_phase = "player_input"  # "player_input", "player_action", "enemy_input", "enemy_action"

var player_hp = 200
var player_max_hp = 200
var enemy_hp = 150
var enemy_max_hp = 150

var log = []  # Battle log
var frame_count = 0

# === LIFECYCLE ===

func _ready():
    randomize()
    reset_battle()
    # Render the scene
    queue_redraw()
    # Input handling
    set_process_input(true)
    # Auto-battle tick
    set_process(true)

func reset_battle():
    player_hp = player_max_hp
    enemy_hp = enemy_max_hp
    current_mode = "manual"
    player_weapon = "laser"
    player_ammo = "normal"
    turn_phase = "player_input"
    log.clear()
    add_log("=== 战斗开始 ===")
    add_log("玩家: 激光枪 + 普通弹")
    add_log("敌人 HP: %d / %d" % [enemy_hp, enemy_max_hp])

# === INPUT ===

func _input(event):
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_A:
                # Toggle auto/manual
                toggle_mode()
            KEY_1:
                # 1 = switch to laser AND attack immediately
                player_weapon = "laser"
                add_log("切换武器 → 激光枪")
                if current_mode == "manual" and turn_phase == "player_input":
                    perform_player_action()
            KEY_2:
                player_weapon = "cannon"
                add_log("切换武器 → 粒子炮")
                if current_mode == "manual" and turn_phase == "player_input":
                    perform_player_action()
            KEY_3:
                player_weapon = "missile"
                add_log("切换武器 → 导弹发射器")
                if current_mode == "manual" and turn_phase == "player_input":
                    perform_player_action()
            KEY_Q:
                # Cycle ammo backwards
                cycle_ammo(-1)
            KEY_E:
                # Cycle ammo forwards
                cycle_ammo(1)
            KEY_D:
                # Defend
                if current_mode == "manual" and turn_phase == "player_input":
                    perform_player_defend()
            KEY_R:
                # Reset battle
                reset_battle()
    queue_redraw()

func toggle_mode():
    if current_mode == "manual":
        current_mode = "auto"
        add_log(">>> 切换到自动模式 (AI 接管)")
    else:
        current_mode = "auto"
        current_mode = "manual"
        add_log(">>> 切换到手动模式 (玩家控制)")

func cycle_ammo(direction):
    var ammo_keys = AMMO.keys()
    var current_idx = ammo_keys.find(player_ammo)
    var new_idx = (current_idx + direction) % ammo_keys.size()
    if new_idx < 0:
        new_idx += ammo_keys.size()
    player_ammo = ammo_keys[new_idx]
    add_log("切换弹药 → %s" % AMMO[player_ammo].name)

# === PLAYER ACTIONS ===

func perform_player_action():
    if player_hp <= 0 or enemy_hp <= 0:
        return
    var weapon = WEAPONS[player_weapon]
    var ammo = AMMO[player_ammo]
    var damage = int(weapon.base_damage * ammo.damage_mult)
    # Accuracy check
    if randf() > weapon.accuracy:
        add_log("玩家攻击 → 命中失败（%s + %s）" % [weapon.name, ammo.name])
    else:
        enemy_hp = max(0, enemy_hp - damage)
        add_log("玩家攻击 → 命中！伤害 %d（%s + %s）" % [damage, weapon.name, ammo.name])
    # Move to enemy turn
    turn_phase = "enemy_input"

func perform_player_defend():
    add_log("玩家防御（减伤 50%）")
    # Add defend buff to player for next enemy attack
    player_defending = true
    turn_phase = "enemy_input"

var player_defending = false

# === ENEMY AI ===

func perform_enemy_action():
    # Simple enemy AI: attack player
    var damage = 25
    if player_defending:
        damage = int(damage * 0.5)
        add_log(">>> 防御生效")
    player_defending = false
    player_hp = max(0, player_hp - damage)
    add_log("敌人攻击 → 伤害 %d" % damage)
    # Back to player
    turn_phase = "player_input"
    check_battle_end()

# === AUTO MODE ===

func _process(delta):
    frame_count += 1
    # Auto mode: AI plays for the player
    if current_mode == "auto" and turn_phase == "player_input":
        if player_hp <= 0 or enemy_hp <= 0:
            return
        # Wait a bit for player to see what's happening
        if frame_count % 60 == 0:  # Every 1 second at 60fps
            # Auto-AI decision: use the highest damage weapon
            # For now, just always attack with current weapon
            perform_player_action()

    # Enemy action: also slowed for visibility
    if turn_phase == "enemy_input":
        if frame_count % 30 == 0:  # 0.5 second delay
            perform_enemy_action()

    queue_redraw()

# === LOGIC ===

func add_log(message):
    log.append(message)
    if log.size() > 10:
        log.pop_front()

func check_battle_end():
    if enemy_hp <= 0:
        add_log("=== 胜利！ ===")
        turn_phase = "battle_end"
    elif player_hp <= 0:
        add_log("=== 失败 ===")
        turn_phase = "battle_end"

# === RENDERING ===

func _draw():
    # Background
    draw_rect(Rect2(0, 0, 1024, 600), Color(0.05, 0.08, 0.12))
    # Title
    draw_string(ThemeDB.fallback_font, Vector2(20, 30), "Battle Core Prototype — Railhunter", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1))
    # Player
    draw_rect(Rect2(150, 300, 80, 100), Color(1.0, 0.42, 0.24))  # warm orange
    draw_string(ThemeDB.fallback_font, Vector2(150, 290), "玩家", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1))
    # Player HP bar
    draw_rect(Rect2(150, 420, 80, 12), Color(0.2, 0.2, 0.2))
    var player_hp_pct = float(player_hp) / float(player_max_hp)
    draw_rect(Rect2(150, 420, 80 * player_hp_pct, 12), Color(1.0, 0.42, 0.24))
    draw_string(ThemeDB.fallback_font, Vector2(150, 450), "HP %d/%d" % [player_hp, player_max_hp], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1))

    # Enemy
    draw_rect(Rect2(700, 320, 60, 60), Color(0.29, 0.87, 0.5))  # toxic green
    draw_string(ThemeDB.fallback_font, Vector2(700, 310), "敌人", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1))
    # Enemy HP bar
    draw_rect(Rect2(700, 400, 60, 12), Color(0.2, 0.2, 0.2))
    var enemy_hp_pct = float(enemy_hp) / float(enemy_max_hp)
    draw_rect(Rect2(700, 400, 60 * enemy_hp_pct, 12), Color(0.86, 0.15, 0.15))
    draw_string(ThemeDB.fallback_font, Vector2(700, 430), "HP %d/%d" % [enemy_hp, enemy_max_hp], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1))

    # Status panel (top right)
    var status_x = 450
    var status_y = 50
    draw_string(ThemeDB.fallback_font, Vector2(status_x, status_y), "模式: %s" % current_mode.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.22, 0.74, 0.97) if current_mode == "auto" else Color(1, 0.7, 0.2))
    draw_string(ThemeDB.fallback_font, Vector2(status_x, status_y + 30), "武器: %s" % WEAPONS[player_weapon].name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1))
    draw_string(ThemeDB.fallback_font, Vector2(status_x, status_y + 50), "弹药: %s" % AMMO[player_ammo].name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1))
    draw_string(ThemeDB.fallback_font, Vector2(status_x, status_y + 70), "回合: %s" % turn_phase, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.6, 0.6))

    # Battle log (bottom)
    var log_x = 20
    var log_y = 500
    for i in log.size():
        var msg = log[i]
        draw_string(ThemeDB.fallback_font, Vector2(log_x, log_y + i * 16), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.7, 0.7, 0.7))

    # Controls help (bottom right)
    var help_x = 700
    var help_y = 480
    draw_string(ThemeDB.fallback_font, Vector2(help_x, help_y), "=== 控制 ===", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1))
    draw_string(ThemeDB.fallback_font, Vector2(help_x, help_y + 20), "空格: 攻击（手动）", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.8, 0.8, 0.8))
    draw_string(ThemeDB.fallback_font, Vector2(help_x, help_y + 40), "A: 切换模式", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.8, 0.8, 0.8))
    draw_string(ThemeDB.fallback_font, Vector2(help_x, help_y + 60), "1/2/3: 切武器", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.8, 0.8, 0.8))
    draw_string(ThemeDB.fallback_font, Vector2(help_x, help_y + 80), "Q/E: 切弹药", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.8, 0.8, 0.8))
    draw_string(ThemeDB.fallback_font, Vector2(help_x, help_y + 100), "D: 防御  R: 重置", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.8, 0.8, 0.8))
