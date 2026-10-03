@tool
extends "res://scripts/ui/components/window.gd"

@onready var log_view: RichTextLabel = %Log
@onready var run_button: Button = %Run
@onready var forecast_label: Label = %Forecast.text_label
@onready var exposure_label: Label = %Exposure
@onready var exposure_bar: ProgressBar = %ExposureBar
@onready var budget_label: Label = %Budget
@onready var target_label: Label = %TargetLabel
@onready var stop_button: Button = %Stop
