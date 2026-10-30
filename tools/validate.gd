extends SceneTree
## Headless data validation. Usage: godot --headless --path . -s res://tools/validate.gd

func _initialize() -> void:
	var dex := Dex.load_default()
	var errors := DataValidator.validate(TypeChart.load_default(), dex, MoveDB.load_default(), ItemDB.load_default())
	var zones := ZoneData.load_all()
	errors.append_array(StoryValidator.validate(dex, MoveDB.load_default(), ItemDB.load_default(), zones))
	var items_db := ItemDB.load_default()
	for zid in zones:
		var z: ZoneData = zones[zid]
		errors.append_array(z.validate(zones))
		errors.append_array(CreatureJobs.errors(z, items_db))  # creature job spots
		for kind in z.encounters:
			for enc in z.encounters[kind]:
				if not dex.has(str(enc.get("species", ""))):
					errors.append("zone %s: encounter species '%s' does not exist" % [zid, enc.get("species", "")])
		if zid != "testbed":
			for n in z.npcs:
				# every NPC must have real art, or it shows up in game as a "?" placeholder
				var sid := str(n.get("sprite", ""))
				var path := ("res://art/sprites/creatures/%s_icon.png" % sid.substr(9)) if sid.begins_with("creature:") else ("res://art/sprites/chars/%s.png" % sid)
				if not FileAccess.file_exists(path):
					errors.append("zone %s: npc '%s' sprite '%s' has no art" % [zid, n.get("id", ""), sid])
	errors.append_array(Quests.validate(Quests.all(), zones, Quests.all_settable()))  # data/quests: zones, flags set somewhere
	errors.append_array(Festivals.validate(zones, dex, Quests.all()))  # data/festivals.json: towns, scripts, quests, creatures
	errors.append_array(Gazetteer.validate(Gazetteer.all()))  # heritage plaques: unique ids, titles, no em-dashes
	errors.append_array(TheseIsles.validate(TheseIsles.themes(), Gazetteer.all(), TheseIsles.people(), Quests.all(), Quests.all_settable(), func(zid): return zones.has(zid)))  # data/these_isles.json
	errors.append_array(Invention.check(Quests.all_settable()))  # data/invention.json: the Timeline of Invention
	errors.append_array(Economist.check(Gazetteer.all()))  # data/economist.json: the notebook's ideas and history plaques
	errors.append_array(IslesWork.validate(IslesWork.all(), Quests.all_settable()))  # data/isles_work.json: How these isles work
	errors.append_array(Langs.check(func(zid): return zones.has(zid)))  # data/lang: places are zones, shape, no em-dashes
	errors.append_array(LangLessons.check(func(zid): return zones.get(zid), ZoneIndex.get_index()))  # data/lang lessons: shape, teachers on free tiles
	errors.append_array(MarketHall.check_files())  # data/market_halls.json: rooms, stall-holders, plaques
	errors.append_array(Knacks.check(dex))  # every line has a knack, legends their own
	errors.append_array(Forms.check(dex, MoveDB.load_default(), _regions(zones), TypeChart.load_default()))  # data/forms.json: regional forms
	errors.append_array(Breeding.check(dex))  # data/breeding.json: the conservation goals name real breeding lines
	errors.append_array(Genetics.check(dex))  # data/genes.json: loci match the code, every line has a kindred
	errors.append_array(Genetics.check_hybrids(dex, MoveDB.load_default()))  # data/hybrids.json: parents, types, caps, sprites
	errors.append_array(BiologyCheck.check())  # data/biology.json: the Biology page and Dr Keir's challenges
	errors.append_array(Crossbreeds.check(dex, MoveDB.load_default()))  # data/taxa.json and every generated crossbreed
	errors.append_array(Overseas.validate(func(zid): return zones.has(zid)))  # data/overseas: the departures board registry
	var regions := {}
	for zd in zones.values():
		regions[str(zd.region)] = true
	errors.append_array(Timezones.validate(func(r): return regions.has(r)))  # data/timezones.json: zones and regions line up
	errors.append_array(Leases.problems(zones, dex))  # data/leases: anchors, cul-de-sac zones, rewild blocks, letters
	errors.append_array(Looks.check(items_db))  # data/items/wear.json deltas the painter can draw; data/looks.json
	errors.append_array(Poi.check(zones, dex, items_db))  # data/poi: dens, camps, stones and caches on the routes
	errors.append_array(Wants.check(zones, items_db))  # w47 C: data/trades residents, wants, front-room shops
	errors.append_array(Errands.check(zones, items_db))  # w47 C: errand npcs and rewards
	errors.append_array(Coverage.check(dex, zones))
	errors.append_array(Coverage.reachability(zones, JsonUtil.read("res://data/ferries.json"), Coverage.script_warp_targets()))
	errors.append_array(Letters.errors(zones, items_db))  # papers on tables and their treasure trails
	for e in errors:
		printerr("DATA: " + e)
	print("validate: %d error(s)" % errors.size())
	quit(1 if errors.size() > 0 else 0)

## Every region id some zone carries.
func _regions(zones: Dictionary) -> Array:
	var out := []
	for zid in zones:
		var r := str(zones[zid].region)
		if r != "" and r not in out:
			out.append(r)
	return out
