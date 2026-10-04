extends Node

var effects_player: AudioStreamPlayer
var muted := false
var level := 0.35
var sounds: Dictionary = {}

func _ready() -> void:
	effects_player = AudioStreamPlayer.new()
	effects_player.bus = &"SFX"
	add_child(effects_player)
	for event in ["add", "run", "success", "fail", "hint"]:
		sounds[event] = make_tone(event)
	_apply_volume()

func make_tone(event: String) -> AudioStreamWAV:
	var duration := 0.65 if event in ["success", "fail"] else 0.14
	var frequency: float = {"add": 660.0, "run": 180.0, "success": 523.25, "fail": 90.0, "hint": 420.0}[event]
	var count := int(duration * 22050)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / 22050.0
		var envelope := minf(t * 70.0, 1.0) * pow(1.0 - t / duration, 2.0)
		var wave := sin(TAU * frequency * t)
		if event == "success":
			wave = (wave + sin(TAU * frequency * 1.25 * t) + sin(TAU * frequency * 1.5 * t)) / 3.0
		data.encode_s16(i * 2, int(wave * envelope * 9500))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = data
	return stream

func play(event: String) -> void:
	if sounds.has(event) and not muted:
		effects_player.stream = sounds[event]
		effects_player.play()

func set_muted(value: bool) -> void:
	muted = value
	_apply_volume()

func set_level(value: float) -> void:
	level = clampf(value, 0.0, 1.0)
	_apply_volume()

func _apply_volume() -> void:
	var gain := level if not muted else 0.0
	effects_player.volume_db = linear_to_db(gain)
