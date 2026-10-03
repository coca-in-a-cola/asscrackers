@tool
extends "res://scripts/ui/components/window.gd"

@export var fact_scene: PackedScene
@onready var dossier: VBoxContainer = %Facts
@onready var dossier_scroll: ScrollContainer = %Scroll
@onready var voice: Label = %Voice
var fact_markers: Dictionary = {}

func apply_mission(mission: Dictionary) -> void:
	%Target.text = mission.get("display_name", "Unknown target")
	%Brief.text = mission.get("brief", "")
	for child in dossier.get_children():
		dossier.remove_child(child)
		child.queue_free()
	fact_markers.clear()
	dossier_scroll.scroll_vertical = 0
	for fact in mission.get("facts", []):
		var card := fact_scene.instantiate()
		dossier.add_child(card)
		card.apply(fact)
		fact_markers[fact.id] = card.marker()
