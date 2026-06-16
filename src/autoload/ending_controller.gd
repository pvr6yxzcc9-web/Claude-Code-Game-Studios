extends Node

# EndingController (S10-018) — rewritten for 4 full endings with narrative weight.
# Per sprint-10-sat5-climax.md + multi-satellite-arc.md §5.3
#
# Endings:
#   A "仁慈的终结" / Merciful: Player has 5 truths + 苍穹号 + ranger as pilot
#   B "循环延续" / Cycle Continues: Player has 5 truths, no 苍穹号
#   C "融合" / Fusion: Player has <5 truths, ranger + 苍穹号
#   D "隐藏之路" / Hidden Path: Player chose "Flee" from the Creator chamber
#
# Thresholds (per multi-satellite-arc.md):
#   5+ truths (all 5 satellites) → can reach A, B, or C depending on choices
#   <5 truths → only C or D (default fallback)
#   苍穹号 unlocked + ranger as pilot → unlocks A path
#   "Flee" choice in Creator chamber → D
#   "Destroy" choice + 5 truths + 苍穹号 → A
#   "Destroy" choice + 5 truths, no 苍穹号 → B
#   "Destroy" choice + <5 truths → C (default)
#   "Understand" / "Transcend" → special A variants (foreshadowed)

const ENDING_A_TREE_ID: StringName = &"dlg_ending_A_merciful"
const ENDING_B_TREE_ID: StringName = &"dlg_ending_B_cycle"
const ENDING_C_TREE_ID: StringName = &"dlg_ending_C_fusion"
const ENDING_D_TREE_ID: StringName = &"dlg_ending_D_hidden"

signal ending_chosen(tree_id: StringName, ending_letter: String)
signal ending_post_credit_started(ending_letter: String)
signal ending_post_credit_finished(ending_letter: String)
signal ending_saved(ending_letter: String)

# Choice made in Creator chamber (per S10-013)
enum CreatorChoice { NOT_CHOSEN, TRANSCEND, UNDERSTAND, DESTROY, FLEE }

var _creator_choice: int = CreatorChoice.NOT_CHOSEN
var _truths_unlocked: int = 0
var _cangqiong_unlocked: bool = false
var _reached_ending: String = ""

# Post-credits scenes (S10-014/015/016/017)
const ENDING_POSTCREDIT_SCENES: Dictionary = {
	"A": {
		"years_later": 10,
		"title": "仁慈的终结 / The Merciful End",
		"description": "Player runs a small museum of the 5 satellites, teaching the next generation.",
	},
	"B": {
		"years_later": 1000,
		"title": "循环延续 / The Cycle Continues",
		"description": "Player's descendant encounters a new Creator seeded from old fragments.",
	},
	"C": {
		"years_later": 50,
		"title": "融合 / Fusion",
		"description": "Frostbite and Bomber tend a small shrine on Sat-1.",
	},
	"D": {
		"years_later": 1,
		"title": "隐藏之路 / The Hidden Path",
		"description": "The Creator has left; humanity is left alone; biosphere collapses.",
	},
}

func _ready() -> void:
	print("[EndingController] ready (S10-018 — 4 endings with full narrative weight)")

# Set the player's choice in the Creator chamber (called from dialogue)
func set_creator_choice(choice: int) -> void:
	_creator_choice = choice
	print("[EndingController] Creator choice: %s" % CreatorChoice.keys()[choice])

# Update game state used by determine_ending
func update_state(truths_unlocked: int, cangqiong_unlocked: bool) -> void:
	_truths_unlocked = truths_unlocked
	_cangqiong_unlocked = cangqiong_unlocked

# Determine which ending the player gets.
# Per multi-satellite-arc.md §5.3 decision tree:
func determine_ending() -> String:
	# D: chose "Flee" — always D
	if _creator_choice == CreatorChoice.FLEE:
		_reached_ending = "D"
		ending_chosen.emit(ENDING_D_TREE_ID, "D")
		return ENDING_D_TREE_ID
	# A: "Destroy" + 5 truths + cangqiong → A (Merciful)
	if _creator_choice == CreatorChoice.DESTROY and _truths_unlocked >= 5 and _cangqiong_unlocked:
		_reached_ending = "A"
		ending_chosen.emit(ENDING_A_TREE_ID, "A")
		return ENDING_A_TREE_ID
	# B: "Destroy" + 5 truths, no cangqiong → B (Cycle Continues)
	if _creator_choice == CreatorChoice.DESTROY and _truths_unlocked >= 5:
		_reached_ending = "B"
		ending_chosen.emit(ENDING_B_TREE_ID, "B")
		return ENDING_B_TREE_ID
	# C: "Destroy" + <5 truths → C (Fusion)
	if _creator_choice == CreatorChoice.DESTROY:
		_reached_ending = "C"
		ending_chosen.emit(ENDING_C_TREE_ID, "C")
		return ENDING_C_TREE_ID
	# TRANSCEND / UNDERSTAND are special "A variants" but for now → A
	if _creator_choice == CreatorChoice.TRANSCEND or _creator_choice == CreatorChoice.UNDERSTAND:
		_reached_ending = "A"
		ending_chosen.emit(ENDING_A_TREE_ID, "A")
		return ENDING_A_TREE_ID
	# Default (no choice made yet) → C
	_reached_ending = "C"
	ending_chosen.emit(ENDING_C_TREE_ID, "C")
	return ENDING_C_TREE_ID

# Play the chosen ending. Caller (Creator chamber dialogue) calls this.
func play_ending() -> Error:
	var tree_id: StringName = determine_ending()
	var reg: Node = get_node("/root/ResourceRegistry")
	var tree: Resource = reg.get_resource(tree_id)
	if tree == null:
		push_error("EndingController: tree %s not found" % tree_id)
		return ERR_DOES_NOT_EXIST
	var dm: Node = get_node("/root/DialogueManager")
	var npc: Resource = Resource.new()
	npc.set("id", &"_ending_%s" % _reached_ending)
	npc.set("display_name", "The Convoy")
	npc.set("dialogue_tree_id", tree_id)
	var err: int = dm.start_dialogue_with_tree(tree, npc)
	if err == OK:
		# After dialogue ends, post-credit scene + save stamp
		dm.dialogue_ended.connect(_on_ending_dialogue_ended.bind(_reached_ending), CONNECT_ONE_SHOT)
	return err

func _on_ending_dialogue_ended(letter: String) -> void:
	# Play post-credit scene (UI scene, S10-014..S10-017)
	play_post_credit_scene(letter)
	# Save ending stamp
	save_ending_stamp(letter)

func play_post_credit_scene(letter: String) -> void:
	ending_post_credit_started.emit(letter)
	print("[EndingController] playing post-credit scene for ending %s" % letter)
	# Trigger the PostCreditScene UI (S10-014..S10-017)
	# The scene is loaded on-demand (not autoloaded) to avoid resource bloat
	var pcs_script: Script = load("res://src/ui/post_credit_scene.gd")
	if pcs_script == null:
		push_warning("EndingController: PostCreditScene script not found")
		ending_post_credit_finished.emit(letter)
		return
	# Get the scene tree root
	var tree: SceneTree = Engine.get_main_loop()
	if tree == null:
		ending_post_credit_finished.emit(letter)
		return
	var pcs: Control = pcs_script.new()
	tree.root.add_child.call_deferred(pcs)
	# Wait one frame for add_child to complete, then play
	pcs.play_post_credit.call_deferred(letter)
	# Listen for close to emit our signal
	pcs.closed.connect(_on_post_credit_closed.bind(letter), CONNECT_ONE_SHOT)

func _on_post_credit_closed(_letter: String) -> void:
	ending_post_credit_finished.emit(_letter)

func save_ending_stamp(letter: String) -> void:
	var meta: Node = get_node_or_null("/root/MetaState")
	if meta == null:
		return
	if meta.has_method("set_ending_reached"):
		meta.set_ending_reached(letter)
	ending_saved.emit(letter)
	print("[EndingController] saved ending %s" % letter)

# === Public helpers ===

func get_reached_ending() -> String:
	return _reached_ending

func get_creator_choice() -> int:
	return _creator_choice

func get_post_credit_info(letter: String) -> Dictionary:
	return ENDING_POSTCREDIT_SCENES.get(letter, {})

# === Save/Load ===

func get_state_snapshot() -> Dictionary:
	return {
		"creator_choice": _creator_choice,
		"truths_unlocked": _truths_unlocked,
		"cangqiong_unlocked": _cangqiong_unlocked,
		"reached_ending": _reached_ending,
	}

func load_snapshot(snap: Dictionary) -> Error:
	if snap.has("creator_choice"):
		_creator_choice = int(snap["creator_choice"])
	if snap.has("truths_unlocked"):
		_truths_unlocked = int(snap["truths_unlocked"])
	if snap.has("cangqiong_unlocked"):
		_cangqiong_unlocked = bool(snap["cangqiong_unlocked"])
	if snap.has("reached_ending"):
		_reached_ending = String(snap["reached_ending"])
	return OK