class_name DeepPlace
extends RefCounted
## The Deep Places kit: four puzzle verbs for caves, mines and vaults, all pure rules over a zone's "deep" block.
##   "deep": {
##     "levers": [{"id", "x", "y", "needs_light": false, "on": "line", "off": "line"}],
##     "plates": [{"id", "x", "y", "weight": "crate" | "any"}],
##     "crates": [{"id", "x", "y"}],
##     "gates":  [{"id", "x", "y", "by": ["lever:a", "!lever:b", "plate:p"], "line": "It's shut."}],
##     "floods": [{"id", "by": [...], "tiles": [[x, y], ...]}]   # water until the condition holds, then shallows
##   }
## Lever and gate: pull a lever (flag dp_<zone>_<id>) and every gate whose "by" list is met opens ("!" means off).
## Weight on plate: a crate pushed onto a plate (or you, for weight "any") latches it for good, so leaving never
## strands you; the crates themselves reset when you come back in. Light and dark: a lever with needs_light is only
## found by Lantern light. Water level: flood tiles are deep water (Brook-wade crosses them) until drained.
## State lives in flags, so old saves need nothing. Closed gates are fence tiles, open ones path; the overworld
## rebuilds the scenery after a change (see DeepScene).

const GATE_CLOSED := "fence"
const GATE_OPEN := "path"
const CRATE_PROP := "slate_stack"
const LEVER_PROP := "lever"
const PLATE_PROP := "limestone_pavement"

static func flag_key(zone_id: String, id: String) -> String:
	return "dp_%s_%s" % [zone_id, id]

static func is_on(data: GameStateData, zone_id: String, id: String) -> bool:
	return data.flag(flag_key(zone_id, id)) == true

## "lever:a" is met when the lever is on, "!lever:a" when it is off; plates are the same ("plate:p").
static func cond_met(data: GameStateData, zone_id: String, by: Array) -> bool:
	for c in by:
		var s := str(c)
		var want := not s.begins_with("!")
		if want == false:
			s = s.substr(1)
		var id := s.get_slice(":", 1)
		if is_on(data, zone_id, id) != want:
			return false
	return true

static func gate_open(data: GameStateData, zone_id: String, gate: Dictionary) -> bool:
	return cond_met(data, zone_id, gate.get("by", []))

static func lever_at(zone: ZoneData, p: Vector2i) -> Dictionary:
	for l in zone.deep.get("levers", []):
		if int(l.x) == p.x and int(l.y) == p.y:
			return l
	return {}

static func gate_at(zone: ZoneData, p: Vector2i) -> Dictionary:
	for g in zone.deep.get("gates", []):
		if int(g.x) == p.x and int(g.y) == p.y:
			return g
	return {}

## Pulls (toggles) a lever; returns its new state.
static func pull(data: GameStateData, zone_id: String, lever: Dictionary) -> bool:
	var now := not is_on(data, zone_id, str(lever.id))
	data.set_flag(flag_key(zone_id, str(lever.id)), now)
	return now

## Lantern radius: a lever with needs_light can only be found where your light reaches (always in a lit zone).
static func can_find(data: GameStateData, zone: ZoneData, lever: Dictionary) -> bool:
	return not (zone.dark and bool(lever.get("needs_light", false))) or FieldMoves.has(data, "lantern")

# --- crates -----------------------------------------------------------------

## id -> tile, where every crate starts.
static func crates_start(zone: ZoneData) -> Dictionary:
	var out := {}
	for c in zone.deep.get("crates", []):
		out[str(c.id)] = Vector2i(int(c.x), int(c.y))
	return out

static func crate_at(crates: Dictionary, p: Vector2i) -> String:
	for id in crates:
		if crates[id] == p:
			return str(id)
	return ""

## Can the crate at `p` be pushed one tile in `dir`? It needs plain floor beyond, with no crate, lever or gate on it.
static func can_push(zone: ZoneData, crates: Dictionary, p: Vector2i, dir: Vector2i) -> bool:
	if crate_at(crates, p) == "":
		return false
	var to := p + dir
	if not zone.in_bounds(to) or zone.tile_at(to) in ["deep_water", "ledge_south", "door"]:
		return false
	var pushed := crates.duplicate()
	pushed.erase(crate_at(crates, p))
	return zone.walkable(to) and crate_at(pushed, to) == "" and zone.warp_at(to).is_empty() and zone.sign_at(to).is_empty() \
		and lever_at(zone, to).is_empty() and gate_at(zone, to).is_empty()

static func push(zone: ZoneData, crates: Dictionary, p: Vector2i, dir: Vector2i) -> void:
	crates[crate_at(crates, p)] = p + dir

## Latches every plate that has its weight on it now. Returns the ids newly pressed.
static func press_plates(data: GameStateData, zone: ZoneData, crates: Dictionary, player_pos: Vector2i) -> Array:
	var out := []
	for pl in zone.deep.get("plates", []):
		var id := str(pl.id)
		if is_on(data, zone.id, id):
			continue
		var at := Vector2i(int(pl.x), int(pl.y))
		if crate_at(crates, at) != "" or (str(pl.get("weight", "crate")) == "any" and player_pos == at):
			data.set_flag(flag_key(zone.id, id), true)
			out.append(id)
	return out

# --- the scenery ------------------------------------------------------------

## Sets gate and flood tiles to match the flags, and puts the crates where they stand now. Safe to call again.
static func apply(data: GameStateData, zone: ZoneData, crates: Dictionary) -> void:
	if zone.deep.is_empty():
		return
	for g in zone.deep.get("gates", []):
		_set_tile(zone, Vector2i(int(g.x), int(g.y)), GATE_OPEN if gate_open(data, zone.id, g) else GATE_CLOSED)
	for f in zone.deep.get("floods", []):
		var drained := cond_met(data, zone.id, f.get("by", []))
		for t in f.tiles:
			_set_tile(zone, Vector2i(int(t[0]), int(t[1])), "shallow" if drained else "deep_water")
	zone.props = zone.props.filter(func(pr): return not pr.get("deep", false))
	for p in zone.deep_solid:
		zone.blocked.erase(p)
	zone.deep_solid.clear()
	for l in zone.deep.get("levers", []):
		_add_prop(zone, LEVER_PROP, Vector2i(int(l.x), int(l.y)), true, 1 if is_on(data, zone.id, str(l.id)) else 0)
	for pl in zone.deep.get("plates", []):
		_add_prop(zone, PLATE_PROP, Vector2i(int(pl.x), int(pl.y)), false)
	for id in crates:
		_add_prop(zone, CRATE_PROP, crates[id], true)

static func _set_tile(zone: ZoneData, p: Vector2i, tile: String) -> void:
	if zone.in_bounds(p):
		zone.tiles[p.y][p.x] = tile

static func _add_prop(zone: ZoneData, type: String, p: Vector2i, solid: bool, variant := 0) -> void:
	zone.props.append({"type": type, "x": p.x, "y": p.y, "walk": not solid, "deep": true, "variant": variant})
	if solid:
		zone.blocked[p] = true
		zone.deep_solid.append(p)

# --- checks -----------------------------------------------------------------

## Problems with a zone's deep block (the validator calls this): ids unique, everything in bounds, and with every
## gate open and every flood drained (the file as written) the spawn still reaches each warp, lever, plate and crate.
static func problems(zone: ZoneData) -> Array:
	var e := []
	if zone.deep.is_empty():
		return e
	var tag := "zone %s: deep " % zone.id
	var seen := {}
	for kind in ["levers", "plates", "crates", "gates", "floods"]:
		for it in zone.deep.get(kind, []):
			if kind != "gates":
				var id := str(it.get("id", ""))
				if id == "" or seen.has(id):
					e.append(tag + "%s id '%s' is empty or repeated" % [kind, id])
				seen[id] = true
			var pts: Array = it.get("tiles", [[int(it.get("x", -1)), int(it.get("y", -1))]])
			for t in pts:
				if not zone.in_bounds(Vector2i(int(t[0]), int(t[1]))):
					e.append(tag + "%s entry at %s is out of bounds" % [kind, str(t)])
	for g in zone.deep.get("gates", []):
		for c in g.get("by", []):
			var id := str(c).trim_prefix("!").get_slice(":", 1)
			if not seen.has(id):
				e.append(tag + "gate at %d,%d names unknown '%s'" % [int(g.x), int(g.y), id])
	if not e.is_empty() or not zone.walkable(zone.spawn):
		return e
	var reach := zone.reachable(zone.spawn, ZoneData.GATE_ABILITIES)  # as loaded, gate and flood tiles are open floor
	for w in zone.warps:
		if not reach.has(Vector2i(int(w.x), int(w.y))):
			e.append(tag + "warp at %d,%d can't be reached even with every gate open" % [int(w.x), int(w.y)])
	for kind in ["levers", "plates"]:
		for it in zone.deep.get(kind, []):
			var near := false
			for d in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				near = near or reach.has(Vector2i(int(it.x), int(it.y)) + d)
			if not near:
				e.append(tag + "%s '%s' can't be reached" % [kind, str(it.id)])
	return e
