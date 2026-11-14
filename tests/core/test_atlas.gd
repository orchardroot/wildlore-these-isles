extends TestCase
## The Atlas (5.4): per-region counts, stamps at half and at all, a modest one-off reward each, and old saves caught up
## the first time it is opened.

func _idx() -> Dictionary:
	return ZoneIndex.get_index()

func _cheshire(d: GameStateData) -> Array:
	return Atlas.regions(d, _idx()).filter(func(r): return r.region == "cheshire")

## Everything in a region found, read, entered and recorded.
func _finish(d: GameStateData, region: String) -> void:
	var c: Dictionary = Atlas.contents(_idx())[region]
	for id in c.places:
		d.set_flag(Discovery.found_key(str(id)))
	for id in c.rooms:
		d.set_flag(VisitorsBook.seen_flag(str(id)))
	for id in c.plaques:
		d.set_flag(Gazetteer.flag_key(str(id)))
	for id in c.poi:
		d.set_flag(Poi.seen_key(Poi.by_id(str(id))))
	for s in FieldSpots.all():
		if str(s.id) in c.spots:
			d.set_flag(FieldSpots.seen_key(s))
	for sp in c.species:
		d.seen[sp] = true

func test_a_new_save_has_nothing_to_show() -> void:
	assert_eq(Atlas.regions(GameStateData.new(), _idx()), [])

func test_a_region_appears_once_a_place_in_it_is_found() -> void:
	var d := GameStateData.new()
	d.set_flag(Discovery.found_key("macc_forest"))
	var r := _cheshire(d)
	assert_eq(r.size(), 1)
	assert_eq(r[0].stamp, "")
	var places: Dictionary = r[0].rows.filter(func(m): return m.key == "places")[0]
	assert_eq(places.got, 1)
	assert_true(places.total >= 2)

func test_rows_count_each_measure() -> void:
	var d := GameStateData.new()
	d.set_flag(Discovery.found_key("macc_forest"))
	d.set_flag(VisitorsBook.seen_flag("macc_home"))
	d.caught["pepperling"] = true
	var rows := Atlas.rows(d, _idx(), "cheshire")
	var by := {}
	for m in rows:
		by[m.key] = m
	assert_eq(by.rooms.got, 1, "a room entered")
	assert_true(by.has("creatures") and by.creatures.total > 0)
	assert_true(by.places.got <= by.places.total)

func test_stamps_come_at_half_and_all() -> void:
	assert_eq(Atlas.stamp_for(0.0), "")
	assert_eq(Atlas.stamp_for(0.49), "")
	assert_eq(Atlas.stamp_for(0.5), "half")
	assert_eq(Atlas.stamp_for(0.99), "half")
	assert_eq(Atlas.stamp_for(1.0), "full")

func test_the_reward_is_paid_once_and_in_items_not_money() -> void:
	var d := GameStateData.new()
	d.money = 0
	var c: Dictionary = Atlas.contents(_idx())["cheshire"]
	for id in c.places:
		d.set_flag(Discovery.found_key(str(id)))
	for id in c.rooms:
		d.set_flag(VisitorsBook.seen_flag(str(id)))
	var paid := Atlas.collect(d, _idx())
	assert_eq(paid, [], "places and rooms alone are a third of a region")
	_finish(d, "cheshire")
	paid = Atlas.collect(d, _idx())
	assert_true(paid.any(func(p): return p.tier == "full"), "all of it: %s" % str(paid))
	var again := Atlas.collect(d, _idx())
	assert_eq(again, [], "paid once only")
	assert_eq(d.money, 0, "no money faucet")
	for p in paid:
		assert_true(p.tier in ["half", "full"])
		for it in p.items:
			assert_true(Bag.new(d.bag).count(str(it.id)) >= int(it.n), "in the bag")

func test_an_old_save_catches_up_on_first_open() -> void:
	var d := GameStateData.new()
	d.play_seconds = 9000.0
	var idx := _idx()
	for t in ["macclesfield", "buxton", "manchester", "liverpool", "chester"]:
		d.set_flag("visited_" + t)
	_finish(d, "cheshire")
	var paid := Atlas.collect(d, idx)
	assert_true(paid.any(func(p): return p.region == "cheshire" and p.tier == "full"), "the stamps it had already earned: %s" % str(paid))
	assert_true(paid.any(func(p): return p.region == "cheshire" and p.tier == "half"), "the half stamp too")
	assert_eq(Atlas.collect(d, idx), [])

func test_reward_items_exist_and_are_cheap() -> void:
	var items := ItemDB.load_default()
	for tier in Atlas.REWARDS:
		for id in Atlas.REWARDS[tier]:
			assert_true(items.has(str(id)), str(id))
			assert_true(int(items.get_item(str(id)).get("price", 0)) <= 1500, "modest: " + str(id))

func test_the_almanac_lists_the_atlas_once_a_place_is_found() -> void:
	var d := GameStateData.new()
	assert_false(Almanac.pages(d).any(func(p): return p.id == "atlas"))
	d.set_flag(Discovery.found_key("macc_forest"))
	assert_true(Almanac.pages(d).any(func(p): return p.id == "atlas"))
	assert_true(Almanac.pages(d).filter(func(p): return p.id == "atlas")[0].blurb.contains("places found"))
