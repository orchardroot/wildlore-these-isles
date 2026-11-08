extends TestCase
## Coracle racing (core/coracle.gd): strokes, spin, gates, the banks and the locals.

func _course() -> Dictionary:
	return Coracle.venue("ironbridge").course

func test_alternate_strokes_go_straighter_than_one_side() -> void:
	var c := _course()
	var s := Coracle.fresh(c)
	Coracle.paddle(s, "l")
	var a := float(s.spin)
	s.cool = 0.0
	Coracle.paddle(s, "r")
	assert_true(absf(float(s.spin)) < absf(a), "left then right cancels the spin")
	var t := Coracle.fresh(c)
	for i in 4:
		t.cool = 0.0
		Coracle.paddle(t, "l")
	assert_true(absf(float(t.spin)) > 3.0, "one side only spins the boat")

func test_stroke_has_a_cooldown() -> void:
	var s := Coracle.fresh(_course())
	assert_true(Coracle.paddle(s, "l"))
	assert_false(Coracle.paddle(s, "r"))

func test_gates_clear_or_miss_by_position() -> void:
	var c := _course()
	var gl := Coracle.gates(c)
	var s := Coracle.fresh(c)
	s.p = Vector2(float(gl[0].x) - 0.01, float(gl[0].y))
	s.v = Vector2(1.0, 0.0)
	assert_true(Coracle.step(s, c, gl, 0.1).has("gate"))
	s.p = Vector2(float(gl[1].x) - 0.01, float(gl[1].y) + float(gl[1].gap))
	s.v = Vector2(1.0, 0.0)
	assert_true(Coracle.step(s, c, gl, 0.1).has("miss"))
	assert_eq(int(s.misses), 1)
	assert_true(Coracle.score(s) >= Coracle.MISS_PENALTY)

func test_easy_widens_the_gates() -> void:
	assert_true(float(Coracle.gates(_course(), true)[0].gap) > float(Coracle.gates(_course(), false)[0].gap))

func test_the_banks_stop_you() -> void:
	var c := _course()
	var gl := Coracle.gates(c)
	var s := Coracle.fresh(c)
	s.p = Vector2(10.0, Coracle.centre(c, 10.0) + 30.0)
	var ev := Coracle.step(s, c, gl, 0.05)
	assert_true(ev.has("bump"))
	assert_true(absf(float(s.p.y) - Coracle.centre(c, float(s.p.x))) <= float(c.width) * 0.5 + 0.01)

func test_a_helmsman_finishes_and_a_spinner_does_not_beat_the_local() -> void:
	var c := _course()
	var local := float(Coracle.venue("ironbridge").rival.time)
	var good := Coracle.auto_paddle(c, 1.0, Rng.new(1))
	assert_true(bool(good.done), "a steady helmsman finishes")
	assert_true(Coracle.score(good) < local + 12.0, "within reach of the local (%.1f)" % Coracle.score(good))
	var spin := Coracle.auto_paddle(c, 1.0, Rng.new(2), true)
	assert_true(not bool(spin.done) or Coracle.score(spin) > local, "paddling one side is slow")

func test_finish_pays_once_then_daily() -> void:
	var d := GameStateData.new()
	assert_true(bool(Coracle.finish(d, "ironbridge", 35.0, true).first))
	assert_eq(int(Coracle.finish(d, "ironbridge", 36.0, true).money), Coracle.DAILY_PURSE)
	assert_eq(int(Coracle.finish(d, "ironbridge", 36.0, true).money), 0)
	assert_eq(Coracle.best(d), 350)

func test_each_seed_gives_its_own_river_and_the_plain_one_is_even() -> void:
	var c := _course()
	var plain := Coracle.fresh(c)
	assert_eq(Coracle.current_at(plain, c, Vector2(20.0, Coracle.centre(c, 20.0))), Coracle.CURRENT)
	assert_eq(Coracle.current_at(plain, c, Vector2(60.0, Coracle.centre(c, 60.0) + 5.0)), Coracle.CURRENT)
	var lo := 99.0
	var hi := 0.0
	for i in 30:
		var s := Coracle.fresh(c, i + 1)
		var cur := Coracle.current_at(s, c, Vector2(40.0, Coracle.centre(c, 40.0)))
		lo = minf(lo, cur)
		hi = maxf(hi, cur)
	assert_true(hi > lo * 1.5, "the river runs differently from day to day (%.2f to %.2f)" % [lo, hi])

func test_mid_channel_runs_faster_than_under_the_bank() -> void:
	var c := _course()
	var s := Coracle.fresh(c, 7)
	var x := 30.0
	var mid := Coracle.current_at(s, c, Vector2(x, Coracle.centre(c, x)))
	var bank := Coracle.current_at(s, c, Vector2(x, Coracle.centre(c, x) + float(c.get("width", 22.0)) * 0.5))
	assert_true(mid > bank * 1.5, "a good line rides the stream (%.2f v %.2f)" % [mid, bank])

func test_a_skilled_helmsman_has_run_to_run_spread_without_a_lower_floor() -> void:
	var c := _course()
	var times: Array = []
	for i in 12:
		var s := Coracle.fresh(c, 500 + i)
		var gl := Coracle.gates(c)
		var side := "l"
		var guard := 0
		while not bool(s.done) and guard < 6000:
			guard += 1
			if float(s.cool) <= 0.0:
				var gi := mini(int(s.gate), gl.size() - 1)
				var target := float(gl[gi].y) if int(s.gate) < gl.size() else Coracle.centre(c, float(s.p.x))
				var err := wrapf(float(s.h), -PI, PI)
				var want := clampf((target - float(s.p.y)) * 0.08, -0.5, 0.5)
				if err < want - 0.05:
					side = "l"
				elif err > want + 0.05:
					side = "r"
				else:
					side = "r" if side == "l" else "l"
				Coracle.paddle(s, side)
			Coracle.step(s, c, gl, 0.05)
		times.append(Coracle.score(s))
	times.sort()
	assert_true(float(times[-1]) - float(times[0]) > 0.8, "good runs differ (%.1f to %.1f)" % [times[0], times[-1]])
	assert_true(float(times[0]) > 22.0, "and the floor has not dropped far (%.1f)" % times[0])

func test_a_tie_reads_as_a_dead_heat() -> void:
	# w52: equal times to the tenth showed a silver rosette with "Not this time."
	var screen = load("res://ui/coracle_screen.gd")
	assert_true(str(screen._verdict(27.6, 27.6, false)).contains("dead heat"))
	assert_eq(str(screen._verdict(26.0, 27.6, true)), " You win by 1.6 seconds.")
	assert_eq(str(screen._verdict(29.0, 27.6, false)), " Not this time.")
	assert_true(str(load("res://ui/snorkel_screen.gd")._verdict(40.0, 40.0, false)).contains("dead heat"))
