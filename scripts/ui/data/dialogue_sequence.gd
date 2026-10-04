class_name DialogueSequence
extends Resource

@export var player_portrait: Texture2D
@export var curator_portrait: Texture2D
@export var player_name := "YOU / TRAINEE"
@export var curator_name := "CURATOR / ID REDACTED"
@export var desktop_reveal_after := 4
@export var lines: Array[Dictionary] = []

func valid() -> bool:
	if player_portrait == null or curator_portrait == null or lines.is_empty() or desktop_reveal_after < 0 or desktop_reveal_after >= lines.size():
		return false
	for line in lines:
		if line.get("speaker", "") not in ["player", "curator"] or typeof(line.get("text")) != TYPE_STRING or line.text.is_empty():
			return false
	return true
