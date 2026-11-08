class_name DeepPlace
extends RefCounted
## The Deep Places kit: four puzzle verbs for caves, mines and vaults, all pure rules over a zone's "deep" block.
##   "deep": {
##     "levers": [{"id", "x", "y", "needs_light": false, "on": "line", "off": "line", "look"?}],
##     "plates": [{"id", "x", "y", "weight": "crate" | "any"}],
##     "crates": [{"id", "x", "y", "look"?}],
##     "gates":  [{"id", "x", "y", "by": ["lever:a", "!lever:b", "plate:p"], "line": "It's shut.", "look"?}],
##     "floods": [{"id", "by": [...], "tiles": [[x, y], ...]}]   # water until the condition holds, then shallows
##   }
## Lever and gate: pull a lever (flag dp_<zone>_<id>) and every gate whose "by" list is met opens ("!" means off).
## Weight on plate: a crate pushed onto a plate (or you, for weight "any") latches it for good, so leaving never
## strands you; the crates themselves reset when you come back in. Light and dark: a lever with needs_light is only
## found by Lantern light. Water level: flood tiles are deep water (Brook-wade crosses them) until drained.
## State lives in flags, so old saves need nothing. A closed gate is a solid prop on the room's own floor, drawn as
## what its line says (LOOKS, look_of); an open one is just that floor. The overworld rebuilds the scenery after a
## change (see DeepScene), and facing a closed gate reads its line.

const GATE_PROP := "deep_gate"
const CRATE_PROP := "deep_crate"
const LEVER_PROP := "deep_lever"
const PLATE_PROP := "deep_plate"
## What each piece can be drawn as (DeepMeshes). A piece's "look" picks one; without it the look comes from the
## words of its line (LOOK_WORDS, first match), or its id for a crate, and failing that the first in the list.
const LOOKS := {
	GATE_PROP: ["cave_gate", "grille", "timber_gate", "barrier", "oak_door", "slab", "basalt_slab", "flowstone"],
	LEVER_PROP: ["lever", "wheel", "winch", "board", "handle", "column", "crack"],
	CRATE_PROP: ["block", "boulder", "tub", "slab", "column"],
	PLATE_PROP: ["plate"],
}
const LOOK_WORDS := {
	GATE_PROP: [["grille", "grille"], ["timber", "timber_gate"], ["barrier", "barrier"], ["door", "oak_door"],
		["flowstone", "flowstone"], ["basalt", "basalt_slab"], ["slab", "slab"], ["gate", "cave_gate"]],
	LEVER_PROP: [["column", "column"], ["winch", "winch"], ["wheel", "wheel"], ["valve", "wheel"], ["sluice", "wheel"],
		["board", "board"], ["handle", "handle"], ["lever", "lever"], ["crack", "crack"], ["hollow", "crack"],
		["niche", "crack"], ["pocket", "crack"]],
	CRATE_PROP: [["boulder", "boulder"], ["tram", "tub"], ["tub", "tub"], ["column", "column"], ["slab", "slab"],
		["block", "block"]],
}

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

## What a piece is drawn as: its "look", else the first LOOK_WORDS word in its line (a crate: its id), else the
## kind's first look. A lever that wants the Lantern and has no other word is a crack in the rock.
static func look_of(kind: String, item: Dictionary) -> String:
	if item.has("look"):
		return str(item.look)
	var text := str(item.get("id", "")) if kind == CRATE_PROP else str(item.get("line", item.get("on", "")))
	var words := []
	for w in text.to_lower().replace("_", " ").replace("'", " ").split(" ", false):
		words.append(w.strip_edges().rstrip(".,;:!?"))
	for pair in LOOK_WORDS.get(kind, []):
		for w in words:
			if w == pair[0] or w == pair[0] + "s":
				return str(pair[1])
	if kind == LEVER_PROP and bool(item.get("needs_light", false)):
		return "crack"
	return str(LOOKS[kind][0])

## The prop variant for a piece: its look's index, times two, plus one when pulled or pressed (DeepMeshes).
static func variant_of(kind: String, item: Dictionary, on := false) -> int:
	return maxi(LOOKS[kind].find(look_of(kind, item)), 0) * 2 + int(on)

## Puts flood tiles, gates, levers, plates and crates in the state the flags say. Safe to call again.
static func apply(data: GameStateData, zone: ZoneData, crates: Dictionary) -> void:
	if zone.deep.is_empty():
		return
	for f in zone.deep.get("floods", []):
		var drained := cond_met(data, zone.id, f.get("by", []))
		for t in f.tiles:
			_set_tile(zone, Vector2i(int(t[0]), int(t[1])), "shallow" if drained else "deep_water")
	zone.props = zone.props.filter(func(pr): return not pr.get("deep", false))
	for p in zone.deep_solid:
		zone.blocked.erase(p)
	zone.deep_solid.clear()
	for g in zone.deep.get("gates", []):
		var at := Vector2i(int(g.x), int(g.y))
		if not gate_open(data, zone.id, g):
			_add_prop(zone, GATE_PROP, at, true, variant_of(GATE_PROP, g))
	for l in zone.deep.get("levers", []):
		_add_prop(zone, LEVER_PROP, Vector2i(int(l.x), int(l.y)), true, variant_of(LEVER_PROP, l, is_on(data, zone.id, str(l.id))))
	for pl in zone.deep.get("plates", []):
		_add_prop(zone, PLATE_PROP, Vector2i(int(pl.x), int(pl.y)), false, variant_of(PLATE_PROP, pl, is_on(data, zone.id, str(pl.id))))
	var looks := {}
	for c in zone.deep.get("crates", []):
		looks[str(c.id)] = variant_of(CRATE_PROP, c)
	for id in crates:
		_add_prop(zone, CRATE_PROP, crates[id], true, int(looks.get(str(id), 0)))

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
	for kind in [GATE_PROP, LEVER_PROP, CRATE_PROP]:
		for it in zone.deep.get(kind.trim_prefix("deep_") + "s", []):
			if it.has("look") and str(it.look) not in LOOKS[kind]:
				e.append(tag + "%s at %d,%d has look '%s', not one of %s" % [kind, int(it.x), int(it.y), str(it.look), str(LOOKS[kind])])
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
