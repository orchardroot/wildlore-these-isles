extends TestCase
## Wave 56: a point of interest is solid in the real game, so it must never stand on a path, road, door-front or gap.

func test_no_poi_stands_on_a_path_or_in_a_gap() -> void:
	var zones := ZoneData.load_all()
	var bad := []
	for p in Poi.all():
		var z: ZoneData = zones[str(p.zone)]
		var t := Poi.tile(z, p)
		if not Poi.placeable(z, t):
			bad.append("%s at %s (%s)" % [p.id, t, z.tile_at(t)])
	assert_eq(bad.size(), 0, str(bad.slice(0, 5)))

func test_chat_moss_stone_and_camp_moved_off_the_path() -> void:
	var z := ZoneData.load_id("chat_moss")
	for id in ["poi_chat_moss_stone", "poi_chat_moss_camp"]:
		var t := Poi.tile(z, Poi.by_id(id))
		assert_true(z.tile_at(t) in Poi.OPEN_TILES, "%s on %s" % [id, z.tile_at(t)])

func test_poi_tile_keeps_the_zone_connected() -> void:
	var zones := ZoneData.load_all()
	for p in Poi.all().slice(0, 40):
		var z: ZoneData = zones[str(p.zone)]
		var t := Poi.tile(z, p)
		var all := z.reachable(z.spawn)
		if all.has(t):
			assert_true(z.reachable(z.spawn, [], {t: true}).size() >= all.size() - 1, "%s corks %s" % [p.id, z.id])
