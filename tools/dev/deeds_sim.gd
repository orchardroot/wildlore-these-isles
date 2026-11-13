extends SceneTree
## Prints the Deeds' payback table: net sterling per in-game day and days to pay back, for each Deed and tier, at the
## cheap early price (badge 3) and the late price (badge 9), managed (see DeedsSim). Wave 55 adds, below the tiers, each
## upgrade's price and payback on top of the top tier, what the monthly matters are worth a month, and the town projects'
## costs by par, so the same script is the before and after.
## Usage: godot --headless --path . -s res://tools/dev/deeds_sim.gd

func _initialize() -> void:
	for b in [3, 9]:
		print("-- badges %d (day %d)" % [b, b * EconomySim.DAYS_PER_BADGE])
		var d: GameStateData = EconomySim._state(b * EconomySim.DAYS_PER_BADGE)
		var managed: bool = b >= EconomySim.BADGES_FOR_MANAGER
		for deed in Deeds.all():
			var id := str(deed.id)
			var line := "  %-20s" % id
			for t in deed.tiers.size():
				line += "  t%d net %6.0f pb %5.1f" % [t, DeedsSim.net_per_day(d, id, t, managed), DeedsSim.payback_days(d, id, t, managed)]
			print(line)
		if DeedChoices.upgrades("chippy_whitby").is_empty():
			continue   # the base branch has none
		print("   upgrades on the top tier (price, extra net a day, days to pay back):")
		for deed in Deeds.all():
			var id := str(deed.id)
			var top: int = (deed.tiers as Array).size() - 1
			var line := "  %-20s" % id
			for u in DeedChoices.upgrades(id):
				var gain := DeedsSim.net_per_day(d, id, top, managed, [str(u.id)]) - DeedsSim.net_per_day(d, id, top, managed)
				line += "  %s %d (+%.0f, pb %.0f)" % [str(u.id), DeedChoices.cost(d, id, u), gain, DeedsSim.upgrade_payback(d, id, top, managed, str(u.id))]
			print(line)
		var asks := ""
		for deed in Deeds.all():
			var id := str(deed.id)
			var day := float(Deeds.daily_estimate(d, id))
			asks += " %s %.2f/%.2f" % [id.split("_")[1], DeedChoices.ask_net_per_day(d, id, true) * 30.0 / day, DeedChoices.ask_net_per_day(d, id, false) * 30.0 / day]
		print("   a month's matters in quiet days of takings, answered well / ignored:" + asks)
	if TownProjects.all().is_empty():
		quit(0)
		return
	print("-- town projects, cost by progress (sterling): par 28 / 60 / 97")
	var total := [0, 0, 0]
	for p in TownProjects.all():
		var row := "  %-22s min %d Stones" % [str(p.id), int(p.badges)]
		for i in 3:
			var c := 0
			for s in (p.stages as Array).size():
				c += TownProjects.cost_at(p, s, clampf((40.0 + [28.0, 60.0, 97.0][i]) / 100.0, TownProjects.FACTOR_LO, TownProjects.FACTOR_HI))
			total[i] += c
			row += "  %7d" % c
		print(row)
	print("  all fifteen: %d / %d / %d" % [total[0], total[1], total[2]])
	quit(0)
