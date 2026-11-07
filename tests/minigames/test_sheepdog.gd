extends TestCase
## Sheepdog trials (core/sheepdog.gd): the flock behaves, a steady bot can pen it, a clumsy one cannot, and the money.

func _bot_move(st: Dictionary) -> Vector2:
	var live: Array = []
	for s in st.sheep:
		if not s.penned:
			live.append(s)
	if live.is_empty():
		return Vector2.ZERO
	var c := Vector2.ZERO
	for s in live:
		c += s.p
	c /= float(live.size())
	var goal := Vector2(20.0, 20.0)
	for g in st.gates:
		var gx := float(g.x)
		var behind := 0
		for s in live:
			if s.p.x > gx:
				behind += 1
		if behind > 0:
			goal = Vector2(gx - 4.0, float(g.y))
	var dir_c: Vector2 = (c - goal).normalized()
	var want: Vector2 = c + dir_c * 9.0
	var to_dog: Vector2 = st.dog - c
	if to_dog.dot(dir_c) < 2.0 and to_dog.length() < 18.0:
		var perp := Vector2(-dir_c.y, dir_c.x)
		if perp.dot(want - st.dog) < 0.0:
			perp = -perp
		return (perp + to_dog.normalized() * 0.5).normalized()
	return (want - st.dog).limit_length(1.0) if (want - st.dog).length() > 1.0 else Vector2.ZERO

func _play(venue_id: String, seed_: int, steady := true, easy := false) -> Dictionary:
	var rng := Rng.new(seed_)
	var st := Sheepdog.start(Sheepdog.venue(venue_id), easy, rng)
	var dt := 1.0 / 30.0
	while not st.done:
		var mv := _bot_move(st) if steady else Vector2(1, 0)
		Sheepdog.step(st, dt, mv, false, false)
	return st

func test_the_venues_are_well_formed() -> void:
	assert_true(Sheepdog.venues().size() >= 2)
	for id in Sheepdog.venues():
		var v := Sheepdog.venue(id)
		assert_true(v.has("rival") and v.has("real") and v.has("prize"), id)
		assert_true(v.gates.size() >= 1)

func test_a_run_is_repeatable_for_a_seed() -> void:
	var a := _play("longshaw", 5)
	var b := _play("longshaw", 5)
	assert_eq(a.penned, b.penned)
	assert_eq(a.t, b.t)

func test_a_steady_dog_pens_most_of_the_flock() -> void:
	for id in Sheepdog.venues():
		var total := 0
		for seed_ in 5:
			total += int(_play(id, seed_ + 1).penned)
		assert_true(total >= 5 * 5, "%s: a steady bot penned %d of 35 over five runs" % [id, total])

func test_a_dog_that_just_charges_does_not() -> void:
	var total := 0
	for seed_ in 4:
		total += int(_play("longshaw", seed_ + 1, false).penned)
	assert_true(total <= 4, "charging in a straight line penned %d" % total)

func test_easier_trials_help() -> void:
	var hard := 0
	var easy := 0
	for seed_ in 4:
		hard += int(_play("lakes", seed_ + 1).penned)
		easy += int(_play("lakes", seed_ + 1, true, true).penned)
	assert_true(easy >= hard, "easy %d vs %d" % [easy, hard])

func test_nothing_leaves_the_field_or_the_fences() -> void:
	var st := _play("lakes", 3)
	for s in st.sheep:
		assert_true(s.p.x >= 0.0 and s.p.y >= 0.0 and s.p.x <= Sheepdog.FIELD.x and s.p.y <= Sheepdog.FIELD.y)
		assert_false(Sheepdog.blocked(st.walls, s.p, 0.0) and not s.penned, "a sheep is inside a fence")

func test_lying_down_calms_the_flock() -> void:
	var st := Sheepdog.start(Sheepdog.venue("longshaw"), false, Rng.new(2))
	st.dog = (st.sheep[0].p as Vector2) + Vector2(8, 0)
	var s0: Vector2 = st.sheep[0].p
	for i in 30:
		Sheepdog.step(st, 1.0 / 30.0, Vector2.ZERO, false, true)
	assert_true((st.sheep[0].p as Vector2).distance_to(s0) < 4.0, "a lying dog at 8 units barely moves them")

func test_score_orders_by_sheep_then_time() -> void:
	var st := Sheepdog.start(Sheepdog.venue("longshaw"), false, Rng.new(1))
	st.penned = 4
	var a := Sheepdog.score(st)
	st.penned = 7
	st.t = 50.0
	var b := Sheepdog.score(st)
	st.t = 100.0
	assert_true(b > a and Sheepdog.score(st) > b - 1.0 and Sheepdog.score(st) < b)

func test_prize_once_then_a_daily_purse() -> void:
	var d := GameStateData.new()
	var f := Sheepdog.finish(d, "longshaw", 7, true)
	assert_true(f.first and f.money == 14)
	var g := Sheepdog.finish(d, "longshaw", 6, true)
	assert_false(g.first)
	assert_eq(g.money, Sheepdog.DAILY_PURSE)
	assert_eq(Sheepdog.finish(d, "longshaw", 6, true).money, 0)
	assert_eq(Sheepdog.finish(d, "longshaw", 2, false).money, 0)
