extends SceneTree

var failures: Array[String] = []
var count := 0

func _initialize() -> void:
	root.position = Vector2i.ZERO
	call_deferred("run")
	create_timer(45.0).timeout.connect(_timeout)

func _timeout() -> void:
	printerr("STARTUP FAIL: watchdog timeout (script error or stalled transition)")
	quit(1)

func check(condition: bool, description: String) -> void:
	count += 1
	if not condition:
		failures.append(description)
		printerr("STARTUP FAIL: " + description)

func settle() -> void:
	for i in 4:
		await process_frame

func key(code: int, pressed: bool, echo := false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.unicode = code + 32 if code >= KEY_A and code <= KEY_Z else 0
	event.pressed = pressed
	event.echo = echo
	root.push_input(event)
	await process_frame

func tap(code: int = KEY_Y) -> void:
	await key(code, true)
	await key(code, false)

func wait_phase(boot: Control, expected: String) -> void:
	var deadline := Time.get_ticks_msec() + 10000
	while boot.phase != expected and Time.get_ticks_msec() < deadline:
		await process_frame
	check(boot.phase == expected, "Reach phase " + expected)

func click_control(control: Control) -> void:
	if DisplayServer.get_name() != "headless":
		root.warp_mouse(control.get_global_rect().get_center())
		await settle()
	var motion := InputEventMouseMotion.new()
	motion.position = control.get_global_rect().get_center()
	motion.global_position = motion.position
	root.push_input(motion)
	await process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = control.get_global_rect().get_center()
		event.global_position = event.position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		root.push_input(event)
	await settle()

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var directory := "user://screenshots"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			directory = argument.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(directory)
	var path := directory.path_join("asscrackers-" + label + ".webp")
	check(root.get_texture().get_image().save_webp(path) == OK, "Capture " + label)
	print("CAPTURE: " + path)

func run() -> void:
	var music: Node = root.get_node("MusicManager")
	check(Engine.get_singleton("MusicManager") == music, "Runtime music registry resolves the configured Autoload instance")
	check(ProjectSettings.get_setting("autoload/MusicManager") == "*res://scenes/audio/music_manager.tscn", "Music is a scene Autoload with editor inputs")
	check(music.cues.size() == 2 and music.track_count() == 4 and not music.music_player.playing, "Configured music remains silent before input")
	for cue in music.cues:
		check(cue.valid() and not cue.resource_path.is_empty(), "Serialized valid cue: " + str(cue.id))
		for stream in cue.tracks:
			check(stream is AudioStreamMP3 and not stream.loop, "Imported non-looping MP3: " + stream.resource_path)
	var packed: PackedScene = load("res://scenes/boot.tscn")
	var boot: Control = packed.instantiate()
	root.add_child(boot)
	await settle()
	var screen: Control = boot.get_node("StartScreen")
	check(boot.desktop == null and boot.find_children("*", "AudioStreamPlayer", true, false).is_empty(), "No desktop or action audio before gesture")
	var credits: Control = screen.get_node("%Credits")
	check(credits.get_node("Author/Name").text == "mice-seller" and credits.get_node("Tools/Model").text == "GPT6.1 Sol" and credits.get_node("Tools/Images").text == "+ Google Image Pro", "Author and tool credits preserved")
	check(credits.get_node("Music/Role").text + " " + credits.get_node("Music/Name").text == "music by Karl Casey @ White Bat audio", "Music credit preserved")
	await capture("start-1440")
	root.push_input(InputEventMouseMotion.new())
	await key(KEY_X, false)
	await key(KEY_X, true, true)
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	root.push_input(wheel)
	check(boot.desktop == null, "Motion, release, echo and wheel do not start")
	await key(KEY_X, true)
	var game: Control = boot.desktop
	check(game != null and music.cue_id == &"intro" and music.music_player.playing and music.music_player.stream.resource_path.ends_with("Sycophant.mp3"), "Gesture starts Sycophant synchronously")
	check(game.intro_pending and game.get_node("VoiceTimer").is_stopped(), "Briefing blocks tools and idle commentary")
	await wait_phase(boot, "BLACK")
	check(boot.get_node("%Curtain").modulate.a > 0.99 and not boot.get_node("Intro").visible, "Full darkness before portraits")
	await capture("intro-black")
	await wait_phase(boot, "PORTRAITS")
	await create_timer(0.22).timeout
	var intro: CanvasLayer = boot.get_node("Intro")
	check(intro.get_node("%ConnectionWindow").modulate.a > 0.1 and intro.get_node("%PlayerPortrait").modulate.a == 0, "Curator appears first; player stays hidden")
	await capture("intro-curator")
	await wait_phase(boot, "DIALOGUE")
	var director: Node = boot.get_node("%DialogueDirector")
	check(intro.entry.valid() and director.line_index == 0 and intro._label.text == "Wake the fuck up, samurai. We have asses to crack", "Mandatory reference opens the plugin dialogue")
	check(intro._label is DialogueLabel and intro.entry.dialogue.resource_path.ends_with(".dialogue"), "Native plugin label and imported writer-editable resource")
	check(intro.get_node("%PlayerPortrait").modulate.a == 0 and intro.get_node("%PlayerText").modulate.a == 0, "Curator's opening line keeps player portrait and text window hidden")
	await key(KEY_X, true, true)
	check(director.line_index == 0 and game.input.text.is_empty(), "Held entry does not skip or type")
	await key(KEY_X, false)
	await tap(KEY_F2)
	check(director.line_index == 0 and intro._label.visible_ratio == 1, "Any key completes printing before advancing")
	for resolution in [Vector2i(1024, 720), Vector2i(1440, 900), Vector2i(1920, 1080)]:
		root.size = resolution
		await settle()
		var bounds := root.get_visible_rect()
		for id in ["PlayerPortrait", "ConnectionWindow", "PlayerText", "CuratorText", "Hint"]:
			var control: Control = intro.get_node("%" + id)
			check(bounds.encloses(control.get_global_rect()), "Intro fits " + str(resolution) + ": " + id)
		var left: Rect2 = intro.get_node("%PlayerText").get_global_rect()
		var right: Rect2 = intro.get_node("%CuratorText").get_global_rect()
		check(absf(left.size.x - right.size.x) < 1 and absf(left.end.y - right.end.y) < 1, "Equal aligned text windows " + str(resolution))
		check(left.end.x < right.position.x and right.end.y < game.get_node("Taskbar").position.y, "Columns separated above taskbar " + str(resolution))
		check(intro.get_node("%PlayerPortrait").size.y <= intro.entry.presentation.maximum_portrait_height + 1, "Portrait height bounded " + str(resolution))
		await capture("intro-" + str(resolution.x))
	root.size = Vector2i(1440, 900)
	await settle()
	await tap()
	check(director.line.character == "Player" and intro._label.text == "Is that the official onboarding?", "First player reply starts from the scenario")
	await create_timer(0.15).timeout
	check(intro.get_node("%PlayerPortrait").modulate.a > 0.1 and intro.get_node("%PlayerPortrait").modulate.a < 1 and is_equal_approx(intro.get_node("%PlayerText").modulate.a, intro.get_node("%PlayerPortrait").modulate.a), "Player portrait and text window fade in together with first reply")
	await capture("intro-player")
	await create_timer(0.2).timeout
	check(intro.get_node("%PlayerPortrait").modulate.a == 1 and intro.get_node("%PlayerText").modulate.a == 1 and intro.get_node("%ConnectionWindow").modulate.a == 1, "Player portrait and text remain visible after arrival")
	# A long manual conversation must keep its own cue, including song wrap.
	var outgoing: AudioStreamPlayer = music.music_player
	outgoing.seek(outgoing.stream.get_length() - 0.6)
	await create_timer(0.85).timeout
	check(music.cue_id == &"intro" and music.music_player != outgoing and music.music_player.playing and not outgoing.playing, "Sycophant repeats without switching to gameplay")
	while director.line_index < 3:
		await tap()
		await settle()
	if intro._label.visible_ratio < 1:
		await tap()
	await tap()
	check(boot.phase == "DESKTOP_REVEAL" and director.waiting_for_presentation, "Authored cue waits for desktop reveal after four lines")
	await tap()
	check(director.line_index == 3, "Input cannot advance through cinematic barrier")
	await create_timer(0.45).timeout
	check(boot.get_node("%Curtain").modulate.a > 0.05 and boot.get_node("%Curtain").modulate.a < 0.95 and music.cue_id == &"intro", "Desktop fades behind dialogue; intro music continues")
	await capture("intro-reveal")
	await wait_phase(boot, "DIALOGUE")
	check(director.line_index == 4 and game.intro_pending, "Briefing continues over desktop")
	check(intro.get_node("%PlayerText").get_node("%Body").text == "Great. What am I breaking?", "Other speaker's previous line remains visible")
	await tap()
	await capture("intro-briefing")
	game._activate_application(&"Terminal")
	game._query_intel("nickname")
	check(not game.get_node("Applications/Terminal").visible and game.session.budget.value == 0, "Locked intro cannot launch tools or purchase recon")
	var index_before: int = director.line_index
	await key(KEY_SPACE, true)
	await create_timer(0.55).timeout
	check(director.line_index > index_before, "Holding Space continuously accelerates conversation")
	await wait_phase(boot, "PLAY")
	check(not intro.visible and not game.intro_pending and not game.get_node("VoiceTimer").is_stopped(), "Fade-out hands over control and starts idle timer")
	await key(KEY_SPACE, true, true)
	await settle()
	var manager: Control = game.get_node("Applications")
	check(manager.active_application.is_empty(), "No initial active application")
	for window in manager.get_children():
		check(not window.visible, "Initial window closed: " + window.name)
	check(game.session.budget.value == 0 and game.session.engine.attempts_used == 0 and game.session.dictionary.words.is_empty(), "Briefing and held handoff spend no risk or requests")
	await key(KEY_SPACE, false)
	await capture("desktop-empty")
	await create_timer(1.6).timeout
	check(music.cue_id == &"background" and music.music_player.stream.resource_path.ends_with("Hackers.mp3") and not music._outgoing, "Sycophant crossfades to background at handoff")
	await click_control(game.get_node("DesktopIcons/DictionaryShortcut"))
	await settle()
	await tap(KEY_X)
	check(manager.application(&"Dictionary").visible and game.input.text == "x", "Player manually opens tools; typing works after handoff")
	game.input.clear()
	var toggle: CheckBox = game.get_node("Taskbar").music_toggle
	await click_control(toggle)
	var position: float = music.music_player.get_playback_position()
	await create_timer(0.12).timeout
	check(not music.enabled and music.music_player.stream_paused and absf(music.music_player.get_playback_position() - position) < 0.05, "Taskbar pauses singleton without resetting position")
	await click_control(toggle)
	check(music.enabled and not music.music_player.stream_paused, "Taskbar resumes singleton")
	for expected_index in [1, 2, 0]:
		outgoing = music.music_player
		outgoing.seek(outgoing.stream.get_length() - 0.6)
		await create_timer(0.1).timeout
		check(music.track_index == expected_index and music.music_player != outgoing, "Background advances to index " + str(expected_index))
		if expected_index == 1:
			music.set_enabled(false)
			var incoming: AudioStreamPlayer = music.music_player
			position = incoming.get_playback_position()
			await create_timer(0.2).timeout
			check(incoming.stream_paused and outgoing.stream_paused and absf(incoming.get_playback_position() - position) < 0.05, "Pause freezes both overlapping players")
			music.set_muted(true)
			music.set_enabled(true)
			check(incoming.volume_linear == 0 and outgoing.volume_linear == 0 and game.audio.muted, "Muted overlap remains silent, action audio follows settings")
			music.set_muted(false)
		await create_timer(0.8).timeout
		check(not outgoing.playing and music.music_player.playing, "Overlap retires only outgoing playback")
	music.set_process(false)
	music.music_player.seek(music.music_player.stream.get_length() - 0.1)
	await create_timer(0.95).timeout
	check(music.track_index == 1 and music.music_player.playing, "Finished fallback advances when overlap polling is skipped")
	music.set_process(true)
	var player: AudioStreamPlayer = music.music_player
	position = player.get_playback_position()
	music.play_cue(&"background")
	game._restart()
	await settle()
	check(music.music_player == player and player.get_playback_position() >= position and boot.phase == "PLAY", "Restart and repeated cue preserve playback, no intro replay")
	game._set_volume(0)
	check(player.volume_linear == 0 and game.audio.effects_player.volume_linear == 0, "Master zero silences music and effects")
	game._set_volume(0.35)
	await check_backend(boot, game, intro, director)
	boot.queue_free()
	await settle()
	check(music.is_inside_tree() and player.playing, "Singleton survives desktop destruction")
	await check_preview()
	print("STARTUP / AUDIO: %d checks, %d failures" % [count, failures.size()])
	quit(0 if failures.is_empty() else 1)

func check_backend(boot: Control, game: Control, intro: CanvasLayer, director: Node) -> void:
	var fixture := intro.default_entry.duplicate() as DialogueEntry
	fixture.id = &"fixture"
	fixture.dialogue = load("res://tests/fixtures/dialogue_backend.dialogue")
	fixture.entry_music = &""
	fixture.exit_music = &""
	check(fixture.valid(), "Fixture uses same resource-driven director")
	var invalid := fixture.duplicate() as DialogueEntry
	invalid.start_cue = "missing"
	check(not await director.start_entry(invalid), "Invalid starting cue rejected before animation")
	var stream: AudioStream = root.get_node("MusicManager").music_player.stream
	game._restart()
	check(game._submit_fragment("B@rsik1990!").ok, "Prepare deterministic successful mission")
	game._run_dictionary()
	game.session.advance(game.session.generation, 1.0)
	check(boot.phase == "RESULT" and game.modal.visible and not intro.active and boot.run.results.is_empty(), "Successful hack waits for SUBMIT RESULT")
	game.dialogue_requested.emit(fixture)
	await wait_phase(boot, "DIALOGUE")
	check(game.session.engine.phase == "WON" and game.dialogue_active and intro.active and not game.modal.visible, "Requested auxiliary dialogue dismisses result")
	check(not await director.start_entry(fixture), "Concurrent dialogue start rejected")
	await key(KEY_SPACE, true)
	await create_timer(0.6).timeout
	check(intro.get_node("%ChoiceScroll").visible and director.line_index == 0, "Hold Space never chooses a response")
	check(intro.get_node("%PlayerText").get_global_rect().encloses(intro.get_node("%ChoiceScroll").get_global_rect()), "Responses stay inside text window")
	await capture("dialogue-choices")
	await key(KEY_SPACE, false)
	var items: Array = intro.get_node("%Responses").get_menu_items()
	var disabled_count := 0
	for item in intro.get_node("%Responses").get_children():
		if item.visible and item.disabled:
			disabled_count += 1
	check(items.size() == 1 and disabled_count == 1, "Native response menu applies conditions")
	await click_control(items[0])
	await settle()
	check(director.line.character == "Player" and director.line.text == "Selected branch.", "Response follows plugin next_id")
	await tap()
	await tap()
	await wait_phase(boot, "PLAY")
	check(not game.dialogue_active and game.modal.visible, "Follow-up returns to result without replaying intro")
	check(root.get_node("MusicManager").music_player.stream == stream, "Empty music inputs preserve existing cue")
	for resource in [fixture.dialogue, intro.default_entry.dialogue]:
		var clean := true
		for data in resource.lines.values():
			clean = clean and not data.has("resource")
		check(clean, "Runtime leaves compiled source immutable: " + resource.resource_path)
	fixture.start_cue = "barrier"
	game.dialogue_requested.emit(fixture)
	await wait_phase(boot, "DESKTOP_REVEAL")
	director.cancel()
	await settle()
	check(boot.phase == "PLAY" and not director.active and not director.busy and not intro.active, "Cancel unblocks an awaited cinematic")
	fixture.start_cue = "start"
	game.dialogue_requested.emit(fixture)
	await create_timer(0.1).timeout
	director.cancel()
	await settle()
	check(boot.phase == "PLAY" and not director.active and not intro.active, "Cancel unblocks portrait entry animation")
	fixture.start_cue = "long"
	root.size = Vector2i(1024, 720)
	game.dialogue_requested.emit(fixture)
	await wait_phase(boot, "DIALOGUE")
	await tap()
	await settle()
	var body: RichTextLabel = intro._label
	var scrollbar := body.get_v_scroll_bar()
	check(scrollbar.max_value > scrollbar.page and body.get_theme_font_size("normal_font_size") >= 18, "Long text scrolls without shrinking below readable font size")
	var wheel := InputEventMouseButton.new()
	wheel.position = body.get_global_rect().get_center()
	wheel.global_position = wheel.position
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	root.push_input(wheel)
	await settle()
	check(scrollbar.value > 0 and director.line_index == 0, "Actual wheel scrolls text without advancing")
	director.cancel()
	await settle()
	root.size = Vector2i(1440, 900)

func check_preview() -> void:
	var dm: Node = root.get_node("DialogueManager")
	var host := Node.new()
	root.add_child(host)
	var original: Callable = dm.get_current_scene
	dm.get_current_scene = func(): return host
	var resource: DialogueResource = load("res://tests/fixtures/dialogue_backend.dialogue")
	var preview: CanvasLayer = dm.show_dialogue_balloon(resource, "barrier")
	await create_timer(2.1).timeout
	check(preview.active and preview.director.line.text == "After the barrier.", "Configured plugin preview resolves Narrative and awaits its local animation")
	await tap()
	await tap()
	await create_timer(0.4).timeout
	check(not is_instance_valid(preview), "Plugin preview completes and disposes its custom balloon")
	dm.get_current_scene = original
	host.queue_free()
	await settle()
	await create_timer(1.6).timeout
