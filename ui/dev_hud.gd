class_name DevHud
extends RefCounted
## Dev switch `--hud=all` (with --boot and --shot): every overworld HUD box up at once, each carrying the longest
## words it can get in play, held still: the zone card, the route chip, the place chip, the Saved toast and the F9
## report toast. `--hud=news` is the same with a parish toast in the card's place (in play they take turns: news
## waits for the card). `--hud=toast` and `--hud=card` hold just that one; `--hud=toast:<n>` holds the nth of
## `toast_samples()`, one of each kind of parish news with the longest words that kind gets. With the shot, `report` writes <shot>.hud.txt:
## HUD boxes that overlap each other or leave the screen (TextCheck, `--text-check`, covers the words inside them).
## Some boxes take turns in play (a toast waits for the card), so `all` is a worst case, not a frame you'll see.

const LONG_ZONE := "Camp: Gypsy Cove and Volunteer Point"
const LONG_TOAST := "Someone in England has noticed you. Help out and they'll count you as one of their own."

static func wanted() -> String:
	for a in DevArgs.user_args():
		if a.begins_with("--hud="):
			return a.substr(6)
	return ""

## The longest town name a route chip can show, and the longest building name a place chip can.
static func longest_town() -> String:
	var best := ""
	var idx := ZoneIndex.get_index()
	for id in idx.zones:
		if str(idx.zones[id].kind) == "town":
			var n := Travel.town_name(str(id))
			if n.length() > best.length():
				best = n
	return best

static func longest_place() -> String:
	var best := ""
	for f in DirAccess.get_files_at("res://data/zones"):
		if not f.ends_with(".json"):
			continue
		var d = JSON.parse_string(FileAccess.get_file_as_string("res://data/zones/" + f))
		if not d is Dictionary:
			continue
		for pr in d.get("props", []):
			if pr is Dictionary and pr.get("type") == "building" and pr.has("label") and pr.get("show_label", true):
				if str(pr.label).length() > best.length():
					best = str(pr.label)
	return best

static func _longest(list: Array, key: String) -> String:
	var best := ""
	for e in list:
		if e is Dictionary and str(e.get(key, "")).length() > best.length():
			best = str(e.get(key, ""))
	return best

## [header, text] for each kind of parish news (core/parish.gd, core/quest_news.gd), at its longest.
static func toast_samples() -> Array:
	var inv := {}
	for e in Invention.entries():
		if str(e.title).length() > str(inv.get("title", "")).length():
			inv = e
	var gm: Dictionary = Gazetteer.MILESTONES.back()
	var pm: Dictionary = PoetsCorner.MILESTONES.back()
	return [
		["Standing", LONG_TOAST],
		["Standing", "The Channel Islands now counts you as one of their own"],
		["Job ready", "%s. Hand it in at any noticeboard in %s." % [_longest(Jobs.all(), "title"), Standing.name_of("northern_ireland")]],
		["Job done", "%s: £4,500, 3 Kendal Mint Cakes, 2 Flasks of Tea, a recipe for Bara Brith and 5 standing in Northern Ireland" % _longest(Jobs.all(), "title")],
		["Euros", "Ireland uses the euro. A kind clerk at the Sanctuary changed £12,345 into €14,321 for you, no commission. Bureaux de change will do the rest."],
		["Gazetteer", "%s added to your Gazetteer" % _longest(Gazetteer.all(), "title")],
		["Gazetteer milestone", "%s! %s" % [str(gm.title), Gazetteer.reward_text(gm, Game.items)]],
		["Poets' Corner", "%s! %s" % [str(pm.title), Gazetteer.reward_text(pm, Game.items)]],
		["Quest complete", _longest(Quests.all(), "title")],
		["Timeline of Invention", "%s (%s) added to your Timeline" % [str(inv.get("title", "")), Invention.year_text(inv)]],
		["New gadget", "%s: find it in the Almanac's Timeline" % _longest(Invention.eras().map(func(e): return e.get("gadget", {})), "name")],
	]

const LONG_WHO := "Professor Bartholomew Fothergill-Montgomery"
const LONG_LINE := "Right, listen carefully, because I'll only say this the once and then I'll be off to put the kettle on. The silk mills along the Bollin ran on water first, then steam, and every bobbin you see in the museum went through a dozen pairs of hands before it ever saw a loom. If you want to understand this town, start with the river, then the chapels, then the pubs, in roughly that order."
const CHOICE_LINE := "Which way are you headed? The road over the moor is quicker, but the canal path is kinder on the legs and there's a tea room at the bottom lock that does a very respectable scone."

## Dev `--hud=talk:<case>`: the dialogue box at its worst. long (a line that needs pages), name (a very long
## speaker), choice (a choice with a speaker), many (more choices than fit above the box). Waits for input, so
## take the shot while it shows.
static func talk(ow: Node, what: String) -> void:
	var box: DialogueBox = load("res://ui/dialogue_box.tscn").instantiate()
	ow.add_child(box)
	match what:
		"long":
			box.show_text(LONG_LINE, "Garside")
		"name":
			box.show_text("Good afternoon. You'll be wanting the museum, I expect. Everyone does.", LONG_WHO)
		"choice":
			box.show_choice(CHOICE_LINE, ["Over the moor", "Along the canal", "Not today"], "Keeper Maud")
		"many":
			var opts := []
			for t in ["Macclesfield", "Buxton", "Liverpool", "Chester", "Llanberis", "Cardiff", "Glastonbury", "Holyhead",
					"Dublin", "Galway", "Belfast", "Inverness", "York", "Stay here"]:
				opts.append(t)
			box.show_choice(CHOICE_LINE, opts, "Station master")

## Puts them all up (after the boot zone has loaded).
static func show(game: Node, what: String) -> void:
	var ow: Node = Router.overworld
	if ow == null:
		return
	if what.begins_with("talk:"):
		await game.get_tree().create_timer(0.6).timeout
		talk(ow, what.substr(5))
		return
	await game.get_tree().create_timer(1.2).timeout  # the route chip and place chip settle first
	var card := game.get_tree().get_first_node_in_group(ZoneCard.GROUP) as ZoneCard
	if what in ["all", "card"] and card:
		card.show_card(LONG_ZONE, "Falkland Islands", "Campamento: Caleta Gitana")
		card._tween.kill()
		card._panel.modulate.a = 1.0
	if what in ["news", "toast"] or what.begins_with("toast:"):
		while card and card.showing():  # as in play: news waits for the town's name card
			await game.get_tree().process_frame
		var m: Array = ["Standing", LONG_TOAST]
		if what.begins_with("toast:"):
			var all := toast_samples()
			m = all[clampi(int(what.substr(6)), 0, all.size() - 1)]
		var t := ParishToast.new()
		ow.add_child(t)
		t._head.text = m[0]
		t._body.text = m[1]
		t.lay_out()
		t._panel.position.y = 22.0
		t._panel.modulate.a = 1.0
		t._up = true
	if what not in ["all", "news"]:
		return
	for c in ow.get_children():
		if c is RouteChip:
			c._text.text = "To %s  ·  12 to go" % longest_town()
			c._arrow.text = "↖"
			c._panel.visible = true
		elif c is PlaceIndicator:
			c.show_place({"name": longest_place(), "kind": "Museum"})
	var saved := SaveToast.new()
	game.add_child(saved)
	saved.flash()
	var rep := SaveToast.new()
	game.add_child(rep)
	rep.layer = 90
	rep.flash("Reported. Keep playing.")
	await game.get_tree().create_timer(0.3).timeout
	for s in [saved, rep]:
		s._tween.kill()
		s._panel.modulate.a = 1.0

## HUD boxes (panels on a CanvasLayer, not inside another panel) that overlap or leave the screen, as lines.
static func report(root: Node, screen: Rect2) -> Array:
	var boxes := []
	_collect(root, 0, 1.0, boxes)
	var out := []
	for i in boxes.size():
		var a: Dictionary = boxes[i]
		if not screen.encloses(a.rect):
			out.append("%s: off the screen (%d,%d %dx%d)" % [a.name, a.rect.position.x, a.rect.position.y, a.rect.size.x, a.rect.size.y])
		for j in range(i + 1, boxes.size()):
			var b: Dictionary = boxes[j]
			var hit: Rect2 = a.rect.intersection(b.rect)
			if hit.size.x > 1.0 and hit.size.y > 8.0:  # a few px is a seam by design (the speaker's tab sits on the box)
				out.append("%s overlaps %s (%dx%d px)" % [a.name, b.name, hit.size.x, hit.size.y])
	return out

static func _collect(n: Node, layer: int, alpha: float, out: Array) -> void:
	if n is CanvasLayer:
		if not (n as CanvasLayer).visible:
			return
		layer = (n as CanvasLayer).layer
	if n is CanvasItem:
		if not (n as CanvasItem).is_visible_in_tree():
			return
		alpha *= (n as CanvasItem).modulate.a
	if n is PanelContainer and layer > 1 and alpha > 0.05:
		var c := n as Control
		out.append({"name": "%s (layer %d)" % [str(c.get_path()).replace("/root/", "").left(60), layer], "rect": c.get_global_rect()})
		return  # what is inside a panel is the panel's business
	for ch in n.get_children():
		_collect(ch, layer, alpha, out)
