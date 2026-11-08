extends TestCase
## Visual QA regressions: labels that read against the wrong building, flags flying into walls and the like.

func _zone(rows: Array, props: Array) -> ZoneData:
	return ZoneData.from_dict({"id": "qa", "name": "QA", "kind": "town", "rows": rows, "props": props, "warps": [], "edges": {},
		"npcs": [], "encounters": {}, "signs": [], "spawn": [0, 0], "weather": {}})

func test_peat_stack_is_brown_not_slate() -> void:
	# Chat Moss cuts peat; its stacks read as slate heaps when they come out blue-grey
	var peat: PackedColorArray = Landmarks.slate_heap(3).surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	var slate: PackedColorArray = Landmarks.slate_heap(0).surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	assert_true(peat[0].r > peat[0].b, "peat is warm brown")
	assert_true(slate[0].b > slate[0].r, "slate stays blue-grey")

func test_short_grass_shows_low_tufts() -> void:
	# tall grass drawn bare ("none") left roaming creatures standing on what looks like a lawn; "short" draws
	# low tufts so you can see where they hide
	Meshes.materials()
	var d := {"id": "qa", "name": "QA", "kind": "route", "rows": ["kk", "kk"], "legend_extra": {"k": {"tile": "tall_grass", "prop": "short"}},
		"props": [], "warps": [], "edges": {}, "npcs": [], "encounters": {}, "signs": [], "spawn": [0, 0], "weather": {}}
	var root := ZoneBuilder.build(ZoneData.from_dict(d))
	var tufts := 0
	for c in root.get_children():
		if c is MultiMeshInstance3D and str(c.name).begins_with("Props_tall_grass_tuft"):
			tufts += (c as MultiMeshInstance3D).multimesh.instance_count
	assert_eq(tufts, 4)
	assert_true(ZoneBuilder.tuft_height("short") < 0.7, "low")
	assert_eq(ZoneBuilder.tuft_height(""), 1.0)
	root.free()

func test_london_landmarks_have_their_own_shapes() -> void:
	# Big Ben and the Shard were stood in by red and white lighthouses in the middle of the lawns
	for name in ["clock_tower", "shard"]:
		assert_true(name in ZoneBuilder.POINT_PROPS, name + " is a point prop")
		var mesh: ArrayMesh = ZoneBuilder._ctor(name, 0)
		assert_true(mesh.get_surface_count() > 0, name + " has geometry")
		assert_true(mesh.get_aabb().size.y > 3.5, name + " is tall")

func test_building_on_a_slope_stands_at_its_door() -> void:
	# placed at its north-west corner's height, a building on rising ground had its door buried in the hill
	Meshes.materials()
	var d := {"id": "qa", "name": "QA", "kind": "town", "rows": ["BBB", "BDB", "..."], "heights": ["000", "222", "222"],
		"props": [{"type": "building", "style": "stone", "x": 0, "y": 0, "w": 3, "h": 2, "label": "Hall"}], "warps": [], "edges": {},
		"npcs": [], "encounters": {}, "signs": [], "spawn": [0, 2], "weather": {}}
	var root := ZoneBuilder.build(ZoneData.from_dict(d))
	assert_true(absf((root.get_node("Building_0_0") as Node3D).position.y - 2 * ZoneBuilder.LEVEL) < 0.001, "base at the door's height")
	root.free()

func _pool(rows: Array, lamp: Vector2i) -> Transform3D:
	var z := _zone(rows, [{"type": "lamp_post", "x": lamp.x, "y": lamp.y}])
	return ZoneBuilder.lamp_pool(z, lamp)

func test_lamp_pool_in_the_open_is_full_size() -> void:
	var t := _pool([".....", ".....", ".....", ".....", "....."], Vector2i(2, 2))
	assert_true(absf(t.basis.get_scale().x - 3.4) < 0.01, "full pool")
	assert_true(absf(t.origin.x - 2.5) < 0.01 and absf(t.origin.z - 2.5) < 0.01, "centred on the lamp")

func test_lamp_pool_by_water_keeps_to_the_bank() -> void:
	# a full pool hangs out over the water (or off a bridge) as a floating disc of light
	var t := _pool([".....", ".....", ".....", "~~~~~", "~~~~~"], Vector2i(2, 2))
	assert_true(t.basis.get_scale().x < 3.0, "smaller pool")
	assert_true(t.origin.z < 2.5, "pushed back from the water")
	assert_true(t.origin.z + t.basis.get_scale().x * 0.5 <= 3.01, "stops at the water's edge")

func test_lamp_pool_with_water_both_sides_shrinks_in_place() -> void:
	var t := _pool(["~~~~~", "~~~~~", "~~.~~", "~~~~~", "~~~~~"], Vector2i(2, 2))
	assert_true(t.basis.get_scale().x <= 1.3, "just the lamp's own tile")
	assert_true(absf(t.origin.x - 2.5) < 0.01 and absf(t.origin.z - 2.5) < 0.01, "centred")

func test_custom_shaders_only_linearise_vertex_colour_where_the_solid_material_does() -> void:
	# the solid material's vertex_color_is_srgb converts only when the output is linear (never in the
	# Compatibility renderer, whose output is sRGB): foliage, trains and flags converting again came out darker
	for path in ["res://art/shaders/foliage.gdshader", "res://art/shaders/train.gdshader", "res://art/shaders/flutter.gdshader", "res://art/shaders/sign_lit.gdshader"]:
		var code := (load(path) as Shader).code
		assert_true(code.contains("OUTPUT_IS_SRGB"), path + " checks OUTPUT_IS_SRGB before converting")

func test_finnieston_crane_reaches_out_over_the_water() -> void:
	# drawn as Belfast's straddling gantry, Glasgow's crane hung its hook over the road behind the quay: a
	# cantilever crane stands on the quay and swings its jib, and hook, out over the river to the south
	assert_has(Landmarks.SPECIAL, "cantilever_crane")
	var body: ArrayMesh = Meshes.building(7, 3, "cantilever_crane", -1, 1)[0]
	var box := body.get_aabb()
	assert_true(box.end.z > 3 + 2.0, "jib runs out past the quay edge (to z %.2f)" % box.end.z)
	assert_true(box.position.z > -2.5, "and only a short tail back over the road (from z %.2f)" % box.position.z)
	assert_true(box.end.y > 6.0, "tall")
	# the hook block: the lowest geometry clear of the tower's legs hangs south of the footprint
	var verts: PackedVector3Array = body.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var hook_z := -99.0
	var low := 99.0
	for v in verts:
		if v.z > 3.0 and v.y < low:
			low = v.y
			hook_z = v.z
	assert_true(low < 2.0 and hook_z > 4.0, "hook hangs low over the water (y %.2f at z %.2f)" % [low, hook_z])

func _colours(m: ArrayMesh) -> PackedColorArray:
	return m.surface_get_arrays(0)[Mesh.ARRAY_COLOR]

func _has_colour(cols: PackedColorArray, c: Color) -> bool:
	for k in cols:
		if k.is_equal_approx(c):
			return true
	return false

func test_castle_pennant_is_a_swallowtail_in_its_nations_colours() -> void:
	# castle flags were plain red rectangles: a pennant tapers and forks, an English one carries St George's cross
	var eng := Landmarks.pennant("yorkshire")
	assert_true(_has_colour(_colours(eng), Landmarks.PENNANT_WHITE), "English: white field")
	assert_true(_has_colour(_colours(eng), Landmarks.PENNANT_RED), "with a red cross")
	var sco := _colours(Landmarks.pennant("scotland"))
	assert_false(_has_colour(sco, Landmarks.PENNANT_RED), "Scotland flies no St George's cross")
	assert_true(_has_colour(sco, Landmarks.PENNANT_BLUE), "but saltire blue")
	assert_false(_has_colour(_colours(Landmarks.pennant("north_wales")), Landmarks.PENNANT_BLUE), "Wales is not blue")
	# the fork: at mid-height the cloth stops short of the tips
	var verts: PackedVector3Array = eng.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var tip := 0.0
	var mid_y := 0.0
	var lo := 99.0
	var hi := -99.0
	for v in verts:
		lo = minf(lo, v.y)
		hi = maxf(hi, v.y)
	mid_y = (lo + hi) * 0.5
	var mid_reach := 0.0
	for v in verts:
		tip = maxf(tip, v.x)
		if absf(v.y - mid_y) < 0.02:
			mid_reach = maxf(mid_reach, v.x)
	assert_true(mid_reach < tip - 0.15, "swallowtail notch (mid %.2f, tips %.2f)" % [mid_reach, tip])

func test_castles_fly_their_regions_pennant() -> void:
	var york: ArrayMesh = Meshes.building(6, 4, "castle", 2, 1, "yorkshire")[0]
	assert_true(_has_colour(_colours(york), Landmarks.PENNANT_WHITE), "York's castle flies St George")
	var scot: ArrayMesh = Meshes.building(6, 4, "castle", 2, 1, "scotland")[0]
	assert_true(_has_colour(_colours(scot), Landmarks.PENNANT_BLUE), "Edinburgh's flies saltire blue")

func test_titanic_belfast_has_four_silver_prows() -> void:
	# it was a plain stone block with a bare roof: the real one is four ship's prows clad in silver shards
	assert_has(Landmarks.SPECIAL, "titanic")
	var body: ArrayMesh = Meshes.building(12, 7, "titanic", 6, 1)[0]
	var box := body.get_aabb()
	assert_true(box.size.y > 5.0, "tall (%.2f)" % box.size.y)
	assert_true(box.size.x <= 12.6 and box.size.z <= 7.6, "keeps (near enough) to its plot")
	var verts: PackedVector3Array = body.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var cols := _colours(body)
	var shades := {}
	var silver := 0
	for c in cols:
		shades[c.to_html(false)] = true
		if absf(c.r - c.b) < 0.08 and c.r > 0.6:
			silver += 1
	assert_true(shades.size() >= 10, "shard cladding in many shades (%d)" % shades.size())
	assert_true(silver > cols.size() / 2, "mostly silver")
	# the high points are the four prow tips, out toward the corners, not a flat roof
	var tips := {}
	for v in verts:
		if v.y > box.end.y - 0.3:
			tips[Vector2i(signi(int(roundf(v.x - 6.0))), signi(int(roundf(v.z - 3.5))))] = true
	for k in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
		assert_true(tips.has(k), "a prow rises at corner %s" % k)

func test_cascade_tumbles_one_level_from_the_upstream_edge() -> void:
	# a hill stream stepping down a level showed a bare earth step between two flat strips of water
	assert_has(ZoneBuilder.POINT_PROPS, "cascade")
	var box := (ZoneBuilder._ctor("cascade", 0) as ArrayMesh).get_aabb()
	assert_true(box.end.y >= ZoneBuilder.LEVEL + 0.04, "reaches the upper pool (%.2f)" % box.end.y)
	assert_true(box.end.x >= 0.5, "falls from the tile's upstream (+x) edge")
	var z := _zone(["~~", "~~"], [{"type": "cascade", "x": 0, "y": 0}])
	assert_near(ZoneBuilder.prop_y(z, "cascade", Vector2i(0, 0)), ZoneBuilder.water_y(z, Vector2i(0, 0)), 0.001, "stands on the lower pool's surface")
	assert_near(ZoneBuilder.prop_y(z, "rock", Vector2i(0, 0)), ZoneBuilder.ground_y(z, Vector2i(0, 0)), 0.001, "a rock sits on the bed")

func test_countryside_props_build() -> void:
	# the fells and the Dales were bare: sheep, field gates and limestone pavement to dress them
	for name in ["sheep", "field_gate", "limestone_pavement"]:
		assert_true(name in ZoneBuilder.POINT_PROPS, name + " is a point prop")
		for v in 3:
			assert_true((ZoneBuilder._ctor(name, v) as ArrayMesh).get_surface_count() > 0, "%s:%d has geometry" % [name, v])
	var sheep := (ZoneBuilder._ctor("sheep", 0) as ArrayMesh).get_aabb()
	assert_true(sheep.size.y < 0.6 and sheep.size.x < 0.9, "a sheep is small (%s)" % sheep.size)
	var pave := (ZoneBuilder._ctor("limestone_pavement", 0) as ArrayMesh).get_aabb()
	assert_true(pave.size.y < 0.12, "pavement lies flat (%.2f)" % pave.size.y)
	assert_true(pave.size.x > 0.8 and pave.size.z > 0.8, "and fills its tile")
	var gate := (ZoneBuilder._ctor("field_gate", 0) as ArrayMesh).get_aabb()
	assert_true(gate.end.z > 0.2, "the open gate stands in front of the wall's face")

func test_pavement_legend_lays_slabs_on_every_such_tile() -> void:
	Meshes.materials()
	var d := {"id": "qa", "name": "QA", "kind": "route", "rows": ["ll", "l."], "legend_extra": {"l": {"tile": "path", "prop": "pavement"}},
		"props": [], "warps": [], "edges": {}, "npcs": [], "encounters": {}, "signs": [], "spawn": [1, 1], "weather": {}}
	var z := ZoneData.from_dict(d)
	assert_true(z.walkable(Vector2i(0, 0)), "you walk on the pavement")
	var root := ZoneBuilder.build(z)
	var slabs := 0
	for c in root.get_children():
		if c is MultiMeshInstance3D and str(c.name).begins_with("Props_limestone_pavement"):
			slabs += (c as MultiMeshInstance3D).multimesh.instance_count
	assert_eq(slabs, 3)
	root.free()

func test_field_barn_is_a_small_stone_barn() -> void:
	assert_has(Landmarks.SPECIAL, "field_barn")
	var box := (Meshes.building(3, 2, "field_barn", -1, 1)[0] as ArrayMesh).get_aabb()
	assert_true(box.size.y > 1.4 and box.size.y < 2.6, "a storey and a roof (%.2f)" % box.size.y)

func test_mills_look_like_their_kind() -> void:
	# w52: Llynnon (a windmill), Laxey (a waterwheel), Starcross (a pumping house) and the Cornish engine houses were
	# all Lancashire cotton mills
	var want := {"anglesey": ["Llynnon Mill", "tower_mill"], "douglas": ["Laxey Wheel (not to scale)", "water_wheel"],
		"exe_estuary": ["Starcross Pumping House", "pumping_house"], "penzance": ["Engine House", "cornish_engine"],
		"shropshire_hills": ["Snailbeach Engine House", "cornish_engine"]}
	for zid in want:
		var found := ""
		for pr in ZoneData.load_id(zid).props:
			if str(pr.get("label", "")) == want[zid][0]:
				found = str(pr.style)
		assert_eq(found, want[zid][1], zid)
	for style in WorksStyles.STYLES:
		assert_has(Landmarks.SPECIAL, style)
	var mill := (Meshes.building(4, 4, "tower_mill", 1, 1)[0] as ArrayMesh).get_aabb()
	assert_true(mill.size.y > 5.0, "sails above a tall tower (%.2f)" % mill.size.y)
	var shed := (Meshes.building(3, 2, "allotment_shed", 1, 1)[0] as ArrayMesh).get_aabb()
	assert_true(shed.size.y < 2.0, "a shed is low (%.2f)" % shed.size.y)
