class_name GreenRun
extends RefCounted
## The `bowls` and `skim` story commands.
##   {"do": "bowls", "venue": "waterloo", "who": "Dennis"}     three ends of crown green against the venue's local
##   {"do": "skim", "venue": "easdale", "who": "Fiona"}        three stones against the venue's local
## Rules, locals, venues and prizes live in Bowls (data/bowls.json) and Skimming (data/skimming.json); the screens are
## ui/bowls_screen.gd and ui/skimming_screen.gd.

var cmd: Commands
var host

func _init(c: Commands) -> void:
	cmd = c
	host = c.host

func bowls(c: Dictionary) -> void:
	var data: GameStateData = host.data
	var id := str(c.get("venue", ""))
	var v := Bowls.venue(id)
	if v.is_empty():
		push_warning("GreenRun: no bowls venue '%s'" % id)
		return
	var who := str(c.get("who", "Green Keeper"))
	var rival: Dictionary = v.rival
	await host.say(who, "%s. %s" % [str(v.name).capitalize(), str(rival.intro)])
	while true:
		var i: int = await host.choice("Three ends against %s, two woods each." % str(rival.who).split(",")[0], ["Play", "How does it work?", "Where's the real thing?", "Not today"])
		if i == 1:
			await host.say(who, str(Bowls.cfg().how))
		elif i == 2:
			await host.say(who, str(v.real))
		else:
			if i != 0:
				await host.say(who, "Fair enough. The green isn't going anywhere. It's had that crown for decades.")
				return
			break
	var res = await host.open_menu("bowls:" + id)
	if not (res is Dictionary):
		await host.say(who, "Walked off mid-end? The jack will wait.")
		return
	var won := bool(res.get("won", false))
	var fin := Bowls.finish(data, id, int(res.get("ends", 0)), won)
	if not won:
		await host.say(who, "Drawn game. Back to the hut for a tea." if bool(res.get("draw", false)) else "Not this time. The crown has its favourites, and today it was not you.")
		return
	await host.say("", "%s wins the match against %s." % [data.player_name, str(rival.who).split(",")[0]])
	if str(fin.line) != "":
		await host.say(str(rival.who).split(",")[0], str(fin.line))
	if int(fin.money) > 0:
		var paid := Wallet.earn_here(data, int(fin.money), host.zone_id())
		await host.sfx("item")
		await host.say("", "%s for the winner%s." % [Wallet.fmt(int(paid.amount), str(paid.cur)), " (the match prize)" if bool(fin.first) else " (a pint and some pork scratchings)"])
	if bool(fin.first):
		var line := Standing.add(data, Standing.nation_for_zone(host.zone_id()), 1)
		if line != "":
			await host.say("", line + ".")

func skim(c: Dictionary) -> void:
	var data: GameStateData = host.data
	var id := str(c.get("venue", ""))
	var v := Skimming.venue(id)
	if v.is_empty():
		push_warning("GreenRun: no skimming venue '%s'" % id)
		return
	var who := str(c.get("who", "Skimmer"))
	var rival: Dictionary = v.rival
	await host.say(who, str(rival.intro))
	while true:
		var i: int = await host.choice("Three stones against %s. Best count of skips wins." % str(rival.who).split(",")[0], ["Have a go", "How does it work?", "Where's the real thing?", "Not today"])
		if i == 1:
			await host.say(who, str(Skimming.cfg().how))
		elif i == 2:
			await host.say(who, str(v.real))
		else:
			if i != 0:
				await host.say(who, "Fair enough. The water will still be flat tomorrow. Probably.")
				return
			break
	var res = await host.open_menu("skim:" + id)
	if not (res is Dictionary):
		await host.say(who, "Gone already? The stones were only warming up.")
		return
	var fin := Skimming.finish(data, id, int(res.get("best", 0)), bool(res.get("won", false)))
	if bool(fin.record):
		await host.say("", "That is your best skim yet: %d." % int(res.get("best", 0)))
	if not bool(res.get("won", false)):
		await host.say(who, "Not this time. Flatter, and keep it near twenty degrees, and the water does the rest.")
		return
	await host.say("", "%s beats %s." % [data.player_name, str(rival.who).split(",")[0]])
	if str(fin.line) != "":
		await host.say(str(rival.who).split(",")[0], str(fin.line))
	if int(fin.money) > 0:
		var paid := Wallet.earn_here(data, int(fin.money), host.zone_id())
		await host.sfx("item")
		await host.say("", "%s for the winner%s." % [Wallet.fmt(int(paid.amount), str(paid.cur)), " (the prize)" if bool(fin.first) else " (chips on the way home)"])
	if bool(fin.first):
		var line := Standing.add(data, Standing.nation_for_zone(host.zone_id()), 1)
		if line != "":
			await host.say("", line + ".")
