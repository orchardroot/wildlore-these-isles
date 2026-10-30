class_name Letters
extends RefCounted
## Papers on the tables (wave 47 B): about 230 letters, diary pages, lists and telegrams written in
## data/letters/<region>.json, each laid on the first table or dresser of an interior. Reading one is once-only (flag
## `<id>_read`); some start a treasure trail: a dig spot in an outdoor zone, within DIG_RADIUS tiles of `near`, that
## appears once the paper is read and pays out once (flag `<id>_dug`). Pure logic, no autoloads: LettersScene
## (world/trails_scene.gd) draws the paper and the dig spots and talks; the Papers page (ui/papers_tab.gd) lists them.
## Schema: {"papers": [{id, zone, title, lines[], trail?: {zone, near: [x, y], clue, reward: {item, n} | {money} | {curio}}}]}

const DIR := "res://data/letters"
const TABLES := ["table", "kitchen_dresser"]
const DIG_TILES := ["grass", "flowers", "sand", "path"]
const DIG_RADIUS := 2
const NONE := Vector2i(-1, -1)

static var _papers: Array = []
static var _by_id := {}
static var _by_zone := {}
static var _loaded := false

static func clear_cache() -> void:
	_papers = []
	_by_id = {}
	_by_zone = {}
	_loaded = false

static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	for path in JsonUtil.list_json(DIR):
		var d = JsonUtil.read(path)
		if not (d is Dictionary):
			continue
		for p in d.get("papers", []):
			var id := str(p.get("id", ""))
			if id == "" or _by_id.has(id):
				continue
			_papers.append(p)
			_by_id[id] = p
			var z := str(p.get("zone", ""))
			if not _by_zone.has(z):
				_by_zone[z] = []
			_by_zone[z].append(p)

static func all() -> Array:
	_load()
	return _papers

static func paper(id: String) -> Dictionary:
	_load()
	return _by_id.get(id, {})

## The papers lying in this interior (usually one).
static func at(zone_id: String) -> Array:
	_load()
	return _by_zone.get(zone_id, [])

## The tile a paper lies on in this zone: its first table (or kitchen dresser) prop, or NONE.
static func prop_for(zone: ZoneData) -> Vector2i:
	for pr in zone.props:
		if str(pr.get("type", "")) in TABLES:
			return Vector2i(int(pr.x), int(pr.y))
	return NONE

static func has_trail(p: Dictionary) -> bool:
	return p.get("trail") is Dictionary

# --- state ---------------------------------------------------------------------------------

static func read_flag(id: String) -> String:
	return id + "_read"

static func dug_flag(id: String) -> String:
	return id + "_dug"

static func is_read(data: GameStateData, id: String) -> bool:
	return ZoneData.flag_on(data.flag(read_flag(id)))

static func is_dug(data: GameStateData, id: String) -> bool:
	return ZoneData.flag_on(data.flag(dug_flag(id)))

static func read_count(data: GameStateData) -> int:
	return read_papers(data).size()

## The papers read so far, in file order.
static func read_papers(data: GameStateData) -> Array:
	return all().filter(func(p): return is_read(data, str(p.id)))

## Read papers with a trail not yet dug: the clues in hand.
static func open_trails(data: GameStateData) -> Array:
	return read_papers(data).filter(func(p): return has_trail(p) and not is_dug(data, str(p.id)))

static func trails_here(data: GameStateData, zone_id: String) -> Array:
	return open_trails(data).filter(func(p): return str(p.trail.get("zone", "")) == zone_id)

## Reads a paper: the title and lines the first time (and the clue, if it starts a trail), "You've read this one."
## after. {lines, first}.
static func read(data: GameStateData, p: Dictionary) -> Dictionary:
	var id := str(p.get("id", ""))
	if is_read(data, id):
		return {"lines": ["You've read this one."], "first": false}
	data.set_flag(read_flag(id), true)
	TrainerStats.add(data, "papers_read")
	var lines: Array = [str(p.get("title", "A paper"))]
	for l in p.get("lines", []):
		lines.append(str(l))
	if has_trail(p):
		lines.append("It might be worth a look: " + str(p.trail.get("clue", "")))
	return {"lines": lines, "first": true}

## The Papers page's one-line status for a paper.
static func status(data: GameStateData, p: Dictionary) -> String:
	if not has_trail(p):
		return "read"
	return "dug up" if is_dug(data, str(p.id)) else "clue open"

## The Almanac's one-line summary.
static func blurb(data: GameStateData) -> String:
	var n := read_count(data)
	var open := open_trails(data).size()
	return "%d of %d read%s" % [n, all().size(), (", %d trail%s open" % [open, "" if open == 1 else "s"]) if open > 0 else ""]

# --- dig spots -----------------------------------------------------------------------------

static func _footprint(z: ZoneData, t: Vector2i) -> bool:
	for pr in z.props:
		var x := int(pr.x)
		var y := int(pr.y)
		if str(pr.get("type", "")) == "building":
			if t.x >= x and t.x < x + int(pr.get("w", 1)) and t.y >= y and t.y < y + int(pr.get("h", 1)):
				return true
		elif t == Vector2i(x, y) and not bool(pr.get("walk", false)):
			return true
	return false

## Whether a tile can hold a dig spot: bare ground, no prop, npc, warp, sign or look-closer spot, off the zone's rim.
static func diggable(z: ZoneData, t: Vector2i) -> bool:
	if t.x < 1 or t.y < 1 or t.x >= z.width - 1 or t.y >= z.height - 1:
		return false
	if not z.walkable(t) or z.tile_at(t) not in DIG_TILES or _footprint(z, t):
		return false
	for n in z.npcs:
		if Vector2i(int(n.x), int(n.y)) == t:
			return false
	for list in [z.warps, z.signs, z.examine]:
		for e in list:
			if Vector2i(int(e.x), int(e.y)) == t:
				return false
	return true

## The dig tile for a trail: the nearest diggable tile to `near` within DIG_RADIUS (ring by ring, scanning up then
## left, as ZoneData.landing_near does), or NONE.
static func dig_tile(z: ZoneData, trail: Dictionary) -> Vector2i:
	var n: Array = trail.get("near", [0, 0])
	var c := Vector2i(int(n[0]), int(n[1]))
	for r in range(0, DIG_RADIUS + 1):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) == r and diggable(z, c + Vector2i(dx, dy)):
					return c + Vector2i(dx, dy)
	return NONE

## Digs a trail's spot: gives the reward, flags it dug. `items` is the ItemDB (or null). {lines, gave}.
static func dig(data: GameStateData, p: Dictionary, items) -> Dictionary:
	var id := str(p.get("id", ""))
	if is_dug(data, id):
		return {"lines": ["Nothing more here."], "gave": false}
	data.set_flag(dug_flag(id), true)
	var lines: Array = ["You dig."]
	var rw: Dictionary = p.trail.get("reward", {})
	var iid := str(rw.get("item", rw.get("curio", "")))
	if iid != "" and items != null and items.has(iid):
		var n := maxi(1, int(rw.get("n", 1)))
		data.bag[iid] = mini(Bag.MAX_STACK, int(data.bag.get(iid, 0)) + n)
		var nm := str(items.get_item(iid).get("name", iid))
		lines.append("A tin, wrapped in oilcloth. Inside: %s." % (nm if n == 1 else "%d x %s" % [n, nm]))
	else:
		var m := maxi(int(rw.get("money", 0)), 500 if iid != "" else 0)
		data.money += m
		lines.append("A tin, wrapped in oilcloth. Inside: %s in old notes and coin." % Wallet.fmt(m))
	return {"lines": lines, "gave": true}

# --- the map -------------------------------------------------------------------------------

## "?" marks for MapLogic.marks: one per open trail, at the trail's zone.
static func marks(data: GameStateData) -> Array:
	var out := []
	for p in open_trails(data):
		out.append({"kind": "trail", "at": str(p.trail.get("zone", ""))})
	return out

# --- validation ----------------------------------------------------------------------------

## Data errors for tools/validate.gd and the tests: zones, tables, bounds, dig tiles, rewards.
static func errors(zones: Dictionary, items) -> Array:
	var out := []
	var seen := {}
	var by_zone := {}
	for p in all():
		var id := str(p.get("id", ""))
		var tag := "letter %s: " % id
		if not id.begins_with("ltr_") or seen.has(id):
			out.append(tag + "id must be unique and start ltr_")
		seen[id] = true
		var zid := str(p.get("zone", ""))
		by_zone[zid] = int(by_zone.get(zid, 0)) + 1
		if not zones.has(zid) or (zones[zid] as ZoneData).kind != "interior":
			out.append(tag + "zone '%s' is not an interior" % zid)
		elif prop_for(zones[zid]) == NONE:
			out.append(tag + "zone '%s' has no table or dresser" % zid)
		var lines: Array = p.get("lines", [])
		if str(p.get("title", "")) == "" or lines.size() < 2 or lines.size() > 6:
			out.append(tag + "needs a title and 2 to 6 lines")
		for l in lines + [p.get("title", "")]:
			if "—" in str(l) or "–" in str(l):
				out.append(tag + "no dashes in player-facing text")
		if not has_trail(p):
			continue
		var t: Dictionary = p.trail
		var tz := str(t.get("zone", ""))
		if not zones.has(tz) or (zones[tz] as ZoneData).kind == "interior":
			out.append(tag + "trail zone '%s' is not an outdoor zone" % tz)
			continue
		var z: ZoneData = zones[tz]
		var n: Array = t.get("near", [])
		if n.size() != 2 or not z.in_bounds(Vector2i(int(n[0]), int(n[1]))):
			out.append(tag + "trail near is out of bounds in %s" % tz)
			continue
		var d := dig_tile(z, t)
		if d == NONE:
			out.append(tag + "no diggable tile near %s in %s" % [str(n), tz])
		elif not z.reachable(z.spawn).has(d):
			out.append(tag + "dig tile %s in %s is not reachable from the spawn" % [str(d), tz])
		if str(t.get("clue", "")) == "":
			out.append(tag + "trail needs a clue")
		var rw: Dictionary = t.get("reward", {})
		var iid := str(rw.get("item", rw.get("curio", "")))
		if iid != "" and items != null and not items.has(iid) and not rw.has("curio"):
			out.append(tag + "reward item '%s' does not exist" % iid)
		if iid == "" and int(rw.get("money", 0)) <= 0:
			out.append(tag + "trail has no reward")
	for zid in by_zone:
		if int(by_zone[zid]) > 1:
			out.append("letters: zone %s holds %d papers (one table, one paper)" % [zid, by_zone[zid]])
	return out
