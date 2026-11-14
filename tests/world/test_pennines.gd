extends TestCase
## The South Pennines and Leeds (wave 21, region "pennines"): Saddleworth Moor off Manchester's east side, Leeds
## beyond it and Haworth north of Leeds, a cul-de-sac off the main line that scales with the story.

const OUTDOOR := ["saddleworth_moor", "leeds", "haworth"]
const QUESTS := "res://data/quests/pennines.json"

func _all() -> Dictionary:
	return ZoneData.load_all()

func test_zones_load_clean() -> void:
	var all := _all()
	for zid in OUTDOOR:
		assert_true(all.has(zid), zid)
		assert_eq(all[zid].validate(all), [], zid)
	for zid in all:
		if zid.begins_with("leeds_") or zid.begins_with("haworth_") or zid in ["saddleworth_museum", "saddleworth_bandroom", "standedge_tunnel", "standedge_visitor"]:
			assert_eq(all[zid].validate(all), [], zid)

func test_joined_at_manchester_only() -> void:
	var all := _all()
	assert_eq(all.manchester.edges.east.to, "saddleworth_moor", "Manchester opens east on to the moor")
	assert_eq(all.saddleworth_moor.edges.west.to, "manchester")
	assert_eq(all.saddleworth_moor.edges.east.to, "leeds")
	assert_eq(all.leeds.edges.west.to, "saddleworth_moor")
	assert_eq(all.leeds.edges.north.to, "haworth")
	assert_eq(all.haworth.edges.keys(), ["south", "west"], "Haworth is the end of the road, bar the wave 55 road over Pendle Hill")
	# no shortcut back into the existing world: every edge out of the region stays inside it, bar Manchester's
	# and wave 55's Pendle Hill road (Haworth west, same story step as Blackpool, see test_w55_roads_england)
	for zid in OUTDOOR:
		for side in all[zid].edges:
			var to: String = all[zid].edges[side].to
			var lease := not Leases.in_zone(to).is_empty()  # an Enclosure lease is a cul-de-sac off the moor (Leases)
			assert_true(to in OUTDOOR or to == "manchester" or lease or to == "pendle_hill", "%s %s edge goes to %s" % [zid, side, to])

func test_scaled_to_manchester_band() -> void:
	var all := _all()
	for zid in OUTDOOR:
		assert_eq(all[zid].scaled_floor, 14, zid)
		assert_eq(all[zid].region, "yorkshire", zid)
	for tid in StoryData.trainer_ids():
		if tid.begins_with("pennines_"):
			assert_eq(int(StoryData.trainer(tid).get("scaled_floor", -1)), 14, tid)

func test_towns_on_the_map() -> void:
	var m := Travel.world_map()
	assert_true(m.towns.has("leeds"))
	assert_true(m.towns.has("haworth"))
	assert_true(m.places.has("saddleworth_moor"))
	assert_true(_all().leeds.station != Vector2i(-1, -1), "Leeds is on the rail network")

func test_plaques_unique_and_plenty() -> void:
	var all := _all()
	var seen := {}
	var per_zone := {}
	for zid in all:
		for s in all[zid].signs:
			if s.has("plaque"):
				assert_false(seen.has(s.plaque), "plaque id %s used twice" % s.plaque)
				seen[s.plaque] = true
				assert_true(str(s.get("title", "")) != "", "%s has a title" % s.plaque)
				if str(s.plaque).begins_with("pennines_"):
					var outer: String = zid if zid in OUTDOOR else ("leeds" if zid.begins_with("leeds_") else ("haworth" if zid.begins_with("haworth_") else "saddleworth_moor"))
					per_zone[outer] = int(per_zone.get(outer, 0)) + 1
					assert_false("—" in str(s.text), "no em-dashes in %s" % s.plaque)
	assert_true(int(per_zone.get("saddleworth_moor", 0)) >= 3, "moor plaques")
	assert_true(int(per_zone.get("leeds", 0)) >= 8, "Leeds plaques")
	assert_true(int(per_zone.get("haworth", 0)) >= 8, "Haworth plaques")

func test_every_quest_flag_is_set_somewhere() -> void:
	var q: Dictionary = JsonUtil.read(QUESTS)
	assert_true(q.quests.size() >= 2)
	var set_flags := {}
	var dialogue := StoryData.all_dialogue()
	for file in dialogue:
		for sid in dialogue[file]:
			_collect_sets(dialogue[file][sid], set_flags)
	for quest in q.quests:
		var flags := [str(quest.start_flag), str(quest.done_flag)]
		for st in quest.steps:
			flags.append(str(st.flag))
			assert_true(_all().has(str(st.zone)), "step zone %s" % st.zone)
		for f in flags:
			assert_true(f.begins_with("q_pennines_"), f)
			assert_true(set_flags.has(f), "%s is never set" % f)

func _collect_sets(cmds: Variant, out: Dictionary) -> void:
	if not cmds is Array:
		return
	for c in cmds:
		if not c is Dictionary:
			continue
		if str(c.get("do", "")) == "set":
			out[str(c.flag)] = true
		for k in ["then", "else"]:
			_collect_sets(c.get(k), out)

func test_whit_friday_runs_end_to_end() -> void:
	var h := FakeStoryHost.new()
	h.zone = "saddleworth_bandroom"
	var sec := StoryData.script("saddleworth_bandroom", "band_secretary")
	await Commands.new(h).run(sec)
	assert_true(h.data.flag("q_pennines_whit_started"))
	await Commands.new(h).run(StoryData.script("saddleworth_moor", "whit_cornet"))
	assert_true(h.data.flag("q_pennines_whit_cornet"))
	await Commands.new(h).run(StoryData.script("saddleworth_moor", "whit_tuba"))
	assert_false(h.data.flag("q_pennines_whit_tuba") == true, "he wants to see a mountain hare first")
	h.data.party.append(Fixtures.creature("snowhare", 15))
	await Commands.new(h).run(StoryData.script("saddleworth_moor", "whit_tuba"))
	assert_true(h.data.flag("q_pennines_whit_tuba"))
	await Commands.new(h).run(StoryData.script("standedge_tunnel", "whit_drummer"))
	assert_true(h.data.flag("q_pennines_whit_drum"))
	await Commands.new(h).run(sec)  # the fake host wins every battle
	assert_true(h.data.flag("q_pennines_whit_done"))
	assert_true(int(h.data.bag.get("whit_rosette", 0)) == 1)

func test_new_species_are_placed() -> void:
	var all := _all()
	var placed := {}
	for zid in OUTDOOR:
		for kind in all[zid].encounters:
			for e in all[zid].encounters[kind]:
				placed[str(e.species)] = true
	for sp in ["tootlet", "hobling", "forcelet", "hobthrust", "snowhare"]:
		assert_true(placed.has(sp), sp)

func test_zones_build() -> void:
	var all := _all()
	for zid in OUTDOOR:
		var root := ZoneBuilder.build(all[zid])
		assert_true(root.get_child_count() > 0, zid)
		root.free()
