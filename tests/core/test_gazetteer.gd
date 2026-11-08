extends TestCase
## The Gazetteer: heritage plaques (zone signs with "plaque" and "title") collected by reading them, grouped by nation
## and town, with milestone rewards and the stats line. Fixture zones use real ids so the nations come out right.

func _zones() -> Array:
	return [
		{"id": "whitby", "name": "Whitby", "kind": "town", "region": "yorkshire", "signs": [
			{"x": 1, "y": 1, "plaque": "whitby_abbey", "title": "Whitby Abbey", "text": "Ruins."},
			{"x": 2, "y": 1, "text": "Just a fingerpost."},
			{"x": 3, "y": 1, "plaque": "whitby_jet", "title": "Whitby Jet", "text": "Black."}]},
		{"id": "north_york_moors", "name": "North York Moors", "kind": "route", "region": "yorkshire", "signs": [
			{"x": 4, "y": 4, "plaque": "nym_heather", "title": "Heather", "text": "Purple."}]},
		{"id": "cardiff", "name": "Cardiff", "kind": "town", "region": "south_wales", "signs": [
			{"x": 1, "y": 1, "plaque": "cardiff_castle", "title": "Cardiff Castle", "text": "Old."}]},
		{"id": "cardiff_castle_hall", "name": "Castle Hall", "kind": "interior", "region": "", "signs": [
			{"x": 1, "y": 1, "plaque": "cardiff_hall_banner", "title": "The Banner", "text": "Red."}]},
	]

func _index() -> Dictionary:
	return {"room_town": {"cardiff_castle_hall": "cardiff"}}

func _list() -> Array:
	return Gazetteer.build(_zones(), _index())

func _data(flags := {}) -> GameStateData:
	var d := GameStateData.new()
	d.flags = flags.duplicate()
	return d

func test_build_finds_plaques_and_only_plaques() -> void:
	var l := _list()
	assert_eq(l.map(func(p): return p.id), ["whitby_abbey", "whitby_jet", "nym_heather", "cardiff_castle", "cardiff_hall_banner"])
	assert_eq(str(l[0].town), "whitby")
	assert_eq(str(l[0].town_name), "Whitby")
	assert_eq(str(l[2].town), "north_york_moors", "a route is its own place")
	assert_eq(str(l[4].town), "cardiff", "a plaque indoors belongs to its town")
	assert_eq(str(l[0].nation), "england")
	assert_eq(str(l[3].nation), "wales")

func test_reading_records_once() -> void:
	var l := _list()
	var d := _data()
	assert_false(Gazetteer.is_read(d, "whitby_abbey"))
	var r := Gazetteer.record(d, "whitby_abbey", l)
	assert_true(r.new, "first read is news")
	assert_true(Gazetteer.is_read(d, "whitby_abbey"))
	assert_eq(d.flag("plaque_whitby_abbey"), true, "a plain flag: save-safe")
	assert_false(Gazetteer.record(d, "whitby_abbey", l).new, "the second read isn't")
	assert_eq(Gazetteer.count(d, l), 1)

func test_unknown_plaques_dont_count() -> void:
	var d := _data({"plaque_gone_since": true, "plaque_whitby_jet": true})
	assert_eq(Gazetteer.count(d, _list()), 1, "a flag for a plaque that's no longer in the game isn't counted")

func test_grouped_by_nation_then_town_with_counts() -> void:
	var d := _data({"plaque_whitby_abbey": true, "plaque_cardiff_hall_banner": true})
	var g := Gazetteer.grouped(d, _list())
	assert_eq(g.map(func(n): return n.nation), ["england", "wales"])
	var eng: Dictionary = g[0]
	assert_eq(eng.name, "England")
	assert_eq([eng.read, eng.total], [1, 3])
	assert_eq(eng.towns.map(func(t): return t.town), ["north_york_moors", "whitby"], "places in name order")
	var wh: Dictionary = eng.towns[1]
	assert_eq([wh.read, wh.total], [1, 2])
	assert_eq(wh.plaques.map(func(p): return p.id), ["whitby_abbey", "whitby_jet"])
	assert_eq([g[1].read, g[1].total], [1, 2])

func test_milestones_pay_once_as_you_pass_them() -> void:
	var ms := [{"n": 2, "flag": "gazetteer_2", "title": "Nosy", "money": 100, "items": {"cup_of_tea": 2}},
		{"n": -1, "flag": "gazetteer_all", "title": "Know-all", "money": 500, "items": {}}]
	var l := _list()
	var d := _data()
	d.money = 0
	assert_eq(Gazetteer.record(d, "whitby_abbey", l, ms).milestones, [])
	var r := Gazetteer.record(d, "whitby_jet", l, ms)
	assert_eq(r.milestones.map(func(m): return m.flag), ["gazetteer_2"])
	assert_eq(d.money, 100)
	assert_eq(int(d.bag.get("cup_of_tea", 0)), 2)
	assert_eq(Gazetteer.title(d, ms), "Nosy")
	Gazetteer.record(d, "nym_heather", l, ms)
	Gazetteer.record(d, "cardiff_castle", l, ms)
	r = Gazetteer.record(d, "cardiff_hall_banner", l, ms)
	assert_eq(r.milestones.map(func(m): return m.flag), ["gazetteer_all"], "every plaque read")
	assert_eq(d.money, 600)
	assert_eq(Gazetteer.title(d, ms), "Know-all")
	assert_eq(Gazetteer.record(d, "cardiff_castle", l, ms).milestones, [], "never twice")

func test_milestones_catch_up_on_an_old_save() -> void:
	var ms := [{"n": 2, "flag": "gazetteer_2", "title": "Nosy", "money": 100, "items": {}}]
	var d := _data({"plaque_whitby_abbey": true, "plaque_whitby_jet": true})
	var r := Gazetteer.record(d, "nym_heather", _list(), ms)
	assert_eq(r.milestones.size(), 1, "passed 2 already: paid on the next read")

func test_next_milestone_and_stats_line() -> void:
	var ms := [{"n": 2, "flag": "gazetteer_2", "title": "Nosy", "money": 0, "items": {}}, {"n": -1, "flag": "gazetteer_all", "title": "Know-all", "money": 0, "items": {}}]
	var d := _data({"plaque_whitby_abbey": true})
	assert_eq(Gazetteer.next_milestone(d, _list(), ms).flag, "gazetteer_2")
	assert_eq(Gazetteer.stats_line(_data(), _list()), "None yet")
	assert_eq(Gazetteer.stats_line(d, _list()), "1 of 5")

func test_reward_text_reads_well() -> void:
	var m := {"n": 10, "title": "Curious Visitor", "money": 500, "items": {"flask_of_tea": 2}}
	assert_eq(Gazetteer.reward_text(m, ItemDB.load_default()), "£500 and 2 Flask of Tea")
	assert_eq(Gazetteer.reward_text({"money": 10000}, null), "£10,000", "thousands get a comma, as everywhere else")

func test_validate_catches_duplicates_and_blanks() -> void:
	var l := _list()
	l.append({"id": "whitby_abbey", "title": "", "text": "Again \u2014 twice.", "zone": "york", "x": 1, "y": 2})
	var errs := "\n".join(Gazetteer.validate(l))
	assert_has(errs, "same id")
	assert_has(errs, "needs a title")
	assert_has(errs, "em-dash")
	assert_eq(Gazetteer.validate(_list()), [])

func test_real_milestones_are_sane() -> void:
	var items := ItemDB.load_default()
	var last := 0
	for m in Gazetteer.MILESTONES:
		assert_true(str(m.title) != "" and str(m.flag).begins_with("gazetteer_"), str(m))
		if int(m.n) > 0:
			assert_true(int(m.n) > last, "in order")
			last = int(m.n)
		for id in m.get("items", {}):
			assert_true(items.has(str(id)), "item %s exists" % id)

func test_real_plaques_have_unique_ids_titles_and_no_em_dashes() -> void:
	var seen := {}
	var l := Gazetteer.all()
	assert_true(l.size() >= 100, "a rich Gazetteer from day one (%d)" % l.size())
	for p in l:
		assert_false(seen.has(p.id), "unique id %s" % p.id)
		seen[p.id] = true
		assert_true(str(p.title) != "" and str(p.text) != "", "%s has a title and text" % p.id)
		assert_false("—" in str(p.text) or "—" in str(p.title), "%s: no em-dashes" % p.id)
