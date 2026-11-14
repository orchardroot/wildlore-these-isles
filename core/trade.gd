class_name Trade
extends RefCounted
## The Trade Ledger: prices that depend on where you are and when. An item's base "price" (data/items) times a
## regional factor (data/trade.json: cheap where it is made, dear far away), plus, on the selling side, seasonal and
## festival demand, a glut that builds as you sell in one town and fades over in-game days, and freshness for
## perishables. Anything not listed in trade.json sits at its base price, so every item has a price.
## All prices are STERLING whole pounds, as items are authored; Wallet converts to the local currency.
## buy_price is the regional factor only, so it never moves with the date; sell_price starts at half the base (the
## corner shop's rate) and demand is capped below the buy-side spread, so buying and selling in one place never pays.
## Callers that sell a stack should quote it with sell_total and then call record_sale; callers that hand over a
## perishable should call stamp. State is two small flag dictionaries that default empty, so old saves are fine:
##   trade_glut  {"town|item": [units, day]}   trade_fresh  {item: average day acquired}
## Pure logic (no autoload names): the validator loads it.

const PATH := "res://data/trade.json"
const GLUT_FLAG := "trade_glut"
const FRESH_FLAG := "trade_fresh"

static var _cfg: Dictionary = {}
static var _items: ItemDB = null
static var _group_of_region: Dictionary = {}

static func config() -> Dictionary:
	if _cfg.is_empty():
		var raw: Variant = JsonUtil.read(PATH)
		_cfg = raw if raw is Dictionary else {}
		_group_of_region = {}
		for g in _cfg.get("groups", {}):
			for r in _cfg.groups[g]:
				_group_of_region[str(r)] = str(g)
	return _cfg

static func items() -> ItemDB:
	if _items == null:
		_items = ItemDB.load_default()
	return _items

## Tests (and anything with its own item set) can swap the item database; null goes back to the real one.
static func set_items(db: ItemDB) -> void:
	_items = db

static func base_price(item_id: String) -> int:
	return maxi(0, int(items().get_item(item_id).get("price", 0)))

static func is_trade_good(item_id: String) -> bool:
	var it := items().get_item(item_id)
	return not it.is_empty() and str(it.get("kind", "")) in config().get("trade_kinds", [])

## The trade region ("wales", "scotland", ..., "overseas") of a zone or room; "" when it has none (dev rooms).
static func group_of(zone_id: String) -> String:
	config()
	var zi: Dictionary = ZoneIndex.get_index()
	var region := str(zi.zones.get(zone_id, {}).get("region", ""))
	if region == "":
		region = zone_id
	if region.begins_with("overseas") or region.begins_with("abroad_"):
		return "overseas"
	return str(_group_of_region.get(region, ""))

static func town_of(zone_id: String) -> String:
	return str(ZoneIndex.get_index().room_town.get(zone_id, zone_id))

static func group_name(group: String) -> String:
	return str(config().get("names", {}).get(group, group))

## Cheap (home factor), dear (wants factor) or 1.0 for this item in this trade region.
static func regional(item_id: String, group: String) -> float:
	var c := config()
	var rule: Dictionary = c.get("goods", {}).get(item_id, {})
	if rule.is_empty():
		rule = c.get("kinds", {}).get(str(items().get_item(item_id).get("kind", "")), {})
	if group in rule.get("home", []):
		return float(c.get("home_factor", 0.6))
	if group in rule.get("wants", []):
		return float(c.get("wants_factor", 1.8))
	return 1.0

## Seasonal and festival demand for selling here today, from 1.0 up to the cap. The season and the national days
## come from Calendar (the player's own date); a festival event (data/festivals.json) pays in its own town.
static func demand(item_id: String, zone_id: String) -> float:
	var c := config()
	var kind := str(items().get_item(item_id).get("kind", ""))
	var t := Calendar.today()
	var season := Calendar.season_for(t.x, t.y)
	var f := 1.0
	for s in c.get("seasonal", []):
		if str(s.season) == season and (item_id in s.get("items", []) or kind in s.get("kinds", [])):
			f = maxf(f, float(s.factor))
	var region := str(ZoneIndex.get_index().zones.get(zone_id, {}).get("region", zone_id))
	var fest := Calendar.festival_for(t.x, t.y)
	var town := town_of(zone_id)
	for s in c.get("festivals", []):
		if item_id not in s.get("items", []):
			continue
		if s.has("festival") and str(s.festival) == fest and Calendar.festival_here(fest, region):
			f = maxf(f, float(s.factor))
		elif s.has("event"):
			var e := Festivals.get_event(str(s.event))
			if not e.is_empty() and str(e.town) == town and Festivals.is_active(e):
				f = maxf(f, float(s.factor))
	return clampf(f, 1.0, float(c.get("demand_cap", 1.8)))

static func _glut_units(data: GameStateData, key: String) -> float:
	var g = data.flag(GLUT_FLAG)
	if not g is Dictionary or not g.has(key):
		return 0.0
	var e: Array = g[key]
	var span := float(config().get("glut_days", 3))
	return float(e[0]) * maxf(0.0, 1.0 - float(data.day_count - int(e[1])) / span)

static func glut_factor(data: GameStateData, item_id: String, zone_id: String) -> float:
	return pow(float(config().get("glut_step", 0.92)), _glut_units(data, "%s|%s" % [town_of(zone_id), item_id]))

## Notes `n` units of an item sold in a town: each makes the next sale a little poorer there until it fades.
static func record_sale(data: GameStateData, item_id: String, zone_id: String, n: int) -> void:
	if n < 1:
		return
	var key := "%s|%s" % [town_of(zone_id), item_id]
	var g: Dictionary = data.flag(GLUT_FLAG) if data.flag(GLUT_FLAG) is Dictionary else {}
	for k in g.keys():  # forget what has fully faded, so the dictionary stays small
		if k != key and _glut_units(data, k) <= 0.0:
			g.erase(k)
	g[key] = [_glut_units(data, key) + n, data.day_count]
	data.set_flag(GLUT_FLAG, g)
	_teach(data, item_id, zone_id)

## The Economist's notebook: a glut you made teaches supply and demand; selling where a thing is wanted, why trade pays.
static func _teach(data: GameStateData, item_id: String, zone_id: String) -> void:
	var nm := str(items().get_item(item_id).get("name", item_id)) if items() != null else item_id
	if glut_factor(data, item_id, zone_id) < 0.85:
		Economist.note(data, "supply_demand", "%s in %s" % [nm, town_of(zone_id).capitalize()])
	if is_trade_good(item_id) and regional(item_id, group_of(zone_id)) > 1.2:
		Economist.note(data, "comparative", nm)

static func keeps_days(item_id: String) -> int:
	var c := config()
	var rule: Dictionary = c.get("goods", {}).get(item_id, {})
	if rule.has("keeps"):
		return int(rule.keeps)
	return int(c.get("keeps", {}).get(str(items().get_item(item_id).get("kind", "")), 0))

## 1.0 while fresh, falling to the stale factor by the end of its keeping time. Missing stamp (old saves) is fresh.
static func freshness(data: GameStateData, item_id: String) -> float:
	var keeps := keeps_days(item_id)
	var stamps = data.flag(FRESH_FLAG)
	if keeps <= 0 or not stamps is Dictionary or not stamps.has(item_id):
		return 1.0
	var age := float(data.day_count - int(stamps[item_id]))
	var half := keeps / 2.0
	var stale := float(config().get("stale_factor", 0.25))
	if age <= half:
		return 1.0
	return clampf(lerpf(1.0, stale, (age - half) / half), stale, 1.0)

## Call when n more of a perishable arrive and `held` were already in the bag: the stack's age is the average.
static func stamp(data: GameStateData, item_id: String, held: int, n: int) -> void:
	if n < 1 or keeps_days(item_id) <= 0:
		return
	var stamps: Dictionary = data.flag(FRESH_FLAG) if data.flag(FRESH_FLAG) is Dictionary else {}
	var old := int(stamps.get(item_id, data.day_count)) if held > 0 else data.day_count
	stamps[item_id] = int(round((float(old) * held + float(data.day_count) * n) / float(held + n)))
	data.set_flag(FRESH_FLAG, stamps)

## `news` is TradeNews.factor: a boost may only lift the seasonal demand up to its cap (never past it), a glut always bites.
static func _sell_unit(item_id: String, zone_id: String, fresh: float, glut: float, news := 1.0) -> int:
	var base := base_price(item_id)
	if base <= 0:
		return 0
	var dem := demand(item_id, zone_id)
	if news > 1.0:
		dem = maxf(dem, minf(dem * news, float(config().get("demand_cap", 1.8))))
	else:
		dem *= news
	var v := base * 0.5 * regional(item_id, group_of(zone_id)) * dem * fresh * glut
	return maxi(1, int(v))  # floored, as the corner shop's half price always was

static func buy_price(_data: GameStateData, item_id: String, zone_id: String) -> int:
	var base := base_price(item_id)
	if base <= 0:
		return 0
	return maxi(1, int(round(base * regional(item_id, group_of(zone_id)))))

static func sell_price(data: GameStateData, item_id: String, zone_id: String) -> int:
	return _sell_unit(item_id, zone_id, freshness(data, item_id) * Trades.sell_mult(data), glut_factor(data, item_id, zone_id), TradeNews.factor(data, item_id, zone_id))

## What n units fetch in all, each sale poorer than the last. Nothing is recorded: follow with record_sale.
## `free` is how many of the n go at the glut-free price (the Trader's market-day pitch): they do not build a glut.
static func sell_total(data: GameStateData, item_id: String, zone_id: String, n: int, free := 0) -> int:
	var fresh := freshness(data, item_id) * Trades.sell_mult(data)  # the Trader perks
	var step := float(config().get("glut_step", 0.92))
	var g := glut_factor(data, item_id, zone_id)
	var news := TradeNews.factor(data, item_id, zone_id)
	var total := 0
	for i in n:
		if i < free:
			total += _sell_unit(item_id, zone_id, fresh, 1.0, news)
			continue
		total += _sell_unit(item_id, zone_id, fresh, g, news)
		g *= step
	return total

## A few words for the price board: "cheap here", "they're crying out for it", "glut", "a bit off" or "".
static func price_note(data: GameStateData, item_id: String, zone_id: String) -> String:
	if base_price(item_id) <= 0:
		return ""
	if glut_factor(data, item_id, zone_id) < 0.85:
		return "glut"
	if freshness(data, item_id) < 0.7:
		return "a bit off"
	var heard := TradeNews.note(data, item_id, zone_id)
	if heard != "":
		return heard
	var r := regional(item_id, group_of(zone_id))
	if r > 1.0 or demand(item_id, zone_id) >= 1.3:
		return "they're crying out for it"
	if r < 1.0:
		return "cheap here"
	return ""

## How many of an item you may carry: trade goods stop at the cap (30) until you own the pannier (then 99);
## everything else keeps the bag's own limit, so nothing you could carry before is now refused.
static func carry_cap(data: GameStateData, item_id: String) -> int:
	if not is_trade_good(item_id) or int(data.bag.get(str(config().get("pannier", "")), 0)) > 0:
		return Bag.MAX_STACK
	return mini(Bag.MAX_STACK, int(config().get("carry_cap", 30)) + Guilds.carry_bonus(data) + Trades.carry_bonus(data))   # the Traders' Guild, the Trader trade

## How many more you may take on (0 when over the cap already, e.g. a stack from before).
static func room(data: GameStateData, item_id: String) -> int:
	return maxi(0, carry_cap(data, item_id) - int(data.bag.get(item_id, 0)))

# --- the wireless: the Money Box ---

static func _pick(day: int, salt: String, n: int) -> int:
	return absi(hash("%s:%d" % [salt, day])) % maxi(1, n)

## The Money Box on the wireless: today's tip, a seasonal note, any glut you have made, and on Mondays (every
## seventh in-game day) the weekly market report. Fixed for the day, so it reads the same twice.
static func money_box(data: GameStateData, _zone_id: String) -> Array:
	var r: Dictionary = config().get("report", {})
	var lines: Array = [str(r.get("intro", ""))]
	var goods: Array = config().get("goods", {}).keys()
	goods.sort()
	var monday := data.day_count % 7 == 0
	if monday:
		lines.append(str(r.get("monday", "")))
	lines.append_array(TradeNews.wireless_lines(data, 3 if monday else 2))   # what is really moving prices this week
	lines.append_array(TradeOrders.wireless_lines(data, 1))                    # a market that is after something
	for i in (2 if monday else 1):
		var id := str(goods[_pick(data.day_count, "tip%d" % i, goods.size())])
		var g: Dictionary = config().goods[id]
		var name := str(items().get_item(id).get("name", id))
		if g.get("home", []).is_empty() or g.get("wants", []).is_empty():
			continue
		lines.append(str(r.get("tip", "")) % [name, group_name(str(g.home[0])), group_name(str(g.wants[_pick(data.day_count, "w" + id, g.wants.size())]))])
	var t := Calendar.today()
	var season := Calendar.season_for(t.x, t.y)
	for s in config().get("seasonal", []):
		if str(s.season) == season:
			lines.append(str(r.get("season", "")) % str(s.get("note", "")))
			break
	var g = data.flag(GLUT_FLAG)
	if g is Dictionary:
		for k in g:
			if _glut_units(data, str(k)) >= 3.0:
				var parts := str(k).split("|")
				lines.append("A word to whoever has been flooding %s with %s: they have had enough." % [Travel.town_name(parts[0]), str(items().get_item(parts[1]).get("name", parts[1]))])
				break
	lines.append(str(r.get("close", "")))
	return lines
