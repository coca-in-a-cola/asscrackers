extends Control

signal start_requested(event: InputEvent)

var accepted := false
var _prompt_tween: Tween
@onready var _music: Node = Engine.get_singleton("MusicManager")

func _ready() -> void:
	$Margin/Stack/Footer/Audio.text = "SOUNDTRACK // %02d FILES" % _music.track_count()
	resized.connect(_update_layout)
	_update_layout()
	reset()

func reset() -> void:
	accepted = false
	set_process_input(true)
	show()
	if _prompt_tween != null and _prompt_tween.is_valid():
		_prompt_tween.kill()
	%Prompt.modulate.a = 1.0
	_prompt_tween = create_tween().set_loops()
	_prompt_tween.tween_property(%Prompt, "modulate:a", 0.6, 0.8).set_trans(Tween.TRANS_SINE)
	_prompt_tween.tween_property(%Prompt, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)

func _update_layout() -> void:
	var compact := size.y < 800
	%Title.add_theme_font_size_override(&"font_size", 88 if compact else 104)
	$Margin.add_theme_constant_override(&"margin_top", 28 if compact else 40)
	$Margin.add_theme_constant_override(&"margin_bottom", 36 if compact else 48)
	$Margin/Stack.add_theme_constant_override(&"separation", 18 if compact else 22)

func _input(event: InputEvent) -> void:
	if accepted:
		return
	var confirmed := false
	if event is InputEventKey:
		confirmed = event.pressed and not event.echo
	elif event is InputEventMouseButton:
		confirmed = event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]
	elif event is InputEventScreenTouch or event is InputEventJoypadButton:
		confirmed = event.pressed
	if not confirmed:
		return
	accepted = true
	set_process_input(false)
	_prompt_tween.kill()
	# The initiating event must not type into the desktop or press its controls.
	get_viewport().set_input_as_handled()
	start_requested.emit(event)
