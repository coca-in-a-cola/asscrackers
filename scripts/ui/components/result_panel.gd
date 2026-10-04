@tool
extends "res://scripts/ui/components/dialog.gd"

func show_mark(mark: String, exposure: float) -> void:
	%ScoreRow.visible = not mark.is_empty()
	%Mark.text = "MARK " + mark
	%Exposure.text = "FINAL EXPOSURE\n%.2f / 100" % exposure

func configure_action(caption: String, submitted := false) -> void:
	%Primary.text = caption
	%Primary.disabled = submitted
	%Secondary.hide()
	closable = false
