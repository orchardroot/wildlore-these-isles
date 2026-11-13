class_name StoryWalk
extends RefCounted
## Wave 55 (roads): which zones can a player WALK to at each step of the story? Used by the sequence-break tests,
## so a new road can be shown never to open a place earlier than the story allows.
## The model: the player stands where the game starts and walks tile by tile (every field ability granted, so only
## the story's own gates count: a still NPC holds its tile unless a flag hides or shows it, a hidden or locked warp is
## shut), off an edge into the next zone or through an open warp. Rail and ferry are not walking and are left out.
## The flags at step i are every `flag_done` of data/objectives.json up to and including i; step -1 is a fresh save.

const START_ZONE := "macclesfield"
## The story never asks for a field ability on the main road (the validator checks that), so the walk has none: they
## would only let it round a gate by wading, scrambling or cutting through.
const NO_ABILITIES: Array = []
## Ferries between nations are sailed when the story sends you (a sailor's dialogue checks the flag), so they are
## not followed on their own: this table names the step flag that puts the player ashore, and where.
const ARRIVALS := {"visited_dublin": ["dublin"], "ch9_started": ["cairnryan"]}
## Flags a battle sets alongside a story flag, where a gate in the world listens for the battle's flag instead.
const IMPLIED := {"strachan1_done": ["trainer_strachan_1"], "badge_frost": ["trainer_keeper_isla"]}

## The story flags, in order, from data/objectives.json. Entry i holds the flag whose completion is step i.
static func story_flags() -> Array:
	var out := []
	var d: Dictionary = JsonUtil.read("res://data/objectives.json")
	for s in d.story:
		out.append(str(s.flag_done))
	out.append("game_complete")
	return out

static func data_at(step: int, flags: Array) -> GameStateData:
	var d := GameStateData.new()
	for i in range(0, step + 1):
		d.set_flag(str(flags[i]))
		for extra in IMPLIED.get(str(flags[i]), []):
			d.set_flag(str(extra))
	return d

## Zone ids reachable on foot with these flags. `skip` names zones to leave out of the world altogether.
static func reach(all: Dictionary, data: GameStateData, skip: Dictionary = {}) -> Dictionary:
	var covered := {}   # zone id -> {tile: true} for every tile already known reachable
	var seen_zone := {}
	var queue: Array = []
	var ferries := Travel.ferries()
	if all.has(START_ZONE):
		_see(all, skip, ferries, seen_zone, queue, START_ZONE, all[START_ZONE].spawn)
	for flag in ARRIVALS:
		if ZoneData.flag_on(data.flag(flag)):
			for zid in ARRIVALS[flag]:
				if all.has(zid) and not skip.has(zid):
					var q: ZoneData = all[zid]
					var pos: Vector2i = Vector2i(int(q.ferry.get("x", 0)), int(q.ferry.get("y", 0))) if not q.ferry.is_empty() else q.spawn
					_see(all, skip, ferries, seen_zone, queue, zid, pos)
	while not queue.is_empty():
		var item: Array = queue.pop_front()
		var z: ZoneData = all[item[0]]
		var from: Vector2i = item[1]
		var cov: Dictionary = covered.get(z.id, {})
		if cov.has(from):
			continue
		_src = "from %s" % z.id
		var region := z.reachable(from, NO_ABILITIES, _held(z, data))
		cov.merge(region)
		covered[z.id] = cov
		for side in z.edges:
			var to := str(z.edges[side].get("to", ""))
			if not all.has(to) or skip.has(to):
				continue
			for t in _border(z, str(side)):
				if region.has(t):
					var target: ZoneData = all[to]
					var arrive := target.landing_near(z.edge_arrival(str(side), t, target), NO_ABILITIES)
					_see(all, skip, ferries, seen_zone, queue, to, arrive)
		for w in z.warps:
			var to := str(w.get("to", ""))
			if not all.has(to) or skip.has(to) or ZoneData.warp_state(w, data) != "open":
				continue
			if region.has(Vector2i(int(w.x), int(w.y))):
				_see(all, skip, ferries, seen_zone, queue, to, Vector2i(int(w.tx), int(w.ty)))
	return seen_zone

## Arrive in `zid` at `at`. The first time a zone is seen the player has also been to its station (the train takes
## you to any station you know) and, within Scotland, to the far end of each of its ferries, so they start walks too.
static func _see(all: Dictionary, skip: Dictionary, ferries: Dictionary, seen: Dictionary, queue: Array, zid: String, at: Vector2i) -> void:
	queue.append([zid, at])
	if seen.has(zid):
		return
	seen[zid] = true
	via[zid] = _src
	var z: ZoneData = all[zid]
	if z.station != Vector2i(-1, -1):
		queue.append([zid, z.station])
	for route in ferries:
		var r: Dictionary = ferries[route]
		if str(r.get("a", "")) != zid and str(r.get("b", "")) != zid:
			continue
		var far := str(r.get("b", "")) if str(r.get("a", "")) == zid else str(r.get("a", ""))
		if all.has(far) and not skip.has(far) and z.region == "scotland" and all[far].region == "scotland":
			var f: ZoneData = all[far]
			_see(all, skip, ferries, seen, queue, far, Vector2i(int(f.ferry.get("x", 0)), int(f.ferry.get("y", 0))) if not f.ferry.is_empty() else f.spawn)

## Tiles a still NPC stands on at these flags (they block).
static func _held(z: ZoneData, data: GameStateData) -> Dictionary:
	var out := {}
	for n in z.npcs:
		if str(n.get("move", "still")) != "still":
			continue
		# as Npc.should_spawn: "hide_if" is gone once its flag is set, "show_if" is there only once its flag is
		if n.has("hide_if") and ZoneData.flag_on(data.flag(str(n.hide_if))):
			continue
		if n.has("show_if") and not ZoneData.flag_on(data.flag(str(n.show_if))):
			continue
		out[Vector2i(int(n.x), int(n.y))] = true
	return out

static func _border(z: ZoneData, side: String) -> Array:
	var out := []
	match side:
		"north":
			for x in z.width:
				out.append(Vector2i(x, 0))
		"south":
			for x in z.width:
				out.append(Vector2i(x, z.height - 1))
		"west":
			for y in z.height:
				out.append(Vector2i(0, y))
		_:
			for y in z.height:
				out.append(Vector2i(z.width - 1, y))
	return out

## {zone id: first step (0 is a fresh save... -1) at which it can be walked to} for every zone ever reached, outdoors
## and in. Steps are -1 (nothing done) up to the last flag.
static func first_steps(all: Dictionary, skip: Dictionary = {}) -> Dictionary:
	var flags := story_flags()
	var out := {}
	var last_sig := ""
	var last: Dictionary = {}
	for step in range(-1, flags.size()):
		var data := data_at(step, flags)
		var sig := _signature(all, data)
		if sig != last_sig:
			last = reach(all, data, skip)
			last_sig = sig
		for zid in last:
			if not out.has(zid):
				out[zid] = step
	return out

## What the flags change about the world's gates: which gating flags are on. Steps with the same answer reach the same zones.
static func _signature(all: Dictionary, data: GameStateData) -> String:
	if _gating == []:
		_find_gating(all)
	var s := ""
	for f in _gating:
		s += "1" if ZoneData.flag_on(data.flag(f)) or int(data.bag.get(f, 0)) > 0 else "0"
	return s

static var _gating: Array = []
## How each zone was first reached (for debugging): zone id -> "from <zone> by <edge/warp/ferry/rail>".
static var via: Dictionary = {}
static var _src := ""

static func _find_gating(all: Dictionary) -> void:
	var seen := {}
	for zid in all:
		var z: ZoneData = all[zid]
		for n in z.npcs:
			for k in ["hide_if", "show_if"]:
				if n.has(k):
					seen[str(n[k])] = true
		for w in z.warps:
			var h = w.get("hidden")
			if h is Dictionary:
				seen[str(h.get("reveal", ""))] = true
			var l = w.get("locked")
			if l is Dictionary:
				seen[str(l.get("needs", ""))] = true
	for f in ARRIVALS:
		seen[f] = true
	_gating = seen.keys()
	_gating.sort()
