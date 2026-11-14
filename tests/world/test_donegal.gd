extends TestCase
## Donegal (3.0 Wider Isles): Glenveagh and Errigal west of Derry, Gaoth Dobhair, Tory Island by boat and Donegal
## Town. A cul-de-sac off Derry, every zone and trainer scaled from Derry's band, quests wired to real flags.

const OUTDOOR := ["glenveagh", "gweedore", "tory_island", "donegal_town"]
const FLOOR := 66

func _zones() -> Dictionary:
	return ZoneData.load_all()

func test_joins_derry_once_on_its_west_side() -> void:
	var all := _zones()
	assert_eq(all.derry.edges.west.to, "glenveagh")
	assert_eq(all.glenveagh.edges.east.to, "derry")
	# a cul-de-sac: nothing else in the region leads back into an existing zone
	for zid in OUTDOOR:
		for side in all[zid].edges:
			var to := str(all[zid].edges[side].to)
			assert_true(to in OUTDOOR or (zid == "glenveagh" and to == "derry"), "%s %s edge stays in Donegal" % [zid, side])

func test_zones_validate_and_are_scaled() -> void:
	var all := _zones()
	for zid in OUTDOOR:
		var z: ZoneData = all[zid]
		assert_eq(z.validate(all), [], zid)
		assert_eq(z.scaled_floor, FLOOR, zid + " is scaled from Derry's band")
		assert_eq(Standing.nation_for_zone(zid), "ireland", zid + " counts for Ireland")
	assert_eq(Standing.nation_for_zone("donegal_tweed"), "ireland", "rooms take their town's nation")

func test_towns_have_a_sanctuary_shop_and_six_rooms() -> void:
	var all := _zones()
	for town in ["gweedore", "donegal"]:
		var rooms := []
		for w in all["donegal_town" if town == "donegal" else town].warps:
			rooms.append(str(w.to))
		assert_has(rooms, town + "_sanctuary")
		assert_has(rooms, town + "_shop")
		assert_true(rooms.size() >= 8, "%s has %d rooms" % [town, rooms.size()])

func test_plaques_are_unique_and_plentiful() -> void:
	var all := ZoneData.load_all()
	var seen := {}
	for zid in all:
		for s in all[zid].signs:
			if s.has("plaque"):
				assert_false(seen.has(s.plaque), "plaque id %s is unique" % s.plaque)
				seen[s.plaque] = true
	var count := {}
	for zid in OUTDOOR:
		count[zid] = 0
		for s in all[zid].signs:
			if s.has("plaque"):
				assert_true(str(s.get("title", "")) != "", "plaque %s has a title" % s.plaque)
				assert_false("—" in str(s.text), "no em-dashes")
				count[zid] += 1
	assert_true(count.gweedore >= 8 and count.donegal_town >= 8, "8+ plaques per town")
	assert_true(count.glenveagh >= 3 and count.tory_island >= 3, "3+ plaques per route")

func test_trainers_are_scaled_and_exist() -> void:
	var n := 0
	# Only trainers standing in the Donegal zones: wave 55's Golden Vale also uses a gv_ prefix, and it is scaled
	# from Kilkenny and Limerick (55), not from Derry's band.
	var all := _zones()
	var placed := {}
	for zid in OUTDOOR:
		for npc in all[zid].npcs:
			if npc.has("trainer"):
				placed[str(npc.trainer)] = true
	for tid in StoryData.trainer_ids():
		if placed.has(tid) and (tid.begins_with("gv_") or tid.begins_with("gw_") or tid.begins_with("tory_") or tid.begins_with("dt_")):
			n += 1
			var raw = JsonUtil.read(StoryData.TRAINER_DIR.path_join(tid + ".json"))
			assert_eq(int(raw.get("scaled_floor", -1)), FLOOR, tid)
	assert_true(n >= 6, "six or more Donegal trainers, got %d" % n)
	assert_eq(JsonUtil.read(StoryData.TRAINER_DIR.path_join("dt_annalist.json")).party.size(), 6, "the local legend has a full party")

func test_every_quest_flag_is_set_somewhere() -> void:
	var quests = JsonUtil.read("res://data/quests/donegal.json")
	assert_true(quests is Dictionary and quests.quests.size() >= 2)
	var text := ""
	for f in ["glenveagh", "gweedore", "gweedore_pub", "gweedore_weaver", "tory_island", "tory_gallery", "donegal_town", "donegal_tweed"]:
		text += FileAccess.get_file_as_string("res://data/dialogue/%s.json" % f)
	for q in quests.quests:
		var flags := [str(q.start_flag), str(q.done_flag)]
		for s in q.steps:
			flags.append(str(s.flag))
		for f in flags:
			assert_true(f.begins_with("q_donegal_"), f + " is namespaced")
			assert_true(('"flag": "%s"' % f) in text and ('"do": "set"' in text), f + " is set by a script")

func test_new_creatures_are_appendix_with_sprites_and_homes() -> void:
	var dex := Dex.load_default()
	var all := _zones()
	for id in ["sodling", "turfclamp", "liagling", "liagmor", "balor"]:
		assert_true(dex.has(id), id)
		assert_true(bool(dex.get_species(id).get("appendix", false)), id + " is in the appendix")
		assert_true(FileAccess.file_exists("res://art/sprites/creatures/%s_front.png" % id), id + " front")
		assert_true(FileAccess.file_exists("res://art/sprites/creatures/%s_back.png" % id), id + " back")
		assert_has(JsonUtil.read("res://data/dex_order.json"), id)
	assert_true(bool(dex.get_species("balor").get("legend", false)), "Balor is a legend")
	var placed := {}
	for zid in OUTDOOR:
		for kind in all[zid].encounters:
			for e in all[zid].encounters[kind]:
				placed[str(e.species)] = true
	assert_true(placed.has("sodling") and placed.has("liagling"), "the basics live in Donegal")
	assert_true('"species": "balor"' in FileAccess.get_file_as_string("res://data/dialogue/tory_island.json"), "Balor waits on Tory")

func test_tory_ferry_runs_both_ways() -> void:
	assert_eq(Travel.ferry_arrival("gweedore_tory", "gweedore").zone, "tory_island")
	assert_eq(Travel.ferry_arrival("gweedore_tory", "tory_island").zone, "gweedore")

func test_regional_items() -> void:
	var items := ItemDB.load_default()
	for id in ["smoked_mackerel", "carrageen_pudding", "tweed_cap", "errigal_quartz", "tory_clay", "crotal", "whin_blossom"]:
		assert_true(items.has(id), id)
	assert_has(items.shops.donegal_town_corner_shop.stock, "smoked_mackerel")
	assert_has(items.shops.gweedore_corner_shop.stock, "carrageen_pudding")
