extends TestCase

func _z(id: String) -> ZoneData:
	return ZoneData.load_id(id)

func _all() -> Dictionary:
	return {"testbed": _z("testbed"), "testbed_house": _z("testbed_house")}

func _base(rows: Array, extra := {}) -> Dictionary:
	var d := {"id": "t", "name": "T", "kind": "route", "rows": rows, "props": [], "warps": [], "edges": {}, "npcs": [], "encounters": {}, "signs": [], "spawn": [1, 1], "weather": {}}
	d.merge(extra, true)
	return d

func _has(errors: Array, needle: String) -> bool:
	for e in errors:
		if needle in e:
			return true
	return false

func test_parse_testbed() -> void:
	var z := _z("testbed")
	assert_eq(z.width, 24)
	assert_eq(z.height, 18)
	assert_eq(z.tile_at(Vector2i(0, 0)), "tree_oak")
	assert_eq(z.tile_at(Vector2i(5, 1)), "tall_grass")
	assert_eq(z.tile_at(Vector2i(14, 4)), "door")
	assert_eq(z.tile_at(Vector2i(-1, 0)), "")
	assert_eq(z.spawn, Vector2i(4, 6))
	assert_eq(z.height_at(Vector2i(14, 13)), 2)

func test_walkable_classes() -> void:
	var z := _z("testbed")
	assert_true(z.walkable(Vector2i(2, 1)), "grass")
	assert_true(z.walkable(Vector2i(5, 1)), "tall grass")
	assert_true(z.walkable(Vector2i(14, 10)), "shallow")
	assert_true(z.walkable(Vector2i(14, 4)), "door")
	assert_false(z.walkable(Vector2i(14, 8)), "water")
	assert_false(z.walkable(Vector2i(0, 0)), "tree")
	assert_false(z.walkable(Vector2i(4, 7)), "hedge")
	assert_false(z.walkable(Vector2i(12, 2)), "building")
	assert_false(z.walkable(Vector2i(30, 2)), "out of bounds")

func test_ledge_is_one_way_south() -> void:
	var z := _z("testbed")
	assert_true(z.walkable(Vector2i(5, 12), Vector2i(0, 1)))
	assert_false(z.walkable(Vector2i(5, 12), Vector2i(0, -1)))
	assert_false(z.walkable(Vector2i(5, 12), Vector2i(1, 0)))

func test_height_step_rule() -> void:
	var z := _z("testbed")
	# row 13 is height 2, row 14 col 12 is height 0 next to col 13 height 2
	assert_false(z.walkable(Vector2i(13, 14), Vector2i(1, 0)), "climbing two levels")
	assert_true(z.walkable(Vector2i(14, 14), Vector2i(1, 0)), "same level")

func test_warp_and_sign_lookup() -> void:
	var z := _z("testbed")
	assert_eq(z.warp_at(Vector2i(14, 4)).to, "testbed_house")
	assert_eq(z.warp_at(Vector2i(1, 1)), {})
	assert_true(z.sign_at(Vector2i(9, 6)).text.begins_with("TESTBED"))

func test_real_zones_validate() -> void:
	var all := _all()
	for id in all:
		assert_eq(all[id].validate(all), [], id)

func test_validate_ragged_rows() -> void:
	var z := ZoneData.from_dict(_base(["...", ".."]))
	assert_true(_has(z.validate({"t": z}), "ragged"))

func test_validate_spawn_with_extra_entries() -> void:
	# a sign pasted into the spawn array is silently dropped from the world; say so instead
	var z := ZoneData.from_dict(_base(["...", "...", "..."], {"spawn": [1, 1, {"x": 2, "y": 2, "text": "lost"}]}))
	assert_true(_has(z.validate({"t": z}), "spawn must be [x, y]"))

func test_validate_unknown_char() -> void:
	var z := ZoneData.from_dict(_base(["...", ".?.", "..."]))
	assert_true(_has(z.validate({"t": z}), "unknown tile char '?'"))

func test_validate_missing_warp_target() -> void:
	var z := ZoneData.from_dict(_base(["...", "...", "..."], {"warps": [{"x": 1, "y": 1, "to": "nowhere", "tx": 0, "ty": 0}]}))
	assert_true(_has(z.validate({"t": z}), "unknown zone 'nowhere'"))

func test_validate_unwalkable_arrival() -> void:
	var a := ZoneData.from_dict(_base(["...", "...", "..."], {"id": "a", "warps": [{"x": 1, "y": 1, "to": "b", "tx": 0, "ty": 0}]}))
	var b := ZoneData.from_dict(_base(["T..", "...", "..."], {"id": "b"}))
	assert_true(_has(a.validate({"a": a, "b": b}), "not walkable"))

func test_validate_unwalkable_spawn() -> void:
	var z := ZoneData.from_dict(_base(["TTT", "TTT", "TTT"]))
	assert_true(_has(z.validate({"t": z}), "spawn"))

func test_validate_building_footprint() -> void:
	var z := ZoneData.from_dict(_base(["BB..", "BB..", "...."], {"spawn": [3, 2]}))
	assert_true(_has(z.validate({"t": z}), "not covered by a building"))

func test_validate_edge_needs_a_way_back() -> void:
	var a := ZoneData.from_dict(_base(["...", "...", "..."], {"id": "a", "edges": {"north": {"to": "b", "offset": 0}}}))
	var b := ZoneData.from_dict(_base(["...", "...", "..."], {"id": "b"}))
	assert_true(_has(a.validate({"a": a, "b": b}), "no south edge back"))

func test_point_props_block_movement() -> void:
	var z := _z("testbed")
	assert_false(z.walkable(Vector2i(11, 4)), "lamp post")
	assert_false(z.walkable(Vector2i(18, 4)), "bench")

func test_signs_block_movement() -> void:
	var z := _z("testbed")
	assert_false(z.walkable(Vector2i(9, 6)), "sign post")

func test_new_tiles_parse() -> void:
	var z := ZoneData.from_dict(_base(["%o/_!$", "......"]))
	assert_eq(z.parse_errors, [])
	assert_eq([z.tile_at(Vector2i(0, 0)), z.tile_at(Vector2i(1, 0)), z.tile_at(Vector2i(2, 0)), z.tile_at(Vector2i(3, 0)), z.tile_at(Vector2i(4, 0)), z.tile_at(Vector2i(5, 0))],
		["bramble", "deep_water", "scree", "platform", "rail", "sea"])
	assert_false(z.walkable(Vector2i(0, 0)), "bramble blocks until cut")
	assert_false(z.walkable(Vector2i(1, 0)), "deep water needs Brook-wade")
	assert_true(z.walkable(Vector2i(1, 0), Vector2i.ZERO, ["brook_wade"]))
	assert_false(z.walkable(Vector2i(2, 0)), "scree needs Fell-scramble")
	assert_true(z.walkable(Vector2i(2, 0), Vector2i.ZERO, ["fell_scramble"]))
	assert_true(z.walkable(Vector2i(3, 0)), "platform")
	assert_false(z.walkable(Vector2i(4, 0)), "rail")
	assert_false(z.walkable(Vector2i(5, 0), Vector2i.ZERO, ["brook_wade"]), "the open sea is never wadeable")
	z.cut(Vector2i(0, 0))
	assert_true(z.walkable(Vector2i(0, 0)), "cut bramble is grass")

func test_ability_gates_rule() -> void:
	# exit east only through a bramble: fails unless the edge says it's gated by hedge_lay
	var rows := ["....%.", "TTTTTT"]
	var other := ZoneData.from_dict(_base(["...", "..."], {"id": "o", "edges": {"west": {"to": "a"}}}))
	var a := ZoneData.from_dict(_base(rows, {"id": "a", "spawn": [0, 0], "edges": {"east": {"to": "o"}}}))
	assert_true(_has(a.validate({"a": a, "o": other}), "can't reach the east edge"))
	var a2 := ZoneData.from_dict(_base(rows, {"id": "a", "spawn": [0, 0], "edges": {"east": {"to": "o", "gate": "hedge_lay"}}}))
	assert_false(_has(a2.validate({"a": a2, "o": other}), "can't reach"))
	# a warp walled off by deep water needs a brook_wade gate
	var b := ZoneData.from_dict(_base(["..o.", "TTTT"], {"id": "b", "spawn": [0, 0], "warps": [{"x": 3, "y": 0, "to": "b", "tx": 0, "ty": 0}]}))
	assert_true(_has(b.validate({"b": b}), "can't reach the warp at 3,0"))

func _cork_zone(extra_npc := {}, extra := {}) -> ZoneData:
	var t := {"id": "tr", "x": 2, "y": 1, "trainer": "tr1"}
	t.merge(extra_npc, true)
	var d := {"id": "c", "spawn": [0, 1], "npcs": [t], "warps": [{"x": 4, "y": 1, "to": "c", "tx": 0, "ty": 1}]}
	d.merge(extra, true)
	return ZoneData.from_dict(_base(["..%..", ".....", "..T.."], d))

func test_corks_ignore_abilities_the_gate_does_not_grant() -> void:
	# an ungated warp must stay reachable by walking, not by a bramble cut it never asked for
	var z := _cork_zone()
	assert_true(_has(z.validate({"c": z}), "walled off by trainers"), "bramble detour doesn't count for an ungated warp")
	var gated := _cork_zone({}, {"warps": [{"x": 4, "y": 1, "to": "c", "tx": 0, "ty": 1, "gate": "hedge_lay"}]})
	assert_false(_has(gated.validate({"c": gated}), "walled off by trainers"), "a hedge_lay gate allows the detour")

func test_trainer_hidden_by_its_own_flag_still_corks() -> void:
	var z := _cork_zone({"hide_if": "trainer_tr1"})
	assert_true(_has(z.validate({"c": z}), "walled off by trainers"))

func test_corks_apply_to_station_and_ferry() -> void:
	var rows := ["..T..", ".....", "..T.."]
	var npc := [{"id": "tr", "x": 2, "y": 1, "trainer": "tr1"}]
	var s := ZoneData.from_dict(_base(rows, {"npcs": npc, "spawn": [0, 1], "station": {"x": 4, "y": 1}}))
	assert_true(_has(s.validate({"t": s}), "boxed in"), "station")
	var f := ZoneData.from_dict(_base(rows, {"npcs": npc, "spawn": [0, 1], "ferry": {"x": 4, "y": 1, "route": "r"}}))
	assert_true(_has(f.validate({"t": f}), "boxed in"), "ferry")

func test_zone_extra_keys() -> void:
	var z := ZoneData.from_dict(_base(["...", "..."], {"stage": "coast", "town_id": "liverpool", "station": {"x": 1, "y": 1}, "ferry": {"x": 2, "y": 1, "route": "liverpool_douglas"}}))
	assert_eq(z.stage, "coast")
	assert_eq(z.town_id, "liverpool")
	assert_eq(z.station, Vector2i(1, 1))
	assert_eq(z.ferry.route, "liverpool_douglas")
	var bad := ZoneData.from_dict(_base(["...", "..T"], {"station": {"x": 2, "y": 1}}))
	assert_true(_has(bad.validate({"t": bad}), "station"))

func test_landmark_meshes_build() -> void:
	for style in Landmarks.SPECIAL:
		var m: Array = Meshes.building(8, 4, style, 2, 1)
		assert_true(m[0].get_surface_count() > 0, "body for " + style)
	for mesh in [Landmarks.standing_stone(), Landmarks.slate_heap(), Landmarks.scree_rubble(), Landmarks.bramble(),
			Landmarks.boat(), Landmarks.boat(1), Landmarks.canal_boat(), Landmarks.buoy(), Landmarks.statue(), Landmarks.harp(), Landmarks.lighthouse()]:
		assert_true(mesh.get_surface_count() > 0)

func test_round_tower_stands_tall() -> void:
	# an Irish round tower is a tall stone needle with a conical cap, not a cottage
	assert_true("round_tower" in Landmarks.SPECIAL)
	var tower: ArrayMesh = Meshes.building(2, 7, "round_tower", 0, 1)[0]
	var cottage: ArrayMesh = Meshes.building(2, 7, "stone", 0, 1)[0]
	assert_true(tower.get_aabb().size.y > 5.0, "tower height %s" % tower.get_aabb().size.y)
	assert_true(cottage.get_aabb().size.y < 3.5)

func test_passage_tomb_is_a_low_mound() -> void:
	# Newgrange: a grassy mound with a white quartz front, lower than a house and filling its plot
	assert_true("passage_tomb" in Landmarks.SPECIAL)
	var aabb: AABB = (Meshes.building(7, 3, "passage_tomb", 3, 1)[0] as ArrayMesh).get_aabb()
	assert_true(aabb.size.y > 1.2 and aabb.size.y < 2.4, "mound height %s" % aabb.size.y)
	assert_true(aabb.size.x > 6.0, "fills the plot")

func test_gallery_zone_builds() -> void:
	var root := ZoneBuilder.build(_z("mesh_gallery"))
	assert_true(root.get_child_count() > 10)
	assert_true(root.has_node("DeepWater"))
	root.free()

func test_edge_landing_must_be_walkable() -> void:
	var a := ZoneData.from_dict(_base(["...", "...", "..."], {"id": "a", "spawn": [1, 1], "edges": {"east": {"to": "b"}}}))
	var b := ZoneData.from_dict(_base(["T..", "...", "T.."], {"id": "b", "spawn": [1, 1], "edges": {"west": {"to": "a"}}}))
	assert_true(_has(a.validate({"a": a, "b": b}), "lands on 0,0 in 'b'"))

func test_station_must_reach_the_town() -> void:
	# platform at (1,1) boxed in by props: arriving by train would trap you
	var z := ZoneData.from_dict(_base(["....", "....", "...."], {"spawn": [3, 2], "station": {"x": 1, "y": 1},
		"props": [{"type": "bench", "x": 0, "y": 1}, {"type": "bench", "x": 2, "y": 1}, {"type": "bench", "x": 1, "y": 0}, {"type": "bench", "x": 1, "y": 2}]}))
	assert_true(_has(z.validate({"t": z}), "station"), "flags a boxed-in platform")

func test_validate_door_onto_railway() -> void:
	var rows := ["!!!!!", ".BDB.", "!!&!!", "....."]
	var z := ZoneData.from_dict(_base(rows, {"spawn": [0, 3], "warps": [{"x": 2, "y": 1, "to": "t", "tx": 0, "ty": 3}]}))
	assert_true(_has(z.validate({"t": z}), "opens straight onto the railway"))
	var ok := ZoneData.from_dict(_base([".....", ".BDB.", ".....", "....."], {"spawn": [0, 3], "warps": [{"x": 2, "y": 1, "to": "t", "tx": 0, "ty": 3}]}))
	assert_false(_has(ok.validate({"t": ok}), "opens straight onto the railway"))


func test_warp_arrival_on_a_door_is_an_error() -> void:
	# arriving on the door's own warp tile (after moving a building) leaves you standing in the doorway
	var town := ZoneData.from_dict(_base(["BBB", "BDB", "..."], {"id": "town", "spawn": [0, 2],
		"props": [{"type": "building", "style": "stone", "x": 0, "y": 0, "w": 3, "h": 2}],
		"warps": [{"x": 1, "y": 1, "to": "room", "tx": 1, "ty": 1}]}))
	var room := ZoneData.from_dict(_base(["...", "..."], {"id": "room", "kind": "interior", "spawn": [1, 1],
		"warps": [{"x": 1, "y": 0, "to": "town", "tx": 1, "ty": 1}]}))
	var errors := room.validate({"town": town, "room": room})
	assert_true(_has(errors, "lands on a warp"), "arrival on the door warp flagged: %s" % [errors])
	room.warps[0].ty = 2
	assert_false(_has(room.validate({"town": town, "room": room}), "lands on a warp"), "one step out is fine")

func test_roam_tiles_of_a_wanderer_stay_in_its_square() -> void:
	var rows := [".......", ".......", ".......", ".......", "......."]
	var z := ZoneData.from_dict(_base(rows, {"npcs": [{"id": "w", "x": 3, "y": 2, "move": "wander", "radius": 1}]}))
	var tiles := z.roam_tiles(z.npcs[0])
	assert_eq(tiles.size(), 9)
	assert_true(Vector2i(4, 3) in tiles and not Vector2i(5, 2) in tiles, "radius 1")
	var z2 := ZoneData.from_dict(_base(rows, {"npcs": [{"id": "w", "x": 3, "y": 2, "move": "wander"}]}))
	assert_eq(z2.roam_tiles(z2.npcs[0]).size(), 25, "default radius %d" % ZoneData.WANDER_RADIUS)
	var z3 := ZoneData.from_dict(_base(rows, {"npcs": [{"id": "p", "x": 1, "y": 1, "move": "pace", "path": ["right", "right"]}]}))
	assert_eq(z3.roam_tiles(z3.npcs[0]), [Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)])

func test_wanderer_must_not_mill_about_a_doorstep() -> void:
	# someone wandering in front of a door (or a cave mouth) stands in your way as you come out
	var rows := ["BBDBB", ".....", ".....", ".....", "....."]
	var props := [{"type": "building", "style": "red_brick", "x": 0, "y": 0, "w": 5, "h": 1}]
	var warps := [{"x": 2, "y": 0, "to": "testbed", "tx": 4, "ty": 6}]
	var bad := ZoneData.from_dict(_base(rows, {"props": props, "warps": warps, "spawn": [0, 4],
		"npcs": [{"id": "jogger", "x": 2, "y": 3, "move": "wander"}]}))
	assert_true(_has(bad.validate(_all()), "jogger"), "wanders on to the doorstep at 2,1")
	var ok := ZoneData.from_dict(_base(rows, {"props": props, "warps": warps, "spawn": [0, 4],
		"npcs": [{"id": "jogger", "x": 2, "y": 3, "move": "wander", "radius": 1}]}))
	assert_false(_has(ok.validate(_all()), "jogger"), "radius 1 keeps off it: %s" % [ok.validate(_all())])

func test_wanderer_must_not_stand_in_a_one_tile_gap() -> void:
	# a gap in a wall, a bridge, a lane between buildings: one wanderer there corks the way through
	var rows := ["......", "......", "WW.WWW", "......", "......"]
	var bad := ZoneData.from_dict(_base(rows, {"spawn": [0, 0], "npcs": [{"id": "dogwalker", "x": 2, "y": 3, "move": "wander", "radius": 1}]}))
	assert_true(_has(bad.validate({}), "dogwalker"), "can step into the gap at 2,2")
	var still := ZoneData.from_dict(_base(rows, {"spawn": [0, 0], "npcs": [{"id": "dogwalker", "x": 4, "y": 4, "move": "wander", "radius": 1}]}))
	assert_false(_has(still.validate({}), "dogwalker"), "clear of the gap")

func test_validate_road_off_an_edge_with_no_exit() -> void:
	var open := ZoneData.from_dict(_base(["..=..", "..=..", "....."], {"spawn": [0, 2], "kind": "town"}))
	assert_true(_has(open.validate({"t": open}), "runs off the north edge"))
	var closed := ZoneData.from_dict(_base(["..F..", "..=..", "....."], {"spawn": [0, 2], "kind": "town"}))
	assert_false(_has(closed.validate({"t": closed}), "runs off the north edge"))
