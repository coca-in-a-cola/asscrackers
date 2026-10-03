@tool
extends "res://scripts/ui/components/window.gd"

@onready var portrait: TextureRect = %Portrait

@export var profile: OperatorProfile:
	set(value):
		profile = value
		if is_node_ready():
			_apply_profile()

func _ready() -> void:
	super._ready()
	_apply_profile()

func _apply_profile() -> void:
	if profile == null:
		return
	title = "Self-portrait — " + profile.filename
	%Portrait.texture = profile.portrait
	%Operator.text = profile.display_name
	%Description.text = profile.description
