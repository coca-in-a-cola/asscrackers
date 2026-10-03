extends PanelContainer

signal help_requested
signal result_requested
signal effects_changed(enabled: bool)
signal music_changed(enabled: bool)
signal mute_changed(enabled: bool)
signal volume_changed(value: float)

@onready var footer: HBoxContainer = %Row
@onready var result_button: Button = %Result
@onready var effects_toggle: CheckBox = %Effects
@onready var state_label: Label = %State
@onready var location_label: Label = %Location

func _on_help() -> void:
	help_requested.emit()
func _on_result() -> void:
	result_requested.emit()
func _on_effects(enabled: bool) -> void:
	effects_changed.emit(enabled)
func _on_music(enabled: bool) -> void:
	music_changed.emit(enabled)
func _on_mute(enabled: bool) -> void:
	mute_changed.emit(enabled)
func _on_volume(value: float) -> void:
	volume_changed.emit(value)
