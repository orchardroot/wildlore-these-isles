extends TestCase
## Contracts (core/contracts.gd, story/contract_talk.gd, data/contracts): every contract can be finished by every
## branch, old saves have none under way, choices persist and change what they say they change, fees are one-off.

func _host(c: Dictionary) -> FakeStoryHost:
	var h := FakeStoryHost.new()
	h.dex = Dex.load_default()
	h.moves = MoveDB.load_default()
	h.zone = str(c.town)
	for i in int(c.badges):
		h.data.badges.append("b%d" % i)
	return h

func _lair(h: FakeStoryHost, c: Dictionary) -> void:
	await Commands.new(h).run([{"do": "contract", "as": "lair", "id": str(c.id)}])

func _poster(h: FakeStoryHost, c: Dictionary) -> void:
	await Commands.new(h).run([{"do": "contract", "as": "poster", "id": str(c.id)}])

func _truth_index(h: FakeStoryHost, c: Dictionary) -> int:
	var th := Contracts.theory(h.data, c)
	var open: Array = c.hypotheses.filter(func(x): return str(x.id) not in th.out)
	for i in open.size():
		if str(open[i].id) == str(c.truth):
			return i
	return -1

## Takes the contract, finds every clue, goes to the lair and ends it the given way. Returns the host.
func _finish(c: Dictionary, ending: String, guess_wrong := false) -> FakeStoryHost:
	var h := _host(c)
	var id := str(c.id)
	assert_true(Contracts.take(h.data, id, false).ok, id + " can be taken")
	for k in c.clues:   # a wrong guess is made by someone who has found nothing
		if not guess_wrong:
			assert_true(Contracts.note_clue(h.data, id, str(k.id)), "%s clue %s noted" % [id, k.id])
	var gi := _truth_index(h, c)
	if guess_wrong:
		gi = 0 if gi != 0 else 1
	var ch := Contracts.choice_of(c, ending)
	if str(ch.get("via", "")) == "catch":
		h.choices = [0, gi]
		h.battle_results = [{"result": "caught"}]
	else:
		h.choices = [0, gi, Contracts.menu_choices(c).find(ch)]
	await _lair(h, c)
	return h

func test_the_files_validate() -> void:
	assert_true(Contracts.all().size() >= 1)
	var errs := Contracts.validate(ZoneData.load_all(), StoryData.all_dialogue(), Dex.load_default(), ItemDB.load_default())
	assert_eq(errs, [], "contract data problems")

func test_old_saves_have_no_contracts() -> void:
	var d := GameStateData.new()
	assert_false(Contracts.visible(d))
	assert_eq(Contracts.open_ones(d), [])
	for c in Contracts.all():
		assert_eq(Contracts.state(d, str(c.id)), 0)
		assert_eq(Contracts.ending_id(d, str(c.id)), "")
		assert_false(Contracts.beaten(d, str(c.id)))
		assert_false(Contracts.clue_found(d, str(c.id), str(c.clues[0].id)))

func test_every_branch_of_every_contract_can_be_finished() -> void:
	for c in Contracts.all():
		for ch in c.choices:
			var id := str(c.id)
			var h := await _finish(c, str(ch.id))
			assert_eq(Contracts.state(h.data, id), Contracts.DECIDED, "%s/%s decided" % [id, ch.id])
			assert_eq(Contracts.ending_id(h.data, id), str(ch.id), "%s/%s ending" % [id, ch.id])
			assert_true(h.data.flag(Contracts.flag(id, "is_" + str(ch.id))) == true, "%s/%s is_ flag" % [id, ch.id])
			for k in ch.flags:
				assert_eq(h.data.flag(str(k)), ch.flags[k], "%s/%s flag %s" % [id, ch.id, k])
			for g in ch.get("repute", {}):
				assert_eq(Contracts.repute(h.data, str(g)), int(ch.repute[g]), "%s/%s repute %s" % [id, ch.id, g])
			assert_eq(h.warps.size(), 1, "the zone is rebuilt so the creature stands or goes")
			assert_eq(h.last_battle.foes.size(), 1)
			# the poster pays once, in the town's money, and the standing moves
			var before := {"money": h.data.money, "euros": h.data.euros}
			await _poster(h, c)
			assert_eq(Contracts.state(h.data, id), Contracts.CLOSED, "%s/%s closed" % [id, ch.id])
			var paid: int = (h.data.money - int(before.money)) + (h.data.euros - int(before.euros))
			assert_true(paid > 0, "%s/%s pays" % [id, ch.id])
			var again := h.data.money + h.data.euros
			await _poster(h, c)
			assert_eq(h.data.money + h.data.euros, again, "paid once")
			assert_false(Contracts.report(h.data, id, str(c.town)).ok, "no second report")
			# the choice is in the save
			var d2 := GameStateData.from_dict(h.data.to_dict(), h.dex)
			assert_eq(Contracts.ending_id(d2, id), str(ch.id))
			assert_true(d2.flag(Contracts.flag(id, "is_" + str(ch.id))) == true)
			assert_eq(Contracts.state(d2, id), Contracts.CLOSED)

func test_a_wrong_guess_makes_the_fight_harder_never_impossible() -> void:
	for c in Contracts.all():
		var h := _host(c)
		var right := Contracts.fight_level(h.data, c, str(c.truth))
		var wrong_id := str(c.hypotheses[0].id) if str(c.hypotheses[0].id) != str(c.truth) else str(c.hypotheses[1].id)
		assert_eq(Contracts.fight_level(h.data, c, wrong_id), right + Contracts.WRONG_LEVELS)
		assert_eq(Contracts.fight_level(h.data, c, ""), right + Contracts.UNSURE_LEVELS)
		assert_true(Contracts.WRONG_LEVELS <= 5, "never impossible")
		# and it is above the par it was written at
		assert_true(right > int(c.lair.floor_par), "%s stands above the par" % c.id)
		# the real fight uses it
		var f := await _finish(c, str(Contracts.menu_choices(c)[0].id), true)
		assert_eq(int(f.last_battle.foes[0].level), right + Contracts.WRONG_LEVELS, "%s wrong guess level" % c.id)
		assert_eq(f.last_battle.foes[0].display_name(), str(c.lair.name))

func test_the_creature_lifts_with_the_story() -> void:
	var c: Dictionary = Contracts.all()[0]
	var d := GameStateData.new()
	var early := Contracts.fight_level(d, c, str(c.truth))
	d.set_flag("game_complete", true)
	assert_true(Contracts.fight_level(d, c, str(c.truth)) > early)

func test_clues_work_out_what_it_is() -> void:
	for c in Contracts.all():
		var d := GameStateData.new()
		d.set_flag(Contracts.flag(str(c.id), "state"), Contracts.TAKEN)
		for k in c.clues:
			Contracts.note_clue(d, str(c.id), str(k.id))
		var th := Contracts.theory(d, c)
		assert_eq(th.lead, [str(c.truth)], "%s: every clue leaves only the truth" % c.id)
		assert_true(th.sure, "%s: sure with every clue" % c.id)
		assert_false(str(c.truth) in th.out, "%s: the truth is never ruled out" % c.id)
		# before any clue, nothing is claimed
		var d0 := GameStateData.new()
		assert_eq(Contracts.theory(d0, c).lead, [], "%s: nothing before the clues" % c.id)

func test_look_spots_keep_their_hours() -> void:
	var c := Contracts.get_contract("mink")
	var d := GameStateData.new()
	assert_eq(Contracts.look(d, "mink.dusk", "dusk", "clear").lines, [], "not yours before you take it")
	d.set_flag(Contracts.flag("mink", "state"), Contracts.TAKEN)
	var day := Contracts.look(d, "mink.dusk", "day", "clear")
	assert_false(day.new)
	assert_false(Contracts.clue_found(d, "mink", "dusk"))
	assert_eq(day.lines.size(), 1, "it says to come back later")
	var night := Contracts.look(d, "mink.dusk", "night", "clear")
	assert_true(night.new)
	assert_true(Contracts.clue_found(d, "mink", "dusk"))
	assert_eq(night.lines, [Contracts.clue_text(Contracts.clue_of(c, "dusk"))])
	assert_false(Contracts.look(d, "mink.dusk", "night", "clear").new, "found once")
	assert_true(Contracts.look(d, "mink.nonsense", "day", "clear").lines.is_empty())

func test_weather_clues_wait_for_the_weather() -> void:
	var k := {"when": {"weather": ["rain", "fog"]}}
	assert_true(Contracts.clue_ready(k, "day", "drizzle"))
	assert_true(Contracts.clue_ready(k, "day", "fog"))
	assert_false(Contracts.clue_ready(k, "day", "clear"))
	assert_true(Contracts.clue_ready({}, "night", "gale"))

func test_weak_to_follows_the_type_chart() -> void:
	assert_has(Contracts.weak_to(["brook", "night"]), "hedgerow")
	assert_false("brook" in Contracts.weak_to(["brook"]))

func test_fees_are_modest_and_haggling_needs_a_town_that_knows_you() -> void:
	var c := Contracts.get_contract("mink")
	var d := GameStateData.new()
	for i in 2:
		d.badges.append("b%d" % i)
	var base := Contracts.base_fee(c)
	assert_eq(Contracts.offer_fee(d, c), base)
	assert_near(Contracts.haggle_share(d, c), 0.0)
	assert_eq(Contracts.take(d, "mink", true).fee, base, "a stranger cannot haggle")
	var d2 := GameStateData.new()
	for i in 2:
		d2.badges.append("b%d" % i)
	d2.set_flag("standing_england", 40)
	assert_true(Contracts.haggle_share(d2, c) > 0.0)
	var r := Contracts.take(d2, "mink", true)
	assert_true(int(r.fee) > base)
	assert_eq(Contracts.fee(d2, "mink"), int(r.fee))
	assert_false(Contracts.take(d2, "mink", false).ok, "taken once")
	# repute moves the fee a little either way
	var d3 := GameStateData.new()
	for i in 2:
		d3.badges.append("b%d" % i)
	d3.set_flag("ct_rep_farmers", 100)
	assert_true(Contracts.offer_fee(d3, c) <= int(base * 1.25) and Contracts.offer_fee(d3, c) > base)
	# modest: a contract is worth a few jobs, not a Deed
	for cc in Contracts.all():
		var jobs := Jobs.money_for({"pay": 1}, int(cc.badges))
		assert_true(Contracts.base_fee(cc) <= 5 * jobs, "%s pays no more than five jobs" % cc.id)

func test_it_cannot_be_taken_before_the_badges() -> void:
	var c := Contracts.get_contract("mink")
	var d := GameStateData.new()
	assert_false(Contracts.take(d, "mink", false).ok)
	assert_eq(Contracts.offered(d, "manchester"), [])
	for i in 2:
		d.badges.append("b%d" % i)
	assert_eq(Contracts.offered(d, "manchester").size(), 1)
	Contracts.take(d, "mink", false)
	assert_eq(Contracts.offered(d, "manchester"), [], "off the board once taken")
	assert_eq(c.town, "manchester")

func test_the_board_notice_takes_haggles_and_leaves() -> void:
	var c := Contracts.get_contract("mink")
	var h := _host(c)
	h.choices = [1]   # Just the jobs
	var cmd := Commands.new(h)
	await cmd.run([{"do": "contract", "as": "board", "town": "manchester"}])
	assert_eq(Contracts.state(h.data, "mink"), 0)
	h.choices = [0, 0]   # read it, take it
	await Commands.new(h).run([{"do": "contract", "as": "board", "town": "manchester"}])
	assert_eq(Contracts.state(h.data, "mink"), Contracts.TAKEN)
	assert_eq(Contracts.fee(h.data, "mink"), Contracts.base_fee(c))
	var h2 := _host(c)
	h2.data.set_flag("standing_england", 40)
	h2.choices = [0, 1]   # read it, haggle
	await Commands.new(h2).run([{"do": "contract", "as": "board", "town": "manchester"}])
	assert_true(Contracts.fee(h2.data, "mink") > Contracts.base_fee(c))
	var h3 := _host(c)
	h3.choices = [0, 1]   # read it, leave it for now (no haggle option for a stranger)
	await Commands.new(h3).run([{"do": "contract", "as": "board", "town": "manchester"}])
	assert_eq(Contracts.state(h3.data, "mink"), 0)

func test_witnesses_only_help_once_you_have_the_contract() -> void:
	var c := Contracts.get_contract("mink")
	var h := _host(c)
	await Commands.new(h).run([{"do": "contract", "as": "clue", "id": "mink", "clue": "volunteer"}])
	assert_false(Contracts.clue_found(h.data, "mink", "volunteer"))
	Contracts.take(h.data, "mink", false)
	await Commands.new(h).run([{"do": "contract", "as": "clue", "id": "mink", "clue": "volunteer"}])
	assert_true(Contracts.clue_found(h.data, "mink", "volunteer"))

func test_losing_the_fight_leaves_the_contract_open() -> void:
	var c := Contracts.get_contract("mink")
	var h := _host(c)
	Contracts.take(h.data, "mink", false)
	h.choices = [0, 0]
	h.battle_results = [{"result": "lose"}]
	h.data.last_sanctuary = {"zone": "manchester_sanctuary", "pos": [3, 3]}
	await _lair(h, c)
	assert_eq(Contracts.state(h.data, "mink"), Contracts.TAKEN)
	assert_false(Contracts.beaten(h.data, "mink"))

func test_beaten_but_undecided_waits_for_you() -> void:
	var c := Contracts.get_contract("mink")
	var h := _host(c)
	Contracts.take(h.data, "mink", false)
	h.choices = [0, 0, Contracts.menu_choices(c).size()]   # face it, name something, then "think it over"
	await _lair(h, c)
	assert_true(Contracts.beaten(h.data, "mink"))
	assert_eq(Contracts.state(h.data, "mink"), Contracts.TAKEN)
	h.choices = [0]   # back later: straight to the decision, no second fight
	h.last_battle = {}
	await _lair(h, c)
	assert_eq(Contracts.ending_id(h.data, "mink"), str(Contracts.menu_choices(c)[0].id))
	assert_true(h.last_battle.is_empty(), "no second fight")

func test_every_choice_changes_something_that_a_resident_shows() -> void:
	for c in Contracts.all():
		var shown := {}
		for f in c.places.get("folk", []):
			for k in ["show_if", "hide_if"]:
				if f.has(k):
					shown[str(f[k])] = true
			for s in f.get("says", []):
				shown[str(s[0])] = true
		for other in Contracts.all():
			for n in other.get("needs", []):
				if str(n.contract) == str(c.id):
					shown[Contracts.flag(str(c.id), "is_" + str(n.ending))] = true
		for ch in c.choices:
			var hit := shown.has(Contracts.flag(str(c.id), "is_" + str(ch.id)))
			for k in ch.flags:
				hit = hit or shown.has(str(k))
			assert_true(hit, "%s/%s changes something a resident shows" % [c.id, ch.id])

func test_residents_say_what_the_choice_changed() -> void:
	for c in Contracts.all():
		for f in c.places.get("folk", []):
			var zone := str(f.zone)
			var script: Array = StoryData.script(zone, "ct_%s_%s" % [c.id, f.id])
			assert_false(script.is_empty(), "%s folk %s has lines" % [c.id, f.id])
			for s in f.get("says", []):
				var h := _host(c)
				h.zone = zone
				h.data.set_flag(str(s[0]), true)
				await Commands.new(h).run(script)
				assert_eq(h.texts(), s[1], "%s/%s says the %s line" % [c.id, f.id, s[0]])
			var h2 := _host(c)
			await Commands.new(h2).run(script)
			assert_eq(h2.texts(), f.get("else", []), "%s/%s default line" % [c.id, f.id])

func test_standing_can_fall_but_not_below_nothing() -> void:
	var d := GameStateData.new()
	d.set_flag("standing_wales", 5)
	Contracts.move_standing(d, "wales", -3)
	assert_eq(Standing.points(d, "wales"), 2)
	Contracts.move_standing(d, "wales", -9)
	assert_eq(Standing.points(d, "wales"), 0)
	Contracts.move_standing(d, "wales", 4)
	assert_eq(Standing.points(d, "wales"), 4)

func test_the_creature_only_stands_in_its_lair_while_the_contract_is_live() -> void:
	for c in Contracts.all():
		var z := ZoneData.load_id(str(c.lair.zone))
		var lair := {}
		for n in z.npcs:
			if str(n.get("id", "")) == "ct_%s_lair" % c.id:
				lair = n
		assert_false(lair.is_empty(), "%s has a lair NPC" % c.id)
		var d := GameStateData.new()
		assert_false(Npc.should_spawn(lair, d, "day"), "%s is not there on an old save" % c.id)
		d.set_flag(Contracts.flag(str(c.id), "state"), Contracts.TAKEN)
		assert_true(Npc.should_spawn(lair, d, "day"), "%s stands there once taken" % c.id)
		d.set_flag(Contracts.flag(str(c.id), "end"), "x")
		assert_false(Npc.should_spawn(lair, d, "day"), "%s is gone once decided" % c.id)

func test_a_later_contract_waits_for_an_ending() -> void:
	var a := {"id": "a", "town": "x", "badges": 0, "choices": [{"id": "yes"}, {"id": "no"}]}
	var b := {"id": "b", "town": "x", "badges": 0, "needs": [{"contract": "a", "ending": "yes"}]}
	Contracts.use([a, b])
	var d := GameStateData.new()
	assert_eq(Contracts.offered(d, "x").map(func(c): return c.id), ["a"], "b is not on the board yet")
	d.set_flag(Contracts.flag("a", "state"), Contracts.CLOSED)
	d.set_flag(Contracts.flag("a", "end"), "no")
	assert_eq(Contracts.offered(d, "x"), [], "the other ending never brings it")
	d.set_flag(Contracts.flag("a", "end"), "yes")
	assert_eq(Contracts.offered(d, "x").map(func(c): return c.id), ["b"], "this ending does")
	Contracts.reset()

func test_the_total_of_the_fees_is_modest() -> void:
	assert_true(Contracts.fees_total() > 0.0)
	assert_true(Contracts.fees_total() < 80000.0, "all twelve together are a lump, not a living")
