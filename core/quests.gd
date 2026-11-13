class_name Quests
extends RefCounted
## Quests (data/quests/<region>.json): short errands round a town and its routes, written by each region as
## ordinary dialogue that sets flags. A file is {"quests": [{id, title, region, town (where it's given), giver,
## summary, start_flag, steps: [{flag, text, zone}], done_flag, reward}]}.
##
## State lives entirely in the save's flags, so old saves need nothing new:
##   not started   start_flag unset (and done_flag unset)
##   active        start_flag set; the current step is the first whose flag is unset (the last stays current once
##                 every step is ticked but the quest isn't handed in yet)
##   done          done_flag set
## The Quest Log (ui/quests_screen.gd), the toasts (QuestNews) and "Where next?" (MenuLogic) read this.
## Pure logic, no autoload names: the validator loads it.
##
## Branching (w55, data/quests/w55_*.json): a quest may carry "endings": [{flag, text}], what the Quest Log says
## once it is done, the first whose flag is on. The choice itself is ordinary dialogue that sets a flag in a branch,
## and consequences that arrive later are stamped when the choice is made ({"do":"set","flag":k,"value":"@now"})
## and ripen with the condition later_<k>_<n> (see later()).

const DIR := "res://data/quests"
const NOT_STARTED := "not_started"
const ACTIVE := "active"
const DONE := "done"
const FLAG_PREFIX := "q_"

static var _cache: Array = []
static var _loaded := false
static var _by_flag: Dictionary = {}

## Every quest in data/quests, file by file (files in name order, quests in file order).
static func all() -> Array:
	if not _loaded:
		var list := []
		for path in JsonUtil.list_json(DIR):
			list.append_array(parse(JsonUtil.read(path), path.get_file().get_basename()))
		use(list)
	return _cache

## Swap in a quest list (tests); reset() goes back to the files.
static func use(list: Array) -> void:
	_cache = list
	_loaded = true
	_by_flag = {}
	for q in list:
		for f in flags_of(q):
			if not _by_flag.has(f):
				_by_flag[f] = []
			_by_flag[f].append(q)

static func reset() -> void:
	_cache = []
	_loaded = false
	_by_flag = {}

## The quests in one file's contents ([] for anything malformed). Each remembers its file as `_file`.
static func parse(d: Variant, file: String) -> Array:
	if not (d is Dictionary) or not (d.get("quests") is Array):
		return []
	var out := []
	for q in d.quests:
		if q is Dictionary:
			var c: Dictionary = q.duplicate(true)
			c["_file"] = file
			if not (c.get("steps") is Array):
				c["steps"] = []
			out.append(c)
	return out

static func get_quest(id: String, list: Array = []) -> Dictionary:
	for q in (list if not list.is_empty() else all()):
		if str(q.get("id", "")) == id:
			return q
	return {}

## start_flag, every step's flag and done_flag (the empty ones left out).
static func flags_of(q: Dictionary) -> Array:
	var out := []
	for f in [str(q.get("start_flag", ""))] + q.get("steps", []).map(func(s): return str(s.get("flag", "")) if s is Dictionary else "") + [str(q.get("done_flag", ""))]:
		if f != "" and f not in out:
			out.append(f)
	return out

## The quests whose state a flag can change.
static func touched_by(key: String, list: Array = []) -> Array:
	if not list.is_empty():
		return list.filter(func(q): return key in flags_of(q))
	all()
	return _by_flag.get(key, [])

static func _on(d: GameStateData, key: String) -> bool:
	if key == "":
		return false
	var v: Variant = d.flag(key)
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

static func status(d: GameStateData, q: Dictionary) -> String:
	if _on(d, str(q.get("done_flag", ""))):
		return DONE
	if _on(d, str(q.get("start_flag", ""))):
		return ACTIVE
	return NOT_STARTED

## The current step's index while active (the last once all are ticked), -1 otherwise.
static func step_index(d: GameStateData, q: Dictionary) -> int:
	if status(d, q) != ACTIVE:
		return -1
	var steps: Array = q.get("steps", [])
	for i in steps.size():
		if not _on(d, str(steps[i].get("flag", ""))):
			return i
	return steps.size() - 1

static func current_step(d: GameStateData, q: Dictionary) -> Dictionary:
	var i := step_index(d, q)
	return q.steps[i] if i >= 0 and i < q.steps.size() else {}

## The steps the Quest Log shows: [{text, zone, done, current}]. The ones ticked and the current one; the rest stay
## a surprise. A finished quest shows the lot, all ticked.
static func log_steps(d: GameStateData, q: Dictionary) -> Array:
	var st := status(d, q)
	if st == NOT_STARTED:
		return []
	var out := []
	var cur := step_index(d, q)
	var steps: Array = q.get("steps", [])
	for i in steps.size():
		var s: Dictionary = steps[i]
		var ticked := st == DONE or (i != cur and _on(d, str(s.get("flag", ""))))
		if not ticked and i != cur:
			continue
		out.append({"text": str(s.get("text", "")), "zone": str(s.get("zone", "")), "done": ticked, "current": i == cur})
	if st == DONE and outcome(d, q) != "":  # how it turned out, a line after the last step
		out.append({"text": outcome(d, q), "zone": "", "done": true, "current": false})
	return out

## How a finished branching quest turned out: the text of the first of its "endings" whose flag is on, else "".
static func outcome(d: GameStateData, q: Dictionary) -> String:
	for e in q.get("endings", []):
		if e is Dictionary and _on(d, str(e.get("flag", ""))):
			return str(e.get("text", ""))
	return ""

# --- consequences that arrive later ---------------------------------------------------------

## The value to keep in a flag when a choice is made: "<real date>@<day_count>@<play seconds>" (see DailyKey).
static func stamp(d: GameStateData) -> String:
	return DailyKey.stamp(d)

## Has the post come? True once `n` in-game days (a night's sleep is one) have passed since the flag was stamped, or the
## real date has changed since, so a player who comes back tomorrow always finds it. False for a flag never stamped.
static func later(d: GameStateData, key: String, n: int) -> bool:
	var v: Variant = d.flag(key)
	if typeof(v) != TYPE_STRING:
		return false
	var parts: PackedStringArray = str(v).split("@")
	if parts.size() < 2 or not parts[1].is_valid_int():
		return false
	return parts[0] != Calendar.today_key() or d.day_count - int(parts[1]) >= n

## The story condition later_<flag>_<n>: 1 when it has ripened, 0 when not yet, -1 when `cond` is not one.
static func later_cond(d: GameStateData, cond: String) -> int:
	var cut := cond.rfind("_")
	if not cond.begins_with("later_") or cut <= 6 or not cond.substr(cut + 1).is_valid_int():
		return -1
	return 1 if later(d, cond.substr(6, cut - 6), int(cond.substr(cut + 1))) else 0

static func active(d: GameStateData, list: Array = []) -> Array:
	return (list if not list.is_empty() else all()).filter(func(q): return status(d, q) == ACTIVE)

static func done(d: GameStateData, list: Array = []) -> Array:
	return (list if not list.is_empty() else all()).filter(func(q): return status(d, q) == DONE)

# --- news (the toasts) -----------------------------------------------------------------

## A quest's state, to compare before and after a scene sets its flags: {status, step}.
static func snapshot(d: GameStateData, q: Dictionary) -> Dictionary:
	return {"status": status(d, q), "step": step_index(d, q)}

## The toast for a quest going from `before` to `after` (snapshots): [header, title], or [] when nothing moved. Just
## the title: a toast is a nudge, the Journal has the rest.
## A scene that starts and finishes a quest at once, or ticks the last step and hands it in, is one toast.
static func change_news(q: Dictionary, before: Dictionary, after: Dictionary) -> Array:
	var title := str(q.get("title", ""))
	if after.status == DONE:
		return ["Quest complete", title] if before.status != DONE else []
	if after.status != ACTIVE:
		return []
	if before.status != ACTIVE:
		return ["New quest", title]
	if after.step != before.step:
		return ["Quest updated", title]
	return []

# --- where ------------------------------------------------------------------------------

## The world map zone for a quest step: a room's town, else the zone itself.
static func map_zone(zone: String, index: Dictionary) -> String:
	var t := str(index.get("room_town", {}).get(zone, ""))
	return t if t != "" else zone

static func _region(zone: String, index: Dictionary) -> String:
	return str(index.get("zones", {}).get(map_zone(zone, index), {}).get("region", ""))

## An active quest near `town`: one whose next step is in the town (or one of its rooms), else one given here, else
## one whose next step is in the same region. {} if none.
static func nearby(d: GameStateData, town: String, index: Dictionary, list: Array = []) -> Dictionary:
	if town == "":
		return {}
	var act := active(d, list)
	for q in act:
		if map_zone(str(current_step(d, q).get("zone", "")), index) == town:
			return q
	for q in act:
		if str(q.get("town", "")) == town:
			return q
	var region := _region(town, index)
	if region != "":
		for q in act:
			if _region(str(current_step(d, q).get("zone", "")), index) == region:
				return q
	return {}

## The pause card's line for a quest nearby, "Quest, <title>: <next step>", or "".
static func hint_line(d: GameStateData, town: String, index: Dictionary, list: Array = []) -> String:
	var q := nearby(d, town, index, list)
	if q.is_empty():
		return ""
	return "Quest, %s: %s" % [str(q.get("title", "")), str(current_step(d, q).get("text", ""))]

# --- the validator ------------------------------------------------------------------------

## Raw zone dictionaries by id (for settable_flags).
static func raw_zones() -> Dictionary:
	var out := {}
	for path in JsonUtil.list_json("res://data/zones"):
		var z = JsonUtil.read(path)
		if z is Dictionary:
			out[str(z.get("id", path.get_file().get_basename()))] = z
	return out

## Every flag the real game can set (see settable_flags), with the trainers' intros and the rewilding rewards.
static func all_settable() -> Dictionary:
	var extra := []
	for tid in StoryData.trainer_ids():
		extra.append(StoryData.trainer(tid).get("intro", []))
	var rw = JsonUtil.read("res://data/rewild.json")
	if rw is Dictionary:
		for s in rw.get("sites", []):
			for r in s.get("rewards", []):
				if r is Array:
					extra.append(r)
	extra.append(Errands.settable_commands())  # w47 C: errand flags are set in code
	return settable_flags(StoryData.all_dialogue(), raw_zones(), extra)

## Flags something in the data sets: `set`, a choice's or relearn's or quiz's `set`, a legend's or gauntlet's
## `flag`, a daily `key`, "trainer_<id>" for every battle and trainer NPC, "badge_<id>", and "plaque_<id>" for
## every Gazetteer plaque and every examine spot's flag. `dialogue` is file -> {script -> commands}, `zones` id -> raw zone, `extra` more
## command lists.
static func settable_flags(dialogue: Dictionary, zones: Dictionary, extra: Array = []) -> Dictionary:
	var out := {}
	var lists: Array = extra.duplicate()
	for file in dialogue:
		for sid in dialogue[file]:
			if dialogue[file][sid] is Array:
				lists.append(dialogue[file][sid])
	for zid in zones:
		for n in zones[zid].get("npcs", []):
			if str(n.get("trainer", "")) != "":
				out["trainer_" + str(n.trainer)] = true
		for e in zones[zid].get("examine", []):
			if str(e.get("flag", "")) != "":  # a look-closer spot sets its flag once (see Examine.read)
				out[str(e.flag)] = true
		for s in zones[zid].get("signs", []):
			if str(s.get("plaque", "")) != "":
				out[Gazetteer.flag_key(str(s.plaque))] = true
	while not lists.is_empty():
		for c in lists.pop_back():
			if not (c is Dictionary):
				continue
			match str(c.get("do", "")):
				"set", "legend", "gauntlet":
					if str(c.get("flag", "")) != "":
						out[str(c.flag)] = true
				"daily":
					out[str(c.get("key", ""))] = true
				"battle":
					out["trainer_" + str(c.get("trainer", ""))] = true
				"badge":
					out["badge_" + str(c.get("id", ""))] = true
			if c.has("set") and str(c.get("do", "")) != "set":
				out[str(c.set)] = true
			for k in ["then", "else"]:
				if c.get(k) is Array:
					lists.append(c[k])
	return out

## Problems with a quest list: ids unique, the fields there, zones real, flags non-empty, in the region's q_
## namespace and set by something somewhere (`settable`, see settable_flags).
static func validate(list: Array, zones: Dictionary, settable: Dictionary) -> Array:
	var errors := []
	var ids := {}
	for q in list:
		var id := str(q.get("id", ""))
		var tag := "quest %s/%s" % [str(q.get("_file", "?")), id if id != "" else "?"]
		if id == "":
			errors.append(tag + ": no id")
		elif ids.has(id):
			errors.append(tag + ": duplicate quest id '%s'" % id)
		ids[id] = true
		for k in ["title", "region", "giver", "summary"]:
			if str(q.get(k, "")) == "":
				errors.append(tag + ": no %s" % k)
		if str(q.get("reward", "")) == "":
			errors.append(tag + ": no reward")
		for e in q.get("endings", []):
			if not (e is Dictionary) or str(e.get("text", "")) == "" or str(e.get("flag", "")) == "":
				errors.append(tag + ": an ending needs a flag and a text")
			elif not settable.has(str(e.flag)):
				errors.append(tag + ": ending flag '%s' is never set by any script" % e.flag)
		var town := str(q.get("town", ""))
		if not zones.has(town):
			errors.append(tag + ": town is unknown zone '%s'" % town)
		var steps: Array = q.get("steps", [])
		if steps.is_empty():
			errors.append(tag + ": no steps")
		var ns := FLAG_PREFIX + str(q.get("region", "")) + "_"
		var flags := [["start_flag", str(q.get("start_flag", ""))], ["done_flag", str(q.get("done_flag", ""))]]
		for i in steps.size():
			var s = steps[i]
			if not (s is Dictionary):
				errors.append(tag + ": step %d is not an object" % (i + 1))
				continue
			if str(s.get("text", "")) == "":
				errors.append(tag + ": step %d has no text" % (i + 1))
			if not zones.has(str(s.get("zone", ""))):
				errors.append(tag + ": step %d is in unknown zone '%s'" % [i + 1, s.get("zone", "")])
			if str(s.get("flag", "")) == "":
				errors.append(tag + ": step %d has no flag" % (i + 1))
			else:
				flags.append(["step %d flag" % (i + 1), str(s.flag)])
		for f in flags:
			if f[1] == "":
				errors.append(tag + ": no %s" % f[0])
				continue
			# a step may be ticked by a plaque or a trainer win; the quest's own flags live in its region's namespace
			if f[0] in ["start_flag", "done_flag"] and not f[1].begins_with(ns) and not f[1].begins_with(FLAG_PREFIX + str(q.get("region", "")).replace("_", "") + "_"):
				errors.append(tag + ": %s '%s' should start %s" % [f[0], f[1], ns])
			if not settable.has(f[1]):
				errors.append(tag + ": %s '%s' is never set by any script, trainer or plaque" % [f[0], f[1]])
	return errors
