extends TestCase
## 3.1 home and garden: souvenirs earned from plaques and set on the shelves, framed plaque boards per nation, and
## the garden's bird table, bug hotel and pond with their seasonal visitors.

func _data() -> GameStateData:
	var d := GameStateData.new()
	d.clock_minutes = 600
	d.day_count = 3
	return d

func _plaques() -> Array:
	return [{"id": "a", "town": "blackpool", "nation": "england"}, {"id": "b", "town": "blackpool", "nation": "england"},
		{"id": "c", "town": "galway", "nation": "ireland"}, {"id": "d", "town": "cardiff", "nation": "wales"}]

func test_souvenirs_are_earned_by_reading_a_plaque_in_the_town() -> void:
	var d := _data()
	assert_eq(HomeExtras.unlocked(d, _plaques()), [])
	d.set_flag(Gazetteer.flag_key("b"))
	d.set_flag(Gazetteer.flag_key("c"))
	var got := HomeExtras.unlocked(d, _plaques())
	assert_true("blackpool_rock" in got and "claddagh_ring" in got and got.size() == 2, "rock and ring: %s" % [got])

func test_souvenir_table_is_sound() -> void:
	var towns := {}
	for p in Gazetteer.all():
		towns[str(p.town)] = true
	var seen := {}
	for s in HomeExtras.SOUVENIRS:
		assert_true(towns.has(s.town) or s.has("project") or s.has("league"), "%s: a town with plaques, a town project or a League title" % s.id)
		assert_false(seen.has(s.id), "%s unique" % s.id)
		seen[s.id] = true
		assert_true(str(s.name) != "" and str(s.line) != "", "%s has text" % s.id)
		assert_false(str(s.line).contains("—") or str(s.name).contains("—"), "no em-dashes")
	assert_true(HomeExtras.SOUVENIRS.size() >= 16, "plenty of them")

func test_placing_moves_a_souvenir_between_slots() -> void:
	var d := _data()
	d.set_flag(Gazetteer.flag_key("a"))
	d.set_flag(Gazetteer.flag_key("d"))
	var pl := _plaques()
	assert_true(HomeExtras.place(d, 1, "blackpool_rock", pl))
	assert_false(HomeExtras.place(d, 2, "claddagh_ring", pl), "not earned yet")
	assert_true(HomeExtras.place(d, 3, "blackpool_rock", pl))
	assert_eq(HomeExtras.slot(d, 1), "", "moved, not copied")
	assert_eq(HomeExtras.slot(d, 3), "blackpool_rock")
	HomeExtras.clear(d, 3)
	assert_eq(HomeExtras.slot(d, 3), "")

func test_a_missing_souvenir_flag_is_just_empty() -> void:
	assert_eq(HomeExtras.slot(_data(), 4), "")

func test_boards_count_plaques_read_per_nation() -> void:
	var d := _data()
	d.set_flag(Gazetteer.flag_key("a"))
	d.set_flag(Gazetteer.flag_key("d"))
	var b := HomeExtras.boards(d, _plaques())
	assert_eq(b.size(), Standing.NATIONS.size())
	var eng: Dictionary = b.filter(func(x): return x.nation == "england")[0]
	assert_eq([eng.read, eng.total], [1, 2])
	var sco: Dictionary = b.filter(func(x): return x.nation == "scotland")[0]
	assert_eq([sco.read, sco.total], [0, 0])
	assert_true(HomeExtras.board_lines(d, _plaques()).size() >= 2)

func test_every_feature_has_a_visitor_each_season() -> void:
	for f in HomeExtras.FEATURES:
		for s in ["spring", "summer", "autumn", "winter"]:
			var sp := HomeExtras.visitor(f, s)
			assert_true(Fixtures.dex().get_species(sp).has("id"), "%s %s: %s is a species" % [f, s, sp])
		assert_true(HomeExtras.visitor(f, "spring") != HomeExtras.visitor(f, "autumn"), "%s rotates" % f)

func test_a_visitor_comes_once_a_day() -> void:
	var d := _data()
	assert_true(HomeExtras.visitor_here(d, "pond"))
	HomeExtras.mark_visited(d, "pond")
	assert_false(HomeExtras.visitor_here(d, "pond"))
	d.day_count += 1
	assert_true(HomeExtras.visitor_here(d, "pond"), "back tomorrow")

func test_befriending_leaves_a_gift_and_builds_friendship() -> void:
	var d := _data()
	var r := HomeExtras.befriend(d, "bird_table", "autumn")
	assert_true(str(r.gift) != "" and int(d.bag.get(r.gift, 0)) >= 1)
	assert_eq(HomeExtras.friends(d, HomeExtras.visitor("bird_table", "autumn")), 1)
	assert_false(HomeExtras.visitor_here(d, "bird_table"))
	for i in HomeExtras.FRIEND_REWARD_AT - 1:
		d.day_count += 1
		r = HomeExtras.befriend(d, "bird_table", "autumn")
	assert_true(str(r.reward) != "", "fond enough to leave something special")
	d.day_count += 1
	assert_eq(str(HomeExtras.befriend(d, "bird_table", "autumn").reward), "", "only the once")

func test_visit_level_follows_the_party_gently() -> void:
	assert_eq(HomeExtras.visit_level(0), 3)
	assert_eq(HomeExtras.visit_level(20), 14)
	assert_eq(HomeExtras.visit_level(90), 25)
