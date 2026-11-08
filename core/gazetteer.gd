class_name Gazetteer
extends RefCounted
## The Gazetteer: heritage plaques round the isles. A zone `signs` entry with "plaque": "<id>" and a "title" is a
## plaque (a lectern by a landmark, or the round blue plaque on a wall). Reading one the first time records it in
## the flag plaque_<id> (nothing else, so old saves are fine) and every milestone passed pays out once (a flag
## each, gazetteer_<n>): something useful, a title for the Gazetteer's header and, at fifty, a postcard from Kit.
## The Gazetteer itself is a tab of the Journal (ui/gazetteer_tab.gd). Pure logic, no autoload names.

const PREFIX := "plaque_"
const ZONE_DIR := "res://data/zones"
## n = plaques read; -1 means every plaque in the game. Paid in order, once each.
const MILESTONES := [
	{"n": 10, "flag": "gazetteer_10", "title": "Curious Visitor", "money": 0, "items": {"flask_of_tea": 2}},
	{"n": 25, "flag": "gazetteer_25", "title": "Keen Rambler", "money": 1500, "items": {"kendal_mint_cake": 1}},
	{"n": 50, "flag": "gazetteer_50", "title": "Local Historian", "money": 0, "items": {"silver_snare": 3}},
	{"n": 100, "flag": "gazetteer_100", "title": "Blue Badge Guide", "money": 5000, "items": {"cream_tea": 2}},
	{"n": -1, "flag": "gazetteer_all", "title": "Keeper of the Gazetteer", "money": 10000, "items": {"brass_rubbing": 1}},
]

static var _cache: Array = []

## Every plaque in the game (zone files in name order, signs in order). See build().
static func all() -> Array:
	if _cache.is_empty():
		var zones := []
		for path in JsonUtil.list_json(ZONE_DIR):
			var z = JsonUtil.read(path)
			if z is Dictionary:
				zones.append(z)
		_cache = build(zones, ZoneIndex.get_index())
	return _cache

static func reset() -> void:
	_cache = []

## [{id, title, text, zone, x, y, town, town_name, nation}] from raw zone dictionaries. A plaque in a room belongs
## to its town (`index.room_town`, see ZoneIndex); one on a route is filed under the route.
static func build(zones: Array, index: Dictionary) -> Array:
	var names := {}
	for z in zones:
		names[str(z.get("id", ""))] = str(z.get("name", z.get("id", "")))
	var out := []
	for z in zones:
		var zid := str(z.get("id", ""))
		if str(z.get("region", "")) == "dev":
			continue
		for s in z.get("signs", []):
			var id := str(s.get("plaque", "")) if s is Dictionary else ""
			if id == "":
				continue
			var town := str(index.get("room_town", {}).get(zid, ""))
			if town == "":
				town = zid
			out.append({"id": id, "title": str(s.get("title", "")), "text": str(s.get("text", "")), "zone": zid,
				"x": int(s.get("x", 0)), "y": int(s.get("y", 0)), "town": town, "town_name": str(names.get(town, town.capitalize())),
				"nation": Standing.nation_for_zone(town), "people": str(s.get("people", "")),  # people: a These Isles theme
				"theme": str(s.get("theme", ""))})  # "arts": Poets' Corner (4.5)
	return out

static func flag_key(id: String) -> String:
	return PREFIX + id

static func is_read(d: GameStateData, id: String) -> bool:
	return d.flag(flag_key(id)) == true

## Plaques read that are still in the game.
static func count(d: GameStateData, list: Array = []) -> int:
	return (list if not list.is_empty() else all()).filter(func(p): return is_read(d, str(p.id))).size()

static func _target(m: Dictionary, total: int) -> int:
	return total if int(m.n) < 0 else int(m.n)

## Reads plaque `id`: records it the first time, then pays any milestone passed and not yet paid (an old save that
## read plenty before the Gazetteer existed catches up here). {new: bool, milestones: [milestone]}.
static func record(d: GameStateData, id: String, list: Array = [], milestones: Array = []) -> Dictionary:
	var l := list if not list.is_empty() else all()
	var ms := milestones if not milestones.is_empty() else MILESTONES
	var fresh := not is_read(d, id)
	if fresh:
		d.set_flag(flag_key(id), true)
	var paid := []
	var n := count(d, l)
	for m in ms:
		if d.flag(str(m.flag)) != true and n >= _target(m, l.size()):
			d.set_flag(str(m.flag), true)
			d.money += int(m.get("money", 0))
			var bag := Bag.new(d.bag)
			for it in m.get("items", {}):
				bag.add(str(it), int(m.items[it]))
			paid.append(m)
	return {"new": fresh, "milestones": paid}

## The title of the best milestone reached ("" before the first).
static func title(d: GameStateData, milestones: Array = []) -> String:
	var t := ""
	for m in (milestones if not milestones.is_empty() else MILESTONES):
		if d.flag(str(m.flag)) == true:
			t = str(m.title)
	return t

## The next milestone not yet paid, or {}.
static func next_milestone(d: GameStateData, list: Array = [], milestones: Array = []) -> Dictionary:
	for m in (milestones if not milestones.is_empty() else MILESTONES):
		if d.flag(str(m.flag)) != true:
			var c: Dictionary = m.duplicate()
			c["target"] = _target(m, (list if not list.is_empty() else all()).size())
			return c
	return {}

## "£1,500 and 1 Kendal Mint Cake".
static func reward_text(m: Dictionary, items: ItemDB) -> String:
	var bits := []
	if int(m.get("money", 0)) > 0:
		bits.append(Wallet.fmt(int(m.money)))
	for id in m.get("items", {}):
		var nm := str(items.get_item(str(id)).get("name", str(id).capitalize())) if items != null else str(id)
		bits.append("%d %s" % [int(m.items[id]), nm])
	if bits.is_empty():
		return ""
	return bits[0] if bits.size() == 1 else ", ".join(bits.slice(0, bits.size() - 1)) + " and " + str(bits.back())

## The Stats page line: "37 of 240", or "None yet".
static func stats_line(d: GameStateData, list: Array = []) -> String:
	var l := list if not list.is_empty() else all()
	var n := count(d, l)
	return "None yet" if n == 0 else "%d of %d" % [n, l.size()]

## Problems with the plaques: ids unique across the game, a title and some text, no em-dashes.
static func validate(list: Array) -> Array:
	var errors := []
	var seen := {}
	for p in list:
		var tag := "zone %s: plaque '%s' at %d,%d" % [str(p.zone), str(p.id), int(p.x), int(p.y)]
		if seen.has(p.id):
			errors.append(tag + " has the same id as one in %s" % str(seen[p.id]))
		seen[p.id] = p.zone
		if str(p.title).strip_edges() == "" or str(p.text).strip_edges() == "":
			errors.append(tag + " needs a title and some text")
		if "\u2014" in str(p.text) + str(p.title):
			errors.append(tag + " has an em-dash")
	return errors

const NATION_ORDER := ["england", "wales", "scotland", "northern_ireland", "ireland", "mann", "overseas", "channel_islands", "abroad"]

## [{nation, name, read, total, towns: [{town, name, read, total, plaques: [plaque]}]}]: nations in the game's
## usual order, places by name, plaques in the order they stand in their zones.
static func grouped(d: GameStateData, list: Array = []) -> Array:
	var by := {}
	for p in (list if not list.is_empty() else all()):
		var n := str(p.nation)
		if not by.has(n):
			by[n] = {"nation": n, "name": Standing.name_of(n), "read": 0, "total": 0, "towns": {}}
		var t: Dictionary = by[n].towns
		if not t.has(p.town):
			t[p.town] = {"town": str(p.town), "name": str(p.town_name), "read": 0, "total": 0, "plaques": []}
		var r := 1 if is_read(d, str(p.id)) else 0
		t[p.town].plaques.append(p)
		t[p.town].total += 1
		t[p.town].read += r
		by[n].total += 1
		by[n].read += r
	var out := []
	var order := NATION_ORDER.duplicate()
	for n in by:
		if n not in order:
			order.append(n)
	for n in order:
		if not by.has(n):
			continue
		var e: Dictionary = by[n]
		var towns: Array = e.towns.values()
		towns.sort_custom(func(a, b): return str(a.name) < str(b.name))
		e["towns"] = towns
		out.append(e)
	return out
