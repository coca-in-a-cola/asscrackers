extends SceneTree

const WordList = preload("res://scripts/domain/dictionary_service.gd")
const Generator = preload("res://scripts/domain/candidate_generator.gd")
const EngineModel = preload("res://scripts/domain/attack_engine.gd")
const Session = preload("res://scripts/domain/game_session.gd")
const Loader = preload("res://scripts/domain/mission_loader.gd")
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
	while engine.phase == "RUNNING":
		engine.step_batch("Barsik1990Fluffy".sha256_text())
	check(engine.result == "SUCCESS" and engine.match_record.sources == ["Barsik", "19", "90", "Fluffy"], "User example recovered by actual hash comparison")
	check(generated == Generator.generate(fragments), "Generation deterministic and target-independent")

func _test_engine() -> void:
	var model := EngineModel.new()
	check(not model.start([]).ok and model.exposure == 0, "Empty job free")
	var candidates: Array = Generator.generate(["secret", "wrong"]).candidates
	model.start(candidates)
	var batch := model.step_batch("secret".sha256_text())
	check(batch.checked == 1 and model.result == "SUCCESS" and model.exposure == 10, "Batch stops on hash match")
	check(model.step("secret".sha256_text()).is_empty() and model.attempts_used == 1, "No post-result work")
	model = EngineModel.new()
	model.start(Generator.generate(["a", "b", "c", "d", "e", "f"]).candidates)
	check(not model.start(candidates).ok and model.exposure == 10, "Concurrent job rejected for free")
	while model.phase == "RUNNING":
		model.step_batch("absent".sha256_text())
	check(model.index == 1956 and model.attempts_used == 1956 and model.phase == "READY" and model.exposure == 15, "Entire pool checked, no per-candidate exposure or 10-request cutoff")
	model.start(candidates)
	model.step_batch("secret".sha256_text())
	check(model.result == "SUCCESS" and model.exposure == 25 and model.runs_used == 2, "Second job after exhaustion")
	model = EngineModel.new()
	model.exposure = 85
	model.start(Generator.generate(["secret"]).candidates)
	model.step_batch("secret".sha256_text())
	check(model.result == "SUCCESS" and model.exposure == 95, "Success avoids exhausted-job penalty")
	model = EngineModel.new()
	model.exposure = 85
	model.start(Generator.generate(["wrong"]).candidates)
	model.step_batch("secret".sha256_text())
	check(model.result == "TRACE" and model.exposure == 100, "Exhaustion can trigger trace")
	model = EngineModel.new()
	model.exposure = 90
	model.start(candidates)
	check(model.result == "TRACE" and model.attempts_used == 0, "Trace on launch checks no hashes")
	model = EngineModel.new()
	var oversized: Array = []
	oversized.resize(1957)
	check(not model.start(oversized).ok and model.exposure == 0, "Reject oversized job without silent truncation")
	model.start(candidates)
	candidates.clear()
	check(model.queue.size() == 4, "Independent deep attack snapshot")

func _test_loader() -> void:
	var loaded := Loader.load_mission(Session.MISSION_PATH)
	check(loaded.ok, "Mission loads")
	check(not Loader.load_mission("res://missing.json").ok, "Missing mission diagnostic")
	check(not Loader.load_mission("res://project.godot").ok, "Invalid JSON diagnostic")
	var bad: Dictionary = loaded.mission.duplicate(true)
	bad.solution.hint_fact_id = "missing"
	check(not Loader.validate(bad).ok, "Broken hint rejected")
	bad = loaded.mission.duplicate(true)
	bad.facts[1].id = bad.facts[0].id
	check(not Loader.validate(bad).ok, "Duplicate fact IDs rejected")

func _test_session() -> void:
	var session := Session.new()
	root.add_child(session)
	check(session.restart().ok and session.candidates.is_empty(), "Clean session")
	check(not session.public_mission.has("solution"), "No secret in public dossier")
	for fragment in ["Barsik", "19", "90"]:
		session.add_fragment(fragment)
	check(session.candidates.size() == 15, "Preview updates from fragments")
	session.start_attack()
	check(not session.set_special_characters(true).ok and not session.add_fragment("other").ok and not session.remove_fragment("19").ok, "All preparation locked during job")
	while session.engine.phase == "RUNNING":
		session.advance(session.generation)
	check(session.engine.phase == "READY" and session.engine.exposure == 15, "Canonical hash needs symbol rules")
	check(session.set_special_characters(true).ok, "Rule toggle allowed after exhaustion")
	check(values(session.candidates).has("B@rsik1990!"), "Canonical password generated automatically")
	session.start_attack()
	while session.engine.phase == "RUNNING":
		session.advance(session.generation)
	check(session.engine.result == "SUCCESS" and session.engine.exposure == 25, "Fragments plus checkbox solve authored mission")
	check(session.engine.match_record.sources == ["Barsik", "19", "90"] and session.engine.match_record.rule == "a → @ + !", "Success includes actual derivation")
	var old: int = session.generation
	session.restart()
	session.advance(old)
	check(session.dictionary.words.is_empty() and session.candidates.is_empty() and session.engine.attempts_used == 0 and not session.dictionary.special_characters, "Restart invalidates old work and resets rules")
	var hints: Array = []
	var results: Array = []
	session.hint.connect(func(id: String): hints.append(id))
	session.ended.connect(func(reason: String): results.append(reason))
	session.add_fragment("wrong")
	for i in 6:
		session.start_attack()
		session.advance(session.generation)
	check(session.engine.exposure == 90 and hints == ["pet"], "Hint once, risk per job")
	session.start_attack()
	session.advance(session.generation)
	check(results == ["TRACE"] and session.engine.attempts_used == 6, "One trace result, no seventh hash check")
	session.free()
