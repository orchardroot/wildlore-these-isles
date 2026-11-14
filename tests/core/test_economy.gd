extends TestCase
## The whole economy (see EconomySim, tools/dev/economy_sim.gd to print it, docs/design/economy.md to read it): no recipe or
## market is a tap, every daily purse stays in its lane, the casino loses, and the big careers (all the Deeds, the Ledger,
## cooking) keep the late game worth earning for. The numbers are a perfect, diligent player's, so they are ceilings.

static var _runs := {}

func _run(strategy: String) -> Dictionary:
	if not _runs.has(strategy):
		_runs[strategy] = EconomySim.run(strategy, 7)
	return _runs[strategy]

func test_no_recipe_made_from_shop_goods_sells_for_more_than_it_costs() -> void:
	assert_eq(EconomySim.recipe_loops(), [], "buy the ingredients, craft, sell: that would be a tap")

func test_the_market_hall_cannot_be_flooded_for_a_fortune() -> void:
	# a full pannier of one dish into a town that wants it: the glut bites, so the load is worth well under the top price
	var d := GameStateData.new()
	var top := Trade.sell_price(d, "welsh_cakes", "swansea")
	var load := MarketHall.payout(d, "swansea_market", "welsh_cakes", 99)
	assert_true(load < 99 * top / 4, "99 units fetch %d against a flat %d" % [load, 99 * top])

func test_the_only_goods_a_shop_stocks_for_the_ledger_make_a_modest_run() -> void:
	# jute (and anything like it) is the one thing you can buy low and carry far; a full load must stay under a good job
	var runs := EconomySim.shop_runs()
	assert_false(runs.is_empty(), "something is both stocked and listed, or the Ledger has no arbitrage at all")
	for id in runs:
		assert_true(int(runs[id]) < EconomySim.jobs_pay(10) / EconomySim.JOBS_PER_PLAY * 1.0, "%s: a 99-unit run clears %d" % [id, runs[id]])

func test_the_casino_loses_over_a_year_on_average() -> void:
	var total := 0
	var n := 40
	for i in n:
		total += EconomySim.casino_year(i + 1)
	assert_true(total < 0, "mean result over %d years of staking the limit daily: %d" % [n, total / n])

func test_the_daily_purses_stay_in_their_lane() -> void:
	for b in [2, 4, 6, 8, 10]:
		var dl := EconomySim.dailies(b)
		var rest := 0.0
		for k in dl:
			if k != "jobs":
				rest += float(dl[k])
		assert_true(rest < float(dl.jobs) * 1.5, "badges %d: everything but the noticeboard (%d) stays near the noticeboard (%d)" % [b, rest, dl.jobs])
	var b0 := 0.0
	for k in EconomySim.dailies(0):
		b0 += float(EconomySim.dailies(0)[k])
	assert_true(b0 < 2000.0, "a first real day pays well under a Deed's price: %d" % b0)

func test_deeds_are_the_engine_but_not_a_runaway_before_the_story_ends() -> void:
	var plain: Dictionary = _run("dailies")
	var rich: Dictionary = _run("deed_rush")
	# cash plus what has gone into the towns (the town projects are a sink for both, which would skew a plain cash ratio)
	assert_true(float(rich.held[78]) < 3.5 * float(plain.held[78]), "the Deeds roughly double a pure saver by the credits: %d against %d" % [rich.held[78], plain.held[78]])
	assert_true(float(rich.at[30]) < 15000.0, "nobody is rich a month in: %d" % rich.at[30])
	assert_true(float(rich.spent.tax) > 0.0, "the taxman notices")

func test_the_late_game_still_has_something_to_buy() -> void:
	# the leases are the sink: even with every Deed at the top tier and the Ledger worked, all ten take weeks, not days
	var every: Dictionary = _run("everything")
	assert_true(int(every.first.lease_all) >= EconomySim.STORY_END + 30, "all ten leases by day %d" % every.first.lease_all)
	var plain: Dictionary = _run("dailies")
	assert_true(int(plain.first.lease5) >= EconomySim.STORY_END + 60, "a saver buys five by day %d" % plain.first.lease5)

func test_cooking_for_the_market_is_an_early_help_not_the_economy() -> void:
	var cook: Dictionary = _run("trader")
	var earned := 0.0
	for k in cook.by_source:
		earned += float(cook.by_source[k])
	assert_true(float(cook.by_source.cooking) < 0.3 * earned, "cooking is %d of %d earned over the year" % [cook.by_source.cooking, earned])
