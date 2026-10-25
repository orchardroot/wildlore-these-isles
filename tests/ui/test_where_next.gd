extends TestCase
## "Where next?" suggests up to three things: the story first, then nearby quests, festivals today, a Deed's till and
## a basket about to hatch. Each only when it applies.

func _lines(d: GameStateData, opts := {}) -> Array:
	return WhereNext.suggest(d, 0, "", opts).map(func(s): return s.text)

func test_the_story_comes_first_and_at_most_three() -> void:
	var d := GameStateData.new()
	d.set_flag("deed_" + str(Deeds.all()[0].id), {"owned": true, "till": 400})
	d.set_flag("breed_basket_0", {"steps_due": 0})
	var out := WhereNext.suggest(d, 0, "", {"fest": ["On now: a fair."]})
	assert_eq(out.size(), 3)
	assert_eq(out[0].kind, "story")

func test_deed_till_is_suggested_when_worth_collecting() -> void:
	var d := GameStateData.new()
	var deed: Dictionary = Deeds.all()[0]
	d.set_flag("deed_" + str(deed.id), {"owned": true, "till": 400})
	var joined := " ".join(_lines(d, {"story": false}))
	assert_true(joined.contains(str(deed.name)) and joined.contains("400"), joined)

func test_an_empty_till_is_not_nagged() -> void:
	var d := GameStateData.new()
	d.set_flag("deed_" + str(Deeds.all()[0].id), {"owned": true, "till": 0})
	assert_eq(_lines(d, {"story": false, "fest": []}), [], "no festival line either: the real calendar stays out of it")

func test_a_basket_about_to_hatch() -> void:
	var d := GameStateData.new()
	d.set_flag("breed_basket_0", {"steps_due": 0})
	var joined := " ".join(_lines(d, {"story": false}))
	assert_true(joined.to_lower().contains("basket"), joined)

func test_festival_today_is_suggested() -> void:
	var lines := _lines(GameStateData.new(), {"story": false, "fest": ["On now: the Fair in Leeds, until 7 May."]})
	assert_true(" ".join(lines).contains("Fair in Leeds"))

func test_no_duplicates() -> void:
	var out := _lines(GameStateData.new(), {"fest": ["On now: x."]})
	var seen := {}
	for l in out:
		assert_false(seen.has(l), l)
		seen[l] = true
