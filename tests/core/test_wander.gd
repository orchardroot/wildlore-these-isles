extends TestCase
## "Where next?" wanders (5.4): a road next door you have never walked, or what is still waiting off the road.

func _d() -> GameStateData:
	return GameStateData.new()

func _texts(d: GameStateData, town: String, opts := {}) -> Array:
	opts["story"] = false
	opts["fest"] = []
	return WhereNext.suggest(d, 0, town, opts).filter(func(s): return s.kind == "wander").map(func(s): return s.text)

func test_no_town_no_wander() -> void:
	assert_eq(_texts(_d(), ""), [])

func test_an_unwalked_road_next_door_is_named() -> void:
	var t := _texts(_d(), "buxton")
	assert_eq(t.size(), 1, str(t))
	assert_true(t[0].contains("just down the road"), t[0])
	assert_false(t[0].contains("—"))

func test_what_is_unfound_is_counted_once_the_roads_are_walked() -> void:
	var idx := ZoneIndex.get_index()
	var d := _d()
	for to in idx.zones["buxton"].links:
		if idx.zones[to].kind == "route":
			d.set_flag(Discovery.found_key(str(to)))
	var t := _texts(d, "buxton")
	for line in t:
		assert_true(line.contains("Still to find") or line.contains("just down"), line)

func test_the_test_override_is_used_as_written() -> void:
	assert_eq(_texts(_d(), "", {"wander": "Go and look at the stile."}), ["Go and look at the stile."])

func test_wander_never_crowds_out_the_story() -> void:
	var out := WhereNext.suggest(_d(), 0, "buxton", {"fest": [], "wander": "A stile."})
	assert_true(out.size() <= WhereNext.LIMIT)
	var kinds := out.map(func(x): return x.kind)
	if "story" in kinds:
		assert_eq(kinds[0], "story", "the story always leads")
	assert_true("wander" in kinds, "a stile is worth a mention")

func test_a_road_behind_a_shut_gate_is_not_advertised() -> void:
	var d := _d()
	var z := {"gates": ["badge_storm", "trainer_x"]}
	assert_false(WhereNext.gates_open(d, z))
	d.set_flag("badge_storm", true)
	assert_false(WhereNext.gates_open(d, z), "every gate, not any")
	d.set_flag("trainer_x", true)
	assert_true(WhereNext.gates_open(d, z))
	assert_true(WhereNext.gates_open(d, {}), "no gates, open")

func test_the_index_carries_the_gates_of_a_gated_route() -> void:
	var idx := ZoneIndex.get_index()
	assert_has(idx.zones["exe_estuary"].gates, "badge_storm")
