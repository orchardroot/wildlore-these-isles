class_name ZoneIndex
extends RefCounted
## A small digest of every zone file, built once a session: who lives where (and when), which region each
## zone belongs to, which regions touch, where each zone sits on the world map, and which rooms belong to
## which town. The Rumours tab, the Fieldbook's region stamps and the Visitor's Book all read it.
## Pure data (no autoload names): build() takes the raw zone dictionaries, so tests can feed in fixtures.

const ZONE_DIR := "res://data/zones"
const MAP_PATH := "res://data/world_map.json"
const FERRIES_PATH := "res://data/ferries.json"
const SKIP_REGIONS := ["dev"]

static var _cached: Dictionary = {}

## The real game's index (loaded on first use).
static func get_index() -> Dictionary:
	if _cached.is_empty():
		var zones := []
		for path in JsonUtil.list_json(ZONE_DIR):
			var z = JsonUtil.read(path)
			if z is Dictionary:
				zones.append(z)
		var m = JsonUtil.read(MAP_PATH)
		var f = JsonUtil.read(FERRIES_PATH)
		_cached = build(zones, m if m is Dictionary else {}, f if f is Dictionary else {})
	return _cached

## {zones: {id: {name, region, kind, town, pos (Vector2, or (-1, -1)), enc: [{species, table, time, weather, season}], deep (a Deep Place), links (doors and edges out)}},
##  adj: {region: [regions next door]}, town_rooms: {town: [interior ids]}, room_town: {interior: town},
##  region_species: {region: [species ids]}}
static func build(zones: Array, world_map := {}, ferries := {}) -> Dictionary:
	var raw := {}
	for z in zones:
		var r := str(z.get("region", ""))
		if r in SKIP_REGIONS or str(z.get("id", "")) == "":
			continue
		raw[str(z.id)] = z
	var out := {"zones": {}, "adj": {}, "town_rooms": {}, "room_town": {}, "region_species": {}}
	var places: Dictionary = world_map.get("places", {})
	var towns: Dictionary = world_map.get("towns", {})
	for id in raw:
		var z: Dictionary = raw[id]
		var enc := []
		var tables = z.get("encounters", {})
		if tables is Dictionary:
			for table in tables:
				for e in tables[table]:
					if str(e.get("species", "")) != "":
						enc.append({"species": str(e.species), "table": str(table), "time": e.get("time", []), "weather": e.get("weather", []), "season": e.get("season", [])})
		var p: Dictionary = towns.get(id, places.get(id, {}))
		out.zones[id] = {"name": str(z.get("name", id)), "region": str(z.get("region", "")), "kind": str(z.get("kind", "route")),
			"town": str(z.get("town_id", "")), "pos": Vector2(float(p.x), float(p.y)) if p.has("x") else Vector2(-1, -1), "enc": enc,
			"deep": z.get("deep") is Dictionary and not (z.deep as Dictionary).is_empty(), "links": _links(z)}
	_fill_regions_and_rooms(raw, out)
	_fill_positions(raw, out)
	_fill_adjacency(raw, out, ferries)
	for id in out.zones:
		var zd: Dictionary = out.zones[id]
		if zd.region == "":
			continue
		if not out.region_species.has(zd.region):
			out.region_species[zd.region] = []
		for e in zd.enc:
			if e.species not in out.region_species[zd.region]:
				out.region_species[zd.region].append(e.species)
	return out

## Every zone a zone leads to, by door or by edge.
static func _links(z: Dictionary) -> Array:
	var out := _targets(z)
	for e in z.get("edges", {}).values():
		var to := str(e.get("to", ""))
		if to != "" and to not in out:
			out.append(to)
	return out

static func _targets(z: Dictionary) -> Array:
	var out := []
	for w in z.get("warps", []):
		var to := str(w.get("to", ""))
		if to != "" and to not in out:
			out.append(to)
	return out

## Interiors take the region of whatever leads into them; a town's rooms are the interiors you can reach
## from it through doors alone (upstairs, the back room, and so on).
static func _fill_regions_and_rooms(raw: Dictionary, out: Dictionary) -> void:
	var changed := true
	while changed:
		changed = false
		for id in raw:
			var r: String = out.zones[id].region
			if r == "":
				continue
			for to in _targets(raw[id]):
				if out.zones.has(to) and out.zones[to].region == "":
					out.zones[to].region = r
					changed = true
	for id in raw:
		if out.zones[id].kind != "town":
			continue
		var rooms := []
		var stack := [id]
		while not stack.is_empty():
			var c: String = stack.pop_back()
			for to in _targets(raw[c]):
				if out.zones.has(to) and out.zones[to].kind == "interior" and to not in rooms and not out.room_town.has(to):
					rooms.append(to)
					out.room_town[to] = id
					stack.append(to)
		rooms.sort()
		out.town_rooms[id] = rooms

## Zones with no world map spot (some routes, caves) borrow the average spot of their neighbours.
static func _fill_positions(raw: Dictionary, out: Dictionary) -> void:
	var incoming := {}  # whatever leads in counts too (a cave's way in)
	for other in raw:
		for to in _targets(raw[other]):
			if not incoming.has(to):
				incoming[to] = []
			incoming[to].append(other)
	for _pass in 6:
		var any := false
		for id in raw:
			if out.zones[id].pos.x >= 0.0:
				continue
			var sum := Vector2.ZERO
			var n := 0
			var near := _targets(raw[id])
			for e in raw[id].get("edges", {}).values():
				near.append(str(e.get("to", "")))
			near.append_array(incoming.get(id, []))
			for o in near:
				if out.zones.has(o) and out.zones[o].pos.x >= 0.0:
					sum += out.zones[o].pos
					n += 1
			if n > 0:
				out.zones[id].pos = sum / n
				any = true
		if not any:
			break

static func _link(out: Dictionary, a: String, b: String) -> void:
	if a == "" or b == "" or a == b:
		return
	for pair in [[a, b], [b, a]]:
		if not out.adj.has(pair[0]):
			out.adj[pair[0]] = []
		if pair[1] not in out.adj[pair[0]]:
			out.adj[pair[0]].append(pair[1])

## Regions touch where a route's edge or a door crosses between them, or a ferry runs.
static func _fill_adjacency(raw: Dictionary, out: Dictionary, ferries: Dictionary) -> void:
	for id in raw:
		var r: String = out.zones[id].region
		var near := _targets(raw[id])
		for e in raw[id].get("edges", {}).values():
			near.append(str(e.get("to", "")))
		for o in near:
			if out.zones.has(o):
				_link(out, r, out.zones[o].region)
	for route in ferries:
		var f = ferries[route]
		if f is Dictionary and out.zones.has(str(f.get("a", ""))) and out.zones.has(str(f.get("b", ""))):
			_link(out, out.zones[str(f.a)].region, out.zones[str(f.b)].region)

## Where a zone sits on the world map, (-1, -1) if nowhere.
static func pos_of(idx: Dictionary, zone_id: String) -> Vector2:
	return idx.zones.get(zone_id, {}).get("pos", Vector2(-1, -1))
