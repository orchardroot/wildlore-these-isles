extends TestCase
## Seasons and festivals from the real date (Calendar), the --date dev switch, and the `when` conditions for them.

func test_meteorological_seasons() -> void:
	assert_eq(Calendar.season_for(3, 1), "spring")
	assert_eq(Calendar.season_for(5, 31), "spring")
	assert_eq(Calendar.season_for(6, 1), "summer")
	assert_eq(Calendar.season_for(8, 31), "summer")
	assert_eq(Calendar.season_for(9, 1), "autumn")
	assert_eq(Calendar.season_for(10, 17), "autumn")
	assert_eq(Calendar.season_for(11, 30), "autumn")
	assert_eq(Calendar.season_for(12, 1), "winter")
	assert_eq(Calendar.season_for(1, 15), "winter")
	assert_eq(Calendar.season_for(2, 29), "winter")

func test_festivals_and_their_edges() -> void:
	assert_eq(Calendar.festival_for(10, 23), "")
	assert_eq(Calendar.festival_for(10, 24), "halloween")
	assert_eq(Calendar.festival_for(10, 31), "halloween")
	assert_eq(Calendar.festival_for(11, 1), "bonfire_night")
	assert_eq(Calendar.festival_for(11, 7), "bonfire_night")
	assert_eq(Calendar.festival_for(11, 8), "")
	assert_eq(Calendar.festival_for(12, 1), "christmas")
	assert_eq(Calendar.festival_for(12, 31), "christmas")
	assert_eq(Calendar.festival_for(1, 1), "")
	assert_eq(Calendar.festival_for(1, 25), "burns_night")
	assert_eq(Calendar.festival_for(3, 1), "st_davids")
	assert_eq(Calendar.festival_for(3, 17), "st_patricks")
	assert_eq(Calendar.festival_for(3, 18), "")
	assert_eq(Calendar.festival_for(7, 4), "", "not round here")

func test_every_festival_is_a_known_condition() -> void:
	for f in Calendar.FESTIVALS:
		assert_true(f in StoryValidator.CONDITIONS, f)
	for s in Calendar.SEASONS:
		assert_true(s in StoryValidator.CONDITIONS, s)

func test_national_days_belong_to_their_nation() -> void:
	assert_eq(Calendar.nation_for_region("ireland_west"), "ireland")
	assert_eq(Calendar.nation_for_region("ireland"), "ireland")
	assert_eq(Calendar.nation_for_region("south_wales"), "wales")
	assert_eq(Calendar.nation_for_region("north_wales"), "wales")
	assert_eq(Calendar.nation_for_region("scotland"), "scotland")
	assert_eq(Calendar.nation_for_region("cheshire"), "england")
	assert_true(Calendar.festival_here("st_patricks", "ireland_east"))
	assert_false(Calendar.festival_here("st_patricks", "cheshire"))
	assert_true(Calendar.festival_here("burns_night", "scotland"))
	assert_true(Calendar.festival_here("halloween", "cheshire"), "everyone gets Halloween")
	assert_false(Calendar.festival_here("", "cheshire"))

func test_override_parses_mm_dd() -> void:
	Calendar.set_override("10-31")
	assert_eq(Calendar.today(), Vector2i(10, 31))
	assert_eq(Calendar.season_today(), "autumn")
	assert_eq(Calendar.festival_today(), "halloween")
	Calendar.set_override("12-25")
	assert_eq(Calendar.festival_today(), "christmas")
	assert_eq(Calendar.season_today(), "winter")
	Calendar.set_override("nonsense")
	var d := Time.get_date_dict_from_system()
	assert_eq(Calendar.today(), Vector2i(int(d.month), int(d.day)), "a bad override falls back to the real date")
	Calendar.set_override("")
	assert_eq(Calendar.today(), Vector2i(int(d.month), int(d.day)))

func test_dev_arg_date() -> void:
	assert_eq(DevArgs.parse(PackedStringArray(["--date=11-05"])).date, "11-05")
	assert_eq(DevArgs.parse(PackedStringArray()).date, "", "no switch: the real date")

func test_foliage_tint_follows_the_season() -> void:
	var summer := Calendar.foliage_tint(7, 10)
	assert_eq(summer, Vector3.ZERO, "summer leaves as painted")
	var early := Calendar.foliage_tint(9, 5)
	var mid := Calendar.foliage_tint(10, 17)
	var late := Calendar.foliage_tint(11, 20)
	assert_true(early.y > 0.0 and early.y < mid.y and mid.y <= late.y, "autumn deepens through the season")
	assert_eq(early.x, 0.0)
	assert_eq(early.z, 0.0)
	assert_true(Calendar.foliage_tint(4, 20).x > 0.0, "spring blossom")
	assert_true(Calendar.foliage_tint(1, 10).z > 0.0, "winter frost")
	for m in range(1, 13):
		var t := Calendar.foliage_tint(m, 15)
		for i in 3:
			assert_true(t[i] >= 0.0 and t[i] <= 1.0, "month %d" % m)

## w51: St Helena's trees went russet in November and a Cayman frost was possible in January.
func test_overseas_trees_keep_their_own_year() -> void:
	assert_eq(Calendar.foliage_tint_in("overseas_st_helena", 11, 20), Vector3.ZERO, "no autumn in the tropics")
	assert_eq(Calendar.foliage_tint_in("overseas_cayman", 1, 10), Vector3.ZERO, "no frost on the palms")
	assert_eq(Calendar.foliage_tint_in("overseas_falklands", 11, 20), Calendar.foliage_tint(5, 20), "November is late spring down south")
	assert_true(Calendar.foliage_tint_in("overseas_falklands", 4, 20).y > 0.0, "and April is autumn")
	assert_eq(Calendar.foliage_tint_in("cheshire", 11, 20), Calendar.foliage_tint(11, 20), "home as before")
	assert_eq(Calendar.local_month("abroad_patagonia", 1), 7)
	assert_eq(Calendar.local_month("abroad_patagonia", 7), 1)
	Calendar.set_override("01-10")
	assert_eq(Calendar.season_in("overseas_cayman"), "", "the tropics keep no winter")
	assert_eq(Calendar.season_in("overseas_falklands"), "summer")
	assert_eq(Calendar.season_in("cheshire"), "winter")
	Calendar.set_override("")

func test_winter_makes_frost_a_bit_likelier() -> void:
	var table := {"drizzle": 45, "clear": 35, "frost": 10}
	assert_eq(Calendar.seasonal_weather(table, "autumn"), table, "only winter changes the odds")
	var w := Calendar.seasonal_weather(table, "winter")
	assert_true(float(w.frost) > 10.0)
	assert_eq(w.drizzle, 45)
	assert_eq(table.frost, 10, "the zone's own table is untouched")
	var no_frost := Calendar.seasonal_weather({"drizzle": 50, "clear": 50}, "winter")
	assert_true(float(no_frost.get("frost", 0)) > 0.0, "a chance of frost even where there's usually none")
	assert_true(float(no_frost.frost) < 10.0, "but only a small one")
	assert_eq(Calendar.seasonal_weather({}, "winter"), {}, "no weather (interiors, caves) stays none")

# --- `when` conditions ---------------------------------------------------------------

func _said(cond: String) -> bool:
	var h := FakeStoryHost.new()
	await Commands.new(h).run([{"do": "when", "cond": cond, "then": [{"do": "say", "text": "yes"}], "else": [{"do": "say", "text": "no"}]}])
	return h.texts() == ["yes"]

func test_when_season_and_festival() -> void:
	Calendar.set_override("10-31")
	assert_true(await _said("autumn"))
	assert_false(await _said("winter"))
	assert_true(await _said("halloween"))
	assert_false(await _said("christmas"))
	Calendar.set_override("11-05")
	assert_true(await _said("bonfire_night"))
	assert_false(await _said("halloween"))
	Calendar.set_override("12-20")
	assert_true(await _said("christmas"))
	assert_true(await _said("winter"))
	for cond in Calendar.SEASONS + Calendar.FESTIVALS:
		var errs := StoryValidator.validate_commands([{"do": "when", "cond": cond, "then": [{"do": "say", "text": "x"}]}], "t", Fixtures.dex(), ItemDB.load_default(), {})
		assert_eq(errs, [], cond)
	Calendar.set_override("")

# --- today_key (the real-date daily key) ------------------------------------------------

func test_today_key_is_the_real_date() -> void:
	Calendar.set_override("")
	var d := Time.get_date_dict_from_system()
	assert_eq(Calendar.today_key(), "%04d-%02d-%02d" % [int(d.year), int(d.month), int(d.day)])

func test_today_key_honours_the_date_switch() -> void:
	Calendar.set_override("2027-03-17")
	assert_eq(Calendar.today_key(), "2027-03-17")
	assert_eq(Calendar.today(), Vector2i(3, 17), "a full date pins the month and day too")
	assert_eq(Calendar.festival_today(), "st_patricks")
	Calendar.set_override("12-25")
	var y := int(Time.get_date_dict_from_system().year)
	assert_eq(Calendar.today_key(), "%04d-12-25" % y, "MM-DD keeps this year")
	Calendar.set_override("2027-13-01")
	assert_eq(Calendar.today_key().length(), 10, "a bad date falls back to the real one")
	assert_false(Calendar.today_key().begins_with("2027-13"))
	Calendar.set_override("")

func test_today_key_sorts_and_is_padded() -> void:
	Calendar.set_override("2026-01-05")
	var a := Calendar.today_key()
	Calendar.set_override("2026-10-17")
	var b := Calendar.today_key()
	Calendar.set_override("")
	assert_eq(a, "2026-01-05")
	assert_true(a < b, "keys sort by date")

func test_dev_arg_full_date() -> void:
	assert_eq(DevArgs.parse(PackedStringArray(["--date=2026-12-25"])).date, "2026-12-25")
