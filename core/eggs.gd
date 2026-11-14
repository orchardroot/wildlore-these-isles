class_name Eggs
extends RefCounted
## Easter eggs (wave 56): a few small things nobody is told about. Each is a flag (absent = not found), none is needed for
## anything and none is named in a menu. Data: data/eggs.json, an array of {id, kind, flag, ...}; kinds:
##   spot    a tile in a zone you face and press confirm on (zone, x, y, lines, optional needs "cat_lead" with plain lines,
##           optional choice: a small riddle with an item for the right answer, optional done lines once solved)
##   step    walking about somewhere (grin: zones, phase, steps, needs "cat_lead")
##   phone   a phone box passed in the first hour after midnight (hour, reach)
##   bench   a bench sat on through a whole evening (zone, x, y, start_before, until)
##   mum     what Mum says about the cat's name (zone, npc, by_name)
##   bottle  a message in a bottle that answers another (bottle id, needs: the flag of the first)
##   title   the title screen's old key sequence (see feed)
## The scenes come back as Commands lists, so they test without a screen; world/eggs_scene.gd plays them. Pure logic:
## no autoload names (the validator loads this).

const PATH := "res://data/eggs.json"
const MAX_LINE := 150
## The classic cheat-code key sequence the title screen listens for: up up down down left right left right B A.
const CODE := [KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_RIGHT, KEY_B, KEY_A]
const PICK := "egg_pick"

static var _all: Array = []
static var _loaded := false

static func all() -> Array:
	if not _loaded:
		_loaded = true
		var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH)) if FileAccess.file_exists(PATH) else null
		if j is Array:
			_all = j
	return _all

static func of_kind(kind: String) -> Array:
	return all().filter(func(e): return str(e.get("kind", "")) == kind)

static func get_egg(id: String) -> Dictionary:
	for e in all():
		if str(e.get("id", "")) == id:
			return e
	return {}

static func found(data: GameStateData, e: Dictionary) -> bool:
	return data.flag(str(e.get("flag", ""))) == true

static func found_count(data: GameStateData) -> int:
	var n := 0
	for e in all():
		if str(e.get("flag", "")) != "" and found(data, e):
			n += 1
	return n

# --- the cat -----------------------------------------------------------------------------

## What the cat is called: her nickname, with her or at home, else the family's name for her.
static func cat_name(data: GameStateData) -> String:
	var i := FamilyCat.party_index(data)
	if i >= 0:
		return data.party[i].display_name()
	var h: Variant = data.flag(FamilyCat.HOME)
	if h is Dictionary and str(h.get("nickname", "")) != "":
		return str(h.nickname)
	return FamilyCat.DEFAULT_NAME

## "Schrödinger", "SCHRODINGER" and "schrodinger" are all the same name.
static func fold(name: String) -> String:
	return name.strip_edges().to_lower().replace("ö", "o").replace("ó", "o")

static func _fill(line: String, data: GameStateData) -> String:
	return line.replace("{cat}", cat_name(data)).replace("{name}", cat_name(data))

static func _say(lines: Array, data: GameStateData) -> Array:
	return lines.map(func(l): return {"do": "say", "who": "", "text": _fill(str(l), data)})

static func _tile(e: Dictionary) -> Vector2i:
	return Vector2i(int(e.get("x", -1)), int(e.get("y", -1)))

# --- spots -------------------------------------------------------------------------------

## What facing tile `p` in `zone_id` plays: a Commands list, or [] when it is not one of ours.
static func spot_script(data: GameStateData, zone_id: String, p: Vector2i) -> Array:
	for e in of_kind("spot"):
		if str(e.zone) == zone_id and _tile(e) == p:
			return _spot(data, e)
	return []

static func _spot(data: GameStateData, e: Dictionary) -> Array:
	if str(e.get("needs", "")) == "cat_lead" and not FamilyCat.is_lead(data):
		return _say(e.get("plain", []), data)
	if found(data, e) and e.has("done"):
		return _say(e.done, data)
	var out := _say(e.lines, data)
	var ch: Variant = e.get("choice")
	if not ch is Dictionary:
		return out + [{"do": "set", "flag": str(e.flag)}]
	out.append({"do": "choice", "text": str(ch.text), "options": ch.options, "set": PICK})
	var right: Array = _say(ch.right_lines, data)
	if str(ch.get("item", "")) != "":
		right.append({"do": "give_item", "item": str(ch.item), "n": 1})
	right.append({"do": "set", "flag": str(e.flag)})
	out.append({"do": "if", "flag": PICK, "eq": int(ch.right), "then": right, "else": _wrong(data, ch)})
	return out

## A wrong reading says why; the last option is "leave it", which says nothing.
static func _wrong(data: GameStateData, ch: Dictionary) -> Array:
	return [{"do": "if", "flag": PICK, "eq": ch.options.size() - 1, "then": [], "else": _say(ch.wrong_lines, data)}]

# --- steps: the grin, the phone ----------------------------------------------------------------

## What walking onto `p` plays. `props` is the zone's props, `minute` the local clock, `steps` the steps taken in this zone.
static func step_script(data: GameStateData, zone_id: String, p: Vector2i, props: Array, minute: int, steps: int) -> Array:
	for e in of_kind("step"):
		if not found(data, e) and (e.get("zones", []) as Array).has(zone_id) \
				and FamilyCat.is_lead(data) and GameClock.phase(minute) == str(e.phase) and steps >= int(e.steps):
			return _say(e.lines, data) + [{"do": "set", "flag": str(e.flag)}]
	for e in of_kind("phone"):
		if not found(data, e) and minute / 60 == int(e.hour) and near_phone_box(props, p, int(e.reach)):
			return _phone(data, e, minute)
	return []

static func near_phone_box(props: Array, p: Vector2i, reach: int) -> bool:
	for pr in props:
		if str(pr.get("type", "")) == "phone_box" and absi(int(pr.x) - p.x) <= reach and absi(int(pr.y) - p.y) <= reach:
			return true
	return false

## The speaking clock, an hour fast: "1:12" at twelve minutes past midnight.
static func clock_reading(minute: int) -> String:
	var m := GameClock.wrap(minute + 60)
	return "%d:%02d" % [m / 60, m % 60]

static func _phone(data: GameStateData, e: Dictionary, minute: int) -> Array:
	var ans: Array = _say(e.answer, data).map(func(c): return {"do": "say", "who": "", "text": str(c.text).replace("{time}", clock_reading(minute))})
	ans.append({"do": "set", "flag": str(e.flag)})
	return [{"do": "sfx", "id": "bike_bell"}] + _say(e.ring, data) + [
		{"do": "choice", "text": str(e.ask), "options": e.options, "set": PICK},
		{"do": "if", "flag": PICK, "eq": 0, "then": ans, "else": []}]

# --- the bench ---------------------------------------------------------------------------

## Stood up from a bench: a whole evening sat out (down before `start_before`, up after `until`) brings someone along.
static func bench_script(data: GameStateData, zone_id: String, bench: Vector2i, start_min: int, end_min: int) -> Array:
	for e in of_kind("bench"):
		if str(e.zone) == zone_id and _tile(e) == bench and not found(data, e) \
				and start_min < int(e.start_before) and start_min >= int(e.get("from", 0)) and end_min >= int(e.until):
			return _say(e.lines, data) + [{"do": "set", "flag": str(e.flag)}]
	return []

# --- Mum, bottles, the title ---------------------------------------------------------------

## ScriptHooks: once, Mum says what she thinks of the cat's name (only after the first morning's errands are done).
static func hook(zone_id: String, npc_id: String, commands: Array, data: GameStateData) -> Array:
	if data.flag("mum_recipes") != true or not FamilyCat.has(data):
		return commands
	for e in of_kind("mum"):
		if str(e.zone) == zone_id and str(e.npc) == npc_id and not found(data, e):
			var lines: Variant = e.by_name.get(fold(cat_name(data)))
			if lines is Array:
				return _say(lines, data).map(func(c): c["who"] = "Mum"; return c) + [{"do": "set", "flag": str(e.flag)}] + commands
	return commands

## Extra lines on a bottle that answers one found before; sets its flag. [] for any other find.
static func bottle_lines(data: GameStateData, flotsam_id: String) -> Array:
	for e in of_kind("bottle"):
		if str(e.bottle) == flotsam_id and data.flag(str(e.needs)) == true:
			data.set_flag(str(e.flag), true)
			return e.lines.duplicate()
	return []

## The title screen's sequence: the new progress after `key` (CODE.size() means it is complete).
static func feed(progress: int, key: int) -> int:
	if progress < CODE.size() and key == CODE[progress]:
		return progress + 1
	if progress == 2 and key == CODE[1]:
		return 2  # up up up: the last two still open up up down
	return 1 if key == CODE[0] else 0

# --- validator ---------------------------------------------------------------------------

static func check(zones: Dictionary, items: ItemDB, flotsam_ids: Array, list := all()) -> Array:
	var errs := []
	var ids := {}
	var flags := {}
	for e in list:
		var id := str(e.get("id", ""))
		if id == "" or ids.has(id):
			errs.append("egg '%s': missing or duplicate id" % id)
		ids[id] = true
		var fl := str(e.get("flag", ""))
		if str(e.get("kind", "")) != "title" and (not fl.begins_with("egg_") or flags.has(fl)):
			errs.append("egg %s: flag must be a unique egg_ name" % id)
		flags[fl] = true
		var zs: Array = e.get("zones", [e.get("zone", "")]) if e.has("zones") or e.has("zone") else []
		for z in zs:
			if not zones.has(str(z)):
				errs.append("egg %s: zone '%s' does not exist" % [id, z])
		if str(e.get("kind", "")) in ["spot", "bench"] and zones.has(str(e.zone)):
			var zd: ZoneData = zones[str(e.zone)]
			if not zd.in_bounds(_tile(e)):
				errs.append("egg %s: tile is out of bounds" % id)
			elif str(e.kind) == "spot" and not zd.warp_at(_tile(e)).is_empty():
				errs.append("egg %s: tile is on a warp" % id)
		if str(e.get("kind", "")) == "bottle" and str(e.bottle) not in flotsam_ids:
			errs.append("egg %s: bottle '%s' is not a flotsam find" % [id, e.bottle])
		var ch: Variant = e.get("choice")
		if ch is Dictionary and str(ch.get("item", "")) != "" and not items.has(str(ch.item)):
			errs.append("egg %s: item '%s' does not exist" % [id, ch.item])
		for l in _all_lines(e):
			if str(l) == "" or "—" in str(l) or "–" in str(l) or str(l).length() > MAX_LINE:
				errs.append("egg %s: a line is empty, has a dash or is over %d characters: %s" % [id, MAX_LINE, str(l).left(40)])
	return errs

static func _all_lines(e: Dictionary) -> Array:
	var out := []
	for k in ["lines", "plain", "done", "ring", "answer"]:
		out.append_array(e.get(k, []))
	var ch: Variant = e.get("choice")
	if ch is Dictionary:
		for k in ["right_lines", "wrong_lines", "options"]:
			out.append_array(ch.get(k, []))
		out.append(ch.get("text", ""))
	for n in e.get("by_name", {}):
		out.append_array(e.by_name[n])
	return out
