class_name ZoneData
extends RefCounted
## One zone (town, route, interior, dungeon) parsed from data/zones/<id>.json. Grid rules live here; rendering lives in ZoneBuilder.

const DIR := "res://data/zones"
## char -> [tile name, walkable]
const LEGEND := {
	".": ["grass", true], ",": ["tall_grass", true], "#": ["path", true], "=": ["road", true],
	":": ["cobbles", true], "s": ["sand", true], "f": ["flowers", true], "~": ["water", false],
	"w": ["shallow", true], "T": ["tree_oak", false], "P": ["tree_pine", false], "H": ["hedge", false],
	"W": ["drystone_wall", false], "F": ["fence", false], "R": ["rock", false], "^": ["cliff", false],
	"B": ["building", false], "D": ["door", true], "x": ["void", false], "|": ["floor_wood", true],
	"+": ["floor_tile", true], "C": ["counter", false], "L": ["ledge_south", false],
	"%": ["bramble", false], "o": ["deep_water", false], "/": ["scree", false], "_": ["platform", true],
	"!": ["rail", false], "$": ["sea", false], "*": ["bog", false], "&": ["level_crossing", true],
}
const WALKABLE_TILES := ["grass", "tall_grass", "path", "road", "cobbles", "sand", "flowers", "shallow", "door", "floor_wood", "floor_tile", "platform", "level_crossing"]
## Tiles a field ability lets you cross (bramble is different: Hedge-lay removes it for good).
const ABILITY_TILES := {"deep_water": "brook_wade", "scree": "fell_scramble", "bog": "bog_cross"}
const GATE_ABILITIES := ["hedge_lay", "brook_wade", "fell_scramble", "bog_cross"]
## Track: a level crossing is rail you can walk over. Every line end needs one of RAIL_CAPS (or the map edge).
const RAIL_TILES := ["rail", "level_crossing"]
const RAIL_CAPS := ["buffer_stop", "tunnel_portal"]
## Dev zones that may break the rail rules.
const RAIL_RULE_EXEMPT := ["mesh_gallery", "testbed"]
const OPPOSITE := {"north": "south", "south": "north", "east": "west", "west": "east"}
## How far (tiles, square) a "wander" NPC strays from where it stands; an NPC's "radius" overrides it.
const WANDER_RADIUS := 2
const STEPS := {"up": Vector2i(0, -1), "down": Vector2i(0, 1), "left": Vector2i(-1, 0), "right": Vector2i(1, 0)}

var id := ""
var name := ""
var region := ""
var kind := "route"
var music := ""
var weather: Dictionary = {}
var width := 0
var height := 0
var chars: Array = []      # rows of single-char strings as written
var tiles: Array = []      # rows of tile names
var heights: Array = []    # rows of ints
var legend_extra: Dictionary = {}
var props: Array = []
var warps: Array = []
var examine: Array = []        # [{x, y, text, find?, money?, flag?, needs?, evidence?}] see Examine
var edges: Dictionary = {}
var npcs: Array = []
var encounters: Dictionary = {}
var signs: Array = []
var spawn := Vector2i.ZERO
var parse_errors: Array = []
var blocked: Dictionary = {}   # Vector2i -> true for point props (lamp posts, benches, stalls)
var stage := ""                # battle diorama id ("" = guess from kind)
var town_id := ""              # world map and rail id; "" for routes and interiors
var station := Vector2i(-1, -1)  # rail stop tile, (-1, -1) for none
var ferry: Dictionary = {}     # {x, y, route}
var stub := false              # a placeholder another builder will replace
var viaducts: Array = []      # scenery viaducts across the zone (see Viaduct)
var scaled_floor := -1        # off the main line: encounters authored at this par, lifted with the story (ParLevel); -1 = fixed
var dark := false              # a cave: only a circle of light round the player (wider with the Lantern)
var deep_solid: Array = []    # tiles DeepPlace made solid (levers, crates), cleared on each re-apply
var deep: Dictionary = {}     # a Deep Place's puzzle pieces (see DeepPlace)
var ambience := ""             # ambience bed override (an Ambience.BEDS id, or "none"); "" = pick from kind/stage

static func load_id(zone_id: String) -> ZoneData:
	var d = JsonUtil.read(DIR.path_join(zone_id + ".json"))
	return from_dict(d if d is Dictionary else {"id": zone_id})

static func load_all() -> Dictionary:
	var out := {}
	for path in JsonUtil.list_json(DIR):
		var d = JsonUtil.read(path)
		if d is Dictionary:
			var z := from_dict(d)
			out[z.id] = z
	return out

static func from_dict(d: Dictionary) -> ZoneData:
	var z := ZoneData.new()
	z.id = d.get("id", "")
	z.name = d.get("name", z.id)
	z.region = d.get("region", "")
	z.kind = d.get("kind", "route")
	z.music = d.get("music", "")
	z.weather = d.get("weather", {})
	z.legend_extra = d.get("legend_extra", {})
	z.props = d.get("props", [])
	z.warps = d.get("warps", [])
	z.examine = d.get("examine", [])
	z.edges = d.get("edges", {})
	z.npcs = d.get("npcs", [])
	z.encounters = d.get("encounters", {})
	z.signs = d.get("signs", [])
	z.stage = str(d.get("stage", ""))
	z.town_id = str(d.get("town_id", ""))
	var stn: Dictionary = d.get("station", {})
	if not stn.is_empty():
		z.station = Vector2i(int(stn.x), int(stn.y))
	z.ferry = d.get("ferry", {})
	z.stub = bool(d.get("stub", false))
	z.dark = bool(d.get("dark", false))
	z.deep = d.get("deep", {})
	z.scaled_floor = int(d.get("scaled_floor", -1))
	z.viaducts = d.get("viaducts", [])
	z.ambience = str(d.get("ambience", ""))
	var sp: Array = d.get("spawn", [0, 0])
	z.spawn = Vector2i(int(sp[0]), int(sp[1]))
	for p in z.props:
		if p.get("type", "") != "building" and not p.get("walk", false):
			z.blocked[Vector2i(int(p.get("x", 0)), int(p.get("y", 0)))] = true
	for sg in z.signs:
		z.blocked[Vector2i(int(sg.get("x", 0)), int(sg.get("y", 0)))] = true
	var rows: Array = d.get("rows", [])
	z.height = rows.size()
	z.width = 0
	for r in rows:
		z.width = maxi(z.width, str(r).length())
	for y in rows.size():
		var row: String = rows[y]
		if row.length() != z.width:
			z.parse_errors.append("row %d is ragged (%d wide, expected %d)" % [y, row.length(), z.width])
		var crow := []
		var trow := []
		for x in z.width:
			var c := row[x] if x < row.length() else "x"
			crow.append(c)
			var t := z._tile_for_char(c)
			if t == "":
				z.parse_errors.append("unknown tile char '%s' at %d,%d" % [c, x, y])
				t = "void"
			trow.append(t)
		z.chars.append(crow)
		z.tiles.append(trow)
	var hrows: Array = d.get("heights", [])
	if not hrows.is_empty() and (hrows.size() != z.height):
		z.parse_errors.append("heights has %d rows, expected %d" % [hrows.size(), z.height])
	for y in z.height:
		var hrow := []
		var src: String = hrows[y] if y < hrows.size() else ""
		if src != "" and src.length() != z.width:
			z.parse_errors.append("heights row %d is %d wide, expected %d" % [y, src.length(), z.width])
		for x in z.width:
			hrow.append(int(src[x]) if x < src.length() and src[x].is_valid_int() else int(d.get("ground_height", 0)))
		z.heights.append(hrow)
	Leases.shape(z)  # an Enclosure lease anchored here: its gap in the border and the edge into the lease zone
	return z

func _tile_for_char(c: String) -> String:
	if legend_extra.has(c):
		return str(legend_extra[c].get("tile", ""))
	if LEGEND.has(c):
		return LEGEND[c][0]
	return ""

func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < width and p.y < height

func tile_at(p: Vector2i) -> String:
	return tiles[p.y][p.x] if in_bounds(p) else ""

func char_at(p: Vector2i) -> String:
	return chars[p.y][p.x] if in_bounds(p) else ""

func height_at(p: Vector2i) -> int:
	return heights[p.y][p.x] if in_bounds(p) else 0

## Can the player stand on p, arriving by moving `from_dir`? NPC occupancy is the overworld's job.
## `abilities` are the field abilities the player has (FieldMoves.abilities).
func walkable(p: Vector2i, from_dir := Vector2i.ZERO, abilities: Array = []) -> bool:
	if not in_bounds(p):
		return false
	var t := tile_at(p)
	if t == "ledge_south":
		return from_dir == Vector2i(0, 1)
	var by_ability: bool = ABILITY_TILES.has(t) and ABILITY_TILES[t] in abilities
	if (t not in WALKABLE_TILES and not by_ability) or blocked.has(p):
		return false
	if from_dir != Vector2i.ZERO:
		var prev := p - from_dir
		if in_bounds(prev) and absi(height_at(prev) - height_at(p)) > 1:
			return false
	return true

## Where to set the player down for an arrival at p. Overlays applied on load (a lease's fence across the anchor's
## gap, a closed Deep Place gate on a warp's landing tile) can leave p unstandable; this is the nearest tile that
## is, searching outward ring by ring (ties go to the first found, scanning up then left). p itself if it will do.
func landing_near(p: Vector2i, abilities: Array = [], max_ring := 8) -> Vector2i:
	if not in_bounds(p) or walkable(p, Vector2i.ZERO, abilities) or tile_at(p) == "ledge_south":
		return p
	for r in range(1, max_ring + 1):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var q := p + Vector2i(dx, dy)
				if walkable(q, Vector2i.ZERO, abilities):
					return q
	return p

## Hedge-lay: the bramble at p becomes grass (the overworld re-applies cut flags on load).
func cut(p: Vector2i) -> void:
	if tile_at(p) == "bramble":
		tiles[p.y][p.x] = "grass"
		chars[p.y][p.x] = "."

## Every tile reachable on foot from `from` with these abilities (bramble passable with hedge_lay).
## Ledges are hopped south; warps and edges are not followed (this zone only).
func reachable(from: Vector2i, abilities: Array = [], also_blocked: Dictionary = {}) -> Dictionary:
	var seen := {from: true}
	var queue: Array = [from]
	while not queue.is_empty():
		var p: Vector2i = queue.pop_front()
		for d in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
			var q: Vector2i = p + d
			if seen.has(q) or not in_bounds(q) or also_blocked.has(q):
				continue
			var ok := walkable(q, d, abilities)
			if not ok and tile_at(q) == "bramble" and "hedge_lay" in abilities and not blocked.has(q):
				ok = true
			if not ok and tile_at(q) == "ledge_south" and d == Vector2i(0, 1):
				var land: Vector2i = q + d
				if walkable(land, d, abilities) and not seen.has(land):
					seen[land] = true
					queue.append(land)
				continue
			if ok:
				seen[q] = true
				queue.append(q)
	return seen

## A warp lands you on `p`: can you take even one step from there that isn't on to a warp? Stepping on to a
## warp sends you straight back out, so a doorstep hemmed in by signs, props and walls makes the whole zone
## unreachable (Galway Docks, 4.5.0: a plaque beside the arrival tile kept everyone out of the Tide Stone fight).
func doorstep_boxed_in(p: Vector2i) -> bool:
	var doors := {}
	for w in warps:
		doors[Vector2i(int(w.x), int(w.y))] = true
	return reachable(p, GATE_ABILITIES, doors).size() <= 1

## Tiles held by NPCs that never move and are never hidden by a flag (they block for good).
func _standing_npcs() -> Dictionary:
	var out := {}
	for n in npcs:
		if str(n.get("move", "still")) == "still" and not n.has("hide_if") and not n.has("show_if"):
			out[Vector2i(int(n.x), int(n.y))] = true
	return out

## Every tile a moving NPC may stand on: a wanderer's square (as far as it can walk inside it), a pacer's beat.
## A still NPC just its own tile.
func roam_tiles(n: Dictionary) -> Array:
	var home := Vector2i(int(n.get("x", 0)), int(n.get("y", 0)))
	match str(n.get("move", "still")):
		"wander":
			var r := int(n.get("radius", WANDER_RADIUS))
			var seen := {home: true}
			var queue: Array = [home]
			while not queue.is_empty():
				var p: Vector2i = queue.pop_front()
				for d in STEPS.values():
					var q: Vector2i = p + d
					if seen.has(q) or maxi(absi(q.x - home.x), absi(q.y - home.y)) > r or not walkable(q, d):
						continue
					if not warp_at(q).is_empty():
						continue  # NPCs never step on to a warp
					seen[q] = true
					queue.append(q)
			var out := seen.keys()
			out.sort()
			return out
		"pace":
			var out := [home]
			var p := home
			for d in n.get("path", []):
				p += STEPS.get(str(d), Vector2i.ZERO)
				if p not in out:
					out.append(p)
			return out
	return [home]

const GAP_DETOUR := 3  # tiles: how far round a "gap" check looks for a way past

## A walkable tile someone standing on would cork: the ways in and out of it don't meet again close by
## (a lane between buildings, a gap in a wall, a bridge). A dead end isn't a gap.
func is_gap(p: Vector2i) -> bool:
	if not walkable(p):
		return false
	var ways := []
	for d in STEPS.values():
		if walkable(p + d, d) and walkable(p, -d):
			ways.append(p + d)
	if ways.size() < 2:
		return false
	var seen := {ways[0]: true}
	var queue: Array = [ways[0]]
	while not queue.is_empty():
		var q: Vector2i = queue.pop_front()
		for d in STEPS.values():
			var r: Vector2i = q + d
			if r == p or seen.has(r) or maxi(absi(r.x - p.x), absi(r.y - p.y)) > GAP_DETOUR or not walkable(r, d):
				continue
			seen[r] = true
			queue.append(r)
	for w in ways:
		if not seen.has(w):
			return true
	return false

## Wanderers and pacers must never cork the way: nowhere on their beat may they stand next to a warp (a
## doorstep, a cave mouth), on the station or ferry tile, or in a one-tile gap (a lane, a wall gap, a bridge).
## What's wrong with NPC n's beat, or "".
func roamer_problem(n: Dictionary) -> String:
	if str(n.get("move", "still")) == "still":
		return ""
	var keep_clear := {}
	for w in warps:
		var wp := Vector2i(int(w.x), int(w.y))
		for d in STEPS.values():
			keep_clear[wp + d] = "the doorstep of the warp at %d,%d" % [wp.x, wp.y]
	if station != Vector2i(-1, -1):
		keep_clear[station] = "the station tile"
	if not ferry.is_empty():
		keep_clear[Vector2i(int(ferry.get("x", -1)), int(ferry.get("y", -1)))] = "the ferry quay"
	var home := Vector2i(int(n.get("x", 0)), int(n.get("y", 0)))
	for p in roam_tiles(n):
		if keep_clear.has(p):
			return "can wander on to %s (at %d,%d)" % [keep_clear[p], p.x, p.y]
		if p != home and is_gap(p):
			return "can wander into a one-tile gap at %d,%d" % [p.x, p.y]
	return ""

func _roamer_errors(tag: String) -> Array:
	var e := []
	for n in npcs:
		var why := roamer_problem(n)
		if why != "":
			e.append(tag + "npc '%s' %s" % [n.get("id", "?"), why])
	return e

func _border(side: String) -> Array:
	var out := []
	match side:
		"north":
			for x in width: out.append(Vector2i(x, 0))
		"south":
			for x in width: out.append(Vector2i(x, height - 1))
		"west":
			for y in height: out.append(Vector2i(0, y))
		"east":
			for y in height: out.append(Vector2i(width - 1, y))
	return out

func _side_reached(side: String, seen: Dictionary) -> bool:
	for p in seen:
		if (side == "north" and p.y == 0) or (side == "south" and p.y == height - 1) \
				or (side == "west" and p.x == 0) or (side == "east" and p.x == width - 1):
			return true
	return false

## Where a ledge hop lands: the first walkable tile south of the ledge.
func ledge_landing(p: Vector2i) -> Vector2i:
	var q := p + Vector2i(0, 1)
	return q

## The building prop covering tile `p`, or {}.
func building_at(p: Vector2i) -> Dictionary:
	for pr in props:
		if pr.get("type") == "building" and p.x >= int(pr.x) and p.x < int(pr.x) + int(pr.w) and p.y >= int(pr.y) and p.y < int(pr.y) + int(pr.h):
			return pr
	return {}

func warp_at(p: Vector2i) -> Dictionary:
	for w in warps:
		if int(w.x) == p.x and int(w.y) == p.y:
			return w
	return {}

## "open", "locked" or "hidden" for a warp: a "hidden" warp ({"reveal": flag}) isn't there until the flag is set, a
## "locked" one ({"needs": flag or item id, "line"}) says its line until you have the key. Old warps are always open.
static func warp_state(w: Dictionary, data: GameStateData) -> String:
	var h = w.get("hidden")
	if h is Dictionary and not flag_on(data.flag(str(h.get("reveal", "")))):
		return "hidden"
	var l = w.get("locked")
	if l is Dictionary and not has_key(data, str(l.get("needs", ""))):
		return "locked"
	return "open"

## A flag that is set, or an item in the bag.
static func has_key(data: GameStateData, need: String) -> bool:
	return need == "" or flag_on(data.flag(need)) or int(data.bag.get(need, 0)) > 0

static func flag_on(v: Variant) -> bool:
	return false if v == null else (v if v is bool else (v != 0 if v is int else true))

## The examine spot on tile `p`, or {}.
func examine_at(p: Vector2i) -> Dictionary:
	for ex in examine:
		if int(ex.x) == p.x and int(ex.y) == p.y:
			return ex
	return {}

func sign_at(p: Vector2i) -> Dictionary:
	for s in signs:
		if int(s.x) == p.x and int(s.y) == p.y:
			return s
	return {}

## Arrival tile when walking off `side` of this zone into its neighbour.
func edge_arrival(side: String, p: Vector2i, target: ZoneData) -> Vector2i:
	var off := int(edges[side].get("offset", 0))
	match side:
		"north":
			return Vector2i(p.x + off, target.height - 1)
		"south":
			return Vector2i(p.x + off, 0)
		"west":
			return Vector2i(target.width - 1, p.y + off)
		_:
			return Vector2i(0, p.y + off)

func validate(all: Dictionary) -> Array:
	var e := parse_errors.duplicate()
	var tag := "zone %s: " % id
	for i in e.size():
		e[i] = tag + e[i]
	if not walkable(spawn):
		e.append(tag + "spawn %s is not walkable" % spawn)
	for w in warps:
		var target: String = w.get("to", "")
		if not all.has(target):
			e.append(tag + "warp at %d,%d goes to unknown zone '%s'" % [int(w.x), int(w.y), target])
		elif not all[target].walkable(Vector2i(int(w.tx), int(w.ty))):
			e.append(tag + "warp arrival %d,%d in '%s' is not walkable" % [int(w.tx), int(w.ty), target])
		elif not all[target].warp_at(Vector2i(int(w.tx), int(w.ty))).is_empty():
			# step out on to the doorstep, not into the doorway (a moved building leaves stale arrivals)
			e.append(tag + "warp arrival %d,%d in '%s' lands on a warp" % [int(w.tx), int(w.ty), target])
		elif all[target].doorstep_boxed_in(Vector2i(int(w.tx), int(w.ty))):
			# a sign or prop added beside the doorstep later can leave the only way off it back through the door
			e.append(tag + "warp arrival %d,%d in '%s' is boxed in: the only way off it is back through a door" % [int(w.tx), int(w.ty), target])
	for w in warps:
		for k in ["locked", "hidden"]:
			if w.has(k) and not (w[k] is Dictionary):
				e.append(tag + "warp at %d,%d: '%s' must be an object" % [int(w.x), int(w.y), k])
		if w.get("locked") is Dictionary and str(w.locked.get("needs", "")) == "":
			e.append(tag + "warp at %d,%d is locked but names nothing it needs" % [int(w.x), int(w.y)])
		if w.get("hidden") is Dictionary and str(w.hidden.get("reveal", "")) == "":
			e.append(tag + "warp at %d,%d is hidden but names no reveal flag" % [int(w.x), int(w.y)])
	var seen_ex := {}
	var ex_reach: Dictionary = reachable(spawn, GATE_ABILITIES) if walkable(spawn) and not examine.is_empty() else {}
	for ex in examine:
		var ep := Vector2i(int(ex.get("x", -1)), int(ex.get("y", -1)))
		if not in_bounds(ep):
			e.append(tag + "examine spot %d,%d is out of bounds" % [ep.x, ep.y])
			continue
		if seen_ex.has(ep):
			e.append(tag + "two examine spots at %d,%d" % [ep.x, ep.y])
		seen_ex[ep] = true
		if not (ex.get("text") is Array) or ex.text.is_empty():
			e.append(tag + "examine spot %d,%d has no text lines" % [ep.x, ep.y])
		if not warp_at(ep).is_empty():
			e.append(tag + "examine spot %d,%d is on a warp" % [ep.x, ep.y])
		# you face it from a neighbouring tile (or stand on it), so something next to it must be reachable
		var ok: bool = ex_reach.has(ep)
		for d in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
			ok = ok or ex_reach.has(ep + d)
		if not ok:
			e.append(tag + "examine spot %d,%d is blocked off (nowhere to stand to face it)" % [ep.x, ep.y])
	var edge_reach_cache := {}
	for side in edges:
		var target: String = edges[side].get("to", "")
		if side not in OPPOSITE:
			e.append(tag + "unknown edge '%s'" % side)
		elif not all.has(target):
			e.append(tag + "%s edge goes to unknown zone '%s'" % [side, target])
		elif edges[side].has("lease"):
			pass  # a lease zone's way back: the anchor's edge only opens once the lease is owned (core/leases.gd)
		elif not all[target].edges.has(OPPOSITE[side]) or all[target].edges[OPPOSITE[side]].get("to") != id:
			e.append(tag + "%s edge to '%s' has no %s edge back" % [side, target, OPPOSITE[side]])
		else:
			# every border tile you can actually reach must land on a walkable tile next door
			if not edge_reach_cache.has("r"):
				edge_reach_cache["r"] = reachable(spawn, GATE_ABILITIES) if walkable(spawn) else {}
			for b in _border(side):
				if edge_reach_cache["r"].has(b):
					var arr := edge_arrival(side, b, all[target])
					if not all[target].walkable(arr):
						e.append(tag + "walking off the %s edge at %d,%d lands on %d,%d in '%s', which is not walkable" % [side, b.x, b.y, arr.x, arr.y, target])
	for kind in encounters:
		for enc in encounters[kind]:
			if enc.has("season") and (not (enc.season is Array) or enc.season.is_empty() \
					or not enc.season.all(func(x): return x in ["spring", "summer", "autumn", "winter"])):
				e.append(tag + "%s encounter '%s' has a bad season %s (a list of spring, summer, autumn, winter)" % [kind, enc.get("species", "?"), enc.season])
	if scaled_floor != -1 and (scaled_floor < 2 or scaled_floor > Rules.MAX_LEVEL):
		e.append(tag + "scaled_floor %d should be a par level, 2 to %d (or absent)" % [scaled_floor, Rules.MAX_LEVEL])
	for s in signs:
		if not in_bounds(Vector2i(int(s.x), int(s.y))):
			e.append(tag + "sign at %d,%d is out of bounds" % [int(s.x), int(s.y)])
	for n in npcs:
		if not walkable(Vector2i(int(n.x), int(n.y))):
			e.append(tag + "npc '%s' stands on an unwalkable tile" % n.get("id", "?"))
	e.append_array(DeepPlace.problems(self))
	# ability gates: every warp and edge must be reachable from the spawn, using only the ability its "gate" names
	if walkable(spawn):
		var cache := {}
		for w in warps:
			var g: String = str(w.get("gate", ""))
			if g != "" and g not in GATE_ABILITIES:
				e.append(tag + "warp at %d,%d has unknown gate '%s'" % [int(w.x), int(w.y), g])
			if not cache.has(g):
				cache[g] = reachable(spawn, [] if g == "" else [g])
			if not cache[g].has(Vector2i(int(w.x), int(w.y))):
				e.append(tag + "can't reach the warp at %d,%d from the spawn%s" % [int(w.x), int(w.y), "" if g == "" else " even with " + g])
		for side in edges:
			var g: String = str(edges[side].get("gate", ""))
			if g != "" and g not in GATE_ABILITIES:
				e.append(tag + "%s edge has unknown gate '%s'" % [side, g])
			if not cache.has(g):
				cache[g] = reachable(spawn, [] if g == "" else [g])
			if side in OPPOSITE and not _side_reached(side, cache[g]):
				e.append(tag + "can't reach the %s edge from the spawn%s" % [side, "" if g == "" else " even with " + g])
	# corks: a beaten trainer stays where it stood, so trainers that never move must not wall off
	# a warp, an edge or another NPC. hide_if only applies when the zone loads, so a trainer hidden by its
	# own flag still stands there until you leave.
	var corks := _standing_npcs()
	for n in npcs:
		if n.has("trainer") and str(n.get("move", "still")) == "still" and (not n.has("hide_if") or str(n.hide_if) == "trainer_" + str(n.trainer)):
			corks[Vector2i(int(n.x), int(n.y))] = true
	if walkable(spawn):
		var cork_cache := {}  # gate -> what's reachable with only that gate's ability and the corks in place
		for w in warps:
			var g: String = str(w.get("gate", ""))
			if g != "" and g not in GATE_ABILITIES:
				continue  # already reported above
			if not cork_cache.has(g):
				cork_cache[g] = reachable(spawn, [] if g == "" else [g], corks)
			if cork_cache[g].has(Vector2i(int(w.x), int(w.y))):
				continue
			if reachable(spawn, [] if g == "" else [g]).has(Vector2i(int(w.x), int(w.y))):
				e.append(tag + "the warp at %d,%d is walled off by trainers that never move" % [int(w.x), int(w.y)])
		for side in edges:
			var g: String = str(edges[side].get("gate", ""))
			if side not in OPPOSITE or (g != "" and g not in GATE_ABILITIES):
				continue
			if not cork_cache.has(g):
				cork_cache[g] = reachable(spawn, [] if g == "" else [g], corks)
			if not _side_reached(side, cork_cache[g]) and _side_reached(side, reachable(spawn, [] if g == "" else [g])):
				e.append(tag + "the %s edge is walled off by trainers that never move" % side)
		var seen: Dictionary = reachable(spawn, GATE_ABILITIES, corks)
		for n in npcs:
			var np := Vector2i(int(n.x), int(n.y))
			var talkable := false
			for d in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
				if seen.has(np + d):
					talkable = true
				# across a shop or Sanctuary counter (Overworld.interact looks one tile past a counter)
				elif tile_at(np + d) == "counter" and seen.has(np + d * 2):
					talkable = true
			if not talkable:
				e.append(tag + "npc '%s' is walled off by trainers that never move" % n.get("id", "?"))
	if station != Vector2i(-1, -1) and not walkable(station):
		e.append(tag + "station tile %s is not walkable" % station)
	elif station != Vector2i(-1, -1) and walkable(spawn) and not reachable(station, GATE_ABILITIES, corks).has(spawn):
		e.append(tag + "station tile %s is boxed in: arriving by train can't reach the town" % station)
	var ferry_tile := Vector2i(int(ferry.get("x", -1)), int(ferry.get("y", -1)))
	if not ferry.is_empty() and not walkable(ferry_tile):
		e.append(tag + "ferry tile is not walkable")
	elif not ferry.is_empty() and walkable(spawn) and not reachable(ferry_tile, GATE_ABILITIES, corks).has(spawn):
		e.append(tag + "ferry quay %s is boxed in: arriving by boat can't reach the town" % ferry_tile)
	# a road or path that reaches the map edge must lead somewhere (an edge exit), or be closed off
	if kind != "interior" and id not in ["mesh_gallery", "testbed"]:
		for side in ["north", "south", "west", "east"]:
			if edges.has(side):
				continue
			for p in _border(side):
				if tile_at(p) in ["path", "road", "cobbles"]:
					e.append(tag + "a road at %d,%d runs off the %s edge, which leads nowhere (close it or add an edge)" % [p.x, p.y, side])
					break
	# every door goes somewhere: a warp, or a station's ticket office (the rail menu)
	for y in height:
		for x in width:
			var dp := Vector2i(x, y)
			if id not in ["mesh_gallery", "testbed"] and tiles[y][x] == "door" and warp_at(dp).is_empty() and str(building_at(dp).get("style", "")) != "station":
				e.append(tag + "door at %d,%d leads nowhere (add a warp)" % [x, y])
			if tiles[y][x] == "door" and in_bounds(dp + Vector2i(0, 1)) and tile_at(dp + Vector2i(0, 1)) in ["rail", "level_crossing"]:
				e.append(tag + "door at %d,%d opens straight onto the railway" % [x, y])
	var covered := {}
	for p in props:
		if p.get("type") == "building":
			for yy in range(int(p.y), int(p.y) + int(p.h)):
				for xx in range(int(p.x), int(p.x) + int(p.w)):
					covered[Vector2i(xx, yy)] = true
					if tile_at(Vector2i(xx, yy)) not in ["building", "door"]:
						e.append(tag + "building '%s' covers %d,%d which is not B or D" % [p.get("label", "?"), xx, yy])
	for y in height:
		for x in width:
			if tiles[y][x] == "building" and not covered.has(Vector2i(x, y)):
				e.append(tag + "B at %d,%d is not covered by a building prop" % [x, y])
	e.append_array(_roamer_errors(tag))
	if id not in RAIL_RULE_EXEMPT:
		e.append_array(_rail_errors(tag))
	return e

# --- rail ----------------------------------------------------------------------
# Lines are straight runs of `!` (and `&` level crossings), one or two tiles wide; T junctions and
# crossings are fine, bends are not. Every line end must run off the map, or stop at a buffer_stop,
# or go into a tunnel_portal (either prop on the end tile itself or on the tile just beyond it).

func is_rail(p: Vector2i) -> bool:
	return tile_at(p) in RAIL_TILES

## How many rail tiles run in a straight line through p along `axis` (p included).
func _rail_run(p: Vector2i, axis: Vector2i) -> int:
	var n := 1
	for s in [axis, -axis]:
		var q: Vector2i = p + s
		while is_rail(q):
			n += 1
			q += s
	return n

## Which way the track runs through rail tile p: (1, 0) east-west or (0, 1) north-south. The longer straight
## run wins, so a double track (two rows side by side) still runs along its rows. Ties go east-west.
func rail_axis(p: Vector2i) -> Vector2i:
	return Vector2i(0, 1) if _rail_run(p, Vector2i(0, 1)) > _rail_run(p, Vector2i(1, 0)) else Vector2i(1, 0)

## Every line end: [{"pos": end tile, "dir": the way out of the line}]. A lone tile has two ends (east and west).
func rail_ends() -> Array:
	var out := []
	for y in height:
		for x in width:
			var p := Vector2i(x, y)
			if not is_rail(p):
				continue
			var a := rail_axis(p)
			var perp := Vector2i(a.y, a.x)
			if is_rail(p + perp) and is_rail(p - perp):
				continue  # the middle of a T junction or a crossing
			var lone := not is_rail(p + a) and not is_rail(p - a)
			for d in [a, -a]:
				if not is_rail(p + d) and (lone or is_rail(p - d)):
					out.append({"pos": p, "dir": d})
	return out

## The rail cap prop (buffer_stop or tunnel_portal) standing on tile p, or {}.
func rail_cap_at(p: Vector2i) -> Dictionary:
	for pr in props:
		if str(pr.get("type", "")) in RAIL_CAPS and int(pr.get("x", -1)) == p.x and int(pr.get("y", -1)) == p.y:
			return pr
	return {}

## What a line end runs into: "edge" (off the map), "buffer_stop", "tunnel_portal", or "" (nothing: a bad end).
func rail_end_cap(end: Dictionary) -> String:
	var p: Vector2i = end.pos
	var beyond: Vector2i = p + end.dir
	if not in_bounds(beyond):
		return "edge"
	for q in [p, beyond]:
		var cap := rail_cap_at(q)
		if not cap.is_empty():
			return str(cap.type)
	return ""

## The way from a cap prop at p towards its track (the cap's open face points this way): along the line
## when the cap sits on the end tile, or at the end tile when it sits just beyond it.
func cap_inward(p: Vector2i) -> Vector2i:
	if is_rail(p):
		var a := rail_axis(p)
		return a if is_rail(p + a) else (-a if is_rail(p - a) else a)
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if is_rail(p + d):
			return d
	return Vector2i(1, 0)

## Is any rail tile within `r` tiles of p (a square, so diagonals count)?
func rail_near(p: Vector2i, r: int) -> bool:
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if is_rail(p + Vector2i(dx, dy)):
				return true
	return false

func _rail_errors(tag: String) -> Array:
	var e := []
	for end in rail_ends():
		if rail_end_cap(end) == "":
			var beyond: Vector2i = end.pos + end.dir
			e.append(tag + "rail line ends at %d,%d with nowhere to go: run it off the map edge, or put a buffer_stop or tunnel_portal on %d,%d or %d,%d" % [end.pos.x, end.pos.y, end.pos.x, end.pos.y, beyond.x, beyond.y])
	for pr in props:
		var pt := str(pr.get("type", ""))
		if pt in RAIL_CAPS:
			var cp := Vector2i(int(pr.get("x", 0)), int(pr.get("y", 0)))
			var touching := is_rail(cp)
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				touching = touching or is_rail(cp + d)
			if not touching:
				e.append(tag + "%s at %d,%d is not on or next to a rail line" % [pt, cp.x, cp.y])
	for n in npcs:
		if tile_at(Vector2i(int(n.get("x", -1)), int(n.get("y", -1)))) == "level_crossing":
			e.append(tag + "npc '%s' stands on a level crossing (trains would wait for ever)" % n.get("id", "?"))
	# a rail stop needs a line to stop on (heritage or disused halts with no "station" tile are left alone)
	if station != Vector2i(-1, -1) and not rail_near(station, 2):
		e.append(tag + "station platform %d,%d is not within 2 tiles of a rail line" % [station.x, station.y])
	return e
