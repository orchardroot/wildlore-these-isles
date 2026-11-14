extends TestCase
## Wave 57, contracts that do not all go the same way: the three shapes (a wrong witness you can strike out, a clue
## that follows another, a clue seen from the coracle), the contracts that use them, the follow-ups, old saves.

func _sample() -> Dictionary:
	return {
		"id": "s", "title": "Sample", "town": "x", "badges": 0,
		"hypotheses": [{"id": "a", "name": "A"}, {"id": "b", "name": "B"}, {"id": "c", "name": "C"}],
		"truth": "a",
		"clues": [
			{"id": "k1", "kind": "look", "points": ["a"], "rules_out": ["c"]},
			{"id": "k2", "kind": "ask", "wrong": true, "points": ["b"], "idle": ["Not now."], "who": "Pat", "text": ["B, it is B."]},
			{"id": "k3", "kind": "look", "points": ["a"], "needs_clue": "k1", "text": "Follows on."},
			{"id": "k4", "kind": "look", "from": "coracle", "optional": true, "points": ["a"], "text": "From the water."},
		],
		"choices": [{"id": "x"}],
	}

func _taken(c: Dictionary) -> GameStateData:
	var d := GameStateData.new()
	d.set_flag(Contracts.flag(str(c.id), "state"), Contracts.TAKEN)
	return d

func test_a_wrong_witness_can_be_struck_out() -> void:
	var c := _sample()
	Contracts.use([c])
	var d := _taken(c)
	Contracts.note_clue(d, "s", "k1")
	Contracts.note_clue(d, "s", "k2")
	var t := Contracts.theory(d, c)
	assert_eq(t.lead.size(), 2, "a witness who is wrong leaves it a toss-up")
	assert_false(t.sure)
	assert_true(Contracts.strike(d, "s", "k2", true))
	assert_true(Contracts.clue_struck(d, "s", "k2"))
	assert_eq(Contracts.theory(d, c).lead, ["a"], "struck out, only what you believe counts")
	assert_true(Contracts.clue_found(d, "s", "k2"), "it is still in the Journal")
	assert_true(Contracts.strike(d, "s", "k2", false), "and it can be put back")
	assert_eq(Contracts.theory(d, c).lead.size(), 2)
	var d2 := GameStateData.from_dict(d.to_dict(), Fixtures.dex())
	assert_false(Contracts.clue_struck(d2, "s", "k2"))
	Contracts.strike(d, "s", "k2", true)
	var d3 := GameStateData.from_dict(d.to_dict(), Fixtures.dex())
	assert_true(Contracts.clue_struck(d3, "s", "k2"), "it is in the save")
	Contracts.reset()

func test_you_can_only_strike_what_you_have_found_and_only_while_it_is_open() -> void:
	var c := _sample()
	Contracts.use([c])
	var d := _taken(c)
	assert_false(Contracts.strike(d, "s", "k2", true), "not found yet")
	Contracts.note_clue(d, "s", "k2")
	d.set_flag(Contracts.flag("s", "state"), Contracts.DECIDED)
	assert_false(Contracts.strike(d, "s", "k2", true), "decided stays decided")
	Contracts.reset()

func test_a_clue_that_follows_another_is_ordinary_ground_until_then() -> void:
	var c := _sample()
	Contracts.use([c])
	var d := _taken(c)
	assert_eq(Contracts.look(d, "s.k3", "day", "clear").lines, [], "nothing here yet: the spot just reads as ground")
	assert_false(Contracts.note_clue(d, "s", "k3"), "cannot be noted early")
	assert_false(Contracts.clue_found(d, "s", "k3"))
	assert_false(Contracts.open_unfound(d, c).any(func(k): return str(k.id) == "k3"), "the Journal does not list it yet")
	Contracts.note_clue(d, "s", "k1")
	assert_true(Contracts.open_unfound(d, c).any(func(k): return str(k.id) == "k3"), "it opens once k1 is found")
	var r := Contracts.look(d, "s.k3", "day", "clear")
	assert_true(r.new)
	assert_eq(r.lines, ["Follows on."])
	Contracts.reset()

func test_a_witness_waits_for_the_clue_that_would_make_them_think_of_it() -> void:
	var c := _sample()
	c.clues[1]["needs_clue"] = "k1"
	c.clues[1]["wrong"] = false
	Contracts.use([c])
	var h := FakeStoryHost.new()
	h.data = _taken(c)
	await Commands.new(h).run([{"do": "contract", "as": "clue", "id": "s", "clue": "k2"}])
	assert_false(Contracts.clue_found(h.data, "s", "k2"))
	assert_eq(h.said.back()[1], "Not now.")
	Contracts.note_clue(h.data, "s", "k1")
	await Commands.new(h).run([{"do": "contract", "as": "clue", "id": "s", "clue": "k2"}])
	assert_true(Contracts.clue_found(h.data, "s", "k2"))
	Contracts.reset()

func test_a_clue_seen_from_the_coracle_needs_the_coracle() -> void:
	var c := _sample()
	Contracts.use([c])
	var d := _taken(c)
	var ashore := Contracts.look(d, "s.k4", "day", "clear", false)
	assert_false(ashore.new)
	assert_eq(ashore.lines.size(), 1, "from the bank you only see that there is something to see")
	assert_false(Contracts.clue_found(d, "s", "k4"))
	var afloat := Contracts.look(d, "s.k4", "day", "clear", true)
	assert_true(afloat.new)
	assert_eq(afloat.lines, ["From the water."])
	assert_eq(Contracts.from_words(c.clues[3]), "seen from the coracle")
	Contracts.reset()

func test_the_plain_clues_make_it_sure_without_the_optional_ones() -> void:
	var c := _sample()
	assert_true(Contracts._validate_theory(c, "s: ").is_empty(), "k1 and k3 are enough with k2 struck")
	var th := Contracts.theory_of(c, ["k1", "k3"])
	assert_eq(th.lead, ["a"])
	assert_true(th.sure)
	c.clues[2]["points"] = []
	assert_false(Contracts._validate_theory(c, "s: ").is_empty(), "now the plain clues alone are not enough")

func test_the_shape_rules_catch_a_bad_clue() -> void:
	var c := _sample()
	var zone := ZoneData.load_id("chat_moss")
	assert_true(Contracts._validate_shape(c, c.clues[1], "s: ", zone).is_empty())
	c.clues[1]["points"] = ["a"]
	assert_false(Contracts._validate_shape(c, c.clues[1], "s: ", zone).is_empty(), "a wrong witness cannot point at the truth")
	c.clues[1]["points"] = ["c"]
	assert_false(Contracts._validate_shape(c, c.clues[1], "s: ", zone).is_empty(), "or at something the others already rule out")
	c.clues[1]["points"] = ["b"]
	c.clues[1]["rules_out"] = ["b"]
	assert_false(Contracts._validate_shape(c, c.clues[1], "s: ", zone).is_empty(), "and nothing rules out for it")
	var c2 := _sample()
	c2.clues[0]["needs_clue"] = "k3"
	assert_false(Contracts._validate_shape(c2, c2.clues[0], "s: ", zone).is_empty(), "k1 and k3 follow each other round")
	c2.clues[0]["needs_clue"] = "nope"
	assert_false(Contracts._validate_shape(c2, c2.clues[0], "s: ", zone).is_empty(), "or a clue that is not there")
	var c3 := _sample()
	c3.clues[3]["optional"] = false
	assert_false(Contracts._validate_shape(c3, c3.clues[3], "s: ", zone).is_empty(), "the coracle is never required")
	var c4 := _sample()
	c4.clues[2]["needs_clue"] = "k4"
	assert_false(Contracts._validate_shape(c4, c4.clues[2], "s: ", zone).is_empty(), "nor is a plain clue behind an optional one")

func _using(key: String) -> Array:
	return Contracts.all().filter(func(c): return (c.clues as Array).any(func(k): return k.has(key) and not (k[key] is bool and not k[key]))).map(func(c): return str(c.id))

func test_each_shape_is_used_by_at_least_three_contracts() -> void:
	assert_true(_using("wrong").size() >= 3, "wrong witnesses: %s" % [_using("wrong")])
	assert_true(_using("needs_clue").size() >= 3, "a clue that follows another: %s" % [_using("needs_clue")])
	assert_true(_using("from").size() >= 3, "seen from the coracle: %s" % [_using("from")])

func test_reworked_contracts_keep_every_old_clue_and_ending() -> void:
	var old := {"mink": ["tracks", "dusk", "ted", "volunteer"], "bog": ["trackway", "light", "mikey", "ranger"],
		"beavers": ["stumps", "dusk", "pidgeon", "ranger"], "kelpie": ["hooves", "spate", "ghillie", "hydro"], "seal": ["bites", "dawn", "netsman", "biologist"]}
	for id in old:
		var c := Contracts.get_contract(id)
		var ids: Array = (c.clues as Array).map(func(k): return str(k.id))
		for k in old[id]:
			assert_has(ids, k, "%s keeps clue %s" % [id, k])
		assert_eq(c.choices.size(), 4, "%s keeps its four endings" % id)
		# a save that was part-way: found clues stay found, the new ones are simply not found yet
		var d := _taken(c)
		for k in old[id]:
			Contracts.note_clue(d, id, k)
		var th := Contracts.theory(d, c)
		assert_true(str(c.truth) in th.lead or th.lead.size() > 0, "%s: an old save still has a theory" % id)
		var d2 := GameStateData.from_dict(d.to_dict(), Fixtures.dex())
		for k in old[id]:
			assert_true(Contracts.clue_found(d2, id, k))

func test_the_wrong_witness_can_hold_a_player_back_until_struck() -> void:
	# mink: the tracks point at an otter as well, and Ted says otter: that looks sure, and is wrong
	var c := Contracts.get_contract("mink")
	var d := _taken(c)
	Contracts.note_clue(d, "mink", "tracks")
	Contracts.note_clue(d, "mink", "ted")
	var t := Contracts.theory(d, c)
	assert_eq(t.lead, ["otter"], "a wrong witness can mislead")
	Contracts.strike(d, "mink", "ted", true)
	assert_eq(Contracts.theory(d, c).lead.size(), 2, "struck out: the tracks leave mink or otter")
	Contracts.note_clue(d, "mink", "volunteer")
	Contracts.note_clue(d, "mink", "dusk")
	assert_eq(Contracts.theory(d, c).lead, ["mink"])

func test_the_look_spots_are_where_the_shapes_say() -> void:
	for pair in [["beavers", "lodge", "exe_estuary"], ["kelpie", "ripple", "great_glen"], ["seal", "net", "pentland_coast"]]:
		var c := Contracts.get_contract(pair[0])
		var k := Contracts.clue_of(c, pair[1])
		assert_eq(str(k.from), "coracle")
		assert_true(bool(k.optional))
		var z := ZoneData.load_id(pair[2])
		var spot := {}
		for e in z.examine:
			if str(e.get("clue", "")) == "%s.%s" % [pair[0], pair[1]]:
				spot = e
		assert_false(spot.is_empty(), "%s has its look-spot" % pair[1])
	for pair in [["mink", "scat"], ["bog", "scorch"]]:
		assert_eq(Contracts.clue_needs(Contracts.clue_of(Contracts.get_contract(pair[0]), pair[1])).size(), 1)

func test_a_poster_never_says_a_share_of_the_fee() -> void:
	for c in Contracts.all():
		for ch in c.choices:
			for l in ch.poster:
				assert_false("per cent" in str(l).to_lower() or "%" in str(l), "%s/%s quotes a number the pay may not match" % [c.id, ch.id])
