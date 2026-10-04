class_name CampaignGoal
extends Resource

@export var id: StringName
@export var title: String
@export_file("*.json") var mission_file: String
@export_multiline var success_text: String
@export var before_dialogue: DialogueEntry
@export var after_dialogue: DialogueEntry

func valid() -> bool:
	return not id.is_empty() and not title.is_empty() and not success_text.is_empty() and mission_file.begins_with("res://") and mission_file.ends_with(".json") and FileAccess.file_exists(mission_file) and before_dialogue != null and before_dialogue.valid() and after_dialogue != null and after_dialogue.valid()
