extends TestCase
## Discovery (5.4): a first visit is recorded once, pays the party once, and old saves are caught up without pay.

func _idx() -> Dictionary:
	return ZoneIndex.get_index()

func _party(d: GameStateData) -> void:
	d.party = [Fixtures.creature("pepperling", 5), Fixtures.creature("pepperling", 6)]

func test_first_visit_is_found_and_pays_once() -> void:
	var d := GameStateData.new()
	_party(d)
	var z := ZoneData.load_id("macc_forest")
	var before: int = d.party[0].friendship
	var got := Discovery.note(d, z, _idx())
	assert_false(got.is_empty(), "a new place")
	assert_true(Discovery.is_found(d, "macc_forest"))
	assert_eq(d.party[0].friendship, before + Discovery.FRIENDSHIP)
	assert_eq(d.party[1].friendship - Fixtures.creature("pepperling", 6).friendship, Discovery.FRIENDSHIP, "the whole party")
	assert_true(str(got.gain) != "")
	assert_eq(Discovery.take("macc_forest").zone, "macc_forest")
	assert_true(Discovery.take("macc_forest").is_empty(), "the card is handed over once")
	var again := Discovery.note(d, z, _idx())
	assert_true(again.is_empty(), "never twice")
	assert_eq(d.party[0].friendship, before + Discovery.FRIENDSHIP, "no second reward")

func test_training_points_go_in_one_stat() -> void:
	var d := GameStateData.new()
	_party(d)
	Discovery.note(d, ZoneData.load_id("macc_forest"), _idx())
	var total := 0
	for s in Rules.STATS:
		total += int(d.party[0].training.get(s, 0))
	assert_eq(total, Poi.STONE_POINTS)

func test_rooms_do_not_count_but_deep_places_do() -> void:
	var d := GameStateData.new()
	assert_true(Discovery.note(d, ZoneData.load_id("macc_home"), _idx()).is_empty(), "a house is a room")
	assert_false(Discovery.is_found(d, "macc_home"))
	assert_false(Discovery.note(d, ZoneData.load_id("blue_john_entry"), _idx()).is_empty(), "a Deep Place is a place")
	assert_true(Discovery.is_found(d, "blue_john_entry"))

func test_old_save_towns_are_found_without_reward() -> void:
	var d := GameStateData.new()
	_party(d)
	d.set_flag("visited_buxton")
	d.set_flag("visited_macclesfield")
	var before: int = d.party[0].friendship
	assert_true(Discovery.note(d, ZoneData.load_id("buxton"), _idx()).is_empty(), "already visited: not new")
	assert_true(Discovery.is_found(d, "macclesfield"), "caught up")
	assert_eq(d.party[0].friendship, before, "no pay for towns walked before the tally")

func test_veteran_routes_between_found_places_are_caught_up() -> void:
	var idx := _idx()
	var d := GameStateData.new()
	d.play_seconds = 9000.0
	for t in ["macclesfield", "buxton", "manchester", "liverpool"]:
		d.set_flag("visited_" + t)
	Discovery.catch_up(d, idx)
	var routes := 0
	for id in Discovery.places(idx):
		if idx.zones[id].kind == "route" and Discovery.is_found(d, id):
			routes += 1
	assert_true(routes > 0, "a route linking two visited towns is plainly walked")
	var fresh := GameStateData.new()
	for t in ["macclesfield", "buxton"]:
		fresh.set_flag("visited_" + t)
	Discovery.catch_up(fresh, idx)
	for id in Discovery.places(idx):
		if idx.zones[id].kind == "route":
			assert_false(Discovery.is_found(fresh, id), "a new save infers no routes: " + id)

func test_catch_up_runs_once() -> void:
	var d := GameStateData.new()
	Discovery.catch_up(d, _idx())
	assert_true(d.flag(Discovery.INIT))
	d.set_flag("visited_buxton")
	Discovery.catch_up(d, _idx())
	assert_false(Discovery.is_found(d, "buxton"), "later visits earn their own card")

func test_tally_counts_outdoor_zones_and_deep_places() -> void:
	var idx := _idx()
	var d := GameStateData.new()
	var t := Discovery.tally(d, idx)
	assert_eq(t.x, 0)
	assert_true(t.y > 150, "a couple of hundred places: %d" % t.y)
	for id in Discovery.places(idx):
		assert_true(idx.zones[id].kind != "interior" or idx.zones[id].deep, id)

func test_note_visit_hooks_discovery() -> void:
	var d := GameStateData.new()
	var z := ZoneData.from_dict({"id": "t", "name": "T", "kind": "route", "rows": ["..."], "spawn": [0, 0]})
	Travel.note_visit(d, z)
	assert_true(Discovery.is_found(d, "t"))
