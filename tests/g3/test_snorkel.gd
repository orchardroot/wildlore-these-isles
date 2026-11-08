extends TestCase
## Bog snorkelling (core/snorkel.gd): the kick, the silt, the breath, the turn and the locals.

func test_good_alternate_kicks_beat_same_foot() -> void:
	var a := Snorkel.fresh()
	var b := Snorkel.fresh()
	assert_eq(Snorkel.kick(a, "l", 0.0), "good")
	assert_eq(Snorkel.kick(a, "r", 0.0), "good")
	assert_eq(Snorkel.kick(b, "l", 0.0), "good")
	assert_eq(Snorkel.kick(b, "l", 0.0), "ragged", "the same flipper twice")
	assert_true(float(a.x) > float(b.x))

func test_ragged_kicks_silt_the_snorkel_and_blowing_clears_it() -> void:
	var s := Snorkel.fresh()
	for i in 4:
		Snorkel.kick(s, "l" if i % 2 == 0 else "r", 0.4)
	assert_true(float(s.silt) > 0.4)
	assert_true(Snorkel.blow(s))
	assert_eq(float(s.silt), 0.0)
	assert_eq(Snorkel.kick(s, "l", 0.0), "", "no kicking while you blow")

func test_easy_widens_the_good_window() -> void:
	assert_eq(Snorkel.grade(0.18, false), "ok")
	assert_eq(Snorkel.grade(0.18, true), "good")

func test_running_out_of_breath_swallows_bog() -> void:
	var s := Snorkel.fresh()
	s.breath = 0.001
	var ev := Snorkel.tick(s, 0.5)
	assert_true(ev.has("swallow"))
	assert_true(float(s.pause) > 1.0)

func test_two_lengths_with_a_turn() -> void:
	var s := Snorkel.fresh()
	s.x = Snorkel.LENGTH - 0.1
	Snorkel.kick(s, "l", 0.0)
	var ev := Snorkel.tick(s, 0.1)
	assert_true(ev.has("turn"))
	assert_eq(int(s.length), 1)
	assert_true(Snorkel.lane_x(s) > Snorkel.LENGTH - 1.0, "the second length starts at the far end")
	s.x = Snorkel.LENGTH * 2.0
	assert_true(Snorkel.tick(s, 0.1).has("finish"))
	assert_true(bool(s.done))

func test_steady_swimmers_beat_ragged_ones_and_the_local_is_fair() -> void:
	var steady := 0.0
	var ragged := 0.0
	for i in 20:
		steady += float(Snorkel.auto_swim(0.95, Rng.new(i)).t)
		ragged += float(Snorkel.auto_swim(0.45, Rng.new(i)).t)
	steady /= 20.0
	ragged /= 20.0
	var local := float(Snorkel.venue("waen_rhydd").rival.time)
	assert_true(steady < ragged - 10.0, "rhythm pays (%.1f vs %.1f)" % [steady, ragged])
	assert_true(steady < local, "a steady swimmer beats the champion (%.1f vs %.1f)" % [steady, local])
	assert_true(ragged > local - 6.0, "a ragged one does not walk it (%.1f)" % ragged)

func test_finish_pays_once_then_daily() -> void:
	var d := GameStateData.new()
	var r := Snorkel.finish(d, "waen_rhydd", 70.0, true)
	assert_true(bool(r.first))
	assert_eq(int(r.money), 12)
	assert_true(Snorkel.finish(d, "waen_rhydd", 71.0, true).money == Snorkel.DAILY_PURSE)
	assert_eq(int(Snorkel.finish(d, "waen_rhydd", 72.0, true).money), 0)
	assert_eq(Snorkel.best(d), 700)

func test_the_plain_trench_is_even_and_each_seed_has_its_own_set() -> void:
	var plain := Snorkel.fresh()
	assert_eq(Snorkel.carry_at(plain), 1.0)
	var lo := 9.0
	var hi := 0.0
	for i in 40:
		var c := Snorkel.carry_at(Snorkel.fresh(i + 1))
		lo = minf(lo, c)
		hi = maxf(hi, c)
	assert_true(hi - lo > 0.06, "the water differs from swim to swim (%.3f to %.3f)" % [lo, hi])

func test_a_perfect_swimmer_has_spread_but_the_floor_stays_near_forty_three() -> void:
	var times: Array = []
	for i in 20:
		var s := Snorkel.auto_swim(1.0, Rng.new(i + 1), false, i + 1)
		times.append(float(s.t))
	times.sort()
	assert_true(float(times[-1]) - float(times[0]) > 1.0, "perfect swims differ (%.1f to %.1f)" % [times[0], times[-1]])
	assert_true(float(times[0]) > 40.5, "the floor has not dropped far (%.1f)" % times[0])
