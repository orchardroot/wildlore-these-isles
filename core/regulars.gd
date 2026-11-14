class_name Regulars
extends RefCounted
## The Regulars (data/regulars.json): twelve recurring characters who remember you. Each lives in a home town and
## turns up again in a second town once you've got to know them. Favour runs 0 to 5 and is earned with a gift they
## like (one a day, see GIFT_PTS): 0 is a stranger, 1 you've met, 2 they turn up in another town, 3 they write to you
## through the post box, 4 they offer to manage one of your Deeds (see Deeds.set_manager), 5 a lifelong friend.
## State lives in the flag `reg_<id>` = {favour, pts, gift_day, meet, letter, manager}; a save without it means
## strangers, so old saves are fine. Nothing here touches money. Pure logic, no autoloads.
## A Regular is either spawned (x, y in the `home` town) or BOUND to a home resident (`zone` and `npc`): then no NPC is
## added, and `hook` (one line in ScriptHooks.wrap) appends the Regular's scenes to what that resident already says.

const PATH := "res://data/regulars.json"
const PREFIX := "reg_"
const SCRIPT_FILE := "regulars"   # data/dialogue/regulars.json, script regular_<id>
const MAX_FAVOUR := 5
## Gifts (points) needed in all to reach favour 2, 3, 4 and 5. Favour 1 is just meeting them.
const GIFTS_FOR := {2: 1, 3: 3, 4: 5, 5: 8}
## At favour 5 a Regular comes to Mum's (zone MUMS_ZONE, spot MUMS_SPOT, nudged to a free tile), one at a time, the
## one who got there first. State: `five_day` (the day favour hit 5; absent on an old save = day 0) and `mums` (seen).
const MUMS_ZONE := "macc_home"
const MUMS_SPOT := Vector2i(6, 5)

static var _regs: Array = []
static var _bound: Dictionary = {}   # "zone/npc" -> regular id, built on first use

static func all() -> Array:
	if _regs.is_empty():
		var d = JsonUtil.read(PATH)
		_regs = d.get("regulars", []) if d is Dictionary else []
	return _regs

static func ids() -> Array:
	return all().map(func(r): return str(r.id))

## The Regular who is this resident, or "" (a bound Regular, see the header).
static func bound_id(zone_id: String, npc_id: String) -> String:
	if _bound.is_empty():
		for r in all():
			if str(r.get("zone", "")) != "":
				_bound[str(r.zone) + "/" + str(r.get("npc", ""))] = str(r.id)
		_bound["_"] = ""
	return str(_bound.get(zone_id + "/" + npc_id, ""))

## What lines and prompts call them: `short` if given ("Old Tom", "Mrs Hale"), else the first name.
static func short_name(r: Dictionary) -> String:
	return str(r.get("short", str(r.get("name", "")).split(" ")[0]))

static func is_bound(r: Dictionary) -> bool:
	return str(r.get("zone", "")) != ""

static func get_reg(id: String) -> Dictionary:
	for r in all():
		if str(r.id) == id:
			return r
	return {}

static func flag_key(id: String) -> String:
	return PREFIX + id

static func _peek(data: GameStateData, id: String) -> Dictionary:
	var v: Variant = data.flag(flag_key(id))
	return v if v is Dictionary else {}

static func _st(data: GameStateData, id: String) -> Dictionary:
	var v: Variant = data.flag(flag_key(id))
	if not (v is Dictionary):
		v = {}
		data.set_flag(flag_key(id), v)
	return v

static func favour(data: GameStateData, id: String) -> int:
	return clampi(int(_peek(data, id).get("favour", 0)), 0, MAX_FAVOUR)

static func met(data: GameStateData, id: String) -> bool:
	return favour(data, id) >= 1

static func points(data: GameStateData, id: String) -> int:
	return int(_peek(data, id).get("pts", 0))

static func liked_item(id: String) -> String:
	return str(get_reg(id).get("likes", ""))

## Gifts still needed for the next favour level, or 0 at the top.
static func gifts_to_next(data: GameStateData, id: String) -> int:
	var f := favour(data, id)
	if f < 1 or f >= MAX_FAVOUR:
		return 0
	return maxi(0, int(GIFTS_FOR[f + 1]) - points(data, id))

## Can they be handed their favourite today? Met, not at the top, nothing given yet today, and it's in the bag.
static func can_gift(data: GameStateData, id: String) -> bool:
	var f := favour(data, id)
	if f < 1 or f >= MAX_FAVOUR or liked_item(id) == "":
		return false
	if int(_peek(data, id).get("gift_day", -1)) == data.day_count:
		return false
	return int(data.bag.get(liked_item(id), 0)) > 0

## Hand over the favourite: takes it from the bag, adds a point, and returns the new favour (or -1 if they can't).
static func give_gift(data: GameStateData, id: String) -> int:
	if not can_gift(data, id):
		return -1
	var item := liked_item(id)
	var left := int(data.bag.get(item, 0)) - 1
	if left <= 0:
		data.bag.erase(item)
	else:
		data.bag[item] = left
	var st := _st(data, id)
	st["pts"] = int(st.get("pts", 0)) + 1
	st["gift_day"] = data.day_count
	for lv in range(MAX_FAVOUR, 1, -1):
		if int(st.pts) >= int(GIFTS_FOR[lv]):
			if lv == MAX_FAVOUR and int(st.get("favour", 0)) < MAX_FAVOUR:
				st["five_day"] = data.day_count
			st["favour"] = maxi(int(st.get("favour", 0)), lv)
			break
	return favour(data, id)

## Which scene is waiting for you here: "intro" (first time, home), "meet" (favour 2, in their second town),
## "offer" (favour 4, home, with a Deed that has a free manager slot) or "".
static func next_beat(data: GameStateData, id: String, zone_id: String) -> String:
	var r := get_reg(id)
	if r.is_empty():
		return ""
	var st := _peek(data, id)
	var f := favour(data, id)
	if zone_id == MUMS_ZONE:
		return "mums" if mums_visitor(data) == id else ""
	if zone_id == str(r.home) or (is_bound(r) and zone_id == str(r.zone)):
		if f < 1:
			return "intro"
		if f >= 4 and str(st.get("manager", "")) == "" and not eligible_deeds(data).is_empty():
			return "offer"
	elif zone_id == str(r.away) and f >= 2 and st.get("meet") != true:
		return "meet"
	return ""

## Who is waiting at Mum's: the Regular at favour 5 who got there first and hasn't had their scene, or "".
static func mums_visitor(data: GameStateData, list: Array = []) -> String:
	var best := ""
	var best_day := 0
	for r in (list if not list.is_empty() else all()):
		var id := str(r.id)
		if favour(data, id) < MAX_FAVOUR or _peek(data, id).get("mums") == true:
			continue
		var d := int(_peek(data, id).get("five_day", 0))
		if best == "" or d < best_day:
			best = id
			best_day = d
	return best

## The scene's been played.
static func complete(data: GameStateData, id: String, beat: String) -> void:
	var st := _st(data, id)
	match beat:
		"intro":
			st["favour"] = maxi(1, int(st.get("favour", 0)))
		"meet":
			st["meet"] = true
		"mums":
			st["mums"] = true

## NPC definitions for the regulars standing in this zone: each at home, and in their second town while the
## meeting is waiting. Positions (x, y at home, ax, ay away) are nudged to a free tile by the overworld, like side stories.
static func npcs_for(zone_id: String, data: GameStateData, list: Array = []) -> Array:
	var out := []
	if zone_id == MUMS_ZONE:
		var v := get_reg(mums_visitor(data, list))
		if not v.is_empty():
			out.append({"id": "reg_" + str(v.id) + "_mums", "sprite": str(v.get("sprite", "villager_1")), "name": str(v.get("name", "")),
				"x": MUMS_SPOT.x, "y": MUMS_SPOT.y, "facing": "left", "move": "still", "script": "regular_" + str(v.id), "script_file": SCRIPT_FILE})
		return out
	for r in (list if not list.is_empty() else all()):
		var id := str(r.id)
		var here: bool = str(r.get("home", "")) == zone_id and not is_bound(r)  # a bound Regular is already standing there
		var away: bool = str(r.get("away", "")) == zone_id and favour(data, id) >= 2 and _peek(data, id).get("meet") != true
		if not (here or away):
			continue
		out.append({"id": "reg_" + id + ("" if here else "_away"), "sprite": str(r.get("sprite", "villager_1")),
			"name": str(r.get("name", "")), "x": int(r.get("x" if here else "ax", 0)), "y": int(r.get("y" if here else "ay", 0)), "facing": "down",
			"move": "still", "script": "regular_" + id, "script_file": SCRIPT_FILE})
	return out

## ScriptHooks entry: a resident who is a Regular says their usual lines, then the Regular scene (story/regular_talk.gd).
static func hook(zone_id: String, npc_id: String, commands: Array, _data: GameStateData) -> Array:
	var id := bound_id(zone_id, npc_id)
	if id == "":
		return commands
	return commands + [{"do": "regular", "id": id, "bound": true}]

## Chat for a visit with nothing else on: rotates by day, and moves on from the "stranger" lines as favour grows.
static func chat_line(data: GameStateData, id: String) -> String:
	var lines: Array = get_reg(id).get("chat", [])
	return "" if lines.is_empty() else str(lines[posmod(data.day_count + favour(data, id), lines.size())])

## Letters waiting at the post box: one from each regular at favour 3 or more who hasn't been read.
static func letters_waiting(data: GameStateData) -> Array:
	var out := []
	for id in ids():
		if favour(data, id) >= 3 and _peek(data, id).get("letter") != true:
			out.append(id)
	return out

## Take the post: marks each letter read and returns the regular ids.
static func collect_letters(data: GameStateData) -> Array:
	var got := letters_waiting(data)
	for id in got:
		_st(data, id)["letter"] = true
	return got

static func letter_lines(id: String, player: String) -> Array:
	var r := get_reg(id)
	if r.is_empty():
		return []
	var out := ["A letter from %s." % str(r.name)]
	for t in r.get("letter", []):
		out.append(str(t).replace("{player}", player))
	return out

## Problems with the Regulars file: real zones, real NPCs (or a walkable away tile), real items, unique ids and residents.
static func problems(zones: Dictionary, items: ItemDB) -> Array:
	var errs := []
	var seen := {}
	var spots := {}
	for r in all():
		var id := str(r.get("id", ""))
		var tag := "regular '%s'" % id
		if id == "" or seen.has(id):
			errs.append("%s: missing or duplicate id" % tag)
		seen[id] = true
		if not items.has(str(r.get("likes", ""))):
			errs.append("%s: likes '%s' is not an item" % [tag, r.get("likes", "")])
		for k in ["name", "sprite", "hint"]:
			if str(r.get(k, "")).strip_edges() == "":
				errs.append("%s: no %s" % [tag, k])
		for k in ["intro", "meet", "letter", "offer", "thanks", "chat", "mums"]:
			if not (r.get(k, []) is Array) or (r.get(k, []) as Array).is_empty():
				errs.append("%s: no %s lines" % [tag, k])
		for l in r.get("mums", []) if r.get("mums", []) is Array else []:
			if not (l is String) or str(l).strip_edges() == "":
				errs.append("%s: a mums line is not text" % tag)
		if "—" in JSON.stringify(r):
			errs.append("%s: has an em-dash" % tag)
		var home: ZoneData = zones.get(str(r.get("home", "")))
		var away: ZoneData = zones.get(str(r.get("away", "")))
		if home == null:
			errs.append("%s: home '%s' is not a zone" % [tag, r.get("home", "")])
		if away == null:
			errs.append("%s: away '%s' is not a zone" % [tag, r.get("away", "")])
		elif str(r.away) == str(r.get("home", "")):
			errs.append("%s: away is the home town" % tag)
		elif not away.in_bounds(Vector2i(int(r.get("ax", -1)), int(r.get("ay", -1)))):
			errs.append("%s: away tile is off the map" % tag)
		if is_bound(r):
			var z: ZoneData = zones.get(str(r.zone))
			if z == null:
				errs.append("%s: zone '%s' is not a zone" % [tag, r.zone])
			elif not z.npcs.any(func(n): return str(n.get("id", "")) == str(r.get("npc", ""))):
				errs.append("%s: zone %s has no npc '%s'" % [tag, r.zone, r.get("npc", "")])
			if spots.has(str(r.zone) + "/" + str(r.get("npc", ""))):
				errs.append("%s: that resident is already a Regular" % tag)
			spots[str(r.zone) + "/" + str(r.get("npc", ""))] = true
		elif home != null and not home.in_bounds(Vector2i(int(r.get("x", -1)), int(r.get("y", -1)))):
			errs.append("%s: spawn tile (%s, %s) is off the map" % [tag, r.get("x", "?"), r.get("y", "?")])  # the overworld nudges it to a free tile
	return errs

# --- the manager hook (Deeds is session A's) ---------------------------------------------------------------

static func _deed_id(e: Variant) -> String:
	return str(e.get("id", "")) if e is Dictionary else str(e)

## Owned Deeds with a manager slot that nobody is managing yet.
static func eligible_deeds(data: GameStateData) -> Array:
	var out := []
	for e in Deeds.owned(data):
		var did := _deed_id(e)
		var st: Variant = data.flag("deed_" + did)
		if did == "" or not Deeds.get_deed(did).get("manager_slot", false):
			continue
		if st is Dictionary and str(st.get("manager", "")) != "":
			continue
		out.append(did)
	return out

static func manager_of(data: GameStateData, id: String) -> String:
	return str(_peek(data, id).get("manager", ""))

## They take the job: records it and tells the Deed. False if that Deed isn't free or they're already busy.
static func appoint(data: GameStateData, id: String, deed_id: String) -> bool:
	if favour(data, id) < 4 or manager_of(data, id) != "" or deed_id not in eligible_deeds(data):
		return false
	Deeds.set_manager(data, deed_id, id)
	_st(data, id)["manager"] = deed_id
	return true

## They stop managing (the Deed lets them go, see Deeds.release_manager): free to be asked again.
static func release(data: GameStateData, id: String) -> void:
	if id != "" and data.flag(flag_key(id)) is Dictionary:
		_st(data, id)["manager"] = ""
