extends TestCase
## Crown green bowls (core/bowls.gd): the wood's path, the crown and bias, scoring an end, the match, the locals and
## the money.

func _mean_skill(side: float, weight: float, rival_id: String, n: int, seed_value: int) -> float:
	var rng := Rng.new(seed_value)
	var rival: Dictionary = Bowls.venue(rival_id).rival
	var me := {"side": side, "weight": weight}
	var net := 0.0
	for i in n:
		var r := Bowls.sim_end(me, rival, i % 2 == 0, rng)
		if r.winner == "me":
			net += float(r.shots)
		elif r.winner == "them":
			net -= float(r.shots)
	return net / n

func test_a_flat_straight_wood_runs_its_weight() -> void:
	var r := Bowls.roll_wood(Vector2(10.0, 10.0), 0.0, 12.0, 0)
	var end: Vector2 = r.end
	assert_near(end.x, 10.0, 0.4, "no bias, off the crown: it runs straight")
	assert_near(10.0 - end.y, 12.0, 0.6, "and stops about its weight away")

func test_bias_curves_the_wood_towards_its_side() -> void:
	var right: Vector2 = Bowls.roll_wood(Bowls.MAT, 0.0, 20.0, 1).end
	var left: Vector2 = Bowls.roll_wood(Bowls.MAT, 0.0, 20.0, -1).end
	assert_true(right.x > 0.5, "bias right curves right: %s" % right)
	assert_true(left.x < -0.5, "bias left curves left")
	assert_near(right.x, -left.x, 0.05, "the two hands are mirror images off the middle line")

func test_a_wood_curves_more_late_in_its_run() -> void:
	var p: PackedVector2Array = Bowls.roll_wood(Bowls.MAT, 0.0, 20.0, 1).path
	var early := p[p.size() / 4].x - p[0].x
	var late := p[p.size() - 1].x - p[p.size() * 3 / 4].x
	assert_true(late > early * 2.0, "most of the bend comes as it slows (early %.2f late %.2f)" % [early, late])

func test_the_crown_pushes_a_wood_downhill() -> void:
	var up: Vector2 = Bowls.roll_wood(Vector2(1.0, 4.0), 0.0, 5.0, 0).end   # climbs past the crown on its right side
	assert_true(up.x > 1.0, "it is shoved away from the middle")
	var far: Vector2 = Bowls.roll_wood(Vector2(12.0, 4.0), 0.0, 5.0, 0).end  # off the crown: nothing
	assert_near(far.x, 12.0, 0.05)

func test_aim_at_finds_the_jack_for_either_hand() -> void:
	for jack in [Vector2(0, -6), Vector2(4, -10), Vector2(-5, -3)]:
		for bias in [-1, 1]:
			var aim := Bowls.aim_at(Bowls.MAT, jack, bias)
			var end: Vector2 = Bowls.roll_wood(Bowls.MAT, float(aim.heading), float(aim.weight), bias).end
			assert_true(end.distance_to(jack) < 0.15, "lands within a hand's breadth of %s (bias %d): %.3f" % [jack, bias, end.distance_to(jack)])

func test_jack_is_clamped_to_a_legal_length_and_the_green() -> void:
	var short := Bowls.jack_spot(Vector2(0, 12))
	assert_near(short.distance_to(Bowls.MAT), Bowls.JACK_MIN, 0.01, "no shorter than the minimum")
	var far := Bowls.jack_spot(Vector2(0, -40))
	assert_true(far.distance_to(Bowls.MAT) <= Bowls.JACK_MAX + 0.01)
	assert_false(Bowls.dead(far), "and still on the green")
	assert_true(Bowls.dead(Vector2(18.0, 0.0)))

func test_scoring_an_end() -> void:
	var j := Vector2(0, -8)
	var r := Bowls.score_end(j, [Vector2(0, -7), Vector2(1, -8)], [Vector2(3, -8), Vector2(-4, -8)])
	assert_eq(r.winner, "me")
	assert_eq(r.shots, 2, "both of mine beat their nearest")
	r = Bowls.score_end(j, [Vector2(0, -7), Vector2(5, -8)], [Vector2(0.4, -8), Vector2(-4, -8)])
	assert_eq(r.winner, "them")
	assert_eq(r.shots, 1)
	r = Bowls.score_end(j, [Vector2(0, -7)], [Vector2(0, -9)])
	assert_eq(r.winner, "none", "an exact tie scores nothing")
	r = Bowls.score_end(j, [Vector2(30, 0)], [Vector2(10, -8)])
	assert_eq(r.winner, "them", "a dead wood never scores")
	assert_eq(r.shots, 1)
	r = Bowls.score_end(j, [Vector2(30, 0)], [Vector2(-30, 0)])
	assert_eq(r.winner, "none", "nothing live at all")

func test_the_match_runs_three_ends_then_extra_if_level() -> void:
	assert_eq(Bowls.match_state(2, 0, 2), "play")
	assert_eq(Bowls.match_state(3, 1, 3), "me")
	assert_eq(Bowls.match_state(1, 4, 3), "them")
	assert_eq(Bowls.match_state(2, 2, 3), "play", "level: an extra end")
	assert_eq(Bowls.match_state(2, 2, 3 + Bowls.MAX_EXTRA), "draw", "and then a draw")
	assert_eq(Bowls.match_state(3, 2, 4), "me")
	assert_eq(Bowls.jack_setter(0), "me")
	assert_eq(Bowls.jack_setter(1), "them")

func test_who_bowls_next() -> void:
	var j := Vector2(0, -8)
	assert_eq(Bowls.next_to_play(j, [], [], "me"), "me")
	assert_eq(Bowls.next_to_play(j, [Vector2(0, -7)], [], "me"), "them")
	assert_eq(Bowls.next_to_play(j, [Vector2(0, -2)], [Vector2(0, -7)], "me"), "me", "the one further away goes")
	assert_eq(Bowls.next_to_play(j, [Vector2(0, -7), Vector2(0, -6)], [Vector2(0, -2)], "me"), "them")
	assert_eq(Bowls.next_to_play(j, [Vector2(0, -7), Vector2(0, -6)], [Vector2(0, -2), Vector2(0, -3)], "me"), "", "end over")

func test_seeded_play_is_repeatable() -> void:
	var a := Bowls.local_wood(Vector2(1, -7), Bowls.venue("waterloo").rival, Rng.new(9))
	var b := Bowls.local_wood(Vector2(1, -7), Bowls.venue("waterloo").rival, Rng.new(9))
	assert_eq(a.end, b.end)
	assert_true(Bowls.steadiness(true).side < Bowls.steadiness(false).side, "easier bowls steadies the hand")

func test_a_steady_player_beats_the_locals_more_often_than_not() -> void:
	for v in Bowls.venues():
		var normal := _mean_skill(float(Bowls.steadiness(false).side), float(Bowls.steadiness(false).weight), v, 40, 11)
		var easy := _mean_skill(float(Bowls.steadiness(true).side), float(Bowls.steadiness(true).weight), v, 40, 11)
		assert_true(easy > normal - 0.15, "easier is never worse: %s" % v)
		assert_true(easy > 0.0, "easy beats %s on shots (%.2f)" % [v, easy])
		assert_true(normal > 0.0, "a true normal hand wins on shots at %s (%.2f)" % [v, normal])

func test_data_is_sound() -> void:
	assert_eq(Bowls.venues().size(), 4)
	for id in Bowls.venues():
		var v: Dictionary = Bowls.venue(id)
		for k in ["name", "prize", "rival"]:
			assert_true(v.has(k), "%s has %s" % [id, k])
		for k in ["who", "side", "weight", "intro", "beaten"]:
			assert_true(v.rival.has(k), "%s rival has %s" % [id, k])
		assert_false("—" in JSON.stringify(v), "no em-dashes")
		assert_true(int(v.prize) <= 20, "prizes are modest")

func test_prizes_and_stats() -> void:
	var d := GameStateData.new()
	var lost := Bowls.finish(d, "waterloo", 1, false)
	assert_eq(lost.money, 0)
	assert_eq(Bowls.ends_won(d), 1, "ends count even in a loss")
	var first := Bowls.finish(d, "waterloo", 2, true)
	assert_true(first.first)
	assert_eq(first.money, int(Bowls.venue("waterloo").prize))
	assert_true(Bowls.beaten(d, "waterloo"))
	var again := Bowls.finish(d, "waterloo", 2, true)
	assert_false(again.first)
	assert_eq(again.money, Bowls.DAILY_PURSE, "then the daily purse")
	assert_eq(Bowls.finish(d, "waterloo", 3, true).money, 0, "once a day")
	assert_eq(Bowls.ends_won(d), 8)
	assert_eq(Bowls.finish(d, "cheshire", 0, true).first, true, "venues are separate")
	assert_true(TrainerStats.sanitise(d.stats).bowls_ends_won == 8, "the stat survives sanitising")
