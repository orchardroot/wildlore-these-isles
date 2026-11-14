class_name RideCheck
extends RefCounted
## The coracle must never be a sequence break. For every outdoor zone, with the story's gate NPCs (Wardens, Marshals
## and the walls that hide when a Stone is won or a chapter is done) treated as solid, and from every way into the
## zone, the warps and edges you can reach in a coracle must be the warps and edges you can reach without one. A zone
## that leaks says so; the fix is a `no_ride` list of [x, y, w, h] rects in that zone's JSON, as small as it can be.
## Pure data: never names an autoload (the validator loads it).

## Everything the best-equipped player can do afloat: both rides, on top of every land ability.
const RIDING := ["hedge_lay", "brook_wade", "fell_scramble", "bog_cross", "tide_ride"]
## A still NPC that hides on one of these flags (and is not waiting for another) is a story gate, not a quest giver.
const GATE_FLAG_PREFIXES := ["badge_", "trainer_", "ch"]
const GATE_FLAGS := ["champion", "moot_won", "kit1_fought", "starter", "ashcombe1_done"]

static func is_gate(n: Dictionary) -> bool:
	if str(n.get("move", "still")) != "still" or not n.has("hide_if") or n.has("show_if"):
		return false
	var f := str(n.hide_if)
	if f in GATE_FLAGS:
		return true
	if f.begins_with("badge_") or f.begins_with("trainer_"):
		return true
	return f.length() > 2 and f.begins_with("ch") and f[2].is_valid_int()  # ch3_ddraig_woke, ch7_judged

## The tiles the gate NPCs stand on.
static func gate_walls(z: ZoneData) -> Dictionary:
	var out := {}
	for n in z.npcs:
		if is_gate(n):
			out[Vector2i(int(n.x), int(n.y))] = true
	return out

## Does the zone have any water a coracle could ever float on?
static func has_water(z: ZoneData) -> bool:
	if not z.ride_zone():
		return false
	for row in z.tiles:
		if "water" in row or "sea" in row:
			return true
	return false

## Every tile you can step on to arrive in `z` on foot: its spawn, the far end of any warp that lands here, and
## where each neighbour's land border tiles put you when you walk off the edge. One per walking region if the zone
## has no ledges (ledges only go one way, so each entry there keeps its own look).
static func entries(zones: Dictionary, z: ZoneData, walls: Dictionary) -> Array:
	var cand := {}
	if z.walkable(z.spawn):
		cand[z.spawn] = true
	for oid in zones:
		var o: ZoneData = zones[oid]
		for w in o.warps:
			if str(w.get("to", "")) == z.id:
				cand[Vector2i(int(w.tx), int(w.ty))] = true
	for side in z.edges:
		var nid := str(z.edges[side].get("to", ""))
		if not zones.has(nid) or side not in ZoneData.OPPOSITE or z.edges[side].has("lease"):
			continue
		var n: ZoneData = zones[nid]
		var back: String = ZoneData.OPPOSITE[side]
		if not n.edges.has(back):
			continue
		for b in n._border(back):
			if n.walkable(b):
				cand[n.edge_arrival(back, b, z)] = true
	var ledges := false
	for row in z.tiles:
		ledges = ledges or "ledge_south" in row
	var out := []
	var covered := {}
	for p in cand:
		if covered.has(p) or not z.walkable(p) or walls.has(p):
			continue
		out.append(p)
		if not ledges:
			covered.merge(z.reachable(p, ZoneData.GATE_ABILITIES, walls))
	return out

## "w:x,y" for each warp and "e:side" for each edge the tiles in `seen` take you to.
static func exits(z: ZoneData, seen: Dictionary) -> Dictionary:
	var out := {}
	for w in z.warps:
		if seen.has(Vector2i(int(w.x), int(w.y))):
			out["w:%d,%d" % [int(w.x), int(w.y)]] = true
	for side in z.edges:
		if side in ZoneData.OPPOSITE and z._side_reached(side, seen):
			out["e:" + str(side)] = true
	return out

## Every gate name some warp or edge of the zone carries (a player may hold every Stone but that one).
static func gates_in(z: ZoneData) -> Array:
	var out := []
	for g in z.warps + z.edges.values():
		var n := str(g.get("gate", ""))
		if n != "" and n in ZoneData.GATE_NAMES and n not in out:
			out.append(n)
	return out

## What the coracle opens up from `entry` that walking does not, for a player with every ability but `without`:
## the exits it reaches ("w:x,y", "e:side") that walking does not.
static func leaks_from(z: ZoneData, entry: Vector2i, walls: Dictionary, without := "") -> Array:
	var on_foot := ZoneData.GATE_ABILITIES.filter(func(a): return a != without)
	var afloat := RIDING.filter(func(a): return a != without)
	var land := z.reachable(entry, on_foot, walls)
	var wet := z.reachable(entry, afloat, walls)
	if wet.size() == land.size():
		return []
	var before := exits(z, land)
	var out := []
	for k in exits(z, wet):
		if not before.has(k):
			out.append(k)
	return out

## Every leak in the zone: {"entry": Vector2i, "what": ..., "without": gate or ""} (once per entry that leaks).
static func leaks(zones: Dictionary, z: ZoneData) -> Array:
	var out := []
	if not has_water(z):
		return out
	var walls := gate_walls(z)
	var scenarios := [""] + gates_in(z)
	for e in entries(zones, z, walls):
		for g in scenarios:
			for k in leaks_from(z, e, walls, g):
				out.append({"entry": e, "what": k, "without": g})
	return out

static func describe(k: String) -> String:
	return ("the warp at " + k.substr(2)) if k.begins_with("w:") else ("the " + k.substr(2) + " edge")

## The validator's view: one error per zone that lets the coracle skip a gate, plus bad `no_ride` rects.
static func problems(zones: Dictionary) -> Array:
	var errs := []
	for id in zones:
		var z: ZoneData = zones[id]
		for r in z.no_ride:
			if not (r is Array) or r.size() != 4 or int(r[2]) < 1 or int(r[3]) < 1:
				errs.append("zone %s: no_ride rect %s must be [x, y, w, h]" % [id, r])
			elif not z.in_bounds(Vector2i(int(r[0]), int(r[1]))) or not z.in_bounds(Vector2i(int(r[0]) + int(r[2]) - 1, int(r[1]) + int(r[3]) - 1)):
				errs.append("zone %s: no_ride rect %s is out of bounds" % [id, r])
		var seen := {}
		for l in leaks(zones, z):
			if seen.has([l.what, l.without]):
				continue
			seen[[l.what, l.without]] = true
			errs.append("zone %s: in a coracle you could reach %s from %d,%d%s without the story's say-so (add a small no_ride rect)" % [id, describe(l.what), l.entry.x, l.entry.y, "" if l.without == "" else " lacking " + l.without])
	return errs
