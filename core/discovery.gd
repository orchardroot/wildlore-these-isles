class_name Discovery
extends RefCounted
## Off the beaten track (5.4): finding a place is a moment. The first time you set foot in any outdoor zone, or in a
## Deep Place, it is recorded (flag found_<zone>), counted in the places-found tally, and pays the whole party a little
## (a touch of friendship and a few training points, the same growth the standing stones give). Towns you had already
## visited before the tally existed count as found without the reward, and a save well under way is caught up the first
## time it is asked (see catch_up), so nobody is paid twice for a road they have walked. Absent flag = not found.
## `nearby_unfound` is the list the creature's "sense cue" reads (world/sense_cue.gd): points of interest and field
## spots close by that you have not dealt with yet; phase 2 adds flotsam and secrets to it.
## Pure: no autoload names (the validator loads it).

const FOUND := "found_"
const INIT := "disc_init"
const SENSED := "sensed_"
const VETERAN_SECONDS := 1800.0   # the Intros rule: half an hour in, you have walked a fair few roads already
const FRIENDSHIP := 2             # a new place is a small treat for the whole party
const SENSE_RANGE := 5            # tiles: how close the creature gets to notice something

## The card for the zone just entered, waiting for the zone card to show it: {zone: {name, count, total, gain}}.
static var _pending: Dictionary = {}

static func found_key(zone_id: String) -> String:
	return FOUND + zone_id

## Outdoor zones and Deep Places can be found. Rooms are the Visitor's Book's business.
static func findable(kind: String, deep: bool) -> bool:
	return kind != "interior" or deep

static func is_found(d: GameStateData, zone_id: String) -> bool:
	return d.flag(found_key(zone_id)) == true

## Every place that can be found: [zone ids], outdoor zones and Deep Places, in the index's order.
static func places(idx: Dictionary) -> Array:
	var out := []
	for id in idx.get("zones", {}):
		var z: Dictionary = idx.zones[id]
		if findable(str(z.kind), bool(z.get("deep", false))):
			out.append(id)
	return out

## Places found, and places in all.
static func tally(d: GameStateData, idx: Dictionary) -> Vector2i:
	catch_up(d, idx)
	var all := places(idx)
	return Vector2i(all.filter(func(id): return is_found(d, str(id))).size(), all.size())

## Marks as found, without a reward, every place an older save has plainly been to: towns with a visited flag,
## Deep Places whose room or puzzle flags are set, and (for a save past the first half hour) any route that links
## two found places, which you must have walked to get from one to the other. Runs once per save, the first time
## the tally or a zone entry asks. A new game has nothing to catch up on, so this is free for it.
static func catch_up(d: GameStateData, idx: Dictionary) -> void:
	if d.flag(INIT) == true:
		return
	d.set_flag(INIT, true)
	var zones: Dictionary = idx.get("zones", {})
	var dp_flags := []
	for k in d.flags:
		if str(k).begins_with("dp_"):
			dp_flags.append(str(k))
	for id in zones:
		var z: Dictionary = zones[id]
		var deep := bool(z.get("deep", false))
		if not findable(str(z.kind), deep):
			continue
		var town := str(z.get("town", ""))
		if town != "" and d.flag("visited_" + town) == true:
			d.set_flag(found_key(str(id)), true)
		elif deep and (d.flag(VisitorsBook.seen_flag(str(id))) == true or dp_flags.any(func(k): return k.begins_with("dp_" + str(id) + "_"))):
			d.set_flag(found_key(str(id)), true)
	if d.play_seconds <= VETERAN_SECONDS:
		return
	var changed := true
	while changed:
		changed = false
		for id in zones:
			var z: Dictionary = zones[id]
			if str(z.kind) == "interior" or is_found(d, str(id)):
				continue
			var known := 0
			for to in z.get("links", []):
				if is_found(d, str(to)):
					known += 1
			if known >= 2:
				d.set_flag(found_key(str(id)), true)
				changed = true

## Call on entering a zone, before the town's visited flag is set. Records a first visit and pays for it; returns
## {zone, name, count, total, gain} for the card (gain is the line about the party), or {} when nothing is new.
static func note(d: GameStateData, zone: ZoneData, idx: Dictionary) -> Dictionary:
	if zone == null:
		return {}
	var deep: bool = not zone.deep.is_empty() or bool(idx.get("zones", {}).get(zone.id, {}).get("deep", false))
	if not findable(zone.kind, deep):
		return {}
	catch_up(d, idx)
	if is_found(d, zone.id):
		return {}
	d.set_flag(found_key(zone.id), true)
	var gain := reward(d, zone.id)
	var t := tally(d, idx)
	var out := {"zone": zone.id, "name": zone.name, "count": t.x, "total": t.y, "gain": gain}
	_pending[zone.id] = out
	return out

## The card waiting for `zone_id`, once ({} if none).
static func take(zone_id: String) -> Dictionary:
	var out: Dictionary = _pending.get(zone_id, {})
	_pending.erase(zone_id)
	return out

## What a new place gives each creature in the party: a little friendship and a few points in one stat, picked by
## the place so a long walk spreads them about. Returns the line for the card ("" when the party is empty).
static func reward(d: GameStateData, zone_id: String) -> String:
	var n := 0
	var stat: String = Rules.STATS[absi(hash(zone_id)) % Rules.STATS.size()]
	for c in d.party:
		c.friendship = mini(255, c.friendship + FRIENDSHIP)
		Poi.train(c, stat)
		n += 1
	if n == 0:
		return ""
	return "Your team is chuffed to be somewhere new." if n > 1 else "%s is chuffed to be somewhere new." % _name_of(d.party[0])

static func _name_of(c: Creature) -> String:
	return c.nickname if c.nickname != "" else str(c.species.get("name", "Your creature"))

# --- the map ------------------------------------------------------------------------

## The map's marks for Deep Places: once a place that has a way into a cave system is found, the cave mouth is
## ringed ("deep", at the cave's entry zone), and ticked once you have been in. One mark per system.
static func deep_marks(d: GameStateData, idx: Dictionary) -> Array:
	var out := []
	var zones: Dictionary = idx.get("zones", {})
	for id in zones:
		var z: Dictionary = zones[id]
		if bool(z.get("deep", false)) or str(z.kind) == "interior":
			continue
		if not is_found(d, str(id)):
			continue
		for to in z.get("links", []):
			if bool(zones.get(to, {}).get("deep", false)) and not out.any(func(m): return m.at == to):
				out.append({"kind": "deep", "at": str(to), "done": is_found(d, str(to)), "ring": true})
	return out

# --- the sense cue ------------------------------------------------------------------

static func sensed_key(id: String) -> String:
	return SENSED + id

## [{kind ("poi" or "field"), id, at (Vector2i)}] points of interest and field spots within SENSE_RANGE tiles (the
## way the rest of the game measures, a square) of `pos` that are not dealt with yet and have not been sensed
## before: once per find. Nothing in towns. `poi_tile` turns a poi's authored spot into the tile it stands on
## (the zone's landing_near); without one the authored `near` is used.
static func nearby_unfound(zone: ZoneData, pos: Vector2i, d: GameStateData, poi_tile := Callable()) -> Array:
	var out := []
	if zone == null or zone.kind != "route":
		return out
	for p in Poi.for_zone(zone.id):
		if Poi.done(d, p) or d.flag(sensed_key(str(p.id))) == true:
			continue
		var at: Vector2i = poi_tile.call(p) if poi_tile.is_valid() else Vector2i(int(p.near[0]), int(p.near[1]))
		if maxi(absi(pos.x - at.x), absi(pos.y - at.y)) <= SENSE_RANGE:
			out.append({"kind": "poi", "id": str(p.id), "at": at})
	for s in FieldSpots.for_zone(zone.id):
		if FieldSpots.done(d, s) or d.flag(sensed_key(str(s.id))) == true:
			continue
		var at := FieldSpots.tile(s)
		if maxi(absi(pos.x - at.x), absi(pos.y - at.y)) <= SENSE_RANGE:
			out.append({"kind": "field", "id": str(s.id), "at": at})
	return out
