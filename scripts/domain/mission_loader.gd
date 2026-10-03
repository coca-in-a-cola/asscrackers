extends RefCounted

const WordList = preload("res://scripts/domain/dictionary_service.gd")
const Services = preload("res://scripts/domain/service_catalog.gd")

static func load_mission(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return fail(path, "File not found.")
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return fail(path, "JSON line %d: %s" % [parser.get_error_line(), parser.get_error_message()])
	var validation := validate(parser.data)
	if not validation.ok:
		return fail(path, validation.message)
	var service := Services.load_service(parser.data.service_id)
	if not service.ok:
		return service
	return {"ok": true, "mission": parser.data, "service": service.service}

static func validate(data: Variant) -> Dictionary:
	if not data is Dictionary or data.get("schema_version") != 3:
		return fail("", "Expected mission schema_version 3.")
	for key in ["id", "display_name", "brief", "login", "service_id"]:
		if not nonempty(data.get(key)):
			return fail("", "Required text field: " + key)
	if not data.get("facts") is Array or data.facts.is_empty() or not data.get("solution") is Dictionary:
		return fail("", "Expected facts and solution.")
	var ids: Dictionary = {}
	for fact in data.facts:
		if not fact is Dictionary or not nonempty(fact.get("id")) or ids.has(fact.id):
			return fail("", "Invalid or duplicate fact ID.")
		ids[fact.id] = fact
		for key in ["label", "value", "source", "note"]:
			if not fact.get(key) is String or (key != "note" and not nonempty(fact[key])):
				return fail("", "Expected fact text: " + key)
		var cost: Variant = fact.get("cost")
		if not (cost is float or cost is int) or not is_finite(float(cost)) or float(cost) != floor(float(cost)) or cost <= 0 or cost >= 100:
			return fail("", "Expected an integer recon cost between 1 and 99.")
		if not fact.get("requires") is Array or not fact.get("position") is Array or fact.position.size() != 2:
			return fail("", "Expected graph dependencies and position.")
		for coordinate in fact.position:
			if not (coordinate is float or coordinate is int) or not is_finite(float(coordinate)) or coordinate < 0 or coordinate > 1200:
				return fail("", "Invalid graph coordinate.")
	for fact in data.facts:
		var seen: Array = []
		for dependency in fact.requires:
			if not dependency is String or not ids.has(dependency) or seen.has(dependency):
				return fail("", "Invalid graph dependency.")
			seen.append(dependency)
	var visited: Dictionary = {}
	var visiting: Dictionary = {}
	for id in ids:
		if _has_cycle(id, ids, visiting, visited):
			return fail("", "Recon graph contains a cycle.")
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
	return {"ok": true}

static func _has_cycle(id: String, ids: Dictionary, visiting: Dictionary, visited: Dictionary) -> bool:
	if visiting.has(id):
		return true
	if visited.has(id):
		return false
	visiting[id] = true
	for dependency in ids[id].requires:
		if _has_cycle(dependency, ids, visiting, visited):
			return true
	visiting.erase(id)
	visited[id] = true
	return false

static func nonempty(value: Variant) -> bool:
	return value is String and not value.strip_edges().is_empty()

static func fail(path: String, message: String) -> Dictionary:
	return {"ok": false, "message": "%s: %s" % [path, message]}
