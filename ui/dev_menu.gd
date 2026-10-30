class_name DevMenu
extends RefCounted
## Dev switch `--menu=<name>[:arg]`: boots a new game with a sample party and bag, then opens that menu.
## Used for screenshots (see docs/screens/t9-*.png). Called from Game._dev_boot.

## Real wear items (data/items/wear.json) a dev Wardrobe or boutique screenshot starts with: bought, the first five worn (cap, jumper, kilt, jacket, wellies).
const DEMO_WEAR := ["flat_cap_yorkshire", "aran_jumper", "black_watch_kilt", "waxed_jacket_green", "wellies_red", "paisley_scarf", "round_glasses"]

static func arg(cmdline: PackedStringArray) -> String:
	for a in cmdline:
		if a.begins_with("--menu="):
			return a.substr(7)
	return ""

## The widest things a save can hold, for checking that every menu still fits (`--stress`).
static func stress(d: GameStateData) -> void:
	d.player_name = "Wilhelmina M"
	d.money = 9999999
	d.play_seconds = 359999.0
	for c in d.party + d.ark:
		c.nickname = "MWMWMWMWMWMW"

static func boot(game: Node, menu: String) -> void:
	game.new_game()
	if menu == "new_game":  # `--menu=new_game`: a fresh journey from the cold open on, as after the name entry
		await game.get_tree().process_frame
		ColdOpen.then_morning(game.get_node("/root/Router"), game.data)
		return
	var d: GameStateData = game.data
	for a in DevArgs.user_args():
		if a.begins_with("--flag="):  # dev: story flags set before the menu opens (a filled Almanac page)
			for f in a.substr(7).split(",", false):
				d.set_flag(f, true)
	var mk := func(id: String, lvl: int) -> Creature:
		return Creature.create(game.dex.get_species(id), lvl, game.rng, game.moves)
	var a: Creature = mk.call("spikkin", 12)
	a.take_damage(a.max_hp() / 3)
	var b: Creature = mk.call("kindlet", 10)
	var c: Creature = mk.call("holtling", 9)
	c.take_damage(c.max_hp() * 4 / 5)
	var e: Creature = mk.call("binfox", 8)
	e.hp = 0
	e.status = "stung"
	var f: Creature = mk.call("hootlet", 7)
	f.status = "asleep"
	a.friendship = 230  # four hearts and a charm, for the summary and team screens
	a.held = "hag_stone"
	a.variant = str(DevArgs.parse(DevArgs.user_args()).coat)  # --coat=<variant>: the summary shows an uncommon coat
	if a.variant != "":  # ...and the Fieldbook has it, plus a couple more seen
		for v in Coats.ALL.slice(0, 3):
			d.set_flag(Coats.flag_key("spikkin", v), "seen")
		d.set_flag(Coats.flag_key("spikkin", a.variant), "caught")
	b.friendship = 255
	c.held = "oak_acorn"
	d.party = [a, b, c, e, f]
	d.ark = [mk.call("croakle", 6), mk.call("pipkin", 4), mk.call("dipling", 9)]
	if menu == "papers":  # `--menu=papers`: the Almanac's Papers page with 8 read, 2 of them trails still open
		var plain := Letters.all().filter(func(q): return not Letters.has_trail(q)).slice(0, 6)
		var trails := Letters.all().filter(func(q): return Letters.has_trail(q)).slice(0, 2)
		for q in plain + trails:
			d.set_flag(Letters.read_flag(str(q.id)), true)
		menu = "almanac:ledger:papers"
	if menu == "cards" or menu.begins_with("trumps"):  # `--menu=cards`: an album part filled (Cheshire done, the Peak half); `--menu=trumps:dev`: a game under way
		Trumps.use_dex(game.dex)
		Trumps.give_starter(d)
		var tz := ZoneIndex.get_index()
		for s in Trumps.region_set("cheshire", tz):
			Trumps.give(d, str(s))
		for k in Trumps.region_set("peak", tz).size() / 2:
			Trumps.give(d, str(Trumps.region_set("peak", tz)[k * 2]))
		for k in 9:
			Trumps.give(d, str(Trumps.region_set("south_wales", tz)[k % maxi(1, Trumps.region_set("south_wales", tz).size())]))
		d.trumps["wins"] = 7
		d.trumps["losses"] = 3
	if menu.begins_with("lang") or menu in ["pedia:words", "pause:words"]:  # two Welsh lessons learnt, in Cardiff, a day on
		d.zone_id = "cardiff"
		for l in ["cy_01", "cy_02"]:
			LangLessons.learn(d, l)
		d.day_count = 2
	if menu.begins_with("ark"):  # a fuller Ark, so sorting shows
		for sp in ["bramblehog", "emberdrey", "redbreast", "snowhare", "gritling", "wispet", "cooplet", "raidtail", "bran"]:
			d.ark.append(mk.call(sp, 3 + d.ark.size() * 4 % 23))
	if menu.begins_with("pairing") or menu in ["pedia:studbook", "pause:basket"]:  # a fond pair of one line, a stranger and a basket under way
		var cross := menu == "pairing:cross"  # `--menu=pairing:cross`: a goat and a sheep, a long-shot crossbreed (core/crossbreeds.gd)
		var m: Creature = mk.call("kidgruff" if cross else "spikkin", 12)
		var f2: Creature = mk.call("herdlet" if cross else "spikkin", 11)
		m.sex = "m"
		m.uid = 101
		f2.sex = "f"
		f2.uid = 102
		m.friendship = 200
		f2.friendship = 200
		m.genome = Genetics.derive(m).genome
		f2.genome = Genetics.derive(f2).genome
		d.party = [m, f2, a, b]
		d.set_flag("breed_basket_0", {"sire_uid": 101, "dam_uid": 102, "genome": {}, "species": "spikkin", "steps_due": 1240, "started_day": 0})
		d.set_flag("book_ideas", {"dominance": true, "breed": true})
		d.set_flag("book_loci", {"mark": true})
	if menu.begins_with("biology") or menu == "pairing:predict":  # Dr Keir's lab under way: some pages, two challenges met, a record
		for fl in ["breed_met_keir", "bio_lab_on", "bio_ch_marks", "bio_ch_daughter", "bio_dolly", "bio_since_dolly", "bio_sim_watched"]:
			d.set_flag(fl, true)
		d.set_flag("book_ideas", {"dominance": true, "breed": true, "vigour": true})
		d.set_flag("bio_record", {"1 in 2": [5, 3], "1 in 4": [4, 1], "None to 1 in 4": [2, 0]})
		d.set_flag("bio_preds", 11)
		d.set_flag("bio_right", 8)
	for sp in ["spikkin", "kindlet", "holtling", "binfox", "hootlet", "pipkin", "scuttlet", "croakle"]:
		d.mark_caught(sp)
	for sp in ["dipling", "wispet", "snowhare"]:
		d.mark_seen(sp)
	d.bag = {"cup_of_tea": 5, "flask_of_tea": 2, "smelling_salts": 3, "bakewell_tart": 1, "kendal_mint_cake": 1,
		"wicker_snare": 8, "iron_snare": 2, "lavender_sachet": 3, "map": 1, "fieldbook": 1,
		"rowan_sprig": 1, "leek": 1}
	d.money = 1840
	if menu.split(":")[0] in ["cage", "fruit", "blackjack", "roulette", "hilo", "races"]:  # the Palace and the bookies
		d.set_flag(Punt.CHIPS_FLAG, 640)
	if menu.begins_with("stats"):
		d.stats.merge({"steps": 48213, "wins_wild": 187, "wins_trainer": 41, "caught": 52, "train_trips": 9, "rail_miles": 1180,
			"ferry_trips": 3, "flights": 4, "money_earned": 96450, "teas": 63, "rained_on": 28, "started": "2026-10-03"}, true)
	var first_day := menu == "jobs:first"  # `--menu=jobs:first`: Macclesfield's board before the first Stone
	d.badges = [] if first_day else ["a", "b"]
	if first_day:
		menu = "jobs:macclesfield"
	d.play_seconds = 100.0 if "--tip" in DevArgs.user_args() else 4980.0  # `--tip` lets the first-time introductions show
	for t in ["macclesfield", "buxton"]:
		d.set_flag("visited_" + t)
		d.set_flag("station_" + t)
	d.set_flag("last_town", "buxton")
	TodaysWalk.today(d, game.items)  # the pause menu's Today's Walk line
	d.bag["rail_pass"] = 1
	if menu.begins_with("pedia:") and (Dex.in_appendix(menu.substr(6)) or Dex.is_hybrid(menu.substr(6)) or Crossbreeds.is_id(menu.substr(6)) or game.dex.has(menu.substr(6))):  # `--menu=pedia:flyling` (any species or a hybrid): that entry, caught
		d.mark_caught(menu.substr(6))
	if menu == "bag:first":  # `--menu=bag:first`: a first-hour bag (tea, snares, the map and the Fieldbook)
		d.bag = {"cup_of_tea": 3, "wicker_snare": 5, "map": 1, "fieldbook": 1}
	if menu == "map:post":  # `--menu=map:post`: the whole map visited, Champion, every Stone
		for t in Travel.world_map().get("towns", {}):
			d.set_flag("visited_" + t)
			d.set_flag("station_" + t)
		for k in ["brook", "urban", "stone", "storm", "fae", "kin", "tide", "iron", "frost", "spirit"]:
			d.set_flag("badge_" + k)
		d.set_flag("champion")
		d.set_flag("game_complete")
		d.set_flag("last_town", "york")
	if menu == "map:route":  # `--menu=map:route`: the whole map visited and a route from Macclesfield stored
		for t in Travel.world_map().get("towns", {}):
			d.set_flag("visited_" + t)
			d.set_flag("station_" + t)
		d.zone_id = "macclesfield"
		d.set_flag("last_town", "macclesfield")
		d.set_flag("route_to", "york")
	if menu.begins_with("craft") or menu.contains("material"):  # a forager's bag and Mum's recipes, plus a few more
		d.bag.merge({"blackberries": 6, "hazelnuts": 3, "nettles": 5, "sloes": 2, "elderflower": 1, "wild_garlic": 2,
			"sheep_wool": 1, "rowan_berry": 1, "heather_honey": 1, "sea_glass": 1}, true)
		for id in Crafting.taught_by("mum") + ["parkin", "bara_brith", "pasty", "miners_lamp"]:
			Crafting.learn(d, id)
	if menu == "pedia:stamps":  # the Fieldbook's region stamps: Cheshire and the Peak finished
		var idx := ZoneIndex.get_index()
		for r in ["cheshire", "peak"]:
			for sp in idx.region_species.get(r, []):
				d.mark_caught(sp)
	if menu.begins_with("map") or menu.begins_with("stats"):  # the Visitor's Book: most of Buxton's rooms, all of Macc's
		var rooms: Dictionary = ZoneIndex.get_index().town_rooms
		for r in rooms.get("macclesfield", []) + rooms.get("buxton", []).slice(0, 7):
			d.set_flag(VisitorsBook.seen_flag(str(r)))
		d.set_flag(VisitorsBook.BOARD_PREFIX + "macclesfield")
	if (menu.begins_with("jobs") and not first_day) or menu.begins_with("stats") or menu == "pause":  # parish standing and jobs in hand
		Standing.add(d, "england", 34)
		Standing.add(d, "wales", 12)
		Standing.add(d, "mann", 3)
		for id in ["eng_jam", "macc_forest_beat"]:
			Jobs.accept(d, id, "macclesfield")
		Jobs.note_win(d, "macc_forest")
		d.bag["blackberries"] = 4
	if menu.begins_with("quests") or menu == "pause" or menu.begins_with("map:quest") or menu.begins_with("stats"):
		# the Journal: the silk errand under way (card delivered) and a good few plaques read, all of Macclesfield's
		d.set_flag("q_macclesfield_silk_started")
		d.set_flag("q_macclesfield_silk_1")
		d.set_flag("last_town", "macclesfield")
		var n := 0
		for p in Gazetteer.all():
			if str(p.town) == "macclesfield" or n % 4 == 0:
				d.set_flag(Gazetteer.flag_key(str(p.id)))
			n += 1
		for m in Gazetteer.MILESTONES.slice(0, 3):
			d.set_flag(str(m.flag))
		if ":isles_work" in menu:  # `--menu=quests:gazetteer:isles_work[:<topic>]`: How these isles work, two in three topics learnt (and that one)
			var k := 0
			for t in IslesWork.all():
				if k % 3 != 2 or menu.ends_with(":" + str(t.id)):
					d.set_flag(IslesWork.flag_key(str(t.id)))
				k += 1
	if "--stress" in DevArgs.user_args():  # dev: worst-case widths, a 12-letter name and nicknames and a full purse
		stress(d)
	if menu.begins_with("relearn"):
		a.level = 20  # past a couple of its moves, so the relearner has something to offer
	if menu.begins_with("postcard"):  # `--menu=postcard:album`: every card in the album (or postcard:<id>[:back])
		for pc in Postcards.cards():
			d.set_flag(Postcards.flag_key(str(pc.id)), "2026-10-%02d" % (2 + Postcards.card_index(str(pc.id))))
	if menu.begins_with("shop") and not menu.contains(":"):
		menu = "shop:macc_corner_shop"
	if menu.begins_with("shop:looks_demo"):  # kept as an alias: the Edinburgh boutique, mid-wardrobe
		menu = "shop:boutique_edinburgh"
	if menu.begins_with("wardrobe") or menu.begins_with("shop:boutique"):  # `--menu=wardrobe[:mirror]`, `--menu=shop:boutique_<city>`: a few bought clothes, the cap on
		for id in DEMO_WEAR:
			d.bag[id] = 1
		for id in DEMO_WEAR.slice(0, 5):
			Looks.wear(d, id, game.items)
	if menu.begins_with("society"):  # `--menu=society:<zone>[:loan]`: a few Stones in, Mum's sub paid out; `:loan` adds a loan, savings and a missed month
		d.day_count = 120
		d.money = 1840
		for i in 3:
			d.badges.append("b%d" % i)
		BuildingSociety.settle(d)
		BuildingSociety.collect_letters(d)
		if menu.ends_with(":loan"):
			BuildingSociety.borrow(d, "manchester_society", 2000, 12)
			BuildingSociety.deposit(d, "gbp", 600)
			d.day_count += BuildingSociety.MONTH
			d.money = 0
			BuildingSociety.settle(d)
			d.money = 1840
			menu = menu.trim_suffix(":loan")
	if menu.begins_with("lease"):  # `--menu=lease[:<id>][:owned|:trust|:ramblers]`: post-game, rich, optionally a guild or a lease already won
		d.set_flag("game_complete", true)
		d.day_count = 400
		d.money = 400000
		d.euros = 400000
		for i in 4:
			d.badges.append("b%d" % i)
		var parts := menu.split(":")
		if "trust" in parts:
			Guilds.join(d, "trust")
		if "ramblers" in parts:
			Guilds.join(d, "ramblers")
		if "owned" in parts:
			var sit := Leases.auction_open(d, parts[1])
			while not bool(sit.over):
				Leases.bid(sit, d)
		menu = "lease" + ((":" + parts[1]) if parts.size() > 1 and parts[1] not in ["owned", "trust", "ramblers"] else "")
	if menu.begins_with("deed"):  # `--menu=deed:<id>[:owned]`: a few Stones in with cash and stock; `:owned` buys it, stocks it and lets a fortnight pass
		d.day_count = 120
		d.money = 20000
		for i in 4:
			d.badges.append("b%d" % i)
		d.set_flag("badge_stone", true)
		d.bag["haddock"] = 8
		d.bag["whiting"] = 8
		d.bag["potatoes"] = 40
		if menu.ends_with(":owned"):
			var did := menu.split(":")[1]
			Deeds.buy(d, did)
			for inp in Deeds.get_deed(did).inputs:
				d.bag[str(inp.item)] = 40
				Deeds.supply(d, did, str(inp.item), 40)
			d.day_count += 14
			Deeds.tick(d, d.day_count)
			menu = menu.trim_suffix(":owned")
	if menu.begins_with("vs:"):  # `--menu=vs:keeper_morwen[:bare]`: that VS splash held at the end (ours has only a Kin starter, so it warns)
		if menu.ends_with(":bare"):  # a lone lead that knows only Scrap
			d.party = d.party.slice(0, 1)
			d.party[0].moves = [{"id": "scrap", "pp": 35, "max_pp": 35}]
		BattleIntro.dev_show(game.get_node("/root/Router"), null, menu.get_slice(":", 0) + ":" + menu.get_slice(":", 1), 1.0)
		return
	if menu == "keepers":  # `--menu=keepers`: Maud beaten, four towns visited, a few lines of gossip heard
		d.set_flag("trainer_keeper_maud", true)
		for t in ["buxton", "liverpool", "llanberis", "glastonbury"]:
			d.set_flag("visited_" + t)
		for kg in ["kg_maud_0", "kg_maud_2", "kg_morwen_1", "kg_ray_0", "kg_ray_1"]:
			d.set_flag(kg, true)
	if menu == "economist":  # `--menu=economist`: most of the notebook met, a Deed and a lease among them
		d.money = 5000
		for i in Economist.ideas():
			if str(i.id) not in ["south_sea_1720", "ot_money"]:
				Economist.note(d, str(i.id), {"text": "the Stag Inn", "gbp": 8000, "over": 23} if str(i.id) in ["opportunity_cost", "winners_curse"] else true)
				if str(i.get("plaque", "")) != "":
					d.set_flag(Gazetteer.flag_key(str(i.plaque)), true)
	if menu.begins_with("almanac"):  # `--menu=almanac[:ledger:guilds|deeds|society]`: every page sprouted (a guild, a Deed with a till, a loan, a basket)
		d.day_count = 120
		d.money = 20000
		for i in 4:
			d.badges.append("b%d" % i)
		d.set_flag("badge_stone", true)
		d.seen["holtling"] = true
		d.set_flag("book_ideas", {"a": true, "b": true})
		Guilds.join(d, "ramblers")
		Guilds.join(d, "naturalists")
		var did := str(Deeds.all()[0].id)
		Deeds.buy(d, did)
		d.day_count += 14
		d.set_flag("deed_" + did, Deeds.state(d, did).merged({"owned": true, "till": 340}, true))
		BuildingSociety.settle(d)
		BuildingSociety.borrow(d, "manchester_society", 2000, 12)
		BuildingSociety.deposit(d, "gbp", 600)
	if menu.begins_with("invention") or menu.begins_with("almanac"):  # `--menu=invention[:gadget:<id>]`: a Timeline part filled, three gadgets open
		for inv_flag in ["plaque_shropshire_iron_bridge", "plaque_chat_moss_rainhill", "plaque_penzance_davy", "plaque_london_faraday",
				"plaque_london_telegraph", "plaque_kerry_valentia", "plaque_penzance_poldhu", "plaque_manchester_baby",
				"plaque_bletchley_bombe", "invent_seen_colossus", "plaque_london_lovelace", "plaque_dover_chain_home"]:
			d.set_flag(inv_flag, true)
		d.seen["holtling"] = true
	if menu.begins_with("almanac") or menu.begins_with("quests:gazetteer"):  # a dozen plaques on the arts read: Poets' Corner (4.5)
		for p in PoetsCorner.all().slice(0, 12):
			d.set_flag(Gazetteer.flag_key(str(p.id)), true)
	if menu.begins_with("bureau") or menu.begins_with("exchange") or menu.begins_with("crypto") or menu == "pause:euros":
		# a few weeks into a journey with both purses, some shares, a Doggerel punt and a Stone or two
		d.day_count = 46
		d.money = 6840
		d.euros = 640
		d.set_flag("badge_stone", true)
		Markets.sync(d)
		for deal in [["PNM", 120], ["KTL", 150], ["VNI", 20], ["GVC", 40]]:
			Markets.buy(d, deal[0], deal[1])
		Markets.coin_buy(d, mini(150, Markets.coin_max_buy(d)))
		d.day_count = 52
		if menu == "pause:euros":
			menu = "pause"
	if menu == "pairing:cross":
		menu = "pairing:pick"
	await game.get_tree().process_frame
	var cur := game.get_tree().current_scene
	if cur:
		cur.visible = false  # hide the title so screenshots show the menu alone
	var router := game.get_node("/root/Router")
	var parts := menu.split(":", true, 1)
	if parts[0] in ["summary", "pedia_popup"]:
		var scene: Node = load("res://ui/%s.tscn" % ("summary_screen" if parts[0] == "summary" else "pedia_popup")).instantiate()
		router._menu_layer.add_child(scene)
		scene.setup(parts[1] if parts.size() > 1 else "")
	else:
		router.open_menu(menu)
