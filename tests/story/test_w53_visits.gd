extends TestCase
## Wave 53 people: residents who notice you've been before (Visits, hooked in ScriptHooks.wrap).

const Z := "w53_zone"
const N := "w53_npc"

func _entry() -> Dictionary:
	return {"who": "Test Person", "again": ["Back again."], "morning": ["Morning."], "evening": ["Evening."],
		"season": {"autumn": ["Leaves."]}, "weather": {"rain": ["Wet."]}}

func _setup() -> FakeStoryHost:
	Visits.reset()
	Visits.all().clear()
	Visits.all()[Visits.key(Z, N)] = _entry()
	return FakeStoryHost.new()

func _says(cmds: Array) -> Array:
	return cmds.filter(func(c): return c.get("do", "") == "say")

func test_first_talk_is_unchanged_and_sets_the_flag() -> void:
	var h := _setup()
	var base := [{"do": "say", "who": "Test Person", "text": "Hello."}]
	var out := ScriptHooks.wrap(Z, N, base, h.data)
	assert_eq(_says(out), base)
	assert_eq(out[-1], {"do": "set", "flag": Visits.flag_key(Z, N)})
	Visits.reset()

func test_old_save_without_the_flag_behaves_as_a_first_visit() -> void:
	var h := _setup()
	assert_true(h.data.flag(Visits.flag_key(Z, N)) == null)
	assert_eq(_says(Visits.hook(Z, N, [], h.data)), [])
	Visits.reset()

func test_second_talk_adds_exactly_one_line() -> void:
	var h := _setup()
	h.data.set_flag(Visits.flag_key(Z, N))
	var base := [{"do": "say", "who": "Test Person", "text": "Hello."}]
	var out := ScriptHooks.wrap(Z, N, base, h.data)
	assert_eq(_says(out).size(), 2)
	assert_eq(out[0], base[0])
	assert_eq(_says(out)[1].who, "Test Person")
	Visits.reset()

func test_strangers_and_missing_entries_are_untouched() -> void:
	var h := _setup()
	var base := [{"do": "say", "text": "hi"}]
	assert_eq(ScriptHooks.wrap("testbed", "nobody", base, h.data), base)
	Visits.reset()

func test_pools_follow_time_season_and_weather() -> void:
	var e := _entry()
	assert_eq(Visits.time_kind(9 * 60), "morning")
	assert_eq(Visits.time_kind(14 * 60), "")
	assert_eq(Visits.time_kind(20 * 60), "evening")
	assert_eq(Visits.time_kind(2 * 60), "evening")
	assert_eq(Visits.pools(e, 14 * 60, "spring", "clear"), [["Back again."]])
	assert_eq(Visits.pools(e, 9 * 60, "autumn", "downpour").size(), 4)
	assert_eq(Visits.pools(e, 14 * 60, "autumn", "clear"), [["Leaves."], ["Back again."]])
	assert_eq(Visits.weather_key("drizzle"), "rain")
	assert_eq(Visits.weather_key("clear"), "")

func test_pick_is_stable_and_stays_in_the_pools() -> void:
	var pl := [["a", "b"], ["c"]]
	for s in range(-5, 40):
		var l := Visits.pick(pl, s)
		assert_true(l in ["a", "b", "c"])
		assert_eq(l, Visits.pick(pl, s))
	assert_eq(Visits.pick([], 3), "")

func test_only_again_is_enough() -> void:
	assert_eq(Visits.pools({"again": ["x"]}, 9 * 60, "autumn", "downpour"), [["x"]])
	assert_eq(Visits.pools({}, 9 * 60, "autumn", "downpour"), [])

func test_check_catches_bad_shapes() -> void:
	Visits.reset()
	Visits.all().clear()  # only this test's entries, not the shipped ones
	var zones := {Z: _zone()}
	Visits.all()[Visits.key(Z, N)] = {"who": "Test Person", "again": []}
	assert_eq(Visits.check(zones).size(), 1)
	Visits.all()[Visits.key(Z, N)] = {"who": "Test Person", "season": {"autumn": ["ok"], "monsoon": ["x"]}, "weather": {"rain": [""]}}
	assert_eq(Visits.check(zones).size(), 2)
	Visits.all()[Visits.key(Z, N)] = {"who": "Someone Else", "again": ["x"]}
	assert_eq(Visits.check(zones).size(), 1)
	Visits.all()[Visits.key(Z, N)] = _entry()
	assert_eq(Visits.check(zones), [])
	Visits.all()["nowhere|x"] = {"again": ["x"]}
	assert_eq(Visits.check(zones).size(), 1)
	Visits.reset()

func _zone() -> Object:
	var o := RefCounted.new()
	o.set_script(preload("res://tests/story/w53_zone_stub.gd"))
	return o

func test_shipped_data_is_valid_and_every_home_resident_has_an_again_line() -> void:
	Visits.reset()
	var zones := ZoneData.load_all()
	assert_eq(Visits.check(zones), [])
	assert_eq(Visits.missing_again(zones), [])
	Visits.reset()
