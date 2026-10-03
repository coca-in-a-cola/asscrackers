@tool
extends PanelContainer

signal close_requested
signal activation_requested

@export var title := "Untitled":
	set(value):
		title = value
		if is_node_ready():
			%Titlebar.title = title
@export var window_icon: Texture2D:
	set(value):
		window_icon = value
		if is_node_ready():
			%Titlebar.window_icon = window_icon
@export var closable := false:
	set(value):
		closable = value
		if is_node_ready():
			%Titlebar.closable = closable
@export var active := false:
	set(value):
		active = value
		if is_node_ready():
			%Titlebar.active = active

func _ready() -> void:
	%Titlebar.title = title
	%Titlebar.window_icon = window_icon
	%Titlebar.closable = closable
	%Titlebar.active = active
	%Titlebar.activation_requested.connect(_on_activation_requested)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_activation_requested()

func _on_activation_requested() -> void:
	activation_requested.emit()

func _on_close_requested() -> void:
	close_requested.emit()
