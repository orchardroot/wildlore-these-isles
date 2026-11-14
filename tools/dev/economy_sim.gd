extends SceneTree
## Prints the economy's shape: every way of earning, played together over a year of in-game days (see EconomySim).
## Usage: godot --headless --path . -s res://tools/dev/economy_sim.gd -- [runs]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var runs := int(args[0]) if args.size() > 0 else 20
	print("Per real day (every %d in-game days), sterling, at badges:" % EconomySim.PLAY_EVERY)
	for b in [0, 2, 4, 6, 8, 10]:
		var dl: Dictionary = EconomySim.dailies(b)
		var line := "  b%-2d" % b
		var tot := 0.0
		for k in dl:
			line += "  %s %.0f" % [k, dl[k]]
			tot += float(dl[k])
		print(line, "  = ", int(tot))
	print("Shop-stocked trade goods, a full load at the festival cap: ", EconomySim.shop_runs())
	print("Dishes a real day: sold where you stand %.0f, hauled to where they are wanted %.0f, hauled with news and orders %.0f" % [EconomySim.dish_pay(false), EconomySim.dish_pay(true), EconomySim.dish_pay(true, true)])
	print("Lumps (Gazetteer, Visitors' Book, quiz league): %.0f   leases: %s   recipe taps: %s" % [EconomySim.lump_total(), EconomySim.lease_average(), EconomySim.recipe_loops()])
	for strategy in EconomySim.STRATEGIES:
		var at := {30: 0.0, 78: 0.0, 90: 0.0, 180: 0.0, 360: 0.0}
		var firsts := {}
		var last := {}
		for i in runs:
			var r: Dictionary = EconomySim.run(strategy, 1 + i)
			for k in at:
				at[k] += float(r.at[k])
			for k in r.first:
				firsts[k] = firsts.get(k, 0) + int(r.first[k])
			last = r
		for k in firsts:
			firsts[k] = "%.0f" % (float(firsts[k]) / runs)
		print("%-10s cash d30 %7.0f  d78 %8.0f  d90 %8.0f  d180 %9.0f  d360 %9.0f  firsts(avg) %s" % [strategy, at[30] / runs, at[78] / runs, at[90] / runs, at[180] / runs, at[360] / runs, firsts])
		var parts := []
		for k in last.by_source:
			parts.append("%s %.0f" % [k, last.by_source[k]])
		print("           earned: ", ", ".join(parts))
		print("           spent: ", last.spent, "  owned: ", last.owned, " leases ", last.leases, " charms ", last.charms)
	quit(0)
