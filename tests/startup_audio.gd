extends SceneTree

var failures: Array[String] = []
var count := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	count += 1
	if not condition:
		failures.append(description)
		printerr("STARTUP FAIL: " + description)

func settle() -> void:
	for i in 4:
		await process_frame

func key_event(pressed: bool, echo := false) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = KEY_X
	event.physical_keycode = KEY_X
	event.unicode = 120
	event.pressed = pressed
	event.echo = echo
	return event

func click_control(control: Control) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = control.get_global_rect().get_center()
		event.global_position = event.position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event)
		await process_frame

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
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/boot.tscn", "F5 enters the start screen")
	var packed: PackedScene = load("res://scenes/boot.tscn")
	var boot: Control = packed.instantiate()
	root.add_child(boot)
	await settle()
	var screen: Control = boot.get_node("StartScreen")
	check(boot.desktop == null and boot.find_children("*", "AudioStreamPlayer", true, false).is_empty(), "Before input: no session and no audio players")
	var credits: Control = screen.get_node("%Credits")
	check(credits.get_node("Author/Role").text == "made by" and credits.get_node("Author/Name").text == "mice-seller", "Creator credit")
	check(credits.get_node("Tools/Role").text == "made with" and credits.get_node("Tools/Model").text == "GPT6.1 Sol" and credits.get_node("Tools/Images").text == "+ Google Image Pro", "Tool credits in order")
	check(credits.get_node("Music/Role").text + " " + credits.get_node("Music/Name").text == "music by Karl Casey @ White Bat audio", "Exact music credit")
	for resolution in [Vector2i(1024, 720), Vector2i(1440, 900), Vector2i(1920, 1080)]:
		root.size = resolution
		await settle()
		var bounds := root.get_visible_rect()
		for label in screen.find_children("*", "Label", true, false):
			var rect: Rect2 = label.get_global_rect()
			check(bounds.encloses(rect), "Start label fits " + str(resolution) + ": " + label.name)
		await capture("start-" + str(resolution.x))
	root.size = Vector2i(1440, 900)
	await settle()
	root.push_input(InputEventMouseMotion.new())
	root.push_input(key_event(false))
	root.push_input(key_event(true, true))
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	root.push_input(wheel)
	await settle()
	check(boot.desktop == null, "Motion, release, echo and wheel do not start")
	root.push_input(key_event(true))
	await settle()
	var game: Control = boot.desktop
	check(game != null and not boot.has_node("StartScreen"), "First press enters desktop once")
	check(game.audio.music_enabled and game.audio.music_player.playing and game.get_node("Taskbar").music_toggle.button_pressed, "Music starts immediately and toggle agrees")
	check(game.input.text.is_empty() and game.session.dictionary.words.is_empty(), "Entry key does not type or submit")
	root.push_input(key_event(true, true))
	await settle()
	check(game.input.text.is_empty() and boot.get_child_count() == 1, "Held entry repeats do not leak or create desktops")
	root.push_input(key_event(false))
	root.push_input(key_event(true))
	await settle()
	check(game.input.text == "x", "Normal typing works after entry release")
	game.input.clear()
	await capture("start-desktop")
	check(game.audio.music_tracks.size() == 3, "Three-track playlist")
	var expected := ["Hackers", "New Beginnings", "The Saga"]
	for i in 3:
		var stream: AudioStream = game.audio.music_tracks[i]
		check(stream is AudioStreamMP3 and stream.resource_path.ends_with("Karl Casey - " + expected[i] + ".mp3") and stream.get_length() > 1 and not stream.loop, "Imported MP3 order: " + expected[i])
	check(game.audio.music_player.bus == &"Music" and game.audio.effects_player.bus == &"SFX", "Separate audio buses")
	check(AudioServer.get_bus_index(&"Music") > 0 and AudioServer.get_bus_index(&"SFX") > 0, "Bus layout is loaded by the engine")
	var music_toggle: CheckBox = game.get_node("Taskbar").music_toggle
	await click_control(music_toggle)
	var pause_position: float = game.audio.music_player.get_playback_position()
	await create_timer(0.12).timeout
	check(not game.audio.music_enabled and game.audio.music_player.stream_paused and absf(game.audio.music_player.get_playback_position() - pause_position) < 0.05, "Taskbar Music click pauses without resetting")
	await click_control(music_toggle)
	check(game.audio.music_enabled and not game.audio.music_player.stream_paused and game.audio.music_player.get_playback_position() >= pause_position, "Taskbar Music click resumes")
	game.audio.crossfade_seconds = 0.2
	# Seek real MP3s to their overlap window; test actual playback, not a
	# manually emitted finished signal or minutes of wall-clock waiting.
	for expected_index in [1, 2, 0]:
		var audio: Node = game.audio
		var outgoing: AudioStreamPlayer = audio.music_player
		outgoing.seek(outgoing.stream.get_length() - 0.15)
		await create_timer(0.07).timeout
		check(audio.track_index == expected_index and audio.music_player != outgoing and audio.music_player.playing, "Auto advance to " + expected[expected_index])
		if expected_index == 1:
			game._set_music(false)
			var incoming: AudioStreamPlayer = audio.music_player
			var paused_at := incoming.get_playback_position()
			await create_timer(0.25).timeout
			check(incoming.stream_paused and outgoing.stream_paused and absf(incoming.get_playback_position() - paused_at) < 0.05, "Pause freezes both sides of crossfade")
			game._set_muted(true)
			game._set_music(true)
			check(not incoming.stream_paused and incoming.volume_db <= -80 and outgoing.volume_db <= -80, "Muted resume remains silent during overlap")
			game._set_muted(false)
			game._set_volume(0.6)
		await create_timer(0.25).timeout
		check(not outgoing.playing and audio.music_player.playing, "Crossfade retires only the old player")
	game.audio.set_process(false)
	game.audio.music_player.seek(game.audio.music_player.stream.get_length() - 0.1)
	await create_timer(0.4).timeout
	check(game.audio.track_index == 1 and game.audio.music_player.playing, "Natural finished signal advances if overlap polling is skipped")
	game.audio.set_process(true)
	var player: AudioStreamPlayer = game.audio.music_player
	var position := player.get_playback_position()
	game._set_music(true)
	game._restart()
	await settle()
	check(game.audio.music_player == player and player.get_playback_position() >= position and not boot.has_node("StartScreen"), "Repeated enable and mission restart preserve music, no intro replay")
	game.audio.set_level(0)
	check(player.volume_linear == 0 and game.audio.effects_player.volume_linear == 0, "Zero master level truly silences both categories")
	boot.queue_free()
	await settle()
	# Other input devices pass through the same one-shot gateway.
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(80, 80)
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_A
	pad.pressed = true
	for event in [click, touch, pad]:
		boot = packed.instantiate()
		root.add_child(boot)
		await settle()
		root.push_input(event)
		await settle()
		check(boot.desktop != null and boot.desktop.audio.music_player.playing and boot.get_child_count() == 1, "Start by " + event.get_class())
		boot.queue_free()
		await settle()
	print("STARTUP / AUDIO: %d checks, %d failures" % [count, failures.size()])
	quit(0 if failures.is_empty() else 1)
