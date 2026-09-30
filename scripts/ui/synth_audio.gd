extends Node

var effects_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var muted := false
var level := 0.35
var music_enabled := false
var sounds: Dictionary = {}

func _ready() -> void:
	effects_player = AudioStreamPlayer.new()
	music_player = AudioStreamPlayer.new()
	add_child(effects_player)
	add_child(music_player)
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

func make_music() -> AudioStreamWAV:
	var rate := 22050
	var duration := 8.0
	var data := PackedByteArray()
	data.resize(int(duration * rate) * 2)
	var notes := [130.81, 155.56, 196.0, 233.08, 130.81, 196.0, 174.61, 155.56]
	for i in int(duration * rate):
		var t := float(i) / rate
		var beat := fmod(t, 0.25)
		var note: float = notes[int(t * 4.0) % notes.size()]
		var arp := sin(TAU * note * 2.0 * t) * exp(-beat * 15.0) * 0.18
		var bass := sin(TAU * 65.406 * t) * (0.55 + 0.45 * cos(TAU * t * 2.0)) * 0.18
		var kick_time := fmod(t, 0.5)
		var kick := sin(TAU * 48.0 * kick_time) * exp(-kick_time * 24.0) * 0.35
		var fade := minf(1.0, minf(t * 30.0, (duration - t) * 30.0))
		data.encode_s16(i * 2, int((arp + bass + kick) * fade * 13000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = int(duration * rate)
	return stream

func play(event: String) -> void:
	if sounds.has(event) and not muted:
		effects_player.stream = sounds[event]
		effects_player.play()

func set_music(enabled: bool) -> void:
	music_enabled = enabled
	if enabled:
		if not music_player.stream:
			music_player.stream = make_music()
		music_player.play()
	else:
		music_player.stop()

func set_muted(value: bool) -> void:
	muted = value
	_apply_volume()

func set_level(value: float) -> void:
	level = value
	_apply_volume()

func _apply_volume() -> void:
	var db := linear_to_db(maxf(level, 0.0001)) if not muted else -80.0
	effects_player.volume_db = db
	music_player.volume_db = db - 8.0
