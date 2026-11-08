class_name RoadBowlRun
extends RefCounted
## The `road_bowl` and `poohsticks` story commands.
##   {"do": "road_bowl", "venue": "cork", "who": "Mairead"}      a round of Irish road bowling against the venue's local
##   {"do": "poohsticks", "venue": "oxford", "who": "Hugo"}      five races of Poohsticks, a small stake on the side
## Rules, locals and prizes live in RoadBowling (data/road_bowling.json) and Poohsticks (data/poohsticks.json); the
## screens are ui/road_bowling_screen.gd and ui/poohsticks_screen.gd.

var cmd: Commands
var host

func _init(c: Commands) -> void:
	cmd = c
	host = c.host

func road_bowl(c: Dictionary) -> void:
	var data: GameStateData = host.data
	var id := str(c.get("venue", ""))
	var v := RoadBowling.venue(id)
	if v.is_empty():
		push_warning("RoadBowlRun: no road bowling venue '%s'" % id)
		return
	var who := str(c.get("who", "Bowler"))
	var rival: Dictionary = v.rival
	var name := str(rival.who).split(",")[0]
	await host.say(who, str(rival.intro))
	while true:
		var i: int = await host.choice("A round of the lane against %s. Fewest throws to the finish wins." % name, ["Have a go", "How does it work?", "Where's the real thing?", "Not today"])
		if i == 1:
			await host.say(who, str(RoadBowling.cfg().how))
		elif i == 2:
			await host.say(who, str(v.real))
		else:
			if i != 0:
				await host.say(who, "Fair enough. The road will be here. It was here before the tarmac.")
				return
			break
	var res = await host.open_menu("roadbowl:" + id)
	if not (res is Dictionary):
		await host.say(who, "Off already? Mind the traffic. There isn't any, but mind it.")
		return
	var won := bool(res.get("won", false))
	var fin := RoadBowling.finish(data, id, won)
	if not won:
		await host.say(who, "Drawn, and we will not be speaking of it." if bool(res.get("draw", false)) else "Not this time. Throw into the bend, and let the road do the walking.")
		return
	await host.say("", "%s beats %s round the %s road." % [data.player_name, name, str(v.name)])
	if str(fin.line) != "":
		await host.say(name, str(fin.line))
	await _pay(int(fin.money), bool(fin.first), "the prize", "a pint at the crossroads")
	if bool(fin.first):
		var line := Standing.add(data, Standing.nation_for_zone(host.zone_id()), 1)
		if line != "":
			await host.say("", line + ".")

func poohsticks(c: Dictionary) -> void:
	var data: GameStateData = host.data
	var id := str(c.get("venue", ""))
	var v := Poohsticks.venue(id)
	if v.is_empty():
		push_warning("RoadBowlRun: no poohsticks venue '%s'" % id)
		return
	var who := str(c.get("who", "Player"))
	var rival: Dictionary = v.rival
	var name := str(rival.who).split(",")[0]
	await host.say(who, str(rival.intro))
	var stake := 0
	while true:
		var i: int = await host.choice("Five races against %s at %s." % [name, str(v.name)], ["Play", "How does it work?", "Where's the real thing?", "Not today"])
		if i == 1:
			await host.say(who, str(Poohsticks.cfg().how))
		elif i == 2:
			await host.say(who, str(v.real))
		else:
			if i != 0:
				await host.say(who, "Fair enough. The river will keep. It is, after all, a river.")
				return
			break
	var cur := Wallet.local(data)
	var opts := ["No stake"]
	var amounts := [0]
	for n in [1, 2, 5]:
		if Wallet.can_afford(data, n, cur):
			opts.append("%s on the match" % Wallet.fmt(n, cur))
			amounts.append(n)
	if opts.size() > 1:
		var s: int = await host.choice("A little something on the side? Pennies, traditionally. %s pays double if you take the match." % name, opts)
		stake = int(amounts[clampi(s, 0, amounts.size() - 1)])
	var res = await host.open_menu("poohsticks:" + id)
	if not (res is Dictionary):
		await host.say(who, "You walked off with your stake still in the river. Nobody is going to fish it out.")
		return
	var won := bool(res.get("won", false))
	var draw := bool(res.get("draw", false))
	if stake > 0:
		if won:
			Wallet.spend(data, stake, cur)
			Wallet.earn(data, stake * 2, cur)
			await host.say("", "%s hands over %s." % [name, Wallet.fmt(stake * 2, cur)])
		elif not draw:
			Wallet.spend(data, stake, cur)
			await host.say("", "You pay %s %s." % [name, Wallet.fmt(stake, cur)])
		else:
			await host.say("", "Stakes returned. The river takes nothing.")
	var fin := Poohsticks.finish(data, id, won)
	if not won:
		await host.say(who, "A draw, and a very polite one." if draw else "The river does not owe anyone anything. Watch the leaves, and go where they go fastest.")
		return
	await host.say("", "%s takes the match against %s, %d races to %d." % [data.player_name, name, int(res.get("wins", 0)), int(res.get("losses", 0))])
	if str(fin.line) != "":
		await host.say(name, str(fin.line))
	await _pay(int(fin.money), bool(fin.first), "the prize", "a bag of chips on the way home")

func _pay(money: int, first: bool, first_note: String, later_note: String) -> void:
	if money <= 0:
		return
	var paid := Wallet.earn_here(host.data, money, host.zone_id())
	await host.sfx("item")
	await host.say("", "%s for the winner (%s)." % [Wallet.fmt(int(paid.amount), str(paid.cur)), first_note if first else later_note])
