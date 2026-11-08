extends TestCase

const NameEntry = preload("res://ui/name_entry.gd")

var _items := ItemDB.load_default()

func _flow(party: Array, foes: Array, ui: FakeBattleUI, opts := {}, bag := {}) -> BattleFlow:
	var data := GameStateData.new()
	data.party = party
	data.bag = bag
	return BattleFlow.new(data, Fixtures.dex(), Fixtures.moves(), Fixtures.chart(), _items, Rng.new(7), foes, opts, ui)

func test_win_wild_battle_awards_xp() -> void:
	var a := Fixtures.creature("kindlet", 10)
	var foe := Fixtures.creature("spikkin", 3)
	var xp0 := a.xp
	var ui := FakeBattleUI.new()
	var f := _flow([a], [foe], ui)
	f.run()
	assert_eq(f.result.result, "win")
	assert_true(a.xp > xp0, "xp rose")
	assert_true(foe.is_fainted())
	assert_true(f.data.seen.has("spikkin"), "foe marked seen")
	assert_true(ui.xp_calls >= 1)
	var gained := false
	for l in ui.said:
		if str(l).contains("gained"):
			gained = true
	assert_true(gained, "xp line said")
	assert_has(ui.event_types(), "faint")

func test_lose_battle() -> void:
	var a := Fixtures.creature("kindlet", 3)
	var foe := Fixtures.creature("spikkin", 40)
	var ui := FakeBattleUI.new()
	var f := _flow([a], [foe], ui)
	f.run()
	assert_eq(f.result.result, "lose")
	assert_true(a.is_fainted())
	assert_false(foe.is_fainted())

func test_forced_replacement_when_creature_faints() -> void:
	var a := Fixtures.creature("kindlet", 3)
	var b := Fixtures.creature("kindlet", 3)
	var foe := Fixtures.creature("spikkin", 30)
	var ui := FakeBattleUI.new()
	var f := _flow([a, b], [foe], ui)
	f.run()
	assert_eq(f.result.result, "lose")
	assert_eq(ui.replacement_asked, 1, "asked once for the only reserve")
	assert_true(b.is_fainted())

func test_catch_with_full_party_goes_to_ark() -> void:
	var party := []
	for i in 6:
		party.append(Fixtures.creature("kindlet", 10))
	var sp := Fixtures.species("pushover", ["kin"], 50, {"catch_rate": 255})
	var foe := Creature.create(sp, 3, FixedRng.new(), Fixtures.moves())
	foe.hp = 1
	var ui := FakeBattleUI.new()
	for i in 20:
		ui.picks.append({"kind": "item", "item": "wicker_snare"})
	var f := _flow(party, [foe], ui, {}, {"wicker_snare": 20})
	f.run()
	assert_eq(f.result.result, "caught")
	assert_true(f.result.caught == foe)
	assert_eq(f.data.party.size(), 6)
	assert_eq(f.data.ark.size(), 1)
	assert_true(f.data.caught.has("pushover"))
	assert_true(f.data.bag.get("wicker_snare", 0) < 20, "snare consumed")
	var told := false
	for l in ui.said:
		if str(l).begins_with("Did you know?"):
			told = true
	assert_eq(ui.first_catches.size(), 1, "first catch shows the Fieldbook popup")
	var types := ui.event_types()
	assert_has(types, "catch")

func test_catch_goes_to_party_when_room() -> void:
	var a := Fixtures.creature("kindlet", 10)
	var sp := Fixtures.species("pushover", ["kin"], 50, {"catch_rate": 255})
	var foe := Creature.create(sp, 3, FixedRng.new(), Fixtures.moves())
	foe.hp = 1
	var ui := FakeBattleUI.new()
	for i in 20:
		ui.picks.append({"kind": "item", "item": "wicker_snare"})
	var f := _flow([a], [foe], ui, {}, {"wicker_snare": 20})
	f.run()
	assert_eq(f.result.result, "caught")
	assert_eq(f.data.party.size(), 2)

func test_snare_not_used_on_trainer_battles() -> void:
	var a := Fixtures.creature("kindlet", 10)
	var foe := Fixtures.creature("spikkin", 3)
	var ui := FakeBattleUI.new()
	ui.picks.append({"kind": "item", "item": "wicker_snare"})
	var f := _flow([a], [foe], ui, {"kind": "trainer", "trainer": {"name": "Keeper Maud"}}, {"wicker_snare": 2})
	f.run()
	assert_eq(f.data.bag.wicker_snare, 2, "not consumed")
	assert_eq(f.result.result, "win")

func test_wobbles_from_chance() -> void:
	assert_eq(BattleFlow.wobbles_for(0.05, false), 1)
	assert_eq(BattleFlow.wobbles_for(0.5, false), 2)
	assert_eq(BattleFlow.wobbles_for(0.95, false), 3)
	assert_eq(BattleFlow.wobbles_for(0.05, true), 3)

func test_learn_pending_skip() -> void:
	var a := Fixtures.creature("kindlet", 12)
	assert_eq(a.moves.size(), 4)
	a.xp = Rules.xp_for_level(a.species.growth, 13) - 1
	var ui := FakeBattleUI.new()
	var f := _flow([a], [Fixtures.creature("spikkin", 3)], ui)
	var before := a.moves.map(func(m): return m.id)
	f.run()
	assert_eq(a.level, 13)
	assert_eq(ui.forget_asked, [["Kindlet", "smoulder"]])
	assert_eq(a.moves.map(func(m): return m.id), before, "skipped, moves unchanged")
	assert_false(a.has_move("smoulder"))

func test_learn_pending_replace() -> void:
	var a := Fixtures.creature("kindlet", 12)
	a.xp = Rules.xp_for_level(a.species.growth, 13) - 1
	var ui := FakeBattleUI.new()
	ui.forget_slot = 0
	var f := _flow([a], [Fixtures.creature("spikkin", 3)], ui)
	f.run()
	assert_true(a.has_move("smoulder"))
	assert_false(a.has_move("scrap"))

func test_evolves_at_level_threshold() -> void:
	var a := Fixtures.creature("kindlet", 15)
	a.xp = Rules.xp_for_level(a.species.growth, 16) - 1
	var ui := FakeBattleUI.new()
	var f := _flow([a], [Fixtures.creature("spikkin", 3)], ui)
	f.run()
	assert_eq(a.level, 16)
	assert_eq(a.species.id, "emberdrey")
	assert_eq(ui.evolve_asked, [["kindlet", "emberdrey"]])
	assert_true(f.data.caught.has("emberdrey"))

func test_evolution_can_be_cancelled() -> void:
	var a := Fixtures.creature("kindlet", 15)
	a.xp = Rules.xp_for_level(a.species.growth, 16) - 1
	var ui := FakeBattleUI.new()
	ui.evolve = false
	var f := _flow([a], [Fixtures.creature("spikkin", 3)], ui)
	f.run()
	assert_eq(a.species.id, "kindlet")
	assert_eq(f.result.result, "win")

func test_trainer_switches_and_pays() -> void:
	var a := Fixtures.creature("kindlet", 20)
	var foes := [Fixtures.creature("spikkin", 3), Fixtures.creature("spikkin", 3)]
	var ui := FakeBattleUI.new()
	var tr := {"name": "Keeper Maud", "money": 250}
	var f := _flow([a], foes, ui, {"kind": "trainer", "trainer": tr, "ai": "trainer"})
	var money0 := f.data.money
	f.run()
	assert_eq(f.result.result, "win")
	assert_eq(f.data.money, money0 + 250)
	assert_true(foes[1].is_fainted())
	var sent := false
	for l in ui.said:
		if str(l).contains("sends out"):
			sent = true
	assert_true(sent, "trainer sends out second creature")
	assert_eq(f.result.money, 250)

func test_run_from_wild() -> void:
	var a := Fixtures.creature("kindlet", 30)
	var ui := FakeBattleUI.new()
	ui.picks.append({"kind": "run"})
	var f := _flow([a], [Fixtures.creature("spikkin", 3)], ui)
	f.run()
	assert_eq(f.result.result, "ran")

func test_cannot_run_from_trainer() -> void:
	var a := Fixtures.creature("kindlet", 30)
	var ui := FakeBattleUI.new()
	ui.picks.append({"kind": "run"})
	var f := _flow([a], [Fixtures.creature("spikkin", 3)], ui, {"kind": "trainer", "trainer": {"name": "Keeper Maud"}})
	f.run()
	assert_eq(f.result.result, "win")
	var said_no := false
	for l in ui.said:
		if str(l).contains("no running"):
			said_no = true
	assert_true(said_no)

func test_healing_item_is_consumed_and_invalid_one_is_not() -> void:
	var a := Fixtures.creature("kindlet", 10)
	var ui := FakeBattleUI.new()
	ui.picks.append({"kind": "item", "item": "cup_of_tea", "target": 0})  # full HP: refused, not consumed
	var f := _flow([a], [Fixtures.creature("spikkin", 3)], ui, {}, {"cup_of_tea": 1})
	f.run()
	assert_eq(f.data.bag.get("cup_of_tea", 0), 1)
	a = Fixtures.creature("kindlet", 10)
	a.hp = 3
	ui = FakeBattleUI.new()
	ui.picks.append({"kind": "item", "item": "cup_of_tea", "target": 0})
	f = _flow([a], [Fixtures.creature("spikkin", 3)], ui, {}, {"cup_of_tea": 1})
	f.run()
	assert_eq(f.data.bag.get("cup_of_tea", 0), 0)
	assert_has(ui.event_types(), "item")

func test_battle_items_lists_only_usable() -> void:
	var a := Fixtures.creature("kindlet", 10)
	var f := _flow([a], [Fixtures.creature("spikkin", 3)], FakeBattleUI.new(), {}, {"cup_of_tea": 2, "wicker_snare": 1, "lucky_charm_key": 1})
	var ids := f.battle_items().map(func(e): return e.id)
	assert_has(ids, "cup_of_tea")
	assert_has(ids, "wicker_snare")
	assert_eq(ids.size(), 2)
	var t := _flow([a], [Fixtures.creature("spikkin", 3)], FakeBattleUI.new(), {"kind": "trainer"}, {"cup_of_tea": 2, "wicker_snare": 1})
	assert_eq(t.battle_items().map(func(e): return e.id), ["cup_of_tea"])

func test_first_catch_shows_the_fieldbook_popup() -> void:
	var a := Fixtures.creature("kindlet", 10)
	var sp := Fixtures.species("pushover", ["kin"], 50, {"catch_rate": 255})
	var foe := Creature.create(sp, 3, FixedRng.new(), Fixtures.moves())
	foe.hp = 1
	var ui := FakeBattleUI.new()
	for i in 20:
		ui.picks.append({"kind": "item", "item": "wicker_snare"})
	var f := _flow([a], [foe], ui, {}, {"wicker_snare": 20})
	f.run()
	assert_eq(ui.first_catches, ["pushover"])

# --- after a catch: nickname and a full party ------------------------------------

func _catch(party: Array, ui: FakeBattleUI) -> BattleFlow:
	var sp := Fixtures.species("pushover", ["kin"], 50, {"catch_rate": 255})
	var foe := Creature.create(sp, 3, FixedRng.new(), Fixtures.moves())
	foe.hp = 1
	for i in 20:
		ui.picks.append({"kind": "item", "item": "wicker_snare"})
	var f := _flow(party, [foe], ui, {}, {"wicker_snare": 20})
	f.run()
	return f

func _full_party() -> Array:
	var party := []
	for i in 6:
		party.append(Fixtures.creature("kindlet", 10))
	return party

func test_catch_offers_a_nickname() -> void:
	var ui := FakeBattleUI.new()
	ui.nickname = "Biscuit"
	var f := _catch([Fixtures.creature("kindlet", 10)], ui)
	assert_eq(ui.nickname_asked, ["pushover"])
	assert_eq(f.result.caught.nickname, "Biscuit")
	assert_eq(f.result.caught.display_name(), "Biscuit")
	assert_eq(ui.nickname_targets, ["nickname:1"], "the name entry is opened on the team slot it joined")

func test_nickname_reaches_a_catch_sent_to_the_ark() -> void:
	var ui := FakeBattleUI.new()
	ui.nickname = "Crumpet"
	var f := _catch(_full_party(), ui)  # full team, sent to the Ark
	var i := f.data.ark.find(f.result.caught)
	assert_true(i >= 0)
	assert_eq(ui.nickname_targets, ["nickname:ark:%d" % i])
	assert_eq(NameEntry.nickname_target(f.data, ui.nickname_targets[0]), f.result.caught)
	assert_eq(f.result.caught.display_name(), "Crumpet")

func test_nickname_follows_a_swap_into_the_team() -> void:
	var ui := FakeBattleUI.new()
	ui.catch_slot = 2
	var f := _catch(_full_party(), ui)
	assert_eq(ui.nickname_targets, ["nickname:2"])
	assert_eq(NameEntry.nickname_target(f.data, "nickname:2"), f.result.caught)

func test_declined_nickname_keeps_the_species_name() -> void:
	var ui := FakeBattleUI.new()
	var f := _catch([Fixtures.creature("kindlet", 10)], ui)
	assert_eq(f.result.caught.nickname, "")

func test_full_party_swap_sends_the_replaced_one_to_the_ark() -> void:
	var party := _full_party()
	var old: Creature = party[4]
	var ui := FakeBattleUI.new()
	ui.catch_slot = 4
	var f := _catch(party, ui)
	assert_eq(ui.destination_asked, ["pushover"])
	assert_true(f.data.party[4] == f.result.caught, "the new catch took the slot")
	assert_true(old in f.data.ark)
	assert_eq(f.data.party.size(), 6)

func test_full_party_can_still_choose_the_ark() -> void:
	var ui := FakeBattleUI.new()
	var f := _catch(_full_party(), ui)  # default: -1, the Ark
	assert_true(f.result.caught in f.data.ark)
	assert_eq(f.data.party.size(), 6)

func test_room_in_the_party_asks_no_destination() -> void:
	var ui := FakeBattleUI.new()
	_catch([Fixtures.creature("kindlet", 10)], ui)
	assert_eq(ui.destination_asked, [])

# --- double battles --------------------------------------------------------------

func _double_opts() -> Dictionary:
	return {"kind": "trainer", "ai": "trainer", "double": true, "trainer": {"name": "Twins Aoife and Fionn"}}

func test_double_battle_runs_to_a_win_and_shares_xp() -> void:
	var a := Fixtures.creature("kindlet", 20)
	var b := Fixtures.creature("kindlet", 20)
	var xa := a.xp
	var xb := b.xp
	var ui := FakeBattleUI.new()
	var f := _flow([a, b], [Fixtures.creature("spikkin", 3), Fixtures.creature("spikkin", 3)], ui, _double_opts())
	f.run()
	assert_eq(f.result.result, "win")
	assert_true(f.battle.double)
	assert_true(a.xp > xa and b.xp > xb, "both creatures on the field earned XP")
	assert_has(f.log, "Twins Aoife and Fionn sends out Spikkin and Spikkin!")
	assert_has(f.log, "Go! Kindlet and Kindlet!")

func test_double_battle_xp_goes_only_to_witnesses() -> void:
	var a := Fixtures.creature("kindlet", 20)
	var b := Fixtures.creature("kindlet", 20)
	var bench := Fixtures.creature("kindlet", 20)
	var x0 := bench.xp
	var f := _flow([a, b, bench], [Fixtures.creature("spikkin", 3), Fixtures.creature("spikkin", 3)], FakeBattleUI.new(), _double_opts())
	f.run()
	assert_eq(f.result.result, "win")
	assert_eq(bench.xp, x0, "the creature on the bench saw nothing")

func test_double_battle_replaces_each_fainted_position() -> void:
	var a := Fixtures.creature("kindlet", 3)
	var b := Fixtures.creature("kindlet", 3)
	var c := Fixtures.creature("kindlet", 3)
	var ui := FakeBattleUI.new()
	var f := _flow([a, b, c], [Fixtures.creature("spikkin", 30), Fixtures.creature("spikkin", 30)], ui, _double_opts())
	f.run()
	assert_eq(f.result.result, "lose")
	assert_eq(ui.replacement_asked, 1, "one reserve, one replacement")
	assert_true(c.is_fainted(), "the reserve came in and fought")

func test_double_battle_refuses_snares() -> void:
	var ui := FakeBattleUI.new()
	ui.picks.append({"kind": "item", "item": "wicker_snare"})
	var f := _flow([Fixtures.creature("kindlet", 20), Fixtures.creature("kindlet", 20)],
		[Fixtures.creature("spikkin", 3), Fixtures.creature("spikkin", 3)], ui, _double_opts(), {"wicker_snare": 2})
	f.run()
	assert_eq(f.data.bag.wicker_snare, 2, "not consumed")
	assert_eq(f.result.result, "win")

func test_double_battle_target_is_passed_through() -> void:
	var ui := FakeBattleUI.new()
	ui.picks.append({"kind": "fight", "slot": 0, "target": 1})
	ui.picks.append({"kind": "fight", "slot": 0, "target": 1})
	var f := _flow([Fixtures.creature("kindlet", 20), Fixtures.creature("kindlet", 20)],
		[Fixtures.creature("spikkin", 20), Fixtures.creature("spikkin", 20)], ui, _double_opts())
	f.run()
	var first_player_hit := {}
	for e in ui.event_batches[0]:
		if e.type == "damage" and e.side == Battle.FOE:
			first_player_hit = e
			break
	assert_eq(first_player_hit.get("pos", -1), 1)

func test_team_thermos_shares_three_quarters_xp_with_the_bench() -> void:
	var a := Fixtures.creature("kindlet", 10)
	var b := Fixtures.creature("spikkin", 5)
	var foe := Fixtures.creature("spikkin", 3)
	var a0 := a.xp
	var b0 := b.xp
	var f := _flow([a, b], [foe], FakeBattleUI.new(), {}, {"team_thermos": 1})
	f.run()
	assert_eq(f.result.result, "win")
	assert_true(b.xp > b0, "the benched creature shared the XP")
	assert_eq(BattleFlow.THERMOS_SHARE, 0.75)
	assert_eq(b.xp - b0, maxi(1, int((a.xp - a0) * 0.75)), "three quarters of the fighter's share")

func test_team_thermos_switched_off_or_missing_shares_nothing() -> void:
	for bag in [{}, {"team_thermos": 1}]:
		var a := Fixtures.creature("kindlet", 10)
		var b := Fixtures.creature("spikkin", 5)
		var b0 := b.xp
		var f := _flow([a, b], [Fixtures.creature("spikkin", 3)], FakeBattleUI.new(), {}, bag)
		f.data.set_flag("thermos_off", not bag.is_empty())
		f.run()
		assert_eq(b.xp, b0, "no share")

func test_team_thermos_skips_the_fainted() -> void:
	var a := Fixtures.creature("kindlet", 10)
	var b := Fixtures.creature("spikkin", 5)
	b.hp = 0
	var d := GameStateData.new()
	d.party = [a, b]
	d.bag = {"team_thermos": 1}
	assert_eq(BattleFlow.thermos_sharers(d, [a]), [])

func test_xp_is_split_between_creatures_that_fought_the_foe() -> void:
	# a starts, switches out for b, b finishes the foe: both fought it, so they split the XP
	var a := Fixtures.creature("kindlet", 10)
	var b := Fixtures.creature("spikkin", 12)
	var foe := Fixtures.creature("spikkin", 4)
	var a0 := a.xp
	var b0 := b.xp
	var ui := FakeBattleUI.new()
	ui.picks.append({"kind": "switch", "index": 1})
	var f := _flow([a, b], [foe], ui)
	f.run()
	assert_eq(f.result.result, "win")
	var whole := Progression.xp_reward(foe, false)
	assert_eq(a.xp - a0, maxi(1, whole / 2), "the one switched out gets half")
	assert_eq(b.xp - b0, maxi(1, whole / 2), "the finisher gets half")

func test_xp_goes_whole_to_a_lone_fighter() -> void:
	var a := Fixtures.creature("kindlet", 10)
	var b := Fixtures.creature("spikkin", 12)
	var foe := Fixtures.creature("spikkin", 4)
	var b0 := b.xp
	var a0 := a.xp
	var f := _flow([a, b], [foe], FakeBattleUI.new())
	f.run()
	assert_eq(a.xp - a0, Progression.xp_reward(foe, false), "never switched: all of it")
	assert_eq(b.xp, b0, "the bench gets nothing without the Thermos")

func test_a_fainted_fighter_does_not_share() -> void:
	var b := Battle.new([Fixtures.creature("kindlet", 10), Fixtures.creature("spikkin", 12)], [Fixtures.creature("spikkin", 4)], {"chart": Fixtures.chart(), "move_db": Fixtures.moves()})
	b.force_switch(Battle.PLAYER, 1, 0)
	b.parties[Battle.PLAYER][0].hp = 0
	var ev := []
	b.parties[Battle.FOE][0].hp = 0
	b._faint(Battle.FOE, 0, ev)
	assert_eq(ev[0].witnesses, [1], "only the standing fighter")

func test_meal_stat_buff_plays_as_an_event_so_the_plate_shows_it() -> void:  # not a turn later at the sync
	var a := Fixtures.creature("kindlet", 10)
	var ui := FakeBattleUI.new()
	var f := _flow([a], [Fixtures.creature("spikkin", 3)], ui)
	f.data.set_flag(Meals.FLAG, "lancashire_hotpot")
	f.run()
	var first: Dictionary = ui.event_batches[0][0]
	assert_eq([first.type, first.side, int(first.delta)], ["charm", Battle.PLAYER, 1])
	assert_true(str(first.stat) != "")
	assert_true(f.log.any(func(l): return str(l).begins_with(a.display_name())), "the dish's line names the lead")
