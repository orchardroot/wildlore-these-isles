class_name FolkRaceRun
extends RefCounted
## The `cheese` and `pancake` story commands.
##   {"do": "cheese", "who": "Race Starter"}     three downhill races on Cooper's Hill (CheeseRoll, ui/cheese_screen.gd)
##   {"do": "pancake", "who": "Pancake Marshal"} one run of the Olney pancake race (Pancake, ui/pancake_screen.gd)
## Both say where the real thing happens, pay once a day (a DailyKey stamp) and tally into TrainerStats. The party
## piece prompt is called by the screens themselves.

var cmd: Commands
var host

func _init(c: Commands) -> void:
	cmd = c
	host = c.host

func cheese(c: Dictionary) -> void:
	var data: GameStateData = host.data
	var who := str(c.get("who", "Race Starter"))
	await host.say(who, "Cooper's Hill, near Gloucester. Every Spring Bank Holiday a Double Gloucester is rolled off the top and a crowd chases it down a slope you would not walk down on purpose. The cheese gets a head start and reaches about 70 miles an hour; nobody has ever caught it on the way down. The winner keeps it.")
	while true:
		var i: int = await host.choice("Three downhill races. First to the bottom wins.", ["Race", "How does it work?", "Where's the real thing?", "Not today"])
		if i == 1:
			await host.say(who, "Steer left and right and dodge the tussocks and rabbit holes. Hold Run to dig your heels in if it gets away from you. The slope leans, so mind the camber. Tumbles cost you points, not the race. And yes, the cheese is catchable here. That is why it is a game.")
		elif i == 2:
			await host.say(who, "Cooper's Hill, Brockworth, Gloucestershire. The Spring Bank Holiday, last Monday in May. There are four downhill races and an uphill one, and a St John Ambulance crew who have seen everything. The roll itself is centuries old. The council and the insurers would like to know nothing about it.")
		else:
			if i != 0:
				await host.say(who, "Wise. The hill will still be there, and so, I am sorry to say, will the nettles at the bottom.")
				return
			break
	var res = await host.open_menu("cheese")
	if not (res is Dictionary):
		await host.say(who, "Left the start line already? The cheese did not wait, to be fair.")
		return
	var fin := CheeseRoll.finish_evening(data, int(res.get("best", 0)), bool(res.get("won", false)))
	if bool(fin.record) and int(res.get("best", 0)) > 0:
		await host.say("", "That is your best evening yet: %d points." % int(res.get("best", 0)))
	if not bool(res.get("won", false)):
		await host.say(who, "No win tonight. Tip: the hill pulls sideways in places, so lean into it early. And dig your heels in before the holes, not after.")
		return
	await host.say("", "%s wins a race and a round of Double Gloucester." % data.player_name)
	if int(fin.money) > 0:
		var paid := Wallet.earn_here(data, int(fin.money), host.zone_id())
		await host.sfx("item")
		await host.say("", "%s for the winner%s." % [Wallet.fmt(int(paid.amount), str(paid.cur)), " (the winner's purse)" if bool(fin.first) else " (a slice and a plaster)"])
	if bool(fin.first):
		var line := Standing.add(data, Standing.nation_for_zone(host.zone_id()), 1)
		if line != "":
			await host.say("", line + ".")

func pancake(c: Dictionary) -> void:
	var data: GameStateData = host.data
	var who := str(c.get("who", "Pancake Marshal"))
	await host.say(who, "Olney, Buckinghamshire, on Shrove Tuesday, and by tradition since 1445. Women of the town run 415 yards to the church in an apron and a headscarf, tossing a pancake in a frying pan at the start and again at the finish. The winner gets a kiss from the verger and a prayer book from the vicar.")
	while true:
		var i: int = await host.choice("One run, against the clock and the champion.", ["Run", "How does it work?", "Where's the real thing?", "Not today"])
		if i == 1:
			await host.say(who, "Confirm tosses the pancake to start. Hold Run to sprint, but the pan sways more. Lean left and right to keep the pancake off the rim; if it drops, you stop and scrape it up. Press Confirm as you pass each flag to flip it. Missed flips cost time, and the last one costs three seconds.")
		elif i == 2:
			await host.say(who, "Olney, Buckinghamshire, Shrove Tuesday. Liberal, Kansas, runs the same race on the same day and compares times, a friendly rivalry since 1950. It is the only pancake race with a transatlantic leaderboard.")
		else:
			if i != 0:
				await host.say(who, "Fine. The pancake will keep, which is more than can be said for most batter.")
				return
			break
	var res = await host.open_menu("pancake")
	if not (res is Dictionary):
		await host.say(who, "Pan down already? The pancake bell had only just stopped.")
		return
	var fin := Pancake.finish_race(data, float(res.get("time", 99.0)), bool(res.get("won", false)))
	if not bool(res.get("won", false)):
		await host.say(who, "Not past the champion this time. Sprint between the flags, lean early, and flip on the beat. And do not look at the crowd.")
		return
	await host.say("", "%s beats the Olney champion, and is kissed by the verger. Rules are rules." % data.player_name)
	if int(fin.money) > 0:
		var paid := Wallet.earn_here(data, int(fin.money), host.zone_id())
		await host.sfx("item")
		await host.say("", "%s for the winner%s." % [Wallet.fmt(int(paid.amount), str(paid.cur)), " (the prayer book, and a tip from the vicar)" if bool(fin.first) else " (a lemon and sugar, and a coin)"])
	if bool(fin.first):
		var line := Standing.add(data, Standing.nation_for_zone(host.zone_id()), 1)
		if line != "":
			await host.say("", line + ".")
