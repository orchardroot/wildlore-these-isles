class_name TradeLedger
extends RefCounted
## The Trader's Ledger: a page in the Almanac that holds only what the player has seen or been told. What each good last
## sold for and where (noted whenever a hall's board is read or a stack is sold), the widest gap between two towns you
## have seen, the news and orders you have heard of that still matter, what is in season, and what in your bag is about
## to go off. There is no all-seeing price list: a price you have not seen is not here, and one you saw a week ago is
## shown as a week old. State is one flag dictionary that defaults empty, so old saves are fine:
##   trade_seen  {"item|town": [sell price, buy price, day seen]}   (sterling, kept to `KEEP` entries)
## Pure logic (no autoload names): the validator loads it.

const SEEN_FLAG := "trade_seen"
const KEEP := 60
const SHOW := 6   # last-seen prices on the page

static func _seen(data: GameStateData) -> Dictionary:
	var s = data.flag(SEEN_FLAG)
	return s if s is Dictionary else {}

## Notes a price seen: what the stall pays and what you would pay, in a town, today.
static func note(data: GameStateData, item_id: String, town: String, sell: int, buy: int) -> void:
	if sell <= 0:
		return
	var s: Dictionary = _seen(data)
	s["%s|%s" % [item_id, town]] = [sell, buy, data.day_count]
	while s.size() > KEEP:   # forget the stalest
		var oldest := ""
		for k in s:
			if oldest == "" or int(s[k][2]) < int(s[oldest][2]):
				oldest = str(k)
		s.erase(oldest)
	data.set_flag(SEEN_FLAG, s)

## Notes a whole board (MarketHall.board rows) at a hall's town.
static func note_board(data: GameStateData, hall_id: String, rows: Array) -> void:
	var town := str(MarketHall.hall(hall_id).get("town", hall_id))
	for r in rows:
		note(data, str(r.id), town, int(r.sell), int(r.buy))

static func count(data: GameStateData) -> int:
	return _seen(data).size()

## Whether the page has anything to say: a price seen, a thing heard, or goods sold before this existed.
static func visible(data: GameStateData) -> bool:
	return count(data) > 0 or not TradeNews.heard_now(data).is_empty() or TrainerStats.get_count(data, "goods_sold") > 0

static func _name(item_id: String) -> String:
	return str(Trade.items().get_item(item_id).get("name", item_id))

static func _town(town: String) -> String:
	return Travel.town_name(town)

static func _ago(data: GameStateData, day: int) -> String:
	var n := data.day_count - day
	return "today" if n <= 0 else ("yesterday" if n == 1 else "%d days ago" % n)

## Prices seen, newest first: [{item, town, sell, buy, day}].
static func recent(data: GameStateData) -> Array:
	var out: Array = []
	var s := _seen(data)
	for k in s:
		var e: Array = s[k]
		out.append({"item": str(k).get_slice("|", 0), "town": str(k).get_slice("|", 1), "sell": int(e[0]), "buy": int(e[1]), "day": int(e[2])})
	out.sort_custom(func(a, b): return int(a.day) > int(b.day) or (int(a.day) == int(b.day) and str(a.item) + str(a.town) < str(b.item) + str(b.town)))
	return out

## The widest gap between where a good fetched most and least among the towns you have seen it in, or {}.
## {item, high_town, high, low_town, low, gap, day} (`day` is the older of the two sightings).
static func best_spread(data: GameStateData) -> Dictionary:
	var by_item := {}
	for r in recent(data):
		if not by_item.has(r.item):
			by_item[r.item] = []
		by_item[r.item].append(r)
	var best := {}
	var ids: Array = by_item.keys()
	ids.sort()
	for id in ids:
		var rows: Array = by_item[id]
		if rows.size() < 2:
			continue
		var hi: Dictionary = rows[0]
		var lo: Dictionary = rows[0]
		for r in rows:
			if int(r.sell) > int(hi.sell):
				hi = r
			if int(r.sell) < int(lo.sell):
				lo = r
		var gap := int(hi.sell) - int(lo.sell)
		if gap > 0 and (best.is_empty() or gap > int(best.gap)):
			best = {"item": id, "high_town": hi.town, "high": int(hi.sell), "low_town": lo.town, "low": int(lo.sell), "gap": gap, "day": mini(int(hi.day), int(lo.day))}
	return best

## What is wanted at this time of year (the Ledger's seasonal list): [[note, item names]].
static func in_season() -> Array:
	var t := Calendar.today()
	var season := Calendar.season_for(t.x, t.y)
	var out: Array = []
	for s in Trade.config().get("seasonal", []):
		if str(s.season) != season:
			continue
		var names: Array = []
		for id in s.get("items", []):
			names.append(_name(str(id)))
		for k in s.get("kinds", []):
			names.append("all " + str(k))
		out.append([str(s.get("note", "")).capitalize(), ", ".join(names)])
	return out

## Perishables in the bag with the days they have left: [{item, n, left}] soonest first. `left` is 0 once a bit off.
static func going_off(data: GameStateData) -> Array:
	var out: Array = []
	var stamps = data.flag(Trade.FRESH_FLAG)
	for id in data.bag:
		var n := int(data.bag[id])
		var keeps := Trade.keeps_days(str(id))
		if n <= 0 or keeps <= 0:
			continue
		var age := 0
		if stamps is Dictionary and stamps.has(id):
			age = data.day_count - int(stamps[id])
		out.append({"item": str(id), "n": n, "left": maxi(0, keeps - age), "keeps": keeps})
	out.sort_custom(func(a, b): return int(a.left) < int(b.left) or (int(a.left) == int(b.left) and str(a.item) < str(b.item)))
	return out

static func _event_where(e: Dictionary) -> String:
	var names: Array = []
	for t in e.get("towns", []):
		names.append(_town(str(t)))
	for g in e.get("groups", []):
		names.append(Trade.group_name(str(g)))
	if names.is_empty():
		return "everywhere"
	if names.size() > 2:
		return "%s and %d more" % [names[0], names.size() - 1]
	return " and ".join(names)

static func _event_what(e: Dictionary) -> String:
	var names: Array = []
	for id in e.get("items", []):
		names.append(_name(str(id)).to_lower())
	for k in e.get("kinds", []):
		names.append(str(k) + (" dishes" if str(k) == "meal" else ""))
	var s := " and ".join(names)
	if names.size() > 2:
		s = ", ".join(names.slice(0, 2)) + " and more"
	match str(e.kind):
		"glut":
			return "%s cheap" % s
		"widen":
			return "price gaps wider"
	return "%s dear" % s

## The page's rows [label, value], never empty. Section headings have an empty value.
static func rows(data: GameStateData) -> Array:
	var out: Array = []
	var day := data.day_count
	var news := TradeNews.heard_now(data)
	out.append(["The news", ""])
	if news.is_empty():
		out.append(["Nothing heard", "Listen to the wireless, or ask at a stall"])
	for e in news:
		var when := ("now, %d day%s left" % [TradeNews.ends(e) - day, "" if TradeNews.ends(e) - day == 1 else "s"]) if bool(e.on) else ("from tomorrow" if int(e.start) - day == 1 else "in %d days" % (int(e.start) - day))
		out.append([str(e.board), "%s: %s, %s" % [_event_where(e), _event_what(e), when]])
	var orders := TradeOrders.heard_open(data)
	out.append(["Orders", ""])
	if orders.is_empty():
		out.append(["None heard of", "Stall-holders talk, and so does the wireless"])
	for o in orders:
		out.append([TradeOrders.hall_name(o), "%d x %s by %s, about %s" % [int(o.qty), TradeOrders.item_name(o), TradeOrders.weekday(int(o.last)), Wallet.fmt(TradeOrders.gross(data, o))]])
	var owed := TradeOrders.owed(data)
	if owed > 0:
		out.append(["You owe the halls", Wallet.fmt(owed) + ", off your next delivery"])
	var seen := recent(data)
	out.append(["Last seen at the stalls", ""])
	if seen.is_empty():
		out.append(["Nothing noted yet", "Read a hall's board and it will be here"])
	for r in seen.slice(0, SHOW):
		out.append([_name(str(r.item)), "%s at %s, %s" % [Wallet.fmt(int(r.sell)), _town(str(r.town)), _ago(data, int(r.day))]])
	var sp := best_spread(data)
	if not sp.is_empty():
		out.append(["Widest gap: %s" % _name(str(sp.item)), "%s at %s, %s at %s, %s" % [Wallet.fmt(int(sp.high)), _town(str(sp.high_town)), Wallet.fmt(int(sp.low)), _town(str(sp.low_town)), _ago(data, int(sp.day))]])
	out.append(["In season", ""])
	var season := in_season()
	if season.is_empty():
		out.append(["Nothing special", "A steady time of year"])
	for r in season:
		out.append(r)
	out.append(["About to go off", ""])
	var off := going_off(data)
	if off.is_empty():
		out.append(["Nothing in your bag", "that will not keep"])
	for r in off.slice(0, 5):
		out.append(["%s x%d" % [_name(str(r.item)), int(r.n)], "a bit off" if int(r.left) <= 0 else ("%d day%s left" % [int(r.left), "" if int(r.left) == 1 else "s"])])
	return out

static func blurb(data: GameStateData) -> String:
	var n := count(data)
	var news := TradeNews.heard_now(data).size()
	return "%d price%s noted, %d bit%s of news" % [n, "" if n == 1 else "s", news, "" if news == 1 else "s"]
