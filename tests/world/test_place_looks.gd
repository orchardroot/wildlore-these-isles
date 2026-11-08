extends TestCase
## w51: places that didn't look like what they are (the w50 world and critic leftovers).

func _types(id: String) -> Array:
	return ZoneData.load_id(id).props.map(func(p): return str(p.get("type", "")))

func test_kytelers_back_door_is_a_door() -> void:
	var z := ZoneData.load_id("kilkenny_kyteler")
	var spot := {}
	for e in z.examine:
		if str(e.text[0]).begins_with("The back door"):
			spot = e
	assert_false(spot.is_empty(), "the examine spot is still there")
	var door := z.props.filter(func(p): return p.type == "back_door" and int(p.x) == int(spot.x) and int(p.y) == int(spot.y))
	assert_eq(door.size(), 1, "a door where the line says")
	var mesh: ArrayMesh = ZoneBuilder._ctor("back_door", 1)
	assert_true(mesh.get_surface_count() > 0)

func test_a_show_cave_is_lit_by_braziers_not_street_lamps() -> void:
	assert_false("lamp_post" in _types("wookey_hole"))
	assert_true("brazier" in _types("wookey_hole"))

func test_no_street_bollards_on_the_grouse_moor() -> void:
	assert_false("bollard" in _types("pennine_grouse_moor"))

func test_the_slate_mine_is_not_a_parlour() -> void:
	var t := _types("lake_slatemine")
	for p in ["kitchen_dresser", "rug", "potted_plant", "plant_stand"]:
		assert_false(p in t, p)
	assert_true("slate_wagon" in t and "slate_stack" in t)
	var z := ZoneData.load_id("lake_slatemine")
	for y in z.height:
		for x in z.width:
			assert_true(z.tile_at(Vector2i(x, y)) != "floor_wood", "no wooden floorboards")
