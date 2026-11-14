extends TestCase
## Shropshire (3.0 Wider Isles): Shrewsbury, the Ironbridge Gorge and the Shropshire Hills hang off Chester's south
## side as a cul-de-sac, scaled from par 21, with their quests, plaques, trainers and regional creatures.

const ZONES := ["shrewsbury", "ironbridge_gorge", "shropshire_hills"]
const FLOOR := 21
const NEW_SPECIES := ["pigling", "ironsow", "squibbet", "darwing", "diaboulder"]

func _json(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func test_joins_chester_south_and_edges_mirror() -> void:
	var chester := ZoneData.load_id("chester")
	assert_eq(str(chester.edges.south.to), "shrewsbury")
	var shr := ZoneData.load_id("shrewsbury")
	assert_eq(str(shr.edges.north.to), "chester")
	assert_eq(str(shr.edges.east.to), "ironbridge_gorge")
	assert_eq(str(shr.edges.south.to), "shropshire_hills")
	assert_eq(str(ZoneData.load_id("ironbridge_gorge").edges.west.to), "shrewsbury")
	assert_eq(str(ZoneData.load_id("shropshire_hills").edges.north.to), "shrewsbury")
	# a cul-de-sac: the new routes lead nowhere else
	assert_eq(ZoneData.load_id("ironbridge_gorge").edges.size(), 2, "Shrewsbury and (wave 55) the Black Country")
	assert_eq(str(ZoneData.load_id("ironbridge_gorge").edges.east.to), "black_country")
	assert_eq(ZoneData.load_id("shropshire_hills").edges.size(), 1)

func test_zones_are_scaled_and_in_the_midlands() -> void:
	for zid in ZONES:
		var z := ZoneData.load_id(zid)
		assert_eq(z.scaled_floor, FLOOR, zid)
		assert_eq(z.region, "midlands", zid)
		for table in z.encounters.values():
			for e in table:
				assert_true(int(e.min) >= FLOOR and int(e.max) <= FLOOR + 3, "%s %s levels" % [zid, e.species])

func test_trainers_are_scaled_and_fair() -> void:
	var n := 0
	for path in DirAccess.get_files_at("res://data/trainers"):
		var id := str(path).get_basename()
		if not (id.begins_with("shr_") or id.begins_with("ib_") or id.begins_with("wen_") or id.begins_with("hills_")):
			continue
		var t: Dictionary = _json("res://data/trainers/" + path)
		n += 1
		assert_eq(int(t.get("scaled_floor", -1)), FLOOR, id)
		for m in t.party:
			assert_true(int(m.level) <= 25, "%s level %d" % [id, int(m.level)])
	assert_true(n >= 6, "trainers: %d" % n)
	assert_eq((_json("res://data/trainers/wen_champion.json") as Dictionary).party.size(), 6, "the local legend has a full party")

func test_plaques_unique_and_enough() -> void:
	var seen := {}
	for zid in ZONES:
		var count := 0
		for s in ZoneData.load_id(zid).signs:
			if s.has("plaque"):
				count += 1
				assert_true(str(s.plaque).begins_with("shropshire_"), str(s.plaque))
				assert_false(seen.has(s.plaque), "duplicate plaque " + str(s.plaque))
				seen[s.plaque] = true
				assert_true(str(s.get("title", "")) != "" and str(s.text).length() > 80, str(s.plaque))
				assert_false("—" in str(s.text), "no em-dashes")
		assert_true(count >= (8 if zid == "shrewsbury" else 3), "%s plaques: %d" % [zid, count])

func test_every_quest_flag_is_set_somewhere() -> void:
	var quests: Array = (_json("res://data/quests/shropshire.json") as Dictionary).quests
	assert_eq(quests.size(), 4)
	var text := ""
	for path in DirAccess.get_files_at("res://data/dialogue"):
		text += FileAccess.get_file_as_string("res://data/dialogue/" + path)
	for q in quests:
		var flags := [q.start_flag, q.done_flag]
		for s in q.steps:
			flags.append(s.flag)
		for f in flags:
			assert_true(str(f).begins_with("q_shropshire_"), str(f))
			assert_true(('"flag": "%s"' % f) in text, "%s is set by a script" % f)

func test_new_species_load_as_appendix_with_sprites() -> void:
	var dex := Dex.load_default()
	var order: Array = _json("res://data/dex_order.json")
	for sp in NEW_SPECIES:
		assert_true(dex.has(sp), sp)
		assert_true(bool(dex.get_species(sp).get("appendix", false)), sp + " is appendix")
		assert_true(sp in order, sp + " in dex order")
		for side in ["front", "back", "icon"]:
			assert_true(FileAccess.file_exists("res://art/sprites/creatures/%s_%s.png" % [sp, side]), "%s %s" % [sp, side])
	# placed: the basics are wild here, the Devil's Chair one is a special encounter
	var wild := {}
	for zid in ZONES:
		for table in ZoneData.load_id(zid).encounters.values():
			for e in table:
				wild[str(e.species)] = true
	assert_true(wild.has("pigling") and wild.has("squibbet"))
	assert_true("diaboulder" in FileAccess.get_file_as_string("res://data/dialogue/shropshire_hills.json"))

func test_regional_items_and_shop() -> void:
	var items := ItemDB.load_default()
	for id in ["shrewsbury_cake", "fidget_pie", "darwin_lens", "darby_ingot", "wenlock_medal", "stiperstones_quartz"]:
		assert_true(items.has(id), id)
	assert_true("shrewsbury_cake" in items.shops["shrewsbury_corner_shop"].stock)

func test_iron_bridge_deck_is_walkable_and_has_no_earth() -> void:
	var z := ZoneData.load_id("ironbridge_gorge")
	for x in range(40, 45):
		assert_true(z.walkable(Vector2i(x, 26)), "deck %d" % x)
	assert_true(bool(z.legend_extra.b.get("bridge", false)))
	var mesh := Landmarks.iron_bridge()
	assert_true(mesh.get_surface_count() > 0)
