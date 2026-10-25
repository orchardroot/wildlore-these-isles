extends TestCase
## Landing tiles that the load-time overlays have made unstandable (the nightly fuzz drops the bot in a lease zone or
## beyond a closed Deep Place gate, then walks out onto the fence): ZoneData.landing_near finds the nearest tile
## that can be stood on.

func test_arriving_through_an_unowned_gap_does_not_land_on_the_fence() -> void:
	for id in ["pennine_grouse_moor", "welsh_conifer_plantation"]:
		var l := Leases.get_lease(id)
		var z := ZoneData.load_id(str(l.anchor))
		var lane := Leases.border_tiles(z, l)
		var landing: Vector2i = lane[lane.size() / 2]
		Leases.apply(GameStateData.new(), z)
		assert_false(z.walkable(landing), id + ": the landing tile is fenced")
		var spot := z.landing_near(landing)
		assert_true(z.walkable(spot), id + ": set down somewhere standable")
		assert_true(absi(spot.x - landing.x) + absi(spot.y - landing.y) <= 3, id + ": and close by")

func test_a_closed_gate_on_the_landing_tile() -> void:
	var z := ZoneData.load_id("wookey_hole")
	var d := GameStateData.new()
	DeepPlace.apply(d, z, DeepPlace.crates_start(z))
	var gate := Vector2i(4, 17)
	assert_false(z.walkable(gate), "the gate is shut")
	assert_true(z.walkable(z.landing_near(gate)))
	assert_eq(z.landing_near(Vector2i(5, 17)), Vector2i(5, 17), "a standable tile is left alone")
