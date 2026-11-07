class_name FieldSpots
extends RefCounted
## Field spots, the HM half of the party pieces (wave 48 F): out on the routes, a gap in a wall, sheep at a gate, a
## molehill, a dead trunk, reeds at a pond edge, a glint in the water. A creature in your party that knows the
## matching field piece (PartyPieces entry with "field": "<verb>") can deal with it, for a little loot, lore or a hop
## across the water. Optional nooks, never the main road. Data: data/field_spots/<region>.json, an array of
## {id, zone, x, y, field, prop, text, reward {item, qty} | {money} | {hop [x, y]} | {curio}, flag, at?}.
## text is the success line ({lead} is the creature that did it). A hop spot never runs out; the rest are once only.
## Pure: no autoload names (the validator loads it).

const DIR := "res://data/field_spots"
const SEEN_RANGE := 6
const PROPS := ["wall_gap", "sheep_gate", "molehill", "dead_trunk", "glint", "skim_target", "bog_pool", "coracle", "cheese", "bale"]
## verb -> the label for hints, a stand-in piece name and place for when no party piece is authored for it yet,
## what the player sees, and the little bit of business the creature does
const VERBS := {
	"mend": {"piece": "Walling", "where": "the dry stone walling contest", "sees": "A gap in the wall.", "anim": "shove"},
	"skim": {"piece": "Stone skimming", "where": "the skimming ponds", "sees": "A bottle on a post across the water.", "anim": "hop"},
	"topple": {"piece": "Tossing the caber", "where": "the Highland games", "sees": "A dead trunk, leaning.", "anim": "topple"},
	"line": {"piece": "Crabbing", "where": "the crabbing quays", "sees": "A glint in the water.", "anim": "rise"},
	"round_up": {"piece": "Sheepdog trials", "where": "the sheepdog trials", "sees": "Sheep, and a gate they will not use.", "anim": "wiggle"},
	"charm": {"piece": "Worm charming", "where": "the worm charming plots", "sees": "A fresh molehill.", "anim": "wiggle"},
	"snorkel": {"piece": "Bog snorkelling", "where": "the peat trenches of mid Wales", "sees": "A black peat pool.", "anim": "rise"},
	"paddle": {"piece": "Coracle racing", "where": "the coracle regattas", "sees": "A coracle on the bank.", "anim": "slide"},
	"roll": {"piece": "Cheese rolling", "where": "Cooper's Hill", "sees": "A cheese wheel stuck in a hollow.", "anim": "slide"},
	"loft": {"piece": "Road bowling", "where": "the country lanes of Armagh and Cork", "sees": "A bend, a bale and a verge.", "anim": "hop"},
}

static var _all: Array = []
static var _loaded := false

static func all() -> Array:
	if not _loaded:
		_loaded = true
		var d := DirAccess.open(DIR)
		if d:
			var names := Array(d.get_files())
			names.sort()
			for f in names:
				if f.ends_with(".json"):
					var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(DIR + "/" + f))
					if j is Array:
						_all.append_array(j)
	return _all

static func for_zone(zone_id: String) -> Array:
	return all().filter(func(s): return str(s.zone) == zone_id)

static func tile(s: Dictionary) -> Vector2i:
	return Vector2i(int(s.x), int(s.y))

static func is_hop(s: Dictionary) -> bool:
	return s.get("reward", {}).has("hop")

# --- state ---------------------------------------------------------------------

static func seen_key(s: Dictionary) -> String:
	return "%s_seen" % s.flag

static func known(data: GameStateData, s: Dictionary) -> bool:
	return ZoneData.flag_on(data.flag(seen_key(s))) or ZoneData.flag_on(data.flag(str(s.flag)))

## A once-only spot is done when its flag is set; a hop spot is "found" the first time you use it but stays usable.
static func done(data: GameStateData, s: Dictionary) -> bool:
	return ZoneData.flag_on(data.flag(str(s.flag)))

static func gone(data: GameStateData, s: Dictionary) -> bool:
	return done(data, s) and not is_hop(s)

static func close_enough(player: Vector2i, at: Vector2i) -> bool:
	return maxi(absi(player.x - at.x), absi(player.y - at.y)) <= SEEN_RANGE

## The map's marks: every spot you have seen, a ring until found and then ticked.
static func marks(data: GameStateData) -> Array:
	var out := []
	for s in all():
		if str(s.get("at", "")) != "" and known(data, s):
			out.append({"kind": "field", "at": str(s.at), "verb": str(s.field), "done": done(data, s)})
	return out

# --- the pieces ------------------------------------------------------------------

## The party piece that does this verb: {game, name, move, where}, or {} when none is authored (yet).
static func piece_for(verb: String) -> Dictionary:
	var es: Dictionary = PartyPieces.entries()
	var ids := es.keys()
	ids.sort()
	for g in ids:
		var e: Dictionary = es[g]
		if str(e.get("field", "")) == verb:
			return {"game": str(g), "name": str(e.get("name", g)), "move": str(e.get("move", "")), "where": str(e.get("where", "")),
				"unlocked_by": str(e.get("zone", ""))}
	return {}

## The first party member (able or not) that knows the verb's move, or null.
static func helper(data: GameStateData, verb: String) -> Creature:
	var pc := piece_for(verb)
	if pc.is_empty() or str(pc.move) == "":
		return null
	for c in data.party:
		if not c.is_fainted() and c.has_move(str(pc.move)):
			return c
	return null

static func piece_name(verb: String) -> String:
	var pc := piece_for(verb)
	if not pc.is_empty():
		return str(pc.name)
	return str(VERBS.get(verb, {}).get("piece", verb))

static func piece_where(verb: String) -> String:
	var pc := piece_for(verb)
	if not pc.is_empty() and str(pc.where) != "":
		return str(pc.where)
	return str(VERBS.get(verb, {}).get("where", "somewhere in the Isles"))

## What you are told when nobody in the party can do it: what it is, and which party piece would.
static func hint(s: Dictionary) -> Array:
	var v := str(s.field)
	var sees: String = VERBS.get(v, {}).get("sees", "Something that wants doing.")
	var move_name := ""
	var pc := piece_for(v)
	if not pc.is_empty() and str(pc.move) != "":
		move_name = " The move is %s." % str(pc.move).capitalize().replace("_", " ")
	return ["%s A creature with the party piece %s would know what to do. You learn it at %s.%s" % [sees, piece_name(v), piece_where(v), move_name]]

static func success_lines(s: Dictionary, lead: Creature) -> Array:
	var who := lead.nickname if lead.nickname != "" else str(lead.species.name)
	return [str(s.text).replace("{lead}", who)]

# --- validator -----------------------------------------------------------------------

static func check(zones: Dictionary, items: ItemDB) -> Array:
	var errs := []
	var ids := {}
	var flags := {}
	var tiles := {}
	var world_map: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/world_map.json"))
	for s in all():
		var id := str(s.get("id", ""))
		if id == "" or ids.has(id):
			errs.append("field spot '%s': missing or duplicate id" % id)
		ids[id] = true
		var fl := str(s.get("flag", ""))
		if fl == "" or flags.has(fl):
			errs.append("field spot %s: missing or duplicate flag" % id)
		flags[fl] = true
		if str(s.get("field", "")) not in VERBS:
			errs.append("field spot %s: field '%s' is not one of %s" % [id, s.get("field", ""), VERBS.keys()])
		if str(s.get("prop", "")) not in PROPS:
			errs.append("field spot %s: prop '%s' is not one of %s" % [id, s.get("prop", ""), PROPS])
		if str(s.get("text", "")) == "" or "—" in str(s.text) or "–" in str(s.text):
			errs.append("field spot %s: text is empty or has a dash" % id)
		var at := str(s.get("at", ""))
		if at != "" and not world_map.towns.has(at) and not world_map.places.has(at):
			errs.append("field spot %s: map place '%s' is not on the map" % [id, at])
		var z: ZoneData = zones.get(str(s.get("zone", "")))
		if z == null:
			errs.append("field spot %s: zone '%s' does not exist" % [id, s.get("zone", "")])
			continue
		if z.kind == "interior":
			errs.append("field spot %s: %s is an interior" % [id, z.id])
		var t := tile(s)
		if not z.in_bounds(t) or not z.walkable(t):
			errs.append("field spot %s: (%d, %d) is not a free walkable tile in %s" % [id, t.x, t.y, z.id])
			continue
		var key := "%s@%d,%d" % [z.id, t.x, t.y]
		if tiles.has(key):
			errs.append("field spot %s: shares a tile with %s" % [id, tiles[key]])
		tiles[key] = id
		if _occupied(z, t):
			errs.append("field spot %s: (%d, %d) in %s is under a prop, npc, sign or warp" % [id, t.x, t.y, z.id])
		for p in Poi.for_zone(str(z.id)):
			if Poi.tile(z, p) == t:
				errs.append("field spot %s: sits on poi %s" % [id, p.id])
		var rw: Dictionary = s.get("reward", {})
		var n := 0
		for k in ["item", "money", "hop", "curio"]:
			if rw.has(k):
				n += 1
		if n != 1:
			errs.append("field spot %s: reward needs exactly one of item, money, hop, curio" % id)
		for k in ["item", "curio"]:
			if rw.has(k) and not items.has(str(rw[k])):
				errs.append("field spot %s: reward %s '%s' does not exist" % [id, k, rw[k]])
		if rw.has("hop"):
			var h: Array = rw.hop
			var ht := Vector2i(int(h[0]), int(h[1])) if h.size() == 2 else Vector2i(-1, -1)
			if not z.in_bounds(ht) or not z.walkable(ht) or _occupied(z, ht):
				errs.append("field spot %s: hop target %s is not a free walkable tile" % [id, ht])
	# every spot must be reachable on foot from the spawn, or be the far end of a hop pair
	var by_zone := {}
	for s in all():
		if zones.has(str(s.get("zone", ""))):
			if not by_zone.has(s.zone):
				by_zone[s.zone] = []
			by_zone[s.zone].append(s)
	for zid in by_zone:
		var z: ZoneData = zones[zid]
		var block := {}
		for s in by_zone[zid]:
			block[tile(s)] = true
		var reach := z.reachable(z.spawn, [], block)
		for s in by_zone[zid]:
			var t := tile(s)
			var ok := false
			for d in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
				if reach.has(t + d):
					ok = true
			if not ok:
				for o in by_zone[zid]:
					if is_hop(o) and reach.has(Vector2i(int(o.reward.hop[0]), int(o.reward.hop[1]))) == false and t.distance_to(Vector2(int(o.reward.hop[0]), int(o.reward.hop[1]))) <= 1.5:
						ok = true
			if not ok:
				errs.append("field spot %s: cannot be reached from the spawn in %s" % [s.id, zid])
	return errs

static func _occupied(z: ZoneData, t: Vector2i) -> bool:
	for k in [z.props, z.warps, z.signs, z.npcs, z.examine]:
		for p in k:
			if p is Dictionary and int(p.get("x", -9)) == t.x and int(p.get("y", -9)) == t.y:
				return true
	return z.spawn == t
