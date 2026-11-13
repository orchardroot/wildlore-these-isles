extends TestCase
## Running a Deed (core/deed_choices.gd, wave 55): upgrades with catches, the monthly matter that needs an answer, what a
## manager's character does, old saves, and that none of it prints money (DeedsSim).

const WHITBY := "chippy_whitby"

func _data(badges := 4, cash := 500000) -> GameStateData:
	var d := GameStateData.new()
	d.money = cash
	d.day_count = 100
	d.rng_seed = 12345
	for i in badges:
		d.badges.append("b%d" % i)
	d.set_flag("badge_stone", true)
	return d

func _owned(id := WHITBY, badges := 4) -> GameStateData:
	var d := _data(badges)
	assert_eq(Deeds.buy(d, id), "")
	return d

func _stock(d: GameStateData, id: String) -> void:
	for inp in Deeds.get_deed(id).inputs:
		d.bag[str(inp.item)] = 99
		Deeds.supply(d, id, str(inp.item), 99)

## A year-ish of days on a stocked Deed, collecting as we go, so the unattended limit never bites. Returns what was collected.
func _run(d: GameStateData, id: String, days: int) -> int:
	var got := 0
	for i in days:
		d.day_count += 1
		_stock(d, id)
		Deeds.tick(d, d.day_count)
		if i % 20 == 19:
			got += Deeds.collect(d, id)
	return got + Deeds.collect(d, id)

func test_the_data_is_sound() -> void:
	assert_eq(DeedChoices.problems(ItemDB.load_default()), [], "no problems in the upgrades, matters and managers")
	for deed in Deeds.all():
		assert_true(DeedChoices.upgrades(str(deed.id)).size() >= 2, str(deed.id) + " has upgrades")
		assert_true(DeedChoices.pool(deed).size() >= 7, str(deed.id) + " has matters to answer")

func test_every_upgrade_has_a_catch_or_a_rival() -> void:
	for deed in Deeds.all():
		for u in DeedChoices.upgrades(str(deed.id)):
			var catches: bool = float(u.get("use", 1.0)) > 1.0 or float(u.get("upkeep", 0.0)) > 0.0 or float(u.get("shield", 0.0)) < 0.0 \
				or float(u.get("rates", 0.0)) > 0.0 or float(u.get("takings", 1.0)) < 1.0 or str(u.get("group", "")) != "" or int(u.get("cost", 0)) > 0
			assert_true(catches, "%s %s costs something" % [deed.id, u.id])
	# and at least one upgrade in each Deed is a real trade-off, not just a price
	for deed in Deeds.all():
		var trade := false
		for u in DeedChoices.upgrades(str(deed.id)):
			trade = trade or float(u.get("use", 1.0)) > 1.0 or float(u.get("upkeep", 0.0)) > 0.0 or float(u.get("shield", 0.0)) < 0.0 or str(u.get("group", "")) != ""
		assert_true(trade, str(deed.id) + " has a trade-off")

# --- upgrades ----------------------------------------------------------------------------------------

func test_buying_an_upgrade_pays_and_records_it() -> void:
	var d := _owned()
	Deeds.upgrade(d, WHITBY)   # tier 1 for the second fryer
	var up := DeedChoices.get_upgrade(WHITBY, "second_fryer")
	var before := d.money
	assert_eq(DeedChoices.buy(d, WHITBY, "second_fryer"), "")
	assert_eq(before - d.money, DeedChoices.cost(d, WHITBY, up))
	assert_true(DeedChoices.has(d, WHITBY, "second_fryer"))
	assert_true(DeedChoices.buy(d, WHITBY, "second_fryer") != "", "only once")
	assert_true(int(Deeds.state(d, WHITBY).paid) >= DeedChoices.cost(d, WHITBY, up), "counts toward sell-back")

func test_an_upgrade_needs_its_tier_and_the_money() -> void:
	var d := _owned()
	assert_true(DeedChoices.buy(d, WHITBY, "second_fryer") != "", "needs the first tier up")
	Deeds.upgrade(d, WHITBY)
	d.money = 0
	assert_true(DeedChoices.buy(d, WHITBY, "second_fryer") != "", "and the money")
	assert_false(DeedChoices.has(d, WHITBY, "second_fryer"))
	assert_true(DeedChoices.buy(d, "boat_whitby", "bigger_nets") != "", "not your Deed")

func test_one_of_a_pair_shuts_out_the_other() -> void:
	var d := _owned()
	Deeds.upgrade(d, WHITBY)
	Deeds.upgrade(d, WHITBY)
	assert_eq(DeedChoices.buy(d, WHITBY, "quay_lease"), "")
	assert_true(DeedChoices.buy(d, WHITBY, "late_licence") != "", "the lease and the licence do not go together")
	assert_true(DeedChoices.why_not(d, WHITBY, "late_licence").contains("instead"))

func test_upgrades_change_what_a_day_takes_and_uses() -> void:
	var plain := _owned()
	var fitted := _owned()
	for d in [plain, fitted]:
		Deeds.upgrade(d, WHITBY)
	DeedChoices.buy(fitted, WHITBY, "second_fryer")
	_stock(plain, WHITBY)
	_stock(fitted, WHITBY)
	var stores := {}
	for d in [plain, fitted]:
		stores[d] = Deeds.store_of(d, WHITBY, "potatoes")
		d.day_count += 3
		Deeds.tick(d, d.day_count)
	assert_true(Deeds.till(fitted, WHITBY) > Deeds.till(plain, WHITBY), "the second fryer takes more")
	assert_true(stores[fitted] - Deeds.store_of(fitted, WHITBY, "potatoes") > stores[plain] - Deeds.store_of(plain, WHITBY, "potatoes"), "and eats more potatoes")

func test_the_catches_bite() -> void:
	var plain := _owned()
	var licensed := _owned()
	for d in [plain, licensed]:
		Deeds.upgrade(d, WHITBY)
		Deeds.upgrade(d, WHITBY)
	DeedChoices.buy(licensed, WHITBY, "late_licence")
	var f := DeedChoices.fx(licensed, WHITBY)
	assert_true(float(f.upkeep) > 0.0, "the licence needs a wage")
	assert_true(float(f.shield) < 0.0, "and bad days bite harder")
	assert_true(DeedChoices.bend(0.6, float(f.shield), 0.0) < 0.6, "a bad day is worse")
	assert_true(DeedChoices.bend(0.6, 0.35, 0.0) > 0.6, "a careful hand softens it")
	assert_eq(DeedChoices.bend(0.0, 0.0, 0.0), 0.0, "a closed day stays closed with no shield")
	assert_true(DeedChoices.bend(2.0, 0.0, 0.5) > 2.0, "a showman stretches a good day")

func test_a_lease_lowers_the_rates() -> void:
	var d := _owned()
	Deeds.upgrade(d, WHITBY)
	Deeds.upgrade(d, WHITBY)
	var plain := _owned()
	Deeds.upgrade(plain, WHITBY)
	Deeds.upgrade(plain, WHITBY)
	DeedChoices.buy(d, WHITBY, "quay_lease")
	for x in [d, plain]:
		_stock(x, WHITBY)
		x.day_count += 8
		Deeds.tick(x, x.day_count)
	var rate_fit := float(Deeds.rates_due(d, WHITBY)) / float(maxi(1, Deeds.till(d, WHITBY) + Deeds.rates_due(d, WHITBY)))
	var rate_plain := float(Deeds.rates_due(plain, WHITBY)) / float(maxi(1, Deeds.till(plain, WHITBY) + Deeds.rates_due(plain, WHITBY)))
	assert_true(rate_fit < rate_plain, "the council takes a smaller share: %.3f vs %.3f" % [rate_fit, rate_plain])

func test_neutral_when_nothing_is_fitted() -> void:
	var d := _owned()
	var f := DeedChoices.fx(d, WHITBY)
	assert_eq(float(f.takings), 1.0)
	assert_eq(float(f.use), 1.0)
	assert_eq(float(f.shield), 0.0)
	assert_eq(int(f.carry), 0)
	assert_eq(DeedChoices.day_mult({}, 100), 1.0, "no name, no spells: the plain day")
	assert_eq(DeedChoices.use_of(6, 1.0), 6)
	assert_eq(DeedChoices.use_of(1, 1.35), 1, "a one-a-day input does not grow by a third")
	assert_eq(DeedChoices.use_of(6, 1.35), 8)
	assert_eq(DeedChoices.use_of(6, 0.85), 5)

# --- an old save --------------------------------------------------------------------------------------

func test_an_old_save_ticks_as_before_and_gets_its_first_matter_later() -> void:
	var d := _owned()
	# the Deed's flag exactly as an old save wrote it: none of the wave 55 keys
	var old := {"owned": true, "tier": 0, "store": {}, "till": 0, "rates_due": 0, "manager": "", "last_day": d.day_count,
		"coll": d.day_count, "paid": 4000, "accrue": 0, "bill": d.day_count + 7, "stmt": d.day_count + 30, "log": []}
	d.set_flag("deed_" + WHITBY, old)
	_stock(d, WHITBY)
	d.day_count += 1
	Deeds.tick(d, d.day_count)
	assert_true(Deeds.till(d, WHITBY) > 0, "takings as ever")
	assert_true(DeedChoices.pending(d, WHITBY).is_empty(), "no matter on the first day back")
	assert_true(DeedChoices.owned_ups(d, WHITBY).is_empty())
	assert_eq(DeedChoices.reputation(d, WHITBY), 0)
	assert_true(int(Deeds.state(d, WHITBY).next_ask) > d.day_count, "the first one is a few days off")

func test_a_deed_that_knows_nothing_of_a_manager_character_still_gets_the_plain_bonus() -> void:
	var d := _owned()
	Deeds.set_manager(d, WHITBY, "reg_pat")   # not a Regular
	assert_eq(float(DeedChoices.fx(d, WHITBY).takings), Deeds.MANAGER_BONUS)

# --- the monthly matter --------------------------------------------------------------------------------

## Walk a Deed on until a matter is waiting.
func _until_matter(d: GameStateData, id: String) -> void:
	for i in 80:
		d.day_count += 1
		_stock(d, id)
		Deeds.tick(d, d.day_count)
		if not DeedChoices.pending(d, id).is_empty():
			return
	fail("no matter came up in 80 days at " + id)

func test_a_matter_comes_up_within_a_couple_of_months_and_is_posted() -> void:
	var d := _owned()
	_until_matter(d, WHITBY)
	var p := DeedChoices.pending(d, WHITBY)
	assert_true(str(p.ask.title) != "")
	assert_true(p.ask.options.size() >= 3)
	assert_true(int(p.left) <= DeedChoices.ASK_WINDOW)
	assert_false(str(p.ask.text).contains("{"), "no stray placeholders: " + str(p.ask.text))
	var kinds := Deeds.letters_waiting(d).map(func(m): return str(m.k))
	assert_has(kinds, "ask")
	var lines := Deeds.collect_letters(d)
	var said := " ".join(PackedStringArray(lines.map(func(l): return str(l))))
	assert_true(said.contains(str(p.ask.title)), "the letter names the matter")

func test_the_same_seed_gives_the_same_matters() -> void:
	var a := _owned()
	var b := _owned()
	_until_matter(a, WHITBY)
	_until_matter(b, WHITBY)
	assert_eq(DeedChoices.pending(a, WHITBY).ask.id, DeedChoices.pending(b, WHITBY).ask.id)
	assert_eq(a.day_count, b.day_count)

func test_answering_costs_the_price_and_records_the_result() -> void:
	var d := _owned()
	_until_matter(d, WHITBY)
	var p := DeedChoices.pending(d, WHITBY)
	var opt: Dictionary = p.ask.options[0]
	var c := DeedChoices.option_cost(d, WHITBY, opt)
	var before := d.money
	assert_eq(DeedChoices.answer(d, WHITBY, str(opt.id)), "")
	assert_eq(before - d.money, c)
	assert_true(DeedChoices.pending(d, WHITBY).is_empty(), "answered")
	assert_eq(DeedChoices.answer(d, WHITBY, str(opt.id)), "Nothing needs an answer.")
	assert_true(Deeds.recent(d, WHITBY).size() >= 1, "it is in the Deed's log")

func test_an_answer_needs_the_money_and_a_real_option() -> void:
	var d := _owned()
	_until_matter(d, WHITBY)
	var p := DeedChoices.pending(d, WHITBY)
	assert_true(DeedChoices.answer(d, WHITBY, "nonsense") != "")
	var dear := ""
	for o in p.ask.options:
		if DeedChoices.option_cost(d, WHITBY, o) > 0:
			dear = str(o.id)
	if dear != "":
		d.money = 0
		assert_true(DeedChoices.answer(d, WHITBY, dear) != "", "can't pay for it")
		assert_false(DeedChoices.pending(d, WHITBY).is_empty(), "still waiting")

func test_an_answer_can_leave_a_name_behind_and_a_spell_of_days() -> void:
	var d := _owned()
	var st := Deeds.books(d, WHITBY)
	var deed := Deeds.get_deed(WHITBY)
	var ask := DeedChoices.get_ask(deed, "inspector")
	var scrub: Dictionary = DeedChoices.shown(deed, ask).options[0]
	DeedChoices._settle(d, st, deed, DeedChoices.shown(deed, ask), scrub, d.day_count, "You")
	assert_eq(DeedChoices.reputation(d, WHITBY), 1, "a good score on the door")
	var busy: Dictionary = DeedChoices.shown(deed, ask).options[2]
	DeedChoices._settle(d, st, deed, DeedChoices.shown(deed, ask), busy, d.day_count, "You")
	assert_eq(DeedChoices.reputation(d, WHITBY), 0, "and a bad one takes it away")
	assert_true(DeedChoices.day_mult(Deeds.books(d, WHITBY), d.day_count) < 1.0, "a spell of worse days")
	assert_eq(DeedChoices.day_mult(Deeds.books(d, WHITBY), d.day_count + 11), 1.0, "that wears off")

func test_reputation_is_capped() -> void:
	var d := _owned()
	var st := Deeds.books(d, WHITBY)
	st["rep"] = 99
	assert_eq(DeedChoices.reputation(d, WHITBY), DeedChoices.REP_CAP)
	assert_near(DeedChoices.day_mult(st, d.day_count), 1.0 + DeedChoices.REP_STEP * DeedChoices.REP_CAP)

func test_a_lapsed_matter_goes_the_worst_way_without_a_manager() -> void:
	var d := _owned()
	_until_matter(d, WHITBY)
	var posted := int(Deeds.state(d, WHITBY).ask.day)
	var ask_id := str(Deeds.state(d, WHITBY).ask.id)
	d.day_count = posted + DeedChoices.ASK_WINDOW
	_stock(d, WHITBY)
	var lines := Deeds.tick(d, d.day_count)
	assert_true(DeedChoices.pending(d, WHITBY).is_empty(), "it lapsed")
	assert_true(lines.size() >= 1, "and the wireless says how it went")
	var deed := Deeds.get_deed(WHITBY)
	var worst := DeedChoices.default_pick(DeedChoices.get_ask(deed, ask_id), "")
	assert_eq(str(worst.tag), DeedChoices.IGNORE)

func test_a_matter_is_not_the_same_twice_running() -> void:
	var d := _owned()
	_until_matter(d, WHITBY)
	var first := str(DeedChoices.pending(d, WHITBY).ask.id)
	DeedChoices.answer(d, WHITBY, str(DeedChoices.pending(d, WHITBY).ask.options[0].id))
	var guard := 0
	while DeedChoices.pending(d, WHITBY).is_empty() and guard < 80:
		guard += 1
		d.day_count += 1
		_stock(d, WHITBY)
		Deeds.tick(d, d.day_count)
	assert_true(str(DeedChoices.pending(d, WHITBY).ask.id) != first)

func test_every_matter_can_be_finished_by_every_answer() -> void:
	for deed in Deeds.all():
		for a in DeedChoices.pool(deed):
			var shown := DeedChoices.shown(deed, a)
			assert_false(str(shown.text).contains("{"), "%s %s text" % [deed.id, a.id])
			assert_false(str(shown.title).contains("{"), "%s %s title" % [deed.id, a.id])
			for o in shown.options:
				assert_false(str(o.label).contains("{") or str(o.say).contains("{"), "%s %s %s words" % [deed.id, a.id, o.id])
				var d := _data()
				d.set_flag("deed_" + str(deed.id), {"owned": true, "tier": 0, "store": {}, "till": 0, "rates_due": 0, "manager": "", "last_day": d.day_count,
					"coll": d.day_count, "paid": 0, "accrue": 0, "bill": d.day_count + 7, "stmt": d.day_count + 30, "log": []})
				d.day_count += 5
				var st := Deeds.books(d, str(deed.id))
				var before := d.money
				DeedChoices._settle(d, st, deed, shown, o, d.day_count, "You")
				assert_true(DeedChoices.reputation(d, str(deed.id)) >= -DeedChoices.REP_CAP, "%s %s %s sane" % [deed.id, a.id, o.id])
				assert_eq(d.money, before, "settling alone takes no cash: the price is taken by answer() or the till")

# --- managers ----------------------------------------------------------------------------------------

func test_five_temperaments_that_average_the_old_bonus() -> void:
	var t := DeedChoices.temperaments()
	assert_eq(t.size(), 5)
	var sum := 0.0
	for k in t:
		sum += float(t[k].bonus)
		assert_true(float(t[k].bonus) >= 1.05 and float(t[k].bonus) <= 1.22, k + " bonus in range")
	assert_near(sum / 5.0, Deeds.MANAGER_BONUS, 0.02, "the old flat figure is the average")

func test_the_regulars_are_dealt_every_temperament_and_it_never_changes() -> void:
	var seen := {}
	for r in Regulars.all():
		var k := DeedChoices.temper_of(str(r.id))
		assert_true(DeedChoices.temperaments().has(k), str(r.id) + " has a real temperament")
		assert_eq(DeedChoices.temper_of(str(r.id)), k, "stable")
		seen[k] = true
	assert_eq(seen.size(), 5, "all five turn up among the Regulars")

func _managed_by(reg_id: String, deed := WHITBY) -> GameStateData:
	var d := _owned(deed)
	d.set_flag("reg_" + reg_id, {"favour": 4})
	Deeds.set_manager(d, deed, reg_id)
	return d

func _reg_with(temper: String) -> String:
	for r in Regulars.all():
		if DeedChoices.temper_of(str(r.id)) == temper and str(r.get("home", "")) != "whitby" and str(r.get("away", "")) != "whitby" and str(r.get("likes", "")) not in ["haddock", "whiting", "potatoes"]:
			return str(r.id)
	return ""

func test_who_you_appoint_changes_what_happens() -> void:
	var by := {}
	for k in DeedChoices.temperaments():
		var rid := _reg_with(str(k))
		assert_true(rid != "", "a Regular for " + str(k))
		var d := _managed_by(rid)
		by[k] = DeedChoices.fx(d, WHITBY)
		assert_eq(DeedChoices.manager_traits(d, WHITBY).temper, k)
	assert_true(float(by.careful.shield) > 0.3 and float(by.showman.shield) < 0.0, "careful softens bad days, a showman does not")
	assert_true(float(by.showman.boom) > 0.0 and float(by.careful.boom) == 0.0, "a showman stretches good ones")
	assert_true(float(by.thrifty.use) < 1.0, "thrifty uses less stock")
	assert_true(int(by.steady.carry) > 0, "steady keeps the till filling")
	assert_true(float(by.showman.takings) > float(by.careful.takings), "the takings differ")

func test_a_manager_answers_by_their_style_after_three_days() -> void:
	var showman := _managed_by(_reg_with("showman"))
	var thrifty := _managed_by(_reg_with("thrifty"))
	var deed := Deeds.get_deed(WHITBY)
	var ask := DeedChoices.get_ask(deed, "supplier")
	assert_eq(str(DeedChoices.default_pick(DeedChoices.shown(deed, ask), "bold").tag), "bold")
	assert_eq(str(DeedChoices.default_pick(DeedChoices.shown(deed, ask), "frugal").tag), "frugal")
	for d in [showman, thrifty]:
		_until_matter(d, WHITBY)
		assert_true(int(DeedChoices.pending(d, WHITBY).left) <= DeedChoices.MANAGED_WINDOW, "a manager gives you a short window to step in")
		var posted := int(Deeds.state(d, WHITBY).ask.day)
		d.day_count = posted + DeedChoices.MANAGED_WINDOW
		_stock(d, WHITBY)
		Deeds.tick(d, d.day_count)
		assert_true(DeedChoices.pending(d, WHITBY).is_empty(), "the manager dealt with it")

func test_a_manager_who_knows_the_town_and_the_goods_does_better() -> void:
	var rid := _reg_with("steady")
	var far := _managed_by(rid)
	assert_false(bool(DeedChoices.manager_traits(far, WHITBY).local))
	var ned := _managed_by("ned")   # Ned Corrigan is from Whitby and likes haddock
	var t := DeedChoices.manager_traits(ned, WHITBY)
	assert_true(bool(t.local) and bool(t.stock), "knows the town and the stock")
	var base: float = float(DeedChoices.temperaments()[DeedChoices.temper_of("ned")].bonus)
	assert_near(float(t.bonus), base + 0.05, 0.0001)
	assert_true(float(t.bonus) <= 1.25, "never more than a quarter on top")
	assert_true(DeedChoices.manager_lines(t, "Ned").size() >= 3)
	assert_true(DeedChoices.character_line("ned") != "")
	assert_eq(DeedChoices.character_line("nobody"), "")

func test_letting_a_manager_go() -> void:
	var d := _managed_by("ned")
	Regulars.appoint(d, "ned", "boat_whitby") # not owned: refused, no harm
	Deeds.release_manager(d, WHITBY)
	assert_eq(Deeds.manager(d, WHITBY), "")
	assert_eq(Regulars.manager_of(d, "ned"), "", "free to be asked again")
	assert_true(DeedChoices.manager_traits(d, WHITBY).is_empty())
	Deeds.release_manager(d, "boat_whitby")   # not owned: nothing happens

func test_the_deed_summary_shows_the_character_and_what_is_fitted() -> void:
	var d := _managed_by("ned")
	Deeds.upgrade(d, WHITBY)
	DeedChoices.buy(d, WHITBY, "second_fryer")
	var text := " ".join(PackedStringArray(Deeds.summary(d, WHITBY).map(func(l): return str(l))))
	assert_true(text.contains("Ned Corrigan"))
	assert_true(text.contains("A second fryer"))

# --- nothing prints money -----------------------------------------------------------------------------

func test_the_matters_are_a_small_drag_when_answered_well_and_a_big_one_when_not() -> void:
	var d := _owned()
	var best := DeedChoices.ask_net_per_day(d, WHITBY, true)
	var worst := DeedChoices.ask_net_per_day(d, WHITBY, false)
	var day := float(Deeds.daily_estimate(d, WHITBY))
	assert_true(worst < best, "ignoring them is worse than answering")
	var month := float(DeedChoices.ASK_EVERY)
	assert_true(best * month > -0.6 * day, "answered well a month's matter costs under half a day: %.2f days" % (best * month / day))
	assert_true(best * month < 0.6 * day, "and never prints money: %.2f days" % (best * month / day))
	assert_true(worst * month < -0.8 * day, "ignored it costs most of a day: %.2f days" % (worst * month / day))

func test_no_upgrade_pays_back_inside_a_fortnight_or_costs_more_than_it_ever_returns() -> void:
	for b in [3, 9]:
		var d := EconomySim._state(b * EconomySim.DAYS_PER_BADGE)
		for deed in Deeds.all():
			var id := str(deed.id)
			var managed: bool = b >= EconomySim.BADGES_FOR_MANAGER
			for u in DeedChoices.upgrades(id):
				var tier: int = (deed.tiers as Array).size() - 1   # the strictest case: the top tier, where the same upgrade earns most
				var pb := DeedsSim.upgrade_payback(d, id, tier, managed, str(u.id))
				assert_true(pb >= 14.0, "%s %s pays back in %.1f days at badge %d" % [id, u.id, pb, b])
