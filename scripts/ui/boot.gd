extends Control
## Campaign presentation host. CampaignState owns grading and submitted progress.

@export var desktop_scene: PackedScene
@export var campaign: CampaignDefinition
@onready var _music: Node = Engine.get_singleton("MusicManager")
var run := CampaignState.new()
var desktop: Control
var phase := "TITLE"
var _entry_keycode := 0
var _blocked_keys: Dictionary = {}
var _dialogue_role: StringName
var _flow_generation := 0
var _effects_preference := true
var final_mark: String:
	get:
		return run.final_mark()

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
	if phase in ["FADE_OUT", "BLACK", "HANDOFF", "RETURN"]:
		get_viewport().set_input_as_handled()
	if event is InputEventKey:
		var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if code == _entry_keycode and not event.pressed:
			_entry_keycode = 0
		if phase in ["PLAY", "RESULT", "GAME_OVER", "SUMMARY"] and _blocked_keys.has(code):
			get_viewport().set_input_as_handled()
			if not event.pressed:
				_blocked_keys.erase(code)

func _start(event: InputEvent) -> void:
	if desktop != null:
		return
	if not run.begin(campaign):
		push_error("Invalid campaign resource. Check goals, dialogue cues and grading policy.")
		%StartScreen.reset()
		return
	_flow_generation += 1
	var generation := _flow_generation
	if event is InputEventKey:
		_entry_keycode = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	phase = "FADE_OUT"
	# Playback remains synchronous with the accepted gesture.
	var first_entry := run.current_goal().before_dialogue
	if not first_entry.entry_music.is_empty():
		_music.play_cue(first_entry.entry_music)
	desktop = desktop_scene.instantiate()
	desktop.goal = run.current_goal()
	desktop.grading = campaign.grading
	desktop.intro_pending = true
	desktop.get_node("RetroEffects").visible = false
	add_child(desktop)
	desktop._set_effects(_effects_preference)
	desktop.get_node("RetroEffects").visible = false
	desktop.dialogue_requested.connect(_start_followup)
	desktop.mission_ended.connect(_on_mission_ended)
	desktop.result_submitted.connect(_submit_result)
	desktop.return_requested.connect(_return_to_title)
	move_child(desktop, 0)
	if not desktop.mission_ready:
		run.fail()
		phase = "GAME_OVER"
		%StartScreen.hide()
		return
	%FadeLayer.visible = true
	%CinematicPlayer.play(&"title_fade")
	await %CinematicPlayer.animation_finished
	if generation != _flow_generation:
		return
	%StartScreen.hide()
	phase = "BLACK"
	%CinematicPlayer.play(&"black")
	await %CinematicPlayer.animation_finished
	if generation == _flow_generation:
		_open_dialogue(first_entry, &"before", _entry_keycode)

func _open_dialogue(entry: DialogueEntry, role: StringName, entry_keycode := 0) -> void:
	_dialogue_role = role
	desktop.dialogue_active = true
	desktop._hide_result()
	desktop.get_node("VoiceTimer").stop()
	desktop.get_node("Applications").cancel_drag()
	phase = "PORTRAITS"
	var generation := _flow_generation
	if not await %DialogueDirector.start_entry(entry, entry_keycode) and generation == _flow_generation:
		push_error("Could not start campaign dialogue: " + str(entry.id))
		_finish_dialogue(entry, true)

func _on_dialogue_started() -> void:
	if phase == "PORTRAITS":
		phase = "DIALOGUE"

func _on_cue_started(id: String) -> void:
	if id == "desktop_reveal":
		phase = "DESKTOP_REVEAL"
		desktop.get_node("RetroEffects").visible = desktop.effects_enabled

func _on_cue_finished(_id: String) -> void:
	phase = "DIALOGUE"

func _finish_dialogue(_entry: DialogueEntry, cancelled: bool) -> void:
	if phase in ["HANDOFF", "PLAY", "RETURN", "TITLE"]:
		return
	var generation := _flow_generation
	var role := _dialogue_role
	if cancelled and role != &"preview":
		run.fail()
		phase = "GAME_OVER"
		%FadeLayer.visible = false
		desktop.show_campaign_error("Could not play the authored dialogue. Check its resource, cue and animation settings.")
		return
	phase = "HANDOFF"
	if not cancelled:
		await %Intro.fade_out()
	if generation != _flow_generation:
		return
	_blocked_keys = %Intro.held_keys.duplicate()
	%FadeLayer.visible = false
	desktop.get_node("RetroEffects").visible = desktop.effects_enabled
	match role:
		&"before":
			desktop.dialogue_active = false
			desktop.finish_intro()
			phase = "PLAY"
		&"after":
			if run.advance_target():
				if not desktop.load_goal(run.current_goal()):
					run.fail()
					phase = "GAME_OVER"
					return
				_open_dialogue(run.current_goal().before_dialogue, &"before")
			else:
				_open_dialogue(campaign.ending_dialogue, &"ending")
		&"ending":
			phase = "SUMMARY"
			desktop.dialogue_active = true
			%Summary.present(run)
		_:
			desktop.dialogue_active = false
			phase = "PLAY"
			desktop._show_result()

func _on_mission_ended(snapshot: Dictionary) -> void:
	if snapshot.result == "SUCCESS":
		if run.record_success(snapshot):
			phase = "RESULT"
	else:
		run.fail()
		phase = "GAME_OVER"
	desktop.get_node("VoiceTimer").stop()

func _submit_result() -> void:
	if phase != "RESULT" or not run.submit_result():
		return
	_open_dialogue(run.current_goal().after_dialogue, &"after")

## Scoped auxiliary conversations use the same backend without campaign advancement.
func _start_followup(entry: DialogueEntry) -> void:
	if phase not in ["PLAY", "RESULT"] or %DialogueDirector.active:
		return
	_open_dialogue(entry, &"preview")

func _return_to_title() -> void:
	if phase == "RETURN" or desktop == null:
		return
	phase = "RETURN"
	_flow_generation += 1
	%CinematicPlayer.stop()
	%DialogueDirector.cancel()
	%Intro.close_immediately()
	%Summary.hide()
	%FadeLayer.visible = false
	_music.stop_playback()
	_effects_preference = desktop.effects_enabled
	desktop.session.cancel_work()
	desktop.hide()
	desktop.queue_free()
	desktop = null
	run.reset()
	_blocked_keys.clear()
	_entry_keycode = 0
	%StartScreen.reset()
	phase = "TITLE"
