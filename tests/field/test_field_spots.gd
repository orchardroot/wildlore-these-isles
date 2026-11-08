extends TestCase
## Wave 48 F: field spots, the HM half of the party pieces.

func _spot(verb: String) -> Dictionary:
	for s in FieldSpots.all():
		if str(s.field) == verb and not FieldSpots.is_hop(s):
			return s
	return {}

func test_data_is_valid_and_wide() -> void:
	var errs := FieldSpots.check(ZoneData.load_all(), ItemDB.load_default())
	assert_eq(errs.size(), 0, str(errs.slice(0, 3)))
	assert_true(FieldSpots.all().size() >= 70, "70+ spots")
	for v in FieldSpots.VERBS:
		assert_true(not _spot(v).is_empty(), v + " has a spot")
	var regions := {}
	var zones := ZoneData.load_all()
	for s in FieldSpots.all():
		regions[zones[str(s.zone)].region] = true
	for r in ["cheshire", "peak", "cumbria", "scotland", "north_wales", "south_wales", "ireland", "cornwall", "yorkshire", "south_east"]:
		assert_true(regions.has(r), "region " + r)

func test_hop_spots_come_in_pairs() -> void:
	var hops := FieldSpots.all().filter(func(s): return FieldSpots.is_hop(s))
	assert_true(hops.size() >= 2 and hops.size() % 2 == 0, "pairs")

func test_hint_names_the_piece_and_where() -> void:
	var h := FieldSpots.hint(_spot("mend"))
	assert_true("party piece" in h[0] and FieldSpots.piece_name("mend") in h[0])
	assert_true(FieldSpots.piece_where("mend") in h[0])

## w51: the hint said "You learn it at The practice bog..." and "The move is Coopers Roll".
func test_hint_reads_well_with_the_real_move_name() -> void:
	var moves := MoveDB.load_default()
	var roll: String = FieldSpots.hint(_spot("roll"), moves)[0]
	assert_true("Cooper's Roll" in roll, roll)
	for v in FieldSpots.VERBS:
		var h: String = FieldSpots.hint(_spot(v), moves)[0]
		assert_false(" at The " in h or " at Beaches" in h or " at Harbour" in h, h)

func test_once_flag_and_gone() -> void:
	var d := GameStateData.new()
	var s := _spot("charm")
	assert_false(FieldSpots.gone(d, s))
	assert_false(FieldSpots.known(d, s))
	d.set_flag(FieldSpots.seen_key(s), true)
	assert_true(FieldSpots.known(d, s))
	d.set_flag(str(s.flag), true)
	assert_true(FieldSpots.gone(d, s))

func test_marks_need_a_sighting() -> void:
	var d := GameStateData.new()
	assert_eq(FieldSpots.marks(d).size(), 0)
	var s := _spot("mend")
	d.set_flag(FieldSpots.seen_key(s), true)
	assert_eq(FieldSpots.marks(d).size(), 1 if str(s.get("at", "")) != "" else 0)

func test_close_enough() -> void:
	assert_true(FieldSpots.close_enough(Vector2i(10, 10), Vector2i(14, 15)))
	assert_false(FieldSpots.close_enough(Vector2i(10, 10), Vector2i(17, 10)))

func test_helper_needs_the_move() -> void:
	var d := GameStateData.new()
	assert_true(FieldSpots.helper(d, "mend") == null, "nobody in the party")
