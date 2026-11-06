class_name NativeAudioDirector
extends Node

## Procedural placeholder SFX keeps the prototype self-contained. Replace these
## generated streams with approved mastered assets before release.

enum Cue { TAP, SHAKE, REVEAL, WIN }

const SAMPLE_RATE := 22_050
const PLAYER_COUNT := 4

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []

func _ready() -> void:
	_streams = {
		Cue.TAP: _make_tone(740.0, 0.045, 0.14, 1.35),
		Cue.SHAKE: _make_tone(150.0, 0.20, 0.10, 0.78),
		Cue.REVEAL: _make_tone(520.0, 0.10, 0.13, 1.08),
		Cue.WIN: _make_chime(),
	}
	for _index in PLAYER_COUNT:
		var player := AudioStreamPlayer.new()
		player.volume_db = -9.0
		add_child(player)
		_players.append(player)

func play(cue: Cue) -> void:
	if not GameSettings.sound_enabled or not _streams.has(cue):
		return
	var player := _available_player()
	player.stream = _streams[cue]
	player.play()

func _available_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player
	return _players[0]

func _make_tone(frequency: float, seconds: float, amplitude: float, overtone: float) -> AudioStreamWAV:
	var frame_count := int(SAMPLE_RATE * seconds)
	var samples := PackedByteArray()
	samples.resize(frame_count * 2)
	for frame in frame_count:
		var time := float(frame) / SAMPLE_RATE
		var envelope := pow(1.0 - float(frame) / frame_count, 2.2)
		var waveform := (sin(TAU * frequency * time) + 0.18 * sin(TAU * frequency * overtone * time)) * amplitude * envelope
		_write_pcm16(samples, frame * 2, waveform)
	return _to_stream(samples)

func _make_chime() -> AudioStreamWAV:
	var seconds := 0.42
	var frame_count := int(SAMPLE_RATE * seconds)
	var samples := PackedByteArray()
	samples.resize(frame_count * 2)
	for frame in frame_count:
		var time := float(frame) / SAMPLE_RATE
		var envelope := pow(1.0 - float(frame) / frame_count, 1.7)
		var waveform := (
			sin(TAU * 659.25 * time)
			+ 0.55 * sin(TAU * 783.99 * time)
			+ 0.25 * sin(TAU * 987.77 * time)
		) * 0.12 * envelope
		_write_pcm16(samples, frame * 2, waveform)
	return _to_stream(samples)

func _to_stream(samples: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = samples
	return stream

func _write_pcm16(samples: PackedByteArray, offset: int, value: float) -> void:
	var integer_sample := int(clamp(value, -1.0, 1.0) * 32_767.0)
	samples[offset] = integer_sample & 0xff
	samples[offset + 1] = (integer_sample >> 8) & 0xff
