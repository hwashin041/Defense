extends Node

# Procedural chiptune audio: no external sound files or licenses required.
const SAMPLE_RATE = 22050
const TAU_F = PI * 2.0
const SONG = [392.0, 523.25, 587.33, 659.25, 587.33, 523.25, 440.0, 392.0, 349.23, 440.0, 523.25, 587.33, 523.25, 440.0, 392.0, 0.0]
var music_player: AudioStreamPlayer
var effect_players: Array[AudioStreamPlayer] = []
var music_cache: Dictionary = {}
var effect_cache: Dictionary = {}
var beat := 0
var beat_clock := 0.0
var muted := false

func _ready() -> void:
    music_player = AudioStreamPlayer.new()
    music_player.volume_db = -21.0
    add_child(music_player)
    for i in range(10):
        var p := AudioStreamPlayer.new()
        p.volume_db = -12.0
        add_child(p)
        effect_players.append(p)
    for n in SONG:
        if n > 0.0 and not music_cache.has(n):
            music_cache[n] = make_tone(n, 0.22, 0.32, "soft")
    effect_cache["place"] = make_tone(659.25, 0.18, 0.65, "bell")
    effect_cache["shoot"] = make_tone(440.0, 0.075, 0.30, "pop")
    effect_cache["kill"] = make_tone(880.0, 0.13, 0.55, "bell")
    effect_cache["start"] = make_tone(523.25, 0.35, 0.60, "bell")
    effect_cache["hurt"] = make_tone(165.0, 0.24, 0.65, "buzz")
    effect_cache["win"] = make_tone(783.99, 0.55, 0.75, "bell")
    effect_cache["lose"] = make_tone(196.0, 0.58, 0.65, "soft")

func _process(delta: float) -> void:
    if muted:
        return
    beat_clock -= delta
    if beat_clock <= 0.0:
        beat_clock += 0.29
        var note: float = SONG[beat % SONG.size()]
        beat += 1
        if note > 0.0:
            music_player.stream = music_cache[note]
            music_player.play()

func make_tone(freq: float, seconds: float, volume: float, style: String) -> AudioStreamWAV:
    var total := int(SAMPLE_RATE * seconds)
    var pcm := PackedByteArray()
    pcm.resize(total * 2)
    for i in range(total):
        var t := float(i) / float(SAMPLE_RATE)
        var phase := TAU_F * freq * t
        var attack := minf(1.0, t / 0.012)
        var release := pow(maxf(0.0, 1.0 - t / seconds), 2.0)
        var s := sin(phase)
        match style:
            "bell":
                s = 0.8 * sin(phase) + 0.2 * sin(phase * 2.01)
            "pop":
                s = sin(phase * (1.0 + 0.25 * (1.0 - t / seconds)))
            "buzz":
                s = 0.65 * sin(phase) + 0.35 * sin(phase * 3.0)
            _:
                s = 0.78 * sin(phase) + 0.22 * sin(phase * 0.5)
        var value := int(clampf(s * attack * release * volume, -1.0, 1.0) * 32767.0)
        pcm[i * 2] = value & 255
        pcm[i * 2 + 1] = (value >> 8) & 255
    var wav := AudioStreamWAV.new()
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.mix_rate = SAMPLE_RATE
    wav.stereo = false
    wav.data = pcm
    return wav

func effect(name: String) -> void:
    if muted or not effect_cache.has(name):
        return
    for p in effect_players:
        if not p.playing:
            p.stream = effect_cache[name]
            p.play()
            return

func toggle_mute() -> void:
    muted = not muted
    if muted:
        music_player.stop()
        for p in effect_players:
            p.stop()
    else:
        beat_clock = 0.0
