extends TestCase
## Cumberland and Westmorland wrestling (core/wrestling.gd): telegraphs, counters, falls, bouts, prizes.

func test_every_move_has_one_counter_and_a_tell() -> void:
	var seen := {}
	for m in Wrestling.MOVES:
		var c := Wrestling.counter_of(m)
		assert_true(c != "", m)
		assert_false(seen.has(c), "counters are all different")
		seen[c] = true
		assert_true(Wrestling.tell(m).length() > 10, "a tell for " + m)

func test_cues_without_a_feint_show_the_real_move_at_once() -> void:
	var cues := Wrestling.cues("hipe", false, Rng.new(1))
	assert_eq(cues.size(), 1)
	assert_eq(cues[0].move, "hipe")
	assert_eq(float(cues[0].at), 0.0)

func test_a_feint_shows_a_different_move_first() -> void:
	for seed in 20:
		var cues := Wrestling.cues("buttock", true, Rng.new(seed))
		assert_eq(cues.size(), 2)
		assert_true(cues[0].move != "buttock", "the decoy differs")
		assert_eq(cues[1].move, "buttock")
		assert_true(float(cues[1].at) > float(cues[0].at))

func test_judging_answers() -> void:
	var plain := Wrestling.cues("hipe", false, Rng.new(1))
	assert_eq(Wrestling.judge(plain, Wrestling.counter_of("hipe"), 0.5, 1.5), "counter")
	assert_eq(Wrestling.judge(plain, Wrestling.counter_of("buttock"), 0.5, 1.5), "wrong")
	assert_eq(Wrestling.judge(plain, Wrestling.counter_of("hipe"), 1.6, 1.5), "late")
	assert_eq(Wrestling.judge(plain, "", 1.6, 1.5), "late", "no answer is late")
	var fe := Wrestling.cues("hipe", true, Rng.new(1))
	var real_at := float(fe[1].at)
	assert_eq(Wrestling.judge(fe, Wrestling.counter_of("hipe"), real_at - 0.1, 1.5), "early", "answering before the real tell")
	assert_eq(Wrestling.judge(fe, Wrestling.counter_of("hipe"), real_at + 0.3, 1.5), "counter")
	assert_eq(Wrestling.judge(fe, Wrestling.counter_of("hipe"), real_at + 1.6, 1.5), "late", "the window starts at the real tell")

func test_easier_widens_the_window() -> void:
	assert_true(Wrestling.window(1.2, true) > Wrestling.window(1.2, false))

func test_a_fall_is_won_by_taking_the_other_off_balance() -> void:
	var f := Wrestling.new_fall(false)
	assert_eq(f.me, Wrestling.BALANCE)
	f = Wrestling.apply(f, "counter")
	assert_eq(f.opp, Wrestling.BALANCE - 1)
	assert_eq(f.winner, "")
	f = Wrestling.apply(f, "counter")
	assert_eq(f.winner, "me", "thrown")
	var g := Wrestling.new_fall(false)
	for r in Wrestling.BALANCE:
		g = Wrestling.apply(g, "wrong")
	assert_eq(g.winner, "opp")

func test_easier_gives_you_more_balance() -> void:
	assert_true(Wrestling.new_fall(true).me > Wrestling.new_fall(false).me)

func test_best_of_three() -> void:
	var b := Wrestling.new_bout()
	b = Wrestling.record_fall(b, "me")
	assert_eq(b.winner, "")
	b = Wrestling.record_fall(b, "opp")
	assert_eq(b.winner, "")
	b = Wrestling.record_fall(b, "me")
	assert_eq(b.winner, "me")
	var c := Wrestling.new_bout()
	c = Wrestling.record_fall(c, "opp")
	c = Wrestling.record_fall(c, "opp")
	assert_eq(c.winner, "opp", "two straight falls ends it")

func test_next_move_never_three_alike() -> void:
	var rng := Rng.new(9)
	var hist: Array = []
	for i in 200:
		var m := Wrestling.next_move(rng, hist)
		hist.append(m)
		assert_true(m in Wrestling.MOVES)
		if hist.size() >= 3:
			assert_false(hist[-1] == hist[-2] and hist[-2] == hist[-3], "no triple")

func test_skilled_players_win_more_bouts() -> void:
	var rival := {"window": 1.0, "feint": 40}
	var rng := Rng.new(5)
	var good := 0
	var poor := 0
	for i in 150:
		if Wrestling.sim_bout(0.9, rival, false, rng) == "me":
			good += 1
		if Wrestling.sim_bout(0.35, rival, false, rng) == "me":
			poor += 1
	assert_true(good > poor + 30, "%d vs %d" % [good, poor])

func test_prizes_ladder_and_daily_purse() -> void:
	var data := GameStateData.new()
	var first := Wrestling.win(data, "grasmere", 0)
	assert_true(first.first and first.money > 0)
	assert_eq(Wrestling.rungs_beaten(data, "grasmere"), 1)
	var again := Wrestling.win(data, "grasmere", 0)
	assert_eq(again.money, Wrestling.DAILY_PURSE)
	assert_eq(Wrestling.win(data, "grasmere", 0).money, 0, "once a day")
	assert_eq(TrainerStats.get_count(data, "wrestling_won"), 3)

func test_data_is_sane() -> void:
	var v := Wrestling.venue("grasmere")
	assert_true(v.rivals.size() >= 3)
	assert_true(Wrestling.venue_total("grasmere") <= 120)
	for r in v.rivals:
		assert_true(float(r.window) >= 0.6)
		assert_false("—" in JSON.stringify(r), "no em-dashes")
