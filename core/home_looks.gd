class_name HomeLooks
extends RefCounted
## Every home has one thing of its own to look at (w53 looks): a home is an interior zone whose id has home, house or
## cottage in it, and it should carry at least one examine spot (see Examine). A missing spot is a warning, not an
## error; a spot whose find is not a real item, or whose text has an em-dash, is an error. Pure: no autoloads.

const KEYS := ["home", "house", "cottage"]
## Zones that are not rooms a player visits.
const SKIP := ["testbed_house"]

static func is_home(zid: String, z: ZoneData) -> bool:
	if z.kind != "interior" or zid in SKIP:
		return false
	for k in KEYS:
		if zid.contains(k):
			return true
	return false

## Ids of homes with no examine spot, sorted.
static func uncovered(zones: Dictionary) -> Array:
	var out := []
	for zid in zones:
		if is_home(str(zid), zones[zid]) and zones[zid].examine.is_empty():
			out.append(str(zid))
	out.sort()
	return out

## Problems in the examine spots of homes: an unknown find item, an em-dash in what the player reads.
static func errors(zones: Dictionary, items) -> Array:
	var out := []
	for zid in zones:
		var z: ZoneData = zones[zid]
		if not is_home(str(zid), z):
			continue
		for ex in z.examine:
			var f = ex.get("find")
			if f is Dictionary and items != null and not items.has(str(f.get("item", ""))):
				out.append("zone %s: examine spot %s,%s finds unknown item '%s'" % [zid, ex.get("x"), ex.get("y"), f.get("item", "")])
			for l in ex.get("text", []):
				if str(l).contains("—"):
					out.append("zone %s: examine spot %s,%s has an em-dash" % [zid, ex.get("x"), ex.get("y")])
	return out
