extends Control

@export var copy: DesktopCopy

@onready var session: Node = %Session
@onready var audio: Node = %Audio
@onready var background: Control = %Background
@onready var portrait: Control = %Operator.portrait
@onready var input: LineEdit = %Dictionary.input
@onready var log_view: RichTextLabel = %Terminal.log_view
@onready var exposure_label: Label = %Terminal.exposure_label
@onready var exposure_bar: ProgressBar = %Terminal.exposure_bar
@onready var budget_label: Label = %Terminal.budget_label
@onready var state_label: Label = %Taskbar.state_label
@onready var run_button: Button = %Terminal.run_button
@onready var slots_label: Label = %Dictionary.slots_label
@onready var special_toggle: CheckBox = %Dictionary.special_toggle
@onready var chip_grid: GridContainer = %Dictionary.chip_grid
@onready var feedback: Label = %Dictionary.feedback
@onready var forecast_label: Label = %Terminal.forecast_label
@onready var dossier: Control = %Dossier.dossier
@onready var dossier_scroll: ScrollContainer = %Dossier.dossier_scroll
@onready var voice: Label = %Dossier.voice
@onready var modal: Control = %ResultOverlay
@onready var modal_title: Label = %Result.heading
@onready var modal_body: RichTextLabel = %Result.body
@onready var tutorial: Control = %HelpOverlay
@onready var footer: VBoxContainer = %Taskbar.footer
@onready var result_button: Button = %Taskbar.result_button
@onready var effects_toggle: CheckBox = %Taskbar.effects_toggle

var chip_labels: Array[Label] = []
var remove_buttons: Array[Button] = []
var selected_intel := ""
var effects_enabled := true
var mission_ready := false
var intro_pending := false
var log_lines: Array[Dictionary] = []
var _follow_pending := false
var _log_scroll_ticket := 0
var voice_index := 0

func _ready() -> void:
	get_window().min_size = Vector2i(1024, 720)
	get_window().size_changed.connect(_update_canvas_size)
	_update_canvas_size()
	session.message.connect(_log)
	session.changed.connect(_refresh)
	session.intel_changed.connect(_refresh_intel)
	session.ended.connect(_on_end)
	run_button.pressed.connect(_run_dictionary)
	%Terminal.stop_button.pressed.connect(_stop_attack)
	log_view.gui_input.connect(_log_scroll_input)
	log_view.get_v_scroll_bar().gui_input.connect(_log_scroll_input)
	%Help.body.text = copy.help_text
	%Taskbar.location_label.text = "ASS / CRACKERS · " + copy.location
	MusicManager.changed.connect(_sync_audio_controls)
	_sync_audio_controls()
	_restart()

func _update_canvas_size() -> void:
	# Keep Controls at native pixel density while using canvas_items for CRT.
	# Resizing changes the layout rather than shrinking small text below its floor.
	var window := get_window()
	if window.content_scale_size != window.size:
		window.content_scale_size = window.size

func _color(role: String) -> Color:
	return theme.get_color(role, &"Palette")

func _set_effects(enabled: bool) -> void:
	effects_enabled = enabled
	background.effects_enabled = enabled
	background.queue_redraw()
	%RetroEffects.visible = enabled

func _activate_application(application_name: StringName) -> void:
	if intro_pending:
		return
	if not %Applications.layout_is_ready():
		await %Applications.layout_ready
	if application_name == &"Help":
		_show_help()
		return
	%Applications.open_application(application_name)
	if application_name == &"Dictionary" and input.editable:
		input.grab_focus()
	elif application_name == &"Terminal":
		log_view.grab_focus()
	elif application_name == &"Dossier":
		dossier_scroll.grab_focus()

func _refresh_windows() -> void:
	if not is_instance_valid(%Taskbar):
		return
	%Taskbar.update_windows(%Applications)
	if not %Dossier.visible or %Applications.active_application != &"Dossier":
		%IntelDetail.hide()

func _on_window_moved(application_name: StringName) -> void:
	if application_name == &"Dossier":
		_position_intel_popup()

func _refresh_intel() -> void:
	%Dossier.apply_snapshot(session.recon_snapshot())
	_refresh_intel_popup()

func _select_intel(id: String) -> void:
	selected_intel = id
	%Applications.focus_application(&"Dossier")
	dossier.select_node(id)
	%IntelDetail.show()
	_refresh_intel_popup()
	_position_intel_popup()
	_settle_intel_popup()

func _settle_intel_popup() -> void:
	# Reflow wrapped source labels at the final width before fixing the height.
	await get_tree().process_frame
	await get_tree().process_frame
	if not %IntelDetail.visible:
		return
	%IntelDetail.size = Vector2(340, 300).max(%IntelDetail.get_combined_minimum_size())
	_position_intel_popup()

func _refresh_intel_popup() -> void:
	if selected_intel.is_empty() or not %IntelDetail.visible:
		return
	for fact in session.recon_snapshot():
		if fact.id == selected_intel:
			%IntelDetail.apply(fact, session.budget.value, session.engine.phase in ["READY", "RUNNING"])
			%IntelDetail.size = Vector2(340, 300).max(%IntelDetail.get_combined_minimum_size())
			return
	%IntelDetail.hide()

func _position_intel_popup() -> void:
	if not is_instance_valid(%IntelDetail) or not %IntelDetail.visible or selected_intel.is_empty():
		return
	var rect: Rect2 = dossier.node_rect(selected_intel)
	var popup_size: Vector2 = %IntelDetail.size
	var point := Vector2(rect.end.x + 10, rect.position.y)
	if point.x + popup_size.x > size.x - 8:
		point.x = rect.position.x - popup_size.x - 10
	%IntelDetail.position = point.clamp(Vector2(8, 8), Vector2(maxf(8, size.x - popup_size.x - 8), maxf(8, %Taskbar.position.y - popup_size.y - 8)))

func _query_intel(id: String) -> void:
	if intro_pending:
		return
	var response: Dictionary = session.request_intel(id)
	if response.get("purchased", false):
		audio.play("hint")
	_refresh_intel_popup()

func _stop_attack() -> void:
	session.stop_attack()

func _set_music(enabled: bool) -> void:
	MusicManager.set_enabled(enabled)

func _sync_audio_controls() -> void:
	audio.set_muted(MusicManager.muted)
	audio.set_level(MusicManager.level)
	%Taskbar.music_toggle.set_pressed_no_signal(MusicManager.enabled)
	%Taskbar.mute_toggle.set_pressed_no_signal(MusicManager.muted)
	%Taskbar.volume_slider.set_value_no_signal(MusicManager.level)

func finish_intro() -> void:
	intro_pending = false
	%VoiceTimer.start()
	_restore_focus()

func _set_muted(enabled: bool) -> void:
	MusicManager.set_muted(enabled)

func _set_volume(value: float) -> void:
	MusicManager.set_level(value)

func _show_help() -> void:
	if intro_pending:
		return
	%Applications.cancel_drag()
	tutorial.show()
	%Help.active = true
	%Help.focus_primary()

func _hide_help() -> void:
	tutorial.hide()
	_restore_focus()

func _show_result() -> void:
	%Applications.cancel_drag()
	%IntelDetail.hide()
	modal.show()
	%Result.active = true
	%Result.focus_primary()

func _hide_result() -> void:
	modal.hide()
	_restore_focus()

func _restore_focus() -> void:
	if intro_pending:
		return
	if tutorial.visible:
		%Help.focus_primary()
	elif modal.visible:
		%Result.focus_primary()
	elif input.editable and %Dictionary.visible:
		input.grab_focus()
	elif result_button.visible:
		result_button.grab_focus()
	else:
		$DesktopIcons/TerminalShortcut.grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if tutorial.visible:
			_hide_help()
		elif modal.visible:
			_hide_result()
		elif %IntelDetail.visible:
			%IntelDetail.hide()
		else:
			return
		accept_event()

func _restart() -> void:
	modal.hide()
	result_button.hide()
	tutorial.hide()
	%IntelDetail.hide()
	selected_intel = ""
	mission_ready = false
	var loaded: Dictionary = session.restart()
	log_lines.clear()
	log_view.clear()
	_follow_pending = true
	_log_scroll_ticket += 1
	input.clear()
	voice_index = 0
	%VoiceTimer.wait_time = 24.0
	if intro_pending:
		%VoiceTimer.stop()
	else:
		%VoiceTimer.start()
	if not loaded.ok:
		modal_title.text = "MISSION DATA ERROR"
		modal_body.text = loaded.message
		_show_result()
		_refresh()
		return
	mission_ready = true
	%Dossier.apply_mission(session.public_mission)
	%Terminal.target_label.text = session.service.display_name + "\nAccount: " + session.public_mission.login + " / time coefficient ×%.2f" % session.service.time_coefficient
	_log("TARGET / %s / %s" % [session.service.display_name, session.public_mission.login], "system")
	_log("24 botnet relays ready. Recon queries and login attempts share Exposure.", "success")
	_log(session.public_mission.brief, "system")
	_set_feedback("Investigate G-D's Eye. Add fragments; a smaller pool costs less.")
	voice.text = "“Every source leaves a footprint. So does every login.” — ?"
	_refresh_intel()
	_refresh()
	_restore_focus()

func _submit_fragment(value: String) -> Dictionary:
	if intro_pending:
		return {"ok": false, "message": "Wait for the briefing to finish."}
	var response: Dictionary = session.add_fragment(value)
	_set_feedback(response.message, not response.ok)
	if response.ok:
		input.clear()
		if response.get("added", false):
			audio.play("add")
	else:
		input.text = value
		input.caret_column = value.length()
	input.grab_focus()
	return response

func _remove_fragment(value: String) -> void:
	var response: Dictionary = session.remove_fragment(value)
	_set_feedback(response.message, not response.ok)
	if response.ok:
		input.grab_focus()

func _toggle_special_characters(enabled: bool) -> void:
	var response: Dictionary = session.set_special_characters(enabled)
	special_toggle.set_pressed_no_signal(session.dictionary.special_characters)
	_set_feedback(response.message, not response.ok)

func _run_dictionary() -> void:
	if intro_pending:
		return
	if not input.text.strip_edges().is_empty():
		_set_feedback("You have an unsaved fragment. Press Enter to save it, or clear the input first.", true)
		input.grab_focus()
		return
	_log("$ hashdog botnet --login " + session.public_mission.login + " --combine" + (" --specials" if session.dictionary.special_characters else ""), "command")
	var response: Dictionary = session.start_attack()
	_log(response.message, "system" if response.ok else "error")
	_set_feedback("Botnet running. Closing its window does not stop requests." if session.engine.phase == "RUNNING" else response.message, not response.ok)
	if response.ok and session.engine.phase == "RUNNING":
		audio.play("run")

func _set_feedback(value: String, error: bool = false) -> void:
	feedback.text = value
	feedback.add_theme_color_override("font_color", _color("error" if error else "muted"))

func _refresh() -> void:
	if not is_instance_valid(exposure_label):
		return
	var model = session.engine
	var can_edit: bool = mission_ready and model.phase == "READY"
	exposure_label.text = "EXPOSURE  %.1f / 100" % model.exposure
	exposure_label.add_theme_color_override("font_color", _color("error" if model.exposure >= 70 else "text"))
	exposure_bar.value = model.exposure
	budget_label.text = "CHECKED %d / %d" % [model.index, model.queue.size()] if model.phase in ["RUNNING", "WON"] else "POOL %d / 1956" % session.candidates.size()
	state_label.text = model.phase
	state_label.add_theme_color_override("font_color", _color("error" if model.phase == "LOST" else "accent"))
	%Taskbar.exposure_label.text = exposure_label.text
	%Taskbar.exposure_label.add_theme_color_override("font_color", _color("error" if model.exposure >= 70 else "text"))
	%Taskbar.exposure_bar.value = model.exposure
	%Taskbar.remaining_label.text = "%.2f s left" % model.remaining if model.phase == "RUNNING" else "BOTNET IDLE"
	%Taskbar.stop_button.disabled = model.phase != "RUNNING"
	%Terminal.stop_button.disabled = model.phase != "RUNNING"
	input.editable = can_edit
	%Dictionary.add_button.disabled = not can_edit
	special_toggle.disabled = not can_edit
	special_toggle.set_pressed_no_signal(session.dictionary.special_characters)
	run_button.disabled = not can_edit or session.dictionary.words.is_empty()
	run_button.text = "Running…" if model.phase == "RUNNING" else "Run dictionary"
	slots_label.text = "%d / %d" % [session.dictionary.words.size(), session.dictionary.capacity()]
	if can_edit:
		var preview: Dictionary = session.forecast()
		forecast_label.text = "%d candidates / %.3f s / up to +%.2f EXP" % [session.candidates.size(), preview.duration, preview.cost]
		if model.exposure + preview.cost >= 100:
			forecast_label.text = "TRACE WARNING / " + forecast_label.text
	elif model.phase == "RUNNING":
		forecast_label.text = "BOTNET / %d/%d sent / %.2f s left / Stop saves unsent requests" % [model.index, model.queue.size(), model.remaining]
	else:
		forecast_label.text = "Session closed. Restart to try again."
	forecast_label.tooltip_text = forecast_label.text
	_refresh_intel_popup()
	_refresh_chips()

func _refresh_chips() -> void:
	chip_labels.clear()
	remove_buttons.clear()
	var words: Array = session.dictionary.words
	for i in chip_grid.get_child_count():
		var occupied := i < words.size()
		var word: String = words[i] if occupied else ""
		var reserved: bool = session.dictionary.special_characters and i == 5
		var status := "FRAGMENT" if occupied else ("RULE SLOT" if reserved else "EMPTY SLOT")
		if occupied and not session.engine.match_record.is_empty() and word in session.engine.match_record.sources:
			status = "USED IN MATCH"
		if occupied and session.engine.phase == "RUNNING":
			status = "IN POOL"
		var slot = chip_grid.get_child(i)
		slot.apply(word, status, mission_ready and session.engine.phase == "READY")
		chip_labels.append(slot.word_label)
		if occupied:
			remove_buttons.append(slot.remove_button)

func _log(value: String, kind: String = "info") -> void:
	var scrollbar := log_view.get_v_scroll_bar()
	var follow := _follow_pending or scrollbar.value >= scrollbar.max_value - scrollbar.page - 6
	var previous := scrollbar.value
	var role: String = {"success": "terminal_success", "error": "terminal_error", "voice": "terminal_error", "warning": "terminal_warning", "attempt": "terminal_warning"}.get(kind, "terminal_text")
	for line in value.split("\n"):
		log_lines.append({"text": line, "color": _color(role)})
	if log_lines.size() > 1000:
		log_lines = log_lines.slice(log_lines.size() - 1000)
	log_view.clear()
	for line in log_lines:
		log_view.push_color(line.color)
		log_view.add_text(line.text + "\n")
		log_view.pop()
	_follow_pending = follow
	_log_scroll_ticket += 1
	_settle_log_scroll(_log_scroll_ticket, follow, previous)
	if kind == "warning":
		_set_feedback("No match. Investigate another source or revise fragments/rules.")

func _log_scroll_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_follow_pending = false
		_log_scroll_ticket += 1

func _settle_log_scroll(ticket: int, follow: bool, previous: float) -> void:
	await get_tree().process_frame
	if ticket != _log_scroll_ticket:
		return
	var scrollbar := log_view.get_v_scroll_bar()
	scrollbar.value = scrollbar.max_value if follow else previous
	_follow_pending = false

func _on_end(result: String) -> void:
	tutorial.hide()
	var titles := {"SUCCESS": "ACCESS GRANTED", "TRACE": "TRACE DETECTED"}
	modal_title.text = titles[result]
	modal_title.add_theme_color_override("font_color", _color("success" if result == "SUCCESS" else "error"))
	var detail := ""
	if result == "SUCCESS":
		var solved: Dictionary = session.victory_details()
		detail = "Password: %s\n\n%s\n\nLayoff order retrieved. The department lives another day.\nBarsik wants a promotion to Chief Scratching Officer." % [solved.password, solved.explanation]
		detail += "\n\nFragments: %s · Rule: %s" % [" + ".join(session.engine.match_record.sources), session.engine.match_record.rule]
	else:
		detail = "Your botnet and recon sources were correlated by the target service.\nThe operation reached 100 Exposure."
		detail += "\n\n“Don't worry. The report will call you an unknown idiot.”\n— a voice from the air vent\n\nRead the clues again and try a different set of fragments."
	modal_body.text = detail + "\n\nLogin requests: %d · Jobs: %d · Exposure: %.2f/100" % [session.engine.attempts_used, session.engine.runs_used, session.engine.exposure]
	result_button.show()
	_show_result()
	_set_feedback("Session closed. Restart the mission to try again.")
	audio.play("success" if result == "SUCCESS" else "fail")
	_log(titles[result], "success" if result == "SUCCESS" else "error")

func _on_voice_timeout() -> void:
	%VoiceTimer.wait_time = 32.0
	if session.engine.phase not in ["READY", "RUNNING"] or copy.idle_voices.is_empty():
		return
	voice.text = copy.idle_voices[voice_index % copy.idle_voices.size()]
	voice_index += 1
