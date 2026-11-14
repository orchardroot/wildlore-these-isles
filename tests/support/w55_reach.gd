extends RefCounted
## Wave 55 (roads): which zones a player can walk to with the flags of a given story step.
##
## Walking only: edges and warps, tile by tile inside each outdoor zone, with the standing NPCs that are gates (a still
## NPC with hide_if or show_if) in the way exactly as the playtest bot's _routing_zones counts them, every field ability
## granted (the generous case), unbeaten trainers not blocking (they come to you), lease edges ignored. Inside an
## interior every door is taken as open. The ferries and the train are modelled by seeds: a step's flags are those of the
## steps before it, and the player starts from the town of every story step up to and including the one they are heading
## for.
##
## `flags` is a Dictionary of set flags, `seeds` an Array of zone ids. Returns {zone id: true}. Pass the same `cache`
## Dictionary to every call over the same zones: a zone explored from the same tile with the same gates standing is
## not walked again.

const DIRS := [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]

## The story as [{flags: [flags done before this step], seeds: [zone ids]}], one entry per step and one after the last.
static func story_steps(zones: Dictionary) -> Array:
	var obj = JSON.parse_string(FileAccess.get_file_as_string("res://data/objectives.json"))
	var out := []
	var done: Array = []
	var seeds: Array = []
	for s in obj.story:
		var town := str(s.get("town", ""))
		if zones.has(town) and town not in seeds:
			seeds.append(town)
		out.append({"flags": done.duplicate(), "seeds": seeds.duplicate()})
		done.append(str(s.flag_done))
	out.append({"flags": done.duplicate(), "seeds": seeds.duplicate()})
	return out

## Every flag a standing NPC is shown or hidden by: the only flags that can change what the walk finds.
static func gate_flags(zones: Dictionary) -> Dictionary:
	var out := {}
	for id in zones:
		for n in zones[id].npcs:
			if str(n.get("move", "still")) == "still" and str(n.get("trainer", "")) == "":
				for k in ["hide_if", "show_if"]:
					if n.has(k):
						out[str(n[k])] = true
	return out

static func _blockers(z: ZoneData, flags: Dictionary) -> Dictionary:
	var out := {}
	for n in z.npcs:
		if str(n.get("move", "still")) != "still" or str(n.get("trainer", "")) != "":
			continue
		if n.has("hide_if") and flags.has(str(n.hide_if)):
			continue
		if n.has("show_if") and not flags.has(str(n.show_if)):
			continue
		out[int(n.y) * z.width + int(n.x)] = true
	return out

## 0 solid, 1 walkable (a field ability counted as owned), 2 a ledge (hopped south).
static func _grid(z: ZoneData, cache: Dictionary) -> PackedByteArray:
	var key := "grid:" + z.id
	if not cache.has(key):
		var ok := PackedByteArray()
		ok.resize(z.width * z.height)
		for y in z.height:
			for x in z.width:
				var p := Vector2i(x, y)
				var t := z.tile_at(p)
				var v := 0
				if t == "ledge_south":
					v = 2
				elif not z.blocked.has(p) and (t in ZoneData.WALKABLE_TILES or ZoneData.ABILITY_TILES.has(t) or t == "bramble"):
					v = 1
				ok[y * z.width + x] = v
		cache[key] = ok
	return cache[key]

## Walk the zone from `at` with these blockers: {list: PackedInt32Array of tile indices, exits: [[zone id, tile], ...]}.
static func _explore(zones: Dictionary, z: ZoneData, at: Vector2i, blockers: Dictionary, cache: Dictionary) -> Dictionary:
	var w := z.width
	var h := z.height
	var exits := []
	if z.kind == "interior":
		for wp in z.warps:
			if zones.has(str(wp.to)):
				exits.append([str(wp.to), Vector2i(int(wp.tx), int(wp.ty))])
		return {"list": PackedInt32Array([at.y * w + at.x]), "exits": exits}
	var ok := _grid(z, cache)
	var doors := {}
	for wp in z.warps:
		doors[int(wp.y) * w + int(wp.x)] = true
	var start := z.landing_near(at, ZoneData.GATE_ABILITIES)
	var seen := PackedByteArray()
	seen.resize(w * h)
	var list := PackedInt32Array()
	var stack := [start.y * w + start.x]
	seen[stack[0]] = 1
	while not stack.is_empty():
		var i: int = stack.pop_back()
		list.append(i)
		var x := i % w
		var y := i / w
		var hi: int = z.heights[y][x]
		for d in DIRS:
			var nx: int = x + d.x
			var ny: int = y + d.y
			if nx < 0 or ny < 0 or nx >= w or ny >= h:
				continue
			var j := ny * w + nx
			if seen[j] == 1 or blockers.has(j) or doors.has(j):
				continue
			var v := ok[j]
			if v == 1:
				if absi(hi - int(z.heights[ny][nx])) > 1:
					continue
				seen[j] = 1
				stack.append(j)
			elif v == 2 and d.y == 1 and ny + 1 < h:
				var land := (ny + 1) * w + nx
				if ok[land] == 1 and seen[land] == 0 and not blockers.has(land) and not doors.has(land):
					seen[land] = 1
					stack.append(land)
	for wp in z.warps:
		var next := str(wp.to)
		if not zones.has(next):
			continue
		var wx := int(wp.x)
		var wy := int(wp.y)
		for d in DIRS:
			var nx: int = wx + d.x
			var ny: int = wy + d.y
			if nx >= 0 and ny >= 0 and nx < w and ny < h and seen[ny * w + nx] == 1:
				exits.append([next, Vector2i(int(wp.tx), int(wp.ty))])
				break
	for side in z.edges:
		var e: Dictionary = z.edges[side]
		if e.has("lease") or not zones.has(str(e.get("to", ""))):
			continue
		var target: ZoneData = zones[str(e.to)]
		for b in z._border(side):
			if seen[b.y * w + b.x] == 1:
				exits.append([target.id, z.edge_arrival(side, b, target)])
	return {"list": list, "exits": exits}

static func reach(zones: Dictionary, flags: Dictionary, seeds: Array, cache: Dictionary = {}) -> Dictionary:
	var seen := {}      # zone id -> PackedByteArray of tiles walked
	var block := {}     # zone id -> blockers
	var sig := {}       # zone id -> a string naming the blockers
	var queue: Array = []
	for s in seeds:
		queue.append([s, zones[s].spawn])
	var head := 0
	while head < queue.size():
		var item: Array = queue[head]
		head += 1
		var z: ZoneData = zones[item[0]]
		var at: Vector2i = item[1]
		if not z.in_bounds(at):
			continue
		if not seen.has(z.id):
			var bytes := PackedByteArray()
			bytes.resize(z.width * z.height)
			seen[z.id] = bytes
			block[z.id] = _blockers(z, flags)
			var ks := []
			for k in block[z.id]:
				ks.append(k)
			ks.sort()
			sig[z.id] = ",".join(PackedStringArray(ks.map(func(n): return str(n))))
		var idx := at.y * z.width + at.x
		if seen[z.id][idx] == 1:
			continue
		var key := "%s|%s|%d" % [z.id, sig[z.id], idx]
		if not cache.has(key):
			cache[key] = _explore(zones, z, at, block[z.id], cache)
		var got: Dictionary = cache[key]
		var bytes2: PackedByteArray = seen[z.id]
		for i in got.list:
			bytes2[i] = 1
		bytes2[idx] = 1
		seen[z.id] = bytes2
		for ex in got.exits:
			var tz: ZoneData = zones[ex[0]]
			var tp: Vector2i = ex[1]
			if not tz.in_bounds(tp) or (seen.has(tz.id) and seen[tz.id][tp.y * tz.width + tp.x] == 1):
				continue
			queue.append(ex)
	var out := {}
	for id in seen:
		out[id] = true
	return out
