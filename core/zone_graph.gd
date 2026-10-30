class_name ZoneGraph
extends RefCounted
## The isles as a graph of zones, for the Map's "Route here" and the playtest bot. Walking is zone to zone
## (an edge or a warp, both ways, cost 1), the train joins every station you know on the same island
## (cost 2, needs the rail pass) and a ferry joins the two ends of its route (cost 3, once either end is known).
## Pure: build() takes the raw zones, ferries and world-map towns, so tests can feed fixtures. Gates are ignored.

const WALK := 1
const RAIL := 2
const FERRY := 3

static var _shared: Dictionary = {}

## The real game's graph, built once.
static func shared() -> Dictionary:
	if _shared.is_empty():
		_shared = build(ZoneData.load_all(), Travel.ferries(), Travel.world_map().get("towns", {}))
	return _shared

## {walk: {zone: {zone: true}}, kind: {zone: kind}, name: {zone: name}, station: {zone: island},
##  ferry: {zone: [far zone, route id]}, towns: {town: island}}
static func build(zones: Dictionary, ferries: Dictionary, towns: Dictionary) -> Dictionary:
	var g := {"walk": walk_adj(zones), "kind": {}, "name": {}, "station": {}, "ferry": {}, "towns": {}}
	for t in towns:
		g.towns[t] = str(towns[t].get("island", "gb"))
	for zid in zones:
		var z: ZoneData = zones[zid]
		g.kind[zid] = z.kind
		g.name[zid] = z.name
		if z.station != Vector2i(-1, -1) and z.town_id != "":
			g.station[zid] = str(g.towns.get(z.town_id, "gb"))
		if not z.ferry.is_empty():
			var r: Dictionary = ferries.get(str(z.ferry.get("route", "")), {})
			if not r.is_empty():
				var far := str(r.get("b", "")) if str(r.get("a", "")) == zid else str(r.get("a", ""))
				if zones.has(far):
					g.ferry[zid] = [far, str(z.ferry.route)]
	return g

## Zone adjacency by edges and warps, both ways, as the bot counts hops. Gates are ignored.
static func walk_adj(zones: Dictionary) -> Dictionary:
	var adj := {}
	for zid in zones:
		if not adj.has(zid):
			adj[zid] = {}
		var z: ZoneData = zones[zid]
		var nexts := []
		for side in z.edges:
			nexts.append(str(z.edges[side].get("to", "")))
		for w in z.warps:
			nexts.append(str(w.get("to", "")))
		for n in nexts:
			if zones.has(n):
				adj[zid][n] = true
				if not adj.has(n):
					adj[n] = {}
				adj[n][zid] = true
	return adj

## Walking hops from a zone to every zone it reaches (BFS).
static func hops(adj: Dictionary, zid: String) -> Dictionary:
	var dist := {zid: 0}
	var queue := [zid]
	var i := 0
	while i < queue.size():
		var a: String = queue[i]
		i += 1
		for b in adj.get(a, {}):
			if not dist.has(b):
				dist[b] = dist[a] + 1
				queue.append(b)
	return dist

static func _station_known(g: Dictionary, data: GameStateData, zid: String) -> bool:
	return g.station.has(zid) and data.flag("station_" + str(zid)) == true

static func _ferry_known(g: Dictionary, data: GameStateData, zid: String) -> bool:
	if not g.ferry.has(zid):
		return false
	return data.flag("visited_" + zid) == true or data.flag("visited_" + str(g.ferry[zid][0])) == true

## Everything one move from `zid` for this player: [[zone, cost, mode], ...]. Interiors only count as the goal.
static func _next(g: Dictionary, data: GameStateData, zid: String, goal: String) -> Array:
	var out := []
	for b in g.walk.get(zid, {}):
		if b == goal or g.kind.get(b, "") != "interior":
			out.append([b, WALK, "walk"])
	if _station_known(g, data, zid) and int(data.bag.get("rail_pass", 0)) > 0:
		for s in g.station:
			if s != zid and g.station[s] == g.station[zid] and _station_known(g, data, s):
				out.append([s, RAIL, "rail"])
	if _ferry_known(g, data, zid):
		out.append([g.ferry[zid][0], FERRY, "ferry"])
	return out

## The cheapest way from a zone to a town (its zone id): zone ids, from first to last, or [] for no way there.
static func route(g: Dictionary, from_zone: String, to_town: String, data: GameStateData) -> Array:
	if not g.kind.has(from_zone) or not g.kind.has(to_town):
		return []
	if from_zone == to_town:
		return [from_zone]
	var dist := {from_zone: 0}
	var prev := {}
	var buckets: Array = [[from_zone]]  # costs are small whole numbers: a bucket per distance
	var d := 0
	var done := {}
	while d < buckets.size():
		for a in buckets[d]:
			if done.has(a) or int(dist[a]) != d:
				continue
			done[a] = true
			if a == to_town:
				d = buckets.size()
				break
			for nx in _next(g, data, a, to_town):
				var nd := d + int(nx[1])
				if not dist.has(nx[0]) or nd < int(dist[nx[0]]):
					dist[nx[0]] = nd
					prev[nx[0]] = a
					while buckets.size() <= nd:
						buckets.append([])
					buckets[nd].append(nx[0])
		d += 1
	if not done.has(to_town):
		return []
	var path := [to_town]
	while path[0] != from_zone:
		path.push_front(prev[path[0]])
	return path

## How you get from one zone to the next on a route: "walk", "rail" or "ferry".
static func hop_mode(g: Dictionary, a: String, b: String) -> String:
	if g.walk.get(a, {}).has(b):
		return "walk"
	if g.ferry.has(a) and g.ferry[a][0] == b:
		return "ferry"
	return "rail" if g.station.has(a) and g.station.has(b) else "walk"

## "3 zones on foot, then the train from Stockport, then 2 zones on foot".
static func summary(g: Dictionary, path: Array) -> String:
	var parts := []
	var walked := 0
	for i in range(1, path.size()):
		var m := hop_mode(g, str(path[i - 1]), str(path[i]))
		if m == "walk":
			walked += 1
			continue
		if walked > 0:
			parts.append(_zones(walked))
			walked = 0
		var from_name := str(g.name.get(path[i - 1], path[i - 1]))
		parts.append(("the train from " if m == "rail" else "the ferry from ") + from_name)
	if walked > 0:
		parts.append(_zones(walked))
	if parts.is_empty():
		return "You are there"
	return ", then ".join(parts)

static func _zones(n: int) -> String:
	return "%d zone%s on foot" % [n, "" if n == 1 else "s"]

const OPPOSITE := {"north": "south", "south": "north", "east": "west", "west": "east"}

## Where to leave `zone` to reach `next` as `mode`: {"side": "north"} for an edge, {"pos": Vector2i} for a warp
## (the nearest to `from`), the station or the quay; {} when there is no way.
static func exit_toward(zone: ZoneData, next: String, mode: String, from: Vector2i) -> Dictionary:
	if mode == "rail":
		return {"pos": zone.station} if zone.station != Vector2i(-1, -1) else {}
	if mode == "ferry":
		return {"pos": Vector2i(int(zone.ferry.get("x", -1)), int(zone.ferry.get("y", -1)))} if not zone.ferry.is_empty() else {}
	for side in zone.edges:
		if str(zone.edges[side].get("to", "")) == next:
			return {"side": str(side)}
	var best := {}
	var best_d := 1 << 30
	for w in zone.warps:
		if str(w.get("to", "")) == next:
			var p := Vector2i(int(w.get("x", 0)), int(w.get("y", 0)))
			var dd := absi(p.x - from.x) + absi(p.y - from.y)
			if dd < best_d:
				best_d = dd
				best = {"pos": p}
	return best

## An arrow glyph for the way from `from` to an exit (north is up the screen).
static func arrow_for(ex: Dictionary, from: Vector2i) -> String:
	var v := Vector2.ZERO
	if ex.has("side"):
		v = {"north": Vector2(0, -1), "south": Vector2(0, 1), "east": Vector2(1, 0), "west": Vector2(-1, 0)}.get(str(ex.side), Vector2.ZERO)
	elif ex.has("pos"):
		v = Vector2(ex.pos - from)
	if v == Vector2.ZERO:
		return "•"
	var i := int(roundf(v.angle() / (TAU / 8.0))) & 7  # 0 = east, clockwise on screen
	return ["→", "↘", "↓", "↙", "←", "↖", "↑", "↗"][i]

## What the overworld breadcrumb should say standing at `pos` in `zone` with a route stored to `to`:
## {state: "off"} (nothing to show: no route, indoors, or no way), {state: "arrived"} (clear it), or
## {state: "go", text: "To Buxton · 3 to go", arrow: "↗", next: zone id, mode: "walk"|"rail"|"ferry"}.
static func guide(g: Dictionary, zone: ZoneData, pos: Vector2i, to: String, data: GameStateData, to_name: String) -> Dictionary:
	if to == "" or zone == null:
		return {"state": "off"}
	if zone.id == to:
		return {"state": "arrived"}
	if zone.kind == "interior":
		return {"state": "off"}
	var path := route(g, zone.id, to, data)
	if path.size() < 2:
		return {"state": "off"}
	var next := str(path[1])
	var mode := hop_mode(g, zone.id, next)
	var ex := exit_toward(zone, next, mode, pos)
	return {"state": "go", "text": "To %s  ·  %d to go" % [to_name, path.size() - 1], "arrow": arrow_for(ex, pos), "next": next, "mode": mode}
