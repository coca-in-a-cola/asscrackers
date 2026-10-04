extends RefCounted
## Linear conversation state, independent of portrait/text presentation.

signal line_changed(line: Dictionary, index: int)
signal desktop_requested
signal finished

var sequence: DialogueSequence
var index := -1
var waiting_for_desktop := false
var complete := false

func start(data: DialogueSequence) -> void:
	sequence = data
	index = -1
	waiting_for_desktop = false
	complete = false
	advance()

func advance() -> void:
	if complete or waiting_for_desktop or sequence == null:
		return
	index += 1
	if index >= sequence.lines.size():
		complete = true
		finished.emit()
	elif index == sequence.desktop_reveal_after:
		waiting_for_desktop = true
		desktop_requested.emit()
	else:
		line_changed.emit(sequence.lines[index], index)

func resume_after_desktop() -> void:
	if not waiting_for_desktop:
		return
	waiting_for_desktop = false
	line_changed.emit(sequence.lines[index], index)
