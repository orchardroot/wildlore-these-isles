extends TestCase
## Wave 54: every town has people moving in it, and none of them are story or shop business.

func test_nearly_every_town_has_someone_moving() -> void:
	var still := []
	var movers := 0
	for z in ZoneData.load_all().values():
		if z.kind != "town":
			continue
		var n: int = z.npcs.filter(func(d): return str(d.get("move", "still")) != "still").size()
		movers += n
		if n == 0:
			still.append(z.id)
	assert_true(still.size() <= 1, "towns where nobody moves: %s" % str(still))
	assert_true(movers >= 300, "movers in towns: %d" % movers)

func test_movers_never_cork_a_lane() -> void:
	for z in ZoneData.load_all().values():
		if z.kind != "town":
			continue
		for d in z.npcs:
			assert_eq(z.roamer_problem(d), "", "%s/%s" % [z.id, d.get("id", "")])
