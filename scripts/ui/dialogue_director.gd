class_name DialogueDirector
extends Node
## Session orchestration only. Dialogue Manager owns parsing and graph traversal.

signal started(entry: DialogueEntry)
signal finished(entry: DialogueEntry, cancelled: bool)
signal cue_started(id: String)
signal cue_finished(id: String)
signal _presentation_completed

@export var stage: CanvasLayer
@export var cinematic_player: AnimationPlayer
@onready var _music: Node = Engine.get_singleton("MusicManager")
var entry: DialogueEntry
var line: DialogueLine
var active := false
var busy := false
var waiting_for_presentation := false
var line_index := -1
var _generation := 0
var _extra_game_states: Array = []

func start_entry(data: DialogueEntry, entry_keycode: int = 0, extra_game_states: Array = []) -> bool:
	if active or data == null or not data.valid() or stage == null or stage.active:
		return false
	if not stage.animation_player.has_animation(data.presentation.enter_animation) or not stage.animation_player.has_animation(data.presentation.exit_animation):
		return false
	for character in data.characters:
		if character.reveal_on_first_line and not stage.portrait_animation_player.has_animation(character.first_line_animation):
			return false
	var player: AnimationPlayer = cinematic_player if cinematic_player != null else stage.animation_player
	for animation in data.presentation_cues.values():
		if not player.has_animation(animation):
			return false
	entry = data
	_extra_game_states = extra_game_states
	active = true
	busy = true
	line_index = -1
	_generation += 1
	var generation := _generation
	stage.director = self
	stage.configure(entry)
	started.emit(entry)
	if not entry.entry_music.is_empty():
		_music.play_cue(entry.entry_music)
	await stage.open(entry_keycode)
	if generation == _generation and active:
		await _request_line(entry.start_cue)
	return true

func advance(next_id: String = "") -> void:
	if not active or busy or waiting_for_presentation or line == null:
		return
	if stage.is_typing():
		stage.complete_typing()
		return
	if not line.responses.is_empty() and next_id.is_empty():
		return
	await _request_line(line.next_id if next_id.is_empty() else next_id)

func _request_line(next_id: String) -> void:
	busy = true
	var generation := _generation
	var next_line := await entry.dialogue.get_next_dialogue_line(next_id, _extra_game_states)
	if generation != _generation or not active:
		return
	busy = false
	line = next_line
	if line == null:
		active = false
		_exit_music()
		finished.emit(entry, false)
		return
	var character := entry.character_for(line.character)
	if character == null:
		push_error("Unknown dialogue character: " + line.character)
		cancel()
		return
	line_index += 1
	stage.present_line(line, character)

## Called from .dialogue via the registered Narrative DialogueStateContext.
func present(id: String) -> void:
	if not active or not entry.presentation_cues.has(id):
		push_error("Unknown presentation cue: " + id)
		cancel()
		return
	var player: AnimationPlayer = cinematic_player if cinematic_player != null else stage.animation_player
	var animation: StringName = entry.presentation_cues[id]
	if not player.has_animation(animation):
		push_error("Missing presentation animation: " + str(animation))
		cancel()
		return
	waiting_for_presentation = true
	var generation := _generation
	cue_started.emit(id)
	player.animation_finished.connect(_on_presentation_finished, CONNECT_ONE_SHOT)
	player.play(animation)
	await _presentation_completed
	if generation == _generation and active:
		waiting_for_presentation = false
		cue_finished.emit(id)

func _on_presentation_finished(_animation: StringName) -> void:
	_presentation_completed.emit()

func cancel() -> void:
	if not active:
		return
	_generation += 1
	active = false
	busy = false
	line = null
	if waiting_for_presentation:
		var player: AnimationPlayer = cinematic_player if cinematic_player != null else stage.animation_player
		player.stop()
		if player.animation_finished.is_connected(_on_presentation_finished):
			player.animation_finished.disconnect(_on_presentation_finished)
		waiting_for_presentation = false
		_presentation_completed.emit()
	stage.close_immediately()
	_exit_music()
	finished.emit(entry, true)

func _exit_music() -> void:
	if not entry.exit_music.is_empty():
		_music.play_cue(entry.exit_music)
