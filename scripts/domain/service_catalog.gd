extends RefCounted

const PATH := "res://data/services/services.json"

static func load_service(id: String) -> Dictionary:
	var parser := JSON.new()
	if not FileAccess.file_exists(PATH) or parser.parse(FileAccess.get_file_as_string(PATH)) != OK:
		return {"ok": false, "message": "Cannot load service catalog."}
	if not parser.data is Dictionary or not parser.data.get(id) is Dictionary:
		return {"ok": false, "message": "Unknown target service: " + id}
	var service: Dictionary = parser.data[id]
	var coefficient: Variant = service.get("time_coefficient")
	if not service.get("display_name") is String or service.display_name.strip_edges().is_empty() or not (coefficient is float or coefficient is int) or not is_finite(float(coefficient)) or float(coefficient) <= 0.0:
		return {"ok": false, "message": "Invalid target service: " + id}
	var copy := service.duplicate(true)
	copy["id"] = id
	return {"ok": true, "service": copy}
