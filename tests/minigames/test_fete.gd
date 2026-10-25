extends TestCase
## The village fete: cheese rolling, bog snorkelling and welly wanging (rules, real dates, prizes, placement).

func test_every_event_has_two_line_rules_and_a_plaque() -> void:
	for id in Fete.EVENTS:
		var e := Fete.event(id)
		assert_true(not e.is_empty(), id)
		assert_eq((e.rules as Array).size(), 2, "%s rules are two lines" % id)
		assert_true(str(e.plaque.text).length() > 60 and not ("—" in str(e.plaque.text)), "%s plaque" % id)
		assert_true(int(e.real_prize) > int(e.prize) and int(e.prize) > 0, "%s prizes" % id)

func test_real_dates() -> void:
	# Spring Bank Holiday: last Monday of May. 2026: 25 May. 2025: 26 May.
	assert_true(Fete.real_day("cheese", 5, 25, 2026))
	assert_false(Fete.real_day("cheese", 5, 26, 2026))
	assert_true(Fete.real_day("cheese", 5, 26, 2025))
	# August bank holiday weekend: Sat-Mon around the last Monday of August. 2026: 31 Aug.
	assert_true(Fete.real_day("bog", 8, 29, 2026))
	assert_true(Fete.real_day("bog", 8, 31, 2026))
	assert_false(Fete.real_day("bog", 8, 28, 2026))
	# Welly wanging: fete season Saturdays, June to August. 2026-07-04 is a Saturday.
	assert_true(Fete.real_day("welly", 7, 4, 2026))
	assert_false(Fete.real_day("welly", 7, 5, 2026))
	assert_false(Fete.real_day("welly", 11, 7, 2026))

func test_cheese_course_is_seeded_and_judged() -> void:
	var a := Fete.cheese_course(Rng.new(5))
	assert_eq(a, Fete.cheese_course(Rng.new(5)))
	assert_eq(a.size(), Fete.GATES)
	for d in a:
		assert_true(d == -1 or d == 1)
	assert_true(Fete.cheese_judge(1, 1, 0.1, false))
	assert_false(Fete.cheese_judge(-1, 1, 0.0, false), "wrong way")
	assert_false(Fete.cheese_judge(1, 1, 0.7, false), "too late")
	assert_true(Fete.cheese_judge(1, 1, 0.7, true), "easier is wider")
	assert_true(Fete.dive_ok(0.6, false))
	assert_false(Fete.dive_ok(0.1, false))
	assert_true(Fete.dive_ok(0.35, true))

func test_cheese_times_and_places() -> void:
	var clean := Fete.cheese_time(0, true)
	assert_true(clean < Fete.cheese_time(1, true) and Fete.cheese_time(1, true) < Fete.cheese_time(1, false))
	var rivals := Fete.cheese_rivals(Rng.new(3), false)
	assert_eq(rivals.size(), 3)
	assert_eq(Fete.place(clean, rivals), 1, "a clean dive wins")
	assert_eq(Fete.place(Fete.cheese_time(1, true), rivals), 1, "one stumble still wins")
	assert_eq(Fete.place(99.0, rivals), 4)

func test_bog_pattern_and_time() -> void:
	var p := Fete.bog_pattern(Rng.new(9))
	assert_eq(p, Fete.bog_pattern(Rng.new(9)))
	assert_eq(p.size(), Fete.BOG_LENGTHS * Fete.BOG_BEATS)
	assert_eq(p[0], "k")
	assert_true(p.has("b"))
	for i in range(1, p.size()):
		assert_false(p[i] == "b" and p[i - 1] == "b", "no two breaths in a row")
	assert_true(Fete.bog_beat(true).window > Fete.bog_beat(false).window)
	assert_true(Fete.bog_time(0) <= Fete.BOG_TARGET and Fete.bog_time(2) <= Fete.BOG_TARGET)
	assert_true(Fete.bog_time(Fete.BOG_LENGTHS * Fete.BOG_BEATS) > Fete.BOG_TARGET)

func test_welly_distance() -> void:
	assert_near(Fete.sweep(0.0, 2.0), 0.0)
	assert_near(Fete.sweep(1.0, 2.0), 1.0)
	assert_near(Fete.sweep(2.0, 2.0), 0.0)
	var best := Fete.welly_distance(1.0, 45.0, 0.0)
	assert_true(best > Fete.WELLY_TARGET, "a full 45 degree wang wins")
	assert_true(Fete.welly_distance(1.0, 20.0, 0.0) < best and Fete.welly_distance(1.0, 80.0, 0.0) < best)
	assert_true(Fete.welly_distance(0.8, 45.0, 3.0) > Fete.welly_distance(0.8, 45.0, -3.0), "tailwind helps")
	assert_true(Fete.welly_distance(0.0, 45.0, 0.0) < 10.0)
	var w := Fete.wind(Rng.new(2))
	assert_true(absf(w) <= 3.0)

func test_win_pays_once_a_day_and_more_on_the_real_date() -> void:
	var d := GameStateData.new()
	var first := Fete.win(d, "cheese", false)
	assert_true(first.first)
	assert_eq(first.prize, int(Fete.event("cheese").prize))
	assert_eq(TrainerStats.get_count(d, "fete_won"), 1)
	assert_eq(Fete.win(d, "cheese", false).prize, 0, "once a day")
	assert_true(Fete.won_today(d, "cheese"))
	var e := GameStateData.new()
	assert_eq(Fete.win(e, "bog", true).prize, int(Fete.event("bog").real_prize))

func test_stewards_stand_on_open_ground() -> void:
	for id in Fete.EVENTS:
		var e := Fete.event(id)
		var z := ZoneData.load_id(str(e.zone))
		assert_true(not z.id.is_empty(), "%s zone exists" % id)
		var found := false
		for n in z.npcs:
			if str(n.id) == str(e.npc):
				found = true
				assert_true(z.walkable(Vector2i(int(n.x), int(n.y))), "%s steward tile walkable" % id)
				assert_eq(str(n.script), str(e.npc))
		assert_true(found, "%s steward placed" % id)
		for n in z.npcs:
			for m in z.npcs:
				if n != m:
					assert_false(n.x == m.x and n.y == m.y, "no stacked npcs in %s" % z.id)
