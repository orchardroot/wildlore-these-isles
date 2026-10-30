class_name Errands
extends RefCounted
## Two or three step errands (wave 47 C). They are ordinary quests (data/quests/w47_<region>.json, the shape in
## core/quests.gd) with extra keys that say who drives them: "start": {zone, npc, ask, accept}, each step's "npc"
## and "line", "reward_item": {item, n}, "reward_money". The hook starts a quest when you talk to the giver, ticks
## a step when you talk to that step's npc in order, and the last step pays out and sets done_flag. State is the
## quests' own flags. Pure, no autoload names.

const WHO := "Resident"

static var _index := {}   # "zone|npc" -> [{"q": quest, "role": "start" | step index}]
static var _built_for := -1

static func reset() -> void:
	_index = {}
	_built_for = -1

## The errand quests: those with a "start" block.
static func quests() -> Array:
	return Quests.all().filter(func(q): return q is Dictionary and q.get("start") is Dictionary)

static func _build() -> void:
	var list := Quests.all()
	if _built_for == list.size() and not _index.is_empty():
		return
	_built_for = list.size()
	_index = {}
	for q in quests():
		var s: Dictionary = q.start
		_add("%s|%s" % [s.get("zone", ""), s.get("npc", "")], {"q": q, "role": -1})
		var steps: Array = q.get("steps", [])
		for i in steps.size():
			_add("%s|%s" % [steps[i].get("zone", ""), steps[i].get("npc", "")], {"q": q, "role": i})

static func _add(key: String, e: Dictionary) -> void:
	if not _index.has(key):
		_index[key] = []
	_index[key].append(e)

static func _on(data: GameStateData, key: String) -> bool:
	var v: Variant = data.flag(key)
	match typeof(v):
		TYPE_NIL:
			return false
		TYPE_BOOL:
			return v
		TYPE_INT, TYPE_FLOAT:
			return v != 0
		TYPE_STRING:
			return v != ""
	return true

static func _say(text: String) -> Dictionary:
	return {"do": "say", "who": WHO, "text": text}

## ScriptHooks entry. Returns `commands` unchanged when this npc has no errand business.
static func hook(zone_id: String, npc_id: String, commands: Array, data: GameStateData) -> Array:
	_build()
	var key := "%s|%s" % [zone_id, npc_id]
	if not _index.has(key):
		return commands
	var out := commands.duplicate()
	for e in _index[key]:
		var q: Dictionary = e.q
		var st := Quests.status(data, q)
		if st == Quests.DONE:
			continue
		var qid := str(q.get("id", ""))
		if e.role == -1:
			if st == Quests.NOT_STARTED:
				var s: Dictionary = q.start
				out.append({"do": "daily", "key": "er_%s_ask" % qid, "then": [
					_say(str(s.get("ask", ""))),
					{"do": "choice", "text": "Help them out?", "options": ["Of course", "Not just now"], "set": Wants.PICK},
					{"do": "if", "flag": Wants.PICK, "eq": 0, "then": [{"do": "set", "flag": str(q.start_flag)}, _say(str(s.get("accept", "Thank you.")))]}]})
		elif st == Quests.ACTIVE and _is_next(data, q, int(e.role)):
			var step: Dictionary = q.steps[e.role]
			out.append(_say(str(step.get("line", ""))))
			out.append({"do": "set", "flag": str(step.flag)})
			if int(e.role) == q.steps.size() - 1:
				out.append({"do": "trade", "op": "errand", "id": qid})
	return out

static func _is_next(data: GameStateData, q: Dictionary, i: int) -> bool:
	var steps: Array = q.steps
	if _on(data, str(steps[i].get("flag", ""))):
		return false
	for j in i:
		if not _on(data, str(steps[j].get("flag", ""))):
			return false
	return true

## Hands in the quest: the reward, then done_flag. Returns the line to show.
static func reward(data: GameStateData, qid: String) -> String:
	var q := Quests.get_quest(qid)
	if q.is_empty() or Quests.status(data, q) == Quests.DONE:
		return ""
	data.set_flag(str(q.done_flag), true)
	var bits := []
	var ri: Dictionary = q.get("reward_item", {})
	if ri.has("item") and Bag.new(data.bag).add(str(ri.item), int(ri.get("n", 1))) > 0:
		bits.append(str(ItemDB.load_default().get_item(str(ri.item)).get("name", ri.item)))
	var m := int(q.get("reward_money", 0))
	if m > 0:
		data.money += m
		bits.append("£%d" % m)
	return "Errand done: %s. You get %s." % [q.get("title", "the errand"), " and ".join(bits) if not bits.is_empty() else "their thanks"]

## For Quests.all_settable: the flags these errands set in code, as `set` commands.
static func settable_commands() -> Array:
	var out := []
	for q in quests():
		for f in Quests.flags_of(q):
			out.append({"do": "set", "flag": f})
	return out

## Validator: giver and step npcs exist, rewards are real items, lines present, no em-dashes.
static func check(zones: Dictionary, items: ItemDB) -> Array:
	var errors := []
	for q in quests():
		var tag := "errand %s" % q.get("id", "?")
		var spots := [q.start]
		spots.append_array(q.get("steps", []))
		for s in spots:
			errors.append_array(Wants._check_at(tag, str(s.get("zone", "")), str(s.get("npc", "")), zones))
		for k in ["ask", "accept"]:
			if str(q.start.get(k, "")) == "":
				errors.append(tag + ": start has no " + k)
		for s in q.get("steps", []):
			if str(s.get("line", "")) == "":
				errors.append(tag + ": a step has no line")
		var ri: Dictionary = q.get("reward_item", {})
		if not items.has(str(ri.get("item", ""))):
			errors.append(tag + ": reward item '%s' is not an item" % ri.get("item", ""))
		if JSON.stringify(q).contains("—"):
			errors.append(tag + ": has an em-dash")
	return errors
