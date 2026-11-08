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
	out.append_array(Poi.marks(data))  # the question marks on the routes
	out.append_array(FieldSpots.marks(data))  # field piece nooks you have spotted
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

## The route as drawn: a walk goes town to town, a rail hop follows the railway between the two stations and a
## ferry hop follows its crossing, so the line runs where you'll actually go. `rail` is the map's rail polylines
## (PackedVector2Array each), `ferry_paths` route id -> PackedVector2Array; a leg with no drawn line is straight.
static func route_legs(path: Array, zones: Dictionary, g: Dictionary, rail: Array, ferry_paths: Dictionary) -> PackedVector2Array:
	var out := PackedVector2Array()
	var prev_zid := ""
	for zid in path:
		var pos: Vector2 = zones.get(str(zid), {}).get("pos", Vector2(-1, -1))
		if pos.x < 0:
			continue
		if not out.is_empty():
			var mode := ZoneGraph.hop_mode(g, prev_zid, str(zid)) if prev_zid != "" else "walk"
			var leg := PackedVector2Array()
			if mode == "rail":
				leg = rail_leg(rail, out[out.size() - 1], pos)
			elif mode == "ferry":
				leg = ferry_leg(ferry_paths.get(str(g.ferry.get(prev_zid, ["", ""])[1]), PackedVector2Array()), out[out.size() - 1], pos)
			for p in leg:
				if out[out.size() - 1] != p:
					out.append(p)
		if out.is_empty() or out[out.size() - 1] != pos:
			out.append(pos)
		prev_zid = str(zid)
	return out

## A ferry's drawn crossing, pointed from `a` to `b` (empty when there is none).
static func ferry_leg(pts: PackedVector2Array, a: Vector2, b: Vector2) -> PackedVector2Array:
	if pts.size() < 2:
		return PackedVector2Array()
	var fwd := pts[0].distance_to(a) + pts[pts.size() - 1].distance_to(b)
	var back := pts[pts.size() - 1].distance_to(a) + pts[0].distance_to(b)
	if back < fwd:
		var r := pts.duplicate()
		r.reverse()
		return r
	return pts

const RAIL_SNAP := 40.0  # a station's dot is this close to its railway, or the hop is drawn straight
const RAIL_JOIN := 4.0  # a line ending this close to another is joined to it (branches off a main line)

## The railway between two stations: from the point on the drawn lines nearest `a`, the shortest run along them
## to the point nearest `b` (empty when either is off the network or they aren't joined up).
static func rail_leg(rail: Array, a: Vector2, b: Vector2) -> PackedVector2Array:
	var net := _rail_net(rail)
	var sa := _snap(net, a)
	var sb := _snap(net, b)
	if sa.is_empty() or sb.is_empty():
		return PackedVector2Array()
	if sa.u == sb.u and sa.v == sb.v:  # both on the same stretch of line
		return PackedVector2Array([sa.pt, sb.pt])
	var nodes: Array = net.nodes
	var dist := {sa.u: float(sa.du), sa.v: float(sa.dv)}
	var prev := {}
	var open := [sa.u, sa.v]
	var done := {}
	while not open.is_empty():
		var best := -1
		for i in open:
			if best < 0 or float(dist[i]) < float(dist[best]):
				best = i
		open.erase(best)
		if done.has(best):
			continue
		done[best] = true
		if done.has(sb.u) and done.has(sb.v):
			break
		for nx in net.adj[best]:
			var nd: float = float(dist[best]) + nodes[best].distance_to(nodes[nx])
			if not dist.has(nx) or nd < float(dist[nx]):
				dist[nx] = nd
				prev[nx] = best
				open.append(nx)
	var ends := []
	for e in [[sb.u, sb.du], [sb.v, sb.dv]]:
		if dist.has(e[0]):
			ends.append([float(dist[e[0]]) + float(e[1]), int(e[0])])
	if ends.is_empty():
		return PackedVector2Array()
	ends.sort()
	var out := PackedVector2Array([sb.pt])
	var at: int = ends[0][1]
	while true:
		out.append(nodes[at])
		if not prev.has(at):
			break
		at = int(prev[at])
	out.append(sa.pt)
	out.reverse()
	var clean := PackedVector2Array()
	for q in out:
		if clean.is_empty() or clean[clean.size() - 1].distance_to(q) > 0.01:
			clean.append(q)
	return clean

## Where `p` meets the network: the nearest point on any edge within RAIL_SNAP, with the edge's ends and the
## distances along it to each ({} when the point is off the network).
static func _snap(net: Dictionary, p: Vector2) -> Dictionary:
	var best := {}
	var bd := RAIL_SNAP
	var nodes: Array = net.nodes
	for u in nodes.size():
		for v in net.adj[u]:
			if v < u:
				continue
			var q: Vector2 = Geometry2D.get_closest_point_to_segment(p, nodes[u], nodes[v])
			var d := q.distance_to(p)
			if d < bd:
				bd = d
				best = {"pt": q, "u": u, "v": v, "du": q.distance_to(nodes[u]), "dv": q.distance_to(nodes[v])}
	return best

static var _rail_cache := {}

## Vertices snapped to whole map units (so lines that meet end to end share a node) with their neighbours; a
## line that ends on or just short of another line is joined to it there (a branch off a main line).
static func _rail_net(rail: Array) -> Dictionary:
	var key := rail.size()
	for line in rail:
		key = key * 31 + line.size()
	if _rail_cache.get("key", -1) == key:
		return _rail_cache.net
	var nodes := []
	var index := {}
	var adj := []
	var ends := []
	for line in rail:
		var last := -1
		for n in line.size():
			var p: Vector2 = line[n]
			var k := Vector2i(roundi(p.x), roundi(p.y))
			if not index.has(k):
				index[k] = nodes.size()
				nodes.append(Vector2(p))
				adj.append([])
			var i: int = index[k]
			if last >= 0 and last != i:
				_link(adj, last, i)
			if n == 0 or n == line.size() - 1:
				ends.append(i)
			last = i
	for e in ends:
		if adj[e].size() > 1:
			continue  # already part of a junction
		var best := {}
		var bd := RAIL_JOIN
		for u in nodes.size():
			for v in adj[u]:
				if v < u or u == e or v == e:
					continue
				var q: Vector2 = Geometry2D.get_closest_point_to_segment(nodes[e], nodes[u], nodes[v])
				var d: float = q.distance_to(nodes[e])
				if d < bd:
					bd = d
					best = {"pt": q, "u": u, "v": v}
		if best.is_empty():
			continue
		var pt: Vector2 = best.pt
		if pt.distance_to(nodes[best.u]) <= 1.0:
			_link(adj, e, best.u)
		elif pt.distance_to(nodes[best.v]) <= 1.0:
			_link(adj, e, best.v)
		else:  # the line ends against the middle of a stretch: split it there
			var n := nodes.size()
			nodes.append(pt)
			adj.append([])
			adj[best.u].erase(best.v)
			adj[best.v].erase(best.u)
			_link(adj, best.u, n)
			_link(adj, n, best.v)
			_link(adj, e, n)
	_rail_cache = {"key": key, "net": {"nodes": nodes, "adj": adj}}
	return _rail_cache.net

static func _link(adj: Array, a: int, b: int) -> void:
	if a == b:
		return
	if not adj[a].has(b):
		adj[a].append(b)
	if not adj[b].has(a):
		adj[b].append(a)
