class_name MapLogic
extends RefCounted
## What the interactive world map knows: which way the cursor jumps, what the info panel says about a
## town, and whether you can fly there. Pure functions over GameStateData and the data files.

## Town -> [Keeper, Stone id]. The Stones are won in order, one Keeper per town.
const KEEPERS := {
	"buxton": ["Maud", "brook"], "liverpool": ["Ray", "urban"], "llanberis": ["Eluned", "stone"],
	"cardiff": ["Rhys", "storm"], "glastonbury": ["Morwen", "fae"], "dublin": ["Declan", "kin"],
	"galway": ["Nuala", "tide"], "belfast": ["Ruairi", "iron"], "inverness": ["Isla", "frost"],
	"york": ["Hester", "spirit"],
}
## Towns whose corner shop file uses a short name.
const SHOP_ALIAS := {"macclesfield": "macc"}

const DIRS := {"left": Vector2(-1, 0), "right": Vector2(1, 0), "up": Vector2(0, -1), "down": Vector2(0, 1)}

## The town the cursor jumps to from `from` going `dir` (a unit vector in map space, y down), or "".
## `cands` is town id -> map position. Prefers a town roughly straight ahead (within 60 degrees), nearer
## and more on-line the better; failing that, anything at all on that side.
static func nearest(from: Vector2, cands: Dictionary, dir: Vector2, exclude := "") -> String:
	var best := ""
	var best_score := INF
	for pass_no in 2:
		for id in cands:
			if id == exclude:
				continue
			var d: Vector2 = cands[id] - from
			var dist := d.length()
			var along := d.dot(dir)
			if dist < 0.001 or along <= 0.0:
				continue
			if pass_no == 0 and along / dist < 0.5:
				continue
			var score := dist + absf(d.cross(dir)) * 1.5
			if score < best_score:
				best_score = score
				best = id
		if best != "":
			break
	return best

## Towns that exist in the game (they have a zone file).
static func real_towns() -> Array:
	var out := []
	for t in Travel.world_map().get("towns", {}):
		if FileAccess.file_exists("res://data/zones/%s.json" % t):
			out.append(t)
	return out

static func visited(data: GameStateData, town: String) -> bool:
	return data.flag("visited_" + town) == true

## Map position of every visited town: the cursor's stepping stones.
static func visited_positions(data: GameStateData) -> Dictionary:
	var out := {}
	var towns: Dictionary = Travel.world_map().get("towns", {})
	for t in real_towns():
		if visited(data, t):
			out[t] = Vector2(float(towns[t].x), float(towns[t].y))
	return out

## Where the cursor starts: your current town if you have been there, else any visited town, else "".
static func start_town(data: GameStateData) -> String:
	var here = data.flag("last_town")
	var pos := visited_positions(data)
	if here and pos.has(str(here)):
		return str(here)
	for t in pos:
		return t
	return ""

## Unvisited towns that still get a name on the map: the one "Where next?" is pointing at.
static func named_unvisited(data: GameStateData, objective_town: String) -> Array:
	return [objective_town] if objective_town != "" and not visited(data, objective_town) else []

## Species that live on the wild routes next to a town, in first-seen order.
static func nearby_species(town: String) -> Array:
	var out := []
	var z := ZoneData.load_id(town)
	for dir in z.edges:
		var r := ZoneData.load_id(str(z.edges[dir].get("to", "")))
		if r.kind == "town" or r.kind == "interior":
			continue
		for kind in r.encounters:
			for e in r.encounters[kind]:
				var sp := str(e.get("species", ""))
				if sp != "" and sp not in out:
					out.append(sp)
	return out

static func has_shop(town: String) -> bool:
	return FileAccess.file_exists("res://data/shops/%s_corner_shop.json" % SHOP_ALIAS.get(town, town))

## Everything the info panel shows about a visited town.
static func info(data: GameStateData, town: String) -> Dictionary:
	var out := {"town": town, "name": Travel.town_name(town), "keeper": {}, "sanctuary": false, "shop": false,
		"station": false, "ferries": [], "found": 0, "nearby": 0, "rooms": 0, "rooms_seen": 0}
	if KEEPERS.has(town):
		var k: Array = KEEPERS[town]
		out.keeper = {"name": k[0], "stone": str(k[1]).capitalize() + " Stone",
			"won": data.flag("badge_" + str(k[1])) == true or str(k[1]) in data.badges}
	out.sanctuary = FileAccess.file_exists("res://data/zones/%s_sanctuary.json" % SHOP_ALIAS.get(town, town))
	out.shop = has_shop(town)
	out.station = data.flag(Travel.station_flag(town)) == true
	var fer: Dictionary = Travel.ferries()
	for route in fer:
		var r: Dictionary = fer[route]
		if str(r.a) == town or str(r.b) == town:
			out.ferries.append(Travel.town_name(str(r.b) if str(r.a) == town else str(r.a)))
	var near := nearby_species(town)
	out.nearby = near.size()
	for sp in near:
		if data.caught.has(sp):
			out.found += 1
	var rooms := VisitorsBook.count(data, town, ZoneIndex.get_index())
	out.rooms_seen = rooms.x
	out.rooms = rooms.y
	var nation := Standing.nation_for_zone(town)
	out["standing"] = "%s in %s" % [Standing.tier_name(data, nation), Standing.name_of(nation)]
	return out

## The panel's lines, top to bottom.
static func info_lines(i: Dictionary) -> Array:
	var out := []
	if not i.keeper.is_empty():
		out.append("Keeper %s: %s %s" % [i.keeper.name, i.keeper.stone, "won" if i.keeper.won else "not yet won"])
	out.append("Sanctuary: " + ("yes" if i.sanctuary else "none"))
	out.append("Corner Shop: " + ("yes" if i.shop else "none"))
	out.append("Station: " + ("yes" if i.station else "not found yet"))
	out.append("Ferry: " + (", ".join(i.ferries) if not i.ferries.is_empty() else "none"))
	if i.nearby > 0:
		out.append("Fieldbook nearby: %d of %d found" % [i.found, i.nearby])
	else:
		out.append("Fieldbook nearby: no wild routes")
	if i.get("rooms", 0) > 0:
		out.append("Rooms visited: %d of %d%s" % [i.rooms_seen, i.rooms, "  (the full tour!)" if i.rooms_seen >= i.rooms else ""])
	if i.has("standing"):
		out.append("Standing: " + str(i.standing))
	return out

## After the Champion, a visited town other than the one you are standing in is a flight away.
static func can_fly_to(data: GameStateData, here: String, town: String) -> bool:
	return data.flag("champion") == true and town in Travel.fly_destinations(data, here)

## Where each label goes. `items` are {id, at (the dot, in screen pixels), size, spots (optional: offsets to try
## instead of label_spots)}; each tries the spots round its
## dot (label_spots) and takes the first that clears every label already placed and every `blockers` Rect2 (the player marker, icons). A label with nowhere
## free is left out. Returns id -> Rect2, in `items` order.
static func place_labels(items: Array, blockers: Array, dots: Array = []) -> Dictionary:
	var out := {}
	var taken: Array = blockers.duplicate()
	for it in items:
		var spots: Array = it.get("spots", label_spots(it.size))
		var fallback := Rect2()
		var found := false
		for o in spots:
			var r := Rect2(it.at + o, it.size)
			if taken.any(func(t): return t.intersects(r)):
				continue
			if fallback.size == Vector2.ZERO:
				fallback = r
			if not it.has("spots") and _nearer_other(r, it.at, dots):
				continue
			taken.append(r)
			out[it.id] = r
			found = true
			break
		if not found and fallback.size != Vector2.ZERO:  # every clear spot reads as a neighbour's: take the best
			taken.append(fallback)
			out[it.id] = fallback
	return out

## Is some other dot in `dots` about as close to rect `r` as its own dot `own`, or closer? (It would read as theirs.)
static func _nearer_other(r: Rect2, own: Vector2, dots: Array) -> bool:
	var mine := _rect_dist(r, own)
	for d in dots:
		if d != own and _rect_dist(r, d) < mine + 10.0:
			return true
	return false

static func _rect_dist(r: Rect2, p: Vector2) -> float:
	return p.distance_to(Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y)))

## The offsets (from a dot to a label's top-left) a label of size `sz` tries, best first: beside, above and
## below the dot, the corners, then further out, then stacked a line or two up or down on either side.
static func label_spots(sz: Vector2) -> Array:
	var out := []
	for gap in [10.0, 22.0, 36.0]:
		out.append_array([Vector2(gap, -sz.y * 0.5), Vector2(-gap - sz.x, -sz.y * 0.5), Vector2(-sz.x * 0.5, -gap - sz.y),
			Vector2(-sz.x * 0.5, gap), Vector2(gap * 0.7, -gap * 0.7 - sz.y), Vector2(gap * 0.7, gap * 0.7),
			Vector2(-gap * 0.7 - sz.x, -gap * 0.7 - sz.y), Vector2(-gap * 0.7 - sz.x, gap * 0.7)])
	for n in range(1, 4):
		var dy := (sz.y + 2.0) * n
		out.append_array([Vector2(10, -sz.y * 0.5 - dy), Vector2(10, -sz.y * 0.5 + dy),
			Vector2(-10 - sz.x, -sz.y * 0.5 - dy), Vector2(-10 - sz.x, -sz.y * 0.5 + dy)])
	return out

## The little marks on the map, each {kind, at (a town or place id), ...}: rewilding sites you've met
## ("rewild", stage 0..3, name), today's County Show ("show", name; pass Tournament.today or {}), Keepers' side
## stories waiting ("side", who) and Kit's postcards waiting ("post", at your last town: any post box will do).
static func marks(data: GameStateData, show: Dictionary) -> Array:
	var out := []
	for s in Rewild.sites():
		var id := str(s.id)
		var st := Rewild.stage(data, id)
		if st > 0 or data.flag(Rewild.flag_key(id) + "_met") != null:
			out.append({"kind": "rewild", "at": str(s.zone), "stage": st, "name": str(s.get("name", ""))})
	if not show.is_empty() and str(show.get("town", "")) != "":
		out.append({"kind": "show", "at": str(show.town), "name": str(show.get("name", ""))})
	for s in SideStories.sides():
		if SideStories.waiting(data, s):
			out.append({"kind": "side", "at": str(s.zone), "who": str(s.get("who", ""))})
	out.append_array(Letters.marks(data))  # "?" where a treasure trail ends
	var here = data.flag("last_town")
	if here and not Postcards.waiting(data).is_empty():
		out.append({"kind": "post", "at": str(here)})
	return out

## Where a mark sits on the map (map units), or (-1, -1) if its town or place isn't drawn.
static func mark_point(mark: Dictionary) -> Vector2:
	var m := Travel.world_map()
	var at := str(mark.get("at", ""))
	var src: Dictionary = m.get("towns", {}).get(at, m.get("places", {}).get(at, {}))
	return Vector2(float(src.x), float(src.y)) if not src.is_empty() else Vector2(-1, -1)

## The map points a route passes through (zones with a spot on the map, in order, repeats dropped).
static func route_points(path: Array, zones: Dictionary) -> PackedVector2Array:
	var out := PackedVector2Array()
	for zid in path:
		var pos: Vector2 = zones.get(str(zid), {}).get("pos", Vector2(-1, -1))
		if pos.x >= 0 and (out.is_empty() or out[out.size() - 1] != pos):
			out.append(pos)
	return out
