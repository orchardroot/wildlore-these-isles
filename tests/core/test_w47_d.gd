extends TestCase
## Wave 47 D: chapbooks (move teaching items) and the fourteen chapmen who sell them.

func _db() -> ItemDB:
	return ItemDB.load_default()

func test_sixty_chapbooks_with_real_moves() -> void:
	var db := _db()
	var n := 0
	for id in db.ids():
		var it := db.get_item(id)
		if str(it.get("kind", "")) == "chapbook":
			n += 1
			assert_true(Fixtures.moves().has(str(it.move)), "%s teaches a real move" % id)
			assert_true(str(it.name).begins_with("Chapbook: "))
			assert_true(int(it.price) >= 400 and int(it.price) <= 3000)
			assert_false(char(0x2014) in str(it.desc), "no em-dashes")
	assert_eq(n, 60)

func test_can_learn_cases() -> void:
	var m := Fixtures.moves()
	var c := Fixtures.creature("spikkin", 10)  # hedgerow
	assert_true(Chapbooks.can_learn(c, "thorn_volley", m), "own type")
	assert_true(Chapbooks.can_learn(c, "hunker", m) or c.has_move("hunker"), "kin moves are for everyone")
	assert_false(Chapbooks.can_learn(c, "haymaker", m), "other type")
	assert_eq(Chapbooks.status(c, "haymaker", m), Chapbooks.CANT)
	c.species = c.species.duplicate()
	c.species["chapbooks"] = ["haymaker"]
	assert_true(Chapbooks.can_learn(c, "haymaker", m), "species key opens an off-type move")
	c.moves.append(c.make_move_slot("haymaker", m))
	assert_false(Chapbooks.can_learn(c, "haymaker", m), "already known")
	assert_eq(Chapbooks.status(c, "haymaker", m), Chapbooks.KNOWS)
	assert_false(Chapbooks.can_learn(c, "no_such_move", m))

func test_bag_returns_learn_and_keeps_the_book() -> void:
	var db := _db()
	var bag := Bag.new({"chapbook_thorn_volley": 1})
	var c := Fixtures.creature("spikkin", 10)
	var r := bag.use_on("chapbook_thorn_volley", c, db, Fixtures.moves())
	assert_true(r.ok)
	assert_eq(r.learn, "thorn_volley")
	assert_eq(bag.count("chapbook_thorn_volley"), 1, "a book you keep")
	var no := bag.use_on("chapbook_haymaker", c, db, Fixtures.moves())
	assert_false(no.get("ok", false))

func test_rotation_is_deterministic_and_leaves_staples() -> void:
	var full := ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l"]
	var s1 := Chapbooks.stock("buxton", 2900, full)
	assert_eq(s1, Chapbooks.stock("buxton", 2900, full))
	assert_eq(s1.size(), full.size() - Chapbooks.ROTATE)
	for st in ["a", "b", "c", "d"]:
		assert_true(st in s1, "staples stay")
	var differs := false
	for w in range(2901, 2910):
		if Chapbooks.stock("buxton", w, full) != s1:
			differs = true
	assert_true(differs, "the shelf changes over the weeks")
	assert_eq(Chapbooks.week_of("2026-10-30"), Chapbooks.week_of("2026-10-30"))
	assert_true(Chapbooks.week_of("2026-11-07") > Chapbooks.week_of("2026-10-30"))

func test_every_chapman_loads_and_the_set_is_complete() -> void:
	var db := _db()
	var all := {}
	for t in Chapbooks.TOWNS:
		var shop: Dictionary = db.shops.get("chapman_" + t, {})
		assert_false(shop.is_empty(), t)
		var n: int = shop.stock.size()
		assert_true(n >= 10 and n <= 14, "%s stocks %d" % [t, n])
		var shared := 0
		for b in shop.stock.slice(0, 4):
			shared += 1
		assert_eq(shared, 4)
		for b in shop.stock:
			all[b] = true
	assert_eq(all.size(), 60, "the whole map is needed")
	assert_eq(Chapbooks.problems(db, Fixtures.moves()), [])

func test_shop_for_week_only_touches_chapmen() -> void:
	var db := _db()
	var s: Dictionary = db.shops["chapman_york"]
	assert_eq(Chapbooks.shop_for_week(s, 100).stock.size(), s.stock.size() - 3)
	var other: Dictionary = db.shops["aberdeen_corner_shop"]
	assert_eq(Chapbooks.shop_for_week(other, 100), other)
