extends TestCase
## Wave 33, agent 6: the Channel Islands. Poole Quay off the Exe Estuary's east side (gated on the Storm Stone), Jersey
## (St Helier and the countryside), Guernsey (St Peter Port and the west), a nod to Sark, the ferries between them,
## their registry files, quests, plaques, trainers, items, creatures and building styles.

const ZONES := ["poole", "st_helier", "jersey_country", "st_peter_port", "guernsey_country", "sark"]
const TOWNS := ["poole", "st_helier", "st_peter_port", "sark"]
const SPECIES := ["tchian", "crockling", "beancrock", "vraicling"]
const STYLES := ["jersey_granite", "guernsey_granite", "jersey_tower", "little_chapel"]
const TRAINERS := {
	"poole": ["poo_lifeboat", "poo_scout", "poo_sandbanks"],
	"st_helier": ["jsy_fishmonger", "jsy_centenier", "jsy_banker", "jsy_swimmer"],
	"jersey_country": ["jer_dairyman", "jer_surfer", "jer_keeper_t", "jer_walker", "jer_legend"],
	"st_peter_port": ["spp_fisher", "spp_douzaine", "spp_herdsman", "spp_tomato"],
	"guernsey_country": ["gue_ormer", "gue_cyclist", "gue_monk", "gue_legend"],
	"sark": ["srk_farmer", "srk_diver"],
}

func _all() -> Dictionary:
	return ZoneData.load_all()

func _run(h: FakeStoryHost, zone: String, script: String, owner := "") -> void:
	StoryData.clear_cache()
	await Commands.new(h, owner).run(StoryData.script(zone, script))

# ------------------------------------------------------------------ geography

func test_poole_hangs_off_the_estuary_and_the_islands_are_cul_de_sacs() -> void:
	var all := _all()
	assert_eq(all["exe_estuary"].edges["east"].to, "poole")
	assert_eq(all["exe_estuary"].edges["north"].to, "exeter", "the estuary's old edges are untouched")
	assert_eq(all["exe_estuary"].edges["west"].to, "dartmoor")
	assert_eq(all["poole"].edges.keys(), ["west", "north"], "Poole: the estuary road, and wave 55's Cranborne Chase road")
	assert_eq(all["st_helier"].edges.keys(), ["north"])
	assert_eq(all["jersey_country"].edges.keys(), ["south"])
	assert_eq(all["st_peter_port"].edges.keys(), ["west"])
	assert_eq(all["guernsey_country"].edges.keys(), ["east"])
	assert_true(all["sark"].edges.is_empty(), "Sark is reached by boat only")
	for zid in ZONES + ["exe_estuary"]:
		assert_eq(all[zid].validate(all), [], zid)

func test_zones_are_scaled_at_the_band_after_the_fourth_badge() -> void:
	var all := _all()
	for zid in ZONES:
		assert_eq(all[zid].scaled_floor, 40, zid)
	for zid in ["st_helier", "jersey_country", "st_peter_port", "guernsey_country", "sark"]:
		assert_eq(all[zid].region, "channel_islands", zid)
	assert_eq(ParLevel.par({"badge_storm": true}), 40, "the Storm Stone is the fourth badge: par 40")

func test_the_road_to_poole_is_shut_until_the_storm_stone() -> void:
	var z := ZoneData.load_id("exe_estuary")
	var marshals := 0
	for n in z.npcs:
		if str(n.get("script", "")) == "poole_marshal":
			marshals += 1
			assert_eq(str(n.get("hide_if", "")), "badge_storm")
	assert_eq(marshals, 3)
	assert_false(StoryData.script("exe_estuary", "poole_marshal").is_empty())

func test_towns_have_sanctuaries_and_rooms_and_are_on_the_map() -> void:
	var all := _all()
	var m: Dictionary = Travel.world_map().towns
	for zid in TOWNS:
		assert_eq(all[zid].town_id, zid)
		assert_true(m.has(zid), zid + " on the world map")
		assert_true(all.has(zid + "_sanctuary"), zid + " has a sanctuary")
	for zid in ["poole", "st_helier", "st_peter_port"]:
		assert_true(all[zid].warps.size() >= (6 if zid == "poole" else 8), zid + " has rooms to enter")
	assert_true(all["poole"].station != Vector2i(-1, -1), "Poole is a rail stop")
	assert_eq(str(m["st_helier"].island), "jersey")
	assert_eq(str(m["st_peter_port"].island), "guernsey")
	assert_true(float(Travel.world_map().space[1]) >= 1400.0, "the map is tall enough for Jersey")
	assert_true(float(m["st_helier"].y) < float(Travel.world_map().space[1]))
	assert_true(Travel.world_map().land.has("channel_islands"), "the islands are drawn")

# ------------------------------------------------------------------ ferries and the registry

func test_ferries_join_the_four_harbours() -> void:
	var all := _all()
	var f := Travel.ferries()
	for route in ["poole_st_helier", "poole_st_peter_port", "st_helier_st_peter_port", "st_peter_port_sark"]:
		assert_true(f.has(route), route)
		assert_true(all.has(str(f[route].a)) and all.has(str(f[route].b)), route + " ends exist")
		assert_true(Travel.world_map().ferry_paths.has(route), route + " is drawn")
	for zid in ["poole", "st_helier", "st_peter_port", "sark"]:
		assert_false(all[zid].ferry.is_empty(), zid + " has a quay")
	assert_eq(str(Travel.ferry_arrival("poole_st_helier", "poole").zone), "st_helier")
	assert_eq(str(Travel.ferry_arrival("poole_st_helier", "st_helier").zone), "poole")
	# the sailors on the piers run the crossings
	for pair in [["poole", "poole_sailor_je", "poole_st_helier"], ["poole", "poole_sailor_gu", "poole_st_peter_port"],
			["st_peter_port", "spp_sailor_jersey", "st_helier_st_peter_port"], ["st_peter_port", "spp_sailor_sark", "st_peter_port_sark"],
			["st_peter_port", "spp_sailor_poole", "poole_st_peter_port"], ["sark", "srk_sailor", "st_peter_port_sark"]]:
		assert_true(JSON.stringify(StoryData.script(pair[0], pair[1])).contains(pair[2]), pair[1])

func test_registry_files() -> void:
	var all := _all()
	for id in ["jersey", "guernsey"]:
		var r: Variant = JsonUtil.read("res://data/overseas/%s.json" % id)
		assert_true(r is Dictionary, id)
		assert_eq(str(r.id), id)
		assert_eq(str(r.via), "ferry")
		assert_eq(str(r.port), "poole")
		assert_true(all.has(str(r.port)), "the port zone exists")
		assert_true(all.has(str(r.arrival.zone)), "the arrival zone exists")
		var a: ZoneData = all[str(r.arrival.zone)]
		assert_true(a.walkable(Vector2i(int(r.arrival.x), int(r.arrival.y))), "the arrival tile is walkable")
		assert_eq(str(r.unlock_flag), "badge_storm", "the islands open at the fourth badge, ahead of the champion gate")
		assert_true(str(r.blurb) != "" and str(r.flight_line) != "")

# ------------------------------------------------------------------ learning: plaques, trainers, items

func test_plaques_are_unique_and_plentiful() -> void:
	var all := _all()
	var ids := {}
	var total := 0
	for zid in ZONES:
		var n := 0
		for s in all[zid].signs:
			if s.has("plaque"):
				assert_true(str(s.plaque).begins_with("channel_islands_"), str(s.plaque))
				assert_false(ids.has(s.plaque), "unique " + str(s.plaque))
				assert_true(str(s.get("title", "")) != "", str(s.plaque) + " has a title")
				assert_false(str(s.text).contains("—"), "no em-dashes")
				ids[s.plaque] = true
				n += 1
		total += n
		assert_true(n >= (3 if all[zid].kind == "route" else 5), "%s has %d plaques" % [zid, n])
	assert_true(total >= 30, "plenty to read: %d" % total)

func test_trainers_are_scaled_and_each_big_zone_has_a_legend() -> void:
	for zid in TRAINERS:
		for tid in TRAINERS[zid]:
			var t := StoryData.trainer(tid)
			assert_false(t.is_empty(), tid)
			assert_eq(int(t.get("scaled_floor", -1)), 40, tid)
	for tid in ["jer_legend", "gue_legend"]:
		assert_eq(StoryData.trainer(tid).party.size(), 6, tid + " brings a full party")
	var all := _all()
	for zid in TRAINERS:
		for tid in TRAINERS[zid]:
			var found := false
			for n in all[zid].npcs:
				found = found or str(n.get("trainer", "")) == tid
			assert_true(found, tid + " stands in " + zid)

func test_regional_items_and_shops() -> void:
	var items := ItemDB.load_default()
	for id in ["jersey_royal", "jersey_black_butter", "jersey_wonder", "guernsey_gache", "golden_guernsey_milk", "guernsey_gansey", "chapel_pebble", "liberation_flag"]:
		assert_false(items.get_item(id).is_empty(), id)
	for id in ["jersey_royal", "jersey_black_butter", "jersey_wonder"]:
		assert_true(id in items.shops["st_helier_corner_shop"].stock, id)
	for id in ["guernsey_gache", "guernsey_gansey", "golden_guernsey_milk"]:
		assert_true(id in items.shops["st_peter_port_corner_shop"].stock, id)
	assert_true(items.shops.has("poole_corner_shop"))

func test_pub_quiz_questions_were_added() -> void:
	var n := 0
	for q in JsonUtil.read("res://data/quiz/questions.json"):
		if str(q.q).contains("Jersey") or str(q.q).contains("Channel Islands") or str(q.q).contains("Poole"):
			n += 1
	assert_true(n >= 6, "island questions in the bank")

# ------------------------------------------------------------------ creatures and landmarks

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
		for zid in ZONES:
			for kind in all[zid].encounters:
				for e in all[zid].encounters[kind]:
					placed = placed or str(e.species) == id
		assert_true(placed, id + " can be met")
		var types: Array = dex.get_species(id).types
		assert_false(types.has("gale"), id + " favours an under-represented type")
	assert_true(JSON.stringify(StoryData.script("jersey_country", "tchian_spot")).contains('"legend"'), "the Black Dog is caught as a legend")
	assert_eq(str(dex.get_species("crockling").evolves.to), "beancrock")

func test_landmark_styles_and_zones_build() -> void:
	for style in STYLES:
		var out: Array = Meshes.building(7, 5, style, 4, 7, "channel_islands")
		assert_true(out[0] is ArrayMesh and (out[0] as ArrayMesh).get_surface_count() > 0, style + " has a mesh")
	for id in ZONES:
		var root := ZoneBuilder.build(ZoneData.load_id(id))
		assert_true(root.get_child_count() > 0, id + " builds")
		root.free()

# ------------------------------------------------------------------ quests

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

func test_every_quest_flag_is_set_somewhere() -> void:
	var quests: Dictionary = JsonUtil.read("res://data/quests/channel_islands.json")
	var set_flags := {}
	var files := StoryData.all_dialogue()
	for f in files:
		for sid in files[f]:
			_collect_sets(files[f][sid], set_flags)
	assert_eq(quests.quests.size(), 3)
	for q in quests.quests:
		var flags := [q.start_flag, q.done_flag]
		for s in q.steps:
			flags.append(s.flag)
		for f in flags:
			assert_true(str(f).begins_with("q_channel_islands_"), f)
			assert_true(set_flags.has(f), "set somewhere: " + f)

func test_royals_quest_wants_a_vraicling_and_a_fight() -> void:
	var h := FakeStoryHost.new()
	h.dex = Dex.load_default()
	await _run(h, "st_helier_market", "sth_royal_stall", "sth_royal_stall")
	assert_eq(h.data.flag("q_channel_islands_royals_started"), true)
	await _run(h, "jersey_farm", "jer_farmwife", "jer_farmwife")
	assert_eq(h.data.flag("q_channel_islands_royals_1"), true)
	await _run(h, "jersey_farm", "jer_farmwife", "jer_farmwife")
	assert_false(h.data.flag("q_channel_islands_royals_2") == true, "no crate without a Vraicling")
	h.data.caught["vraicling"] = true
	await _run(h, "jersey_farm", "jer_farmwife", "jer_farmwife")
	assert_false(h.data.flag("q_channel_islands_royals_2") == true, "no crate without beating Josué")
	h.data.set_flag("trainer_jer_legend")
	await _run(h, "jersey_farm", "jer_farmwife", "jer_farmwife")
	assert_eq(h.data.flag("q_channel_islands_royals_2"), true)
	assert_eq(Bag.new(h.data.bag).count("jersey_royal"), 3)
	await _run(h, "st_helier_market", "sth_royal_stall", "sth_royal_stall")
	assert_eq(h.data.flag("q_channel_islands_royals_done"), true)
	assert_eq(Bag.new(h.data.bag).count("jersey_royal"), 6, "three more from the stall as thanks")
	assert_eq(h.data.party.size(), 1, "and a Crockling")

func test_liberation_quest_visits_two_witnesses_in_order() -> void:
	var h := FakeStoryHost.new()
	await _run(h, "jersey_tunnels", "jer_tunnel_keeper", "jer_tunnel_keeper")
	assert_false(h.data.flag("q_channel_islands_liberation_1") == true, "the archivist waits to be asked")
	await _run(h, "st_helier_maritime", "sth_tapestry", "sth_tapestry")
	assert_eq(h.data.flag("q_channel_islands_liberation_started"), true)
	await _run(h, "st_helier_castle", "sth_castle_guide", "sth_castle_guide")
	assert_false(h.data.flag("q_channel_islands_liberation_2") == true, "the castle guide goes second")
	await _run(h, "jersey_tunnels", "jer_tunnel_keeper", "jer_tunnel_keeper")
	assert_eq(h.data.flag("q_channel_islands_liberation_1"), true)
	await _run(h, "st_helier_castle", "sth_castle_guide", "sth_castle_guide")
	assert_eq(h.data.flag("q_channel_islands_liberation_2"), true)

func test_chapel_quest_wants_a_pinchkin_then_china() -> void:
	var h := FakeStoryHost.new()
	h.dex = Dex.load_default()
	await _run(h, "guernsey_country", "gue_brother", "gue_brother")
	assert_eq(h.data.flag("q_channel_islands_chapel_started"), true)
	await _run(h, "guernsey_country", "gue_beachcomber", "gue_beachcomber")
	assert_false(h.data.flag("q_channel_islands_chapel_1") == true, "no shell without a crab")
	h.data.caught["pinchkin"] = true
	await _run(h, "guernsey_country", "gue_beachcomber", "gue_beachcomber")
	assert_eq(h.data.flag("q_channel_islands_chapel_1"), true)
	await _run(h, "st_peter_port_bakery", "spp_baker", "spp_baker")
	assert_eq(h.data.flag("q_channel_islands_chapel_2"), true)

func test_black_dog_comes_only_at_night_or_in_fog() -> void:
	var h := FakeStoryHost.new()
	h.dex = Dex.load_default()
	await _run(h, "jersey_country", "tchian_spot", "jer_tchian")
	assert_true(h.last_battle.is_empty(), "nothing in broad daylight")
