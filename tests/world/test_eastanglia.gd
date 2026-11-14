extends TestCase
## East Anglia (3.0 Wider Isles): Cambridge, the Fens, Norwich and the Broads, hung off London's north side.

const OUTDOOR := ["cambridge", "the_fens", "norwich", "the_broads"]
const TOWNS := ["cambridge", "norwich"]
const SPECIES := ["tickhopper", "chronophage", "mustling", "mustardrake", "turvling", "turfmere", "fentiger", "hereward"]

func _zones() -> Dictionary:
	return ZoneData.load_all()

func test_zones_load_scaled_and_in_the_region() -> void:
	var all := _zones()
	for id in OUTDOOR:
		assert_true(all.has(id), "%s exists" % id)
		var z: ZoneData = all[id]
		assert_eq(z.parse_errors, [], "%s parses" % id)
		assert_eq(z.scaled_floor, 94, "%s is scaled from London's floor" % id)
		assert_eq(z.region, "east_anglia")
		assert_eq(z.validate(all), [], "%s validates" % id)

func test_joined_to_london_as_a_cul_de_sac() -> void:
	var all := _zones()
	assert_eq(str(all["london"].edges["north"].to), "cambridge")
	assert_eq(str(all["cambridge"].edges["south"].to), "london")
	assert_eq(str(all["cambridge"].edges["north"].to), "the_fens")
	assert_eq(str(all["the_fens"].edges["east"].to), "norwich")
	assert_eq(str(all["norwich"].edges["east"].to), "the_broads")
	for id in OUTDOOR:
		for side in all[id].edges:
			var to := str(all[id].edges[side].to)
			assert_true(to in OUTDOOR or (id == "cambridge" and to in ["london", "varsity_line"]) or all[id].edges[side].has("lease"), "%s %s edge stays inside East Anglia" % [id, side])

func test_towns_have_sanctuary_shop_station_and_six_interiors() -> void:
	var all := _zones()
	for id in TOWNS:
		var z: ZoneData = all[id]
		var inside := z.warps.map(func(w): return str(w.to))
		assert_has(inside, id + "_sanctuary")
		assert_has(inside, id + "_shop")
		assert_true(inside.size() >= 8, "%s has plenty of places to go in" % id)
		assert_true(z.station != Vector2i(-1, -1), "%s has a station" % id)

func test_plaques_are_unique_and_plentiful() -> void:
	var all := _zones()
	var seen := {}
	for id in all:
		for s in all[id].signs:
			if s.has("plaque"):
				assert_false(seen.has(s.plaque), "plaque id %s is unique" % s.plaque)
				seen[s.plaque] = true
	for id in OUTDOOR:
		var n := 0
		for s in all[id].signs:
			if str(s.get("plaque", "")).begins_with("eastanglia_"):
				n += 1
				assert_true(str(s.get("title", "")) != "", "plaque %s has a title" % s.plaque)
		assert_true(n >= (8 if id in TOWNS else 3), "%s has %d plaques" % [id, n])

func test_trainers_are_scaled() -> void:
	var n := 0
	for path in JsonUtil.list_json("res://data/trainers"):
		var t: Dictionary = JsonUtil.read(path)
		var id := str(t.get("id", ""))
		if id.begins_with("cam_") or id.begins_with("fen_") or id.begins_with("nor_") or id.begins_with("broads_"):
			n += 1
			assert_eq(int(t.get("scaled_floor", -1)), 94, "%s is scaled" % id)
	assert_true(n >= 6, "plenty of trainers (%d)" % n)
	assert_eq(StoryData.trainer("broads_jem").party.size(), 6, "the local legend has a full party")

func _sets(cmds: Array, out: Dictionary) -> void:
	for c in cmds:
		if not c is Dictionary:
			continue
		if str(c.get("do", "")) == "set":
			out[str(c.flag)] = true
		elif str(c.get("do", "")) == "legend":
			out[str(c.get("flag", ""))] = true
		for k in ["then", "else"]:
			_sets(c.get(k, []), out)

func test_every_quest_flag_is_set_somewhere() -> void:
	var data: Dictionary = JsonUtil.read("res://data/quests/eastanglia.json")
	var flagset := {}
	var dialogue := StoryData.all_dialogue()
	for file in dialogue:
		for sid in dialogue[file]:
			_sets(dialogue[file][sid], flagset)
	assert_true(data.quests.size() >= 4)
	for q in data.quests:
		var flags := [str(q.start_flag), str(q.done_flag)]
		for s in q.steps:
			flags.append(str(s.flag))
		for f in flags:
			assert_true(f.begins_with("q_eastanglia_"), "%s is namespaced" % f)
			assert_true(flagset.has(f), "%s is set by some dialogue" % f)

func test_regional_creatures() -> void:
	var dex := Dex.load_default()
	var order: Array = JsonUtil.read("res://data/dex_order.json")
	var all := _zones()
	for id in SPECIES:
		assert_true(dex.has(id), "%s loads" % id)
		var sp := dex.get_species(id)
		assert_true(bool(sp.get("appendix", false)), "%s is in the appendix" % id)
		assert_has(order, id)
		for side in ["front", "back", "icon"]:
			assert_true(FileAccess.file_exists("res://art/sprites/creatures/%s_%s.png" % [id, side]), "%s %s sprite" % [id, side])
		var placed: bool = id == "hereward"  # met through the Hereward quest's legend encounter
		for z in OUTDOOR:
			for kind in all[z].encounters:
				for e in all[z].encounters[kind]:
					placed = placed or str(e.species) == id
		assert_true(placed, "%s can be met" % id)

func test_regional_items_are_stocked() -> void:
	var items := ItemDB.load_default()
	for id in ["chelsea_bun", "fen_smoked_eel", "norfolk_dumpling", "norwich_mustard", "fen_runners", "norfolk_reed", "canary_scarf"]:
		assert_false(items.get_item(id).is_empty(), "%s exists" % id)
	assert_has(items.shops["cambridge_corner_shop"].stock, "chelsea_bun")
	assert_has(items.shops["norwich_corner_shop"].stock, "norwich_mustard")

func test_on_the_world_map() -> void:
	var m := Travel.world_map()
	assert_true(m.towns.has("cambridge") and m.towns.has("norwich"))
	assert_true(m.places.has("the_fens") and m.places.has("the_broads"))
