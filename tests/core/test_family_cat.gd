extends TestCase
## Wave 54: the family cat. Sootkit, Grimalkin and Cat-Sith (appendix, only the player's), Nine Lives, how she joins in
## a new game (the Cat and Fiddle road) and in an old save (at home by her bowl), that nothing else can produce the line,
## and that she can't be released or boxed in the Ark.

const KT := preload("res://tests/battle/test_knacks.gd")
const USE := {"type": "move", "slot": 0}
const MF := preload("res://tests/battle/test_move_fx.gd")

var dex := Fixtures.dex()

func _data(flags := {}, party := ["kindlet"], level := 7) -> GameStateData:
	var d := GameStateData.new()
	for id in party:
		d.party.append(Fixtures.creature(id, level))
	d.flags = flags.duplicate()
	return d

func _host(d: GameStateData) -> FakeStoryHost:
	var h := FakeStoryHost.new()
	h.data = d
	return h

func _run(h: FakeStoryHost, file: String, script: String) -> void:
	await Commands.new(h).run(StoryData.script(file, script))

# --- the line ---------------------------------------------------------------------------------

func test_three_species_in_order_with_bond_as_an_early_way() -> void:
	var t := {}
	for id in FamilyCat.LINE:
		assert_true(dex.has(id), id)
		assert_true(Dex.in_appendix(id), "%s never counts towards the 200" % id)
		var sp := dex.get_species(id)
		t[id] = 0
		for s in Rules.STATS:
			t[id] += int(sp.base[s])
		assert_true(str(sp.dex.text) != "" and str(sp.dex.fact) != "" and str(sp.get("real", "")) != "", id)
		for k in ["text", "fact"]:
			assert_false("—" in str(sp.dex[k]) or "–" in str(sp.dex[k]), "%s %s: no dashes" % [id, k])
		for lang in ["cy", "ga", "gd"]:
			assert_true(str(sp.names.get(lang, "")) != "", "%s has a %s name" % [id, lang])
		for which in ["front", "back", "icon"]:
			assert_true(FileAccess.file_exists("res://art/sprites/creatures/%s_%s.png" % [id, which]), "%s %s" % [id, which])
		assert_true(FileAccess.file_exists("res://art/recipes/creatures/%s.json" % id))
		assert_eq(Knacks.id_for_species(sp), "nine_lives")
		assert_true((sp.habitat as Array).is_empty())
	assert_eq(t, {"sootkit": 310, "grimalkin": 430, "catsith": 530})
	assert_eq(dex.get_species("sootkit").types, ["night"])
	assert_eq(dex.get_species("grimalkin").types, ["night", "fae"])
	assert_eq(dex.get_species("catsith").types, ["fae", "night"])
	var e1: Dictionary = dex.get_species("sootkit").evolves
	var e2: Dictionary = dex.get_species("grimalkin").evolves
	assert_eq([e1.to, e1.level, e1.has("bond")], ["grimalkin", 16, true], "bond brings it on early, the level is the fallback")
	assert_eq([e2.to, e2.level, e2.has("bond")], ["catsith", 32, true])
	assert_eq(dex.get_species("catsith").evolves, null)
	for id in FamilyCat.LINE:  # fast and frail beside the starters (kindlet 66 speed, 40 HP at 310)
		var b: Dictionary = dex.get_species(id).base
		assert_true(int(b.spd) > int(b.hp) and int(b.spd) >= int(b.atk) + 20, id)

func test_bond_evolves_her_early() -> void:
	var c := Fixtures.creature("sootkit", 10)
	assert_eq(Progression.evolution_target(c), "", "level 10 and no bond")
	c.friendship = 220
	assert_eq(Progression.evolution_target(c), "grimalkin")

func test_signature_move_is_hers_to_learn() -> void:
	var m := MoveDB.load_default()
	assert_true(m.has("black_cat_crossing"))
	assert_eq(m.get_move("black_cat_crossing").priority, 1)
	var sp := dex.get_species("sootkit")
	assert_true(sp.learnset.any(func(e): return e[1] == "black_cat_crossing"))
	for e in sp.learnset:
		assert_true(m.has(str(e[1])), str(e[1]))

func test_nine_lives_leaves_one_hit_point_once_a_battle() -> void:
	var def := Knacks.get_def("nine_lives")
	assert_eq(def.name, "Nine Lives")
	assert_true(bool(def.endure_once))
	var me := KT.mon("lives", "nine_lives", ["t_wait"], 10, 40)
	me.hp = 20  # not full: it is the once-a-battle knack, not the full-HP one
	var b := MF.fight([me], [KT.mon("foe", "", ["t_big"], 90)])
	var ev := b.take_turn(USE, USE)
	assert_eq(me.hp, 1)
	assert_eq(MF.first(ev, "knack").knack, "nine_lives")
	b.take_turn(USE, USE)
	assert_true(me.is_fainted(), "once a battle only")

func test_knack_data_is_clean_with_the_line() -> void:
	assert_eq(Knacks.check(dex), [])

# --- exclusive ------------------------------------------------------------------------------

func test_the_real_data_is_clean() -> void:
	assert_eq(FamilyCat.problems(dex, ZoneData.load_all()), [])

func test_the_rule_catches_an_encounter_table() -> void:
	var z := ZoneData.from_dict({"id": "t_zone", "kind": "route", "rows": ["...."], "encounters": {"grass": [{"species": "grimalkin", "min": 5, "max": 6, "weight": 5}]}})
	var errs := FamilyCat.problems(dex, {"t_zone": z})
	assert_eq(errs.size(), 1)
	assert_true("t_zone" in str(errs[0]) and "grimalkin" in str(errs[0]))

func test_the_rule_catches_a_gift_in_a_script() -> void:
	assert_eq(FamilyCat._gives([{"do": "give_creature", "species": "catsith"}, {"do": "if", "then": [{"do": "starter", "species": "sootkit"}]}]), ["catsith", "sootkit"])
	assert_eq(FamilyCat._gives([{"do": "family_cat", "op": "join"}, {"do": "give_creature", "species": "kindlet"}]), [])

func test_no_kindred_breeds_her() -> void:
	assert_false(Genetics.breeds(str(Genetics.genes().lines.sootkit)), "no egg can be hers")

func test_every_data_file_that_names_her_is_on_the_list() -> void:
	for p in FamilyCat.ALLOWED:
		assert_true(FileAccess.file_exists(p), p)
	var hits := []
	FamilyCat._scan("res://data", hits)
	assert_eq(hits, [])

# --- no release, no Ark -----------------------------------------------------------------------

func test_she_cant_be_released_from_the_party_or_the_ark() -> void:
	var d := _data({}, ["kindlet", "spikkin"])
	d.party.append(Fixtures.creature("sootkit", 7))
	var rule := ArkLogic.release_rule(d, true, 2)
	assert_false(rule.ok)
	assert_true(str(rule.why) != "")
	assert_true(d.release(true, 2) != "", "the call itself refuses")
	assert_eq(d.party.size(), 3)
	assert_true(ArkLogic.release_rule(d, true, 0).ok, "anyone else still may go")

func test_she_is_never_boxed_in_the_ark() -> void:
	var d := _data({}, ["kindlet", "spikkin"])
	d.party.append(Fixtures.creature("sootkit", 7))
	assert_eq(d.deposit(2), FamilyCat.ARK_REASON)
	d.ark.append(Fixtures.creature("pipkin", 5))
	assert_eq(d.swap_with_ark(2, 0), FamilyCat.ARK_REASON)
	assert_eq(d.ark.size(), 1)
	assert_true(FamilyCat.in_party(d))

func test_a_full_team_boxes_someone_else_for_a_catch() -> void:
	var d := _data({}, ["kindlet", "spikkin", "pipkin", "holtling", "snowhare"])
	d.party.append(Fixtures.creature("sootkit", 7))  # slot 5
	d.add_creature_swapping(Fixtures.creature("scuttlet", 5), 5)
	assert_true(FamilyCat.in_party(d), "she stayed")
	assert_eq(d.ark.size(), 1)
	assert_false(FamilyCat.is_family(d.ark[0]))
	assert_eq(d.party.size(), 6)

func test_a_stray_cat_in_the_ark_goes_home() -> void:
	var d := _data({}, ["kindlet"])
	d.ark.append(Fixtures.creature("sootkit", 7))
	FamilyCat.sync(d, dex)
	assert_true(d.ark.is_empty())
	assert_true(FamilyCat.at_home(d))
	assert_true(FamilyCat.has(d))
	assert_false(FamilyCat.in_party(d))

# --- new game: the road --------------------------------------------------------------------------

func test_the_road_scene_is_due_once_in_a_new_game() -> void:
	var d := _data({"starter": "kindlet"})
	assert_true(FamilyCat.scene_due(d, "cat_and_fiddle"))
	assert_false(FamilyCat.scene_due(d, "macclesfield"), "only on that road")
	assert_false(FamilyCat.waiting(d))
	assert_false(FamilyCat.scene_due(GameStateData.new(), "cat_and_fiddle"), "not without a starter in the party")
	d.flags[FamilyCat.MET] = true
	assert_false(FamilyCat.scene_due(d, "cat_and_fiddle"))

func test_she_joins_at_the_starters_level_and_the_family_names_her() -> void:
	var d := _data({"starter": "kindlet"}, ["kindlet"], 9)
	var h := _host(d)
	h.choices = [0]
	await _run(h, "cat_and_fiddle", "cat_scene")
	assert_eq(d.party.size(), 2)
	var cat: Creature = d.party[1]
	assert_eq(cat.species.id, "sootkit")
	assert_eq(cat.level, 9, "the starter's level")
	assert_eq(cat.display_name(), "Meadow", "the default answer")
	assert_true(FamilyCat.in_party(d) and FamilyCat.met(d))
	assert_true(d.caught.has("sootkit"))
	assert_false(FamilyCat.is_lead(d), "the starter still leads")
	for t in h.texts():
		assert_false("{" in str(t), "no raw tokens: " + str(t))
		assert_false("—" in str(t))
	assert_true(h.texts().any(func(t): return "Kindlet" in str(t)), "her scene names the lead")

func test_another_name_opens_the_keyboard() -> void:
	var d := _data({"starter": "kindlet"})
	var h := _host(d)
	h.choices = [1]
	await _run(h, "cat_and_fiddle", "cat_scene")
	assert_true(h.log.any(func(l): return l[0] == "menu" and l[1] == "name:nickname:1"))
	assert_eq(d.party[1].display_name(), "Meadow", "backing out keeps the family's name")

func test_a_second_scene_gives_nothing() -> void:
	var d := _data({"starter": "kindlet"})
	var h := _host(d)
	h.choices = [0]
	await _run(h, "cat_and_fiddle", "cat_scene")
	var h2 := _host(d)
	h2.choices = [0]
	await _run(h2, "cat_and_fiddle", "cat_scene")
	assert_eq(d.party.size(), 2, "only one cat")

func test_a_full_team_leaves_her_at_home() -> void:
	var d := _data({"starter": "kindlet"}, ["kindlet", "spikkin", "pipkin", "holtling", "snowhare", "scuttlet"])
	var h := _host(d)
	await _run(h, "cat_and_fiddle", "cat_scene")
	assert_eq(d.party.size(), 6)
	assert_false(FamilyCat.in_party(d))
	assert_true(FamilyCat.at_home(d))
	assert_eq(FamilyCat.display_name(d, dex), "Meadow")
	assert_true(FamilyCat.collect(d, dex) != "", "no room yet")

# --- old saves: at home --------------------------------------------------------------------------

func test_an_old_save_past_the_road_finds_her_waiting() -> void:
	var d := _data({"starter": "kindlet", "visited_buxton": true, "badge_brook": true}, ["kindlet"], 18)
	assert_true(FamilyCat.waiting(d))
	assert_false(FamilyCat.scene_due(d, "cat_and_fiddle"), "the road scene is for those not past it")
	FamilyCat.sync(d, dex)
	assert_true(d.flag(FamilyCat.WAITING) == true, "Mum's lines read this")
	var defs := FamilyCat.npcs_for("macc_home", d, dex)
	assert_eq(defs.size(), 1)
	assert_eq(defs[0].script, "cat")
	assert_eq(FamilyCat.npcs_for("macclesfield", d, dex), [])
	assert_eq(str(defs[0].sprite).substr(0, 9), "creature:")
	var z := ZoneData.load_id("macc_home")
	assert_true(z.walkable(Vector2i(int(defs[0].x), int(defs[0].y))), "she sits on a free floor tile")

func test_she_joins_at_the_par_level_from_home() -> void:
	var d := _data({"starter": "kindlet", "visited_buxton": true, "badge_brook": true, "badge_urban": true}, ["kindlet", "spikkin"], 30)
	FamilyCat.sync(d, dex)
	var h := _host(d)
	h.choices = [0]
	await _run(h, "macc_home", "cat")
	assert_eq(d.party.size(), 3)
	var cat: Creature = d.party[2]
	assert_eq(cat.level, ParLevel.par(d.flags), "the story's par, held to the best of the team")
	assert_eq(cat.species.id, FamilyCat.species_at(dex, cat.level))
	assert_true(d.flag(FamilyCat.WAITING) != true)
	assert_eq(FamilyCat.npcs_for("macc_home", d, dex), [], "she is out of the window now")

func test_par_never_lifts_her_above_the_team() -> void:
	var d := _data({"badge_storm": true, "visited_buxton": true}, ["kindlet"], 12)
	assert_eq(FamilyCat.par_level(d), 12)
	var late := _data({"game_complete": true, "visited_buxton": true}, ["kindlet"], 80)
	assert_eq(FamilyCat.par_level(late), ParLevel.par(late.flags))
	assert_eq(FamilyCat.species_at(dex, 80), "catsith")
	assert_eq(FamilyCat.species_at(dex, 20), "grimalkin")
	assert_eq(FamilyCat.species_at(dex, 6), "sootkit")

func test_the_waiting_note_is_one_off() -> void:
	var d := _data({"visited_buxton": true})
	assert_eq(FamilyCat.note(d).size(), 2)
	assert_true("Mum" in str(FamilyCat.note(d)[0]))
	d.flags[FamilyCat.NOTE] = true
	assert_eq(FamilyCat.note(d), [])
	assert_eq(FamilyCat.note(_data({"starter": "kindlet"})), [], "a new game has nothing waiting")

func test_a_save_from_before_has_no_cat_and_nothing_changes() -> void:
	var d := _data({"starter": "kindlet"})
	FamilyCat.sync(d, dex)
	assert_false(FamilyCat.has(d))
	assert_false(FamilyCat.at_home(d))
	assert_eq(FamilyCat.npcs_for("macc_home", d, dex), [])
	assert_eq(d.flags, {"starter": "kindlet"}, "sync adds no flags until there is something to say")

# --- home and the bowl ------------------------------------------------------------------------

func _with_cat() -> GameStateData:
	var d := _data({"starter": "kindlet"}, ["kindlet", "spikkin"], 10)
	d.party.append(Fixtures.creature("sootkit", 10))
	d.party[2].nickname = "Meadow"
	FamilyCat.sync(d, dex)
	return d

func test_leave_and_collect() -> void:
	var d := _with_cat()
	assert_true(FamilyCat.in_party(d) and d.flag(FamilyCat.WITH_YOU) == true)
	assert_eq(FamilyCat.leave(d), "")
	assert_false(FamilyCat.in_party(d))
	assert_true(FamilyCat.at_home(d))
	assert_eq(d.party.size(), 2)
	assert_eq(FamilyCat.npcs_for("macc_home", d, dex).size(), 1, "she is by her bowl")
	assert_eq(FamilyCat.display_name(d, dex), "Meadow")
	assert_eq(FamilyCat.collect(d, dex), "")
	assert_true(FamilyCat.in_party(d))
	assert_false(FamilyCat.at_home(d))
	assert_eq(d.party[2].display_name(), "Meadow", "same cat, same name")

func test_she_keeps_what_she_has_learnt_while_at_home() -> void:
	var d := _with_cat()
	d.party[2].level = 21
	d.party[2].friendship = 200
	FamilyCat.leave(d)
	FamilyCat.collect(d, dex)
	assert_eq(d.party[2].level, 21)
	assert_eq(d.party[2].friendship, 200)

func test_she_stays_home_if_she_is_the_only_one_able_to_fight() -> void:
	var d := _with_cat()
	d.party[0].hp = 0
	d.party[1].hp = 0
	assert_true(FamilyCat.leave(d) != "", "someone must be fit to battle")
	assert_true(FamilyCat.in_party(d))

func test_home_script_offers_her_and_collects_her() -> void:
	var d := _with_cat()
	FamilyCat.leave(d)
	FamilyCat.sync(d, dex)
	var h := _host(d)
	h.choices = [0]
	await _run(h, "macc_home", "cat")
	assert_true(FamilyCat.in_party(d))
	var h2 := _host(_with_cat())
	h2.choices = [1]
	FamilyCat.leave(h2.data)
	await _run(h2, "macc_home", "cat")
	assert_false(FamilyCat.in_party(h2.data), "she'd have said no anyway")

func test_mum_offers_to_keep_her_once_a_day() -> void:
	var d := _with_cat()
	d.flags["mum_recipes"] = true
	d.flags["mum_done"] = true
	var h := _host(d)
	h.choices = [1]
	await _run(h, "macc_home", "mum")
	assert_false(FamilyCat.in_party(d), "Mum keeps her by the bowl")
	assert_true(FamilyCat.at_home(d))

func test_first_morning_mum_mentions_the_cat() -> void:
	var d := _data({})
	var h := _host(d)
	await _run(h, "macc_home", "mum")
	assert_true(h.texts().any(func(t): return "cat" in str(t) and "breakfast" in str(t)), "the cat hasn't touched her breakfast")

func test_mum_says_she_has_been_in_the_window() -> void:
	var d := _data({"starter": "kindlet", "visited_buxton": true, "mum_recipes": true, "mum_done": true})
	FamilyCat.sync(d, dex)
	var h := _host(d)
	await _run(h, "macc_home", "mum")
	assert_true(h.texts().any(func(t): return "window" in str(t) and "waiting" in str(t)))

# --- the save and the follower ------------------------------------------------------------------

func test_the_cat_survives_a_save_at_home_and_in_the_party() -> void:
	var d := _with_cat()
	d.party[2].level = 17
	var back := GameStateData.from_dict(JSON.parse_string(JSON.stringify(d.to_dict())), dex)
	assert_true(FamilyCat.in_party(back))
	assert_eq(back.party[2].level, 17)
	assert_eq(back.party[2].display_name(), "Meadow")
	FamilyCat.leave(back)
	var again := GameStateData.from_dict(JSON.parse_string(JSON.stringify(back.to_dict())), dex)
	assert_true(FamilyCat.at_home(again))
	assert_eq(FamilyCat.collect(again, dex), "")
	assert_eq(again.party[2].level, 17)
	assert_eq(again.party[2].display_name(), "Meadow")

func test_lead_and_has() -> void:
	var d := _data({}, ["sootkit", "kindlet"])
	assert_true(FamilyCat.is_lead(d))
	assert_true(FamilyCat.has(d))
	d.party[0].hp = 0
	assert_false(FamilyCat.is_lead(d), "she is not the one walking beside you when she can't walk")
	assert_false(FamilyCat.is_lead(_data({}, ["kindlet", "sootkit"])))
	assert_false(FamilyCat.has(_data({}, ["kindlet"])))

func test_her_own_follower_lines() -> void:
	var c := Fixtures.creature("grimalkin", 20)
	c.nickname = "Meadow"
	var seen := {}
	for w in ["clear", "drizzle", "fog", "gale", "frost", "sunshine", "downpour"]:
		for ph in ["dawn", "day", "dusk", "night"]:
			for kind in ["town", "route", "cave", "interior"]:
				for pool_line in FamilyCat.mood_pool("grimalkin", 0.9, w, ph, kind, 255):
					seen[pool_line] = true
	assert_true(seen.size() >= 20, "plenty to say: %d" % seen.size())
	for l in seen:
		assert_false("—" in str(l), str(l))
		assert_true("{name}" in str(l), str(l))
	var line := FamilyCat.mood_line(c, 0.9, "clear", "day", "Buxton", "town", 3)
	assert_true("Meadow" in line and not "{" in line, line)
	assert_true(FamilyCat.mood_line(c, 0.2, "fog", "night", "Buxton", "route", 12345).length() > 10)

func test_every_word_she_says_is_dash_free() -> void:
	var texts := []
	for f in ["macc_home", "cat_and_fiddle"]:
		for sid in ["cat", "cat_scene"]:
			for c in StoryData.script(f, sid):
				texts.append(JSON.stringify(c))
	assert_false(texts.is_empty())
	for t in texts:
		assert_false("—" in str(t))
