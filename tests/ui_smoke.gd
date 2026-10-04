extends SceneTree

var failures: Array = []
var count := 0

func _initialize() -> void:
	root.position = Vector2i.ZERO
	call_deferred("run")
	create_timer(45.0).timeout.connect(func(): printerr("UI FAIL: watchdog timeout"); quit(1))

func check(condition: bool, description: String) -> void:
	count += 1
	if not condition:
		failures.append(description)
		printerr("UI FAIL: " + description)

func settle() -> void:
	await process_frame
	await process_frame
	await process_frame
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
	var webp := "--webp" in OS.get_cmdline_user_args()
	var path := directory.path_join("asscrackers-" + label + (".webp" if webp else ".png"))
	var image := root.get_texture().get_image()
	check((image.save_webp(path) if webp else image.save_png(path)) == OK, "Screenshot " + label)
	print("CAPTURE: " + path)

func mouse_button(point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	root.push_input(event)
	await settle()

func click_control(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	if DisplayServer.get_name() != "headless":
		root.warp_mouse(point)
		await settle()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion)
	await process_frame
	# Deliver one complete click before OS hover polling can move mouse focus.
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		root.push_input(event)
	await settle()

func drag_title(window: Control, offset: Vector2) -> void:
	var title := window.get_node("Stack/Titlebar") as Control
	var start := title.global_position + Vector2(80, 12)
	await mouse_button(start, true)
	var motion := InputEventMouseMotion.new()
	motion.position = start + offset
	motion.global_position = motion.position
	motion.relative = offset
	root.push_input(motion)
	await process_frame
	await mouse_button(start + offset, false)

func type_fragment(scene: Control, value: String) -> void:
	scene.input.text = value
	scene.input.text_submitted.emit(value)

func source(scene: Control, id: String) -> void:
	scene.get_node("IntelDetail").hide()
	scene._activate_application(&"Dossier")
	scene.dossier_scroll.ensure_control_visible(scene.dossier.nodes[id])
	await settle()
	var popup: Control = scene.get_node("IntelDetail")
	var widths: Array[float] = []
	var sample := func():
		if popup.is_visible_in_tree() and popup.modulate.a > 0:
			widths.append(popup.size.x)
	var frame_signal: Signal = process_frame if DisplayServer.get_name() == "headless" else RenderingServer.frame_post_draw
	frame_signal.connect(sample)
	await click_control(scene.dossier.nodes[id])
	await settle()
	frame_signal.disconnect(sample)
	check(scene.selected_intel == id and popup.visible and popup.modulate.a == 1, "Source opens anchored subwindow: " + id)
	check(not widths.is_empty() and widths.all(func(width: float): return absf(width - popup.preferred_size.x) < 1), "Every visible source frame has final width: " + id)
	var source_title: Label = popup.get_node("%InfoTitle")
	check(not source_title.text.is_empty() and source_title.size.y >= source_title.get_theme_font_size("font_size"), "Source metadata retains readable height: " + id)

func buy(scene: Control, id: String) -> void:
	await source(scene, id)
	await click_control(scene.get_node("IntelDetail").query_button)
	await settle()

func check_layout(scene: Control) -> void:
	var bounds := root.get_visible_rect().size
	check(scene.footer.get_global_rect().end.y <= bounds.y and scene.footer.get_global_rect().end.x <= bounds.x, "Taskbar fits")
	for application in scene.get_node("Applications").get_children():
		var rect: Rect2 = application.get_global_rect()
		check(rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= bounds.x and rect.end.y < scene.footer.get_global_rect().position.y, "Application fits desktop: " + application.name)
	var dictionary: Control = scene.get_node("Applications/Dictionary")
	var rect := dictionary.get_global_rect()
	check(scene.input.get_global_rect().position.x >= rect.position.x + 12 and scene.input.get_global_rect().end.x <= rect.end.x - 12, "Dictionary has horizontal content padding")
	check(scene.feedback.get_global_rect().end.y <= rect.end.y - 10, "Dictionary has bottom content padding")
	for chip in scene.chip_grid.get_children():
		check(chip.get_global_rect().end.y < scene.input.get_global_rect().position.y, "Slots stay above input")
	var popup: Control = scene.get_node("IntelDetail")
	if popup.visible:
		check(popup.get_global_rect().position.x >= 0 and popup.get_global_rect().end.x <= bounds.x and popup.get_global_rect().end.y < scene.footer.get_global_rect().position.y, "Intel subwindow stays in usable screen area")

func run() -> void:
	var music: Node = root.get_node("MusicManager")
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.get_node("Session").automatic_clock = false
	root.add_child(scene)
	await settle()
	var manager: Control = scene.get_node("Applications")
	if not manager.layout_is_ready():
		await manager.layout_ready
	var terminal: Control = manager.application(&"Terminal")
	var dictionary: Control = manager.application(&"Dictionary")
	var dossier_window: Control = manager.application(&"Dossier")
	var popup: Control = scene.get_node("IntelDetail")
	check(scene.run_button.disabled and scene.chip_grid.get_child_count() == 6, "Empty six-slot state")
	check(scene.portrait.texture.resource_path == "res://assets/portraits/player-icon.png", "Operator uses prepared player portrait")
	for window in manager.get_children():
		check(not window.visible, "Applications start hidden: " + window.name)
	check(scene.dossier.nodes.size() == 2 and not scene.dossier.nodes.has("pet"), "Initial graph hides undiscovered branches")
	check(terminal.target_label.text.contains("lexa@anus.industries"), "Known login displayed")
	check_layout(scene)
	await click_control(scene.get_node("DesktopIcons/TerminalShortcut"))
	var original_id := terminal.get_instance_id()
	var original_size := terminal.size
	var original_position := terminal.position
	await drag_title(terminal, Vector2(30, -20))
	check(terminal.position != original_position and terminal.size == original_size, "Titlebar moves window without resizing")
	var moved := terminal.position
	await click_control(terminal.get_node("Stack/Titlebar/Row/Close"))
	check(not terminal.visible, "Close hides application")
	await click_control(scene.get_node("DesktopIcons/TerminalShortcut"))
	check(terminal.visible and terminal.get_instance_id() == original_id and terminal.position == moved, "Shortcut restores same window and position")
	await drag_title(terminal, Vector2(-3000, -3000))
	check(terminal.position.x >= 8 and terminal.position.y >= 8 and terminal.size == original_size, "Dragging is bounded, size fixed")
	await drag_title(terminal, original_position - terminal.position)
	for id in [&"Dictionary", &"Operator", &"Dossier"]:
		scene._activate_application(id)
	await settle()
	scene.effects_toggle.button_pressed = false
	await settle()
	check(not scene.get_node("RetroEffects").visible, "FX disables entire stack")
	await capture("desktop-clean")
	scene.effects_toggle.button_pressed = true
	await capture("desktop")
	scene._activate_application(&"Terminal")
	await click_control(scene.special_toggle)
	check(manager.active_application == &"Dictionary" and scene.special_toggle.button_pressed, "Consumed checkbox click activates its owning window")
	await click_control(scene.special_toggle)
	await click_control(scene.get_node("DesktopIcons/HelpShortcut"))
	check(scene.tutorial.visible and scene.tutorial.is_ancestor_of(root.gui_get_focus_owner()), "Help takes modal focus")
	var tab := InputEventKey.new()
	tab.keycode = KEY_TAB
	tab.pressed = true
	root.push_input(tab)
	await process_frame
	check(scene.tutorial.is_ancestor_of(root.gui_get_focus_owner()), "Tab remains in modal")
	await capture("help")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape)
	await process_frame
	check(not scene.tutorial.visible, "Escape closes help")
	await source(scene, "nickname")
	check(not popup.body.text.contains("Lexa / @") and popup.query_button.visible and scene.session.budget.value == 0, "Click previews cost without retrieving content")
	await capture("intel-query")
	await click_control(popup.query_button)
	await settle()
	check(scene.session.budget.value == 5 and scene.dossier.nodes.size() == 5 and popup.body.text.contains("@lexa_never_sleeps"), "Paid query reveals content and branches")
	await source(scene, "nickname")
	check(not popup.query_button.visible and scene.session.budget.value == 5, "Purchased source opens for free")
	await buy(scene, "pet")
	check(scene.session.budget.value == 13 and not scene.dossier.nodes.has("habit"), "Deeper node waits for cross-reference")
	await buy(scene, "leaked")
	check(scene.dossier.nodes.has("habit"), "Cross-reference adds new leaf")
	await buy(scene, "birth_year")
	await buy(scene, "habit")
	check(scene.session.budget.value == 45 and popup.body.text.contains("replace lowercase a"), "Full useful recon trail costs 45")
	check(scene.session.dictionary.words.is_empty(), "Graph does not insert password fragments automatically")
	await capture("intel-revealed")
	var popup_position := popup.position
	await drag_title(dossier_window, Vector2(-130, -40))
	check(popup.visible and popup.position != popup_position, "Information subwindow follows its owner")
	manager.close_application(&"Dossier")
	check(not popup.visible, "Closing graph hides owned subwindow")
	manager.open_application(&"Dossier")
	await source(scene, "habit")
	check(popup.body.text.contains("replace lowercase a") and scene.session.budget.value == 45, "Reopening graph preserves bought information")
	popup.hide()
	scene._select_intel("nickname")
	check(popup.visible and popup.modulate.a == 0, "First popup reflow is not drawn")
	popup.hide()
	await settle()
	check(not popup.visible, "Closing during reflow prevents late popup reveal")
	scene._select_intel("birth_year")
	scene._select_intel("habit")
	await settle()
	await settle()
	check(popup.fact_id == "habit" and popup.modulate.a == 1 and popup.size.x == popup.preferred_size.x, "Rapid selection reveals only latest source at fixed width")
	root.size = Vector2i(1024, 720)
	await settle()
	check_layout(scene)
	await capture("minimum")
	root.size = Vector2i(1920, 1080)
	await settle()
	check_layout(scene)
	await capture("fullhd")
	root.size = Vector2i(1440, 900)
	await settle()
	popup.hide()
	scene._activate_application(&"Dictionary")
	var slot_ids: Array = []
	for slot in scene.chip_grid.get_children():
		slot_ids.append(slot.get_instance_id())
	for word in ["Fluffy", "Barsik", "19", "90", "Kek", "lol"]:
		type_fragment(scene, word)
	check(scene.session.candidates.size() == 1956 and scene.forecast_label.text.contains("60.000 s"), "Full dictionary forecasts one minute")
	scene.special_toggle.button_pressed = true
	check(not scene.special_toggle.button_pressed and scene.feedback.text.contains("Remove"), "Special toggle preserves sixth fragment")
	scene.remove_buttons[5].pressed.emit()
	scene.special_toggle.button_pressed = true
	check(scene.slots_label.text == "5 / 5" and scene.chip_labels[5].text == "! ? # @", "Special mode reserves one slot")
	for index in scene.chip_grid.get_child_count():
		check(scene.chip_grid.get_child(index).get_instance_id() == slot_ids[index], "Slot identities persist")
	scene.input.text = "unsaved"
	scene._run_dictionary()
	check(scene.session.budget.value == 45 and scene.feedback.text.contains("unsaved"), "Unsaved draft blocks attack for free")
	scene.input.clear()
	scene._run_dictionary()
	check(not scene.input.editable and scene.run_button.disabled and scene.get_node("Taskbar").stop_button.disabled == false, "Running job locks dictionary and enables global Stop")
	scene.session.advance(scene.session.generation, 60)
	await settle()
	check(scene.modal.visible and scene.session.engine.result == "SUCCESS" and scene.session.engine.elapsed < 60, "Early successful login opens result")
	check(scene.modal_body.text.contains("Barsik + 19 + 90") and scene.log_view.get_parsed_text().contains("LOGIN ACCEPTED"), "Result and log explain actual login match")
	await capture("victory")
	scene._restart()
	for fragment in ["a", "b", "c", "d", "e", "f"]:
		type_fragment(scene, fragment)
	scene._activate_application(&"Terminal")
	scene._run_dictionary()
	await click_control(terminal.get_node("Stack/Titlebar/Row/Close"))
	scene.session.advance(scene.session.generation, 5)
	await settle()
	check(not terminal.visible and scene.session.engine.index == 163 and scene.session.engine.phase == "RUNNING", "Closed terminal keeps botnet running")
	check(scene.get_node("Taskbar").remaining_label.text.contains("55.00") and scene.get_node("Taskbar").exposure_bar.value > 2, "Taskbar displays background time and exposure")
	await capture("background-job")
	for window in manager.get_children():
		manager.close_application(StringName(window.name))
	await click_control(scene.get_node("Taskbar").stop_button)
	var stopped_units: int = scene.session.budget.units
	scene.session.advance(scene.session.generation, 60)
	check(scene.session.engine.phase == "READY" and scene.session.budget.units == stopped_units, "Global Stop works with every application closed")
	await click_control(scene.get_node("Taskbar").application_buttons[&"Terminal"])
	check(terminal.visible and terminal.get_instance_id() == original_id and scene.log_view.get_parsed_text().contains("STOPPED"), "Taskbar reopens persistent application")
	scene._activate_application(&"Dictionary")
	scene._restart()
	type_fragment(scene, "[color=red]")
	check(scene.chip_labels[0].text == "[color=red]", "Literal fragment text preserved")
	scene._restart()
	# One tiny run uses the real runtime clock, with its terminal hidden.
	scene.session.automatic_clock = true
	type_fragment(scene, "wrong")
	scene._run_dictionary()
	manager.close_application(&"Terminal")
	await create_timer(0.2).timeout
	check(scene.session.engine.phase == "READY" and scene.session.engine.attempts_used == 1, "Real background clock finishes tiny pool")
	scene.session.automatic_clock = false
	scene._activate_application(&"Terminal")
	for line in 30:
		scene._log("Scroll preservation test line %d" % line)
	await settle()
	var scrollbar: VScrollBar = scene.log_view.get_v_scroll_bar()
	scrollbar.value = 0
	scene._log("Reader scroll preservation")
	await settle()
	check(scrollbar.value == 0, "Manual log scroll survives updates")
	scene._restart()
	scene.session.budget.charge_points(97)
	scene._query_intel("nickname")
	await settle()
	check(scene.modal.visible and scene.session.engine.result == "TRACE", "Paid recon can trigger shared-budget trace")
	await capture("trace")
	scene.effects_toggle.button_pressed = false
	music.play_cue(&"background")
	scene._set_music(true)
	scene._set_muted(true)
	scene._restart()
	check(scene.audio.muted and music.music_player.playing and not scene.effects_enabled and scene.dossier.nodes.size() == 2, "Restart resets recon, preserves presentation preferences")
	scene._set_music(false)
	print("UI SMOKE: %d checks, %d failures" % [count, failures.size()])
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
