class_name TradeNews
extends RefCounted
## Trade news: a few seeded events a week that really move what things sell for in real places (data/trade.json "news").
## A glut at Lerwick, gales that keep the Hull boats in, a late frost, a rail strike that widens every gap, a festival
## crowd. Each starts on a seeded in-game day, is announced `lead` days before it bites (0 means "as it happens"), and
## lasts a few days. The player hears them on the wireless (Trade.money_box), from a stall-holder (the Market Hall)
## and on the Trade Ledger page; hearing one is remembered, nothing else is stored. The Trader trade (level 2) hears
## each two days sooner. Pure logic (no autoload names): the validator loads it.
## The effect is a multiplier on the SELLING price only (Trade.sell_price reads `factor`), so buying and selling in one
## place still never pays: a boost cannot lift the combined demand above the festival cap, a glut only ever lowers it.
## State: trade_heard {"id@start": day heard}, a flag dictionary that defaults empty, so old saves are fine.

const HEARD_FLAG := "trade_heard"
const EARLY_DAYS := 2   # how much sooner a level 2 Trader hears

static var _cache_day := -99999
static var _cache_season := ""
static var _cache: Array = []

static func cfg() -> Dictionary:
	var n = Trade.config().get("news", {})
	return n if n is Dictionary else {}

static func event_def(id: String) -> Dictionary:
	for e in cfg().get("events", []):
		if str(e.id) == id:
			return e
	return {}

static func _season() -> String:
	var t := Calendar.today()
	return Calendar.season_for(t.x, t.y)

## The event that starts on an in-game day, or {} on a quiet day: `per_week` days in seven, picked by a seeded hash.
static func starting(day: int) -> Dictionary:
	var c := cfg()
	if day < 0 or absi(hash("news:%d" % day)) % 7 >= int(c.get("per_week", 3)):
		return {}
	var season := _season()
	var pool: Array = []
	for e in c.get("events", []):
		if not e.has("seasons") or season in e.seasons:
			pool.append(e)
	if pool.is_empty():
		return {}
	var e: Dictionary = pool[absi(hash("newspick:%d" % day)) % pool.size()].duplicate()
	e["start"] = day
	return e

static func key_of(e: Dictionary) -> String:
	return "%s@%d" % [str(e.id), int(e.start)]

static func ends(e: Dictionary) -> int:
	return int(e.start) + int(e.days)   # the first day it no longer bites

## Every event that has started, is announced or has yet to be announced around a day, oldest start first. Cached for
## the day, because prices ask for it a lot.
static func window(day: int) -> Array:
	var season := _season()
	if day == _cache_day and season == _cache_season:
		return _cache
	var out: Array = []
	var lo := day - int(cfg().get("max_days", 6)) - 1
	for s in range(maxi(0, lo), day + 6):
		var e := starting(s)
		if not e.is_empty():
			out.append(e)
	_cache = out
	_cache_day = day
	_cache_season = season
	return out

static func early(data: GameStateData) -> int:
	return EARLY_DAYS if Trades.has_perk(data, "trader_early") else 0

static func is_on(e: Dictionary, day: int) -> bool:
	return day >= int(e.start) and day < ends(e)

## What a player standing at `day` may know: announced and not over. [{... event ..., "on": bool}]
static func visible(data: GameStateData, day := -1) -> Array:
	if day < 0:
		day = data.day_count
	var out: Array = []
	var sooner := early(data)
	for e in window(day):
		if day < ends(e) and day >= int(e.start) - int(e.lead) - sooner:
			var v: Dictionary = e.duplicate()
			v["on"] = is_on(e, day)
			out.append(v)
	return out

static func _in_scope(e: Dictionary, zone_id: String) -> bool:
	var has_scope := e.has("towns") or e.has("groups")
	if not has_scope:
		return true
	return Trade.town_of(zone_id) in e.get("towns", []) or Trade.group_of(zone_id) in e.get("groups", [])

static func _hits(e: Dictionary, item_id: String) -> bool:
	if item_id in e.get("items", []):
		return true
	return str(Trade.items().get_item(item_id).get("kind", "")) in e.get("kinds", [])

## The selling multiplier the news puts on an item in a place today (1.0 when there is none).
static func factor(data: GameStateData, item_id: String, zone_id: String) -> float:
	var f := 1.0
	var day := data.day_count
	for e in window(day):
		if not is_on(e, day) or not _hits(e, item_id) or not _in_scope(e, zone_id):
			continue
		if str(e.kind) == "widen":
			var r := Trade.regional(item_id, Trade.group_of(zone_id))
			f *= float(e.factor) if r > 1.0 else (1.0 / float(e.factor) if r < 1.0 else 1.0)
		else:
			f *= float(e.factor)
	var c := cfg()
	return clampf(f, float(c.get("min_factor", 0.6)), float(c.get("max_factor", 1.5)))

## True while a rail strike (or anything of the "widen" kind) is on: orders pay a little extra for getting through.
static func widening(data: GameStateData) -> bool:
	for e in window(data.day_count):
		if str(e.kind) == "widen" and is_on(e, data.day_count):
			return true
	return false

## One line about an event as of a day: "Today: ...", "Still going: ..." or "In two days: ...".
static func line(e: Dictionary, day: int, field := "wire") -> String:
	var text := str(e.get(field, ""))
	if field == "stall":
		return text
	var gap := int(e.start) - day
	if gap <= 0:
		return ("Today: " if day == int(e.start) else "Still going: ") + text
	return ("Tomorrow: " if gap == 1 else "In %d days: " % gap) + text

static func _remember(data: GameStateData, e: Dictionary) -> void:
	note_heard(data, key_of(e))

## Remembers that something was heard ("id@start" for news, "o:<order id>" for an order), once.
static func note_heard(data: GameStateData, k: String) -> void:
	var heard: Dictionary = data.flag(HEARD_FLAG) if data.flag(HEARD_FLAG) is Dictionary else {}
	if heard.has(k):
		return
	heard[k] = data.day_count
	if heard.size() > int(cfg().get("heard_keep", 40)):   # forget the oldest, so the flag stays small
		var oldest := ""
		for kk in heard:
			if oldest == "" or int(heard[kk]) < int(heard[oldest]):
				oldest = str(kk)
		heard.erase(oldest)
	data.set_flag(HEARD_FLAG, heard)

static func heard(data: GameStateData, e: Dictionary) -> bool:
	return heard_key(data, key_of(e))

static func heard_key(data: GameStateData, k: String) -> bool:
	var h = data.flag(HEARD_FLAG)
	return h is Dictionary and h.has(k)

## The wireless: up to `n` things to say today, soonest first, and each is noted as heard. [] on a quiet day.
static func wireless_lines(data: GameStateData, n := 2) -> Array:
	var out: Array = []
	for e in visible(data):
		if out.size() >= n:
			break
		_remember(data, e)
		out.append(line(e, data.day_count))
	return out

## What the stall-holder at a hall has to say today about the news (and a hint of an order elsewhere), or "". Noted as heard.
static func stall_line(data: GameStateData, hall_id: String) -> String:
	var seen := visible(data)
	if seen.is_empty():
		return ""
	var e: Dictionary = seen[absi(hash("stall:%s:%d" % [hall_id, data.day_count])) % seen.size()]
	_remember(data, e)
	return str(e.stall)

## The news the player has heard that still matters, for the ledger: [{event..., "on": bool}].
static func heard_now(data: GameStateData) -> Array:
	var out: Array = []
	for e in visible(data):
		if heard(data, e):
			out.append(e)
	return out

## A word for a price board when the news is moving this item here, or "".
static func note(data: GameStateData, item_id: String, zone_id: String) -> String:
	var f := factor(data, item_id, zone_id)
	if f >= 1.1:
		return "in the news: short of it"
	if f <= 0.9:
		return "in the news: a glut"
	return ""

## Problems with the news data: ids unique, each event has all its words, a real kind and scope, real items, sane numbers.
static func problems() -> Array:
	var errs := []
	var seen := {}
	for e in cfg().get("events", []):
		var id := str(e.get("id", ""))
		if id == "" or seen.has(id):
			errs.append("trade news: duplicate or empty id %s" % id)
		seen[id] = true
		if str(e.get("kind", "")) not in ["glut", "shortage", "widen"]:
			errs.append("trade news %s: kind must be glut, shortage or widen" % id)
		for k in ["board", "wire", "stall"]:
			if str(e.get(k, "")) == "" or str(e.get(k, "")).contains("—"):
				errs.append("trade news %s: needs %s text, without an em-dash" % [id, k])
		if not e.has("items") and not e.has("kinds"):
			errs.append("trade news %s: names no items or kinds" % id)
		for it in e.get("items", []):
			if Trade.items().get_item(str(it)).is_empty() or Trade.base_price(str(it)) <= 0:
				errs.append("trade news %s: %s is not a priced item" % [id, it])
		for g in e.get("groups", []):
			if not Trade.config().get("names", {}).has(str(g)):
				errs.append("trade news %s: %s is not a trade region" % [id, g])
		var f := float(e.get("factor", 1.0))
		var kind := str(e.get("kind", ""))
		if (kind == "glut" and f >= 1.0) or (kind != "glut" and f <= 1.0) or f > float(cfg().get("max_factor", 1.5)) or f < float(cfg().get("min_factor", 0.6)):
			errs.append("trade news %s: factor %s does not fit its kind" % [id, f])
		if int(e.get("days", 0)) < 1 or int(e.days) > int(cfg().get("max_days", 6)) or int(e.get("lead", -1)) < 0 or int(e.lead) > 3:
			errs.append("trade news %s: days 1 to max_days, lead 0 to 3" % id)
	return errs
