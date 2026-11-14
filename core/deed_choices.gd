class_name DeedChoices
extends RefCounted
## Running a Deed is a run of small decisions (wave 55), all of it on top of core/deeds.gd and none of it needed:
##  - UPGRADES (data/deeds/<id>.json "upgrades"): two or three a Deed, bought on top of the tiers, each with a catch
##    (a second fryer eats more fish; a late licence needs a wage; one of a pair shuts out the other).
##  - THE MONTHLY MATTER (data/deed_asks.json and a Deed's own "asks"): once a month something wants an answer (the
##    health inspector, a supplier putting prices up, a coach party, a bad review). Each answer has a price in days of
##    takings and a result that lasts: a spell of better or worse days, and the Deed's name in the town (reputation).
##    Left alone it lapses to the worst answer, unless a manager picks one for you.
##  - A MANAGER'S CHARACTER (data/deed_managers.json): the Regular you appoint is careful, a showman, thrifty, a
##    charmer or steady, and that changes the takings, the stock used, how bad days bite, and what they answer.
## State is more keys in the Deed's own flag, all absent on an old save (and then nothing changes):
##   ups [ids bought], ask {id, day}, next_ask day, mods [[until_day, mult]], rep -5..5, last_ask id
## All sums are STERLING whole pounds, like Deeds. Pure logic, no autoloads.

const ASKS_PATH := "res://data/deed_asks.json"
const MANAGERS_PATH := "res://data/deed_managers.json"
const ASK_EVERY := 30          # in-game days between matters (a month)
const ASK_JITTER := 6          # the date wobbles by this many days either side, seeded
const ASK_WINDOW := 10         # days to answer before it lapses
const MANAGED_WINDOW := 3      # a manager answers on the third day, so you can still step in
const REP_CAP := 5
const REP_STEP := 0.01         # each point of reputation moves takings by this much
const MODS_KEEP := 8
const SHIELD_FLOOR := -0.5
const SHIELD_CEIL := 0.8
const IGNORE := "ignore"

static var _asks: Array = []
static var _nouns: Dictionary = {}
static var _mgr: Dictionary = {}

static func reset() -> void:
	_asks = []
	_nouns = {}
	_mgr = {}

static func _load_asks() -> void:
	if _asks.is_empty():
		var raw: Variant = JsonUtil.read(ASKS_PATH)
		if raw is Dictionary:
			_asks = raw.get("asks", [])
			_nouns = raw.get("nouns", {})

static func shared_asks() -> Array:
	_load_asks()
	return _asks

static func _i(d: Dictionary, k: String) -> int:
	return int(d.get(k, 0))

# --- upgrades ---------------------------------------------------------------------------------

static func upgrades(deed_id: String) -> Array:
	var u: Variant = Deeds.get_deed(deed_id).get("upgrades", [])
	return u if u is Array else []

static func get_upgrade(deed_id: String, up_id: String) -> Dictionary:
	for u in upgrades(deed_id):
		if str(u.id) == up_id:
			return u
	return {}

static func owned_ups(data: GameStateData, id: String) -> Array:
	var v: Variant = Deeds.state(data, id).get("ups", [])
	return v if v is Array else []

static func has(data: GameStateData, id: String, up_id: String) -> bool:
	return owned_ups(data, id).has(up_id)

## An upgrade's price: the data's figure, grown with the badge band as the Deed is (so the late ones stay a sink) and
## with inflation.
static func cost(data: GameStateData, id: String, up: Dictionary) -> int:
	return roundi(float(up.get("cost", 0)) * Deeds.inflation(data) * Deeds.band_scale(data))

## "" when it can be bought, else a friendly reason.
static func why_not(data: GameStateData, id: String, up_id: String) -> String:
	var up := get_upgrade(id, up_id)
	if up.is_empty():
		return "There's no such thing."
	if not Deeds.is_owned(data, id):
		return "You don't own it."
	if has(data, id, up_id):
		return "Already done."
	if Deeds.tier_of(data, id) < int(up.get("tier", 0)):
		return "Not until the place is a bit grander (%s first)." % str(Deeds.get_deed(id).tiers[int(up.tier)].name)
	var g := str(up.get("group", ""))
	if g != "":
		for o in upgrades(id):
			if str(o.get("group", "")) == g and str(o.id) != up_id and has(data, id, str(o.id)):
				return "You chose %s instead, and you can't have both." % str(o.name)
	return ""

## Pays for an upgrade. "" or a reason.
static func buy(data: GameStateData, id: String, up_id: String) -> String:
	var why := why_not(data, id, up_id)
	if why != "":
		return why
	var up := get_upgrade(id, up_id)
	var c := cost(data, id, up)
	var cur := Deeds.cur_of(id)
	if not Wallet.spend(data, Wallet.localise(c, cur), cur):
		return "You'd need %s for that." % Wallet.fmt(Wallet.localise(c, cur), cur)
	var st := Deeds.books(data, id)
	(st.ups as Array).append(up_id)
	st.paid = _i(st, "paid") + c
	return ""

## What an upgrade means in a line, for the screen: the good first, then the catch.
static func describe(up: Dictionary) -> String:
	var good := []
	var bad := []
	var t := float(up.get("takings", 1.0))
	if t > 1.0:
		good.append("takings +%d%%" % roundi((t - 1.0) * 100.0))
	elif t < 1.0:
		bad.append("takings -%d%%" % roundi((1.0 - t) * 100.0))
	var r := float(up.get("rates", 0.0))
	if r < 0.0:
		good.append("rates down %d points" % roundi(-r * 100.0))
	elif r > 0.0:
		bad.append("rates up %d points" % roundi(r * 100.0))
	var s := float(up.get("shield", 0.0))
	if s > 0.0:
		good.append("bad days bite less")
	elif s < 0.0:
		bad.append("bad days bite harder")
	if float(up.get("boom", 0.0)) > 0.0:
		good.append("good days go further")
	if int(up.get("carry", 0)) > 0:
		good.append("the till fills %d days longer while you're away" % int(up.carry))
	var u := float(up.get("use", 1.0))
	if u > 1.0:
		bad.append("uses %d%% more stock" % roundi((u - 1.0) * 100.0))
	elif u < 1.0:
		good.append("uses %d%% less stock" % roundi((1.0 - u) * 100.0))
	if float(up.get("upkeep", 0.0)) > 0.0:
		bad.append("%d a day to run" % int(up.upkeep))
	return "%s. The catch: %s." % [", ".join(good).capitalize() if not good.is_empty() else "A steadier life", ", ".join(bad) if not bad.is_empty() else "the price"]

# --- managers ---------------------------------------------------------------------------------

static func _managers() -> Dictionary:
	if _mgr.is_empty():
		var raw: Variant = JsonUtil.read(MANAGERS_PATH)
		_mgr = raw if raw is Dictionary else {"temperaments": {}, "order": []}
	return _mgr

static func temperaments() -> Dictionary:
	return _managers().get("temperaments", {})

## The temperament id for a Regular: an explicit "assign" entry, else a stable pick from the letters of their id.
static func temper_of(reg_id: String) -> String:
	var m := _managers()
	var a: Variant = m.get("assign", {})
	if a is Dictionary and a.has(reg_id):
		return str(a[reg_id])
	var order: Array = m.get("order", [])
	if order.is_empty():
		return ""
	var n := 0
	for i in reg_id.length():
		n = (n * 31 + reg_id.unicode_at(i)) % 100003
	return str(order[n % order.size()])

## What a manager is like on this Deed: {} when there is none. Keys: temper, label, bonus, use, shield, boom, carry,
## style, cost, rep, local (knows the town), stock (knows the goods), blurb, notes.
static func manager_traits(data: GameStateData, id: String) -> Dictionary:
	var reg_id := Deeds.manager(data, id)
	if reg_id == "":
		return {}
	var r := Regulars.get_reg(reg_id)
	var t: Dictionary = temperaments().get(temper_of(reg_id), {}) if not r.is_empty() else {}   # someone who is not a Regular is just a manager
	var out := {"reg": reg_id, "temper": temper_of(reg_id) if not t.is_empty() else "", "label": str(t.get("label", "a safe pair of hands")),
		"bonus": float(t.get("bonus", Deeds.MANAGER_BONUS)), "use": float(t.get("use", 1.0)), "shield": float(t.get("shield", 0.0)),
		"boom": float(t.get("boom", 0.0)), "carry": int(t.get("carry", 0)), "style": str(t.get("style", "safe")),
		"cost": float(t.get("cost", 1.0)), "rep": int(t.get("rep", 0)), "blurb": str(t.get("blurb", "")), "local": false, "stock": false}
	var deed := Deeds.get_deed(id)
	if not r.is_empty() and (str(r.get("home", "")) == str(deed.get("zone", "")) or str(r.get("away", "")) == str(deed.get("zone", ""))):
		out.local = true
		out.bonus = float(out.bonus) + 0.03
	for inp in deed.get("inputs", []):
		if str(inp.item) == str(r.get("likes", "-")):
			out.stock = true
			out.bonus = float(out.bonus) + 0.02
			out.use = float(out.use) * 0.9
	if Regulars.favour(data, reg_id) >= Regulars.MAX_FAVOUR:
		out.bonus = float(out.bonus) + 0.02
	return out

## What a Regular would be like in charge of a Deed, in a line, before they are appointed.
static func character_line(reg_id: String) -> String:
	var r := Regulars.get_reg(reg_id)
	var t: Dictionary = temperaments().get(temper_of(reg_id), {})
	if r.is_empty() or t.is_empty():
		return ""
	return "%s would be %s. %s" % [Regulars.short_name(r), str(t.label), str(t.blurb)]

## The manager's character in a few plain lines, for the counter and for the offer scene.
static func manager_lines(traits: Dictionary, name: String) -> Array:
	var out := []
	if traits.is_empty():
		return out
	out.append("%s is %s. %s" % [name, str(traits.label), str(traits.blurb)])
	if bool(traits.local):
		out.append("They know the town, and the town knows them: a little extra on the takings.")
	if bool(traits.stock):
		out.append("They know the goods and waste less of them.")
	return out

# --- the sum of it all ------------------------------------------------------------------------

## Everything that bends this Deed's days, from the upgrades and the manager together:
## takings (a multiplier, the manager's bonus included), use, rates (added to the Deed's rate), shield (how much of a bad
## day's loss is avoided; negative makes it worse), boom (how much more a good day gives), carry (extra unattended days),
## upkeep (sterling a day). Nothing bought and nobody managing gives the plain numbers.
static func fx(data: GameStateData, id: String) -> Dictionary:
	var f := {"takings": 1.0, "use": 1.0, "rates": 0.0, "shield": 0.0, "boom": 0.0, "carry": 0, "upkeep": 0.0}
	for up_id in owned_ups(data, id):
		_fold(f, get_upgrade(id, str(up_id)))
	_fold(f, TownProjects.deed_fx(data, id))   # what the town's finished projects give the Deeds there
	var m := manager_traits(data, id)
	if not m.is_empty():
		f.takings = float(f.takings) * float(m.bonus)
		f.use = float(f.use) * float(m.use)
		f.shield = float(f.shield) + float(m.shield)
		f.boom = float(f.boom) + float(m.boom)
		f.carry = int(f.carry) + int(m.carry)
	f.shield = clampf(float(f.shield), SHIELD_FLOOR, SHIELD_CEIL)
	return f

static func _fold(f: Dictionary, up: Dictionary) -> void:
	f.takings = float(f.takings) * float(up.get("takings", 1.0))
	f.use = float(f.use) * float(up.get("use", 1.0))
	f.rates = float(f.rates) + float(up.get("rates", 0.0))
	f.shield = float(f.shield) + float(up.get("shield", 0.0))
	f.boom = float(f.boom) + float(up.get("boom", 0.0))
	f.carry = int(f.carry) + int(up.get("carry", 0))
	f.upkeep = float(f.upkeep) + float(up.get("upkeep", 0.0))

## The fx of a Deed with the given upgrades and a manager of the given temperament (or ""), for the simulations: the
## typical figures with no local or stock bonus.
static func fx_for(deed_id: String, up_ids: Array, temper: String) -> Dictionary:
	var f := {"takings": 1.0, "use": 1.0, "rates": 0.0, "shield": 0.0, "boom": 0.0, "carry": 0, "upkeep": 0.0}
	for u in up_ids:
		_fold(f, get_upgrade(deed_id, str(u)))
	if temper != "":
		var t: Dictionary = temperaments().get(temper, {})
		f.takings = float(f.takings) * float(t.get("bonus", Deeds.MANAGER_BONUS))
		f.use = float(f.use) * float(t.get("use", 1.0))
		f.shield = float(f.shield) + float(t.get("shield", 0.0))
		f.boom = float(f.boom) + float(t.get("boom", 0.0))
		f.carry = int(f.carry) + int(t.get("carry", 0))
	return f

## Units a day uses of an input with this multiplier: more stock means at least the plain figure, less means at
## least one.
static func use_of(per_day: int, use: float) -> int:
	if use >= 1.0:
		return maxi(per_day, roundi(float(per_day) * use))
	return maxi(1, mini(per_day, roundi(float(per_day) * use)))

## A day's event multiplier bent by shield and boom.
static func bend(mult: float, shield: float, boom: float) -> float:
	if mult < 1.0:
		return clampf(mult + (1.0 - mult) * shield, 0.0, 1.0) if shield >= 0.0 else maxf(0.0, mult + (1.0 - mult) * shield)
	if mult > 1.0:
		return mult + (mult - 1.0) * boom
	return mult

## The reputation and the spells of better or worse days, as one multiplier for day `dd`.
static func day_mult(st: Dictionary, dd: int) -> float:
	var m := 1.0 + REP_STEP * float(clampi(_i(st, "rep"), -REP_CAP, REP_CAP))
	var mods: Variant = st.get("mods")
	if mods is Array:
		for e in mods:
			if dd < int(e[0]):
				m *= float(e[1])
	return m

static func reputation(data: GameStateData, id: String) -> int:
	return clampi(_i(Deeds.state(data, id), "rep"), -REP_CAP, REP_CAP)

# --- the monthly matter -----------------------------------------------------------------------

static func _text(s: String, deed: Dictionary) -> String:
	var n: Dictionary = _nouns
	var kind := str(deed.get("kind", ""))
	var out := s.replace("{deed}", str(deed.get("name", "the place")))
	for k in n:
		out = out.replace("{%s}" % k, str(n[k].get(kind, k)))
	return out

## Every matter that can come up at this Deed: the shared ones for its kind and its own.
static func pool(deed: Dictionary) -> Array:
	_load_asks()
	var out := []
	for a in _asks:
		var kinds: Array = a.get("kinds", [])
		if kinds.is_empty() or kinds.has(str(deed.get("kind", ""))):
			out.append(a)
	var own: Variant = deed.get("asks", [])
	if own is Array:
		out.append_array(own)
	return out

static func get_ask(deed: Dictionary, ask_id: String) -> Dictionary:
	for a in pool(deed):
		if str(a.id) == ask_id:
			return a
	return {}

## A matter's title, words and answers with the Deed's own nouns in them.
static func shown(deed: Dictionary, ask: Dictionary) -> Dictionary:
	var out := {"id": str(ask.get("id", "")), "title": _text(str(ask.get("title", "")), deed), "text": _text(str(ask.get("text", "")), deed), "options": []}
	for o in ask.get("options", []):
		var c: Dictionary = o.duplicate(true)
		c["label"] = _text(str(o.get("label", "")), deed)
		c["say"] = _text(str(o.get("say", "")), deed)
		if c.get("risk") is Dictionary:
			c.risk["say"] = _text(str(c.risk.get("say", "")), deed)
		out.options.append(c)
	return out

static func _roll(data: GameStateData, id: String, day: int, salt: String) -> float:
	return float(absi(hash("%d:%s:%d:%s" % [data.rng_seed, id, day, salt])) % 10000) / 10000.0

## The matter waiting at a Deed: {ask (shown), day, left (days to answer)} or {}.
static func pending(data: GameStateData, id: String, today := -1) -> Dictionary:
	var a: Variant = Deeds.state(data, id).get("ask")
	if not (a is Dictionary) or (a as Dictionary).is_empty():
		return {}
	var deed := Deeds.get_deed(id)
	var raw := get_ask(deed, str(a.get("id", "")))
	if raw.is_empty():
		return {}
	var day := int(a.get("day", 0))
	var t := data.day_count if today < 0 else today
	return {"ask": shown(deed, raw), "day": day, "left": maxi(0, day + _window(data, id) - t)}

static func _window(data: GameStateData, id: String) -> int:
	return MANAGED_WINDOW if Deeds.manager(data, id) != "" else ASK_WINDOW

## Quiet-day takings, the price of an answer is counted in.
static func _day_gbp(data: GameStateData, id: String) -> float:
	return float(Deeds.daily_estimate(data, id))

static func option_cost(data: GameStateData, id: String, opt: Dictionary, frugal := 1.0) -> int:
	return roundi(float(opt.get("cost", 0.0)) * _day_gbp(data, id) * frugal)

## Players answer here. "" or a reason; the price comes out of the purse.
static func answer(data: GameStateData, id: String, opt_id: String) -> String:
	var p := pending(data, id)
	if p.is_empty():
		return "Nothing needs an answer."
	var deed := Deeds.get_deed(id)
	var opt := {}
	for o in p.ask.options:
		if str(o.id) == opt_id:
			opt = o
	if opt.is_empty():
		return "That isn't one of the answers."
	var c := option_cost(data, id, opt)
	var cur := Deeds.cur_of(id)
	if c > 0 and not Wallet.spend(data, Wallet.localise(c, cur), cur):
		return "You'd need %s for that." % Wallet.fmt(Wallet.localise(c, cur), cur)
	var st := Deeds.books(data, id)
	_settle(data, st, deed, p.ask, opt, data.day_count, "You")
	st.erase("ask")
	return ""

## The outcome (risk rolled), recorded, with its effects. Returns the line.
static func _settle(data: GameStateData, st: Dictionary, deed: Dictionary, ask: Dictionary, opt: Dictionary, day: int, _by: String) -> String:
	var id := str(deed.id)
	var out: Dictionary = opt
	var say := str(opt.get("say", ""))
	var r: Variant = opt.get("risk")
	if r is Dictionary and _roll(data, id, day, "risk" + str(ask.id)) < float(r.get("chance", 0.0)):
		out = r
		say = str(r.get("say", say))
	var mult := float(out.get("mult", 1.0))
	var days := int(out.get("days", 0))
	if mult != 1.0 and days > 0:
		var mods: Array = st.get("mods", [])
		mods.append([day + days, mult])
		while mods.size() > MODS_KEEP:
			mods.remove_at(0)
		st["mods"] = mods
	st["rep"] = clampi(_i(st, "rep") + int(out.get("rep", 0)), -REP_CAP, REP_CAP)
	st["last_ask"] = str(ask.id)
	st["asked"] = _i(st, "asked") + 1
	Deeds.note(st, day, "%s: %s" % [str(ask.get("title", "")), say])
	return say

## Picks the answer a manager (or the lapse of time) gives: the manager's style, else the safe one; no manager, the
## one tagged "ignore".
static func default_pick(ask: Dictionary, style: String) -> Dictionary:
	var opts: Array = ask.get("options", [])
	if style == "":
		for o in opts:
			if str(o.get("tag", "")) == IGNORE:
				return o
		return opts[opts.size() - 1]
	for tag in [style, "safe", "frugal"]:
		for o in opts:
			if str(o.get("tag", "")) == tag:
				return o
	return opts[0]

# --- the days go by (called from Deeds.tick) ----------------------------------------------------

## One day at a Deed: spells expire on their own (day_mult), a matter lapses or is answered by the manager, a new
## one is posted when its month comes round, a charmer builds the name. Returns lines for the wireless.
static func daily(data: GameStateData, deed: Dictionary, st: Dictionary, dd: int) -> Array:
	var lines := []
	var id := str(deed.id)
	var mods: Variant = st.get("mods")
	if mods is Array and not (mods as Array).is_empty() and int(mods[0][0]) <= dd:
		st["mods"] = (mods as Array).filter(func(e): return dd < int(e[0]))
	var a: Variant = st.get("ask")
	if a is Dictionary and not (a as Dictionary).is_empty():
		var traits := manager_traits(data, id)
		var window := MANAGED_WINDOW if not traits.is_empty() else ASK_WINDOW
		if dd >= int(a.get("day", 0)) + window:
			var raw := get_ask(deed, str(a.get("id", "")))
			if not raw.is_empty():
				var ask := shown(deed, raw)
				var opt := default_pick(ask, str(traits.get("style", "")) if not traits.is_empty() else "")
				var c := roundi(float(opt.get("cost", 0.0)) * _day_gbp(data, id) * float(traits.get("cost", 1.0)))
				st["till"] = maxi(0, _i(st, "till") - c)
				var who := "The manager" if not traits.is_empty() else "Nobody"
				var say := _settle(data, st, deed, ask, opt, dd, who)
				lines.append("%s: %s" % [str(deed.name), say])
			st.erase("ask")
		return lines
	if _i(st, "next_ask") <= 0:
		st["next_ask"] = dd + 8 + int(_roll(data, id, dd, "first") * float(ASK_EVERY - 8))   # an old save's first matter is not today
		return lines
	if dd >= _i(st, "next_ask"):
		var pick := _pick(data, deed, st, dd)
		var jitter := int(_roll(data, id, dd, "gap") * float(ASK_JITTER * 2 + 1)) - ASK_JITTER
		st["next_ask"] = dd + ASK_EVERY + jitter
		if not pick.is_empty():
			st["ask"] = {"id": str(pick.id), "day": dd}
			Deeds.post_ask(data, id, dd, _text(str(pick.get("title", "")), deed))
		var traits2 := manager_traits(data, id)
		if int(traits2.get("rep", 0)) > 0 and _i(st, "rep") < 3:
			st["rep"] = _i(st, "rep") + int(traits2.rep)
	return lines

static func _pick(data: GameStateData, deed: Dictionary, st: Dictionary, dd: int) -> Dictionary:
	var season := Calendar.season_for(((dd / Deeds.MONTH) % 12) + 1, 1)
	var opts := []
	var weight := 0.0
	for a in pool(deed):
		var want := str(a.get("season", ""))
		if (want != "" and want != season) or str(a.id) == str(st.get("last_ask", "")):
			continue
		var w := 2.0 if a.has("deed") or deed.get("asks", []).has(a) else 1.0
		opts.append([a, w])
		weight += w
	if opts.is_empty():
		return {}
	var roll := _roll(data, str(deed.id), dd, "ask") * weight
	for e in opts:
		roll -= float(e[1])
		if roll < 0.0:
			return e[0]
	return opts[opts.size() - 1][0]

# --- for the simulations ------------------------------------------------------------------------

## What answering this Deed's matters is worth on a day with the best answer each time, as sterling per in-game day:
## the price comes off, the spell of better or worse days comes on. A matter handled well should be near break-even
## or a little better; one ignored costs. `temper` "" means a player answering by hand.
static func ask_net_per_day(data: GameStateData, id: String, best := true) -> float:
	var deed := Deeds.get_deed(id)
	var day := _day_gbp(data, id)
	var p := pool(deed)
	if p.is_empty() or day <= 0.0:
		return 0.0
	var total := 0.0
	for a in p:
		var pick := -INF
		var worst := INF
		for o in a.get("options", []):
			var v := option_value(o, day)
			pick = maxf(pick, v)
			worst = minf(worst, v)
		total += pick if best else worst
	return total / float(p.size()) / float(ASK_EVERY)

## One answer's worth in sterling: spells of better or worse days less the price; a rolled risk is its expectation.
static func option_value(opt: Dictionary, day_gbp: float) -> float:
	var v := _outcome_value(opt, day_gbp)
	var r: Variant = opt.get("risk")
	if r is Dictionary:
		var ch := float(r.get("chance", 0.0))
		v = (1.0 - ch) * v + ch * _outcome_value(r, day_gbp)
	return v - float(opt.get("cost", 0.0)) * day_gbp

static func _outcome_value(out: Dictionary, day_gbp: float) -> float:
	return (float(out.get("mult", 1.0)) - 1.0) * float(out.get("days", 0)) * day_gbp

# --- checks for the validator -----------------------------------------------------------------------------------

## Problems in the Deed upgrades, the monthly matters and the manager temperaments: shape, ids, a way out of every
## matter, and no em-dashes in anything a player reads.
static func problems(_items: ItemDB) -> Array:
	var errs := []
	var tags := ["safe", "bold", "frugal", IGNORE]
	_load_asks()
	var every: Array = _asks.duplicate()
	for deed in Deeds.all():
		var did := str(deed.id)
		var seen := {}
		var groups := {}
		var ups := upgrades(did)
		if ups.size() < 2 or ups.size() > 4:
			errs.append("deed %s: wants two to four upgrades" % did)
		for u in ups:
			var uid := str(u.get("id", ""))
			if uid == "" or seen.has(uid):
				errs.append("deed %s: upgrade with a missing or duplicate id" % did)
			seen[uid] = true
			for k in ["name", "text"]:
				if str(u.get(k, "")).strip_edges() == "":
					errs.append("deed %s upgrade %s: no %s" % [did, uid, k])
			if int(u.get("cost", 0)) <= 0:
				errs.append("deed %s upgrade %s: no cost" % [did, uid])
			if int(u.get("tier", 0)) >= (deed.tiers as Array).size():
				errs.append("deed %s upgrade %s: needs a tier the Deed does not have" % [did, uid])
			var g := str(u.get("group", ""))
			if g != "":
				groups[g] = int(groups.get(g, 0)) + 1
			var bends := float(u.get("takings", 1.0)) > 1.0 or float(u.get("shield", 0.0)) > 0.0 or float(u.get("boom", 0.0)) > 0.0 \
				or float(u.get("rates", 0.0)) < 0.0 or int(u.get("carry", 0)) > 0 or float(u.get("use", 1.0)) < 1.0
			if not bends:
				errs.append("deed %s upgrade %s: does nothing good" % [did, uid])
		for g in groups:
			if int(groups[g]) < 2:
				errs.append("deed %s: group '%s' has only one upgrade in it" % [did, g])
		var own: Variant = deed.get("asks", [])
		if own is Array:
			every.append_array(own)
	for a in every:
		var aid := str(a.get("id", ""))
		var tag := "deed matter '%s': " % aid
		if aid == "":
			errs.append("a deed matter has no id")
		for k in ["title", "text"]:
			if str(a.get(k, "")).strip_edges() == "":
				errs.append(tag + "no " + k)
		var opts: Array = a.get("options", [])
		var has_ignore := false
		var oids := {}
		if opts.size() < 3 or opts.size() > 4:
			errs.append(tag + "wants three or four answers")
		for o in opts:
			var oid := str(o.get("id", ""))
			if oid == "" or oids.has(oid):
				errs.append(tag + "an answer with a missing or duplicate id")
			oids[oid] = true
			if not tags.has(str(o.get("tag", ""))):
				errs.append(tag + "answer %s has tag '%s'" % [oid, o.get("tag", "")])
			has_ignore = has_ignore or str(o.get("tag", "")) == IGNORE
			if str(o.get("label", "")).strip_edges() == "" or str(o.get("say", "")).strip_edges() == "":
				errs.append(tag + "answer %s has no label or no words" % oid)
			if float(o.get("cost", 0.0)) < 0.0 or float(o.get("cost", 0.0)) > 3.0:
				errs.append(tag + "answer %s costs an odd number of days" % oid)
			if absf(float(o.get("mult", 1.0)) - 1.0) > 0.8 or int(o.get("days", 0)) > 40:
				errs.append(tag + "answer %s bends the takings too far" % oid)
		if not has_ignore:
			errs.append(tag + "no answer tagged ignore, so no way for it to lapse")
		if "—" in JSON.stringify(a):
			errs.append(tag + "has an em-dash")
	for k in temperaments():
		var t: Dictionary = temperaments()[k]
		if not ["safe", "bold", "frugal"].has(str(t.get("style", ""))):
			errs.append("manager temperament %s: unknown style" % k)
		if str(t.get("label", "")).strip_edges() == "" or str(t.get("blurb", "")).strip_edges() == "":
			errs.append("manager temperament %s: no label or blurb" % k)
	for k in _managers().get("order", []):
		if not temperaments().has(str(k)):
			errs.append("manager order names '%s', which is not a temperament" % k)
	if "—" in JSON.stringify(_managers()):
		errs.append("data/deed_managers.json has an em-dash")
	return errs
