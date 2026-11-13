extends TestCase
## Wave 55, the trade session: trade news (seeded events that move real prices), the Trader's Ledger page (only what has
## been seen or heard), delivery orders (bounded, premium for speed and freshness, never for shop goods), and the Trader's
## standing (a day's early word, a bigger pannier, credit, a market-day pitch). See core/trade_news.gd, trade_ledger.gd,
## trade_orders.gd, market_hall.gd and core/trades.gd.

func _d(day := 0) -> GameStateData:
	var d := GameStateData.new()
	d.day_count = day
	return d

## A save with the Trader at a level: goods_sold 0, 500, 3000, 12000, 40000 are levels 1 to 5.
func _trader(level: int, day := 0) -> GameStateData:
	var d := _d(day)
	d.stats["goods_sold"] = [0, 500, 3000, 12000, 40000][level - 1]
	return d

## The first day (from 1) an event of this id starts, under the current season override.
func _day_of(id: String, from := 1) -> int:
	for day in range(from, 2000):
		if str(TradeNews.starting(day).get("id", "")) == id:
			return day
	return -1

# --- trade news ---

func test_the_news_data_is_sound() -> void:
	assert_eq(TradeNews.problems(), [], "every event has words, a kind, real items and a sane factor")
	assert_eq(TradeOrders.problems(), [], "orders have something to ask for")
	assert_true(TradeNews.cfg().events.size() >= 12, "enough kinds of news that a week is not the same twice")

func test_a_few_events_a_week_and_the_same_every_time() -> void:
	Calendar.set_override("2026-06-10")
	var n := 0
	for day in 700:
		if not TradeNews.starting(day).is_empty():
			n += 1
		assert_eq(TradeNews.starting(day), TradeNews.starting(day), "seeded: day %d reads the same twice" % day)
	assert_true(n >= 250 and n <= 350, "about three a week over a hundred weeks, got %d" % n)
	Calendar.set_override("")

func test_news_moves_the_price_where_it_is_said_to_and_only_there() -> void:
	Calendar.set_override("2026-06-10")
	var day := _day_of("herring_glut", 10)
	assert_true(day > 0)
	var before := Trade.sell_price(_d(day - 1), "herring", "aberdeen")
	var on := Trade.sell_price(_d(day), "herring", "aberdeen")
	assert_true(on < before, "a glut at Lerwick: herring is cheaper in Aberdeen (%d against %d)" % [on, before])
	assert_eq(Trade.sell_price(_d(day), "herring", "cardiff"), Trade.sell_price(_d(day - 1), "herring", "cardiff"), "Cardiff does not care")
	assert_eq(Trade.sell_price(_d(day), "arbroath_smokie", "aberdeen"), Trade.sell_price(_d(day - 1), "arbroath_smokie", "aberdeen"), "other goods do not move")
	var over := day + int(TradeNews.event_def("herring_glut").days)
	assert_eq(TradeNews.factor(_d(over), "herring", "aberdeen"), 1.0, "and it ends (unless another begins): checked on a fresh day")
	assert_true(Trade.price_note(_d(day), "herring", "aberdeen").begins_with("in the news"), "the price board says so")
	Calendar.set_override("")

func test_a_shortage_pays_more_but_never_past_the_festival_cap() -> void:
	Calendar.set_override("2026-06-10")
	var day := _day_of("smokie_shortage", 10)
	assert_true(day > 0)
	var base := Trade.sell_price(_d(day - 20), "arbroath_smokie", "swansea")
	var on := Trade.sell_price(_d(day), "arbroath_smokie", "swansea")
	assert_true(on > base, "smokies are dearer in Wales when the smokehouses are short")
	var top := int(Trade.base_price("arbroath_smokie") * 0.5 * Trade.regional("arbroath_smokie", "wales") * float(Trade.config().demand_cap))
	assert_true(on <= top, "never past the demand cap: %d against %d" % [on, top])
	Calendar.set_override("")

func test_a_rail_strike_widens_every_gap() -> void:
	Calendar.set_override("2026-06-10")
	var day := _day_of("rail_strike", 10)
	assert_true(day > 0)
	assert_true(TradeNews.widening(_d(day)))
	var far := Trade.sell_price(_d(day), "arbroath_smokie", "cardiff")
	var home := Trade.sell_price(_d(day), "arbroath_smokie", "glasgow")
	var far0 := Trade.sell_price(_d(day - 30), "arbroath_smokie", "cardiff")
	var home0 := Trade.sell_price(_d(day - 30), "arbroath_smokie", "glasgow")
	assert_true(float(far) / float(home) > float(far0) / float(home0), "dear is dearer and cheap is cheaper")
	Calendar.set_override("")

func test_news_never_lets_you_buy_and_sell_in_one_place_for_a_profit() -> void:
	for date in ["2026-06-10", "2026-12-20", "2026-10-05"]:
		Calendar.set_override(date)
		for day in range(1, 45):
			var d := _d(day)
			for h in MarketHall.halls():
				var town := str(MarketHall.hall(h).town)
				for id in Trade.config().goods:
					assert_true(Trade.sell_price(d, str(id), town) <= Trade.buy_price(d, str(id), town), "%s in %s on day %d (%s)" % [id, town, day, date])

func test_the_trader_hears_two_days_early() -> void:
	Calendar.set_override("2026-06-10")
	var day := _day_of("smokie_shortage", 10)   # a lead of two days
	var plain := _d(day - 2)
	var early := _trader(2, day - 4)
	var found := false
	for e in TradeNews.visible(plain):
		found = found or str(e.id) == "smokie_shortage"
	assert_true(found, "everyone hears it two days ahead")
	var plain_early := _d(day - 4)
	found = false
	for e in TradeNews.visible(plain_early):
		found = found or (str(e.id) == "smokie_shortage" and int(e.start) == day)
	assert_false(found, "four days ahead only the Trader hears")
	found = false
	for e in TradeNews.visible(early):
		found = found or (str(e.id) == "smokie_shortage" and int(e.start) == day)
	assert_true(found, "the Trader's early word")
	Calendar.set_override("")

func test_the_wireless_carries_the_news_and_remembers_what_it_said() -> void:
	Calendar.set_override("2026-06-10")
	var day := _day_of("rail_strike", 10) - 1   # announced a day ahead
	var d := _d(day)
	var lines := Trade.money_box(d, "cardiff")
	var said := false
	for l in lines:
		said = said or "rail strike" in str(l).to_lower()
		assert_false("—" in str(l), "no em-dashes")
	assert_true(said, "the strike is on the wireless the day before")
	assert_true(TradeNews.heard_now(d).size() >= 1, "and the player now knows it")
	assert_eq(Trade.money_box(_d(day), "cardiff"), lines, "the same day reads the same")
	Calendar.set_override("")

func test_a_stall_holder_gives_the_news_in_their_own_words() -> void:
	Calendar.set_override("2026-06-10")
	var day := _day_of("herring_glut", 10)
	var d := _d(day)
	var said := TradeNews.stall_line(d, "inverness_market")
	assert_true(said != "" and not "—" in said)
	assert_true(TradeNews.heard_now(d).size() >= 1)

# --- the ledger ---
	Calendar.set_override("")

func test_a_fresh_ledger_is_empty_but_never_blank_and_knows_nothing() -> void:
	var d := _d(5)
	assert_false(TradeLedger.visible(d), "nothing to show a new player")
	var rows := TradeLedger.rows(d)
	assert_true(rows.size() >= 6, "every section says something, even when empty")
	for r in rows:
		assert_eq(r.size(), 2)
		for part in r:
			assert_false("—" in str(part))
	var all := JSON.stringify(rows)
	assert_false("Cardiff" in all or "Glasgow" in all, "no all-seeing price list")

func test_the_ledger_remembers_what_you_saw_and_how_old_it_is() -> void:
	Calendar.set_override("2026-06-10")
	var d := _d(10)
	var rows := [{"id": "arbroath_smokie", "sell": 300, "buy": 400}, {"id": "welsh_cakes", "sell": 90, "buy": 120}]
	TradeLedger.note_board(d, "cardiff_hall", rows)
	assert_true(TradeLedger.visible(d))
	assert_eq(TradeLedger.count(d), 2)
	d.day_count = 13
	TradeLedger.note(d, "arbroath_smokie", "glasgow", 110, 130)
	var recent := TradeLedger.recent(d)
	assert_eq(recent[0].town, "glasgow", "newest first")
	var sp := TradeLedger.best_spread(d)
	assert_eq(sp.item, "arbroath_smokie")
	assert_eq(sp.gap, 190)
	assert_eq(sp.high_town, "cardiff")
	var text := JSON.stringify(TradeLedger.rows(d))
	assert_true("3 days ago" in text, "a price from the 10th is three days old on the 13th: %s" % text)
	assert_false("Dublin" in text, "only what you saw")
	Calendar.set_override("")

func test_the_ledger_forgets_the_stalest_when_full() -> void:
	var d := _d(0)
	for i in TradeLedger.KEEP + 15:
		d.day_count = i
		TradeLedger.note(d, "welsh_cakes", "town%d" % i, 50, 60)
	assert_eq(TradeLedger.count(d), TradeLedger.KEEP)
	assert_false(TradeLedger._seen(d).has("welsh_cakes|town0"), "the oldest went first")

func test_the_ledger_lists_what_in_the_bag_is_about_to_go_off() -> void:
	var d := _d(20)
	d.bag["cullen_skink"] = 3
	d.bag["herring"] = 2
	d.bag["map_of_the_isles"] = 1
	Trade.stamp(d, "herring", 0, 2)
	d.day_count = 22   # the herring (keeps 3 days) is two days old
	var off := TradeLedger.going_off(d)
	assert_eq(off[0].item, "herring", "soonest first")
	assert_eq(off[0].left, 1)
	for r in off:
		assert_true(str(r.item) != "map_of_the_isles", "only perishables")
	var text := JSON.stringify(TradeLedger.rows(d))
	assert_true("1 day left" in text)

func test_a_late_save_with_goods_sold_sees_the_page_at_once() -> void:
	var d := _d(60)
	d.stats["goods_sold"] = 4000
	assert_true(TradeLedger.visible(d), "nothing new has to be done first")
	assert_true(Almanac.pages(d).any(func(p): return str(p.id) == "trade"))
	assert_false(Almanac.pages(_d(1)).any(func(p): return str(p.id) == "trade"))

func test_the_ledger_page_is_in_the_almanac_and_has_rows() -> void:
	var d := _d(60)
	d.stats["goods_sold"] = 600
	assert_true(Almanac.ledger(d, "trade").size() >= 6)
	assert_true(Almanac.blurb(d, "trade") != "")

# --- orders ---

func _a_posted_order(from := 0) -> Dictionary:
	for day in range(from, from + 400):
		for h in TradeOrders.hall_ids():
			var o := TradeOrders.posted(str(h), day)
			if not o.is_empty():
				return o
	return {}

func test_orders_are_seeded_wanted_there_and_never_shop_goods() -> void:
	TradeOrders.reset_cache()
	var n := 0
	var stocked := TradeOrders._shop_stocked()
	for day in 200:
		for h in TradeOrders.hall_ids():
			var o := TradeOrders.posted(str(h), day)
			assert_eq(o, TradeOrders.posted(str(h), day), "seeded")
			if o.is_empty():
				continue
			n += 1
			assert_true(Trade.regional(str(o.item), Trade.group_of(str(h))) > 1.0, "%s is wanted at %s" % [o.item, h])
			assert_false(stocked.has(str(o.item)), "nothing you can buy at a shop is ever asked for")
			assert_true(int(o.qty) >= 2 and int(o.qty) <= 6)
			assert_eq(int(o.last), int(o.posted) + 7)
	assert_true(n > 200 and n < 1500, "a handful posted every day across the halls, got %d" % n)

func test_orders_open_for_a_week_then_go() -> void:
	var o := _a_posted_order(20)
	var d := _d(int(o.posted))
	assert_true(TradeOrders.open_at(d, str(o.hall)).any(func(x): return x.id == o.id))
	d.day_count = int(o.last)
	assert_true(TradeOrders.open_at(d, str(o.hall)).any(func(x): return x.id == o.id), "still open on the last day")
	d.day_count = int(o.last) + 1
	assert_false(TradeOrders.open_at(d, str(o.hall)).any(func(x): return x.id == o.id), "gone the day after")
	assert_true(TradeOrders.blocked(d, o, 99).begins_with("Too late"))

func test_delivery_pays_the_board_price_plus_a_premium_and_builds_a_glut() -> void:
	Calendar.set_override("2026-06-10")
	var o := _a_posted_order(20)
	var d := _d(int(o.posted) + 5)   # not fast
	var town := TradeOrders.town_of(o)
	var board := Trade.sell_total(d, str(o.item), town, int(o.qty))
	var p := TradeOrders.premium(d, o)
	assert_near(p, 1.2, 0.001, "base plus fresh (no stamp means fresh), not fast: %s" % p)
	var due := TradeOrders.deliver(d, o)
	assert_eq(due, roundi(board * p))
	assert_true(TradeOrders.filled(d, str(o.id)))
	assert_true(Trade.glut_factor(d, str(o.item), town) < 1.0, "a delivery is a sale in that town")
	assert_eq(TradeOrders.blocked(d, o, 99), "Already seen to.")
	assert_true(TrainerStats.get_count(d, "goods_sold") > 0, "and it counts toward the Trader trade")
	Calendar.set_override("")

func test_a_fast_fresh_delivery_pays_more_than_a_slow_stale_one() -> void:
	var o := _a_posted_order(20)
	var fast := _d(int(o.posted))
	var slow := _d(int(o.posted) + 6)
	slow.flags[Trade.FRESH_FLAG] = {str(o.item): int(o.posted) - 40}
	if Trade.keeps_days(str(o.item)) > 0:
		assert_true(TradeOrders.premium(fast, o) > TradeOrders.premium(slow, o) + 0.2)
	assert_true(TradeOrders.premium(fast, o) <= 1.5, "bounded: base .1, fast .15, fresh .1, strike .15 at the most")

func test_a_strike_adds_to_the_premium() -> void:
	Calendar.set_override("2026-06-10")
	var day := _day_of("rail_strike", 30)
	var o := _a_posted_order(20)
	var calm := _d(day - 20)
	var out := _d(day)
	var gap := TradeOrders.premium(out, {"posted": day - 6, "item": o.item}) - TradeOrders.premium(calm, {"posted": day - 26, "item": o.item})
	assert_near(gap, float(TradeOrders.cfg().strike), 0.001)
	Calendar.set_override("")

func test_three_deliveries_a_day_and_no_more() -> void:
	Calendar.set_override("2026-06-10")
	var d := _d(40)
	var open := TradeOrders.all_open(d)
	assert_true(open.size() >= 4, "enough orders about to test the cap, got %d" % open.size())
	for i in 3:
		assert_eq(TradeOrders.blocked(d, open[i], 99), "")
		TradeOrders.deliver(d, open[i])
	assert_true(TradeOrders.blocked(d, open[3], 99).begins_with("That is enough"))
	d.day_count = 41
	assert_eq(TradeOrders.delivered_today(d), 0, "a new day, a clean count")
	Calendar.set_override("")

func test_an_order_needs_the_goods() -> void:
	var o := _a_posted_order(20)
	var d := _d(int(o.posted))
	assert_true(TradeOrders.blocked(d, o, int(o.qty) - 1).begins_with("You need"))
	assert_eq(TradeOrders.blocked(d, o, int(o.qty)), "")

func test_the_wireless_and_stall_holders_tell_you_of_orders_and_the_ledger_keeps_them() -> void:
	Calendar.set_override("2026-06-10")
	var d := _d(50)
	var lines := TradeOrders.wireless_lines(d, 1)
	assert_eq(lines.size(), 1)
	assert_false("—" in str(lines[0]))
	assert_true(TradeOrders.heard_open(d).size() >= 1)
	var s := TradeOrders.stall_line(d, "leeds_kirkgate")
	assert_true(s != "" and not "—" in s)
	var text := JSON.stringify(TradeLedger.rows(d))
	assert_true("by " in text and " x " in text, "the ledger lists orders heard of: %s" % text)
	Calendar.set_override("")

func test_credit_is_a_loan_not_a_gift() -> void:
	Calendar.set_override("2026-06-10")
	var o := _a_posted_order(20)
	var plain := _d(int(o.posted))
	assert_eq(TradeOrders.take_advance(plain, o), 0, "no credit before Trader 4")
	var d := _trader(4, int(o.posted))
	var amt := TradeOrders.take_advance(d, o)
	assert_true(amt > 0)
	assert_true(amt <= int(TradeOrders.board_value(d, o) * 0.26), "a quarter of the board value")
	assert_eq(TradeOrders.take_advance(d, o), 0, "one at a time")
	var due := TradeOrders.deliver(d, o)
	assert_true(due >= 0, "the rest comes on delivery")
	assert_eq(TradeOrders.advance_of(d, str(o.id)), 0, "settled")
	assert_eq(TradeOrders.owed(d), 0)
	Calendar.set_override("")

func test_an_advance_on_an_order_you_let_lapse_comes_off_your_next_delivery() -> void:
	Calendar.set_override("2026-06-10")
	var o := _a_posted_order(20)
	var d := _trader(4, int(o.posted))
	var amt := TradeOrders.take_advance(d, o)
	d.day_count = int(o.last) + 3
	TradeOrders.settle_lapsed(d)
	assert_eq(TradeOrders.owed(d), amt, "the debt is the advance")
	var again: Dictionary = TradeOrders.all_open(d)[0]
	assert_eq(TradeOrders.take_advance(d, again), 0, "no more credit while you owe")
	var gross := TradeOrders.gross(d, again)
	var due := TradeOrders.deliver(d, again)
	assert_eq(due, gross - mini(amt, gross), "the debt comes off the next delivery")
	assert_eq(TradeOrders.owed(d), maxi(0, amt - gross))

# --- the Trader's standing ---
	Calendar.set_override("")

func test_the_trader_opens_things_that_are_not_percentages() -> void:
	assert_false(Trades.has_perk(_trader(1), "trader_early"))
	assert_true(Trades.has_perk(_trader(2), "trader_early"))
	var d := _trader(3)
	assert_eq(Trades.carry_bonus(d), 15)
	assert_eq(Trade.carry_cap(d, "welsh_cakes"), 45, "a bigger pannier at Trader 3")
	d.bag["traders_pannier"] = 1
	assert_eq(Trade.carry_cap(d, "welsh_cakes"), 99, "the real pannier is still the best")
	assert_eq(Trade.carry_cap(_trader(2), "welsh_cakes"), 30, "nothing changes below level 3")
	assert_true(Trades.has_perk(_trader(4), "trader_credit"))
	assert_false(Trades.has_perk(_trader(4), "trader_pitch"))
	assert_true(Trades.has_perk(_trader(5), "trader_pitch"))

func test_the_market_day_pitch_is_twelve_units_a_hall_and_builds_no_glut() -> void:
	Calendar.set_override("2026-06-10")
	var market_day := 5
	var d := _trader(5, 7 * 10 + market_day)
	var plain := _d(7 * 10 + market_day)
	assert_eq(MarketHall.pitch_left(d, "swansea_market"), 12)
	assert_eq(MarketHall.pitch_left(plain, "swansea_market"), 0, "only the Trader 5 has a pitch")
	var off := _trader(5, 7 * 10 + 2)
	assert_eq(MarketHall.pitch_left(off, "swansea_market"), 0, "only on market day")
	var with_pitch := MarketHall.payout(d, "swansea_market", "welsh_cakes", 12)
	var without := Trade.sell_total(d, "welsh_cakes", "swansea", 12)
	assert_true(with_pitch > without, "twelve at the top price: %d against %d" % [with_pitch, without])
	var paid := MarketHall.settle(d, "swansea_market", "welsh_cakes", 12)
	assert_eq(paid, with_pitch)
	assert_eq(Trade.glut_factor(d, "welsh_cakes", "swansea"), 1.0, "no glut from the pitch")
	assert_eq(MarketHall.pitch_left(d, "swansea_market"), 0, "used up for the day at that hall")
	assert_eq(MarketHall.pitch_left(d, "cardiff_hall"), 12, "each hall has its own")
	MarketHall.settle(d, "swansea_market", "welsh_cakes", 3)
	assert_true(Trade.glut_factor(d, "welsh_cakes", "swansea") < 1.0, "past the pitch the glut builds as ever")

# --- saves ---
	Calendar.set_override("")

func test_every_new_flag_defaults_and_survives_a_save() -> void:
	Calendar.set_override("2026-06-10")
	var d := _d(40)
	for k in [TradeNews.HEARD_FLAG, TradeLedger.SEEN_FLAG, TradeOrders.FILLED_FLAG, TradeOrders.ADVANCE_FLAG, TradeOrders.OWED_FLAG, TradeOrders.DONE_FLAG, "trade_pitch"]:
		assert_eq(d.flag(k), null, "%s is absent on an old save, and nothing breaks" % k)
	assert_eq(TradeOrders.owed(d), 0)
	assert_eq(TradeOrders.delivered_today(d), 0)
	assert_true(TradeLedger.rows(d).size() > 0)
	var o: Dictionary = TradeOrders.all_open(d)[0]
	TradeOrders.see_hall(d, str(o.hall))
	TradeNews.wireless_lines(d, 3)
	TradeLedger.note(d, "welsh_cakes", "cardiff", 90, 100)
	TradeOrders.deliver(d, o)
	var back := _d(40)
	back.flags = JSON.parse_string(JSON.stringify(d.flags))
	assert_true(TradeOrders.filled(back, str(o.id)), "a delivery survives the JSON round trip")
	assert_eq(TradeLedger.recent(back)[0].item, "welsh_cakes")
	assert_eq(TradeOrders.delivered_today(back), 1)
	assert_eq(TradeNews.heard_now(back).size(), TradeNews.heard_now(d).size())
	Calendar.set_override("")

