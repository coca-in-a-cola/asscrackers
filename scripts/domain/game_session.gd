extends Node

signal changed
signal message(text: String, kind: String)
signal hint(fact_id: String)
signal ended(result: String)

const WordList = preload("res://scripts/domain/dictionary_service.gd")
const EngineModel = preload("res://scripts/domain/attack_engine.gd")
const Loader = preload("res://scripts/domain/mission_loader.gd")
const Generator = preload("res://scripts/domain/candidate_generator.gd")
const MISSION_PATH := "res://data/targets/target_001.json"

var dictionary = WordList.new()
var engine = EngineModel.new()
var public_mission: Dictionary = {}
var _solution: Dictionary = {}
var _target_hash := ""
var candidates: Array = []
var hint_shown := false
var generation := 0
var _timer: Timer
var _announced := false

func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = 0.1
	add_child(_timer)
	_timer.timeout.connect(_on_tick)

func restart() -> Dictionary:
	generation += 1
	if _timer:
		_timer.stop()
	dictionary.clear()
	engine = EngineModel.new()
	hint_shown = false
	_announced = false
	public_mission = {}
	_solution = {}
	_target_hash = ""
	candidates = []
	var response := Loader.load_mission(MISSION_PATH)
	if not response.ok:
		return response
	public_mission = response.mission.duplicate(true)
	_solution = public_mission.solution.duplicate(true)
	public_mission.erase("solution")
	_target_hash = _solution.password.sha256_text()
	changed.emit()
	return {"ok": true}

func add_fragment(value: String) -> Dictionary:
	if engine.phase != "READY" or _solution.is_empty():
		return {"ok": false, "message": "Wait for the run to finish, or restart the mission."}
	var response: Dictionary = dictionary.add_word(value)
	if response.ok:
		_rebuild_candidates()
		changed.emit()
	return response

func remove_fragment(value: String) -> Dictionary:
	if engine.phase != "READY" or _solution.is_empty():
		return {"ok": false, "message": "Wait for the run to finish, or restart the mission."}
	var response: Dictionary = dictionary.remove_word(value)
	if response.ok:
		_rebuild_candidates()
		changed.emit()
	return response

func set_special_characters(enabled: bool) -> Dictionary:
	if engine.phase != "READY" or _solution.is_empty():
		return {"ok": false, "message": "Rules are locked while running or after the session ends."}
	var response: Dictionary = dictionary.set_special_characters(enabled)
	if response.ok:
		_rebuild_candidates()
		changed.emit()
	return response

func _rebuild_candidates() -> void:
	var generated := Generator.generate(dictionary.snapshot(), dictionary.special_characters)
	candidates = generated.get("candidates", [])

func start_attack() -> Dictionary:
	if _solution.is_empty():
		return {"ok": false, "message": "Mission data is unavailable."}
	var response: Dictionary = engine.start(candidates)
	if response.ok:
		if engine.phase == "RUNNING" and _timer:
			_timer.start()
		_check_events()
	return response

func _on_tick() -> void:
	advance(generation)

func advance(expected_generation: int) -> void:
	if expected_generation != generation:
		return
	var batch: Dictionary = engine.step_batch(_target_hash)
	if batch.checked == 0:
		return
	var record: Dictionary = batch.last
	message.emit("[%04d/%04d] %s  /  %s  →  %s" % [engine.index, engine.queue.size(), record.word, record.rule, "HASH MATCH" if record.matched else "no match (batch sample)"], "success" if record.matched else "attempt")
	if engine.phase == "READY":
		message.emit("EXHAUSTED: all %d candidates checked. Exposure +5. Revise fragments or enable special characters." % engine.queue.size(), "warning")
	_check_events()

func _check_events() -> void:
	if engine.phase != "RUNNING" and _timer:
		_timer.stop()
	if engine.phase in ["WON", "LOST"]:
		if not _announced:
			_announced = true
			ended.emit(engine.result)
	elif engine.exposure >= 60 and not hint_shown:
		hint_shown = true
		hint.emit(_solution.hint_fact_id)
	changed.emit()

func victory_details() -> Dictionary:
	return _solution.duplicate(true) if engine.phase == "WON" else {}
