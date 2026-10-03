@tool
extends "res://scripts/ui/components/window.gd"

signal query_requested(id: String)
var fact_id := ""
@onready var body: RichTextLabel = %InfoBody
@onready var query_button: Button = %Query
@onready var status: Label = %InfoStatus

func _ready() -> void:
	super._ready()
	close_requested.connect(hide)
	query_button.pressed.connect(func(): query_requested.emit(fact_id))

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
