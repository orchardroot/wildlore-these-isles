extends TestCase
## w51: York Minster was the red sandstone `cathedral` block (it read as a mill). It is its own pale limestone
## `minster` now, and a keeper's hall keeps its black and gold board whatever its style (a style with no wall
## for a name used to give it a lectern instead).

func _labels(node: Node) -> Array:
	var out := []
	for c in node.get_children():
		if c is Label3D:
			out.append(c)
		out.append_array(_labels(c))
	return out

func _minster(z: ZoneData) -> Dictionary:
	for pr in z.props:
		if str(pr.get("label", "")) == "York Minster":
			return pr
	return {}

func test_york_minster_is_its_own_limestone_style() -> void:
	var pr := _minster(ZoneData.load_id("york"))
	assert_eq(str(pr.get("style", "")), "minster")
	assert_true("minster" in Landmarks.SPECIAL, "drawn by Landmarks, not the generic house")
	var built: Array = Landmarks.building(16, 8, "minster", 8, 1)
	var mesh: ArrayMesh = built[0]
	assert_true(mesh.get_aabb().size.y > 8.0, "the central tower stands over the west towers (%.1f high)" % mesh.get_aabb().size.y)
	assert_true(mesh.surface_get_array_len(0) > 3000, "towers, buttresses, pinnacles")
	var windows: ArrayMesh = built[1]
	assert_true(windows.get_surface_count() > 0 and windows.surface_get_array_len(0) > 300, "great west window, lancets, rose")

func test_the_minster_keeps_its_gold_keeper_board_over_the_door() -> void:
	Meshes.materials()
	var z := ZoneData.load_id("york")
	var pr := _minster(z)
	var root := ZoneBuilder.build(z)
	var labels := _labels(root.get_node("Building_%d_%d" % [int(pr.x), int(pr.y)]))
	assert_eq(labels.size(), 1)
	var l: Label3D = labels[0]
	assert_eq(l.text, "YORK MINSTER")
	assert_eq(l.font, Signage.font("caps"), "the keeper board's carved capitals")
	assert_true(l.position.y > 1.5, "over the door, not on a lectern (y %.2f)" % l.position.y)
	assert_true(l.pixel_size * Signage.FS >= Signage.KEEPER_MIN_EM, "big enough to be grand")
	for r in SignSight.audit(z, root):
		if r.label == "York Minster":
			assert_eq(float(r.hidden), 0.0, "shows whole from the door")
	root.free()

func test_a_keeper_hall_with_no_wall_for_a_name_still_gets_its_board() -> void:
	# a round tower has no wall for a name (a lectern stands in front); as a keeper's hall it gets the gold board
	Meshes.materials()
	var rows := ["BBBBB", "BBBBB", "BBDBB", ".....", "....."]
	var z := ZoneData.from_dict({"id": "qa", "name": "QA", "kind": "town", "rows": rows, "edges": {}, "npcs": [], "encounters": {},
		"props": [{"type": "building", "style": "round_tower", "x": 0, "y": 0, "w": 5, "h": 3, "label": "Keeper Tower"}],
		"warps": [{"x": 2, "y": 2, "to": "york_minster_crypt", "tx": 1, "ty": 1}], "signs": [], "spawn": [0, 4], "weather": {}})
	assert_eq(Signage.front("round_tower", 5, 3, 2).mode, "stand")
	var root := ZoneBuilder.build(z)
	var l: Label3D = _labels(root.get_node("Building_0_0"))[0]
	assert_eq(l.font, Signage.font("caps"))
	assert_true(l.position.y > 1.3, "on brackets over the door (y %.2f)" % l.position.y)
	root.free()

func test_a_narrow_gatehouse_keeper_board_is_readable() -> void:
	# Glastonbury's St Michael's Tower (a castle 3 wide): the gatehouse between its drum towers left the name 0 high
	Meshes.materials()
	var z := ZoneData.load_id("glastonbury")
	var root := ZoneBuilder.build(z)
	for pr in z.props:
		if str(pr.get("label", "")) == "St Michael's Tower":
			var l: Label3D = _labels(root.get_node("Building_%d_%d" % [int(pr.x), int(pr.y)]))[0]
			assert_true(l.pixel_size * Signage.FS >= Signage.KEEPER_MIN_EM, "%.3f high" % (l.pixel_size * Signage.FS))
	root.free()
