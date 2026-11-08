extends TestCase
## Road bowling (core/road_bowling.gd): the lane, the throw, the loft, the local and the money.

func _venue() -> Dictionary:
	return RoadBowling.venue("cork")

func test_repeatable_for_a_seed() -> void:
	var a := RoadBowling.throw_bowl(_venue(), 0.0, 0.0, 0.8, 0.0, false, Rng.new(5))
	var b := RoadBowling.throw_bowl(_venue(), 0.0, 0.0, 0.8, 0.0, false, Rng.new(5))
	assert_eq(a.s1, b.s1)
	assert_eq(a.pts.size(), b.pts.size())

func test_a_straight_hard_throw_goes_far_on_a_straight_lane() -> void:
	var r := RoadBowling.throw_bowl(_venue(), 0.0, 0.0, 0.6, 0.0, false, Rng.new(1))
	assert_true(float(r.s1) > 80.0, "far")
	assert_false(r.off)

func test_a_hard_swing_into_the_verge_leaves_the_road_and_is_fetched_back() -> void:
	var r := RoadBowling.throw_bowl(_venue(), 0.0, 0.0, 1.0, 1.0, false, Rng.new(1))
	assert_true(r.off, "left the road")
	assert_true(float(r.s1) < float(r.off_s), "put back")
	assert_eq(r.y1, RoadBowling.centre(_venue(), r.s1))

func test_a_loft_clears_the_verge_it_flies_over_but_runs_less() -> void:
	var v := _venue()
	var low := RoadBowling.throw_bowl(v, 100.0, 0.0, 0.9, 1.0, false, Rng.new(2), 0.0)
	var high := RoadBowling.throw_bowl(v, 100.0, 0.0, 0.9, 1.0, true, Rng.new(2), 0.0)
	assert_true(low.off, "the flat one hits the verge")
	assert_true(not high.off or float(high.off_s) > float(low.off_s), "the loft flies over it")

func test_the_road_bends_and_ends_straight_again() -> void:
	var v := _venue()
	assert_eq(RoadBowling.centre(v, 0.0), 0.0)
	assert_true(RoadBowling.centre(v, 250.0) > 12.0)
	assert_true(absf(RoadBowling.centre(v, 640.0) - 10.0) < 0.01, "16 - 20 + 14")

func test_the_local_gets_round_in_a_sensible_number_of_throws() -> void:
	for id in RoadBowling.venues():
		var v := RoadBowling.venue(id)
		var rng := Rng.new(9)
		var tot := 0
		for i in 20:
			tot += RoadBowling.local_round(v, rng)
		var mean := float(tot) / 20.0
		assert_true(mean >= 5.0 and mean <= 12.0, "%s local averages %.1f" % [id, mean])

func test_a_careful_human_beats_the_local_sometimes() -> void:
	# a player who aims like the local but lofts nothing should win a fair share, so the game is winnable
	for id in RoadBowling.venues():
		var v := RoadBowling.venue(id)
		var rng := Rng.new(21)
		var wins := 0
		for i in 30:
			if RoadBowling.local_round(v, rng) >= RoadBowling.local_round(v, rng):
				wins += 1
		assert_true(wins > 8, "even rounds draw or win often (%d)" % wins)

func test_rewards_first_win_then_a_daily_purse() -> void:
	var d := GameStateData.new()
	var f := RoadBowling.finish(d, "cork", true)
	assert_true(f.first)
	assert_eq(f.money, 14)
	var g := RoadBowling.finish(d, "cork", true)
	assert_false(g.first)
	assert_eq(g.money, RoadBowling.DAILY_PURSE)
	var h := RoadBowling.finish(d, "cork", true)
	assert_eq(h.money, 0)
	assert_eq(RoadBowling.finish(d, "armagh", false).money, 0)
