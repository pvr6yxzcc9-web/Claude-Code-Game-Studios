extends Control

# CodexUI (per hud.md + S2-020) — Label-based, no _draw (avoids Godot 4.6 HiDPI crash).
# Shows: unlocked story fragments, all weapons catalog (6), all enemies catalog (5).
# All sections visible in one scrollable view; W/S or PageUp/PageDown to scroll.

@export var unlocked_fragments: Array[StringName] = []

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

var _scroll: float = 0.0
var _max_scroll: float = 0.0

# UI elements (all created in _ready)
var _bg: ColorRect
var _content_labels: Array[Label] = []  # ordered Labels that get re-positioned on _refresh
var _scroll_indicator: ColorRect

func _ready() -> void:
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Background panel
	var rect_w: float = 800.0
	var rect_h: float = 600.0
	_bg = ColorRect.new()
	_bg.color = Color(0.05, 0.05, 0.1, 0.95)
	_bg.position = Vector2((1280 - rect_w) / 2, (720 - rect_h) / 2)
	_bg.size = Vector2(rect_w, rect_h)
	add_child(_bg)
	# Border (top + bottom stripes)
	var top: ColorRect = ColorRect.new()
	top.color = Color(0.6, 0.4, 1.0, 1)
	top.position = _bg.position
	top.size = Vector2(rect_w, 2)
	add_child(top)
	var bot: ColorRect = ColorRect.new()
	bot.color = Color(0.6, 0.4, 1.0, 1)
	bot.position = Vector2(_bg.position.x, _bg.position.y + rect_h - 2)
	bot.size = Vector2(rect_w, 2)
	add_child(bot)
	# Pre-allocate labels for content (will be re-populated each refresh)
	_create_content_labels()
	# Scroll indicator track
	var track: ColorRect = ColorRect.new()
	track.color = Color(0.2, 0.2, 0.3, 1)
	track.position = _bg.position + Vector2(rect_w - 8, 0)
	track.size = Vector2(4, rect_h)
	add_child(track)
	_scroll_indicator = ColorRect.new()
	_scroll_indicator.color = Color(0.6, 0.4, 1.0, 1)
	_scroll_indicator.position = track.position
	_scroll_indicator.size = Vector2(4, rect_h)
	add_child(_scroll_indicator)
	# Listen
	var sm: Node = get_node("/root/GameStateMachine")
	sm.state_changed.connect(_on_state_changed)
	var meta: Node = get_node("/root/MetaState")
	meta.fragment_unlocked.connect(_on_fragment_unlocked)
	_refresh()
	print("[CodexUI] ready")

func _create_content_labels() -> void:
	# We allocate enough labels to cover the largest possible content layout
	# Title + section headers + max items
	var needed: int = 1 + 3 + unlocked_fragments.size() + WEAPON_IDS.size() + ENEMY_IDS.size() + 5
	for i in needed:
		var lbl: Label = Label.new()
		lbl.visible = false
		add_child(lbl)
		_content_labels.append(lbl)

func _on_state_changed(_old: StringName, new: StringName) -> void:
	visible = (new == &"state_codex")
	if visible:
		_scroll = 0.0
		_refresh()

func _on_fragment_unlocked(_frag_id: StringName) -> void:
	_refresh()

func _refresh() -> void:
	var meta: Node = get_node("/root/MetaState")
	unlocked_fragments.clear()
	for key in meta.unlocked.keys():
		if bool(meta.unlocked[key]):
			unlocked_fragments.append(StringName(key))
	# Build text content as a list of (text, font_size, color) tuples
	var lines: Array = []
	lines.append(["CODEX", 24, Color(0.8, 0.6, 1.0, 1)])
	lines.append(["== FRAGMENTS (%d unlocked) ==" % unlocked_fragments.size(), 16, Color(0.7, 0.5, 0.9, 1)])
	var reg: Node = get_node("/root/ResourceRegistry")
	for frag_id in unlocked_fragments:
		var frag: Resource = reg.get_resource(frag_id)
		if frag == null:
			continue
		var title: String = String(frag.get("title"))
		var body: String = String(frag.get("body"))
		lines.append(["• " + title, 14, Color(1, 1, 1, 1)])
		var short_body: String = body.substr(0, 90) + ("..." if body.length() > 90 else "")
		lines.append(["  " + short_body, 11, Color(0.7, 0.7, 0.7, 1)])
	if unlocked_fragments.is_empty():
		lines.append(["(no fragments unlocked yet)", 12, Color(0.5, 0.5, 0.5, 1)])
	lines.append(["== WEAPONS (%d) ==" % WEAPON_IDS.size(), 16, Color(0.7, 0.5, 0.9, 1)])
	for wid in WEAPON_IDS:
		var w: Resource = reg.get_resource(wid)
		if w == null:
			continue
		var name: String = String(w.get("display_name"))
		var min_d: int = int(w.get("min_damage"))
		var max_d: int = int(w.get("max_damage"))
		var acc: float = float(w.get("accuracy"))
		var line: String = "• %s   DMG %d-%d   ACC %.0f%%" % [name, min_d, max_d, acc * 100]
		lines.append([line, 13, Color(1, 1, 1, 1)])
	lines.append(["== ENEMIES (%d) ==" % ENEMY_IDS.size(), 16, Color(0.7, 0.5, 0.9, 1)])
	for eid in ENEMY_IDS:
		var e: Resource = reg.get_resource(eid)
		if e == null:
			continue
		var ename: String = String(e.get("display_name"))
		var hp: int = int(e.get("max_hp"))
		var atk: int = int(e.get("attack"))
		var eacc: float = float(e.get("accuracy"))
		var is_boss: bool = bool(e.get("boss"))
		var prefix: String = "[BOSS] " if is_boss else "• "
		var color: Color = Color(1.0, 0.5, 0.3) if is_boss else Color(1, 1, 1)
		var line2: String = "%s%s   HP %d   ATK %d   ACC %.0f%%" % [prefix, ename, hp, atk, eacc * 100]
		lines.append([line2, 13, color])
	# Apply scroll: hide labels outside [scroll, scroll+600]
	var view_top: float = _scroll
	var view_bot: float = _scroll + 600.0
	var y: float = 0.0
	var line_h: float = 22.0
	var title_h: float = 30.0
	var header_h: float = 24.0
	var body_h: float = 22.0
	var small_h: float = 16.0
	var last_label_idx: int = 0
	for i in lines.size():
		var triple: Array = lines[i]
		var text: String = triple[0]
		var fs: int = int(triple[1])
		var color: Color = triple[2]
		# Compute line height
		var lh: float = title_h if fs >= 20 else (header_h if fs >= 16 else (body_h if fs >= 12 else small_h))
		# In view?
		if y + lh >= view_top and y <= view_bot:
			if last_label_idx < _content_labels.size():
				var lbl: Label = _content_labels[last_label_idx]
				lbl.text = text
				lbl.add_theme_font_size_override("font_size", fs)
				lbl.add_theme_color_override("font_color", color)
				lbl.position = _bg.position + Vector2(20, 20 + y - _scroll)
				lbl.visible = true
				last_label_idx += 1
		y += lh
	# Hide unused labels
	for j in range(last_label_idx, _content_labels.size()):
		_content_labels[j].visible = false
	# Update scroll indicator
	if lines.is_empty():
		_max_scroll = 0.0
	else:
		var total_h: float = y
		_max_scroll = max(0.0, total_h - 600.0 + 40.0)
	if _max_scroll > 0.0:
		var bar_h: float = 600.0 * (600.0 / (600.0 + _max_scroll))
		_scroll_indicator.size.y = bar_h
		_scroll_indicator.position.y = _bg.position.y + (600.0 - bar_h) * (_scroll / _max_scroll)
	else:
		_scroll_indicator.size.y = 600.0
		_scroll_indicator.position.y = _bg.position.y

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_page_down") or (event is InputEventKey and event.keycode == KEY_S and event.pressed):
		_scroll = min(_scroll + 60.0, _max_scroll)
		_refresh()
	elif event.is_action_pressed("ui_page_up") or (event is InputEventKey and event.keycode == KEY_W and event.pressed):
		_scroll = max(_scroll - 60.0, 0.0)
		_refresh()
