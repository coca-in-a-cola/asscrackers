extends Control

@export var desktop_scene: PackedScene
var desktop: Control
var _entry_keycode := 0

func _ready() -> void:
	get_window().min_size = Vector2i(1024, 720)
	get_window().size_changed.connect(_sync_canvas)
	_sync_canvas()

func _sync_canvas() -> void:
	var window := get_window()
	if window.content_scale_size != window.size:
		window.content_scale_size = window.size

func _input(event: InputEvent) -> void:
	# Suppress the entry key's held repeats/release, not subsequent typing.
	if _entry_keycode == 0 or not event is InputEventKey:
		return
	var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if code == _entry_keycode:
		get_viewport().set_input_as_handled()
		if not event.pressed:
			_entry_keycode = 0

func _start(event: InputEvent) -> void:
	if desktop != null:
		return
	if event is InputEventKey:
		_entry_keycode = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	# No await: first playback belongs to the accepted input gesture.
	desktop = desktop_scene.instantiate()
	add_child(desktop)
	desktop.start_audio()
	%StartScreen.hide()
	%StartScreen.queue_free()
