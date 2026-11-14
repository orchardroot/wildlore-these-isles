class_name ArkLogic
extends RefCounted
## Pure rules behind the Ark screen: sorting the stored creatures and deciding what may be released.

const MODES := ["dex", "level", "type"]
const MODE_NAMES := {"dex": "Fieldbook number", "level": "Level", "type": "Type"}
## Legends are the species marked `"legend": true` in data/creatures (the validator keeps every rock-bottom catch rate
## marked); letting one go takes two confirmations.

static func next_mode(mode: String) -> String:
	var i := MODES.find(mode)
	return MODES[(i + 1) % MODES.size()]

static func is_legend(c: Creature) -> bool:
	return bool(c.species.get("legend", false))

## Sorts `ark` in place. `order` is the Fieldbook order (Dex.ids()). Every mode falls back to Fieldbook number,
## then to level (highest first), so the result is stable and predictable.
static func sort(ark: Array, mode: String, order: Array) -> void:
	var rank := {}
	for i in order.size():
		rank[order[i]] = i
	var num := func(c: Creature) -> int: return int(rank.get(c.species.id, 100000))
	ark.sort_custom(func(a: Creature, b: Creature) -> bool:
		if mode == "level" and a.level != b.level:
			return a.level > b.level
		if mode == "type":
			var ta := str(a.types()[0])
			var tb := str(b.types()[0])
			if ta != tb:
				return ta < tb
		var na: int = num.call(a)
		var nb: int = num.call(b)
		if na != nb:
			return na < nb
		return a.level > b.level)

## Can this creature be released? {ok, why, confirms}: confirms is how many "are you sure"s to ask (2 for a legend).
static func release_rule(data: GameStateData, from_party: bool, i: int) -> Dictionary:
	var list: Array = data.party if from_party else data.ark
	if i < 0 or i >= list.size():
		return {"ok": false, "why": "Nobody there.", "confirms": 0}
	var c: Creature = list[i]
	if FamilyCat.is_family(c):
		return {"ok": false, "why": FamilyCat.keep_reason(c), "confirms": 0}  # family is for keeps
	if from_party:
		if data.party.size() <= 1:
			return {"ok": false, "why": "You can't travel without a single companion.", "confirms": 0}
		var able := data.party.filter(func(x): return not x.is_fainted())
		if not c.is_fainted() and able.size() <= 1:
			return {"ok": false, "why": "That's your last creature fit to battle. Keep them with you.", "confirms": 0}
	return {"ok": true, "why": "", "confirms": 2 if is_legend(c) else 1}
