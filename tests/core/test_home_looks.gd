extends TestCase
## Homes each carry an examine spot (core/home_looks.gd): the coverage rule, the checks, and the real data.

func _zone(id: String, extra := {}) -> ZoneData:
	var d := {"id": id, "kind": "interior", "spawn": [1, 1], "rows": ["xxxx", "x||x", "x||x", "xxxx"]}
	d.merge(extra, true)
	return ZoneData.from_dict(d)

func test_what_counts_as_a_home() -> void:
	assert_true(HomeLooks.is_home("york_house_a", _zone("york_house_a")))
	assert_true(HomeLooks.is_home("penzance_home1", _zone("penzance_home1")))
	assert_false(HomeLooks.is_home("york_minster", _zone("york_minster")))
	assert_false(HomeLooks.is_home("testbed_house", _zone("testbed_house")))
	assert_false(HomeLooks.is_home("farm_house", _zone("farm_house", {"kind": "outdoor"})))

func test_uncovered_lists_homes_without_a_spot() -> void:
	var zones := {
		"a_home": _zone("a_home"),
		"b_home": _zone("b_home", {"examine": [{"x": 1, "y": 1, "text": ["A clock."]}]}),
	}
	assert_eq(HomeLooks.uncovered(zones), ["a_home"])

func test_errors_catch_unknown_finds_and_dashes() -> void:
	var zones := {"a_home": _zone("a_home", {"examine": [{"x": 1, "y": 1, "text": ["Old — odd."], "find": {"item": "no_such"}}]})}
	var errs := "\n".join(HomeLooks.errors(zones, ItemDB.load_default()))
	assert_true(errs.contains("unknown item"), errs)
	assert_true(errs.contains("em-dash"), errs)

func test_every_real_home_has_a_spot() -> void:
	var zones := ZoneData.load_all()
	assert_eq(HomeLooks.uncovered(zones), [], "homes with no examine spot")
	assert_eq(HomeLooks.errors(zones, ItemDB.load_default()), [])

func test_about_a_quarter_carry_a_find_or_flag() -> void:
	var zones := ZoneData.load_all()
	var homes := 0
	var gives := 0
	for zid in zones:
		if HomeLooks.is_home(str(zid), zones[zid]):
			homes += 1
			for ex in zones[zid].examine:
				if Examine.has_find(ex):
					gives += 1
					break
	assert_true(homes >= 160, "homes: %d" % homes)
	assert_true(gives * 5 >= homes and gives * 3 <= homes, "%d of %d carry a find or flag" % [gives, homes])
