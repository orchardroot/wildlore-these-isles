class_name TrainerStats
extends RefCounted
## The trainer's lifetime tallies (the Stats page). They live in GameStateData.stats as a plain dictionary of
## counters plus a "started" date, so old saves just start at 0. Hooks elsewhere are one-liners calling in here.

const COUNTERS := ["steps", "wins_wild", "wins_trainer", "caught", "train_trips", "ferry_trips", "flights",
	"rail_miles", "money_earned", "teas", "rained_on", "fish_caught",
	"goods_sold", "dishes_cooked", "darts_won", "crabs_caught", "show_rosettes", "sheepdog_trials", "rows_rung", "walls_built", "games_won", "pulls_sung", "conkers_won",
	"bowls_ends_won", "skims_best", "lessons_taken", "words_reviewed", "say_it_right", "lang_certs", "arcade_toys", "fete_won"]
const TEA_ITEMS := ["cup_of_tea", "flask_of_tea", "cream_tea"]
const MILES_PER_MAP_UNIT := 0.45   # the world map is 1000 x 1300 for roughly 450 x 600 miles of Britain

## A brand new tally, with today as the day play began.
static func fresh() -> Dictionary:
	var out := {}
	for k in COUNTERS:
		out[k] = 0
	out["started"] = today()
	return out

static func today() -> String:
	var t := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [t.year, t.month, t.day]

## Turns whatever a save held into a complete, safe tally: unknown keys dropped, junk counters read as 0,
## a missing start date stamped with today (the first time an old save is loaded).
static func sanitise(raw) -> Dictionary:
	var out := fresh()
	if not (raw is Dictionary):
		return out
	for k in COUNTERS:
		var v = raw.get(k)
		if (v is int or v is float) and v > 0:
			out[k] = int(v)
	var s = raw.get("started")
	if s is String and s.length() == 10:
		out["started"] = s
	return out

static func get_count(data: GameStateData, key: String) -> int:
	return int(data.stats.get(key, 0))

static func add(data: GameStateData, key: String, n := 1) -> void:
	data.stats[key] = get_count(data, key) + n

## Goods sold to a shopkeeper, in pounds sterling (feeds the Trader trade; market halls call this too).
static func sold(data: GameStateData, amount: int) -> void:
	if amount > 0:
		add(data, "goods_sold", amount)

static func earned(data: GameStateData, amount: int) -> void:
	if amount > 0:
		add(data, "money_earned", amount)

## A battle finished: wild and trainer wins are kept apart (a keeper or Moot fight counts as a trainer's).
static func record_battle(data: GameStateData, kind: String, result: Dictionary) -> void:
	if str(result.get("result", "")) == "win":
		add(data, "wins_wild" if kind == "wild" else "wins_trainer")

static func note_item(data: GameStateData, item_id: String) -> void:
	if item_id in TEA_ITEMS:
		add(data, "teas")

## Straight-line miles between two towns on the world map (0 if either is unknown).
static func rail_miles(from_town: String, to_town: String) -> int:
	var towns: Dictionary = Travel.world_map().get("towns", {})
	if not towns.has(from_town) or not towns.has(to_town):
		return 0
	var a := Vector2(float(towns[from_town].x), float(towns[from_town].y))
	var b := Vector2(float(towns[to_town].x), float(towns[to_town].y))
	return roundi(a.distance_to(b) * MILES_PER_MAP_UNIT)

static func note_train(data: GameStateData, from_town: String, to_town: String) -> void:
	add(data, "train_trips")
	add(data, "rail_miles", rail_miles(from_town, to_town))

## Rows for the Stats page: [label, value text].
static func lines(data: GameStateData) -> Array:
	var c := func(k: String) -> int: return get_count(data, k)
	var out := [
		["Playing since", str(data.stats.get("started", "?"))],
		["Steps walked", _n(c.call("steps"))],
		["Wild battles won", _n(c.call("wins_wild"))],
		["Trainer battles won", _n(c.call("wins_trainer"))],
		["Creatures caught", _n(c.call("caught"))],
		["Train journeys", "%s (about %s miles)" % [_n(c.call("train_trips")), _n(c.call("rail_miles"))]],
		["Ferry crossings", _n(c.call("ferry_trips"))],
		["Flights on Bran's Raven", _n(c.call("flights"))],
		["Money earned", "£" + _n(c.call("money_earned"))],
		["Cups of tea drunk", _n(c.call("teas"))],
		["Times rained on", _n(c.call("rained_on"))],
		["Visitor's Book", _visitors_book(data)],
		["Land rewilded", "%d of %d sites Wild" % [Rewild.wild_count(data), Rewild.sites().size()]],
	]
	if c.call("darts_won") > 0:
		out.append(["Darts legs won", _n(c.call("darts_won"))])
	if c.call("crabs_caught") > 0:
		out.append(["Crabs caught and released", _n(c.call("crabs_caught"))])
	if c.call("rows_rung") > 0:
		out.append(["Bell rows rung in time", _n(c.call("rows_rung"))])
	if c.call("walls_built") > 0:
		out.append(["Drystone walls mended", _n(c.call("walls_built"))])
	if c.call("games_won") > 0:
		out.append(["Highland games, hurling and shinty won", _n(c.call("games_won"))])
	if c.call("pulls_sung") > 0:
		out.append(["Shanty pulls in time", _n(c.call("pulls_sung"))])
	if c.call("conkers_won") > 0:
		out.append(["Conker matches won", _n(c.call("conkers_won"))])
	if c.call("bowls_ends_won") > 0:
		out.append(["Bowls ends won", _n(c.call("bowls_ends_won"))])
	if c.call("skims_best") > 0:
		out.append(["Best stone skim", "%s skips" % _n(c.call("skims_best"))])
	if c.call("arcade_toys") > 0:
		out.append(["Arcade toys won", _n(c.call("arcade_toys"))])
	if c.call("lessons_taken") > 0:
		out.append(["Language lessons taken", "%s (%s certificate%s)" % [_n(c.call("lessons_taken")), _n(c.call("lang_certs")), "" if c.call("lang_certs") == 1 else "s"]])
		out.append(["Words reviewed", _n(c.call("words_reviewed"))])
	if c.call("say_it_right") > 0:
		out.append(["Said it right after a battle", _n(c.call("say_it_right"))])
	out.append_array(Tournament.stat_lines(data))  # County Shows and the Open Moot
	out.append_array(Punt.stat_lines(data))  # the Palace and the bookies, once you've had a flutter
	return out

## "20 rooms, 1 town complete": rooms walked into, and towns whose every room you've seen (see VisitorsBook).
static func _visitors_book(data: GameStateData) -> String:
	var rooms := VisitorsBook.rooms_seen(data)
	var towns := VisitorsBook.towns_complete(data)
	return "%s room%s, %s town%s complete" % [_n(rooms), "" if rooms == 1 else "s", _n(towns), "" if towns == 1 else "s"]

static func _n(v: int) -> String:
	var s := str(absi(v))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out

# --- event hooks (connected once, from the Game autoload, which passes itself in: autoload names
# can't be used here, or every tool script that loads the save data fails to compile) --------------

static var _kind := "wild"

static func connect_bus(game: Node) -> void:
	var bus := game.get_node("/root/Bus")
	bus.battle_started.connect(func(kind: String): _kind = kind)
	bus.battle_ended.connect(func(result: Dictionary): record_battle(game.data, _kind, result))
	bus.creature_caught.connect(func(_id: String): add(game.data, "caught"))
	bus.zone_entered.connect(func(_zone_id: String): _on_zone_entered(game))
	bus.zone_entered.connect(func(_zone_id: String): Trades.refresh(game.data))

## Walking into an outdoor zone while it rains (drizzle or downpour) counts as being rained on.
static func _on_zone_entered(game: Node) -> void:
	var ow = game.get_node("/root/Router").overworld
	if ow == null or not is_instance_valid(ow) or ow.zone == null or ow.zone.kind == "interior":
		return
	if rains(str(ow.weather)):
		add(game.data, "rained_on")

static func rains(weather: String) -> bool:
	return weather in ["drizzle", "downpour"]
