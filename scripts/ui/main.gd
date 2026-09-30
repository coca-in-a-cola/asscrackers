extends Control

const Session = preload("res://scripts/domain/game_session.gd")
const Art = preload("res://scripts/ui/cyber_art.gd")
const Synth = preload("res://scripts/ui/synth_audio.gd")
const CYAN := Color("00ffcc")
const PINK := Color("ff369a")
const GOLD := Color("f4d67a")
const INK := Color("d4e1f0")
const MUTED := Color("7d92b0")

var session: Node
var audio: Node
var background: Control
var portrait: Control
var input: LineEdit
var log_view: RichTextLabel
var exposure_label: Label
var exposure_bar: ProgressBar
var budget_label: Label
var state_label: Label
var run_button: Button
var slots_label: Label
var special_toggle: CheckButton
var chip_grid: GridContainer
var chip_labels: Array[Label] = []
var remove_buttons: Array[Button] = []
var feedback: Label
var forecast_label: Label
var dossier: VBoxContainer
var dossier_scroll: ScrollContainer
var fact_markers: Dictionary = {}
var voice: Label
var modal: PanelContainer
var modal_title: Label
var modal_body: RichTextLabel
var tutorial: AcceptDialog
var footer: HBoxContainer
var result_button: Button
var effects_toggle: CheckButton
var effects_enabled := true
var mission_ready := false
var log_lines: Array = []
var _follow_pending := false
var _log_scroll_ticket := 0
var elapsed := 0.0
var next_voice := 24.0
var voice_index := 0

func _ready() -> void:
	get_window().min_size = Vector2i(1024, 720)
	_build_theme()
	session = Session.new()
	add_child(session)
	audio = Synth.new()
	add_child(audio)
	_build_ui()
	session.message.connect(_log)
	session.changed.connect(_refresh)
	session.hint.connect(_on_hint)
	session.ended.connect(_on_end)
	_restart()

func box(fill: Color, border: Color, radius: int = 8, padding: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style

func _build_theme() -> void:
	var custom := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Cascadia Code", "Consolas", "DejaVu Sans Mono"])
	custom.default_font = font
	custom.default_font_size = 16
	custom.set_color("font_color", "Label", INK)
	custom.set_color("default_color", "RichTextLabel", INK)
	custom.set_color("font_color", "Button", CYAN)
	custom.set_color("font_hover_color", "Button", Color.WHITE)
	custom.set_color("font_disabled_color", "Button", MUTED)
	custom.set_stylebox("normal", "Button", box(Color("142638"), Color("2c5664"), 6, 10))
	custom.set_stylebox("hover", "Button", box(Color("1d3d4c"), CYAN, 6, 10))
	custom.set_stylebox("pressed", "Button", box(Color("244158"), PINK, 6, 10))
	custom.set_stylebox("disabled", "Button", box(Color("111b2a"), Color("263348"), 6, 10))
	custom.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), GOLD, 6, 10))
	custom.set_stylebox("normal", "LineEdit", box(Color("080e19"), Color("2b5263"), 8, 14))
	custom.set_stylebox("focus", "LineEdit", box(Color("0c1723"), CYAN, 8, 14))
	custom.set_color("font_color", "LineEdit", CYAN)
	custom.set_color("caret_color", "LineEdit", PINK)
	custom.set_stylebox("background", "ProgressBar", box(Color("192338"), Color("192338"), 3, 0))
	custom.set_stylebox("fill", "ProgressBar", box(CYAN, CYAN, 3, 0))
	theme = custom

func text(value: String, font_size: int = 16, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func button(value: String, callback: Callable) -> Button:
	var control := Button.new()
	control.text = value
	control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	control.pressed.connect(callback)
	return control

func panel(parent: Node, border: Color = Color("27374f"), padding: int = 12) -> VBoxContainer:
	var shell := PanelContainer.new()
	shell.add_theme_stylebox_override("panel", box(Color("101827"), border, 8, padding))
	parent.add_child(shell)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	shell.add_child(stack)
	return stack

func rich() -> RichTextLabel:
	var control := RichTextLabel.new()
	control.bbcode_enabled = false
	control.selection_enabled = true
	control.size_flags_vertical = Control.SIZE_EXPAND_FILL
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return control

func _build_ui() -> void:
	background = Art.new()
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var branding := VBoxContainer.new()
	branding.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(branding)
	branding.add_child(text("ASS / CRACKERS", 28, CYAN))
	branding.add_child(text("PROFILE THE PERSON. LET HASHDOG DO THE COMBINING.", 11, MUTED))
	state_label = text("● READY", 16, CYAN)
	header.add_child(state_label)
	var metrics := panel(root, Color("34344f"), 8)
	var metrics_row := HBoxContainer.new()
	metrics.add_child(metrics_row)
	exposure_label = text("EXPOSURE  00 / 100", 14, PINK)
	exposure_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	metrics_row.add_child(exposure_label)
	metrics_row.add_child(text("JOB +10 / EXHAUSTED +5     ", 11, MUTED))
	budget_label = text("POOL  0 / 1956", 14, CYAN)
	metrics_row.add_child(budget_label)
	exposure_bar = ProgressBar.new()
	exposure_bar.show_percentage = false
	exposure_bar.custom_minimum_size.y = 4
	metrics.add_child(exposure_bar)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 14)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(columns)
	var workspace := VBoxContainer.new()
	workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workspace.size_flags_stretch_ratio = 1.65
	workspace.add_theme_constant_override("separation", 10)
	columns.add_child(workspace)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(right)
	_build_workspace(workspace)
	_build_dossier(right)
	_build_footer(root)
	_build_modal()

func _build_workspace(parent: Node) -> void:
	var terminal := panel(parent, Color("2b4e60"), 10)
	var command_row := HBoxContainer.new()
	terminal.add_child(command_row)
	var command := text("$ hashdog run", 17, CYAN)
	command.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	command_row.add_child(command)
	run_button = button("▶ RUN DICTIONARY", _run_dictionary)
	command_row.add_child(run_button)
	log_view = rich()
	log_view.custom_minimum_size.y = 42
	log_view.add_theme_font_size_override("normal_font_size", 14)
	log_view.gui_input.connect(_log_scroll_input)
	log_view.get_v_scroll_bar().gui_input.connect(_log_scroll_input)
	terminal.add_child(log_view)
	forecast_label = text("", 11, MUTED)
	forecast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	terminal.add_child(forecast_label)
	var board := panel(parent, Color("35625f"), 14)
	board.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	var board_header := HBoxContainer.new()
	board.add_child(board_header)
	var title := text("YOUR DICTIONARY", 18, CYAN)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_header.add_child(title)
	special_toggle = CheckButton.new()
	special_toggle.text = "Special characters"
	special_toggle.add_theme_font_size_override("font_size", 12)
	special_toggle.tooltip_text = "5 fragments × 6 rule variants (max 1950): unchanged, suffix !, suffix ?, suffix #, a → @, a → @ plus !. No arbitrary symbol insertion."
	special_toggle.toggled.connect(_toggle_special_characters)
	board_header.add_child(special_toggle)
	slots_label = text("0 / 6", 20, MUTED)
	board_header.add_child(slots_label)
	var instruction := text("Words + numbers → all orders and subsets. Each fragment used at most once.", 12, MUTED)
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	board.add_child(instruction)
	chip_grid = GridContainer.new()
	chip_grid.columns = 3
	chip_grid.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	chip_grid.add_theme_constant_override("h_separation", 10)
	chip_grid.add_theme_constant_override("v_separation", 10)
	board.add_child(chip_grid)
	var repeat_note := text("6 fragments: ≤1956 combinations. Special rules: 5 fragments, ≤1950.", 11, MUTED)
	repeat_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	board.add_child(repeat_note)
	var entry := VBoxContainer.new()
	entry.add_theme_constant_override("separation", 6)
	parent.add_child(entry)
	entry.add_child(text("TYPE A WORD OR NUMBER  /  ENTER TO ADD", 12, GOLD))
	input = LineEdit.new()
	input.custom_minimum_size.y = 58
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.add_theme_font_size_override("font_size", 23)
	input.placeholder_text = "A name, a year, a word…"
	input.text_submitted.connect(_submit_fragment)
	entry.add_child(input)
	feedback = text("Collect meaningful fragments. You don't need to type the finished password.", 12, MUTED)
	feedback.custom_minimum_size.y = 24
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	entry.add_child(feedback)

func _build_dossier(parent: Node) -> void:
	var content := panel(parent, Color("53345c"), 12)
	content.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	var heading := HBoxContainer.new()
	content.add_child(heading)
	var title := text("G-D'S EYE", 22, PINK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	heading.add_child(text("READ ONLY\nDOSSIER 001", 10, MUTED))
	var target := HBoxContainer.new()
	target.add_theme_constant_override("separation", 12)
	content.add_child(target)
	portrait = Art.new()
	portrait.portrait = true
	portrait.custom_minimum_size = Vector2(74, 74)
	target.add_child(portrait)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target.add_child(details)
	details.add_child(text("ALEX / LEXA", 18))
	details.add_child(text("ANUS INDUSTRIES\nHuman Remains Manager", 11, MUTED))
	var avatar_note := text("Avatar replaced by your brain.", 10, PINK)
	avatar_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(avatar_note)
	var brief := text("JOB / Steal the HR layoff order. The clues below explain his password habits.", 13, GOLD)
	brief.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(brief)
	dossier_scroll = ScrollContainer.new()
	dossier_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dossier_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(dossier_scroll)
	dossier = VBoxContainer.new()
	dossier.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dossier.add_theme_constant_override("separation", 10)
	dossier_scroll.add_child(dossier)
	voice = text("", 12, GOLD)
	voice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(voice)

func _populate_dossier() -> void:
	for child in dossier.get_children():
		dossier.remove_child(child)
		child.queue_free()
	fact_markers.clear()
	dossier_scroll.scroll_vertical = 0
	for fact in session.public_mission.facts:
		var card := panel(dossier, Color("293951"), 10)
		var source := text(fact.source, 10, MUTED)
		source.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(source)
		var label := text(fact.label, 12, MUTED)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(label)
		var value := text(fact.value, 16)
		value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(value)
		var note := text(fact.note, 14, INK)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(note)
		var marker := text("◈ CLUE / THE CAT, NOT THE MAN.", 12, PINK)
		marker.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		marker.hide()
		card.add_child(marker)
		fact_markers[fact.id] = marker

func _build_footer(parent: Node) -> void:
	footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	parent.add_child(footer)
	var location := text("PERM-2091 / LOCAL SIM", 11, MUTED)
	location.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(location)
	result_button = button("RESULT", func(): modal.show())
	result_button.hide()
	footer.add_child(result_button)
	tutorial = AcceptDialog.new()
	tutorial.title = "Three steps. No commands to learn."
	tutorial.dialog_text = "1. Read the dossier. Type relevant words and numbers.\n2. Enter saves each fragment as a chip. Use × to remove it.\n3. RUN DICTIONARY tries every order and every nonempty subset.\n\nExample: Neon + 20 + 88 can generate Neon2088.\nEach fragment is used at most once per candidate. Case stays as typed.\n\nSPECIAL CHARACTERS: five slots, six rules per combination:\nplain, add !, add ?, add #, a → @, a → @ plus !.\nNormal: up to 1956 candidates. Special: up to 1950.\n\nChecks run against a captured local SHA-256 hash. GPU is simulated.\nRelay Exposure: +10 per job, +5 if exhausted. At 100, traced."
	add_child(tutorial)
	footer.add_child(button("HOW TO PLAY", func(): tutorial.popup_centered(Vector2i(720, 380))))
	effects_toggle = CheckButton.new()
	effects_toggle.text = "FX"
	effects_toggle.button_pressed = true
	effects_toggle.toggled.connect(_set_effects)
	footer.add_child(effects_toggle)
	var music := CheckButton.new()
	music.text = "SYNTH"
	music.toggled.connect(audio.set_music)
	footer.add_child(music)
	var mute := CheckButton.new()
	mute.text = "MUTE"
	mute.toggled.connect(audio.set_muted)
	footer.add_child(mute)
	var volume := HSlider.new()
	volume.custom_minimum_size.x = 70
	volume.min_value = 0
	volume.max_value = 1
	volume.step = 0.01
	volume.value = 0.35
	volume.tooltip_text = "Master volume"
	volume.value_changed.connect(audio.set_level)
	footer.add_child(volume)

func _set_effects(enabled: bool) -> void:
	effects_enabled = enabled
	background.effects_enabled = enabled
	background.queue_redraw()
	portrait.effects_enabled = enabled
	portrait.queue_redraw()

func _build_modal() -> void:
	modal = PanelContainer.new()
	modal.add_theme_stylebox_override("panel", box(Color("111d30"), PINK, 12, 24))
	add_child(modal)
	modal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	modal.offset_left = -360
	modal.offset_right = 360
	modal.offset_top = -215
	modal.offset_bottom = 215
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 16)
	modal.add_child(stack)
	stack.add_child(text("// CONNECTION CLOSED", 13, MUTED))
	modal_title = text("ACCESS GRANTED", 30, CYAN)
	stack.add_child(modal_title)
	modal_body = rich()
	modal_body.custom_minimum_size = Vector2(620, 230)
	stack.add_child(modal_body)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	stack.add_child(actions)
	var restart_button := button("↻ RESTART MISSION", _restart)
	restart_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(restart_button)
	actions.add_child(button("VIEW DICTIONARY", func(): modal.hide()))
	modal.hide()

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
	elapsed = 0.0
	next_voice = 24.0
	voice_index = 0
	if not loaded.ok:
		modal_title.text = "MISSION DATA ERROR"
		modal_body.text = loaded.message
		modal.show()
		_refresh()
		return
	mission_ready = true
	_populate_dossier()
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
	feedback.add_theme_color_override("font_color", PINK if error else MUTED)

func _refresh() -> void:
	if not is_instance_valid(exposure_label):
		return
	var model = session.engine
	var can_edit: bool = mission_ready and model.phase == "READY"
	var danger: Color = CYAN if model.exposure < 40 else (GOLD if model.exposure < 70 else PINK)
	exposure_label.text = "EXPOSURE  %02d / 100" % model.exposure
	exposure_label.add_theme_color_override("font_color", danger)
	exposure_bar.value = model.exposure
	exposure_bar.add_theme_stylebox_override("fill", box(danger, danger, 3, 0))
	budget_label.text = "CHECKED %d / %d" % [model.index, model.queue.size()] if model.phase in ["RUNNING", "WON"] else "POOL %d / 1956" % session.candidates.size()
	state_label.text = "● " + model.phase
	state_label.add_theme_color_override("font_color", PINK if model.phase == "LOST" else CYAN)
	input.editable = can_edit
	special_toggle.disabled = not can_edit
	special_toggle.set_pressed_no_signal(session.dictionary.special_characters)
	run_button.disabled = not can_edit or session.dictionary.words.is_empty()
	run_button.text = "TESTING %d / %d" % [model.index, model.queue.size()] if model.phase == "RUNNING" else "▶ RUN DICTIONARY"
	slots_label.text = "%d / %d" % [session.dictionary.words.size(), session.dictionary.capacity()]
	if can_edit:
		forecast_label.text = "%d unique candidates · %s · offline SHA-256" % [session.candidates.size(), "6 special rule variants" if session.dictionary.special_characters else "all fragment orders"]
		if model.exposure >= 90:
			forecast_label.text = "TRACE WARNING: starting another job reaches 100 Exposure."
	elif model.phase == "RUNNING":
		forecast_label.text = "GPU SIM · %d / %d checked · terminal shows batch samples" % [model.index, model.queue.size()]
	else:
		forecast_label.text = "Session closed. Restart to try again."
	_refresh_chips()

func _refresh_chips() -> void:
	for child in chip_grid.get_children():
		chip_grid.remove_child(child)
		child.queue_free()
	chip_labels.clear()
	remove_buttons.clear()
	var words: Array = session.dictionary.words
	for i in 6:
		var occupied := i < words.size()
		var word: String = words[i] if occupied else ""
		var reserved: bool = session.dictionary.special_characters and i == 5
		var status := "FRAGMENT" if occupied else ("RULE SLOT" if reserved else "EMPTY SLOT")
		var accent := CYAN if occupied else Color("293951")
		if occupied and not session.engine.match_record.is_empty() and word in session.engine.match_record.sources:
			status = "USED IN MATCH"
		if occupied and session.engine.phase == "RUNNING":
			status = "IN POOL"
			accent = GOLD
		if reserved:
			accent = GOLD
		var card := panel(chip_grid, accent, 8)
		card.get_parent().add_theme_stylebox_override("panel", box(Color("142a35") if occupied else Color("101827"), accent, 16, 8))
		card.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
		card.get_parent().custom_minimum_size.y = 72
		card.add_child(text("%02d / %s" % [i + 1, status], 10, accent if occupied else MUTED))
		var row := HBoxContainer.new()
		row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card.add_child(row)
		var label := text(word if occupied else ("! ? # @" if reserved else "—"), 21, INK if occupied else MUTED)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.clip_text = true
		label.tooltip_text = word
		row.add_child(label)
		chip_labels.append(label)
		if occupied:
			var remove := button("×", _remove_fragment.bind(word))
			remove.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			remove.add_theme_stylebox_override("normal", box(Color("142638"), Color("2c5664"), 6, 6))
			remove.add_theme_stylebox_override("hover", box(Color("1d3d4c"), CYAN, 6, 6))
			remove.add_theme_stylebox_override("pressed", box(Color("244158"), PINK, 6, 6))
			remove.add_theme_stylebox_override("disabled", box(Color("111b2a"), Color("263348"), 6, 6))
			remove.add_theme_stylebox_override("focus", box(Color(0, 0, 0, 0), GOLD, 6, 6))
			remove.tooltip_text = "Remove " + word
			remove.disabled = session.engine.phase != "READY"
			row.add_child(remove)
			remove_buttons.append(remove)

func _log(value: String, kind: String = "info") -> void:
	var scrollbar := log_view.get_v_scroll_bar()
	var follow := _follow_pending or scrollbar.value >= scrollbar.max_value - scrollbar.page - 6
	var previous := scrollbar.value
	var color: Color = {"success": CYAN, "command": Color.WHITE, "error": PINK, "voice": PINK, "warning": GOLD, "attempt": GOLD, "system": MUTED}.get(kind, INK)
	for line in value.split("\n"):
		log_lines.append({"text": line, "color": color})
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
		if effects_enabled:
			marker.modulate = Color(2.0, 0.6, 1.6)
			create_tween().tween_property(marker, "modulate", Color.WHITE, 0.5)
	voice.text = "“MEOW. His current cat. His birth year.\nSame old pattern.” — Barsik, allegedly"
	_log("[HALLUCINATION] Start with his current cat: Barsik.", "voice")
	audio.play("hint")

func _on_end(result: String) -> void:
	tutorial.hide()
	var titles := {"SUCCESS": "ACCESS GRANTED", "TRACE": "TRACE DETECTED"}
	modal_title.text = titles[result]
	modal_title.add_theme_color_override("font_color", CYAN if result == "SUCCESS" else PINK)
	var detail := ""
	if result == "SUCCESS":
		var solved: Dictionary = session.victory_details()
		detail = "Password: %s\n\n%s\n\nLayoff order retrieved. The department lives another day.\nBarsik wants a promotion to Chief Scratching Officer." % [solved.password, solved.explanation]
		detail += "\n\nFragments: %s · Rule: %s" % [" + ".join(session.engine.match_record.sources), session.engine.match_record.rule]
	else:
		detail = "Your rented compute relay was traced after repeated jobs.\nThe local hash checks did not send login requests."
		detail += "\n\n“Don't worry. The report will call you an unknown idiot.”\n— a voice from the air vent\n\nRead the clues again and try a different set of fragments."
	modal_body.text = detail + "\n\nHashes checked: %d · Jobs: %d · Exposure: %d/100" % [session.engine.attempts_used, session.engine.runs_used, session.engine.exposure]
	modal.show()
	result_button.show()
	_set_feedback("Session closed. Restart the mission to try again.")
	audio.play("success" if result == "SUCCESS" else "fail")
	_log(titles[result], "success" if result == "SUCCESS" else "error")

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= next_voice and is_instance_valid(session) and session.engine.phase in ["READY", "RUNNING"]:
		next_voice += 32.0
		var voices := ["“I'm not a cat. I'm your burnout interface.” — ?", "“They updated the password policy. Not the people.” — ?", "“Your request matters to us. Especially the last one.” — ?"]
		if not session.hint_shown:
			voice.text = voices[voice_index % voices.size()]
		voice_index += 1
