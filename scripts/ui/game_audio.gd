extends Node

@export var music_tracks: Array[AudioStream] = []
@export_range(0.1, 2.0) var crossfade_seconds := 0.75

var effects_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var muted := false
var level := 0.35
var music_enabled := false
var sounds: Dictionary = {}
var track_index := 0
var _music_players: Array[AudioStreamPlayer] = []
var _outgoing: AudioStreamPlayer
var _crossfade: Tween
var _mix := 1.0

func _ready() -> void:
	effects_player = AudioStreamPlayer.new()
	effects_player.bus = &"SFX"
	add_child(effects_player)
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.name = "Music" + str(i + 1)
		player.bus = &"Music"
		add_child(player)
		player.finished.connect(_on_track_finished.bind(player))
		_music_players.append(player)
	music_player = _music_players[0]
	for event in ["add", "run", "success", "fail", "hint"]:
		sounds[event] = make_tone(event)
	_apply_volume()

func _process(_delta: float) -> void:
	if not music_enabled or _outgoing != null or not music_player.playing:
		return
	var duration := music_player.stream.get_length()
	if duration > 0.0 and music_player.get_playback_position() >= duration - minf(crossfade_seconds, duration * 0.5):
		_advance_track()

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

func set_music(enabled: bool) -> void:
	if enabled == music_enabled:
		return
	if enabled and music_tracks.is_empty():
		push_error("Music playlist is empty.")
		return
	music_enabled = enabled
	for player in _music_players:
		player.stream_paused = not enabled
	if _crossfade != null and _crossfade.is_valid():
		if enabled:
			_crossfade.play()
		else:
			_crossfade.pause()
	if enabled and music_player.stream == null:
		music_player.stream = music_tracks[track_index]
		music_player.play()

func _advance_track() -> void:
	if not music_enabled or _outgoing != null:
		return
	_outgoing = music_player
	music_player = _music_players[1] if music_player == _music_players[0] else _music_players[0]
	track_index = (track_index + 1) % music_tracks.size()
	music_player.stream = music_tracks[track_index]
	music_player.stream_paused = false
	_mix = 0.0
	_apply_volume()
	music_player.play()
	var fade_time := minf(crossfade_seconds, music_player.stream.get_length() * 0.5)
	_crossfade = create_tween()
	_crossfade.tween_method(_set_mix, 0.0, 1.0, maxf(0.01, fade_time))
	_crossfade.tween_callback(_finish_crossfade)

func _set_mix(value: float) -> void:
	_mix = value
	_apply_volume()

func _finish_crossfade() -> void:
	_outgoing.stop()
	_outgoing = null
	_mix = 1.0
	_apply_volume()

func _on_track_finished(player: AudioStreamPlayer) -> void:
	# finished is a fallback for a frame hitch that skips the overlap window.
	if player == music_player and music_enabled and _outgoing == null:
		_advance_track()

func set_muted(value: bool) -> void:
	muted = value
	_apply_volume()

func set_level(value: float) -> void:
	level = clampf(value, 0.0, 1.0)
	_apply_volume()

func _apply_volume() -> void:
	var gain := level if not muted else 0.0
	effects_player.volume_db = linear_to_db(gain)
	# Equal-power overlap. Volume and mute remain live during a crossfade.
	music_player.volume_db = linear_to_db(gain * sin(_mix * PI * 0.5)) - 8.0
	if _outgoing != null:
		_outgoing.volume_db = linear_to_db(gain * cos(_mix * PI * 0.5)) - 8.0
