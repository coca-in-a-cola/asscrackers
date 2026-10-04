extends SceneTree

const Budget = preload("res://scripts/domain/exposure_budget.gd")
const Session = preload("res://scripts/domain/game_session.gd")
const Loader = preload("res://scripts/domain/mission_loader.gd")
var count := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")
	create_timer(30.0).timeout.connect(func(): printerr("CAMPAIGN FAIL: watchdog timeout"); quit(1))

func check(condition: bool, description: String) -> void:
	count += 1
	if not condition:
		failures.append(description)
		printerr("CAMPAIGN FAIL: " + description)

func run() -> void:
	var data: CampaignDefinition = load("res://data/campaign/main.tres")
	check(data.valid() and data.goals.size() == 3, "Three serialized valid campaign goals")
	var invalid_campaign := data.duplicate() as CampaignDefinition
	invalid_campaign.goals = data.goals.duplicate()
	invalid_campaign.goals[0] = data.goals[0].duplicate() as CampaignGoal
	invalid_campaign.goals[0].id = &"mismatched_id"
	check(not invalid_campaign.valid(), "Reject goal ID mismatch before campaign launch")
	var grading := data.grading
	for point in [25, 50, 75]:
		var tier := int(point / 25) - 1
		check(grading.mark_for_units(point * Budget.SCALE) == grading.marks[tier], "Inclusive grade boundary " + str(point))
		check(grading.mark_for_units(point * Budget.SCALE + 1) == grading.marks[tier + 1], "One exact unit above boundary " + str(point))
	check(grading.mark_for_units(0) == "A" and grading.mark_for_units(Budget.LIMIT - 1) == "D", "Successful risk extrema")
	check(grading.mark_for_units(Budget.LIMIT).is_empty() and grading.mark_for_units(-1).is_empty(), "Trace and invalid risk have no successful mark")
	check(grading.mark_for_units(101 * Budget.SCALE, 2) == "C", "Mean Exposure, not mean letters")
	check(grading.mark_for_units(50 * Budget.SCALE + 1, 2) == "B", "Fractional average cannot round into A")
	var bad := grading.duplicate() as GradingPolicy
	bad.inclusive_limits = PackedInt32Array([25, 25, 75, 100])
	check(not bad.valid(), "Reject non-monotonic grade policy")
	var state := CampaignState.new()
	check(state.begin(data) and state.index == 0 and state.results.is_empty(), "Fresh campaign starts first target")
	check(not state.submit_result() and not state.advance_target(), "No advancement without success and submission")
	var wrong := {"result": "SUCCESS", "mission_id": "wrong", "exposure_units": 0}
	check(not state.record_success(wrong), "Reject another target's result")
	var routes := [["nickname", "pet", "leaked", "birth_year", "habit"], ["profile", "education", "pet", "sample", "habit"], ["directory", "vehicle", "forum", "sample", "habit"]]
	var fragments := [["Barsik", "19", "90"], ["Luna", "2002"], ["Volga", "1984"]]
	var expected_costs := [45, 32, 38]
	var expected_coefficients := [1.0, 1.5, 2.0]
	for index in data.goals.size():
		var goal := data.goals[index]
		var loaded: Dictionary = Loader.load_mission(goal.mission_file)
		check(loaded.ok and loaded.mission.id == str(goal.id), "Goal IDs match validated mission " + str(index))
		check(loaded.service.time_coefficient == expected_coefficients[index], "Resource service coefficient " + str(index))
		var session := Session.new()
		check(session.start_mission(goal.mission_file).ok, "Load target " + str(index))
		for source in routes[index]:
			check(session.request_intel(source).ok, "Reachable recon source " + source)
		check(session.budget.value == expected_costs[index], "Authored useful recon route cost " + str(index))
		for fragment in fragments[index]:
			session.add_fragment(fragment)
		session.set_special_characters(true)
		check(session.start_attack().ok, "Start real generated candidate pool " + str(index))
		session.advance(session.generation, 120.0)
		check(session.engine.phase == "WON" and not session.engine.match_record.is_empty(), "Clues and allowed rules solve target " + str(index))
		var snapshot: Dictionary = session.result_snapshot()
		check(state.record_success(snapshot) and state.results.size() == index, "Success remains pending " + str(index))
		snapshot["exposure_units"] = 0
		check(state.pending.exposure_units > 0, "Pending result is independent frozen snapshot")
		check(not state.record_success(session.result_snapshot()), "Duplicate success rejected")
		check(state.submit_result() and not state.submit_result(), "Submission occurs exactly once")
		var previous_generation: int = session.generation
		session.start_mission(goal.mission_file)
		session.advance(previous_generation, 100)
		check(session.budget.units == 0 and session.dictionary.words.is_empty() and session.engine.attempts_used == 0, "New mission clears state and invalidates old work")
		session.free()
		check(state.advance_target() == (index < 2), "Ordered progression or completion " + str(index))
	check(state.phase == &"COMPLETE" and state.results.size() == 3 and state.final_mark() == "B", "Complete campaign computes mean-risk B")
	check(state.average_exposure() > 38 and state.average_exposure() < 42, "Mean uses actual successful risk")
	state.reset()
	check(state.phase == &"IDLE" and state.results.is_empty() and state.pending.is_empty(), "Reset clears all campaign progress")
	state.begin(data)
	state.record_success({"result": "SUCCESS", "mission_id": "target_001", "exposure_units": 2 * Budget.SCALE})
	state.fail()
	check(state.phase == &"FAILED" and not state.submit_result() and state.pending.is_empty(), "Game over cannot submit pending result")
	print("CAMPAIGN DOMAIN: %d checks, %d failures" % [count, failures.size()])
	quit(0 if failures.is_empty() else 1)
