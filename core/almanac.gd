class_name Almanac
extends RefCounted
## The Almanac (4.0): one hub for the pages that have sprouted since 1.0. Pure logic: `pages` lists the pages this save
## has earned, in one steady order, each with a one-line blurb and the menu that opens it; `ledger` gives the rows of
## the pages that had no screen of their own (guilds, Deeds, the Building Society). Nothing is stored: a page simply
## appears once its system has something to show, so old saves need nothing.

## The menus behind each page, in tab order. "ledger:<kind>" opens the Almanac's own read-only ledger.
const ORDER := ["journal", "fieldbook", "gazetteer", "poets", "casebook", "studbook", "biology", "words", "invention", "rumours", "trades", "standing", "stats", "guilds", "deeds", "society", "landsky", "economist", "worth", "papers", "cards", "keepers"]
const NAMES := {"journal": "Quest log", "fieldbook": "Fieldbook", "gazetteer": "Gazetteer", "poets": "Poets' Corner", "casebook": "Casebook", "studbook": "Stud Book", "biology": "Biology", "words": "Words of the Isles", "invention": "Timeline of Invention", "rumours": "Rumours", "trades": "Trades", "standing": "Standing", "stats": "Tallies", "guilds": "Guilds", "deeds": "Deeds", "society": "Building Society", "landsky": "Land and Sky", "economist": "Economist's notebook", "worth": "Things worth knowing", "papers": "Papers", "cards": "Trumps cards", "keepers": "Keepers"}
const MENUS := {"journal": "quests", "fieldbook": "pedia", "gazetteer": "quests:gazetteer", "poets": "ledger:poets", "casebook": "pedia:casebook", "studbook": "pedia:studbook", "biology": "biology", "words": "pedia:words", "invention": "invention", "rumours": "pedia:rumours", "trades": "stats:trades", "standing": "stats:standing", "stats": "stats", "guilds": "ledger:guilds", "deeds": "ledger:deeds", "society": "ledger:society", "landsky": "ledger:landsky", "economist": "economist", "worth": "ledger:worth", "papers": "ledger:papers", "cards": "cards", "keepers": "keepers"}

static func sprouted(d: GameStateData, id: String) -> bool:
	match id:
		"poets":
			return PoetsCorner.count(d) > 0  # the first plaque on the arts read (4.5)
		"casebook":
			return Casebook.visible(d)
		"studbook":
			return StudBook.idea_count(d) > 0 or not Breeding.baskets(d).is_empty()
		"biology":
			return Biology.visible(d)
		"words":
			return words_met(d) > 0
		"invention":
			return Invention.found_count(d) > 0
		"rumours":
			return not d.seen.is_empty()
		"guilds":
			return not joined_guilds(d).is_empty()
		"deeds":
			return not Deeds.owned(d).is_empty()
		"society":
			return society_active(d)
		"keepers":
			return not KeeperIntel.known_ids(d).is_empty()  # wave 47: the Keepers briefing
		"worth":
			return LifeLessons.count(d) > 0
		"papers":
			return Letters.read_count(d) > 0
		"cards":
			return Trumps.owned_count(d) > 0
		"economist":
			return Economist.count(d) > 0
		"landsky":
			return LandSky.met_count(d) > 0  # the geology, weather and climate page (4.5)
	return true

## Local words met so far (the Words of the Isles tab, 4.1).
static func words_met(d: GameStateData) -> int:
	return d.flags.keys().filter(func(k): return str(k).begins_with(Langs.FLAG_PREFIX)).size()

static func joined_guilds(d: GameStateData) -> Array:
	return Guilds.IDS.filter(func(g): return Guilds.is_member(d, g))

static func society_active(d: GameStateData) -> bool:
	return BuildingSociety.has_loan(d) or BuildingSociety.mum_owed(d) > 0 or not BuildingSociety.recent(d).is_empty() \
		or Wallet.CURRENCIES.keys().any(func(c): return BuildingSociety.saved(d, c) > 0)

## The pages to show: [{id, name, blurb, menu}].
static func pages(d: GameStateData) -> Array:
	var out := []
	for id in ORDER:
		if sprouted(d, id):
			out.append({"id": id, "name": NAMES[id], "blurb": blurb(d, id), "menu": MENUS[id]})
	return out

static func blurb(d: GameStateData, id: String) -> String:
	match id:
		"papers":
			return Letters.blurb(d)
		"journal":
			return "%d under way, %d done" % [Quests.active(d).size(), Quests.done(d).size()]
		"fieldbook":
			return "%d seen, %d caught" % [d.seen.size(), d.caught.size()]
		"gazetteer":
			return "Plaques read: " + Gazetteer.stats_line(d)
		"poets":
			return "Plaques on the arts read: " + PoetsCorner.stats_line(d)
		"casebook":
			var open := Casebook.open_cases(d).filter(func(c): return not Casebook.solved(d, c)).size()
			return "%d case%s open" % [open, "" if open == 1 else "s"]
		"studbook":
			return "%d idea%s noted%s" % [StudBook.idea_count(d), "" if StudBook.idea_count(d) == 1 else "s", ""]
		"biology":
			var ch := (", %d of %d of Dr Keir's challenges" % [Biology.done_count(d), Biology.challenges().size()]) if Biology.lab_on(d) else ""
			return "%d of %d pages%s" % [Biology.open_count(d), Biology.pages().size(), ch]
		"words":
			var w := words_met(d)
			var lessons := TrainerStats.get_count(d, "lessons_taken")  # language lessons (4.5, LangLessons)
			return "%d local word%s met%s" % [w, "" if w == 1 else "s", (", %d lesson%s" % [lessons, "" if lessons == 1 else "s"]) if lessons > 0 else ""]
		"invention":
			var g := Invention.open_gadgets(d).size()
			return "%d of %d found, %d gadget%s" % [Invention.found_count(d), Invention.entries().size(), g, "" if g == 1 else "s"]
		"rumours":
			return "Local gossip and region stamps"
		"trades":
			var best := ""
			var lv := 0
			for t in Trades.IDS:
				if Trades.level(d, t) > lv:
					lv = Trades.level(d, t)
					best = Trades.title(d, t)
			return "Best: %s" % best if best != "" else "Six trades to take up"
		"standing":
			return "Six nations, and jobs in hand"
		"stats":
			return "Steps, wins, catches and daft things"
		"guilds":
			var n := joined_guilds(d).size()
			return "%d of %d joined" % [n, Guilds.IDS.size()]
		"deeds":
			var tills := 0
			for dd in Deeds.owned(d):
				tills += Deeds.till(d, str(dd.id))
			return "%d owned%s" % [Deeds.owned(d).size(), (", %s in the tills" % Wallet.fmt(tills)) if tills > 0 else ""]
		"society":
			if BuildingSociety.has_loan(d):
				return "A loan to clear"
			return "Savings and statements"
		"worth":
			return "%d of %d lessons picked up" % [LifeLessons.count(d), LifeLessons.all().size()]
		"keepers":
			return "%d of %d Keepers, and what bites them" % [KeeperIntel.known_ids(d).size(), KeeperIntel.ids().size()]
		"economist":
			return "%d of %d ideas met" % [Economist.count(d), Economist.total()]
		"landsky":
			return LandSky.blurb(d)
		"cards":
			return Trumps.blurb(d)
	return ""

## The rows [label, value] of a ledger page. Never empty: a page with nothing yet says so.
static func ledger(d: GameStateData, kind: String) -> Array:
	var out := []
	match kind:
		"poets":
			out = PoetsCorner.ledger(d)
		"guilds":
			for g in joined_guilds(d):
				var r := Guilds.rank(d, g)
				var src: Dictionary = Guilds.SOURCE[g]
				var v := Guilds.rank_title(d, g) if r > 0 else "Newly joined"
				out.append([Guilds.NAMES[g], "%s (%d %s)" % [v, Guilds.measure(d, g), src.unit]])
			if out.is_empty():
				out.append(["No guilds joined yet", "Each has a hall somewhere"])
		"deeds":
			for dd in Deeds.owned(d):
				var id := str(dd.id)
				out.append([str(dd.get("name", id)), "%s waiting (%s)" % [Wallet.fmt(Deeds.till(d, id), Deeds.cur_of(id)), Deeds.tier_name(d, id)]])
			if out.is_empty():
				out.append(["No Deeds yet", "Somewhere a place is for sale"])
		"society":
			for line in BuildingSociety.statement(d):
				var s := str(line)
				var i := s.find(": ")
				out.append([s.left(i), s.substr(i + 2)] if i > 0 else [s, ""])
			for line in BuildingSociety.recent(d).slice(0, 3):
				out.append(["", str(line)])
		"worth":
			out = LifeLessons.rows(d)
		"landsky":
			out = LandSky.rows(d)
	return out
