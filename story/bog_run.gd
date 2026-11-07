class_name BogRun
extends RefCounted
## The `snorkel` and `coracle` story commands (wave 48, session G3).
##   {"do": "snorkel", "venue": "waen_rhydd", "who": "Bog Marshal"}   two lengths of a peat trench against the local
##   {"do": "coracle", "venue": "ironbridge", "who": "Coracle Racer"}  a buoy course down the river against the local
## Rules, locals, venues and prizes live in Snorkel (data/snorkel.json) and Coracle (data/coracle.json); the screens
## are ui/snorkel_screen.gd and ui/coracle_screen.gd.

var cmd: Commands
var host

func _init(c: Commands) -> void:
	cmd = c
	host = c.host

func snorkel(c: Dictionary) -> void:
	var v := Snorkel.venue(str(c.get("venue", "")))
	if v.is_empty():
		push_warning("BogRun: no snorkel venue '%s'" % str(c.get("venue", "")))
		return
	await _game(c, v, Snorkel.cfg(), "snorkel", "Two lengths against %s. Fastest wins.", func(data, id, t, won): return Snorkel.finish(data, id, t, won),
		"That is your best swim yet: %s.", func(t): return Snorkel.fmt(t), "Not this time. Keep the kicks alternate and on the beat, and blow the snorkel before it clogs.")

func coracle(c: Dictionary) -> void:
	var v := Coracle.venue(str(c.get("venue", "")))
	if v.is_empty():
		push_warning("BogRun: no coracle venue '%s'" % str(c.get("venue", "")))
		return
	await _game(c, v, Coracle.cfg(), "coracle", "Eight gates against %s. Fastest wins, penalties included.", func(data, id, t, won): return Coracle.finish(data, id, t, won),
		"That is your best run yet: %s.", func(t): return "%.1f seconds" % t, "Not this time. Alternate the strokes, and brace when the boat starts to spin.")

func _game(c: Dictionary, v: Dictionary, cfg: Dictionary, menu: String, ask: String, fin_fn: Callable, record_line: String, fmt_fn: Callable, lose_line: String) -> void:
	var data: GameStateData = host.data
	var id := str(c.get("venue", ""))
	var who := str(c.get("who", "Marshal"))
	var rival: Dictionary = v.rival
	var rname := str(rival.who).split(",")[0]
	await host.say(who, str(rival.intro))
	while true:
		var i: int = await host.choice(ask % rname, ["Have a go", "How does it work?", "Where's the real thing?", "Not today"])
		if i == 1:
			await host.say(who, str(cfg.how))
		elif i == 2:
			await host.say(who, str(v.real))
		else:
			if i != 0:
				await host.say(who, "Fair enough. The water will still be here tomorrow. Mostly.")
				return
			break
	var res = await host.open_menu(menu + ":" + id)
	if not (res is Dictionary):
		await host.say(who, "Out already? The water was only just getting used to you.")
		return
	var won := bool(res.get("won", false))
	var t := float(res.get("time", 0.0))
	var fin: Dictionary = fin_fn.call(data, id, t, won)
	if bool(fin.record):
		await host.say("", record_line % str(fmt_fn.call(t)))
	if not won:
		await host.say(who, lose_line)
		return
	await host.say("", "%s beats %s." % [data.player_name, rname])
	if str(fin.line) != "":
		await host.say(rname, str(fin.line))
	if int(fin.money) > 0:
		var paid := Wallet.earn_here(data, int(fin.money), host.zone_id())
		await host.sfx("item")
		await host.say("", "%s for the winner%s." % [Wallet.fmt(int(paid.amount), str(paid.cur)), " (the prize)" if bool(fin.first) else " (a tin of pennies from the hat)"])
	if bool(fin.first):
		var line := Standing.add(data, Standing.nation_for_zone(host.zone_id()), 1)
		if line != "":
			await host.say("", line + ".")
