extends TestCase
## The Deep Places kit (DeepPlace) on the real Blue John Cavern: lever and gate, weight on plate, light and dark,
## water level, and that the zones around it are wired up.

func _data() -> GameStateData:
	return GameStateData.new()

func _applied(id: String, d: GameStateData, crates := {}) -> ZoneData:
	var z := ZoneData.load_id(id)
	DeepPlace.apply(d, z, crates if not crates.is_empty() else DeepPlace.crates_start(z))
	return z

## A closed gate: a solid gate prop on the room's own floor (DeepPlace.apply).
func _shut(z: ZoneData, p: Vector2i) -> bool:
	for pr in z.props:
		if pr.get("type") == DeepPlace.GATE_PROP and Vector2i(int(pr.x), int(pr.y)) == p:
			return not z.walkable(p)
	return false

func test_lever_opens_the_gate_and_back() -> void:
	var d := _data()
	var z := _applied("blue_john_entry", d)
	assert_true(_shut(z, Vector2i(6, 4)), "shut on a fresh save")
	assert_false(z.walkable(Vector2i(6, 4)))
	var lever := DeepPlace.lever_at(z, Vector2i(10, 6))  # beside the desk, as Gwen says
	assert_true(DeepPlace.pull(d, z.id, lever))
	DeepPlace.apply(d, z, DeepPlace.crates_start(z))
	assert_false(_shut(z, Vector2i(6, 4)))
	assert_true(z.walkable(Vector2i(7, 4)))
	assert_false(DeepPlace.pull(d, z.id, lever), "a second pull shuts it")
	DeepPlace.apply(d, z, DeepPlace.crates_start(z))
	assert_true(_shut(z, Vector2i(7, 4)))

func test_conditions_can_want_a_lever_off() -> void:
	var d := _data()
	d.set_flag(DeepPlace.flag_key("z", "a"), true)
	assert_true(DeepPlace.cond_met(d, "z", ["lever:a"]))
	assert_false(DeepPlace.cond_met(d, "z", ["lever:a", "!lever:a"]))
	assert_true(DeepPlace.cond_met(d, "z", ["!lever:b"]))
	assert_true(DeepPlace.cond_met(d, "z", []), "no condition, no lock")

func test_the_valve_drains_the_passage() -> void:
	var d := _data()
	var z := _applied("blue_john_stream", d)
	assert_eq(z.tile_at(Vector2i(12, 5)), "deep_water")
	assert_false(z.walkable(Vector2i(12, 5)), "no Brook-wade, no crossing")
	assert_true(z.walkable(Vector2i(12, 5), Vector2i.ZERO, ["brook_wade"]))
	DeepPlace.pull(d, z.id, DeepPlace.lever_at(z, Vector2i(8, 4)))
	DeepPlace.apply(d, z, {})
	assert_eq(z.tile_at(Vector2i(12, 5)), "shallow")
	assert_true(z.reachable(z.spawn).has(Vector2i(19, 8)), "now on foot all the way to the steps down")

func test_the_hidden_pocket_wants_a_lantern() -> void:
	var d := _data()
	var z := ZoneData.load_id("blue_john_stream")
	var pocket := DeepPlace.lever_at(z, Vector2i(4, 3))
	assert_false(DeepPlace.can_find(d, z, pocket), "two tiles of light is not enough")
	d.badges = ["iron"]
	assert_true(DeepPlace.can_find(d, z, pocket))
	assert_true(DeepPlace.can_find(d, z, DeepPlace.lever_at(z, Vector2i(8, 4))), "the valve is in plain sight")

func test_slab_onto_plate_opens_the_vein() -> void:
	var d := _data()
	var z := _applied("blue_john_chamber", d)
	var crates := DeepPlace.crates_start(z)
	assert_true(_shut(z, Vector2i(14, 4)), "shut until the plate is pressed")
	for i in 2:  # up from (5,6) to (5,4)
		var at: Vector2i = crates.slab
		assert_true(DeepPlace.can_push(z, crates, at, Vector2i(0, -1)))
		DeepPlace.push(z, crates, at, Vector2i(0, -1))
	assert_eq(crates.slab, Vector2i(5, 4))
	for i in 6:  # along to (11,4)
		assert_true(DeepPlace.press_plates(d, z, crates, Vector2i(0, 0)).is_empty())
		DeepPlace.push(z, crates, crates.slab, Vector2i(1, 0))
	assert_eq(DeepPlace.press_plates(d, z, crates, Vector2i(0, 0)), ["plate"])
	DeepPlace.apply(d, z, crates)
	assert_false(_shut(z, Vector2i(14, 4)))
	assert_eq(DeepPlace.press_plates(d, z, crates, Vector2i(0, 0)), [], "latched: pressing again changes nothing")
	var back := _applied("blue_john_chamber", d)
	assert_false(_shut(back, Vector2i(14, 4)), "the latch is saved, so a return visit finds it open")

func test_a_crate_will_not_go_into_a_wall_or_another_crate() -> void:
	var d := _data()
	var z := _applied("blue_john_chamber", d)
	var crates := {"a": Vector2i(1, 4), "b": Vector2i(2, 4)}
	assert_false(DeepPlace.can_push(z, crates, Vector2i(1, 4), Vector2i(-1, 0)), "wall")
	assert_false(DeepPlace.can_push(z, crates, Vector2i(1, 4), Vector2i(1, 0)), "another crate")
	assert_false(DeepPlace.can_push(z, crates, Vector2i(3, 4), Vector2i(1, 0)), "nothing there")

func test_the_zones_check_out() -> void:
	var all := ZoneData.load_all()
	for id in ["castleton", "blue_john_entry", "blue_john_stream", "blue_john_chamber", "buxton"]:
		assert_eq(all[id].validate(all), [], id)
	assert_eq(all["buxton"].edges.south.to, "castleton")
	assert_eq(all["castleton"].edges.north.to, "buxton")

func test_the_reward_is_there_and_is_once_only() -> void:
	var items := ItemDB.load_default()
	assert_true(int(items.get_item("blue_john").price) > int(items.get_item("blue_john_chip").price))
	var z := ZoneData.load_id("blue_john_chamber")
	assert_eq(z.npcs[0].hide_if, "bluejohn_caught", "the creature is gone once caught")

func test_marble_arch_caves_floors() -> void:
	var d := _data()
	var z := _applied("marblearch_cladagh", d)
	assert_false(z.walkable(Vector2i(12, 4)), "flooded until the weir is lifted")
	assert_true(_shut(z, Vector2i(17, 4)), "the grille is down")
	DeepPlace.pull(d, z.id, DeepPlace.lever_at(z, Vector2i(7, 3)))
	DeepPlace.pull(d, z.id, DeepPlace.lever_at(z, Vector2i(16, 2)))
	DeepPlace.apply(d, z, {})
	assert_true(z.reachable(z.spawn).has(Vector2i(19, 8)), "on foot to the stairs down")
	assert_false(DeepPlace.can_find(d, z, DeepPlace.lever_at(z, Vector2i(2, 3))), "pearls want a lantern")
	var h := _applied("marblearch_deep", d)
	assert_true(_shut(h, Vector2i(14, 5)))
	assert_eq(ZoneData.load_id("enniskillen_marblearch").tile_at(Vector2i(8, 1)), "door")

func test_aillwee_cave_is_wired_and_solvable() -> void:
	var d := _data()
	var burren := ZoneData.load_id("burren")
	var linked := false
	for w in burren.warps:
		if w.get("to", "") == "aillwee_entry":
			linked = true
	assert_true(linked, "Aillwee door on the Burren")
	var haven := _applied("aillwee_haven", d)
	assert_true(_shut(haven, Vector2i(14, 4)), "slab shut until the plate is pressed")
	var gallery := _applied("aillwee_gallery", d)
	assert_eq(gallery.tile_at(Vector2i(9, 5)), "deep_water")
	DeepPlace.pull(d, gallery.id, DeepPlace.lever_at(gallery, Vector2i(8, 3)))
	DeepPlace.apply(d, gallery, {})
	assert_eq(gallery.tile_at(Vector2i(9, 5)), "shallow")
	assert_false(DeepPlace.can_find(d, gallery, DeepPlace.lever_at(gallery, Vector2i(6, 2))), "the crack needs the lantern")

func _look(zone_id: String, kind: String, list: String, i: int) -> String:
	return DeepPlace.look_of(kind, ZoneData.load_id(zone_id).deep[list][i])

func test_pieces_are_drawn_as_their_lines_say() -> void:
	assert_eq(_look("blue_john_entry", DeepPlace.GATE_PROP, "gates", 0), "cave_gate")
	assert_eq(_look("dyo_entry", DeepPlace.GATE_PROP, "gates", 0), "barrier")
	assert_eq(_look("dyo_entry", DeepPlace.LEVER_PROP, "levers", 0), "handle", "the brass handle by the desk")
	assert_eq(_look("wookey_chamber", DeepPlace.GATE_PROP, "gates", 0), "oak_door")
	assert_eq(_look("staffa_columns", DeepPlace.GATE_PROP, "gates", 0), "timber_gate")
	assert_eq(_look("staffa_columns", DeepPlace.GATE_PROP, "gates", 1), "basalt_slab")
	assert_eq(_look("staffa_columns", DeepPlace.CRATE_PROP, "crates", 0), "column", "the loose column-end on the sign")
	assert_eq(_look("marblearch_cladagh", DeepPlace.GATE_PROP, "gates", 0), "grille")
	assert_eq(_look("marblearch_cladagh", DeepPlace.LEVER_PROP, "levers", 1), "winch")
	assert_eq(_look("marblearch_deep", DeepPlace.GATE_PROP, "gates", 0), "flowstone")
	assert_eq(_look("blaenavon_bigpit_east", DeepPlace.CRATE_PROP, "crates", 0), "tub")
	assert_eq(_look("aillwee_gallery", DeepPlace.LEVER_PROP, "levers", 0), "wheel")
	assert_eq(_look("aillwee_gallery", DeepPlace.LEVER_PROP, "levers", 1), "crack", "a pocket found by lantern light")

func test_an_open_gate_is_the_rooms_own_floor() -> void:
	var d := _data()
	var z := _applied("blue_john_entry", d)
	var floor := z.tile_at(Vector2i(6, 5))
	assert_eq(z.tile_at(Vector2i(6, 4)), floor, "the gate stands on cave floor, not a fence on grass")
	DeepPlace.pull(d, z.id, DeepPlace.lever_at(z, Vector2i(10, 6)))
	DeepPlace.apply(d, z, {})
	assert_eq(z.tile_at(Vector2i(6, 4)), floor)
	assert_true(z.walkable(Vector2i(6, 4)))
	assert_true(ZoneBuilder.is_cave(z), "a show cave's entrance has rock walls, not plaster")
