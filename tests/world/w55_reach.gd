extends RefCounted
## Wave 55: how far can a player WALK at each step of the story? Used by the roads tests to prove that a new road
## never lets anyone reach a place earlier than the story allows (and by tools/dev/roads_golden.gd to record the
## answer for the unchanged game). Not the playtest bot: no routing, just flood fills.
##
## A walk goes from zone to zone by edges and by warps. Inside an outdoor zone the player floods across everything
## walkable (every field ability counted as known, so only the story's own gates count), with these standing in the
## way: NPCs that never move and have a hide_if flag (the Morris Men, the Wardens, the wall of "gate" people) until
## that flag is set. Interiors are taken as open rooms: every warp in them can be used.

const START_ZONE := "macclesfield"
## Flags a step brings that data/objectives.json does not list (trainers' flags, the Moot's result).
const ALSO := {"starter": ["kit1_fought"], "strachan1_done": ["trainer_strachan_1"], "moot_won": ["champion"]}

## [{name, flags}] in story order: the start, then after each objective, with a state between "starter" and the rest
## where the Kit fight at the Field Station has not yet happened.
static func states() -> Array:
	var d = JsonUtil.read("res://data/objectives.json")
	var out := [{"name": "start", "flags": {}}]
	var cur := {}
	for s in d.story:
		var f := str(s.flag_done)
		cur[f] = true
		if f == "starter":
			out.append({"name": f, "flags": cur.duplicate()})
			cur["kit1_fought"] = true
			out.append({"name": "starter+kit1", "flags": cur.duplicate()})
			continue
		for e in ALSO.get(f, []):
			cur[e] = true
		out.append({"name": f, "flags": cur.duplicate()})
	return out

static func _gates(z: ZoneData, flags: Dictionary) -> Dictionary:
	var out := {}
	for n in z.npcs:
		if str(n.get("move", "still")) != "still" or n.has("show_if"):
			continue
		if n.has("hide_if") and not flags.has(str(n.hide_if)):
			out[Vector2i(int(n.x), int(n.y))] = true
	return out

## Every zone id reachable on foot with these flags.
static func reach(zones: Dictionary, flags: Dictionary, cache: Dictionary) -> Dictionary:
	var seen_zones := {}
	var done := {}
	var queue: Array = [[START_ZONE, zones[START_ZONE].spawn]]
	while not queue.is_empty():
		var item: Array = queue.pop_back()
		var zid: String = item[0]
		var at: Vector2i = item[1]
		var key := "%s@%d,%d" % [zid, at.x, at.y]
		if not zones.has(zid) or done.has(key):
			continue
		done[key] = true
		seen_zones[zid] = true
		var z: ZoneData = zones[zid]
		if z.kind == "interior":
			for w in z.warps:
				queue.append([str(w.to), Vector2i(int(w.tx), int(w.ty))])
			continue
		var gates := _gates(z, flags)
		var ck := key + "#" + _gate_sig(z, flags)
		if not cache.has(ck):
			cache[ck] = _exits(z, at, gates)
		for e in cache[ck]:
			if e.has("warp"):
				queue.append([e.warp, e.land])
			else:
				var tgt: Dictionary = z.edges[e.side]
				var other: String = str(tgt.get("to", ""))
				if zones.has(other):
					queue.append([other, z.edge_arrival(e.side, e.at, zones[other])])
	return seen_zones

static func _gate_sig(z: ZoneData, flags: Dictionary) -> String:
	var parts := []
	for n in z.npcs:
		if n.has("hide_if") and str(n.get("move", "still")) == "still" and not n.has("show_if"):
			parts.append("1" if flags.has(str(n.hide_if)) else "0")
	return "".join(parts)

static func _exits(z: ZoneData, at: Vector2i, gates: Dictionary) -> Array:
	var tiles := z.reachable(at, ZoneData.GATE_ABILITIES, gates)
	var out := []
	var warps := {}
	for w in z.warps:
		warps[Vector2i(int(w.x), int(w.y))] = w
	for p in tiles:
		if warps.has(p):
			var w: Dictionary = warps[p]
			out.append({"warp": str(w.to), "land": Vector2i(int(w.tx), int(w.ty))})
		if p.x == 0 and z.edges.has("west"):
			out.append({"side": "west", "at": p})
		if p.x == z.width - 1 and z.edges.has("east"):
			out.append({"side": "east", "at": p})
		if p.y == 0 and z.edges.has("north"):
			out.append({"side": "north", "at": p})
		if p.y == z.height - 1 and z.edges.has("south"):
			out.append({"side": "south", "at": p})
	return out

## {zone id: index of the first state in which it can be walked to} for every outdoor and town zone, and the state
## names in order.
static func first_steps(zones: Dictionary) -> Dictionary:
	var first := {}
	var names := []
	var cache := {}
	var i := 0
	for st in states():
		names.append(st.name)
		var r := reach(zones, st.flags, cache)
		for zid in r:
			if zones[zid].kind != "interior" and not first.has(zid):
				first[zid] = i
		i += 1
	return {"states": names, "first": first}
