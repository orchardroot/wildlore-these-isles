extends TestCase
## SoundEmitters: where hearths, clocks, streams and the shore are in a zone, and how their sound falls away with distance.

func _zone(kind: String, rows: Array, props := []) -> ZoneData:
	var d := {"id": "t", "name": "T", "kind": kind, "rows": rows, "props": props, "warps": [], "edges": {},
		"npcs": [], "encounters": {}, "signs": [], "spawn": [0, 0], "weather": {}}
	return ZoneData.from_dict(d)

func test_a_room_with_a_hearth_and_a_clock_has_both() -> void:
	var z := _zone("interior", ["....", "...."], [{"type": "fireplace", "x": 1, "y": 0}, {"type": "clock", "x": 3, "y": 0}, {"type": "table", "x": 2, "y": 1}])
	var p := SoundEmitters.plan(z)
	assert_eq(p.keys().size(), 2)
	assert_eq(p.fire, [Vector2(1.5, 0.5)])
	assert_eq(p.clock, [Vector2(3.5, 0.5)])

func test_a_bare_room_makes_no_sound_of_its_own() -> void:
	assert_true(SoundEmitters.plan(_zone("interior", ["...."], [{"type": "table", "x": 2, "y": 0}])).is_empty())

func test_streams_and_the_shore_are_outdoors_only() -> void:
	var rows := ["....~~..", "....~~..", "$$$$....", "$$$$...."]
	var p := SoundEmitters.plan(_zone("route", rows))
	assert_true(p.has("stream"))
	assert_true(p.has("shore"))
	for s in p.stream:
		assert_true(s.x >= 4.0 and s.x < 6.0 and s.y < 2.0, "a stream source sits on water %s" % s)
	for s in p.shore:
		assert_true(s.x < 4.5, "a shore source sits on the sea %s" % s)
	assert_true(SoundEmitters.plan(_zone("interior", rows)).is_empty(), "a room's painted water is not a stream")

func test_open_sea_is_not_a_shore() -> void:
	var p := SoundEmitters.plan(_zone("route", ["$$$$", "$$$$", "$$$$"]))
	assert_false(p.has("shore"), "no land, no breakers")

func test_a_long_river_is_thinned() -> void:
	var rows := []
	for y in 40:
		rows.append("~".repeat(40))
	var p := SoundEmitters.plan(_zone("route", rows))
	assert_true(p.stream.size() <= SoundEmitters.MAX_SOURCES)
	assert_true(p.stream.size() > 10)

func test_gain_falls_with_distance_and_goes_silent() -> void:
	assert_eq(SoundEmitters.gain_db(0.5, 1.5, 9.0), 0.0, "full close by")
	assert_eq(SoundEmitters.gain_db(1.5, 1.5, 9.0), 0.0)
	var a := SoundEmitters.gain_db(3.0, 1.5, 9.0)
	var b := SoundEmitters.gain_db(6.0, 1.5, 9.0)
	assert_true(a < 0.0 and b < a, "quieter the further off")
	assert_eq(SoundEmitters.gain_db(9.0, 1.5, 9.0), SoundEmitters.SILENT, "gone past its range")
	assert_eq(SoundEmitters.gain_db(40.0, 1.5, 9.0), SoundEmitters.SILENT)
	assert_true(SoundEmitters.gain_db(8.5, 1.5, 9.0) < -30.0, "fades out rather than cutting off")

func test_nearest_picks_the_closest() -> void:
	assert_eq(SoundEmitters.nearest([Vector2(10, 0), Vector2(3, 4)], Vector2.ZERO), 5.0)
	assert_eq(SoundEmitters.nearest([], Vector2.ZERO), INF)

func test_every_kind_has_a_loop_file() -> void:
	for kind in SoundEmitters.KINDS:
		assert_true(ResourceLoader.exists("res://audio/ambience/%s.wav" % SoundEmitters.KINDS[kind][0]), kind)
