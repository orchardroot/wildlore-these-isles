extends TestCase
## Stud Book (core/stud_book.gd), Punnett preview logic (ui/punnett_view.gd), pairing decisions (ui/pairing_logic.gd).

func _mk(sex: String, over := {}, uid := 0) -> Creature:
	var c := Fixtures.creature("moolet", 10)
	c.sex = sex
	c.uid = uid
	c.friendship = 200
	var g := {"coat": ["+", "+"], "tint": ["W", "W"], "mark": ["b", "b"], "knack": ["K", "K"], "ginger": ["o", "o"],
		"frame1": ["+", "-"], "frame2": ["+", "-"], "frame3": ["+", "-"], "frame4": ["+", "-"]}
	g.merge(over, true)
	if sex == "m":
		g["ginger"] = [g["ginger"][0], "Y"]
	c.genome = g
	return c

func test_every_idea_has_four_paragraphs_a_hint_and_no_em_dash() -> void:
	var seen := {}
	for i in StudBook.IDEAS:
		assert_false(seen.has(i.id), "unique id " + i.id)
		seen[i.id] = true
		assert_eq(i.text.size(), 4, i.id + " paragraphs")
		for s in i.text + [i.hint, i.story, i.title]:
			assert_false(str(s).contains("—"), i.id + " has no em-dash")
		for banned in ["Day Care", "Ditto", "egg group", "IV "]:
			assert_false(str(i.text).contains(banned), "no Pokemon vocabulary")

func test_odds_words() -> void:
	assert_eq(StudBook.odds_words(0.25), "1 in 4")
	assert_eq(StudBook.odds_words(0.5), "1 in 2")
	assert_eq(StudBook.odds_words(0.0), "never")
	assert_eq(StudBook.odds_words(0.375), "38%")

func test_observe_logs_a_tally_against_expected_and_unlocks_ideas() -> void:
	var d := GameStateData.new()
	var sire := _mk("m", {"coat": ["+", "c"]})
	var dam := _mk("f", {"coat": ["+", "c"]})
	var kid := _mk("f", {"coat": ["c", "c"], "tint": ["W", "W"]})
	var fresh := StudBook.observe(d, sire, dam, kid, "same_line")
	assert_has(fresh, "carriers", "two plain carriers threw a coloured one")
	assert_has(fresh, "breed")
	assert_true(StudBook.unlocked(d, "carriers"))
	var plain := _mk("m")
	StudBook.observe(d, sire, dam, plain, "same_line")
	var lines := StudBook.tally_lines(d)
	var coat := lines.filter(func(l): return str(l).begins_with("Coat"))
	assert_eq(coat.size(), 1, "one Coat line for one pair of hands")
	assert_eq(coat[0], "Coat, +c x +c: coloured expected 1 in 4, seen 1 of 2")
	assert_true(StudBook.locus_seen(d, "tint"), "a coloured child shows its tint")
	assert_false(StudBook.locus_seen(d, "knack"))

func test_dominance_roan_and_selection_unlocks() -> void:
	var d := GameStateData.new()
	var coloured := _mk("m", {"coat": ["c", "c"], "tint": ["W", "W"]})
	var plain := _mk("f")
	var carrier := _mk("f", {"coat": ["+", "c"]})
	assert_has(StudBook.observe(d, coloured, plain, carrier), "dominance")
	var roan := _mk("f", {"coat": ["c", "c"], "tint": ["W", "D"]})
	assert_has(StudBook.observe(d, coloured, plain, roan), "codominance")
	for i in 4:
		StudBook.observe(d, coloured, plain, carrier)
	assert_true(StudBook.unlocked(d, "polygenic") and StudBook.unlocked(d, "selection"), "three and six crosses")
	assert_eq(StudBook.crosses_log(d).size(), 6)

func test_log_is_capped_and_survives_a_json_round_trip() -> void:
	var d := GameStateData.new()
	var a := _mk("m")
	var b := _mk("f")
	for i in 40:
		StudBook.observe(d, a, b, _mk("m"))
	assert_eq(StudBook.crosses_log(d).size(), StudBook.LOG_MAX)
	var back := GameStateData.from_dict(JSON.parse_string(JSON.stringify(d.to_dict())), Fixtures.dex())
	assert_eq(StudBook.tally_lines(back), StudBook.tally_lines(d))
	assert_true(StudBook.unlocked(back, "breed"))

func test_old_saves_have_an_empty_book() -> void:
	var d := GameStateData.new()
	assert_eq(StudBook.idea_count(d), 0)
	assert_eq(StudBook.tally_lines(d), [])
	assert_false(StudBookTab.visible(d))

func test_notes_unlock_hybrids_and_vigour() -> void:
	var d := GameStateData.new()
	StudBook.note(d, "sterile")
	StudBook.note(d, "close_kin")
	assert_true(StudBook.unlocked(d, "hybrids") and StudBook.unlocked(d, "vigour"))

# --- the Punnett preview --------------------------------------------------------------------------------

func test_unknown_alleles_show_as_question_marks_and_odds_stay_in_range() -> void:
	var sire := _mk("m")
	var dam := _mk("f")
	assert_eq(PunnettView.axis(sire, "coat", true), ["+", "?"])
	assert_eq(PunnettView.axis(sire, "coat", false), ["+", "+"])
	assert_eq(PunnettView.axis(sire, "tint", true), ["?", "?"], "tint is unread on a plain coat")
	var o := PunnettView.goal_odds(sire, dam, "coat", true)
	assert_near(o.min, 0.0)
	assert_near(o.max, 0.25)
	assert_true(o.p >= o.min and o.p <= o.max)
	assert_eq(PunnettView.odds_text(o), "none to 1 in 4")
	var known := PunnettView.goal_odds(sire, dam, "coat", false)
	assert_near(known.p, 0.0, 0.0001, "two known ++ parents cannot throw a coloured coat")

func test_a_coloured_parent_is_fully_known() -> void:
	var sire := _mk("m", {"coat": ["c", "c"]})
	assert_eq(PunnettView.axis(sire, "coat", true), ["c", "c"])

func test_goal_odds_for_known_parents() -> void:
	var sire := _mk("m", {"coat": ["c", "c"], "tint": ["W", "D"], "mark": ["B", "b"], "knack": ["k", "k"]})
	var dam := _mk("f", {"coat": ["c", "c"], "tint": ["W", "D"], "mark": ["B", "b"], "knack": ["k", "k"]})
	assert_near(PunnettView.goal_odds(sire, dam, "coat", true).p, 1.0)
	assert_near(PunnettView.goal_odds(sire, dam, "roan", true).p, 0.5, 0.0001, "WD x WD is half WD")
	assert_near(PunnettView.goal_odds(sire, dam, "mark", true).p, 0.25)
	assert_near(PunnettView.goal_odds(sire, dam, "knack", true).p, 1.0)

func test_frame_odds_sum_over_the_four_loci() -> void:
	var big := {"frame1": ["+", "+"], "frame2": ["+", "+"], "frame3": ["+", "+"], "frame4": ["+", "+"]}
	assert_near(PunnettView.goal_odds(_mk("m", big), _mk("f", big), "frame", true).p, 1.0)
	var mid := PunnettView.goal_odds(_mk("m"), _mk("f"), "frame", true)
	assert_true(mid.p > 0.0 and mid.p < 0.4, "two middling parents rarely throw a big frame (%f)" % mid.p)

func test_open_loci_grow_with_the_book() -> void:
	var d := GameStateData.new()
	assert_eq(PunnettView.open_loci(d), ["coat"])
	d.set_flag("book_loci", {"mark": true, "frame": true})
	assert_eq(PunnettView.open_loci(d), ["coat", "mark", "frame"])

func test_tested_creatures_lose_their_question_marks() -> void:
	var d := GameStateData.new()
	var c := _mk("m", {}, 55)
	assert_false(PunnettView.tested(d, c))
	d.set_flag("stud_tested_55")
	assert_true(PunnettView.tested(d, c))

# --- pairing --------------------------------------------------------------------------------------------

func test_kinship_words() -> void:
	assert_eq(PairingLogic.kinship_words(0.0), "Unrelated")
	assert_eq(PairingLogic.kinship_words(0.03), "Distant cousins")
	assert_eq(PairingLogic.kinship_words(0.0625), "Cousins")
	assert_eq(PairingLogic.kinship_words(0.125), "Close kin")
	assert_eq(PairingLogic.kinship_words(0.25), "Too close")

func test_verdict_needs_fondness_one_a_day_and_room_in_the_baskets() -> void:
	var d := GameStateData.new()
	var m := _mk("m", {}, 1)
	var f := _mk("f", {}, 2)
	var v := PairingLogic.verdict(d, "farm", f, m)
	assert_true(v.ok, "fond, same line, opposite sexes: " + str(v.why))
	assert_eq(v.sire, m, "the pair is sorted whichever way round it was picked")
	f.friendship = 10
	assert_false(PairingLogic.verdict(d, "farm", m, f).ok)
	f.friendship = 200
	assert_true(str(PairingLogic.verdict(d, "farm", m, null).why).contains("Pick a female"), "one pick says what it still needs")
	assert_true(Breeding.start(d, m, f, "farm", Fixtures.dex(), Fixtures.moves(), Rng.new(5), "spring").ok)
	var again := PairingLogic.verdict(d, "farm", m, f)
	assert_false(again.ok)
	assert_true(again.why.contains("One pairing a day"))
	assert_true(PairingLogic.verdict(d, "other_farm", m, f).ok, "one a day is per farm")

func test_same_sex_and_kin_are_refused_with_the_farmers_words() -> void:
	var d := GameStateData.new()
	var a := _mk("m", {}, 1)
	var b := _mk("m", {}, 2)
	assert_false(PairingLogic.verdict(d, "farm", a, b).ok)
	var dam := _mk("f", {}, 3)
	var son := _mk("m", {}, 4)
	son.pedigree = {"sire": {"uid": 1}, "dam": {"uid": 3}}
	var v := PairingLogic.verdict(d, "farm", son, dam)
	assert_false(v.ok)
	assert_eq(v.kin_words, "Too close")

func test_basket_line() -> void:
	var d := GameStateData.new()
	assert_eq(PairingLogic.basket_line(d), "")
	d.set_flag("breed_basket_0", {"steps_due": 1240})
	assert_eq(PairingLogic.basket_line(d), "Basket: 1,240 steps to go")
	d.stats["steps"] = 1240
	assert_eq(PairingLogic.basket_line(d), "Basket: ready to hatch")
	d.set_flag("breed_basket_1", {"steps_due": 5000})
	assert_eq(PairingLogic.basket_line(d), "Baskets: 2, one ready to hatch")
	assert_eq(PairingLogic.commas(1234567), "1,234,567")

func test_the_stud_book_tab_lists_every_idea_then_the_log() -> void:
	var ids := StudBookTab.ids()
	assert_eq(ids.size(), StudBook.IDEAS.size() + 1)
	assert_eq(ids[-1], "crosses")
	assert_eq(MenuLogic.next_filter("rumours"), "all", "the Stud Book tab is off until there is something in it")
	assert_eq(MenuLogic.next_filter("rumours", true), "studbook")
	assert_eq(MenuLogic.next_filter("studbook", true), "all")

func test_the_genome_page_builds_for_any_creature() -> void:
	var d := GameStateData.new()
	var c := _mk("f", {"coat": ["+", "c"]}, 9)
	var page := GenomePage.build(d, c)
	assert_true(page.get_child_count() > 0)
	assert_eq(GenomePage.alleles(d, c, "coat"), ["+", "?"], "a carrier hides behind its plain coat until tested")
	d.set_flag("stud_tested_9")
	assert_eq(GenomePage.alleles(d, c, "coat"), ["+", "c"])
	assert_eq(GenomePage.showing_words(c, "coat", true), "carries a coloured coat")
	assert_eq(GenomePage.showing_words(c, "coat"), "plain")
	page.free()
