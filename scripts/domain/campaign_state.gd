class_name CampaignState
extends RefCounted
## Owns submitted results and progression; authored resources remain immutable.

const Budget = preload("res://scripts/domain/exposure_budget.gd")
var definition: CampaignDefinition
var index := 0
var phase: StringName = &"IDLE"
var results: Array[Dictionary] = []
var pending: Dictionary = {}

func begin(data: CampaignDefinition) -> bool:
	if data == null or not data.valid():
		return false
	reset()
	definition = data
	phase = &"ACTIVE"
	return true

func reset() -> void:
	definition = null
	index = 0
	phase = &"IDLE"
	results.clear()
	pending.clear()

func current_goal() -> CampaignGoal:
	return definition.goals[index] if definition != null and index < definition.goals.size() else null

func record_success(snapshot: Dictionary) -> bool:
	if phase != &"ACTIVE" or snapshot.get("result") != "SUCCESS" or snapshot.get("mission_id") != str(current_goal().id):
		return false
	var units: Variant = snapshot.get("exposure_units")
	if not units is int or units < 0 or units >= Budget.LIMIT:
		return false
	pending = snapshot.duplicate(true)
	pending["title"] = current_goal().title
	pending["mark"] = definition.grading.mark_for_units(units)
	phase = &"AWAITING_SUBMIT"
	return true

func submit_result() -> bool:
	if phase != &"AWAITING_SUBMIT" or pending.is_empty():
		return false
	results.append(pending.duplicate(true))
	pending.clear()
	phase = &"TRANSITION"
	return true

func advance_target() -> bool:
	if phase != &"TRANSITION":
		return false
	if index + 1 == definition.goals.size():
		phase = &"COMPLETE"
		return false
	index += 1
	phase = &"ACTIVE"
	return true

func fail() -> void:
	pending.clear()
	phase = &"FAILED"

func total_units() -> int:
	var total := 0
	for result in results:
		total += result.exposure_units
	return total

func average_exposure() -> float:
	return float(total_units()) / (Budget.SCALE * results.size()) if not results.is_empty() else 0.0

func final_mark() -> String:
	return definition.grading.mark_for_units(total_units(), results.size()) if definition != null else ""
