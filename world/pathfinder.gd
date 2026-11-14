class_name Pathfinder
extends RefCounted
## Grid paths for the playtest bot (and, later, NPC walks): within one zone, and across zones via
## doors (warps) and walk-off edges. Door tiles are avoided unless they are the goal, since stepping
## on one warps you.

const DIRS := [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
## Field abilities the walker has (FieldMoves.abilities); set before planning. Brambles count as passable
## with hedge_lay (walking into one clears it).
static var abilities: Array = []

const EDGE_DIR := {"north": Vector2i(0, -1), "south": Vector2i(0, 1), "west": Vector2i(-1, 0), "east": Vector2i(1, 0)}

## BFS parents from `from` over walkable tiles. Ledges are taken as a two-tile hop south.
static func _flood(z: ZoneData, from: Vector2i, blocked: Dictionary, goal := Vector2i(-99, -99)) -> Dictionary:
	var parent := {from: from}
	var queue := [from]
	var i := 0
	while i < queue.size():
		var p: Vector2i = queue[i]
		i += 1
		if p == goal:
			break
		if p != from and not z.warp_at(p).is_empty():
			continue  # standing on a door would warp; don't route through it
		for d in DIRS:
			var q: Vector2i = p + d
			if z.tile_at(q) == "ledge_south":
				if d != Vector2i(0, 1):
					continue
				q = q + d
				if not z.walkable(q, Vector2i.ZERO, abilities) or blocked.has(q):
					continue
			elif not (z.walkable(q, d, abilities) or (z.tile_at(q) == "bramble" and "hedge_lay" in abilities)) or blocked.has(q):
				continue
			if parent.has(q):
				continue
			parent[q] = p
			queue.append(q)
	return parent

static func _unwind(parent: Dictionary, from: Vector2i, to: Vector2i) -> Array:
	if not parent.has(to):
		return []
	var out := []
	var p := to
	while p != from:
		out.push_front(p)
		p = parent[p]
	return out

## Positions to step through from `from` to `to` (excluding from). Empty if unreachable.
static func within(z: ZoneData, from: Vector2i, to: Vector2i, blocked: Dictionary) -> Array:
	if from == to:
		return []
	return _unwind(_flood(z, from, blocked, to), from, to)

## Exits reachable from `from`: [{kind, tile, dir, to_zone, arrival}]
static func _exits(z: ZoneData, zones: Dictionary, parent: Dictionary) -> Array:
	var out := []
	for w in z.warps:
		var t := Vector2i(int(w.x), int(w.y))
		if parent.has(t) and zones.has(str(w.to)):
			out.append({"kind": "warp", "tile": t, "dir": "", "to_zone": str(w.to), "arrival": Vector2i(int(w.tx), int(w.ty))})
	for side in z.edges:
		var target_id: String = z.edges[side].get("to", "")
		if not zones.has(target_id):
			continue
		var target: ZoneData = zones[target_id]
		var d: Vector2i = EDGE_DIR[side]
		for t in parent:
			var off: Vector2i = t + d
			if z.in_bounds(off):
				continue
			var arr := z.edge_arrival(side, t, target)
			if target.walkable(arr):
				out.append({"kind": "edge", "tile": t, "dir": GridMotion.facing_from(d), "to_zone": target_id, "arrival": arr})
	return out

## Legs [{zone, start, path, exit: {kind: "warp"|"edge"|"goal", dir}}] from one place to another, fewest zone changes first.
static func route(zones: Dictionary, from_zone: String, from: Vector2i, to_zone: String, to: Vector2i, blocked := {}) -> Array:
	var start_key := "%s|%d,%d" % [from_zone, from.x, from.y]
	var came := {start_key: null}
	var queue := [[from_zone, from]]
	var found := ""
	var covered := {}  # zone -> every tile an earlier flood there reached (not the start zone, which has `blocked`)
	var i := 0
	while i < queue.size() and found == "":
		var zid: String = queue[i][0]
		var pos: Vector2i = queue[i][1]
		i += 1
		var z: ZoneData = zones[zid]
		# Arriving on a tile an earlier flood of this zone already reached adds nothing: whatever is reachable from
		# here was reachable from there. (Without this every edge tile is its own arrival, and a loop of zones
		# floods each zone dozens of times.) A door tile is the exception, a flood does not leave from one.
		if zid != from_zone and covered.has(zid) and covered[zid].has(pos) and z.warp_at(pos).is_empty():
			continue
		# `blocked` holds NPC tiles of the zone you're standing in; they mean nothing in other zones
		var parent := _flood(z, pos, blocked if zid == from_zone else {})
		if zid != from_zone:
			if not covered.has(zid):
				covered[zid] = {}
			covered[zid].merge(parent)
		var key := "%s|%d,%d" % [zid, pos.x, pos.y]
		if zid == to_zone and parent.has(to):
			found = key
			came["goal"] = {"from": key, "zone": zid, "start": pos, "path": _unwind(parent, pos, to), "exit": {"kind": "goal", "dir": ""}}
			break
		for ex in _exits(z, zones, parent):
			var nk := "%s|%d,%d" % [ex.to_zone, ex.arrival.x, ex.arrival.y]
			if came.has(nk):
				continue
			came[nk] = {"from": key, "zone": zid, "start": pos, "path": _unwind(parent, pos, ex.tile), "exit": {"kind": ex.kind, "dir": ex.dir}}
			queue.append([ex.to_zone, ex.arrival])
	if found == "":
		return []
	var legs := []
	var k = "goal"
	while came[k] != null:
		var leg: Dictionary = came[k]
		legs.push_front({"zone": leg.zone, "start": leg.start, "path": leg.path, "exit": leg.exit})
		k = leg.from
	return legs
