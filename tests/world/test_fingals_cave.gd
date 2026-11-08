extends TestCase
## Fingal's Cave as a Deep Place: three floors, all four puzzle verbs, plaques, and a reward.

func _applied(id: String, d: GameStateData) -> ZoneData:
	var z := ZoneData.load_id(id)
	DeepPlace.apply(d, z, DeepPlace.crates_start(z))
	return z

## A closed gate: a solid gate prop on the room's own floor (DeepPlace.apply).
func _shut(z: ZoneData, p: Vector2i) -> bool:
	for pr in z.props:
		if pr.get("type") == DeepPlace.GATE_PROP and Vector2i(int(pr.x), int(pr.y)) == p:
			return not z.walkable(p)
	return false

func test_the_floors_are_linked_and_valid() -> void:
	var all := ZoneData.load_all()
	for id in ["staffa_cave", "staffa_columns", "staffa_hollow"]:
		assert_eq(all[id].validate(all), [], id)
	assert_eq(all["staffa_columns"].warp_at(Vector2i(1, 1)).to, "staffa_cave")
	assert_eq(all["staffa_cave"].warp_at(Vector2i(8, 2)).to, "staffa_columns")
	assert_eq(all["staffa_columns"].warp_at(Vector2i(20, 5)).to, "staffa_hollow")

func test_winch_opens_the_first_gate() -> void:
	var d := GameStateData.new()
	var z := _applied("staffa_columns", d)
	assert_true(_shut(z, Vector2i(8, 3)))
	DeepPlace.pull(d, z.id, DeepPlace.lever_at(z, Vector2i(6, 4)))
	DeepPlace.apply(d, z, DeepPlace.crates_start(z))
	assert_false(_shut(z, Vector2i(8, 3)))

func test_block_onto_stone_plate_opens_the_second_gate() -> void:
	var d := GameStateData.new()
	var z := _applied("staffa_columns", d)
	var crates := DeepPlace.crates_start(z)
	for i in 6:
		assert_true(DeepPlace.can_push(z, crates, crates.block, Vector2i(1, 0)))
		DeepPlace.push(z, crates, crates.block, Vector2i(1, 0))
	assert_eq(DeepPlace.press_plates(d, z, crates, Vector2i.ZERO), ["stone"])
	DeepPlace.apply(d, z, crates)
	assert_false(_shut(z, Vector2i(18, 3)))

func test_tide_and_echo_in_the_hollow() -> void:
	var d := GameStateData.new()
	var z := _applied("staffa_hollow", d)
	assert_eq(z.tile_at(Vector2i(10, 3)), "deep_water")
	assert_true(_shut(z, Vector2i(16, 3)))
	DeepPlace.pull(d, z.id, DeepPlace.lever_at(z, Vector2i(6, 4)))
	DeepPlace.apply(d, z, {})
	assert_eq(z.tile_at(Vector2i(10, 3)), "shallow")
	var echo := DeepPlace.lever_at(z, Vector2i(14, 4))
	assert_false(DeepPlace.can_find(d, z, echo), "no lantern, no ringing column")
	d.badges = ["iron"]
	assert_true(DeepPlace.can_find(d, z, echo))
	DeepPlace.pull(d, z.id, echo)
	DeepPlace.apply(d, z, {})
	assert_false(_shut(z, Vector2i(16, 3)))

func test_four_plaques_and_the_reward() -> void:
	var n := 0
	for id in ["staffa_cave", "staffa_columns", "staffa_hollow"]:
		for s in ZoneData.load_id(id).signs:
			if str(s.get("plaque", "")).begins_with("staffa_"):
				n += 1
	assert_true(n >= 4, "plaques: %d" % n)
	var items := ItemDB.load_default()
	assert_true(int(items.get_item("fingals_organ_pipe").price) > int(items.get_item("staffa_basalt_chip").price))
