class_name Rumours
extends RefCounted
## The Fieldbook's Rumours tab: local gossip about creatures you haven't caught yet, written from the
## encounter tables. Only places in a region you've been to (or the next one over) get talked about. A creature
## you've never seen is described by its size and type colour; once you've seen one, they use its name.
## Pure logic: species info comes in as {id: {name, types, base}}, so tests needn't load the Dex.

## Who's doing the talking, by where the creature lives.
const SPEAKERS := {
	"grass": ["a birder", "a dog walker", "a farmer", "a rambler", "the postie", "a lad outside the chippy",
		"a woman with a flask", "the bus driver", "a man with binoculars", "a retired teacher"],
	"water": ["a fisherman", "the ferryman", "a lock keeper", "a wild swimmer", "a man with a rod", "a canoeist"],
}

## [table ("any", "grass" or "water"), text]. {who}/{Who} a speaker, {place} the zone, {what} the creature,
## {where} the habitat ("in the long grass"),
## {when} " at dusk" etc. (or ""), {when_or} the same but never empty, {Thing} "Something leaf green" or the name.
const TEMPLATES := [
	["any", "{Who} at {place} swears there's {what} {where}{when}."],
	["any", "According to {who}, {what} has been turning up {where} at {place}{when}."],
	["any", "Word in the pub is there's {what} {where} at {place}{when}. Nobody's caught it yet."],
	["any", "The landlady says her cousin saw {what} {where} at {place}{when}. Her cousin also saw Elvis, mind."],
	["any", "{Who} told the bus queue about {what} {where} at {place}{when}. The bus queue was unmoved."],
	["any", "\"{What_cap}, {where} at {place}{when}. I know what I saw,\" says {who}."],
	["any", "{Who} reckons {what} lives {where} at {place}, and only shows itself{when_or}."],
	["any", "A note on the parish noticeboard: \"Has anyone else seen {what} {where} at {place}{when}?\""],
	["any", "{Who} lost a whole sandwich to {what} {where} at {place}{when}. Still bitter about it."],
	["any", "Somebody's posted a blurry photo of {what} {where} at {place}{when}. It could be a bin bag. It isn't."],
	["any", "{Who} keeps a notebook. Last entry: \"{place}{when}. {What_cap}, {where}. Again.\""],
	["any", "The bus driver on the {place} run says to keep your eyes peeled{when}. There's {what} about."],
	["any", "{Who} says if you want {what}, try {where} at {place}{when}. Bring a flask."],
	["any", "There's talk at the village shop of {what} {where} at {place}{when}. The shopkeeper's selling more torches."],
	["any", "{Who} heard something rustle {where} at {place}{when}, and caught a glimpse of {what}."],
	["any", "A postcard on the pub wall: \"Weather lovely. Saw {what} {where} at {place}{when}. Wish you were here.\""],
	["grass", "{Who} at {place} says the sheep won't go near the long grass{when}. {Thing} has them spooked."],
	["grass", "A farmer at {place} has stopped mowing the top field. Says there's {what} in there{when} and it glares."],
	["grass", "{Who} walking the lanes at {place}{when} swears {what} followed them for a mile."],
	["grass", "The dog at {place} won't stop barking at the hedge{when}. {Who} reckons it's {what}."],
	["grass", "{Who} spotted {what} slipping through the heather at {place}{when}. Gone before the kettle boiled."],
	["water", "The ferryman says the water off {place} churns{when}. {What_cap}, he reckons."],
	["water", "{Who} at {place} had a bite that nearly took the rod{when}. Saw {what} just under the surface."],
	["water", "{Who} says to watch the water at {place}{when}. There's {what} out there, and it's watching back."],
	["water", "A wild swimmer at {place} came out faster than she went in{when}. {Thing} brushed past her."],
	["water", "The lock keeper near {place} keeps finding the water stirred up{when}. Says it's {what}."],
]

## Colour words for a creature's first type, for the ones you've never seen.
const TYPE_COLOURS := {
	"kin": "sandy brown", "hedgerow": "leaf green", "brook": "river blue", "tide": "sea green", "hearth": "ember orange",
	"gale": "sky pale", "storm": "thundery yellow", "frost": "icy white", "stone": "slate grey", "bog": "peaty brown",
	"iron": "rusty red", "urban": "brick red", "fae": "lilac", "spirit": "ghostly pale", "brawn": "bruise purple",
	"night": "inky black",
}

const WHERE := {"grass": "in the long grass", "water": "in the water", "cave": "down in the dark"}

## Time sets read better as one phrase than as a list.
const TIME_PHRASES := {
	"dawn": "at first light", "day": "in the daytime", "dusk": "at dusk", "night": "after dark",
	"dusk,night": "from dusk till late", "dawn,dusk": "at dawn and dusk", "dawn,day": "in the mornings",
	"day,dusk": "in the afternoons", "dawn,day,dusk": "while it's light", "dawn,dusk,night": "between dusk and dawn",
	"dawn,night": "in the small hours",
}
const WEATHER_PHRASES := {
	"fog": "in the fog", "drizzle": "in the rain", "downpour": "in the rain", "gale": "when the wind's up",
	"frost": "on frosty days", "sunshine": "when the sun's out", "clear": "on clear days",
}
const TIME_ORDER := ["dawn", "day", "dusk", "night"]
const WEATHER_ORDER := ["clear", "sunshine", "drizzle", "downpour", "fog", "gale", "frost"]

## "in the fog at dusk", "after dark in winter", or "" for any time, any weather, any season.
static func when_phrase(times: Array, weathers: Array, seasons: Array = []) -> String:
	var parts := []
	var w := []
	var in_the := []  # "in the rain or fog" rather than "in the rain or in the fog"
	for x in WEATHER_ORDER:
		var ph: String = WEATHER_PHRASES[x]
		if x not in weathers:
			continue
		if ph.begins_with("in the "):
			if ph.substr(7) not in in_the:
				in_the.append(ph.substr(7))
		elif ph not in w:
			w.append(ph)
	if not in_the.is_empty():
		w.push_front("in the " + " or ".join(in_the))
	if not w.is_empty():
		parts.append(" or ".join(w.slice(0, 2)))  # two's plenty for gossip
	var t := TIME_ORDER.filter(func(x): return x in times)
	if not t.is_empty() and t.size() < 4:
		var key := ",".join(t)
		parts.append(str(TIME_PHRASES[key]) if TIME_PHRASES.has(key) else " or ".join(t.map(func(x): return TIME_PHRASES[x])))
	var s := Calendar.SEASONS.filter(func(x): return x in seasons)
	if not s.is_empty() and s.size() < 4:
		if s == ["spring", "winter"]:  # the year turns at New Year, not in March
			s = ["winter", "spring"]
		parts.append("in " + " and ".join(s) if s.size() < 3 else "except in " + str(Calendar.SEASONS.filter(func(x): return x not in s)[0]))
	return " ".join(parts)

## A creature you've never seen: "something small and leaf green". Seen: "a Pepperling".
static func describe(info: Dictionary, seen: bool) -> String:
	if seen:
		var nm := str(info.get("name", "?"))
		return ("an " if nm.substr(0, 1).to_lower() in ["a", "e", "i", "o", "u"] else "a ") + nm
	var types: Array = info.get("types", [])
	var colour := str(TYPE_COLOURS.get(str(types[0]) if not types.is_empty() else "", "odd-looking"))
	var size := size_word(info.get("base", {}))
	return "something %s%s" % [(size + " and ") if size != "" else "", colour]

static func size_word(base: Dictionary) -> String:
	var total := 0
	for k in base:
		total += int(base[k])
	if total == 0:
		return ""
	if total < 330:
		return "small"
	if total >= 480:
		return "big"
	return ""

## A stable pick for a creature and place, so the gossip doesn't change every time you open the book.
static func _pick(key: String, n: int) -> int:
	return posmod(hash(key), n) if n > 0 else 0

## The gossip line for one encounter entry.
static func text(species: String, info: Dictionary, seen: bool, place: String, table: String, times: Array, weathers: Array, seasons: Array = []) -> String:
	var ok := TEMPLATES.filter(func(t): return t[0] == "any" or t[0] == table)
	var tpl: String = ok[_pick(species + "@" + place, ok.size())][1]
	var pool: Array = SPEAKERS.get(table, SPEAKERS.grass)
	var who: String = pool[_pick(place + "#" + species, pool.size())]
	var what := describe(info, seen)
	var when := when_phrase(times, weathers, seasons)
	var thing := what.substr(0, 1).to_upper() + what.substr(1)
	if not seen:  # "Something leaf green", without the size
		var types: Array = info.get("types", [])
		thing = "Something " + str(TYPE_COLOURS.get(str(types[0]) if not types.is_empty() else "", "odd-looking"))
	return tpl.replace("{Who}", who.substr(0, 1).to_upper() + who.substr(1)).replace("{who}", who) \
		.replace("{What_cap}", what.substr(0, 1).to_upper() + what.substr(1)).replace("{what}", what) \
		.replace("{where}", str(WHERE.get(table, "about"))).replace("{place}", place) \
		.replace("{when_or}", (" " + when) if when != "" else " when it feels like it") \
		.replace("{when}", (" " + when) if when != "" else "").replace("{Thing}", thing)

## Regions whose gossip reaches you: the regions of towns you've visited (and where you are), plus their neighbours.
static func regions_in_reach(data: GameStateData, idx: Dictionary, here_zone: String) -> Array:
	var visited := []
	for id in idx.zones:
		var z: Dictionary = idx.zones[id]
		if z.region != "" and z.kind == "town" and data.flag("visited_" + str(z.town if z.town != "" else id)) == true and z.region not in visited:
			visited.append(z.region)
	var here := str(idx.zones.get(here_zone, {}).get("region", ""))
	if here != "" and here not in visited:
		visited.append(here)
	var out := visited.duplicate()
	for r in visited:
		for n in idx.adj.get(r, []):
			if n not in out:
				out.append(n)
	return out

## Where the player is on the world map: this zone's spot, else the last town's.
static func here_pos(data: GameStateData, idx: Dictionary, here_zone: String) -> Vector2:
	var p := ZoneIndex.pos_of(idx, here_zone)
	if p.x < 0.0:
		p = ZoneIndex.pos_of(idx, str(data.flag("last_town") if data.flag("last_town") else ""))
	return p

## [{species, zone, place, region, seen, text, dist}] for every species not yet caught that lives in reach,
## one rumour each (its nearest place), nearest first. `species_info` is {id: {name, types, base}}.
static func build(data: GameStateData, idx: Dictionary, species_info: Dictionary, here_zone: String) -> Array:
	var reach := regions_in_reach(data, idx, here_zone)
	var from := here_pos(data, idx, here_zone)
	var best := {}  # species -> {zone, entry, dist}
	for id in idx.zones:
		var z: Dictionary = idx.zones[id]
		if z.region not in reach or z.enc.is_empty():
			continue
		var d: float = from.distance_to(z.pos) if from.x >= 0.0 and z.pos.x >= 0.0 else 9999.0
		for e in z.enc:
			var sp: String = e.species
			if data.caught.has(sp) or not species_info.has(sp):
				continue
			var year_round: bool = (e.get("season", []) as Array).is_empty()
			if not best.has(sp) or d < best[sp].dist or (d == best[sp].dist and (id < best[sp].zone or (id == best[sp].zone and year_round))):
				best[sp] = {"zone": id, "entry": e, "dist": d}
	var out := []
	for sp in best:
		var b: Dictionary = best[sp]
		var z: Dictionary = idx.zones[b.zone]
		var seen := data.seen.has(sp)
		out.append({"species": sp, "zone": b.zone, "place": z.name, "region": z.region, "seen": seen, "dist": b.dist,
			"text": text(sp, species_info[sp], seen, z.name, "cave" if z.kind == "interior" else b.entry.table, b.entry.time, b.entry.weather,
				b.entry.get("season", []))})
	out.sort_custom(func(a, b): return a.dist < b.dist if a.dist != b.dist else a.species < b.species)
	return out

# --- the legend hunt (5.4) ------------------------------------------------------------
## data/legend_hunts.json (tools/explore/gen_legend_hunts.py): for each legend stood in the world, one or two rumours of
## its real folklore, each told once by a named resident of its region (ScriptHooks.wrap calls `hook`). Hearing one sets
## a flag, rings the legend's place on the map (`marks`) and gives the Fieldbook a clue (`clue`) in place of "somewhere
## secret". A hunt: {id, species, zone, rumours: [{zone, npc, text, clue}]}. Absent flag = not heard.

const HUNTS_PATH := "res://data/legend_hunts.json"
const HEARD := "legend_"

static var _hunts: Array = []
static var _tellers: Dictionary = {}   # "zone|npc" -> [hunt index, rumour index]
static var _hunts_loaded := false

static func hunts() -> Array:
	if not _hunts_loaded:
		_hunts_loaded = true
		var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(HUNTS_PATH)) if FileAccess.file_exists(HUNTS_PATH) else null
		_hunts = j if j is Array else []
		for h in _hunts.size():
			var rs: Array = _hunts[h].get("rumours", [])
			for i in rs.size():
				_tellers["%s|%s" % [rs[i].get("zone", ""), rs[i].get("npc", "")]] = [h, i]
	return _hunts

static func heard_key(hunt_id: String, i: int) -> String:
	return "%s%s_%d" % [HEARD, hunt_id, i]

## How many of a hunt's rumours the player has heard.
static func heard_count(data: GameStateData, hunt: Dictionary) -> int:
	var n := 0
	for i in hunt.get("rumours", []).size():
		if data.flag(heard_key(str(hunt.id), i)) == true:
			n += 1
	return n

static func hunt_of(species: String) -> Dictionary:
	for h in hunts():
		if str(h.species) == species:
			return h
	return {}

## The Fieldbook's clue for a legend: the clue of the last rumour you have heard of it, or "".
static func clue(data: GameStateData, species: String) -> String:
	var h := hunt_of(species)
	var best := ""
	var rs: Array = h.get("rumours", [])
	for i in rs.size():
		if data.flag(heard_key(str(h.id), i)) == true:
			best = str(rs[i].get("clue", ""))
	return best

## ScriptHooks line: a resident who has a rumour tells it once, after what they would have said. Nothing for a legend
## you have already caught.
static func hook(zone_id: String, npc_id: String, commands: Array, data: GameStateData) -> Array:
	hunts()
	var hit = _tellers.get("%s|%s" % [zone_id, npc_id])
	if hit == null:
		return commands
	var h: Dictionary = _hunts[int(hit[0])]
	var i := int(hit[1])
	if data.flag(heard_key(str(h.id), i)) == true or data.caught.has(str(h.species)):
		return commands
	return commands + [{"do": "say", "who": "", "text": str(h.rumours[i].text)}, {"do": "set", "flag": heard_key(str(h.id), i)}]

## The map's marks for legends you have heard of: ringed until caught, then ticked. {kind "legend", at (a zone id), done}.
static func marks(data: GameStateData) -> Array:
	var out := []
	for h in hunts():
		if heard_count(data, h) > 0:
			out.append({"kind": "legend", "at": str(h.zone), "done": data.caught.has(str(h.species)), "ring": true})
	return out

## The validator: every hunt names a real legend and place, every teller is a free-standing resident of a real zone
## (no gate on them, so the rumour is always there to hear), no two tellers are the same person, no dashes.
static func check(zones: Dictionary, dex: Dex) -> Array:
	var errs := []
	var ids := {}
	var who := {}
	for h in hunts():
		var id := str(h.get("id", ""))
		if id == "" or ids.has(id):
			errs.append("legend hunt '%s': missing or duplicate id" % id)
		ids[id] = true
		if not dex.has(str(h.get("species", ""))):
			errs.append("legend hunt %s: species '%s' does not exist" % [id, h.get("species", "")])
		if not zones.has(str(h.get("zone", ""))):
			errs.append("legend hunt %s: zone '%s' does not exist" % [id, h.get("zone", "")])
		var rs: Array = h.get("rumours", [])
		if rs.is_empty() or rs.size() > 2:
			errs.append("legend hunt %s: wants one or two rumours" % id)
		for r in rs:
			var z: ZoneData = zones.get(str(r.get("zone", "")))
			var key := "%s|%s" % [r.get("zone", ""), r.get("npc", "")]
			var npc: Dictionary = {}
			if z != null:
				for n in z.npcs:
					if str(n.get("id", "")) == str(r.get("npc", "")):
						npc = n
			if npc.is_empty():
				errs.append("legend hunt %s: teller %s is not a resident" % [id, key])
			elif npc.has("hide_if") or npc.has("show_if") or npc.has("shop"):
				errs.append("legend hunt %s: teller %s is gated or a shop, so the rumour may never be heard" % [id, key])
			if who.has(key):
				errs.append("legend hunt %s: teller %s already tells another rumour" % [id, key])
			who[key] = true
			for t in [str(r.get("text", "")), str(r.get("clue", ""))]:
				if t == "" or "—" in t or "–" in t:
					errs.append("legend hunt %s: empty text or a dash" % id)
			if str(r.get("text", "")).length() > 300 or str(r.get("clue", "")).length() > 110:
				errs.append("legend hunt %s: a rumour or clue is too long to read comfortably" % id)
	return errs
