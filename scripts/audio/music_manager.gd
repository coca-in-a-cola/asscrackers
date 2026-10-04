extends Node
## Owns music only. Cue resources are editor inputs, never runtime-mutated.

signal changed

@export var cues: Array[MusicCue] = []
@export_range(-30.0, 0.0) var relative_volume_db := -8.0

@onready var music_player: AudioStreamPlayer = %MusicA
@onready var _players: Array[AudioStreamPlayer] = [%MusicA, %MusicB]

var cue_id: StringName = &""
var track_index := 0
var enabled := true
var muted := false
var level := 0.35
var _catalog: Dictionary = {}
var _outgoing: AudioStreamPlayer
var _crossfade: Tween
var _mix := 1.0
var _pending_cue: StringName = &""
var _registered_service := false

func _ready() -> void:
	# Runtime lookup stays valid when editor/CLI compilation has no Autoload symbols.
	if not Engine.has_singleton("MusicManager"):
		Engine.register_singleton("MusicManager", self)
		_registered_service = true
	for cue in cues:
		if cue == null or not cue.valid() or _catalog.has(cue.id):
			push_error("MusicManager: invalid or duplicate cue configuration.")
			continue
		_catalog[cue.id] = cue
	for player in _players:
		player.finished.connect(_on_finished.bind(player))
	_apply_volume()

func play_cue(id: StringName) -> bool:
	if not _catalog.has(id):
		push_error("MusicManager: unknown cue " + str(id))
		return false
	if id == cue_id:
		_pending_cue = &""
		return true
	if _outgoing != null:
		# Finish the current two-player overlap before the latest cue request.
		_pending_cue = id
		return true
	cue_id = id
	track_index = 0
	var cue: MusicCue = _catalog[id]
	_start_stream(cue.tracks[0], cue.transition_seconds)
	changed.emit()
	return true

func _process(_delta: float) -> void:
	if not enabled or _outgoing != null or not music_player.playing or cue_id.is_empty():
		return
	var cue: MusicCue = _catalog[cue_id]
	var duration := music_player.stream.get_length()
	if music_player.get_playback_position() >= duration - minf(cue.crossfade_seconds, duration * 0.5):
		_advance()

func _advance() -> void:
	var cue: MusicCue = _catalog[cue_id]
	if track_index + 1 >= cue.tracks.size() and not cue.repeat:
		return
	track_index = (track_index + 1) % cue.tracks.size()
	_start_stream(cue.tracks[track_index], cue.crossfade_seconds)
	changed.emit()

func _start_stream(stream: AudioStream, seconds: float) -> void:
	if music_player.stream == null:
		music_player.stream = stream
		music_player.play()
		music_player.stream_paused = not enabled
		_apply_volume()
		return
	_outgoing = music_player
	music_player = _players[1] if music_player == _players[0] else _players[0]
	music_player.stream = stream
	_mix = 0.0
	_apply_volume()
	music_player.play()
	music_player.stream_paused = not enabled
	_crossfade = create_tween()
	_crossfade.tween_method(_set_mix, 0.0, 1.0, minf(seconds, stream.get_length() * 0.5))
	_crossfade.tween_callback(_finish_crossfade)
	if not enabled:
		_crossfade.pause()

func _set_mix(value: float) -> void:
	_mix = value
	_apply_volume()

func _finish_crossfade() -> void:
	_outgoing.stop()
	_outgoing = null
	_mix = 1.0
	_apply_volume()
	changed.emit()
	if not _pending_cue.is_empty():
		var next := _pending_cue
		_pending_cue = &""
		play_cue(next)

func _on_finished(player: AudioStreamPlayer) -> void:
	if player == music_player and enabled and _outgoing == null and not cue_id.is_empty():
		_advance()

func set_enabled(value: bool) -> void:
	if enabled == value:
		return
	enabled = value
	for player in _players:
		player.stream_paused = not value
	if _crossfade != null and _crossfade.is_valid():
		if value:
			_crossfade.play()
		else:
			_crossfade.pause()
	changed.emit()

func set_muted(value: bool) -> void:
	muted = value
	_apply_volume()
	changed.emit()

func set_level(value: float) -> void:
	level = clampf(value, 0.0, 1.0)
	_apply_volume()
	changed.emit()

func _apply_volume() -> void:
	var gain := level if not muted else 0.0
	music_player.volume_db = linear_to_db(gain * maxf(0.0, sin(_mix * PI * 0.5))) + relative_volume_db
	if _outgoing != null:
		_outgoing.volume_db = linear_to_db(gain * maxf(0.0, cos(_mix * PI * 0.5))) + relative_volume_db

func track_count() -> int:
	var streams: Dictionary = {}
	for cue in cues:
		if cue != null:
			for stream in cue.tracks:
				streams[stream] = true
	return streams.size()

func stop_playback() -> void:
	if _crossfade != null and _crossfade.is_valid():
		_crossfade.kill()
	for player in _players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	_outgoing = null
	_pending_cue = &""
	cue_id = &""
	track_index = 0
	_mix = 1.0
	changed.emit()

func _exit_tree() -> void:
	if _registered_service:
		Engine.unregister_singleton("MusicManager")
		_registered_service = false
	stop_playback()
