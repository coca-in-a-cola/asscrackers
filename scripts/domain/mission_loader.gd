extends RefCounted

const WordList = preload("res://scripts/domain/dictionary_service.gd")

static func load_mission(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return fail(path, "File not found.")
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return fail(path, "JSON line %d: %s" % [parser.get_error_line(), parser.get_error_message()])
	var validation := validate(parser.data)
	if not validation.ok:
		return fail(path, validation.message)
	return {"ok": true, "mission": parser.data}

static func validate(data: Variant) -> Dictionary:
	if not data is Dictionary:
		return fail("", "Expected a mission object.")
	if data.get("schema_version") != 2:
		return fail("", "Unsupported schema_version.")
	for key in ["id", "display_name", "brief"]:
		if not nonempty(data.get(key)):
			return fail("", "Required text field: " + key)
	if not data.get("facts") is Array or data.facts.is_empty() or not data.get("solution") is Dictionary:
		return fail("", "Expected facts and solution.")
	var ids: Array = []
	for fact in data.facts:
		if not fact is Dictionary or not nonempty(fact.get("id")) or ids.has(fact.id):
			return fail("", "Invalid or duplicate fact ID.")
		ids.append(fact.id)
		for key in ["label", "value", "source", "note"]:
			if not fact.get(key) is String:
				return fail("", "Expected fact text: " + key)
		if fact.label.is_empty() or fact.value.is_empty():
			return fail("", "Fact label and value cannot be empty.")
	var solution: Dictionary = data.solution
	if not WordList.valid_word(solution.get("password")) or not nonempty(solution.get("explanation")):
		return fail("", "Invalid password or explanation.")
	if not solution.get("fact_ids") is Array or solution.fact_ids.is_empty():
		return fail("", "Expected solution fact_ids.")
	var used: Array = []
	for id in solution.fact_ids:
		if not id is String or not ids.has(id) or used.has(id):
			return fail("", "Invalid solution fact reference.")
		used.append(id)
	if not solution.get("hint_fact_id") is String or not used.has(solution.hint_fact_id):
		return fail("", "Invalid hint_fact_id.")
	return {"ok": true}

static func nonempty(value: Variant) -> bool:
	return value is String and not value.strip_edges().is_empty()

static func fail(path: String, message: String) -> Dictionary:
	return {"ok": false, "message": "%s: %s" % [path, message]}
