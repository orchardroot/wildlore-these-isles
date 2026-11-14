extends TestCase
## Wave 56: the Easter eggs. Each is a flag (absent = not found), triggers only where and when it should, and says
## nothing in any menu. The scenes are Commands lists, so they run here against a fake host.

var dex := Fixtures.dex()
var moves := Fixtures.moves()

func _data(cat_lead := false, flags := {}) -> GameStateData:
	var d := GameStateData.new()
	d.party.append(Fixtures.creature("kindlet", 8))
	d.flags = flags.duplicate()
	if cat_lead:
		var c := FamilyCat.make(dex, moves, Rng.new(1), 8)
		FamilyCat.join(d, c, "Meadow")
		d.party.erase(c)
		d.party.push_front(c)
	return d

func _run(d: GameStateData, cmds: Array, picks := []) -> FakeStoryHost:
	var h := FakeStoryHost.new()
	h.data = d
	h.choices = picks.duplicate()
	Commands.new(h).run(cmds)
	return h

func _said(h: FakeStoryHost) -> String:
	return " ".join(h.said.map(func(s): return str(s[1])))

func test_the_data_is_sound_and_every_egg_is_a_flag() -> void:
	var zones := ZoneData.load_all()
	var flo := Flotsam.all().map(func(f): return str(f.id))
	assert_eq(Eggs.check(zones, ItemDB.load_default(), flo), [])
	assert_true(Eggs.all().size() >= 10)
	var d := GameStateData.new()
	assert_eq(Eggs.found_count(d), 0, "an old save has found none")
	for e in Eggs.all():
		if str(e.kind) != "title":
			assert_false(Eggs.found(d, e), e.id)

func test_schrodinger_box_needs_the_cat_at_the_front() -> void:
	var p := Vector2i(3, 7)
	var plain := _data(false)
	assert_false(Eggs.spot_script(plain, "dublin_trinity", p).is_empty(), "the basket reads either way")
	var h := _run(plain, Eggs.spot_script(plain, "dublin_trinity", p))
	assert_false("Schrödinger" in _said(h))
	assert_false(Eggs.found(plain, Eggs.get_egg("box")))
	var d := _data(true)
	h = _run(d, Eggs.spot_script(d, "dublin_trinity", p))
	assert_true("Schrödinger" in _said(h) and "1956" in _said(h) and "Meadow" in _said(h))
	assert_true(Eggs.found(d, Eggs.get_egg("box")))
	assert_eq(Eggs.spot_script(d, "dublin", p), [], "only in that room")

func test_the_cat_eggs_work_with_her_anywhere_in_the_party() -> void:
	var d := _data(true)
	var kind: Creature = d.party[0]
	d.party.erase(kind)
	d.party.push_back(kind)  # she is now at the back
	assert_false(FamilyCat.is_lead(d))
	var h := _run(d, Eggs.spot_script(d, "dublin_trinity", Vector2i(3, 7)))
	assert_true("Schrödinger" in _said(h), "the basket, with her at the back")
	var d2 := _data(true)
	var c: Creature = d2.party[0]
	d2.party.erase(c)
	d2.party.push_back(c)
	assert_true(Eggs.step_script(d2, "chester", Vector2i(5, 5), [], 19 * 60, 30).size() > 0, "the grin, with her at the back")

func test_the_grin_is_dusk_in_cheshire_with_the_cat_in_front() -> void:
	var dusk := 19 * 60
	var d := _data(true)
	assert_eq(Eggs.step_script(d, "macclesfield", Vector2i(5, 5), [], dusk, 3), [], "not until you have been about a while")
	assert_eq(Eggs.step_script(d, "macclesfield", Vector2i(5, 5), [], 12 * 60, 30), [], "not at noon")
	assert_eq(Eggs.step_script(d, "manchester", Vector2i(5, 5), [], dusk, 30), [], "not outside Cheshire")
	assert_eq(Eggs.step_script(_data(false), "macclesfield", Vector2i(5, 5), [], dusk, 30), [], "not without her in front")
	var cmds := Eggs.step_script(d, "chester", Vector2i(5, 5), [], dusk, 30)
	var h := _run(d, cmds)
	assert_true("Daresbury" in _said(h) and "1832" in _said(h))
	assert_true(Eggs.found(d, Eggs.get_egg("grin")))
	assert_eq(Eggs.step_script(d, "chester", Vector2i(5, 5), [], dusk, 30), [], "once")

func test_the_arcade_cabinet_has_one_name_on_it() -> void:
	var d := _data(false)
	var h := _run(d, Eggs.spot_script(d, "blackpool_arcade", Vector2i(11, 2)))
	assert_true("MONSTERQUEST" in _said(h) and "JIM" in _said(h))
	assert_true(Eggs.found(d, Eggs.get_egg("cabinet")))

func test_the_caesar_slip_gives_a_keepsake_for_the_right_reading_only() -> void:
	var p := Vector2i(2, 2)
	var d := _data(false)
	var h := _run(d, Eggs.spot_script(d, "bletchley_hut8", p), [1])
	assert_true("does not fit" in _said(h))
	assert_false(Eggs.found(d, Eggs.get_egg("caesar")))
	assert_eq(int(d.bag.get("w56_bp_slip", 0)), 0)
	h = _run(d, Eggs.spot_script(d, "bletchley_hut8", p), [3])
	assert_false("does not fit" in _said(h), "leaving it is not a wrong answer")
	assert_eq(int(d.bag.get("w56_bp_slip", 0)), 0)
	h = _run(d, Eggs.spot_script(d, "bletchley_hut8", p), [0])
	assert_eq(int(d.bag.get("w56_bp_slip", 0)), 1)
	assert_true(Eggs.found(d, Eggs.get_egg("caesar")))
	h = _run(d, Eggs.spot_script(d, "bletchley_hut8", p))
	assert_eq(int(d.bag.get("w56_bp_slip", 0)), 1, "one keepsake")

func test_the_slip_really_is_shifted_by_three() -> void:
	var out := ""
	for ch in "SXW WKH NHWWOH RQ":
		out += ch if ch == " " else char((ch.unicode_at(0) - 65 - 3 + 26) % 26 + 65)
	assert_eq(out, "PUT THE KETTLE ON")

func test_the_phone_rings_at_midnight_beside_a_phone_box_and_is_an_hour_fast() -> void:
	var props := [{"type": "phone_box", "x": 10, "y": 10}]
	var d := _data(false)
	assert_eq(Eggs.step_script(d, "cambridge", Vector2i(10, 12), props, 12, 5).size() > 0, true, "two tiles away is passing")
	assert_eq(Eggs.step_script(d, "cambridge", Vector2i(10, 14), props, 12, 5), [], "too far")
	assert_eq(Eggs.step_script(d, "cambridge", Vector2i(10, 12), props, 13 * 60, 5), [], "only after midnight")
	assert_true(Eggs.step_script(d, "cambridge", Vector2i(10, 12), props, 2 * 60 + 40, 5).size() > 0, "and until three")
	assert_eq(Eggs.step_script(d, "cambridge", Vector2i(10, 12), props, 3 * 60, 5), [], "not at three")
	assert_eq(Eggs.step_script(d, "cambridge", Vector2i(10, 12), [], 12, 5), [], "needs a box")
	assert_eq(Eggs.clock_reading(12), "1:12")
	assert_eq(Eggs.clock_reading(23 * 60 + 30), "0:30")
	var cmds := Eggs.step_script(d, "cambridge", Vector2i(10, 12), props, 12, 5)
	var h := _run(d, cmds, [1])
	assert_false(Eggs.found(d, Eggs.get_egg("phone")), "walking on leaves it unanswered")
	h = _run(d, cmds, [0])
	assert_true("third stroke" in _said(h) and "1:12" in _said(h))
	assert_true(Eggs.found(d, Eggs.get_egg("phone")))
	assert_eq(Eggs.step_script(d, "cambridge", Vector2i(10, 12), props, 12, 5), [], "answered once")

func test_cambridge_has_a_forty_two() -> void:
	var d := _data(false)
	var h := _run(d, Eggs.spot_script(d, "cambridge", Vector2i(39, 30)))
	assert_true("42" in _said(h) and "1952" in _said(h))
	assert_true(Eggs.found(d, Eggs.get_egg("forty_two")))

func test_the_title_sequence() -> void:
	var p := 0
	for k in Eggs.CODE:
		p = Eggs.feed(p, k)
	assert_eq(p, Eggs.CODE.size())
	p = 0
	for k in [KEY_UP, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_B, KEY_A]:
		p = Eggs.feed(p, k)
	assert_true(p < Eggs.CODE.size(), "a wrong key starts over")
	p = Eggs.feed(Eggs.feed(Eggs.feed(0, KEY_UP), KEY_UP), KEY_UP)
	assert_eq(p, 2, "a stray up keeps the first two: it is still the start of up up down")

func test_a_whole_evening_on_the_bench_brings_someone() -> void:
	var b := Vector2i(25, 33)
	var d := _data(false)
	assert_eq(Eggs.bench_script(d, "blackpool", b, 17 * 60 + 30, 18 * 60), [], "a quick sit is just a sit")
	assert_eq(Eggs.bench_script(d, "blackpool", b, 20 * 60, 21 * 60 + 15), [], "started too late for a whole evening")
	assert_eq(Eggs.bench_script(d, "blackpool", Vector2i(29, 33), 17 * 60, 21 * 60 + 15), [], "the other bench is not the one")
	assert_eq(Eggs.bench_script(d, "chester", b, 17 * 60, 21 * 60 + 15), [], "nor another town")
	var h := _run(d, Eggs.bench_script(d, "blackpool", b, 17 * 60, 21 * 60 + 15))
	assert_true("1894" in _said(h))
	assert_true(Eggs.found(d, Eggs.get_egg("bench")))
	assert_eq(Eggs.bench_script(d, "blackpool", b, 17 * 60, 21 * 60 + 15), [], "once")

func test_mum_has_an_opinion_on_three_names() -> void:
	for nm in ["Bagpuss", "Schrödinger", "Macavity", "SCHRODINGER"]:
		var d := _data(true, {"mum_recipes": true})
		FamilyCat.current(d, dex).nickname = nm
		var cmds := Eggs.hook("macc_home", "mum", [{"do": "say", "who": "Mum", "text": "Hello."}], d)
		assert_true(cmds.size() > 1, nm)
		var h := _run(d, cmds)
		assert_true(h.said[0][0] == "Mum" and nm in str(h.said[0][1]), nm)
		assert_true(Eggs.found(d, Eggs.get_egg("names")), nm)
		assert_eq(Eggs.hook("macc_home", "mum", [{"do": "say"}], d).size(), 1, "once")
	var plain := _data(true, {"mum_recipes": true})
	assert_eq(Eggs.hook("macc_home", "mum", [{"do": "say"}], plain).size(), 1, "Meadow is just Meadow")
	var early := _data(true)
	early.party[0].nickname = "Macavity"
	assert_eq(Eggs.hook("macc_home", "mum", [{"do": "say"}], early).size(), 1, "never in front of the first morning")
	assert_eq(Eggs.hook("macc_home", "gran", [{"do": "say"}], _data(true, {"mum_recipes": true})).size(), 1)

func test_the_cat_at_home_is_named_too() -> void:
	var d := _data(true, {"mum_recipes": true})
	var c: Creature = d.party[0]
	c.nickname = "Macavity"
	FamilyCat.leave(d)
	assert_true(FamilyCat.at_home(d))
	assert_eq(Eggs.cat_name(d), "Macavity")
	assert_true(Eggs.hook("macc_home", "mum", [], d).size() > 0)

func test_one_bottle_answers_another() -> void:
	var d := GameStateData.new()
	assert_eq(Eggs.bottle_lines(d, "fl_severn_crossing_1"), [], "not before the first")
	d.set_flag("flotsam_bath_1", true)
	assert_eq(Eggs.bottle_lines(d, "fl_bath_1"), [], "only that bottle answers")
	var lines := Eggs.bottle_lines(d, "fl_severn_crossing_1")
	assert_true(lines.size() > 0 and "soap" in str(lines))
	assert_true(Eggs.found(d, Eggs.get_egg("bottles")))

func test_no_egg_is_named_in_a_menu() -> void:
	for path in ["res://ui/atlas_screen.gd", "res://ui/pause_menu.gd", "res://core/atlas.gd"]:
		if FileAccess.file_exists(path):
			assert_false("Eggs." in FileAccess.get_file_as_string(path), path)

func test_the_props_are_there_to_find() -> void:
	var zones := ZoneData.load_all()
	for pair in [["dublin_trinity", "creature_basket", 3, 7], ["blackpool_arcade", "slot_machine", 11, 2], ["cambridge", "phone_box", 39, 30]]:
		var ok := false
		for pr in zones[pair[0]].props:
			ok = ok or (str(pr.type) == pair[1] and int(pr.x) == pair[2] and int(pr.y) == pair[3])
		assert_true(ok, str(pair))
