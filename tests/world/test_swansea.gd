extends TestCase
## Wider Isles, R5: Swansea (Abertawe) and Gower (Gŵyr), hung off the south side of the Brecon Beacons.
## The join, the scaling, the quests' flags, the plaques, the new creatures and the landmarks.

const ZONES := ["swansea", "gower"]
const TRAINERS := ["swa_jack", "swa_trader", "swa_historian", "swa_surfer", "swa_poet", "swa_jogger",
	"gow_trekker", "gow_climber", "gow_cockler", "gow_caver", "gow_kiter", "gow_gwen"]
const NEW_SPECIES := ["wurmlet", "ormwyrm", "smeltling", "cuprion", "marilwyd"]
const STYLES := ["football_stadium", "engine_house", "swansea_market", "waterfront_museum", "pier", "cave_mouth", "three_cliffs"]

func _json(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func _run(h: FakeStoryHost, zone: String, script: String, owner := "") -> void:
	StoryData.clear_cache()
	await Commands.new(h, owner).run(StoryData.script(zone, script))

# ------------------------------------------------------------------ geography

func test_the_beacons_open_south_on_to_swansea_and_nowhere_else_new() -> void:
	var b := ZoneData.load_id("beacons")
	assert_eq(str(b.edges.south.to), "swansea")
	assert_eq(str(b.edges.west.to), "st_davids", "the old edges are untouched")
	assert_eq(str(b.edges.east.to), "cardiff")
	var s := ZoneData.load_id("swansea")
	assert_eq(str(s.edges.north.to), "beacons")
	assert_eq(str(s.edges.west.to), "gower")
	assert_eq(s.edges.size(), 3, "Swansea joins only the Beacons, Gower and (wave 55) the Glamorgan coast")
	assert_eq(str(s.edges.east.to), "glamorgan_coast")
	var g := ZoneData.load_id("gower")
	assert_eq(g.edges.keys(), ["east"], "Gower is the end of the line")
	# walking down the lane lands on Swansea's road, and back up again
	for x in range(23, 26):
		var arr := b.edge_arrival("south", Vector2i(x, b.height - 1), s)
		assert_true(s.walkable(arr), "south off the Beacons at %d lands on a walkable tile" % x)
		var back := s.edge_arrival("north", arr, b)
		assert_eq(back, Vector2i(x, b.height - 1), "and the way back lines up")

func test_new_zones_are_scaled_from_the_beacons_band() -> void:
	for id in ZONES:
		var z := ZoneData.load_id(id)
		assert_eq(z.scaled_floor, 33, id + " is scaled from par 33")
		assert_eq(z.region, "south_wales")
	for t in TRAINERS:
		var d: Dictionary = _json("res://data/trainers/%s.json" % t)
		assert_eq(int(d.get("scaled_floor", -1)), 33, t + " is scaled")
	assert_eq((_json("res://data/trainers/gow_gwen.json") as Dictionary).party.size(), 6, "the local legend has a full team")

func test_swansea_is_a_proper_town_with_a_station() -> void:
	var s := ZoneData.load_id("swansea")
	assert_eq(s.town_id, "swansea")
	assert_true(s.station != Vector2i(-1, -1), "a stop on the rail network")
	var to := []
	for w in s.warps:
		to.append(str(w.to))
	for room in ["swansea_sanctuary", "swansea_shop", "swansea_market", "swansea_waterfront", "swansea_birthplace",
			"swansea_dtc", "swansea_nosign", "swansea_stadium", "swansea_copperworks", "swansea_lifeboat"]:
		assert_has(to, room)
	var map: Dictionary = _json("res://data/world_map.json")
	assert_true(map.towns.has("swansea"), "Swansea is on the map")
	assert_true(map.places.has("gower"), "Gower is on the map")

func test_plaques_are_unique_and_plentiful() -> void:
	var seen := {}
	var count := {}
	for id in ZONES:
		count[id] = 0
		for s in ZoneData.load_id(id).signs:
			if s.has("plaque"):
				assert_false(seen.has(s.plaque), "plaque id %s is unique" % s.plaque)
				seen[s.plaque] = true
				assert_true(str(s.plaque).begins_with("swansea_"))
				assert_true(str(s.get("title", "")) != "")
				assert_false("—" in str(s.text), "no em-dashes")
				count[id] += 1
	assert_true(count.swansea >= 8, "8+ plaques in Swansea")
	assert_true(count.gower >= 3, "3+ plaques on Gower")

func test_landmarks_build() -> void:
	for style in STYLES:
		var out: Array = Meshes.building(6, 5, style, 2, 7, "south_wales")
		assert_true(out[0] is ArrayMesh and (out[0] as ArrayMesh).get_surface_count() > 0, style + " has a mesh")
	for id in ZONES:
		var root := ZoneBuilder.build(ZoneData.load_id(id))
		assert_true(root.get_child_count() > 0, id + " builds")
		root.free()

# ------------------------------------------------------------------ quests

func test_every_quest_flag_is_set_by_some_script() -> void:
	var text := ""
	for f in DirAccess.get_files_at("res://data/dialogue"):
		if f.begins_with("swansea") or f.begins_with("gower"):
			text += FileAccess.get_file_as_string("res://data/dialogue/" + f)
	var quests: Array = (_json("res://data/quests/swansea.json") as Dictionary).quests
	assert_eq(quests.size(), 3)
	for q in quests:
		var flags: Array = [q.start_flag, q.done_flag]
		for s in q.steps:
			flags.append(s.flag)
		for fl in flags:
			assert_true(str(fl).begins_with("q_swansea_"), fl)
			assert_true(text.contains("\"%s\"" % fl), "%s is set in the dialogue" % fl)

func test_worms_head_tide_puzzle_good_answer() -> void:
	var h := FakeStoryHost.new()
	h.choices = [1]
	await _run(h, "gower", "gow_coastguard", "gow_coastguard")
	assert_eq(h.data.flag("q_swansea_worm_started"), true)
	assert_eq(h.data.flag("q_swansea_worm_1"), true)
	assert_eq(h.data.flag("q_swansea_worm_safe"), true)
	assert_eq(h.warps.size(), 1, "over the causeway")

func test_worms_head_wrong_times() -> void:
	var h := FakeStoryHost.new()
	h.choices = [0]
	await _run(h, "gower", "gow_coastguard", "gow_coastguard")
	assert_false(h.data.flag("q_swansea_worm_1") == true, "10am: still under the sea")
	assert_eq(h.warps.size(), 0)
	h.choices = [2]
	await _run(h, "gower", "gow_coastguard", "gow_coastguard")
	assert_eq(h.data.flag("q_swansea_worm_1"), true, "the picnic plan gets you over...")
	assert_eq(h.data.flag("q_swansea_worm_safe"), false, "...but not back")
	h.warps.clear()
	h.choices = [1]
	await _run(h, "gower", "gow_warden", "gow_warden")
	assert_eq(h.warps.size(), 1, "stranded: you wait for the tide and are walked back")
	assert_eq(h.data.flag("q_swansea_worm_safe"), true)

func test_worm_needs_gwen_then_a_catch() -> void:
	var h := FakeStoryHost.new()
	h.data.set_flag("q_swansea_worm_started", true)
	h.data.set_flag("q_swansea_worm_1", true)
	await _run(h, "gower", "gow_wyrm", "gow_wyrm")
	assert_true(h.last_battle.is_empty(), "nothing answers before Gwen")
	await _run(h, "gower", "gow_gwen", "gow_gwen")
	assert_eq(h.last_battle.opts.trainer.id, "gow_gwen")
	assert_eq(h.data.flag("q_swansea_worm_2"), true)
	h.last_battle = {}
	await _run(h, "gower", "gow_wyrm", "gow_wyrm")
	assert_eq(h.last_battle.foes[0].species.id, "ormwyrm")
	assert_eq(h.last_battle.foes[0].level, 36, "authored at par 33")
	assert_false(h.data.flag("q_swansea_worm_3") == true, "knocked out is not caught")
	h.battle_results = [{"result": "caught"}]
	h.data.set_flag("badge_spirit", true)  # par 88: the wyrm lifts with the story
	await _run(h, "gower", "gow_wyrm", "gow_wyrm")
	assert_eq(h.last_battle.foes[0].level, 36 + 88 - 33)
	assert_eq(h.data.flag("q_swansea_worm_caught"), true)
	assert_eq(h.data.flag("q_swansea_worm_3"), true)
	await _run(h, "gower", "gow_coastguard", "gow_coastguard")
	assert_eq(h.data.flag("q_swansea_worm_done"), true)
	assert_eq(Bag.new(h.data.bag).count("hag_stone"), 1)

func test_milk_wood_voices() -> void:
	var h := FakeStoryHost.new()
	await _run(h, "swansea_dtc", "dtc_curator", "dtc_curator")
	assert_eq(h.data.flag("q_swansea_milkwood_started"), true)
	for v in [["swansea", "swa_captain_cat"], ["swansea", "swa_polly"], ["swansea_nosign", "swa_organ"]]:
		await _run(h, v[0], v[1], v[1])
	await _run(h, "swansea_dtc", "dtc_curator", "dtc_curator")
	assert_false(h.data.flag("q_swansea_milkwood_done") == true, "three voices is not four")
	await _run(h, "swansea", "swa_ogmore", "swa_ogmore")
	await _run(h, "swansea_dtc", "dtc_curator", "dtc_curator")
	assert_eq(h.data.flag("q_swansea_milkwood_done"), true)
	assert_eq(Bag.new(h.data.bag).count("milk_wood_script"), 1)

func test_cockles_need_the_riddle() -> void:
	var h := FakeStoryHost.new()
	await _run(h, "swansea_market", "mkt_megan", "mkt_megan")
	assert_eq(h.data.flag("q_swansea_cockles_started"), true)
	h.choices = [0]
	await _run(h, "gower", "gow_dilys", "gow_dilys")
	assert_eq(h.data.flag("q_swansea_cockles_1"), true)
	assert_false(h.data.flag("q_swansea_cockles_2") == true, "taking every cockle is wrong")
	h.choices = [1]
	await _run(h, "gower", "gow_dilys", "gow_dilys")
	assert_eq(Bag.new(h.data.bag).count("penclawdd_cockles"), 1)
	await _run(h, "swansea_market", "mkt_megan", "mkt_megan")
	assert_eq(h.data.flag("q_swansea_cockles_done"), true)
	assert_true(Bag.new(h.data.bag).count("laverbread") >= 4)

# ------------------------------------------------------------------ creatures and items

func test_new_creatures_are_appendix_lines_with_sprites_and_homes() -> void:
	var order: Array = _json("res://data/dex_order.json")
	var knacks: Dictionary = (_json("res://data/knacks.json") as Dictionary).species
	var placed := {}
	for id in ZONES:
		for kind in ZoneData.load_id(id).encounters:
			for e in ZoneData.load_id(id).encounters[kind]:
				placed[str(e.species)] = true
	var dex := Dex.load_default()
	for sp in NEW_SPECIES:
		assert_true(dex.has(sp), sp + " loads")
		assert_eq(dex.get_species(sp).get("appendix"), true, sp + " is in the appendix")
		assert_has(order, sp)
		assert_true(knacks.has(sp), sp + " has a knack")
		for side in ["front", "back", "icon"]:
			assert_true(ResourceLoader.exists("res://art/sprites/creatures/%s_%s.png" % [sp, side]), "%s %s sprite" % [sp, side])
		assert_true(placed.has(sp), sp + " lives somewhere in Swansea or Gower")
	var at := order.find(NEW_SPECIES[0])
	assert_eq(order.slice(at, at + NEW_SPECIES.size()), NEW_SPECIES, "appended together, in order, after the base dex")
	assert_true(at >= 212, "after the original dex (later regions append after them)")

func test_regional_items_are_sold_locally() -> void:
	var items := ItemDB.load_default()
	for id in ["welsh_cake", "laverbread", "penclawdd_cockles", "milk_wood_script", "copper_slag", "copper_sheathing"]:
		assert_true(items.has(id), id)
	var stall: Dictionary = _json("res://data/shops/swansea_market_stall.json")
	for id in ["welsh_cake", "laverbread", "copper_sheathing"]:
		assert_has(stall.stock, id)
