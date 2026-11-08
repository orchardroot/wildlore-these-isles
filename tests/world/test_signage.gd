extends TestCase
## Building names as signs: which sign a building gets, how its name fits the board, and where it goes.

func _zone(rows: Array, props: Array, warps := [], signs := []) -> ZoneData:
	return ZoneData.from_dict({"id": "qa", "name": "QA", "kind": "town", "rows": rows, "props": props, "warps": warps,
		"edges": {}, "npcs": [], "encounters": {}, "signs": signs, "spawn": [0, 0], "weather": {}})

func _labels(node: Node) -> Array:
	var out := []
	for c in node.get_children():
		if c is Label3D:
			out.append(c)
		out.append_array(_labels(c))
	return out

# --- which sign -----------------------------------------------------------------

func test_sanctuary_and_corner_shop_carry_their_own_brand() -> void:
	assert_eq(Signage.sign_type("Sanctuary", "sanctuary"), "sanctuary")
	assert_eq(Signage.sign_type("Sanctuary", "stone", "", "york_sanctuary"), "sanctuary")
	assert_eq(Signage.sign_type("Corner Shop", "shop"), "chain")
	assert_eq(Signage.sign_type("Corner Shop", "red_brick", "", "macc_shop"), "chain")

func test_pubs_get_a_pub_sign() -> void:
	for name in ["The Garavogue Arms", "Kyteler's Inn", "Waterloo Tavern", "The Quays Bar", "The Cobbler's Tap",
			"Ye Olde Trip to Jerusalem", "Tigh Neachtain", "The Crown Posada", "The Last Drop", "Admiral Benbow"]:
		assert_eq(Signage.sign_type(name, "tudor", "cafe"), "pub", name)
	# the taproom at Knott Mill runs the Manchester pub quiz
	assert_eq(Signage.sign_type("Knott Mill", "mill", "mill", "manchester_knottmill"), "pub")

func test_bars_that_are_not_pubs() -> void:
	assert_eq(Signage.sign_type("Micklegate Bar", "castle", "castle"), "heritage", "York's bars are city gates")
	assert_eq(Signage.sign_type("Sandwich Bar", "red_brick", "cafe"), "fascia")
	assert_eq(Signage.sign_type("Temple Bar Books", "terrace", "library"), "fascia")

func test_shops_and_cafes_get_a_fascia() -> void:
	for name in ["Bettys Tea Rooms", "The Chippy", "Fish and Chips", "Grange Chippy", "Bev's Bikes", "Strand Bakery",
			"Pasty Co.", "Kyle Station Cafe", "Llanfair PG Station Sign Shop", "Páirc Café", "Caffi Padarn", "Salthill Gifts"]:
		assert_eq(Signage.sign_type(name, "red_brick"), "fascia", name)

func test_stations() -> void:
	assert_eq(Signage.sign_type("Piccadilly Station", "station"), "station")
	assert_eq(Signage.sign_type("Goathland Halt", "station"), "station")
	assert_eq(Signage.sign_type("Signal Box", "slate_cottage", "workshop"), "station")
	assert_eq(Signage.sign_type("Cliff Railway", "stone", "museum"), "station")
	assert_eq(Signage.sign_type("Field Station", "white_render"), "heritage", "a research station, not a railway one")
	assert_eq(Signage.sign_type("Pumping Station", "mill", "mill"), "heritage")
	assert_eq(Signage.sign_type("Station Terrace", "terrace", "home"), "street")

func test_landmarks_get_heritage_signs() -> void:
	assert_eq(Signage.sign_type("Paradise Mill", "red_brick", "mill"), "heritage")
	assert_eq(Signage.sign_type("John Rylands Library", "stone", "library"), "heritage")
	assert_eq(Signage.sign_type("St Michael's", "stone", "church"), "heritage")
	assert_eq(Signage.sign_type("Edinburgh Castle", "castle", "castle"), "heritage")
	assert_eq(Signage.sign_type("Pontcysyllte Aqueduct", "aqueduct"), "heritage")

func test_visitor_attractions_get_a_brown_sign() -> void:
	assert_eq(Signage.sign_type("Visitor Centre", "white_render", "hall"), "tourist")
	assert_eq(Signage.sign_type("Cliffs of Moher Visitor Centre", "stone", "museum"), "tourist")
	assert_eq(Signage.sign_type("Monster Exhibition", "white_render", "museum"), "tourist")

func test_keeper_halls_are_grand() -> void:
	assert_eq(Signage.sign_type("Dublin Hall", "stone", "", "dublin_hall"), "keeper")
	assert_eq(Signage.sign_type("York Minster", "cathedral", "", "york_minster_crypt"), "keeper")

func test_keeper_hall_list_matches_the_keeper_music() -> void:
	# a keeper's hall is any interior that plays the keeper battle music; the sign list must not drift from it
	var found := []
	for f in DirAccess.get_files_at("res://data/zones"):
		if not f.ends_with(".json"):
			continue
		var d = JSON.parse_string(FileAccess.get_file_as_string("res://data/zones/" + f))
		if d is Dictionary and str(d.get("music", "")) == "battle_keeper":
			found.append(str(d.id))
	found.sort()
	var listed: Array = Signage.KEEPER_HALLS.duplicate()
	listed.sort()
	assert_eq(listed, found)

func test_streets_get_a_street_plate() -> void:
	for name in ["Grey Street", "Micklegate", "Bishopthorpe Road", "Marine Terrace", "Mary King's Close", "Gateshead Terraces"]:
		assert_eq(Signage.sign_type(name, "terrace", "home"), "street", name)

func test_homes_get_nothing_but_named_houses_a_little_plate() -> void:
	for name in ["Home", "Test House", "Field Barn", "Barn", "Farmhouse", "Bothy", "Laithe", "Cottage"]:
		assert_eq(Signage.sign_type(name, "slate_cottage", "cottage"), "", name)
	assert_eq(Signage.sign_type("", "red_brick"), "")
	for name in ["Cartref", "Budle Farm", "Lochside Bothy", "Riverside Cottage"]:
		assert_eq(Signage.sign_type(name, "slate_cottage", "cottage"), "house", name)

func test_every_named_building_in_the_game_gets_a_sign_type() -> void:
	var types := {}
	for f in DirAccess.get_files_at("res://data/zones"):
		if not f.ends_with(".json"):
			continue
		var z := ZoneData.load_id(f.get_basename())
		if z.kind == "interior":
			continue
		for pr in z.props:
			if pr.get("type") != "building" or not pr.has("label") or not pr.get("show_label", true):
				continue
			var t := Signage.type_of(z, pr)
			assert_true(t in Signage.TYPES, "%s in %s: %s" % [pr.label, z.id, t])
			types[t] = types.get(t, 0) + 1
			if str(pr.label).contains(" Inn") or str(pr.label).ends_with(" Arms"):
				assert_eq(t, "pub", str(pr.label))
	for t in ["fascia", "pub", "sanctuary", "chain", "station", "heritage", "keeper", "street"]:
		assert_true(types.get(t, 0) > 0, "some buildings get a %s sign" % t)

func test_fascia_colour_is_deterministic_and_varied() -> void:
	assert_eq(Signage.palette("The Chippy", "aberystwyth"), Signage.palette("The Chippy", "aberystwyth"))
	var seen := {}
	for name in ["The Chippy", "Bakery", "Bookshop", "Tea Rooms", "Corner Cafe", "Bev's Bikes", "Pasty Shop", "Gifts"]:
		seen[Signage.palette(name, "x").board.to_html()] = true
	assert_true(seen.size() >= 3, "several heritage colours (%d)" % seen.size())

func test_place_words() -> void:
	assert_eq(Signage.place_word("Paradise Mill", "red_brick", "museum", "macc_paradise"), "Museum")
	assert_eq(Signage.place_word("Silk Museum", "red_brick", "museum", "macc_silkmuseum"), "", "the name already says it")
	assert_eq(Signage.place_word("Sanctuary", "sanctuary"), "Rest and healing")
	assert_eq(Signage.place_word("Corner Shop", "shop"), "Supplies")
	assert_eq(Signage.place_word("The Garavogue Arms", "tudor", "cafe"), "Pub")
	assert_eq(Signage.place_word("Dublin Hall", "stone", "", "dublin_hall"), "Keeper's Hall")
	assert_eq(Signage.place_word("St Michael's", "stone", "church"), "Church")
	assert_eq(Signage.place_word("Piccadilly Station", "station"), "")
	assert_eq(Signage.place_word("Goathland Halt", "station"), "Railway station")

# --- fitting the name to its board -------------------------------------------------

func test_short_name_fits_on_one_line_at_full_size() -> void:
	var f := Signage.fit("Bakery", Signage.font("serif"), 0.25, 3.0)
	assert_eq(f.text, "Bakery")
	assert_eq(int(f.lines), 1)
	assert_near(float(f.em), 0.25, 0.0001)
	assert_true(float(f.width) < 3.0)

func test_long_name_shrinks_a_little_then_wraps_never_overflowing() -> void:
	var font := Signage.font("serif")
	var one := Signage.fit("Pulteney Bridge Tea Rooms", font, 0.25, 3.4)
	assert_true(float(one.width) <= 3.4 + 0.001, "fits (%.2f)" % float(one.width))
	var two := Signage.fit("BALTIC Centre for Contemporary Art", font, 0.25, 2.6)
	assert_eq(int(two.lines), 2)
	assert_true(str(two.text).contains("\n"), "broken on a space")
	assert_true(float(two.width) <= 2.6 + 0.001, "both lines fit (%.2f)" % float(two.width))
	assert_true(float(two.em) >= 0.25 * 0.55, "still readable (%.3f)" % float(two.em))
	# one long word: shrinks to fit rather than overflow
	var word := Signage.fit("Llanfairpwllgwyngyll", font, 0.25, 1.0)
	assert_true(float(word.width) <= 1.0 + 0.001, "a single long word shrinks (%.2f)" % float(word.width))

func test_two_lines_never_taller_than_the_board_allows() -> void:
	var f := Signage.fit("Captain Cook Memorial Museum", Signage.font("serif"), 0.25, 1.8, 0.45)
	assert_true(float(f.height) <= 0.45 + 0.001, "height %.3f" % float(f.height))
	assert_true(float(f.width) <= 1.8 + 0.001)

# --- in the world -------------------------------------------------------------------

func _shop_zone(extra_props := [], signs := []) -> ZoneData:
	var rows := ["BBBBBB..", "BBBBBB..", "BBBBBB..", "BBDBBB..", "........"]
	var props := [{"type": "building", "style": "red_brick", "label": "Bev's Bikes", "x": 0, "y": 0, "w": 6, "h": 4}]
	props.append_array(extra_props)
	return _zone(rows, props, [], signs)

func test_sign_text_is_depth_tested_lit_and_unoutlined() -> void:
	Meshes.materials()
	var root := ZoneBuilder.build(_shop_zone())
	var labels := _labels(root.get_node("Building_0_0"))
	assert_true(labels.size() >= 1, "the name is on the building")
	for l: Label3D in labels:
		assert_false(l.no_depth_test, "hidden behind other buildings like a real sign")
		assert_eq(l.outline_size, 0)
		assert_true(l.shaded, "dims at night")
		assert_eq(l.font, Signage.font("serif"))
	assert_true(root.has_node("Signs"), "boards are one merged mesh")
	root.free()

func test_fascia_sits_on_the_front_wall_between_the_floors() -> void:
	Meshes.materials()
	var root := ZoneBuilder.build(_shop_zone())
	var l: Label3D = _labels(root.get_node("Building_0_0"))[0]
	assert_true(l.position.z > 3.99 and l.position.z < 4.3, "on the door-side wall (z %.2f)" % l.position.z)
	assert_true(l.position.y > 0.97 and l.position.y < 1.56, "above the ground-floor windows, below the first (%.2f)" % l.position.y)
	assert_true(l.position.x > 0.0 and l.position.x < 6.0)
	root.free()

func test_aqueduct_names_itself_on_the_trough() -> void:
	Meshes.materials()
	var z := _zone(["BBBBBB", "BBBBBB", "......"], [{"type": "building", "style": "aqueduct", "x": 0, "y": 0, "w": 6, "h": 2, "label": "Viaduct"}])
	var root := ZoneBuilder.build(z)
	var l: Label3D = _labels(root.get_node("Building_0_0"))[0]
	assert_true(l.position.y > 3.0, "up on the trough, not at %.2f" % l.position.y)
	root.free()

func test_pub_hangs_its_sign_clear_of_bunting_and_plaque() -> void:
	Meshes.materials()
	var rows := ["BBBBBB..", "BBBBBB..", "BBBBBB..", "BBBDBB..", "........"]
	var pub := {"type": "building", "style": "white_render", "label": "The Ryan Arms", "x": 0, "y": 0, "w": 6, "h": 4}
	var plaque := {"x": 2, "y": 3, "kind": "plaque", "text": "BLUE PLAQUE", "dx": 0.475}
	var z := _zone(rows, [pub, {"type": "bunting", "x": 0, "y": 4, "variant": 5, "walk": true}], [], [plaque])
	var hang := Signage.hanging_spot(z, pub, 3)
	assert_false(hang.is_empty(), "a pub gets a hanging sign")
	assert_true(absf(float(hang.x) - 3.0) > 0.2, "not over the plaque beside the door (x %.2f)" % float(hang.x))
	assert_true(float(hang.bottom) > 1.72, "hangs above the bunting (bottom %.2f)" % float(hang.bottom))
	var root := ZoneBuilder.build(z)
	assert_true(_labels(root.get_node("Building_0_0")).size() >= 1, "and a fascia with its name")
	root.free()

func test_unnamed_and_homes_have_no_sign() -> void:
	Meshes.materials()
	var rows := ["BBBB", "BBDB", "...."]
	for pr in [{"type": "building", "style": "red_brick", "x": 0, "y": 0, "w": 4, "h": 2, "show_label": false},
			{"type": "building", "style": "red_brick", "x": 0, "y": 0, "w": 4, "h": 2, "label": "Home"}]:
		var root := ZoneBuilder.build(_zone(rows, [pr]))
		assert_eq(_labels(root).size(), 0)
		root.free()

func test_station_board_stands_on_the_canopy_with_a_totem() -> void:
	Meshes.materials()
	var rows := ["BBBBBBBB", "BBBDBBBB", "........", "........"]
	var z := _zone(rows, [{"type": "building", "style": "station", "x": 0, "y": 0, "w": 8, "h": 2, "label": "Keswick Station"}])
	var root := ZoneBuilder.build(z)
	var labels := _labels(root.get_node("Building_0_0"))
	assert_true(labels.size() >= 2, "a name board and a totem")
	for l: Label3D in labels:
		assert_eq(l.font, Signage.font("sans"))
	root.free()

# --- where you can read it (SignSight) ------------------------------------------------------

func test_a_taller_neighbour_in_front_pushes_the_name_along_the_front() -> void:
	# Cardiff Bay's Pierhead: a long front with its door at the west end, and a block standing two rows forward
	# across its east end, off to the side of the door (so it stays solid while you stand there)
	Meshes.materials()
	var rows := []
	for y in 10:
		rows.append("..........")
	rows[0] = "BBBBBBBBBB"
	rows[1] = "BBBBBBBBBB"
	rows[2] = "BBBBBBBBBB"
	rows[3] = "BDBBBBBBBB"
	var shop := {"type": "building", "style": "red_brick", "label": "Pierhead Building", "kind": "museum", "x": 0, "y": 0, "w": 10, "h": 4}
	var block := {"type": "building", "style": "mill", "x": 3, "y": 6, "w": 7, "h": 3}
	var z := _zone(rows, [shop, block])
	var root := ZoneBuilder.build(z)
	var l: Label3D = _labels(root.get_node("Building_0_0"))[0]
	var half := float(l.get_meta("size").x) * 0.5
	assert_true(l.position.x + half < 3.4, "the name keeps west of the block (ends at %.2f)" % (l.position.x + half))
	for r in SignSight.audit(z, root):
		assert_eq(float(r.hidden), 0.0, "%s: all of it shows from the door" % r.label)
	root.free()

func test_a_jettied_front_carries_its_name_on_its_face_not_inside_it() -> void:
	Meshes.materials()
	var rows := ["BBBBBBBB", "BBBBBBBB", "BBBBBBBB", "BBBDBBBB", "........", "........"]
	var z := _zone(rows, [{"type": "building", "style": "york_timber", "label": "Bettys Tea Rooms", "x": 0, "y": 0, "w": 8, "h": 4}])
	var root := ZoneBuilder.build(z)
	var l: Label3D = _labels(root.get_node("Building_0_0"))[0]
	assert_true(l.position.z > 4.12, "in front of the oversailing upper floor (z %.2f)" % l.position.z)
	assert_eq(float(SignSight.audit(z, root)[0].hidden), 0.0)
	root.free()

func test_town_signs_read_whole_from_their_doors() -> void:
	# the towns players see most, and the owner's Cardiff Bay: every name fits its building and shows whole
	# from its door with the game's camera (tools/dev/sign_audit.gd runs this over every zone)
	Meshes.materials()
	for id in ["cardiff", "liverpool", "london", "edinburgh", "york", "belfast", "dublin", "macclesfield", "llanberis", "whitby"]:
		var z := ZoneData.load_id(id)
		if z == null:
			continue
		var root := ZoneBuilder.build(z)
		for r in SignSight.audit(z, root):
			assert_eq(float(r.hidden), 0.0, "%s/%s hidden from its door" % [id, r.label])
			assert_false(r.wide, "%s/%s wider than its building" % [id, r.label])
			assert_eq(float(r.off), 0.0, "%s/%s off the screen" % [id, r.label])
			assert_false(r.moved, "%s/%s pushed off its wall" % [id, r.label])
		root.free()

func test_lamp_posts_and_trees_count_as_in_the_way() -> void:
	# London's Vane Tower lost its O to a lamp post: props standing in front of a building are in the sight check
	Meshes.materials()
	var z := ZoneData.load_id("london")
	var root := ZoneBuilder.build(z)
	var bodies := []
	for pr in z.props:
		if pr.get("type") == "building" and root.get_node_or_null("Building_%d_%d" % [int(pr.x), int(pr.y)]):
			bodies.append({"pr": pr, "body": root.get_node("Building_%d_%d" % [int(pr.x), int(pr.y)])})
	var sight := SignSight.make(z, bodies, root)
	var lamp := {}
	for it in sight._items:
		if it.has("prop") and (it.xf as Transform3D).origin.is_equal_approx(Vector3(39.5, (it.xf as Transform3D).origin.y, 21.5)):
			lamp = it
	assert_false(lamp.is_empty(), "the lamp post in front of the Vane Tower is in the check")
	var eye := sight.eye(Vector2i(37, 20), ZoneBuilder.ground_y(z, Vector2i(37, 20)))
	var at := Vector3(39.5, 1.0, 21.5)  # right behind the lamp, looking at the camera
	sight.focus(AABB(at, Vector3.ZERO), eye)
	assert_true(sight.blocked(at - (eye - at).normalized() * 0.5, eye), "a sight line through a lamp post is blocked")
	root.free()
