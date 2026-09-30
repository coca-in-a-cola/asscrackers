extends RefCounted

const MAX_CANDIDATES := 1956
const MAX_LENGTH := 64
const RULES := ["plain", "append !", "append ?", "append #", "a → @", "a → @ + !"]

static func capacity(specials: bool) -> int:
	return 5 if specials else 6

static func upper_bound(fragment_count: int, specials: bool) -> int:
	var total := 0
	var permutations := 1
	for length in range(1, fragment_count + 1):
		permutations *= fragment_count - length + 1
		total += permutations
	return total * (RULES.size() if specials else 1)

static func generate(fragments: Array, specials: bool = false) -> Dictionary:
	if fragments.size() > capacity(specials):
		return {"ok": false, "message": "Too many fragments for this mode."}
	var input_seen: Dictionary = {}
	for fragment in fragments:
		if not fragment is String or fragment.is_empty() or fragment.length() > MAX_LENGTH:
			return {"ok": false, "message": "Fragments must contain 1–64 characters."}
		if input_seen.has(fragment):
			return {"ok": false, "message": "Duplicate fragment."}
		input_seen[fragment] = true
	var candidates: Array = []
	var seen: Dictionary = {}
	# Short combinations first; deterministic dictionary order within each length.
	for length in range(1, fragments.size() + 1):
		_expand(fragments, length, 0, "", [], specials, candidates, seen)
	if candidates.size() > MAX_CANDIDATES:
		return {"ok": false, "message": "Candidate budget exceeded."}
	return {"ok": true, "candidates": candidates, "upper_bound": upper_bound(fragments.size(), specials)}

static func _expand(fragments: Array, remaining: int, used: int, prefix: String, sources: Array, specials: bool, output: Array, seen: Dictionary) -> void:
	if prefix.length() > MAX_LENGTH:
		return
	if remaining == 0:
		var variants: Array = [prefix]
		if specials:
			var leet := prefix.replace("a", "@")
			variants.append_array([prefix + "!", prefix + "?", prefix + "#", leet, leet + "!"])
		for i in variants.size():
			var word: String = variants[i]
			if word.length() <= MAX_LENGTH and not seen.has(word):
				seen[word] = true
				output.append({"word": word, "sources": sources.duplicate(), "rule": RULES[i]})
		return
	for i in fragments.size():
		if used & (1 << i):
			continue
		sources.append(fragments[i])
		_expand(fragments, remaining - 1, used | (1 << i), prefix + fragments[i], sources, specials, output, seen)
		sources.pop_back()
