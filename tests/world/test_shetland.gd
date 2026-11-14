extends TestCase
## 3.2 Shetland: Lerwick and the Mainland road south of it, reached by ferry from Kirkwall, and Up Helly Aa (the last
## Tuesday of January) as a yearly festival there.

const ZONES := ["lerwick", "shetland_mainland"]
const INTERIORS := ["lerwick_museum", "lerwick_galley_shed", "lerwick_pub", "lerwick_fort", "lerwick_townhall", "lerwick_tearoom", "lerwick_wool", "lerwick_home_a"]
const OWN_TRAINERS := ["lerwick_", "mainland_", "shetland_"]

func _json(path: String) -> Variant:
	return JsonUtil.read(path)

func _species_ids() -> Dictionary:
	var ids := {}
	for f in DirAccess.get_files_at("res://data/creatures"):
		if f.ends_with(".json"):
			var d: Dictionary = _json("res://data/creatures/" + f)
			for sp in d.species:
				ids[str(sp.id)] = true
	return ids

func _is_own(tid: String) -> bool:
	for p in OWN_TRAINERS:
		if tid.begins_with(p):
			return true
	return false

func test_ferry_from_kirkwall_and_a_road_south() -> void:
	var r: Dictionary = Travel.ferries().kirkwall_lerwick
	assert_eq(r.a, "kirkwall")
	assert_eq(r.b, "lerwick")
	var lerwick := ZoneData.load_id("lerwick")
	var kirkwall := ZoneData.load_id("kirkwall")
	assert_eq(lerwick.ferry.route, "kirkwall_lerwick")
	assert_true(lerwick.walkable(Vector2i(int(lerwick.ferry.x), int(lerwick.ferry.y))))
	assert_eq(Travel.ferry_arrival("kirkwall_lerwick", "kirkwall").zone, "lerwick")
	assert_eq(Travel.ferry_arrival("kirkwall_lerwick", "lerwick").zone, "kirkwall")
	assert_true(kirkwall.walkable(Travel.ferry_arrival("kirkwall_lerwick", "lerwick").pos), "Kirkwall's quay tile")
	var ler_sides: Array = lerwick.edges.keys()
	ler_sides.sort()
	assert_eq(ler_sides, ["north", "south"], "wave 55 added the Scalloway road north")
	assert_eq(lerwick.edges.north.to, "scalloway_road")
	assert_eq(lerwick.edges.south.to, "shetland_mainland")
	var sm := ZoneData.load_id("shetland_mainland")
	var sm_sides: Array = sm.edges.keys()
	sm_sides.sort()
	assert_eq(sm_sides, ["north", "west"], "a cul-de-sac bar the wave 55 Scalloway road")
	assert_eq(sm.edges.west.to, "scalloway_road")
	assert_eq(sm.edges.north.to, "lerwick")
	assert_eq(lerwick.town_id, "lerwick")
	# Kirkwall keeps its own two boats; the new hand on the quay sails the third
	var hand := {}
	for n in kirkwall.npcs:
		if str(n.id) == "kwl_lerwick_hand":
			hand = n
	assert_false(hand.is_empty())
	var dlg: Array = StoryData.script("kirkwall", str(hand.script))
	assert_eq(str(dlg[-1].route), "kirkwall_lerwick")
	assert_eq(kirkwall.ferry.route, "aberdeen_kirkwall")
	var ferryhand: Array = StoryData.script("lerwick", "ls_ferryhand")
	assert_eq(str(ferryhand[-1].route), "kirkwall_lerwick")

func test_on_the_world_map_in_scotland() -> void:
	var m: Dictionary = Travel.world_map()
	assert_eq(m.towns.lerwick.nation, "scotland")
	assert_eq(Travel.town_name("lerwick"), "Lerwick")
	assert_true(["kirkwall", "lerwick"] in m.ferries)
	assert_true(m.ferry_paths.has("kirkwall_lerwick"))
	assert_true(m.places.has("shetland_mainland"))
	for z in ZONES:
		assert_eq(ZoneData.load_id(z).region, "scotland")

func test_scaled_to_kirkwalls_band() -> void:
	var band := int(ZoneData.load_id("kirkwall").encounters.grass[0].min)
	for z in ZONES:
		assert_eq(ZoneData.load_id(z).scaled_floor, band, z)
	var n := 0
	for tid in StoryData.trainer_ids():
		if _is_own(str(tid)):
			assert_eq(int(StoryData.trainer(tid).get("scaled_floor", -1)), band, tid)
			n += 1
	assert_true(n >= 8, "trainers: %d" % n)

func test_what_a_new_town_needs() -> void:
	var lerwick := ZoneData.load_id("lerwick")
	var targets := []
	for w in lerwick.warps:
		targets.append(str(w.to))
	assert_true("lerwick_sanctuary" in targets)
	assert_true("lerwick_shop" in targets)
	for id in INTERIORS:
		assert_true(id in targets, "no door to " + id)
		var z := ZoneData.load_id(id)
		assert_eq(z.kind, "interior")
		assert_true(z.npcs.size() >= 1, id)
	assert_true(INTERIORS.size() >= 6)
	var shop: Dictionary = _json("res://data/shops/lerwick_corner_shop.json")
	for id in ["reestit_mutton_soup", "shetland_bannock", "fair_isle_tammy"]:
		assert_true(id in shop.stock, id)
	assert_true(Charms.is_charm("fair_isle_tammy"))
	assert_true(Charms.is_charm("jarlshof_whorl"))
	assert_true(Charms.is_charm("pony_rosette"))
	var local := 0
	for t in lerwick.warps:
		if str(t.to).begins_with("lerwick_"):
			local += 1
	assert_true(local >= 10)

func test_the_real_places_are_there() -> void:
	var labels := []
	for p in ZoneData.load_id("lerwick").props:
		if p.type == "building":
			labels.append(str(p.get("label", "")))
	for want in ["Shetland Museum and Archives", "Up Helly Aa Galley Shed", "Fort Charlotte", "The Lounge", "Clickimin Broch"]:
		assert_true(want in labels, want)
	var main_labels := []
	for p in ZoneData.load_id("shetland_mainland").props:
		if p.type == "building":
			main_labels.append(str(p.get("label", "")))
	for want in ["Jarlshof", "Sumburgh Airport", "Mousa Broch"]:
		assert_true(want in main_labels, want)

func test_plaques_unique_and_enough() -> void:
	var counts := {}
	var seen := {}
	for z in ZONES:
		counts[z] = 0
		for s in ZoneData.load_id(z).signs:
			if s.has("plaque"):
				assert_false(seen.has(s.plaque), "duplicate plaque " + str(s.plaque))
				seen[s.plaque] = true
				assert_true(str(s.get("title", "")) != "")
				assert_true(str(s.text).length() > 100)
				assert_false("—" in str(s.text), "em-dash")
				counts[z] += 1
	assert_true(counts.lerwick >= 8)
	assert_true(counts.shetland_mainland >= 3)

func test_every_species_used_exists_and_the_wild_is_shetland() -> void:
	var ids := _species_ids()
	for tid in StoryData.trainer_ids():
		if _is_own(str(tid)):
			for m in StoryData.trainer(tid).party:
				assert_true(ids.has(str(m.species)), "%s: %s" % [tid, m.species])
	var wild := {}
	for z in ZONES:
		for kind in ZoneData.load_id(z).encounters:
			for e in ZoneData.load_id(z).encounters[kind]:
				assert_true(ids.has(str(e.species)), "%s: %s" % [z, e.species])
				wild[str(e.species)] = true
	for want in ["foalmoor", "puffling", "rillotter", "selklet"]:
		assert_true(wild.has(want), want)

func _flags_set(cmds: Variant, out: Dictionary) -> void:
	if not cmds is Array:
		return
	for c in cmds:
		if not c is Dictionary:
			continue
		if c.get("do") == "set":
			out[str(c.flag)] = true
		for k in ["then", "else"]:
			_flags_set(c.get(k), out)

func test_every_quest_flag_is_set_somewhere() -> void:
	var set_flags := {}
	var dlg := StoryData.all_dialogue()
	for file in dlg:
		for sid in dlg[file]:
			_flags_set(dlg[file][sid], set_flags)
	var q: Dictionary = _json("res://data/quests/shetland.json")
	assert_true(q.quests.size() >= 2)
	for quest in q.quests:
		var flags := [quest.start_flag, quest.done_flag]
		for st in quest.steps:
			flags.append(st.flag)
		for f in flags:
			assert_true(str(f).begins_with("q_shetland_"), f)
			assert_true(set_flags.has(f), "nobody sets " + str(f))
	var fq := Quests.get_quest("festivals_uphellyaa")
	for f in Quests.flags_of(fq):
		assert_true(set_flags.has(f), "nobody sets " + str(f))

func test_the_judge_battle_is_a_real_trainer() -> void:
	assert_false(StoryData.trainer("shetland_ponyjudge").is_empty())
	assert_true(StoryData.trainer("lerwick_jarl").party.size() >= 6, "the local legend has a full party")

# --- Up Helly Aa ---

func test_up_helly_aa_is_the_last_tuesday_of_january() -> void:
	var e := Festivals.get_event("uphellyaa")
	assert_false(e.is_empty())
	assert_eq(str(e.town), "lerwick")
	assert_eq(Festivals.window_of(e, 2026), [1, 24, 1, 28], "27 January 2026")
	assert_eq(Festivals.window_of(e, 2027), [1, 23, 1, 27], "26 January 2027")
	assert_eq(Festivals.window_of(e, 2028), [1, 22, 1, 26], "25 January 2028")
	assert_eq(Festivals.window_of(e, 2030), [1, 26, 1, 30], "29 January 2030")
	assert_true(Festivals.in_window(e, 1, 27, 2026))
	assert_false(Festivals.in_window(e, 1, 29, 2026))
	assert_false(Festivals.in_window(e, 1, 23, 2026))
	assert_false(Festivals.in_window(e, 2, 3, 2026))

func test_up_helly_aa_people_and_sparks_appear_only_on_the_day() -> void:
	Calendar.set_override("2026-01-27")
	var defs := Festivals.npcs_for("lerwick")
	assert_eq(defs.size(), 1)
	assert_eq(str(defs[0].script), "fest_uphellyaa")
	assert_true(Festivals.cond("fest_uphellyaa"))
	var extra := Festivals.extra_encounters("lerwick", "grass", [{"species": "foalmoor", "min": 80, "max": 80, "weight": 10}])
	assert_eq(extra.size(), 1)
	assert_eq(str(extra[0].species), "kindlet")
	Calendar.set_override("2026-06-10")
	assert_eq(Festivals.npcs_for("lerwick").size(), 0)
	assert_false(Festivals.cond("fest_uphellyaa"))
	Calendar.set_override("")

func test_up_helly_aa_runs_again_next_year_and_the_torch_is_kept_once() -> void:
	var d := GameStateData.new()
	Calendar.set_override("2026-01-27")
	assert_eq(Festivals.rollover(d), [])
	for f in ["q_festivals_uphellyaa_started", "q_festivals_uphellyaa_1", "q_festivals_uphellyaa_2", "q_festivals_uphellyaa_done"]:
		d.set_flag(f)
	Calendar.set_override("2027-01-26")
	assert_true("uphellyaa" in Festivals.rollover(d))
	assert_true(d.flag("q_festivals_uphellyaa_done") == null, "a fresh run in 2027")
	assert_true(d.flag("festivals_souv_uphellyaa") == true, "the torch stays yours")
	assert_eq(Festivals.years_done(d, Festivals.get_event("uphellyaa")), 1)
	Calendar.set_override("")
