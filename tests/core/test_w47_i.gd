extends TestCase
## Trumps (core/trumps.gd): card stats, a seeded game, holders, region sets, the album, the hook, old saves.

func _d() -> GameStateData:
	return GameStateData.new()

func test_stats_cover_one_to_ten_across_the_dex() -> void:
	var dex := Trumps.dex()
	for stat in Trumps.STATS:
		var seen := {}
		for id in dex.core_ids():
			var v := int(Trumps.card_of(id)[stat])
			assert_true(v >= 1 and v <= 10, "%s %s" % [id, stat])
			seen[v] = true
		assert_true(seen.has(1) and seen.has(10), "%s spans 1..10" % stat)
		assert_true(seen.size() >= (4 if stat == "rarity" else 8), "%s has spread" % stat)

func test_legends_are_the_rarest() -> void:
	for id in Trumps.legends():
		assert_eq(int(Trumps.card_of(id).rarity), 10)

func test_game_is_deterministic_with_a_seed() -> void:
	var a := Trumps.autoplay(Trumps.new_game(["spikkin", "kindlet", "holtling", "binfox", "hootlet"], ["bramblehog", "emberdrey", "redbreast", "snowhare", "gritling"]), Rng.new(7))
	var b := Trumps.autoplay(Trumps.new_game(["spikkin", "kindlet", "holtling", "binfox", "hootlet"], ["bramblehog", "emberdrey", "redbreast", "snowhare", "gritling"]), Rng.new(7))
	assert_eq(a.mine, b.mine)
	assert_eq(a.theirs, b.theirs)
	assert_true(Trumps.over(a))
	assert_eq(a.mine.size() + a.theirs.size(), 10, "no card is lost")

func test_higher_stat_takes_the_pair_and_leads() -> void:
	var g := Trumps.new_game(["spikkin", "kindlet"], ["bramblehog", "emberdrey"])
	var stat := "size"
	for s in Trumps.STATS:
		if Trumps.value(g, "spikkin", s) > Trumps.value(g, "bramblehog", s):
			stat = s
	var r := Trumps.play(g, stat)
	if r.result == "win":
		assert_eq(g.mine.size(), 3)
		assert_eq(g.theirs.size(), 1)
		assert_eq(g.lead, "mine")
		assert_eq(g.mine[-1], "bramblehog")
	elif r.result == "lose":
		assert_eq(g.theirs.size(), 3)
		assert_eq(g.lead, "theirs")

func test_tie_keeps_the_cards_and_blocks_that_stat() -> void:
	var g := Trumps.new_game(["spikkin"], ["spikkin"])
	var r := Trumps.play(g, "lore")
	assert_eq(r.result, "tie")
	assert_eq(g.mine.size(), 1)
	assert_true("lore" in g.tried)
	assert_false("lore" in Trumps.choices(g))
	for s in ["size", "speed", "grit", "rarity"]:
		Trumps.play(g, s)
	assert_eq(g.round, 1, "all five tied: the round passes")

func test_game_ends_at_twelve_rounds_or_empty() -> void:
	var g := Trumps.new_game(["spikkin"], ["spikkin"])
	g.round = Trumps.MAX_ROUNDS
	assert_true(Trumps.over(g))
	assert_eq(Trumps.winner(g), "draw")
	var h := Trumps.new_game(["spikkin", "kindlet"], [])
	assert_true(Trumps.over(h))
	assert_eq(Trumps.winner(h), "mine")

func test_ai_picks_a_legal_stat() -> void:
	var g := Trumps.new_game(["spikkin"], ["balor"])
	var rng := Rng.new(3)
	for i in 30:
		assert_true(Trumps.ai_pick(g, rng) in Trumps.STATS)

func test_holders_are_stable_and_in_region() -> void:
	var idx := ZoneIndex.get_index()
	assert_eq(Trumps.holder("macc_home", "mum", 0), Trumps.holder("macc_home", "mum", 0))
	var deck := Trumps.deck("macc_home", "mum", 5)
	assert_eq(deck.size(), 5)
	assert_eq(deck, Trumps.deck("macc_home", "mum", 5))
	for s in deck:
		assert_true(Trumps.dex().has(str(s)))
	assert_eq(Trumps.region_of("macc_home", idx), "cheshire")

func test_about_half_of_home_residents_play() -> void:
	var idx := ZoneIndex.get_index()
	var n := 0
	var yes := 0
	for id in idx.zones:
		if str(idx.zones[id].kind) != "interior" or not (id.contains("home") or id.contains("pub")):
			continue
		for k in 6:
			n += 1
			if Trumps.plays(id, "npc%d" % k, idx):
				yes += 1
	assert_true(n > 100)
	assert_true(float(yes) / n > 0.35 and float(yes) / n < 0.65, "%d of %d" % [yes, n])
	assert_false(Trumps.plays("macclesfield", "someone", idx), "outdoors never")

func test_starter_five_and_region_sets() -> void:
	var d := _d()
	var five := Trumps.give_starter(d)
	assert_eq(five.size(), 5)
	assert_true(d.flag(Trumps.FLAG_STARTER) == true)
	assert_eq(Trumps.owned_count(d), 5)
	assert_false(Trumps.region_complete(d, "cheshire"))
	for s in Trumps.region_set("cheshire"):
		Trumps.give(d, str(s))
	assert_true(Trumps.region_complete(d, "cheshire"))

func test_album_never_shows_the_appendix() -> void:
	for g in Trumps.album(_d()):
		for s in g.species:
			assert_false(Dex.in_appendix(str(s)), str(s))
			assert_false(Dex.is_hybrid(str(s)), str(s))

func test_album_covers_the_original_200() -> void:
	var seen := {}
	for g in Trumps.album(_d()):
		for s in g.species:
			seen[s] = true
	assert_eq(seen.size(), Trumps.core_ids().size())

func test_settle_pays_the_card_once_then_money() -> void:
	var d := _d()
	var first := Trumps.settle(d, "macc_home", "mum", true)
	assert_true(str(first.card) != "")
	assert_true(Trumps.has_card(d, str(first.card)))
	assert_true(int(first.money) >= 2)
	var again := Trumps.settle(d, "macc_home", "mum", true)
	assert_eq(str(again.card), "")
	var lost := Trumps.settle(d, "macc_home", "mum", false)
	assert_eq(int(lost.money), 0)
	assert_eq(Trumps.streak(d), 0)
	assert_eq(int(d.trumps.wins), 2)

func test_prize_is_fixed_by_region() -> void:
	assert_eq(Trumps.prize("cheshire"), Trumps.prize("cheshire"))
	var p := Trumps.prize("peak")
	assert_true(str(p.kind) in ["chapbook", "coat"])

func test_hook_offers_once_a_day_and_hands_out_the_starter() -> void:
	var d := _d()
	var base := [{"do": "say", "who": "X", "text": "Hi"}]
	var mum := Trumps.hook("macc_home", "mum", base, d)
	assert_eq(mum[-1].do, "trumps")
	assert_eq(mum[-1].give, "starter")
	assert_eq(Trumps.hook("macc_home", "someone", base, d), base, "no starter yet: no offers")
	d.set_flag(Trumps.FLAG_STARTER, true)
	var zone := ""
	for id in ZoneIndex.get_index().zones:
		if str(id).contains("home") and Trumps.plays(str(id), "n1"):
			zone = str(id)
			break
	var offer := Trumps.hook(zone, "n1", base, d)
	assert_eq(offer.size(), 3)
	assert_eq(offer[1].text, "Fancy a game of Trumps?")
	d.set_flag(Trumps.day_key(zone, "n1"), DailyKey.stamp(d))
	assert_eq(Trumps.hook(zone, "n1", base, d), base)

func test_old_saves_load_without_trumps_and_new_ones_round_trip() -> void:
	var s := GameStateData.from_dict({"player_name": "Old"}, Trumps.dex())
	assert_eq(s.trumps, {})
	Trumps.give(s, "spikkin", 2)
	var back := GameStateData.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())), Trumps.dex())
	assert_eq(int(back.trumps.cards.spikkin), 2)

func test_no_em_dashes_in_player_text() -> void:
	for f in ["res://core/trumps.gd", "res://ui/trumps_screen.gd", "res://ui/cards_tab.gd", "res://story/trumps_run.gd"]:
		assert_false(FileAccess.get_file_as_string(f).contains("—"), f)
