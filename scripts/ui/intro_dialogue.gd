extends CanvasLayer
## Custom Dialogue Manager balloon: two speakers, two retained text windows.

signal started
signal _transition_finished
@export var default_entry: DialogueEntry
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var portrait_animation_player: AnimationPlayer = %PortraitAnimationPlayer
var director: DialogueDirector
var entry: DialogueEntry
var active := false
var held_keys: Dictionary = {}
var _blocked_entry_key := 0
var _fast_held := false
var _held_seconds := 0.0
var _auto_seconds := 0.0
var _label: DialogueLabel
var _panels: Array[PanelContainer] = []
var _portraits: Array[TextureRect] = []
var _generation := 0
var _revealed_slots: Dictionary = {}

func _ready() -> void:
	_panels = [%PlayerText, %CuratorText]
	_portraits = [%PlayerPortrait, %CuratorPortrait]
	get_window().focus_exited.connect(_release_input)
	get_viewport().size_changed.connect(_layout)
	%Responses.response_selected.connect(_select_response)
	animation_player.animation_finished.connect(func(_animation: StringName): _transition_finished.emit())
	visible = false

func configure(data: DialogueEntry) -> void:
	entry = data
	%View.theme = entry.presentation.theme
	_label = null
	portrait_animation_player.stop()
	_revealed_slots.clear()
	%ChoiceScroll.hide()
	for panel in _panels:
		panel.get_node("%Body").text = ""
		panel.modulate.a = 0.0
	for portrait in _portraits:
		portrait.modulate.a = 0.0
	for character in entry.characters:
		_portraits[character.slot].texture = character.portrait()
		_portraits[character.slot].modulate.a = 0.0 if character.reveal_on_first_line else 1.0
		_panels[character.slot].modulate.a = _portraits[character.slot].modulate.a
		if not character.reveal_on_first_line:
			_revealed_slots[character.slot] = true
		_panels[character.slot].get_node("%Name").text = "> " + character.display_name
	_layout()

func _layout() -> void:
	if entry == null or not is_node_ready():
		return
	var settings := entry.presentation
	var viewport := get_viewport().get_visible_rect().size
	var width := minf(viewport.x * settings.width_fraction, settings.maximum_width)
	var portrait_height := minf(viewport.y * settings.portrait_height_fraction, settings.maximum_portrait_height)
	var height := portrait_height + settings.panel_height + settings.row_gap + 36.0
	%View.position = Vector2((viewport.x - width) / 2.0, viewport.y - settings.bottom_clearance - height)
	%View.size = Vector2(width, height)
	%Actors.custom_minimum_size.y = portrait_height
	%ConnectionWindow.offset_top = -portrait_height * settings.connection_rise_fraction
	%CuratorPortrait.offset_top = -portrait_height
	%Panels.custom_minimum_size.y = settings.panel_height
	for panel in _panels:
		panel.custom_minimum_size.x = (width - settings.column_gap) / 2.0
	%Actors.add_theme_constant_override("separation", settings.column_gap)
	%Panels.add_theme_constant_override("separation", settings.column_gap)
	%Stack.add_theme_constant_override("separation", settings.row_gap)
	await get_tree().process_frame
	if is_inside_tree():
		_place_choices()

func _place_choices() -> void:
	var body: Control = %PlayerText.get_node("%Body")
	%ChoiceScroll.position = body.global_position - %View.global_position
	%ChoiceScroll.size = body.size

func open(entry_keycode: int = 0) -> void:
	_generation += 1
	_release_input()
	active = true
	visible = true
	_blocked_entry_key = entry_keycode
	if entry_keycode != 0:
		held_keys[entry_keycode] = true
	animation_player.play(entry.presentation.enter_animation)
	await _transition_finished

func present_line(line: DialogueLine, character: DialogueCharacter) -> void:
	_generation += 1
	var generation := _generation
	%ChoiceScroll.hide()
	_portraits[character.slot].texture = character.portrait(line.get_tag_value("expression"))
	_reveal_character(character)
	for index in _panels.size():
		_panels[index].get_node("%Titlebar").theme_type_variation = &"DialogueTitleActive" if index == character.slot else &"DialogueTitle"
	_label = _panels[character.slot].get_node("%Body")
	_label.seconds_per_step = 1.0 / entry.presentation.characters_per_second
	_label.seconds_per_pause_step = entry.presentation.punctuation_pause
	_label.dialogue_line = line
	_label.type_out()
	started.emit()
	await _label.finished_typing
	if generation != _generation or not active:
		return
	if not line.responses.is_empty():
		# The response window must accompany its portrait when choices are offered.
		for respondent in entry.characters:
			if respondent.slot == DialogueCharacter.Slot.LEFT:
				_reveal_character(respondent)
		%Responses.responses = line.responses
		_place_choices()
		%ChoiceScroll.show()
		var items: Array = %Responses.get_menu_items()
		if not items.is_empty():
			items[0].grab_focus()
	elif not line.time.is_empty():
		var delay := line.text.length() / entry.presentation.characters_per_second if line.time == "auto" else line.time.to_float()
		await get_tree().create_timer(delay).timeout
		if generation == _generation and active:
			director.advance()

func _reveal_character(character: DialogueCharacter) -> void:
	if not _revealed_slots.has(character.slot):
		_revealed_slots[character.slot] = true
		portrait_animation_player.play(character.first_line_animation)

func is_typing() -> bool:
	return _label != null and _label.is_typing

func complete_typing() -> void:
	if _label != null:
		_label.skip_typing()

func advance() -> void:
	_auto_seconds = 0.0
	if director != null:
		director.advance()

func _select_response(response: DialogueResponse) -> void:
	if response.is_allowed and director != null:
		director.advance(response.next_id)

func _input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		return
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
		_release_fast_forward()
	# Let the plugin response menu own selection and focus; never auto-pick.
	if %ChoiceScroll.visible:
		if event is InputEventKey and event.echo:
			get_viewport().set_input_as_handled()
		return
	get_viewport().set_input_as_handled()
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

func _unhandled_input(_event: InputEvent) -> void:
	if active:
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not active or not _fast_held or director == null:
		return
	_held_seconds += delta
	if _held_seconds < entry.presentation.fast_hold_delay or director.busy or %ChoiceScroll.visible:
		return
	if _label != null:
		_label.seconds_per_step = 1.0 / (entry.presentation.characters_per_second * entry.presentation.fast_multiplier)
		_label.seconds_per_pause_step = entry.presentation.punctuation_pause / entry.presentation.fast_multiplier
	if not is_typing():
		_auto_seconds += delta
		if _auto_seconds >= entry.presentation.fast_advance_interval:
			advance()

func fade_out() -> void:
	_generation += 1
	portrait_animation_player.stop()
	animation_player.play(entry.presentation.exit_animation)
	await _transition_finished
	active = false
	visible = false
	_release_fast_forward()

func close_immediately() -> void:
	_generation += 1
	animation_player.stop()
	portrait_animation_player.stop()
	_transition_finished.emit()
	for panel in _panels:
		panel.get_node("%Body").is_typing = false
	active = false
	visible = false
	_release_input()

func _release_fast_forward() -> void:
	_fast_held = false
	_held_seconds = 0.0
	_auto_seconds = 0.0
	if _label != null and entry != null:
		_label.seconds_per_step = 1.0 / entry.presentation.characters_per_second
		_label.seconds_per_pause_step = entry.presentation.punctuation_pause

func _release_input() -> void:
	held_keys.clear()
	_blocked_entry_key = 0
	_release_fast_forward()

## Standard plugin balloon API, also used by the Dialogue editor preview.
func start(resource: DialogueResource, cue: String = "", extra_game_states: Array = []) -> void:
	var data := default_entry.duplicate() as DialogueEntry
	data.dialogue = resource
	if not cue.is_empty():
		data.start_cue = cue
	var preview_director := DialogueDirector.new()
	preview_director.stage = self
	add_child(preview_director)
	var context := DialogueStateContext.new()
	context.alias = "Narrative"
	context.target = preview_director
	preview_director.add_child(context)
	preview_director.finished.connect(func(_data: DialogueEntry, cancelled: bool):
		if not cancelled:
			await fade_out()
		queue_free()
	)
	await get_tree().process_frame
	preview_director.start_entry(data, 0, extra_game_states)
