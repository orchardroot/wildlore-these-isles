extends TestCase
## Session G: the zone graph, routes and the breadcrumb.

func _data() -> GameStateData:
	return GameStateData.new()

func test_walking_route_between_neighbours() -> void:
	var g := ZoneGraph.shared()
	var p := ZoneGraph.route(g, "macclesfield", "buxton", _data())
	assert_true(p.size() >= 2)
	assert_eq(p[0], "macclesfield")
	assert_eq(p[p.size() - 1], "buxton")
	for i in range(1, p.size()):
		assert_true(g.walk[p[i - 1]].has(p[i]))
		assert_eq(ZoneGraph.hop_mode(g, p[i - 1], p[i]), "walk")

func test_no_route_across_the_sea_without_a_ferry() -> void:
	var g := ZoneGraph.shared()
	assert_eq(ZoneGraph.route(g, "macclesfield", "dublin", _data()), [])

func test_ferry_opens_the_sea() -> void:
	var g := ZoneGraph.shared()
	var d := _data()
	d.set_flag("visited_holyhead")
	d.set_flag("visited_dublin")
	var p := ZoneGraph.route(g, "holyhead", "dublin", d)
	assert_eq(p, ["holyhead", "dublin"])
	assert_eq(ZoneGraph.hop_mode(g, "holyhead", "dublin"), "ferry")
	assert_true(ZoneGraph.summary(g, p).contains("ferry from"))
	assert_eq(ZoneGraph.route(g, "holyhead", "dublin", _data()), [])

func test_rail_beats_a_long_walk() -> void:
	var g := ZoneGraph.shared()
	var d := _data()
	var walk := ZoneGraph.route(g, "birmingham", "york", d)
	assert_true(walk.size() > 4)
	d.bag["rail_pass"] = 1
	d.set_flag("station_birmingham")
	d.set_flag("station_york")
	var by_rail := ZoneGraph.route(g, "birmingham", "york", d)
	assert_eq(by_rail, ["birmingham", "york"])
	assert_eq(ZoneGraph.hop_mode(g, "birmingham", "york"), "rail")
	assert_true(ZoneGraph.summary(g, by_rail).contains("the train from Birmingham"))
	d.bag.erase("rail_pass")  # no pass, no train
	assert_eq(ZoneGraph.route(g, "birmingham", "york", d), walk)

func test_rail_does_not_cross_the_sea() -> void:
	var g := ZoneGraph.shared()
	var d := _data()
	d.bag["rail_pass"] = 1
	d.set_flag("station_birmingham")
	d.set_flag("station_dublin")
	assert_eq(ZoneGraph.route(g, "birmingham", "dublin", d), [])

func test_summary_counts_walking() -> void:
	var g := ZoneGraph.shared()
	var p := ZoneGraph.route(g, "macclesfield", "buxton", _data())
	assert_true(ZoneGraph.summary(g, p).begins_with("%d zone" % (p.size() - 1)))

func test_bot_adjacency_is_the_graph_walk() -> void:
	var zones := ZoneData.load_all()
	var adj := ZoneGraph.walk_adj(zones)
	assert_true(adj["macclesfield"].has("macc_home"))
	assert_true(adj["macc_home"].has("macclesfield"))
	assert_eq(int(ZoneGraph.hops(adj, "macclesfield")["macc_home"]), 1)

func test_map_points_skip_unplaced() -> void:
	var z := {"a": {"pos": Vector2(1, 2)}, "b": {"pos": Vector2(-1, -1)}, "c": {"pos": Vector2(3, 4)}}
	assert_eq(MapLogic.route_points(["a", "b", "c"], z).size(), 2)
	var idx: Dictionary = ZoneIndex.get_index().zones
	var p := ZoneGraph.route(ZoneGraph.shared(), "macclesfield", "buxton", _data())
	assert_true(MapLogic.route_points(p, idx).size() >= 2)

func test_guide_points_at_the_exit_and_clears_on_arrival() -> void:
	var g := ZoneGraph.shared()
	var d := _data()
	var z := ZoneData.load_id("macclesfield")
	var r := ZoneGraph.guide(g, z, Vector2i(10, 10), "buxton", d, "Buxton")
	assert_eq(r.state, "go")
	assert_true(str(r.text).begins_with("To Buxton"))
	assert_true(str(r.arrow) in ["→", "↘", "↓", "↙", "←", "↖", "↑", "↗"])
	assert_eq(ZoneGraph.guide(g, ZoneData.load_id("buxton"), Vector2i(5, 5), "buxton", d, "Buxton").state, "arrived")
	assert_eq(ZoneGraph.guide(g, ZoneData.load_id("macc_home"), Vector2i(2, 2), "buxton", d, "Buxton").state, "off")
	assert_eq(ZoneGraph.guide(g, z, Vector2i(10, 10), "", d, "").state, "off")

func test_arrow_directions() -> void:
	assert_eq(ZoneGraph.arrow_for({"side": "north"}, Vector2i.ZERO), "↑")
	assert_eq(ZoneGraph.arrow_for({"side": "east"}, Vector2i.ZERO), "→")
	assert_eq(ZoneGraph.arrow_for({"pos": Vector2i(0, 9)}, Vector2i(0, 2)), "↓")
	assert_eq(ZoneGraph.arrow_for({"pos": Vector2i(-5, 0)}, Vector2i(0, 0)), "←")

func test_exit_toward_edge_and_warp() -> void:
	var z := ZoneData.load_id("macclesfield")
	assert_eq(ZoneGraph.exit_toward(z, "macc_forest", "walk", Vector2i.ZERO), {"side": "east"})
	assert_eq(ZoneGraph.exit_toward(z, "macc_home", "walk", Vector2i.ZERO), {"pos": Vector2i(8, 10)})
	assert_eq(ZoneGraph.exit_toward(z, "nowhere", "walk", Vector2i.ZERO), {})
