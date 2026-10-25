class_name LadderSportRun
extends RefCounted
## The `curling` and `wrestling` story commands.
##   {"do": "curling", "rink": "inverness_rink", "who": "Rink Steward"}    a four-stone end against the next club skip
##   {"do": "wrestling", "venue": "grasmere", "who": "Ring Steward"}       a best-of-three bout against the next rival
## Each is a small ladder (data/curling.json, data/wrestling.json): beat the next rival for the prize, then play
## rematches for the venue's daily purse (a DailyKey stamp). Rules and prizes live in Curling and Wrestling; the
## screens are ui/curling_screen.gd and ui/wrestling_screen.gd.

var cmd: Commands
var host

func _init(c: Commands) -> void:
	cmd = c
	host = c.host

func curling(c: Dictionary) -> void:
	var rink_id := str(c.get("rink", host.zone_id()))
	var who := str(c.get("who", "Rink Steward"))
	var rink := Curling.rink(rink_id)
	if rink.is_empty():
		push_warning("LadderSportRun: no curling rink '%s'" % rink_id)
		return
	await _ladder({
		"who": who, "name": str(rink.name), "list": rink.skips, "beaten": Curling.rungs_beaten(host.data, rink_id),
		"next": Curling.next_rung(host.data, rink_id), "menu": "curling:%s:%%d" % rink_id,
		"ask": "Four stones each, and you have the last one. Closest to the button scores.", "verb": "end",
		"win": func(i: int): return Curling.win(host.data, rink_id, i),
		"champion": func(): return Curling.champion(host.data, rink_id),
		"purse": "(the rink's kitty)",
	})

func wrestling(c: Dictionary) -> void:
	var venue_id := str(c.get("venue", host.zone_id()))
	var who := str(c.get("who", "Ring Steward"))
	var venue := Wrestling.venue(venue_id)
	if venue.is_empty():
		push_warning("LadderSportRun: no wrestling venue '%s'" % venue_id)
		return
	await _ladder({
		"who": who, "name": str(venue.name), "list": venue.rivals, "beaten": Wrestling.rungs_beaten(host.data, venue_id),
		"next": Wrestling.next_rung(host.data, venue_id), "menu": "wrestling:%s:%%d" % venue_id,
		"ask": "Best of three falls. Read the throw and answer it.", "verb": "bout",
		"win": func(i: int): return Wrestling.win(host.data, venue_id, i),
		"champion": func(): return Wrestling.champion(host.data, venue_id),
		"purse": "(the tent's kitty)",
	})

## The shared flow: offer the next rival (or a friendly), open the screen, pay out.
func _ladder(o: Dictionary) -> void:
	var data: GameStateData = host.data
	var who: String = o.who
	var list: Array = o.list
	var beaten: int = o.beaten
	var next: Dictionary = o.next
	var opts: Array = []
	var picks: Array = []
	if not next.is_empty():
		await host.say(who, "%s. You're on %d of %d. %s" % [o.name, beaten, list.size(), str(next.intro)])
		opts.append("Play %s" % str(next.who).split(",")[0])
		picks.append(beaten)
	else:
		await host.say(who, "Champion of the %s! Fancy a friendly?" % o.name)
	if beaten > 0:
		opts.append("A friendly")
		picks.append(-1)
	opts.append("Not today")
	var i: int = await host.choice(str(o.ask), opts)
	if i >= picks.size():
		await host.say(who, "Fair enough. We'll be here.")
		return
	var idx: int = picks[i]
	if idx < 0:
		idx = host.rng.roll_int(0, maxi(0, mini(beaten, list.size()) - 1))
	var res = await host.open_menu(str(o.menu) % idx)
	if not (res is Dictionary) or not bool(res.get("won", false)):
		await host.say(who, "Not this time. %s" % ("No shame in it." if res is Dictionary and not res.get("quit", false) else "Walked off mid-%s, did we?" % o.verb))
		return
	var won: Dictionary = o.win.call(idx)
	await host.say("", "%s wins the %s against %s." % [data.player_name, o.verb, str(list[idx].who).split(",")[0]])
	if str(won.line) != "":
		await host.say(str(list[idx].who).split(",")[0], str(won.line))
	if int(won.money) > 0:
		var paid := Wallet.earn_here(data, int(won.money), host.zone_id())
		await host.sfx("item")
		await host.say("", "%s for the winner%s." % [Wallet.fmt(int(paid.amount), str(paid.cur)), " (the prize)" if bool(won.first) else " " + str(o.purse)])
	if bool(won.first):
		var line := Standing.add(data, Standing.nation_for_zone(host.zone_id()), 3 if bool(o.champion.call()) else 1)
		if line != "":
			await host.say("", line + ".")
