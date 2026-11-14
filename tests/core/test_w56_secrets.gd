extends TestCase
## Wave 56, secrets: the hidden places (core/secrets.gd, data/secrets.json). Each one is a small room behind a `hidden`
## warp: it is not there until its reveal flag is set (by an examine spot, a resident's rumour, a bottle, the dawn), it
## can be entered once it is, it counts as found only when you have been in, and an old save sees none of it.

func _zones() -> Dictionary:
	return ZoneData.load_all()

func _idx() -> Dictionary:
	return ZoneIndex.get_index()

func _party(d: GameStateData) -> void:
	d.party = [Fixtures.creature("pepperling", 5), Fixtures.creature("pepperling", 6)]

func _warp(zones: Dictionary, s: Dictionary) -> Dictionary:
	return (zones[str(s.at)] as ZoneData).warp_at(Secrets.tile(s))

func test_there_are_fifteen_and_the_data_lines_up() -> void:
	assert_eq(Secrets.all().size(), 15, "fifteen hidden places")
	var zones := _zones()
	assert_eq(Secrets.problems(zones, Quests.all_settable(), ItemDB.load_default(), Fixtures.dex()), [])

func test_they_are_spread_and_some_need_the_coracle() -> void:
	var coracle := 0
	var sea := 0
	var nations := {}
	var zones := _zones()
	for s in Secrets.all():
		nations[str(s.nation)] = true
		if bool(s.get("coracle", false)):
			coracle += 1
			if (zones[str(s.at)] as ZoneData).tile_at(Secrets.tile(s)) == "sea":
				sea += 1
	assert_true(coracle >= 5, "at least five need the coracle (%d)" % coracle)
	assert_true(sea >= 2, "at least two on the near-shore sea (%d)" % sea)
	assert_true(nations.size() >= 5, "spread over the nations (%s)" % str(nations.keys()))

func test_the_way_in_is_hidden_until_the_reveal() -> void:
	var zones := _zones()
	for s in Secrets.all():
		var w := _warp(zones, s)
		assert_false(w.is_empty(), "%s: a warp at its tile" % s.id)
		assert_eq(str(w.get("to", "")), str(s.zone))
		assert_eq(ZoneData.warp_state(w, GameStateData.new()), "hidden", "%s: hidden at the start" % s.id)
		var d := GameStateData.new()
		d.set_flag(str(s.reveal))
		assert_eq(ZoneData.warp_state(w, d), "open", "%s: open once revealed" % s.id)

func test_nothing_else_leads_in() -> void:
	var zones := _zones()
	var dialogue := JSON.stringify(StoryData.all_dialogue())
	for s in Secrets.all():
		var ways := 0
		for zid in zones:
			for w in (zones[zid] as ZoneData).warps:
				if str(w.get("to", "")) == str(s.zone):
					ways += 1
			for e in (zones[zid] as ZoneData).edges.values():
				assert_ne_str(str(e.get("to", "")), str(s.zone), "%s: no edge leads in" % s.id)
		assert_eq(ways, 1, "%s: one way in" % s.id)
		assert_false(dialogue.contains('"zone": "%s"' % s.zone), "%s: no script warps you there" % s.id)

func assert_ne_str(a: String, b: String, msg := "") -> void:
	if a == b:
		fail("%s expected not <%s>" % [msg, b])

func test_foot_places_are_walked_to_and_coracle_places_are_paddled_to() -> void:
	var zones := _zones()
	for s in Secrets.all():
		var outer: ZoneData = zones[str(s.at)]
		var at := Secrets.tile(s)
		var foot := outer.reachable(outer.spawn, ZoneData.GATE_ABILITIES)
		var afloat := outer.reachable(outer.spawn, ZoneData.CORACLE_ABILITIES)
		var w := _warp(zones, s)
		var back := Vector2i(int(zones[str(s.zone)].warps[0].tx), int(zones[str(s.zone)].warps[0].ty))
		assert_true(foot.has(back), "%s: you step out on to land you can walk to" % s.id)
		assert_true(afloat.has(at), "%s: reachable with the rides" % s.id)
		if bool(s.get("coracle", false)):
			assert_true(bool(w.get("coracle", false)))
			assert_false(foot.has(at), "%s: not on foot" % s.id)
		else:
			assert_true(foot.has(at), "%s: on foot" % s.id)

func test_the_reveal_can_happen() -> void:
	var zones := _zones()
	var settable := Quests.all_settable()
	for s in Secrets.all():
		assert_true(settable.has(str(s.reveal)), "%s: something sets %s" % [s.id, s.reveal])
		var outer: ZoneData = zones[str(s.at)]
		var spots := outer.examine.filter(func(e): return str(e.get("flag", "")) == str(s.reveal))
		match str(s.how):
			"examine", "bottle", "dawn":
				assert_eq(spots.size(), 1, "%s: one spot reveals it" % s.id)
				var d := GameStateData.new()
				Examine.read(d, str(s.at), spots[0], null)
				assert_true(Secrets.revealed(d, s), "%s: reading the spot reveals it" % s.id)
				if str(s.how) == "dawn":
					assert_eq(spots[0].phase, ["dawn"])
					assert_true(spots[0].has("off"), "a line for the wrong hour")
			"rumour":
				assert_eq(spots.size(), 0)
		# and somebody is there to point the way
		var told := outer.npcs.filter(func(n): return str(n.get("id", "")).begins_with("sec_") and StoryData.all_dialogue().get(str(s.at), {}).has(str(n.script)))
		assert_true(told.size() >= 1, "%s: a resident has something to say" % s.id)

func test_a_rumour_sets_the_flag_when_told() -> void:
	for s in Secrets.all():
		if str(s.how) != "rumour":
			continue
		var script: Array = StoryData.all_dialogue()[str(s.at)].get(_resident(s), [])
		assert_true(JSON.stringify(script).contains('"flag": "%s", "value": true' % str(s.reveal)) or JSON.stringify(script).contains(str(s.reveal)), "%s: the telling sets it" % s.id)

func _resident(s: Dictionary) -> String:
	for n in (ZoneData.load_id(str(s.at)) as ZoneData).npcs:
		if str(n.get("id", "")).begins_with("sec_") and StoryData.all_dialogue().get(str(s.at), {}).has(str(n.script)):
			return str(n.script)
	return ""

func test_going_in_is_a_hidden_place_card_paid_once() -> void:
	var s: Dictionary = Secrets.all()[0]
	var d := GameStateData.new()
	_party(d)
	var before: int = d.party[0].friendship
	var room := ZoneData.load_id(str(s.zone))
	var card := Discovery.note(d, room, _idx())
	assert_eq(card.label, "HIDDEN PLACE")
	assert_eq(card.count, 1)
	assert_eq(card.total, Secrets.all().size())
	assert_true(str(card.gain) != "" and str(card.sub) != "")
	assert_true(Secrets.found(d, s))
	assert_eq(d.party[0].friendship, before + Discovery.FRIENDSHIP, "the party is pleased")
	assert_eq(Discovery.take(str(s.zone)).zone, str(s.zone), "held for the zone card")
	assert_true(Discovery.note(d, room, _idx()).is_empty(), "never twice")
	assert_eq(d.party[0].friendship, before + Discovery.FRIENDSHIP, "no second reward")
	assert_eq(Discovery.tally(d, _idx()).x, 0, "a hidden place is not in the places tally")

func test_hidden_places_are_not_rooms_or_places() -> void:
	var idx := _idx()
	var places := Discovery.places(idx)
	for s in Secrets.all():
		assert_false(str(s.zone) in places)
		assert_false(idx.room_town.has(str(s.zone)), "%s is no room of a town" % s.id)
	var c := Atlas.contents(idx)
	for r in c:
		for s in Secrets.all():
			assert_false(str(s.zone) in c[r].rooms, "not a room in the Atlas")

func test_the_sense_cue_calls_you_over_once_it_is_revealed() -> void:
	var zones := _zones()
	for s in Secrets.all():
		var outer: ZoneData = zones[str(s.at)]
		var at := Secrets.tile(s)
		var d := GameStateData.new()
		var list := Discovery.nearby_unfound(outer, at, d).filter(func(n): return n.kind == "secret")
		assert_eq(list.size(), 0, "%s: nothing to sense before the reveal" % s.id)
		d.set_flag(str(s.reveal))
		list = Discovery.nearby_unfound(outer, at, d).filter(func(n): return n.kind == "secret")
		assert_eq(list.size(), 1, "%s: sensed once revealed" % s.id)
		assert_eq(list[0].id, str(s.id))
		assert_eq(list[0].at, at)
		var far := Discovery.nearby_unfound(outer, at + Vector2i(Discovery.SENSE_RANGE + 1, 0), d).filter(func(n): return n.kind == "secret")
		assert_eq(far.size(), 0, "%s: out of range" % s.id)
		d.set_flag(Discovery.sensed_key(str(s.id)))
		assert_eq(Discovery.nearby_unfound(outer, at, d).filter(func(n): return n.kind == "secret").size(), 0, "once per find")
		var d2 := GameStateData.new()
		d2.set_flag(str(s.reveal))
		d2.set_flag(Discovery.found_key(str(s.zone)))
		assert_eq(Discovery.nearby_unfound(outer, at, d2).filter(func(n): return n.kind == "secret").size(), 0, "been in: no more calling")

func test_the_map_marks_it_once_known_and_ticks_it_once_found() -> void:
	var s: Dictionary = Secrets.all()[0]
	var d := GameStateData.new()
	assert_eq(Secrets.marks(d), [], "unknown: no mark")
	d.set_flag(str(s.reveal))
	var m := Secrets.marks(d)
	assert_eq(m.size(), 1)
	assert_eq(m[0].kind, "secret")
	assert_eq(m[0].at, str(s.at))
	assert_false(m[0].done)
	assert_true(m[0].ring)
	assert_eq(MapLogic.marks(d, {}).filter(func(k): return k.kind == "secret").size(), 1, "the map draws it")
	d.set_flag(Discovery.found_key(str(s.zone)))
	assert_true(Secrets.marks(d)[0].done)
	var p := MapLogic.mark_point({"at": str(s.at)})
	assert_true(p.x >= 0.0, "the place that hides it has a spot on the map")

func test_the_atlas_counts_hidden_places() -> void:
	var d := GameStateData.new()
	var n := Secrets.all().size()
	assert_eq(Secrets.line(d), "hidden places 0 of %d" % n)
	var s: Dictionary = Secrets.all()[0]
	d.set_flag(Discovery.found_key(str(s.zone)))
	assert_eq(Secrets.line(d), "hidden places 1 of %d" % n)
	var region := str(_idx().zones[str(s.at)].region)
	var rows := Atlas.hidden_rows(d, _idx(), region)
	assert_eq(rows.size(), 1)
	assert_eq(rows[0].label, "Hidden places")
	assert_true(rows[0].got >= 1 and rows[0].total >= rows[0].got)
	assert_eq(Atlas.rows(d, _idx(), region).filter(func(r): return r.key == "hidden"), [], "the stamp does not wait on one")
	var total := 0
	for r in ZoneIndex.get_index().adj:
		total += Secrets.tally_in(d, _idx(), str(r)).y
	assert_true(total >= n - 2, "every place is in some region")

func test_old_saves_see_nothing_and_are_not_paid() -> void:
	var d := GameStateData.from_dict(GameStateData.new().to_dict(), Fixtures.dex())
	Discovery.catch_up(d, _idx())
	for s in Secrets.all():
		assert_false(Secrets.revealed(d, s))
		assert_false(Secrets.found(d, s))
	assert_eq(Secrets.marks(d), [])
	d.play_seconds = 9000.0
	d.set_flag("disc_init", null)
	Discovery.catch_up(d, _idx())
	assert_eq(Secrets.tally(d).x, 0, "catching up never finds a hidden place for you")

func test_each_place_holds_something_that_is_not_money() -> void:
	var zones := _zones()
	var items := ItemDB.load_default()
	var kinds := {}
	for s in Secrets.all():
		kinds[str(s.reward)] = true
		var room: ZoneData = zones[str(s.zone)]
		assert_true(room.signs.size() >= 1 and str(room.signs[0].text).length() > 80, "%s: a plaque" % s.id)
		assert_true(room.examine.size() >= 1, "%s: examine text" % s.id)
		match str(s.reward):
			"creature":
				var pup := room.npcs.filter(func(n): return str(n.get("sprite", "")) == "creature:" + str(s.species))
				assert_eq(pup.size(), 1, "%s: the creature is there" % s.id)
				assert_eq(pup[0].hide_if, str(s.zone) + "_got", "gone once it is yours")
				var script: Array = JsonUtil.read("res://data/dialogue/%s.json" % s.zone)[str(pup[0].script)]
				assert_true(script.any(func(c): return c.get("do") == "give_creature" and c.species == str(s.species) and c.has("scaled_floor")), "%s: it joins you, at the par of the place" % s.id)
				assert_true(Fixtures.dex().has(str(s.species)))
			"chapbook", "curio":
				var finds := room.examine.filter(func(e): return e.get("find") is Dictionary and str(e.find.item) == str(s.item))
				assert_eq(finds.size(), 1, "%s: the %s is lying there" % [s.id, s.reward])
				var kind := str(items.get_item(str(s.item)).get("kind", ""))
				assert_eq(kind, str(s.reward))
			"letter":
				var papers := Letters.at(str(s.zone))
				assert_eq(papers.size(), 1, "%s: a letter on the table" % s.id)
				assert_true(Letters.has_trail(papers[0]), "which starts a trail")
				assert_true(Letters.prop_for(room) != Letters.NONE, "a table to lay it on")
			"view":
				assert_eq(room.examine.filter(func(e): return str(e.get("flag", "")) == str(s.zone) + "_viewed").size(), 1, "%s: a view" % s.id)
	assert_true(kinds.has("creature") and kinds.has("chapbook") and kinds.has("curio") and kinds.has("view") and kinds.has("letter"), "a mix of rewards: %s" % str(kinds.keys()))

func test_a_curio_found_in_the_field_goes_on_the_curios_page() -> void:
	var items := ItemDB.load_default()
	var id := str(Search.curio_ids()[0])
	var d := GameStateData.new()
	var res := Examine.read(d, "somewhere", {"x": 1, "y": 1, "text": ["A thing."], "find": {"item": id}}, items)
	assert_true(res.gave)
	assert_true(Search.found(d).has(id), "on the Curios page")
	assert_eq(int(d.bag.get(id, 0)), 1)

func test_no_dashes_and_lines_that_fit_the_box() -> void:
	var zones := _zones()
	var texts := []
	for s in Secrets.all():
		var room: ZoneData = zones[str(s.zone)]
		for e in room.examine:
			texts.append_array(e.text)
		for g in room.signs:
			texts.append(str(g.text))
		var outer: ZoneData = zones[str(s.at)]
		for e in outer.examine:
			if str(e.get("flag", "")) == str(s.reveal):
				texts.append_array(e.text)
				texts.append_array(e.get("off", []))
		var files := [str(s.at), str(s.zone)]
		for f in files:
			var path := "res://data/dialogue/%s.json" % f
			if FileAccess.file_exists(path):
				var d: Dictionary = JsonUtil.read(path)
				for k in d:
					if k.begins_with("sec_") or k.begins_with("secret_"):
						_says(d[k], texts)
	for t in texts:
		assert_false("—" in str(t) or "–" in str(t), "no dashes: " + str(t))
		assert_false('"' in str(t), "no double quotes: " + str(t))
		assert_true(str(t).length() <= 260, "fits: " + str(t))

func _says(cmds: Array, into: Array) -> void:
	for c in cmds:
		if c.get("do") == "say":
			assert_true(str(c.text).length() <= 150, "a line that fits two lines: " + str(c.text))
			into.append(str(c.text))
		for k in ["then", "else"]:
			if c.has(k):
				_says(c[k], into)
