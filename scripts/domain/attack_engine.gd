extends RefCounted

const Generator = preload("res://scripts/domain/candidate_generator.gd")
var phase := "READY"
var attempts_used := 0
var runs_used := 0
var exposure := 0
var result := ""
var queue: Array = []
var index := 0
var last_record: Dictionary = {}
var match_record: Dictionary = {}

func start(candidates: Array) -> Dictionary:
	if phase != "READY" or candidates.is_empty() or exposure >= 100:
		return {"ok": false, "message": "Add fragments first. Runs are only available while READY."}
	if candidates.size() > Generator.MAX_CANDIDATES:
		return {"ok": false, "message": "Candidate budget exceeded. No work was started."}
	for candidate in candidates:
		if not candidate is Dictionary or not candidate.get("word") is String or candidate.word.is_empty():
			return {"ok": false, "message": "Invalid candidate snapshot."}
	queue = candidates.duplicate(true)
	index = 0
	last_record = {}
	match_record = {}
	runs_used += 1
	exposure = mini(100, exposure + 10)
	phase = "RUNNING"
	if exposure >= 100:
		finish("TRACE")
		return {"ok": true, "message": "TRACE: compute relay burned before the first hash check."}
	return {"ok": true, "message": "Offline SHA-256 job: %d candidates. GPU simulation. Exposure +10." % queue.size()}

func step(target_hash: String) -> Dictionary:
	if phase != "RUNNING":
		return {}
	var candidate: Dictionary = queue[index]
	index += 1
	attempts_used += 1
	var matched: bool = candidate.word.sha256_text() == target_hash
	last_record = candidate.duplicate(true)
	last_record["matched"] = matched
	last_record["attempt"] = attempts_used
	last_record["index"] = index
	if matched:
		match_record = last_record.duplicate(true)
		finish("SUCCESS")
	elif index == queue.size():
		# Gameplay risk belongs to the compute job, never each local hash operation.
		exposure = mini(100, exposure + 5)
		if exposure >= 100:
			finish("TRACE")
		else:
			phase = "READY"
	return last_record

func step_batch(target_hash: String, batch_size: int = 64) -> Dictionary:
	var checked := 0
	while phase == "RUNNING" and checked < batch_size:
		step(target_hash)
		checked += 1
	return {"checked": checked, "last": last_record.duplicate(true)}

func finish(reason: String) -> void:
	result = reason
	phase = "WON" if reason == "SUCCESS" else "LOST"
