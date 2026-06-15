extends Node

# AudioManager (S6-018) — central volume + mute control.
# Owns the master bus volume_db and mute state. UI sliders call
# set_master_db() / set_mute() and broadcast via the volume_changed signal.
# Settings persist to MetaState on change so they survive restarts.
#
# Why not per-channel (SFX/music) volumes? Both SFXPlayer and MusicPlayer
# route through the "Master" bus. To get per-channel control we'd need
# to add SFX and Music buses in project.godot's audio_bus_layout.
# That's a follow-up; for now master + mute covers 90% of user need.
#
# dB scale: -30 (effectively silent) to 0 (full volume), 0 = default.

signal volume_changed(db: float)
signal mute_changed(muted: bool)

const MIN_DB: float = -30.0
const MAX_DB: float = 0.0
const DEFAULT_DB: float = 0.0

var _db: float = DEFAULT_DB
var _muted: bool = false

func _ready() -> void:
	# Restore persisted settings from MetaState
	var meta: Node = get_node_or_null("/root/MetaState")
	if meta != null:
		if "audio_db" in meta:
			_db = clamp(float(meta.audio_db), MIN_DB, MAX_DB)
		if "audio_muted" in meta:
			_muted = bool(meta.audio_muted)
	_apply_to_bus()
	print("[AudioManager] ready: db=%.1f muted=%s" % [_db, _muted])

func get_db() -> float:
	return _db

func is_muted() -> bool:
	return _muted

# S6-018: set master volume in dB. Clamped to [MIN_DB, MAX_DB].
# Persists to MetaState for cross-session persistence.
func set_master_db(db: float) -> void:
	_db = clamp(db, MIN_DB, MAX_DB)
	_apply_to_bus()
	_persist()
	volume_changed.emit(_db)

# S6-018: mute toggle. When muted, bus volume goes to MIN_DB;
# when unmuted, restores last _db. So a player can mute + unmute
# without losing their original slider position.
func set_muted(muted: bool) -> void:
	_muted = muted
	_apply_to_bus()
	_persist()
	mute_changed.emit(_muted)

func toggle_mute() -> void:
	set_muted(not _muted)

func _apply_to_bus() -> void:
	# When muted, force to MIN_DB. When not muted, use _db.
	var effective: float = MIN_DB if _muted else _db
	# Find the Master bus index (always 0 by convention)
	var master_idx: int = AudioServer.get_bus_index("Master")
	if master_idx == -1:
		push_warning("[AudioManager] Master bus not found")
		return
	AudioServer.set_bus_volume_db(master_idx, effective)
	# Also update SFXPlayer and MusicPlayer volume to reflect new effective
	var sfx: Node = get_node_or_null("/root/SFXPlayer")
	if sfx != null and sfx.has_method("set_volume_db"):
		sfx.set_volume_db(effective)
	var music: Node = get_node_or_null("/root/MusicPlayer")
	if music != null and music.has_method("set_volume_db"):
		music.set_volume_db(effective)

func _persist() -> void:
	var meta: Node = get_node_or_null("/root/MetaState")
	if meta != null:
		meta.set("audio_db", _db)
		meta.set("audio_muted", _muted)
