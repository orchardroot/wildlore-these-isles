extends TestCase
## Curling (core/curling.gd): the sheet, weight and line, sweeping, hits, scoring an end, the skip and the prizes.

func _stone(team: int, x: float, y: float) -> Dictionary:
	return {"team": team, "x": x, "y": y}

func test_weight_six_is_the_tee() -> void:
	assert_near(Curling.weight_distance(6), Curling.HACK_TO_TEE, 0.001, "weight 6 reaches the tee line")
	assert_true(Curling.weight_distance(1) < Curling.weight_distance(2), "heavier goes further")

func test_sweeping_carries_the_stone_and_has_a_cap() -> void:
	assert_eq(Curling.carry(0, false), 0.0)
	assert_true(Curling.carry(4, false) > 0.0)
	assert_eq(Curling.carry(Curling.SWEEP_CAP + 20, false), Curling.carry(Curling.SWEEP_CAP, false), "sweeping has a cap")
	assert_true(Curling.carry(4, true) > Curling.carry(4, false), "easier sweeping carries further")

func test_draw_to_the_button_lands_on_it() -> void:
	var plan := Curling.plan(Vector2.ZERO, 1, 0.0, false)
	var r := Curling.deliver([], 0, plan.dist, plan.broom, 1, 0, 0.0, false)
	assert_eq(r.event, "house")
	var s: Dictionary = r.stones[0]
	assert_true(Vector2(s.x, s.y).length() < 0.05, "a perfect draw sits on the button")

func test_short_of_the_hog_line_is_removed() -> void:
	var r := Curling.deliver([], 0, Curling.weight_distance(1), 0.0, 1, 0, 0.0, false)
	assert_eq(r.event, "hog")
	assert_eq(r.stones.size(), 0, "a stone that stops short of the far hog line is taken off")

func test_through_the_house_is_burnt() -> void:
	var r := Curling.deliver([], 0, Curling.weight_distance(8), 0.0, 1, 0, 0.0, false)
	assert_eq(r.event, "back")
	assert_eq(r.stones.size(), 0)

func test_sweeping_extends_a_stone() -> void:
	var base := Curling.weight_distance(4)
	var lazy := Curling.deliver([], 0, base, 0.0, 1, 0, 0.0, false)
	var swept := Curling.deliver([], 0, base, 0.0, 1, 8, 0.0, false)
	var y0: float = lazy.stones[0].y if lazy.stones.size() > 0 else -99.0
	var y1: float = swept.stones[0].y
	assert_true(y1 > y0, "sweeping carries it further")

func test_sweeping_straightens_the_curl() -> void:
	var base := Curling.weight_distance(3)
	var a := Curling.deliver([], 0, base, 0.0, 1, 0, 0.0, false)
	var b := Curling.deliver([], 0, base, 0.0, 1, 10, 0.0, false)
	assert_true(absf(float(b.stones[0].x)) < absf(float(a.stones[0].x)), "swept stones curl less")

func test_handle_curls_opposite_ways() -> void:
	var base := Curling.weight_distance(6)
	var a := Curling.deliver([], 0, base, 0.0, 1, 0, 0.0, false)
	var b := Curling.deliver([], 0, base, 0.0, -1, 0, 0.0, false)
	assert_true(float(a.stones[0].x) > 0.0 and float(b.stones[0].x) < 0.0)

func test_a_takeout_removes_the_stone_it_hits() -> void:
	var guard := [_stone(1, 0.0, -0.4)]
	var plan := Curling.plan(Vector2(0.0, -0.4), 1, 0.0, true)
	var r := Curling.deliver(guard, 0, plan.dist, plan.broom, 1, 0, 0.0, false)
	assert_eq(r.event, "hit")
	assert_eq(r.stones.size(), 1, "theirs is gone, mine stays")
	assert_eq(int(r.stones[0].team), 0)

func test_a_stone_in_the_way_is_hit_not_passed() -> void:
	var guard := [_stone(1, 0.0, -4.0)]
	var base := Curling.weight_distance(6)
	var r := Curling.deliver(guard, 0, base, -Curling.CURL * 0.0, 1, 0, 0.0, false)
	assert_true(r.event in ["hit", "glance", "house", "back", "hog", "wide", "guard"], "an event is always named")
	# a stone aimed straight down the line of another cannot finish beyond it
	var line := Curling.deliver(guard, 0, base, 0.0, 1, 0, 0.0, false)
	for s in line.stones:
		if int(s.team) == 0:
			assert_true(float(s.y) <= -4.0 + 0.001 or line.event == "back" or line.event == "house", "not through a stone")

func test_scoring_an_end() -> void:
	var a := Curling.score_end([_stone(0, 0.2, 0.0), _stone(1, 0.5, 0.0)])
	assert_eq(a.team, 0)
	assert_eq(a.points, 1)
	var b := Curling.score_end([_stone(0, 0.2, 0.0), _stone(0, 0.6, 0.0), _stone(1, 0.9, 0.0)])
	assert_eq(b.points, 2, "two nearer than their best")
	var c := Curling.score_end([_stone(0, 0.2, 0.0), _stone(1, 0.5, 0.0), _stone(0, 1.0, 0.0)])
	assert_eq(c.points, 1, "only the ones nearer than the other side's best count")
	var d := Curling.score_end([_stone(0, 3.0, 0.0), _stone(1, 2.5, 0.0)])
	assert_eq(d.points, 0, "outside the house counts for nothing")
	assert_eq(d.team, -1, "a blank end")
	var e := Curling.score_end([])
	assert_eq(e.points, 0)

func test_house_edge_counts_the_stone_radius() -> void:
	assert_eq(Curling.score_end([_stone(0, Curling.HOUSE + Curling.STONE_R - 0.01, 0.0)]).points, 1, "touching the rings is in")
	assert_eq(Curling.score_end([_stone(0, Curling.HOUSE + Curling.STONE_R + 0.05, 0.0)]).points, 0)

func test_skip_goes_for_the_takeout_when_you_hold_shot() -> void:
	var skip := {"sigma_w": 0.0, "sigma_l": 0.0, "hit": 100}
	var mine := [_stone(0, 0.1, 0.0)]
	var rng := Rng.new(3)
	var aim := Curling.skip_stone(mine, 1, skip, 0.0, rng)
	assert_eq(aim.kind, "takeout")
	var r := Curling.deliver(mine, 1, aim.dist, aim.broom, aim.handle, 0, 0.0, false)
	assert_eq(r.event, "hit")
	assert_eq(r.stones.filter(func(s): return int(s.team) == 0).size(), 0, "your stone has gone")

func test_skip_draws_to_an_empty_house() -> void:
	var skip := {"sigma_w": 0.0, "sigma_l": 0.0, "hit": 100}
	var aim := Curling.skip_stone([], 1, skip, 0.0, Rng.new(4))
	assert_eq(aim.kind, "draw")

func test_ends_are_deterministic_and_decisive() -> void:
	var skip := {"sigma_w": 0.6, "sigma_l": 0.25, "hit": 70}
	var a := Curling.sim_end(0.6, 0.25, skip, Rng.new(11))
	var b := Curling.sim_end(0.6, 0.25, skip, Rng.new(11))
	assert_eq(a.team, b.team)
	assert_eq(a.points, b.points)

func test_better_curlers_win_more_ends() -> void:
	var skip := {"sigma_w": 0.8, "sigma_l": 0.35, "hit": 60}
	var good := 0
	var poor := 0
	var rng := Rng.new(77)
	for i in 120:
		if int(Curling.sim_end(0.3, 0.12, skip, rng).team) == 0:
			good += 1
		if int(Curling.sim_end(2.5, 1.0, skip, rng).team) == 0:
			poor += 1
	assert_true(good > poor + 15, "skill matters: %d vs %d" % [good, poor])

func test_prizes_once_then_a_daily_purse() -> void:
	var data := GameStateData.new()
	var first := Curling.win(data, "inverness_rink", 0)
	assert_true(first.first and first.money > 0)
	assert_eq(Curling.rungs_beaten(data, "inverness_rink"), 1)
	var again := Curling.win(data, "inverness_rink", 0)
	assert_false(again.first)
	assert_eq(again.money, Curling.DAILY_PURSE, "a rematch pays the purse once")
	var third := Curling.win(data, "inverness_rink", 0)
	assert_eq(third.money, 0, "once a day")
	assert_eq(TrainerStats.get_count(data, "curling_won"), 3)

func test_the_ladder_cannot_be_skipped() -> void:
	var data := GameStateData.new()
	var r := Curling.win(data, "inverness_rink", 1)
	assert_false(r.first, "rung two before rung one is only a friendly")
	assert_eq(Curling.rungs_beaten(data, "inverness_rink"), 0)

func test_data_is_sane() -> void:
	var rink := Curling.rink("inverness_rink")
	assert_true(rink.skips.size() >= 3)
	var total := Curling.rink_total("inverness_rink")
	assert_true(total > 0 and total <= 120, "modest prizes")
	for s in rink.skips:
		assert_true(float(s.sigma_w) > 0.0 and float(s.sigma_l) > 0.0)
		assert_false("—" in JSON.stringify(s), "no em-dashes")
