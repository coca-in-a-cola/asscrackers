extends "res://tests/startup_audio.gd"

func _initialize() -> void:
	root.position = Vector2i.ZERO
	call_deferred("run")
	create_timer(90.0).timeout.connect(_timeout)

func advance_to(boot: Control, expected: String) -> void:
	var deadline := Time.get_ticks_msec() + 18000
	while boot.phase != expected and Time.get_ticks_msec() < deadline:
		if boot.phase == "DIALOGUE" and not boot.get_node("%DialogueDirector").busy:
			await tap(KEY_Q)
		else:
			await process_frame
	check(boot.phase == expected, "Campaign reaches " + expected)

func solve(game: Control, index: int, recon := true) -> void:
	var routes := [["nickname", "pet", "leaked", "birth_year", "habit"], ["profile", "education", "pet", "sample", "habit"], ["directory", "vehicle", "forum", "sample", "habit"]]
	var fragments := [["Barsik", "19", "90"], ["Luna", "2002"], ["Volga", "1984"]]
	game.session.automatic_clock = false
	if recon:
		for source in routes[index]:
			check(game.session.request_intel(source).ok, "Campaign source " + source)
	for fragment in fragments[index]:
		game._submit_fragment(fragment)
	game._toggle_special_characters(true)
	game._run_dictionary()
	game.session.advance(game.session.generation, 120)
	await settle()
	check(game.session.engine.phase == "WON", "Campaign solved target " + str(index))

func run() -> void:
	var boot: Control = load("res://scenes/boot.tscn").instantiate()
	root.add_child(boot)
	await settle()
	var conversations: Array[String] = []
	boot.get_node("%DialogueDirector").started.connect(func(entry: DialogueEntry): conversations.append(str(entry.id)))
	await tap(KEY_X)
	await advance_to(boot, "PLAY")
	var game: Control = boot.desktop
	var positions: Dictionary = {}
	for window in game.get_node("Applications").get_children():
		positions[window.name] = window.position
	for index in 3:
		check(boot.run.index == index and game.goal == boot.campaign.goals[index], "Campaign selects authored goal " + str(index))
		check(game.session.budget.units == 0 and game.session.dictionary.words.is_empty(), "Goal starts with fresh risk and dictionary")
		await solve(game, index)
		check(boot.phase == "RESULT" and not boot.get_node("Intro").active and boot.run.results.size() == index, "SUCCESS waits for explicit submission")
		var button: Button = game.get_node("%Result").get_node("%Primary")
		check(button.text == "SUBMIT RESULT" and button.size.y >= 60, "Large submit action")
		check(game.get_node("%Result").get_node("%Mark").text == "MARK B", "Per-target frozen mark shown")
		if index == 0:
			for resolution in [Vector2i(1024, 720), Vector2i(1440, 900), Vector2i(1920, 1080)]:
				root.size = resolution
				await settle()
				check(root.get_visible_rect().encloses(game.get_node("%Result").get_global_rect()), "Success result fits " + str(resolution))
				await capture("submit-" + str(resolution.x))
			root.size = Vector2i(1440, 900)
			await settle()
		# Resolution changes legitimately clamp positions; compare the transition itself.
		for window in game.get_node("Applications").get_children():
			positions[window.name] = window.position
		await click_control(button)
		game._result_primary()
		check(boot.run.results.size() == index + 1 and boot.run.phase == &"TRANSITION", "Submit records once and opens post-target dialogue")
		await advance_to(boot, "PLAY" if index < 2 else "SUMMARY")
		for window in game.get_node("Applications").get_children():
			check(window.position == positions[window.name] and not window.visible, "Target transition preserves window position and closes it")
	check(boot.run.results.size() == 3 and boot.run.final_mark() == "B", "Three submitted targets yield final B")
	check(conversations == ["intro", "after_hr", "before_finance", "after_finance", "before_vault", "after_vault", "ending"], "Every before/after dialogue runs once in authored order")
	var summary: Control = boot.get_node("%Summary")
	check(summary.get_node("%Rows").get_child_count() == 16 and summary.get_node("%Mark").text == "FINAL MARK B", "Summary contains all targets and final mark")
	for resolution in [Vector2i(1024, 720), Vector2i(1440, 900), Vector2i(1920, 1080)]:
		root.size = resolution
		await settle()
		check(root.get_visible_rect().encloses(summary.get_node("Margin/Center/Panel").get_global_rect()), "Summary fits " + str(resolution))
		await capture("summary-" + str(resolution.x))
	root.size = Vector2i(1440, 900)
	await settle()
	# Exercise every real conditional ending without duplicating game narrative in tests.
	var ending_texts: Array[String] = []
	for risk in [10, 35, 60, 85]:
		boot.run.begin(boot.campaign)
		for index in 3:
			boot.run.record_success({"result": "SUCCESS", "mission_id": str(boot.campaign.goals[index].id), "exposure_units": risk * 1956, "requests": 1, "jobs": 1, "elapsed": 0.1})
			boot.run.submit_result()
			boot.run.advance_target()
		summary.hide()
		boot._open_dialogue(boot.campaign.ending_dialogue, &"ending")
		await wait_phase(boot, "DIALOGUE")
		var director: Node = boot.get_node("%DialogueDirector")
		check(director.line.character == "Curator", "Final branch is curator-only")
		ending_texts.append(director.line.text)
		await tap()
		await capture("ending-" + boot.final_mark)
		await advance_to(boot, "SUMMARY")
	check(ending_texts.size() == 4 and ending_texts.all(func(text: String): return ending_texts.count(text) == 1), "A/B/C/D select four distinct authored final lines")
	game._set_volume(0.22)
	game._set_effects(false)
	summary.return_button.grab_focus()
	await tap(KEY_ENTER)
	await settle()
	check(boot.phase == "TITLE" and boot.desktop == null and boot.run.results.is_empty(), "Summary returns to fresh title")
	var music: Node = root.get_node("MusicManager")
	check(not music.music_player.playing and music.cue_id.is_empty(), "Returning to title stops soundtrack")
	for target_index in 3:
		await tap(KEY_X)
		await advance_to(boot, "PLAY")
		game = boot.desktop
		check(not game.effects_enabled and is_equal_approx(music.level, 0.22), "New campaign preserves audio and FX preferences")
		for previous in target_index:
			await solve(game, previous, false)
			game._result_primary()
			await advance_to(boot, "PLAY")
		game.session.budget.charge_points(97)
		var first_source: String = game.session.recon_snapshot()[0].id
		game._query_intel(first_source)
		await settle()
		check(boot.phase == "GAME_OVER" and game.modal_title.text.contains("GAME OVER") and boot.run.phase == &"FAILED", "TRACE on target " + str(target_index) + " ends campaign")
		check(not game.get_node("%Result").get_node("%ScoreRow").visible, "Game over has no successful mark")
		await capture("game-over-" + str(target_index + 1))
		game.get_node("%Result").get_node("%Primary").grab_focus()
		await tap(KEY_ENTER)
		await settle()
		check(boot.phase == "TITLE" and boot.desktop == null and boot.run.results.is_empty() and not music.music_player.playing, "TRACE resets whole campaign to silent initial screen")
	boot.queue_free()
	await settle()
	print("CAMPAIGN FLOW: %d checks, %d failures" % [count, failures.size()])
	quit(0 if failures.is_empty() else 1)
