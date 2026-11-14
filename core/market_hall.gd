class_name MarketHall
extends RefCounted
## The Market Halls: 25 real covered markets where a stall-holder buys your trade goods at the Trade Ledger's price.
## data/market_halls.json: {halls: {<hall zone id>: {name, town, trader}}}. Pure logic (no autoload names): the
## screen (ui/market_hall_screen.gd) and the tests drive it. Nothing is saved here; selling is just the purse and bag.

const PATH := "res://data/market_halls.json"
## What a stall-holder will take: produce, dishes and fish. Kit, charms and key items stay in your pocket.
const GOODS_KINDS := ["material", "meal", "fish", "produce"]

const PITCH_FLAG := "trade_pitch"   # {hall id: [day, units sold on the pitch]}: the Trader 5's market-day pitch

static var _db: Dictionary = {}

static func halls() -> Dictionary:
	if _db.is_empty():
		var d = JsonUtil.read(PATH)
		_db = d.get("halls", {}) if d is Dictionary else {}
	return _db

static func hall(id: String) -> Dictionary:
	return halls().get(id, {})

## True for an item a stall-holder trades in.
static func is_trade_good(item: Dictionary) -> bool:
	return str(item.get("kind", "")) in GOODS_KINDS and int(item.get("price", 0)) > 0

## The price board for what you carry: [{id, name, n, buy, sell, note}] in item-id order. `store` is the bag's
## {id: count}; `lookup` maps an id to its item dictionary (ItemDB.get_item). Prices are sterling, from Trade.
static func board(data: GameStateData, store: Dictionary, lookup: Callable, hall_id: String) -> Array:
	var town := str(hall(hall_id).get("town", hall_id))
	var out := []
	var ids := store.keys()
	ids.sort()
	for id in ids:
		var n := int(store[id])
		var it: Dictionary = lookup.call(id)
		if n <= 0 or it.is_empty() or not is_trade_good(it):
			continue
		out.append({"id": id, "name": str(it.get("name", id)), "n": n, "buy": Trade.buy_price(data, id, town),
			"sell": Trade.sell_price(data, id, town), "note": Trade.price_note(data, id, town)})
	return out

## Market day is the Saturday of the in-game week (the Money Box's Monday is day 0 of the seven).
static func market_day(data: GameStateData) -> bool:
	return data.day_count % 7 == int(TradeOrders.cfg().get("market_day", 5))

## How many units the Trader's pitch still covers at this hall today: 0 unless the Trader is level 5 and it is market day.
static func pitch_left(data: GameStateData, hall_id: String) -> int:
	if not Trades.has_perk(data, "trader_pitch") or not market_day(data):
		return 0
	var used := 0
	var p = data.flag(PITCH_FLAG)
	if p is Dictionary and p.has(hall_id) and int(p[hall_id][0]) == data.day_count:
		used = int(p[hall_id][1])
	return maxi(0, int(TradeOrders.cfg().get("pitch_units", 12)) - used)

## What a stall-holder pays for a stack, in sterling: each unit sold makes the next poorer (Trade.sell_total), as at a shop.
## The first units on a Trader's market-day pitch go at the glut-free price.
static func payout(data: GameStateData, hall_id: String, item_id: String, qty: int) -> int:
	return Trade.sell_total(data, item_id, str(hall(hall_id).get("town", hall_id)), maxi(0, qty), mini(maxi(0, qty), pitch_left(data, hall_id)))

## The payout for a stack, with the sale noted so the glut builds in that town (and fades over in-game days). The caller
## takes the stack from the bag and pays the purse. Without this the halls were a tap: every unit at the top price.
## Units sold on the pitch use it up for the day and build no glut.
static func settle(data: GameStateData, hall_id: String, item_id: String, qty: int) -> int:
	var total := payout(data, hall_id, item_id, qty)
	var free := mini(maxi(0, qty), pitch_left(data, hall_id))
	Trade.record_sale(data, item_id, str(hall(hall_id).get("town", hall_id)), qty - free)
	if free > 0:
		var p: Dictionary = data.flag(PITCH_FLAG) if data.flag(PITCH_FLAG) is Dictionary else {}
		for k in p.keys():   # only today's pitches are worth keeping
			if int(p[k][0]) != data.day_count:
				p.erase(k)
		p[hall_id] = [data.day_count, int(TradeOrders.cfg().get("pitch_units", 12)) - pitch_left(data, hall_id) + free]
		data.set_flag(PITCH_FLAG, p)
	return total

## What the stall-holder says as you walk up: the news in their own words, else word of an order at another hall, else "".
static func talk(data: GameStateData, hall_id: String) -> String:
	var line := TradeNews.stall_line(data, hall_id)
	return line if line != "" else TradeOrders.stall_line(data, hall_id)

## problems() for the files on disk: only the halls' rooms and towns are read.
static func check_files() -> Array:
	var zones := {}
	var dialogue := {}
	for id in halls():
		for zid in [id, str(halls()[id].get("town", ""))]:
			if zid != "" and not zones.has(zid):
				var z = JsonUtil.read("res://data/zones/%s.json" % zid)
				if z is Dictionary:
					zones[zid] = z
		var d = JsonUtil.read("res://data/dialogue/%s.json" % id)
		dialogue[id] = d if d is Dictionary else {}
	return problems(zones, dialogue)

## Problems with the hall data: each hall has a town and a name, its room exists, the room has a stall-holder who
## runs the `market` command for it and one plaque. `zones` is {id: raw zone dictionary}; `dialogue` {zone: {script: [...]}}.
static func problems(zones: Dictionary, dialogue: Dictionary) -> Array:
	var errs := []
	for id in halls():
		var h: Dictionary = halls()[id]
		if str(h.get("name", "")) == "" or not zones.has(str(h.get("town", ""))):
			errs.append("market hall %s: needs a name and a real town" % id)
		if not zones.has(id):
			errs.append("market hall %s: no such room" % id)
			continue
		var z: Dictionary = zones[id]
		var runs := false
		for n in z.get("npcs", []):
			var sc = dialogue.get(id, {}).get(str(n.get("script", "")), [])
			if JSON.stringify(sc).contains("\"market\"") and JSON.stringify(sc).contains("\"" + id + "\""):
				runs = true
		if not runs:
			errs.append("market hall %s: no stall-holder runs the market command" % id)
		var plaques := 0
		for s in z.get("signs", []):
			if s is Dictionary and str(s.get("plaque", "")) != "":
				plaques += 1
		if plaques < 1:
			errs.append("market hall %s: no fact plaque" % id)
	if halls().size() != 25:
		errs.append("expected 25 market halls, found %d" % halls().size())
	return errs
