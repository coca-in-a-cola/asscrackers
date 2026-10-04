extends Control

@export var desktop_scene: PackedScene
var desktop: Control
var _entry_keycode := 0
var _blocked_keys: Dictionary = {}
var phase := "TITLE"

func _ready() -> void:
	get_window().min_size = Vector2i(1024, 720)
	get_window().size_changed.connect(_sync_canvas)
	get_window().focus_exited.connect(func(): _blocked_keys.clear(); _entry_keycode = 0)
	_sync_canvas()

func _sync_canvas() -> void:
	var window := get_window()
	if window.content_scale_size != window.size:
		window.content_scale_size = window.size

func _input(event: InputEvent) -> void:
	if phase == "TITLE":
		return
	if phase != "PLAY":
		get_viewport().set_input_as_handled()
	if event is InputEventKey:
		var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if code == _entry_keycode and not event.pressed:
			_entry_keycode = 0
		if phase == "PLAY" and _blocked_keys.has(code):
			get_viewport().set_input_as_handled()
			if not event.pressed:
				_blocked_keys.erase(code)

func _start(event: InputEvent) -> void:
	if desktop != null:
		return
	if event is InputEventKey:
		_entry_keycode = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	phase = "FADE_OUT"
	# No await before audio: playback belongs to the accepted input gesture.
	MusicManager.play_cue(&"intro")
	desktop = desktop_scene.instantiate()
	desktop.intro_pending = true
	desktop.get_node("RetroEffects").visible = false
	add_child(desktop)
	move_child(desktop, 0)
	%FadeLayer.visible = true
	await _fade_to(1.0, 0.2)
	%StartScreen.hide()
	%StartScreen.queue_free()
	phase = "BLACK"
	var pause := create_tween()
	pause.tween_interval(0.15)
	await pause.finished
	phase = "PORTRAITS"
	%Intro.begin(_entry_keycode)

func _fade_to(opacity: float, seconds: float) -> void:
	var tween := create_tween()
	tween.tween_property(%Curtain, "modulate:a", opacity, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func _on_dialogue_started() -> void:
	phase = "DIALOGUE"

func _reveal_desktop() -> void:
	phase = "DESKTOP_REVEAL"
	desktop.get_node("RetroEffects").visible = desktop.effects_enabled
	%Intro.reveal_backdrop()
	await _fade_to(0.0, 1.0)
	phase = "DIALOGUE"
	%Intro.resume_after_desktop()

func _finish_intro() -> void:
	if phase == "HANDOFF" or phase == "PLAY":
		return
	phase = "HANDOFF"
	MusicManager.play_cue(&"background")
	await %Intro.fade_out()
	_blocked_keys = %Intro.held_keys.duplicate()
	%FadeLayer.visible = false
	desktop.get_node("RetroEffects").visible = desktop.effects_enabled
	phase = "PLAY"
	desktop.finish_intro()
