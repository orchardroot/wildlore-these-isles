extends TestCase
## w50: a Corner Shop looked like a reading room (one bookshelf and a plant). Every shop now has stocked shelves
## behind the counter in both back corners, and the counter, the door and the shopkeeper are still reachable.

func test_the_shelf_builds_a_mesh() -> void:
	assert_true("shop_shelf" in ZoneBuilder.POINT_PROPS, "registered")
	assert_true("shop_shelf" in ZoneBuilder.CONTACT_SHADOWED, "sits on the floor")
	var mesh: ArrayMesh = ZoneBuilder._ctor("shop_shelf", 1)
	assert_true(mesh.get_surface_count() > 0 and mesh.surface_get_array_len(0) > 300, "a frame with stock on it")

func test_every_shop_is_stocked_and_walkable() -> void:
	var n := 0
	for f in DirAccess.get_files_at(ZoneData.DIR):
		if not f.ends_with("_shop.json"):
			continue
		var z := ZoneData.load_id(f.get_basename())
		var shelves := z.props.filter(func(p): return str(p.get("type", "")) == "shop_shelf")
		assert_true(shelves.size() >= 2, z.id + " has stocked shelves")
		assert_true(z.walkable(z.spawn), z.id + " spawn is clear")
		for keeper in z.npcs.filter(func(k): return int(k.y) == 1):  # behind the counter
			var to_counter := Vector2i(int(keeper.x), int(keeper.y)) + Vector2i(0, 2)
			assert_true(z.walkable(to_counter), z.id + ": the tile in front of the counter is clear")
		n += 1
	assert_true(n > 90, "found the shops")
