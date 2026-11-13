class_name Flotsam
extends RefCounted
## Flotsam (wave 54): crates, lobster pots, messages in bottles and island caches that only a coracle reaches.
## One-off finds, each a flag (absent = not found), with a modest item for a reward and never any money.
## Data: data/flotsam.json, written by tools/flotsam/gen_flotsam.py, an array of
## {id, zone, x, y, kind, text [lines], reward {item, qty}, flag}. A crate, pot or bottle floats on a `~` or `$` tile
## and stands solid there until found; a cache sits on an islet or a far bank. Pure: no autoload names (the validator
## loads it).

const PATH := "res://data/flotsam.json"
const KINDS := ["crate", "pot", "bottle", "cache"]
const FLOATING := ["crate", "pot", "bottle"]

static var _all: Array = []
static var _loaded := false

static func all() -> Array:
	if not _loaded:
		_loaded = true
		var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH)) if FileAccess.file_exists(PATH) else null
		if j is Array:
			_all = j
	return _all

static func for_zone(zone_id: String) -> Array:
	return all().filter(func(f): return str(f.zone) == zone_id)

static func tile(f: Dictionary) -> Vector2i:
	return Vector2i(int(f.x), int(f.y))

static func is_floating(f: Dictionary) -> bool:
	return str(f.kind) in FLOATING

## Has this find been taken? (A flag that was never set means it is still there.)
static func found(data: GameStateData, f: Dictionary) -> bool:
	return data.flag(str(f.flag)) == true

static func found_count(data: GameStateData) -> int:
	var n := 0
	for f in all():
		if found(data, f):
			n += 1
	return n

## What is said before "You take X": the find's own lines.
static func lines(f: Dictionary) -> Array:
	return f.text.duplicate()

# --- validator ---------------------------------------------------------------------

static func check(zones: Dictionary, items: ItemDB, list := all()) -> Array:
	var errs := []
	var ids := {}
	var flags := {}
	var tiles := {}
	var by_zone := {}
	for f in list:
		var id := str(f.get("id", ""))
		if id == "" or ids.has(id):
			errs.append("flotsam '%s': missing or duplicate id" % id)
		ids[id] = true
		var fl := str(f.get("flag", ""))
		if fl == "" or flags.has(fl):
			errs.append("flotsam %s: missing or duplicate flag" % id)
		flags[fl] = true
		if str(f.get("kind", "")) not in KINDS:
			errs.append("flotsam %s: kind '%s' is not one of %s" % [id, f.get("kind", ""), KINDS])
		var text: Variant = f.get("text", [])
		if not (text is Array) or text.is_empty() or text.any(func(l): return str(l) == "" or "—" in str(l) or "–" in str(l)):
			errs.append("flotsam %s: text must be lines with no dashes" % id)
		var rw: Dictionary = f.get("reward", {})
		if not rw.has("item") or not rw.has("qty") or rw.size() != 2:
			errs.append("flotsam %s: the reward is an item and a quantity, never money" % id)
		elif not items.has(str(rw.get("item", ""))) or int(rw.get("qty", 0)) < 1 or int(rw.get("qty", 0)) > 3:
			errs.append("flotsam %s: reward '%s' x%s is not a small amount of a real item" % [id, rw.get("item", ""), rw.get("qty", 0)])
		var z: ZoneData = zones.get(str(f.get("zone", "")))
		if z == null:
			errs.append("flotsam %s: zone '%s' does not exist" % [id, f.get("zone", "")])
			continue
		if not z.ride_zone():
			errs.append("flotsam %s: %s has no coracle water" % [id, z.id])
			continue
		var t := tile(f)
		var key := "%s@%d,%d" % [z.id, t.x, t.y]
		if tiles.has(key):
			errs.append("flotsam %s: shares a tile with %s" % [id, tiles[key]])
		tiles[key] = id
		if not by_zone.has(z.id):
			by_zone[z.id] = []
		by_zone[z.id].append(f)
	for zid in by_zone:
		errs.append_array(_zone_errors(zones, zones[zid], by_zone[zid]))
	return errs

## Where each of a zone's finds stands: on water the coracle can float on with room to turn, or on land only the
## coracle reaches; never on a door, person, sign, prop or field spot; and never somewhere you can walk to.
static func _zone_errors(zones: Dictionary, z: ZoneData, list: Array) -> Array:
	var errs := []
	var walls := RideCheck.gate_walls(z)
	var on_foot := {}
	for e in RideCheck.entries(zones, z, walls):
		on_foot.merge(z.reachable(e, ZoneData.GATE_ABILITIES, walls))
	var afloat := z.reachable(z.spawn, RideCheck.RIDING, walls) if z.walkable(z.spawn) else {}
	var taken := {}
	for k in [z.warps, z.npcs, z.signs, z.examine]:
		for p in k:
			taken[Vector2i(int(p.get("x", -9)), int(p.get("y", -9)))] = true
	for s in FieldSpots.for_zone(str(z.id)):
		taken[FieldSpots.tile(s)] = true
	for f in list:
		var id := str(f.id)
		var t := tile(f)
		if not z.in_bounds(t):
			errs.append("flotsam %s: (%d, %d) is out of bounds in %s" % [id, t.x, t.y, z.id])
			continue
		if taken.has(t) or z.blocked.has(t) or t == z.spawn:
			errs.append("flotsam %s: (%d, %d) in %s is under a prop, person, sign, door or spot" % [id, t.x, t.y, z.id])
		if on_foot.has(t):
			errs.append("flotsam %s: (%d, %d) in %s can be walked to; it is for the coracle" % [id, t.x, t.y, z.id])
		if is_floating(f):
			if not z.can_ride(t, RideCheck.RIDING):
				errs.append("flotsam %s: (%d, %d) in %s is not water a coracle can float on" % [id, t.x, t.y, z.id])
				continue
			var open := 0
			for d in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
				if on_foot.has(t + d):
					errs.append("flotsam %s: (%d, %d) in %s is within reach of the bank" % [id, t.x, t.y, z.id])
					break
			for d in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
				if afloat.has(t + d) and z.tile_at(t + d) in ZoneData.RIDE_TILES:
					open += 1
			if open < 3:
				errs.append("flotsam %s: (%d, %d) in %s would sit in a narrow channel (%d open sides)" % [id, t.x, t.y, z.id, open])
		else:
			if not z.walkable(t):
				errs.append("flotsam %s: (%d, %d) in %s is not a free walkable tile" % [id, t.x, t.y, z.id])
		if not afloat.has(t):
			errs.append("flotsam %s: (%d, %d) in %s cannot be reached even by coracle from the spawn" % [id, t.x, t.y, z.id])
	return errs
