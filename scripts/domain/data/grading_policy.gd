class_name GradingPolicy
extends Resource

const Budget = preload("res://scripts/domain/exposure_budget.gd")
@export var marks: PackedStringArray = ["A", "B", "C", "D"]
@export var inclusive_limits: PackedInt32Array = [25, 50, 75, 100]

func valid() -> bool:
	if marks.is_empty() or marks.size() != inclusive_limits.size() or inclusive_limits[-1] != 100:
		return false
	var previous := -1
	var seen: Dictionary = {}
	for index in marks.size():
		if marks[index].is_empty() or seen.has(marks[index]) or inclusive_limits[index] <= previous or inclusive_limits[index] > 100:
			return false
		seen[marks[index]] = true
		previous = inclusive_limits[index]
	return true

func mark_for_units(total_units: int, sample_count: int = 1) -> String:
	if not valid() or sample_count <= 0 or total_units < 0 or total_units >= Budget.LIMIT * sample_count:
		return ""
	for index in marks.size():
		# Compare rational averages directly; never round displayed Exposure first.
		if total_units <= inclusive_limits[index] * Budget.SCALE * sample_count:
			return marks[index]
	return ""
