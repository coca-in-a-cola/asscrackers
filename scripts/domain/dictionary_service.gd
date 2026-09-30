extends RefCounted

const Generator = preload("res://scripts/domain/candidate_generator.gd")
const MAX_LENGTH := 64
var words: Array[String] = []
var special_characters := false

func clear() -> void:
	words.clear()
	special_characters = false

func capacity() -> int:
	return Generator.capacity(special_characters)

func set_special_characters(enabled: bool) -> Dictionary:
	if words.size() > Generator.capacity(enabled):
		return {"ok": false, "message": "Special characters need one slot. Remove a fragment first; nothing was deleted."}
	special_characters = enabled
	return {"ok": true, "message": "Special rules ON: 5 fragments, up to 1950 candidates." if enabled else "Special rules OFF: 6 fragments, up to 1956 candidates."}

static func valid_word(value: Variant) -> bool:
	return value is String and not value.strip_edges().is_empty() and value.length() <= MAX_LENGTH and not value.contains("\n") and not value.contains("\r") and not value.contains("\t")

func add_word(raw_word: String) -> Dictionary:
	var word := raw_word.strip_edges()
	if not valid_word(word):
		return {"ok": false, "message": "Use 1–64 characters on a single line."}
	if words.has(word):
		return {"ok": true, "added": false, "message": "That fragment is already in your dictionary."}
	if words.size() >= capacity():
		return {"ok": false, "message": "All %d slots are full. Remove a chip with × to make room." % capacity()}
	words.append(word)
	return {"ok": true, "added": true, "message": "Fragment saved. Hashdog will combine the words and numbers for you."}

func remove_word(word: String) -> Dictionary:
	if not words.has(word):
		return {"ok": false, "message": "That fragment is no longer in the dictionary."}
	words.erase(word)
	return {"ok": true, "message": "Fragment removed. Combinations recalculated."}

func snapshot() -> Array:
	return words.duplicate()
