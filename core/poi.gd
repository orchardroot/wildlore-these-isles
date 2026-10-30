class_name Poi
extends RefCounted
## Points of interest on the routes, the Witcher's question marks: a creature den, a poachers' camp, a standing stone
## and a hidden cache, placed at runtime from data/poi/<region>.json (tools/poi/gen_poi.py lays them on free,
## reachable ground; ZoneData.landing_near is the fuzz if an overlay got in the way). The world/poi_scene.gd draws
## and plays them; this is the pure half: placement, state flags, the battles and the rewards.
## Pure: no autoload names (the validator loads it).
##
## A poi: {id, zone, near [x,y], kind, at? (map place for the "?"), mentioned_by? {zone, npc}, and per kind:
## den {species}, camp {names [[name, class]], party [species], line, money, item}, stone {stat, lore [lines]},
## cache {item, line, paper?, curio?}}.
## Flags: poi_<id>_seen (stood within SEEN_RANGE, or a resident mentioned it), poi_<id>_done (a den holds
## day_count + 1 so it can restock after DEN_DAYS; the rest hold true).

const DIR := "res://data/poi"
const KINDS := ["den", "camp", "stone", "cache"]
const SEEN_RANGE := 6
const DEN_DAYS := 14
const DEN_BOOST := 3        # the den's wild creatures are this many levels above the route's
const STONE_POINTS := 4
const CURIOS_FILE := "res://data/items/w47_a.json"

static var _all: Array = []
static var _loaded := false
static var _mentions: Dictionary = {}   # "zone|npc" -> [poi]

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
					if j is Dictionary:
						_all.append_array(j.get("pois", []))
		for p in _all:
			var m: Dictionary = p.get("mentioned_by", {})
			if not m.is_empty():
				var k := "%s|%s" % [m.get("zone", ""), m.get("npc", "")]
				if not _mentions.has(k):
					_mentions[k] = []
				_mentions[k].append(p)
	return _all

static func for_zone(zone_id: String) -> Array:
	return all().filter(func(p): return str(p.zone) == zone_id)

static func by_id(id: String) -> Dictionary:
	for p in all():
		if str(p.id) == id:
			return p
	return {}

## Where it stands: the authored tile, or the nearest tile the player can stand on.
static func tile(z: ZoneData, p: Dictionary) -> Vector2i:
	return z.landing_near(Vector2i(int(p.near[0]), int(p.near[1])))

# --- state ---------------------------------------------------------------------

static func seen_key(p: Dictionary) -> String:
	return "%s_seen" % p.id

static func done_key(p: Dictionary) -> String:
	return "%s_done" % p.id

static func known(data: GameStateData, p: Dictionary) -> bool:
	return ZoneData.flag_on(data.flag(seen_key(p)))

static func done(data: GameStateData, p: Dictionary) -> bool:
	var v: Variant = data.flag(done_key(p))
	if not ZoneData.flag_on(v):
		return false
	if str(p.kind) == "den":
		return data.day_count - (int(v) - 1) < DEN_DAYS
	return true

static func mark_done(data: GameStateData, p: Dictionary) -> void:
	data.set_flag(done_key(p), data.day_count + 1 if str(p.kind) == "den" else true)

static func close_enough(player: Vector2i, at: Vector2i) -> bool:
	return maxi(absi(player.x - at.x), absi(player.y - at.y)) <= SEEN_RANGE

## The map's "?" marks: every poi you know of, a "?" until it is done and then its kind's icon.
static func marks(data: GameStateData) -> Array:
	var out := []
	for p in all():
		if str(p.get("at", "")) != "" and known(data, p):
			out.append({"kind": "poi", "at": str(p.at), "poi": str(p.kind), "done": done(data, p)})
	return out

# --- the battles -----------------------------------------------------------------

## The zone's wild table as [species, lo, hi, weight] (grass first, any table if it has no grass).
static func table(z: ZoneData) -> Array:
	var src: Array = z.encounters.get("grass", [])
	if src.is_empty():
		for k in z.encounters:
			src = z.encounters[k]
			break
	return src

## Three wild fights for the den: [{species, level}].
static func den_fights(z: ZoneData, rng: Rng) -> Array:
	var t := table(z)
	var out := []
	if t.is_empty():
		return out
	for _i in 3:
		var total := 0.0
		for e in t:
			total += float(e.get("weight", 1))
		var r := rng.roll() * total
		var pick: Dictionary = t.back()
		for e in t:
			r -= float(e.get("weight", 1))
			if r < 0.0:
				pick = e
				break
		var lo := int(pick.get("min", 5))
		out.append({"species": str(pick.species), "level": rng.roll_int(lo, maxi(lo, int(pick.get("max", lo)))) + DEN_BOOST})
	return out

## The den's resident: a species the route does not otherwise have, a little above the best level here.
static func resident_level(z: ZoneData) -> int:
	var hi := 5
	for e in table(z):
		hi = maxi(hi, int(e.get("max", 5)))
	return hi + DEN_BOOST + 1

## A level for the camp's poachers: the route's best plus two, or just under the story's par if that is higher.
static func camp_level(z: ZoneData, flags: Dictionary) -> int:
	var hi := 5
	for e in table(z):
		hi = maxi(hi, int(e.get("max", 5)))
	return clampi(maxi(hi + 2, ParLevel.par(flags) - 1), 2, Rules.MAX_LEVEL)

## The camp's trainers as party defs for TrainerParty.build.
static func camp_trainers(z: ZoneData, p: Dictionary, flags: Dictionary) -> Array:
	var lv := camp_level(z, flags)
	var out := []
	var names: Array = p.get("names", [])
	var party: Array = p.get("party", [])
	for i in names.size():
		var members := []
		for j in 2:
			members.append({"species": str(party[(i + j) % party.size()]), "level": lv + j})
		out.append({"id": "%s_%d" % [p.id, i], "name": str(names[i][0]), "class": str(names[i][1]), "sprite": "warden_grunt",
			"party": members, "ai": "trainer", "money": 0,
			"intro": [{"do": "say", "who": str(names[i][0]), "text": str(p.get("line", "Private camp."))}],
			"win": "Fair enough. Fair enough.", "after": ""})
	return out

## What the strongbox holds: pence scaled to the camp's level, and its item.
static func strongbox(z: ZoneData, p: Dictionary, flags: Dictionary) -> Dictionary:
	return {"money": int(p.get("money", 400)) + 20 * camp_level(z, flags), "item": str(p.get("item", "")), "n": 1}

# --- stones and caches -----------------------------------------------------------

## Adds STONE_POINTS training points in `stat` to the creature, within the per-stat and total caps. Returns how many went in.
static func train(c: Creature, stat: String) -> int:
	var total := 0
	for s in Rules.STATS:
		total += int(c.training.get(s, 0))
	var room := mini(Rules.TRAINING_STAT_CAP - int(c.training.get(stat, 0)), Rules.TRAINING_TOTAL_CAP - total)
	var n := clampi(mini(STONE_POINTS, room), 0, STONE_POINTS)
	c.training[stat] = int(c.training.get(stat, 0)) + n
	return n

static func stat_name(s: String) -> String:
	return {"hp": "stamina", "atk": "strength", "def": "toughness", "lore": "lore", "ward": "ward", "spd": "speed"}.get(s, s)

## A curio id from a list (data/items/w47_a.json ids, if that file is there) picked by the poi's id, else "".
static func curio_for(p: Dictionary, curios: Array) -> String:
	return str(curios[absi(hash(str(p.id))) % curios.size()]) if not curios.is_empty() else ""

static func curio_ids() -> Array:
	var out := []
	if FileAccess.file_exists(CURIOS_FILE):
		var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(CURIOS_FILE))
		var list: Array = j if j is Array else (j.get("items", []) if j is Dictionary else [])
		for i in list:
			if i is Dictionary and str(i.get("kind", "")) == "curio":
				out.append(str(i.id))
	return out

# --- residents -------------------------------------------------------------------

const MENTION := {
	"den": "There's a den out on %s, past the stile, if you're brave.",
	"camp": "Somebody's set up a camp out on %s. Poachers, I shouldn't wonder.",
	"stone": "There's a stone out on %s the sheep won't go near. Worth a look.",
	"cache": "The kids say something's hidden out on %s. Under a rock, they reckon.",
}

## ScriptHooks line: a resident who mentions a place says so once (setting its seen flag) after their chat.
static func hook(zone_id: String, npc_id: String, commands: Array, data: GameStateData) -> Array:
	all()
	var list: Array = _mentions.get("%s|%s" % [zone_id, npc_id], [])
	if list.is_empty():
		return commands
	var out := commands
	for p in list:
		if known(data, p):
			continue
		var z := ZoneData.load_id(str(p.zone))
		if out == commands:
			out = commands.duplicate()
		out.append({"do": "say", "who": "", "text": MENTION[str(p.kind)] % (z.name if z else "the road")})
		out.append({"do": "set", "flag": seen_key(p), "value": true})
	return out

# --- the validator -----------------------------------------------------------------

static func check(zones: Dictionary, dex: Dex, items: ItemDB) -> Array:
	var errs := []
	var ids := {}
	var world_map: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/world_map.json"))
	for p in all():
		var id := str(p.get("id", ""))
		if id == "" or ids.has(id):
			errs.append("poi '%s': missing or duplicate id" % id)
		ids[id] = true
		var k := str(p.get("kind", ""))
		if k not in KINDS:
			errs.append("poi %s: kind '%s' is not one of %s" % [id, k, KINDS])
		var z: ZoneData = zones.get(str(p.get("zone", "")))
		if z == null:
			errs.append("poi %s: zone '%s' does not exist" % [id, p.get("zone", "")])
			continue
		var near: Array = p.get("near", [])
		if near.size() != 2 or not z.in_bounds(Vector2i(int(near[0]), int(near[1]))):
			errs.append("poi %s: near is out of bounds in %s" % [id, z.id])
		elif not z.walkable(tile(z, p)):
			errs.append("poi %s: no standable tile near it in %s" % [id, z.id])
		var at := str(p.get("at", ""))
		if at != "" and not world_map.towns.has(at) and not world_map.places.has(at):
			errs.append("poi %s: map place '%s' is not on the map" % [id, at])
		var m: Dictionary = p.get("mentioned_by", {})
		if not m.is_empty():
			var mz: ZoneData = zones.get(str(m.get("zone", "")))
			if mz == null or not mz.npcs.any(func(n): return str(n.get("id", "")) == str(m.get("npc", ""))):
				errs.append("poi %s: mentioned_by %s/%s is not a resident" % [id, m.get("zone", ""), m.get("npc", "")])
		var texts: Array = [p.get("line", ""), p.get("paper", "")] + p.get("lore", [])
		for t in texts:
			if "—" in str(t) or "–" in str(t):
				errs.append("poi %s: dash in text" % id)
		match k:
			"den":
				if not dex.has(str(p.get("species", ""))):
					errs.append("poi %s: den species '%s' does not exist" % [id, p.get("species", "")])
				elif table(z).any(func(e): return str(e.species) == str(p.species)):
					errs.append("poi %s: den species '%s' is already on the route" % [id, p.species])
				if table(z).is_empty():
					errs.append("poi %s: den on a route with no wild table" % id)
			"camp":
				var party: Array = p.get("party", [])
				if party.is_empty() or p.get("names", []).is_empty():
					errs.append("poi %s: camp needs names and a party" % id)
				for s in party:
					if not dex.has(str(s)):
						errs.append("poi %s: camp species '%s' does not exist" % [id, s])
				if str(p.get("item", "")) != "" and not items.has(str(p.item)):
					errs.append("poi %s: strongbox item '%s' does not exist" % [id, p.item])
			"stone":
				if str(p.get("stat", "")) not in Rules.STATS or p.get("lore", []).is_empty():
					errs.append("poi %s: stone needs a stat and lore" % id)
			"cache":
				if not items.has(str(p.get("item", ""))):
					errs.append("poi %s: cache item '%s' does not exist" % [id, p.get("item", "")])
	return errs
