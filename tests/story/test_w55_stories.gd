extends TestCase
## Wave 55 stories (data/quests/w55_*.json): the branching and the post that comes later (Quests.later), then each chain
## played through its scripts with a FakeStoryHost, once for every branch. Consequences are checked three ways: the flags
## survive a save, the people in the rooms change (Npc.should_spawn on the raw zone data) and a fresh save is untouched.

func _talk(h: FakeStoryHost, zone: String, script: String) -> void:
	h.said.clear()
	await Commands.new(h, script).run(StoryData.script(zone, script))

func _said(h: FakeStoryHost) -> String:
	return " ".join(h.said.map(func(l): return str(l[1])))

func _q(id: String) -> Dictionary:
	return Quests.get_quest(id)

func _present(zone: String, npc_id: String, d: GameStateData) -> bool:
	var z: Variant = JsonUtil.read("res://data/zones/%s.json" % zone)
	for n in z.npcs:
		if str(n.id) == npc_id:
			return Npc.should_spawn(n, d, "day")
	assert_true(false, "%s has no npc %s" % [zone, npc_id])
	return false

## A save and a load: what the player would see after quitting.
func _reload(h: FakeStoryHost) -> void:
	h.data = GameStateData.from_dict(JSON.parse_string(JSON.stringify(h.data.to_dict())), h.dex)

func _sleep(h: FakeStoryHost, days: int) -> void:
	h.data.day_count += days

func _bag(h: FakeStoryHost, id: String) -> int:
	return int(h.data.bag.get(id, 0))

# --- the mechanism -----------------------------------------------------------------------------

func test_later_ripens_after_days_or_a_new_real_date() -> void:
	var d := GameStateData.new()
	assert_false(Quests.later(d, "k", 3), "never stamped")
	d.set_flag("k", Quests.stamp(d))
	assert_false(Quests.later(d, "k", 3), "same day, same night")
	d.day_count += 2
	assert_false(Quests.later(d, "k", 3), "two nights is not three")
	d.day_count += 1
	assert_true(Quests.later(d, "k", 3), "three nights")
	d.set_flag("k", "2020-01-01@%d@0" % d.day_count)
	assert_true(Quests.later(d, "k", 99), "a different real date always counts")
	d.set_flag("k", true)
	assert_false(Quests.later(d, "k", 0), "a plain flag is not a stamp")

func test_later_condition_and_stamp_command() -> void:
	var h := FakeStoryHost.new()
	assert_eq(Quests.later_cond(h.data, "dusk"), -1, "other conditions are not ours")
	assert_eq(Quests.later_cond(h.data, "later_k_x"), -1)
	assert_eq(Quests.later_cond(h.data, "later_k_3"), 0)
	await Commands.new(h, "t").run([{"do": "set", "flag": "k", "value": "@now"},
		{"do": "when", "cond": "later_k_3", "then": [{"do": "say", "who": "A", "text": "ripe"}], "else": [{"do": "say", "who": "A", "text": "green"}]}])
	assert_eq(_said(h), "green")
	assert_true(str(h.data.flag("k")).contains("@"), "stamped with the day")
	h.data.day_count += 3
	h.said.clear()
	await Commands.new(h, "t").run([{"do": "when", "cond": "later_k_3", "then": [{"do": "say", "who": "A", "text": "ripe"}]}])
	assert_eq(_said(h), "ripe")

func test_outcome_line_shows_in_the_log_once_done() -> void:
	var h := FakeStoryHost.new()
	var q := {"id": "t", "title": "T", "start_flag": "s", "done_flag": "d", "steps": [{"flag": "d", "text": "x", "zone": "z"}],
		"endings": [{"flag": "a", "text": "It went one way."}, {"flag": "b", "text": "It went the other."}]}
	h.data.set_flag("s", true)
	h.data.set_flag("b", true)
	assert_eq(Quests.log_steps(h.data, q).size(), 1, "nothing about the ending while it is open")
	h.data.set_flag("d", true)
	var steps := Quests.log_steps(h.data, q)
	assert_eq(steps.size(), 2)
	assert_eq(steps[1].text, "It went the other.")

func test_every_w55_quest_has_endings_that_validate() -> void:
	var mine := Quests.all().filter(func(q): return str(q.get("_file", "")).begins_with("w55_"))
	for q in mine:
		assert_true(q.get("endings", []).size() >= 2, "%s: at least two endings" % q.id)
		assert_true(q.steps.size() >= 3 and q.steps.size() <= 5, "%s: three to five steps" % q.id)
	assert_eq(Quests.validate(mine, Quests.raw_zones(), Quests.all_settable()), [])

# --- England: Who Takes the Moor Farm ------------------------------------------------------------------

const E := "q_stories_england_"

func _england(pick: int) -> FakeStoryHost:
	var h := FakeStoryHost.new()
	var q := _q("stories_england")
	assert_eq(Quests.status(h.data, q), Quests.NOT_STARTED)
	await _talk(h, "nym_moorfarm", "w55e_hannah")
	assert_eq(Quests.status(h.data, q), Quests.ACTIVE)
	await _talk(h, "nym_moorfarm", "moorfarm_farmer")
	assert_true(str(_said(h)).contains("hefted"), "Dale says his side")
	assert_eq(Quests.step_index(h.data, q), 1, "Joe next")
	await _talk(h, "nym_moorfarm", "moorfarm_farmer")
	h.choices = [pick]
	await _talk(h, "nym_moorfarm", "moorfarm_farmer")
	assert_eq(h.data.flag(E + "decided"), null, "not before Joe and the ranger have spoken")
	await _talk(h, "nym_rosedale", "w55e_joe")
	await _talk(h, "nym_moorcock", "w55e_ranger")
	assert_eq(Quests.step_index(h.data, q), 3, "tell Dale")
	h.choices = [pick]
	await _talk(h, "nym_moorfarm", "moorfarm_farmer")
	return h

func test_england_every_branch_finishes_and_arrives_later() -> void:
	var worlds := ["hannah", "joe", "scheme"]
	var keepsake := ["w55_moor_notebook", "w55_moor_crook", "w55_moor_tally"]
	for i in 3:
		var h := await _england(i)
		var q := _q("stories_england")
		assert_true(h.data.flag(E + "decided") == true, "decided")
		assert_true(h.data.flag(E + "pick_" + worlds[i]) == true, "the choice is kept")
		assert_eq(Quests.status(h.data, q), Quests.ACTIVE, "not done in the same conversation")
		assert_eq(_bag(h, keepsake[i]), 0, "no reward yet")
		_reload(h)
		await _talk(h, "nym_moorcock", "w55e_postie")
		assert_true(_said(h).contains("Nothing for you yet"), "the same night: nothing")
		assert_eq(Quests.status(h.data, q), Quests.ACTIVE)
		_sleep(h, 3)
		await _talk(h, "nym_moorcock", "w55e_postie")
		assert_eq(Quests.status(h.data, q), Quests.DONE, "the letter comes")
		assert_eq(_bag(h, keepsake[i]), 1)
		assert_eq(_bag(h, "flat_cap_yorkshire"), 1)
		assert_true(Crafting.is_known(h.data, "parkin"))
		assert_eq(Quests.outcome(h.data, q), str(q.endings[i].text))
		for j in 3:
			if j != i:
				assert_eq(_bag(h, keepsake[j]), 0, "only the keepsake of the choice made")
		await _talk(h, "nym_moorcock", "w55e_postie")
		assert_eq(_bag(h, keepsake[i]), 1, "the letter is not read twice")
		_reload(h)
		assert_eq(Quests.status(h.data, q), Quests.DONE, "done survives a save")
		var d := h.data
		var hannah_there := _present("nym_moorfarm", "w55e_hannah", d)
		var dale_at_farm := _present("nym_moorfarm", "moorfarm_farmer", d)
		var sam_there := _present("nym_moorfarm", "w55e_sam", d)
		var dale_at_pub := _present("nym_moorcock", "w55e_dale_pub", d)
		var ranger_farm := _present("nym_moorfarm", "w55e_ranger_farm", d)
		var ranger_pub := _present("nym_moorcock", "w55e_ranger", d)
		assert_eq(_present("nym_moorcock", "w55e_postie", d), false, "the post has been collected")
		match i:
			0:
				assert_true(hannah_there and dale_at_farm and not sam_there and not dale_at_pub and ranger_pub and not ranger_farm)
			1:
				assert_true(not hannah_there and not dale_at_farm and sam_there and dale_at_pub and ranger_pub)
			2:
				assert_true(not hannah_there and dale_at_farm and ranger_farm and not ranger_pub and not sam_there)

func test_england_not_started_leaves_the_old_farm_alone() -> void:
	var h := FakeStoryHost.new()
	await _talk(h, "nym_moorfarm", "moorfarm_farmer")
	assert_true(_said(h).contains("parkin"), "Dale is still Dale")
	assert_eq(h.data.flag(E + "started"), null)
	assert_true(_present("nym_moorfarm", "moorfarm_farmer", h.data))
	assert_true(_present("nym_moorfarm", "w55e_hannah", h.data), "Hannah is just home for the weekend")
	assert_false(_present("nym_moorcock", "w55e_postie", h.data), "no post waiting")
	assert_false(_present("nym_moorfarm", "w55e_sam", h.data))
	await _talk(h, "nym_rosedale", "w55e_joe")
	await _talk(h, "nym_moorcock", "w55e_ranger")
	assert_eq(Quests.status(h.data, _q("stories_england")), Quests.NOT_STARTED, "the neighbours do not start it")
	assert_eq(h.data.flag(E + "joe"), null)

func test_england_need_to_think_does_not_decide() -> void:
	var h := await _england(3)
	assert_eq(h.data.flag(E + "decided"), null)
	assert_eq(Quests.status(h.data, _q("stories_england")), Quests.ACTIVE)
	h.choices = [1]
	await _talk(h, "nym_moorfarm", "moorfarm_farmer")
	assert_true(h.data.flag(E + "pick_joe") == true, "and he can still be told later")

# --- the other five chains, played the same way ----------------------------------------------------------
## Each spec: quest id, flag prefix, who starts it, who to hear (in order), who takes the answer, who brings the post,
## the flag each branch sets, the keepsake of each branch, what everyone gets, and who stands where: [zone, npc, there
## before the chain has ended, there afterwards in each of the three worlds].

const CHAINS := [
	{"id": "stories_scotland", "p": "q_stories_scotland_", "start": ["thurso_pub", "w55s_isobel"],
		"voices": [["thurso_pub", "w55s_calum"], ["forsinard_centre", "flows_warden"]], "decide": ["thurso_pub", "w55s_isobel"],
		"post": ["thurso_pub", "w55s_postie"], "picks": ["support", "object", "compromise"],
		"keep": ["w55_hall_slate", "w55_hall_feather", "w55_hall_minute"], "gift": ["wellies_green"], "recipe": "clootie_dumpling",
		"seen": [["thurso_pub", "w55s_tech", false, [true, false, true]], ["thurso_pub", "w55s_kirsty", true, [true, false, true]]]},
	{"id": "stories_wales", "p": "q_stories_wales_", "start": ["rhondda_chapel", "w55w_eirlys"],
		"voices": [["rhondda_institute", "w55w_kieran"], ["rhondda_chapel", "rhn_conductor"]], "decide": ["rhondda_chapel", "w55w_eirlys"],
		"post": ["rhondda_home", "w55w_postman"], "picks": ["sell", "keep", "split"],
		"keep": ["w55_bethania_key", "w55_bethania_thermometer", "w55_bethania_keys"], "gift": ["welsh_wool_shawl"], "recipe": "welsh_cakes",
		"seen": [["rhondda_institute", "w55w_chorister", false, [true, false, false]], ["rhondda_chapel", "w55w_ladder", false, [false, true, false]],
			["rhondda_chapel", "w55w_father", false, [false, false, true]]]},
	{"id": "stories_ireland", "p": "q_stories_ireland_", "start": ["gweedore_pub", "gp_barman"],
		"voices": [["gweedore_pub", "w55i_niamh"], ["gweedore_pub", "w55i_brid"], ["gweedore_pub", "w55i_orla"]], "decide": ["gweedore_pub", "gp_barman"],
		"post": ["gweedore_pub", "w55i_postman"], "picks": ["couple", "coop", "hotel"],
		"keep": ["w55_snug_latch", "w55_coop_share", "w55_last_orders_bell"], "gift": ["donegal_tweed_cap"], "recipe": "boxty",
		"seen": [["gweedore_pub", "gp_barman", true, [false, false, false]], ["gweedore_pub", "w55i_retired", false, [true, true, true]],
			["gweedore_pub", "w55i_couple", false, [true, false, false]], ["gweedore_pub", "w55i_coop", false, [false, true, false]],
			["gweedore_pub", "w55i_hotel", false, [false, false, true]], ["gweedore_pub", "w55i_brid", true, [true, true, true]]]},
	{"id": "stories_northern_ireland", "p": "q_stories_northern_ireland_", "start": ["bushmills_postoffice", "bush_postmaster"],
		"voices": [["bushmills_postoffice", "w55n_margaret"], ["bushmills_postoffice", "w55n_gareth"], ["bushmills_craftshop", "w55n_joanne"]],
		"decide": ["bushmills_postoffice", "bush_postmaster"], "post": ["bushmills_postoffice", "w55n_postman"], "picks": ["community", "franchise", "hosted"],
		"keep": ["w55_counter_tin", "w55_counter_scales", "w55_counter_sign"], "gift": ["belfast_linen_shirt"], "recipe": "soda_farl",
		"seen": [["bushmills_postoffice", "bush_postmaster", true, [false, false, false]], ["bushmills_postoffice", "w55n_retired", false, [true, true, true]],
			["bushmills_postoffice", "w55n_vol", false, [true, false, false]], ["bushmills_postoffice", "w55n_till", false, [false, true, false]],
			["bushmills_craftshop", "w55n_hatch", false, [false, false, true]], ["bushmills_craftshop", "w55n_joanne", true, [false, false, false]],
			["bushmills_postoffice", "w55n_margaret", true, [false, false, false]], ["bushmills_postoffice", "w55n_gareth", true, [false, false, false]]]},
	{"id": "stories_islands", "p": "q_stories_islands_", "start": ["lerwick_wool", "w55k_eila"],
		"voices": [["lerwick_tearoom", "w55k_magnie"], ["lerwick_townhall", "w55k_ruth"]], "decide": ["lerwick_wool", "w55k_eila"],
		"post": ["lerwick_tearoom", "w55k_hand"], "picks": ["full", "lean", "small"],
		"keep": ["w55_isle_plate", "w55_isle_timetable", "w55_isle_lifebelt"], "gift": ["shetland_lace_shawl"], "recipe": "stovies",
		"seen": [["lerwick_wool", "w55k_robbie", false, [true, false, false]], ["lerwick_wool", "w55k_lorna", false, [false, true, false]],
			["lerwick_tearoom", "w55k_skipper", false, [false, false, true]]]},
]

func _play_chain(c: Dictionary, pick: int, think_first := false) -> FakeStoryHost:
	var h := FakeStoryHost.new()
	var q := _q(str(c.id))
	assert_false(q.is_empty(), str(c.id))
	assert_eq(Quests.status(h.data, q), Quests.NOT_STARTED)
	await _talk(h, c.start[0], c.start[1])
	assert_eq(Quests.status(h.data, q), Quests.ACTIVE, "%s starts" % c.id)
	h.choices = [pick]
	await _talk(h, c.decide[0], c.decide[1])
	assert_eq(h.data.flag(c.p + "decided"), null, "%s: not decided before everyone has been heard" % c.id)
	for v in c.voices:
		await _talk(h, v[0], v[1])
	for i in c.voices.size():
		assert_true(h.data.flag(str(q.steps[i].flag)) == true, "%s: step %d ticked" % [c.id, i + 1])
	assert_eq(Quests.step_index(h.data, q), c.voices.size(), "%s: now it is for you to say" % c.id)
	if think_first:
		h.choices = [3]
		await _talk(h, c.decide[0], c.decide[1])
		assert_eq(h.data.flag(c.p + "decided"), null, "%s: 'I need to think' decides nothing" % c.id)
	h.choices = [pick]
	await _talk(h, c.decide[0], c.decide[1])
	return h

func _chain_every_branch(c: Dictionary) -> void:
	for i in 3:
		var h := await _play_chain(c, i, i == 0)
		var q := _q(str(c.id))
		assert_true(h.data.flag(c.p + "decided") == true, "%s/%d decided" % [c.id, i])
		assert_true(h.data.flag(c.p + "pick_" + c.picks[i]) == true, "%s/%d: the choice is kept" % [c.id, i])
		assert_eq(Quests.status(h.data, q), Quests.ACTIVE, "%s/%d: not done in the same conversation" % [c.id, i])
		assert_eq(_bag(h, c.keep[i]), 0)
		_reload(h)
		for s in c.seen:
			assert_eq(_present(s[0], s[1], h.data), bool(s[2]), "%s/%d: %s is as before until the letter" % [c.id, i, s[1]])
		assert_true(_present(c.post[0], c.post[1], h.data), "%s/%d: the post is waiting" % [c.id, i])
		await _talk(h, c.post[0], c.post[1])
		assert_eq(Quests.status(h.data, q), Quests.ACTIVE, "%s/%d: the same night, nothing" % [c.id, i])
		_sleep(h, 3)
		await _talk(h, c.post[0], c.post[1])
		assert_eq(Quests.status(h.data, q), Quests.DONE, "%s/%d: the letter comes" % [c.id, i])
		assert_eq(_bag(h, c.keep[i]), 1)
		for j in 3:
			if j != i:
				assert_eq(_bag(h, c.keep[j]), 0, "only the keepsake of the choice made")
		for g in c.gift:
			assert_eq(_bag(h, g), 1)
		assert_true(Crafting.is_known(h.data, c.recipe))
		assert_eq(Quests.outcome(h.data, q), str(q.endings[i].text))
		await _talk(h, c.post[0], c.post[1])
		assert_eq(_bag(h, c.keep[i]), 1, "the letter is not read twice")
		_reload(h)
		assert_eq(Quests.status(h.data, q), Quests.DONE, "done survives a save")
		assert_false(_present(c.post[0], c.post[1], h.data), "the post has been collected")
		for s in c.seen:
			assert_eq(_present(s[0], s[1], h.data), bool(s[3][i]), "%s/%d: %s afterwards" % [c.id, i, s[1]])

func test_scotland_every_branch() -> void:
	await _chain_every_branch(CHAINS[0])

func test_wales_every_branch() -> void:
	await _chain_every_branch(CHAINS[1])

func test_ireland_every_branch() -> void:
	await _chain_every_branch(CHAINS[2])

func test_northern_ireland_every_branch() -> void:
	await _chain_every_branch(CHAINS[3])

func test_islands_every_branch() -> void:
	await _chain_every_branch(CHAINS[4])

func test_fresh_saves_are_untouched_until_a_chain_is_started() -> void:
	for c in CHAINS:
		var h := FakeStoryHost.new()
		for v in c.voices:
			await _talk(h, v[0], v[1])
		assert_eq(Quests.status(h.data, _q(str(c.id))), Quests.NOT_STARTED, "%s: hearing the neighbours first starts nothing" % c.id)
		assert_eq(h.data.flag(c.p + "decided"), null)
		assert_eq(h.data.flag(c.p + "started"), null)
		for s in c.seen:
			assert_eq(_present(s[0], s[1], h.data), bool(s[2]), "%s: %s on a save that has not started it" % [c.id, s[1]])

func test_every_w55_step_and_ending_flag_is_set_somewhere() -> void:
	var settable := Quests.all_settable()
	for c in CHAINS:
		var q := _q(str(c.id))
		for s in q.steps:
			assert_true(settable.has(str(s.flag)), "%s: %s" % [c.id, s.flag])
		for e in q.endings:
			assert_true(settable.has(str(e.flag)), "%s: %s" % [c.id, e.flag])
