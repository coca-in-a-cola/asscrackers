extends Control

@export_node_path("Control") var dialog_path: NodePath

func _on_visibility_changed() -> void:
	if not is_node_ready() or not visible:
		return
	var controls := _focusable_controls()
	for index in controls.size():
		var control := controls[index]
		var next := control.get_path_to(controls[(index + 1) % controls.size()])
		var previous := control.get_path_to(controls[posmod(index - 1, controls.size())])
		control.focus_next = next
		control.focus_previous = previous
		control.focus_neighbor_right = next
		control.focus_neighbor_bottom = next
		control.focus_neighbor_left = previous
		control.focus_neighbor_top = previous

func _focusable_controls() -> Array[Control]:
	var controls: Array[Control] = []
	if dialog_path.is_empty():
		return controls
	var dialog := get_node_or_null(dialog_path)
	if dialog == null:
		return controls
	for control in dialog.find_children("*", "Control", true, false):
		if control.is_visible_in_tree() and control.focus_mode == Control.FOCUS_ALL:
			if control is BaseButton and control.disabled:
				continue
			controls.append(control)
	return controls

func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed or event.keycode != KEY_TAB:
		return
	var controls := _focusable_controls()
	if not controls.is_empty():
		var index := controls.find(get_viewport().gui_get_focus_owner())
		var direction := -1 if event.shift_pressed else 1
		controls[posmod(index + direction, controls.size())].grab_focus()
	get_viewport().set_input_as_handled()
