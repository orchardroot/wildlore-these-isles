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
