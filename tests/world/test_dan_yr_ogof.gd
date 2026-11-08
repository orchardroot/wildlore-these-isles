extends TestCase
## Dan yr Ogof (Brecon Beacons), a Deep Place built with the 3.7 kit: the four verbs, the way in, the plaques.

const ZONES := ["dyo_entry", "dyo_river", "dyo_cathedral", "dyo_bone"]

func test_the_way_in_is_wired_both_ways() -> void:
	var b := ZoneData.load_id("beacons")
	var door := {}
	for w in b.warps:
		if w.to == "dyo_entry":
			door = w
	assert_false(door.is_empty(), "a door in the Beacons")
	assert_true(b.walkable(Vector2i(int(door.x), int(door.y)) + Vector2i(0, 1)), "the doorstep is open")
	var e := ZoneData.load_id("dyo_entry")
	var back := false
	for w in e.warps:
		if w.to == "beacons":
			back = true
			assert_true(b.walkable(Vector2i(int(w.tx), int(w.ty))), "you come out on open ground")
	assert_true(back)

func test_every_floor_loads_and_has_plaques() -> void:
	var plaques := 0
	for id in ZONES:
		var z := ZoneData.load_id(id)
		assert_true(z != null and z.id == id, id)
		for s in z.signs:
			if s.has("plaque"):
				plaques += 1
	assert_true(plaques >= 4, "four plaques or more, got %d" % plaques)

func test_all_four_verbs_are_used() -> void:
	var lever := false
	var plate := false
	var light := false
	var flood := false
	for id in ZONES:
		var dp: Dictionary = ZoneData.load_id(id).deep
		lever = lever or not dp.get("gates", []).is_empty() and not dp.get("levers", []).is_empty()
		plate = plate or not dp.get("plates", []).is_empty()
		flood = flood or not dp.get("floods", []).is_empty()
		for l in dp.get("levers", []):
			light = light or bool(l.get("needs_light", false))
	assert_true(lever and plate and light and flood)

func test_weir_drains_the_river_and_block_opens_the_slab() -> void:
	var d := GameStateData.new()
	var r := ZoneData.load_id("dyo_river")
	DeepPlace.apply(d, r, {})
	assert_eq(r.tile_at(Vector2i(13, 5)), "deep_water")
	DeepPlace.pull(d, r.id, DeepPlace.lever_at(r, Vector2i(13, 4)))
	DeepPlace.apply(d, r, {})
	assert_eq(r.tile_at(Vector2i(13, 5)), "shallow")
	assert_true(r.reachable(r.spawn).has(Vector2i(18, 8)) or r.reachable(r.spawn).has(Vector2i(17, 8)))
	var c := ZoneData.load_id("dyo_cathedral")
	var crates := DeepPlace.crates_start(c)
	DeepPlace.apply(d, c, crates)
	assert_false(c.walkable(Vector2i(14, 4)), "the slab is across the way")
	for i in 2:
		DeepPlace.push(c, crates, crates.block, Vector2i(0, -1))
	for i in 5:
		assert_true(DeepPlace.can_push(c, crates, crates.block, Vector2i(1, 0)))
		DeepPlace.push(c, crates, crates.block, Vector2i(1, 0))
	assert_eq(DeepPlace.press_plates(d, c, crates, Vector2i(0, 0)), ["plate"])
	DeepPlace.apply(d, c, crates)
	assert_true(c.walkable(Vector2i(14, 4)), "and now it isn't")
