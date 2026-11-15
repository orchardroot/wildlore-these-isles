extends TestCase
## Wave 57, the Walkers' League: a champion on each of the thirty new roads, a weekly rematch at par with a team that
## follows the season and the weather, titles at ten, twenty and thirty with keepsakes, and old saves.

class RecHost extends FakeStoryHost:
	var fought: Array = []

	func battle(foe_party: Array, opts: Dictionary) -> Dictionary:
		fought.append(opts.trainer.duplicate(true))
		return super.battle(foe_party, opts)

const WEEK1 := "2026-11-09"   # a Monday
const WEEK1_SUN := "2026-11-15"
const WEEK2 := "2026-11-16"

func _host() -> RecHost:
	var h := RecHost.new()
	h.dex = Dex.load_default()
	h.moves = MoveDB.load_default()
	h.data.weather = "clear"
	return h

func _run(h: FakeStoryHost, id: String) -> void:
	StoryData.clear_cache()
	var champ := RouteChampions.get_champion(id)
	h.zone = str(champ.zone)
	await Commands.new(h, id).run(StoryData.script(str(champ.zone), "champ_" + id))

func _said_has(h: FakeStoryHost, needle: String) -> bool:
	for line in h.said:
		if String(line[1]).contains(needle):
			return true
	return false

# ---------------------------------------------------------------- the data

func test_every_champion_is_a_real_trainer_on_a_real_road() -> void:
	var zones := {}
	for c in RouteChampions.all():
		zones[str(c.zone)] = ZoneData.load_id(str(c.zone))
	var errs := RouteChampions.problems(zones, Dex.load_default())
	assert_eq(errs, [], "\n".join(errs))

func test_the_team_suits_the_place() -> void:
	# every creature a champion fields is wild on that road or on one of its trainers' teams
	for c in RouteChampions.all():
		var z := ZoneData.load_id(str(c.zone))
		var found := {}
		for kind in z.encounters:
			for e in z.encounters[kind]:
				found[str(e.species)] = true
		for n in z.npcs:
			if str(n.get("trainer", "")) != "":
				for m in StoryData.trainer(str(n.trainer)).party:
					found[str(m.species)] = true
		var mine: Array = c.stay.duplicate()
		for s in c.season.values():
			mine.append(s)
		for w in c.weather.values():
			mine.append(w)
		for sp in mine:
			assert_true(found.has(str(sp)), "%s: %s belongs on the %s road" % [c.id, sp, c.route])
		assert_eq(mine.size(), 9, c.id + ": two stayers, four seasons, three kinds of weather")
		assert_eq(mine.size(), _unique(mine).size(), c.id + ": nobody twice")

func _unique(a: Array) -> Array:
	var seen := {}
	for x in a:
		seen[x] = true
	return seen.keys()

func test_a_champion_is_the_strongest_on_the_road() -> void:
	for c in RouteChampions.all():
		var z := ZoneData.load_id(str(c.zone))
		var mine := StoryData.trainer(str(c.id))
		var top := 0
		for n in z.npcs:
			if str(n.get("trainer", "")) != "":
				top = maxi(top, int(StoryData.trainer(str(n.trainer)).money))
		assert_eq(int(mine.money), top, "%s is on the top purse of the road" % c.id)
		assert_eq(int(mine.scaled_floor), int(c.floor), c.id + ": the floor in the data is the trainer's")

func test_the_thirty_roads_of_waves_55_and_56() -> void:
	assert_eq(RouteChampions.total(), 30)
	var zones := {}
	for c in RouteChampions.all():
		zones[str(c.zone)] = true
	assert_eq(zones.size(), 30, "one champion a road")

# ---------------------------------------------------------------- the weekly rematch

func test_a_rematch_is_open_once_beaten_and_shut_for_the_rest_of_the_week() -> void:
	var d := GameStateData.new()
	Calendar.set_override(WEEK1)
	assert_false(RouteChampions.rematch_open(d, "ag_osprey"), "not before the first win")
	d.set_flag("trainer_ag_osprey", true)
	assert_true(RouteChampions.rematch_open(d, "ag_osprey"))
	RouteChampions.record_rematch(d, "ag_osprey")
	assert_false(RouteChampions.rematch_open(d, "ag_osprey"))
	Calendar.set_override(WEEK1_SUN)
	assert_false(RouteChampions.rematch_open(d, "ag_osprey"), "Sunday is still the same week")
	Calendar.set_override(WEEK2)
	assert_true(RouteChampions.rematch_open(d, "ag_osprey"), "Monday starts a new one")
	assert_eq(RouteChampions.wins(d, "ag_osprey"), 1)
	assert_true(RouteChampions.rematch_open(d, "hp_cornish") == false, "each champion has their own week")
	Calendar.set_override("")

func test_the_week_is_used_by_a_win_and_not_by_a_loss_or_a_no() -> void:
	Calendar.set_override(WEEK1)
	var h := _host()
	h.data.set_flag("trainer_ag_osprey", true)
	h.choices = [1]
	await _run(h, "ag_osprey")
	assert_eq(h.fought.size(), 0, "declined")
	h.choices = [0]
	h.battle_results = [{"result": "lose"}]
	h.data.money = 1000
	h.data.last_sanctuary = {"zone": "macclesfield", "pos": [3, 4]}
	await _run(h, "ag_osprey")
	assert_eq(h.fought.size(), 1)
	assert_eq(h.data.money, 500, "a loss is the usual whiteout")
	assert_true(RouteChampions.rematch_open(h.data, "ag_osprey"), "and does not use up the week")
	h.choices = [0]
	await _run(h, "ag_osprey")
	assert_eq(h.fought.size(), 2)
	assert_false(RouteChampions.rematch_open(h.data, "ag_osprey"), "a win does")
	assert_eq(RouteChampions.wins(h.data, "ag_osprey"), 1)
	h.choices = [0]
	await _run(h, "ag_osprey")
	assert_eq(h.fought.size(), 2, "no second fight in the week")
	assert_true(_said_has(h, "Monday"))
	Calendar.set_override(WEEK2)
	h.choices = [0]
	await _run(h, "ag_osprey")
	assert_eq(h.fought.size(), 3, "a new week, a new rematch")
	Calendar.set_override("")

func test_an_unbeaten_champion_offers_no_rematch() -> void:
	var h := _host()
	await _run(h, "ag_osprey")
	assert_eq(h.fought.size(), 0)

# ---------------------------------------------------------------- par and the team of the day

func test_the_rematch_is_at_par_and_pays_a_little() -> void:
	var c := RouteChampions.get_champion("ag_osprey")
	var t := StoryData.trainer("ag_osprey")
	for flag in ["", "badge_storm", "badge_tide", "game_complete"]:
		var flags := {}
		if flag != "":
			flags[flag] = true
		var par := ParLevel.par(flags)
		var def := RouteChampions.rematch_def(c, t, "summer", "clear", flags)
		var foes := TrainerParty.build(def, Dex.load_default(), Rng.new(1), MoveDB.load_default(), 0, flags)
		assert_eq(foes.size(), 4)
		var at := maxi(par, int(t.scaled_floor))
		var top := 0
		for f in foes:
			top = maxi(top, f.level)
			assert_true(f.level >= at and f.level <= at + 1, "level %d at par %d" % [f.level, par])
		assert_eq(top, at + 1, "the last is a step above par")
		assert_eq(int(def.money), par * RouteChampions.PRIZE_PER_LEVEL)
		assert_true(int(def.money) < 1000, "small")

func test_the_season_and_the_weather_change_the_team() -> void:
	var c := RouteChampions.get_champion("hp_cornish")
	var sets := {}
	for season in RouteChampions.SEASONS:
		sets[RouteChampions.team_species(c, season, "clear")[2]] = true
	assert_eq(sets.size(), 4, "a different creature every season")
	var w := {}
	for weather in ["clear", "sunshine", "drizzle", "downpour", "gale", "fog", "frost", "snow"]:
		w[RouteChampions.team_species(c, "spring", weather)[3]] = true
	assert_eq(w.size(), 3, "three kinds of weather: wet, rough and fair")
	assert_eq(RouteChampions.weather_kind("downpour"), "wet")
	assert_eq(RouteChampions.weather_kind("frost"), "rough")
	assert_eq(RouteChampions.weather_kind("sunshine"), "fair")
	assert_eq(RouteChampions.team_species(c, "winter", "fog").slice(0, 2), c.stay, "the stayers always come")

func test_the_rematch_fought_follows_the_day() -> void:
	Calendar.set_override("2026-12-02")   # winter
	var h := _host()
	h.data.weather = "drizzle"
	h.data.set_flag("trainer_hp_cornish", true)
	h.choices = [0]
	await _run(h, "hp_cornish")
	assert_eq(h.fought.size(), 1)
	var c := RouteChampions.get_champion("hp_cornish")
	var got: Array = h.fought[0].party.map(func(m): return str(m.species))
	assert_eq(got, [c.stay[0], c.stay[1], c.season.winter, c.weather.wet])
	assert_true(_said_has(h, "winter"), "the team of the day is announced before the choice")
	Calendar.set_override("")

func test_a_rematch_win_pays_through_the_battle_and_says_its_line() -> void:
	Calendar.set_override(WEEK1)
	var h := _host()
	h.data.set_flag("trainer_trt_guide", true)
	h.choices = [0]
	await _run(h, "trt_guide")
	assert_eq(int(h.fought[0].money), ParLevel.par(h.data.flags) * RouteChampions.PRIZE_PER_LEVEL)
	assert_true(_said_has(h, "beaten and the path still there"))
	Calendar.set_override("")

# ---------------------------------------------------------------- the first win, titles, old saves

func test_the_first_win_is_dated_once() -> void:
	Calendar.set_override(WEEK1)
	var h := _host()
	await _first(h, "ag_osprey")
	assert_eq(RouteChampions.first_date(h.data, "ag_osprey"), WEEK1)
	Calendar.set_override(WEEK2)
	await _first(h, "ag_osprey")
	assert_eq(RouteChampions.first_date(h.data, "ag_osprey"), WEEK1, "the first date stands")
	Calendar.set_override("")

func _first(h: FakeStoryHost, id: String) -> void:
	StoryData.clear_cache()
	await Commands.new(h, id).run([{"do": "battle", "trainer": id}])

func test_an_old_save_counts_a_beaten_champion_once() -> void:
	var d := GameStateData.new()
	d.set_flag("trainer_ag_osprey", true)
	d.set_flag("trainer_hp_cornish", true)
	assert_eq(RouteChampions.beaten_count(d), 2)
	assert_eq(RouteChampions.first_date(d, "ag_osprey"), "", "no date: beaten before the League")
	assert_true(RouteChampions.rematch_open(d, "ag_osprey"), "and can be rematched")
	d.set_flag("trainer_ag_osprey", true)
	assert_eq(RouteChampions.beaten_count(d), 2, "still once")
	assert_eq(RouteChampions.beaten_count(GameStateData.new()), 0)

func test_titles_at_ten_twenty_and_thirty() -> void:
	var t := RouteChampions.titles()
	assert_eq(t.map(func(x): return int(x.at)), [10, 20, 30])
	assert_eq(RouteChampions.titles_earned(9).size(), 0)
	assert_eq(RouteChampions.titles_earned(10).size(), 1)
	assert_eq(RouteChampions.titles_earned(25).size(), 2)
	assert_eq(RouteChampions.titles_earned(30).size(), 3)
	var d := GameStateData.new()
	assert_eq(RouteChampions.current_title(d), {})
	assert_eq(int(RouteChampions.next_title(d).at), 10)
	var ids := RouteChampions.ids()
	for i in mini(ids.size(), 10):
		d.set_flag("trainer_" + str(ids[i]), true)
	if ids.size() >= 10:
		assert_eq(str(RouteChampions.current_title(d).name), "Waymarker")
		assert_eq(int(RouteChampions.next_title(d).at), 20)

func test_a_title_is_announced_once_and_an_old_save_hears_of_all_it_has() -> void:
	var d := GameStateData.new()
	var ids := RouteChampions.ids()
	var n := mini(ids.size(), 22)
	for i in n:
		d.set_flag("trainer_" + str(ids[i]), true)
	var got := RouteChampions.take_new_titles(d)
	assert_eq(got.size(), RouteChampions.titles_earned(n).size(), "everything earned so far")
	assert_eq(RouteChampions.take_new_titles(d), [], "and only once")

func test_the_win_that_makes_ten_announces_a_title() -> void:
	var ids := RouteChampions.ids()
	if ids.size() < 10:
		return
	var h := _host()
	for i in 9:
		h.data.set_flag("trainer_" + str(ids[i]), true)
	h.data.set_flag(RouteChampions.TITLES_FLAG, 0)
	await _first(h, str(ids[9]))
	assert_true(_said_has(h, "Waymarker"))
	assert_true(_said_has(h, "Walking Stick Badge"), "the keepsake is mentioned, by its proper name")

func test_each_title_leaves_a_keepsake_for_the_shelf() -> void:
	for t in RouteChampions.titles():
		var id := RouteChampions.keepsake_id(t)
		var s := HomeExtras.souvenir(id)
		assert_false(s.is_empty(), id + " is on the souvenir list")
		var d := GameStateData.new()
		assert_false(id in HomeExtras.unlocked(d, []), "not before the title")
		var ids := RouteChampions.ids()
		for i in mini(ids.size(), int(t.at)):
			d.set_flag("trainer_" + str(ids[i]), true)
		if ids.size() >= int(t.at):
			assert_true(id in HomeExtras.unlocked(d, []), id + " once it is earned")
			assert_true(HomeExtras.place(d, 1, id, []), id + " can be set on the shelf")
		assert_false("—" in str(s.line))

# ---------------------------------------------------------------- the Almanac page

func test_the_page_sprouts_with_the_first_champion() -> void:
	var d := GameStateData.new()
	assert_false(Almanac.pages(d).any(func(p): return p.id == "walkers"))
	d.set_flag("trainer_ag_osprey", true)
	var page: Array = Almanac.pages(d).filter(func(p): return p.id == "walkers")
	assert_eq(page.size(), 1)
	assert_eq(str(page[0].menu), "ledger:walkers")
	assert_true(str(page[0].blurb).contains("1 of %d" % RouteChampions.total()))

func test_the_page_rows_say_who_and_when() -> void:
	var d := GameStateData.new()
	d.set_flag("trainer_ag_osprey", true)
	d.set_flag(RouteChampions.FIRST_PREFIX + "ag_osprey", "2026-11-09")
	var rows := RouteChampions.rows(d)
	assert_eq(rows.size(), RouteChampions.total())
	var r: Dictionary = rows.filter(func(x): return x.id == "ag_osprey")[0]
	assert_true(r.beaten and r.open)
	assert_eq(r.date, "2026-11-09")
	assert_eq(r.name, "Osprey Watcher Bethan")

# ---------------------------------------------------------------- the economy and the words

func test_a_champion_never_out_earns_a_keeper() -> void:
	var keeper: int = int(StoryData.trainer("keeper_morwen_rematch").money)
	assert_true(RouteChampions.prize(100) * 5 < keeper, "a week of one champion is far under a day of one Keeper")
	var weekly := RouteChampions.weekly_pay(97)
	assert_true(weekly < keeper * 7, "all thirty in a week come to less than one Keeper's week (%d)" % weekly)

func test_no_em_dashes_in_what_a_player_reads() -> void:
	for c in RouteChampions.all():
		for line in StoryData.script(str(c.zone), "champ_" + str(c.id)):
			assert_false("—" in JSON.stringify(line), c.id)

# ---------------------------------------------------------------- Kit on three roads

const KIT_ROADS := [["pen_y_gwryd", "kit_pyg", "kit_road_pyg", "ch3_ddraig_woke", "badge_storm"],
	["hook_head", "kit_hook", "kit_road_hook", "badge_kin", "badge_tide"],
	["west_highland_way", "kit_whw", "kit_road_whw", "strachan1_done", "badge_frost"]]

func test_kit_stands_on_three_roads_between_two_story_points() -> void:
	for k in KIT_ROADS:
		var npc := {}
		for n in ZoneData.load_id(k[0]).npcs:
			if str(n.get("id", "")) == k[1]:
				npc = n
		assert_eq(str(npc.get("show_if", "")), k[3], k[1])
		assert_eq(str(npc.get("hide_if", "")), k[4], k[1])
		assert_eq(str(npc.get("sprite", "")), "kit")
		assert_false(npc.has("trainer"), "his battle is offered, never sprung")
		assert_eq(int(StoryData.trainer(k[2]).scaled_floor), int(ZoneData.load_id(k[0]).scaled_floor), "at the par of the road")

func test_kit_offers_a_battle_once_and_you_can_say_no() -> void:
	for k in KIT_ROADS:
		var h := _host()
		h.choices = [1]
		StoryData.clear_cache()
		await Commands.new(h, k[1]).run(StoryData.script(k[0], k[1]))
		assert_eq(h.fought.size(), 0, k[1] + ": declined")
		h.choices = [0]
		await Commands.new(h, k[1]).run(StoryData.script(k[0], k[1]))
		assert_eq(h.fought.size(), 1, k[1] + ": accepted")
		assert_true(h.data.flag("trainer_" + k[2]) == true)
		await Commands.new(h, k[1]).run(StoryData.script(k[0], k[1]))
		assert_eq(h.fought.size(), 1, k[1] + ": paid and won once, then only talk")
