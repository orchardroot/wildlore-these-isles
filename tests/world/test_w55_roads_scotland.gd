extends TestCase
## Wave 55 roads-scotland: new roads must never let a player WALK to a place earlier than the story allows, and each
## new road must be a real road (two ends, both ways, wildlife, trainers, plaques, something off the path).
## tests/world/w55_walk_baseline.json is StoryWalk.first_steps of the game before any wave 55 road (outdoor zones only).
## Every outdoor zone of that game must first be reachable at the same story step as before; a new zone may only be
## reachable once at least one place it joins is.

## The zones this session adds, with the existing places each one joins.
const NEW := {
	"southern_upland_way": ["scottish_borders", "galloway"],
	"west_highland_way": ["loch_lomond", "glencoe"],
	"devils_staircase": ["glencoe", "fort_william"],
	"pass_of_brander": ["loch_lomond", "oban"],
	"rob_roy_way": ["central_belt", "dundee"],
	"angus_coast": ["dundee", "aberdeen"],
	"trotternish": ["skye", "portree"],
	"uig_road": ["stornoway", "harris"],
	"scalloway_road": ["lerwick", "shetland_mainland"],
	"the_machars": ["galloway", "cairnryan"],
}

func _baseline() -> Dictionary:
	return JsonUtil.read("res://tests/world/w55_walk_baseline.json")

func test_no_new_road_opens_a_place_early() -> void:
	var all := ZoneData.load_all()
	var base := _baseline()
	assert_true(base.size() > 100, "baseline loaded: %d zones" % base.size())
	var now := StoryWalk.first_steps(all)
	for zid in base:
		if not all.has(zid):
			continue
		assert_eq(int(now.get(zid, 999)), int(base[zid]), "%s is reachable at the same story step as before" % zid)
	for zid in now:
		if all[zid].kind != "interior" and not NEW.has(zid):
			assert_true(base.has(zid), "%s was not walkable at all before, so no road may open it" % zid)
	for zid in NEW:
		assert_true(all.has(zid), "new zone exists: " + zid)
		var earliest := 999
		for j in NEW[zid]:
			earliest = mini(earliest, int(base.get(j, 999)))
		assert_true(int(now.get(zid, 999)) >= earliest, "%s opens no sooner than the places it joins" % zid)
		assert_true(now.has(zid), "%s can be walked to at some point" % zid)

func test_each_road_joins_its_two_places_both_ways() -> void:
	for zid in NEW:
		var z := ZoneData.load_id(zid)
		assert_eq(z.kind, "route", zid)
		assert_eq(z.region, "scotland", zid)
		assert_eq(z.edges.size(), 2, "%s has exactly its two ends" % zid)
		var joined := []
		for side in z.edges:
			var to := str(z.edges[side].to)
			joined.append(to)
			var other := ZoneData.load_id(to)
			var back: String = ZoneData.OPPOSITE[side]
			assert_true(other.edges.has(back), "%s: %s has an edge back on its %s side" % [zid, to, back])
			assert_eq(str(other.edges[back].to), zid, "%s: and it leads here" % to)
			assert_eq(int(other.edges[back].offset), -int(z.edges[side].offset), "%s <-> %s offsets cancel" % [zid, to])
			# every tile of the three-wide road mouth lands on walkable ground the other side
			var mouth := 0
			for i in (z.height if side in ["west", "east"] else z.width):
				var p := _border_tile(z, str(side), i)
				if not z.walkable(p):
					continue
				mouth += 1
				var arrive := z.edge_arrival(str(side), p, other)
				assert_true(other.walkable(arrive), "%s %s end: %s lands on ground in %s" % [zid, side, arrive, to])
			assert_eq(mouth, 3, "%s %s mouth is three tiles wide" % [zid, side])
		joined.sort()
		var want: Array = NEW[zid].duplicate()
		want.sort()
		assert_eq(joined, want, "%s joins the places it says it does" % zid)

func _border_tile(z: ZoneData, side: String, i: int) -> Vector2i:
	match side:
		"north":
			return Vector2i(i, 0)
		"south":
			return Vector2i(i, z.height - 1)
		"west":
			return Vector2i(0, i)
	return Vector2i(z.width - 1, i)

func test_each_road_has_wildlife_trainers_plaques_and_a_nook() -> void:
	var dex := Dex.load_default()
	for zid in NEW:
		var z := ZoneData.load_id(zid)
		var seen := {}
		for table in z.encounters.values():
			for e in table:
				assert_true(dex.has(str(e.species)), "%s: %s is a real species" % [zid, e.species])
				assert_true(int(e.min) >= z.scaled_floor and int(e.max) <= z.scaled_floor + 3, "%s: %s at the par of the places it joins" % [zid, e.species])
				seen[str(e.species)] = true
		assert_true(z.encounters.has("grass") and z.encounters.grass.size() >= 6, "%s: six or more grass entries" % zid)
		assert_true(seen.size() >= 8, "%s: %d species" % [zid, seen.size()])
		var plaques := 0
		for s in z.signs:
			if s.has("plaque") and str(s.get("title", "")) != "":
				plaques += 1
		assert_true(plaques >= 2, "%s: two or more plaques (%d)" % [zid, plaques])
		var trainers := 0
		for n in z.npcs:
			if n.has("trainer"):
				trainers += 1
				var t := StoryData.trainer(str(n.trainer))
				assert_false(t.is_empty(), "%s: trainer %s exists" % [zid, n.trainer])
				for m in t.party:
					assert_true(dex.has(str(m.species)), "%s: %s in %s's party" % [zid, m.species, n.trainer])
		assert_true(trainers >= 3, "%s: three or more trainers (%d)" % [zid, trainers])
		assert_true(Poi.for_zone(zid).size() >= 2, "%s: things to find off the path" % zid)
		var spots := FieldSpots.all().filter(func(s): return str(s.zone) == zid)
		assert_true(spots.size() >= 1, "%s: a field spot" % zid)

func test_the_validator_is_happy_with_the_new_roads_and_the_places_they_cut_into() -> void:
	var all := ZoneData.load_all()
	var dex := Dex.load_default()
	var items := ItemDB.load_default()
	var mine := {}
	for zid in NEW:
		mine[zid] = true
		for j in NEW[zid]:
			mine[j] = true
	var errs := []
	for zid in mine:
		errs.append_array(all[zid].validate(all))
	errs.append_array(Poi.check(all, dex, items).filter(func(e): return _about(str(e), mine)))
	errs.append_array(FieldSpots.check(all, items).filter(func(e): return _about(str(e), mine)))
	errs.append_array(Gazetteer.validate(Gazetteer.all()))
	errs.append_array(WorldConsistency.check(all, StoryData.all_dialogue()).filter(func(e): return _about(JSON.stringify(e), mine)))
	errs.append_array(Coverage.reachability(all, JsonUtil.read("res://data/ferries.json"), Coverage.script_warp_targets()).filter(func(e): return _about(str(e), mine)))
	assert_eq(errs.size(), 0, str(errs.slice(0, 5)))

func _about(text: String, zones: Dictionary) -> bool:
	for z in zones:
		if text.contains(str(z)):
			return true
	return false

func test_no_dash_in_what_the_player_reads() -> void:
	for zid in NEW:
		var z := ZoneData.load_id(zid)
		for s in z.signs:
			assert_false("—" in str(s.text) or "–" in str(s.text), "%s sign at %d,%d" % [zid, s.x, s.y])
		var d: Variant = JsonUtil.read("res://data/dialogue/%s.json" % zid)
		assert_true(d is Dictionary, zid + " has a dialogue file")
		assert_false("—" in JSON.stringify(d) or "–" in JSON.stringify(d), zid + " dialogue")
		for n in z.npcs:
			if n.has("trainer"):
				var t := JSON.stringify(StoryData.trainer(str(n.trainer)))
				assert_false("—" in t or "–" in t, "trainer " + str(n.trainer))
