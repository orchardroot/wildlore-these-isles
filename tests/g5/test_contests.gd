extends TestCase
## Gurning, welly wanging and the Games League (wave 48 G5).

func _data() -> GameStateData:
	return GameStateData.new()

func test_gurning_sequence_grows_and_never_triples() -> void:
	var rng := Rng.new(5)
	var s := Gurning.start_sequence(rng)
	assert_eq(s.size(), Gurning.START_LEN)
	for i in 60:
		s = Gurning.extend(s, rng)
	assert_eq(s.size(), Gurning.START_LEN + 60)
	for i in range(2, s.size()):
		assert_false(s[i] == s[i - 1] and s[i] == s[i - 2], "no three alike at %d" % i)

func test_gurning_each_direction_has_a_face() -> void:
	for d in ["up", "right", "down", "left"]:
		assert_true(Gurning.face_for_dir(d) >= 0, d)
	assert_true(Gurning.is_correct([2, 1], 1, 1))
	assert_false(Gurning.is_correct([2, 1], 0, 1))

func test_gurning_easier_is_gentler() -> void:
	assert_true(Gurning.slips_allowed(true) > Gurning.slips_allowed(false))
	assert_true(Gurning.show_time(5, true) > Gurning.show_time(5, false))
	assert_eq(Gurning.answer_time(true), 0.0)

func test_gurning_finish_pays_once_then_daily() -> void:
	var d := _data()
	var a := Gurning.finish(d, "egremont", 8, true)
	assert_true(bool(a.first))
	assert_true(int(a.money) > 0)
	assert_eq(Gurning.best(d), 8)
	var b := Gurning.finish(d, "egremont", 9, true)
	assert_false(bool(b.first))
	assert_eq(int(b.money), Gurning.DAILY_PURSE)
	var c := Gurning.finish(d, "egremont", 9, true)
	assert_eq(int(c.money), 0, "once a day")
	assert_eq(int(Gurning.finish(d, "egremont", 1, false).money), 0)

func test_welly_release_in_the_gap_beats_a_bad_one() -> void:
	var good := WellyWang.wang(0.8, WellyWang.IDEAL, 0.0)
	var late := WellyWang.wang(0.8, 85.0, 0.0)
	var low := WellyWang.wang(0.8, 5.0, 0.0)
	assert_true(float(good.metres) > float(late.metres) + 3.0)
	assert_true(float(good.metres) > float(low.metres) + 3.0)

func test_welly_behind_you_is_a_foul() -> void:
	var r := WellyWang.wang(0.8, 200.0, 0.0)
	assert_true(bool(r.foul))
	assert_eq(float(r.metres), 0.0)

func test_welly_wind_and_spin_matter() -> void:
	var calm := float(WellyWang.wang(0.7, WellyWang.IDEAL, 0.0).metres)
	assert_true(float(WellyWang.wang(0.7, WellyWang.IDEAL, 5.0).metres) > calm + 1.0, "tail wind helps")
	assert_true(float(WellyWang.wang(0.7, WellyWang.IDEAL, -5.0).metres) < calm - 1.0, "head wind hurts")
	assert_true(float(WellyWang.wang(0.9 - 0.3, WellyWang.IDEAL, 0.0).metres) < float(WellyWang.wang(0.8, WellyWang.IDEAL, 0.0).metres))

func test_welly_dizzy_spin_wobbles_the_aim() -> void:
	var steady := WellyWang.wang(0.8, WellyWang.IDEAL, 0.0, 30.0)
	assert_false(bool(steady.dizzy), "jitter ignored below the dizzy line")
	var wobbly := WellyWang.wang(0.95, WellyWang.IDEAL, 0.0, 30.0)
	assert_true(bool(wobbly.dizzy))
	assert_true(float(wobbly.quality) < 1.0)

func test_welly_easier_pulls_towards_the_gap() -> void:
	assert_true(absf(WellyWang.assist(70.0, true) - WellyWang.IDEAL) < absf(70.0 - WellyWang.IDEAL))
	assert_eq(WellyWang.assist(70.0, false), 70.0)

func test_welly_a_sane_spread_of_distances_and_a_beatable_rival() -> void:
	var rng := Rng.new(9)
	var rival: Dictionary = WellyWang.venue("upperthong").rival
	var wins := 0
	for i in 200:
		var rb := WellyWang.local_best(rival, rng)
		assert_true(rb > 5.0 and rb < 50.0, "rival %.1f" % rb)
		if float(WellyWang.wang(0.8, WellyWang.IDEAL, 0.0).metres) > rb:
			wins += 1
	assert_true(wins > 40 and wins < 190, "a good wang beats the champion sometimes (%d/200)" % wins)

func test_gurning_rival_is_beatable() -> void:
	var rng := Rng.new(3)
	var rival: Dictionary = Gurning.venue("egremont").rival
	for i in 50:
		var b := Gurning.local_best(rival, rng)
		assert_true(b >= 2 and b <= Gurning.MAX_LEN)

func test_pieces_data_is_consistent() -> void:
	var e := PartyPieces.entries()
	for id in ["gurning", "welly_wang"]:
		assert_true(e.has(id), id)
		assert_true(float(e[id].master) > float(e[id].good), id)
		assert_true(ResourceLoader.exists("res://data/zones/%s.json" % str(e[id].zone)), id)
	var moves = JsonUtil.read("res://data/moves/pieces_g5.json")
	var ids := []
	for m in moves:
		ids.append(str(m.id))
		assert_true(m.has("piece"), str(m.id))
	assert_has(ids, "gurn")
	assert_has(ids, "welly_wang")

func test_league_stamps_and_letters() -> void:
	var d := _data()
	assert_eq(GamesLeague.stamps(d), 0)
	PartyPieces.record(d, "gurning", 3.0)
	assert_eq(GamesLeague.stamps(d), 1)
	assert_true(GamesLeague.due_letters(d).is_empty())
	var rows := GamesLeague.rows(d)
	assert_true(rows.size() >= 2)
	var goal := GamesLeague.next_goal(d)
	assert_eq(int(goal.need), 10)

func test_league_letter_at_ten_stamps_once() -> void:
	var d := _data()
	d.set_flag("pieces_stub", {})
	# fake ten games through the real state: a dict of plays on whichever store GamesLeague reads
	var store: Dictionary = d.pieces if "pieces" in d else d.flag("pieces_stub")
	for i in 10:
		store["fake_%d" % i] = {"best": 1.0, "plays": 1, "rosette": 1}
	# stamps only count games the Isles list, so list ten through the entries cache
	var saved := PartyPieces.entries().duplicate(true)
	for i in 10:
		PartyPieces._cache["fake_%d" % i] = {"name": "Fake %d" % i, "zone": "keswick", "move": "gurn", "types": [], "good": 2, "master": 4, "unit": "x", "where": "nowhere"}
	var got := GamesLeague.due_letters(d)
	assert_true(got.size() >= 1 and str(got[0].id) == "10", "ten stamps earn the first letter")
	assert_true(GamesLeague.due_letters(d).is_empty(), "delivered once")
	PartyPieces._cache = saved
