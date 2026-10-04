class_name CampaignDefinition
extends Resource

const Loader = preload("res://scripts/domain/mission_loader.gd")

@export var title: String
@export var goals: Array[CampaignGoal] = []
@export var grading: GradingPolicy
@export var ending_dialogue: DialogueEntry

func valid() -> bool:
	if title.is_empty() or goals.is_empty() or grading == null or not grading.valid() or ending_dialogue == null or not ending_dialogue.valid():
		return false
	var seen: Dictionary = {}
	for goal in goals:
		if goal == null or not goal.valid() or seen.has(goal.id):
			return false
		var loaded: Dictionary = Loader.load_mission(goal.mission_file)
		if not loaded.ok or loaded.mission.id != str(goal.id):
			return false
		seen[goal.id] = true
	return true
