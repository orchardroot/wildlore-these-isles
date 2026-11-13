extends TestCase
## Friendship: hearts, the gentle sources and losses, and the battle perks (player's creatures only).

const SLOT0 := {"type": "move", "slot": 0}

func _mk(level := 30, move_ids := ["glare"], friendship := 70) -> Creature:
	var c := Creature.create(Fixtures.species("pal", ["kin"]), level, FixedRng.new(), Fixtures.moves())
	c.moves.clear()
	for id in move_ids:
		c.moves.append(c.make_move_slot(id, Fixtures.moves()))
	c.friendship = friendship
	return c

func _of(events: Array, type: String) -> Array:
	return events.filter(func(e): return e.type == type)

func test_hearts_mapping() -> void:
	var cases := {0: 0, 49: 0, 50: 1, 70: 1, 99: 1, 100: 2, 149: 2, 150: 3, 219: 3, 220: 4, 254: 4, 255: 5}
	for f in cases:
		assert_eq(Bond.hearts(f), cases[f], "friendship %d" % f)

func test_add_stays_in_range() -> void:
	var c := _mk(5, ["glare"], 254)
	assert_eq(Bond.add(c, 5), 1)
	assert_eq(c.friendship, 255)
	c.friendship = 0
	assert_eq(Bond.add(c, Bond.FAINT), 0)
	assert_eq(c.friendship, 0)

func test_perk_line() -> void:
	assert_eq(Bond.perk_line(_mk(5, ["glare"], 70)), "At 3 hearts: shrugs off a status now and then.")
	assert_eq(Bond.perk_line(_mk(5, ["glare"], 150)), "Shrugs off a status now and then.")
	assert_eq(Bond.perk_line(_mk(5, ["glare"], 255)), "Shrugs off a status now and then, hangs on at 1 HP once a battle, lands more critical hits.")

func test_shrug_off_a_status() -> void:
	var me := _mk(30, ["glare"], 150)
	var lucky := FixedRng.new()
	lucky.f = 0.05  # under 10%: shrugs it off
	var b := Fixtures.battle([me], [_mk(30, ["drench"])], {"rng": lucky})
	var ev := b.take_turn(SLOT0, SLOT0)
	assert_eq(me.status, "")
	var e: Dictionary = _of(ev, "bond")[0]
	assert_eq(EventPlayer.lines_for(e, EventPlayer.make_ctx(b))[0], "Pal shook it off for you!")

func test_no_shrug_on_a_bad_roll_or_below_150() -> void:
	var me := _mk(30, ["glare"], 150)
	var b := Fixtures.battle([me], [_mk(30, ["drench"])])  # f = 1.0
	b.take_turn(SLOT0, SLOT0)
	assert_eq(me.status, "soaked")
	var low := _mk(30, ["glare"], 149)
	var lucky := FixedRng.new()
	lucky.f = 0.05
	b = Fixtures.battle([low], [_mk(30, ["drench"])], {"rng": lucky})
	b.take_turn(SLOT0, SLOT0)
	assert_eq(low.status, "soaked")

func test_foes_never_get_perks() -> void:
	var foe := _mk(30, ["glare"], 255)
	var lucky := FixedRng.new()
	lucky.f = 0.05
	var b := Fixtures.battle([_mk(30, ["drench"])], [foe], {"rng": lucky})
	b.take_turn(SLOT0, SLOT0)
	assert_eq(foe.status, "soaked")
	var weak := _mk(5, ["glare"], 255)
	b = Fixtures.battle([_mk(60, ["scrap"])], [weak])
	b.take_turn(SLOT0, SLOT0)
	assert_true(weak.is_fainted())

func test_hang_on_once_a_battle() -> void:
	var me := _mk(5, ["glare"], 220)
	var b := Fixtures.battle([me, _mk(5)], [_mk(60, ["scrap"])])
	var ev := b.take_turn(SLOT0, SLOT0)
	assert_eq(me.hp, 1)
	var e: Dictionary = _of(ev, "bond")[0]
	assert_eq(EventPlayer.lines_for(e, EventPlayer.make_ctx(b))[0], "Pal hung on so you wouldn't worry!")
	b.take_turn(SLOT0, SLOT0)
	assert_true(me.is_fainted())

func test_horseshoe_first_then_friendship() -> void:
	var me := _mk(5, ["glare"], 220)
	me.held = "horseshoe"
	var b := Fixtures.battle([me, _mk(5)], [_mk(60, ["scrap"])])
	assert_eq(_of(b.take_turn(SLOT0, SLOT0), "charm").size(), 1)
	assert_eq(me.hp, 1)
	me.hp = me.max_hp()
	assert_eq(_of(b.take_turn(SLOT0, SLOT0), "bond").size(), 1)
	assert_eq(me.hp, 1)

func test_crit_bonus_at_255() -> void:
	assert_eq(Bond.crit_mult(_mk(5, ["glare"], 254)), 1.0)
	assert_eq(Bond.crit_mult(_mk(5, ["glare"], 255)), 1.5)
	# a roll of 5%: misses the normal 4.2% crit chance, lands the boosted 6.25%
	for f in [[254, false], [255, true]]:
		var rng := FixedRng.new()
		rng.f = 0.05
		var b := Fixtures.battle([_mk(30, ["scrap"], f[0])], [_mk(30)], {"rng": rng})
		var ev := b.take_turn(SLOT0, SLOT0)
		var hit: Dictionary = _of(ev, "damage").filter(func(e): return e.side == Battle.FOE)[0]
		assert_eq(bool(hit.crit), f[1], "friendship %d" % f[0])

func test_fainting_costs_one_and_winning_gives_one() -> void:
	var me := _mk(5, ["glare"], 100)
	var b := Fixtures.battle([me, _mk(60, ["scrap"], 100)], [_mk(60, ["scrap"])])
	b.take_turn(SLOT0, SLOT0)
	assert_eq(me.friendship, 99)
	var winner := _mk(60, ["scrap"], 100)
	var bench := _mk(10, ["glare"], 100)
	b = Fixtures.battle([winner, bench], [_mk(5)])
	b.take_turn(SLOT0, SLOT0)
	assert_true(b.over)
	assert_eq(winner.friendship, 101)
	assert_eq(bench.friendship, 100, "only those out on the field")

func test_sharing_food_adds_friendship() -> void:
	var c := Fixtures.creature("kindlet", 12)
	c.hp = 3
	var f := c.friendship
	var r := Bag.new({"cup_of_tea": 1}).use_on("cup_of_tea", c, ItemDB.load_default())
	assert_true(r.ok)
	assert_eq(c.friendship, f + Bond.FEED)
	assert_true("enjoyed sharing it" in str(r.text))
	var cure := Fixtures.creature("kindlet", 12)
	cure.status = "stung"
	Bag.new({"smelling_salts": 1}).use_on("smelling_salts", cure, ItemDB.load_default())
	assert_eq(cure.friendship, 70, "only food")

func test_talking_once_an_hour() -> void:
	var d := GameStateData.new()
	var c := _mk()
	d.clock_minutes = 600
	assert_true(Bond.talk(d, c))
	assert_false(Bond.talk(d, c))
	d.clock_minutes = 659
	assert_false(Bond.talk(d, c))
	d.clock_minutes = 660
	assert_true(Bond.talk(d, c))
	assert_eq(c.friendship, 72)

func test_follower_friendship_lines() -> void:
	var low := Follower.mood_pool(1.0, "clear", "day", "route", 60)
	var high := Follower.mood_pool(1.0, "clear", "day", "route", 255)
	for t in Follower.BOND_LINES[5]:
		assert_has(high, t)
		assert_false(t in low)
	var any := false
	for i in 40:
		if Follower.mood_line("Pal", 1.0, "clear", "day", "Here", "route", i, 255) in Follower.BOND_LINES[5].map(func(t): return t.replace("{name}", "Pal")):
			any = true
	assert_true(any, "close friends say so now and then")

func test_bond_evolutions_keep_their_level_and_point_at_real_species() -> void:
	var n := 0
	for id in Fixtures.dex().ids():
		var evo = Fixtures.dex().get_species(id).get("evolves")
		if evo is Dictionary and evo.has("bond"):
			n += 1
			assert_true(Fixtures.dex().has(str(evo.to)), id)
			assert_true(evo.has("level"), id + " still evolves by level for players who never bond")
			assert_eq(int(evo.bond), 220)
	assert_true(n >= 4 and n <= 10, "got %d" % n)  # w54: the family cat's two
