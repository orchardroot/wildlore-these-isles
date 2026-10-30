extends TestCase
## Wave 47 A: searchable furniture, the curios and the Curios page.

func _zone(id := "macc_home") -> ZoneData:
	var z := ZoneData.load_id(id)
	assert_true(z != null, "zone " + id)
	return z

func _shelf(z: ZoneData) -> Dictionary:
	for p in z.props:
		if str(p.type) in Search.TYPES:
			return p
	return {}

func test_stash_is_deterministic() -> void:
	var z := _zone()
	var p := _shelf(z)
	var d := GameStateData.new()
	assert_eq(Search.stash(z, p, d), Search.stash(z, p, d))
	assert_true(Search.stash(z, p, d, 1) is Dictionary)

func test_all_outcomes_turn_up() -> void:
	var z := _zone()
	var p := _shelf(z).duplicate()
	var d := GameStateData.new()
	var kinds := {}
	for x in 400:
		p.x = x
		var s := Search.stash(z, p, d)
		kinds["nothing" if s.has("nothing") else ("money" if s.has("money") else ("curio" if s.has("curio") else "item"))] = true
		if s.has("money"):
			assert_true(int(s.money) >= 20 and int(s.money) <= 300)
	assert_eq(kinds.size(), 4)

func test_restock_after_seven_days() -> void:
	var z := _zone()
	var p := _shelf(z)
	var d := GameStateData.new()
	d.day_count = 10
	var items := ItemDB.load_default()
	var r := Search.take(z, p, d, items)
	assert_true(r.lines.size() > 0)
	assert_true(Search.searched(d, "macc_home", int(p.x), int(p.y)))
	assert_true(Search.take(z, p, d, items).again, "second search the same day finds the drawer empty")
	d.day_count = 16
	assert_true(Search.searched(d, "macc_home", int(p.x), int(p.y)))
	d.day_count = 17
	assert_false(Search.searched(d, "macc_home", int(p.x), int(p.y)), "restocked 7 days on")
	assert_true(TrainerStats.get_count(d, "searches") >= 1)

func test_table_ids_exist() -> void:
	var items := ItemDB.load_default()
	for id in Search.all_table_ids():
		assert_true(items.has(str(id)), "item exists: " + str(id))

func test_curios() -> void:
	var items := ItemDB.load_default()
	var ids := Search.curio_ids()
	assert_eq(ids.size(), 60)
	for id in ids:
		var it: Dictionary = items.get_item(str(id))
		assert_eq(str(it.kind), "curio")
		assert_true(int(it.price) >= 100 and int(it.price) <= 4000, "price " + str(id))
		assert_true(str(it.desc) != "" and str(it.name) != "")
		for k in ["name", "desc", "one"]:
			assert_false(str(it.get(k, "")).contains("—"), "no em-dash in " + str(id))

func test_find_a_curio_records_it() -> void:
	var z := _zone()
	var d := GameStateData.new()
	var items := ItemDB.load_default()
	var p := _shelf(z).duplicate()
	for x in 200:
		p.x = x
		if Search.stash(z, p, d).has("curio"):
			var r := Search.take(z, p, d, items)
			assert_true(r.curio)
			assert_eq(Search.found_count(d), 1)
			assert_eq(TrainerStats.get_count(d, "curios_found"), 1)
			return
	assert_true(false, "no curio in 200 drawers")

func test_nothing_lines_clean() -> void:
	for t in Search.NOTHING:
		for l in Search.NOTHING[t]:
			assert_false(str(l).contains("—"))
	for q in Search.QUIPS:
		assert_false(str(q).contains("—"))

func test_quip_once_per_visit() -> void:
	var z := _zone()
	var d := GameStateData.new()
	Search._last_zone = ""
	assert_true(Search.quip(z, d) != "", "first search gets a word")
	assert_eq(Search.quip(z, d), "", "not twice in a visit")

func test_curios_page_sprouts() -> void:
	var d := GameStateData.new()
	assert_false(Almanac.pages(d).any(func(p): return p.id == "curios"))
	d.set_flag(Search.FOUND_PREFIX + str(Search.curio_ids()[0]), true)
	assert_true(Almanac.pages(d).any(func(p): return p.id == "curios"))
	assert_eq(Search.pat_on_back(20) != "", true)
