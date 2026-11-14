class_name Atlas
extends RefCounted
## The Atlas (5.4), a page of the Almanac: for each region you have set foot in, how much of it you have seen, as counts
## and a bar. Six measures: places found (Discovery), rooms visited (the Visitor's Book), plaques read (the Gazetteer),
## points of interest and field spots found, and creatures recorded in the Fieldbook. Every measure counts the whole
## of the region, so a bar is honest about how much is left, and the region's percentage is the average of its bars. A region earns a stamp at half and another at all, each
## with a modest one-off reward from the bag of ordinary items (no money). Nothing is stored but the stamp flags, so
## an old save catches up on the first open: every stamp it has already earned is paid then.
## Pure: no autoload names (the validator loads it).

const KEYS := ["places", "rooms", "plaques", "poi", "spots", "creatures"]
const LABELS := {"places": "Places found", "rooms": "Rooms visited", "plaques": "Plaques read", "poi": "Points of interest",
	"spots": "Field spots", "creatures": "Creatures recorded"}
const HALF := 0.5
const FLAG := "atlas_"
## Item rewards by stamp: a flask of tea and a Kendal Mint Cake. Existing items, cheap, and no money.
const REWARDS := {"half": {"flask_of_tea": 1}, "full": {"kendal_mint_cake": 1}}

static var _cache: Dictionary = {}   # region -> {places: [zone ids], rooms: [...], plaques: [ids], poi: [ids], spots: [ids], species: [ids]}

static func reset() -> void:
	_cache = {}

## What each region holds, built once from the zone index and the data files.
static func contents(idx: Dictionary) -> Dictionary:
	if _cache.is_empty():
		var zones: Dictionary = idx.get("zones", {})
		var out := {}
		var open := func(r: String) -> Dictionary:
			if not out.has(r):
				out[r] = {"places": [], "rooms": [], "plaques": [], "poi": [], "spots": [], "species": []}
			return out[r]
		for id in zones:
			var z: Dictionary = zones[id]
			var r := str(z.region)
			if r == "":
				continue
			if str(z.kind) == "interior":
				open.call(r).rooms.append(str(id))
			if Discovery.findable(str(z.kind), bool(z.get("deep", false))):
				open.call(r).places.append(str(id))
		for p in Gazetteer.all():
			var r := str(zones.get(str(p.zone), {}).get("region", ""))
			if r != "":
				open.call(r).plaques.append(str(p.id))
		for p in Poi.all():
			var r := str(zones.get(str(p.zone), {}).get("region", ""))
			if r != "":
				open.call(r).poi.append(str(p.id))
		for s in FieldSpots.all():
			var r := str(zones.get(str(s.zone), {}).get("region", ""))
			if r != "":
				open.call(r).spots.append(str(s.id))
		for r in idx.get("region_species", {}):
			var entry: Dictionary = open.call(str(r))
			entry["species"] = idx.region_species[r].filter(func(sp): return not Dex.in_appendix(sp))
		_cache = out
	return _cache

## One region's rows: [{key, label, got, total}] for the measures it has anything of.
static func rows(d: GameStateData, idx: Dictionary, region: String) -> Array:
	var c: Dictionary = contents(idx).get(region, {})
	var out := []
	if c.is_empty():
		return out
	var poi_got := (c.poi as Array).filter(func(id): return _poi_found(d, str(id))).size()
	var spot_got := (c.spots as Array).filter(func(id): return _spot_found(d, str(id))).size()
	var got := {
		"places": (c.places as Array).filter(func(id): return Discovery.is_found(d, str(id))).size(),
		"rooms": (c.rooms as Array).filter(func(id): return d.flag(VisitorsBook.seen_flag(str(id))) == true).size(),
		"plaques": (c.plaques as Array).filter(func(id): return Gazetteer.is_read(d, str(id))).size(),
		"poi": poi_got, "spots": spot_got,
		"creatures": (c.species as Array).filter(func(sp): return d.seen.has(sp) or d.caught.has(sp)).size(),
	}
	var total := {"places": c.places.size(), "rooms": c.rooms.size(), "plaques": c.plaques.size(), "poi": c.poi.size(),
		"spots": c.spots.size(), "creatures": c.species.size()}
	for k in KEYS:
		if int(total[k]) > 0:
			out.append({"key": k, "label": str(LABELS[k]), "got": int(got[k]), "total": int(total[k])})
	return out

static func _poi_found(d: GameStateData, id: String) -> bool:
	var p := Poi.by_id(id)
	return not p.is_empty() and (Poi.known(d, p) or Poi.done(d, p))

static func _spot_found(d: GameStateData, id: String) -> bool:
	for s in FieldSpots.all():
		if str(s.id) == id:
			return FieldSpots.known(d, s) or FieldSpots.done(d, s)
	return false

## How much of a region is seen, 0..1: the average of its measures, each counting the same, so a town full of rooms
## does not drown out the one plaque and the one standing stone.
static func fraction(rs: Array) -> float:
	var sum := 0.0
	for r in rs:
		sum += float(r.got) / float(r.total)
	return sum / float(rs.size()) if not rs.is_empty() else 0.0

## "" below half, "half" from half, "full" at all of it.
static func stamp_for(frac: float) -> String:
	if frac >= 0.999:
		return "full"
	return "half" if frac >= HALF else ""

static func stamp_flag(region: String, tier: String) -> String:
	return "%s%s_%s" % [FLAG, region, tier]

## The regions to list, in the Fieldbook's region order: those with at least one place found.
## [{region, name, rows, frac, stamp, got, total}] where got/total are places.
static func regions(d: GameStateData, idx: Dictionary) -> Array:
	Discovery.catch_up(d, idx)
	var out := []
	var order := FieldbookGoals.REGION_NAMES.keys()
	var ids: Array = contents(idx).keys()
	ids.sort_custom(func(a, b):
		var ia := order.find(a)
		var ib := order.find(b)
		if ia == -1 and ib == -1:
			return a < b
		if ia == -1 or ib == -1:
			return ia != -1
		return ia < ib)
	for r in ids:
		var rs := rows(d, idx, str(r))
		var placed := 0
		for row in rs:
			if row.key == "places":
				placed = int(row.got)
		if placed <= 0:
			continue
		var f := fraction(rs)
		out.append({"region": str(r), "name": FieldbookGoals.region_name(str(r)), "rows": rs, "frac": f, "stamp": stamp_for(f)})
	return out

## Pays every stamp now earned and not yet paid (the half stamp, then the full one), setting its flag. A stamp the bag has
## no room for waits for the next look. Returns [{region, name, tier, items: [{id, n}]}] for what was paid.
static func collect(d: GameStateData, idx: Dictionary) -> Array:
	var paid := []
	for reg in regions(d, idx):
		for tier in ["half", "full"]:
			if tier == "full" and reg.stamp != "full":
				continue
			if tier == "half" and reg.stamp == "":
				continue
			var key := stamp_flag(str(reg.region), tier)
			if d.flag(key) == true:
				continue
			var items := []
			var bag := Bag.new(d.bag)
			var ok := true
			for id in REWARDS[tier]:
				var n := int(REWARDS[tier][id])
				if bag.add(str(id), n) < n:
					ok = false
				items.append({"id": str(id), "n": n})
			if ok:
				d.set_flag(key, true)
				paid.append({"region": str(reg.region), "name": str(reg.name), "tier": tier, "items": items})
	return paid

## Places found and places in all, for the Almanac's one-line blurb.
static func blurb(d: GameStateData, idx: Dictionary) -> String:
	var t := Discovery.tally(d, idx)
	return "%d of %d places found" % [t.x, t.y]
