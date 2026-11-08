class_name ContestRun
extends RefCounted
## The `gurn`, `wang` and `league` story commands (wave 48 G5).
##   {"do": "gurn", "venue": "egremont", "who": "Maureen"}      the gurning contest against the venue's champion
##   {"do": "wang", "venue": "upperthong", "who": "Dave"}       three wangs of a welly against the venue's champion
##   {"do": "league", "who": "Secretary"}                       the Isles Games League card, and its reward letters
## Rules, rivals and prizes live in Gurning (data/gurning.json), WellyWang (data/welly_wang.json) and GamesLeague.

var cmd: Commands
var host

func _init(c: Commands) -> void:
	cmd = c
	host = c.host

func _intro(who: String, v: Dictionary, how: String, label: String) -> bool:
	var rival: Dictionary = v.rival
	await host.say(who, str(rival.intro))
	while true:
		var i: int = await host.choice(label % str(rival.who).split(",")[0], ["Have a go", "How does it work?", "Where's the real thing?", "Not today"])
		if i == 1:
			await host.say(who, how)
		elif i == 2:
			await host.say(who, str(v.real))
		elif i == 0:
			return true
		else:
			return false
	return false

func _paid(who: String, v: Dictionary, fin: Dictionary, noun: String) -> void:
	var data: GameStateData = host.data
	var rival: Dictionary = v.rival
	await host.say("", "%s beats %s." % [data.player_name, str(rival.who).split(",")[0]])
	if str(fin.line) != "":
		await host.say(str(rival.who).split(",")[0], str(fin.line))
	if int(fin.money) > 0:
		var paid := Wallet.earn_here(data, int(fin.money), host.zone_id())
		await host.sfx("item")
		await host.say("", "%s for the winner%s." % [Wallet.fmt(int(paid.amount), str(paid.cur)), " (the %s)" % noun if bool(fin.first) else " (a pie on the way home)"])
	if bool(fin.first):
		var line := Standing.add(data, Standing.nation_for_zone(host.zone_id()), 1)
		if line != "":
			await host.say("", line + ".")

func gurn(c: Dictionary) -> void:
	var data: GameStateData = host.data
	var id := str(c.get("venue", ""))
	var v := Gurning.venue(id)
	if v.is_empty():
		push_warning("ContestRun: no gurning venue '%s'" % id)
		return
	var who := str(c.get("who", "Judge"))
	if not await _intro(who, v, str(Gurning.cfg().how), "Longest run of gurns copied against %s wins."):
		await host.say(who, "Fair enough. The braffin will keep. It has kept since 1267.")
		return
	var res = await host.open_menu("gurning:" + id)
	if not (res is Dictionary):
		await host.say(who, "Gone already? The collar was only warming up.")
		return
	var fin := Gurning.finish(data, id, int(res.get("best", 0)), bool(res.get("won", false)))
	if bool(fin.record):
		await host.say("", "That is your longest run of gurns yet: %d." % int(res.get("best", 0)))
	if not bool(res.get("won", false)):
		await host.say(who, "Not this time. Say the order under your breath, and keep the face loose.")
		return
	await _paid(who, v, fin, "purse")

func wang(c: Dictionary) -> void:
	var data: GameStateData = host.data
	var id := str(c.get("venue", ""))
	var v := WellyWang.venue(id)
	if v.is_empty():
		push_warning("ContestRun: no welly wang venue '%s'" % id)
		return
	var who := str(c.get("who", "Steward"))
	if not await _intro(who, v, str(WellyWang.cfg().how), "Three wangs against %s. Furthest boot wins."):
		await host.say(who, "Fair enough. The boots will still smell the same tomorrow.")
		return
	var res = await host.open_menu("wang:" + id)
	if not (res is Dictionary):
		await host.say(who, "Walking off with the boot still in your hand? Most unusual.")
		return
	var fin := WellyWang.finish(data, id, float(res.get("best", 0.0)), bool(res.get("won", false)))
	if bool(fin.record):
		await host.say("", "That is your furthest wang yet: %d metres." % int(res.get("best", 0.0)))
	if not bool(res.get("won", false)):
		await host.say(who, "Not this time. Spin it up, let go in the gap, and let the wind do a bit.")
		return
	await _paid(who, v, fin, "prize")

func league(c: Dictionary) -> void:
	var data: GameStateData = host.data
	var who := str(c.get("who", "Secretary"))
	await host.say(who, "The Isles Games Society keeps a card for every game played in earnest. Stamp it by playing, not by turning up.")
	await host.open_menu("league")
	for letter in GamesLeague.due_letters(data):
		await host.sfx("level_up")
		await host.say("", "A letter from the Isles Games Society.")
		await host.say("Isles Games Society", str(letter.text))
		if int(letter.money) > 0:
			var paid := Wallet.earn_here(data, int(letter.money), host.zone_id())
			await host.sfx("item")
			await host.say("", "%s was enclosed." % Wallet.fmt(int(paid.amount), str(paid.cur)))
