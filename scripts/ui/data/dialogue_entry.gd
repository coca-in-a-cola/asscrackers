class_name DialogueEntry
extends Resource

@export var id: StringName
@export var dialogue: DialogueResource
@export var start_cue := "start"
@export var characters: Array[DialogueCharacter] = []
@export var presentation: DialoguePresentation
@export var entry_music: StringName
@export var exit_music: StringName
@export var presentation_cues: Dictionary[String, StringName] = {}

func valid() -> bool:
	if dialogue == null or dialogue.lines.is_empty() or not dialogue.cues.has(start_cue) or presentation == null or presentation.theme == null or characters.is_empty():
		return false
	var ids: Dictionary = {}
	var slots: Dictionary = {}
	for character in characters:
		if character == null or not character.valid() or ids.has(character.id) or slots.has(character.slot):
			return false
		ids[character.id] = true
		slots[character.slot] = true
	for name in dialogue.character_names:
		if not name.is_empty() and not name.begins_with("{{") and not ids.has(StringName(name)):
			return false
	return true

func character_for(id_value: String) -> DialogueCharacter:
	for character in characters:
		if character.id == StringName(id_value):
			return character
	return null
