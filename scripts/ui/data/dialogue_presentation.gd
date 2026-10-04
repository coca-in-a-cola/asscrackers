class_name DialoguePresentation
extends Resource

@export var theme: Theme
@export_range(0.5, 0.95) var width_fraction := 0.80
@export var maximum_width := 1320.0
@export_range(0.2, 0.5) var portrait_height_fraction := 0.34
@export var maximum_portrait_height := 320.0
@export_range(0.0, 0.5) var connection_rise_fraction := 0.25
@export var panel_height := 176.0
@export var bottom_clearance := 104.0
@export var column_gap := 32
@export var row_gap := 18
@export_range(10.0, 100.0) var characters_per_second := 38.0
@export_range(0.0, 1.0) var punctuation_pause := 0.10
@export_range(0.1, 1.0) var fast_hold_delay := 0.3
@export_range(2.0, 20.0) var fast_multiplier := 8.0
@export_range(0.05, 1.0) var fast_advance_interval := 0.12
@export var enter_animation: StringName = &"enter"
@export var exit_animation: StringName = &"exit"
