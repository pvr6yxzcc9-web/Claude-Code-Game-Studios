extends Node

# SFXPlayer — S2-021 (procedural), S6-010 (real .wav files).
# Plays short synthesized WAV files for attack/damage/UI events.
# Falls back to procedural beeps if the .wav file is missing (dev safety).

# S6-010: cached on _ready. 5 stream variants:
#   attack_blaster, attack_railgun, attack_plasma, hit_enemy, ui_click
# Weapon attack picks a stream by slot index (0=blaster, 1=railgun, 2=plasma)
# or by weapon_id if provided.
const _SFX_DIR: StringName = &"res://assets/audio/sfx/"
const _FALLBACK_FREQ: float = 220.0  # used if .wav file is missing

var _player: AudioStreamPlayer = null
var _streams: Dictionary[StringName, AudioStreamWAV] = {}
var _loaded_ok: bool = false

func _ready() -> void:
    _player = AudioStreamPlayer.new()
    _player.bus = "Master"
    add_child(_player)
    _load_streams()
    print("[SFXPlayer] ready (loaded %d SFX files)" % _streams.size())

# S6-018: public API for AudioManager to set volume on this bus.
func set_volume_db(db: float) -> void:
    if _player != null:
        _player.volume_db = db

func _load_streams() -> void:
    for name in [&"attack_blaster", &"attack_railgun", &"attack_plasma", &"hit_enemy", &"ui_click"]:
        var path: String = String(_SFX_DIR) + String(name) + ".wav"
        if ResourceLoader.exists(path):
            _streams[name] = load(path) as AudioStreamWAV
    _loaded_ok = _streams.size() > 0

# S2-021 / S6-010: Play attack SFX. Picks stream by weapon_id if provided,
# else falls back to slot-based selection (0=blaster, 1=railgun, 2=plasma).
# weapon_id param optional: &"blaster_rifle" / &"railgun" / &"plasma_cannon" / etc.
func play_attack(slot: int = 0, weapon_id: StringName = &"") -> void:
    if _player == null:
        return
    var key: StringName = _weapon_to_sfx_key(weapon_id, slot)
    _play_stream_or_beep(key, _FALLBACK_FREQ + slot * 80.0, 0.12)

# S2-021 / S6-010: Hit/damage SFX.
func play_damage() -> void:
    if _player == null:
        return
    _play_stream_or_beep(&"hit_enemy", 110.0, 0.18)

# S2-021 / S6-010: UI click SFX.
func play_ui() -> void:
    if _player == null:
        return
    _play_stream_or_beep(&"ui_click", 660.0, 0.05)

# Map weapon_id to SFX key. Unknown weapons get the blaster shot.
func _weapon_to_sfx_key(weapon_id: StringName, slot: int) -> StringName:
    if weapon_id != &"":
        var wid: String = String(weapon_id)
        if wid.contains("rail") or wid.contains("sniper"):
            return &"attack_railgun"
        if wid.contains("plasma") or wid.contains("cannon") or wid.contains("arc"):
            return &"attack_plasma"
        # blaster / shotgun / mine fall through to blaster
        if wid != &"":
            return &"attack_blaster"
    # Fallback: slot-based
    match slot:
        0: return &"attack_blaster"
        1: return &"attack_railgun"
        2: return &"attack_plasma"
        _: return &"attack_blaster"

func _play_stream_or_beep(key: StringName, fallback_freq: float, fallback_dur: float) -> void:
    if _loaded_ok and _streams.has(key):
        _player.stream = _streams[key]
    else:
        _player.stream = _make_beep(fallback_freq, fallback_dur)
    _player.play()

# Procedural sine-wave beep as AudioStreamWAV (16-bit PCM mono). Fallback
# only — S6-010 ships real .wav files.
func _make_beep(freq_hz: float, duration_s: float) -> AudioStreamWAV:
    var sample_rate: int = 22050
    var sample_count: int = int(sample_rate * duration_s)
    var data: PackedByteArray = PackedByteArray()
    data.resize(sample_count * 2)
    for i in sample_count:
        var t: float = float(i) / float(sample_rate)
        var env: float = 1.0 - (t / duration_s)
        var sample_value: float = sin(2.0 * PI * freq_hz * t) * env * 0.4
        var int_sample: int = int(sample_value * 32767.0)
        int_sample = clamp(int_sample, -32768, 32767)
        var lo: int = int_sample & 0xFF
        var hi: int = (int_sample >> 8) & 0xFF
        data[i * 2] = lo
        data[i * 2 + 1] = hi
    var stream: AudioStreamWAV = AudioStreamWAV.new()
    stream.data = data
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = sample_rate
    stream.stereo = false
    return stream
