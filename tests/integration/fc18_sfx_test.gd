extends GutTest

# FC-18 SFX Player Test (S2-021)
# Verifies SFXPlayer autoload + procedural beep generation + trigger from battle.

func test_sfx_player_autoload_present() -> void:
    var sfx: Node = get_node_or_null("/root/SFXPlayer")
    assert_not_null(sfx, "SFXPlayer autoload must be present")
    assert_true(sfx.has_method("play_attack"), "SFXPlayer has play_attack")
    assert_true(sfx.has_method("play_damage"), "SFXPlayer has play_damage")
    assert_true(sfx.has_method("play_ui"), "SFXPlayer has play_ui")

func test_play_attack_does_not_crash() -> void:
    var sfx: Node = get_node("/root/SFXPlayer")
    for slot in range(3):
        sfx.play_attack(slot)
        await get_tree().process_frame
    # No assertion needed — if it crashed, test would fail

func test_play_damage_does_not_crash() -> void:
    var sfx: Node = get_node("/root/SFXPlayer")
    sfx.play_damage()
    await get_tree().process_frame

func test_play_ui_does_not_crash() -> void:
    var sfx: Node = get_node("/root/SFXPlayer")
    sfx.play_ui()
    await get_tree().process_frame

func test_make_beep_returns_valid_wav() -> void:
    var sfx: Node = get_node("/root/SFXPlayer")
    var stream: AudioStreamWAV = sfx._make_beep(440.0, 0.1)
    assert_not_null(stream, "_make_beep returns AudioStreamWAV")
    assert_eq(stream.format, AudioStreamWAV.FORMAT_16_BITS, "beep is 16-bit PCM")
    assert_false(stream.stereo, "beep is mono")
    assert_eq(stream.mix_rate, 22050, "beep sample rate is 22050 Hz")
    # 0.1s at 22050 Hz = 2205 samples = 4410 bytes
    assert_eq(stream.data.size(), 4410, "0.1s beep = 4410 bytes")
