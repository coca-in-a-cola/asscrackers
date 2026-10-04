extends Control

signal return_requested
const Budget = preload("res://scripts/domain/exposure_budget.gd")
@onready var return_button: Button = %Return

func _ready() -> void:
	return_button.pressed.connect(func(): return_requested.emit())
	hide()

func present(state: CampaignState) -> void:
	%Title.text = state.definition.title
	%Mark.text = "FINAL MARK " + state.final_mark()
	%Average.text = "AVERAGE EXPOSURE  %.2f / 100" % state.average_exposure()
	for child in %Rows.get_children():
		%Rows.remove_child(child)
		child.queue_free()
	var total_requests := 0
	var total_jobs := 0
	for caption in ["TARGET", "EXPOSURE", "MARK", "REQUESTS"]:
		_add_cell(caption, true)
	for result in state.results:
		_add_cell(result.title)
		_add_cell("%.2f" % (float(result.exposure_units) / Budget.SCALE))
		_add_cell(result.mark, true)
		_add_cell(str(result.requests))
		total_requests += result.requests
		total_jobs += result.jobs
	%Totals.text = "%d / %d targets submitted   ·   %d requests   ·   %d jobs" % [state.results.size(), state.definition.goals.size(), total_requests, total_jobs]
	show()
	return_button.grab_focus()

func _add_cell(text: String, emphasis := false) -> void:
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 18)
	if emphasis:
		label.theme_type_variation = &"TitleText"
		label.add_theme_color_override("font_color", get_theme_color("accent", "Palette"))
	%Rows.add_child(label)

func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.echo:
		get_viewport().set_input_as_handled()

func _unhandled_input(_event: InputEvent) -> void:
	if visible:
		get_viewport().set_input_as_handled()
