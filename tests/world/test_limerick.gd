extends TestCase
## Wider Isles: the Shannon estuary, Limerick and Lough Gur, off Galway's south side.

const ZONES := ["shannon_estuary", "limerick", "lough_gur"]
const SPECIES := ["dolfeen", "estuarch", "versling", "rhymerick", "cuppeen", "sheridram", "silvershod"]

func test_edges_join_galway_as_a_cul_de_sac() -> void:
	var all := ZoneData.load_all()
	assert_eq(str(all["galway"].edges.south.to), "shannon_estuary")
	assert_eq(str(all["shannon_estuary"].edges.north.to), "galway")
	assert_eq(str(all["shannon_estuary"].edges.east.to), "limerick")
	assert_eq(str(all["limerick"].edges.west.to), "shannon_estuary")
	assert_eq(str(all["limerick"].edges.south.to), "lough_gur")
	var gur_edges: Array = all["lough_gur"].edges.keys().filter(func(k): return not all["lough_gur"].edges[k].has("lease"))
	assert_eq(gur_edges.size(), 1, "Lough Gur is the end of the line (a lease gap only opens when owned)")
	for zid in ZONES:
		for side in all[zid].edges:
			if all[zid].edges[side].has("lease"):
				continue
			var new_roads: Array = ["golden_vale", "clare_road"] if zid == "limerick" else []
			assert_true(str(all[zid].edges[side].to) in ZONES + ["galway"] + new_roads, "%s only joins its own zones, Galway and the wave 55 roads" % zid)
		assert_true(all[zid].validate(all).is_empty(), "%s validates: %s" % [zid, all[zid].validate(all)])

func test_zones_and_trainers_are_scaled_from_galway() -> void:
	var all := ZoneData.load_all()
	for zid in ZONES:
		assert_eq(all[zid].scaled_floor, 58, zid)
	var n := 0
	for tid in StoryData.trainer_ids():
		var t: Dictionary = StoryData.trainer(tid)
		if str(tid).begins_with("est_") or str(tid).begins_with("lim_") or str(tid).begins_with("lg_"):
			n += 1
			assert_eq(int(t.get("scaled_floor", -1)), 58, tid)
	assert_true(n >= 6, "at least six local trainers (%d)" % n)
	assert_eq(StoryData.trainer("lim_legend").party.size(), 6, "the local legend has a full party")

func test_zones_count_as_ireland() -> void:
	for zid in ZONES + ["limerick_kingjohn", "shannon_bunratty", "loughgur_centre"]:
		assert_eq(Standing.nation_for_zone(zid), "ireland", zid)

func test_town_has_sanctuary_shop_station_and_interiors() -> void:
	var z := ZoneData.load_id("limerick")
	assert_true(z.station != Vector2i(-1, -1))
	var to := []
	for w in z.warps:
		to.append(str(w.to))
	assert_true("limerick_sanctuary" in to and "limerick_shop" in to)
	assert_true(to.size() >= 8, "plenty of places to go in")
	assert_true(Travel.world_map().towns.has("limerick"))

func test_plaques_unique_and_enough() -> void:
	var seen := {}
	var per := {}
	for zid in ZONES:
		for s in ZoneData.load_id(zid).signs:
			if s.has("plaque"):
				assert_false(seen.has(s.plaque), "duplicate plaque " + str(s.plaque))
				seen[s.plaque] = true
				assert_true(str(s.get("title", "")) != "", "plaque has a title")
				assert_false("—" in str(s.text), "no em-dashes")
				per[zid] = int(per.get(zid, 0)) + 1
	assert_true(int(per.get("limerick", 0)) >= 8)
	assert_true(int(per.get("shannon_estuary", 0)) >= 3)
	assert_true(int(per.get("lough_gur", 0)) >= 3)

func _flags_set(cmds: Array, out: Dictionary) -> void:
	for c in cmds:
		if not c is Dictionary:
			continue
		if str(c.get("do", "")) == "set":
			out[str(c.flag)] = true
		if str(c.get("do", "")) == "legend":
			out[str(c.get("flag", ""))] = true
		for k in ["then", "else"]:
			if c.get(k) is Array:
				_flags_set(c[k], out)

func test_every_quest_flag_is_set_somewhere() -> void:
	var q: Dictionary = JsonUtil.read("res://data/quests/limerick.json")
	assert_true(q.quests.size() >= 4)
	var set_flags := {}
	for path in JsonUtil.list_json("res://data/dialogue"):
		var d = JsonUtil.read(path)
		if d is Dictionary:
			for sid in d:
				if d[sid] is Array:
					_flags_set(d[sid], set_flags)
	for quest in q.quests:
		var flags: Array = [quest.start_flag, quest.done_flag]
		for st in quest.steps:
			flags.append(st.flag)
			assert_true(ZoneData.load_id(str(st.zone)).width > 0, "step zone exists: " + str(st.zone))
		for f in flags:
			assert_true(str(f).begins_with("q_limerick_"), f)
			assert_true(set_flags.has(f), "quest flag never set: " + str(f))

func test_regional_items_and_shops() -> void:
	var f = JsonUtil.read("res://data/items/limerick.json")
	assert_true(f is Array and f.size() >= 3)
	var stock: Array = JsonUtil.read("res://data/shops/limerick_corner_shop.json").stock
	assert_true("limerick_ham" in stock and "irish_coffee" in stock)

func test_new_species_are_appendix_with_art_and_a_home() -> void:
	var order: Array = JsonUtil.read("res://data/dex_order.json")
	var placed := {}
	for zid in ZONES:
		for kind in ZoneData.load_id(zid).encounters:
			for e in ZoneData.load_id(zid).encounters[kind]:
				placed[str(e.species)] = true
	for sp in SPECIES:
		assert_true(sp in order, sp + " in dex order")
		for which in ["front", "back", "icon"]:
			assert_true(FileAccess.file_exists("res://art/sprites/creatures/%s_%s.png" % [sp, which]), sp + " " + which)
		if sp != "silvershod":
			assert_true(placed.has(sp), sp + " is found wild somewhere here")
	for path in ["res://data/creatures/dolfeen.json", "res://data/creatures/versling.json", "res://data/creatures/cuppeen.json", "res://data/creatures/silvershod.json"]:
		for s in JsonUtil.read(path).species:
			assert_true(bool(s.get("appendix", false)), str(s.id) + " is appendix")
