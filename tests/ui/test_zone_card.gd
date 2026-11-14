extends TestCase
## The zone name card: shown on entering a new town or route, never for interiors or the same area again.

func test_card_rules() -> void:
	var c := ZoneCard.new()
	assert_true(c.note("town", "macclesfield"), "first town")
	assert_false(c.note("interior", "macc_home"), "never for interiors")
	assert_false(c.note("town", "macclesfield"), "back out of a house: same area, no card")
	assert_true(c.note("route", "macc_forest"), "a new route")
	assert_true(c.note("town", "macclesfield"), "back to town from the route")
	assert_false(c.note("town", "macclesfield"), "warping within the same town")
	c.free()

func test_subtitles() -> void:
	assert_eq(ZoneCard.subtitle("macclesfield", "cheshire"), "Cheshire")
	assert_eq(ZoneCard.subtitle("buxton", "peak"), "The Peak District")
	assert_eq(ZoneCard.subtitle("belfast", "ireland"), "Northern Ireland")
	assert_eq(ZoneCard.subtitle("dublin", "ireland"), "Ireland")
	assert_eq(ZoneCard.subtitle("london", "midlands"), "South East England")
	assert_eq(ZoneCard.subtitle("testbed", "dev"), "")
	assert_eq(ZoneCard.subtitle("nowhere", "made_up"), "", "unknown regions have no subtitle")

func test_every_outdoor_zone_has_a_subtitle() -> void:
	var all := ZoneData.load_all()
	for id in all:
		var z: ZoneData = all[id]
		if z.kind == "interior" or z.region in ["dev", ""]:
			continue
		assert_true(ZoneCard.subtitle(z.id, z.region) != "", "%s (%s) has a region subtitle" % [z.id, z.region])

func test_the_new_place_tally_waits_until_the_fifth_place() -> void:
	assert_eq(ZoneCard.new_line({"count": 1, "total": 217}), "NEW PLACE")
	assert_eq(ZoneCard.new_line({"count": 4, "total": 217, "label": "NEW PLACE"}), "NEW PLACE")
	assert_eq(ZoneCard.new_line({"count": 5, "total": 217}), "NEW PLACE  ·  5 of 217 found")
	assert_eq(ZoneCard.new_line({"count": 1, "total": 15, "label": "HIDDEN PLACE"}), "HIDDEN PLACE  ·  1 of 15 found")
