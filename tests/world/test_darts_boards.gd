extends TestCase
## w51: the five darts pubs had a darts player but no dartboard, so nothing in the room said where the game was.

func test_the_board_builds() -> void:
	assert_true("dartboard" in ZoneBuilder.POINT_PROPS, "registered")
	var mesh: ArrayMesh = ZoneBuilder._ctor("dartboard", 0)
	assert_true(mesh.get_surface_count() > 0 and mesh.surface_get_array_len(0) > 100, "a board with its rings")

func test_every_darts_pub_has_a_board() -> void:
	var n := 0
	for f in DirAccess.get_files_at(ZoneData.DIR):
		if not f.ends_with(".json"):
			continue
		var z := ZoneData.load_id(f.get_basename())
		if z == null or not z.npcs.any(func(p): return str(p.get("id", "")).ends_with("_darts")):
			continue
		n += 1
		assert_true(z.props.any(func(p): return str(p.get("type", "")) == "dartboard"), z.id + " has a dartboard")
	assert_true(n >= 5, "found the darts pubs")
