class_name TradeOrders
extends RefCounted
## Delivery orders: now and then a Market Hall's stall-holder wants a few of something their region is short of (six
## Arbroath smokies for the Cardiff Central Market by Friday). An order is posted on a seeded in-game day, stays open
## for `open_days`, and pays what the hall's own board would pay for the goods plus a premium: a little for being a
## guaranteed buyer, more for arriving inside `fast_days` of the posting, more for arriving fresh, a little more again
## while a rail strike is on. The player hears of orders on the wireless, from a stall-holder at another hall and on
## the hall's own board; delivering needs no promise, only the goods, at the hall, in time.
## Bounds: at most `per_day` deliveries an in-game day, one fill per order, goods the corner shops stock are never
## asked for (so nothing can be bought low and delivered), and a delivery builds the glut in that town like any sale.
## The Trader's credit (level 4) lets a hall advance a quarter of an order's worth before you have the goods; an advance
## on an order that lapses is owed and comes off your next delivery, so credit is never free money.
## State, all plain flags that default empty: trade_filled {order id: day}, trade_advance {order id: pounds},
## trade_owed pounds, trade_done [day, deliveries]. Pure logic (no autoload names): the validator loads it.

const FILLED_FLAG := "trade_filled"
const ADVANCE_FLAG := "trade_advance"
const OWED_FLAG := "trade_owed"
const DONE_FLAG := "trade_done"
const DAYS := ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

static var _eligible: Dictionary = {}

## Forget the cached wants (tests that swap the item database call this).
static func reset_cache() -> void:
	_eligible = {}

static func cfg() -> Dictionary:
	var o = Trade.config().get("orders", {})
	return o if o is Dictionary else {}

static func _shop_stocked() -> Dictionary:
	var out := {}
	for sid in Trade.items().shops:
		for id in Trade.items().shops[sid].get("stock", []):
			out[str(id)] = true
	return out

## What a hall's region is short of and the corner shops do not sell: dishes the Ledger lists as wanted there, and a few
## British fish (the Midlands want fish). Sorted, so a seeded pick is stable.
static func eligible(hall_id: String) -> Array:
	if _eligible.has(hall_id):
		return _eligible[hall_id]
	var group := Trade.group_of(hall_id)
	var stocked := _shop_stocked()
	var kinds: Array = cfg().get("kinds", [])
	var out: Array = []
	var ids: Array = Trade.config().get("goods", {}).keys()
	ids.append_array(cfg().get("fish", []))
	for id in ids:
		var it := Trade.items().get_item(str(id))
		if it.is_empty() or str(it.get("kind", "")) not in kinds or Trade.base_price(str(id)) <= 0 or stocked.has(str(id)):
			continue
		if Trade.regional(str(id), group) > 1.0 and str(id) not in out:
			out.append(str(id))
	out.sort()
	_eligible[hall_id] = out
	return out

static func hall_ids() -> Array:
	var ids: Array = MarketHall.halls().keys()
	ids.sort()
	return ids

## The order a hall posts on a day, or {}: {id, hall, item, qty, posted, last} (`last` is the final day it may be filled).
static func posted(hall_id: String, day: int) -> Dictionary:
	var c := cfg()
	if day < 0 or absi(hash("order:%s:%d" % [hall_id, day])) % maxi(1, int(c.get("per_hall_chance", 4))) != 0:
		return {}
	var pool := eligible(hall_id)
	if pool.is_empty():
		return {}
	var span := int(c.get("max_qty", 6)) - int(c.get("min_qty", 2)) + 1
	return {"id": "%s|%d" % [hall_id, day], "hall": hall_id, "item": str(pool[absi(hash("oi:%s:%d" % [hall_id, day])) % pool.size()]),
		"qty": int(c.get("min_qty", 2)) + absi(hash("oq:%s:%d" % [hall_id, day])) % span, "posted": day, "last": day + int(c.get("open_days", 8)) - 1}

static func filled(data: GameStateData, id: String) -> bool:
	var f = data.flag(FILLED_FLAG)
	return f is Dictionary and f.has(id)

## Orders a hall has open on a day: posted in the last `open_days` and not yet filled. Newest first.
static func open_at(data: GameStateData, hall_id: String, day := -1) -> Array:
	if day < 0:
		day = data.day_count
	var out: Array = []
	for d in range(day, day - int(cfg().get("open_days", 8)), -1):
		var o := posted(hall_id, d)
		if not o.is_empty() and not filled(data, str(o.id)):
			out.append(o)
	return out

## Every open order in the Isles, newest first.
static func all_open(data: GameStateData, day := -1) -> Array:
	var out: Array = []
	for h in hall_ids():
		out.append_array(open_at(data, str(h), day))
	out.sort_custom(func(a, b): return int(a.posted) > int(b.posted) or (int(a.posted) == int(b.posted) and str(a.id) < str(b.id)))
	return out

static func town_of(o: Dictionary) -> String:
	return str(MarketHall.hall(str(o.hall)).get("town", o.hall))

static func item_name(o: Dictionary) -> String:
	return str(Trade.items().get_item(str(o.item)).get("name", o.item))

static func hall_name(o: Dictionary) -> String:
	return str(MarketHall.hall(str(o.hall)).get("name", o.hall))

static func weekday(day: int) -> String:
	return str(DAYS[posmod(day, 7)])

## "6 Arbroath smokies for The Barras by Friday".
static func describe(o: Dictionary) -> String:
	return "%d x %s for %s by %s" % [int(o.qty), item_name(o), hall_name(o), weekday(int(o.last))]

## The multiplier on the board price: the order's base, plus fast, fresh and strike extras. `fresh` is Trade.freshness.
static func premium(data: GameStateData, o: Dictionary, day := -1) -> float:
	if day < 0:
		day = data.day_count
	var c := cfg()
	var p := float(c.get("base", 1.1))
	if day - int(o.posted) < int(c.get("fast_days", 3)):
		p += float(c.get("fast", 0.15))
	if Trade.freshness(data, str(o.item)) >= 0.99:
		p += float(c.get("fresh", 0.1))
	if TradeNews.widening(data):
		p += float(c.get("strike", 0.15))
	return p

## What the hall would pay for the goods on the board, before the premium.
static func board_value(data: GameStateData, o: Dictionary) -> int:
	return Trade.sell_total(data, str(o.item), town_of(o), int(o.qty))

## What delivering would fetch in all (sterling), before any advance or debt comes off.
static func gross(data: GameStateData, o: Dictionary) -> int:
	return roundi(float(board_value(data, o)) * premium(data, o))

static func owed(data: GameStateData) -> int:
	return maxi(0, int(data.flag(OWED_FLAG) if data.flag(OWED_FLAG) != null else 0))

static func advance_of(data: GameStateData, id: String) -> int:
	var a = data.flag(ADVANCE_FLAG)
	return int(a.get(id, 0)) if a is Dictionary else 0

static func delivered_today(data: GameStateData) -> int:
	var d = data.flag(DONE_FLAG)
	return int(d[1]) if d is Array and d.size() == 2 and int(d[0]) == data.day_count else 0

## The reason an order cannot be filled right now, or "" when it can. `held` is how many of the item the bag has.
static func blocked(data: GameStateData, o: Dictionary, held: int, day := -1) -> String:
	if day < 0:
		day = data.day_count
	if filled(data, str(o.id)):
		return "Already seen to."
	if day > int(o.last):
		return "Too late: that one has gone elsewhere."
	if held < int(o.qty):
		return "You need %d, and you have %d." % [int(o.qty), held]
	if delivered_today(data) >= int(cfg().get("per_day", 3)):
		return "That is enough deliveries for one day. Come back tomorrow."
	return ""

## Turns advances on orders that lapsed unfilled into debt. Safe to call any time, as often as you like.
static func settle_lapsed(data: GameStateData) -> void:
	var a = data.flag(ADVANCE_FLAG)
	if not a is Dictionary or a.is_empty():
		return
	var open_days := int(cfg().get("open_days", 8))
	var debt := owed(data)
	for id in a.keys():
		var day := int(str(id).get_slice("|", 1))
		if data.day_count >= day + open_days and not filled(data, str(id)):
			debt += int(a[id])
			a.erase(id)
	data.set_flag(OWED_FLAG, debt)
	data.set_flag(ADVANCE_FLAG, a)

## True if a hall will advance money on this order: the Trader's credit, no debt, none already taken for it, and time left.
static func can_advance(data: GameStateData, o: Dictionary) -> bool:
	settle_lapsed(data)
	return Trades.has_perk(data, "trader_credit") and owed(data) == 0 and advance_of(data, str(o.id)) == 0 \
		and not filled(data, str(o.id)) and data.day_count <= int(o.last) and not (data.flag(ADVANCE_FLAG) is Dictionary and not data.flag(ADVANCE_FLAG).is_empty())

static func advance_amount(data: GameStateData, o: Dictionary) -> int:
	return int(float(board_value(data, o)) * float(cfg().get("advance", 0.25)))

## Takes the advance: returns the sterling to pay the player now (0 if it cannot be had).
static func take_advance(data: GameStateData, o: Dictionary) -> int:
	if not can_advance(data, o):
		return 0
	var amt := advance_amount(data, o)
	var a: Dictionary = data.flag(ADVANCE_FLAG) if data.flag(ADVANCE_FLAG) is Dictionary else {}
	a[str(o.id)] = amt
	data.set_flag(ADVANCE_FLAG, a)
	return amt

## Fills the order: records the sale (so the glut builds), counts the delivery and the pounds, forgets old fills and
## returns the sterling to pay the player NOW (the gross, less any advance already paid and any debt). The caller checks
## `blocked` first, takes the goods from the bag and pays the purse.
static func deliver(data: GameStateData, o: Dictionary) -> int:
	var total := gross(data, o)
	Trade.record_sale(data, str(o.item), town_of(o), int(o.qty))
	var f: Dictionary = data.flag(FILLED_FLAG) if data.flag(FILLED_FLAG) is Dictionary else {}
	for k in f.keys():   # an order older than its window can never come back, so forget it
		if data.day_count - int(str(k).get_slice("|", 1)) > 3 * int(cfg().get("open_days", 8)):
			f.erase(k)
	f[str(o.id)] = data.day_count
	data.set_flag(FILLED_FLAG, f)
	var done: int = delivered_today(data) + 1
	data.set_flag(DONE_FLAG, [data.day_count, done])
	var net := total - advance_of(data, str(o.id))
	var a = data.flag(ADVANCE_FLAG)
	if a is Dictionary and a.has(str(o.id)):
		a.erase(str(o.id))
		data.set_flag(ADVANCE_FLAG, a)
	settle_lapsed(data)
	var debt := mini(owed(data), maxi(0, net))
	if debt > 0:
		data.set_flag(OWED_FLAG, owed(data) - debt)
		net -= debt
	TrainerStats.sold(data, total)
	return net

# --- hearing about them ---

static func _hear(data: GameStateData, o: Dictionary) -> void:
	TradeNews.note_heard(data, "o:%s" % str(o.id))

static func heard(data: GameStateData, o: Dictionary) -> bool:
	return TradeNews.heard_key(data, "o:%s" % str(o.id))

## A hall's own board is seen by whoever stands in it.
static func see_hall(data: GameStateData, hall_id: String) -> Array:
	var open := open_at(data, hall_id)
	for o in open:
		_hear(data, o)
	return open

## Orders heard of that are still open, newest first.
static func heard_open(data: GameStateData) -> Array:
	return all_open(data).filter(func(o): return heard(data, o))

static func _pick_other(data: GameStateData, salt: String, skip_hall := "") -> Dictionary:
	var open := all_open(data).filter(func(o): return str(o.hall) != skip_hall)
	if open.is_empty():
		return {}
	return open[absi(hash("%s:%d" % [salt, data.day_count])) % open.size()]

## The wireless: a market that is after something. Up to n lines, noted as heard. [] when nobody is asking.
static func wireless_lines(data: GameStateData, n := 1) -> Array:
	var out: Array = []
	if n < 1:
		return out
	var o := _pick_other(data, "wire")
	if not o.is_empty():
		_hear(data, o)
		var asks: Array = cfg().get("asks", [""])
		out.append("%s is calling for %d %s, wanted by %s. %s" % [hall_name(o), int(o.qty), item_name(o), weekday(int(o.last)), str(asks[absi(hash("ask:%d" % data.day_count)) % asks.size()])])
	return out

## What a stall-holder says about another hall's order, or "". Noted as heard.
static func stall_line(data: GameStateData, hall_id: String) -> String:
	var o := _pick_other(data, "stall:" + hall_id, hall_id)
	if o.is_empty():
		return ""
	_hear(data, o)
	return "I hear %s want %d %s, and by %s." % [hall_name(o), int(o.qty), item_name(o), weekday(int(o.last))]

## Problems with the orders data (the validator calls this): halls with orders have something to ask for.
static func problems() -> Array:
	var errs := []
	var asked := 0
	for h in hall_ids():
		asked += eligible(str(h)).size()
	if asked == 0:
		errs.append("trade orders: no hall has anything to ask for")
	for id in cfg().get("fish", []):
		if Trade.items().get_item(str(id)).is_empty():
			errs.append("trade orders: %s is not an item" % id)
	for line in cfg().get("asks", []):
		if str(line).contains("—"):
			errs.append("trade orders: no em-dashes")
	return errs
