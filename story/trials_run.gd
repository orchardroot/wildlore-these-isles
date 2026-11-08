class_name TrialsRun
extends RefCounted
## The `sheepdog` and `worms` story commands (wave 48).
##   {"do": "sheepdog", "venue": "longshaw", "who": "Roy"}    seven sheep, a gate and a pen, against the venue's local
##   {"do": "worms", "venue": "willaston", "who": "Pat"}      sixty seconds on a three-by-three plot, against the local
## Rules, locals, venues and prizes live in SheepdogTrials (data/sheepdog_trials.json) and WormCharming (data/worm_charming.json); the
## screens are ui/sheepdog_screen.gd and ui/worm_screen.gd, which also offer the party piece.

var cmd: Commands
var host

func _init(c: Commands) -> void:
	cmd = c
	host = c.host

func sheepdog(c: Dictionary) -> void:
	var id := str(c.get("venue", ""))
	var v := SheepdogTrials.venue(id)
	if v.is_empty():
		push_warning("TrialsRun: no sheepdog venue '%s'" % id)
		return
	await _run(c, v, "sheepdog", SheepdogTrials.cfg().how, "Walk them in, steady. Sheep don't read the programme.", "penned")

func worms(c: Dictionary) -> void:
	var id := str(c.get("venue", ""))
	var v := WormCharming.venue(id)
	if v.is_empty():
		push_warning("TrialsRun: no worm charming venue '%s'" % id)
		return
	await _run(c, v, "worms", WormCharming.cfg().how, "Keep the beat steady and the earth does the rest.", "worms")

func _run(c: Dictionary, v: Dictionary, menu: String, how: String, tip: String, key: String) -> void:
	var data: GameStateData = host.data
	var id := str(c.get("venue", ""))
	var who := str(c.get("who", "Steward"))
	var rival: Dictionary = v.rival
	var them := str(rival.who).split(",")[0]
	var sheep := menu == "sheepdog"
	await host.say(who, str(rival.intro))
	while true:
		var i: int = await host.choice(("Seven sheep against %s and the clock." if sheep else "One minute on the plot against %s.") % them, ["Have a go", "How does it work?", "Where's the real thing?", "Not today"])
		if i == 1:
			await host.say(who, how)
		elif i == 2:
			await host.say(who, str(v.real))
		else:
			if i != 0:
				await host.say(who, "Fair enough. The sheep aren't going anywhere. Neither, by the look of it, is the dog." if sheep else "Fair enough. The worms will keep. They always do.")
				return
			break
	var res = await host.open_menu("%s:%s" % [menu, id])
	if not (res is Dictionary):
		await host.say(who, "Off already? The flock hadn't even noticed you." if sheep else "Gone already? The soil had barely started to hum.")
		return
	var won := bool(res.get("won", false))
	var n := int(res.get(key, 0))
	var fin: Dictionary = SheepdogTrials.finish(data, id, n, won) if sheep else WormCharming.finish(data, id, n, won)
	if not sheep and bool(fin.record):
		await host.say("", "That is your best charm yet: %d worms." % n)
	if not won:
		await host.say(who, ("A draw. Both of you will be at the back of the tent for the tea." if bool(res.get("draw", false)) else tip) if sheep else tip)
		return
	await host.say("", "%s beats %s." % [data.player_name, them])
	if str(fin.line) != "":
		await host.say(them, str(fin.line))
	if int(fin.money) > 0:
		var paid := Wallet.earn_here(data, int(fin.money), host.zone_id())
		await host.sfx("item")
		await host.say("", "%s for the winner%s." % [Wallet.fmt(int(paid.amount), str(paid.cur)), " (the trial prize)" if bool(fin.first) else " (a tea and a rosette sticker)"])
	if bool(fin.first):
		var line := Standing.add(data, Standing.nation_for_zone(host.zone_id()), 1)
		if line != "":
			await host.say("", line + ".")
