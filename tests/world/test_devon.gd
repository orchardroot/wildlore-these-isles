extends TestCase
## The Devon region (Wider Isles): Plymouth and Exeter off Dartmoor, with the Exe Estuary between, its quests,
## plaques, trainers, items and three appendix creature lines.

const ZONES := ["plymouth", "exeter", "exe_estuary"]
const SPECIES := ["wishtling", "wistoak", "beaconet", "beaconblaze", "hairyhands"]

func _all() -> Dictionary:
	return ZoneData.load_all()

func test_zones_join_dartmoor_as_a_cul_de_sac() -> void:
	var all := _all()
	var moor: ZoneData = all["dartmoor"]
	assert_eq(moor.edges["south"].to, "plymouth")
	assert_eq(moor.edges["east"].to, "exe_estuary")
	assert_eq(moor.edges["north"].to, "somerset_levels", "Dartmoor's old edges are untouched")
	assert_eq(moor.edges["west"].to, "tintagel")
	var plym_edges: Array = all["plymouth"].edges.keys().filter(func(k): return not all["plymouth"].edges[k].has("lease"))
	assert_eq(plym_edges, ["north"], "Plymouth only leads back to the moor (bar a lease zone)")
	assert_eq(all["exeter"].edges.keys(), ["south"], "Exeter only leads back to the estuary")
	assert_eq(all["exe_estuary"].edges["north"].to, "exeter")
	for zid in ZONES + ["dartmoor"]:
		assert_eq(all[zid].validate(all), [], zid)

func test_zones_are_scaled_from_the_moor_floor() -> void:
	var all := _all()
	for zid in ZONES:
		assert_eq(all[zid].scaled_floor, 43, zid)
		assert_eq(all[zid].region, "south_england", zid)

func test_towns_have_stations_and_six_rooms() -> void:
	var all := _all()
	for zid in ["plymouth", "exeter"]:
		var z: ZoneData = all[zid]
		assert_eq(z.town_id, zid)
		assert_true(z.station != Vector2i(-1, -1), zid + " station")
		assert_true(Travel.world_map().towns.has(zid), zid + " on the world map")
		assert_true(z.warps.size() >= 8, zid + " rooms")
		assert_true(all.has(zid + "_sanctuary"), zid + " sanctuary")

func test_plaques() -> void:
	var all := _all()
	var ids := {}
	for zid in ZONES + ["dartmoor"]:
		var n := 0
		for s in all[zid].signs:
			if s.has("plaque"):
				assert_true(str(s.plaque).begins_with("devon_"), str(s.plaque))
				assert_false(ids.has(s.plaque), "unique " + str(s.plaque))
				ids[s.plaque] = true
				n += 1
		if zid != "dartmoor":
			assert_true(n >= (3 if all[zid].kind == "route" else 8), "%s has %d plaques" % [zid, n])

func test_trainers_are_scaled_and_one_is_a_legend() -> void:
	var full := 0
	for tid in ["ply_bowls", "ply_rating", "ply_fan", "ply_angler", "ply_jogger", "ply_aquarist", "exe_legion", "exe_student",
			"exe_runner", "exe_verger", "exe_jory", "exe_twitcher", "exe_cyclist", "exe_walker", "exe_boater", "exe_cobley"]:
		var t := StoryData.trainer(tid)
		assert_false(t.is_empty(), tid)
		assert_eq(int(t.get("scaled_floor", -1)), 43, tid)
		if t.party.size() == 6:
			full += 1
	assert_eq(full, 1, "Uncle Tom Cobley brings a full party")

func test_every_quest_flag_is_set_somewhere() -> void:
	var quests: Dictionary = JsonUtil.read("res://data/quests/devon.json")
	var set_flags := {}
	var files := StoryData.all_dialogue()
	for f in files:
		for sid in files[f]:
			_collect_sets(files[f][sid], set_flags)
	assert_eq(quests.quests.size(), 4)
	for q in quests.quests:
		var flags := [q.start_flag, q.done_flag]
		for s in q.steps:
			flags.append(s.flag)
		for f in flags:
			assert_true(str(f).begins_with("q_devon_"), f)
			assert_true(set_flags.has(f), "set somewhere: " + f)

func _collect_sets(cmds: Variant, out: Dictionary) -> void:
	if not cmds is Array:
		return
	for c in cmds:
		if not c is Dictionary:
			continue
		if str(c.get("do", "")) == "set":
			out[str(c.flag)] = true
		for k in ["then", "else"]:
			_collect_sets(c.get(k, []), out)

func test_quests_include_a_battle_and_a_catch() -> void:
	var tea := StoryData.script("exeter_tearoom", "tea_jory")
	assert_true(JSON.stringify(tea).contains('"battle"'), "the cream tea war is a trainer fight")
	var hands := StoryData.script("exe_estuary", "est_hairyhands")
	assert_true(JSON.stringify(hands).contains('"legend"'), "the Hairy Hands are caught")

func test_regional_items_and_shops() -> void:
	var items := ItemDB.load_default()
	for id in ["devon_scone", "scrumpy", "turned_coat", "drakes_drum", "clotted_cream", "stamp_book"]:
		assert_false(items.get_item(id).is_empty(), id)
	for shop in ["plymouth_corner_shop", "exeter_corner_shop"]:
		for id in ["devon_scone", "scrumpy", "turned_coat"]:
			assert_true(id in items.shops[shop].stock, "%s sells %s" % [shop, id])

func test_new_creatures_are_appendix_with_art_and_a_home() -> void:
	var dex := Dex.load_default()
	var order: Array = JsonUtil.read("res://data/dex_order.json")
	var all := _all()
	for id in SPECIES:
		assert_true(dex.has(id), id)
		assert_true(bool(dex.get_species(id).get("appendix", false)), id + " is appendix")
		assert_true(id in order, id + " in dex order")
		for which in ["front", "back", "icon"]:
			assert_true(ResourceLoader.exists("res://art/sprites/creatures/%s_%s.png" % [id, which]), id + " " + which)
		var placed := false
		for zid in ZONES + ["dartmoor"]:
			for kind in all[zid].encounters:
				for e in all[zid].encounters[kind]:
					placed = placed or str(e.species) == id
		placed = placed or JSON.stringify(StoryData.script("exe_estuary", "est_hairyhands")).contains(id)
		assert_true(placed, id + " can be met")
		var types: Array = dex.get_species(id).types
		assert_false(types.has("gale") or types.has("kin"), id + " favours an under-represented type")

func test_the_hairy_hands_clue_says_what_must_be_done_first() -> void:
	var hunt := {}
	for h in Rumours.hunts():
		if str(h.id) == "hairyhands":
			hunt = h
	assert_false(hunt.is_empty())
	assert_true(str(hunt.rumours[0].clue).contains("letterbox"), "the clue names the stamp that wakes them")
	var gate := ""
	for n in _all()["exe_estuary"].npcs:
		if str(n.id) == "est_hairyhands":
			gate = str(n.show_if)
	assert_eq(gate, "q_devon_letterbox_3")
