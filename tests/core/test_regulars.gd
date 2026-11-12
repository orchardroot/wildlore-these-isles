extends TestCase
## The Regulars (core/regulars.gd, story/regular_talk.gd): twelve sound characters, favour from gifts (one a day),
## the scenes at each level, letters at the post box, the manager hook, old saves, and the story command.

func _data() -> GameStateData:
	var d := GameStateData.new()
	d.day_count = 10
	return d

func _meet(d: GameStateData, id: String) -> void:
	Regulars.complete(d, id, "intro")

func _gift_days(d: GameStateData, id: String, n: int) -> void:
	for i in n:
		d.day_count += 1
		d.bag[Regulars.liked_item(id)] = 1
		Regulars.give_gift(d, id)

func test_twelve_sound_regulars() -> void:
	var items := ItemDB.load_default()
	assert_true(Regulars.all().size() >= 12)
	var seen := {}
	for r in Regulars.all():
		var id := str(r.id)
		assert_false(seen.has(id), "unique " + id)
		seen[id] = true
		assert_true(FileAccess.file_exists("res://data/zones/%s.json" % r.home), id + " home zone")
		assert_true(FileAccess.file_exists("res://data/zones/%s.json" % r.away), id + " away zone")
		assert_true(str(r.home) != str(r.away))
		assert_true(items.has(str(r.likes)), id + " likes a real item " + str(r.likes))
		for k in ["intro", "meet", "letter", "offer", "chat", "thanks"]:
			assert_false((r.get(k, []) as Array).is_empty(), id + " has " + k)
		assert_true((r.chat as Array).size() >= 2)
		var first := Regulars.short_name(r)
		for k in ["intro", "meet", "offer", "chat", "thanks"]:
			for l in r[k]:
				assert_false("—" in str(l), id + " has an em-dash")
				var head := str(l).split(": ")[0]
				if str(l).contains(": ") and head.length() < 20 and head.split(" ").size() <= first.split(" ").size():
					assert_eq(head, first, id + " speaker prefix")
		for l in r.letter:
			assert_false("—" in str(l))

func test_homes_are_all_different_towns() -> void:
	var homes := {}
	for r in Regulars.all():
		homes[str(r.home)] = true
	assert_eq(homes.size(), Regulars.all().size(), "one Regular to a town")

func test_favour_starts_at_zero_and_old_saves_are_fine() -> void:
	var d := _data()
	for id in Regulars.ids():
		assert_eq(Regulars.favour(d, id), 0)
	assert_true(Regulars.letters_waiting(d).is_empty())
	assert_eq(d.flags.size(), 0, "reading state writes nothing")

func test_first_scene_then_gifts_raise_favour() -> void:
	var d := _data()
	var id := "ned"
	assert_eq(Regulars.next_beat(d, id, "whitby"), "intro")
	assert_false(Regulars.can_gift(d, id), "strangers don't take gifts")
	_meet(d, id)
	assert_eq(Regulars.favour(d, id), 1)
	assert_eq(Regulars.next_beat(d, id, "whitby"), "")
	_gift_days(d, id, 1)
	assert_eq(Regulars.favour(d, id), 2)
	_gift_days(d, id, 2)
	assert_eq(Regulars.favour(d, id), 3)
	_gift_days(d, id, 2)
	assert_eq(Regulars.favour(d, id), 4)
	_gift_days(d, id, 10)
	assert_eq(Regulars.favour(d, id), Regulars.MAX_FAVOUR, "capped")
	assert_false(Regulars.can_gift(d, id), "no more gifts at the top")

func test_one_gift_a_day_and_it_comes_out_of_the_bag() -> void:
	var d := _data()
	_meet(d, "gwenllian")
	d.bag["welsh_cakes"] = 2
	assert_eq(Regulars.give_gift(d, "gwenllian"), 2)
	assert_eq(int(d.bag["welsh_cakes"]), 1)
	assert_false(Regulars.can_gift(d, "gwenllian"), "not twice in a day")
	assert_eq(Regulars.give_gift(d, "gwenllian"), -1)
	assert_eq(int(d.bag["welsh_cakes"]), 1, "refused gift is kept")
	d.day_count += 1
	assert_true(Regulars.can_gift(d, "gwenllian"))
	Regulars.give_gift(d, "gwenllian")
	assert_false(d.bag.has("welsh_cakes"), "last one gone from the bag")

func test_wrong_item_or_empty_bag_is_no_gift() -> void:
	var d := _data()
	_meet(d, "dot")
	assert_false(Regulars.can_gift(d, "dot"))
	d.bag["cod"] = 3
	assert_false(Regulars.can_gift(d, "dot"))

func test_second_town_scene_needs_favour_two() -> void:
	var d := _data()
	var r := Regulars.get_reg("hilda")
	_meet(d, "hilda")
	assert_eq(Regulars.next_beat(d, "hilda", str(r.away)), "")
	assert_true(Regulars.npcs_for(str(r.away), d).filter(func(n): return str(n.id).begins_with("reg_hilda")).is_empty())
	_gift_days(d, "hilda", 1)
	assert_eq(Regulars.next_beat(d, "hilda", str(r.away)), "meet")
	var npcs := Regulars.npcs_for(str(r.away), d).filter(func(n): return str(n.id) == "reg_hilda_away")
	assert_eq(npcs.size(), 1)
	assert_eq(str(npcs[0].script), "regular_hilda")
	Regulars.complete(d, "hilda", "meet")
	assert_eq(Regulars.next_beat(d, "hilda", str(r.away)), "")
	assert_true(Regulars.npcs_for(str(r.away), d).filter(func(n): return str(n.id) == "reg_hilda_away").is_empty())

func test_everyone_is_at_home() -> void:
	var d := _data()
	for r in Regulars.all():
		var here := Regulars.npcs_for(str(r.home), d).filter(func(n): return str(n.id) == "reg_" + str(r.id))
		assert_eq(here.size(), 0 if Regulars.is_bound(r) else 1, str(r.id) + " at home (a bound one is already standing there)")

func test_letters_arrive_at_favour_three_once() -> void:
	var d := _data()
	_meet(d, "morag")
	assert_true(Regulars.letters_waiting(d).is_empty())
	_gift_days(d, "morag", 3)
	assert_eq(Regulars.letters_waiting(d), ["morag"])
	var lines := Regulars.letter_lines("morag", "Sam")
	assert_true(str(lines[0]).contains("Morag MacLeod"))
	assert_eq(Regulars.collect_letters(d), ["morag"])
	assert_true(Regulars.letters_waiting(d).is_empty(), "read once")
	assert_eq(Regulars.collect_letters(d), [])

func test_manager_offer_waits_for_favour_four_and_a_free_deed() -> void:
	var d := _data()
	_meet(d, "mervyn")
	_gift_days(d, "mervyn", 6)
	assert_eq(Regulars.favour(d, "mervyn"), 4)
	if Deeds.owned(d).is_empty():
		assert_eq(Regulars.next_beat(d, "mervyn", "belfast"), "", "no Deed, no offer")
		assert_false(Regulars.appoint(d, "mervyn", "chippy_whitby"))
	else:
		assert_eq(Regulars.next_beat(d, "mervyn", "belfast"), "offer")

func test_validator_knows_the_command_and_the_scripts() -> void:
	var ok := StoryValidator.validate_commands([{"do": "regular", "id": "ned"}], "t", Fixtures.dex(), ItemDB.load_default(), {})
	assert_eq(ok, [])
	var bad := StoryValidator.validate_commands([{"do": "regular", "id": "nobody"}], "t", Fixtures.dex(), ItemDB.load_default(), {})
	assert_eq(bad.size(), 1)
	for r in Regulars.all():
		if Regulars.is_bound(r):
			continue  # a bound Regular talks through their own zone's script and the ScriptHooks line
		var cmds := StoryData.script(Regulars.SCRIPT_FILE, "regular_" + str(r.id))
		assert_eq(cmds.size(), 1, str(r.id) + " script")

func test_talking_plays_intro_then_takes_a_gift() -> void:
	var h := FakeStoryHost.new()
	h.zone = "whitby"
	h.data.day_count = 5
	await Commands.new(h).run([{"do": "regular", "id": "ned"}])
	assert_eq(Regulars.favour(h.data, "ned"), 1)
	assert_true(str(h.said).contains("Ned"))
	h.said.clear()
	await Commands.new(h).run([{"do": "regular", "id": "ned"}])
	assert_true(str(h.said).contains("haddock"), "hints at what they like")
	h.data.bag["haddock"] = 1
	h.choices = [0]
	h.said.clear()
	await Commands.new(h).run([{"do": "regular", "id": "ned"}])
	assert_eq(Regulars.favour(h.data, "ned"), 2)
	assert_false(h.data.bag.has("haddock"))

# --- Regulars who are home residents (w53) ---------------------------------------------------------------

func _bound() -> Array:
	return Regulars.all().filter(func(r): return Regulars.is_bound(r))

func test_bound_regulars_point_at_real_residents() -> void:
	var zones := ZoneData.load_all()
	assert_eq(Regulars.problems(zones, ItemDB.load_default()), [])
	assert_true(_bound().size() >= 50, "a Regular in (nearly) every town with homes")
	for r in _bound():
		assert_eq(Regulars.bound_id(str(r.zone), str(r.npc)), str(r.id))

func test_problems_catches_bad_bindings() -> void:
	var zones := ZoneData.load_all()
	var saved := Regulars._regs
	var good: Dictionary = Regulars.all()[0].duplicate(true)
	var bad := good.duplicate(true)
	bad["id"] = "x_bad"
	bad["zone"] = "nowhere"
	bad["npc"] = "ghost"
	bad["likes"] = "unobtainium"
	bad["away"] = "narnia"
	Regulars._regs = [good, bad]
	var errs := Regulars.problems(zones, ItemDB.load_default())
	Regulars._regs = saved
	assert_true(errs.size() >= 3, str(errs))

func test_bound_regular_spawns_no_npc_but_hooks_the_talk() -> void:
	var r: Dictionary = _bound()[0]
	var d := _data()
	assert_true(Regulars.npcs_for(str(r.home), d).filter(func(n): return str(n.id) == "reg_" + str(r.id)).is_empty())
	var base := [{"do": "say", "who": "X", "text": "Hello."}]
	var out := Regulars.hook(str(r.zone), str(r.npc), base, d)
	assert_eq(out.size(), 2)
	assert_eq(out[0], base[0], "their own lines first")
	assert_eq(out[1].do, "regular")
	assert_eq(out[1].id, str(r.id))
	assert_eq(Regulars.hook(str(r.zone), "nobody_here", base, d), base)
	var wrapped := ScriptHooks.wrap(str(r.zone), str(r.npc), base, d)
	assert_eq(wrapped[0], base[0], "ScriptHooks.wrap keeps their own lines first")
	assert_true(wrapped.has(out[1]), "ScriptHooks.wrap carries it (after the w53 visit bookkeeping)")

func test_bound_regular_intro_in_the_house_not_the_street() -> void:
	var r: Dictionary = _bound()[0]
	var d := _data()
	var id := str(r.id)
	assert_eq(Regulars.next_beat(d, id, str(r.zone)), "intro")
	assert_eq(Regulars.next_beat(d, id, str(r.home)), "intro")
	_meet(d, id)
	assert_eq(Regulars.next_beat(d, id, str(r.zone)), "")
	_gift_days(d, id, 1)
	assert_eq(Regulars.next_beat(d, id, str(r.away)), "meet")

func test_bound_talk_is_quiet_until_friends_then_chats() -> void:
	var r: Dictionary = _bound()[0]
	var h := FakeStoryHost.new()
	h.zone = str(r.zone)
	h.data.day_count = 5
	var id := str(r.id)
	await Commands.new(h).run([{"do": "regular", "id": id, "bound": true}])
	assert_eq(Regulars.favour(h.data, id), 1)
	h.said.clear()
	await Commands.new(h).run([{"do": "regular", "id": id, "bound": true}])
	assert_false(str(h.said).contains(str(Regulars.get_reg(id).chat[0])), "no chat for a mere acquaintance")
	_gift_days(h.data, id, 1)
	h.said.clear()
	await Commands.new(h).run([{"do": "regular", "id": id, "bound": true}])
	assert_true(h.said.size() >= 1, "chat once favour is 2")

func test_old_save_has_no_regular_state_for_the_new_ones() -> void:
	var d := _data()
	for r in _bound():
		assert_eq(Regulars.favour(d, str(r.id)), 0)
	assert_eq(d.flags.size(), 0)

func test_many_managers_dont_clash_over_a_deed() -> void:
	var d := _data()
	for i in 4:
		d.badges.append("b%d" % i)
	d.set_flag("badge_stone", true)
	d.money = 999999
	assert_eq(Deeds.buy(d, "chippy_whitby"), "")
	var a := str(_bound()[0].id)
	var b := str(_bound()[1].id)
	for id in [a, b]:
		_meet(d, id)
		_gift_days(d, id, 6)
		assert_eq(Regulars.favour(d, id), 4)
	assert_true(Regulars.appoint(d, a, "chippy_whitby"))
	assert_false(Regulars.appoint(d, b, "chippy_whitby"), "one manager to a Deed")
	assert_false(Regulars.appoint(d, a, "chippy_whitby"), "and one Deed to a manager")
	assert_eq(Regulars.next_beat(d, b, str(Regulars.get_reg(b).home)), "", "no free Deed, no offer")
	assert_eq(Deeds.manager(d, "chippy_whitby"), a)
	assert_true(Deeds.summary(d, "chippy_whitby").has("Manager: " + str(Regulars.get_reg(a).name)), "shown by name")

# --- favour 5: the scene at Mum's (w53 mums) ---------------------------------------------------------------

func _five(d: GameStateData, id: String, day: int) -> void:
	d.day_count = day
	_meet(d, id)
	_gift_days(d, id, 8)  # eight gifts takes them to favour 5

func test_nobody_waits_at_mums_before_favour_five() -> void:
	var d := _data()
	assert_eq(Regulars.npcs_for("macc_home", d), [])
	_meet(d, "ned")
	_gift_days(d, "ned", 5)
	assert_eq(Regulars.favour(d, "ned"), 4)
	assert_eq(Regulars.npcs_for("macc_home", d), [])
	assert_eq(Regulars.next_beat(d, "ned", "macc_home"), "")

func test_favour_five_waits_at_mums_and_nowhere_else_new() -> void:
	var d := _data()
	_five(d, "ned", 10)
	assert_eq(Regulars.favour(d, "ned"), 5)
	var defs := Regulars.npcs_for("macc_home", d)
	assert_eq(defs.size(), 1)
	assert_eq(defs[0].id, "reg_ned_mums")
	assert_eq(defs[0].script, "regular_ned")
	assert_eq(Regulars.next_beat(d, "ned", "macc_home"), "mums")
	assert_eq(Regulars.npcs_for("whitby", d).size(), 1, "still at home in Whitby, nothing else added")

func test_one_visitor_at_a_time_earliest_first() -> void:
	var d := _data()
	_five(d, "gwenllian", 40)
	_five(d, "ned", 20)
	_five(d, "mervyn", 30)
	assert_eq(Regulars.mums_visitor(d), "ned")
	assert_eq(Regulars.npcs_for("macc_home", d).size(), 1)
	assert_eq(Regulars.next_beat(d, "mervyn", "macc_home"), "", "not their turn")
	Regulars.complete(d, "ned", "mums")
	assert_eq(Regulars.mums_visitor(d), "mervyn")
	Regulars.complete(d, "mervyn", "mums")
	assert_eq(Regulars.mums_visitor(d), "gwenllian")
	Regulars.complete(d, "gwenllian", "mums")
	assert_eq(Regulars.mums_visitor(d), "")

func test_old_save_favour_five_counts_as_day_zero() -> void:
	var d := _data()
	d.set_flag(Regulars.flag_key("hilda"), {"favour": 5, "pts": 8})  # no five_day, as before this change
	_five(d, "ned", 12)
	assert_eq(Regulars.mums_visitor(d), "hilda", "the old save's friend comes first and still gets a scene")
	d.set_flag(Regulars.flag_key("hilda"), {"favour": 5, "pts": 8, "mums": true})
	assert_eq(Regulars.mums_visitor(d), "ned")

func test_the_scene_plays_gives_tea_and_they_go_home() -> void:
	var h := FakeStoryHost.new()
	h.zone = "macc_home"
	h.data.player_name = "Sam"
	_five(h.data, "ned", 10)
	await Commands.new(h).run([{"do": "regular", "id": "ned"}])
	var said := str(h.said)
	assert_true(said.contains("Mum"), "Mum is in it")
	assert_true(said.contains("Whitby"), "their town is filled in")
	assert_true(said.contains("Sam"), "{player} is filled in")
	assert_true(said.contains("Hull"), "their own line")
	assert_false(said.contains("{"), "no raw placeholders")
	assert_true(Regulars._peek(h.data, "ned").get("mums") == true)
	assert_eq(int(h.data.bag.get("flask_of_tea", 0)), 1)
	assert_eq(Regulars.npcs_for("macc_home", h.data), [], "they have gone home")
	assert_eq(Regulars.favour(h.data, "ned"), 5)

func test_validator_wants_mums_lines() -> void:
	var zones := ZoneData.load_all()
	assert_eq(Regulars.problems(zones, ItemDB.load_default()), [], "all 70 have lines")
	var saved := Regulars._regs
	for bad in [null, [], [""], [5]]:
		var r: Dictionary = Regulars.all()[0].duplicate(true)
		if bad == null:
			r.erase("mums")
		else:
			r["mums"] = bad
		Regulars._regs = [r]
		var errs := Regulars.problems(zones, ItemDB.load_default())
		assert_true(errs.size() >= 1 and "mums" in str(errs), "caught " + str(bad))
	Regulars._regs = saved
