extends TestCase
## Wave 53 (asks): residents who ask for a sighting or a photograph, dishes and fish, and what goes in a trade file.

func _trade(kind: Dictionary) -> Dictionary:
	return {"id": "tr_w53_t", "zone": "x", "npc": "y", "wants": kind, "gives": {"money": 100}, "ask": "Ask.", "thanks": "Thanks.", "repeat": false}

func test_seen_wants_the_fieldbook() -> void:
	var t := _trade({"kind": "seen", "species": "heronarch"})
	var d := GameStateData.new()
	assert_false(Wants.can_pay(d, t), "an empty Fieldbook has not seen it")
	d.mark_seen("starlet")
	assert_false(Wants.can_pay(d, t), "another species does not do")
	d.mark_seen("heronarch")
	assert_true(Wants.can_pay(d, t), "seen is enough")
	var c := GameStateData.new()
	c.mark_caught("heronarch")
	assert_true(Wants.can_pay(c, t), "caught counts as seen")

func test_photo_wants_the_zone_flag() -> void:
	var t := _trade({"kind": "photo", "zone": "york"})
	var d := GameStateData.new()
	assert_false(Wants.can_pay(d, t))
	Wants.note_photo(d, "bath")
	assert_false(Wants.can_pay(d, t), "a photograph somewhere else does not do")
	Wants.note_photo(d, "york")
	assert_true(Wants.can_pay(d, t))
	assert_eq(d.flag("photo_york"), true)

func test_showing_takes_nothing_and_pays_once() -> void:
	var t := _trade({"kind": "seen", "species": "heronarch"})
	Wants._by_id[t.id] = t
	var d := GameStateData.new()
	d.mark_seen("heronarch")
	d.bag["potatoes"] = 3
	assert_true(Wants.is_open(d, t))
	var line := Wants.pay(d, t)
	assert_true(line.contains("Heronarch"), line)
	assert_eq(d.money, 600)
	assert_eq(d.bag, {"potatoes": 3}, "a sighting costs nothing from the bag")
	assert_false(Wants.is_open(d, t), "a one-off is done")
	Wants._by_id.erase(t.id)

func test_not_seen_gives_nothing() -> void:
	var t := _trade({"kind": "photo", "zone": "york"})
	var d := GameStateData.new()
	assert_eq(Wants.pay(d, t), "")
	assert_eq(d.money, 500, "nothing paid")

func test_prompt_names_the_page() -> void:
	Wants.all()
	var key := "w53box|npc"
	var t := _trade({"kind": "seen", "species": "heronarch"})
	t.zone = "w53box"
	t.npc = "npc"
	Wants._by_npc[key] = [t]
	var d := GameStateData.new()
	var asks: Array = Wants.parts("w53box", "npc", d).asks
	assert_eq(asks.size(), 1, "unmet: a daily ask line, no prompt")
	d.mark_seen("heronarch")
	var offered: Array = Wants.parts("w53box", "npc", d).trade
	assert_eq(str(offered[1].text), "Show them your Heronarch page?")
	assert_eq(str(offered[1].options[0]), "Show them the Heronarch page")
	Wants._by_npc.erase(key)

func test_old_save_has_no_photos() -> void:
	var d := GameStateData.from_dict({}, Dex.load_default())
	assert_false(Wants.can_pay(d, _trade({"kind": "photo", "zone": "york"})), "absent flag = no photograph")
	Wants.note_photo(d, "york")
	var back := GameStateData.from_dict(d.to_dict(), Dex.load_default())
	assert_true(Wants.can_pay(back, _trade({"kind": "photo", "zone": "york"})), "the flag survives a save")

func test_validator_rejects_bad_new_kinds() -> void:
	var zones := ZoneData.load_all()
	var dex := Dex.load_default()
	var items := ItemDB.load_default()
	Wants.all()
	var bad := [_trade({"kind": "seen", "species": "no_such_beast"}), _trade({"kind": "photo", "zone": "no_such_place"}), _trade({"kind": "dance"})]
	for i in bad.size():
		bad[i].id = "tr_w53_bad%d" % i
		bad[i].zone = "bath_home1"
		bad[i].npc = "bath_home1_gran"
		Wants._by_id[bad[i].id] = bad[i]
	var errs := Wants.check(zones, items, dex)
	for i in bad.size():
		Wants._by_id.erase(bad[i].id)
		assert_true(str(errs).contains("tr_w53_bad%d" % i), "caught bad %d: %s" % [i, errs])

func test_the_new_asks() -> void:
	Wants.reset()
	var zones := ZoneData.load_all()
	assert_eq(Wants.check(zones, ItemDB.load_default(), Dex.load_default()), [])
	var items := ItemDB.load_default()
	var per := {"seen": {}, "photo": {}}
	var dishes := 0
	var fish := 0
	for t in Wants.all():
		if not str(t.id).ends_with("_dish_%s" % str(t.wants.get("item", "-"))) and not str(t.id).contains("_seen_") and not str(t.id).contains("_photo_") and not str(t.id).contains("_fish_"):
			continue
		var kind := Wants.kind_of(t)
		if per.has(kind):
			per[kind][Standing.nation_for_zone(str(t.zone))] = int(per[kind].get(Standing.nation_for_zone(str(t.zone)), 0)) + 1
			assert_false(bool(t.repeat), "%s: a sighting or photograph is paid once" % t.id)
			assert_true(int(t.gives.get("money", 0)) <= 250, "%s: modest" % t.id)
		elif str(t.id).contains("_dish_"):
			dishes += 1
			assert_eq(str(items.get_item(str(t.wants.item)).get("kind", "")), "meal", t.id)
			assert_true(bool(t.repeat), "%s: a dish ask is daily" % t.id)
			assert_true(int(t.gives.money) * 2 <= int(items.get_item(str(t.wants.item)).price), "%s: pays less than the dish sells for" % t.id)
		elif str(t.id).contains("_fish_"):
			fish += 1
			assert_eq(str(items.get_item(str(t.wants.item)).get("kind", "")), "fish", t.id)
			assert_false(bool(t.repeat))
			assert_true(int(t.gives.money) <= int(items.get_item(str(t.wants.item)).price) * int(t.wants.n), "%s: no more than market" % t.id)
	for k in per:
		for nation in ["england", "scotland", "wales", "northern_ireland", "ireland"]:
			assert_true(int(per[k].get(nation, 0)) >= 1, "%s asks in %s" % [k, nation])
	assert_true(dishes >= 6 and fish >= 3, "dishes %d fish %d" % [dishes, fish])

func test_no_new_ask_sits_in_a_home_with_an_older_trade() -> void:
	Wants.reset()
	var older := {}
	for t in Wants.all():
		if not str(t.id).contains("_seen_") and not str(t.id).contains("_photo_") and not str(t.id).contains("_dish_") and not str(t.id).contains("_fish_"):
			older[str(t.zone)] = true
	for t in Wants.all():
		if str(t.id).contains("_seen_") or str(t.id).contains("_photo_") or str(t.id).contains("_dish_") or str(t.id).contains("_fish_"):
			assert_false(older.has(str(t.zone)), "%s: that home already has a trade" % t.id)

# ---- indoor folklore

const FOLK := {"brownie": ["scotland"], "gruagach": ["scotland"], "cluricaun": ["ireland"], "bansheen": ["ireland"],
	"bogglet": ["england"], "dresserwight": ["england"], "dishwight": ["england"], "hobling": ["england"],
	"tylwyth": ["wales"], "marilwyd": ["wales"], "pixiedell": ["england"]}

func _indoor_homes() -> Array:
	var out := []
	var zones := ZoneData.load_all()
	for id in zones:
		var z: ZoneData = zones[id]
		if z.encounters.has(IndoorFolk.KIND):
			out.append(z)
	return out

func test_indoor_tables_are_real_folklore_and_gated() -> void:
	var dex := Dex.load_default()
	var homes := _indoor_homes()
	assert_true(homes.size() >= 30, "homes with something living there: %d" % homes.size())
	var species := {}
	for z in homes:
		assert_eq(z.kind, "interior", String(z.id))
		assert_true(String(z.id).contains("home") or String(z.id).contains("house") or String(z.id).contains("cottage") or String(z.id).contains("_h"), "%s is a home" % z.id)
		assert_eq(z.encounters.keys(), [IndoorFolk.KIND], "only an indoor table in %s" % z.id)
		for e in z.encounters.indoor:
			assert_true(dex.has(str(e.species)), "%s: species" % z.id)
			assert_true(FOLK.has(str(e.species)), "%s: %s is not on the folklore list" % [z.id, e.species])
			assert_true(not e.get("time", []).is_empty() or not e.get("weather", []).is_empty() or not e.get("season", []).is_empty(), "%s: gated" % z.id)
			assert_true(int(e.min) >= 1 and int(e.max) >= int(e.min))
			species[str(e.species)] = true
			assert_true(FOLK[str(e.species)].has(Standing.nation_for_zone(String(z.id))), "%s: %s belongs elsewhere" % [z.id, e.species])
	assert_true(species.size() >= 8, "species used: %d" % species.size())

func test_indoor_roll_respects_gates() -> void:
	var z := ZoneData.load_id("llanberis_home2")
	var e: Dictionary = z.encounters.indoor[0]
	var by_day := 0
	var by_night := 0
	var rng := Rng.new(7)
	for i in 4000:
		if not IndoorFolk.roll(z, "day", "clear", rng, {}).is_empty():
			by_day += 1
		var r := IndoorFolk.roll(z, "night", "clear", rng, {})
		if not r.is_empty():
			by_night += 1
			assert_eq(r.species, e.species)
			assert_true(int(r.level) >= int(e.min) and int(r.level) <= int(e.max))
	assert_eq(by_day, 0, "nothing stirs by day")
	assert_true(by_night >= 20 and by_night <= 150, "rare, but it happens: %d in 4000 steps" % by_night)

func test_the_mari_lwyd_only_calls_in_winter() -> void:
	var z := ZoneData.load_id("rhondda_home")
	assert_eq(Encounters.candidates(z, IndoorFolk.KIND, "night", "clear", {}, "winter").size(), 1)
	assert_eq(Encounters.candidates(z, IndoorFolk.KIND, "night", "clear", {}, "summer").size(), 0)

func test_indoor_weather_gate_reads_the_sky_outside() -> void:
	var z := ZoneData.load_id("kerry_cottage")
	var calm := Encounters.candidates(z, IndoorFolk.KIND, "night", "clear", {})
	var gale := Encounters.candidates(z, IndoorFolk.KIND, "night", "gale", {})
	assert_eq(calm.size(), 0)
	assert_eq(gale.size(), 1)

func test_outdoor_zones_are_left_alone() -> void:
	var z := ZoneData.load_id("macclesfield")
	assert_eq(IndoorFolk.roll(z, "night", "clear", Rng.new(1), {}), {})

# ---- the family drawer

func _homes() -> Array:
	var out := []
	var zones := ZoneData.load_all()
	var rx := RegEx.create_from_string("_h\\d+$")
	for id in zones:
		var z: ZoneData = zones[id]
		if z.kind == "interior" and id != "testbed_house" and (id.contains("home") or id.contains("house") or id.contains("cottage") or rx.search(id) != null):
			out.append(z)
	return out

func test_every_home_has_a_drawer() -> void:
	var missing := []
	var unreachable := []
	for z in _homes():
		if FamilyDrawer.entry(String(z.id)).is_empty():
			missing.append(String(z.id))
		elif FamilyDrawer.prop_for(z).is_empty():
			unreachable.append(String(z.id))
	assert_eq(missing, [], "homes without a drawer")
	assert_true(unreachable.size() <= 8, "homes with nothing to search: %s" % [unreachable])
	assert_eq(FamilyDrawer.check(ZoneData.load_all(), ItemDB.load_default()), [])

func test_drawer_is_found_once_then_the_lottery_resumes() -> void:
	var z := ZoneData.load_id("macc_home")
	var items := ItemDB.load_default()
	var d := GameStateData.new()
	var p := FamilyDrawer.prop_for(z)
	assert_false(p.is_empty())
	assert_false(FamilyDrawer.found(d, "macc_home"), "an old save has not found it")
	assert_true(FamilyDrawer.is_drawer(z, p, d))
	var r := Search.take(z, p, d, items)
	assert_eq(r.lines.size() >= 2, true)
	assert_true(FamilyDrawer.found(d, "macc_home"))
	assert_eq(r.lines[0], FamilyDrawer.entry("macc_home").lines[0])
	assert_false(FamilyDrawer.is_drawer(z, p, d), "only once")
	assert_eq(FamilyDrawer.found_count(d), 1)
	var again := Search.take(z, p, d, items)
	assert_false(again.lines.has(FamilyDrawer.entry("macc_home").lines[0]), "the ordinary drawer now")
	assert_false(Search.searched(GameStateData.new(), "macc_home", int(p.x), int(p.y)))

func test_drawer_curio_goes_in_the_bag() -> void:
	var items := ItemDB.load_default()
	var tested := 0
	for z in _homes():
		var e := FamilyDrawer.entry(String(z.id))
		if str(e.get("curio", "")) == "" or FamilyDrawer.prop_for(z).is_empty():
			continue
		var d := GameStateData.new()
		var r := Search.take(z, FamilyDrawer.prop_for(z), d, items)
		assert_true(r.curio and r.gave)
		assert_eq(int(d.bag.get(str(e.curio), 0)), 1)
		assert_eq(d.flag(Search.FOUND_PREFIX + str(e.curio)), true)
		tested += 1
		if tested >= 5:
			break
	assert_eq(tested, 5)

func test_drawer_never_sits_under_an_examine_spot() -> void:
	for z in _homes():
		var p := FamilyDrawer.prop_for(z)
		if not p.is_empty():
			assert_true(z.examine_at(Vector2i(int(p.x), int(p.y))).is_empty(), String(z.id))
