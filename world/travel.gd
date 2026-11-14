class_name Travel
extends RefCounted
## Rail fast travel, ferries and the world map data. A town's station counts as visited once you've been
## in that town; trains run between visited stations (with a Rail Pass). Ferries run both ways on their route.

const MAP_PATH := "res://data/world_map.json"
const FERRIES_PATH := "res://data/ferries.json"

static var _map: Dictionary = {}
static var _ferries: Dictionary = {}

static func world_map() -> Dictionary:
	if _map.is_empty():
		var m = JsonUtil.read(MAP_PATH)
		_map = m if m is Dictionary else {}
	return _map

static func ferries() -> Dictionary:
	if _ferries.is_empty():
		var f = JsonUtil.read(FERRIES_PATH)
		_ferries = f if f is Dictionary else {}
	return _ferries

static func station_flag(town: String) -> String:
	return "station_" + town

static func town_name(town: String) -> String:
	if Overseas.name_of(town) != "":
		return Overseas.name_of(town)
	return str(world_map().get("towns", {}).get(town, {}).get("name", town.capitalize()))

## Call on entering any zone: records a first visit (the Discovery tally and its small reward, before the town's own
## visited flag so an old save's towns are caught up first), marks the town visited (world map), its station (rail)
## and the last town.
static func note_visit(data: GameStateData, zone: ZoneData) -> void:
	Discovery.note(data, zone, ZoneIndex.get_index())
	if zone.town_id == "":
		return
	data.set_flag("visited_" + zone.town_id)
	data.set_flag("last_town", zone.town_id)
	if zone.station != Vector2i(-1, -1):
		data.set_flag(station_flag(zone.town_id))

## "gb", "ireland" or "man": trains never cross the sea.
static func island_of(town: String) -> String:
	return str(world_map().get("towns", {}).get(town, {}).get("island", "gb"))

## Towns you can take the train to from `here` (same island only), in the world map's town order.
static func rail_destinations(data: GameStateData, here: String) -> Array:
	var out := []
	var isle := island_of(here)
	for town in world_map().get("towns", {}):
		if town != here and island_of(town) == isle and data.flag(station_flag(town)) and FileAccess.file_exists("res://data/zones/%s.json" % town):
			out.append(town)
	return out

## What the station or the Raven says when there's nowhere to go. Stations on another island get a ferry mention.
static func rail_empty_text(data: GameStateData, here: String, flying: bool) -> String:
	if flying:
		return "No other towns visited yet. Bran's Raven only flies where you've been."
	var isle := island_of(here)
	for town in world_map().get("towns", {}):
		if town != here and island_of(town) != isle and data.flag(station_flag(town)):
			return "Trains don't do the sea. Nowhere else on this island yet; the other stations you know need a ferry."
	return "No other stations visited yet. Trains only go where you've been."

static func rail_arrival(town: String) -> Dictionary:
	var z := ZoneData.load_id(town)
	return {"zone": town, "pos": z.station if z.station != Vector2i(-1, -1) else Vector2i(-1, -1)}

## Where a ferry on `route` leaving from `from_town` lands: the other end's quay tile.
static func ferry_arrival(route: String, from_town: String) -> Dictionary:
	var r: Dictionary = ferries().get(route, {})
	if r.is_empty():
		return {}
	var to: String = r.b if str(r.a) == from_town else r.a
	var z := ZoneData.load_id(to)
	return {"zone": to, "pos": Vector2i(int(z.ferry.get("x", -1)), int(z.ferry.get("y", -1)))}

## Flight (after the Moot): any visited town on any island, except where you are.
static func fly_destinations(data: GameStateData, here: String) -> Array:
	var out := []
	for town in world_map().get("towns", {}):
		if town != here and data.flag("visited_" + town) == true and FileAccess.file_exists("res://data/zones/%s.json" % town):
			out.append(town)
	return out

## Where a flight lands: the station platform if the town has one, else the town's spawn.
static func fly_arrival(town: String) -> Dictionary:
	var z := ZoneData.load_id(town)
	return {"zone": town, "pos": z.station if z.station != Vector2i(-1, -1) else z.spawn}
