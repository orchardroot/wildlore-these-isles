extends RefCounted
## The body of tools/dev/text_audit.gd (loaded at run time so the autoloads it leans on exist): opens each screen
## with DevMenu's sample journey, lets it settle, and prints TextFitAudit's problems.

## Every screen the Router opens, with the arguments that change what is on it (long lists, tabs, games under way).
const SCREENS := [
	"title", "name", "credits", "settings", "controls", "accessibility", "report", "save:save", "save:load",
	"pause", "party", "summary:0", "summary:0:genome", "pedia", "pedia:spikkin", "pedia:studbook", "pedia:casebook",
	"pedia:words", "pedia:rumours", "pedia:stamps", "bag", "bag:first", "bag:chapbook", "bag:tab:key", "bag:hold:0",
	"shop", "shop:macc_corner_shop:sell", "shop:boutique_edinburgh", "wardrobe", "wardrobe:mirror", "ark", "ark:sorted",
	"starter", "relearn:0", "map", "map:post", "map:route", "travel", "travel:all", "travel:fly", "travel:overseas",
	"quests", "quests:done", "quests:gazetteer", "quests:gazetteer:macclesfield", "quests:gazetteer:isles_work",
	"almanac", "almanac:pieces", "almanac:ledger:guilds", "almanac:ledger:deeds", "almanac:ledger:society", "papers",
	"stats", "stats:standing", "stats:trades", "stats:weekly", "jobs", "jobs:first", "craft", "craft:workbench",
	"postcard:album", "keepers", "curios", "economist", "invention", "lang", "biology", "selection", "pairing:pick",
	"pairing:cross", "pairing:predict", "quiz", "quiz:all:answered", "crossword", "crossword:filled",
	"bureau", "exchange:london", "crypto:london", "market:leeds_kirkgate", "society:manchester_society",
	"deed:allotment_york", "lease", "cards", "trumps:dev",
	"cage:dev", "fruit:dev", "blackjack:dev", "roulette:dev", "hilo:dev", "races:dev", "arcade:dev", "arcade:dev:claw",
	"arcade:dev:falls", "darts", "crabbing:dev", "bowls:dev", "skim:dev", "sheepdog:dev", "worms:dev", "ringing:dev",
	"walling:dev", "games:caber:dev", "games:tug:dev", "games:hurling:dev", "shanty:dev", "conkers:dev", "cheese:dev",
	"pancake:dev", "snorkel:dev", "coracle:dev", "roadbowl:dev", "poohsticks:dev", "gurning:dev", "wang:dev",
	"league:dev", "fete:cheese:dev", "fete:bog:dev", "fete:welly:dev", "curling:dev", "wrestling:dev", "science",
	"forecasting:dev",
]

const SETTLE := 0.7  # seconds for slide-ins and fades to finish

## args: screen names (or "all"); "--kind=a,b" keeps only those kinds; "--summary" prints counts only.
func run(tree: SceneTree, args: PackedStringArray) -> int:
	var want: Array = []
	var kinds: Array = []
	var summary := false
	for a in args:
		if a.begins_with("--kind="):
			kinds = Array(a.substr(7).split(","))
		elif a == "--summary":
			summary = true
		elif not a.begins_with("--"):
			want.append(a)
	if want.is_empty() or want == ["all"]:
		want = SCREENS
	var total := 0
	var game: Node = tree.root.get_node("Game")
	game.autosave_enabled = false  # never touch the player's saves
	game.save_dir = "user://saves_dev"
	for s in want:
		var probs: Array = await audit(tree, str(s))
		if not kinds.is_empty():
			probs = probs.filter(func(p): return p.kind in kinds)
		total += probs.size()
		if summary:
			var by := {}
			for p in probs:
				by[p.kind] = by.get(p.kind, 0) + 1
			print("%-34s %3d  %s" % [s, probs.size(), str(by) if not by.is_empty() else "ok"])
		else:
			for p in probs:
				print("%s  %s" % [s, TextFitAudit.line(p)])
	print("text_audit: %d problem(s) on %d screen(s)" % [total, want.size()])
	return total

## Opens one screen as the dev menu switch would, then lists its problems and closes it.
static func audit(tree: SceneTree, screen: String) -> Array:
	var router: Node = tree.root.get_node("Router")
	var game: Node = tree.root.get_node("Game")
	var root: Node
	if screen == "title":
		root = load("res://ui/title.tscn").instantiate()
		tree.root.add_child(root)
	else:
		DevMenu.boot(game, screen)
		root = router._menu_layer
	await tree.create_timer(SETTLE).timeout
	var probs := TextFitAudit.report(root, tree.root.get_visible_rect())
	if root == router._menu_layer:
		for m in root.get_children():
			if m.has_signal("closed"):
				m.closed.emit(null)
			m.queue_free()
	else:
		root.queue_free()
	router.busy = false
	await tree.process_frame
	return probs
