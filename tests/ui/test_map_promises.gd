extends TestCase
## The map makes promises (5.4): neighbours of places you have been are named with a question mark, legends you have
## heard of are ringed, and Deep Places show once you have seen the way in.

func _data(visited: Array) -> GameStateData:
	var d := GameStateData.new()
	for t in visited:
		d.set_flag("visited_" + str(t))
	return d

func test_next_door_towns_are_promised() -> void:
	var d := _data(["macclesfield"])
	var p := MapLogic.promised_towns(d)
	assert_true("buxton" in p or "manchester" in p, "a town over the nearest route: %s" % str(p))
	assert_false("macclesfield" in p, "never a place you have been")
	d.set_flag("visited_buxton")
	assert_false("buxton" in MapLogic.promised_towns(d), "visiting it ends the question mark")

func test_a_new_save_promises_nothing() -> void:
	assert_eq(MapLogic.promised_towns(_data([])), [])

func test_a_legend_in_a_town_names_the_town() -> void:
	var d := _data(["york"])
	d.set_flag(Rumours.heard_key("shuck", 1))
	assert_true("whitby" in MapLogic.promised_towns(d), "the rumour names Whitby")

func test_ferries_promise_the_other_end() -> void:
	var f: Dictionary = Travel.ferries()
	var route := ""
	for r in f:
		if FileAccess.file_exists("res://data/zones/%s.json" % f[r].a) and FileAccess.file_exists("res://data/zones/%s.json" % f[r].b):
			route = str(r)
			break
	assert_true(route != "")
	var d := _data([f[route].a])
	assert_true(str(f[route].b) in MapLogic.promised_towns(d))

func test_marks_carry_rings_and_have_points_on_the_map() -> void:
	var d := _data(["buxton"])
	d.set_flag(Rumours.heard_key("lambton", 0))
	var legend := MapLogic.marks(d, {}).filter(func(m): return m.kind == "legend")
	assert_eq(legend.size(), 1)
	assert_true(MapLogic.mark_point(legend[0]).x >= 0.0, "a route with no spot of its own borrows its neighbours'")

func test_deep_places_show_once_the_way_in_is_found() -> void:
	var idx := ZoneIndex.get_index()
	var d := GameStateData.new()
	assert_eq(Discovery.deep_marks(d, idx), [])
	var outer := ""
	for id in idx.zones:
		for to in idx.zones[id].links:
			if idx.zones[to].deep and not idx.zones[id].deep and idx.zones[id].kind != "interior":
				outer = str(id)
	assert_true(outer != "", "some outdoor zone leads into a Deep Place")
	d.set_flag(Discovery.found_key(outer))
	var marks := Discovery.deep_marks(d, idx)
	assert_true(marks.size() >= 1)
	assert_true(marks[0].ring)
	assert_false(marks[0].done)
