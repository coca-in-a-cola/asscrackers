extends CanvasLayer

signal started
signal desktop_requested
signal finished

@export var sequence: DialogueSequence
@export_range(10.0, 100.0) var characters_per_second := 38.0

const Playback = preload("res://scripts/ui/dialogue_playback.gd")
var playback = Playback.new()
var active := false
var held_keys: Dictionary = {}
var _blocked_entry_key := 0
var _line_active := false
var _fast_held := false
var _held_seconds := 0.0
var _auto_seconds := 0.0
var _reveal: Tween
var _speaker_fade: Tween

func _ready() -> void:
	playback.line_changed.connect(_show_line)
	playback.desktop_requested.connect(func(): desktop_requested.emit())
	playback.finished.connect(_on_finished)
	get_window().focus_exited.connect(_release_input)

func begin(entry_keycode: int = 0) -> void:
	if sequence == null or not sequence.valid():
		push_error("Invalid introductory dialogue resource.")
		finished.emit()
		return
	active = true
	visible = true
	_blocked_entry_key = entry_keycode
	if entry_keycode != 0:
		held_keys[entry_keycode] = true
	%View.modulate.a = 1.0
	%StageDimmer.modulate.a = 0.0
	%PlayerPortrait.texture = sequence.player_portrait
	%CuratorPortrait.texture = sequence.curator_portrait
	%PlayerName.text = sequence.player_name
	%CuratorName.text = sequence.curator_name
	%PlayerPortrait.modulate.a = 0.0
	%CuratorPortrait.modulate.a = 0.0
	%DialoguePanel.modulate.a = 0.0
	await _fade(%PlayerPortrait, 1.0, 0.3)
	var pause := create_tween()
	pause.tween_interval(0.1)
	await pause.finished
	await _fade(%CuratorPortrait, 1.0, 0.3)
	await _fade(%DialoguePanel, 1.0, 0.18)
	_line_active = true
	playback.start(sequence)
	started.emit()

func _fade(item: CanvasItem, opacity: float, seconds: float) -> void:
	var tween := create_tween()
	tween.tween_property(item, "modulate:a", opacity, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func _input(event: InputEvent) -> void:
	if not active:
		return
	get_viewport().set_input_as_handled()
	if event is InputEventKey:
		var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if event.pressed:
			held_keys[code] = true
		else:
			held_keys.erase(code)
		if code == _blocked_entry_key:
			if not event.pressed:
				_blocked_entry_key = 0
			return
	if event.is_action_released(&"dialogue_fast_forward"):
		_fast_held = false
		_held_seconds = 0.0
		if _reveal != null and _reveal.is_valid():
			_reveal.set_speed_scale(1.0)
	if event.is_action_pressed(&"dialogue_fast_forward"):
		_fast_held = true
		_held_seconds = 0.0
	var confirmed := false
	if event is InputEventKey:
		confirmed = event.pressed and not event.echo
	elif event is InputEventMouseButton:
		confirmed = event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]
	elif event is InputEventScreenTouch or event is InputEventJoypadButton:
		confirmed = event.pressed
	if confirmed:
		advance()

func _process(delta: float) -> void:
	if not active or not _fast_held:
		return
	_held_seconds += delta
	if _held_seconds < 0.3 or not _line_active or playback.waiting_for_desktop or playback.complete:
		return
	if _reveal != null and _reveal.is_running():
		_reveal.set_speed_scale(8.0)
	else:
		_auto_seconds += delta
		if _auto_seconds >= 0.12:
			_auto_seconds = 0.0
			playback.advance()

func advance() -> void:
	if not _line_active or playback.waiting_for_desktop or playback.complete:
		return
	_auto_seconds = 0.0
	if _reveal != null and _reveal.is_running():
		_reveal.kill()
		%Body.visible_ratio = 1.0
	else:
		playback.advance()

func _show_line(line: Dictionary, index: int) -> void:
	if _reveal != null and _reveal.is_valid():
		_reveal.kill()
	var player_speaking: bool = line.speaker == "player"
	%Speaker.text = sequence.player_name if player_speaking else sequence.curator_name
	%Speaker.theme_type_variation = &"BootAccent" if player_speaking else &"BootMusic"
	%Progress.text = "%02d / %02d" % [index + 1, sequence.lines.size()]
	%Body.text = line.text
	%Body.visible_ratio = 0.0
	_reveal = create_tween()
	_reveal.tween_property(%Body, "visible_ratio", 1.0, line.text.length() / characters_per_second)
	if _fast_held and _held_seconds >= 0.3:
		_reveal.set_speed_scale(8.0)
	if _speaker_fade != null and _speaker_fade.is_valid():
		_speaker_fade.kill()
	_speaker_fade = create_tween().set_parallel(true)
	var subdued := Color(0.62, 0.62, 0.62, 1.0)
	_speaker_fade.tween_property(%PlayerPortrait, "modulate", Color.WHITE if player_speaking else subdued, 0.16)
	_speaker_fade.tween_property(%CuratorPortrait, "modulate", subdued if player_speaking else Color.WHITE, 0.16)

func reveal_backdrop() -> void:
	_fade(%StageDimmer, 1.0, 1.0)

func resume_after_desktop() -> void:
	playback.resume_after_desktop()

func _on_finished() -> void:
	_line_active = false
	finished.emit()

func fade_out() -> void:
	if _reveal != null and _reveal.is_valid():
		_reveal.kill()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(%View, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE)
	tween.tween_property(%StageDimmer, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE)
	await tween.finished
	active = false
	visible = false
	_fast_held = false

func _release_input() -> void:
	held_keys.clear()
	_blocked_entry_key = 0
	_fast_held = false
	_held_seconds = 0.0
	if _reveal != null and _reveal.is_valid():
		_reveal.set_speed_scale(1.0)
