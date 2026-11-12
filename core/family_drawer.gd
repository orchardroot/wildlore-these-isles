class_name FamilyDrawer
extends RefCounted
## One drawer per home that always holds that household's own thing (wave 53): a photograph, a letter, a keepsake or a
## curio. data/family_drawers.json: {zone: {kind, in, lines: [..], curio?}}. `in` is the furniture the thing is kept in
## (the first of that type, reading order, that no examine spot sits on; any other searchable piece if the room has none
## of that type). It is found once, flag drawer_<zone> (absent = not found, so old saves simply have it still to find),
## before the furniture's ordinary lottery, whatever the week. Pure logic, no autoload names.

const FILE := "res://data/family_drawers.json"
const FLAG_PREFIX := "drawer_"

static var _all: Dictionary = {}
static var _loaded := false

static func all() -> Dictionary:
	if not _loaded:
		_loaded = true
		var d: Variant = JsonUtil.read(FILE)
		_all = d if d is Dictionary else {}
	return _all

static func entry(zone_id: String) -> Dictionary:
	return all().get(zone_id, {})

static func flag_key(zone_id: String) -> String:
	return FLAG_PREFIX + zone_id

static func found(data: GameStateData, zone_id: String) -> bool:
	return ZoneData.flag_on(data.flag(flag_key(zone_id)))

## The piece of furniture that holds this home's drawer ({} if the room has nothing searchable).
static func prop_for(zone: ZoneData) -> Dictionary:
	var e := entry(String(zone.id))
	if e.is_empty():
		return {}
	var want := str(e.get("in", ""))
	var spare := []
	for p in zone.props:
		if str(p.get("type", "")) in Search.TYPES and zone.examine_at(Vector2i(int(p.x), int(p.y))).is_empty():
			spare.append(p)
	spare.sort_custom(func(a, b): return [int(a.y), int(a.x)] < [int(b.y), int(b.x)])
	for p in spare:
		if str(p.type) == want:
			return p
	return spare[0] if not spare.is_empty() else {}

## Whether `prop` is this home's drawer and it has not been found.
static func is_drawer(zone: ZoneData, prop: Dictionary, data: GameStateData) -> bool:
	if zone.kind != "interior" or found(data, String(zone.id)):
		return false
	var p := prop_for(zone)
	return not p.is_empty() and int(p.x) == int(prop.get("x", -1)) and int(p.y) == int(prop.get("y", -2))

## Opens the drawer: marks it found, gives the curio if it holds one. Same result shape as Search.take.
static func take(zone: ZoneData, data: GameStateData, items) -> Dictionary:
	var e := entry(String(zone.id))
	data.set_flag(flag_key(String(zone.id)), true)
	TrainerStats.add(data, "drawers_found")
	var lines: Array = []
	for l in e.get("lines", []):
		lines.append(str(l))
	var curio := false
	var id := str(e.get("curio", ""))
	if id != "":
		curio = true
		data.bag[id] = mini(Bag.MAX_STACK, int(data.bag.get(id, 0)) + 1)
		var first := not ZoneData.flag_on(data.flag(Search.FOUND_PREFIX + id))
		data.set_flag(Search.FOUND_PREFIX + id, true)
		TrainerStats.add(data, "curios_found")
		var it: Dictionary = items.get_item(id) if items != null and items.has(id) else {}
		lines.append("You take %s with you." % str(it.get("one", it.get("name", id))))
		if first:
			lines.append("A new one for the Curios page.")
	return {"lines": lines, "gave": curio, "curio": curio, "rare": false, "again": false}

## How many homes' drawers have been found.
static func found_count(data: GameStateData) -> int:
	var n := 0
	for z in all():
		if found(data, str(z)):
			n += 1
	return n

## Validator: a real home, lines present and clean, `in` a searchable type, a real curio.
static func check(zones: Dictionary, items: ItemDB) -> Array:
	var errors := []
	for zid in all():
		var tag := "family drawer %s" % zid
		var e: Dictionary = all()[zid]
		if not zones.has(zid) or zones[zid].kind != "interior":
			errors.append(tag + ": not an interior zone")
			continue
		var lines: Array = e.get("lines", [])
		if lines.is_empty():
			errors.append(tag + ": no lines")
		for l in lines:
			if str(l) == "" or str(l).contains("—"):
				errors.append(tag + ": an empty line or an em-dash")
		if str(e.get("in", "")) != "" and str(e.in) not in Search.TYPES:
			errors.append(tag + ": 'in' is not searchable furniture")
		if str(e.get("curio", "")) != "" and not items.has(str(e.curio)):
			errors.append(tag + ": unknown curio '%s'" % e.curio)
	return errors
