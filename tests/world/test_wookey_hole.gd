extends TestCase
## Wookey Hole as a three-floor Deep Place: the lever gate, the draining sluice with its lantern niche, the slab and
## plate, and the cave-aged cheddar at the end.

func _applied(id: String, d: GameStateData) -> ZoneData:
	var z := ZoneData.load_id(id)
	DeepPlace.apply(d, z, DeepPlace.crates_start(z))
	return z

func test_the_floors_are_linked_both_ways() -> void:
	var pairs := {"wookey_hole": "wookey_river", "wookey_river": "wookey_chamber"}
	for a in pairs:
		var b: String = pairs[a]
		var down := false
		for w in ZoneData.load_id(a).warps:
			down = down or w.to == b
		var up := false
		for w in ZoneData.load_id(b).warps:
			up = up or w.to == a
		assert_true(down and up, "%s <-> %s" % [a, b])

func test_all_four_puzzle_verbs_are_used() -> void:
	assert_false(ZoneData.load_id("wookey_hole").deep.levers.is_empty(), "lever and gate")
	var r := ZoneData.load_id("wookey_river")
	assert_false(r.deep.floods.is_empty(), "water level")
	assert_true(r.deep.levers[1].get("needs_light", false), "light and dark")
	assert_false(ZoneData.load_id("wookey_chamber").deep.plates.is_empty(), "weight on plate")

func test_the_hatch_lever_opens_the_stair() -> void:
	var d := GameStateData.new()
	var z := _applied("wookey_hole", d)
	assert_false(z.walkable(Vector2i(4, 17)))
	DeepPlace.pull(d, z.id, DeepPlace.lever_at(z, Vector2i(11, 15)))  # by the water, as its sign and the gate say
	DeepPlace.apply(d, z, {})
	assert_true(z.walkable(Vector2i(4, 17)))

func test_the_sluice_drains_the_passage() -> void:
	var d := GameStateData.new()
	var z := _applied("wookey_river", d)
	assert_false(z.walkable(Vector2i(13, 4)))
	DeepPlace.pull(d, z.id, DeepPlace.lever_at(z, Vector2i(8, 3)))
	DeepPlace.apply(d, z, {})
	assert_true(z.reachable(z.spawn).has(Vector2i(24, 7)))

func test_the_niche_wants_a_lantern() -> void:
	var d := GameStateData.new()
	var z := ZoneData.load_id("wookey_river")
	var niche := DeepPlace.lever_at(z, Vector2i(4, 5))
	assert_false(DeepPlace.can_find(d, z, niche))
	d.badges = ["iron"]
	assert_true(DeepPlace.can_find(d, z, niche))

func test_the_block_opens_the_cheese_store() -> void:
	var d := GameStateData.new()
	var z := _applied("wookey_chamber", d)
	var crates := DeepPlace.crates_start(z)
	assert_false(z.walkable(Vector2i(15, 3)))
	DeepPlace.push(z, crates, crates.block, Vector2i(0, -1))
	for i in 8:
		DeepPlace.push(z, crates, crates.block, Vector2i(1, 0))
	assert_eq(DeepPlace.press_plates(d, z, crates, Vector2i(0, 0)), ["plate"])
	DeepPlace.apply(d, z, crates)
	assert_true(z.walkable(Vector2i(15, 3)))

func test_plaques_and_rewards() -> void:
	var n := 0
	for id in ["wookey_hole", "wookey_river", "wookey_chamber"]:
		for s in ZoneData.load_id(id).signs:
			if s.has("plaque"):
				n += 1
				assert_true(str(s.plaque).begins_with("wookey_"))
	assert_true(n >= 4, "four or more plaques, got %d" % n)
	assert_true(ItemDB.load_default().has("wookey_cheddar"))
	assert_true(ItemDB.load_default().has("hyena_tooth"))
