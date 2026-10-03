@tool
extends "res://scripts/ui/components/window.gd"

signal node_selected(id: String)
signal graph_moved

@onready var dossier: Control = %Graph
@onready var dossier_scroll: ScrollContainer = %Scroll
@onready var voice: Label = %Voice

func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		dossier.node_selected.connect(func(id: String): node_selected.emit(id))
		dossier_scroll.get_h_scroll_bar().value_changed.connect(func(_value: float): graph_moved.emit())
		dossier_scroll.get_v_scroll_bar().value_changed.connect(func(_value: float): graph_moved.emit())

func apply_mission(mission: Dictionary) -> void:
	%Target.text = mission.display_name + " / " + mission.login
	dossier.apply_target(mission.display_name)
	dossier_scroll.scroll_horizontal = 0
	dossier_scroll.scroll_vertical = 0

func apply_snapshot(snapshot: Array) -> void:
	dossier.apply_snapshot(snapshot)
	var retrieved := 0
	for fact in snapshot:
		if fact.revealed:
			retrieved += 1
	%Statusbar.text = "%d sources visible / %d retrieved / scroll to explore" % [snapshot.size(), retrieved]
