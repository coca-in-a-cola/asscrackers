extends RefCounted

const Generator = preload("res://scripts/domain/candidate_generator.gd")
const Budget = preload("res://scripts/domain/exposure_budget.gd")
const BASE_SECONDS := 60.0
var budget: RefCounted
var phase := "READY"
var attempts_used := 0
var runs_used := 0
var result := ""
var queue: Array = []
var index := 0
var elapsed := 0.0
var duration := 0.0
var seconds_per_request := BASE_SECONDS / Generator.MAX_CANDIDATES
var last_record: Dictionary = {}
var match_record: Dictionary = {}
var exposure: float:
	get:
		return budget.value
var remaining: float:
	get:
		return maxf(0, duration - elapsed) if phase == "RUNNING" else 0.0

func _init(shared_budget: RefCounted = null) -> void:
	budget = shared_budget if shared_budget != null else Budget.new()

static func forecast(count: int, coefficient: float) -> Dictionary:
	return {"duration": BASE_SECONDS * coefficient * count / Generator.MAX_CANDIDATES, "cost": Budget.attack_cost(count)}

func start(candidates: Array, coefficient: float = 1.0) -> Dictionary:
	if phase != "READY" or candidates.is_empty() or budget.exhausted:
		return {"ok": false, "message": "Add fragments first. Runs are only available while READY."}
	if candidates.size() > Generator.MAX_CANDIDATES or not is_finite(coefficient) or coefficient <= 0:
		return {"ok": false, "message": "Invalid candidate budget or service coefficient."}
	for candidate in candidates:
		if not candidate is Dictionary or not candidate.get("word") is String or candidate.word.is_empty():
			return {"ok": false, "message": "Invalid candidate snapshot."}
	queue = candidates.duplicate(true)
	index = 0
	elapsed = 0.0
	seconds_per_request = BASE_SECONDS * coefficient / Generator.MAX_CANDIDATES
	duration = queue.size() * seconds_per_request
	last_record = {}
	match_record = {}
	runs_used += 1
	budget.charge_points(2)
	phase = "RUNNING"
	if budget.exhausted:
		finish("TRACE")
		return {"ok": true, "message": "TRACE: botnet launch intercepted before the first request."}
	return {"ok": true, "message": "Botnet dispatched: %d login candidates, up to %.3f s. Launch Exposure +2." % [queue.size(), duration]}

func advance(delta: float, target_hash: String) -> Dictionary:
	if phase != "RUNNING" or not is_finite(delta) or delta <= 0.0:
		return {"checked": 0, "last": {}}
	var before := index
	elapsed = minf(duration, elapsed + delta)
	var due := mini(queue.size(), int(floor((elapsed + 0.000000001) / seconds_per_request)))
	while phase == "RUNNING" and index < due:
		var candidate: Dictionary = queue[index]
		index += 1
		attempts_used += 1
		budget.charge_request()
		last_record = candidate.duplicate(true)
		last_record.merge({"matched": false, "attempt": attempts_used, "index": index})
		if budget.exhausted:
			finish("TRACE")
		elif candidate.word.sha256_text() == target_hash:
			last_record.matched = true
			match_record = last_record.duplicate(true)
			finish("SUCCESS")
		elif index == queue.size():
			phase = "READY"
		if phase != "RUNNING":
			elapsed = index * seconds_per_request
	return {"checked": index - before, "last": last_record.duplicate(true)}

func stop() -> bool:
	if phase != "RUNNING":
		return false
	phase = "READY"
	elapsed = index * seconds_per_request
	return true

func finish(reason: String) -> void:
	result = reason
	phase = "WON" if reason == "SUCCESS" else "LOST"
