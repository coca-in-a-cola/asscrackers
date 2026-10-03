extends Node

signal changed
signal intel_changed
signal message(text: String, kind: String)
signal ended(result: String)

const WordList = preload("res://scripts/domain/dictionary_service.gd")
const EngineModel = preload("res://scripts/domain/attack_engine.gd")
const Loader = preload("res://scripts/domain/mission_loader.gd")
const Generator = preload("res://scripts/domain/candidate_generator.gd")
const Budget = preload("res://scripts/domain/exposure_budget.gd")
const Intel = preload("res://scripts/domain/intel_service.gd")
const MISSION_PATH := "res://data/targets/target_001.json"

var dictionary = WordList.new()
var budget = Budget.new()
var engine = EngineModel.new(budget)
var intel = Intel.new([], budget)
var public_mission: Dictionary = {}
var service: Dictionary = {}
var _solution: Dictionary = {}
var _target_hash := ""
var candidates: Array = []
var generation := 0
var _announced := false
var _sample_elapsed := 0.0
# Tests drive advance() directly. Runtime clock never depends on window visibility.
var automatic_clock := true

func _process(delta: float) -> void:
	if automatic_clock and engine.phase == "RUNNING":
		advance(generation, delta)

func restart() -> Dictionary:
	generation += 1
	dictionary.clear()
	budget = Budget.new()
	engine = EngineModel.new(budget)
	intel = Intel.new([], budget)
	_announced = false
	_sample_elapsed = 0.0
	public_mission = {}
	service = {}
	_solution = {}
	_target_hash = ""
	candidates = []
	var response := Loader.load_mission(MISSION_PATH)
	if not response.ok:
		return response
	var mission: Dictionary = response.mission
	public_mission = {"id": mission.id, "display_name": mission.display_name, "brief": mission.brief, "login": mission.login, "service_id": mission.service_id}
	_solution = mission.solution.duplicate(true)
	_target_hash = _solution.password.sha256_text()
	service = response.service.duplicate(true)
	intel = Intel.new(mission.facts, budget)
	intel_changed.emit()
	changed.emit()
	return {"ok": true}

func recon_snapshot() -> Array:
	return intel.snapshot()

func request_intel(id: String) -> Dictionary:
	if engine.phase in ["WON", "LOST"] or _solution.is_empty():
		return {"ok": false, "message": "Mission connection is closed."}
	var response: Dictionary = intel.purchase(id)
	message.emit(response.message, "system" if response.ok else "error")
	if response.get("purchased", false):
		intel_changed.emit()
	_check_events()
	return response

func _editable() -> bool:
	return engine.phase == "READY" and not _solution.is_empty()

func add_fragment(value: String) -> Dictionary:
	if not _editable():
		return {"ok": false, "message": "Stop the botnet or wait for this run to finish."}
	var response: Dictionary = dictionary.add_word(value)
	if response.ok:
		_rebuild_candidates()
		changed.emit()
	return response

func remove_fragment(value: String) -> Dictionary:
	if not _editable():
		return {"ok": false, "message": "Stop the botnet or wait for this run to finish."}
	var response: Dictionary = dictionary.remove_word(value)
	if response.ok:
		_rebuild_candidates()
		changed.emit()
	return response

func set_special_characters(enabled: bool) -> Dictionary:
	if not _editable():
		return {"ok": false, "message": "Rules are locked while the botnet is running."}
	var response: Dictionary = dictionary.set_special_characters(enabled)
	if response.ok:
		_rebuild_candidates()
		changed.emit()
	return response

func _rebuild_candidates() -> void:
	var generated := Generator.generate(dictionary.snapshot(), dictionary.special_characters)
	candidates = generated.get("candidates", [])

func forecast() -> Dictionary:
	return EngineModel.forecast(candidates.size(), float(service.get("time_coefficient", 1.0)))

func start_attack() -> Dictionary:
	if _solution.is_empty():
		return {"ok": false, "message": "Mission data is unavailable."}
	var response: Dictionary = engine.start(candidates, float(service.time_coefficient))
	if response.ok:
		_sample_elapsed = 0.0
		_check_events()
	return response

func stop_attack() -> void:
	if engine.stop():
		message.emit("STOPPED: %d requests sent. Unsent candidates cost no Exposure." % engine.index, "system")
		changed.emit()

func advance(expected_generation: int, delta: float) -> void:
	if expected_generation != generation:
		return
	var batch: Dictionary = engine.advance(delta, _target_hash)
	if batch.checked > 0:
		_sample_elapsed += delta
		if _sample_elapsed >= 0.5 or engine.phase != "RUNNING":
			_sample_elapsed = 0.0
			var record: Dictionary = batch.last
			message.emit("[%04d/%04d] %s / %s → %s" % [engine.index, engine.queue.size(), record.word, record.rule, "LOGIN ACCEPTED" if record.matched else "login rejected (sample)"], "success" if record.matched else "attempt")
		if engine.phase == "READY":
			message.emit("EXHAUSTED: %d login candidates sent. Revise fragments or investigate another source." % engine.queue.size(), "warning")
	_check_events()

func _check_events() -> void:
	if budget.exhausted and engine.phase != "LOST":
		engine.finish("TRACE")
	if engine.phase in ["WON", "LOST"] and not _announced:
		_announced = true
		ended.emit(engine.result)
	changed.emit()

func victory_details() -> Dictionary:
	return _solution.duplicate(true) if engine.phase == "WON" else {}
