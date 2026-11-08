extends TestCase
## Poohsticks (core/poohsticks.gd): the river, the drop, the local and the money.

func test_the_middle_runs_faster_than_the_banks() -> void:
	var v := Poohsticks.venue("oxford")
	var rng := Rng.new(3)
	var mid := 0.0
	var bank := 0.0
	for i in 100:
		var r := Poohsticks.river(v, rng)
		mid += float(r.speed[3])
		bank += float(r.speed[1])
	assert_true(mid > bank * 1.2, "centre beats the bank on average")

func test_a_drop_is_repeatable_for_a_seed() -> void:
	var r := Poohsticks.river(Poohsticks.venue("oxford"), Rng.new(8))
	var a := Poohsticks.run(r, 3, Poohsticks.stick(1), Rng.new(4))
	var b := Poohsticks.run(r, 3, Poohsticks.stick(1), Rng.new(4))
	assert_eq(a.time, b.time)

func test_a_snag_slows_a_light_stick_more_than_a_heavy_one() -> void:
	var r := {"speed": [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5], "snag": 3, "eddy": -1}
	var rng := Rng.new(1)
	var light := 0
	var heavy := 0
	for i in 300:
		if Poohsticks.run(r, 3, Poohsticks.stick(0), rng).snagged:
			light += 1
		if Poohsticks.run(r, 3, Poohsticks.stick(2), rng).snagged:
			heavy += 1
	assert_true(light > heavy * 2, "willow %d vs oak %d" % [light, heavy])

func test_reading_the_water_wins_most_races() -> void:
	var v := Poohsticks.venue("oxford")
	var rng := Rng.new(12)
	var wins := 0
	for i in 200:
		var r := Poohsticks.river(v, rng)
		var mine: float = Poohsticks.run(r, Poohsticks.best_lane(r), Poohsticks.stick(1), rng).time
		var theirs: float = Poohsticks.run(r, 0, Poohsticks.stick(1), rng).time
		if mine < theirs:
			wins += 1
	assert_true(wins > 150, "best lane beats a bank lane (%d/200)" % wins)

func test_the_local_is_beatable_and_not_hopeless() -> void:
	for id in Poohsticks.venues():
		var v := Poohsticks.venue(id)
		var rng := Rng.new(5)
		var wins := 0
		for i in 300:
			var r := Poohsticks.river(v, rng)
			var mine: float = Poohsticks.run(r, Poohsticks.best_lane(r), Poohsticks.stick(1), rng).time
			var theirs: float = Poohsticks.run(r, Poohsticks.local_lane(r, float(v.rival.skill), rng), Poohsticks.stick(1), rng).time
			if mine < theirs:
				wins += 1
		assert_true(wins > 90 and wins < 270, "%s: perfect reading wins %d/300" % [id, wins])

func test_rewards() -> void:
	var d := GameStateData.new()
	var f := Poohsticks.finish(d, "oxford", true)
	assert_true(f.first)
	assert_eq(f.money, 10)
	assert_eq(Poohsticks.finish(d, "oxford", true).money, Poohsticks.DAILY_PURSE)
	assert_eq(Poohsticks.finish(d, "oxford", false).money, 0)
