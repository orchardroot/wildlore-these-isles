class_name BuildingSociety
extends RefCounted
## The Macclesfield and District Building Society (data/society.json): a branch in Manchester, Cardiff, Edinburgh and
## Belfast, and a credit union in Dublin that deals in euros. Pat lends with honest compound interest (a fixed monthly
## rate, repaid in equal monthly instalments taken from the purse by themselves), keeps a savings account that pays a
## little on the average balance, and writes through the post box when you fall behind. Mum's sub is a one-off,
## interest-free loan that arrives by post after the first Stone.
## A month is MONTH in-game days. Everything lives in one save flag (`society`) that old saves simply don't have:
## {loan: {cur, owed, pay, bp, term, next, last, missed}, save: {cur: {bal, acc, mark, next}}, mum: {owed, day, nag},
## mail: [letter ids], log: [[day, text]]}. Money only ever moves through Wallet, so nothing here can print it
## (see SocietySim). Pure logic, no autoloads.

const PATH := "res://data/society.json"
const FLAG := "society"
const MONTH := 30
const TERMS := [6, 12, 24]
const MIN_BADGES := 2          # Pat won't lend before the second Stone
const LIMIT_BASE := 500        # pounds, plus LIMIT_PER_BADGE for each Stone
const LIMIT_PER_BADGE := 1500
const MIN_LOAN := 50
const BUS_FARE := 5            # a repayment never takes the last of the purse
const SAVE_CAP_BASE := 2000    # the most that earns interest: this plus the same again for each Stone
const SAVE_CAP_PER_BADGE := 2000
const MUM_SUB := 300
const MUM_NAG_DAYS := 60
const LOG_KEEP := 8
const MAX_CATCH_UP := 240

static var _db: Dictionary = {}

static func db() -> Dictionary:
	if _db.is_empty():
		var d = JsonUtil.read(PATH)
		_db = d if d is Dictionary else {"branches": {}, "rates": {}, "letters": {}, "talk": {}}
	return _db

## The branch behind a zone id ("cardiff_society"), or {}.
static func branch(zone_id: String) -> Dictionary:
	return db().get("branches", {}).get(zone_id, {})

static func talk(key: String) -> String:
	return str(db().get("talk", {}).get(key, ""))

static func letter_ids() -> Array:
	return db().get("letters", {}).keys()

static func letter(id: String) -> Dictionary:
	return db().get("letters", {}).get(id, {})

## What a letter says, as lines for the textbox. With `data`, the envelope carries your name and title (Mr / Ms,
## see Looks.pronoun).
static func letter_lines(id: String, data: GameStateData = null) -> Array:
	var l := letter(id)
	if l.is_empty():
		return []
	var out := ["A letter from %s." % str(l.get("from", "")) if data == null else "A letter from %s, addressed to %s %s." % [str(l.get("from", "")), Looks.pronoun(data, "Mr"), data.player_name]]
	for t in l.get("text", []):
		out.append(str(t))
	return out

static func loan_rate(cur: String) -> float:
	return float(db().get("rates", {}).get(cur, db().get("rates", {}).get("gbp", {})).get("loan", 0.01))

static func save_rate(cur: String) -> float:
	return float(db().get("rates", {}).get(cur, db().get("rates", {}).get("gbp", {})).get("save", 0.002))

# --- the sums --------------------------------------------------------------------------

static func _bp(rate: float) -> int:
	return roundi(rate * 10000.0)

## Interest on `owed` at a monthly `rate` for `days` days, rounded up to the next whole unit: a month is exactly the rate.
static func interest(owed: int, rate: float, days: int) -> int:
	if owed <= 0 or days <= 0:
		return 0
	var den := 10000 * MONTH
	return (owed * _bp(rate) * days + den - 1) / den

## The yearly figure the law makes a lender print: what a year of this monthly rate costs once interest is charged on interest.
static func apr(rate: float) -> float:
	return pow(1.0 + rate, 12.0) - 1.0

static func _payment(principal: int, rate: float, term: int) -> int:
	var pay := int(ceil(float(principal) / term)) if rate <= 0.0 else int(ceil(principal * rate / (1.0 - pow(1.0 + rate, -float(term)))))
	while _months_to_clear(principal, rate, pay) > term:  # interest rounds up to whole units, so nudge to clear in the term
		pay += 1
	return pay

static func _months_to_clear(principal: int, rate: float, pay: int) -> int:
	var owed := principal
	var n := 0
	while owed > 0 and n < 1000:
		owed += interest(owed, rate, MONTH)
		owed -= mini(pay, owed)
		n += 1
	return n

## Every instalment of a loan, month by month, the last one smaller: [pay, pay, ..., last].
static func schedule(principal: int, rate: float, term: int) -> Array:
	var pay := _payment(principal, rate, term)
	var owed := principal
	var out := []
	while owed > 0 and out.size() < term + 1:
		owed += interest(owed, rate, MONTH)
		var p := mini(pay, owed)
		out.append(p)
		owed -= p
	return out

## {payment, total, interest, months}: what Pat shows you before you sign.
static func quote(principal: int, rate: float, term: int) -> Dictionary:
	var s := schedule(principal, rate, term)
	var total := 0
	for p in s:
		total += int(p)
	return {"payment": _payment(principal, rate, term), "total": total, "interest": total - principal, "months": s.size()}

# --- the account in the save ------------------------------------------------------------

static func _i(d: Dictionary, k: String) -> int:
	return int(d.get(k, 0))

## The stored account, created on first use. A save that never visited has no flag and loads exactly as before.
static func _st(data: GameStateData) -> Dictionary:
	var v: Variant = data.flag(FLAG)
	if not (v is Dictionary):
		v = {"loan": {}, "save": {}, "mum": {}, "mail": [], "log": []}
		data.set_flag(FLAG, v)
	var st: Dictionary = v
	for k in ["loan", "save", "mum"]:
		if not (st.get(k) is Dictionary):
			st[k] = {}
	for k in ["mail", "log"]:
		if not (st.get(k) is Array):
			st[k] = []
	return st

static func _peek(data: GameStateData) -> Dictionary:
	var v: Variant = data.flag(FLAG)
	return v if v is Dictionary else {}

static func _note(st: Dictionary, data: GameStateData, text: String) -> void:
	st.log.append([data.day_count, text])
	while st.log.size() > LOG_KEEP:
		st.log.remove_at(0)

static func _mail(st: Dictionary, id: String) -> void:
	if id not in st.mail:
		st.mail.append(id)

static func has_loan(data: GameStateData) -> bool:
	return not (_peek(data).get("loan", {}) as Dictionary).is_empty()

static func loan(data: GameStateData) -> Dictionary:
	return (_peek(data).get("loan", {}) as Dictionary).duplicate()

static func owed(data: GameStateData) -> int:
	return _i(_peek(data).get("loan", {}), "owed")

static func loan_cur(data: GameStateData) -> String:
	return str(_peek(data).get("loan", {}).get("cur", ""))

static func missed(data: GameStateData) -> int:
	return _i(_peek(data).get("loan", {}), "missed")

## Owed today including the days since the last instalment: what clearing it right now costs.
static func payoff(data: GameStateData) -> int:
	var l: Dictionary = _peek(data).get("loan", {})
	if l.is_empty():
		return 0
	return _i(l, "owed") + interest(_i(l, "owed"), loan_rate(str(l.cur)), data.day_count - _i(l, "last"))

static func mum_owed(data: GameStateData) -> int:
	return _i(_peek(data).get("mum", {}), "owed")

static func saved(data: GameStateData, cur: String) -> int:
	return _i(_peek(data).get("save", {}).get(cur, {}), "bal")

static func letters_waiting(data: GameStateData) -> Array:
	return (_peek(data).get("mail", []) as Array).duplicate()

## Purse plus savings less everything owed, in one currency (sterling counts Mum's sub too).
static func net_worth(data: GameStateData, cur: String) -> int:
	var n := Wallet.balance(data, cur) + saved(data, cur)
	if loan_cur(data) == cur:
		n -= payoff(data)
	if cur == Wallet.GBP:
		n -= mum_owed(data)
	return n

## The most Pat will lend you in this money, by how far you've got: nothing before the second Stone.
static func limit(data: GameStateData, cur: String) -> int:
	if data.badges.size() < MIN_BADGES:
		return 0
	return Wallet.localise(LIMIT_BASE + LIMIT_PER_BADGE * data.badges.size(), cur)

static func save_cap(data: GameStateData, cur: String) -> int:
	return Wallet.localise(SAVE_CAP_BASE + SAVE_CAP_PER_BADGE * data.badges.size(), cur)

static func _floor_for(cur: String) -> int:
	return Wallet.localise(BUS_FARE, cur)

# --- loans ------------------------------------------------------------------------------

## Signs for a loan at the branch of `zone_id`. {ok, why}: nothing moves unless ok.
static func borrow(data: GameStateData, zone_id: String, principal: int, term: int) -> Dictionary:
	var b := branch(zone_id)
	if b.is_empty():
		return {"ok": false, "why": "No such branch."}
	var cur := str(b.cur)
	if has_loan(data):
		return {"ok": false, "why": "You've a loan with us already. One at a time, love."}
	var lim := limit(data, cur)
	if lim <= 0:
		return {"ok": false, "why": "Come back when you've a bit more behind you. I lend to folk who've been somewhere."}
	if principal < Wallet.localise(MIN_LOAN, cur) or principal > lim:
		return {"ok": false, "why": "Between %s and %s, love." % [Wallet.fmt(Wallet.localise(MIN_LOAN, cur), cur), Wallet.fmt(lim, cur)]}
	if term not in TERMS:
		return {"ok": false, "why": "Six, twelve or twenty-four months. It's on the board."}
	var st := _st(data)
	var rate := loan_rate(cur)
	st.loan = {"cur": cur, "owed": principal, "pay": _payment(principal, rate, term), "bp": _bp(rate), "term": term,
		"next": data.day_count + MONTH, "last": data.day_count, "missed": 0}
	Wallet.earn(data, principal, cur)
	_note(st, data, "Borrowed %s over %d months" % [Wallet.fmt(principal, cur), term])
	Economist.note(data, "apr")
	return {"ok": true}

## Pays `amount` off the loan (never more than clearing it costs). The days since the last instalment are charged first.
static func repay(data: GameStateData, amount: int) -> Dictionary:
	if not has_loan(data) or amount <= 0:
		return {"ok": false, "paid": 0}
	var st := _st(data)
	var l: Dictionary = st.loan
	var cur := str(l.cur)
	var due := payoff(data)
	var pay := mini(amount, due)
	if not Wallet.spend(data, pay, cur):
		return {"ok": false, "paid": 0}
	l.owed = due - pay
	l.last = data.day_count
	if int(l.owed) <= 0:
		st.loan = {}
		_mail(st, "cleared")
		_note(st, data, "Loan cleared")
	else:
		l.missed = 0 if pay >= _i(l, "pay") else _i(l, "missed")
		_note(st, data, "Paid %s off the loan" % Wallet.fmt(pay, cur))
	return {"ok": true, "paid": pay}

# --- savings ----------------------------------------------------------------------------

static func _roll_account(a: Dictionary, day: int) -> void:
	a.acc = _i(a, "acc") + _i(a, "bal") * (day - _i(a, "mark"))
	a.mark = day

static func deposit(data: GameStateData, cur: String, amount: int) -> bool:
	if amount <= 0 or not Wallet.can_afford(data, amount, cur):
		return false
	var st := _st(data)
	if not st.save.has(cur):
		st.save[cur] = {"bal": 0, "acc": 0, "mark": data.day_count, "next": data.day_count + MONTH}
	var a: Dictionary = st.save[cur]
	_roll_account(a, data.day_count)
	Wallet.spend(data, amount, cur)
	a.bal = _i(a, "bal") + amount
	Economist.note(data, "compound")
	return true

static func withdraw(data: GameStateData, cur: String, amount: int) -> bool:
	var have := saved(data, cur)
	if amount <= 0 or amount > have:
		return false
	var a: Dictionary = _st(data).save[cur]
	_roll_account(a, data.day_count)
	a.bal = have - amount
	Wallet.earn(data, amount, cur)
	return true

# --- Mum --------------------------------------------------------------------------------

## Pays Mum back, as much as you like up to what's owed. No interest, ever.
static func repay_mum(data: GameStateData, amount: int) -> Dictionary:
	var owing := mum_owed(data)
	if owing <= 0 or amount <= 0:
		return {"ok": false, "paid": 0}
	var pay := mini(amount, owing)
	if not Wallet.spend(data, pay, Wallet.GBP):
		return {"ok": false, "paid": 0}
	var st := _st(data)
	st.mum.owed = owing - pay
	_note(st, data, "Paid Mum back %s" % Wallet.fmt(pay))
	return {"ok": true, "paid": pay}

# --- the months go by -------------------------------------------------------------------

## Catches the society up to today: instalments taken (or missed, with a letter), savings interest credited, Mum's sub
## posted after the first Stone. Safe to call as often as you like; Game calls it as each in-game day begins.
static func settle(data: GameStateData) -> void:
	var has_any := data.flag(FLAG) is Dictionary
	if not has_any and data.badges.is_empty():
		return
	var st := _st(data)
	if data.badges.size() >= 1 and not st.mum.has("day"):
		st.mum = {"owed": 0, "day": data.day_count, "nag": false, "sent": true}
		_mail(st, "mum_sub")
	var guard := 0
	while not st.loan.is_empty() and data.day_count >= _i(st.loan, "next") and guard < MAX_CATCH_UP:
		guard += 1
		_instalment(st, data)
	for cur in st.save.keys():
		var a: Dictionary = st.save[cur]
		guard = 0
		while data.day_count >= _i(a, "next") and guard < MAX_CATCH_UP:
			guard += 1
			_roll_account(a, _i(a, "next"))
			var avg := mini(_i(a, "acc") / MONTH, save_cap(data, cur))
			a.bal = _i(a, "bal") + avg * _bp(save_rate(cur)) / 10000
			a.acc = 0
			a.next = _i(a, "next") + MONTH
	if _i(st.mum, "owed") > 0 and not bool(st.mum.get("nag", false)) and data.day_count - _i(st.mum, "day") >= MUM_NAG_DAYS \
			and data.money >= _i(st.mum, "owed") * 2:
		st.mum.nag = true
		_mail(st, "mum_nag")

static func _instalment(st: Dictionary, data: GameStateData) -> void:
	var l: Dictionary = st.loan
	var cur := str(l.cur)
	var rate := float(_i(l, "bp")) / 10000.0
	var due := _i(l, "next")
	l.owed = _i(l, "owed") + interest(_i(l, "owed"), rate, due - _i(l, "last"))
	var pay := mini(_i(l, "pay"), _i(l, "owed"))
	if Wallet.balance(data, cur) >= pay + _floor_for(cur):
		Wallet.spend(data, pay, cur)
		l.owed = _i(l, "owed") - pay
		l.missed = 0
		_note(st, data, "Instalment of %s taken" % Wallet.fmt(pay, cur))
	else:
		l.missed = _i(l, "missed") + 1
		_note(st, data, "Instalment of %s missed" % Wallet.fmt(pay, cur))
		var m := _i(l, "missed")
		if m <= 3:
			_mail(st, "late_%d" % m)
		elif m % 3 == 0:
			_mail(st, "late_3")
	l.last = due
	l.next = due + MONTH
	if _i(l, "owed") <= 0:
		st.loan = {}
		_mail(st, "cleared")
		_note(st, data, "Loan cleared")

## The post waiting at a post box. Takes it out of the queue; Mum's money arrives with her letter.
static func collect_letters(data: GameStateData) -> Array:
	var v: Variant = data.flag(FLAG)
	if not (v is Dictionary) or (v.mail as Array).is_empty():
		return []
	var st := _st(data)
	var got: Array = st.mail.duplicate()
	st.mail = []
	if "mum_sub" in got:
		Wallet.earn(data, MUM_SUB, Wallet.GBP)
		st.mum.owed = _i(st.mum, "owed") + MUM_SUB
		_note(st, data, "Mum sent a sub of %s" % Wallet.fmt(MUM_SUB))
	return got

# --- the statement ----------------------------------------------------------------------

## Plain-English lines for the statement screen, in a steady order.
static func statement(data: GameStateData) -> Array:
	var out := []
	var l := loan(data)
	if l.is_empty():
		out.append("Loan: none.")
	else:
		var cur := str(l.cur)
		var rate := float(_i(l, "bp")) / 10000.0
		out.append("Loan: %s owed, %s a month, %.2f%% a month (%.1f%% APR)." % [Wallet.fmt(payoff(data), cur), Wallet.fmt(_i(l, "pay"), cur), rate * 100.0, apr(rate) * 100.0])
		var days := maxi(0, _i(l, "next") - data.day_count)
		out.append("Next payment in %d day%s%s." % [days, "" if days == 1 else "s", ", and %d missed" % _i(l, "missed") if _i(l, "missed") > 0 else ""])
	for cur in Wallet.CURRENCIES:
		if saved(data, cur) > 0:
			out.append("Savings: %s at %.1f%% a month." % [Wallet.fmt(saved(data, cur), cur), save_rate(cur) * 100.0])
	if mum_owed(data) > 0:
		out.append("Mum's sub: %s still owed. No interest, but she remembers." % Wallet.fmt(mum_owed(data)))
	return out

## The last few entries, newest first, as "day N: text".
static func recent(data: GameStateData) -> Array:
	var out := []
	var log: Array = _peek(data).get("log", [])
	for i in range(log.size() - 1, -1, -1):
		out.append("Day %d: %s" % [int(log[i][0]), str(log[i][1])])
	return out
