class_name EconomySim
extends RefCounted
## The whole economy on one page: plays every way of making money together over a long career (the Deeds, the Trade
## Ledger, cooking, jobs and the daily purses, stud fees, racing, shares, the Building Society, the casino) against
## everything money can buy (charms, the pannier, Deed tiers, leases and their stages), and reports who earned what and
## when the big purchases land. It reads the REAL numbers (Jobs.money_for, Deeds, DeedsSim, Trade, Punt, Racing, Stud,
## Leases ...) and leaves only the player's habits as assumptions, all named below. A MarketSim-style harness: the test
## (tests/core/test_economy.gd) pins the shape, tools/dev/economy_sim.gd prints it, docs/design/economy.md explains it.
## Habits are generous on purpose (a perfect, diligent player), so a ceiling that holds here holds for everyone. Pure
## logic, no autoloads.

const DAYS := 360             # a year of in-game days; the story ends about day 90 (MarketSim.STORY_DAYS)
const STORY_END := 90
const DAYS_PER_BADGE := 8     # as MarketSim: all ten badges by day 80
const PLAY_EVERY := 3         # a "real day" of play every this many in-game days (a game day is 24 minutes)
const STRATEGIES := ["dailies", "deed_rush", "trader", "cook", "casino", "everything"]

# --- the player's habits (all generous) ---
const JOBS_PER_PLAY := 4      # noticeboard jobs handed in per real day, the best-paying half of what is eligible
const QUIZ_PUBS := 2          # pub quizzes per real day, answering 70% right
const QUIZ_P := 0.7
const DARTS_PUBS := 2
const NOVICE_P := [0.25, 0.2, 0.15]   # chance of first, second, third in the daily novice race (your creature runs)
const SUPPLY := 0.85          # share of days a Deed's store is actually full (you have to carry the stock)
const DISHES_PER_PLAY := 8    # dishes cooked and sold per real day (foraging is the limit)
const EXPLORED := 0.5         # share of Visitors' Book towns you ever finish
const BADGES_FOR_STUD := 2
const BADGES_FOR_MANAGER := 3
const LEASE_BADGES := 10      # the Enclosure sells off its leases after the credits
const LEASE_BID := 1.25       # a winning bid over the reserve
const CHARM_CAP := 12         # charms you bother to buy: a party and spares
const PAYBACK_MAX := 60.0     # days a Deed purchase may take to pay back and still be bought
const CASINO_BETS := 10       # even-money roulette bets a visit, the limit split between them

static func badges_at(day: int) -> int:
	return clampi(day / DAYS_PER_BADGE, 0, 10)

static func _state(day: int) -> GameStateData:
	var d := GameStateData.new()
	d.day_count = day
	for i in badges_at(day):
		d.badges.append("b%d" % i)
	return d

# --- the daily purses and jobs (sterling per real day, at a badge count) ---

static func jobs_pay(badges: int) -> float:
	var pays := []
	for j in Jobs.all():
		if int(j.get("badges", 0)) <= badges:
			pays.append(Jobs.money_for(j, badges))
	if pays.is_empty():
		return 0.0
	pays.sort()
	pays.reverse()
	var top := pays.slice(0, maxi(1, pays.size() / 2))
	var sum := 0.0
	for p in top:
		sum += float(p)
	return JOBS_PER_PLAY * sum / top.size()

static func _binom(n: int, k: int, p: float) -> float:
	var c := 1.0
	for i in k:
		c = c * float(n - i) / float(i + 1)
	return c * pow(p, k) * pow(1.0 - p, n - k)

static func quiz_pay() -> float:
	var ev := 0.0
	for score in range(0, 6):
		var pr: Dictionary = PubQuiz.prize(score)
		var v := float(pr.money)
		if str(pr.item) != "":
			v += float(Trade.base_price(str(pr.item))) * 0.5   # sold back at the corner shop
		ev += _binom(5, score, QUIZ_P) * v
	return QUIZ_PUBS * ev

static func show_pay() -> float:
	var ev := 0.0
	for cls in [ShowClasses.PRODUCE, ShowClasses.DOG, ShowClasses.BREED]:
		for p in range(1, 4):
			ev += 0.25 * float(ShowClasses.prize(cls, p).money)
	return ev

static func novice_pay(badges: int) -> float:
	if badges < 1:
		return 0.0
	var ev := 0.0
	for i in 3:
		ev += float(NOVICE_P[i]) * Racing.novice_prize(i + 1, badges)
	return ev

static func stud_pay(badges: int) -> float:
	if badges < BADGES_FOR_STUD:
		return 0.0
	return Stud.fee(_state(badges * DAYS_PER_BADGE)) * Stud.STUD_OUT_SHARE

## Everything that pays once a real day without a stake, per real day.
static func dailies(badges: int) -> Dictionary:
	return {"jobs": jobs_pay(badges), "quiz": quiz_pay(), "crossword": float(Crossword.PRIZE), "novice_race": novice_pay(badges),
		"stud": stud_pay(badges), "shows": show_pay(), "darts": float(DARTS_PUBS * Darts.DAILY_PURSE),
		"bowls": float(Bowls.DAILY_PURSE), "skims": float(Skimming.DAILY_PURSE)}

## Once-only lumps: the Gazetteer's milestones, the Visitors' Book, the quiz league. Paid as the badges come in.
static func lump_total() -> float:
	var t := 0.0
	for m in Gazetteer.MILESTONES:
		t += float(m.money)
	t += float(VisitorsBook.MONEY) * ZoneIndex.get_index().get("town_rooms", {}).size() * EXPLORED
	var ql := QuizLeague.cfg()
	t += float(ql.get("title_prize", 0)) * 3 + float(ql.get("cup_prize", 0))
	return t

# --- the Trade Ledger ---

static func _sell_unit(base: int, reg: float, dem: float, glut: float) -> int:
	return maxi(1, int(base * 0.5 * reg * dem * glut))

## Profit of one load of a good a SHOP sells (the only kind you can buy low: dishes and fish are made or caught, not
## stocked), carried from the region where it is cheap to one that wants it and sold across `towns` towns, each town's
## glut building as you sell. Almost nothing is both stocked and listed, which is why the Ledger is hard to tap.
static func shop_run(item_id: String, cap: int, demand: float, towns := 3) -> int:
	var c := Trade.config()
	var base := Trade.base_price(item_id)
	var buy := maxi(1, int(round(base * float(c.get("home_factor", 0.6)))))
	var reg := float(c.get("wants_factor", 1.8))
	var step := float(c.get("glut_step", 0.92))
	var glut := []
	for t in towns:
		glut.append(1.0)
	var profit := 0
	for n in cap:
		var bt := 0
		for t in towns:
			if float(glut[t]) > float(glut[bt]):
				bt = t
		var v := _sell_unit(base, reg, demand, float(glut[bt]))
		if v <= buy:
			break
		profit += v - buy
		glut[bt] = float(glut[bt]) * step
	return profit

## Trade goods a shop stocks that the Ledger prices regionally, with what a full load clears at the festival cap.
static func shop_runs() -> Dictionary:
	var out := {}
	var stocked := shop_goods()
	for id in Trade.config().get("goods", {}):
		if stocked.has(str(id)):
			out[str(id)] = shop_run(str(id), 99, float(Trade.config().get("demand_cap", 1.8)))
	return out

## Dishes cooked from forage and sold: DISHES_PER_PLAY units into one town a real day. `haul` sends them to a region
## that wants them (a train fare away, with the demand of a season in hand); otherwise wherever you happen to be.
static func dish_pay(haul := false) -> float:
	var bases := []
	for r in Crafting.all():
		if str(Trade.items().get_item(str(r.out)).get("kind", "")) == "meal":
			bases.append(Trade.base_price(str(r.out)) * int(r.get("n", 1)))
	if bases.is_empty():
		return 0.0
	var sum := 0.0
	for b in bases:
		sum += float(b)
	var base := int(sum / bases.size())
	var step := float(Trade.config().get("glut_step", 0.92))
	var reg := float(Trade.config().get("wants_factor", 1.8)) if haul else 1.0
	var dem := 1.15 if haul else 1.0
	var glut := 1.0
	var total := 0.0
	for i in DISHES_PER_PLAY:
		total += _sell_unit(base, reg, dem, glut)
		glut *= step
	return total

# --- crafting loops ---

## Item ids any shop stocks.
static func shop_goods() -> Dictionary:
	var out := {}
	for sid in Trade.items().shops:
		for id in Trade.items().shops[sid].get("stock", []):
			out[str(id)] = true
	return out

## Recipes made wholly of things a shop sells, whose output sells back (at the corner shop's half price, before any
## regional or seasonal uplift) for more than the ingredients cost at the cheapest shop with the best standing discount.
## Such a recipe is a money tap: buy, craft, sell, repeat. [{id, cost, sale}]
static func recipe_loops() -> Array:
	var buyable := shop_goods()
	var out := []
	for r in Crafting.all():
		var cost := float(r.get("money", 0))
		var all_shop := true
		for k in r["in"]:
			if not buyable.has(str(k)):
				all_shop = false
				break
			cost += DeedsSim.cheapest_buy(str(k)) * int(r["in"][k]) * (1.0 - float(Standing.DISCOUNT[Standing.DISCOUNT.size() - 1]))
		if not all_shop:
			continue
		var sale := float(int(r.get("n", 1)) * int(Trade.base_price(str(r.out)) * 0.5))
		if sale > cost:
			out.append({"id": str(r.id), "cost": cost, "sale": sale})
	return out

# --- the Deeds ---

## [net per in-game day at tier, outlay to reach tier] for each tier, at a day.
static func deed_rows(day: int) -> Array:
	var d := _state(day)
	var rows := []
	for deed in Deeds.all():
		var id := str(deed.id)
		for t in deed.tiers.size():
			rows.append({"id": id, "kind": str(deed.kind), "tier": t, "net": DeedsSim.net_per_day(d, id, t, d.badges.size() >= BADGES_FOR_MANAGER) * SUPPLY,
				"cost": Deeds.price(d, id) if t == 0 else roundi(float(deed.tiers[t].cost) * Deeds.inflation(d))})
	return rows

## One year's tax on `income` of passive money: nothing under the allowance, then the bands.
static func tax_on(income: float) -> float:
	var tax := 0.0
	var from := float(Deeds.ALLOWANCE)
	for band in Deeds.TAX_BANDS:
		var top := float(band[0])
		if income > from:
			tax += (minf(income, top) - from) * float(band[1])
		from = maxf(from, top)
	return tax

static func lease_average() -> Dictionary:
	var r := 0.0
	var u := 0.0
	var all := Leases.all()
	for l in all:
		r += float(l.get("reserve", 0))
		u += float(l.get("upkeep", 0))
	return {"reserve": r / maxf(1.0, all.size()), "upkeep": u / maxf(1.0, all.size())}

# --- casino ---

## Net result of a visit staking the whole day's limit on even-money roulette, split into CASINO_BETS bets.
static func casino_visit(limit: int, rng: Rng) -> int:
	var stake := maxi(1, limit / CASINO_BETS)
	var net := 0
	for i in CASINO_BETS:
		net += Roulette.returns(Roulette.red(), stake, Roulette.spin(rng)) - stake
	return net

## A year of nothing but the casino: the day's whole limit staked every real day, from badge 0 to 10 as the story goes.
static func casino_year(seed_value: int) -> int:
	var rng := Rng.new(hash("casino:%d" % seed_value))
	var net := 0
	var day := 0
	while day < DAYS:
		day += PLAY_EVERY
		net += casino_visit(Punt.limit(_state(day)), rng)
	return net

# --- the career ---

## One career. {"wealth", "spent", "by_source", "first": {event: day}, "at": {day: wealth}, "owned": [...]}
static func run(strategy: String, seed_value: int) -> Dictionary:
	var rng := Rng.new(hash("econ:%d" % seed_value))
	var money := 0.0
	var by := {}
	var first := {}
	var at := {}
	var spent := {"charms": 0.0, "deeds": 0.0, "leases": 0.0, "pannier": 0.0, "upkeep": 0.0}
	var tiers := {}     # deed id -> tier
	var leases := 0
	var charms := 0
	var pannier := false
	var lumps_paid := 0.0
	var deeds_on := strategy in ["deed_rush", "everything"]
	var trade_on := strategy in ["trader", "everything"]    # cooks, and hauls the dishes to where they are wanted
	var cook_on := strategy == "cook"                        # cooks and sells where it stands
	var casino_on := strategy in ["casino", "everything"]
	var all_lumps := lump_total()
	var day := 0
	while day < DAYS:
		day += PLAY_EVERY
		var b := badges_at(day)
		var d := _state(day)
		# income earned over the last PLAY_EVERY days
		var inc := {}
		inc.merge(dailies(b))
		# the lumps arrive as badges do
		var due := all_lumps * float(b) / 10.0
		if due > lumps_paid:
			inc["lumps"] = due - lumps_paid
			lumps_paid = due
		if cook_on or trade_on:
			inc["cooking"] = dish_pay(trade_on)
		if deeds_on and not tiers.is_empty():
			var net := 0.0
			for id in tiers:
				net += DeedsSim.net_per_day(d, str(id), int(tiers[id]), b >= BADGES_FOR_MANAGER) * SUPPLY
			inc["deeds"] = net * PLAY_EVERY
		if casino_on and b >= 0:
			inc["casino"] = float(casino_visit(Punt.limit(d), rng))
		for k in inc:
			money += float(inc[k])
			by[k] = float(by.get(k, 0.0)) + float(inc[k])
		# upkeep on leases
		for i in leases:
			var up := PLAY_EVERY / 7.0 * float(lease_average().upkeep)
			money -= up
			spent.upkeep += up
		# spend: Deeds first (they pay), then the pannier, charms, leases
		if deeds_on:
			var guard := 0
			while guard < 40:
				guard += 1
				var pick := {}
				var pick_pb := INF
				var rows := deed_rows(day)
				var cur := {}
				for r in rows:
					if tiers.has(r.id) and int(tiers[r.id]) == int(r.tier):
						cur[r.kind] = r
				for r in rows:
					var owned_here: bool = tiers.has(r.id)
					var kind_taken := false
					for oid in tiers:
						if str(oid) != str(r.id) and Deeds.get_deed(str(oid)).kind == r.kind:
							kind_taken = true
					if kind_taken or (owned_here and int(r.tier) != int(tiers[r.id]) + 1) or (not owned_here and int(r.tier) != 0):
						continue
					var gain := float(r.net) - (float(cur[r.kind].net) if owned_here and cur.has(r.kind) else 0.0)
					if gain <= 0.0 or float(r.cost) > money:
						continue
					var pb := float(r.cost) / gain
					if pb < pick_pb and pb <= PAYBACK_MAX:
						pick_pb = pb
						pick = r
				if pick.is_empty():
					break
				money -= float(pick.cost)
				spent.deeds += float(pick.cost)
				tiers[pick.id] = int(pick.tier)
				if not first.has("deed"):
					first["deed"] = day
		var keep := 0.0
		if not pannier and trade_on and money >= 2000.0 * 1.5:
			money -= 2000.0
			spent.pannier += 2000.0
			pannier = true
		while charms < CHARM_CAP and money >= 3500.0 * 1.3 and b >= 1:
			money -= 3500.0
			spent.charms += 3500.0
			charms += 1
			if not first.has("charm"):
				first["charm"] = day
		if b >= LEASE_BADGES:
			var ls := lease_average()
			var cost: float = float(ls.reserve) * (LEASE_BID + float(Leases.STAGE_PCT) * 6.0)   # the bid, then three stages
			while leases < Leases.all().size() and money >= cost:
				money -= cost
				spent.leases += cost
				leases += 1
				if not first.has("lease"):
					first["lease"] = day
				if leases == 5:
					first["lease5"] = day
				if leases == Leases.all().size():
					first["lease_all"] = day
		if tiers.size() == 6 and not first.has("deeds_t3"):
			var maxed := true
			for id in tiers:
				if int(tiers[id]) < Deeds.get_deed(str(id)).tiers.size() - 1:
					maxed = false
			if maxed:
				first["deeds_t3"] = day
		if day == 30 or day == 78 or day == STORY_END or day == 180 or day == DAYS:
			at[day] = money
	# the year's self assessment on passive income (Deeds.TAX_BANDS), settled in April
	var tax := tax_on(float(by.get("deeds", 0.0)) * 360.0 / float(DAYS))
	money -= tax
	spent["tax"] = tax
	var shown := []
	for id in tiers:
		shown.append("%s:t%d" % [id, int(tiers[id])])
	return {"wealth": money, "spent": spent, "by_source": by, "first": first, "at": at, "owned": shown, "leases": leases, "charms": charms}
