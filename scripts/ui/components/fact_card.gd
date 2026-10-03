@tool
extends PanelContainer

@export var preview_fact: Dictionary = {"source": "SOURCE / archive", "label": "Record", "value": "Evidence", "note": "Read this record to infer a fragment."}

func _ready() -> void:
	apply(preview_fact)

func apply(fact: Dictionary) -> void:
	%Source.text = fact.get("source", "")
	%Heading.text = fact.get("label", "")
	%Value.text = fact.get("value", "")
	%Note.text = fact.get("note", "")
	%Marker.hide()

func marker() -> Label:
	return %Marker
