extends PanelContainer

signal help_requested
signal result_requested
signal application_requested(application_name: StringName)
signal stop_requested
signal effects_changed(enabled: bool)
signal music_changed(enabled: bool)
signal mute_changed(enabled: bool)
signal volume_changed(value: float)

@onready var footer: VBoxContainer = %Row
@onready var result_button: Button = %Result
@onready var effects_toggle: CheckBox = %Effects
@onready var music_toggle: CheckBox = %Music
@onready var mute_toggle: CheckBox = %Mute
@onready var volume_slider: HSlider = %Volume
@onready var state_label: Label = %State
@onready var location_label: Label = %Location
@onready var exposure_label: Label = %GlobalExposure
@onready var exposure_bar: ProgressBar = %GlobalBar
@onready var remaining_label: Label = %Remaining
@onready var stop_button: Button = %StopJob
var application_buttons: Dictionary = {}

func _ready() -> void:
	for button in %AppButtons.get_children():
		var id := StringName(button.name)
		application_buttons[id] = button
		button.pressed.connect(func(): application_requested.emit(id))
	stop_button.pressed.connect(func(): stop_requested.emit())

func update_windows(manager: Control) -> void:
	for id in application_buttons:
		var button: Button = application_buttons[id]
		var window: Control = manager.application(id)
		button.set_pressed_no_signal(window.visible and manager.active_application == id)
		button.text = ("• " if window.visible else "") + ("Eye" if id == &"Dossier" else str(id))

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
