extends RefCounted

var _facts: Array = []
var _revealed: Dictionary = {}
var _budget: RefCounted

func _init(facts: Array = [], budget: RefCounted = null) -> void:
	_facts = facts.duplicate(true)
	_budget = budget

func _available(fact: Dictionary) -> bool:
	for dependency in fact.requires:
		if not _revealed.has(dependency):
			return false
	return true

func snapshot() -> Array:
	var visible: Array = []
	for fact in _facts:
		if not _available(fact):
			continue
		var item := {"id": fact.id, "label": fact.label, "source": fact.source, "cost": fact.cost, "requires": fact.requires.duplicate(), "position": fact.position.duplicate(), "revealed": _revealed.has(fact.id)}
		if item.revealed:
			item["value"] = fact.value
			item["note"] = fact.note
		visible.append(item)
	return visible

func purchase(id: String) -> Dictionary:
	for fact in _facts:
		if fact.id != id:
			continue
		if not _available(fact):
			return {"ok": false, "message": "Source has not been discovered."}
		if _revealed.has(id):
			return {"ok": true, "purchased": false, "message": "Already retrieved. Reading is free."}
		if _budget == null or _budget.exhausted:
			return {"ok": false, "message": "Recon connection is closed."}
		_budget.charge_points(int(fact.cost))
		if _budget.exhausted:
			return {"ok": false, "message": "TRACE: source query intercepted before the reply."}
		_revealed[id] = true
		return {"ok": true, "purchased": true, "message": "%s retrieved. Exposure +%d." % [fact.label, fact.cost]}
	return {"ok": false, "message": "Unknown source."}
