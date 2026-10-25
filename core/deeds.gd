class_name Deeds
extends RefCounted
## Deeds: businesses the player buys in one real place (data/deeds/<id>.json; the chippy, B&B, boat, stall and
## allotment all share this one engine). You stock a Deed from the bag, it earns takings by itself each in-game
## day, council rates are billed weekly out of the takings, and you collect the till in person. A tier upgrade lifts
## the takings; a manager (a Regular, see Regulars) lifts them a little more and lets the till go on filling while
## you're away. One Deed per archetype per save.
## State lives in one flag per Deed, absent until bought, so old saves are fine:
##   deed_<id>  {owned, tier, store {item: n}, till, rates_due, manager, last_day, coll, paid, accrue, bill, stmt, log}
## and the post (rates bills, monthly statements, the tax envelope) in a single flag:
##   deeds_post {mail [{k, d, day, a, c}], income {cur: {year: gbp}}, taxed {cur: year}, owed {cur: n}}
## All sums are STERLING whole pounds as the data authors them; Wallet converts at the Deed's own zone.
## Takings are seeded per Deed and day (no state to walk), and nothing here can make money from nothing: the stock
## costs real goods, the tiers cost more than they return for many days, and selling back pays 60% of what went in
## (see DeedsSim). Pure logic, no autoloads.

const DIR := "res://data/deeds/"
const POST_PATH := "res://data/deeds_post.json"
const FLAG_PREFIX := "deed_"
const POST_FLAG := "deeds_post"
const BANDS := [4, 8]            # badges at which the second and third cost apply
const WEEK := 7
const MONTH := 30
const YEAR := 365
const SELL_BACK := 0.6
const MAX_CATCH_UP := 120        # days settled in one go; a longer absence is trimmed, not exploded
const UNATTENDED_DAYS := 30      # without a manager the till stops filling this long after your last visit
const MANAGED_DAYS := 90
const MANAGER_BONUS := 1.15
const STORE_DAYS := 14           # the store holds this many days of each input
const LOG_KEEP := 6
const MAIL_KEEP := 12
const BAND_BONUS := 0.4         # takings grow with how far you have got (badge bands), as costs do
const NO_STOCK := 0.25           # a Deed with no stock earns only this much of its base
const DRIFT_PER_YEAR := 0.03     # inflation: costs and takings rise together, gently, and never above the cap
const DRIFT_CAP := 1.5
## Self assessment, scaled to game money: [up to, rate] per band. The allowance is untaxed.
const ALLOWANCE := 2000
const TAX_BANDS := [[20000, 0.10], [60000, 0.15], [999999999, 0.20]]
const TAX_MONTH := 4
const TAX_LAST_DAY := 7

static var _all: Array = []
static var _by_id: Dictionary = {}
static var _post: Dictionary = {}

static func all() -> Array:
	if _all.is_empty():
		_all = []
		_by_id = {}
		for f in DirAccess.get_files_at(DIR):
			if not f.ends_with(".json"):
				continue
			var raw: Variant = JsonUtil.read(DIR + f)
			if raw is Dictionary and str(raw.get("id", "")) != "":
				_all.append(raw)
				_by_id[str(raw.id)] = raw
		_all.sort_custom(func(a, b): return str(a.id) < str(b.id))
	return _all

static func get_deed(id: String) -> Dictionary:
	all()
	return _by_id.get(id, {})

static func post_text() -> Dictionary:
	if _post.is_empty():
		var raw: Variant = JsonUtil.read(POST_PATH)
		_post = raw if raw is Dictionary else {"letters": {}, "talk": {}}
	return _post

static func talk(key: String) -> String:
	return str(post_text().get("talk", {}).get(key, ""))

static func _i(d: Dictionary, k: String) -> int:
	return int(d.get(k, 0))

# --- state ----------------------------------------------------------------------------

static func _peek(data: GameStateData, id: String) -> Dictionary:
	var v: Variant = data.flag(FLAG_PREFIX + id)
	return v if v is Dictionary else {}

## The stored state of a Deed, normalised in place (JSON round trips turn ints to floats and may drop keys).
static func _st(data: GameStateData, id: String) -> Dictionary:
	var v: Variant = data.flag(FLAG_PREFIX + id)
	if not (v is Dictionary):
		v = {}
		data.set_flag(FLAG_PREFIX + id, v)
	var st: Dictionary = v
	for k in ["tier", "till", "rates_due", "last_day", "coll", "paid", "accrue", "bill", "stmt"]:
		st[k] = _i(st, k)
	if not (st.get("store") is Dictionary):
		st["store"] = {}
	if not (st.get("log") is Array):
		st["log"] = []
	st["manager"] = str(st.get("manager", ""))
	return st

static func state(data: GameStateData, id: String) -> Dictionary:
	return _peek(data, id).duplicate(true)

static func is_owned(data: GameStateData, id: String) -> bool:
	return bool(_peek(data, id).get("owned", false))

## The Deeds the player owns, as their data dictionaries.
static func owned(data: GameStateData) -> Array:
	var out := []
	for d in all():
		if is_owned(data, str(d.id)):
			out.append(d)
	return out

static func tier_of(data: GameStateData, id: String) -> int:
	var n: int = get_deed(id).get("tiers", []).size()
	return clampi(_i(_peek(data, id), "tier"), 0, maxi(0, n - 1))

static func tier_name(data: GameStateData, id: String) -> String:
	var t: Array = get_deed(id).get("tiers", [])
	return str(t[tier_of(data, id)].get("name", "")) if not t.is_empty() else ""

static func till(data: GameStateData, id: String) -> int:
	return _i(_peek(data, id), "till")

static func rates_due(data: GameStateData, id: String) -> int:
	return _i(_peek(data, id), "rates_due")

static func manager(data: GameStateData, id: String) -> String:
	return str(_peek(data, id).get("manager", ""))

static func store_of(data: GameStateData, id: String, item_id: String) -> int:
	return _i(_peek(data, id).get("store", {}), item_id)

static func recent(data: GameStateData, id: String) -> Array:
	var out := []
	var log: Array = _peek(data, id).get("log", [])
	for i in range(log.size() - 1, -1, -1):
		out.append("Day %d: %s" % [int(log[i][0]), str(log[i][1])])
	return out

static func cur_of(id: String) -> String:
	return Wallet.currency_for_zone(str(get_deed(id).get("zone", "")))

# --- inflation ------------------------------------------------------------------------

## A gentle, seeded drift in what Deeds cost and take, by the in-game year. 1.0 for the first year; never above
## DRIFT_CAP. It only touches Deeds: shop prices never read it.
static func inflation(data: GameStateData, day: int = -1) -> float:
	var d := data.day_count if day < 0 else day
	var years := d / YEAR
	var f := 1.0
	for y in years:
		var wobble := float(absi(hash("%d:infl:%d" % [data.rng_seed, y])) % 21 - 10) / 1000.0   # +-1%
		f *= 1.0 + DRIFT_PER_YEAR + wobble * 0.5
	return minf(f, DRIFT_CAP)

static func band_scale(data: GameStateData) -> float:
	return 1.0 + BAND_BONUS * _band(data)

# --- prices ---------------------------------------------------------------------------

static func _band(data: GameStateData) -> int:
	var b := 0
	for t in BANDS:
		if data.badges.size() >= int(t):
			b += 1
	return b

## What the Deed costs today in sterling: by badge band, with inflation.
static func price(data: GameStateData, id: String) -> int:
	var cost: Array = get_deed(id).get("cost", [])
	if cost.is_empty():
		return 0
	return roundi(float(cost[mini(_band(data), cost.size() - 1)]) * inflation(data))

static func upgrade_cost(data: GameStateData, id: String) -> int:
	var t: Array = get_deed(id).get("tiers", [])
	var n := tier_of(data, id) + 1
	if n >= t.size():
		return 0
	return roundi(float(t[n].get("cost", 0)) * inflation(data))

static func tier_mult(data: GameStateData, id: String) -> float:
	var t: Array = get_deed(id).get("tiers", [])
	return float(t[tier_of(data, id)].get("mult", 1.0)) if not t.is_empty() else 1.0

# --- buying ---------------------------------------------------------------------------

static func _kind_owned(data: GameStateData, kind: String) -> String:
	for d in owned(data):
		if str(d.kind) == kind:
			return str(d.id)
	return ""

## "" when it worked, else a friendly reason. Pays in the Deed's own money.
static func buy(data: GameStateData, id: String) -> String:
	var d := get_deed(id)
	if d.is_empty():
		return "There's no such place."
	if is_owned(data, id):
		return "You own it already."
	var mine := _kind_owned(data, str(d.kind))
	if mine != "":
		return "You already run %s. One of each kind is plenty." % str(get_deed(mine).name)
	var gate := str(d.get("unlock_flag", ""))
	if gate != "" and data.flag(gate) != true:
		return "Not yet. Nobody sells a business to a stranger with no Stones to their name."
	var cur := cur_of(id)
	var cost := Wallet.localise(price(data, id), cur)
	if not Wallet.spend(data, cost, cur):
		return "You'd need %s for that." % Wallet.fmt(cost, cur)
	data.set_flag(FLAG_PREFIX + id, {"owned": true, "tier": 0, "store": {}, "till": 0, "rates_due": 0, "manager": "",
		"last_day": data.day_count, "coll": data.day_count, "paid": price(data, id), "accrue": 0,
		"bill": data.day_count + WEEK, "stmt": data.day_count + MONTH, "log": []})
	Economist.note(data, "opportunity_cost", {"text": str(d.name), "gbp": price(data, id)})
	return ""

## Moves up to n of an item from the bag into the Deed's store (never past a fortnight's stock). How many went in.
static func supply(data: GameStateData, id: String, item_id: String, n: int) -> int:
	if not is_owned(data, id) or n <= 0:
		return 0
	var per_day := 0
	for inp in get_deed(id).get("inputs", []):
		if str(inp.item) == item_id:
			per_day = int(inp.per_day)
	if per_day <= 0:
		return 0
	var st := _st(data, id)
	var room := per_day * STORE_DAYS - _i(st.store, item_id)
	var give := mini(mini(n, room), int(data.bag.get(item_id, 0)))
	if give <= 0:
		return 0
	data.bag[item_id] = int(data.bag.get(item_id, 0)) - give
	if int(data.bag[item_id]) <= 0:
		data.bag.erase(item_id)
	st.store[item_id] = _i(st.store, item_id) + give
	return give

static func set_manager(data: GameStateData, id: String, npc_id: String) -> void:
	if is_owned(data, id):
		_st(data, id).manager = npc_id

## Pays the next tier. "" or a reason.
static func upgrade(data: GameStateData, id: String) -> String:
	if not is_owned(data, id):
		return "You don't own it."
	var cost := upgrade_cost(data, id)
	if cost <= 0:
		return "It's as good as it gets."
	var cur := cur_of(id)
	if not Wallet.spend(data, Wallet.localise(cost, cur), cur):
		return "You'd need %s for that." % Wallet.fmt(Wallet.localise(cost, cur), cur)
	var st := _st(data, id)
	st.tier = tier_of(data, id) + 1
	st.paid = _i(st, "paid") + cost
	return ""

## Empties the till into the purse, after any rates owed. How much reached the purse (local money). The sterling
## figure counts toward the year's tax.
static func collect(data: GameStateData, id: String) -> int:
	if not is_owned(data, id):
		return 0
	var st := _st(data, id)
	var gross := _i(st, "till")
	var rates := mini(gross, _i(st, "rates_due"))
	var net := gross - rates
	st.till = 0
	st.rates_due = _i(st, "rates_due") - rates
	st.coll = data.day_count
	if net <= 0:
		return 0
	var cur := cur_of(id)
	_post_st(data, true)
	_add_income(data, cur, net)
	return Wallet.earn(data, Wallet.localise(net, cur), cur)

## 60% of what you paid in all (the Deed and its upgrades), plus the till less rates. Gives the place up.
static func sell_back(data: GameStateData, id: String) -> int:
	if not is_owned(data, id):
		return 0
	var got := collect(data, id)
	var st := _st(data, id)
	var cur := cur_of(id)
	var sale := roundi(float(_i(st, "paid")) * SELL_BACK)
	sale = maxi(0, sale - _i(st, "rates_due"))   # whatever the council is still owed comes off first
	for item in st.store:                         # the store goes back to you
		data.bag[item] = mini(Bag.MAX_STACK, int(data.bag.get(item, 0)) + _i(st.store, item))
	data.set_flag(FLAG_PREFIX + id, {"owned": false})
	return got + Wallet.earn(data, Wallet.localise(sale, cur), cur)

# --- the days go by -------------------------------------------------------------------

static func _roll(data: GameStateData, id: String, day: int, salt: String) -> float:
	return float(absi(hash("%d:%s:%d:%s" % [data.rng_seed, id, day, salt])) % 10000) / 10000.0

## Today's event for a Deed, or {}. At most one a day; seasonal ones only in season; chances are per day.
static func event_on(data: GameStateData, id: String, day: int) -> Dictionary:
	var roll := _roll(data, id, day, "ev")
	var season := Calendar.season_for(((day / MONTH) % 12) + 1, 1)
	var acc := 0.0
	for e in get_deed(id).get("events", []):
		var want := str(e.get("season", ""))
		if want != "" and want != season:
			continue
		acc += float(e.get("chance", 0.0))
		if roll < acc:
			return e
	return {}

## Units of an input that a day would use right now.
static func _stock_fraction(st: Dictionary, deed: Dictionary) -> float:
	var inputs: Array = deed.get("inputs", [])
	if inputs.is_empty():
		return 1.0
	var f := 0.0
	for inp in inputs:
		f += minf(1.0, float(_i(st.store, str(inp.item))) / maxf(1.0, float(inp.per_day)))
	return f / inputs.size()

static func _consume(st: Dictionary, deed: Dictionary) -> int:
	var used := 0
	for inp in deed.get("inputs", []):
		var u := mini(_i(st.store, str(inp.item)), int(inp.per_day))
		st.store[str(inp.item)] = _i(st.store, str(inp.item)) - u
		used += u
	return used

## One quiet day's takings with a full store at tier 0, before events: for the sim and the screen.
static func daily_estimate(data: GameStateData, id: String) -> int:
	var d := get_deed(id)
	if d.is_empty():
		return 0
	var units := 0
	for inp in d.get("inputs", []):
		units += int(inp.per_day)
	var o: Dictionary = d.get("output", {})
	return roundi((float(o.get("base", 0)) + float(o.get("per_input", 0)) * units) * tier_mult(data, id) * inflation(data) * band_scale(data))

## Advances every owned Deed to `day`: stock used, takings added (tier, event, manager and inflation), rates
## accrued and billed, statements and the tax envelope posted. Returns lines for the post box and the wireless.
static func tick(data: GameStateData, day: int) -> Array:
	var lines := []
	for deed in owned(data):
		lines.append_array(_tick_one(data, deed, day))
	_tax_check(data)
	return lines

static func _tick_one(data: GameStateData, deed: Dictionary, day: int) -> Array:
	var id := str(deed.id)
	var st := _st(data, id)
	var lines := []
	var from := _i(st, "last_day") + 1
	if day - from + 1 > MAX_CATCH_UP:
		from = day - MAX_CATCH_UP + 1
	for dd in range(from, day + 1):
		var ev := event_on(data, id, dd)
		var mult := 1.0
		if not ev.is_empty():
			mult = float(ev.get("mult", 1.0))
		var takings := 0.0
		if mult > 0.0:                          # a closed day uses nothing and takes nothing
			var f := _stock_fraction(st, deed)
			var used := _consume(st, deed)
			var o: Dictionary = deed.get("output", {})
			var base := float(o.get("base", 0)) * (NO_STOCK + (1.0 - NO_STOCK) * f) + float(o.get("per_input", 0)) * used
			takings = base * tier_mult(data, id) * mult * inflation(data, dd) * band_scale(data)
			if str(st.manager) != "":
				takings *= MANAGER_BONUS
		var window := MANAGED_DAYS if str(st.manager) != "" else UNATTENDED_DAYS
		var t := roundi(takings) if dd - _i(st, "coll") <= window else 0
		st.till = _i(st, "till") + t
		st.accrue = _i(st, "accrue") + t
		if not ev.is_empty():
			var line := "%s: %s" % [str(deed.name), str(ev.get("line", ""))]
			_log(st, dd, str(ev.get("line", "")))
			lines.append(line)
		if dd >= _i(st, "bill"):
			var due := ceili(float(_i(st, "accrue")) * float(deed.get("rates", 0.0)))
			st.rates_due = _i(st, "rates_due") + due
			st.accrue = 0
			st.bill = _i(st, "bill") + WEEK
			if due > 0:
				_mail(data, "rates", id, dd, _i(st, "rates_due"))
		if dd >= _i(st, "stmt"):
			st.stmt = _i(st, "stmt") + MONTH
			_mail(data, "statement", id, dd, _i(st, "till"))
	st.last_day = day
	return lines

static func _log(st: Dictionary, day: int, text: String) -> void:
	st.log.append([day, text])
	while st.log.size() > LOG_KEEP:
		st.log.remove_at(0)

# --- the post ---------------------------------------------------------------------------

static func _post_st(data: GameStateData, create: bool) -> Dictionary:
	var v: Variant = data.flag(POST_FLAG)
	if not (v is Dictionary):
		if not create:
			return {}
		v = {}
		data.set_flag(POST_FLAG, v)
	var p: Dictionary = v
	if not (p.get("mail") is Array):
		p["mail"] = []
	for k in ["income", "taxed", "owed"]:
		if not (p.get(k) is Dictionary):
			p[k] = {}
	return p

## Queues a letter. Only one of each kind per Deed waits at a time: a newer bill replaces the older.
static func _mail(data: GameStateData, kind: String, deed_id: String, day: int, amount: int, cur := "") -> void:
	var p := _post_st(data, true)
	var m: Array = p.mail
	for i in range(m.size() - 1, -1, -1):
		if str(m[i].k) == kind and str(m[i].d) == deed_id:
			m.remove_at(i)
	m.append({"k": kind, "d": deed_id, "day": day, "a": amount, "c": cur})
	while m.size() > MAIL_KEEP:
		m.remove_at(0)

static func letters_waiting(data: GameStateData) -> Array:
	var v: Variant = data.flag(POST_FLAG)
	if not (v is Dictionary) or not (v.get("mail") is Array):
		return []
	return (v.mail as Array).duplicate(true)

## Takes the waiting post out of the box. Returns the letters' lines, ready for the textbox. The tax is settled
## as its envelope is opened.
static func collect_letters(data: GameStateData) -> Array:
	var got := letters_waiting(data)
	if got.is_empty():
		return []
	_post_st(data, true).mail = []
	var out := []
	for m in got:
		out.append_array(letter_lines(data, m))
		if str(m.k) == "tax":
			out.append_array(_settle_tax(data, m))
	return out

static func _fill(t: String, m: Dictionary, name: String) -> String:
	var cur := str(m.get("c", "")) if str(m.get("c", "")) != "" else Wallet.GBP
	var amount := Wallet.fmt(Wallet.localise(int(m.get("a", 0)), cur), cur)
	return t.replace("{deed}", name).replace("{amount}", amount).replace("{day}", str(int(m.get("day", 0))))

static func letter_lines(_data: GameStateData, m: Dictionary) -> Array:
	var l: Dictionary = post_text().get("letters", {}).get(str(m.k) + ("_eur" if str(m.get("c", "")) == Wallet.EUR else ""), {})
	if l.is_empty():
		return []
	var name := str(get_deed(str(m.get("d", ""))).get("name", "your business"))
	var out := ["A letter from %s." % _fill(str(l.get("from", "")), m, name)]
	for t in l.get("text", []):
		out.append(_fill(str(t), m, name).replace("{mx}", Looks.pronoun(_data, "Mx")).replace("{player}", _data.player_name))  # Mr / Ms / Mx (see Looks)
	return out

# --- the taxman -------------------------------------------------------------------------

static func _add_income(data: GameStateData, cur: String, gbp: int) -> void:
	var p := _post_st(data, true)
	if not (p.income.get(cur) is Dictionary):
		p.income[cur] = {}
	var y := str(Calendar.year())
	p.income[cur][y] = int(p.income[cur].get(y, 0)) + gbp

## Tax on a year's takings: nothing under the allowance, then banded.
static func tax_on(income: int) -> int:
	var tax := 0.0
	var lo := ALLOWANCE
	for b in TAX_BANDS:
		if income <= lo:
			break
		tax += (mini(income, int(b[0])) - lo) * float(b[1])
		lo = int(b[0])
	return roundi(tax)

## In the first week of April, once a year, last year's takings (per currency, so the Revenue Commissioners write
## about euros) bring a brown or a green envelope. Nothing happens for a player who owned no Deed last year.
static func _tax_check(data: GameStateData) -> void:
	var today := Calendar.today()
	if today.x != TAX_MONTH or today.y > TAX_LAST_DAY:
		return
	var p := _post_st(data, false)
	if p.is_empty():
		return
	var year := Calendar.year()
	for cur in p.income:
		var last := int(p.income[cur].get(str(year - 1), 0))
		if last <= 0 or int(p.taxed.get(cur, 0)) >= year:
			continue
		p.taxed[cur] = year
		var tax := tax_on(last)
		_mail(data, "tax", "", data.day_count, tax, cur)
		p.mail[p.mail.size() - 1]["inc"] = last

static func _settle_tax(data: GameStateData, m: Dictionary) -> Array:
	var cur := str(m.get("c", Wallet.GBP))
	var p := _post_st(data, true)
	var due := Wallet.localise(int(m.get("a", 0)), cur) + int(p.owed.get(cur, 0))
	if due <= 0:
		return [talk("tax_none")]
	var pay := mini(due, Wallet.balance(data, cur))
	Wallet.spend(data, pay, cur)
	p.owed[cur] = due - pay
	if due - pay > 0:
		return [talk("tax_short").replace("{left}", Wallet.fmt(due - pay, cur))]
	return [talk("tax_paid").replace("{paid}", Wallet.fmt(pay, cur))]

## A line for the statement screen: what you owe the taxman on the year so far.
static func tax_so_far(data: GameStateData, cur: String) -> int:
	var p := _post_st(data, false)
	if p.is_empty() or not (p.income.get(cur) is Dictionary):
		return 0
	return tax_on(int(p.income[cur].get(str(Calendar.year()), 0)))

## What the money-sinks of owning a Deed cost per in-game day, in sterling: rates at the Deed's rate on a full day.
static func daily_rates(data: GameStateData, id: String) -> int:
	return roundi(daily_estimate(data, id) * float(get_deed(id).get("rates", 0.0)) * Guilds.rates_mult(data))   # the Heritage Trust

## A line for the Deed screen: the state of the till, store and manager.
static func summary(data: GameStateData, id: String) -> Array:
	var d := get_deed(id)
	var out := []
	if not is_owned(data, id):
		return out
	var cur := cur_of(id)
	out.append("%s (%s)" % [str(d.name), tier_name(data, id)])
	out.append("Till: %s" % Wallet.fmt(Wallet.localise(till(data, id), cur), cur))
	out.append("Business rates owed: %s" % Wallet.fmt(Wallet.localise(rates_due(data, id), cur), cur))
	var stock := []
	for inp in d.get("inputs", []):
		stock.append("%s %d" % [str(Trade.items().get_item(str(inp.item)).get("name", inp.item)), store_of(data, id, str(inp.item))])
	if not stock.is_empty():
		out.append("Store: " + ", ".join(stock))
	out.append("Manager: %s" % (manager(data, id) if manager(data, id) != "" else "none"))
	return out
