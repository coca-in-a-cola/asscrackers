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
@onready var dossier: VBoxContainer = %Dossier.dossier
@onready var dossier_scroll: ScrollContainer = %Dossier.dossier_scroll
@onready var voice: Label = %Dossier.voice
@onready var modal: Control = %ResultOverlay
@onready var modal_title: Label = %Result.heading
@onready var modal_body: RichTextLabel = %Result.body
@onready var tutorial: Control = %HelpOverlay
@onready var footer: HBoxContainer = %Taskbar.footer
@onready var result_button: Button = %Taskbar.result_button
@onready var effects_toggle: CheckBox = %Taskbar.effects_toggle

var chip_labels: Array[Label] = []
var remove_buttons: Array[Button] = []
var fact_markers: Dictionary = {}
var effects_enabled := true
var mission_ready := false
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
	session.hint.connect(_on_hint)
	session.ended.connect(_on_end)
	run_button.pressed.connect(_run_dictionary)
	log_view.gui_input.connect(_log_scroll_input)
	log_view.get_v_scroll_bar().gui_input.connect(_log_scroll_input)
	%Help.body.text = copy.help_text
	%Taskbar.location_label.text = "ASS / CRACKERS · " + copy.location
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
	if application_name == &"Help":
		_show_help()
		return
	%Applications.focus_application(application_name)
	if application_name == &"Dictionary" and input.editable:
		input.grab_focus()
	elif application_name == &"Terminal":
		log_view.grab_focus()
	elif application_name == &"Dossier":
		dossier_scroll.grab_focus()

func _set_music(enabled: bool) -> void:
	audio.set_music(enabled)

func _set_muted(enabled: bool) -> void:
	audio.set_muted(enabled)

func _set_volume(value: float) -> void:
	audio.set_level(value)

func _show_help() -> void:
	tutorial.show()
	%Help.active = true
	%Help.focus_primary()

func _hide_help() -> void:
	tutorial.hide()
	_restore_focus()

func _show_result() -> void:
	modal.show()
	%Result.active = true
	%Result.focus_primary()

func _hide_result() -> void:
	modal.hide()
	_restore_focus()

func _restore_focus() -> void:
	if tutorial.visible:
		%Help.focus_primary()
	elif modal.visible:
		%Result.focus_primary()
	elif input.editable:
		input.grab_focus()
	else:
		result_button.grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if tutorial.visible:
			_hide_help()
		elif modal.visible:
			_hide_result()
		else:
			return
		accept_event()

func _restart() -> void:
	modal.hide()
	result_button.hide()
	tutorial.hide()
	mission_ready = false
	var loaded: Dictionary = session.restart()
	log_lines.clear()
	log_view.clear()
	_follow_pending = true
	_log_scroll_ticket += 1
	input.clear()
	voice_index = 0
	%VoiceTimer.wait_time = 24.0
	%VoiceTimer.start()
	if not loaded.ok:
		modal_title.text = "MISSION DATA ERROR"
		modal_body.text = loaded.message
		_show_result()
		_refresh()
		return
	mission_ready = true
	%Dossier.apply_mission(session.public_mission)
	fact_markers = %Dossier.fact_markers
	_log("Captured SHA-256 hash / account lexa / offline GPU simulation", "system")
	_log("Add fragments. Hashdog combines them automatically.", "success")
	_set_feedback("Read the dossier. Add names and numbers separately; hashdog does the combining.")
	voice.text = "“The cat is not on your payroll.\nNeither is the voice in your head.” — ?"
	_refresh()
	input.grab_focus()

func _submit_fragment(value: String) -> Dictionary:
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
	if not input.text.strip_edges().is_empty():
		_set_feedback("You have an unsaved fragment. Press Enter to save it, or clear the input first.", true)
		input.grab_focus()
		return
	_log("$ hashdog run --combine" + (" --specials" if session.dictionary.special_characters else ""), "command")
	var response: Dictionary = session.start_attack()
	_log(response.message, "system" if response.ok else "error")
	_set_feedback("Checking generated candidates…" if session.engine.phase == "RUNNING" else response.message, not response.ok)
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
	exposure_label.text = "EXPOSURE  %02d / 100" % model.exposure
	exposure_label.add_theme_color_override("font_color", _color("error" if model.exposure >= 70 else "text"))
	exposure_bar.value = model.exposure
	budget_label.text = "CHECKED %d / %d" % [model.index, model.queue.size()] if model.phase in ["RUNNING", "WON"] else "POOL %d / 1956" % session.candidates.size()
	state_label.text = model.phase
	state_label.add_theme_color_override("font_color", _color("error" if model.phase == "LOST" else "accent"))
	input.editable = can_edit
	%Dictionary.add_button.disabled = not can_edit
	special_toggle.disabled = not can_edit
	special_toggle.set_pressed_no_signal(session.dictionary.special_characters)
	run_button.disabled = not can_edit or session.dictionary.words.is_empty()
	run_button.text = "Testing %d / %d" % [model.index, model.queue.size()] if model.phase == "RUNNING" else "Run dictionary"
	slots_label.text = "%d / %d" % [session.dictionary.words.size(), session.dictionary.capacity()]
	if can_edit:
		forecast_label.text = "%d candidates · %s · +10 exposure/job, +5 exhausted" % [session.candidates.size(), "6 special rules" if session.dictionary.special_characters else "all fragment orders"]
		if model.exposure >= 90:
			forecast_label.text = "TRACE WARNING: starting another job reaches 100 Exposure."
	elif model.phase == "RUNNING":
		forecast_label.text = "GPU SIM · %d / %d checked · terminal shows batch samples" % [model.index, model.queue.size()]
	else:
		forecast_label.text = "Session closed. Restart to try again."
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
		_set_feedback("No match. Revise fragments or enable special characters. Individual words are not ruled out.")

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

func _on_hint(fact_id: String) -> void:
	var marker: Label = fact_markers.get(fact_id)
	if marker:
		marker.show()
	voice.text = "“MEOW. His current cat. His birth year.\nSame old pattern.” — Barsik, allegedly"
	_log("[HALLUCINATION] Start with his current cat: Barsik.", "voice")
	audio.play("hint")

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
		detail = "Your rented compute relay was traced after repeated jobs.\nThe local hash checks did not send login requests."
		detail += "\n\n“Don't worry. The report will call you an unknown idiot.”\n— a voice from the air vent\n\nRead the clues again and try a different set of fragments."
	modal_body.text = detail + "\n\nHashes checked: %d · Jobs: %d · Exposure: %d/100" % [session.engine.attempts_used, session.engine.runs_used, session.engine.exposure]
	result_button.show()
	_show_result()
	_set_feedback("Session closed. Restart the mission to try again.")
	audio.play("success" if result == "SUCCESS" else "fail")
	_log(titles[result], "success" if result == "SUCCESS" else "error")

func _on_voice_timeout() -> void:
	%VoiceTimer.wait_time = 32.0
	if session.engine.phase not in ["READY", "RUNNING"] or copy.idle_voices.is_empty():
		return
	if not session.hint_shown:
		voice.text = copy.idle_voices[voice_index % copy.idle_voices.size()]
	voice_index += 1
