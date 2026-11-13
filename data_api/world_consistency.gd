class_name WorldConsistency
extends RefCounted
## The world matches what it says. Six rules over every zone, its signs, examine spots, Deep Place lines and the
## dialogue of the people standing in it:
##   object     a line points at a thing you could look for ("the lever by the desk", "pull the winch") that the
##              zone has nothing like (OBJECTS: props, tiles, building styles, Deep Place pieces)
##   near       a line puts a thing by another ("the lever by the desk", "a lever near the water") and in this zone
##              no such thing stands within NEAR tiles of the other
##   stairs     a line in a one-room interior sends you upstairs, down the steps or through the back
##   cave       a warp into a cave, mine or tunnel whose outside is drawn as an ordinary building
##   entrance   a warp in an outdoor zone with nothing to show a way in (no building, door, portal or map edge)
##   blocker    a warp you can only reach with a Stone's field ability, and no sign or person near the blocking
##              tiles names the Stone
##   text       leftovers in player text: unknown {tokens}, stray braces, TODO, doubled words, odd double quotes,
##              " ," and ".."
## Findings that are fine as they stand (a line about the real building upstairs, a real visitor centre over a
## cave) are listed with the reason in data/world_consistency.json, by rule, zone and key. Pure and deterministic.

const OK_FILE := "res://data/world_consistency.json"
## Words for things you could go and look for -> what in a zone counts as one. "prop:", "tile:", "style:" (part
## of a building style), "deep:<list>" (any), "look:<look>" (a Deep Place piece drawn so), "ferry", "never".
const OBJECTS := {
	"lever": ["deep:levers", "prop:lever"], "levers": ["deep:levers", "prop:lever"], "switch": ["deep:levers", "prop:lever"],
	"handle": ["deep:levers", "prop:lever"], "valve": ["look:wheel"], "sluice": ["look:wheel", "look:board"],
	"winch": ["look:winch"], "plate": ["deep:plates"], "slab": ["deep:crates", "deep:gates", "look:crack", "prop:standing_stone", "prop:tomb_chest"],
	"desk": ["prop:table", "tile:counter", "prop:kitchen_dresser"], "chest": ["prop:tomb_chest", "prop:display_case"],
	"hatch": ["tile:counter", "deep:gates"], "trapdoor": ["deep:gates"], "ladder": ["never"], "ladders": ["never"],
	"crate": ["deep:crates", "prop:barrel", "prop:market_stall"], "grille": ["look:grille"],
	"gate": ["deep:gates", "prop:field_gate", "tile:fence", "prop:harbour_arch", "style:gate", "style:castle", "style:college", "style:city_wall", "style:abbey", "style:keep"],
	"bell": ["style:church", "style:cathedral", "style:chapel", "style:kirk", "style:abbey", "style:minster", "style:tower", "style:college", "prop:clock_tower"],
	"boat": ["prop:boat", "prop:canal_boat", "prop:punt", "prop:currach", "prop:wherry", "prop:catcher_hulk", "prop:ship_ribs", "ferry"],
}
## Words in the same sentence that make a mention a pointer ("by the desk", "pull the lever"), not a story.
const CUES := "mind|by|beside|next to|behind|near|up in|over there|over by|across|at the back|in the corner|this side|pull|haul|heave|turn|spin|wind|push|climb|press|ring|works|opens|through|up the|down the"
const STAIRS := "upstairs|downstairs|up the stairs|down the stairs|up the steps|down the steps|through the back|the back room|back door"
const UNDERGROUND := "cave|caves|cavern|mine|tunnel|tunnels|pit|hole|colliery|souterrain|grotto|catacomb|catacombs"
## Outside buildings that read as a way underground.
const ENTRANCE_STYLES := ["cave_mouth", "marble_arch_cave", "canal_tunnel", "passage_tomb", "baths_boulders", "winding_gear", "engine_house"]
## Props that show a way in where there is no building.
const ENTRANCE_PROPS := ["tunnel_portal", "cave_cleft", "crypt_arch", "brick_arch", "harbour_arch"]
## Text tokens the dialogue runner fills in (Commands, Looks).
const TOKENS := ["{player}", "{rival}", "{greeting}", "{caught}", "{left}", "{total}", "{he}", "{him}", "{his}", "{Mr}", "{man}",
	"{He}", "{Him}", "{His}", "{Man}", "{worn_top}", "{worn_shoes}", "{worn_neck}", "{worn_hat}", "{worn_coat}", "{cat}", "{lead}"]  # {cat} and {lead}: CatTalk
const HINT_RADIUS := 8
## "<thing> by the <place>": where each can be, as for OBJECTS but only things with a tile (see _spots).
const THINGS := {"lever": ["deep:levers", "prop:lever"], "handle": ["deep:levers"], "switch": ["deep:levers"],
	"valve": ["look:wheel"], "sluice": ["look:wheel", "look:board"], "wheel": ["look:wheel"], "winch": ["look:winch"],
	"plate": ["deep:plates"], "gate": ["deep:gates", "prop:field_gate"]}
const PLACES := {"desk": ["prop:table", "prop:kitchen_dresser", "tile:counter"], "table": ["prop:table"],
	"counter": ["tile:counter"], "door": ["tile:door"], "water": ["tile:water", "tile:shallow", "tile:deep_water", "tile:sea"],
	"bank": ["tile:water", "tile:shallow", "tile:deep_water"], "water's": ["tile:water", "tile:shallow", "tile:deep_water", "tile:sea"],
	"wall": ["tile:void", "tile:building", "tile:drystone_wall"]}
const NEAR := 2  # tiles from the first blocking tile within which a sign or a person should name the Stone

static var _re := {}

static func _rx(key: String, pattern: String) -> RegEx:
	if not _re.has(key):
		_re[key] = RegEx.create_from_string(pattern)
	return _re[key]

## Errors for the validator: every finding not listed as fine in OK_FILE.
static func check(zones: Dictionary, dialogue: Dictionary) -> Array:
	var ok := {}
	var listed = JsonUtil.read(OK_FILE) if FileAccess.file_exists(OK_FILE) else {}
	for it in (listed.get("ok", []) if listed is Dictionary else []):
		ok["%s|%s|%s" % [it.get("rule", ""), it.get("zone", ""), it.get("key", "")]] = true
	var out := []
	for f in findings(zones, dialogue):
		if not ok.has("%s|%s|%s" % [f.rule, f.zone, f.key]):
			out.append("world: %s in %s (%s): %s" % [f.rule, f.zone, f.key, f.text])
	return out

## Every finding, as {rule, zone, key, text}. `dialogue` is StoryData.all_dialogue() (file -> script id -> commands).
static func findings(zones: Dictionary, dialogue: Dictionary) -> Array:
	var out := []
	var ids := zones.keys()
	ids.sort()
	var arrivals := _arrivals(zones)
	for zid in ids:
		var z: ZoneData = zones[zid]
		if z.stub or zid in ["testbed", "mesh_gallery"]:
			continue
		var lines := zone_lines(z, dialogue)
		out.append_array(_objects(z, lines, zones))
		out.append_array(_near(z, lines))
		out.append_array(_stairs(z, lines))
		if z.kind != "interior":
			out.append_array(_warps(z, zones))
			out.append_array(_blockers(z, arrivals.get(zid, []), lines))
	var files := dialogue.keys()
	files.sort()
	for file in files:
		var scripts: Dictionary = dialogue[file]
		for sid in scripts:
			for t in texts(scripts[sid], []):
				out.append_array(_text(str(file), str(sid), t))
	for zid in ids:
		for l in zone_lines(zones[zid], {}):
			out.append_array(_text(str(zid), str(l.who), str(l.text)))
	var seen := {}
	return out.filter(func(f):
		var k := "%s|%s|%s|%s" % [f.rule, f.zone, f.key, f.text]
		if seen.has(k):
			return false
		seen[k] = true
		return true)

# --- what a zone says ---------------------------------------------------------------------------------------------

## Every line the player reads in a zone, as {who, text}: its people's scripts, signs, examine spots, Deep Place
## lines and locked warps.
static func zone_lines(z: ZoneData, dialogue: Dictionary) -> Array:
	var out := []
	if not dialogue.is_empty():
		var common: Dictionary = dialogue.get("common", {})
		var own: Dictionary = dialogue.get(z.id, {})
		for n in z.npcs:
			var sid := str(n.get("script", ""))
			for t in texts(own.get(sid, common.get(sid, [])), []):
				out.append({"who": str(n.get("id", "")), "text": t})
	for s in z.signs:
		out.append({"who": "sign %d,%d" % [int(s.x), int(s.y)], "text": str(s.get("text", ""))})
	for e in z.examine:
		for t in texts(e, []):
			out.append({"who": "examine %d,%d" % [int(e.x), int(e.y)], "text": t})
	for kind in ["levers", "gates"]:
		for it in z.deep.get(kind, []):
			for key in ["line", "on", "off"]:
				if it.has(key):
					out.append({"who": "deep %d,%d" % [int(it.x), int(it.y)], "text": str(it[key])})
	for w in z.warps:
		if w.get("locked") is Dictionary and w.locked.has("line"):
			out.append({"who": "warp %d,%d" % [int(w.x), int(w.y)], "text": str(w.locked.line)})
	return out

## Every "text" (a string or a list of them) anywhere in a script or record.
static func texts(x: Variant, out: Array) -> Array:
	if x is Dictionary:
		for k in x:
			var v = x[k]
			if k in ["text", "line", "lose_line", "next_line"] and v is String:
				out.append(v)
			elif k == "text" and v is Array:
				for t in v:
					if t is String:
						out.append(t)
			else:
				texts(v, out)
	elif x is Array:
		for v in x:
			texts(v, out)
	return out

static func _sentences(t: String) -> PackedStringArray:
	return t.replace("! ", ".\n").replace("? ", ".\n").replace(". ", ".\n").split("\n", false)

# --- object ---------------------------------------------------------------------------------------------------------

static func _objects(z: ZoneData, lines: Array, zones: Dictionary) -> Array:
	var out := []
	var words := "|".join(PackedStringArray(OBJECTS.keys()))
	var re := _rx("obj", "(?i)\\b(the|a|an|that|this|my|our)\\s+(?:[\\w'-]+\\s){0,2}?(" + words + ")\\b")
	var cue := _rx("cue", "(?i)\\b(" + CUES + ")\\b")
	var have := {}  # worked out on the first mention: most zones never point at anything
	var seen := {}
	var any := _rx("any", "(?i)\\b(" + words + ")\\b")
	for l in lines:
		if any.search(str(l.text)) == null:
			continue
		for s in _sentences(str(l.text)):
			if cue.search(s) == null:
				continue
			for m in re.search_all(s):
				var w := m.get_string(2).to_lower()
				if have.is_empty():
					have = _evidence(z, zones)
				if seen.has(w) or _has_any(have, OBJECTS[w]):
					continue
				seen[w] = true
				out.append({"rule": "object", "zone": z.id, "key": w, "text": "%s says \"%s\" and nothing here is one" % [l.who, s.strip_edges()]})
	return out

static func _has_any(have: Dictionary, wants: Array) -> bool:
	for want in wants:
		var w := str(want)
		if w.begins_with("style:"):
			for k in have:
				if str(k).begins_with("style:") and str(k).contains(w.substr(6)):
					return true
		elif have.has(w):
			return true
	return false

## What a zone has that a line could point at. An interior also counts the outside it opens on to, and the rooms
## beyond it up to CHAIN warps away (a cave guide describes the chambers below).
const CHAIN := 3

static func _evidence(z: ZoneData, zones: Dictionary) -> Dictionary:
	var have := {"zone": true}
	var seen := {z.id: true}
	var ring := [z]
	for hop in CHAIN + 1:
		var next := []
		for r in ring:
			have.merge(_things(r))
			if r.kind != "interior":
				continue
			for w in r.warps:
				var to: ZoneData = zones.get(str(w.get("to", "")))
				if to and not seen.has(to.id) and (hop < CHAIN or to.kind != "interior"):
					seen[to.id] = true
					next.append(to)
		ring = next
	return have

static func _things(z: ZoneData) -> Dictionary:
	var have := {}
	for p in z.props:
		have["prop:" + str(p.get("type", ""))] = true
		if p.get("type") == "building":
			have["style:" + str(p.get("style", ""))] = true
	for row in z.tiles:
		for t in row:
			have["tile:" + str(t)] = true
	for kind in z.deep:
		if not z.deep[kind].is_empty():
			have["deep:" + kind] = true
	for pair in [[DeepPlace.LEVER_PROP, "levers"], [DeepPlace.GATE_PROP, "gates"], [DeepPlace.CRATE_PROP, "crates"]]:
		for it in z.deep.get(pair[1], []):
			have["look:" + DeepPlace.look_of(pair[0], it)] = true
	if not z.ferry.is_empty():
		have["ferry"] = true
	return have

# --- near -----------------------------------------------------------------------------------------------------------

static func _near(z: ZoneData, lines: Array) -> Array:
	var re := _rx("near", "(?i)\\b(" + "|".join(PackedStringArray(THINGS.keys())) + ")\\b[^.?!]{0,30}?\\b(?:by|beside|next to|near)\\s+the\\s+(?:[\\w-]+\\s)?(" + "|".join(PackedStringArray(PLACES.keys())) + ")\\b")
	var out := []
	for l in lines:
		for m in re.search_all(str(l.text)):
			var things := _spots(z, THINGS[m.get_string(1).to_lower()])
			var places := _spots(z, PLACES[m.get_string(2).to_lower()])
			if things.is_empty() or places.is_empty():
				continue  # not in this zone: the object rule speaks for the zone as a whole
			var ok := false
			for a in things:
				for b in places:
					ok = ok or maxi(absi(a.x - b.x), absi(a.y - b.y)) <= NEAR
			if not ok:
				out.append({"rule": "near", "zone": z.id, "key": m.get_string(0).to_lower(), "text": "%s says \"%s\" but none is within %d tiles of one" % [l.who, m.get_string(0), NEAR]})
	return out

## Tiles where things of these kinds stand in a zone.
static func _spots(z: ZoneData, kinds: Array) -> Array:
	var out := []
	for k in kinds:
		var kind := str(k)
		if kind.begins_with("prop:"):
			for p in z.props:
				if p.get("type", "") == kind.substr(5) and p.has("x"):
					out.append(Vector2i(int(p.x), int(p.y)))
		elif kind.begins_with("deep:"):
			for it in z.deep.get(kind.substr(5), []):
				out.append(Vector2i(int(it.x), int(it.y)))
		elif kind.begins_with("look:"):
			for it in z.deep.get("levers", []):
				if DeepPlace.look_of(DeepPlace.LEVER_PROP, it) == kind.substr(5):
					out.append(Vector2i(int(it.x), int(it.y)))
		elif kind.begins_with("tile:"):
			for y in z.height:
				for x in z.width:
					if z.tiles[y][x] == kind.substr(5):
						out.append(Vector2i(x, y))
	return out

# --- stairs ---------------------------------------------------------------------------------------------------------

static func _stairs(z: ZoneData, lines: Array) -> Array:
	if z.kind != "interior" or z.warps.size() > 1:
		return []
	var re := _rx("stairs", "(?i)\\b(" + STAIRS + ")\\b")
	var out := []
	var seen := {}
	for l in lines:
		for m in re.search_all(str(l.text)):
			var w := m.get_string(1).to_lower()
			if not seen.has(w):
				seen[w] = true
				out.append({"rule": "stairs", "zone": z.id, "key": w, "text": "%s mentions \"%s\" in a room with one way out" % [l.who, w]})
	return out

# --- warps ----------------------------------------------------------------------------------------------------------

static func _warps(z: ZoneData, zones: Dictionary) -> Array:
	var out := []
	var under := _rx("under", "(?i)\\b(" + UNDERGROUND + ")\\b")
	for w in z.warps:
		var p := Vector2i(int(w.x), int(w.y))
		var to: ZoneData = zones.get(str(w.get("to", "")))
		var b := z.building_at(p)
		var style := str(b.get("style", ""))
		var near := _near_props(z, p)
		var marked := not ENTRANCE_PROPS.filter(func(t): return t in near).is_empty()
		if to and to.kind == "interior" and (to.dark or to.stage == "cave" or under.search(to.name) != null) \
				and style not in ENTRANCE_STYLES and not marked:
			out.append({"rule": "cave", "zone": z.id, "key": to.id, "text": "the way into %s at %d,%d is drawn as %s" % [to.name, p.x, p.y, ("a '%s' building" % style) if style != "" else "nothing"]})
		if b.is_empty() and z.tile_at(p) != "door" and not marked and not w.get("hidden", false) and not _on_border(z, p) and not _path_end(z, p):
			out.append({"rule": "entrance", "zone": z.id, "key": str(w.get("to", "")), "text": "the warp at %d,%d to %s has nothing to show a way in" % [p.x, p.y, str(w.get("to", ""))]})
	return out

static func _near_props(z: ZoneData, p: Vector2i) -> Array:
	var out := []
	for pr in z.props:
		if pr.has("x") and absi(int(pr.x) - p.x) <= 1 and absi(int(pr.y) - p.y) <= 1:
			out.append(str(pr.get("type", "")))
	return out

## A path that runs up to the warp and stops at a hedge, a tree line or a cliff: the way on is plain to see.
static func _path_end(z: ZoneData, p: Vector2i) -> bool:
	if z.tile_at(p) not in ["path", "road", "cobbles"]:
		return false
	for d in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
		if z.tile_at(p - d) in ["path", "road", "cobbles"] and not z.walkable(p + d):
			return true
	return false

static func _on_border(z: ZoneData, p: Vector2i) -> bool:
	return p.x == 0 or p.y == 0 or p.x == z.width - 1 or p.y == z.height - 1

# --- blockers -------------------------------------------------------------------------------------------------------

## zone id -> tiles people arrive on from outdoor zones' warps (coming back out of a building or a cave puts you
## on the far side of whatever kept you out of it, so those don't count).
static func _arrivals(zones: Dictionary) -> Dictionary:
	var out := {}
	for zid in zones:
		if zones[zid].kind == "interior":
			continue
		for w in zones[zid].warps:
			var to := str(w.get("to", ""))
			if not out.has(to):
				out[to] = []
			out[to].append(Vector2i(int(w.get("tx", -1)), int(w.get("ty", -1))))
	return out

static func _blockers(z: ZoneData, arrivals: Array, lines: Array) -> Array:
	if z.warps.is_empty() or not _has_ability_tiles(z):
		return []
	var starts := arrivals.duplicate()
	starts.append(z.spawn)
	for side in z.edges:
		starts.append_array(z._border(side))
	var walk := {}
	for s in starts:
		if z.in_bounds(s) and z.walkable(s) and not walk.has(s):
			walk.merge(z.reachable(s))
	if z.warps.all(func(w): return walk.has(Vector2i(int(w.x), int(w.y))) or w.get("hidden", false)):
		return []
	var full := {}
	for s in starts:
		if z.in_bounds(s) and z.walkable(s, Vector2i.ZERO, ZoneData.GATE_ABILITIES) and not full.has(s):
			full.merge(z.reachable(s, ZoneData.GATE_ABILITIES))
	var gated := []
	for w in z.warps:
		var p := Vector2i(int(w.x), int(w.y))
		if not walk.has(p) and full.has(p) and not w.get("hidden", false):
			gated.append(w)
	if gated.is_empty():
		return []
	var first := []  # blocking tiles at the edge of where you can walk
	for p in walk:
		for d in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
			var q: Vector2i = p + d
			if FieldMoves.TILE_ABILITY.has(z.tile_at(q)) and full.has(q):
				first.append(q)
	var words := _rx("stone", "(?i)\\b(stone|" + "|".join(PackedStringArray(FieldMoves.NAMES.values())).replace("-", "\\-") + ")\\b")
	var hinted := false
	for s in z.signs:
		hinted = hinted or (_close(Vector2i(int(s.x), int(s.y)), first) and words.search(str(s.get("text", ""))) != null)
	for n in z.npcs:
		if _close(Vector2i(int(n.x), int(n.y)), first):
			for l in lines:
				hinted = hinted or (l.who == str(n.get("id", "")) and words.search(str(l.text)) != null)
	if hinted:
		return []
	var out := []
	for w in gated:
		out.append({"rule": "blocker", "zone": z.id, "key": str(w.get("to", "")), "text": "the warp at %d,%d to %s is behind %s with no sign near it naming the Stone" % [int(w.x), int(w.y), str(w.get("to", "")), z.tile_at(first[0]) if not first.is_empty() else "something"]})
	return out

static func _has_ability_tiles(z: ZoneData) -> bool:
	for row in z.tiles:
		for t in row:
			if t == "bramble" or ZoneData.ABILITY_TILES.has(t):
				return true
	return false

static func _close(p: Vector2i, tiles: Array) -> bool:
	for q in tiles:
		if maxi(absi(q.x - p.x), absi(q.y - p.y)) <= HINT_RADIUS:
			return true
	return false

# --- text -----------------------------------------------------------------------------------------------------------

static func _text(where: String, who: String, t: String) -> Array:
	var out := []
	var bad := []
	if t.contains("{") or t.contains("}"):
		var stripped := t
		for tok in TOKENS:
			stripped = stripped.replace(tok, "")
		if stripped.contains("{") or stripped.contains("}"):
			bad.append("a stray brace or unknown token")
	for word in ["TODO", "XXX", "FIXME", "TBD"]:
		if t.contains(word):
			bad.append(word)
	var dbl := _rx("dbl", "(?i)\\b(the|a|an|to|of|and|in|on|is|it|for|with|at|be|was|you|your|i|we|my|this|that)\\s+\\1\\b").search(t)
	if dbl and not (dbl.get_string(1).to_lower() in ["that", "is"]):  # "that that" and "is is" can be meant
		bad.append("doubled '%s'" % dbl.get_string(1))
	if t.count("\"") % 2 == 1 or t.count("“") != t.count("”"):
		bad.append("odd quotes")
	var dots := t.replace("...", "")
	if t.contains(" ,") or dots.contains(" .") or dots.contains(".."):
		bad.append("stray punctuation")
	for b in bad:
		out.append({"rule": "text", "zone": where, "key": who, "text": "%s: \"%s\"" % [b, t.substr(0, 90)]})
	return out
