extends TestCase
## The legend hunt (5.4): each legend has real folklore rumours told once by named residents; hearing one sets a flag,
## rings the place on the map and gives the Fieldbook a clue in place of "somewhere secret".

const Pedia = preload("res://ui/pedia_screen.gd")

func _data() -> GameStateData:
	return GameStateData.new()

func test_every_hunt_is_valid() -> void:
	var errs := Rumours.check(ZoneData.load_all(), Dex.load_default())
	assert_eq(errs, [], "legend hunts: %s" % str(errs))

func test_every_stood_legend_with_a_story_has_a_hunt() -> void:
	for sp in ["shuck", "lambton", "nessie", "ddraig", "enbarr", "balor", "hereward", "herne", "greenman", "bran", "morrigan",
			"cusith", "nuckelavee", "knucker", "silvershod", "tchian", "tylwyth"]:
		assert_false(Rumours.hunt_of(sp).is_empty(), sp)
	assert_true(Rumours.hunts().size() >= 25, "a rumour for most of the legends: %d" % Rumours.hunts().size())

func test_a_resident_tells_a_rumour_once_and_sets_the_flag() -> void:
	var d := _data()
	var base := [{"do": "say", "who": "", "text": "Hello."}]
	var out := Rumours.hook("whitby", "wby_oldsalt", base, d)
	assert_eq(out.size(), 3, "their own lines, then the rumour and its flag")
	assert_eq(out[0], base[0], "what they would have said comes first")
	assert_true(str(out[1].text).contains("Barghest"))
	assert_eq(out[2].flag, Rumours.heard_key("shuck", 0))
	d.set_flag(out[2].flag)
	assert_eq(Rumours.hook("whitby", "wby_oldsalt", base, d), base, "told once")

func test_a_stranger_says_nothing_extra() -> void:
	var base := [{"do": "say", "who": "", "text": "Hello."}]
	assert_eq(Rumours.hook("whitby", "nobody", base, _data()), base)
	assert_eq(Rumours.hook("macclesfield", "wby_oldsalt", base, _data()), base, "the right resident in the right place")

func test_a_legend_already_caught_is_not_gossiped_about() -> void:
	var d := _data()
	d.caught["shuck"] = true
	var base := [{"do": "say", "who": "", "text": "Hello."}]
	assert_eq(Rumours.hook("whitby", "wby_oldsalt", base, d), base)

func test_the_clue_replaces_somewhere_secret() -> void:
	var d := _data()
	assert_eq(Rumours.clue(d, "shuck"), "")
	assert_eq(Pedia.found_in([], Rumours.clue(d, "shuck")), "Found in: somewhere secret")
	d.set_flag(Rumours.heard_key("shuck", 0))
	var c := Rumours.clue(d, "shuck")
	assert_true(c.contains("Whitby"), c)
	assert_eq(Pedia.found_in([], c), "Rumour: " + c)
	d.set_flag(Rumours.heard_key("shuck", 1))
	assert_true(Rumours.clue(d, "shuck") != c, "the second rumour sharpens the clue")
	assert_eq(Pedia.found_in(["Whitby"], c), "Found in: Whitby. Rumour: " + c)

func test_heard_legends_are_marked_on_the_map() -> void:
	var d := _data()
	assert_eq(Rumours.marks(d), [], "nothing heard, nothing marked")
	d.set_flag(Rumours.heard_key("lambton", 0))
	var m := Rumours.marks(d)
	assert_eq(m.size(), 1)
	assert_eq(m[0].at, "penshaw")
	assert_true(m[0].ring)
	assert_false(m[0].done)
	d.caught["lambton"] = true
	assert_true(Rumours.marks(d)[0].done, "ticked once caught")

func test_the_hook_reaches_the_resident_through_script_hooks() -> void:
	var d := _data()
	var out := ScriptHooks.wrap("whitby", "wby_oldsalt", [{"do": "say", "who": "", "text": "Hello."}], d)
	assert_true(out.any(func(c): return c is Dictionary and str(c.get("text", "")).contains("Barghest")), "the rumour rides along with the chat")
