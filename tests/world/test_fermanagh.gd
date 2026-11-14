extends TestCase
## 3.0 Wider Isles: Fermanagh. Lough Neagh (a route) and Enniskillen (a town) hang off Belfast's west side as a
## cul-de-sac, scaled from par 65, with three quests, heritage plaques, local items and three appendix lines.

const OUTDOOR := ["lough_neagh", "enniskillen"]
const NEW_SPECIES := ["neagheen", "neaghmor", "dripkin", "stalaghast", "twaface"]
const ITEMS := ["boxty", "fermanagh_black_bacon", "smoked_eel", "armagh_bramley", "illuminated_page", "geopark_pin", "scutched_flax"]
const NEW_STYLES := ["erne_terrace", "watergate", "palladian", "monument_column", "marble_arch_cave"]

func _zone(id: String) -> ZoneData:
	return ZoneData.load_id(id)

func _region_zone_ids() -> Array:
	var out := []
	for path in JsonUtil.list_json("res://data/zones"):
		var id: String = path.get_file().get_basename()
		if id == "lough_neagh" or id == "enniskillen" or id.begins_with("lough_neagh_") or id.begins_with("enniskillen_"):
			out.append(id)
	return out

func test_the_way_west_from_belfast() -> void:
	var bel := _zone("belfast")
	assert_eq(str(bel.edges.west.to), "lough_neagh")
	var ln := _zone("lough_neagh")
	assert_eq(str(ln.edges.east.to), "belfast")
	assert_eq(str(ln.edges.west.to), "enniskillen")
	var en := _zone("enniskillen")
	assert_eq(str(en.edges.east.to), "lough_neagh")
	assert_eq(str(en.edges.west.to), "erne_shore")  # w56: the Erne Shore Road on to Donegal Town, shut until the Iron Stone
	assert_eq(en.edges.size(), 2, "Enniskillen joins only Lough Neagh and the Erne Shore Road")
	# Belfast's other edges are untouched
	assert_eq(str(bel.edges.north.to), "antrim_coast")
	assert_eq(str(bel.edges.south.to), "mournes")

func test_new_areas_scale_from_belfasts_band() -> void:
	for id in OUTDOOR + ["enniskillen_marblearch"]:
		assert_eq(_zone(id).scaled_floor, 65, id)
	for tid in StoryData.trainer_ids():
		if str(tid).begins_with("ln_") or str(tid).begins_with("en_"):
			assert_eq(int(StoryData.trainer(tid).get("scaled_floor", -1)), 65, tid)

func test_enough_trainers_and_a_local_legend() -> void:
	var n := 0
	for tid in StoryData.trainer_ids():
		if str(tid).begins_with("ln_") or str(tid).begins_with("en_"):
			n += 1
	assert_true(n >= 6, "at least six trainers, got %d" % n)
	assert_eq(StoryData.trainer("en_bridie").party.size(), 6, "the Queen of the Erne has a full party")

func test_zones_are_northern_irish() -> void:
	for id in _region_zone_ids():
		assert_eq(Standing.nation_for_zone(id), "northern_ireland", id)
	assert_eq(StoryData.greeting("enniskillen_blakes", 600), "Bout ye?")

func test_town_has_its_sanctuary_shop_and_six_more_rooms() -> void:
	var en := _zone("enniskillen")
	var to := en.warps.map(func(w): return str(w.to))
	assert_has(to, "enniskillen_sanctuary")
	assert_has(to, "enniskillen_shop")
	assert_true(to.size() >= 8, "Sanctuary, shop and at least six places people know")

func test_heritage_plaques() -> void:
	var seen := {}
	for path in JsonUtil.list_json("res://data/zones"):
		var z = JsonUtil.read(path)
		if not z is Dictionary:
			continue
		for s in z.get("signs", []):
			if s.has("plaque"):
				assert_false(seen.has(s.plaque), "plaque id %s is unique" % s.plaque)
				seen[s.plaque] = true
	var counts := {"lough_neagh": 0, "enniskillen": 0}
	for id in _region_zone_ids():
		for s in _zone(id).signs:
			if s.has("plaque"):
				assert_true(str(s.get("title", "")) != "", "%s has a title" % s.plaque)
				assert_false(str(s.text).contains("—"), "no em-dashes in %s" % s.plaque)
				counts["lough_neagh" if id.begins_with("lough_neagh") else "enniskillen"] += 1
	assert_true(counts.enniskillen >= 8, "Enniskillen plaques: %d" % counts.enniskillen)
	assert_true(counts.lough_neagh >= 3, "Lough Neagh plaques: %d" % counts.lough_neagh)

## Every flag a quest waits on is set somewhere: by a dialogue "set" or a legend's catch flag.
func test_every_quest_flag_is_set_somewhere() -> void:
	var setters := {}
	var all := StoryData.all_dialogue()
	for file in all:
		for sid in all[file]:
			_collect(all[file][sid], setters)
	var q = JsonUtil.read("res://data/quests/fermanagh.json")
	assert_eq(q.quests.size(), 3)
	for quest in q.quests:
		var flags := [str(quest.start_flag), str(quest.done_flag)]
		for st in quest.steps:
			flags.append(str(st.flag))
			assert_true(ZoneData.load_id(str(st.zone)).id != "" and FileAccess.file_exists("res://data/zones/%s.json" % st.zone), "step zone %s" % st.zone)
		for f in flags:
			assert_true(f.begins_with("q_fermanagh_"), f)
			assert_true(setters.has(f), "%s is set somewhere" % f)

func _collect(cmds: Variant, out: Dictionary) -> void:
	if not cmds is Array:
		return
	for c in cmds:
		if not c is Dictionary:
			continue
		if str(c.get("do", "")) == "set":
			out[str(c.flag)] = true
		if str(c.get("do", "")) == "legend" and c.has("flag"):
			out[str(c.flag)] = true
		for k in ["then", "else"]:
			_collect(c.get(k, []), out)

func test_quests_include_a_fight_and_a_catch() -> void:
	var cave: Array = StoryData.script("enniskillen_marblearch", "en_caver_spot")
	assert_true(JSON.stringify(cave).contains("\"trainer\":\"en_caver\""), "the cave quest has a trainer battle")
	var janus: Array = StoryData.script("enniskillen", "en_janus")
	assert_true(JSON.stringify(janus).contains("\"species\":\"twaface\""), "the islands quest ends with a catch")

func test_regional_creatures() -> void:
	var dex := Dex.load_default()
	var order = JsonUtil.read("res://data/dex_order.json")
	var placed := {}
	for id in _region_zone_ids():
		var z := _zone(id)
		for kind in z.encounters:
			for e in z.encounters[kind]:
				placed[str(e.species)] = true
	for id in NEW_SPECIES:
		assert_true(dex.has(id), id)
		var sp := dex.get_species(id)
		assert_true(bool(sp.get("appendix", false)), "%s is in the appendix" % id)
		assert_has(order, id)
		assert_true(FileAccess.file_exists("res://art/sprites/creatures/%s_front.png" % id), id + " front")
		assert_true(FileAccess.file_exists("res://art/sprites/creatures/%s_back.png" % id), id + " back")
		var bst := 0
		for k in sp.base:
			bst += int(sp.base[k])
		if sp.get("evolves") is Dictionary:
			assert_true(bst >= 280 and bst <= 330, "%s basic BST %d" % [id, bst])
		else:
			assert_true(bst >= 450 and bst <= 500, "%s final BST %d" % [id, bst])
		for t in sp.types:
			assert_true(t in ["bog", "storm", "frost", "spirit", "stone"], "%s favours under-represented types" % id)
		assert_true(placed.has(id) or id == "twaface", "%s lives somewhere in Fermanagh" % id)
	assert_eq(str(dex.get_species("neagheen").evolves.to), "neaghmor")
	assert_eq(str(dex.get_species("dripkin").evolves.to), "stalaghast")

func test_regional_items_are_in_the_shop() -> void:
	var items := ItemDB.load_default()
	var stock: Array = JsonUtil.read("res://data/shops/enniskillen_corner_shop.json").stock
	for id in ITEMS:
		assert_true(items.has(id), id)
	for id in ["boxty", "fermanagh_black_bacon", "smoked_eel", "armagh_bramley"]:
		assert_has(stock, id)

func test_new_building_styles_build() -> void:
	for style in NEW_STYLES:
		assert_has(Landmarks.SPECIAL, style)
		var r: Array = Landmarks.building(6, 4, style, 2, 7)
		assert_true((r[0] as ArrayMesh).get_surface_count() > 0, style)

func test_on_the_map() -> void:
	var m = JsonUtil.read("res://data/world_map.json")
	assert_true(m.towns.has("enniskillen"))
	assert_eq(str(m.towns.enniskillen.nation), "northern_ireland")
	assert_true(m.places.has("lough_neagh"))
	# west of Belfast, Enniskillen further west and south
	assert_true(m.places.lough_neagh.x < m.towns.belfast.x and m.towns.enniskillen.x < m.places.lough_neagh.x)
	assert_true(m.towns.enniskillen.y > m.towns.belfast.y)
