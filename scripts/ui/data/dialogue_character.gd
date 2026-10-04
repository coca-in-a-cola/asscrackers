class_name DialogueCharacter
extends Resource

enum Slot { LEFT, RIGHT }
@export var id: StringName
@export var display_name: String
@export var slot: Slot = Slot.LEFT
@export var expressions: Dictionary[String, Texture2D] = {}
@export var reveal_on_first_line := false
@export var first_line_animation: StringName

func portrait(expression: String = "neutral") -> Texture2D:
	return expressions.get(expression, expressions.get("neutral"))

func valid() -> bool:
	return not id.is_empty() and not display_name.is_empty() and portrait() != null and (not reveal_on_first_line or not first_line_animation.is_empty())
