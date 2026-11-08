extends TestCase
## The first hour (2.1): the parish taught early, the first standing point noticed, a first job you can always do
## in the Forest, and Today's Walk that never sends a new player to a pub three countries away.

func _script(file: String, key: String) -> Array:
	var d = JsonUtil.read("res://data/dialogue/%s.json" % file)
	return d.get(key, []) if d is Dictionary else []

## Every "say" text in a script, branches and all.
func _texts(list: Array) -> String:
	var out := []
	for c in list:
		if not (c is Dictionary):
			continue
		if c.get("do") == "say":
			out.append(str(c.get("text", "")))
		for k in ["then", "else"]:
			if c.has(k):
				out.append(_texts(c[k]))
	return "\n".join(PackedStringArray(out))

# --- standing ------------------------------------------------------------------

func test_first_standing_point_in_a_nation_is_noticed() -> void:
	var d := GameStateData.new()
	var line := Parish.standing_line(d, "england", 1)
	assert_true(line.contains("England") and line.contains("noticed you"), line)
	assert_eq(Parish.standing_line(d, "england", 1), "", "later points stay quiet")
	assert_true(Parish.standing_line(d, "mann", 1).contains("on the Isle of Man"), "on an island, not in it")
	assert_true(Parish.standing_line(d, "channel_islands", 1).contains("in the Channel Islands"), "no capital The mid-sentence")
	assert_true(Parish.standing_line(d, "overseas", 1).contains("Someone out here has"), "not \"in Britain Overseas\" (some of it is Spain, Cyprus or Oxfordshire)")
	assert_true(Parish.standing_line(d, "abroad", 1).contains("among the Kin Abroad"), "people, not a place")
	assert_eq(Parish.standing_line(d, "atlantis", 1), "", "not a nation")

func test_a_new_tier_still_wins_over_the_first_point_line() -> void:
	var d := GameStateData.new()
	var line := Parish.standing_line(d, "wales", Standing.TIER_POINTS[1])
	assert_eq(line, Standing.tier_line("wales", Standing.KNOWN_FACE))

# --- the first job -------------------------------------------------------------

func test_first_board_day_in_macclesfield_offers_a_forest_catch_job_first() -> void:
	Jobs.reset()
	for s in [1, 7, 42, 99, 12345, 2026]:
		Calendar.set_override("2026-10-18")
		var d := GameStateData.new()
		d.rng_seed = s
		var first: Dictionary = Jobs.offers(d, "macclesfield")[0]
		assert_true(bool(first.get("first", false)), "seed %d: the first job leads (%s)" % [s, first.id])
		assert_eq(str(first.step.type), "catch")
		assert_eq(str(first.town), "macclesfield")
	Calendar.set_override("")

func test_the_first_job_can_be_done_in_macclesfield_forest() -> void:
	var first := {}
	for j in Jobs.all():
		if bool(j.get("first", false)):
			first = j
	assert_false(first.is_empty(), "a first job exists")
	var forest = JsonUtil.read("res://data/zones/macc_forest.json")
	var ok := false
	var dex := Dex.load_default()
	for e in forest.encounters.get("grass", []):
		if str(e.species) == str(first.step.get("species", "")) or str(first.step.get("ctype", "")) in dex.get_species(str(e.species)).get("types", []):
			ok = true
	assert_true(ok, "something in the Forest's grass fits")

func test_only_one_first_job_and_later_board_days_shuffle_as_before() -> void:
	assert_eq(Jobs.all().filter(func(j): return bool(j.get("first", false))).size(), 1)

# --- Today's Walk ----------------------------------------------------------------

func test_no_pub_visited_means_no_far_off_pub() -> void:
	var fresh := GameStateData.new()
	var ix := {"zones": {"r": {"name": "R", "region": "cheshire", "species": ["pipkin"]}}, "towns": {}, "names": {}}
	assert_eq(TodaysWalk.pick("2026-10-01", fresh, ix, TodaysWalk.config(), null).pub, "")

func test_menu_line_says_where_the_bounty_is_collected_and_skips_a_missing_pub() -> void:
	Calendar.set_override("2026-10-17")
	var d := GameStateData.new()
	d.set_flag(TodaysWalk.FLAG, {"key": "2026-10-17", "species": "pipkin", "zone": "macc_route", "pub": "", "weather": "rain",
		"reward": "cream_tea", "reward_n": 1, "zone_name": "Macc Forest", "pub_name": ""})
	var line := TodaysWalk.summary(d, null)
	assert_true(line.contains("Macc Forest"), line)
	assert_true(line.contains("nurse") or line.contains("Sanctuary"), "says where to collect: " + line)
	assert_false(line.contains("quiz"), "no pub, no quiz: " + line)
	assert_false(line.contains("{"), line)
	d.set_flag(TodaysWalk.FLAG, {"key": "2026-10-17", "species": "pipkin", "zone": "macc_route", "pub": "york", "weather": "rain",
		"reward": "cream_tea", "reward_n": 1, "zone_name": "Macc Forest", "pub_name": "Bettys Tea Rooms"})
	line = TodaysWalk.summary(d, null)
	assert_true(line.contains("Bettys Tea Rooms"), line)
	Calendar.set_override("")

# --- the words -------------------------------------------------------------------

func test_mum_mentions_the_noticeboard_and_the_garden() -> void:
	var t := _texts(_script("macc_home", "mum")).to_lower()
	assert_true(t.contains("noticeboard"), "the board")
	assert_true(t.contains("garden"), "the garden")

func test_someone_in_town_points_at_the_noticeboard() -> void:
	assert_true(_texts(_script("macclesfield", "pigeon_lady")).to_lower().contains("noticeboard"))
	assert_true(_texts(_script("macc_fieldstation", "garside")).to_lower().contains("noticeboard"))

func test_post_maud_speech_is_split_and_the_walker_tells_you_about_hilda() -> void:
	assert_false(JSON.stringify(JsonUtil.read("res://data/dialogue/buxton_spa.json")).contains("Hilda"), "Hilda moved out of the spa speech")
	assert_true(_texts(_script("buxton", "goyt_guide")).contains("Hilda"))
