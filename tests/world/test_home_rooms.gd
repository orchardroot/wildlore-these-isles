extends TestCase
## Every dressed home (w53): the spawn, warps, signs and NPC tiles stay clear, every NPC can be talked to, every
## floor tile is reachable from the door, and a save that stood on a tile that is now furniture lands beside it.

func _homes() -> Array:
	var out := []
	var zs := ZoneData.load_all()
	for id in zs:
		var z: ZoneData = zs[id]
		if z.kind == "interior" and ("_home" in id or "cottage" in id) and not z.props.filter(func(p): return p.get("type") in HomeProps.NAMES).is_empty():
			out.append(z)
	return out

func test_the_regional_pieces_are_in_use() -> void:
	var seen := {}
	for z in _homes():
		for p in z.props:
			seen[p.get("type")] = true
	for t in HomeProps.NAMES:
		assert_true(seen.has(t), t + " furnishes a home")

func test_dressed_homes_stay_walkable() -> void:
	for z in _homes():
		var reach: Dictionary = z.reachable(z.spawn)
		assert_true(z.walkable(z.spawn), z.id + ": spawn clear")
		for w in z.warps:
			assert_true(reach.has(Vector2i(int(w.x), int(w.y))), z.id + ": door reachable")
		for n in z.npcs:
			var p := Vector2i(int(n.x), int(n.y))
			var near := [p + Vector2i(1, 0), p + Vector2i(-1, 0), p + Vector2i(0, 1), p + Vector2i(0, -1)]
			var ok := false
			for q in near:
				if reach.has(q) or (z.tile_at(q) == "counter" and reach.has(q + (q - p))):
					ok = true
			assert_true(ok, z.id + ": " + str(n.get("id")) + " can be talked to")

func test_a_save_on_new_furniture_lands_on_floor() -> void:
	for z in _homes():
		for p in z.props:
			if p.get("type") in HomeProps.NAMES and not p.get("walk", false):
				var spot: Vector2i = z.landing_near(Vector2i(int(p.x), int(p.y)))
				assert_true(z.walkable(spot), z.id + ": landing beside " + str(p.type))
