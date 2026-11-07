extends TestCase
## Cheese rolling (core/cheese_roll.gd) and the pancake race (core/pancake.gd): fair, finishable, deterministic.

const DT := 1.0 / 60.0

## A steady dodger: steers away from the next obstacle in sight, and chases the cheese when nothing is close.
func _cheese_run(seed_value: int, easy := false, dodge := true, brace := false) -> CheeseRoll:
	var g := CheeseRoll.new(seed_value, easy)
	var guard := 0
	while not g.done and guard < 6000:
		var steer := 0.0
		if dodge:
			var best_o = null
			for o in g.obstacles:
				var d: float = float(o.y) - g.y
				if d > 0.0 and d < 16.0 and absf(float(o.x) - g.x) < float(o.r) + 0.3 and (best_o == null or d < float(best_o.y) - g.y):
					best_o = o
			if best_o != null:
				steer = 1.0 if g.x >= float(best_o.x) else -1.0
				if absf(g.x) > 0.8:
					steer = -signf(g.x)
			else:
				steer = clampf((float(g.cheese.x) - g.x) * 3.0 - g.camber(g.y), -1.0, 1.0)
		g.step(DT, steer, brace)
		guard += 1
	return g

func test_same_seed_same_hill() -> void:
	var a := _cheese_run(5)
	var b := _cheese_run(5)
	assert_eq(a.obstacles.size(), b.obstacles.size())
	assert_eq(a.place, b.place)
	assert_eq(a.tumbles, b.tumbles)

func test_a_clean_run_always_finishes_and_places() -> void:
	for s in 12:
		var g := _cheese_run(s + 1)
		assert_true(g.done, "seed %d finished" % s)
		assert_true(g.place >= 1 and g.place <= 4)
		assert_true(g.finish_t < 40.0, "a run takes seconds, not minutes")

func test_a_careful_player_usually_wins_a_heat_and_a_sloppy_one_does_not() -> void:
	var wins := 0
	var sloppy_wins := 0
	var sloppy_tumbles := 0
	for s in 20:
		if _cheese_run(s + 1).place == 1:
			wins += 1
		var l := _cheese_run(s + 1, false, false)
		sloppy_tumbles += l.tumbles
		if l.place == 1:
			sloppy_wins += 1
	assert_true(wins >= 8, "dodging wins often (%d of 20)" % wins)
	assert_true(wins > sloppy_wins, "dodging beats running straight (%d v %d)" % [wins, sloppy_wins])
	assert_true(sloppy_tumbles > 20, "running straight down Cooper's Hill hurts (%d tumbles)" % sloppy_tumbles)

func test_the_hill_is_passable() -> void:
	# no two obstacles close together leave less than a runner's width between them
	for s in 30:
		var g := CheeseRoll.new(s + 1)
		for o in g.obstacles:
			assert_true(absf(float(o.x)) <= 0.85)
		for i in g.obstacles.size():
			for j in range(i + 1, g.obstacles.size()):
				var a: Dictionary = g.obstacles[i]
				var b: Dictionary = g.obstacles[j]
				if absf(float(a.y) - float(b.y)) < 3.0:
					assert_true(absf(float(a.x) - float(b.x)) >= 0.75, "seed %d leaves a gap" % s)

func test_the_cheese_can_be_caught() -> void:
	var caught := 0
	for s in 30:
		if _cheese_run(s + 1).caught:
			caught += 1
	assert_true(caught >= 3 and caught < 30, "catchable, not trivial (%d of 30)" % caught)

func test_points_reward_place_the_catch_and_punish_tumbles() -> void:
	assert_eq(CheeseRoll.points_for(1, false, 0), 100)
	assert_eq(CheeseRoll.points_for(1, true, 1), 115)
	assert_eq(CheeseRoll.points_for(4, false, 9), 0)
	assert_true(CheeseRoll.points_for(2, false, 0) > CheeseRoll.points_for(1, false, 3), "a tidy second beats a battered win")

func test_easier_cheese_rolling_is_gentler() -> void:
	var hard := 0
	var easy := 0
	for s in 20:
		hard += _cheese_run(s + 1, false, false).tumbles
		easy += _cheese_run(s + 1, true, false).tumbles
	assert_true(easy < hard, "fewer tumbles when easier (%d v %d)" % [easy, hard])

# ---- pancake

func _pancake_run(seed_value: int, sprint: bool, easy := false, flip_ok := true, tilt_ok := true) -> Pancake:
	var g := Pancake.new(seed_value, easy)
	g.step(DT, 0.0, false, true)    # the starting toss
	var guard := 0
	while not g.done and guard < 20000:
		var tilt := clampf(g.p * 2.6 + g.pv * 0.7, -1.0, 1.0) if tilt_ok else 0.0
		var flip := false
		if flip_ok and g.next_station <= Pancake.STATIONS:
			var d := Pancake.station_y(g.next_station) - g.y
			flip = absf(d / maxf(g.v, Pancake.JOG)) < 0.05
		g.step(DT, tilt, sprint, flip)
		guard += 1
	return g

func test_a_steady_player_finishes_inside_the_gold_time() -> void:
	var g := _pancake_run(3, true)
	assert_true(g.done)
	assert_true(g.total() < Pancake.MASTER_TIME, "a clean sprint gets gold (%.1f s)" % g.total())
	assert_true(g.drops == 0, "and drops nothing (%d)" % g.drops)

func test_jogging_is_safer_but_slower() -> void:
	var j := _pancake_run(3, false)
	var s := _pancake_run(3, true)
	assert_true(j.total() > s.total() + 5.0, "jog %.1f v sprint %.1f" % [j.total(), s.total()])
	assert_true(j.total() < Pancake.GOOD_TIME + 8.0)

func test_not_tilting_the_pan_drops_the_pancake() -> void:
	var g := _pancake_run(3, true, false, true, false)
	assert_true(g.drops >= 2, "an untilted sprinting pan drops it (%d)" % g.drops)
	assert_true(g.total() > Pancake.MASTER_TIME)

func test_missed_flips_cost_time() -> void:
	var good := _pancake_run(4, true)
	var lazy := _pancake_run(4, true, false, false)
	assert_true(lazy.total() > good.total() + 8.0, "%.1f v %.1f" % [lazy.total(), good.total()])
	assert_eq(lazy.count("miss"), Pancake.STATIONS)

func test_easier_pancake_has_wider_windows_and_fewer_drops() -> void:
	var w := Pancake.new(1, false).windows()
	var we := Pancake.new(1, true).windows()
	assert_true(float(we.good) > float(w.good) and float(we.perfect) > float(w.perfect))
	var hard := _pancake_run(2, true, false, true, false).drops
	var easy := _pancake_run(2, true, true, true, false).drops
	assert_true(easy <= hard)

func test_the_champion_is_beatable_but_not_by_jogging_idly() -> void:
	for s in 6:
		assert_true(Pancake.champion_time(s) > Pancake.MASTER_TIME and Pancake.champion_time(s) < Pancake.GOOD_TIME)

# ---- prizes

func test_prizes_are_first_time_then_daily_and_stats_tally() -> void:
	var d := GameStateData.new()
	var a := CheeseRoll.finish_evening(d, 100, true)
	assert_true(a.first and a.money == 10)
	var b := CheeseRoll.finish_evening(d, 90, true)
	assert_true(not b.first and b.money == CheeseRoll.DAILY_PURSE)
	var c := CheeseRoll.finish_evening(d, 90, true)
	assert_eq(c.money, 0)
	assert_eq(TrainerStats.get_count(d, "cheese_wins"), 3)
	var p := Pancake.finish_race(d, 44.4, true)
	assert_true(p.first and p.record)
	assert_eq(TrainerStats.get_count(d, "pancake_best"), 444)
	assert_true(not Pancake.finish_race(d, 60.0, false).record)

func test_pieces_state_round_trips() -> void:
	var d := GameStateData.new()
	d.pieces["cheese"] = {"best": 110.0, "plays": 2, "rosette": 2}
	var back := GameStateData.from_dict(d.to_dict(), Dex.load_default())
	assert_eq(int(back.pieces.cheese.rosette), 2)

# ---- party pieces (against the contract; the stub or P's real one)

func test_g2_party_pieces_are_well_formed() -> void:
	var db := MoveDB.load_default()
	for id in ["cheese", "pancake"]:
		assert_true(PartyPieces.entries().has(id), id)
	assert_eq(PartyPieces.problems(db), [])
	assert_eq(str(db.get_move("coopers_roll").piece), "cheese")
	assert_eq(str(db.get_move("shrove_toss").piece), "pancake")

func test_g2_rosettes_follow_the_score_both_ways_round() -> void:
	var d := GameStateData.new()
	assert_eq(PartyPieces.record(d, "cheese", 40.0).rosette, 1)
	assert_true(not PartyPieces.unlocked(d, "cheese"))
	var r := PartyPieces.record(d, "cheese", 80.0)
	assert_true(r.unlocked and r.rosette == 2)
	assert_eq(PartyPieces.record(d, "cheese", 125.0).rosette, 3)
	assert_eq(PartyPieces.record(d, "pancake", 51.0).rosette, 2)   # lower is better: 51 s is silver
	assert_eq(PartyPieces.record(d, "pancake", 41.0).rosette, 3)
