class_name Secrets
extends RefCounted
## Hidden places (5.6): fifteen small rooms that are not on the way to anywhere, each a real kind of place at a real
## spot (a cave behind a waterfall, a priest hole, a crannog), each with one thing worth the trip that is not money.
## data/secrets.json lists them: {secrets: [{id, zone (the room, secret_*), at (the outdoor zone that hides it), x, y
## (the hidden warp's tile there), reveal (the flag that opens it), how, coracle?, name, nation, kind}]}. The way in is
## an ordinary `hidden` warp with that reveal flag, so until it is set the warp is not there at all; what sets the flag
## is something in the world (an examine spot, a resident's rumour, a bottle, the dawn). Once revealed the creature's
## sense cue calls you over to it, the map rings the place, and the Atlas counts it. Entering the room the first time
## is a "HIDDEN PLACE" card and the same small treat for the party that any new place gives. An old save has none of
## the flags, so nothing is revealed and nothing changes. Pure: no autoload names (the validator loads it).

const PATH := "res://data/secrets.json"
const PREFIX := "secret_"
const LABEL := "HIDDEN PLACE"

static var _all: Array = []
static var _by_zone := {}
static var _by_at := {}
static var _loaded := false
static var _water := {}

static func clear_cache() -> void:
	_all = []
	_by_zone = {}
	_by_at = {}
	_loaded = false
	_water = {}

static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var d = JsonUtil.read(PATH)
	if not (d is Dictionary):
		return
	for s in d.get("secrets", []):
		_all.append(s)
		_by_zone[str(s.zone)] = s
		var at := str(s.at)
		if not _by_at.has(at):
			_by_at[at] = []
		_by_at[at].append(s)

static func all() -> Array:
	_load()
	return _all

static func is_secret_zone(zone_id: String) -> bool:
	return zone_id.begins_with(PREFIX)

## The secret whose room is `zone_id` ({} if it is not one).
static func by_zone(zone_id: String) -> Dictionary:
	_load()
	return _by_zone.get(zone_id, {})

## The secrets hidden in this outdoor zone.
static func in_zone(zone_id: String) -> Array:
	_load()
	return _by_at.get(zone_id, [])

static func tile(s: Dictionary) -> Vector2i:
	return Vector2i(int(s.x), int(s.y))

static func revealed(d: GameStateData, s: Dictionary) -> bool:
	return ZoneData.flag_on(d.flag(str(s.reveal)))

## The Stone that crosses the water a coracle place sits on: the Tide Stone for the sea, the Urban Stone for a lake.
## Until the player has it the way in is a rumour only: no cue, no keyhole (the flag is still set, so it all appears
## the moment the Stone is won). "" for a place on land.
static func stone_for(s: Dictionary) -> String:
	if not bool(s.get("coracle", false)):
		return ""
	var id := str(s.id)
	if not _water.has(id):
		_water[id] = "tide" if ZoneData.load_id(str(s.at)).tile_at(tile(s)) == "sea" else "urban"
	return _water[id]

## Revealed, and (for a coracle place) the player can cross to it.
static func known(d: GameStateData, s: Dictionary) -> bool:
	if not revealed(d, s):
		return false
	var need := stone_for(s)
	return need == "" or need in d.badges

static func found(d: GameStateData, s: Dictionary) -> bool:
	return Discovery.is_found(d, str(s.zone))

## Found and total: "hidden places 3 of 15".
static func tally(d: GameStateData) -> Vector2i:
	var n := 0
	for s in all():
		if found(d, s):
			n += 1
	return Vector2i(n, all().size())

static func line(d: GameStateData) -> String:
	var t := tally(d)
	return "hidden places %d of %d" % [t.x, t.y]

## Found and total among the secrets hidden in one region (the region of the zone that hides them).
static func tally_in(d: GameStateData, idx: Dictionary, region: String) -> Vector2i:
	var n := 0
	var total := 0
	for s in all():
		if str(idx.get("zones", {}).get(str(s.at), {}).get("region", "")) != region:
			continue
		total += 1
		if found(d, s):
			n += 1
	return Vector2i(n, total)

## The card for the room just entered, or {} (already found, or not a secret). Same shape as Discovery.note's, with
## the label and the place that hides it; Discovery.note holds it for the zone card.
static func note(d: GameStateData, zone: ZoneData, idx: Dictionary) -> Dictionary:
	var s := by_zone(zone.id)
	if s.is_empty() or Discovery.is_found(d, zone.id):
		return {}
	d.set_flag(Discovery.found_key(zone.id), true)
	var gain := Discovery.reward(d, zone.id)
	var t := tally(d)
	var sub := str(idx.get("zones", {}).get(str(s.at), {}).get("name", ""))
	return {"zone": zone.id, "name": zone.name, "count": t.x, "total": t.y, "gain": gain, "label": LABEL, "sub": sub}

## What the sense cue sees: revealed secrets here, not yet entered, not sensed before, within `range` tiles of the way in.
static func nearby(zone_id: String, pos: Vector2i, d: GameStateData, reach: int) -> Array:
	var out := []
	for s in in_zone(zone_id):
		if not known(d, s) or found(d, s) or d.flag(Discovery.sensed_key(str(s.id))) == true:
			continue
		var at := tile(s)
		if maxi(absi(pos.x - at.x), absi(pos.y - at.y)) <= reach:
			out.append({"kind": "secret", "id": str(s.id), "at": at})
	return out

## The map's marks: a ringed keyhole at the place that hides each secret you know of, filled once you have been in.
static func marks(d: GameStateData) -> Array:
	var out := []
	for s in all():
		if known(d, s):
			out.append({"kind": "secret", "at": str(s.at), "done": found(d, s), "ring": true})
	return out

# --- validation ----------------------------------------------------------------------------

## Data errors for tools/validate.gd and the tests: rooms and warps line up, nobody else leads in, the reveal can happen,
## the thing inside is real. `settable` is Quests.all_settable().
static func problems(zones: Dictionary, settable: Dictionary, items, dex) -> Array:
	var out := []
	var seen := {}
	for s in all():
		var id := str(s.get("id", ""))
		var tag := "secret %s: " % id
		var zid := str(s.get("zone", ""))
		if id == "" or seen.has(id) or not zid.begins_with(PREFIX):
			out.append(tag + "needs a unique id and a room named secret_*")
		seen[id] = true
		if not zones.has(zid) or (zones[zid] as ZoneData).kind != "interior":
			out.append(tag + "room '%s' is not an interior" % zid)
			continue
		var room: ZoneData = zones[zid]
		var at := str(s.get("at", ""))
		if not zones.has(at) or (zones[at] as ZoneData).kind == "interior":
			out.append(tag + "'%s' is not an outdoor zone" % at)
			continue
		var outer: ZoneData = zones[at]
		var ways := 0
		for oid in zones:
			for w in (zones[oid] as ZoneData).warps:
				if str(w.get("to", "")) == zid:
					ways += 1
					var hid = w.get("hidden")
					if oid != at or int(w.x) != int(s.x) or int(w.y) != int(s.y) or not (hid is Dictionary) or str(hid.get("reveal", "")) != str(s.reveal):
						out.append(tag + "the way in must be the hidden warp at %d,%d in %s that reveals on %s" % [int(s.x), int(s.y), at, str(s.reveal)])
		if ways != 1:
			out.append(tag + "%d ways in, wanted exactly one" % ways)
		if room.warps.size() != 1 or str(room.warps[0].get("to", "")) != at:
			out.append(tag + "the room wants one way out, back to %s" % at)
		var wt := outer.tile_at(tile(s))
		if bool(s.get("coracle", false)) != (wt in ZoneData.RIDE_TILES):
			out.append(tag + "a coracle secret sits on water and any other on land (tile is %s)" % wt)
		if not settable.has(str(s.reveal)):
			out.append(tag + "nothing sets the reveal flag %s" % str(s.reveal))
		for k in ["name", "nation", "kind", "how", "reward"]:
			if str(s.get(k, "")) == "":
				out.append(tag + "needs a " + k)
		match str(s.get("reward", "")):
			"creature":
				if not dex.has(str(s.get("species", ""))):
					out.append(tag + "unknown creature '%s'" % str(s.get("species", "")))
			"chapbook", "curio":
				if not items.has(str(s.get("item", ""))):
					out.append(tag + "unknown item '%s'" % str(s.get("item", "")))
	return out
