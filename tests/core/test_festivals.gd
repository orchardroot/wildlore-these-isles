extends TestCase
## Festivals (data/festivals.json): date windows (including ones that wrap the new year), the people and creatures
## they bring, the "What's on" lines, and that every event's data hangs together.

func test_windows_and_the_new_year_wrap() -> void:
	var bonfire := Festivals.get_event("bonfire")
	assert_true(Festivals.in_window(bonfire, 11, 1))
	assert_true(Festivals.in_window(bonfire, 11, 7))
	assert_false(Festivals.in_window(bonfire, 11, 8))
	assert_false(Festivals.in_window(bonfire, 10, 31))
	var hog := Festivals.get_event("hogmanay")
	assert_true(Festivals.in_window(hog, 12, 31))
	assert_true(Festivals.in_window(hog, 1, 2))
	assert_false(Festivals.in_window(hog, 1, 3))
	assert_false(Festivals.in_window(hog, 12, 27))

func test_days_until() -> void:
	var bonfire := Festivals.get_event("bonfire")
	assert_eq(Festivals.days_until(bonfire, Vector2i(11, 3)), 0)
	assert_eq(Festivals.days_until(bonfire, Vector2i(10, 30)), 2)
	assert_eq(Festivals.days_until(bonfire, Vector2i(11, 8)), 358)

func test_at_least_eight_occasions_over_the_four_nations() -> void:
	assert_true(Festivals.events().size() >= 8)
	var nations := {}
	for e in Festivals.events():
		nations[Calendar.nation_for_region(ZoneData.load_id(str(e.town)).region)] = true
	for n in ["england", "wales", "scotland", "ireland"]:
		assert_true(nations.has(n), n)

func test_the_person_is_only_there_in_the_window() -> void:
	assert_eq(Festivals.npcs_for("york", Vector2i(7, 1)).size(), 0)
	var defs := Festivals.npcs_for("york", Vector2i(11, 5))
	assert_eq(defs.size(), 1)
	assert_eq(str(defs[0].script_file), Festivals.SCRIPT_FILE)
	assert_eq(Festivals.npcs_for("dublin", Vector2i(11, 5)).size(), 0, "wrong town")

func test_the_creature_joins_the_wild_table_only_in_the_window() -> void:
	var table := [{"species": "pepperling", "min": 84, "max": 85, "weight": 20}]
	assert_eq(Festivals.extra_encounters("york", "grass", table, Vector2i(7, 1)), [])
	var got := Festivals.extra_encounters("york", "grass", table, Vector2i(11, 2))
	assert_eq(got.size(), 1)
	assert_eq(str(got[0].species), "fizzlet")
	assert_eq(int(got[0].min), 84)
	assert_eq(Festivals.extra_encounters("york", "water", table, Vector2i(11, 2)), [])
	assert_eq(Festivals.extra_encounters("york", "grass", [], Vector2i(11, 2)), [], "no table, no festival creature")

func test_whats_on_lists_now_then_soon() -> void:
	var lines := Festivals.whats_on(Vector2i(11, 3))
	assert_true(lines[0].begins_with("On now:"), lines[0])
	assert_true("York" in lines[0])
	var soon := Festivals.whats_on(Vector2i(10, 30))
	assert_true(soon.any(func(l): return l.begins_with("Coming up:") and "York" in l and "in 2 days" in l))
	assert_eq(Festivals.whats_on(Vector2i(11, 10)), [], "nothing near in mid November")
	assert_true(Festivals.whats_on(Vector2i(11, 3), 2).size() <= 2)

func test_when_condition() -> void:
	Calendar.set_override("11-03")
	assert_true(Festivals.cond("fest_bonfire"))
	assert_false(Festivals.cond("fest_fringe"))
	assert_false(Festivals.cond("fest_nonsense"))
	assert_true(Festivals.is_cond("fest_fringe"))
	assert_false(Festivals.is_cond("fest_nonsense"))
	Calendar.set_override("")

func test_data_validates_and_every_quest_flag_is_set() -> void:
	var zones := {}
	for e in Festivals.events():
		zones[str(e.town)] = true
	var errs := Festivals.validate(zones, Dex.load_default(), Quests.all())
	assert_eq(errs, [], str(errs))
	var set_flags := Quests.all_settable()
	var n := 0
	for q in Quests.all():
		if str(q.get("_file", "")) != "festivals":
			continue
		n += 1
		for f in Quests.flags_of(q):
			assert_true(f.begins_with("q_festivals_"), f)
			assert_true(set_flags.has(f), "nobody sets " + f)
	assert_eq(n, Festivals.events().size())

func test_the_scripts_walk_the_quest_to_the_end() -> void:
	for e in Festivals.events():
		var cmds := StoryData.script(Festivals.SCRIPT_FILE, str(e.script))
		var text := JSON.stringify(cmds)
		assert_true(text.contains("q_festivals_%s_done" % e.id), str(e.id))
		assert_true(text.contains("has_" + str(e.spawn.species)), str(e.id))
		assert_false(text.contains("—"), "no em-dashes")
		assert_true(FileAccess.file_exists("res://art/sprites/chars/%s.png" % e.sprite), str(e.id))
		var z := ZoneData.load_id(str(e.town))
		assert_true(SideStories.free_tile(z, Vector2i(int(e.x), int(e.y))), "%s: stands somewhere free" % e.id)

# --- Every year ---

func _d() -> GameStateData:
	return GameStateData.new()

func test_a_rule_window_moves_with_the_calendar() -> void:
	var rule := {"rule": {"nth": "last", "weekday": 2, "month": 1, "from": -3, "to": 1}}
	assert_eq(Festivals.window_of(rule, 2026), [1, 24, 1, 28], "last Tuesday of January 2026 is the 27th")
	assert_eq(Festivals.window_of(rule, 2027), [1, 23, 1, 27], "the 26th in 2027")
	assert_eq(Festivals.window_of(rule, 2028), [1, 22, 1, 26], "the 25th in 2028")
	assert_true(Festivals.in_window(rule, 1, 27, 2026))
	assert_false(Festivals.in_window(rule, 1, 28, 2027))

## Up Helly Aa is the last Tuesday of January, which falls anywhere from the 25th to the 31st. The real event's rule
## must put that Tuesday inside the window every year, with the days around it, from 2026 to 2040.
func test_up_helly_aa_hits_the_last_tuesday_of_january_every_year() -> void:
	var e := Festivals.get_event("uphellyaa")
	assert_true(e.get("rule") is Dictionary, "Up Helly Aa moves with the calendar")
	assert_false(e.has("window"), "no fixed window to mislead anyone")
	var last_tuesdays := {2026: 27, 2027: 26, 2028: 25, 2029: 30, 2030: 29, 2031: 28, 2032: 27, 2033: 25,
		2034: 31, 2035: 30, 2036: 29, 2037: 27, 2038: 26, 2039: 25, 2040: 31}
	for y in last_tuesdays:
		var d: int = last_tuesdays[y]
		var w: Array = Festivals.window_of(e, y)
		assert_eq(w, [1, d - 3, 1, min(d + 1, 31)] if d < 31 else [1, 28, 2, 1], "window for %d" % y)
		assert_true(Festivals.in_window(e, 1, d, y), "Tuesday %d January %d is on" % [d, y])
		assert_true(Festivals.in_window(e, 1, d - 3, y), "the Saturday before is on in %d" % y)
		assert_false(Festivals.in_window(e, 1, d - 4, y), "the Friday before is not, in %d" % y)
		if d < 31:
			assert_false(Festivals.in_window(e, 1, d + 2, y), "two days after is not, in %d" % y)
		assert_eq(Festivals.run_year(e, Vector2i(1, d), y), y)
		for day in [24, 25, 26, 27, 28, 29, 30, 31]:
			if day < d - 3 or day > d + 1:
				assert_false(Festivals.in_window(e, 1, day, y), "%d January %d is off" % [day, y])
	# Late December looks ahead to the right January: 2029's is the 30th, not the 2028 window's 22nd.
	assert_eq(Festivals.coming_window(e, Vector2i(12, 28), 2028), [1, 27, 1, 31])
	assert_eq(Festivals.days_until(e, Vector2i(12, 28), 2028), 30)
	assert_eq(Festivals.days_until(e, Vector2i(1, 20), 2029), 7)
	assert_eq(Festivals.days_until(e, Vector2i(1, 30), 2029), 0)

func test_braemar_is_on_the_scottish_dee() -> void:
	var e := Festivals.get_event("braemar")
	assert_eq(str(e.town), "cairngorms", "Braemar is in the Cairngorms National Park, on the Aberdeenshire Dee")
	var q := Festivals.quest_of(e)
	assert_eq(str(q.get("town", "")), "cairngorms")
	for s in q.get("steps", []):
		assert_eq(str(s.get("zone", "")), "cairngorms")
	assert_true(Festivals.in_window(e, 9, 1) and Festivals.in_window(e, 9, 7), "the first Saturday of September always falls from the 1st to the 7th")

func test_braemar_is_held_on_green_grass_not_ski_snow() -> void:
	# w52: Caber Callum stood on the snow by the ski centre in September; the Games are on a green field
	var e := Festivals.get_event("braemar")
	var raw: Dictionary = JsonUtil.read("res://data/zones/cairngorms.json")
	var ch := str(raw.rows[int(e.y)])[int(e.x)]
	assert_eq(str(raw.legend_extra.get(ch, {}).get("colour", "")), "#6f8a52", "the glen's green grass, not the white 'n'")

func test_up_helly_aa_guizers_are_in_viking_gear() -> void:
	# w52: Guizer Magnus wore Blackpool's pink flower crown
	assert_eq(str(Festivals.get_event("uphellyaa").sprite), "guizer")
	assert_true(ResourceLoader.exists("res://art/sprites/chars/guizer.png"))

func test_run_year_follows_the_year_a_new_year_window_opened() -> void:
	var hog := Festivals.get_event("hogmanay")
	assert_eq(Festivals.run_year(hog, Vector2i(12, 31), 2026), 2026)
	assert_eq(Festivals.run_year(hog, Vector2i(1, 1), 2027), 2026, "1 January is still last year's Hogmanay")
	assert_eq(Festivals.run_year(Festivals.get_event("bonfire"), Vector2i(11, 3), 2026), 2026)

func test_a_3_1_run_still_counts_for_its_year_then_starts_afresh() -> void:
	var d := _d()
	d.set_flag("q_festivals_bonfire_started")
	d.set_flag("q_festivals_bonfire_1")
	d.set_flag("q_festivals_bonfire_2")
	d.set_flag("q_festivals_bonfire_done")
	assert_eq(Festivals.rollover(d, Vector2i(11, 3), 2026), [], "same year: nothing resets")
	assert_true(d.flag("q_festivals_bonfire_done") == true)
	assert_true(d.flag("festivals_souv_bonfire") == true, "the 3.1 souvenir is already yours")
	assert_eq(Festivals.rollover(d, Vector2i(11, 3), 2027), ["bonfire"])
	assert_true(d.flag("q_festivals_bonfire_done") == null)
	assert_true(d.flag("q_festivals_bonfire_started") == null)
	assert_true(d.flag("festivals_souv_bonfire") == true, "the souvenir flag survives the new year")
	assert_eq(int(d.flag("festivals_year_bonfire")), 2027)
	assert_eq(Festivals.years_done(d, Festivals.get_event("bonfire")), 1)
	assert_eq(Festivals.rollover(d, Vector2i(11, 4), 2027), [], "once per year")

func test_a_new_save_and_an_unfinished_run() -> void:
	var d := _d()
	assert_eq(Festivals.rollover(d, Vector2i(11, 3), 2026), [])
	assert_eq(int(d.flag("festivals_year_bonfire")), 2026)
	d.set_flag("q_festivals_bonfire_started")
	d.set_flag("q_festivals_bonfire_1")
	Festivals.rollover(d, Vector2i(11, 3), 2027)
	assert_true(d.flag("q_festivals_bonfire_1") == null, "an unfinished run does not carry over")
	assert_true(d.flag("festivals_souv_bonfire") == null, "and earned no souvenir")
	assert_eq(Festivals.years_done(d, Festivals.get_event("bonfire")), 0)

func test_only_the_festival_on_today_rolls_over() -> void:
	var d := _d()
	d.set_flag("q_festivals_burns_done")
	assert_eq(Festivals.rollover(d, Vector2i(11, 3), 2027), ["bonfire"])
	assert_true(d.flag("q_festivals_burns_done") == true, "Burns Night is not on in November")

func test_every_souvenir_is_given_once_and_the_food_every_year() -> void:
	var d: Dictionary = JsonUtil.read("res://data/dialogue/festivals.json")
	var souvenirs := 0
	var stack := [d]
	while not stack.is_empty():
		var n: Variant = stack.pop_back()
		if n is Dictionary:
			if n.get("do") == "give_item" and str(n.item).begins_with("fest_"):
				assert_true(false, "souvenir given outside its once-only guard: " + str(n.item))
			if n.get("do") == "if" and str(n.get("flag", "")).begins_with("festivals_souv_"):
				souvenirs += 1
				assert_true(n.get("else", []).size() == 2, "guarded give plus set")
				continue
			for v in n.values():
				stack.append(v)
		elif n is Array:
			stack.append_array(n)
	assert_true(souvenirs >= 24)
