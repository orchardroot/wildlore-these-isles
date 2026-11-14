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
