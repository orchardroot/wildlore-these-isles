extends TestCase
## Town projects (core/town_projects.gd, wave 55): fifteen things a town needs, paid for a stage at a time, and what each
## changes for good. Stages, costs by par, the resident's words, old saves, the hidden warps that open, the Deeds that
## gain, and that the money goes through the Wallet.

func _data(badges := 8, cash := 2000000) -> GameStateData:
	var d := GameStateData.new()
	d.money = cash
	d.euros = 0
	d.day_count = 100
	d.rng_seed = 99
	d.player_name = "Sam"
	for i in badges:
		d.badges.append("b%d" % i)
	return d

func _finish(d: GameStateData, id: String) -> void:
	if TownProjects.started(d, id):
		d.day_count += 60   # let whatever is already building finish first
	assert_eq(TownProjects.fund_all(d, id), "")
	d.day_count += 60
	TownProjects.tick(d, d.day_count)

func test_the_data_is_sound() -> void:
	var zones := ZoneData.load_all()
	assert_eq(TownProjects.problems(zones, ItemDB.load_default()), [], "no problems")
	assert_eq(TownProjects.all().size(), 15)

func test_fifteen_towns_across_every_nation() -> void:
	var towns := {}
	var nations := {}
	for p in TownProjects.all():
		assert_false(towns.has(str(p.zone)), "one project a town: " + str(p.zone))
		towns[str(p.zone)] = true
		nations[Standing.nation_for_zone(str(p.zone))] = int(nations.get(Standing.nation_for_zone(str(p.zone)), 0)) + 1
	for n in ["england", "scotland", "wales", "ireland", "northern_ireland"]:
		assert_true(int(nations.get(n, 0)) >= 1, "a project in " + n)
	assert_true(int(nations.get("england", 0)) >= 5)

func test_nothing_is_done_or_started_on_a_new_save() -> void:
	var d := GameStateData.new()
	for p in TownProjects.all():
		var id := str(p.id)
		assert_false(TownProjects.is_done(d, id))
		assert_false(TownProjects.started(d, id))
		assert_eq(TownProjects.days_left(d, id), 0)
	assert_eq(TownProjects.done_ids(d), [])
	assert_eq(TownProjects.plaques(d), [])
	assert_true(TownProjects.tick(d, 500).is_empty(), "the daily tick has nothing to do")

# --- money -----------------------------------------------------------------------------------------

func test_costs_scale_with_the_story_like_jobs_do() -> void:
	var early := _data()
	var late := _data()
	early.set_flag("starter", true)
	late.set_flag("game_complete", true)
	var p := TownProjects.get_project("whitby_lifeboat")
	assert_true(TownProjects.cost_left(early, p) < TownProjects.cost_left(late, p) / 2, "a late visit is dearer")
	var mid := _data()
	mid.set_flag("badge_tide", true)   # par 60
	assert_true(absi(TownProjects.cost_left(mid, p) - int(p.cost)) <= 150, "the figure in the data is the cost at par 60")
	for q in TownProjects.all():
		var total := 0
		for s in (q.stages as Array).size():
			total += TownProjects.cost_at(q, s, 1.0)
		assert_true(absi(total - int(q.cost)) <= 150, "%s stages add up to its cost: %d vs %d" % [q.id, total, q.cost])
		assert_eq(TownProjects.cost_at(q, 0, 1.0) % TownProjects.ROUND, 0, "rounded to the nearest fifty")

func test_the_total_is_a_proper_sink() -> void:
	var d := _data()
	d.set_flag("game_complete", true)
	var late := 0
	var mid := _data()
	mid.set_flag("badge_tide", true)
	var base := 0
	for p in TownProjects.all():
		late += TownProjects.cost_left(d, p)
		base += TownProjects.cost_left(mid, p)
	assert_true(base >= 280000 and base <= 400000, "about three hundred thousand at par 60: %d" % base)
	assert_true(late > base, "and more at the credits: %d" % late)

func test_paying_a_stage_goes_through_the_wallet_in_the_towns_money() -> void:
	var d := _data()
	var p := TownProjects.get_project("dingle_pier")
	assert_eq(TownProjects.cur_of(p), Wallet.EUR)
	assert_true(TownProjects.fund(d, "dingle_pier") != "", "no euros in the purse yet")
	d.set_flag("badge_tide", true)
	var gbp := TownProjects.stage_cost(d, p, 0)
	d.euros = Wallet.localise(gbp, Wallet.EUR) + 5
	assert_eq(TownProjects.fund(d, "dingle_pier"), "")
	assert_eq(d.euros, 5)
	var q := TownProjects.get_project("whitby_lifeboat")
	var before := d.money
	assert_eq(TownProjects.fund(d, "whitby_lifeboat"), "")
	assert_eq(before - d.money, TownProjects.stage_cost(d, q, 0), "sterling for an English town")

func test_a_project_is_not_open_until_you_have_the_stones() -> void:
	var d := _data(0)
	var p := TownProjects.get_project("whitby_lifeboat")
	assert_false(TownProjects.available(d, p))
	assert_true(TownProjects.fund(d, "whitby_lifeboat") != "")
	assert_eq(d.money, 2000000, "nothing taken")
	var q := TownProjects.get_project("kirkwall_ferry")
	assert_true(int(q.badges) >= 8, "Scotland's far north waits for the late game")

# --- the stages ---------------------------------------------------------------------------------------

func test_a_stage_at_a_time_with_the_work_taking_its_days() -> void:
	var d := _data()
	var id := "carlisle_library"
	var p := TownProjects.get_project(id)
	assert_eq(TownProjects.fund(d, id), "")
	assert_eq(TownProjects.stages_paid(d, id), 1)
	assert_true(TownProjects.started(d, id))
	assert_true(TownProjects.fund(d, id) != "", "the first stage is still being built")
	assert_true(TownProjects.days_left(d, id) > 0)
	assert_false(TownProjects.is_done(d, id))
	d.day_count += TownProjects.days_left(d, id)
	assert_eq(TownProjects.fund(d, id), "")
	d.day_count += 20
	assert_eq(TownProjects.fund(d, id), "")
	assert_eq(TownProjects.stages_paid(d, id), (p.stages as Array).size())
	assert_false(TownProjects.is_done(d, id), "paid for, not yet built")
	assert_true(TownProjects.fund(d, id) != "", "nothing left to pay")
	d.day_count += 20
	var lines := TownProjects.tick(d, d.day_count)
	assert_true(TownProjects.is_done(d, id))
	assert_true(lines.size() >= 1, "the wireless says so")
	assert_true(TownProjects.tick(d, d.day_count + 5).is_empty(), "and only the once")
	assert_true(ZoneData.flag_on(d.flag("project_carlisle_library")), "the flag a gate or a warp can read")

func test_paying_everything_at_once_still_takes_its_time() -> void:
	var d := _data()
	var p := TownProjects.get_project("york_floodgate")
	var cost := TownProjects.cost_left(d, p)
	var before := d.money
	assert_eq(TownProjects.fund_all(d, "york_floodgate"), "")
	assert_eq(before - d.money, cost)
	assert_false(TownProjects.is_done(d, "york_floodgate"))
	var days := 0
	for s in (p.stages as Array).size():
		days += int(p.stages[s].days)
	assert_eq(TownProjects.days_left(d, "york_floodgate"), days)
	d.day_count += days - 1
	TownProjects.tick(d, d.day_count)
	assert_false(TownProjects.is_done(d, "york_floodgate"))
	d.day_count += 1
	TownProjects.tick(d, d.day_count)
	assert_true(TownProjects.is_done(d, "york_floodgate"))

func test_a_stage_costs_what_it_cost_when_you_paid_it() -> void:
	var d := _data()
	var p := TownProjects.get_project("carlisle_library")
	var first := TownProjects.stage_cost(d, p, 0)
	TownProjects.fund(d, "carlisle_library")
	assert_eq(int(TownProjects.state(d, "carlisle_library").paid), first)
	d.set_flag("game_complete", true)
	assert_eq(int(TownProjects.state(d, "carlisle_library").paid), first, "the story moving on does not change what you paid")

func test_finishing_raises_standing_gives_the_keepsake_and_puts_a_name_on_the_plaque() -> void:
	var d := _data()
	d.player_name = "Rowan"
	var nation := Standing.nation_for_zone("whitby")
	var before := Standing.points(d, nation)
	_finish(d, "whitby_lifeboat")
	assert_true(TownProjects.is_done(d, "whitby_lifeboat"))
	assert_eq(Standing.points(d, nation), before + 8)
	assert_eq(int(d.bag.get("parkin", 0)), 1, "a keepsake, once")
	var p := TownProjects.get_project("whitby_lifeboat")
	assert_true(TownProjects.plaque(d, p).contains("Rowan"))
	d.player_name = "Someone Else"
	assert_true(TownProjects.plaque(d, p).contains("Rowan"), "the name is the one on the day")
	assert_eq(TownProjects.plaques(d).size(), 1)

# --- the town and its people --------------------------------------------------------------------------

func test_the_resident_speaks_for_the_project_in_three_voices() -> void:
	var d := _data()
	var p := TownProjects.get_project("whitby_lifeboat")
	var base: Array = [{"do": "say", "who": "", "text": "Morning."}]
	var asked := TownProjects.hook("whitby", str(p.npc), base, d)
	assert_true(asked.size() > base.size())
	assert_eq(str(asked[asked.size() - 1].do), "project", "and a way to the plans")
	assert_true(str(asked[1].text).contains("Sam"), "{player} is filled in")
	TownProjects.fund(d, "whitby_lifeboat")
	var going := TownProjects.hook("whitby", str(p.npc), base, d)
	assert_eq(str(going[going.size() - 1].do), "project")
	assert_true(str(going[1].text) != str(asked[1].text), "a different word while it is being built")
	_finish(d, "whitby_lifeboat")
	var done := TownProjects.hook("whitby", str(p.npc), base, d)
	assert_true(done.size() > base.size())
	assert_true(str(done[done.size() - 1].get("do", "")) != "project", "nothing left to pay for")
	assert_eq(TownProjects.hook("whitby", "someone_else", base, d), base, "nobody else says a word")
	assert_eq(TownProjects.hook("york", str(p.npc), base, d), base, "the right town")

func test_the_resident_says_nothing_until_it_is_open_to_you() -> void:
	var d := _data(0)
	for p in TownProjects.all():
		var base: Array = [{"do": "say", "who": "", "text": "Hello."}]
		if int(p.badges) > 0:
			assert_eq(TownProjects.hook(str(p.zone), str(p.npc), base, d), base, str(p.id) + " is quiet on a new save")

func test_the_residents_are_real_and_their_lines_are_clean() -> void:
	for p in TownProjects.all():
		var z := ZoneData.load_id(str(p.zone))
		assert_true(z.npcs.any(func(n): return str(n.get("id", "")) == str(p.npc)), "%s has %s" % [p.zone, p.npc])
		for k in ["ask", "progress", "done"]:
			for l in p[k]:
				assert_false("—" in str(l), str(p.id) + " " + k)
				assert_true(str(l).length() < 260, "a line that fits a textbox in " + str(p.id))
		assert_false("—" in str(p.plaque) or "—" in str(p.text))

func test_two_projects_open_a_hidden_footbridge() -> void:
	for pair in [["inverness", "inverness_footbridge", 2], ["lancaster", "lancaster_mill", 2]]:
		var z := ZoneData.load_id(str(pair[0]))
		var shut := GameStateData.new()
		var hidden := z.warps.filter(func(w): return w.get("hidden") is Dictionary and str(w.hidden.get("reveal", "")) == "project_" + str(pair[1]))
		assert_eq(hidden.size(), int(pair[2]), "two warps, one at each end of the bridge")
		for w in hidden:
			assert_eq(ZoneData.warp_state(w, shut), "hidden", "not there until the project is built")
			assert_true(z.walkable(Vector2i(int(w.x), int(w.y))), "you can stand where the bridge starts")
			assert_true(z.walkable(Vector2i(int(w.tx), int(w.ty))), "and land at its end")
			assert_true(z.warp_at(Vector2i(int(w.tx), int(w.ty))).is_empty(), "not on another warp")
			assert_eq(str(w.to), str(pair[0]), "a shortcut inside the town, no new zone")
		var open := _data()
		_finish(open, str(pair[1]))
		for w in hidden:
			assert_eq(ZoneData.warp_state(w, open), "open")

func test_the_footbridges_really_are_shortcuts() -> void:
	for pair in [["inverness", 33], ["lancaster", 40]]:
		var z := ZoneData.load_id(str(pair[0]))
		for w in z.warps:
			if not (w.get("hidden") is Dictionary) or not str(w.hidden.get("reveal", "")).begins_with("project_"):
				continue
			var from := Vector2i(int(w.x), int(w.y))
			var to := Vector2i(int(w.tx), int(w.ty))
			var doors := {}
			for o in z.warps:
				doors[Vector2i(int(o.x), int(o.y))] = true
			var walk := _walk_len(z, from, to, doors)
			assert_true(walk >= int(pair[1]) / 2, "%s: the long way round is %d steps" % [pair[0], walk])

## Steps on foot between two tiles without using a warp, or 9999.
func _walk_len(z: ZoneData, a: Vector2i, b: Vector2i, doors: Dictionary) -> int:
	var dist := {a: 0}
	var q := [a]
	while not q.is_empty():
		var p: Vector2i = q.pop_front()
		if p == b:
			return int(dist[p])
		for dd in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
			var n: Vector2i = p + dd
			if dist.has(n) or not z.walkable(n, dd) or (doors.has(n) and n != b):
				continue
			dist[n] = int(dist[p]) + 1
			q.append(n)
	return 9999

func test_a_finished_project_gives_the_deeds_in_its_town_something_for_good() -> void:
	var d := _data()
	d.set_flag("badge_stone", true)
	Deeds.buy(d, "boat_whitby")
	assert_eq(float(DeedChoices.fx(d, "boat_whitby").shield), 0.0)
	_finish(d, "whitby_lifeboat")
	assert_near(float(DeedChoices.fx(d, "boat_whitby").shield), 0.15, 0.0001, "bad days bite less")
	assert_eq(float(DeedChoices.fx(d, "chippy_whitby").shield), 0.0, "only the boat, which is the lifeboat's business")
	var b := _data()
	Deeds.buy(b, "bnb_portree")
	_finish(b, "portree_pontoon")
	assert_near(float(DeedChoices.fx(b, "bnb_portree").takings), 1.04, 0.0001, "yachts eat ashore")
	Deeds.buy(b, "stall_bath")
	assert_eq(float(DeedChoices.fx(b, "stall_bath").takings), 1.0, "a different town's Deed is untouched")

func test_every_deed_effect_names_a_deed_in_that_town() -> void:
	for p in TownProjects.all():
		var dd: Variant = p.get("effects", {}).get("deed", {})
		if dd is Dictionary:
			for did in dd:
				assert_eq(str(Deeds.get_deed(str(did)).zone), str(p.zone), "%s: %s is in the town" % [p.id, did])

func test_a_project_survives_a_save() -> void:
	var d := _data()
	TownProjects.fund(d, "carlisle_library")
	var back := GameStateData.from_dict(JSON.parse_string(JSON.stringify(d.to_dict())), Dex.load_default())
	assert_eq(TownProjects.stages_paid(back, "carlisle_library"), 1)
	assert_eq(int(TownProjects.state(back, "carlisle_library").paid), int(TownProjects.state(d, "carlisle_library").paid))
	_finish(d, "carlisle_library")
	var back2 := GameStateData.from_dict(JSON.parse_string(JSON.stringify(d.to_dict())), Dex.load_default())
	assert_true(TownProjects.is_done(back2, "carlisle_library"))
	assert_true(TownProjects.plaque(back2, TownProjects.get_project("carlisle_library")).contains("Sam"))

func test_the_daily_deeds_tick_opens_finished_projects() -> void:
	var d := _data()
	TownProjects.fund_all(d, "carlisle_library")
	d.day_count += 60
	Deeds.tick(d, d.day_count)   # no Deed owned, the projects still open
	assert_true(TownProjects.is_done(d, "carlisle_library"))
