extends SceneTree

var failures: Array = []
var count := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	count += 1
	if not condition:
		failures.append(description)
		printerr("UI FAIL: " + description)

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var directory := "user://screenshots"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			directory = argument.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(directory)
	var path := directory.path_join("asscrackers-" + label + ".png")
	check(root.get_texture().get_image().save_png(path) == OK, "Screenshot " + label)
	print("CAPTURE: " + path)

func type_fragment(scene: Control, value: String) -> void:
	scene.input.text = value
	scene.input.text_submitted.emit(value)

func wait_for_job(scene: Control) -> void:
	for i in 120:
		if scene.session.engine.phase != "RUNNING":
			return
		await create_timer(0.05).timeout
	check(false, "Job completes within six seconds")

func check_layout(scene: Control) -> void:
	var bounds := root.get_visible_rect().size
	check(scene.footer.get_global_rect().end.y <= bounds.y and scene.footer.get_global_rect().end.x <= bounds.x, "Footer fits")
	check(scene.input.get_global_rect().end.y < scene.footer.get_global_rect().position.y, "Input fits above footer")
	check(scene.special_toggle.get_global_rect().end.x < scene.dossier.get_global_rect().position.x, "Special toggle fits workspace")
	for chip in scene.chip_grid.get_children():
		check(chip.get_global_rect().end.y < scene.input.get_global_rect().position.y and chip.get_global_rect().end.x <= bounds.x, "Chip fits")

func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	check(scene.run_button.disabled and scene.chip_grid.get_child_count() == 6, "Empty six-slot state")
	check(scene.dossier.find_children("*", "Button", true, false).is_empty(), "Dossier read-only")
	await capture("desktop")
	for word in ["Fluffy", "Barsik", "19", "90", "Kek", "lol"]:
		type_fragment(scene, word)
	check(scene.session.candidates.size() == 1956, "Six fragments produce full combination pool")
	scene.special_toggle.button_pressed = true
	check(not scene.special_toggle.button_pressed and scene.session.dictionary.words.size() == 6 and scene.feedback.text.contains("Remove"), "Toggle rejected without deleting sixth fragment")
	type_fragment(scene, "seventh")
	check(scene.input.text == "seventh" and scene.session.dictionary.words.size() == 6, "Seventh fragment rejected")
	scene.input.clear()
	await capture("combinations")
	scene.remove_buttons[5].pressed.emit()
	scene.special_toggle.button_pressed = true
	check(scene.special_toggle.button_pressed and scene.session.dictionary.capacity() == 5 and scene.slots_label.text == "5 / 5", "Checkbox changes actual capacity")
	check(scene.chip_labels[5].text == "! ? # @" and scene.remove_buttons.size() == 5, "Reserved rule slot, no delete button")
	check(scene.session.candidates.size() <= 1950 and scene.session.candidates.size() > 325, "Special pool count")
	type_fragment(scene, "sixth")
	check(scene.input.text == "sixth" and scene.session.dictionary.words.size() == 5, "Special mode rejects sixth fragment")
	scene.input.clear()
	await process_frame
	await capture("specials")
	root.size = Vector2i(1024, 720)
	await process_frame
	await process_frame
	check_layout(scene)
	await capture("minimum")
	root.size = Vector2i(1440, 900)
	await process_frame
	scene.input.text = "unsaved"
	scene.run_button.pressed.emit()
	check(scene.session.engine.exposure == 0 and scene.feedback.text.contains("unsaved"), "Unsaved input blocks job for free")
	scene.input.clear()
	scene.run_button.pressed.emit()
	check(not scene.input.editable and scene.special_toggle.disabled and scene.run_button.disabled and scene.remove_buttons[0].disabled, "Job locks words and rules")
	await wait_for_job(scene)
	check(scene.session.engine.result == "SUCCESS" and scene.modal.visible, "Authored mission solved from fragments plus rules")
	check(scene.session.engine.attempts_used > 10 and scene.session.engine.exposure == 10, "More than ten candidates tested without network cap")
	check(scene.modal_body.text.contains("Barsik + 19 + 90") and scene.modal_body.text.contains("a → @ + !"), "Result explains combination and rule")
	check(scene.log_view.get_parsed_text().contains("--specials") and scene.log_view.get_parsed_text().contains("HASH MATCH"), "Terminal generated command and sample result")
	await capture("victory")
	scene._restart()
	check(not scene.special_toggle.button_pressed and scene.session.candidates.is_empty(), "Restart resets special mode and pool")
	type_fragment(scene, "[color=red]")
	check(scene.chip_labels[0].text == "[color=red]", "Literal fragment display")
	scene._restart()
	for fragment in ["aa", "ba", "ca", "da", "ea"]:
		type_fragment(scene, fragment)
	scene.special_toggle.button_pressed = true
	check(scene.session.candidates.size() == 1950, "Maximum special pool in UI")
	scene.run_button.pressed.emit()
	await create_timer(0.25).timeout
	check(scene.session.engine.phase == "RUNNING" and scene.session.engine.index > 0 and scene.session.engine.index < 1950, "Incremental responsive batches")
	await capture("running")
	await wait_for_job(scene)
	check(scene.session.engine.phase == "READY" and scene.session.engine.index == 1950 and scene.session.engine.exposure == 15, "Exhaustion checks entire pool, allows revision")
	check(not scene.modal.visible and scene.input.editable and scene.chip_labels[0].text == "aa", "Fragments retained after no-match")
	await capture("exhausted")
	scene._restart()
	scene.effects_toggle.button_pressed = false
	type_fragment(scene, "wrong")
	for i in 6:
		scene.run_button.pressed.emit()
		await wait_for_job(scene)
	check(scene.session.hint_shown and scene.fact_markers.pet.visible, "FX-off clue survives")
	await process_frame
	var scrollbar: VScrollBar = scene.log_view.get_v_scroll_bar()
	check(scrollbar.value >= scrollbar.max_value - scrollbar.page - 6, "Terminal follows batch output")
	scrollbar.value = 0
	scene._log("Reader scroll preservation", "system")
	await process_frame
	await process_frame
	check(scrollbar.value == 0, "Manual scroll preserved")
	scene.run_button.pressed.emit()
	check(scene.session.engine.result == "TRACE" and scene.session.engine.attempts_used == 6, "Relay trace before seventh job hashes")
	await capture("trace")
	scene.audio.set_music(true)
	scene.audio.set_muted(true)
	scene._restart()
	check(scene.audio.muted and scene.audio.music_player.playing and not scene.effects_enabled, "Preferences survive restart")
	scene.audio.set_music(false)
	print("UI SMOKE: %d checks, %d failures" % [count, failures.size()])
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
