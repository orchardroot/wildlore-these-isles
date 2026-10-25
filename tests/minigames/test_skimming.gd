extends TestCase
## Stone skimming (core/skimming.gd): the throw, the sweet spot, the stones, the locals and the money.

func _mean(st_id: String, angle: float, power: float, n := 400, wobble := 1.0) -> float:
	var rng := Rng.new(3)
	var st := Skimming.stone(st_id)
	var t := 0
	for i in n:
		t += int(Skimming.skim(st, angle, power, rng, wobble).skips)
	return float(t) / n

func test_a_throw_is_repeatable_for_a_seed() -> void:
	var st := Skimming.stone("slate_thin")
	var a := Skimming.skim(st, 20.0, 0.8, Rng.new(42))
	var b := Skimming.skim(st, 20.0, 0.8, Rng.new(42))
	assert_eq(a.skips, b.skips)
	assert_eq(a.hops, b.hops)
	assert_eq(a.hops.size(), a.skips, "one hop per skip")

func test_a_steep_stone_sinks_at_once() -> void:
	var r := Skimming.skim(Skimming.stone("slate_thin"), 44.0, 1.0, Rng.new(1))
	assert_eq(r.skips, 0)
	assert_eq(r.sank, "steep")

func test_about_twenty_degrees_is_best() -> void:
	var good := _mean("slate_thin", 20.0, 0.85)
	assert_true(good > _mean("slate_thin", 8.0, 0.85) + 1.5, "much flatter is worse (%.1f)" % good)
	assert_true(good > _mean("slate_thin", 32.0, 0.85) + 2.0, "much steeper is worse")
	assert_true(good > _mean("slate_thin", 40.0, 0.85) + 4.0)

func test_power_helps_up_to_a_point() -> void:
	assert_true(_mean("slate_thin", 20.0, 1.0) > _mean("slate_thin", 20.0, 0.1) + 3.0, "a feeble throw dies fast")

func test_the_stone_matters() -> void:
	var slate := _mean("slate_thin", 20.0, 0.85)
	var pebble := _mean("pebble", 20.0, 0.85)
	var lump := _mean("round", 20.0, 0.85)
	assert_true(slate > pebble + 1.0 and pebble > lump + 0.5, "slate %.1f > pebble %.1f > round lump %.1f" % [slate, pebble, lump])

func test_hops_shorten() -> void:
	var rng := Rng.new(2)
	var found := false
	for i in 60:
		var r := Skimming.skim(Skimming.stone("slate_thin"), 20.0, 1.0, rng)
		if r.hops.size() >= 6:
			found = true
			assert_true(float(r.hops[0]) > float(r.hops[r.hops.size() - 1]), "the last hop is shorter than the first")
			break
	assert_true(found, "a good throw gets six skips")

func test_easier_skimming_is_steadier() -> void:
	assert_true(_mean("pebble", 20.0, 0.85, 400, Skimming.wobble_scale(true)) > _mean("pebble", 20.0, 0.85, 400, 1.0))

func test_advice_names_the_fault() -> void:
	assert_true(Skimming.advice({"skips": 0, "sank": "steep"}, 40.0).contains("flatter"))
	assert_true(Skimming.advice({"skips": 1, "sank": "slow"}, 5.0).contains("20"))
	assert_true(Skimming.advice({"skips": 9, "sank": "slow"}, 20.0).contains("proper"))

func test_locals_are_beatable_but_not_pushovers() -> void:
	for v in Skimming.venues():
		var rival: Dictionary = Skimming.venue(v).rival
		var rng := Rng.new(7)
		var theirs := 0
		var mine := 0
		var wins := 0
		var n := 200
		for i in n:
			var b := Skimming.local_best(rival, rng)
			theirs += b
			var m := 0
			for t in Skimming.THROWS:
				m = maxi(m, int(Skimming.skim(Skimming.stone("slate_thin"), 20.0, 0.85, rng).skips))
			mine += m
			if m > b:
				wins += 1
		assert_true(theirs / n >= 5, "%s's local skims properly (%d)" % [v, theirs / n])
		assert_true(float(wins) / n > 0.3, "a sound player beats %s often enough (%d%%)" % [v, wins * 100 / n])
		assert_true(float(wins) / n < 0.9, "but not always (%d%%)" % (wins * 100 / n))

func test_data_is_sound() -> void:
	assert_eq(Skimming.stones().size(), 4)
	assert_eq(Skimming.venues().size(), 2)
	assert_false("—" in JSON.stringify(Skimming.cfg()), "no em-dashes")
	for id in Skimming.venues():
		assert_true(int(Skimming.venue(id).prize) <= 20)
		assert_false(Skimming.stone(str(Skimming.venue(id).rival.stone)).is_empty())

func test_prizes_and_best() -> void:
	var d := GameStateData.new()
	var r := Skimming.finish(d, "easdale", 5, false)
	assert_true(r.record)
	assert_eq(r.money, 0)
	assert_eq(Skimming.best(d), 5)
	r = Skimming.finish(d, "easdale", 4, true)
	assert_false(r.record, "4 is not a new best")
	assert_true(r.first)
	assert_eq(r.money, int(Skimming.venue("easdale").prize))
	r = Skimming.finish(d, "easdale", 9, true)
	assert_true(r.record)
	assert_eq(r.money, Skimming.DAILY_PURSE)
	assert_eq(Skimming.finish(d, "easdale", 3, true).money, 0, "once a day")
	assert_eq(Skimming.best(d), 9)
	assert_eq(TrainerStats.sanitise(d.stats).skims_best, 9)
