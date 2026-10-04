extends SceneTree

const WordList = preload("res://scripts/domain/dictionary_service.gd")
const Generator = preload("res://scripts/domain/candidate_generator.gd")
const EngineModel = preload("res://scripts/domain/attack_engine.gd")
const Session = preload("res://scripts/domain/game_session.gd")
const Loader = preload("res://scripts/domain/mission_loader.gd")
const Budget = preload("res://scripts/domain/exposure_budget.gd")
const Services = preload("res://scripts/domain/service_catalog.gd")
var count := 0
var failures: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	count += 1
	if not condition:
		failures.append(description)
		printerr("FAIL: " + description)

func run() -> void:
	_test_words()
	_test_generator()
	_test_engine()
	_test_loader()
	_test_session()
	print("DOMAIN TESTS: %d checks, %d failures" % [count, failures.size()])
	quit(0 if failures.is_empty() else 1)

func values(candidates: Array) -> Array:
	var result: Array = []
	for candidate in candidates:
		result.append(candidate.word)
	return result

func _test_words() -> void:
	var store := WordList.new()
	check(store.words.is_empty() and store.capacity() == 6, "Default six-slot dictionary")
	check(store.add_word(" Barsik ").ok and store.words == ["Barsik"], "Trim outer whitespace")
	check(not store.add_word("Barsik").added and store.words.size() == 1, "Duplicate is a no-op")
	store.add_word("barsik")
	store.add_word("two words")
	check(store.words == ["Barsik", "barsik", "two words"], "Case and internal spaces preserved")
	for value in ["", "   ", "a\nb", "a\tb", "x".repeat(65)]:
		var before := store.snapshot()
		check(not store.add_word(value).ok and store.words == before, "Invalid fragment is atomic: " + str(value.length()))
	for value in ["one", "two", "three"]:
		store.add_word(value)
	var full := store.snapshot()
	check(not store.add_word("seventh").ok and store.words == full, "Six-slot limit")
	check(not store.set_special_characters(true).ok and store.words == full and not store.special_characters, "Toggle cannot delete sixth fragment")
	store.remove_word("three")
	check(store.set_special_characters(true).ok and store.capacity() == 5, "Special mode uses five slots")
	check(not store.add_word("extra").ok and store.words.size() == 5, "Special-mode sixth fragment rejected")
	check(store.add_word("one").ok and store.words.size() == 5, "Duplicate in full special dictionary")
	check(store.set_special_characters(false).ok and store.words.size() == 5 and store.capacity() == 6, "Disabling rules preserves fragments")
	store.remove_word("barsik")
	store.add_word("new")
	check(store.words == ["Barsik", "two words", "one", "two", "new"], "Removal/insertion order")
	var copy := store.snapshot()
	copy.clear()
	check(store.words.size() == 5, "Independent snapshot")
	store.clear()
	check(store.words.is_empty() and not store.special_characters, "Reset clears words and rule mode")

func _test_generator() -> void:
	check(Generator.upper_bound(6, false) == 1956, "6 + 30 + 120 + 360 + 720 + 720 = 1956")
	check(Generator.upper_bound(5, true) == 1950, "(5 + 20 + 60 + 120 + 120) × 6 = 1950")
	var generated := Generator.generate(["a", "b", "c", "d", "e", "f"])
	check(generated.ok and generated.candidates.size() == 1956, "Full normal pool")
	check(Generator.generate([]).candidates.is_empty(), "Empty dictionary has no candidates")
	check(values(Generator.generate(["A", "B"]).candidates) == ["A", "B", "AB", "BA"], "Singles then all ordered subsets; no repetition")
	check(values(Generator.generate(["a", "aa"]).candidates) == ["a", "aa", "aaa"], "Deduplicate equal concatenations")
	check(Generator.generate(["a", "a"]).ok == false, "Reject duplicate generator inputs")
	check(not Generator.generate(["a", "b", "c", "d", "e", "f"], true).ok, "Special generator cannot bypass slot cap")
	generated = Generator.generate(["aa", "ba", "ca", "da", "ea"], true)
	check(generated.candidates.size() == 1950, "Full special pool stays within same compute budget")
	var special := values(Generator.generate(["cat"], true).candidates)
	check(special == ["cat", "cat!", "cat?", "cat#", "c@t", "c@t!"], "Six explicit special-character rules")
	check(values(Generator.generate(["xyz"], true).candidates) == ["xyz", "xyz!", "xyz?", "xyz#"], "Unchanged leet output deduplicated")
	check(not values(Generator.generate(["cat"]).candidates).has("c@t!"), "No specials when toggle off")
	check(not values(Generator.generate(["cat"], true).candidates).has("Cat"), "No hidden case changes")
	generated = Generator.generate(["x".repeat(64), "y"], true)
	var within_limit := true
	for candidate in generated.candidates:
		within_limit = within_limit and candidate.word.length() <= 64
	check(within_limit and values(generated.candidates).has("x".repeat(64)), "Long combined candidates skipped without truncation")
	var fragments := ["Fluffy", "Barsik", "19", "90", "Kek", "lol"]
	generated = Generator.generate(fragments)
	check(values(generated.candidates).has("Barsik1990Fluffy"), "User example generated from four fragments in arbitrary order")
	var engine := EngineModel.new()
	engine.start(generated.candidates)
	engine.advance(60, "Barsik1990Fluffy".sha256_text())
	check(engine.result == "SUCCESS" and engine.match_record.sources == ["Barsik", "19", "90", "Fluffy"], "User example recovered by actual hash comparison")
	check(generated == Generator.generate(fragments), "Generation deterministic and target-independent")

func _test_engine() -> void:
	var model := EngineModel.new()
	check(not model.start([]).ok and model.exposure == 0, "Empty job free")
	var full: Array = Generator.generate(["a", "b", "c", "d", "e", "f"]).candidates
	check(is_equal_approx(EngineModel.forecast(1956, 1).duration, 60), "Full baseline forecast exactly 60 seconds")
	check(is_equal_approx(EngineModel.forecast(325, 1).duration, 60.0 * 325 / 1956), "Partial forecast proportional to unique candidates")
	check(EngineModel.forecast(1956, 1).cost == 20, "Full baseline exposure forecast exactly 20")
	model.start(full)
	check(model.exposure == 2 and model.attempts_used == 0, "Launch charges only 2, sends no premature requests")
	check(not model.start(full).ok and model.exposure == 2, "Concurrent job rejected for free")
	model.advance(59.999, "absent".sha256_text())
	check(model.phase == "RUNNING" and model.index == 1955, "Full pass unfinished immediately before sixty seconds")
	model.advance(0.001, "absent".sha256_text())
	check(model.phase == "READY" and model.index == 1956 and model.elapsed == 60, "Full pass finishes at sixty seconds without waiting in real time")
	check(model.exposure == 20 and model.attempts_used == 1956, "Exact per-request exposure, no exhaustion penalty")
	check(model.advance(60, "absent".sha256_text()).checked == 0 and model.exposure == 20, "Completed jobs cannot keep spending")
	model = EngineModel.new()
	model.start(full, 2)
	model.advance(60, "absent".sha256_text())
	check(model.phase == "RUNNING" and model.index == 978 and model.remaining == 60, "Service coefficient doubles duration, not requests")
	model.advance(60, "absent".sha256_text())
	check(model.phase == "READY" and model.exposure == 20, "Slower service has identical request cost")
	var candidates: Array = Generator.generate(["secret", "wrong"]).candidates
	model = EngineModel.new()
	model.start(candidates)
	var batch := model.advance(60, "secret".sha256_text())
	check(batch.checked == 1 and model.result == "SUCCESS", "Early success sends only the matching request")
	check(model.budget.units == 2 * Budget.SCALE + Budget.REQUEST_UNITS and model.elapsed < 0.031, "Early match saves unspent exposure and time")
	check(model.advance(60, "secret".sha256_text()).checked == 0, "No post-success requests")
	model = EngineModel.new()
	model.start(full)
	model.advance(10, "absent".sha256_text())
	var spent: int = model.budget.units
	check(model.stop() and model.phase == "READY" and model.index == 326, "Stop cancels remaining requests")
	model.advance(100, "absent".sha256_text())
	check(model.budget.units == spent and not model.stop(), "Stopped jobs do not spend and repeated Stop is harmless")
	check(model.start(candidates).ok, "New run allowed after stop")
	model = EngineModel.new()
	model.budget.charge_points(98)
	model.start(candidates)
	check(model.result == "TRACE" and model.attempts_used == 0 and model.exposure == 100, "Launch can trace before requests")
	model = EngineModel.new()
	model.budget.charge_points(97)
	model.start(full)
	model.advance(60, "absent".sha256_text())
	check(model.result == "TRACE" and model.exposure == 100 and model.index == 109, "Trace interrupts the pool at exact fixed-point threshold")
	model = EngineModel.new()
	var oversized: Array = []
	oversized.resize(1957)
	check(not model.start(oversized).ok and model.exposure == 0, "Reject oversized job without silent truncation")
	check(not model.start(candidates, 0).ok and not model.start(candidates, INF).ok and model.exposure == 0, "Invalid service coefficients rejected for free")
	model.start(candidates)
	model.advance(-1, "absent".sha256_text())
	model.advance(INF, "absent".sha256_text())
	check(model.index == 0, "Invalid clock deltas cannot send requests")
	candidates.clear()
	check(model.queue.size() == 4, "Independent deep attack snapshot")

func _test_loader() -> void:
	var loaded := Loader.load_mission("res://data/targets/target_001.json")
	check(loaded.ok, "Mission loads")
	check(not Loader.load_mission("res://missing.json").ok, "Missing mission diagnostic")
	check(not Loader.load_mission("res://project.godot").ok, "Invalid JSON diagnostic")
	var bad: Dictionary = loaded.mission.duplicate(true)
	bad.facts[0].requires = ["missing"]
	check(not Loader.validate(bad).ok, "Missing graph reference rejected")
	bad = loaded.mission.duplicate(true)
	bad.facts[1].id = bad.facts[0].id
	check(not Loader.validate(bad).ok, "Duplicate fact IDs rejected")
	bad = loaded.mission.duplicate(true)
	bad.facts[0].requires = ["habit"]
	check(not Loader.validate(bad).ok, "Cyclic recon dependency rejected")
	bad = loaded.mission.duplicate(true)
	bad.facts[0].cost = 1.5
	check(not Loader.validate(bad).ok, "Fractional recon prices rejected")
	bad = loaded.mission.duplicate(true)
	bad.facts[0].requires = ["birth_year", "birth_year"]
	check(not Loader.validate(bad).ok, "Duplicate dependencies rejected")
	check(loaded.service.time_coefficient == 1 and Services.load_service("anus_vault").service.time_coefficient == 2, "Mission selects named catalog service")
	check(not Services.load_service("missing").ok, "Unknown service diagnosed")

func _test_session() -> void:
	var session := Session.new()
	session.mission_path = "res://data/targets/target_001.json"
	session.automatic_clock = false
	root.add_child(session)
	check(session.restart().ok and session.candidates.is_empty(), "Clean session")
	check(not session.public_mission.has("solution") and not session.public_mission.has("facts"), "No secret or unretrieved facts in public mission")
	check(session.public_mission.login == "lexa@anus.industries" and session.service.id == "anus_hr", "Known account and target service supplied by task")
	check(session.recon_snapshot().size() == 2 and not str(session.recon_snapshot()).contains("Barsik"), "Only initial sources exposed, no content leak")
	check(not session.request_intel("habit").ok and not session.request_intel("missing").ok and session.budget.value == 0, "Undiscovered and unknown nodes cannot charge or reveal")
	session.request_intel("nickname")
	check(session.budget.value == 5 and session.recon_snapshot().size() == 5, "Paid profile unlocks three child sources")
	check(not session.request_intel("nickname").purchased and session.budget.value == 5, "Repeat retrieval free")
	var public_copy: Array = session.recon_snapshot()
	public_copy[0].label = "tampered"
	check(session.recon_snapshot()[0].label != "tampered", "Recon projection independent from source data")
	session.request_intel("pet")
	check(session.recon_snapshot().size() == 5, "Multiple-parent child waits for all prerequisites")
	session.request_intel("leaked")
	check(session.recon_snapshot().size() == 6, "Cross-reference reveals deeper IT branch")
	session.request_intel("habit")
	session.request_intel("birth_year")
	check(session.budget.value == 45, "Recon prices share one exact exposure ledger")
	for fragment in ["Barsik", "19", "90"]:
		session.add_fragment(fragment)
	check(session.candidates.size() == 15, "Preview updates from fragments")
	session.start_attack()
	check(not session.set_special_characters(true).ok and not session.add_fragment("other").ok and not session.remove_fragment("19").ok, "All preparation locked during job")
	session.advance(session.generation, 60)
	check(session.engine.phase == "READY" and session.budget.units == 47 * Budget.SCALE + 15 * Budget.REQUEST_UNITS, "No-match costs only launch and sent requests, in shared ledger")
	check(session.set_special_characters(true).ok, "Rule toggle allowed after exhaustion")
	check(values(session.candidates).has("B@rsik1990!"), "Canonical password generated automatically")
	session.start_attack()
	session.advance(session.generation, 60)
	check(session.engine.result == "SUCCESS" and session.engine.exposure < 50, "Target login accepted early from inferred fragments and rules")
	check(session.engine.match_record.sources == ["Barsik", "19", "90"] and session.engine.match_record.rule == "a → @ + !", "Success includes actual derivation")
	check(not session.request_intel("hobby").ok, "Mission result closes paid reconnaissance")
	var old: int = session.generation
	session.restart()
	session.add_fragment("wrong")
	session.start_attack()
	session.advance(old, 60)
	check(session.engine.attempts_used == 0 and session.recon_snapshot().size() == 2, "Restart invalidates stale clock and all purchased branches")
	session.stop_attack()
	session.restart()
	var results: Array = []
	session.ended.connect(func(reason: String): results.append(reason))
	for fragment in ["a", "b", "c", "d", "e", "f"]:
		session.add_fragment(fragment)
	session.start_attack()
	session.request_intel("nickname")
	check(session.engine.phase == "RUNNING" and session.budget.value == 7, "Recon available while botnet runs, sharing launch cost")
	session.budget.charge_points(90)
	session.request_intel("pet")
	check(results == ["TRACE"] and session.budget.value == 100, "Recon can trace and terminate active botnet")
	session.advance(session.generation, 60)
	check(results == ["TRACE"] and session.engine.attempts_used == 0, "One result signal, no requests after recon trace")
	session.free()
