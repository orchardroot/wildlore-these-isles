extends TestCase
## w51: a Sanctuary looked like a reading room (a counter, a bookshelf, a plant). Every one now has the restoring
## cabinet behind the counter, a shelf of medicines, creature baskets, the noticeboard and a poster, and the
## counter, the nurse, the Retired Keeper and the door are all still reachable.

const PROPS := ["sanctuary_restorer", "sanctuary_shelf", "creature_basket", "sanctuary_noticeboard", "sanctuary_poster"]

func test_the_furniture_builds_meshes() -> void:
	for p in PROPS:
		assert_true(p in ZoneBuilder.POINT_PROPS, p + " registered")
		for v in 2:
			var mesh: ArrayMesh = ZoneBuilder._ctor(p, v)
			assert_true(mesh != null and mesh.get_surface_count() > 0 and mesh.surface_get_array_len(0) > 100, "%s %d has a mesh" % [p, v])
	for p in ["sanctuary_restorer", "sanctuary_shelf", "creature_basket"]:
		assert_true(p in ZoneBuilder.CONTACT_SHADOWED, p + " sits on the floor")

func _reachable(z: ZoneData) -> Dictionary:
	var seen := {z.spawn: true}
	var q := [z.spawn]
	while not q.is_empty():
		var p: Vector2i = q.pop_front()
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n: Vector2i = p + d
			if not seen.has(n) and z.walkable(n):
				seen[n] = true
				q.append(n)
	return seen

func test_every_sanctuary_is_dressed_and_walkable() -> void:
	var n := 0
	for f in DirAccess.get_files_at(ZoneData.DIR):
		if not f.ends_with("_sanctuary.json"):
			continue
		var z := ZoneData.load_id(f.get_basename())
		var types := z.props.map(func(p): return str(p.get("type", "")))
		for p in ["sanctuary_restorer", "sanctuary_shelf", "creature_basket", "sanctuary_noticeboard"]:
			assert_true(p in types, "%s has a %s" % [z.id, p])
		assert_false("bookshelf" in types, z.id + ": no reading-room bookshelf")
		assert_true(z.walkable(z.spawn), z.id + " spawn is clear")
		var seen := _reachable(z)
		for w in z.warps:
			var door := Vector2i(int(w.x), int(w.y))
			assert_true(seen.has(door) or seen.has(door + Vector2i.UP), z.id + ": the way out")
		for k in z.npcs:
			var at := Vector2i(int(k.x), int(k.y))
			var near := false
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN, Vector2i(0, 2)]:  # across the counter
				near = near or seen.has(at + d)
			assert_true(near, "%s: you can reach %s" % [z.id, k.id])
		n += 1
	assert_true(n > 100, "found the sanctuaries")
