@tool
extends "res://scripts/ui/components/window.gd"

signal query_requested(id: String)
signal presentation_ready
@export var preferred_size := Vector2(340, 300)
var fact_id := ""
var _layout_ticket := 0
var _preparing := false
@onready var body: RichTextLabel = %InfoBody
@onready var query_button: Button = %Query
@onready var status: Label = %InfoStatus

func _ready() -> void:
	super._ready()
	close_requested.connect(hide)
	query_button.pressed.connect(func():
		if not _preparing:
			query_requested.emit(fact_id)
	)
	visibility_changed.connect(_on_visibility_changed)

func present(fact: Dictionary, exposure: float, can_query: bool) -> void:
	if visible:
		apply(fact, exposure, can_query)
		if not _preparing:
			_fit_content()
			presentation_ready.emit()
		return
	_layout_ticket += 1
	var ticket := _layout_ticket
	_preparing = true
	# Hidden Containers have stale text minimums. Reflow before the first draw.
	modulate.a = 0.0
	size = preferred_size
	apply(fact, exposure, can_query)
	show()
	for _frame in 4:
		await get_tree().process_frame
		if ticket != _layout_ticket or not visible:
			return
	_fit_content()
	_preparing = false
	presentation_ready.emit()
	modulate.a = 1.0

func _fit_content() -> void:
	size = Vector2(preferred_size.x, maxf(preferred_size.y, get_combined_minimum_size().y))

func _on_visibility_changed() -> void:
	if not visible:
		_layout_ticket += 1
		_preparing = false
		modulate.a = 1.0

func apply(fact: Dictionary, exposure: float, can_query: bool) -> void:
	fact_id = fact.id
	title = "G-D's Eye / " + fact.label
	%InfoTitle.text = fact.source
	query_button.visible = not fact.revealed
	query_button.disabled = not can_query
	query_button.text = "Query source / +%d EXP" % fact.cost
	if fact.revealed:
		var text: String = fact.value + "\n\n" + fact.note
		if body.text != text:
			body.text = text
		status.text = "RETRIEVED / read again for free"
	else:
		var text := "Source located. Request its information to investigate this branch.\n\nNew leads may appear after retrieval."
		if body.text != text:
			body.text = text
		status.text = "Exposure %.1f → %.1f / 100" % [exposure, minf(100, exposure + fact.cost)]
		if exposure + fact.cost >= 100:
			status.text = "TRACE WARNING: this query reaches 100."
